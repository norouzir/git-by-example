# Chapter 25. merge

## What it is

`git merge <branch>` brings the commits of another branch into the current one.
It answers "put that work into this branch".

A merge has one of two results:

| Result | When | What Git does |
|---|---|---|
| *fast-forward* | the current branch has no commits the other lacks | moves the current branch forward to the other branch's commit; no new commit |
| *true merge* | both branches have commits of their own | combines the changes and records a *merge commit* with two parents |

The commit where the two histories split is their *merge base*. A true merge
compares both branches with it: a change made on one side only is taken, and
when both sides changed the same lines differently, the merge stops with a
*conflict* for you to resolve. This chapter shows a conflict stopping a merge and
how to finish or abandon it; Chapter 26 is about resolving conflicts, and
Chapter 27 about the strategies and options that change how Git combines files.

Before a merge Git saves where the current branch was in `ORIG_HEAD`, so a merge
can be undone.

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What does `git merge` do?](#what-it-is)
- [What is the difference between a fast-forward and a merge commit?](#what-it-is)

**[Synopsis](#synopsis)**

- [What can I type after `git merge`?](#synopsis)

**[Options at a glance](#options-at-a-glance)**

- [Is there a list of every option, and where each is explained?](#options-at-a-glance)

**[The example repository](#the-example-repository)**

- [What repository do the examples use?](#the-example-repository)

**[Fast-forward and true merges](#fast-forward-and-true-merges)**

- [Why did my merge not create a merge commit?](#fast-forward)
- [How do I always get a merge commit, even when a fast-forward is possible?](#ff-no-ff-and-ff-only)
- [How do I merge only if it can be a fast-forward?](#ff-no-ff-and-ff-only)
- [What does "Already up to date" mean?](#ff-no-ff-and-ff-only)
- [What is inside a merge commit, and how do I tell its parents apart?](#what-a-merge-commit-is)
- [Why does `git show` on a merge commit show no changes?](#what-a-merge-commit-is)

**[The merge message](#the-merge-message)**

- [Why did `git merge` open an editor, and how do I stop it?](#the-default-message-and-the-editor)
- [How do I write my own merge message?](#writing-your-own-message)
- [How do I list the merged commits in the message?](#listing-the-merged-commits)
- [Why does the message say "into try" on one branch and not on `main`?](#the-branch-name-in-the-message)

**[What merge prints](#what-merge-prints)**

- [What does the list after "Merge made by the 'ort' strategy" mean, and can I change it?](#what-merge-prints)

**[Stopping before the commit](#stopping-before-the-commit)**

- [How do I merge but look at the result before committing?](#merging-without-committing)
- [Why did `--no-commit` still move my branch?](#merging-without-committing)
- [How do I squash a branch into one commit instead of merging it?](#squash-merges)
- [Why can't I delete a branch after a squash merge?](#squash-merges)

**[Merging several branches at once](#merging-several-branches-at-once)**

- [Can I merge several branches in one go?](#merging-several-branches-at-once)

**[When a merge stops](#when-a-merge-stops)**

- [My merge says "CONFLICT". What state am I in?](#when-a-merge-stops)
- [How do I cancel a merge that stopped?](#when-a-merge-stops)
- [How do I finish a merge after fixing the files?](#when-a-merge-stops)
- [What does `git merge --quit` do?](#when-a-merge-stops)

**[Uncommitted changes](#uncommitted-changes)**

- [Can I merge with uncommitted changes?](#uncommitted-changes)
- [Why does merge refuse because of a file I only staged?](#uncommitted-changes)
- [What does `--autostash` do, and where do my changes go if the merge stops?](#uncommitted-changes)

**[What you can merge](#what-you-can-merge)**

- [What does `git merge` with no branch name merge?](#what-you-can-merge)
- [How do I merge what I fetched from the server?](#what-you-can-merge)
- [Does merging a tag create a merge commit?](#what-you-can-merge)
- [Can I merge while HEAD is detached?](#what-you-can-merge)
- [What does "refusing to merge unrelated histories" mean?](#what-you-can-merge)

**[Undoing a merge](#undoing-a-merge)**

- [How do I undo a merge I just made?](#undoing-a-merge)
- [How do I undo a merge that is already pushed?](#undoing-a-merge)
- [I reverted a merge and merging the branch again does nothing. Why?](#undoing-a-merge)

**[merge and its neighbours](#merge-and-its-neighbours)**

- [How do I see whether a merge would conflict, without touching my files?](#merge-and-its-neighbours)
- [Should I merge, rebase, squash or cherry-pick?](#merge-and-its-neighbours)

**[The settings](#the-settings)**

- [Which settings change what `git merge` does?](#the-settings)

</details>

## Synopsis

```
git merge [-n] [--stat] [--compact-summary] [--no-commit] [--squash] [--[no-]edit]
          [--no-verify] [-s <strategy>] [-X <strategy-option>] [-S[<keyid>]]
          [--[no-]allow-unrelated-histories]
          [--[no-]rerere-autoupdate] [-m <msg>] [-F <file>]
          [--into-name <branch>] [<commit>...]
git merge (--continue | --abort | --quit)
```

| Part | Means |
|---|---|
| `<commit>...` | What to merge: usually a branch, but any commit, tag or remote-tracking branch; several make one merge |
| `<msg>`, `<file>` | The merge commit's message, or a file holding it |
| `<strategy>`, `<strategy-option>` | How files are combined; Chapter 27 |

| Command | Does |
|---|---|
| `git merge <branch>` | Merge the branch into the current branch |
| `git merge` | Merge the current branch's upstream |
| `git merge --continue` | Finish a merge that stopped, once conflicts are resolved |
| `git merge --abort` | Cancel a merge that stopped, restoring the state before it |
| `git merge --quit` | Forget a merge that stopped, leaving the files as they are |

## Options at a glance

### Options for how the merge ends

| Option | Does | Covered in |
|---|---|---|
| `--ff` | Fast-forward when possible, the default | [--ff, --no-ff and --ff-only](#ff-no-ff-and-ff-only) |
| `--no-ff` | Always make a merge commit | [--ff, --no-ff and --ff-only](#ff-no-ff-and-ff-only) |
| `--ff-only` | Only fast-forward; fail otherwise | [--ff, --no-ff and --ff-only](#ff-no-ff-and-ff-only) |
| `--no-commit`, `--commit` | Stop before the merge commit, or not | [Merging without committing](#merging-without-committing) |
| `--squash`, `--no-squash` | Stage the combined changes without recording a merge | [Squash merges](#squash-merges) |
| `--abort` | Cancel a merge that stopped | [When a merge stops](#when-a-merge-stops) |
| `--continue` | Finish a merge that stopped | [When a merge stops](#when-a-merge-stops) |
| `--quit` | Forget a merge that stopped, keeping the files | [When a merge stops](#when-a-merge-stops) |
| `--autostash`, `--no-autostash` | Put uncommitted changes aside during the merge, or not | [Uncommitted changes](#uncommitted-changes) |
| `--allow-unrelated-histories` | Merge a branch that shares no commit with this one | [What you can merge](#what-you-can-merge) |
| `--overwrite-ignore`, `--no-overwrite-ignore` | Overwrite ignored files in the way, the default, or refuse; as in Chapter 24 | Chapter 24 |

### Options for the message

| Option | Does | Covered in |
|---|---|---|
| `-e`, `--edit`, `--no-edit` | Open an editor on the message, or accept it | [The default message and the editor](#the-default-message-and-the-editor) |
| `-m <msg>` | Use this message | [Writing your own message](#writing-your-own-message) |
| `-F <file>`, `--file=<file>` | Take the message from a file | [Writing your own message](#writing-your-own-message) |
| `--cleanup=<mode>` | How the message is tidied; the modes are in Chapter 12 | [Writing your own message](#writing-your-own-message) |
| `--log[=<n>]`, `--no-log` | List the merged commits, at most `<n>`, or not | [Listing the merged commits](#listing-the-merged-commits) |
| `--signoff`, `--no-signoff` | Add a `Signed-off-by` trailer | [The branch name in the message](#the-branch-name-in-the-message) |
| `--into-name <branch>` | Write the message as if merging into another branch | [The branch name in the message](#the-branch-name-in-the-message) |

### Options for output

| Option | Does | Covered in |
|---|---|---|
| `--stat` | List the changed files at the end, the default | [What merge prints](#what-merge-prints) |
| `-n`, `--no-stat` | Leave that list out | [What merge prints](#what-merge-prints) |
| `--compact-summary` | A shorter list with `(new)` and similar marks | [What merge prints](#what-merge-prints) |
| `--summary`, `--no-summary` | Old names for `--stat` and `--no-stat` | [What merge prints](#what-merge-prints) |
| `-q`, `--quiet` | Print nothing | [What merge prints](#what-merge-prints) |
| `-v`, `--verbose` | Print more | [What merge prints](#what-merge-prints) |
| `--progress`, `--no-progress` | Show progress, or not | [What merge prints](#what-merge-prints) |

### Options covered in other chapters

| Option | Does | Covered in |
|---|---|---|
| `-s <strategy>`, `--strategy=<strategy>` | Choose how files are combined | Chapter 27 |
| `-X <option>`, `--strategy-option=<option>` | Pass an option to the strategy | Chapter 27 |
| `--rerere-autoupdate`, `--no-rerere-autoupdate` | Stage conflict resolutions Git remembered | Chapter 26 |
| `-S[<key-id>]`, `--gpg-sign[=<key-id>]`, `--no-gpg-sign` | Sign the merge commit | Chapter 68 |
| `--verify-signatures`, `--no-verify-signatures` | Refuse unless the merged commit is signed | Chapter 68 |
| `--verify`, `--no-verify` | Run the pre-merge and commit-msg hooks, or skip them | Chapter 67 |

## The example repository

```console
$ git log --oneline --graph --all --decorate
* b197e90 (origin/main, origin/HEAD) List the tools
| * e2356ff (HEAD -> main) Water tomatoes more
|/  
| * c53233d (frost) Water less in frost
|/  
| * 72353bd (pond) Dig a pond
|/  
| * 88f0e2c (paths) Lay a gravel path
|/  
| * fb07981 (compost) Add a compost rule
| * 25699ee Start composting
|/  
| * 87ebba0 (lettuce) Water the lettuce
| * e91be24 Plant lettuce
|/  
* 8833aaa Add a watering plan
* f7427e3 Start the planner
```

A garden planner. Every branch started at `Add a watering plan`, which is
`main~1`:

| Branch | Changes |
|---|---|
| `main` | the README, and the tomato line of `water.txt` |
| `lettuce` | adds lettuce to `plants.txt` and `water.txt` |
| `compost` | adds `compost.txt`, in two commits |
| `paths`, `pond` | add `paths.txt` and `pond.txt` |
| `frost` | changes the same tomato line of `water.txt` as `main`, differently |
| `origin/main` | a commit someone else pushed, `List the tools` |

Most examples begin with `git switch -q -C try main`, which puts a scratch branch
`try` at `main` (Chapter 24), so each merge starts from the same place.

Git opens an editor for a merge commit's message only when it runs in a
terminal, Git's source shows. The examples do not run in one, so every merge
that makes a commit says `--no-edit`, which accepts the message Git proposes, or
sets the editor with `GIT_EDITOR` (Chapter 62). Typed at a terminal without them,
the same merges open your editor
([The default message and the editor](#the-default-message-and-the-editor)).

## Fast-forward and true merges

### Fast-forward

```console
$ git switch -q -C try main~1
$ git merge lettuce
Updating 8833aaa..87ebba0
Fast-forward
 plants.txt | 1 +
 water.txt  | 1 +
 2 files changed, 2 insertions(+)
$ git log --oneline --graph -3
* 87ebba0 Water the lettuce
* e91be24 Plant lettuce
* 8833aaa Add a watering plan
```

`try` was at `Add a watering plan`, and `lettuce` had only built on it, so there
was nothing to combine. Git moved `try` to `lettuce`'s commit, `Updating
8833aaa..87ebba0`, and updated the files, listing what changed. The history
stays a straight line, and no commit records that a merge happened.

### --ff, --no-ff and --ff-only

```console
$ git switch -q -C try main~1
$ git merge --no-ff --no-edit lettuce
Merge made by the 'ort' strategy.
 plants.txt | 1 +
 water.txt  | 1 +
 2 files changed, 2 insertions(+)
$ git log --oneline --graph -4
*   5eca5af Merge branch 'lettuce' into try
|\  
| * 87ebba0 Water the lettuce
| * e91be24 Plant lettuce
|/  
* 8833aaa Add a watering plan
$ git merge lettuce
Already up to date.
$ git switch -q -C try main~1
$ git merge --ff-only lettuce
Updating 8833aaa..87ebba0
Fast-forward
 plants.txt | 1 +
 water.txt  | 1 +
 2 files changed, 2 insertions(+)
$ git switch -q -C try main
$ git merge --ff-only lettuce; echo "exit $?"
hint: Diverging branches can't be fast-forwarded, you need to either:
hint:
hint: 	git merge --no-ff
hint:
hint: or:
hint:
hint: 	git rebase
hint:
hint: Disable this message with "git config set advice.diverging false"
fatal: Not possible to fast-forward, aborting.
exit 128
$ git switch -q -C try main~1
$ git -c merge.ff=false merge --no-edit lettuce
Merge made by the 'ort' strategy.
 plants.txt | 1 +
 water.txt  | 1 +
 2 files changed, 2 insertions(+)
$ git switch -q -C try main
$ git -c merge.ff=only merge --no-edit compost
hint: Diverging branches can't be fast-forwarded, you need to either:
hint:
hint: 	git merge --no-ff
hint:
hint: or:
hint:
hint: 	git rebase
hint:
hint: Disable this message with "git config set advice.diverging false"
fatal: Not possible to fast-forward, aborting.
$ git -c merge.ff=only merge --ff --no-edit compost
Merge made by the 'ort' strategy.
 compost.txt | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 compost.txt
$ git log --oneline --graph -4
*   0fe4aa8 Merge branch 'compost' into try
|\  
| * fb07981 Add a compost rule
| * 25699ee Start composting
* | e2356ff Water tomatoes more
|/  
```

| Option | If a fast-forward is possible | If both sides have commits |
|---|---|---|
| `--ff`, the default | fast-forward | merge commit |
| `--no-ff` | merge commit anyway | merge commit |
| `--ff-only` | fast-forward | refuse, exit code 128 |

`--no-ff` keeps a record that `lettuce` was a separate piece of work: `git log
--graph` shows it as a side branch, and one merge commit can be undone to remove
it all (Chapter 31). Many teams merge finished branches this way. `--ff-only` is
the safe way to update a branch that should never gain a merge commit by
accident, such as a copy of a shared branch.

Merging again did nothing: every commit of `lettuce` was already in `try`, which
is what "Already up to date" means. The setting `merge.ff` makes `false` or
`only` the default; `git -c <name>=<value>` sets it for one command (Chapter 62).
An option on the command line wins over it, as the last merge shows.

### What a merge commit is

```console
$ git switch -q -C try main
$ git merge --no-edit compost
Merge made by the 'ort' strategy.
 compost.txt | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 compost.txt
$ git log --oneline --graph -5
*   8c5ffbb Merge branch 'compost' into try
|\  
| * fb07981 Add a compost rule
| * 25699ee Start composting
* | e2356ff Water tomatoes more
|/  
* 8833aaa Add a watering plan
$ git cat-file -p HEAD
tree e7f1f03325886b646499f4c098578ca1ac0d6b8c
parent e2356ff190eafe341deee7604ded777ce2fbd0c5
parent fb07981e269c316e219a3ebcd6fd50a4605bc7e9
author Ada Lovelace <ada@example.com> 1767650400 +0000
committer Ada Lovelace <ada@example.com> 1767650400 +0000

Merge branch 'compost' into try
$ git rev-parse HEAD^1 HEAD^2
e2356ff190eafe341deee7604ded777ce2fbd0c5
fb07981e269c316e219a3ebcd6fd50a4605bc7e9
$ git show HEAD
commit 8c5ffbb13406507c26112cd4066a9227c24ce2bd
Merge: e2356ff fb07981
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 22:00:00 2026 +0000

    Merge branch 'compost' into try

$ cat .git/ORIG_HEAD
e2356ff190eafe341deee7604ded777ce2fbd0c5
$ git rev-parse main
e2356ff190eafe341deee7604ded777ce2fbd0c5
$ git merge compost
Already up to date.
$ git branch --merged
  compost
  main
* try
```

A merge commit is an ordinary commit with two `parent` lines (Chapter 6). The
first parent, `HEAD^1`, is the branch you were on; the second, `HEAD^2`, is the
branch you merged (Chapter 18). Its tree is the combined result.

`git show` printed no changes. For a merge it shows a *combined diff*, only the
places where the result differs from both parents, and a merge with no conflict
has none. Chapter 17 shows the ways to see a merge's changes, and Chapter 26
reads combined diffs. `ORIG_HEAD` holds where `try` was before the merge. After
the merge, `compost` counts as merged into `try` (Chapter 23).

## The merge message

### The default message and the editor

```console
$ git switch -q -C try main
$ GIT_EDITOR=cat git merge --edit compost
Merge branch 'compost' into try
# Please enter a commit message to explain why this merge is necessary,
# especially if it merges an updated upstream into a topic branch.
#
# Lines starting with '#' will be ignored, and an empty message aborts
# the commit.
Merge made by the 'ort' strategy.
 compost.txt | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 compost.txt
```

`--edit`, or `-e`, opens the editor on the message Git proposes; `GIT_EDITOR=cat`
printed it instead. Typed at a terminal, a plain `git merge compost` does the
same, because there Git opens the editor by default. Lines starting with `#` are
dropped, and emptying the message cancels the merge commit. `--no-edit` accepts
the proposed message without asking.

Git's documentation adds that older scripts, written before merges opened an
editor, can set the environment variable `GIT_MERGE_AUTOEDIT=no` to keep the
old behaviour.

### Writing your own message

```console
$ git switch -q -C try main
$ git merge -m 'Bring in composting' compost
Merge made by the 'ort' strategy.
 compost.txt | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 compost.txt
$ git log -1 --format=%B
Bring in composting

```

`-m` gives the message directly, and then no editor opens even on a terminal.

### Listing the merged commits

```console
$ git switch -q -C try main
$ git merge --log --no-edit compost
Merge made by the 'ort' strategy.
 compost.txt | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 compost.txt
$ git log -1 --format=%B
Merge branch 'compost' into try

* compost:
  Add a compost rule
  Start composting

$ git switch -q -C try main
$ git merge --log=1 --no-edit compost
Merge made by the 'ort' strategy.
 compost.txt | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 compost.txt
$ git log -1 --format=%B
Merge branch 'compost' into try

* compost: (2 commits)
  Add a compost rule
  ...

$ git switch -q -C try main
$ git -c merge.log=true merge --no-log --no-edit compost
Merge made by the 'ort' strategy.
 compost.txt | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 compost.txt
$ git log -1 --format=%B
Merge branch 'compost' into try

```

`--log` adds the titles of the merged commits, newest first; `--log=<n>` stops
after `<n>` and says how many there were. The setting `merge.log` turns it on by
default, with `true` meaning 20 as Git's documentation says, and `--no-log`
overrides it. With `merge.branchdesc`, the branch's description is added too
(Chapter 23).

```console
$ git switch -q -C try main
$ GIT_EDITOR=cat git merge -e -m 'Bring in composting' compost
Bring in composting
# Please enter a commit message to explain why this merge is necessary,
# especially if it merges an updated upstream into a topic branch.
#
# Lines starting with '#' will be ignored, and an empty message aborts
# the commit.
Merge made by the 'ort' strategy.
 compost.txt | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 compost.txt
$ git switch -q -C try main
$ GIT_EDITOR="sed -i '1s/.*/Merge the compost work/'" git merge -e compost
Merge made by the 'ort' strategy.
 compost.txt | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 compost.txt
$ git log -1 --format=%s
Merge the compost work
$ cat ../merge-msg.txt
Merge composting

# a line starting with a hash
$ git switch -q -C try main
$ git merge -F ../merge-msg.txt compost
Merge made by the 'ort' strategy.
 compost.txt | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 compost.txt
$ git log -1 --format=%B
Merge composting

# a line starting with a hash

$ git switch -q -C try main
$ git merge -F ../merge-msg.txt --cleanup=strip compost
Merge made by the 'ort' strategy.
 compost.txt | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 compost.txt
$ git log -1 --format=%B
Merge composting

```

`-e` with `-m` opens the editor starting from your draft. The `sed` command stood
in for typing a new first line. `-F` reads the message from a file, and kept the
line starting with `#`, because no editor was involved; `--cleanup=strip`
removed it. Chapter 12 describes every `--cleanup` mode.

### The branch name in the message

```console
$ git switch -q -C try main
$ git merge --signoff --no-edit compost
Merge made by the 'ort' strategy.
 compost.txt | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 compost.txt
$ git log -1 --format=%B
Merge branch 'compost' into try

Signed-off-by: Ada Lovelace <ada@example.com>

$ git switch -q -C try main
$ git merge --into-name release --no-edit compost
Merge made by the 'ort' strategy.
 compost.txt | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 compost.txt
$ git log -1 --format=%s
Merge branch 'compost' into release
$ git switch -q -C try main
$ git -c merge.suppressDest=try merge --no-edit compost
Merge made by the 'ort' strategy.
 compost.txt | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 compost.txt
$ git log -1 --format=%s
Merge branch 'compost'
$ git switch -q main
$ git merge --no-edit compost
Merge made by the 'ort' strategy.
 compost.txt | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 compost.txt
$ git log -1 --format=%s
Merge branch 'compost'
$ git reset -q --hard ORIG_HEAD
```

`--signoff` adds a `Signed-off-by` trailer, as for `git commit` (Chapter 12).
The title names the branch merged into, "into try". `--into-name` writes another
name there, for example when merging on a temporary branch on behalf of the real
one. The setting `merge.suppressDest` lists branch names, as globs, whose name
is left out.

Merging into `main` left "into main" out without any setting. Git's
documentation says the default list is `master`; Git's source adds `main` too.
`git reset --hard ORIG_HEAD` put `main` back where it was
([Undoing a merge](#undoing-a-merge)).

> **Since Git 2.29.** `merge.suppressDest`, and `main` in its default list since
> Git 2.30. **Since Git 2.35.** `--into-name`.

## What merge prints

```console
$ git switch -q -C try main
$ git merge --no-edit compost
Merge made by the 'ort' strategy.
 compost.txt | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 compost.txt
$ git switch -q -C try main
$ git merge --no-edit -n compost
Merge made by the 'ort' strategy.
$ git switch -q -C try main
$ git merge --no-edit --no-stat compost
Merge made by the 'ort' strategy.
$ git switch -q -C try main
$ git merge --no-edit --stat compost
Merge made by the 'ort' strategy.
 compost.txt | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 compost.txt
$ git switch -q -C try main
$ git merge --no-edit --compact-summary compost
Merge made by the 'ort' strategy.
 compost.txt (new) | 3 +++
 1 file changed, 3 insertions(+)
$ git switch -q -C try main
$ git merge --no-edit --summary compost
Merge made by the 'ort' strategy.
 compost.txt | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 compost.txt
$ git switch -q -C try main
$ git -c merge.stat=compact merge --no-edit compost
Merge made by the 'ort' strategy.
 compost.txt (new) | 3 +++
 1 file changed, 3 insertions(+)
$ git switch -q -C try main
$ git -c merge.stat=false merge --no-edit compost
Merge made by the 'ort' strategy.
$ git switch -q -C try main
$ git merge --no-edit -q compost
$ git switch -q -C try main
$ git merge --no-edit -v compost
Merge made by the 'ort' strategy.
 compost.txt | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 compost.txt
$ git switch -q -C try main
$ GIT_PROGRESS_DELAY=0 git merge --no-edit --progress compost
Merge made by the 'ort' strategy.
 compost.txt | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 compost.txt
```

"Merge made by the 'ort' strategy" names the strategy that combined the files
(Chapter 27). The list below it is the change the merge made to your branch, in
the form of `git diff --stat` (Chapter 13).

| Option or setting | What is listed |
|---|---|
| `--stat`, the default, or `merge.stat=true` | files changed, with a `create mode` line for a new file |
| `-n`, `--no-stat`, or `merge.stat=false` | nothing |
| `--compact-summary`, or `merge.stat=compact` | the same list, with `(new)` in place of the extra lines |
| `--summary`, `--no-summary` | the same as `--stat` and `--no-stat`; Git's documentation marks them deprecated |

`-q` printed nothing at all. `-v` and `--progress` changed nothing for this small
merge; Git's documentation notes that not every strategy reports progress.

> **Since Git 2.51.** `--compact-summary` and `merge.stat=compact`.

## Stopping before the commit

### Merging without committing

```console
$ git switch -q -C try main
$ git merge --no-commit compost
Automatic merge went well; stopped before committing as requested
$ git status
On branch try
All conflicts fixed but you are still merging.
  (use "git commit" to conclude merge)

Changes to be committed:
	new file:   compost.txt

$ ls .git/MERGE_HEAD .git/MERGE_MSG
.git/MERGE_HEAD
.git/MERGE_MSG
$ git commit --no-edit
[try 0a39e11] Merge branch 'compost' into try
$ git log --oneline --graph -3
*   0a39e11 Merge branch 'compost' into try
|\  
| * fb07981 Add a compost rule
| * 25699ee Start composting
$ git switch -q -C try main
$ git merge --no-commit compost
Automatic merge went well; stopped before committing as requested
$ GIT_EDITOR=true git merge --continue
[try 9432838] Merge branch 'compost' into try
$ git log --oneline -1
9432838 Merge branch 'compost' into try
$ git switch -q -C try main~1
$ git merge --no-commit lettuce
Updating 8833aaa..87ebba0
Fast-forward
 plants.txt | 1 +
 water.txt  | 1 +
 2 files changed, 2 insertions(+)
$ git log --oneline -1
87ebba0 Water the lettuce
$ git switch -q -C try main~1
$ git merge --no-commit --no-ff lettuce
Automatic merge went well; stopped before committing as requested
$ git merge --abort
$ git log --oneline -1
8833aaa Add a watering plan
```

`--no-commit` does the merge, stages the result and stops, so you can test it or
change a file before recording it. `MERGE_HEAD` holds the commit being merged and
`MERGE_MSG` the proposed message. `git commit` then makes the merge commit with
both parents, and so does `git merge --continue`; `GIT_EDITOR=true` accepted the
message unchanged, as saving without editing would. `git merge --abort` gave
up instead.

A fast-forward has no merge commit to stop before, so `--no-commit` alone still
moved the branch, as Git's documentation warns. `--no-commit --no-ff` stops in
every case.

```console
$ git switch -q -C try main
$ git merge --no-commit --commit --no-edit compost
Merge made by the 'ort' strategy.
 compost.txt | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 compost.txt
$ git log --oneline -1
e3d4133 Merge branch 'compost' into try
```

`--commit` cancels an earlier `--no-commit`, which is useful when an alias or
the setting `branch.<name>.mergeOptions` supplies it.

### Squash merges

```console
$ git switch -q -C try main
$ git merge --squash compost
Automatic merge went well; stopped before committing as requested
Squash commit -- not updating HEAD
$ git status --short
A  compost.txt
$ ls .git/MERGE_HEAD; cat .git/SQUASH_MSG
ls: cannot access '.git/MERGE_HEAD': No such file or directory
Squashed commit of the following:

commit fb07981e269c316e219a3ebcd6fd50a4605bc7e9
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 14:00:00 2026 +0000

    Add a compost rule

commit 25699ee8b0b6f32744e4ec32804eb55da1f06c99
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 13:00:00 2026 +0000

    Start composting
$ git commit -q -m 'Add composting'
$ git log --oneline --graph -3
* 6f4a6d5 Add composting
* e2356ff Water tomatoes more
* 8833aaa Add a watering plan
$ git branch -d compost
error: the branch 'compost' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D compost'
hint: Disable this message with "git config set advice.forceDeleteBranch false"
$ git merge --squash --commit compost
fatal: options '--squash' and '--commit.' cannot be used together
$ git switch -q -C try main
$ git merge --squash --no-squash --no-edit compost
Merge made by the 'ort' strategy.
 compost.txt | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 compost.txt
$ git log --oneline --graph -3
*   61fb821 Merge branch 'compost' into try
|\  
| * fb07981 Add a compost rule
| * 25699ee Start composting
```

`--squash` stages the combined changes but records no merge: no `MERGE_HEAD`,
and the commit you make has one parent. `SQUASH_MSG` lists the squashed commits
as a starting message for `git commit` without `-m`. The history stays a
straight line with all of `compost`'s work in one commit.

Because no merge was recorded, `compost` does not count as merged, and
`git branch -d` refused (Chapter 23); after a squash merge, delete the branch
with `-D`. `--squash` cannot be combined with `--commit`, and `--no-squash`
cancels an earlier `--squash`.

```console
$ git switch -q -C try main~1
$ git merge --squash lettuce
Updating 8833aaa..87ebba0
Fast-forward
Squash commit -- not updating HEAD
 plants.txt | 1 +
 water.txt  | 1 +
 2 files changed, 2 insertions(+)
$ git status --short
M  plants.txt
M  water.txt
$ git log --oneline -1
8833aaa Add a watering plan
$ git reset -q --hard
```

Even where a fast-forward was possible, `--squash` only staged the changes and
did not move the branch. `git reset --hard` threw them away (Chapter 30).

## Merging several branches at once

```console
$ git switch -q -C try main
$ git merge --no-edit paths pond
Trying simple merge with paths
Trying simple merge with pond
Merge made by the 'octopus' strategy.
 paths.txt | 1 +
 pond.txt  | 1 +
 2 files changed, 2 insertions(+)
 create mode 100644 paths.txt
 create mode 100644 pond.txt
$ git log --oneline --graph -5
*-.   7642394 Merge branches 'paths' and 'pond' into try
|\ \  
| | * 72353bd Dig a pond
| * | 88f0e2c Lay a gravel path
| |/  
* / e2356ff Water tomatoes more
|/  
* 8833aaa Add a watering plan
$ git cat-file -p HEAD | head -4
tree c972dbb683cb5c005adc1d26e8fd3f73c5c27659
parent e2356ff190eafe341deee7604ded777ce2fbd0c5
parent 88f0e2cc83595d98df1c0c928f89c3b4d5e7b339
parent 72353bdfe276ff6da7b93fd36b1e725f4735b9d8
$ git switch -q -C try main
$ git merge --no-edit paths frost
Trying simple merge with paths
Trying simple merge with frost
Simple merge did not work, trying automatic merge.
Auto-merging water.txt
ERROR: content conflict in water.txt
fatal: merge program failed
Automatic merge failed; fix conflicts and then commit the result.
$ git status --short
A  paths.txt
UU water.txt
$ ls .git/MERGE_HEAD
.git/MERGE_HEAD
$ git merge --abort
$ git log --oneline -1
e2356ff Water tomatoes more
```

Naming several branches makes one merge commit with a parent for each, which Git
calls an *octopus merge*, using the `octopus` strategy. It suits several
independent branches that do not touch the same lines. `frost` conflicted with
`try`, so this one stopped with a conflict, and `--abort` cancelled it. Chapter
27 describes the octopus strategy and its limits; merging such branches one at
a time is usually easier to resolve.

## When a merge stops

```console
$ git switch -q -C try main
$ git merge frost
Auto-merging water.txt
CONFLICT (content): Merge conflict in water.txt
Automatic merge failed; fix conflicts and then commit the result.
$ git status
On branch try
You have unmerged paths.
  (fix conflicts and run "git commit")
  (use "git merge --abort" to abort the merge)

Unmerged paths:
  (use "git add <file>..." to mark resolution)
	both modified:   water.txt

no changes added to commit (use "git add" and/or "git commit -a")
$ ls .git/MERGE_HEAD
.git/MERGE_HEAD
$ git merge compost
error: Merging is not possible because you have unmerged files.
hint: Fix them up in the work tree, and then use 'git add/rm <file>'
hint: as appropriate to mark resolution and make a commit.
fatal: Exiting because of an unresolved conflict.
$ git commit -q -m 'Try to commit'
error: Committing is not possible because you have unmerged files.
hint: Fix them up in the work tree, and then use 'git add/rm <file>'
hint: as appropriate to mark resolution and make a commit.
fatal: Exiting because of an unresolved conflict.
U	water.txt
$ git merge --abort
$ git status --short
```

Both branches changed the tomato line of `water.txt`, so Git could not combine
them. The merge is *in progress*: `MERGE_HEAD` records `frost`, `water.txt` holds
conflict markers, and nothing is committed. Other merges and commits are refused
until you finish or cancel. `git merge --abort` put everything back as it was
before the merge.

> **Careful.** Git's documentation warns that `--abort` cannot always rebuild
> uncommitted changes you had before the merge, especially ones changed again
> during it. Commit or stash your work before merging.

```console
$ git merge frost
Auto-merging water.txt
CONFLICT (content): Merge conflict in water.txt
Automatic merge failed; fix conflicts and then commit the result.
$ printf 'tomato: every other day\nbasil: daily\n' > water.txt
$ git merge --continue
error: Committing is not possible because you have unmerged files.
hint: Fix them up in the work tree, and then use 'git add/rm <file>'
hint: as appropriate to mark resolution and make a commit.
fatal: Exiting because of an unresolved conflict.
U	water.txt
$ git add water.txt
$ GIT_EDITOR=cat git merge --continue
Merge branch 'frost' into try

# Conflicts:
#	water.txt
#
# It looks like you may be committing a merge.
# If this is not correct, please run
#	git update-ref -d MERGE_HEAD
# and try again.


# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
#
# On branch try
# All conflicts fixed but you are still merging.
#
# Changes to be committed:
#	modified:   water.txt
#
[try 999b5ef] Merge branch 'frost' into try
$ git log --oneline --graph -4
*   999b5ef Merge branch 'frost' into try
|\  
| * c53233d Water less in frost
* | e2356ff Water tomatoes more
|/  
* 8833aaa Add a watering plan
```

Here the file was written with the line wanted, but a file counts as resolved
only once it is staged with `git add`. After that, `git merge --continue` made
the merge commit, opening the editor on a message that lists the conflicted
files. Chapter 26 shows how to read and resolve conflicts properly.

```console
$ git switch -q -C try main
$ git merge frost
Auto-merging water.txt
CONFLICT (content): Merge conflict in water.txt
Automatic merge failed; fix conflicts and then commit the result.
$ git merge --quit
$ git status --short
UU water.txt
$ ls .git/MERGE_HEAD
ls: cannot access '.git/MERGE_HEAD': No such file or directory
$ git reset -q --hard
$ git merge --abort
fatal: There is no merge to abort (MERGE_HEAD missing).
$ git merge --continue
fatal: There is no merge in progress (MERGE_HEAD missing).
```

`--quit` forgets that a merge is in progress but leaves the files and index as
they are, conflict and all. Tried here, `git commit` was still refused until the
file was resolved and staged, and the commit then had one parent, because Git no
longer knew a merge was under way. It is for keeping the partly merged files for
some other use.
`git reset --hard` cleaned up, and with no merge in progress, `--abort` and
`--continue` have nothing to act on.

## Uncommitted changes

In each example here, `plants.txt` or another file has an uncommitted edit
before the merge starts.

```console
$ git switch -q -C try main
$ git status --short
 M plants.txt
?? compost.txt
$ git merge --no-edit compost
error: The following untracked working tree files would be overwritten by merge:
	compost.txt
Please move or remove them before you merge.
Aborting
Merge with strategy ort failed.
$ rm compost.txt
$ git merge --no-edit compost
Merge made by the 'ort' strategy.
 compost.txt | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 compost.txt
$ git status --short
 M plants.txt
$ git switch -q -C try main
$ git merge --no-edit lettuce
error: Your local changes to the following files would be overwritten by merge:
	plants.txt
Please commit your changes or stash them before you merge.
Aborting
Merge with strategy ort failed.
$ git -c merge.autoStash=true merge --no-autostash --no-edit lettuce
error: Your local changes to the following files would be overwritten by merge:
	plants.txt
Please commit your changes or stash them before you merge.
Aborting
Merge with strategy ort failed.
$ git merge --no-edit --autostash lettuce
Created autostash: 1826054
Auto-merging water.txt
Merge made by the 'ort' strategy.
 plants.txt | 1 +
 water.txt  | 1 +
 2 files changed, 2 insertions(+)
Applied autostash.
$ git status --short
 M plants.txt
$ git stash list
$ git restore plants.txt
```

| Uncommitted change | Merge |
|---|---|
| an edit to a file the merge does not touch | allowed; the edit stays |
| an edit to a file the merge changes | refused |
| an untracked file where the merge adds one | refused |
| anything staged | refused, whatever the file |

`compost` did not change `plants.txt`, so the edit to it survived the merge.
`lettuce` does, and plain `git merge` refused, as it would even if the two
edits could combine. `--autostash` put the edit aside in a stash (Chapter 55),
merged, and applied it again; `merge.autoStash=true` makes that the default and
`--no-autostash` turns it off.

```console
$ git switch -q -C try main
$ git merge --no-edit --autostash lettuce
Created autostash: f9ddecf
Auto-merging water.txt
Merge made by the 'ort' strategy.
 plants.txt | 1 +
 water.txt  | 1 +
 2 files changed, 2 insertions(+)
Your local changes are stashed, however applying them
resulted in conflicts.  You can either resolve the conflicts
and then discard the stash with "git stash drop", or, if you
do not want to resolve them now, run "git reset --hard" and
apply the local changes later by running "git stash pop".
$ git status --short
UU plants.txt
$ git stash list
stash@{0}: autostash
$ git reset -q --hard
$ git stash drop
Dropped refs/stash@{0} (f9ddecf0770708c3e3fa52ee3d17f746e5a24ee0)
```

This time the edit added `sage` at the end of `plants.txt`, where `lettuce` added
its line. The merge commit was made, but applying the stash conflicted, so the
stash was kept for you. Here it was thrown away: `git reset --hard` and
`git stash drop` lost the edit for good.

```console
$ git switch -q -C try main
$ git add README.md
$ git merge --no-edit compost
error: Your local changes to the following files would be overwritten by merge:
  README.md
Merge with strategy ort failed.
$ git restore --staged --worktree README.md
$ git merge --autostash frost
Created autostash: 39e8baa
Auto-merging water.txt
CONFLICT (content): Merge conflict in water.txt
Automatic merge failed; fix conflicts and then commit the result.
When finished, apply stashed changes with `git stash pop`
$ git status --short
UU water.txt
$ git stash list
$ git merge --abort
Applied autostash.
$ git status --short
 M plants.txt
$ git stash list
$ git merge --autostash frost
Created autostash: 39e8baa
Auto-merging water.txt
CONFLICT (content): Merge conflict in water.txt
Automatic merge failed; fix conflicts and then commit the result.
When finished, apply stashed changes with `git stash pop`
$ printf 'tomato: every other day\nbasil: daily\n' > water.txt
$ git add water.txt
$ GIT_EDITOR=true git merge --continue
[try 61edab3] Merge branch 'frost' into try
Applied autostash.
$ git status --short
 M plants.txt
$ git switch -q -C try main
$ git restore plants.txt
$ git merge --no-edit pond
error: The following untracked working tree files would be overwritten by merge:
	pond.txt
Please move or remove them before you merge.
Aborting
Merge with strategy ort failed.
$ rm pond.txt
```

A staged edit to `README.md` was enough to refuse a merge that never touches
`README.md`: Git's documentation says the index must match `HEAD` before a merge,
so that unrelated changes do not end up in the merge commit.

When a merge with `--autostash` stops on a conflict, the stash is not in
`git stash list`; Git's documentation says it is kept in the ref
`MERGE_AUTOSTASH`. `git merge --abort` applied it again. Finishing the merge
applied it too, although the message suggested `git stash pop`: the commit made
by `git merge --continue` was followed by "Applied autostash".

## What you can merge

```console
$ git switch -q main
$ git branch -vv --list main
* main e2356ff [origin/main: ahead 1, behind 1] Water tomatoes more
$ git merge --no-edit
Merge made by the 'ort' strategy.
 tools.txt | 2 ++
 1 file changed, 2 insertions(+)
 create mode 100644 tools.txt
$ git log --oneline --graph -4
*   a571e42 Merge remote-tracking branch 'refs/remotes/origin/main'
|\  
| * b197e90 List the tools
* | e2356ff Water tomatoes more
|/  
* 8833aaa Add a watering plan
$ git reset -q --hard ORIG_HEAD
$ git -c merge.defaultToUpstream=false merge
fatal: No commit specified and merge.defaultToUpstream not set.
$ git switch -q -C try main
$ git merge
fatal: No remote for the current branch.
$ git merge --no-edit origin/main
Merge made by the 'ort' strategy.
 tools.txt | 2 ++
 1 file changed, 2 insertions(+)
 create mode 100644 tools.txt
$ git log -1 --format=%s
Merge remote-tracking branch 'origin/main' into try
```

With no commit named, `git merge` merges the current branch's upstream, here
`origin/main`, as last fetched; `merge.defaultToUpstream=false` turns that off,
and a branch without an upstream has nothing to merge. Merging `origin/main` by
name is the same, apart from the shorter name in the message. `git fetch`
followed by this merge is what `git pull` does (Chapter 42), which also covers
merging `FETCH_HEAD`.

```console
$ git tag -a -m 'Spring planting' spring main
$ git switch -q -C try lettuce
$ git merge --no-edit spring
Auto-merging water.txt
Merge made by the 'ort' strategy.
 README.md | 1 +
 water.txt | 2 +-
 2 files changed, 2 insertions(+), 1 deletion(-)
$ git log -1 --format=%B
Merge tag 'spring' into try

Spring planting

$ git switch -q -C try main~1
$ git merge --no-edit spring
Updating 8833aaa..e2356ff
Fast-forward
 README.md | 1 +
 water.txt | 2 +-
 2 files changed, 2 insertions(+), 1 deletion(-)
$ git log --oneline -1
e2356ff Water tomatoes more
$ git merge nosuch
merge: nosuch - not something we can merge
$ git merge HEAD
Already up to date.
$ git merge main~2
Already up to date.
```

Merging an annotated tag puts the tag's message into the merge message. Where a
fast-forward was possible, it fast-forwarded. A section of Git's documentation
says merging an annotated tag always creates a merge commit, but its description
of `--ff` limits that to a tag not stored in its usual place under `refs/tags/`,
and this tag, which is, fast-forwarded. Any commit can be merged; one already in
the branch's history is "Already up to date".

```console
$ git switch -q --detach main
$ git merge --no-edit compost
Merge made by the 'ort' strategy.
 compost.txt | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 compost.txt
$ git log --oneline --graph -3
*   edb12b4 Merge branch 'compost' into HEAD
|\  
| * fb07981 Add a compost rule
| * 25699ee Start composting
$ git switch -q -C try main
$ git log --oneline wiki
5a2d0c5 Start a wiki
$ git merge --no-edit wiki
fatal: refusing to merge unrelated histories
$ git merge --allow-unrelated-histories --no-edit wiki
Merge made by the 'ort' strategy.
 wiki.txt | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 wiki.txt
$ git log --oneline --graph -5
*   991d495 Merge branch 'wiki' into try
|\  
| * 5a2d0c5 Start a wiki
* e2356ff Water tomatoes more
* 8833aaa Add a watering plan
* f7427e3 Start the planner
$ ls
README.md
plants.txt
water.txt
wiki.txt
```

A detached `HEAD` can be merged into; the merge commit is on no branch
(Chapter 24). `wiki` is an orphan branch (Chapter 24) with no commit in common
with `try`, so there is no merge base, and Git refused. `--allow-unrelated-histories`
merged the two anyway, for combining two projects that started separately; Git's
documentation says no setting will ever make this the default.

## Undoing a merge

```console
$ git switch -q -C try main
$ git merge --no-edit compost
Merge made by the 'ort' strategy.
 compost.txt | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 compost.txt
$ git reset --hard ORIG_HEAD
HEAD is now at e2356ff Water tomatoes more
$ git merge --no-edit compost
Merge made by the 'ort' strategy.
 compost.txt | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 compost.txt
$ git revert -m 1 --no-edit HEAD
[try 704cf91] Revert "Merge branch 'compost' into try"
 Date: Wed Jan 7 18:00:00 2026 +0000
 1 file changed, 3 deletions(-)
 delete mode 100644 compost.txt
$ git log --oneline --graph -4
* 704cf91 Revert "Merge branch 'compost' into try"
*   432fb53 Merge branch 'compost' into try
|\  
| * fb07981 Add a compost rule
| * 25699ee Start composting
$ ls
README.md
plants.txt
water.txt
$ git merge --no-edit compost
Already up to date.
```

| Undo | What happens | Use when |
|---|---|---|
| `git reset --hard ORIG_HEAD` | the branch goes back to before the merge, which disappears from it (Chapter 30) | the merge is only in your repository |
| `git revert -m 1 <merge>` | a new commit undoes the merge's changes, keeping history (Chapter 31) | the merge is already pushed |

`ORIG_HEAD` changes with the next command that sets it, so use it straight after
the merge. `-m 1` tells `revert` to undo the merge relative to its first parent,
the branch merged into.

> **Careful.** After a revert, the merged commits are still in the branch's
> history, so merging the branch again said "Already up to date" and brought
> nothing back. Chapter 31 explains how to merge it again, by reverting the
> revert.

## merge and its neighbours

```console
$ git merge-base main compost
8833aaa05307e9d18da624d006583cfa9cbe465c
$ git merge-tree --write-tree main compost
e7f1f03325886b646499f4c098578ca1ac0d6b8c
$ git merge-tree --write-tree main frost; echo "exit $?"
7ef59c7ef24f545b7e19c4b8a1a40b5cc5f5e915
100644 9dd7825396bc4a6069464d1338ecdd3b22575de5 1	water.txt
100644 39dd388b4cee940fdbb6ec66503b0a555956f4e2 2	water.txt
100644 b29ee66c63c29be2ab13d19e0933aa23ab21954d 3	water.txt

Auto-merging water.txt
CONFLICT (content): Merge conflict in water.txt
exit 1
$ git switch -q -C try main~1
$ git -c branch.try.mergeOptions=--no-ff merge --no-edit lettuce
Merge made by the 'ort' strategy.
 plants.txt | 1 +
 water.txt  | 1 +
 2 files changed, 2 insertions(+)
$ git log --oneline --graph -3
*   224f8a2 Merge branch 'lettuce' into try
|\  
| * 87ebba0 Water the lettuce
| * e91be24 Plant lettuce
|/  
```

`git merge-base` prints the merge base (Chapter 76). `git merge-tree --write-tree`
does a merge without touching your branch, index or files: it prints the tree the
merge would produce, and for a conflict exits with 1 and lists the conflicted
files with their versions, the numbered stages Chapter 26 explains. It is the
way to ask "would this conflict?" in a script. The setting
`branch.<name>.mergeOptions` gives one branch default options, here `--no-ff`
for `try`.

> **Since Git 2.38.** `git merge-tree --write-tree`.

| Command | Result | Use it when |
|---|---|---|
| `git merge` | a merge commit, or a fast-forward; history shows the branch | you want the branch's history kept as it happened |
| `git merge --squash` | one ordinary commit with all the changes | you want one commit and do not need the branch's commits |
| `git rebase` | the branch's commits copied on top of the other branch, a straight line (Chapter 33) | you want linear history before merging or sharing |
| `git cherry-pick` | copies of chosen commits (Chapter 32) | you want only some commits |
| `git pull` | `git fetch` then merge or rebase (Chapter 42) | you want the server's changes in your branch |

## The settings

| Setting | Effect |
|---|---|
| `merge.ff` | `false` acts as `--no-ff`, `only` as `--ff-only` |
| `merge.log` | Add up to this many merged commit titles, `true` meaning 20 |
| `merge.branchdesc` | Add branch descriptions to the message, with `--log` (Chapter 23) |
| `merge.suppressDest` | Branch-name globs left out of "into ..." in the title |
| `merge.stat` | `true`, `false` or `compact`: what to list after the merge |
| `merge.autoStash` | Act as `--autostash` |
| `merge.defaultToUpstream` | Whether `git merge` with no commit merges the upstream; `true` by default |
| `merge.verifySignatures` | Act as `--verify-signatures` (Chapter 68) |
| `merge.conflictStyle` | How conflicts are written into files (Chapter 26) |
| `merge.renames`, `merge.directoryRenames`, `merge.renameLimit`, `merge.renormalize`, `merge.verbosity` | How files are combined (Chapter 27) |
| `merge.tool` | The tool `git mergetool` starts (Chapter 26) |
| `branch.<name>.mergeOptions` | Default options for merging into that branch |
| `advice.diverging` | Whether `--ff-only` explains what to do when it fails |
