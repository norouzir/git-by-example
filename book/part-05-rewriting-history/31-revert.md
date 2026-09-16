# Chapter 31. revert

## What it is

`git revert` undoes a commit by making a new one that applies the opposite
change. The commit it undoes stays exactly where it is, so nothing already
published is replaced and nobody else has to do anything.

It answers one question: *how do I undo a commit that other people already
have?*

That makes it the odd chapter in this part. Everything else here rewrites
history; `git revert` is what you use when you must not. It is also the only
undo command whose result is a record: the history says that the change was
made and then taken back, and why.

| Term | Means |
|---|---|
| *revert* | a new commit whose change is the reverse of an older commit's |
| *the sequencer* | the state Git keeps in `.git/sequencer` while working through a list of commits, so it can be continued or abandoned |
| *`REVERT_HEAD`* | while a revert is stopped, the commit being reverted |
| *mainline* | for a merge, the parent whose side of history is being kept (Chapter 25) |
| *ours*, *theirs* | during a revert conflict, your branch and the reversed change (Chapter 26) |

`git revert` shares its machinery, its sequencer subcommands and most of its
options with `git cherry-pick` (Chapter 32): one applies a commit's change
forwards and the other backwards.

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What does `git revert` do to my history?](#what-it-is)
- [Does it delete the commit I am reverting?](#what-it-is)

**[Synopsis](#synopsis)**

- [What can I type after `git revert`?](#synopsis)

**[Options at a glance](#options-at-a-glance)**

- [Which options does revert take, and where is each one shown?](#options-at-a-glance)

**[The example repository](#the-example-repository)**

- [What repository do the examples use?](#the-example-repository)

**[Reverting one commit](#reverting-one-commit)**

- [How do I undo a commit that other people already have?](#reverting-one-commit)
- [What exactly is in the commit revert makes?](#reverting-one-commit)
- [Does it undo only that commit, or everything since?](#reverting-one-commit)

**[The message revert writes](#the-message-revert-writes)**

- [Where does "This reverts commit ..." come from?](#the-message-revert-writes)
- [Why did no editor open when I ran `git revert`?](#the-message-revert-writes)
- [How do I explain why I reverted?](#writing-the-reason-in)
- [Can the reference to the old commit be shorter than a full hash?](#a-shorter-reference)
- [What is this "SAY WHY WE ARE REVERTING" line in my history?](#a-shorter-reference)

**[Reverting several commits](#reverting-several-commits)**

- [How do I revert three commits in one go?](#reverting-several-commits)
- [Does the order I list them in matter?](#reverting-several-commits)
- [Why did `git revert A..B` leave A alone?](#a-range)
- [Do I get one commit or several?](#reverting-several-commits)

**[Reverting without committing](#reverting-without-committing)**

- [How do I undo several commits and record it as a single commit?](#reverting-without-committing)
- [What state am I in after `-n`, and how do I finish?](#reverting-without-committing)

**[Reverting a merge](#reverting-a-merge)**

- ["is a merge but no -m option was given" — what number do I give?](#reverting-a-merge)
- [Which parent is 1 and which is 2?](#the-other-parent)
- [What does reverting a merge actually undo?](#reverting-a-merge)

**[Merging again after a reverted merge](#merging-again-after-a-reverted-merge)**

- [I reverted a merge, fixed the branch and merged again, and got "Already up to date". Why?](#merging-again-after-a-reverted-merge)
- [How do I actually get that branch's work back in?](#merging-again-after-a-reverted-merge)

**[When a revert conflicts](#when-a-revert-conflicts)**

- [The revert stopped with a conflict. Where am I?](#when-a-revert-conflicts)
- [What do the conflict markers say in a revert?](#when-a-revert-conflicts)
- [What is `REVERT_HEAD`?](#when-a-revert-conflicts)
- [I fixed the conflict. Which command finishes it?](#finishing-the-revert)

**[Stopping, continuing and abandoning](#stopping-continuing-and-abandoning)**

- [How do I cancel a revert that is going badly?](#stopping-continuing-and-abandoning)
- [What is the difference between `--abort` and `--quit`?](#quitting-instead)
- [How do I give up on one commit and carry on with the rest?](#skipping-one-commit-of-several)

**[Taking a side automatically](#taking-a-side-automatically)**

- [Can I make a revert resolve conflicts by preferring one side?](#taking-a-side-automatically)

**[Another strategy](#another-strategy)**

- [Can I revert with a different merge strategy?](#another-strategy)

**[Signing off](#signing-off)**

- [How do I add a `Signed-off-by` line to a revert?](#signing-off)

**[When revert refuses](#when-revert-refuses)**

- ["your local changes would be overwritten" — what do I do?](#when-revert-refuses)
- [Can I revert while a merge is unfinished?](#during-a-merge)
- [What happens if the change I am reverting is not in this branch?](#a-commit-that-is-not-in-this-branch)
- [Can I revert in a repository with no commits?](#with-no-commits-at-all)

**[revert and its neighbours](#revert-and-its-neighbours)**

- [Should I revert or reset?](#revert-and-its-neighbours)
- [How is reverting different from cherry-picking the opposite change?](#revert-and-its-neighbours)
- [How do I undo an undo?](#revert-and-its-neighbours)

**[The settings](#the-settings)**

- [Which settings change what revert does?](#the-settings)

</details>

## Synopsis

```
git revert [--[no-]edit] [-n] [-m <parent-number>] [-s] [-S[<keyid>]] <commit>...
git revert (--continue | --skip | --abort | --quit)
```

| Part | Means |
|---|---|
| `<commit>...` | the commits to undo: names, hashes or a range, in the order they are to be applied |
| `<parent-number>` | for a merge, which parent's side to keep, counting from 1 |

| Command | Does |
|---|---|
| `git revert <commit>` | Make a commit that undoes `<commit>` |
| `git revert -n <commit>...` | Undo them in the working tree and index, without committing |
| `git revert -m 1 <merge>` | Undo a merge, keeping the first parent's side |
| `git revert --continue` | Carry on after resolving a conflict |
| `git revert --skip` | Give up on the current commit and carry on with the rest |
| `git revert --abort` | Cancel, and put everything back as it was |
| `git revert --quit` | Forget the revert is in progress, leaving the files as they are |

## Options at a glance

| Option | Does | Covered in |
|---|---|---|
| `-e`, `--edit` | Open an editor on the message; the default only at a terminal | [The message revert writes](#the-message-revert-writes) |
| `--no-edit` | Do not open an editor | [Reverting one commit](#reverting-one-commit) |
| `--reference` | Refer to the reverted commit in the short `reference` format | [A shorter reference](#a-shorter-reference) |
| `-n`, `--no-commit` | Apply the reverse change without committing | [Reverting without committing](#reverting-without-committing) |
| `-m <parent-number>`, `--mainline <parent-number>` | Which parent of a merge to treat as the mainline | [Reverting a merge](#reverting-a-merge) |
| `-s`, `--signoff` | Add a `Signed-off-by` trailer | [Signing off](#signing-off) |
| `--cleanup=<mode>` | How the message is tidied; the modes are in Chapter 12 | Chapter 12 |
| `--strategy=<strategy>` | Use another merge strategy | [Another strategy](#another-strategy) |
| `-X<option>`, `--strategy-option=<option>` | Pass an option to the merge strategy | [Taking a side automatically](#taking-a-side-automatically) |
| `--rerere-autoupdate`, `--no-rerere-autoupdate` | Stage resolutions rerere remembers, or leave them unstaged | Chapter 26 |
| `-S[<keyid>]`, `--gpg-sign[=<keyid>]`, `--no-gpg-sign` | Sign the revert commit | Chapter 68 |
| `--continue`, `--skip`, `--abort`, `--quit` | Work through a stopped revert | [Stopping, continuing and abandoning](#stopping-continuing-and-abandoning) |

## The example repository

```console
$ git log --oneline --graph --decorate -7
*   565284a (HEAD -> main) Merge branch 'loyalty'
|\
| * 3ca8101 (loyalty) Say when stamps expire
| * dc71bc9 Start a loyalty card
* | 773fe86 Add the opening hours
* | 7f97752 Raise every price
|/
* cfe8114 Add the snacks
* b772315 Add the drinks
$ git show --stat --oneline main~2
7f97752 Raise every price
 drinks.md | 4 ++--
 snacks.md | 4 ++--
 2 files changed, 4 insertions(+), 4 deletions(-)
```

A shop's price list. `main~2`, `Raise every price`, is the commit most examples
undo: it changed two lines in each of `drinks.md` and `snacks.md`. `loyalty`
was merged in at the tip, which gives the chapter a merge to revert.

Every example starts with `git switch -C try main`, a scratch branch at `main`
(Chapter 24), so each begins from the same place.

`git revert` opens an editor on the message only when it is run from a terminal,
which the sandbox is not, so the examples that want one pass `-e` and set
`GIT_EDITOR`, and the rest pass `--no-edit`. At a terminal, `git revert
<commit>` on its own opens your editor.

## Reverting one commit

```console
$ git switch -q -C try main
$ git revert --no-edit main~2
[try 471d994] Revert "Raise every price"
 Date: Mon Jan 5 17:00:00 2026 +0000
 2 files changed, 4 insertions(+), 4 deletions(-)
$ git log --oneline -2
471d994 Revert "Raise every price"
565284a Merge branch 'loyalty'
$ git show --stat HEAD
commit 471d994841c2d2c568b0897e485a6525746f3851
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 17:00:00 2026 +0000

    Revert "Raise every price"

    This reverts commit 7f977526a60c58edc9f73250d90d388a4d9b3dca.

 drinks.md | 4 ++--
 snacks.md | 4 ++--
 2 files changed, 4 insertions(+), 4 deletions(-)
$ cat drinks.md
tea 2
coffee 3
```

One new commit at the tip, undoing one old commit in the middle. `Raise every
price` is still there, still reachable, still in everyone's clone; the branch
simply has a later commit that puts the prices back.

Note what was *not* undone. `Add the opening hours` and the merge came after
the reverted commit and are untouched, and `hours.md` is still in the working
tree. A revert undoes one commit's change, not everything since.

The revert commit's own change is the reverse of the original's: the same two
files, the same four lines, in the opposite direction.

## The message revert writes

```console
$ git switch -q -C try main
$ GIT_EDITOR=cat git revert -e main~2
Revert "Raise every price"

This reverts commit 7f977526a60c58edc9f73250d90d388a4d9b3dca.

# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
#
# On branch try
# Changes to be committed:
#	modified:   drinks.md
#	modified:   snacks.md
#
[try 8a47ade] Revert "Raise every price"
 2 files changed, 4 insertions(+), 4 deletions(-)
$ git log -1 --format=%B
Revert "Raise every price"

This reverts commit 7f977526a60c58edc9f73250d90d388a4d9b3dca.
```

The message Git proposes is the original subject with `Revert ` in front of it,
and a body naming the full hash of what was undone. That body is the only
machine-readable record that a revert happened, and tools use it.

**Why an editor may not open.** `git revert` opens one only when it is run from
a terminal; in a script, or here, it commits the proposed message without
asking. `-e` forces the editor and `--no-edit` prevents it, whichever way the
default falls.

### Writing the reason in

```console
$ git switch -q -C try main
$ GIT_EDITOR="sed -i '1s/.*/Put the old prices back, the rise was a mistake/'" git revert -e main~2
[try f617042] Put the old prices back, the rise was a mistake
 2 files changed, 4 insertions(+), 4 deletions(-)
$ git log -1 --format=%B
Put the old prices back, the rise was a mistake

This reverts commit 7f977526a60c58edc9f73250d90d388a4d9b3dca.
```

The subject can be anything; the `This reverts commit` line stays unless you
delete it. Git's own documentation is unusually insistent here: it *strongly*
recommends explaining why, because `Revert "X"` says what happened and nothing
about whether it was a mistake, a rollback for a release, or a change that will
come back next week.

The `GIT_EDITOR=` part stands for your editor opening: `sed -i` replaces the
first line of the message file and exits, which is what you would do by hand.

### A shorter reference

```console
$ git switch -q -C try main
$ GIT_EDITOR="sed -i '1s/.*/Put the old prices back/'" git revert -e --reference main~2
[try 435e060] Put the old prices back
 2 files changed, 4 insertions(+), 4 deletions(-)
$ git log -1 --format=%B
Put the old prices back

This reverts commit 7f97752 (Raise every price, 2026-01-05).
```

`--reference` writes the body in Git's `reference` format — abbreviated hash,
subject, date — instead of the bare forty characters. It reads better in a log
and is the form the Linux kernel and Git itself use.

```console
$ git -c revert.reference=true revert --no-edit main~3 && git log -1 --format=%B
[try 76d12e7] # *** SAY WHY WE ARE REVERTING ON THE TITLE LINE ***
 Date: Mon Jan 5 21:00:00 2026 +0000
 1 file changed, 2 deletions(-)
 delete mode 100644 snacks.md
# *** SAY WHY WE ARE REVERTING ON THE TITLE LINE ***

This reverts commit cfe8114 (Add the snacks, 2026-01-05).
```

`revert.reference` turns it on for every revert. But notice the subject: with
`--reference`, Git does not invent one. It writes a placeholder shouting at you
to replace it, and if no editor opens — because the command was `--no-edit`, or
was not run from a terminal — the placeholder is committed as the subject.

> **Careful.** That placeholder line begins with `#`, so a `--cleanup` mode
> that strips comments would delete it and leave the commit with no subject at
> all. With `--reference`, write the subject.

## Reverting several commits

```console
$ git switch -q -C try main
$ git revert --no-edit main~2 main~3
[try 9038ceb] Revert "Raise every price"
 Date: Mon Jan 5 22:00:00 2026 +0000
 2 files changed, 4 insertions(+), 4 deletions(-)
[try f683aa2] Revert "Add the snacks"
 Date: Mon Jan 5 22:00:00 2026 +0000
 1 file changed, 2 deletions(-)
 delete mode 100644 snacks.md
$ git log --oneline -3
f683aa2 Revert "Add the snacks"
9038ceb Revert "Raise every price"
565284a Merge branch 'loyalty'
$ ls
README.md
drinks.md
hours.md
loyalty.md
```

Several commits means several revert commits, one for each, applied in the
order you wrote them. Here that order matters: `Raise every price` changed
lines in `snacks.md`, so undoing the price rise first and then the commit that
added the file works, while the other order would have tried to change a file
that had just been deleted.

The rule of thumb is to revert newest first, which is what a range does
automatically.

### A range

```console
$ git switch -q -C try main
$ git revert --no-edit main~3..main~1
[try 63a8bec] Revert "Add the opening hours"
 Date: Tue Jan 6 00:00:00 2026 +0000
 1 file changed, 1 deletion(-)
 delete mode 100644 hours.md
[try 242e64f] Revert "Raise every price"
 Date: Tue Jan 6 00:00:00 2026 +0000
 2 files changed, 4 insertions(+), 4 deletions(-)
$ git log --oneline -3
242e64f Revert "Raise every price"
63a8bec Revert "Add the opening hours"
565284a Merge branch 'loyalty'
```

`A..B` means "commits reachable from B but not from A" (Chapter 18), so
`main~3..main~1` is `main~2` and `main~1` — the endpoint `A` itself is
excluded, which is the usual surprise. To include it, say `main~4..main~1`, or
list the commits.

Given a range, revert works through it newest first, so each revert applies to
a tree that still contains the later commits. That is the opposite of
`git cherry-pick`, which applies a range oldest first (Chapter 32), and for the
same reason: undoing is stacking backwards.

## Reverting without committing

```console
$ git switch -q -C try main
$ git revert -n main~2 main~3
$ git status --short
M  drinks.md
D  snacks.md
$ git commit -q -m 'Undo the price rise and the snacks' && git log --oneline -2
1a7fc94 Undo the price rise and the snacks
565284a Merge branch 'loyalty'
```

`-n` applies the reverse changes to the working tree and the index and stops
there, so several reverts become one commit with a message you write. It is
also how to revert something and then adjust the result before committing.

Two things follow from "the revert is done against the beginning state of your
index", as Git's documentation puts it: the index does not have to be clean
when you start, and nothing is committed, so `git revert --quit` is not needed
to finish — there is no sequencer state left behind for a `-n` run that
completes.

## Reverting a merge

```console
$ git switch -q -C try main
$ git revert --no-edit HEAD
error: commit 565284adda46845c1c41a9b13870a9c9dacefda6 is a merge but no -m option was given.
fatal: revert failed
$ git log --oneline --graph -3 HEAD
*   565284a Merge branch 'loyalty'
|\
| * 3ca8101 Say when stamps expire
| * dc71bc9 Start a loyalty card
$ git revert --no-edit -m 1 HEAD
[try 2da625c] Revert "Merge branch 'loyalty'"
 Date: Tue Jan 6 03:00:00 2026 +0000
 1 file changed, 2 deletions(-)
 delete mode 100644 loyalty.md
$ git log --oneline -2 && ls
2da625c Revert "Merge branch 'loyalty'"
565284a Merge branch 'loyalty'
README.md
drinks.md
hours.md
snacks.md
$ git show --stat --oneline HEAD
2da625c Revert "Merge branch 'loyalty'"
 loyalty.md | 2 --
 1 file changed, 2 deletions(-)
```

A merge has two parents, so "the change this commit made" is ambiguous until
you say which side to keep. `-m 1` means "keep the first parent's side", which
for a merge made by `git merge` is the branch you were on — so `-m 1` undoes
everything the *other* branch brought in. That is what the reader almost always
wants: `loyalty.md` is gone and everything `main` had is untouched.

The parents are in the order Git recorded them, first parent first, and
`git log --graph` draws the first parent as the straight line down the left.

### The other parent

```console
$ git switch -q -C try main
$ git revert --no-edit -m 2 HEAD
[try 10b914a] Revert "Merge branch 'loyalty'"
 Date: Tue Jan 6 04:00:00 2026 +0000
 3 files changed, 4 insertions(+), 5 deletions(-)
 delete mode 100644 hours.md
$ git show --stat --oneline HEAD
10b914a Revert "Merge branch 'loyalty'"
 drinks.md | 4 ++--
 hours.md  | 1 -
 snacks.md | 4 ++--
 3 files changed, 4 insertions(+), 5 deletions(-)
```

`-m 2` keeps the *loyalty* side and undoes everything `main` contributed to the
merge: the price rise and the opening hours are gone and `loyalty.md` stays.
That is rarely what anyone means, and it is worth running
`git show --stat` on the result before pushing it.

| To undo | Use |
|---|---|
| the branch that was merged in | `-m 1` |
| everything the branch you were on had added since the fork | `-m 2` |
| the merge itself, when it is only in your repository | `git reset --hard HEAD~1` (Chapter 30) |

## Merging again after a reverted merge

```console
$ git switch -q -C try main
$ git revert --no-edit -m 1 HEAD
[try c9e7e83] Revert "Merge branch 'loyalty'"
 Date: Tue Jan 6 05:00:00 2026 +0000
 1 file changed, 2 deletions(-)
 delete mode 100644 loyalty.md
$ git merge --no-edit loyalty
Already up to date.
$ ls
README.md
drinks.md
hours.md
snacks.md
```

This is the trap. The merge is still in history, so `loyalty`'s commits are
still ancestors of `try`, so there is nothing left to merge — `Already up to
date` — and yet `loyalty.md` is not there, because a later commit deleted it.
Merging harder does not help, and neither does merging again after adding more
commits to `loyalty`: those new commits will merge, and the old ones will stay
undone.

Git's documentation says it plainly: reverting a merge declares that you never
want that branch's changes, and later merges will only bring in what came
after.

```console
$ git revert --no-edit HEAD
[try 5ec8f2e] Reapply "Merge branch 'loyalty'"
 Date: Tue Jan 6 06:00:00 2026 +0000
 1 file changed, 2 insertions(+)
 create mode 100644 loyalty.md
$ git log --oneline -3 && ls
5ec8f2e Reapply "Merge branch 'loyalty'"
c9e7e83 Revert "Merge branch 'loyalty'"
565284a Merge branch 'loyalty'
README.md
drinks.md
hours.md
loyalty.md
snacks.md
```

The way back in is to revert the revert. The branch's work returns as an
ordinary commit, and Git labels it `Reapply` rather than `Revert "Revert "`,
which it does whenever the subject being reverted already starts with `Revert`.

**What to do instead, next time.** If the branch is going to be merged again
later, prefer one of these:

| Instead of reverting the merge | Do |
|---|---|
| when the merge is not pushed | `git reset --hard ORIG_HEAD`, and the merge never happened (Chapter 30) |
| when only part of the branch is bad | revert the individual commits, not the merge |
| when the branch will come back | revert the merge, and revert *that* when it does |
| when the branch is abandoned | revert the merge; this problem is not a problem |

## When a revert conflicts

```console
$ git switch -q -C try main
$ git commit -q -am 'Add cocoa' && git log --oneline -1
28f2526 Add cocoa
$ git revert --no-edit main~2
Auto-merging drinks.md
CONFLICT (content): Merge conflict in drinks.md
error: could not revert 7f97752... Raise every price
hint: After resolving the conflicts, mark them with
hint: "git add/rm <pathspec>", then run
hint: "git revert --continue".
hint: You can instead skip this commit with "git revert --skip".
hint: To abort and get back to the state before "git revert",
hint: run "git revert --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
$ git status --short --branch
## try
UU drinks.md
M  snacks.md
$ git status | head -12
On branch try
You are currently reverting commit 7f97752.
  (fix conflicts and run "git revert --continue")
  (use "git revert --skip" to skip this patch)
  (use "git revert --abort" to cancel the revert operation)

Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   snacks.md

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
$ cat drinks.md
<<<<<<< HEAD
tea 3
coffee 4
cocoa 5
=======
tea 2
coffee 3
>>>>>>> parent of 7f97752 (Raise every price)
$ git log --oneline -1 REVERT_HEAD
7f97752 Raise every price
```

A later commit changed the same lines, so putting the old ones back is not
something Git can decide. It stops exactly as a merge does (Chapter 26), with
one difference worth reading twice: the label on the incoming side is
**`parent of 7f97752`**, not the commit being reverted. That is literally what
is being applied — the file as it was *before* the bad commit.

`snacks.md` had no conflict, so its part of the revert is already staged. The
whole revert is one commit, so it waits for the conflicted file.

`REVERT_HEAD` names the commit being reverted, for as long as the revert is
stopped; `git status` prints the same thing in words.

### Finishing the revert

```console
$ git add drinks.md && git revert --continue --no-edit
[try b37b22d] Revert "Raise every price"
 2 files changed, 4 insertions(+), 4 deletions(-)
$ git log --oneline -2 && cat drinks.md
b37b22d Revert "Raise every price"
28f2526 Add cocoa
tea 2
coffee 3
cocoa 5
```

Edit the file, `git add` it, `git revert --continue`. The resolution kept the
old prices and the new line, which is what "undo the price rise, keep
everything else" means.

`git commit` also finishes it, and then `git revert --quit` clears the
sequencer; `--continue` does both in one step and is the command `git status`
recommends.

## Stopping, continuing and abandoning

```console
$ git switch -q -C try main
$ git commit -q -am 'Add cocoa'
$ git revert --no-edit main~2
Auto-merging drinks.md
CONFLICT (content): Merge conflict in drinks.md
error: could not revert 7f97752... Raise every price
...
$ git revert --abort && git status --short && cat drinks.md
tea 3
coffee 4
cocoa 5
```

`--abort` puts everything back: the conflict markers are gone, nothing is
staged, and the branch is where it was. It is the safe way out.

### Quitting instead

```console
$ git revert --no-edit main~2
Auto-merging drinks.md
CONFLICT (content): Merge conflict in drinks.md
error: could not revert 7f97752... Raise every price
...
$ git revert --quit && git status --short
UU drinks.md
M  snacks.md
$ git log --oneline -1
24a0489 Add cocoa
```

`--quit` forgets that a revert is in progress and changes nothing else: the
conflicted file is still conflicted, the resolved file is still staged, and
`REVERT_HEAD` is gone. It is for when you want to keep the half-finished work
and deal with it as ordinary changes — or when a revert was abandoned so long
ago that Git's complaints about it have become noise.

| Command | The files | The branch | The sequencer |
|---|---|---|---|
| `git revert --continue` | committed | moves | cleared |
| `git revert --abort` | back as they were | back as it was | cleared |
| `git revert --quit` | left exactly as they are | stays | cleared |
| `git revert --skip` | this commit's changes dropped | carries on with the rest | continues |

### Skipping one commit of several

```console
$ git switch -q -C try main
$ git commit -q -am 'Add cocoa'
$ git revert --no-edit main~2 main~1
Auto-merging drinks.md
CONFLICT (content): Merge conflict in drinks.md
error: could not revert 7f97752... Raise every price
...
$ git revert --skip
[try b679f4e] Revert "Add the opening hours"
 Date: Tue Jan 6 11:00:00 2026 +0000
 1 file changed, 1 deletion(-)
 delete mode 100644 hours.md
$ git log --oneline -3 && ls
b679f4e Revert "Add the opening hours"
46124bf Add cocoa
565284a Merge branch 'loyalty'
README.md
drinks.md
loyalty.md
snacks.md
```

`--skip` abandons the commit that conflicted and carries on with the rest of
the list. The price rise is still in place — `drinks.md` and `snacks.md` are
untouched — and `hours.md` is gone, which is the second revert done.

## Taking a side automatically

```console
$ git switch -q -C try main
$ git commit -q -am 'Add cocoa'
$ git revert --no-edit -Xours main~2
Auto-merging drinks.md
[try de0340b] Revert "Raise every price"
 Date: Tue Jan 6 13:00:00 2026 +0000
 1 file changed, 2 insertions(+), 2 deletions(-)
$ git log --oneline -2 && cat drinks.md
de0340b Revert "Raise every price"
95b2617 Add cocoa
tea 3
coffee 4
cocoa 5
```

`-X` passes an option to the merge strategy (Chapter 27). `-Xours` resolves
every conflicting chunk in favour of what is already on the branch, which
during a revert means "where the revert conflicts, do not revert". The commit
was still made — `snacks.md` had no conflict and was reverted — but `drinks.md`
kept the new prices.

`-Xtheirs` is the other way round: conflicting chunks are taken from the
reversed change. Neither looks at whether the result makes sense, so a revert
made this way needs reading afterwards.

## Another strategy

```console
$ git switch -q -C try main
$ git revert --no-edit --strategy=ort main~2 && git log --oneline -1
[try 9329a09] Revert "Raise every price"
 Date: Tue Jan 6 14:00:00 2026 +0000
 2 files changed, 4 insertions(+), 4 deletions(-)
9329a09 Revert "Raise every price"
```

`--strategy` names the merge strategy used to apply the reverse change. `ort`
is the default, so this changes nothing; the option exists because a revert is
a merge underneath, and the alternatives — `resolve`, `ours`, `octopus`,
`subtree` — are in Chapter 27. In practice `-X` is the useful half of the pair,
and `--strategy` is for the rare case where the default strategy cannot apply
the change at all.

## Signing off

```console
$ git switch -q -C try main
$ git revert --no-edit -s main~2 && git log -1 --format=%B
[try 3659cec] Revert "Raise every price"
 Date: Tue Jan 6 15:00:00 2026 +0000
 2 files changed, 4 insertions(+), 4 deletions(-)
Revert "Raise every price"

This reverts commit 7f977526a60c58edc9f73250d90d388a4d9b3dca.

Signed-off-by: Ada Lovelace <ada@example.com>
```

`-s` adds the trailer projects use to record that someone stands behind the
change (Chapter 53), after the `This reverts commit` line.

## When revert refuses

```console
$ git switch -q -C try main
$ git revert --no-edit main~2
error: Your local changes to the following files would be overwritten by merge:
	drinks.md
Please commit your changes or stash them before you merge.
Aborting
fatal: revert failed
$ git status --short
 M drinks.md
$ git stash push -q && git status --short
$ git revert --no-edit main~2 && git log --oneline -1
[try 192a0c9] Revert "Raise every price"
 Date: Tue Jan 6 16:00:00 2026 +0000
 2 files changed, 4 insertions(+), 4 deletions(-)
192a0c9 Revert "Raise every price"
```

An uncommitted change to a file the revert has to touch stops the command
before it does anything: commit it, stash it (Chapter 55), or throw it away.
Uncommitted changes to *other* files are fine — Git only objects to what it
would overwrite.

### During a merge

```console
$ git switch -q try && git merge rival
Auto-merging drinks.md
CONFLICT (content): Merge conflict in drinks.md
Automatic merge failed; fix conflicts and then commit the result.
$ git revert --no-edit main~2
error: Reverting is not possible because you have unmerged files.
hint: Fix them up in the work tree, and then use 'git add/rm <file>'
hint: as appropriate to mark resolution and make a commit.
fatal: revert failed
```

No commit of any kind can be made while the index has unmerged entries, so a
revert cannot start. Finish or abandon the merge first (Chapter 25).

### A commit that is not in this branch

```console
$ git switch -q -C try main
$ git switch -q -c other main~3 && git revert --no-edit main~2
On branch other
nothing to commit, working tree clean
$ git status --short --branch && git log --oneline -1
## other
cfe8114 Add the snacks
$ git revert --quit && git log --oneline -2 && ls
cfe8114 Add the snacks
b772315 Add the drinks
README.md
drinks.md
snacks.md
```

`other` is at `main~3`, before the price rise, so undoing the price rise has
nothing to undo: reversing the change produces the tree that is already there.
Git applies it, finds nothing to commit, and says so.

Nothing was committed and the branch did not move, but the sequencer is still
in progress — that is why `git revert --quit` is the tidy-up here. If the
reverse change *had* applied, the revert would have been made regardless of
whether the original commit is an ancestor: `git revert` applies a change, and
does not require the commit it came from to be in your history at all.

### With no commits at all

```console
$ git switch -q --orphan nothing-yet && git revert --no-edit HEAD
fatal: bad revision 'HEAD'
```

On a branch with no commits there is no `HEAD` to name, and nothing to revert.

## revert and its neighbours

| Command | Undoes by | Safe on a shared branch | Chapter |
|---|---|---|---|
| `git revert` | adding a commit that reverses an old one | yes | this chapter |
| `git reset` | moving the branch off the commits | no | Chapter 30 |
| `git restore` | putting files back, without touching history | yes, it makes no commit | Chapter 14 |
| `git commit --amend` | replacing the last commit | no | Chapter 29 |
| `git rebase -i`, `drop` | leaving the commit out of a rewritten history | no | Chapter 34 |

**Revert or reset?** If the commit has been pushed and anyone else may have it,
revert. If it is still only yours, reset is tidier, because it leaves no trace
of a mistake nobody saw. Chapter 28 is the test for "only yours".

**Is a revert the same as cherry-picking the opposite change?** Nearly.
`git cherry-pick` applies a commit's change forwards; `git revert` applies it
backwards. They share the sequencer, the conflict behaviour, `-n`, `-e`, `-s`,
`-m`, `-X` and all four of `--continue`, `--skip`, `--abort` and `--quit`.
What differs is the message Git writes, and that `git revert` has `--reference`
while `git cherry-pick` has `-x` for the same job in the other direction
(Chapter 32).

**How do I undo an undo?** Revert the revert, as [Merging again after a
reverted merge](#merging-again-after-a-reverted-merge) does. Subjects pile up
as `Revert "..."` and then `Reapply "..."`; Git's documentation asks you to
reword those into something readable rather than let them grow.

## The settings

| Setting | Does |
|---|---|
| `revert.reference` | Write the `This reverts commit` line in the short `reference` format, as `--reference` does |
| `core.editor` | Which editor opens on the message, when one opens (Chapter 62) |
| `commit.cleanup` | How the message is tidied before it is stored (Chapter 12) |
| `commit.gpgSign` | Sign every commit, reverts included (Chapter 68) |
| `merge.conflictStyle` | How a conflict from a revert is written into the file (Chapter 26) |
| `rerere.enabled` | Whether Git remembers and replays how you resolved a revert conflict (Chapter 26) |
| `advice.mergeConflict` | Whether the hints after a conflict are printed |
