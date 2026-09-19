# Chapter 30. reset

## What it is

`git reset` moves the current branch to another commit, and can update the
index and the working tree to match. It is how you undo a commit, unstage a
file, throw away everything since the last commit, and get out of a merge that
went wrong.

It answers one question: *how do I put things back the way they were?*

The command has two halves that share a name and have almost nothing else in
common:

| Form | Does |
|---|---|
| `git reset [<mode>] [<commit>]` | Move the current branch to `<commit>`, and update the index and working tree according to `<mode>` |
| `git reset [<commit>] -- <path>...` | Leave the branch alone; set the staged version of those paths to the one in `<commit>` |

The first is a rewrite in the sense of Chapter 28: commits the branch used to
contain are no longer in it. The second is the opposite of `git add` and
changes no history at all.

| Term | Means |
|---|---|
| *the working tree* | the files you edit (Chapter 5) |
| *the index* | what the next commit will contain, also called the staging area (Chapter 5) |
| *`HEAD`* | the commit the current branch points at (Chapter 7) |
| *mode* | which of the three a reset updates: `--soft`, `--mixed`, `--hard`, `--merge` or `--keep` |
| *`<tree-ish>`* | anything that names a tree: a commit, a tag, a branch, or a tree itself (Chapter 18) |
| *`ORIG_HEAD`* | a ref Git sets to where `HEAD` was before a reset, merge, pull or rebase |
| *unmerged entry* | an index entry with a conflict in it, holding several versions of one path (Chapter 26) |

