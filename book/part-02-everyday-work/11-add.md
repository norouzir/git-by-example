# Chapter 11. add

`git add` copies content from the working tree into the index. That is its only
job, and everything in this chapter is a variation on which content.

## The plain form

```console
$ git add a.txt
$ git status --short
A  a.txt
?? b.txt
$ git add a.txt b.txt
$ git status --short
A  a.txt
A  b.txt
```

Multiple paths in one command, and adding a file twice is harmless.

## What it actually does

`git add` writes a blob object and records its hash in the index. You can watch
it happen, because the hash is predictable before you run the command:

```console
$ git hash-object a.txt
c9083a27264f2d09fe915e541902e6b5cd8dde24
$ git add a.txt
$ git ls-files --stage a.txt
100644 c9083a27264f2d09fe915e541902e6b5cd8dde24 0	a.txt
$ git cat-file -p :a.txt
alpha
second line
```

The content is in the object database from this moment. That is why staging
something and then destroying the file on disk is survivable, and why
`git restore` on an unstaged change is not. Chapter 14 leans on this.

## Checking before you commit to it

```console
$ git add -n .
add 'c.txt'
$ git status --short
M  a.txt
?? c.txt
```

`-n` is `--dry-run`. It lists what would be added and changes nothing. Worth
using any time you are about to run `git add` with a wildcard in a repository
you do not know well.

## The four ways to say "everything"

Starting from a modified file, a deleted file, and two untracked ones:

```console
$ git status --short
M  a.txt
 D b.txt
?? c.txt
?? src/
$ git add -u && git status --short
M  a.txt
D  b.txt
?? c.txt
?? src/
$ git add -A && git status --short
M  a.txt
D  b.txt
A  c.txt
A  src/one.txt
A  src/two.txt
$ git add . && git status --short
M  a.txt
D  b.txt
A  c.txt
A  src/one.txt
A  src/two.txt
```

| Form | Modified | Deleted | Untracked |
|---|---|---|---|
| `git add -u` | yes | yes | **no** |
| `git add -A` | yes | yes | yes |
| `git add .` | yes | yes | yes |
| `git add :/` | yes | yes | yes |

From the top of the repository, `.` and `-A` are identical, which is why so
many people believe they are the same command.

## Where `.` and `-A` differ

They differ the moment you are not at the top. From inside `src`:

```console
$ git add . && git status --short
 M ../a.txt
 D ../b.txt
A  one.txt
A  two.txt
?? ../c.txt
$ git add -A && git status --short
M  ../a.txt
D  ../b.txt
A  ../c.txt
A  one.txt
A  two.txt
```

`git add .` staged only what is under the current directory. `git add -A`
staged the whole repository regardless of where you are standing.

| You want | Command |
|---|---|
| Everything in this directory and below | `git add .` |
| Everything in the repository, from anywhere | `git add -A` |
| Everything in the repository, from anywhere, explicitly | `git add :/` |

> **Careful.** This is how a commit ends up missing a file. You are in `src`,
> you run `git add .`, and the config file you edited at the top of the
> repository is not in the commit. The build then fails for everyone but you,
> because your working tree has it. `git status` before committing catches it
> every time.

> **Worth knowing.** Very old Git limited `-A` to the current directory too.
> Git's documentation still mentions the change. If you find advice online
> claiming `-A` and `.` are the same, it was written before Git 2.0.

## Pathspecs

The argument to `git add` is a **pathspec**, which is more expressive than a
filename:

```console
$ git add 'docs/*.md' && git status --short
A  docs/api.md
A  docs/guide.md
?? docs/logo.png
$ git add docs && git status --short
A  docs/api.md
A  docs/guide.md
A  docs/logo.png
```

Quote the glob. Unquoted, your shell expands it first, and the result is
usually the same but not always, because Git's globbing and your shell's are
different. The difference matters most when a pattern matches nothing: the
shell may pass the pattern through literally and Git will then report that the
pathspec matched no files.

### Pathspec magic

