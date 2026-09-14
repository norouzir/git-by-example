# Chapter 14. Undoing Local Changes with restore

## What it is

This chapter covers undoing work that has not been committed. Undoing commits
is Chapters 30 and 31; getting back things you thought were gone is Chapter 78.

`git restore` puts files back the way they were: in your working tree, in the
index, or both, taken from the index or from any commit. It never moves a branch
and never makes a commit, so history is untouched. What it can destroy is work
you have not committed, and the chapter says clearly each time that happens.

Its neighbour `git clean` handles what `restore` cannot: files Git has never
tracked. Both are here, because "make my working tree clean again" usually needs
the two together.

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What does `git restore` change, and what can it never change?](#what-it-is)

**[Synopsis](#synopsis)**

- [What can I type after `git restore` and `git clean`?](#synopsis)

**[Options at a glance](#options-at-a-glance)**

- [Is there a list of every `git restore` option, and where each is explained?](#git-restore-options)
- [Is there a list of every `git clean` option?](#git-clean-options)

**[The one-sentence model](#the-one-sentence-model)**

- [Where does `git restore` copy from, and where to?](#the-one-sentence-model)

**[Throwing away an unstaged edit](#throwing-away-an-unstaged-edit)**

- [How do I throw away changes to a file I haven't staged?](#throwing-away-an-unstaged-edit)
- [I ran `git restore` on the wrong file. Can I get my changes back?](#throwing-away-an-unstaged-edit)

**[Unstaging without losing the edit](#unstaging-without-losing-the-edit)**

- [How do I unstage a file but keep my changes?](#unstaging-without-losing-the-edit)
- [What happens if I unstage a new file?](#unstaging-without-losing-the-edit)

**[Both at once](#both-at-once)**

- [How do I make a file exactly as it was in the last commit?](#both-at-once)
- [What do `-SW` and `-s@` mean?](#both-at-once)

**[Restoring from a different commit](#restoring-from-a-different-commit)**

- [How do I get an old version of a file back without changing history?](#restoring-from-a-different-commit)
- [Can I take a file from another branch?](#restoring-from-a-different-commit)
- [What does `main...other` mean as a source?](#restoring-from-a-different-commit)

**[Bringing back a deleted file](#bringing-back-a-deleted-file)**

- [I deleted a file by accident. How do I get it back?](#bringing-back-a-deleted-file)
- [How do I recover a file that was deleted several commits ago?](#bringing-back-a-deleted-file)

**[Restoring everything](#restoring-everything)**

- [How do I throw away every change in the project?](#restoring-everything)
- [Why did `git restore .` leave changes in other folders?](#restoring-everything)
- [Can I restore all files matching a pattern, even deleted ones?](#restoring-everything)

**[Choosing what to throw away](#choosing-what-to-throw-away)**

- [Can I throw away some changes in a file and keep others?](#choosing-what-to-throw-away)
- [Can I unstage only part of a file?](#choosing-what-to-throw-away)
- [Why did `git restore -SW -p` say the hunks "do not apply to the index"?](#choosing-what-to-throw-away)

**[The silent one](#the-silent-one)**

- [I restored a folder from an old commit and some files disappeared. Why?](#the-silent-one)
- [How do I restore old files without deleting newer ones?](#the-silent-one)

**[During a conflict](#during-a-conflict)**

- [How do I take my version or their version of a conflicted file?](#during-a-conflict)
- [I messed up resolving a conflict. Can I get the conflict markers back?](#during-a-conflict)
- [What do the `diff3` and `zdiff3` conflict styles show?](#during-a-conflict)
- [Why does `git restore` say "path is unmerged"?](#during-a-conflict)

**[Paths from a file](#paths-from-a-file)**

- [Can I give `git restore` a list of files?](#paths-from-a-file)

**[Sparse checkouts](#sparse-checkouts)**

- [Why does restore say a file "did not match" when it's in the repository?](#sparse-checkouts)

**[Untracked files are somebody else's job](#untracked-files-are-somebody-else-s-job)**

- [Why doesn't `git restore .` delete my new files?](#untracked-files-are-somebody-else-s-job)
- [How do I delete all untracked files safely?](#untracked-files-are-somebody-else-s-job)
- [Why didn't `git clean -f` remove a folder?](#what-git-clean-removes)
- [How do I remove only ignored files, like build output?](#what-git-clean-removes)
- [Why didn't `git clean` delete a folder that contains another repository?](#what-git-clean-removes)
- [Can I pick which files `git clean` deletes?](#choosing-interactively)

**[The classic equivalents](#the-classic-equivalents)**

- [What did people use before `git restore`?](#the-classic-equivalents)
- [Is `git checkout -- file` exactly the same as `git restore file`?](#where-the-classic-forms-differ)
- [Why does `git checkout <name>` sometimes switch branch instead of restoring a file?](#where-the-classic-forms-differ)

**[restore, reset and revert](#restore-reset-and-revert)**

- [What is the difference between `restore`, `reset` and `revert`?](#restore-reset-and-revert)

**[The settings](#the-settings)**

- [Which settings affect `git restore` and `git clean`?](#the-settings)

</details>

## Synopsis

```
git restore [<options>] [--source=<tree>] [--staged] [--worktree] [--] <pathspec>...
git restore [<options>] [--source=<tree>] [--staged] [--worktree] --pathspec-from-file=<file> [--pathspec-file-nul]
git restore (-p|--patch) [<options>] [--source=<tree>] [--staged] [--worktree] [--] [<pathspec>...]

git clean [-d] [-f] [-i] [-n] [-q] [-e <pattern>] [-x | -X] [--] [<pathspec>...]
```

| Part | Means |
|---|---|
| `<pathspec>` | Which files. Required, except with `-p` (Chapter 11 covers pathspecs) |
| `<tree>` | Where to take content from: a commit, a branch, a tag |
| `--` | Everything after it is a path |

| Command | Does |
|---|---|
| `git restore <file>` | Throw away unstaged changes to a file |
| `git restore --staged <file>` | Unstage a file, keeping the changes |
| `git restore --staged --worktree <file>` | Make a file match the last commit, in both places |
| `git restore --source=<commit> <file>` | Put an old version in the working tree |
| `git restore -p` | Choose which changes to throw away |
| `git clean -n` | List untracked files that would be deleted |

## Options at a glance

### git restore options

| Option | Does | Covered in |
|---|---|---|
| `-W`, `--worktree` | Restore the working tree. The default if neither is given | [The one-sentence model](#the-one-sentence-model) |
| `-S`, `--staged` | Restore the index | [Unstaging without losing the edit](#unstaging-without-losing-the-edit) |
| `-s <tree>`, `--source=<tree>` | Restore from this commit or tree instead of the index | [Restoring from a different commit](#restoring-from-a-different-commit) |
| `-p`, `--patch` | Choose hunk by hunk | [Choosing what to throw away](#choosing-what-to-throw-away) |
| `-U<n>`, `--unified=<n>` | Context lines for `-p` | [Choosing what to throw away](#choosing-what-to-throw-away) |
| `--inter-hunk-context=<n>` | Join nearby hunks for `-p` | [Choosing what to throw away](#choosing-what-to-throw-away) |
| `--overlay`, `--no-overlay` | Whether to remove files absent from the source. `--no-overlay` is the default | [The silent one](#the-silent-one) |
| `--ours`, `-2` | During a conflict, take our side (Chapter 26) | [During a conflict](#during-a-conflict) |
| `--theirs`, `-3` | During a conflict, take their side | [During a conflict](#during-a-conflict) |
| `-m`, `--merge` | Recreate the conflict markers | [During a conflict](#during-a-conflict) |
| `--conflict=merge` | Recreate the markers with both sides | [During a conflict](#during-a-conflict) |
| `--conflict=diff3` | Recreate them with the common ancestor too | [During a conflict](#during-a-conflict) |
| `--conflict=zdiff3` | Like `diff3`, with lines both sides share moved out of the conflict | [During a conflict](#during-a-conflict) |
| `--ignore-unmerged` | Do not fail on unmerged paths | [During a conflict](#during-a-conflict) |
| `-q`, `--quiet` | Say nothing | [During a conflict](#during-a-conflict) |
| `--pathspec-from-file=<file>` | Read paths from a file | [Paths from a file](#paths-from-a-file) |
| `--pathspec-file-nul` | Those paths are NUL-separated | [Paths from a file](#paths-from-a-file) |
| `--ignore-skip-worktree-bits` | In a sparse checkout, restore paths outside it too (Chapter 60) | [Sparse checkouts](#sparse-checkouts) |
| `--progress`, `--no-progress` | Force progress output on or off | [The one-sentence model](#the-one-sentence-model) |
| `--recurse-submodules`, `--no-recurse-submodules` | Also restore submodules' working trees | Chapter 57 |

<!-- no-example: --progress
     Restoring thirty files with --progress printed nothing at all, the same
     as without it: the update finished before there was any progress to
     report. No transcript the sandbox can produce shows the option doing
     anything. -->

### git clean options

| Option | Does | Covered in |
|---|---|---|
| `-n`, `--dry-run` | List what would be removed | [Untracked files are somebody else's job](#untracked-files-are-somebody-else-s-job) |
| `-f`, `--force` | Actually remove. Required, unless `clean.requireForce` is false | [Untracked files are somebody else's job](#untracked-files-are-somebody-else-s-job) |
| `-d` | Include untracked directories | [What git clean removes](#what-git-clean-removes) |
| `-x` | Also remove ignored files | [What git clean removes](#what-git-clean-removes) |
| `-X` | Remove *only* ignored files, keeping other untracked ones | [What git clean removes](#what-git-clean-removes) |
| `-e <pattern>`, `--exclude=<pattern>` | Add an extra exclude pattern for this run | [What git clean removes](#what-git-clean-removes) |
| `-q`, `--quiet` | Do not list what was removed | [What git clean removes](#what-git-clean-removes) |
| `-i`, `--interactive` | Choose from a menu | [Choosing interactively](#choosing-interactively) |

## The one-sentence model

`git restore` copies content from a source into a destination.

| Flag | Destination |
|---|---|
| (none) | The working tree |
| `--staged` | The index |
| `--staged --worktree` | Both |

| Flag | Source |
|---|---|
| (none) | The index |
| (none, with `--staged`) | `HEAD` |
| `--source=<commit>` | That commit |

Everything else in this chapter follows from those two tables.

`--worktree` names the default destination; it only needs saying when
`--staged` is also given. `git restore` prints nothing when it succeeds, as
every example below shows. `--progress` asks for a progress report even when
the output is not a terminal, for a restore slow enough to need one; restoring
thirty files in the sandbox printed nothing with it or without it.

## Throwing away an unstaged edit

```console
$ git status --short
 M a.txt
$ git restore a.txt
$ git status --short
$ cat a.txt
second version of a
```

The file went back to its index version and the edit is gone.

> **Careful.** This is the most destructive everyday command in Git. The
> content you overwrote was never staged, so it was never written to an
> object, so there is nothing anywhere to recover it from. Not the reflog, not
> `git fsck`, nothing. Chapter 78 lists what can be recovered and this is on
> the other list.
>
> The habit that prevents it: `git add` early and often. A staged change is
> recoverable even after you overwrite it, because the blob exists.

## Unstaging without losing the edit

```console
$ git status --short
M  b.txt
$ git restore --staged b.txt
$ git status --short
 M b.txt
$ cat b.txt
a good edit
```

The letter moved from the left column to the right. The index went back to
matching `HEAD`, and the working tree was not touched at all. This one is
completely safe.

A new file has no version in `HEAD`, so unstaging it takes it out of the index
altogether and it is untracked again:

```console
$ git add new.txt && git status --short
A  new.txt
$ git restore --staged new.txt && git status --short
?? new.txt
```

Before the very first commit there is no `HEAD` at all, and `--staged` fails;
Chapter 11 shows the error and the way round it.

## Both at once

```console
$ git status --short
 M b.txt
MM c.txt
$ git restore --staged --worktree c.txt
$ git status --short
 M b.txt
$ cat c.txt
original c
```

`c.txt` was staged *and* modified again, and both are gone. The two flags
together mean "make this file look like `HEAD` again", which is the nuclear
option for a single file.

The short forms, which Git's own documentation calls more practical but less
readable:

```console
$ git status --short
MM a.txt
$ git restore -SW a.txt && git status --short
$ git restore -s@ -SW a.txt && git status --short
```

`-S` is `--staged`, `-W` is `--worktree`, and they combine as `-SW`. `-s@` is
`--source=HEAD`, because `@` on its own means `HEAD` (Chapter 18). The second
command found nothing left to do.

## Restoring from a different commit

```console
$ git log --oneline
0008e6b Second commit
1522806 First commit
$ git restore --source=HEAD~1 a.txt
$ git status --short
 M a.txt
 M b.txt
$ cat a.txt
original a
$ git diff
diff --git a/a.txt b/a.txt
index 61e59bf..37c76c2 100644
--- a/a.txt
+++ b/a.txt
@@ -1 +1 @@
-second version of a
+original a
diff --git a/b.txt b/b.txt
index b5153d8..be2755f 100644
--- a/b.txt
+++ b/b.txt
@@ -1 +1 @@
-original b
+a good edit
$ git restore --source=HEAD a.txt
$ git status --short
 M b.txt
```

The working tree now holds an old version, and Git reports it as an ordinary
modification, because that is exactly what it is. Nothing about the branch or
the history changed. (`b.txt` is the edit left unstaged two sections ago.)

This is how you look at how a file used to be while still being able to run the
rest of the project. To put it back, restore it from `HEAD`, as the last command
did.

`-s` is the short form of `--source`.

> **Careful.** `--source` implies nothing about the index. `git restore
> --source=HEAD~5 file.txt` changes only your working tree, so the next
> `git status` shows a modification you may not remember making. Add `--staged`
> if you intend to commit the old version.

The source can be anything that names a commit. Here `other` is a branch, and
the file was `v1` in the first commit, `from other` on `other`, and `v2` on
`main`:

```console
$ git restore --source=other a.txt && cat a.txt
from other
$ git restore --source=main...other a.txt && cat a.txt
v1
$ git restore -s ...other a.txt && cat a.txt
v1
$ git restore --source=HEAD~1 --staged a.txt && git status --short
M  a.txt
$ git restore -SW a.txt
$ git restore --source=nonexistent a.txt
fatal: could not resolve 'nonexistent'
```

`main...other` with three dots, only as a source, means the *merge base* of the
two branches: the last commit they have in common, where `a.txt` was `v1`. Git's
documentation allows leaving one side out, which stands for `HEAD`. Chapter 76
covers merge bases. `--staged` with a source staged the old version without
touching the working tree.

## Bringing back a deleted file

```console
$ git status --short
 D b.txt
$ git restore b.txt
$ ls
a.txt
b.txt
c.txt
```

And if the deletion was already staged, undo both halves:

```console
$ git status --short
D  b.txt
$ git restore --staged --worktree b.txt
$ git status --short
$ cat b.txt
original b
```

A file deleted in an earlier commit is not in the index or in `HEAD`. It is in
the parent of the commit that deleted it:

```console
$ git log --oneline --diff-filter=D -- old.txt
e571def Remove old.txt
$ git restore --source=HEAD~1^ old.txt && cat old.txt && git status --short
old content
?? old.txt
```

`git log --diff-filter=D` lists the commits that deleted the path (Chapter 17);
here that commit is `HEAD~1`, and `HEAD~1^` is the one before it (Chapter 18).
The file came back as untracked, because only the working tree was restored.
`git add` it to keep it.

## Restoring everything

```console
$ git status --short
 M a.txt
 M b.txt
 M c.txt
$ git restore .
$ git status --short
```

`git restore .` takes a pathspec like every other command, so the full
vocabulary from Chapter 11 applies, including `:/` for the whole repository
from anywhere and `:!pattern` to exclude.

> **Careful.** `git restore .` from a subdirectory restores only that
> subdirectory. Use `git restore :/` when you mean everything.

Here `keep.txt` at the top was changed and `src/a.c` deleted:

```console
$ cd src
$ git restore . && git status --short
 M ../keep.txt
$ git restore :/ && git status --short
```

A quoted pattern is matched against the index, not against the files on disk,
so it brings back deleted files too, as Git's documentation points out:

```console
$ git status --short
 D src/a.c
 D src/b.c
$ git restore 'src/*.c' && git status --short
```

Unquoted, the shell would have found no `.c` files in `src` to expand the
pattern to. A path is required; without one, restore refuses rather than
guessing that you meant everything:

```console
$ git restore
fatal: you must specify path(s) to restore
```

## Choosing what to throw away

```console
$ printf 'y\nn\n' | git restore -p poem.txt
diff --git a/poem.txt b/poem.txt
index c9e9e05..d96039a 100644
--- a/poem.txt
+++ b/poem.txt
@@ -1,4 +1,4 @@
-one
+ONE
 two
 three
 four
(1/2) Discard this hunk from worktree [y,n,q,a,d,k,K,j,J,g,/,e,p,P,?]? @@ -7,4 +7,4 @@ six
 seven
 eight
 nine
-ten
+TEN
(2/2) Discard this hunk from worktree [y,n,q,a,d,K,J,g,/,e,p,P,?]? 
$ cat poem.txt
one
two
three
four
five
six
seven
eight
nine
TEN
```

The first change was discarded, the second kept. Same keys as `git add -p`
(Chapter 11), but read the prompt: it says **discard**, not stage. Answering
`y` here destroys work rather than saving it, which is the opposite of the
muscle memory you built with `add -p`. As in Chapter 11, `printf` feeds in the
answers you would type.

The question changes with the direction, so it always says what `y` will do:

```console
$ git add poem.txt
$ printf 'y\nn\n' | git restore --staged -p poem.txt
diff --git a/poem.txt b/poem.txt
index c9e9e05..d96039a 100644
--- a/poem.txt
+++ b/poem.txt
@@ -1,4 +1,4 @@
-one
+ONE
 two
 three
 four
(1/2) Unstage this hunk [y,n,q,a,d,k,K,j,J,g,/,e,p,P,?]? @@ -7,4 +7,4 @@ six
 seven
 eight
 nine
-ten
+TEN
(2/2) Unstage this hunk [y,n,q,a,d,K,J,g,/,e,p,P,?]? 
$ git status --short && git diff --staged --stat
MM poem.txt
 poem.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git add poem.txt
$ printf 'y\nn\n' | git restore -SW -p poem.txt
diff --git a/poem.txt b/poem.txt
index c9e9e05..d96039a 100644
--- a/poem.txt
+++ b/poem.txt
@@ -1,4 +1,4 @@
-one
+ONE
 two
 three
 four
(1/2) Discard this hunk from index and worktree [y,n,q,a,d,k,K,j,J,g,/,e,p,P,?]? @@ -7,4 +7,4 @@ six
 seven
 eight
 nine
-ten
+TEN
(2/2) Discard this hunk from index and worktree [y,n,q,a,d,K,J,g,/,e,p,P,?]? 
$ git status --short && head -1 poem.txt
M  poem.txt
one
```

With `--staged`, `y` unstaged the first change and left it in the file. With
both, it removed the first change from both places, and the second stayed
staged.

Both places must contain the change for that to work. Here the second change is
only in the working tree:

```console
$ git restore --staged poem.txt
$ printf 'y\ny\n' | git restore -SW -p poem.txt
diff --git a/poem.txt b/poem.txt
index c9e9e05..edf6008 100644
--- a/poem.txt
+++ b/poem.txt
@@ -7,4 +7,4 @@ six
 seven
 eight
 nine
-ten
+TEN
(1/1) Discard this hunk from index and worktree [y,n,q,a,d,e,p,P,?]? error: patch failed: poem.txt:7
error: poem.txt: patch does not apply
The selected hunks do not apply to the index!
Apply them to the worktree anyway? 
$ git status --short && tail -1 poem.txt
ten
```

The index had nothing to remove, so Git asked whether to change the working
tree alone, and the second `y` said yes.

From another commit, `y` means applying the old version:

```console
$ printf 'y\nn\n' | git restore --source=HEAD~1 -p poem.txt && cat poem.txt
diff --git b/poem.txt a/poem.txt
index d96039a..c9e9e05 100644
--- b/poem.txt
+++ a/poem.txt
@@ -1,4 +1,4 @@
-ONE
+one
 two
 three
 four
(1/2) Apply this hunk to worktree [y,n,q,a,d,k,K,j,J,g,/,e,p,P,?]? @@ -7,4 +7,4 @@ six
 seven
 eight
 nine
-TEN
+ten
(2/2) Apply this hunk to worktree [y,n,q,a,d,K,J,g,/,e,p,P,?]? 
one
two
three
four
five
six
seven
eight
nine
TEN
```

Here the capitals had been committed, so `HEAD~1` holds the lower-case version.
The diff is shown from the file's point of view, with `b/` and `a/` swapped, so
that `+` is what `y` would bring in.

| Command | The prompt says | `y` |
|---|---|---|
| `git restore -p` | Discard this hunk from worktree | throws the change away |
| `git restore --staged -p` | Unstage this hunk | takes it out of the index, keeps it in the file |
| `git restore -SW -p` | Discard this hunk from index and worktree | throws it away from both |
| `git restore --source=<commit> -p` | Apply this hunk to worktree | brings in the older content |

The hunks can be shaped as in `git add -p`, and `-p` is the one form that needs
no path:

```console
$ printf 'n\nn\n' | git restore -p -U1 poem.txt
diff --git a/poem.txt b/poem.txt
index d96039a..c9e9e05 100644
--- a/poem.txt
+++ b/poem.txt
@@ -1,2 +1,2 @@
-ONE
+one
 two
(1/2) Discard this hunk from worktree [y,n,q,a,d,k,K,j,J,g,/,e,p,P,?]? @@ -9,2 +9,2 @@ eight
 nine
-TEN
+ten
(2/2) Discard this hunk from worktree [y,n,q,a,d,K,J,g,/,e,p,P,?]? 
$ printf 'n\n' | git restore -p --inter-hunk-context=4 poem.txt
diff --git a/poem.txt b/poem.txt
index d96039a..c9e9e05 100644
--- a/poem.txt
+++ b/poem.txt
@@ -1,10 +1,10 @@
-ONE
+one
 two
 three
 four
 five
 six
 seven
 eight
 nine
-TEN
+ten
(1/1) Discard this hunk from worktree [y,n,q,a,d,s,e,p,P,?]? 
$ printf 'n\nn\n' | git restore -p
diff --git a/poem.txt b/poem.txt
index d96039a..c9e9e05 100644
--- a/poem.txt
+++ b/poem.txt
@@ -1,4 +1,4 @@
-ONE
+one
 two
 three
 four
(1/2) Discard this hunk from worktree [y,n,q,a,d,k,K,j,J,g,/,e,p,P,?]? @@ -7,4 +7,4 @@ six
 seven
 eight
 nine
-TEN
+ten
(2/2) Discard this hunk from worktree [y,n,q,a,d,K,J,g,/,e,p,P,?]? 
```

In these three the capitals were committed and the file was changed back to
lower case, so every hunk turns `ONE` back into `one`.

> **Since Git 2.51.** `-U` and `--inter-hunk-context`.

## The silent one

Restoring a path from a commit where that path does not exist does not produce
an error. It deletes the file.

```console
$ ls poem.txt
poem.txt
$ git log --oneline -- poem.txt
ddf4ff0 Add poem
$ git restore --source=HEAD~1 poem.txt
$ ls poem.txt
ls: cannot access 'poem.txt': No such file or directory
$ git status --short
 D poem.txt
```

`poem.txt` was added in the last commit, so in `HEAD~1` it does not exist, so
restoring it from there means making the working tree match: absent. Git said
nothing.

The same with `--staged` stages the deletion:

```console
$ git restore --staged --source=HEAD~1 poem.txt
$ git status --short
D  poem.txt
```

> **Careful.** This is consistent and it is still a trap. If you restore a
> directory from an old commit, every file added since then disappears, with
> no message. Check with `git status` afterwards, always. The fix is
> `git restore --staged --worktree <path>` with no `--source`, which brings
> everything back from `HEAD`.

Compare with the error you get for a path Git has never heard of:

```console
$ git restore no-such-file.txt
error: pathspec 'no-such-file.txt' did not match any file(s) known to git
```

So Git errors on a path it does not track, and silently deletes a path it does
track but that is absent from your chosen source. Knowing which is which saves
an afternoon.

`--overlay` turns the deletion off. Here `dir/y.txt` was added after `HEAD~1`:

```console
$ git restore --source=HEAD~1 dir && git status --short
 D dir/y.txt
$ git restore dir
$ git restore --source=HEAD~1 --overlay dir && git status --short && ls dir
x.txt
y.txt
```

> **Worth knowing.** `--no-overlay` being the default is the mechanism behind
> the silent deletion above. In overlay mode Git only adds and updates files
> and never removes one, which is how `git checkout <commit> -- <path>`
> behaves. If you want that older behaviour from `restore`, pass `--overlay`.

## During a conflict

When a merge stops on a conflict (Chapter 26), the index holds three versions of
the file and the working tree holds a mix with conflict markers:

```console
$ git merge side
Auto-merging app.py
CONFLICT (content): Merge conflict in app.py
Automatic merge failed; fix conflicts and then commit the result.
$ cat app.py
start
common
<<<<<<< HEAD
from main
=======
from side
>>>>>>> side
end
$ git restore --ours app.py && cat app.py && git status --short
start
common
from main
end
UU app.py
$ git restore --theirs app.py && cat app.py
start
common
from side
end
$ git restore -2 app.py && sed -n 3p app.py
from main
$ git restore -3 app.py && sed -n 3p app.py
from side
```

`--ours` wrote our version into the working tree, and `--theirs` theirs. `-2`
and `-3` are the same, named after the stage numbers from Chapter 10. The file
is still `UU`: taking a side is not marking it resolved, which `git add` does.
`sed -n 3p` prints only the third line.

> **Careful.** During a rebase the sides are swapped: `--ours` gives the branch
> being rebased onto and `--theirs` your own work being rebased. Git's
> documentation warns about this, and Chapter 33 explains why.

The markers can be put back, in three styles:

```console
$ git restore -m app.py && cat app.py
start
common
<<<<<<< ours
from main
=======
from side
>>>>>>> theirs
end
$ git restore --conflict=diff3 app.py && cat app.py
start
<<<<<<< ours
common
from main
||||||| base
shared
=======
common
from side
>>>>>>> theirs
end
$ git restore --conflict=zdiff3 app.py && cat app.py
start
common
<<<<<<< ours
from main
||||||| base
shared
=======
from side
>>>>>>> theirs
end
$ git restore --conflict=merge app.py && cat app.py
start
common
<<<<<<< ours
from main
=======
from side
>>>>>>> theirs
end
$ git restore --conflict=tidy app.py
error: unknown conflict style 'tidy'
```

Both sides had replaced the line `shared` with `common` and one line of their
own. `-m` and `--conflict=merge` show just the two sides. `diff3` adds the
common ancestor's version under `|||||||`, and repeats `common` on both sides.
`zdiff3` moves the line both sides agree on out of the conflict. The labels
became `ours` and `theirs`, where the merge itself had written `HEAD` and
`side`. `merge.conflictStyle` sets the default style.

> **Since Git 2.35.** `zdiff3`.

A plain restore refuses an unmerged path, because it cannot know which version
you mean:

```console
$ git restore --ours --source=HEAD app.py
fatal: '--merge', '--ours', or '--theirs' cannot be used when checking out of a tree
$ git restore app.py other.py
error: path 'app.py' is unmerged
$ git status --short
UU app.py
 M other.py
$ git restore --ignore-unmerged app.py other.py && git status --short
warning: path 'app.py' is unmerged
UU app.py
$ git restore -q --ignore-unmerged app.py other.py && git status --short
UU app.py
```

The sides exist only in the index, so they cannot be combined with `--source`.
The refusal stopped `other.py` from being restored too. `--ignore-unmerged`
restored `other.py` and left `app.py` alone with a warning, and `-q` silenced
the warning.

Marking a file resolved does not lose the conflict for good:

```console
$ git add app.py && git status --short
M  app.py
$ git restore -m app.py && git status --short && cat app.py
UU app.py
start
common
<<<<<<< ours
from main
=======
from side
>>>>>>> theirs
end
$ git merge --abort
```

After `git add`, `-m` brought back both the markers and the unmerged state.
Git's documentation of the index format explains how: resolving a conflict
saves the conflicting versions in the index, so that the conflict can be
recreated (Chapter 73). That is the way back from a resolution you got wrong.

## Paths from a file

```console
$ printf 'a.txt\n' | git restore --pathspec-from-file=- && git status --short
 M b.txt
$ printf 'b.txt\0' | git restore --pathspec-from-file=- --pathspec-file-nul && git status --short
```

The paths come from a file, or from standard input with `-`, one per line or
separated by NUL bytes, as in `git add` (Chapter 11).

> **Since Git 2.25.** `--pathspec-from-file` and `--pathspec-file-nul`.

## Sparse checkouts

In a sparse checkout only some directories are in the working tree (Chapter 60).
Here only `keep/`, plus the files at the top, which the default *cone mode*
always includes, according to Git's documentation:

```console
$ git sparse-checkout set keep && ls
a.txt
b.txt
keep
$ git restore other/o.txt
error: pathspec 'other/o.txt' did not match any file(s) known to git
$ git restore --ignore-skip-worktree-bits other/o.txt && ls other
o.txt
```

`other/o.txt` is in the repository and in the index, but outside the sparse
checkout restore does not look at it, and says so in the words it uses for a
path that does not exist. `--ignore-skip-worktree-bits` restores it anyway.

## Untracked files are somebody else's job

```console
$ git status --short
?? build/
?? junk.txt
$ git restore .
$ git status --short
?? build/
?? junk.txt
```

`git restore` did nothing, correctly. Untracked files have no index entry, so
there is no source to restore from. The tool for those is `git clean`:

```console
$ git clean -n
Would remove junk.txt
$ git clean -nd
Would remove build/
Would remove junk.txt
$ git clean -fd
Removing build/
Removing junk.txt
$ git status --short
```

| Flag | Does |
|---|---|
| `-n`, `--dry-run` | List what would be removed |
| `-f`, `--force` | Actually remove. Required, unless `clean.requireForce` is false |
| `-d` | Include untracked directories |
| `-x` | Also remove ignored files |
| `-X` | Remove *only* ignored files, keeping other untracked ones |
| `-i`, `--interactive` | Choose from a menu |
| `-e <pattern>` | Add an extra exclude pattern for this run |

> **Careful.** `git clean -fdx` deletes every untracked and ignored file,
> which usually includes your local configuration, your virtual environment,
> your `.env` with credentials in it, and your editor settings. None of it is
> recoverable through Git because none of it was ever in Git. Run `git clean
> -ndx` first, read the list, then drop the `n`.

Note `-f` and `-d` are separate. `git clean -f` alone leaves untracked
directories behind, which surprises people who expected a clean tree.

### What git clean removes

This repository ignores `*.log` and `venv/`, and has untracked files at the top,
a new file in the tracked directory `src/`, two untracked directories, one of
them empty, and `nested`, a repository of its own:

```console
$ git clean
fatal: clean.requireForce is true and -f not given: refusing to clean
$ git clean -n
Would remove draft.md
Would remove notes.txt
Would remove src/tmp.txt
$ git clean -nd
Would remove build/
Would remove draft.md
Would remove empty/
Would remove notes.txt
Would remove src/tmp.txt
$ git clean -ndx
Would remove build/
Would remove debug.log
Would remove draft.md
Would remove empty/
Would remove notes.txt
Would remove src/tmp.txt
Would remove venv/
$ git clean -ndX
Would remove debug.log
Would remove venv/
$ git clean -nd -e '*.md'
Would remove build/
Would remove empty/
Would remove notes.txt
Would remove src/tmp.txt
$ git clean -ndx -e '*.log'
Would remove build/
Would remove draft.md
Would remove empty/
Would remove notes.txt
Would remove src/tmp.txt
Would remove venv/
$ git clean -n draft.md build
Would remove build/
Would remove draft.md
$ cd src
$ git clean -n
Would remove tmp.txt
```

| Command | Removes |
|---|---|
| `git clean -f` | untracked files, but not inside untracked directories |
| `git clean -fd` | untracked files and untracked directories |
| `git clean -fdx` | the same, plus ignored files and directories |
| `git clean -fdX` | only ignored files and directories |
| `git clean -fd -e <pattern>` | as `-fd`, keeping anything `<pattern>` matches |
| `git clean -f <path>` | only untracked files under `<path>`, directories included |
| `git clean -f` in a subdirectory | only what is under that subdirectory |

`src/tmp.txt` appeared without `-d` because `src/` itself is tracked. `-e` adds
an ignore rule for one run, and still counts with `-x`, which otherwise drops
the ignore rules: `debug.log` was kept. With a path, `-d` is not needed, as Git's
documentation says and `build` shows. And like most commands, clean works from
the current directory down.

Two more things it will not do without being told twice, and one way to be
quiet:

```console
$ git clean -fd nested && ls -d nested
nested
$ git clean -ffd nested
Removing nested/
$ git clean -fq notes.txt && git status --short
?? build/
?? draft.md
?? src/tmp.txt
$ git -c clean.requireForce=false clean draft.md
Removing draft.md
```

`nested` contains a `.git` directory, so a single `-f` skipped it without a word;
a second `f` removed it and everything in it. `-q` deleted `notes.txt` without
listing it. With `clean.requireForce` set to `false`, no `-f` is needed at all,
which removes the one safety catch `git clean` has.

### Choosing interactively

`-i` lists what would go and offers a menu. `ask each` asks about every item:

```console
$ printf '4\ny\nn\nn\n' | git clean -id
Would remove the following items:
  build/       empty/       src/tmp.txt
*** Commands ***
    1: clean                2: filter by pattern    3: select by numbers
    4: ask each             5: quit                 6: help
What now> Remove build/ [y/N]? Remove empty/ [y/N]? Remove src/tmp.txt [y/N]? Removing build/
$ git status --short --ignored
?? src/tmp.txt
!! debug.log
!! venv/
```

`filter by pattern` takes patterns to keep, and `select by numbers` takes the
items to delete, in the forms `git add -i` accepts (Chapter 11):

```console
$ printf '2\n*.log\n\n5\n' | git clean -idx
Would remove the following items:
  debug.log    empty/       src/tmp.txt  venv/
*** Commands ***
    1: clean                2: filter by pattern    3: select by numbers
    4: ask each             5: quit                 6: help
What now>   debug.log    empty/       src/tmp.txt  venv/
Input ignore patterns>>   empty/       src/tmp.txt  venv/
Input ignore patterns>> Would remove the following items:
  empty/       src/tmp.txt  venv/
*** Commands ***
    1: clean                2: filter by pattern    3: select by numbers
    4: ask each             5: quit                 6: help
What now> Bye.
$ printf '3\n2\n\n1\n' | git clean -idx
Would remove the following items:
  debug.log    empty/       src/tmp.txt  venv/
*** Commands ***
    1: clean                2: filter by pattern    3: select by numbers
    4: ask each             5: quit                 6: help
What now>     1: debug.log      2: empty/         3: src/tmp.txt    4: venv/
Select items to delete>>     1: debug.log    * 2: empty/         3: src/tmp.txt    4: venv/
Select items to delete>> Would remove the following item:
  empty/
*** Commands ***
    1: clean                2: filter by pattern    3: select by numbers
    4: ask each             5: quit                 6: help
What now> Removing empty/
$ git status --short --ignored
?? src/tmp.txt
!! debug.log
!! venv/
```

In the first, `*.log` took `debug.log` off the list, and `5` quit without
deleting anything. In the second, `2` selected `empty/`, and `1` cleaned just
that. `-i` needs no `-f`, because, as Git's documentation puts it, the menu is
its own safety catch.

## The classic equivalents

```console
$ git reset HEAD a.txt
Unstaged changes after reset:
M	a.txt
$ git status --short
 M a.txt
$ git checkout -- a.txt
$ git status --short
```

| Task | Modern | Classic |
|---|---|---|
| Discard a working-tree change | `git restore <file>` | `git checkout -- <file>` |
| Unstage a change | `git restore --staged <file>` | `git reset HEAD <file>` |
| Both | `git restore --staged --worktree <file>` | `git checkout HEAD -- <file>` |
| Take a file from an old commit | `git restore -s <commit> <file>` | `git checkout <commit> -- <file>` |
| Choose hunks to discard | `git restore -p <file>` | `git checkout -p <file>` |

Two reasons the modern forms are worth the retraining.

The `--` in `git checkout -- <file>` is load-bearing. Without it, `git checkout
name` is ambiguous: Git checks whether `name` is a branch first, so if a branch
and a file share a name you switch branches instead of discarding an edit.
`git restore` only ever takes paths, so the ambiguity cannot arise.

And the classic column uses two unrelated commands for one concept. `reset`
unstages, `checkout` discards, and neither name suggests what it does to a
file. `restore` does both jobs and says which with a flag.

### Where the classic forms differ

Here a file and a branch are both called `notes`, and the file has an edit:

```console
$ git branch
* main
  notes
$ git checkout notes
Switched to branch 'notes'
M	notes
$ git branch --show-current && git status --short
notes
 M notes
$ git checkout -- notes && cat notes
first notes
$ git switch -q main
$ git restore notes && cat notes
first notes
```

The first `git checkout` switched to the branch and carried the edit along. With
`--` it discarded the edit, as `git restore` does with no ambiguity at all.

Taking a file from an old commit is not quite the same either:

```console
$ git restore --source=HEAD~1 a.txt && git status --short
 M a.txt
$ git restore a.txt
$ git checkout HEAD~1 -- a.txt && git status --short
M  a.txt
```

```console
$ git restore --source=HEAD~1 --overlay dir && git status --short && ls dir
x.txt
y.txt
$ git checkout HEAD~1 -- dir && git status --short && ls dir
x.txt
y.txt
```

`git checkout <commit> -- <path>` writes the old version to the index as well,
so it is staged, where `restore --source` changes only the working tree. And it
works in overlay mode: in a directory, files added since that commit are kept,
where `restore` without `--overlay` would delete them.

| | `git restore -s <commit> <path>` | `git checkout <commit> -- <path>` |
|---|---|---|
| Working tree | updated | updated |
| Index | untouched | updated too |
| Files missing from `<commit>` | deleted | kept |

## restore, reset and revert

The three names sound alike and do different jobs. Git's own documentation has a
section on exactly this:

| Command | Changes | History |
|---|---|---|
| `git restore` | files in the working tree, the index, or both | untouched; no branch moves |
| `git reset` | which commit a branch points to, and optionally the index and working tree (Chapter 30) | rewritten: commits are removed from the branch |
| `git revert` | nothing directly; it makes a new commit that undoes an old one (Chapter 31) | added to: the undo is itself a commit |

`git reset <path>` also unstages, which is where it overlaps with
`git restore --staged`, as the classic equivalents above show.

## The settings

| Setting | Effect |
|---|---|
| `clean.requireForce` | `false` lets `git clean` delete without `-f` |
| `merge.conflictStyle` | Default style for `-m`: `merge`, `diff3` or `zdiff3` (Chapter 26) |
| `interactive.singleKey` | In `-p`, act on a key press without Enter |
| `diff.context`, `diff.interHunkContext` | Hunk size in `-p`. Since Git 2.51 |

> **Since Git 2.23.** `git restore` itself, and Git 2.51 declared it no longer
> experimental. On an older Git, use the classic column above.
