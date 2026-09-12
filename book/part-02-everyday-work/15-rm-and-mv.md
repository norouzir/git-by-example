# Chapter 15. rm and mv

Neither of these commands does anything you could not do with your shell plus
`git add`. Both exist because doing it in one step avoids a specific mistake,
and `git mv` avoids one you cannot work around on Windows or macOS.

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
```

Note the result is two file deletions. As Chapter 4 explained, Git has no
object for a directory on its own, so removing a directory is removing the
files in it.

## The safety checks

`git rm` refuses to destroy work you have not committed, and it distinguishes
two cases:

```console
$ git rm keep.txt
error: the following file has local modifications:
    keep.txt
(use --cached to keep the file, or -f to force removal)
```

```console
$ git rm keep.txt
error: the following file has changes staged in the index:
    keep.txt
(use --cached to keep the file, or -f to force removal)
```

| Message | Means |
|---|---|
| `has local modifications` | The working tree differs from the index |
| `has changes staged in the index` | The index differs from `HEAD` |

Both offer `--cached` before `-f`, and that order is a hint. `-f` destroys the
edits; `--cached` keeps the file on disk and only stops tracking it.

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
```

The file is still on disk. Git now reports a staged deletion *and* an untracked
directory containing the same file, which looks contradictory and is exactly
right: the path left the index, so it became untracked.

Chapter 8 covers when you want this, which is mostly "I committed something
that should have been ignored".

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

## The rm options

| Option | Does |
|---|---|
| `-n`, `--dry-run` | Show what would be removed |
| `-r` | Recurse into directories |
| `-f`, `--force` | Remove despite uncommitted changes |
| `--cached` | Remove from the index only, keep the file |
| `--ignore-unmatch` | Exit 0 even if nothing matched |
| `-q`, `--quiet` | Do not list removed files |
| `--sparse` | Allow removing paths outside a sparse checkout (Chapter 60) |
| `--pathspec-from-file=<file>` | Read paths from a file |

## git mv

```console
$ git mv src/main.py src/app.py
$ git status --short
R  src/main.py -> src/app.py
$ ls src
app.py
$ git show --stat --oneline HEAD
9971f0f Rename main to app
 src/{main.py => app.py} | 0
 1 file changed, 0 insertions(+), 0 deletions(-)
```

The `src/{main.py => app.py}` notation in `--stat` is Git's compact way of
showing a rename inside a directory. Chapter 13 covers rename display in full.

## mv is three commands in one

```console
$ mv src/app.py src/program.py
$ git status --short
 D src/app.py
?? src/program.py
$ git add -A && git status --short
R  src/app.py -> src/program.py
```

Same result. `git mv` is `mv` plus `git rm` plus `git add`, and the commit it
produces is byte-for-byte identical. As Chapter 4 explained, nothing anywhere
records a rename; both routes produce a tree with a different name pointing at
the same blob, and rename detection works it out at display time.

So on a case-sensitive filesystem, `git mv` saves you one command and nothing
else.

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
> but the only thing that works. It is also why a colleague on Linux can push
> a rename from `Readme.md` to `README.md` that appears to do nothing on your
> machine, and why the file may then show up twice in a case-sensitive
> checkout later. Use `git mv` for any rename that changes only capitalisation.

> **Worth knowing.** The other way to do it is two commits: rename to a
> temporary third name, commit, rename to the final name, commit. `git mv` is
> one step and does not litter history.

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

## The mv errors

```console
$ git mv no-such.txt anywhere.txt
fatal: bad source, source=no-such.txt, destination=anywhere.txt
$ git mv plain.txt renamed.txt
fatal: not under version control, source=plain.txt, destination=renamed.txt
```

| Message | Means |
|---|---|
| `bad source` | The path does not exist on disk |
| `not under version control` | The file exists but Git is not tracking it |
| `destination exists` | Something is already there; use `-f` |
| `can not move directory into itself` | The destination is inside the source |
| `destination directory does not exist` | Create it first, or use `-k` to skip |

The second one catches people moving a file they only just created. Add it
first, or use plain `mv` since Git has nothing to update.

## The mv options

| Option | Does |
|---|---|
| `-f`, `--force` | Overwrite the destination |
| `-k` | Skip moves that would error instead of failing |
| `-n`, `--dry-run` | Report what would move |
| `-v`, `--verbose` | Report each move |

## Which to use

| Situation | Use |
|---|---|
| Delete a tracked file | `git rm` |
| Delete a file and keep it on disk | `git rm --cached` |
| Delete an untracked file | your shell, or `git clean` (Chapter 14) |
| Rename, on Linux | either; `git mv` saves a step |
| Rename changing only case | `git mv`, always |
| Rename a file you have not committed yet | your shell |
| Move a whole directory | `git mv <dir> <newdir>`, which handles the contents |