A pathspec starting with a colon carries **magic words** that change how it is
matched:

```console
$ git add ':(glob)**/*.md' && git status --short
A  docs/api.md
A  docs/guide.md
?? docs/logo.png
$ git add ':!docs/logo.png' && git status --short
```

| Magic | Short form | Does |
|---|---|---|
| `:(top)` | `:/` | Match from the repository root, wherever you are standing |
| `:(literal)` | | Treat `*` and `?` as ordinary characters |
| `:(icase)` | | Match without regard to case |
| `:(glob)` | | Full shell globbing, where `*` does not cross a `/` and `**` does |
| `:(exclude)` | `:!` or `:^` | Remove matching paths from the result |
| `:(attr:...)` | | Match only paths with given gitattributes (Chapter 65) |

Magic words combine: `:(top,icase)README*` matches any casing of `README` from
the root. And `:(exclude)` is the one you will actually reach for, because
"everything except that" is a common thing to want:

```
git add . ':!*.log'
```

> **Worth knowing.** Pathspecs are not specific to `add`. The same syntax works
> in `git diff`, `git log`, `git grep`, `git restore` and `git checkout`.
> Learning it once pays off in every chapter after this one.

## Staging part of a file

`git add -p` walks the diff hunk by hunk and asks about each one. This is the
feature that makes the index worth having.

```console
$ git diff
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
@@ -7,4 +7,4 @@ six
 seven
 eight
 nine
-ten
+TEN
```

Two hunks. Answer `y` to the first and `n` to the second:

```console
$ git add -p poem.txt
...
(1/2) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,e,p,P,?]? 
...
(2/2) Stage this hunk [y,n,q,a,d,K,J,g,/,e,p,P,?]? 
$ git status --short
MM poem.txt
```

The file is now staged and modified at once, with different content in each
place:

```console
$ git diff --staged
@@ -1,4 +1,4 @@
-one
+ONE
 two
 three
 four
$ git diff
@@ -7,4 +7,4 @@ six
 seven
 eight
 nine
-ten
+TEN
```

One change staged, the other left behind, from a single file. That is how you
turn an afternoon of mixed edits into a series of clean commits.

### The keys

| Key | Does |
|---|---|
| `y` | stage this hunk |
| `n` | do not stage this hunk |
| `q` | quit; do not stage this hunk or any remaining |
| `a` | stage this hunk and all later hunks in the file |
| `d` | do not stage this hunk or any later hunk in the file |
| `s` | split the current hunk into smaller hunks |
| `e` | manually edit the current hunk |
| `g` | select a hunk to go to |
| `/` | search for a hunk matching a regex |
| `j` | go to the next undecided hunk |
| `J` | go to the next hunk |
| `k` | go to the previous undecided hunk |
| `K` | go to the previous hunk |
| `p` | print the current hunk again |
| `P` | print the current hunk through the pager |
| `?` | print help |

`s` and `e` are the two that matter beyond `y` and `n`. `s` splits a hunk when
Git grouped two unrelated changes together because they were close. `e` opens
the hunk in your editor so you can stage individual lines, which is the last
resort when `s` cannot split far enough.

> **Careful.** In the editor that `e` opens, you delete lines you do not want
> to stage, but the rules differ by line type: remove a `+` line to leave it
> unstaged, and change a `-` line's leading character to a space to keep it.
> The editor buffer explains this at the bottom. Getting it wrong produces a
> hunk that will not apply, and Git then tells you and leaves the file alone.

`git add -i` is an older menu-driven interface that includes patch mode plus
other options. `-p` is the part almost everyone wants.

## Ignored files

```console
$ git add debug.log
The following paths are ignored by one of your .gitignore files:
debug.log
hint: Use -f if you really want to add them.
hint: Disable this message with "git config set advice.addIgnoredFile false"
$ git add -f debug.log && git status --short
A  debug.log
```

Git refuses rather than silently doing nothing, which is the right call. Note
that adding an ignored file with `-f` makes it tracked forever after, and the
ignore rule stops applying to it. Chapter 8 covers why.