Nothing `git reset` does is permanent by itself: the commits it moves off a
branch are still in the repository, and the reflog still names them
(Chapter 36). The exception is `--hard`, which overwrites files in the working
tree, and uncommitted work has no reflog.

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What exactly does `git reset` reset?](#what-it-is)
- [Why does the same command sometimes move my branch and sometimes unstage a file?](#what-it-is)

**[Synopsis](#synopsis)**

- [What are the forms of `git reset`, and how do I tell them apart?](#synopsis)

**[Options at a glance](#options-at-a-glance)**

- [Is there a list of every option and where each one is shown?](#options-at-a-glance)

**[The example repository](#the-example-repository)**

- [What repository do the examples use?](#the-example-repository)

**[The three things reset can touch](#the-three-things-reset-can-touch)**

- [What is the difference between `--soft`, `--mixed` and `--hard`?](#the-three-things-reset-can-touch)
- [Which mode do I want for what I am trying to do?](#the-three-things-reset-can-touch)

**[--soft](#soft)**

- [How do I undo my last commit but keep the changes staged?](#soft)
- [How do I turn my last three commits into one without a rebase?](#squashing-the-last-three-commits)
- [Does `--soft` touch my files at all?](#what-soft-leaves-alone)

**[--mixed, the default](#mixed-the-default)**

- [How do I unstage everything I have added?](#mixed-the-default)
- [What is the "Unstaged changes after reset" list?](#mixed-the-default)
- [After a reset, why is a file I had committed now shown as untracked?](#a-file-the-target-commit-does-not-have)
- [What does `-N` do, and when would I want it?](#a-file-the-target-commit-does-not-have)
- [What does `--no-refresh` change?](#without-refreshing-the-index)

**[--hard](#hard)**

- [How do I throw away everything since my last commit?](#hard)
- [Does `--hard` delete files I never added to Git?](#untracked-and-ignored-files)
- [Does it remove files that exist now but not in the target commit?](#hard)

**[--merge](#merge)**

- [How do I get out of a conflicted merge without losing edits I made before it started?](#merge)
- [How is `--merge` different from `--hard`?](#merge)

**[--keep](#keep)**

- [What does `--keep` do that `--hard` does not?](#keep)
- [Why did `--keep` stop with "not uptodate. Cannot merge"?](#keep-refusing)
- [What would `--hard` have done in the same situation?](#keep-refusing)

**[Every mode side by side](#every-mode-side-by-side)**

- [Is there one table that says what each mode does to each file?](#every-mode-side-by-side)
- [Some combinations are disallowed. Which, and what do I do instead?](#when-merge-refuses)

**[Resetting files instead of commits](#resetting-files-instead-of-commits)**

- [How do I unstage one file?](#resetting-files-instead-of-commits)
- [Is `git reset <file>` any different from `git restore --staged <file>`?](#reset-and-restore-staged)
- [How do I make the staged version of a file match an older commit?](#the-staged-version-from-another-commit)
- [Why can't I give a mode and a path in the same command?](#reset-with-a-path-and-a-mode)
- [How do I unstage only part of a file?](#unstaging-part-of-a-file)
- [Why does the question in `git reset -p` run into the next chunk of diff?](#unstaging-part-of-a-file)

**[ORIG_HEAD](#orighead)**

- [Where was my branch before the reset?](#orighead)
- [Which commands set `ORIG_HEAD`?](#orighead)

**[Resetting somewhere other than backwards](#resetting-somewhere-other-than-backwards)**

- [Can I point my branch at any commit, including one that is not an ancestor?](#resetting-somewhere-other-than-backwards)
- [How do I make my branch exactly match another branch?](#resetting-somewhere-other-than-backwards)
- [Can I reset a branch I am not on?](#moving-a-branch-you-are-not-on)

**[What reset never touches](#what-reset-never-touches)**

- [Does resetting my branch move any other branch?](#what-reset-never-touches)
- [Does reset touch my stash or my tags?](#what-reset-never-touches)

**[When reset refuses](#when-reset-refuses)**

- [What are the errors reset can give, and what does each mean?](#when-reset-refuses)
- [Can I reset in a repository where nothing has been committed?](#when-reset-refuses)
- [Why does "Cannot do a soft reset in the middle of a merge" happen, and what do I run instead?](#in-the-middle-of-a-merge)
- [Can I reset in a bare repository?](#in-a-bare-repository)

**[Undoing a reset](#undoing-a-reset)**

- [I reset to the wrong commit. How do I go back?](#undoing-a-reset)
- [I ran `reset --hard` with changes that were staged but never committed. Are they gone?](#work-that-was-staged-and-never-committed)

**[reset, restore, revert and checkout](#reset-restore-revert-and-checkout)**

- [Which of the four do I want, and how do I remember the difference?](#reset-restore-revert-and-checkout)
- [Is `git reset --hard <commit>` the same as checking that commit out?](#reset-restore-revert-and-checkout)

**[The settings](#the-settings)**

- [Which settings change what reset does?](#the-settings)

</details>

## Synopsis

```
git reset [--soft | --mixed [-N] | --hard | --merge | --keep] [-q] [<commit>]
git reset [-q] [<tree-ish>] [--] <pathspec>...
git reset [-q] [--pathspec-from-file=<file> [--pathspec-file-nul]] [<tree-ish>]
git reset (--patch | -p) [<tree-ish>] [--] [<pathspec>...]
DEPRECATED: git reset [-q] [--stdin [-z]] [<tree-ish>]
```

| Part | Means |
|---|---|
| `<commit>` | where the branch is to point; defaults to `HEAD`, which moves nothing |
| `<tree-ish>` | where the staged version of the paths comes from; defaults to `HEAD` |
| `<pathspec>...` | which paths to change in the index, leaving the branch alone |

| Command | Does |
|---|---|
| `git reset` | Unstage everything; the branch does not move |
| `git reset <commit>` | Move the branch to `<commit>` and unstage everything |
| `git reset --soft <commit>` | Move the branch only; index and files untouched |
| `git reset --hard <commit>` | Move the branch and make index and files match it |
| `git reset -- <path>` | Unstage `<path>` |
| `git reset <commit> -- <path>` | Set the staged `<path>` to the version in `<commit>` |
| `git reset -p` | Choose which parts of the staged changes to unstage |

The third form exists so that a long list of paths can come from a file rather
than the command line, and the last is the old way of doing the same through
standard input, which Git's documentation marks deprecated.

## Options at a glance

### Modes

| Option | Moves the branch | Index | Working tree | Covered in |
|---|---|---|---|---|
| `--soft` | yes | untouched | untouched | [--soft](#soft) |
| `--mixed` | yes | matches the new `HEAD` | untouched | [--mixed, the default](#mixed-the-default) |
| `--hard` | yes | matches the new `HEAD` | matches the new `HEAD` | [--hard](#hard) |
| `--merge` | yes | matches the new `HEAD` | keeps unstaged changes, resets the rest; refuses if that would lose one | [--merge](#merge) |
| `--keep` | yes | matches the new `HEAD` | keeps local changes; refuses if the commit being left touched the same file | [--keep](#keep) |

### The other options

| Option | Does | Covered in |
|---|---|---|
| `-N`, `--intent-to-add` | Mark removed paths as to-be-added, so `git diff` and `git add -p` see them | [A file the target commit does not have](#a-file-the-target-commit-does-not-have) |
| `-p`, `--patch` | Choose the changes to unstage, one chunk at a time | [Unstaging part of a file](#unstaging-part-of-a-file) |
| `--refresh`, `--no-refresh` | Refresh the index after a mixed reset, the default, or skip it | [Without refreshing the index](#without-refreshing-the-index) |
| `-q`, `--quiet` | Report only errors | [Without refreshing the index](#without-refreshing-the-index) |
| `--pathspec-from-file=<file>`, `--pathspec-file-nul` | Read the paths from a file instead of the command line | Chapter 11 |
| `--stdin`, `-z` | The deprecated spelling of the same | [Synopsis](#synopsis) |
| `--auto-advance`, `--no-auto-advance` | In `-p`, move to the next file on its own, or stay until you ask | Chapter 11 |
| `-U<n>`, `--unified=<n>`, `--inter-hunk-context=<n>` | How much context the chunks in `-p` show | Chapter 13 |
| `--recurse-submodules`, `--no-recurse-submodules` | Reset the working tree of active submodules too | Chapter 57 |

<!-- no-example: --stdin  the deprecated form of --pathspec-from-file=-; it is
     named in the synopsis with its replacement beside it, and showing it
     working would teach a spelling Git's own documentation tells readers to
     stop using -->
<!-- no-example: -z  only meaningful with --stdin, and deprecated with it -->

## The example repository

```console
$ git log --oneline --graph --all --decorate
* 45d69a0 (HEAD -> main) Go on to Evora
| * 751a3cb (detour) Go on to Faro
|/
* 577de10 Add the budget
* 432a5d9 Add the packing list
* b66f096 Add the route
* fd28311 Start the trip plan
$ git status --short --branch
## main
```

A trip plan: `README.md`, `route.md`, `packing.md` and `budget.md`, one per
commit. `detour` adds a different third day to `route.md` than `main` does, so
merging it conflicts.

Every example starts with `git switch -C try main`, which puts a scratch branch
`try` at `main` and switches to it (Chapter 24), so each begins from the same
commit with a clean working tree no matter what the last one did.

## The three things reset can touch

Three examples from exactly the same starting point: one commit to undo,
`Go on to Evora`, which changed `route.md`, and one edit of `packing.md` staged
by hand.

```console
$ git switch -q -C try main
$ git add packing.md && git status --short
M  packing.md
$ git reset --soft HEAD~1 && git status --short
M  packing.md
M  route.md
$ git log --oneline -2
577de10 Add the budget
432a5d9 Add the packing list
```

`--soft` moved the branch back one commit and touched nothing else. The change
that commit contained, to `route.md`, is now staged — the index still holds it,
and it is no longer in the branch, so `git status` reports it as staged. The
`packing.md` edit is untouched.

```console
$ git switch -q -C try main
$ git add packing.md && git reset HEAD~1
Unstaged changes after reset:
M	packing.md
M	route.md
$ git status --short
 M packing.md
 M route.md
```

`--mixed`, the default, went one step further: the index was made to match the
new `HEAD`, so nothing is staged any more. Both changes are still in the files,
now as unstaged modifications — the mark has moved from the first column to the
second (Chapter 10).

```console
$ git switch -q -C try main
$ git add packing.md && git reset --hard HEAD~1
HEAD is now at 577de10 Add the budget
$ git status --short && cat route.md
Day 1 Lisbon
Day 2 Sintra
```

`--hard` went all the way: `git status` prints nothing, and `route.md` has lost
its third day. Both the commit and the staged edit are gone from the files.

| You want | Mode |
|---|---|
| to redo the commit differently | `--soft` |
| to rebuild the commit from scratch, choosing what goes in | `--mixed` |
| to pretend none of it happened | `--hard` |
| to get out of a conflicted merge | `--merge` |
| to drop the last commits but keep what you are working on | `--keep` |

## --soft

```console
$ git switch -q -C try main
$ git reset --soft HEAD~1 && git status --short && git log --oneline -1
M  route.md
577de10 Add the budget
```

The most common use: the last commit was right about *what* changed and wrong
about something else — the message, the split, which branch it is on. `--soft`
takes the commit off the branch and leaves everything it contained staged,
ready to be committed again.

`git commit --amend` does the same job in one command when the commit is
staying where it is (Chapter 29).

### Squashing the last three commits

```console
$ git switch -q -C try main
$ git reset --soft HEAD~3 && git status --short
A  budget.md
A  packing.md
M  route.md
$ git commit -q -m 'Plan the trip' && git log --oneline
aaca29b Plan the trip
b66f096 Add the route
fd28311 Start the trip plan
```

`--soft` back three commits stages everything those three commits did, and one
`git commit` turns them into one. This is the quickest way to squash a run of
commits at the tip of a branch, and it needs no rebase; what it cannot do is
combine commits that are not at the tip, or keep any of the old messages
(Chapter 34).

### What --soft leaves alone

```console
$ git switch -q -C try main
$ git reset --soft HEAD~2 && git status --short
AM budget.md
M  route.md
```

`budget.md` had been edited in the working tree before the reset. `AM` means
the two columns disagree: staged as a new file, because the commit that added
it is no longer in the branch, and modified again since. `--soft` changed
nothing about the file — only the branch moved, and `git status` compares
against the new `HEAD`.

## --mixed, the default

```console
$ git switch -q -C try main
$ git reset --mixed HEAD~2 && git log --oneline -1
Unstaged changes after reset:
M	route.md
432a5d9 Add the packing list
$ git reset --mixed main && git log --oneline -1
45d69a0 Go on to Evora
```

`--mixed` is what you get when no mode is given, so it is rarely typed; the two
commands above only spell it out. The second is also the shape of "put this
branch back where that one is", which the [--hard](#hard) version of does more
thoroughly.

```console
$ git add budget.md && git reset
Unstaged changes after reset:
M	budget.md
$ git status --short
 M budget.md
```

With no commit named, `git reset` stays where it is and only clears the index:
it is the "unstage everything" command. The list it prints is not a warning —
it is every path that differs between the index and the working tree once the
reset is done, which after an unstage is exactly what you just unstaged.

### Moving the branch as well

```console
$ git switch -q -C try main
$ git reset HEAD~2 && git status --short
Unstaged changes after reset:
M	route.md
 M route.md
?? budget.md
```

Two commits undone: the changes to `route.md` are back as an unstaged
modification, and `budget.md` — a file that did not exist at `HEAD~2` — is
untracked. The file is still on disk, because `--mixed` never touches the
working tree; it is simply no longer in the index or in any commit the branch
reaches.

### A file the target commit does not have

```console
$ git switch -q -C try main
$ git reset -N HEAD~2 && git status --short
Unstaged changes after reset:
A	budget.md
M	route.md
 A budget.md
 M route.md
$ git diff --stat
 budget.md | 2 ++
 route.md  | 1 +
 2 files changed, 3 insertions(+)
```

`-N` records an *intent to add*: the path goes into the index with no content,
so Git knows it should be tracked without staging anything. The difference is
visible in the two commands above. Without `-N`, `budget.md` is untracked
(`??`) and `git diff` ignores it entirely, because `git diff` compares the index
with the working tree and untracked files are in neither. With `-N` it is ` A`,
and its contents appear in `git diff` as an addition.

That matters when the next step is `git add -p` to rebuild the commit in
pieces: without `-N`, the new file is invisible to it (Chapter 11).

### Without refreshing the index

```console
$ git switch -q -C try main
$ git add budget.md && git reset --no-refresh
$ git status --short
 M budget.md
```

A mixed reset normally refreshes the index afterwards — restating which files
differ from it — and that refresh is what prints the `Unstaged changes after
reset` list. `--no-refresh` skips it, so the command is silent, as the same
command with `-q` would be. The result in the index is the same; the reason to
skip it is speed in a very large repository, where the refresh has to stat
every file.

## --hard

```console
$ git switch -q -C try main
$ git add packing.md && git status --short
M  packing.md
 M route.md
$ git reset --hard
HEAD is now at 45d69a0 Go on to Evora
$ git status --short && cat route.md
Day 1 Lisbon
Day 2 Sintra
Day 3 Evora
```

With no commit named, `git reset --hard` throws away everything since the last
commit: staged and unstaged changes alike, with nothing kept anywhere. There is
no undo for this, because none of it was ever committed —
[Work that was staged and never
committed](#work-that-was-staged-and-never-committed) is the partial exception.

`--hard` also *removes* tracked files that the target commit does not have. In
[The three things reset can touch](#the-three-things-reset-can-touch) that was
visible as `route.md` losing a line; resetting back past the commit that added
`budget.md` deletes the file from disk.

### Untracked and ignored files

```console
$ git switch -q -C try main
$ git add .gitignore && git commit -q -m 'Ignore log files' && git status --short
?? scratch.txt
$ git reset --hard HEAD~1
HEAD is now at 45d69a0 Go on to Evora
$ git status --short && ls
?? debug.log
?? scratch.txt
README.md
budget.md
debug.log
packing.md
route.md
scratch.txt
```

Untracked files survive a `--hard` reset. `scratch.txt` was never added and is
still there; `debug.log` was ignored by the `.gitignore` in the commit that was
just undone, and with that commit gone it is untracked rather than ignored, but
it is still on disk.

This is the difference between `git reset --hard` and a clean checkout: reset
deals only in tracked files. `git clean` is what removes the rest, and it is
the command to be careful with (Chapter 14).

## --merge

```console
$ git switch -q -C try main
$ git merge detour
Auto-merging route.md
CONFLICT (content): Merge conflict in route.md
Automatic merge failed; fix conflicts and then commit the result.
$ git status --short
 M packing.md
UU route.md
$ git reset --merge
$ git status --short && git log --oneline -1
 M packing.md
45d69a0 Go on to Evora
```

The merge stopped with a conflict, and there was an unrelated edit to
`packing.md` in the working tree that was there before the merge started.
`git reset --merge` with no commit named cleared the conflict and left that
edit alone — `--hard` would have thrown it away too.

That is what the mode is for. Git's documentation puts it as: `--merge` resets
the index, updates the files that differ between the target and `HEAD`, and
keeps the files that differ between the index and the working tree, which is
exactly the set of changes a merge is guaranteed not to have touched.

`git merge --abort` is the same thing with a clearer name, and is what to reach
for while a merge is in progress (Chapter 25). `--merge` still matters for the
cases `--abort` does not cover: a merge that has already been committed, or a
conflict left by `git am -3` or `git switch -m`.

## --keep

```console
$ git switch -q -C try main
$ git reset --keep HEAD~1
$ git status --short && git log --oneline -1
 M packing.md
577de10 Add the budget
```

`--keep` drops the last commit and keeps what you are working on. `packing.md`
had an uncommitted edit; the branch moved back one commit, `route.md` was
reset to the older version, and the edit survived.

That is what people usually mean by "undo the commit but not my work", and it
differs from `--mixed` in updating the working tree for the files the reset
moved past, so nothing is left as a spurious modification.

### --keep refusing

```console
$ git switch -q -C try main
$ git reset --keep HEAD~1
error: Entry 'route.md' not uptodate. Cannot merge.
fatal: Could not reset index file to revision 'HEAD~1'.
$ git status --short && git log --oneline -1
 M route.md
45d69a0 Go on to Evora
```

Here the uncommitted edit is to `route.md`, the same file the commit being
dropped changed. Keeping both is impossible, so `--keep` refuses and changes
nothing: the branch has not moved and the edit is still there. That refusal is
the whole point of the mode — it will not silently choose between your work and
the commit.

```console
$ git reset --hard HEAD~1
HEAD is now at 577de10 Add the budget
$ git status --short && git log --oneline -1
577de10 Add the budget
```

`--hard` in the same situation does what it always does: the branch moves and
the edit to `route.md` is gone, with no warning at all.

## Every mode side by side

Git's documentation gives the full answer as a set of tables, one per
combination of file states. The short version, for a file that differs between
where you are and where you are going:

| Mode | If the file is unchanged locally | If you have uncommitted changes to it |
|---|---|---|
| `--soft` | left as it is; only the branch moves | left as it is |
| `--mixed` | index updated, file left as it is | index updated, file left as it is |
| `--hard` | file overwritten | file overwritten, changes lost |
| `--merge` | file updated | refuses, unless the change is only in the working tree |
| `--keep` | file updated | refuses |

Two things follow from it. `--soft` and `--mixed` never lose work but can leave
files that look modified when they are not. `--hard` never refuses and never
warns. `--merge` and `--keep` sit in between: they update what they safely can
and stop otherwise.

### When --merge refuses

```console
$ git switch -q -C try main
$ git add budget.md
$ git status --short
MM budget.md
$ git reset --merge HEAD~1
error: Entry 'budget.md' not uptodate. Cannot merge.
fatal: Could not reset index file to revision 'HEAD~1'.
$ git reset --soft HEAD~1 && git status --short
MM budget.md
M  route.md
```

`budget.md` differs from `HEAD` in the index *and* differs again in the working
tree — `MM`. Git's documentation explains the refusal: a mergy operation always
writes its result into the working tree, so a file that differs in both places
cannot have come from one, and `--merge` will not guess. `--soft` has no such
scruple, because it changes neither.

The same two-line error, `Entry ... not uptodate. Cannot merge.`, is what both
`--merge` and `--keep` print when they refuse.

## Resetting files instead of commits

```console
$ git switch -q -C try main
$ git add -A && git status --short
M  budget.md
M  packing.md
$ git reset -- packing.md
Unstaged changes after reset:
M	packing.md
$ git status --short
M  budget.md
 M packing.md
$ git reset
Unstaged changes after reset:
M	budget.md
M	packing.md
$ git status --short
 M budget.md
 M packing.md
```

With paths, `git reset` is the opposite of `git add`: it sets the staged
version of those paths back to the one in `HEAD` and leaves the files alone.
The branch does not move, no mode is involved, and nothing is lost.

A path that matches nothing is not an error — `git reset -- nosuchfile.md`
prints nothing and succeeds, where `git add` would complain.

### reset and restore --staged

```console
$ git switch -q -C try main
$ git add packing.md && git restore --staged packing.md && git status --short
 M packing.md
```

`git restore --staged <path>` does exactly what `git reset -- <path>` does, and
is the modern spelling: it cannot be confused with the form that moves a
branch, and `git status` suggests it rather than `reset` (Chapter 14).

| Modern | Classic |
|---|---|
| `git restore --staged <path>` | `git reset -- <path>` |
| `git restore --staged --worktree <path>` | `git checkout HEAD -- <path>` |
| `git restore --source=<commit> --staged <path>` | `git reset <commit> -- <path>` |

Git's documentation states the first of these as an equivalence; the difference
in what they print is real but the effect on the index is the same. The
transcript above and the one before it show both leaving `packing.md` as ` M`.

### The staged version from another commit

```console
$ git switch -q -C try main
$ git reset HEAD~1 -- route.md
Unstaged changes after reset:
M	route.md
$ git status --short && git diff --cached
MM route.md
diff --git a/route.md b/route.md
index c82ad91..b397be8 100644
--- a/route.md
+++ b/route.md
@@ -1,3 +1,2 @@
 Day 1 Lisbon
 Day 2 Sintra
-Day 3 Evora
$ git log --oneline -1
45d69a0 Go on to Evora
```

Naming a commit as well as a path stages that commit's version of the file.
The branch has not moved — `git log` still shows `Go on to Evora` — but the
index now holds `route.md` as it was one commit earlier, so the staged change
is a deletion of the third day, and committing would undo that part of the last
commit.

`MM` again: the index differs from `HEAD`, and the working tree differs from
the index, because the file on disk still has the line.

### reset with a path and a mode

```console
$ git reset --hard -- route.md
fatal: Cannot do hard reset with paths.
$ git reset --soft -- route.md
fatal: Cannot do soft reset with paths.
```

The two halves of the command cannot be combined. A mode says what to do with
the branch, the index and the working tree; with paths there is no branch
involved, so the mode has nothing to say. To put a file back in the working
tree as well, use `git restore --source=<commit> --staged --worktree <path>`
(Chapter 14).

### Unstaging part of a file

```console
$ git switch -q -C try main
$ git add itinerary.md && git commit -q -m 'Add the itinerary'
$ git add itinerary.md && git diff --cached --stat
 itinerary.md | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
$ printf 'n\ny\n' | git reset -p; echo
diff --git a/itinerary.md b/itinerary.md
index fa22a99..93b402c 100644
--- a/itinerary.md
+++ b/itinerary.md
@@ -1,4 +1,4 @@
-Day 1 Lisbon
+Day 1 Faro
 Day 2 Sintra
 Day 3 Evora
 Day 4 rest
(1/2) Unstage this hunk [y,n,q,a,d,k,K,j,J,g,/,e,p,P,?]? @@ -9,4 +9,4 @@ Day 8 rest
 Day 9 rest
 Day 10 rest
 Day 11 rest
-Day 12 Porto
+Day 12 Braga
(2/2) Unstage this hunk [y,n,q,a,d,K,J,g,/,e,p,P,?]?

$ git status --short && git diff --cached
MM itinerary.md
diff --git a/itinerary.md b/itinerary.md
index fa22a99..c4a5104 100644
--- a/itinerary.md
+++ b/itinerary.md
@@ -1,4 +1,4 @@
-Day 1 Lisbon
+Day 1 Faro
 Day 2 Sintra
 Day 3 Evora
 Day 4 rest
```

`git reset -p` asks about each chunk of the difference between the index and
`HEAD`, and unstages the ones you say yes to. It is the exact opposite of
`git add -p`, down to the keys it accepts, which Chapter 11 lists in full.

The `printf` stands for typing the answers: `n` to the first chunk, `y` to the
second. Piped input is not echoed and the question has no newline after it,
which is why `(1/2) Unstage this hunk ...?` and the second chunk's `@@` line
run together on one line here; at a terminal you would type `n`, press Enter,
and see the next chunk below.

Afterwards the first chunk is still staged and the second is not, so the file
is `MM`: staged with one change, and different again on disk.

## ORIG_HEAD

```console
$ git switch -q -C try main
$ git reset --hard HEAD~2 && git log --oneline -1
HEAD is now at 432a5d9 Add the packing list
432a5d9 Add the packing list
$ git log --oneline -1 ORIG_HEAD
45d69a0 Go on to Evora
$ git reset --hard ORIG_HEAD && git log --oneline -1
HEAD is now at 45d69a0 Go on to Evora
45d69a0 Go on to Evora
```

Before moving the branch, `git reset` writes where it was to `ORIG_HEAD`, so
`git reset --hard ORIG_HEAD` undoes the reset. `git merge`, `git pull`,
`git rebase` and `git am` set it too, which is why `git reset --hard ORIG_HEAD`
is the standard way to undo a merge (Chapter 25).

It holds one value, the last one written. A second reset overwrites it, and
then only the reflog remembers the first — see [Undoing a
reset](#undoing-a-reset).

## Resetting somewhere other than backwards

```console
$ git switch -q -C try main
$ git reset --hard HEAD~3 && git log --oneline
HEAD is now at b66f096 Add the route
b66f096 Add the route
fd28311 Start the trip plan
$ git reset --hard main && git log --oneline -1
HEAD is now at 45d69a0 Go on to Evora
45d69a0 Go on to Evora
$ git reset --hard detour && git log --oneline -2
HEAD is now at 751a3cb Go on to Faro
751a3cb Go on to Faro
577de10 Add the budget
$ git status --short
```

`<commit>` is any commit, not only an ancestor. The second command moved `try`
forward again by naming another branch, and the third moved it sideways onto
`detour`, which is not in its history at all: `git reset --hard <branch>` makes
the current branch identical to another one, files included, which is the usual
way to say "throw mine away and use theirs".

> **Careful.** `git reset --hard origin/main` is the standard way to make a
> local branch match the remote exactly, and it discards every local commit that
> is not on the remote, silently. Check first with
> `git log --oneline origin/main..HEAD` (Chapter 28).

### Moving a branch you are not on

```console
$ git switch -q main && git log --oneline -1 try
751a3cb Go on to Faro
$ git branch -f try main~1 && git log --oneline -1 try
577de10 Add the budget
$ git log --oneline -1
45d69a0 Go on to Evora
```

`git reset` always acts on the branch you are on; it takes no branch argument.
To move a different branch, `git branch -f <branch> <commit>` does the same job
without switching (Chapter 23) — and, because there is no working tree
involved, without any of the modes. `main` did not move here, and neither did
the files.

## What reset never touches

```console
$ git switch -q -C try main
$ git stash push -q -m 'packing ideas' && git stash list
stash@{0}: On try: packing ideas
$ git reset --hard HEAD~2 && git stash list
HEAD is now at 432a5d9 Add the packing list
stash@{0}: On try: packing ideas
$ git log --oneline --decorate -1 main && git log --oneline --decorate -1 detour
45d69a0 (main) Go on to Evora
751a3cb (detour) Go on to Faro
```

A `--hard` reset of `try` left the stash exactly where it was and both other
branches where they were. Nothing outside the current branch, the index and the
working tree is affected: not other branches, not tags, not the stash, not
remote-tracking branches, and nothing on any server.

That is worth saying plainly because `--hard` feels drastic. It is drastic
about one branch and the files in front of you, and about nothing else.

## When reset refuses

```console
$ git switch -q -C try main
$ git reset --soft HEAD~1 -- route.md
fatal: Cannot do soft reset with paths.
$ git reset --hard nosuchcommit
fatal: ambiguous argument 'nosuchcommit': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
$ git reset -- nosuchfile.md
$ git switch -q --orphan nothing-yet && git reset --hard HEAD~1
fatal: ambiguous argument 'HEAD~1': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
$ git reset && git status --short
```

| Message | Means |
|---|---|
| `Cannot do soft reset with paths.` | a mode and a pathspec in one command; pick one |
| `ambiguous argument '<name>'` | nothing of that name exists, so Git wondered whether it was a file |
| nothing at all | a pathspec that matches nothing is not an error |

The last two commands are on a branch with no commits, made with
`git switch --orphan`. `HEAD~1` cannot be resolved because there is no `HEAD`
commit — the same message a brand-new repository gives. A plain `git reset`
still works there and empties the index, because it has a target: the empty
tree.

### In the middle of a merge

```console
$ git switch -q -C try main
$ git merge detour
Auto-merging route.md
CONFLICT (content): Merge conflict in route.md
Automatic merge failed; fix conflicts and then commit the result.
$ git status --short
UU route.md
$ git reset --soft HEAD~1
fatal: Cannot do a soft reset in the middle of a merge.
$ git reset --merge && git status --short && git log --oneline -1
45d69a0 Go on to Evora
```

While a merge is unfinished the index holds several versions of the conflicted
files, and `--soft` would leave those unmerged entries in place while moving
the branch out from under them. Git refuses rather than produce that state.
`--mixed`, `--hard` and `--merge` all work, because each rewrites the index.

### In a bare repository

```console
$ git -C /home/ada/trip.git reset --hard HEAD
fatal: this operation must be run in a work tree
$ git -C /home/ada/trip.git reset --soft HEAD~1 && git -C /home/ada/trip.git log --oneline -1
577de10 Add the budget
```

A bare repository has no working tree and no index worth the name, so `--hard`
and the other modes that touch files have nothing to work on. `--soft` is
different: moving a branch needs neither, and it works. That is the one way to
move a branch on a server-side repository with `reset`, though `git branch -f`
or `git update-ref` are the usual tools (Chapter 23, Chapter 74).

## Undoing a reset

```console
$ git switch -q -C try main
$ git reset --hard HEAD~2 && git log --oneline -1
HEAD is now at 432a5d9 Add the packing list
432a5d9 Add the packing list
$ git reflog show try -3
432a5d9 try@{0}: reset: moving to HEAD~2
45d69a0 try@{1}: branch: Reset to main
432a5d9 try@{2}: reset: moving to HEAD~2
$ git reset --hard try@{1} && git log --oneline -1
HEAD is now at 45d69a0 Go on to Evora
45d69a0 Go on to Evora
```

Every reset writes a reflog entry saying where the branch went, so the entry
below it says where it came from. `try@{1}` is that position, and resetting to
it puts the branch back.

`ORIG_HEAD` does the same job for the *last* reset and is shorter to type; the
reflog goes back further, which is what you need after two resets in a row, or
after a merge overwrote `ORIG_HEAD`. Chapter 36 covers it in full.

### Work that was staged and never committed

```console
$ git add list.md && git rev-parse :list.md
4cb29ea38f70d7c61b2a3a25b02e3bdf44905402
$ git reset --hard HEAD
HEAD is now at 6a40be6 Start a list
$ git status --short && cat list.md
one
two
$ git fsck --lost-found
dangling blob 4cb29ea38f70d7c61b2a3a25b02e3bdf44905402
$ git cat-file -p 4cb29ea38f70d7c61b2a3a25b02e3bdf44905402
one
two
three
$ git cat-file -p 4cb29ea38f70d7c61b2a3a25b02e3bdf44905402 > list.md && cat list.md
one
two
three
```

This runs in a separate small repository, so that the only lost object in it is
the one the example is looking for.

A `--hard` reset threw away a staged change, and no reflog records it, because
nothing was ever committed. But `git add` had already written the file's
content into the repository as a blob — that is what `git rev-parse :list.md`
printed, the object id of the staged version — and the object survives the
reset. `git fsck --lost-found` lists objects nothing reaches, and
`git cat-file -p` prints one out.

This only works for content that reached the index. An edit that was never
staged has never been in the repository at all, and no Git command can bring it
back. Chapter 77 covers `git fsck` and Chapter 79 the whole recovery procedure.

> **Careful.** `git gc` deletes unreachable objects that are more than two
> weeks old, and runs on its own from time to time. The window is wide but not
> infinite.

## reset, restore, revert and checkout

Four commands that all undo something. Git's own documentation separates them
by what they change:

| Command | Changes | Chapter |
|---|---|---|
| `git reset` | which commit the branch points at, and optionally the index and working tree | this chapter |
| `git restore` | files in the working tree or the index; never the branch | Chapter 14 |
| `git revert` | nothing that exists; it adds a new commit that undoes an old one | Chapter 31 |
| `git checkout` | either, depending on the arguments, which is why the other three exist | Chapter 24 |

| What you want | Command |
|---|---|
| Undo the last commit, keep the changes | `git reset --soft HEAD~1` |
| Undo the last commit and the changes | `git reset --hard HEAD~1` |
| Unstage a file | `git restore --staged <file>` |
| Throw away edits to a file | `git restore <file>` |
| Throw away every edit since the last commit | `git reset --hard` |
| Undo a commit other people have | `git revert <commit>` |
| Look at an old commit without moving the branch | `git switch --detach <commit>` |

**Is `git reset --hard <commit>` the same as `git checkout <commit>`?** No, and
the difference is the whole point of the branch. `git reset --hard` moves the
current branch to that commit, so the commits it left are no longer on the
branch. `git checkout <commit>` leaves every branch where it is and detaches
`HEAD` (Chapter 24). One is a rewrite, the other is a look around.

## The settings

`git reset` has no configuration of its own — there is no `reset.*` section in
Git's documentation. These change its behaviour from elsewhere.

| Setting | Does |
|---|---|
| `submodule.recurse` | Makes `--recurse-submodules` the default, so a reset updates submodule working trees too (Chapter 57) |
| `core.logAllRefUpdates` | Whether the reflog that makes a reset undoable is written at all; off in a bare repository (Chapter 36) |
| `gc.reflogExpire`, `gc.reflogExpireUnreachable` | How long that reflog keeps the commits you reset away: 30 days by default, in every version (Chapter 36) |
| `gc.pruneExpire` | How long an unreachable object survives, two weeks, which is the window for recovering staged work (Chapter 77) |
| `diff.context` | How much context `git reset -p` shows around each chunk (Chapter 13) |
