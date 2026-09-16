# Chapter 32. cherry-pick

## What it is

`git cherry-pick` takes the change one commit made and applies it here, as a
new commit. The original stays where it is; what you get is a copy, with a
different name.

It answers one question: *how do I get that one commit onto this branch,
without the rest of its branch?*

The everyday use is a backport: a fix is on `main`, a release branch needs it,
and merging `main` would bring in everything else. It is also how you rescue a
commit made on the wrong branch, and how a rebase works underneath — a rebase
is a run of cherry-picks onto a new base (Chapter 33).

| Term | Means |
|---|---|
| *cherry-pick* | apply the change a commit introduced, and record it as a new commit here |
| *the sequencer* | the state in `.git/sequencer` while Git works through a list of commits, so it can be continued or abandoned |
| *`CHERRY_PICK_HEAD`* | while a cherry-pick is stopped, the commit being applied |
| *patch id* | a hash of a change with line numbers ignored, which lets Git recognise the same change in two differently named commits |
| *empty commit* | one whose tree is the same as its parent's, so it changes nothing |

Nothing here rewrites history: a cherry-pick only adds. It earns its place in
this part because the copy has a different hash from the original, which is the
same fact that makes a rebase a rewrite (Chapter 28), and because the same
change existing twice is something you then have to reason about.

