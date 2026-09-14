# Chapter 15. rm and mv

## What it is

`git rm` deletes a file and stages the deletion. `git mv` renames or moves a
file and stages the rename. Each changes the working tree and the index in one
step; neither makes a commit.

Neither of these commands does anything you could not do with your shell plus
`git add`. Both exist because doing it in one step avoids a specific mistake,
and `git mv` avoids one you cannot work around on Windows or macOS.

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [Do I have to use `git rm` and `git mv`, or can I delete and rename files normally?](#what-it-is)

**[Synopsis](#synopsis)**

- [What can I type after `git rm` and `git mv`?](#synopsis)

**[Options at a glance](#options-at-a-glance)**

- [Is there a list of every `git rm` option?](#git-rm-options)
- [Is there a list of every `git mv` option?](#git-mv-options)

**[git rm](#git-rm)**

- [How do I delete a file from the repository?](#git-rm)

**[Look before you delete](#look-before-you-delete)**

- [Can I see what `git rm` would delete first?](#look-before-you-delete)

**[Directories need -r](#directories-need-r)**

- [Why does `git rm` refuse to remove a folder?](#directories-need-r)
- [Why did `git rm 'd*'` delete more than I expected?](#patterns)

**[The safety checks](#the-safety-checks)**

- [Git refuses to remove a file with "local modifications". What now?](#the-safety-checks)
- [Is it safe when `git rm` deletes without any warning?](#the-safety-checks)

**[Untracking without deleting](#untracking-without-deleting)**

- [How do I stop tracking a file but keep it on my disk?](#untracking-without-deleting)
- [Why does `git rm --cached` sometimes refuse?](#untracking-without-deleting)

**[Files you already deleted](#files-you-already-deleted)**

- [I deleted files with my file manager. How do I tell Git?](#files-you-already-deleted)

**[Paths Git does not know](#paths-git-does-not-know)**

- [Why does `git rm` say "did not match any files"?](#paths-git-does-not-know)
- [How do I make `git rm` not fail in a script when the file is missing?](#paths-git-does-not-know)

**[git mv](#git-mv)**

- [How do I rename a file in Git?](#git-mv)
- [How do I rename or move a whole folder?](#moving-several-things)

**[mv is three commands in one](#mv-is-three-commands-in-one)**

- [Is there any difference between `git mv` and renaming then running `git add`?](#mv-is-three-commands-in-one)
- [Does Git lose a file's history when I rename it?](#mv-is-three-commands-in-one)

**[The case that only git mv can handle](#the-case-that-only-git-mv-can-handle)**

- [I renamed `readme.md` to `README.md` and Git doesn't see any change. Why?](#the-case-that-only-git-mv-can-handle)

**[mv will not overwrite](#mv-will-not-overwrite)**

- [Git says "destination exists". How do I replace the file?](#mv-will-not-overwrite)

**[The mv errors](#the-mv-errors)**

- [What do "bad source", "not under version control" and the other `git mv` errors mean?](#the-mv-errors)
- [Can `git mv` skip the files that would fail and move the rest?](#the-mv-errors)

**[Sparse checkouts](#sparse-checkouts)**

- [Why do `rm` and `mv` refuse a path "outside of your sparse-checkout definition"?](#sparse-checkouts)

**[Which to use](#which-to-use)**

- [Which command should I use to delete, untrack or rename?](#which-to-use)

</details>

## Synopsis

```
git rm [-f | --force] [-n] [-r] [--cached] [--ignore-unmatch]
       [--quiet] [--pathspec-from-file=<file> [--pathspec-file-nul]]
       [--] [<pathspec>...]

git mv [-v] [-f] [-n] [-k] <source> <destination>
git mv [-v] [-f] [-n] [-k] <source>... <destination-directory>
```

| Part | Means |
|---|---|
| `<pathspec>` | Which tracked files to remove (Chapter 11 covers pathspecs) |
| `<source>` | A tracked file, symbolic link or directory |
| `<destination>` | The new name |
| `<destination-directory>` | An existing directory to move several sources into |

| Command | Does |
|---|---|
| `git rm <file>` | Delete the file and stage the deletion |
| `git rm -r <directory>` | The same for everything in a directory |
| `git rm --cached <file>` | Stop tracking the file, keep it on disk |
| `git mv <old> <new>` | Rename, and stage the rename |
| `git mv <file>... <directory>` | Move files into a directory |

## Options at a glance

### git rm options

| Option | Does | Covered in |
|---|---|---|
| `-n`, `--dry-run` | Show what would be removed | [Look before you delete](#look-before-you-delete) |
| `-r` | Recurse into directories | [Directories need -r](#directories-need-r) |
| `-q`, `--quiet` | Do not list removed files | [Directories need -r](#directories-need-r) |
| `-f`, `--force` | Remove despite uncommitted changes | [The safety checks](#the-safety-checks) |
| `--cached` | Remove from the index only, keep the file | [Untracking without deleting](#untracking-without-deleting) |
| `--pathspec-from-file=<file>` | Read paths from a file | [Files you already deleted](#files-you-already-deleted) |
| `--pathspec-file-nul` | Those paths are NUL-separated | [Files you already deleted](#files-you-already-deleted) |
| `--ignore-unmatch` | Exit 0 even if nothing matched | [Paths Git does not know](#paths-git-does-not-know) |
| `--sparse` | Allow removing paths outside a sparse checkout (Chapter 60) | [Sparse checkouts](#sparse-checkouts) |

### git mv options

| Option | Does | Covered in |
|---|---|---|
| `-v`, `--verbose` | Report each move | [git mv](#git-mv) |
| `-n`, `--dry-run` | Report what would move | [git mv](#git-mv) |
| `-f`, `--force` | Overwrite the destination | [mv will not overwrite](#mv-will-not-overwrite) |
| `-k` | Skip moves that would error instead of failing | [The mv errors](#the-mv-errors) |
| `--sparse` | Allow moving paths outside a sparse checkout | [Sparse checkouts](#sparse-checkouts) |

## git rm

```console
$ git rm doomed.txt
rm 'doomed.txt'
$ git status --short
D  doomed.txt
$ ls
keep.txt
logs
src
```

Gone from disk and the deletion is staged, in one step. The `D` is in the left
column, so this is ready to commit.

## Look before you delete

```console
$ git rm -r -n logs
rm 'logs/one.log'
rm 'logs/two.log'
$ ls logs
one.log
two.log
```

`-n` is `--dry-run`. Given how little it costs, run it whenever the argument
contains a wildcard or a directory.

## Directories need -r

```console
$ git rm logs
fatal: not removing 'logs' recursively without -r
$ git rm -r logs
rm 'logs/one.log'
rm 'logs/two.log'
$ git status --short
D  logs/one.log
D  logs/two.log
$ ls
keep.txt
src
$ git restore --staged --worktree .
$ ls logs
one.log
two.log
```

Note the result is two file deletions. The index has entries only for files,
never for a directory on its own (Chapter 5), so removing a directory is removing
the files in it. The directory itself disappeared from disk once it was empty,
and `git restore` brought all of it back (Chapter 14).

`-q` removes the same way and lists nothing:

```console
$ git rm -q -r d && git status --short && ls
D  d/one.txt
D  d/sub/three.txt
d2
docs
gone.txt
keep.txt
top.md
```

### Patterns

A quoted pattern is matched by Git against every tracked path, and `*` crosses
directory boundaries:

```console
$ git rm -n 'd*'
rm 'd/one.txt'
rm 'd/sub/three.txt'
rm 'd2/two.txt'
rm 'docs/a.md'
rm 'docs/deep/b.md'
$ git rm -n 'd/*'
rm 'd/one.txt'
rm 'd/sub/three.txt'
$ git rm -n '*.md'
rm 'docs/a.md'
rm 'docs/deep/b.md'
rm 'top.md'
```

`'d*'` matched every path starting with `d`, which took in `d2/` and `docs/` as
well as `d/`. Git's documentation uses exactly this example to warn about the
difference between `'d*'` and `'d/*'`. A pattern also needs no `-r`: `'d/*'`
reached `d/sub/three.txt` without it. Unquoted, the shell would expand the
pattern first, and only to names in the current directory.

## The safety checks

`git rm` refuses to destroy work you have not committed, and it distinguishes
two cases:

```console
$ git rm keep.txt
error: the following file has local modifications:
    keep.txt
(use --cached to keep the file, or -f to force removal)
$ git status --short
 M keep.txt
$ git rm -f keep.txt
rm 'keep.txt'
$ git status --short
D  keep.txt
$ git restore --staged --worktree keep.txt
$ cat keep.txt
keep me
```

```console
$ git rm keep.txt
error: the following file has changes staged in the index:
    keep.txt
(use --cached to keep the file, or -f to force removal)
$ git rm -f keep.txt
rm 'keep.txt'
$ git restore --staged --worktree keep.txt
```

| Message | Means |
|---|---|
| `has local modifications` | The working tree differs from the index |
| `has changes staged in the index` | The index differs from `HEAD` |
| `has staged content different from both the file and the HEAD` | With `--cached`: the index matches neither, so removing it loses that version |

Both offer `--cached` before `-f`, and that order is a hint. `-f` destroys the
edits; `--cached` keeps the file on disk and only stops tracking it.

The `restore` after each `-f` put the file back from `HEAD`, which here was
possible only because the edits being thrown away were not needed.

> **Careful.** The check compares against both the index and `HEAD`, so a file
> whose content matches `HEAD` is deleted without complaint. `git rm` being
> quiet does not mean the content is safe somewhere; it means the content is
> already committed. That is the same thing here, but it is worth knowing which
> question Git actually asked.

## Untracking without deleting

```console
$ git rm --cached src/main.py
rm 'src/main.py'
$ git status --short
D  src/main.py
?? src/
$ ls src
main.py
$ git restore --staged src/main.py
$ git status --short
```

The file is still on disk. Git now reports a staged deletion *and* an untracked
directory containing the same file, which looks contradictory and is exactly
right: the path left the index, so it became untracked. `git restore --staged`
undid it.

Chapter 8 covers when you want this, which is mostly "I committed something
that should have been ignored".

`--cached` has a safety check of its own. Git's documentation says the staged
content must match either `HEAD` or the file on disk, so that removing it from
the index cannot lose the only copy of a version:

```console
$ git rm --cached keep.txt && git status --short
rm 'keep.txt'
D  keep.txt
?? keep.txt
$ git reset -q --hard
$ git rm --cached keep.txt
error: the following file has staged content different from both the
file and the HEAD:
    keep.txt
(use -f to force removal)
$ git rm --cached -f keep.txt && git status --short
rm 'keep.txt'
D  keep.txt
?? keep.txt
```

The first time, a change was staged and the file on disk was the same, so the
staged version still existed on disk and `--cached` went ahead. The second time,
the file had been changed again after staging, and the staged version existed
nowhere else. `-f` removed it anyway; the file on disk kept its newer content.
`git reset -q --hard` in between put everything back as committed (Chapter 30).

## Files you already deleted

A file deleted without Git is an unstaged deletion, and `git rm` stages it even
though there is nothing left to delete:

```console
$ git status --short
 D gone.txt
$ git rm gone.txt && git status --short
rm 'gone.txt'
D  gone.txt
```

For many files at once, `git add -u` stages every deletion along with every
other change to tracked files (Chapter 11). To stage only the deletions, Git's
documentation gives this pipeline:

```console
$ git diff --name-only --diff-filter=D -z | xargs -0 git rm --cached
rm 'gone.txt'
rm 'top.md'
$ git status --short
D  gone.txt
D  top.md
```

`git diff --name-only --diff-filter=D` lists the tracked files missing from the
working tree (Chapter 13), `-z` separates the names with NUL bytes, and `xargs -0`
hands them to `git rm --cached`. The same list can go straight into `git rm`:

```console
$ printf 'top.md\0keep.txt\0' | git rm -q --pathspec-from-file=- --pathspec-file-nul && git status --short
D  keep.txt
D  top.md
```

> **Since Git 2.26.** `git rm --pathspec-from-file` and `--pathspec-file-nul`.

## Paths Git does not know

```console
$ git rm untracked.txt
fatal: pathspec 'untracked.txt' did not match any files
$ git rm --ignore-unmatch untracked.txt; echo exit=$?
exit=0
```

`--ignore-unmatch` makes a missing path a non-event and exits 0. It exists for
scripts and cleanup targets in makefiles, where "delete this if it is tracked"
is the intent.

To delete a file Git does not track, use the shell or `git clean` (Chapter 14).
With no path at all, `git rm` asks:

```console
$ git rm
fatal: No pathspec was given. Which files should I remove?
```

## git mv

```console
$ git mv src/main.py src/app.py
$ git status --short
R  src/main.py -> src/app.py
$ ls src
app.py
$ git commit -q -m 'Rename main to app'
$ git show --stat --oneline HEAD
9971f0f Rename main to app
 src/{main.py => app.py} | 0
 1 file changed, 0 insertions(+), 0 deletions(-)
```

The `src/{main.py => app.py}` notation in `--stat` is Git's compact way of
showing a rename inside a directory. Chapter 13 covers rename display in full.

`git mv` prints nothing unless asked. `-v` reports each move, and `-n` reports
without moving:

```console
$ git mv -v a.txt c.txt && git status --short
Renaming a.txt to c.txt
R  a.txt -> c.txt
$ git reset -q --hard
$ git mv -n a.txt c.txt && git status --short
Checking rename of 'a.txt' to 'c.txt'
Renaming a.txt to c.txt
```

After `-n` the status is empty: nothing was renamed, despite the wording.

### Moving several things

```console
$ git mv dir newdir && git status --short && ls
R  dir/sub/y.txt -> newdir/sub/y.txt
R  dir/x.txt -> newdir/x.txt
a.txt
b.txt
newdir
$ git reset -q --hard && rm -rf newdir
$ mkdir target && git mv a.txt b.txt target && git status --short
R  a.txt -> target/a.txt
R  b.txt -> target/b.txt
```

A directory moves with everything in it, recorded as a rename of each file. With
more than one source, the last argument must be an existing directory, and the
sources go into it.

## mv is three commands in one

```console
$ mv src/app.py src/program.py
$ git status --short
 D src/app.py
?? src/program.py
$ git add -A && git status --short
R  src/app.py -> src/program.py
$ git restore --staged --worktree .
$ ls src
app.py
```

Same result. `git mv` is `mv` plus `git rm` plus `git add`, and the commit it
produces is byte-for-byte identical. As Chapter 4 explained, nothing anywhere
records a rename; both routes produce a tree with a different name pointing at
the same blob, and rename detection works it out at display time.

The tree Git would commit shows it. `git write-tree` writes the index as a tree
object and prints its hash (Chapter 75):

```console
$ mv a.txt c.txt && git add -A && git write-tree
195f8a0a2d036e1feec219567b71289420d613be
$ git reset -q --hard
$ git mv a.txt c.txt && git write-tree
195f8a0a2d036e1feec219567b71289420d613be
```

The same hash from both routes, so the same tree; a commit made from either,
with the same message, author and time, would have the same hash too.

So on a case-sensitive filesystem, `git mv` saves you one command and nothing
else.

That is also why a rename never loses history: the history belongs to commits,
not to file names. `git log --follow` (Chapter 17) follows one file across a
rename by detecting it in each commit.

A file with uncommitted changes moves with them. The rename is staged, and the
changes stay as they were:

```console
$ git mv a.txt c.txt && git status --short
RM a.txt -> c.txt
```

## The case that only git mv can handle

On Windows and macOS the filesystem is usually case-insensitive, and Git knows:

```console
$ git config get core.ignorecase
true
```

Renaming a file to a different case with your shell then does nothing at all,
as far as Git is concerned:

```console
$ mv keep.txt KEEP.TXT
$ git status --short
$ ls KEEP.TXT
KEEP.TXT
```

The file on disk is called `KEEP.TXT`. `git status` reports no change
whatsoever, because when Git asks the filesystem about `keep.txt` the
filesystem cheerfully hands back the file. There is nothing for `git add` to
notice, so the rename can never be committed.

`git mv` rewrites the index entry directly and does not have to ask:

```console
$ git mv keep.txt KEEP.TXT
$ git status --short
R  keep.txt -> KEEP.TXT
$ git ls-files
KEEP.TXT
logs/one.log
logs/two.log
other.txt
src/app.py
```

> **Windows.** This is the one situation where `git mv` is not a convenience
> but the only thing that works. Use `git mv` for any rename that changes only
> capitalisation.

> **Worth knowing.** The other way to do it is two commits: rename to a
> temporary third name, commit, rename to the final name, commit. `git mv` is
> one step and does not litter history.

On Linux, where the filesystem tells the two names apart, the shell `mv` shows
up as a deletion and a new file, as any other rename does, and `git add -A`
works.

## mv will not overwrite

```console
$ git mv keep.txt other.txt
fatal: destination exists, source=keep.txt, destination=other.txt
$ git mv -f keep.txt other.txt
$ git status --short
D  keep.txt
M  other.txt
$ cat other.txt
keep me
```

With `-f` the destination is overwritten, which is reported as a deletion plus
a modification rather than as a rename, because that is what happened to the
two paths involved.

The destination does not have to be tracked to count as existing:

```console
$ git mv a.txt untracked.txt
fatal: destination exists, source=a.txt, destination=untracked.txt
$ git mv -f a.txt untracked.txt && git status --short
R  a.txt -> untracked.txt
```

Here the overwritten file was never in Git, so the result is a plain rename, and
the untracked file's content is gone for good.

## The mv errors

```console
$ git mv no-such.txt anywhere.txt
fatal: bad source, source=no-such.txt, destination=anywhere.txt
$ git mv plain.txt renamed.txt
fatal: not under version control, source=plain.txt, destination=renamed.txt
```

```console
$ git mv a.txt b.txt nowhere
fatal: destination 'nowhere' is not a directory
$ git mv a.txt nowhere/c.txt
fatal: renaming 'a.txt' failed: No such file or directory
$ git mv dir dir/sub
fatal: can not move directory into itself, source=dir, destination=dir/sub/dir
```

| Message | Means |
|---|---|
| `bad source` | The path does not exist on disk |
| `not under version control` | The file exists but Git is not tracking it |
| `destination exists` | Something is already there; use `-f` |
| `can not move directory into itself` | The destination is inside the source |
| `is not a directory` | Several sources were given and the last argument is not an existing directory |
| `renaming ... failed: No such file or directory` | The directory the new name is in does not exist; create it first |

The second one catches people moving a file they only just created. Add it
first, or use plain `mv` since Git has nothing to update.

`-k` skips every source that would fail and moves the rest:

```console
$ git mv -k a.txt untracked.txt nosuch.txt dir && git status --short
R  a.txt -> dir/a.txt
?? untracked.txt
```

`untracked.txt` is not under version control and `nosuch.txt` does not exist, so
both were skipped without a message, and only `a.txt` moved.

## Sparse checkouts

In a sparse checkout (Chapter 60), only `keep/` is in the working tree here:

```console
$ git sparse-checkout set keep
$ git rm other/o.txt
The following paths and/or pathspecs matched paths that exist
outside of your sparse-checkout definition, so will not be
updated in the index:
other/o.txt
hint: If you intend to update such entries, try one of the following:
hint: * Use the --sparse option.
hint: * Disable or modify the sparsity rules.
hint: Disable this message with "git config set advice.updateSparsePath false"
$ git rm --sparse other/o.txt && git status --short
rm 'other/o.txt'
D  other/o.txt
$ git reset -q --hard
$ git mv other/o.txt keep/o.txt
The following paths and/or pathspecs matched paths that exist
outside of your sparse-checkout definition, so will not be
updated in the index:
other/o.txt
hint: If you intend to update such entries, try one of the following:
hint: * Use the --sparse option.
hint: * Disable or modify the sparsity rules.
hint: Disable this message with "git config set advice.updateSparsePath false"
$ git mv --sparse other/o.txt keep/o.txt && git status --short
R  other/o.txt -> keep/o.txt
```

Both refuse to change index entries outside the sparse checkout, and `--sparse`
lets them. `git mv --sparse` is listed by `git mv -h` though not yet in
`git mv`'s documentation.

> **Since Git 2.34.** `--sparse` for both commands.

## Which to use

| Situation | Use |
|---|---|
| Delete a tracked file | `git rm` |
| Delete a file and keep it on disk | `git rm --cached` |
| Stage files you already deleted | `git rm <path>`, or `git add -u` for all changes |
| Delete an untracked file | your shell, or `git clean` (Chapter 14) |
| Undo a `git rm` before committing | `git restore --staged --worktree <path>` (Chapter 14) |
| Rename, on Linux | either; `git mv` saves a step |
| Rename changing only case | `git mv`, always |
| Rename a file you have not committed yet | your shell |
| Move a whole directory | `git mv <dir> <newdir>`, which handles the contents |
| Remove a file from all of history, such as a leaked password | neither; Chapter 37 |

`git rm` only records a deletion from now on. Every earlier commit still
contains the file, which is why a secret committed by mistake needs Chapter 37,
not `git rm`.

Git's documentation also describes how both commands treat submodules, updating
`.gitmodules` for you; Chapter 57 covers that.
