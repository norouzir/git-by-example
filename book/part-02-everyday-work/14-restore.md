# Chapter 14. Undoing Local Changes with restore

This chapter covers undoing work that has not been committed. Undoing commits
is Chapters 30 and 31; getting back things you thought were gone is Chapter 78.

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

## Restoring from a different commit

```console
$ git log --oneline
0008e6b Second commit
1522806 First commit
$ git restore --source=HEAD~1 a.txt
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
```

The working tree now holds an old version, and Git reports it as an ordinary
modification, because that is exactly what it is. Nothing about the branch or
the history changed.

This is how you look at how a file used to be while still being able to run the
rest of the project. To put it back, restore it from `HEAD`.

`-s` is the short form of `--source`.

> **Careful.** `--source` implies nothing about the index. `git restore
> --source=HEAD~5 file.txt` changes only your working tree, so the next
> `git status` shows a modification you may not remember making. Add `--staged`
> if you intend to commit the old version.

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

## Choosing what to throw away

```console
$ git restore -p poem.txt
...
(1/2) Discard this hunk from worktree [y,n,q,a,d,k,K,j,J,g,/,e,p,P,?]? 
...
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
muscle memory you built with `add -p`.

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

## The options table

| Option | Does |
|---|---|
| `-s <tree>`, `--source=<tree>` | Restore from this commit or tree instead of the index |
| `-S`, `--staged` | Restore the index |
| `-W`, `--worktree` | Restore the working tree. The default if neither is given |
| `-p`, `--patch` | Choose hunk by hunk |
| `--ours`, `--theirs` | During a conflict, take one side (Chapter 26) |
| `-m`, `--merge` | Recreate the conflict markers |
| `--conflict=<style>` | Conflict marker style, for instance `zdiff3` |
| `--ignore-unmerged` | Do not fail on unmerged paths |
| `--overlay`, `--no-overlay` | Whether to remove files absent from the source. `--no-overlay` is the default |
| `--pathspec-from-file=<file>` | Read paths from a file |
| `-q`, `--quiet` | Say nothing |

> **Worth knowing.** `--no-overlay` being the default is the mechanism behind
> the silent deletion above. In overlay mode Git only adds and updates files
> and never removes one, which is how `git checkout <commit> -- <path>`
> behaves. If you want that older behaviour from `restore`, pass `--overlay`.

> **Since Git 2.23.** `git restore` itself, and Git 2.51 declared it no longer
> experimental. On an older Git, use the classic column above.
