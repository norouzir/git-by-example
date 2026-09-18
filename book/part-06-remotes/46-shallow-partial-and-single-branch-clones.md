# Chapter 46. Shallow, Partial, and Single-Branch Clones

## What it is

A normal clone downloads everything: every branch, every commit, and every
version of every file. Three kinds of clone download less, each by leaving out
something different:

- A *shallow* clone leaves out old history. It has the newest commits and
  pretends the history starts there.
- A *partial* clone has all the commits, and leaves out objects, usually old
  versions of files, which Git downloads later when a command needs them.
- A *single-branch* clone fetches one branch, now and in later fetches.

On their own they answer one question: *how little can I download and still
work?* Each saves differently and costs differently. A shallow clone cannot
show or merge what it does not have; a partial clone needs the server again
whenever it reaches for a missing object; a single-branch clone does not see
other branches. This chapter shows what each one contains, what stops working
in it, how to add what is missing later, and how the three compare. Chapter 9
introduced all three; the sections below point back to it rather than repeat it.

| Term | Means |
|---|---|
| *shallow clone* | a repository whose history has been cut off at some commits; `git rev-parse --is-shallow-repository` answers `true` |
| *shallow boundary* | the commits where history was cut, listed in `.git/shallow`; Git treats them as if they had no parents |
| *depth* | the number of commits kept, counted from the tip of each branch fetched |
| *deepen*, *unshallow* | fetch more of the history of a shallow clone, or all of it |
| *partial clone* | a repository that was fetched with a filter and may lack objects the server has |
| *filter* | the rule `--filter=<spec>` saying which objects to leave out, such as `blob:none` |
| *promisor remote* | the remote a partial clone was made from, which promises to supply missing objects later |
| *lazy fetch* | a fetch Git starts on its own when a command needs an object the partial clone lacks |
| *blob*, *tree* | a file's content, and a directory listing (Chapter 6) |
| *blobless*, *treeless* clone | a partial clone made with `--filter=blob:none`, which leaves out file contents, or `--filter=tree:0`, which leaves out directory listings as well |
| *single-branch clone* | a clone whose fetch refspec names one branch (Chapter 44) |

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What is the difference between a shallow, a partial and a single-branch clone?](#what-it-is)
- [What does each one cost me later?](#what-it-is)

**[The three at a glance](#the-three-at-a-glance)**

- [Which one leaves out what, and how do I make it complete again?](#the-three-at-a-glance)

**[Options at a glance](#options-at-a-glance)**

- [Is there a list of every option involved, and where each is shown?](#options-at-a-glance)

**[The example repository](#the-example-repository)**

- [What repository do the examples use?](#the-example-repository)
- [I cloned a folder on my own disk with `--filter` and got a warning. Why?](#the-example-repository)

**[Shallow clones](#shallow-clones)**

- [What is actually in a clone made with `--depth 3`?](#what-a-shallow-clone-has)
- [What does "grafted" mean in `git log`?](#what-a-shallow-clone-has)
- [Why does `git show` say the oldest commit I have added every file?](#what-stops-working)
- [Why does `git blame` say every line came from one commit with a `^`?](#what-stops-working)
- [Why does `git describe` fail, or an old tag seem not to exist?](#what-stops-working)
- [I started `git bisect` with an old tag as the good commit, and it just waits. Why?](#what-stops-working)
- [How do I get more history into a shallow clone, or all of it?](#deepening)
- [What is the difference between `--depth` and `--deepen` on a fetch?](#deepening)
- [Does fetching with a smaller depth delete the older commits?](#deepening)
- [Can a fetch make a complete clone shallow?](#deepening)
- [Why does merging a branch fail with "refusing to merge unrelated histories"?](#merging-in-a-shallow-clone)
- [Can I just add `--allow-unrelated-histories` and merge anyway?](#merging-in-a-shallow-clone)
- [Can I push from a shallow clone?](#pushing-from-a-shallow-clone)
- [What does "shallow update not allowed" mean?](#pushing-from-a-shallow-clone)
- [Fetching from a shallow clone did nothing but print a warning. Why?](#fetching-from-a-shallow-repository)

**[Single-branch clones](#single-branch-clones)**

- [Why does `git switch` say "invalid reference" for a branch the server has?](#what-a-single-branch-clone-sees)
- [I fetched the other branch by name. Why is there still no `origin/<branch>`?](#what-a-single-branch-clone-sees)
- [How do I add another branch to a single-branch clone?](#widening-a-single-branch-clone)
- [What happens if the one branch I clone is a tag?](#a-tag-as-the-one-branch)

**[Partial clones](#partial-clones)**

- [What does each filter leave out?](#filters)
- [Why are fewer files missing after a clone that checked out a branch?](#filters)
- [Can I combine two filters?](#filters)
- [The clone said "filter not supported". Whose setting is that?](#what-the-server-allows)
- [What does "Server does not allow request for unadvertised object" mean?](#what-the-server-allows)
- [How can I tell a partial clone's packs from ordinary ones?](#what-a-partial-clone-keeps)
- [Which commands will download objects without asking me?](#commands-that-fetch-on-demand)
- [Why is `git blame` or `git log -p` slow in a partial clone?](#commands-that-fetch-on-demand)
- [What happens when the server cannot be reached?](#without-the-server)
- [How do I stop Git from downloading, to check what is really there?](#without-the-server)
- [How do I download the missing files in advance, before I go offline?](#downloading-ahead)
- [Why does `git backfill` with a branch's name say the name is unknown?](#downloading-ahead)
- [Does downloading the files of a range also bring the files of the commit before it?](#downloading-ahead)
- [How do I change the filter of an existing partial clone, or make it complete?](#changing-the-filter)
- [What does `--filter=auto` do?](#a-filter-the-server-chooses)
- [Why did `--filter=auto` give me an ordinary full clone?](#a-filter-the-server-chooses)

**[How much each one downloads](#how-much-each-one-downloads)**

- [How much does each kind of clone actually save?](#how-much-each-one-downloads)

**[Which to choose](#which-to-choose)**

- [Which kind of clone should I use for a build, for daily work, or on a slow connection?](#which-to-choose)

**[Clones and their neighbours](#clones-and-their-neighbours)**

- [How do these compare with a sparse checkout, `--revision`, an archive or a bundle?](#clones-and-their-neighbours)

**[The settings](#the-settings)**

- [Which settings matter, on my side and on the server?](#the-settings)

</details>

## The three at a glance

| Kind | Made with | Leaves out | Stops working or gets slow | Made complete with |
|---|---|---|---|---|
| shallow | `git clone --depth <n>`, `--shallow-since`, `--shallow-exclude` | commits older than the boundary, and their files | history, blame, describe, bisect and merges beyond the boundary | `git fetch --unshallow` |
| partial | `git clone --filter=<spec>` | the objects the filter names, until needed | anything needing a missing object when the server is unreachable; commands that read many old files | `git backfill --all` for file contents, or `git fetch --refetch` once the filter setting is removed |
| single-branch | `git clone --single-branch` | other branches | switching to or comparing with the branches left out | `git remote set-branches` (Chapter 39) |

`--depth` also makes the clone single-branch unless `--no-single-branch` is given
(Chapter 9). Shallow and partial clones need the real transfer protocol, so a
local path must be written as a `file://` URL, as every example here does
([The example repository](#the-example-repository) shows what happens
otherwise).

## Options at a glance

### For shallow clones

| Option | Does | Covered in |
|---|---|---|
| `--depth=<n>` | Clone or fetch only the last `<n>` commits of each branch | [What a shallow clone has](#what-a-shallow-clone-has) |
| `--deepen=<n>` | Fetch `<n>` more commits behind the current boundary | [Deepening](#deepening) |
| `--shallow-since=<date>` | Keep the commits after a date | [Deepening](#deepening) |
| `--shallow-exclude=<ref>` | Keep the commits not reachable from a branch or tag | [Deepening](#deepening) |
| `--unshallow` | Fetch the whole history | [Deepening](#deepening) |
| `--update-shallow` | Accept refs from a shallow repository that need a new boundary | [Fetching from a shallow repository](#fetching-from-a-shallow-repository) |
| `--reject-shallow`, `--no-reject-shallow` | Refuse to clone a shallow repository, or allow it | Chapter 9 |
| `--no-single-branch` | With `--depth`, fetch every branch | Chapter 9 |

### For single-branch clones

| Option | Does | Covered in |
|---|---|---|
| `--single-branch` | Clone one branch, and write a refspec for it alone | [What a single-branch clone sees](#what-a-single-branch-clone-sees) |
| `-b <name>`, `--branch <name>` | The branch, or tag, to clone | [A tag as the one branch](#a-tag-as-the-one-branch) |

### For partial clones

| Option | Does | Covered in |
|---|---|---|
| `--filter=blob:none` | Leave out every blob | [Filters](#filters) |
| `--filter=blob:limit=<n>` | Leave out blobs of `<n>` bytes or more; `k`, `m`, `g` for units | [Filters](#filters) |
| `--filter=tree:<depth>` | Keep only the top `<depth>` levels of each commit's trees and files: `tree:0` keeps none, `tree:1` the top-level tree alone | [Filters](#filters) |
| `--filter=object:type=<type>` | Keep only objects of one type | [Filters](#filters) |
| `--filter=combine:<spec>+<spec>` | Leave out what any of the filters leaves out; also written as repeated `--filter` | [Filters](#filters) |
| `--filter=sparse:oid=<blob>` | Leave out blobs outside a sparse-checkout pattern stored in a blob | Chapter 60 |
| `--filter=auto` | Use the filter the server advertises for its promisor remotes | [A filter the server chooses](#a-filter-the-server-chooses) |
| `--refetch` | Fetch everything again, as a new clone would, with the filter now in force | [Changing the filter](#changing-the-filter) |
| `--no-lazy-fetch` | An option of `git` itself: never fetch a missing object on demand | [Without the server](#without-the-server) |
| `--also-filter-submodules` | Apply the filter to submodules too | Chapter 57 |

### For git backfill

| Option | Does | Covered in |
|---|---|---|
| `<revision-range>` | Only blobs reachable from these commits; `HEAD` by default | [Downloading ahead](#downloading-ahead) |
| `--min-batch-size=<n>` | Ask for at least `<n>` blobs per request; 50,000 by default | [Downloading ahead](#downloading-ahead) |
| `--include-edges`, `--no-include-edges` | Include, or not, the blobs of the commits just outside the range, such as `A` in `A..B`; included by default | [Downloading ahead](#downloading-ahead) |
| `--sparse`, `--no-sparse` | Only blobs inside the sparse checkout | Chapter 60 |

> **Since Git 2.49.** `git backfill`, with `--min-batch-size` and `--sparse`.
> **Since Git 2.54.** Its revision range, and `--filter=auto`. **Since Git 2.55.**
> `--include-edges` and `--no-include-edges`; before 2.55 backfill left out the
> blobs of the commits just outside the range. **Since Git 2.24.** `combine:`.
> **Since Git 2.32.** `object:type=`. **Since Git 2.36.** `git fetch --refetch`
> and `--also-filter-submodules`. **Since Git 2.45.** `git --no-lazy-fetch`.

`git backfill` is marked experimental in Git's documentation, which says its
behaviour may change.

## The example repository

```console
$ git -C server/atlas.git log --oneline --graph --all --decorate
* a0235f1 (drafts) Draft an idea
| * 0e2b720 (HEAD -> main) Add Oceania
| * ffb488c (tag: v2.0) Add Africa
|/  
*   49dd93b Merge branch 'rivers'
|\  
| * d89121e (rivers) List rivers
* | 430c0e5 Write the guide
* | 1cd765d Update the elevation data
|/  
* 6bcb8b8 Add Asia
* 1cf532f (tag: v1.0) Add the elevation data
* 0fe19df Add Europe
* 0dd6887 Start the atlas
$ git -C server/atlas.git cat-file -s v1.0:data/elevation.txt && git -C server/atlas.git cat-file -s v2.0:data/elevation.txt
6553
7001
```

A bare repository on the "server" with three branches, a merge, and two
annotated tags. `data/elevation.txt` is the one large file, in two versions of
6,553 and 7,001 bytes (`git cat-file -s` prints an object's size, Chapter 6).
The server allows filters, as hosting services do (`uploadpack.allowFilter`,
Chapter 9). Each section makes its own clones, in the directory that holds
`server`, from `file:///home/ada/server/atlas.git`. A plain path would not do:

```console
$ git clone --filter=blob:none server/atlas.git local
Cloning into 'local'...
warning: --filter is ignored in local clones; use file:// instead.
done.
```

As with `--depth` in Chapter 9, a local path copies the object database
directly instead of running the transfer protocol, and filters belong to the
protocol. The warning says so, and the clone is an ordinary one.

## Shallow clones

### What a shallow clone has

```console
$ git clone -q --depth 3 file:///home/ada/server/atlas.git shallow
$ git log --oneline --graph --decorate --all
* 0e2b720 (HEAD -> main, origin/main, origin/HEAD) Add Oceania
* ffb488c (tag: v2.0) Add Africa
* 49dd93b (grafted) Merge branch 'rivers'
$ git branch -a && git tag && cat .git/shallow && git rev-parse --is-shallow-repository
* main
  remotes/origin/HEAD -> origin/main
  remotes/origin/main
v2.0
49dd93bec2e9c54c98753a17cbe3c6a71a2b4fc3
true
```

In the clone. Three commits, the last marked `grafted`: that is how `git log`
labels a commit in `.git/shallow`, a boundary commit whose parents Git will not
look for. The merge commit is there; the two lines of history it joins are not.
Only `main` was cloned, because `--depth` implies `--single-branch`, and of the
tags only `v2.0`, the one pointing into the history that was fetched.

### What stops working

```console
$ git show --stat --format=%s HEAD~2
Merge branch 'rivers'

 README.md           |   1 +
 data/elevation.txt  | 320 ++++++++++++++++++++++++++++++++++++++++++++++++++++
 docs/guide/intro.md |   1 +
 maps/asia.txt       |   1 +
 maps/europe.txt     |   1 +
 rivers.txt          |   1 +
 6 files changed, 325 insertions(+)
$ git blame maps/europe.txt
^49dd93b (Ada Lovelace 2026-01-05 16:00:00 +0000 1) Europe
```

To every command that walks history, the boundary is the first commit ever
made. So `git show` presents the merge as adding every file in the project, and
`git blame` gives every line to the boundary, marking it with `^`, which is how
blame marks a commit it could not look past (Chapter 19). Neither is an error,
and neither is true.

```console
$ git describe && git describe HEAD~2; echo "exit $?"
v2.0-1-g0e2b720
fatal: No tags can describe '49dd93bec2e9c54c98753a17cbe3c6a71a2b4fc3'.
Try --always, or create some tags.
exit 128
$ git log --oneline v1.0; echo "exit $?"
fatal: ambiguous argument 'v1.0': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
exit 128
$ git rev-list --count HEAD && git -C ../server/atlas.git rev-list --count main
3
10
```

`git describe` works from the newest commit, which has `v2.0` behind it, and
fails at the boundary, which has no tag in its known history (Chapter 22). `v1.0`
points below the boundary and was never fetched, so Git does not know the name.
Counting commits counts three, where the server has ten.

```console
$ git bisect start HEAD v1.0
status: waiting for 'good' commit(s), 'bad' commit known
$ git bisect start HEAD v1.0 --; echo "exit $?"
fatal: 'v1.0' does not appear to be a valid revision
exit 128
```

`git bisect` needs a good commit, and the one you know may be below the
boundary. The first command gave no error: `git bisect start` reads its
arguments as commits until it meets one it cannot resolve, and takes that one
and everything after it as paths to limit the search to (read from
`bisect_start` in Git 2.55's `builtin/bisect.c`). `v1.0` became a path, and
bisect is still waiting for a good commit. With `--`, every argument before it
must be a commit, and the mistake is reported. The first command did start a
session, which `git bisect reset` ends (Chapter 20). Deepen the clone first, as
the next section shows, until the good commit is in it.

| Command | In a shallow clone |
|---|---|
| `git log`, `git rev-list --count` | stop at the boundary, which looks like the first commit |
| `git show`, `git log -p` of the boundary commit | show every file as added |
| `git blame` | gives lines older than the boundary to the boundary, marked `^` |
| `git describe` | fails for commits with no tag between them and the boundary |
| tags and commits below the boundary | unknown |
| `git bisect start <bad> <good>` with the good commit below the boundary | takes the unknown name as a path and waits; with `--` after the commits, fails |
| `git merge` of a branch that split off below the boundary | refused as unrelated ([Merging in a shallow clone](#merging-in-a-shallow-clone)) |
| `git commit`, and `git push` to the server the clone came from | work normally ([Pushing from a shallow clone](#pushing-from-a-shallow-clone)) |

### Deepening

In the same clone:

```console
$ git fetch -q --deepen 2 && git rev-list --count HEAD && cat .git/shallow
7
1cd765d6e2adeea55db3080c974ea6571d588c53
6bcb8b8d4041e1e0b0ad8ac9d12a1a13f9b803fc
$ git fetch -q --depth 2 && git rev-list --count HEAD && cat .git/shallow
2
1cd765d6e2adeea55db3080c974ea6571d588c53
6bcb8b8d4041e1e0b0ad8ac9d12a1a13f9b803fc
ffb488c985e47b633db1d8dd8a45a9fa57a7abed
$ git cat-file -t 49dd93b && git show -s --format=%s 49dd93b
commit
Merge branch 'rivers'
```

`--deepen 2` fetched two more commits behind the boundary along every path: two
behind the merge on each side of it, seven commits in all, with a new boundary
on each side. `--depth 2` counts from the branch tips instead, and so it made
the history *shorter*, two commits, with `Add Africa` as the new boundary. The
commits no longer counted are still in the repository, beyond the boundary:
`git cat-file -t` finds the merge, and `git show` shows it by its hash.
`.git/shallow` kept the older boundary lines as well.

```console
$ git fetch -q --shallow-exclude=v1.0 && git log --oneline | tail -2
d89121e List rivers
6bcb8b8 Add Asia
$ git fetch -q --shallow-since=2026-01-05T15:30:00Z && git log --format='%h %ad %s' --date=iso | tail -2
ffb488c 2026-01-05 17:00:00 +0000 Add Africa
49dd93b 2026-01-05 16:00:00 +0000 Merge branch 'rivers'
```

`--shallow-exclude` moves the boundary to just after a tag or branch: every
commit reachable from `v1.0` was left out, and `Add Asia`, the next, is the
oldest. `--shallow-since` keeps the commits made after a date, and the boundary
here became the merge made at 16:00. Both shorten or deepen, as the history
requires.

```console
$ git fetch --unshallow && git rev-parse --is-shallow-repository && git rev-list --count HEAD
From file:///home/ada/server/atlas
 * [new tag]         v1.0       -> v1.0
false
10
$ git fetch --unshallow; echo "exit $?"
fatal: --unshallow on a complete repository does not make sense
exit 128
$ git fetch -q --depth 1 && git rev-parse --is-shallow-repository && git rev-list --count HEAD
true
1
```

`--unshallow` fetched the rest: the clone is complete, with all ten commits, and
`v1.0`, now pointing into the history, came with it. On a complete repository
the option is an error. And a fetch with `--depth` on a complete repository makes
it shallow again.

| Fetch option | New boundary |
|---|---|
| `git fetch --depth=<n>` | `<n>` commits from the tip of each branch fetched; may shorten |
| `git fetch --deepen=<n>` | `<n>` commits further than the current boundary |
| `git fetch --shallow-since=<date>` | the commits after the date |
| `git fetch --shallow-exclude=<ref>` | the commits not reachable from the ref |
| `git fetch --unshallow` | none: the whole history |

### Merging in a shallow clone

In a clone made with `--depth 1 --no-single-branch`, which has the newest commit
of every branch (Chapter 9), and one commit of its own on `main` that adds a
line to `maps/europe.txt`. The branch `drafts` split from `main` at the merge
`49dd93b`, two commits behind `origin/main`:

```console
$ git merge origin/drafts; echo "exit $?"
fatal: refusing to merge unrelated histories
exit 128
$ git merge --allow-unrelated-histories origin/drafts; echo "exit $?"
Auto-merging maps/europe.txt
CONFLICT (add/add): Merge conflict in maps/europe.txt
Automatic merge failed; fix conflicts and then commit the result.
exit 1
$ git merge --abort && git fetch -q --deepen 2 && git merge --no-edit origin/drafts
Merge made by the 'ort' strategy.
 drafts.txt | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 drafts.txt
```

A merge needs the commit where the two branches split, the merge base
(Chapter 25), and with one commit on each side there is none, so the histories
look unrelated. `--allow-unrelated-histories` merges without a base, so every
file counts as added on both sides: files the two sides have alike merge
cleanly, and a file that differs becomes an add/add conflict (Chapter 26). Here
that was `maps/europe.txt`, which only this side had changed. `git merge --abort`
ended the attempt. Deepening every branch past the split point let the merge
find its base, and the same merge went through with no conflict.

### Pushing from a shallow clone

In a clone made with `--depth 1`, with a new commit `Add the Arctic`, pushing
first to a new, empty repository and then to the server the clone came from:

```console
$ git push ../server/new.git main; echo "exit $?"
To ../server/new.git
 ! [remote rejected] main -> main (shallow update not allowed)
error: failed to push some refs to '../server/new.git'
exit 1
$ git -C ../server/new.git config set receive.shallowUpdate true
$ git push --progress ../server/new.git main 2>&1 | tr '\r' '\n' | grep -E 'Total|->'
Total 18 (delta 2), reused 12 (delta 0), pack-reused 0 (from 0)
 * [new branch]      main -> main
$ git -C ../server/new.git rev-parse --is-shallow-repository
true
$ git push --progress origin main 2>&1 | tr '\r' '\n' | grep -E 'Total|->'
Total 4 (delta 2), reused 0 (delta 0), pack-reused 0 (from 0)
   0e2b720..675eeb3  main -> main
```

An empty repository has none of the history, so the push would make it shallow
too, and a receiving repository refuses that unless `receive.shallowUpdate` is
`true`, as Git's documentation for it says. Allowed, the push sent 18 objects,
everything the clone has, and the new repository became shallow. The server the
clone came from already has the history below the boundary, so the push there
was an ordinary fast-forward and sent four objects: the new commit, its two
changed trees and the new file. `--progress`, `tr` and `grep` are Chapter 43's
way of seeing the object count. The server's `main` was put back afterwards, so
later sections do not see this commit.

### Fetching from a shallow repository

In an empty repository, fetching `main` from the clone of
[Merging in a shallow clone](#merging-in-a-shallow-clone), which is still
shallow:

```console
$ git fetch ../merging main; echo "exit $?"
warning: rejected refs/heads/main because shallow roots are not allowed to be updated
exit 0
$ git fetch --update-shallow ../merging main && git rev-parse --is-shallow-repository
From ../merging
 * branch            main       -> FETCH_HEAD
true
```

The same rule on the fetching side: taking history from a shallow repository
would make this one shallow, and by default fetch refuses, with a warning and an
exit status of 0, so a script sees success. `--update-shallow` accepts it.

## Single-branch clones

### What a single-branch clone sees

A clone made with `--single-branch --branch drafts`, in the clone:

```console
$ git branch -a && git tag && git config get --all remote.origin.fetch
* drafts
  remotes/origin/drafts
v1.0
+refs/heads/drafts:refs/remotes/origin/drafts
$ git switch rivers; echo "exit $?"
fatal: invalid reference: rivers
exit 128
$ git fetch origin rivers && git branch -r
From file:///home/ada/server/atlas
 * branch            rivers     -> FETCH_HEAD
  origin/drafts
```

The history of `drafts` is complete, and so the tag `v1.0`, which points into
it, came along. The refspec names `drafts` alone (Chapter 44), so there is no
`origin/rivers`, and `git switch rivers` has nothing to make a branch from
(Chapter 24). Naming the branch in a fetch downloads it, but only into
`FETCH_HEAD`: without a refspec that covers `rivers`, there is nowhere to record
it (Chapter 41), and `git branch -r` still lists `origin/drafts` alone.

### Widening a single-branch clone

```console
$ git remote set-branches --add origin rivers && git fetch && git switch -q rivers && git branch -vv
From file:///home/ada/server/atlas
 * [new branch]      rivers     -> origin/rivers
  drafts a0235f1 [origin/drafts] Draft an idea
* rivers d89121e [origin/rivers] List rivers
```

`git remote set-branches --add` adds a refspec line for one more branch
(Chapter 39); the next fetch created `origin/rivers`, and `git switch` could use
it. `git remote set-branches origin '*'` replaces the lines with one for every
branch, which undoes the single-branch clone entirely.

### A tag as the one branch

In the directory above the clones:

```console
$ git clone -q --single-branch --branch v1.0 file:///home/ada/server/atlas.git one-tag 2>&1 | head -2 && git -C one-tag config get --all remote.origin.fetch
warning: refs/tags/v1.0 3a7e6f6dd094ab530e07d772022c074cbae8c799 is not a commit!
Note: switching to '1cf532fbf624ecaea213bf88309da22b62bacf74'.
+refs/tags/v1.0:refs/tags/v1.0
```

`--branch` accepts a tag, and the clone is left on a detached `HEAD` at its
commit (Chapter 9). With `--single-branch`, the refspec names the tag, so later
fetches follow that tag and nothing else. The warning is about the annotated
tag, a tag object and not a commit (Chapter 6); the clone still worked, and
`head -2` cut the detached `HEAD` advice that follows.

## Partial clones

### Filters

In the directory above the clones:

```console
$ git clone -q --no-checkout --filter=blob:none file:///home/ada/server/atlas.git blobless && git -C blobless rev-list --objects --all --missing=print | grep -c '^?'
10
$ git clone -q --filter=blob:none file:///home/ada/server/atlas.git blobless-checked-out && git -C blobless-checked-out rev-list --objects --all --missing=print | grep -c '^?'
2
```

`git rev-list --objects --all --missing=print` lists every object the history
refers to, marking with `?` those that are missing ([Chapter 22](#ch22-missing-objects)),
and `grep -c` counts them. `blob:none` left out all ten file versions;
`--no-checkout` kept the clone from checking out a branch. The second clone
checked out `main`, and to write its files Git fetched their contents during the
clone, so only the two versions `main` does not use were still missing.

```console
$ git clone -q --filter=blob:limit=1k file:///home/ada/server/atlas.git small-blobs && git -C small-blobs rev-list --objects --all --missing=print | grep '^?' && git -C small-blobs rev-list --objects --all | grep elevation
?a2045bb2ddf3a0d05105378637ae4868a80988d2
52568a940629abe3c96d0b59eea3e3b1d9a1e4db data/elevation.txt
a2045bb2ddf3a0d05105378637ae4868a80988d2 data/elevation.txt
```

`blob:limit=1k` leaves out blobs of 1 KiB or more. Only the older version of the
elevation data is missing: the newer one is also large, but the checkout needed
it.

```console
$ git clone -q --no-checkout file:///home/ada/server/atlas.git everything && git -C everything count-objects -v | grep in-pack
in-pack: 42
$ git clone -q --no-checkout --filter=tree:0 file:///home/ada/server/atlas.git treeless && git -C treeless count-objects -v | grep in-pack
in-pack: 13
$ git clone -q --no-checkout --filter=object:type=commit file:///home/ada/server/atlas.git commits-only && git -C commits-only count-objects -v | grep in-pack
in-pack: 13
```

A filter that leaves out trees hides the blobs below them from
`--missing=print`, so these are counted with `git count-objects`, which counts
what the clone holds (Chapter 71). A complete clone holds 42 objects.
`tree:0` leaves out every tree and blob, keeping 13: the eleven commits and the
two annotated tags. `object:type=commit` keeps only commits, and yet the tags
are there too: Git's documentation of the filters says objects asked for
explicitly are never filtered out, and a clone asks the server for each tag it
fetches by the tag's hash. So it came to the same 13.

```console
$ git clone -q --no-checkout --filter=tree:2 file:///home/ada/server/atlas.git two-levels && git -C two-levels count-objects -v | grep in-pack
in-pack: 34
$ git clone -q --no-checkout --filter=blob:none --filter=tree:2 file:///home/ada/server/atlas.git combined && git -C combined count-objects -v | grep in-pack && git -C combined config get remote.origin.partialclonefilter
in-pack: 31
combine:blob:none+tree:2
$ git clone -q --no-checkout --filter=combine:blob:none+tree:2 file:///home/ada/server/atlas.git combined-long && git -C combined-long count-objects -v | grep in-pack
in-pack: 31
```

`tree:2` keeps two levels of each commit's trees: the top-level tree, and what it
lists directly, the directories `maps`, `data` and `docs` and the files at the
top. `docs/guide`, and every file inside a directory, were left out: 34 objects.
Two `--filter` options combine, and an object is left out if either filter
leaves it out, so `blob:none` also removed the three files at the top: 31, fewer
than either filter alone. The clone stored the pair as one filter,
`combine:blob:none+tree:2`, the long form Git's documentation describes, and
written that way it gave the same 31.

### What the server allows

```console
$ git -C server/atlas.git config set uploadpackfilter.tree.allow false && git clone --filter=tree:0 file:///home/ada/server/atlas.git refused; echo "exit $?"
Cloning into 'refused'...
fatal: filter 'tree' not supported
fatal: remote error: filter 'tree' not supported
exit 128
```

The first command is a setting on the server. Filtering is the server's work, so
the server decides: `uploadpack.allowFilter` turns filters on (Chapter 9), and
`uploadpackfilter.<filter>.allow` can refuse one kind, here every `tree:`
filter. The refusal comes from the remote end, and nothing was cloned. A server
that does not allow filtering at all gives only a warning and an ordinary full
clone, as Chapter 9 shows. The setting was removed again after this example.

A lazy fetch asks the server for objects by their hash. Over protocol version 2,
the default (Chapter 40), every lazy fetch in this chapter was allowed to. Over
version 0:

```console
$ git clone -q --no-checkout --filter=blob:none file:///home/ada/server/atlas.git old-protocol && git -C old-protocol -c protocol.version=0 show v1.0:maps/europe.txt; echo "exit $?"
error: Server does not allow request for unadvertised object 2520ce9a07d91973803f92098b6204699b73461c
fatal: could not fetch 2520ce9a07d91973803f92098b6204699b73461c from promisor remote
exit 128
$ git -C server/atlas.git config set uploadpack.allowAnySHA1InWant true && git -C old-protocol -c protocol.version=0 show v1.0:maps/europe.txt
Europe
```

The server refused to hand out an object that none of its refs points at
directly, until `uploadpack.allowAnySHA1InWant`, which Git's documentation
describes as allowing a request for any object at all, was set on the server.
This setting too was removed after the example.

### What a partial clone keeps

```console
$ ls blobless/.git/objects/pack | sed 's/pack-[0-9a-f]*/pack-<hash>/'
pack-<hash>.idx
pack-<hash>.pack
pack-<hash>.promisor
pack-<hash>.rev
```

Beside each pack a partial clone receives is a `.promisor` file. Git's technical
documentation on partial clone calls these promisor packfiles: an object such a
pack refers to but does not contain counts as promised by the remote, which is
how Git tells an object left out on purpose from one lost to corruption. `sed`
only shortened the hash in the names. The clone's configuration marks the remote with
`remote.origin.promisor` and records the filter in
`remote.origin.partialclonefilter` (Chapter 9), and `git remote -v` shows the
filter (Chapter 39).

### Commands that fetch on demand

In the blobless clone that checked out `main`:

```console
$ GIT_TRACE=1 git log --oneline 2>&1 >/dev/null | grep -c 'fetch'
0
$ GIT_TRACE=1 git log -p 2>&1 >/dev/null | grep -o 'run_command: .*noop fetch.*'
run_command: git -c fetch.negotiationAlgorithm=noop fetch origin --no-tags --no-write-fetch-head --recurse-submodules=no --filter=blob:none --stdin
```

`GIT_TRACE=1` prints each program Git starts ([Chapter 40](#ch40-seeing-more)),
on two lines, `run_command:` and `start_command:`; the greps here match the
first, so each lazy fetch is one line. `git log --oneline` needs only commits,
and started nothing. `git log -p` needed the one file version the checkout had
not brought, the older elevation data, and started one lazy fetch: a
`git fetch` of the missing objects, named on standard input, with the clone's
filter, and with the `noop` negotiation, which sends no `have` lines
([Chapter 41](#ch41-what-the-client-says-it-has)).

In the blobless clone with nothing checked out:

```console
$ GIT_TRACE=1 git blame main -- data/elevation.txt 2>&1 >/dev/null | grep -c 'run_command: .*noop fetch'
2
$ GIT_TRACE=1 git log -p 2>&1 >/dev/null | grep -c 'run_command: .*noop fetch'
7
```

`git blame` fetched twice for one file, once for each version it needed, one
after the other. `git log -p` then fetched seven times: once for each commit
showing a file version not yet downloaded, since the two versions of the
elevation data had come with blame.

In the treeless clone:

```console
$ GIT_TRACE=1 git log --stat --oneline 2>&1 >/dev/null | grep -c 'run_command: .*noop fetch'
18
```

`git log --stat` needed each commit's trees as well as its files, and fetched 18
times for ten commits. Each fetch here took no time; over a network each is a
separate connection to the server. That is why a treeless clone suits a build
that reads only the newest files, and a blobless clone suits daily work better.

| Command | In a blobless clone | In a treeless clone |
|---|---|---|
| `git log --oneline`, `git log --graph` | no fetch | no fetch |
| `git log -- <path>` | no fetch | one fetch for each missing tree it reads |
| `git log -p`, `git log --stat` | one fetch for each commit whose file versions are missing | the same, and one for each missing tree |
| `git blame <file>` | one fetch for each missing version of the file | the same, and one for each missing tree |
| `git diff <commit> <commit>`, `git switch` to another commit | one fetch for all the missing files | one for each missing tree, then the files |
| `git status`, `git add`, `git commit` with a branch checked out | no fetch | no fetch |

<!-- The table was measured on this chapter's example with GIT_TRACE=1,
     counting run_command lines, one fresh clone per command, 2026-09-18.
     Checked out main, blobless / treeless: log --oneline 0/0,
     log --oneline -- maps/asia.txt 0/8, log --stat 1/10, log -p 1/10,
     blame main -- data/elevation.txt 1/6, diff v1.0 v2.0 1/3,
     switch --detach v1.0 1/2, status 0/0, add and commit 0/0.
     With nothing checked out, blobless: log -p 8, blame 2, diff 1, switch 1.
     A packet trace showed one object per treeless fetch for trees. -->

### Without the server

A blobless clone was made, and then the server's repository was moved, as if the
network had gone:

```console
$ git log --oneline -2 && git show v1.0:maps/europe.txt; echo "exit $?"
0e2b720 Add Oceania
ffb488c Add Africa
fatal: '/home/ada/server/atlas.git' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
fatal: could not fetch 2520ce9a07d91973803f92098b6204699b73461c from promisor remote
exit 128
$ git --no-lazy-fetch cat-file -e v1.0:maps/europe.txt; echo "exit $?"
exit 1
$ GIT_NO_LAZY_FETCH=1 git show v1.0:maps/europe.txt; echo "exit $?"
fatal: bad object v1.0:maps/europe.txt
exit 128
```

The history is all there, and `git log` worked. Showing an old file needed a
blob the clone never had, the lazy fetch failed with the transport's error, and
the command failed with it. For a reader working offline this is the property to
remember: a partial clone works offline only for what it has already downloaded.

`git --no-lazy-fetch`, or the environment variable `GIT_NO_LAZY_FETCH=1`, which
Git's documentation calls equivalent, turns lazy fetching off for one command.
The documentation suggests it for checking what is really present: `git
cat-file -e` exits with 1 for a missing object, and `git show` reports it as a
bad object instead of trying the network.

### Downloading ahead

In a new blobless clone, with nothing checked out:

```console
$ git backfill v1.0 && git rev-list --objects --all --missing=print | grep -c '^?'
7
$ git backfill && git rev-list --objects --all --missing=print | grep '^?'
?ddc7f5c6d0e0e746de1486386c9f08c4df361caa
$ git log --oneline -1 --all -- drafts.txt
a0235f1 Draft an idea
$ git backfill drafts; echo "exit $?"
fatal: ambiguous argument 'drafts': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
exit 128
$ git backfill --all && git rev-list --objects --all --missing=print | grep -c '^?'
0
```

`git backfill` downloads, in batches, the blobs reachable from the commits it
is given, `HEAD` by default, which is the way to prepare a partial clone for
working offline. `v1.0` brought the three file versions of that release, and
seven were still missing. `HEAD` brought everything `main` refers to; the one
blob left belongs to `drafts`, which `main` does not contain. The clone has no
branch `drafts` of its own, only `origin/drafts` (Chapter 41), so `git backfill
drafts` failed as `git log drafts` would. `--all` takes every ref, as it does
for `git log` (Chapter 17), and left nothing missing.

In two new blobless clones:

```console
$ GIT_TRACE=1 git backfill 2>&1 | grep -c 'run_command: .*noop fetch'
1
$ GIT_TRACE=1 git backfill --min-batch-size=1 2>&1 | grep -c 'run_command: .*noop fetch'
8
```

Git's documentation says backfill groups the blobs by path and asks for at
least 50,000 at a time by default, so that the server can compress versions of
the same file against each other, and that a batch may go over the minimum to
finish the blobs of a path. Here the default fetched all nine blobs of `main`'s
history in one request. `--min-batch-size=1` took eight requests, one for each
path, with the two versions of `data/elevation.txt` in the same one.

In two more:

```console
$ git backfill main~5..main~4 && git --no-lazy-fetch cat-file -e main~5:data/elevation.txt; echo "exit $?"
exit 0
$ git backfill --no-include-edges main~5..main~4 && git --no-lazy-fetch cat-file -e main~5:data/elevation.txt; echo "exit $?"
exit 1
```

`main~5..main~4` is one commit, `Update the elevation data`. Its parent `main~5`,
`Add Asia`, is the edge of the range, left out as a range always leaves out its
left side (Chapter 18). By default backfill also downloads the edge commit's
blobs, which a command such as `git log -p main~5..main~4` needs in order to show
what the commit changed, and the older elevation data was there.
`--no-include-edges` leaves them out, and `git cat-file -e` found it missing.

### Changing the filter

In a new blobless clone, with nothing checked out:

```console
$ git rev-list --objects --all --missing=print | grep -c '^?'
10
$ git fetch -q --refetch --filter=blob:limit=1k && git rev-list --objects --all --missing=print | grep -c '^?' && git config get remote.origin.partialclonefilter
2
blob:none
$ git config unset remote.origin.partialclonefilter && git fetch -q --refetch && git rev-list --objects --all --missing=print | grep -c '^?'
0
```

A normal fetch skips everything the clone already has commits for, so changing
the filter would affect only new commits, as Git's documentation of
`remote.<name>.partialclonefilter` says. `--refetch` fetches everything again
as a new clone would, with the filter now in force: `blob:limit=1k` brought
every small file, leaving the two large versions missing. A filter on the
command line applies to that fetch only, and the setting still said
`blob:none`. With the setting removed, a refetch had no filter to apply and
fetched every object, which makes the clone complete. Git's documentation says
automatic maintenance afterwards removes the duplicate copies.

### A filter the server chooses

This section needs a server that keeps large files in a second repository and
advertises it. In the server's configuration: a remote `large-files` with a
`partialCloneFilter` of `blob:limit=1k`, `promisor.advertise` set to `true`, and
`promisor.sendFields` set to `partialCloneFilter`, so that the server announces
the remote together with its filter. Three clones:

```console
$ GIT_TRACE_PACKET=1 git clone --filter=auto file:///home/ada/server/atlas.git auto-default 2>&1 | grep -o 'clone< promisor-remote=.*\|clone> filter .*'
clone< promisor-remote=name=large-files,url=/home/ada/server/large-files.git,partialCloneFilter=blob:limit=1k
$ GIT_TRACE_PACKET=1 git -c promisor.acceptFromServer=all clone --filter=auto file:///home/ada/server/atlas.git auto-all 2>&1 | grep -o 'clone< promisor-remote=.*\|clone> filter .*'
clone< promisor-remote=name=large-files,url=/home/ada/server/large-files.git,partialCloneFilter=blob:limit=1k
$ GIT_TRACE_PACKET=1 git clone -c promisor.acceptFromServer=knownUrl -c remote.large-files.url=/home/ada/server/large-files.git -c remote.large-files.promisor=true --filter=auto file:///home/ada/server/atlas.git auto 2>&1 | grep -o 'clone< promisor-remote=.*\|clone> filter .*'
clone< promisor-remote=name=large-files,url=/home/ada/server/large-files.git,partialCloneFilter=blob:limit=1k
clone> filter blob:limit=1024
$ git -C auto config get --all --show-names --regexp '^remote\.origin\.(promisor|partialclonefilter)'
remote.origin.promisor true
remote.origin.partialclonefilter auto
```

The packet trace (Chapter 40) shows the advertisement, `clone<`, and the filter
the clone asked for, `clone>`. `--filter=auto` builds the filter from the
advertised promisor remotes the client accepts, and `promisor.acceptFromServer`
decides which those are. By default it accepts none, and the first clone sent no
filter: it is an ordinary full clone, although it recorded `auto`. The second
accepted `all` and still sent none, because it has no remote called
`large-files` of its own; Git's documentation says an advertisement never
creates one. The third was given that remote with `clone -c` (Chapter 9), and
`knownUrl`, which accepts a remote whose name and URL match one already
configured; it sent `filter blob:limit=1024`, the server's filter in bytes.

After a new commit on the server, in the clone `auto`:

```console
$ GIT_TRACE_PACKET=1 git fetch 2>&1 | grep -o 'fetch> filter .*'
fetch> filter blob:limit=1024
```

Git's documentation says the recorded `auto` makes later fetches follow the
server's current recommendation, and this one asked for the same filter. That
depends on `promisor.acceptFromServer` being in the clone's own configuration,
where `clone -c` put it. Given as `git -c promisor.acceptFromServer=knownUrl
clone ...` instead, it lasted for the clone alone, and in a test of that form
the later fetch sent no filter at all.

This is for servers that keep large files elsewhere; for an ordinary server,
name the filter.

## How much each one downloads

In the directory above the clones, each clone made with nothing checked out:

```console
$ git clone -q --no-checkout file:///home/ada/server/atlas.git c-full && git -C c-full count-objects -v | grep in-pack
in-pack: 42
$ git clone -q --no-checkout --single-branch file:///home/ada/server/atlas.git c-single && git -C c-single count-objects -v | grep in-pack
in-pack: 39
$ git clone -q --no-checkout --depth 1 file:///home/ada/server/atlas.git c-depth && git -C c-depth count-objects -v | grep in-pack
in-pack: 14
$ git clone -q --no-checkout --filter=blob:none file:///home/ada/server/atlas.git c-blobless && git -C c-blobless count-objects -v | grep in-pack
in-pack: 32
$ git clone -q --no-checkout --filter=tree:0 file:///home/ada/server/atlas.git c-treeless && git -C c-treeless count-objects -v | grep in-pack
in-pack: 13
$ git clone -q --no-checkout --depth 1 --filter=blob:none file:///home/ada/server/atlas.git c-both && git -C c-both count-objects -v | grep in-pack
in-pack: 6
```

| Clone | Objects | What is left out |
|---|---|---|
| complete | 42 | nothing |
| `--single-branch` | 39 | the `drafts` commit, its tree and its file |
| `--depth 1` | 14 | every commit but the newest, the other branches and the tags, with every tree and file version only they use |
| `--filter=blob:none` | 32 | every file version |
| `--filter=tree:0` | 13 | every tree and file version |
| `--depth 1 --filter=blob:none` | 6 | both: one commit, its trees, no files |

The numbers count objects, not bytes. Which kind saves the most in a real
project depends on how its size divides between history and files, which this
small example cannot show.

## Which to choose

| You want to | Use | Because |
|---|---|---|
| build or test the newest commit once, and throw the clone away | `git clone --depth 1`, or `--filter=tree:0` | the least download; history is not needed |
| work on a large project every day | `git clone --filter=blob:none` | full history for log, branches and merges; old files come when needed |
| work offline with a partial clone | `git backfill --all` before going offline, or a complete clone | lazy fetches fail without the server |
| investigate history: blame, bisect, describe | a complete clone | shallow clones give wrong answers there, and partial clones fetch for every old version |
| follow one branch of a repository with many | `git clone --single-branch --branch <name>` | other branches are never fetched |
| keep a mirror or backup | a complete clone, `--mirror` (Chapter 9) | anything less is not a backup |

## Clones and their neighbours

| To leave out | Use | Difference |
|---|---|---|
| old history | a shallow clone | commits are missing, so history-based commands stop at the boundary |
| old file contents | a partial clone | history is complete; contents come on demand, with the server |
| other branches | a single-branch clone | what is fetched is complete |
| files from your working tree | a sparse checkout (Chapter 60) | everything is downloaded unless combined with a filter |
| every branch and tag, keeping one commit and its history | `git clone --revision=<commit>` (Chapter 9) | detached, no branches to fetch later |
| the repository altogether | `git archive --remote` (Chapter 61) | files of one commit, no Git history |
| the network | `git bundle` (Chapter 61) | a file that carries history offline |
| large files from normal history | Git LFS (Chapter 59) | files are replaced by pointers when committed, not filtered when fetched |

## The settings

| Setting | Does |
|---|---|
| `remote.<name>.promisor` | This remote supplies missing objects |
| `remote.<name>.partialclonefilter` | The filter for fetches from this remote, or `auto`; `--refetch` applies a change to existing history |
| `promisor.quiet` | Fetch missing objects quietly |
| `promisor.acceptFromServer` | `none`, `knownUrl`, `knownName` or `all`: which advertised promisor remotes to accept |
| `promisor.checkFields`, `promisor.storeFields` | Which advertised fields to check against, or store in, the local configuration |
| `clone.rejectShallow` | Refuse to clone a shallow repository (Chapter 9) |
| `clone.filterSubmodules` | Apply the clone's filter to submodules (Chapter 57) |

On the server:

| Setting | Does |
|---|---|
| `uploadpack.allowFilter` | Allow partial clones and fetches (Chapter 9) |
| `uploadpackfilter.allow` | The default for every kind of filter; `true` by default |
| `uploadpackfilter.<filter>.allow` | Allow or refuse one kind: `blob:none`, `blob:limit`, `object:type`, `tree`, `sparse:oid`, `combine` |
| `uploadpackfilter.tree.maxDepth` | The largest depth allowed in `tree:<depth>` |
| `uploadpack.allowAnySHA1InWant` | Allow a request for any object by its hash, which lazy fetches over protocol version 0 need |
| `promisor.advertise`, `promisor.sendFields` | Advertise the server's promisor remotes, and which of their fields |
| `receive.shallowUpdate` | Accept pushes that would make the repository shallow |

> **Since Git 2.29.** `uploadpackfilter.*`. **Since Git 2.32.**
> `clone.rejectShallow`. **Since Git 2.36.** `clone.filterSubmodules`. **Since
> Git 2.46.** `promisor.quiet`. **Since Git 2.49.** `promisor.advertise` and
> `promisor.acceptFromServer`. **Since Git 2.52.** `promisor.sendFields` and
> `promisor.checkFields`. **Since Git 2.54.** `promisor.storeFields`.