`git cherry-pick` and `git revert` (Chapter 31) are one command wearing two
faces: one applies a commit's change forwards, the other backwards, and they
share the sequencer and most options.

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What does `git cherry-pick` copy — the commit, or its change?](#what-it-is)
- [Does the commit move, or is it in two places now?](#what-it-is)

**[Synopsis](#synopsis)**

- [What can I type after `git cherry-pick`?](#synopsis)

**[Options at a glance](#options-at-a-glance)**

- [Which options does cherry-pick take, and where is each one shown?](#options-at-a-glance)

**[The example repository](#the-example-repository)**

- [What repository do the examples use?](#the-example-repository)

**[Copying one commit](#copying-one-commit)**

- [How do I take one commit from another branch without merging the branch?](#copying-one-commit)
- [Do I have to be on a particular branch first?](#copying-one-commit)

**[What is kept and what changes](#what-is-kept-and-what-changes)**

- [The copy has a different hash. What else is different?](#what-is-kept-and-what-changes)
- [Whose name is on the copy, mine or the original author's?](#what-is-kept-and-what-changes)
- [Does the copy know where it came from?](#what-is-kept-and-what-changes)

**[Copying several commits](#copying-several-commits)**

- [How do I copy three commits at once?](#copying-several-commits)
- [Are they applied in the order I typed them?](#copying-several-commits)
- [Why does `git cherry-pick A..B` not include A?](#a-range)
- [How do I copy everything the other branch has that mine does not?](#everything-the-other-branch-has-that-this-one-does-not)

**[Recording where the commit came from](#recording-where-the-commit-came-from)**

- [How do I make the copy say which commit it came from?](#recording-where-the-commit-came-from)
- [What does `-r` do — it looks like it undoes `-x`?](#recording-where-the-commit-came-from)

**[Editing the message](#editing-the-message)**

- [How do I change the message while copying?](#editing-the-message)
- [What is this "It looks like you may be committing a cherry-pick" block?](#editing-the-message)

**[Copying without committing](#copying-without-committing)**

- [How do I copy several commits into one commit?](#copying-without-committing)

**[Signing off](#signing-off)**

- [How do I add a `Signed-off-by` line?](#signing-off)

**[When the commit is already a descendant](#when-the-commit-is-already-a-descendant)**

- [What does `--ff` do, and when would I want it?](#when-the-commit-is-already-a-descendant)

**[A commit that is already here](#a-commit-that-is-already-here)**

- ["The previous cherry-pick is now empty" — what do I do?](#a-commit-that-is-already-here)
- [What is the difference between `--empty=drop`, `--empty=keep` and `--empty=stop`?](#dropping-it-instead)

**[A commit that was empty to start with](#a-commit-that-was-empty-to-start-with)**

- [How do I copy a commit that was empty in the first place?](#a-commit-that-was-empty-to-start-with)
- [What about a commit with an empty message?](#a-commit-that-was-empty-to-start-with)

**[Copying a merge](#copying-a-merge)**

- [Can I cherry-pick a merge commit?](#copying-a-merge)
- [Which parent number do I give, and what does the result contain?](#copying-a-merge)

**[When a cherry-pick conflicts](#when-a-cherry-pick-conflicts)**

- [The cherry-pick stopped with a conflict. What do I do?](#when-a-cherry-pick-conflicts)
- [Which side is "ours" here?](#when-a-cherry-pick-conflicts)
- [What is `CHERRY_PICK_HEAD`?](#when-a-cherry-pick-conflicts)
- [How do I see what the commit being applied actually changes?](#when-a-cherry-pick-conflicts)
- [I resolved it. Which command finishes?](#finishing-the-cherry-pick)

**[Abandoning it](#abandoning-it)**

- [How do I skip this commit and carry on with the rest?](#abandoning-it)
- [`--abort` or `--quit` — which do I want?](#abandoning-it)
- [Git still thinks a cherry-pick is in progress. How do I clear it?](#abandoning-it)

**[Taking a side automatically](#taking-a-side-automatically)**

- [Can I make a cherry-pick prefer one side when it conflicts?](#taking-a-side-automatically)

**[Another strategy](#another-strategy)**

- [Can I use a different merge strategy?](#another-strategy)

**[Finding out what has already been copied](#finding-out-what-has-already-been-copied)**

- [How do I tell whether this commit is already on the other branch under a different hash?](#finding-out-what-has-already-been-copied)
- [What do the `+` and `-` in `git cherry` mean?](#finding-out-what-has-already-been-copied)
- [How does Git recognise a copy when the hash is different?](#finding-out-what-has-already-been-copied)

**[When cherry-pick refuses](#when-cherry-pick-refuses)**

- ["your local changes would be overwritten" — what do I do?](#when-cherry-pick-refuses)
- [Can I cherry-pick while a merge is unfinished?](#when-cherry-pick-refuses)
- [What happens on a branch with no commits yet?](#onto-a-branch-with-nothing-in-it)

**[cherry-pick and its neighbours](#cherry-pick-and-its-neighbours)**

- [Should I cherry-pick or merge?](#cherry-pick-and-its-neighbours)
- [Is cherry-picking a whole branch the same as rebasing it?](#cherry-pick-and-its-neighbours)
- [How is this different from `git format-patch` and `git am`?](#cherry-pick-and-its-neighbours)

**[The settings](#the-settings)**

- [Which settings change what cherry-pick does?](#the-settings)

</details>

## Synopsis

```
git cherry-pick [--edit] [-n] [-m <parent-number>] [-s] [-x] [--ff]
                [-S[<keyid>]] <commit>...
git cherry-pick (--continue | --skip | --abort | --quit)
```

| Part | Means |
|---|---|
| `<commit>...` | the commits to copy: names, hashes or a range, applied in the order given |
| `<parent-number>` | for a merge, which parent's side the change is measured against, counting from 1 |

| Command | Does |
|---|---|
| `git cherry-pick <commit>` | Apply that commit's change here as a new commit |
| `git cherry-pick <a> <b>` | Apply both, in that order, as two commits |
| `git cherry-pick <a>..<b>` | Apply every commit after `<a>` up to `<b>`, oldest first |
| `git cherry-pick -n <commit>...` | Apply them to the working tree and index without committing |
| `git cherry-pick --continue` | Carry on after resolving a conflict |
| `git cherry-pick --skip` | Give up on the current commit and carry on with the rest |
| `git cherry-pick --abort` | Cancel, and put everything back as it was |
| `git cherry-pick --quit` | Forget the cherry-pick is in progress, leaving the files as they are |

## Options at a glance

| Option | Does | Covered in |
|---|---|---|
| `-x` | Add a `(cherry picked from commit ...)` line to the message | [Recording where the commit came from](#recording-where-the-commit-came-from) |
| `-r` | Nothing; it used to turn `-x` off | [Recording where the commit came from](#recording-where-the-commit-came-from) |
| `-e`, `--edit` | Open an editor on the message | [Editing the message](#editing-the-message) |
| `--cleanup=<mode>` | How the message is tidied; the modes are in Chapter 12 | Chapter 12 |
| `-n`, `--no-commit` | Apply the change without committing | [Copying without committing](#copying-without-committing) |
| `-s`, `--signoff` | Add a `Signed-off-by` trailer | [Signing off](#signing-off) |
| `--ff` | Fast-forward instead of copying, when the commit's parent is `HEAD` | [When the commit is already a descendant](#when-the-commit-is-already-a-descendant) |
| `-m <parent-number>`, `--mainline <parent-number>` | Copy a merge, relative to that parent | [Copying a merge](#copying-a-merge) |
| `--empty=drop` | Silently drop a commit whose change is already here | [Dropping it instead](#dropping-it-instead) |
| `--empty=keep` | Keep it as an empty commit | [Dropping it instead](#dropping-it-instead) |
| `--empty=stop` | Stop and ask, the default | [A commit that is already here](#a-commit-that-is-already-here) |
| `--allow-empty` | Copy a commit that was empty to begin with | [A commit that was empty to start with](#a-commit-that-was-empty-to-start-with) |
| `--allow-empty-message` | Copy a commit whose message is empty | [A commit that was empty to start with](#a-commit-that-was-empty-to-start-with) |
| `--keep-redundant-commits` | The deprecated spelling of `--empty=keep` | [Dropping it instead](#dropping-it-instead) |
| `--strategy=<strategy>` | Use another merge strategy | [Another strategy](#another-strategy) |
| `-X<option>`, `--strategy-option=<option>` | Pass an option to the merge strategy | [Taking a side automatically](#taking-a-side-automatically) |
| `--rerere-autoupdate`, `--no-rerere-autoupdate` | Stage resolutions rerere remembers, or leave them unstaged | Chapter 26 |
| `-S[<keyid>]`, `--gpg-sign[=<keyid>]`, `--no-gpg-sign` | Sign the new commit | Chapter 68 |
| `--continue`, `--skip`, `--abort`, `--quit` | Work through a stopped cherry-pick | [Abandoning it](#abandoning-it) |

<!-- no-example: --allow-empty-message  the commits in the example repository all
     have messages; the option is the message-shaped twin of --allow-empty,
     which is demonstrated, and it behaves the same way -->
<!-- no-example: --keep-redundant-commits  Git's documentation calls it a
     deprecated synonym for --empty=keep, which is demonstrated in the same
     section; showing both would teach the spelling being retired -->

## The example repository

```console
$ git log --oneline --graph --all --decorate
*   5747851 (HEAD -> main) Merge branch 'colour'
|\  
| * ecd5de4 (colour) Add colours
* | c1df1b6 Say what it counts
|/  
* 63b7adc Add the help text
* bb75b71 Fix the crash on an empty line
| * ca5345d (release) Prepare release 1.0
|/  
* 93f4d71 Add the parser
* 9217863 Start the tool
$ git show --stat --oneline main~3
bb75b71 Fix the crash on an empty line
 parser.py | 2 ++
 1 file changed, 2 insertions(+)
```

A command-line tool. `release` forked at `Add the parser` and has one commit of
its own; `main` has carried on with a bug fix, two commits about the help text
and a merge. `main~3`, `Fix the crash on an empty line`, is the commit the
release branch wants and most examples copy.

Every example starts with `git switch -C try release`, a scratch branch at
`release` (Chapter 24), so each begins from the same place.

## Copying one commit

```console
$ git switch -q -C try release
$ git log --oneline -2
ca5345d Prepare release 1.0
93f4d71 Add the parser
$ git cherry-pick main~3
[try bb31cda] Fix the crash on an empty line
 Date: Mon Jan 5 12:00:00 2026 +0000
 1 file changed, 2 insertions(+)
$ git log --oneline -2
bb31cda Fix the crash on an empty line
ca5345d Prepare release 1.0
$ cat parser.py
def parse(line):
    if line is None:
        return []
    return line.split()
```

One commit named, one commit added to the branch you are on. Nothing about
`main` changed, and nothing else from `main` came across: `help.txt` and
`colour.py` are not here.

You have to be on the branch that is to receive the copy. `git cherry-pick` has
no "onto" argument; it always applies to `HEAD`.

## What is kept and what changes

```console
$ git log -1 --pretty=fuller
commit bb31cda54c38c291e04fa0cab1d2109708171bf3
Author:     Ada Lovelace <ada@example.com>
AuthorDate: Mon Jan 5 12:00:00 2026 +0000
Commit:     Ada Lovelace <ada@example.com>
CommitDate: Mon Jan 5 17:00:00 2026 +0000

    Fix the crash on an empty line
$ git log -1 --pretty=fuller main~3
commit bb75b715d925538f126929331bf65cc0a1cc21b7
Author:     Ada Lovelace <ada@example.com>
AuthorDate: Mon Jan 5 12:00:00 2026 +0000
Commit:     Ada Lovelace <ada@example.com>
CommitDate: Mon Jan 5 12:00:00 2026 +0000

    Fix the crash on an empty line
```

| Part of the commit | In the copy |
|---|---|
| the commit's own name | new: different parent, different committer date |
| the message | the same |
| the author and author date | the same, so the copy still credits whoever wrote it |
| the committer and committer date | you, now |
| the parent | wherever you are |

Nothing in the copy records where it came from. That is what `-x` is for
([Recording where the commit came from](#recording-where-the-commit-came-from)),
and without it only the identical message and author suggest a relationship,
which is why [Finding out what has already been
copied](#finding-out-what-has-already-been-copied) exists.

```console
$ git diff main~3 HEAD
diff --git a/VERSION b/VERSION
new file mode 100644
index 0000000..d3827e7
--- /dev/null
+++ b/VERSION
@@ -0,0 +1 @@
+1.0
```

The two trees differ only by `VERSION`, the file the release branch added. The
copy's *change* is the same as the original's; what differs is the history
underneath it.

## Copying several commits

```console
$ git switch -q -C try release
$ git cherry-pick main~3 main~2
[try 2344f16] Fix the crash on an empty line
 Date: Mon Jan 5 12:00:00 2026 +0000
 1 file changed, 2 insertions(+)
[try 4380b20] Add the help text
 Date: Mon Jan 5 13:00:00 2026 +0000
 1 file changed, 1 insertion(+)
 create mode 100644 help.txt
$ git log --oneline -3
4380b20 Add the help text
2344f16 Fix the crash on an empty line
ca5345d Prepare release 1.0
```

Each commit named becomes its own commit here, applied in the order you wrote
them, oldest first if you write them that way. If one of them fails, the ones
before it are already committed and Git stops there — see [Abandoning
it](#abandoning-it).

### A range

```console
$ git switch -q -C try release
$ git cherry-pick main~4..main~1
[try f6a4e73] Fix the crash on an empty line
 Date: Mon Jan 5 12:00:00 2026 +0000
 1 file changed, 2 insertions(+)
[try b8b837e] Add the help text
 Date: Mon Jan 5 13:00:00 2026 +0000
 1 file changed, 1 insertion(+)
 create mode 100644 help.txt
[try 9f3a658] Say what it counts
 Date: Mon Jan 5 14:00:00 2026 +0000
 1 file changed, 1 insertion(+)
$ git log --oneline -4
9f3a658 Say what it counts
b8b837e Add the help text
f6a4e73 Fix the crash on an empty line
ca5345d Prepare release 1.0
```

`A..B` is "reachable from B but not from A" (Chapter 18), so the commit `A`
itself is *not* copied — `main~4..main~1` gave three commits, starting with
`main~3`. To include `main~4`, write `main~5..main~1`.

A range is applied oldest first, which is the order they were written in and
the only order that can work: each one expects the ones before it. That is the
opposite of `git revert`, which works newest first (Chapter 31).

### Everything the other branch has that this one does not

```console
$ git switch -q -C try release
$ git cherry-pick ..main~1
[try a010cec] Fix the crash on an empty line
 Date: Mon Jan 5 12:00:00 2026 +0000
 1 file changed, 2 insertions(+)
[try 5697992] Add the help text
 Date: Mon Jan 5 13:00:00 2026 +0000
 1 file changed, 1 insertion(+)
 create mode 100644 help.txt
[try 18ea042] Say what it counts
 Date: Mon Jan 5 14:00:00 2026 +0000
 1 file changed, 1 insertion(+)
$ git log --oneline -4
18ea042 Say what it counts
5697992 Add the help text
a010cec Fix the crash on an empty line
ca5345d Prepare release 1.0
```

`..main~1` is `HEAD..main~1`: everything in `main~1` that is not already here.
It is the shape to reach for when the question is "bring over what we are
missing", and it copies nothing that is already on this branch by ancestry.

> **Careful.** Ancestry is not the same as content. A commit that was already
> cherry-picked here under a different hash is *not* an ancestor of `main~1`,
> so this form will copy it again. [Finding out what has already been
> copied](#finding-out-what-has-already-been-copied) is how to see that coming.

## Recording where the commit came from

```console
$ git switch -q -C try release
$ git cherry-pick -x main~3
[try ec7dadc] Fix the crash on an empty line
 Date: Mon Jan 5 12:00:00 2026 +0000
 1 file changed, 2 insertions(+)
$ git log -1 --format=%B
Fix the crash on an empty line

(cherry picked from commit bb75b715d925538f126929331bf65cc0a1cc21b7)
```

`-x` appends a line naming the original. Git's documentation is specific about
when to use it: between branches other people can see, such as backporting a
fix from development to a maintenance branch, where knowing the origin helps.
Not from a private branch, where the hash means nothing to anyone else.

The line is added only for cherry-picks that apply without conflict.

`-r` does nothing at all. It used to turn `-x` off, back when `-x` was the
default; Git's documentation still lists it, marked as a no-op, so that old
scripts keep working.

## Editing the message

```console
$ git switch -q -C try release
$ GIT_EDITOR=cat git cherry-pick -e main~3
Fix the crash on an empty line
#
# It looks like you may be committing a cherry-pick.
# If this is not correct, please run
#	git update-ref -d CHERRY_PICK_HEAD
# and try again.


# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
#
# Date:      Mon Jan 5 12:00:00 2026 +0000
#
# On branch try
# You are currently cherry-picking commit bb75b71.
#
# Changes to be committed:
#	modified:   parser.py
#
[try 1eaf805] Fix the crash on an empty line
 Date: Mon Jan 5 12:00:00 2026 +0000
 1 file changed, 2 insertions(+)
$ git log -1 --format=%s
Fix the crash on an empty line
```

Without `-e`, the original message is used as it stands. With it, the editor
opens on that message first — which is where to add a line explaining that this
is a backport, or to fix a subject that made sense on `main` and does not here.

The `It looks like you may be committing a cherry-pick` block is Git covering
itself: `CHERRY_PICK_HEAD` exists, so if you reached this editor by running
`git commit` by hand rather than by cherry-picking, it tells you how to clear
the flag. All of it is stripped from the stored message.

`GIT_EDITOR=cat` stands for your editor opening; `cat` prints the file and
accepts it unchanged.

## Copying without committing

```console
$ git switch -q -C try release
$ git cherry-pick -n main~3 main~2
$ git status --short
A  help.txt
M  parser.py
$ git commit -q -m 'Backport the crash fix and the help text' && git log --oneline -2
c31d803 Backport the crash fix and the help text
ca5345d Prepare release 1.0
```

`-n` applies every named commit to the working tree and the index and stops, so
several commits become one commit with a message you write. The index does not
have to be clean when you start: as Git's documentation puts it, the
cherry-pick is done against the beginning state of your index.

It is also the way to copy a commit and then adjust the result — take the fix,
drop the part that does not apply here, and commit what is left.

## Signing off

```console
$ git switch -q -C try release
$ git cherry-pick -s main~3 && git log -1 --format=%B
[try dca301a] Fix the crash on an empty line
 Date: Mon Jan 5 12:00:00 2026 +0000
 1 file changed, 2 insertions(+)
Fix the crash on an empty line

Signed-off-by: Ada Lovelace <ada@example.com>
```

`-s` adds the trailer that records who is passing the change on (Chapter 53).
On a backport it is the usual way to say who did the backporting, since the
author line still names whoever wrote the original.

## When the commit is already a descendant

```console
$ git switch -q -C try release
$ git cherry-pick --ff main~3 && git log --oneline -2
[try 93c9e5b] Fix the crash on an empty line
 Date: Mon Jan 5 12:00:00 2026 +0000
 1 file changed, 2 insertions(+)
93c9e5b Fix the crash on an empty line
ca5345d Prepare release 1.0
$ git switch -q -C try main~4
$ git log --oneline -1
93f4d71 Add the parser
$ git cherry-pick --ff main~3 && git log --oneline -2
bb75b71 Fix the crash on an empty line
93f4d71 Add the parser
$ git status --short --branch
## try
```

`--ff` says: if the commit being copied has `HEAD` as its parent, do not copy
it — just move the branch to it.

Both halves of that are in the transcript. On `release`, `HEAD` is not the
parent of `main~3`, so a copy was made, `93c9e5b`. On `main~4`, which *is* that
parent, no commit was made at all and `try` moved to `bb75b71`: the original
hash, not a copy.

That matters when copying a run of commits onto a branch that is only behind:
with `--ff`, the ones that fit are taken as they are and keep their identity,
which is exactly what `git cherry-pick --ff ..next` is for.

## A commit that is already here

```console
$ git switch -q -C try release
$ git cherry-pick main~3
[try b635bee] Fix the crash on an empty line
 Date: Mon Jan 5 12:00:00 2026 +0000
 1 file changed, 2 insertions(+)
$ git cherry-pick main~3
The previous cherry-pick is now empty, possibly due to conflict resolution.
If you wish to commit it anyway, use:

    git commit --allow-empty

Otherwise, please use 'git cherry-pick --skip'
On branch try
You are currently cherry-picking commit bb75b71.
  (all conflicts fixed: run "git cherry-pick --continue")
  (use "git cherry-pick --skip" to skip this patch)
  (use "git cherry-pick --abort" to cancel the cherry-pick operation)

nothing to commit, working tree clean
$ git cherry-pick --abort
$ git log --oneline -2
b635bee Fix the crash on an empty line
ca5345d Prepare release 1.0
```

Copying the same commit twice applies a change that is already there, so the
result would be a commit that changes nothing. Git stops and asks, which is
`--empty=stop`, the default. The wording mentions conflict resolution because
that is the other way a commit becomes empty: you resolved a conflict by
keeping what was already there.

Three ways out, and the message names two of them: commit it anyway with
`git commit --allow-empty`, `--skip` it, or `--abort` the whole thing.

### Dropping it instead

```console
$ git cherry-pick --empty=stop main~3
The previous cherry-pick is now empty, possibly due to conflict resolution.
If you wish to commit it anyway, use:

    git commit --allow-empty

Otherwise, please use 'git cherry-pick --skip'
On branch try
You are currently cherry-picking commit bb75b71.
  (all conflicts fixed: run "git cherry-pick --continue")
  (use "git cherry-pick --skip" to skip this patch)
  (use "git cherry-pick --abort" to cancel the cherry-pick operation)

nothing to commit, working tree clean
$ git cherry-pick --abort
$ git cherry-pick --empty=drop main~3 && git log --oneline -2
dropping bb75b715d925538f126929331bf65cc0a1cc21b7 Fix the crash on an empty line -- patch contents already upstream
b635bee Fix the crash on an empty line
ca5345d Prepare release 1.0
$ git cherry-pick --empty=keep main~3 && git log --oneline -3
[try d2865ff] Fix the crash on an empty line
 Date: Mon Jan 5 12:00:00 2026 +0000
d2865ff Fix the crash on an empty line
b635bee Fix the crash on an empty line
ca5345d Prepare release 1.0
$ git show --stat --oneline HEAD
d2865ff Fix the crash on an empty line
```

`--empty` says what to do about a commit that *becomes* empty:

| Value | Does |
|---|---|
| `--empty=stop` | stop and ask, the default |
| `--empty=drop` | say `dropping ... -- patch contents already upstream` and carry on |
| `--empty=keep` | make the commit anyway, with no change in it |

`--empty=drop` is what you want when copying a range that overlaps what is
already here. `--empty=keep` leaves a commit whose `git show --stat` has no
file list at all, which is occasionally wanted for a marker and usually not.
`--keep-redundant-commits` is the older spelling of `--empty=keep`, which
Git's documentation now calls deprecated.

## A commit that was empty to start with

```console
$ git switch -q -C try release
$ git switch -q -C empties main
$ git commit -q --allow-empty -m 'A deliberately empty commit' && git log --oneline -1
7d89c97 A deliberately empty commit
$ git switch -q try && git cherry-pick empties
The previous cherry-pick is now empty, possibly due to conflict resolution.
If you wish to commit it anyway, use:

    git commit --allow-empty

Otherwise, please use 'git cherry-pick --skip'
On branch try
You are currently cherry-picking commit 7d89c97.
  (all conflicts fixed: run "git cherry-pick --continue")
  (use "git cherry-pick --skip" to skip this patch)
  (use "git cherry-pick --abort" to cancel the cherry-pick operation)

nothing to commit, working tree clean
$ git cherry-pick --allow-empty empties && git log --oneline -2
[try 4850e78] A deliberately empty commit
 Date: Tue Jan 6 09:00:00 2026 +0000
4850e78 A deliberately empty commit
ca5345d Prepare release 1.0
$ git show --stat --oneline HEAD
4850e78 A deliberately empty commit
```

A commit that was empty when it was made is a different case from one that
becomes empty, and `--empty` does not cover it: without `--allow-empty` the
copy fails the same way, and `--empty=drop` would not help. `--allow-empty`
makes it come across.

`--allow-empty-message` is the same idea for a commit whose *message* is empty,
which without it is also refused.

## Copying a merge

```console
$ git switch -q -C try release
$ git cherry-pick main
error: commit 574785184ac9e88c08f27068ee966b3cbddea87b is a merge but no -m option was given.
fatal: cherry-pick failed
$ git cherry-pick -m 1 main
[try 6ee5e3e] Merge branch 'colour'
 Date: Mon Jan 5 16:00:00 2026 +0000
 1 file changed, 1 insertion(+)
 create mode 100644 colour.py
$ git log --oneline -2 && ls
6ee5e3e Merge branch 'colour'
ca5345d Prepare release 1.0
README.md
VERSION
colour.py
parser.py
$ git show --stat --oneline HEAD
6ee5e3e Merge branch 'colour'
 colour.py | 1 +
 1 file changed, 1 insertion(+)
```

A merge has two parents, so "the change it made" is ambiguous until you say
which parent to measure against. `-m 1` measures against the first parent — the
branch the merge was made on — so what gets copied is everything the *other*
side brought in: `colour.py`, and nothing else.

The result is an ordinary commit with one parent. The merge is not reproduced;
its combined change is. The message still says `Merge branch 'colour'`, which is
worth rewriting with `-e`, because on this branch nothing was merged.

## When a cherry-pick conflicts

```console
$ git switch -q -C try release
$ git commit -q -am 'Strip whitespace first' && git log --oneline -1
d364295 Strip whitespace first
$ git cherry-pick main~3
Auto-merging parser.py
CONFLICT (content): Merge conflict in parser.py
error: could not apply bb75b71... Fix the crash on an empty line
hint: After resolving the conflicts, mark them with
hint: "git add/rm <pathspec>", then run
hint: "git cherry-pick --continue".
hint: You can instead skip this commit with "git cherry-pick --skip".
hint: To abort and get back to the state before "git cherry-pick",
hint: run "git cherry-pick --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
$ git status --short --branch
## try
UU parser.py
$ git status | head -8
On branch try
You are currently cherry-picking commit bb75b71.
  (fix conflicts and run "git cherry-pick --continue")
  (use "git cherry-pick --skip" to skip this patch)
  (use "git cherry-pick --abort" to cancel the cherry-pick operation)

Unmerged paths:
  (use "git add <file>..." to mark resolution)
$ cat parser.py
def parse(line):
<<<<<<< HEAD
    return line.strip().split()
=======
    if line is None:
        return []
    return line.split()
>>>>>>> bb75b71 (Fix the crash on an empty line)
$ git log --oneline -1 CHERRY_PICK_HEAD
bb75b71 Fix the crash on an empty line
$ git show --stat --oneline CHERRY_PICK_HEAD
bb75b71 Fix the crash on an empty line
 parser.py | 2 ++
 1 file changed, 2 insertions(+)
```

The release branch had changed the same line, so the change cannot be applied
mechanically. Git stops exactly as a merge does (Chapter 26): `HEAD` is the
branch you are on, and the incoming side is labelled with the commit being
copied, `bb75b71 (Fix the crash on an empty line)`.

`CHERRY_PICK_HEAD` names that commit while the cherry-pick is stopped, so
`git show CHERRY_PICK_HEAD` answers "what was this change supposed to do?"
without looking anything up.

### Finishing the cherry-pick

```console
$ git add parser.py && git cherry-pick --continue --no-edit
[try 96a1f92] Fix the crash on an empty line
 Date: Mon Jan 5 12:00:00 2026 +0000
 1 file changed, 2 insertions(+)
$ git log --oneline -2 && cat parser.py
96a1f92 Fix the crash on an empty line
d364295 Strip whitespace first
def parse(line):
    if line is None:
        return []
    return line.strip().split()
```

Resolve, `git add`, `git cherry-pick --continue`. The resolution kept both
changes, which is what a backport usually needs.

`--continue` opens an editor on the message by default after a conflict, on the
grounds that a resolution may deserve a note; `--no-edit` says not to. `git
commit` also finishes the commit, but leaves the sequencer running, so
`--continue` is the one to use.

## Abandoning it

```console
$ git switch -q -C try release
$ git commit -q -am 'Strip whitespace first'
$ git cherry-pick main~3 main~2
Auto-merging parser.py
CONFLICT (content): Merge conflict in parser.py
error: could not apply bb75b71... Fix the crash on an empty line
...
$ git cherry-pick --skip
[try 88d32e4] Add the help text
 Date: Mon Jan 5 13:00:00 2026 +0000
 1 file changed, 1 insertion(+)
 create mode 100644 help.txt
$ git log --oneline -3
88d32e4 Add the help text
3cc35c9 Strip whitespace first
ca5345d Prepare release 1.0
```

`--skip` abandons the commit that conflicted and carries on with the rest of
the list: the crash fix was not copied, the help text was.

```console
$ git cherry-pick main~3
Auto-merging parser.py
CONFLICT (content): Merge conflict in parser.py
error: could not apply bb75b71... Fix the crash on an empty line
...
$ git cherry-pick --quit && git status --short
UU parser.py
$ git reset -q --hard HEAD && git cherry-pick main~3
Auto-merging parser.py
CONFLICT (content): Merge conflict in parser.py
error: could not apply bb75b71... Fix the crash on an empty line
...
$ git cherry-pick --abort && git status --short && git log --oneline -1
88d32e4 Add the help text
```

`--quit` forgets that a cherry-pick is in progress and leaves the files exactly
as they are, conflict markers included: it is for keeping the half-done work
and dealing with it by hand. `--abort` puts everything back — no markers,
nothing staged, branch where it was.

| Command | The files | The branch | The sequencer |
|---|---|---|---|
| `git cherry-pick --continue` | committed | moves | cleared, or carries on with the rest |
| `git cherry-pick --skip` | this commit's changes dropped | stays | carries on with the rest |
| `git cherry-pick --abort` | back as they were | back as it was | cleared |
| `git cherry-pick --quit` | left exactly as they are | stays | cleared |

## Taking a side automatically

```console
$ git switch -q -C try release
$ git commit -q -am 'Strip whitespace first'
$ git cherry-pick -Xtheirs main~3
Auto-merging parser.py
[try 0acbbe5] Fix the crash on an empty line
 Date: Mon Jan 5 12:00:00 2026 +0000
 1 file changed, 3 insertions(+), 1 deletion(-)
$ git log --oneline -2 && cat parser.py
0acbbe5 Fix the crash on an empty line
cb5488c Strip whitespace first
def parse(line):
    if line is None:
        return []
    return line.split()
```

`-Xtheirs` resolves every conflicting chunk in favour of the commit being
copied, so the cherry-pick goes through without stopping — and the release
branch's own `strip()` is gone. `-Xours` is the other way round and would have
kept it while copying nothing.

Neither reads the code. A conflict resolved this way needs looking at
afterwards, and on a backport that usually means looking at both.

## Another strategy

```console
$ git switch -q -C try release
$ git cherry-pick --strategy=resolve main~3 && git log --oneline -1
Trying simple merge.
[try 9650ad8] Fix the crash on an empty line
 Date: Mon Jan 5 12:00:00 2026 +0000
 1 file changed, 2 insertions(+)
9650ad8 Fix the crash on an empty line
```

`--strategy` picks the merge strategy that applies the change; `ort` is the
default and the alternatives are in Chapter 27. `resolve` announces itself with
`Trying simple merge.`, which is the clearest sign that a cherry-pick really is
a merge underneath.

## Finding out what has already been copied

```console
$ git switch -q -C try release
$ git cherry-pick -x main~3 main~2
[try 28a2258] Fix the crash on an empty line
 Date: Mon Jan 5 12:00:00 2026 +0000
 1 file changed, 2 insertions(+)
[try c8b7cd2] Add the help text
 Date: Mon Jan 5 13:00:00 2026 +0000
 1 file changed, 1 insertion(+)
 create mode 100644 help.txt
$ git cherry -v main try
+ ca5345d8b86cafcef70c9bf239c7dad97d7da251 Prepare release 1.0
- 28a2258c3b544d6b7e4aaed9c582fb0e70664eba Fix the crash on an empty line
- c8b7cd2aace5fbf05281e9d49f3d63533ded295e Add the help text
```

`git cherry <upstream> <head>` lists the commits on `<head>` that are not on
`<upstream>`, and marks each one:

| Mark | Means |
|---|---|
| `-` | an equivalent change is already in `<upstream>` |
| `+` | it is not |

So the two copies are marked `-`, because the originals are on `main`, and
`Prepare release 1.0` is marked `+`, because nothing on `main` makes that
change. Read it as "what would still need copying": the `+` lines.

`git cherry` without `-v` prints only the marks and hashes.

```console
$ git log --oneline --cherry-mark --left-right main...try
= c8b7cd2 Add the help text
= 28a2258 Fix the crash on an empty line
< 5747851 Merge branch 'colour'
< ecd5de4 Add colours
< c1df1b6 Say what it counts
= 63b7adc Add the help text
= bb75b71 Fix the crash on an empty line
> ca5345d Prepare release 1.0
$ git log --oneline --cherry-pick --left-right main...try
< 5747851 Merge branch 'colour'
< ecd5de4 Add colours
< c1df1b6 Say what it counts
> ca5345d Prepare release 1.0
$ git rev-list --count --cherry-pick --right-only main...try
1
```

`git log` can answer the same question over a symmetric difference,
`main...try`, which is "commits on either side but not both" (Chapter 18):

| Option | Does |
|---|---|
| `--left-right` | mark each commit `<` for the left side or `>` for the right |
| `--cherry-mark` | mark `=` instead, for commits that exist on both sides as copies |
| `--cherry-pick` | leave those out altogether |

The first listing shows both copies and both originals marked `=`. The second
drops them, leaving only what is genuinely on one side. The third counts what
is left on the right: one commit, `Prepare release 1.0`.

**How Git recognises a copy.** By *patch id*: a hash of the change with line
numbers and whitespace context normalised away. Two commits with the same patch
id made the same change, whatever their hashes, messages or authors. That is
also how `git rebase` knows to skip commits that are already upstream
(Chapter 33), and it is why a commit that was modified during the copy — a
conflict resolved differently, a line dropped — will *not* be recognised.

## When cherry-pick refuses

```console
$ git switch -q -C try release
$ git cherry-pick main~3
error: Your local changes to the following files would be overwritten by merge:
	parser.py
Please commit your changes or stash them before you merge.
Aborting
fatal: cherry-pick failed
$ git checkout -q -- . && git switch -q -c rival release
$ git commit -q -am 'Bump to 1.0.1'
$ git switch -q try && git commit -q -am 'Mark the hotfix' && git merge rival
Auto-merging VERSION
CONFLICT (content): Merge conflict in VERSION
Automatic merge failed; fix conflicts and then commit the result.
$ git cherry-pick main~3
error: Cherry-picking is not possible because you have unmerged files.
hint: Fix them up in the work tree, and then use 'git add/rm <file>'
hint: as appropriate to mark resolution and make a commit.
fatal: cherry-pick failed
$ git merge --abort
```

Two refusals, both about state that would be lost or confused:

- An uncommitted change to a file the copy has to touch. Commit it, stash it
  (Chapter 55), or throw it away; changes to *other* files are fine.
- Unmerged entries in the index, from a merge or another stopped operation. No
  commit of any kind can be made until they are resolved.

### Onto a branch with nothing in it

```console
$ git switch -q --orphan nothing-yet && git cherry-pick main~3
CONFLICT (modify/delete): parser.py deleted in HEAD and modified in bb75b71 (Fix the crash on an empty line).  Version bb75b71 (Fix the crash on an empty line) of parser.py left in tree.
error: could not apply bb75b71... Fix the crash on an empty line
...
$ git cherry-pick --abort
error: cannot abort from a branch yet to be born
fatal: cherry-pick failed
$ git cherry-pick --quit && git status --short --branch
## No commits yet on nothing-yet
DU parser.py
```

On a branch with no commits the tree is empty, so a change to `parser.py` is a
modify/delete conflict: the file does not exist to be changed. Git leaves the
incoming version in the tree and stops.

`--abort` cannot help, because there is no commit to go back to — "cannot abort
from a branch yet to be born". `--quit` is the way out, and then the files are
ordinary changes to deal with by hand. `DU` means deleted by us, modified by
them (Chapter 26).

## cherry-pick and its neighbours

| Command | Brings the change over by | Leaves | Chapter |
|---|---|---|---|
| `git cherry-pick` | copying chosen commits | a second commit with the same change | this chapter |
| `git merge` | joining the histories | one merge commit; both branches keep their commits | Chapter 25 |
| `git rebase` | copying every commit onto a new base | the originals abandoned | Chapter 33 |
| `git revert` | applying a commit's change backwards | a new commit that undoes it | Chapter 31 |
| `git format-patch` and `git am` | a patch file, applied elsewhere | a commit with the author and message from the mail | Chapter 61 |

**Cherry-pick or merge?** Merge when you want everything the branch has and a
record that the branches were joined. Cherry-pick when you want one change and
nothing else — and accept that the change now exists twice, so a later merge of
that branch has to reconcile two copies. Chapter 25 goes into what that costs.

**Is cherry-picking a whole branch the same as rebasing it?** Nearly, and a
rebase is implemented that way. The difference is what happens to the originals:
a rebase moves the branch to the copies and abandons the originals, while a
cherry-pick leaves both branches exactly where they were and adds to this one.

**And `format-patch` plus `am`?** The same job across a gap that Git cannot
walk: no shared repository, an email list, a patch in a bug report.
`git cherry-pick` needs both commits in one repository; `git am` needs only the
patch, and carries the author across in the mail headers (Chapter 61).

## The settings

| Setting | Does |
|---|---|
| `core.editor` | Which editor opens for `-e` and after a conflict (Chapter 62) |
| `commit.cleanup` | How the message is tidied before it is stored (Chapter 12) |
| `commit.gpgSign` | Sign every commit, copies included (Chapter 68) |
| `merge.conflictStyle` | How a conflict from a cherry-pick is written into the file (Chapter 26) |
| `rerere.enabled` | Whether Git remembers and replays how you resolved the same conflict before (Chapter 26) |
| `advice.mergeConflict` | Whether the hints after a conflict are printed |