## Saying a file is coming

```console
$ git status --short
?? draft.txt
$ git add -N draft.txt
$ git status --short
 A draft.txt
$ git diff
diff --git a/draft.txt b/draft.txt
new file mode 100644
index 0000000..6816e90
--- /dev/null
+++ b/draft.txt
@@ -0,0 +1 @@
+unfinished
$ git ls-files --stage draft.txt
100644 e69de29bb2d1d6434b8b29ae775ad8c2e48c5391 0	draft.txt
```

`-N`, or `--intent-to-add`, puts the path in the index with the **empty blob**
as its content. That hash, `e69de29bb2d1d6434b8b29ae775ad8c2e48c5391`, is the
same in every Git repository in the world, because it is the hash of nothing.

The effect is that the file is now tracked enough to appear in `git diff`, but
its content is still entirely unstaged. Two reasons to want that:

| Reason | Why it helps |
|---|---|
| You want `git diff` to show a new file | Otherwise new files are invisible to `diff`, which only looks at tracked paths |
| You want `git add -p` on a new file | Patch mode needs an index entry to diff against |

> **Careful.** Committing straight after `git add -N` commits an empty file,
> because the empty blob is what is in the index. Stage the real content first.
> The ` A` in the status output, with the letter on the right, is Git telling
> you the content is not staged.

## Setting the executable bit

```console
$ git add --chmod=+x script.sh && git ls-files --stage script.sh
100755 4163036efa65bd4a469e752267498f01ea36a55c 0	script.sh
```

Mode `100755` rather than `100644`, without touching the file on disk. This is
how you make a script executable in the repository from Windows, where the
filesystem has no executable bit to set. `--chmod=-x` goes the other way.

## The errors

```console
$ git add nothing-here
fatal: pathspec 'nothing-here' did not match any files
$ git add ''
fatal: empty string is not a valid pathspec. please use . instead if you meant to match all paths
$ git add ../outside
fatal: ../outside: '../outside' is outside repository at '/home/ada/adding'
```

| Message | Cause |
|---|---|
| `pathspec ... did not match any files` | Typo, wrong directory, or a glob your shell expanded to nothing |
| `empty string is not a valid pathspec` | A shell variable expanded to nothing. `git add "$file"` with `$file` unset |
| `is outside repository` | You are pointing above the repository root |
| `The following paths are ignored` | An ignore rule matched; use `-f` if you mean it |

That second one is worth recognising, because in a script it means a variable
you expected to be set was empty, and the error is about the symptom rather
than the cause.

## The options table

| Option | Does |
|---|---|
| `-n`, `--dry-run` | Show what would be added, change nothing |
| `-v`, `--verbose` | Print each path as it is added |
| `-f`, `--force` | Add ignored files too |
| `-u`, `--update` | Only files already tracked |
| `-A`, `--all` | Everything, from the repository root |
| `--no-all`, `--ignore-removal` | Add and modify, but do not record deletions |
| `-p`, `--patch` | Choose hunk by hunk |
| `-i`, `--interactive` | The older menu interface |
| `-e`, `--edit` | Edit the whole diff in your editor before staging |
| `-N`, `--intent-to-add` | Record the path with empty content |
| `--refresh` | Only update the index's cached file stats, stage nothing |
| `--chmod=(+\|-)x` | Set or clear the executable bit in the index |
| `--renormalize` | Re-apply line ending and filter rules to tracked files (Chapter 66) |
| `--pathspec-from-file=<file>` | Read pathspecs from a file, one per line |
| `--pathspec-file-nul` | Those pathspecs are NUL-separated |
| `--sparse` | Allow adding paths outside the sparse-checkout cone (Chapter 60) |
| `--ignore-errors` | Keep going if some files cannot be added |

> **Worth knowing.** `--renormalize` is the fix for the day your whole
> repository shows as modified after a line-ending configuration change. It
> re-stages every tracked file through the current rules without touching your
> working tree. Chapter 66 uses it as the main remedy.
