# Chapter 13. diff

## What it is

`git diff` shows, line by line, how two versions of your files differ. The two
versions can be your working tree, the index, any commit, or even two files that
have nothing to do with Git. It changes nothing; it only reports.

The report is made of *hunks*: each hunk is one block of changed lines,
with a few unchanged lines around it so you can see where it sits.

With no arguments it answers one specific question: what have I changed that I
have not staged yet? Every other form answers a different question, and knowing
which question each form asks is most of what there is to learn about it.

Its output is the unified diff format that almost every tool understands, with a
few extra lines only Git writes. It looks like the output of the Unix `diff`
command, but it is not the same program and does not behave the same way; the
section "git diff and the diff command" near the end of this chapter compares
the two.

## Synopsis

These are the forms Git's own documentation lists:

```
git diff [<options>] [<commit>] [--] [<path>...]
git diff [<options>] --cached [--merge-base] [<commit>] [--] [<path>...]
git diff [<options>] [--merge-base] <commit> [<commit>...] <commit> [--] [<path>...]
git diff [<options>] <commit>...<commit> [--] [<path>...]
git diff [<options>] <blob> <blob>
git diff [<options>] --no-index [--] <path> <path> [<pathspec>...]
```

| Part | Means |
|---|---|
| `[<options>]` | Any of the options below. They may also come after the commits |
| `<commit>` | Anything that names a commit: a hash, a branch, `HEAD`, `HEAD~2` (Chapter 18) |
| `--cached` | Compare the index instead of the working tree. `--staged` is a synonym |
| `<blob>` | A file's content, usually written `<commit>:<path>` |
| `--` | Everything after this is a path, never a commit |
| `<path>...` | Limit the diff to these paths. Pathspec syntax applies (Chapter 11) |

What each form compares:

| Command | Compares |
|---|---|
| `git diff` | working tree against index |
| `git diff --staged` | index against HEAD |
| `git diff HEAD` | working tree against HEAD |
| `git diff <commit>` | working tree against that commit |
| `git diff --staged <commit>` | index against that commit |
| `git diff <a> <b>` | commit `a` against commit `b` |
| `git diff <a>..<b>` | the same thing; the dots are optional here |
| `git diff <a>...<b>` | the merge base of `a` and `b` against `b` |
| `git diff --merge-base <a> <b>` | the same as `<a>...<b>` |
| `git diff <a>:<path> <b>:<path>` | one file's blob against another's |
| `git diff --no-index <f1> <f2>` | two files, with no repository involved |

The first three rows are the ones you will use every day, and they are the ones
people confuse. Chapter 5 explains them through the three areas; the section
"Choosing what to compare" below shows every row running.

> **Careful.** Inside a repository, `git diff a.txt b.txt` does not compare
> `a.txt` with `b.txt`. Both names are read as paths to limit the first form,
> so it shows your uncommitted changes to each. To compare two files, add
> `--no-index`. The section "git diff and the diff command" shows the trap.

## Options at a glance

Every option below is demonstrated in the section named in the last column.

| Option | Does | Covered in |
|---|---|---|
| `--staged`, `--cached` | Compare the index, against HEAD or a commit you name | Choosing what to compare |
| `--merge-base` | Compare from the merge base, like three dots | Two dots and three dots |
| `-R` | Swap the two sides | Choosing what to compare |
| `--relative[=<path>]` | Limit to a directory and show paths relative to it | Choosing what to compare |
| `--no-index` | Compare two paths outside version control | git diff and the diff command |
| `-U<n>`, `--unified=<n>` | Number of context lines | How much context |
| `-W`, `--function-context` | Show the whole function around each change | How much context |
| `--inter-hunk-context=<n>` | Merge hunks separated by up to `<n>` unchanged lines | How much context |
| `--stat[=<width>]` | A bar chart per file | Summaries instead of content |
| `--stat-count=<n>` | List at most `<n>` files in `--stat` | Summaries instead of content |
| `--numstat`, `--shortstat` | Exact counts, or only the total | Summaries instead of content |
| `--name-only`, `--name-status`, `--summary` | Path listings | Summaries instead of content |
| `--compact-summary` | `--stat` with creations, deletions and mode changes marked | Summaries instead of content |
| `--dirstat[=<params>]` | Share of change per directory | Summaries instead of content |
| `--word-diff[=<mode>]` | Word-level output | Word-level diffs |
| `--word-diff-regex=<regex>` | What counts as a word | Word-level diffs |
| `--color-words` | Word diff in colour | Word-level diffs |
| `-S <string>`, `-G <regex>` | Filter by content change | Searching history through diffs |
| `--pickaxe-regex` | Treat `-S` as a regex | Searching history through diffs |
| `--pickaxe-all` | Keep every file in a matching commit | Searching history through diffs |
| `-w`, `--ignore-all-space` | Ignore all whitespace | Whitespace |
| `-b`, `--ignore-space-change` | Ignore changes in the amount of whitespace | Whitespace |
| `--ignore-space-at-eol` | Ignore whitespace at line ends only | Whitespace |
| `--ignore-blank-lines` | Ignore added or removed blank lines | Whitespace |
| `--ignore-cr-at-eol` | Ignore a carriage return at line end | Whitespace |
| `--check` | Report whitespace errors and conflict markers | Whitespace |
| `-M[<n>]`, `--find-renames[=<n>]` | Rename detection and its threshold | Renames and copies |
| `-C[<n>]`, `--find-copies[=<n>]` | Copy detection from changed files | Renames and copies |
| `--find-copies-harder` | Copy detection from every file | Renames and copies |
| `--no-renames` | Report renames as a delete plus an add | Renames and copies |
| `-B`, `--break-rewrites` | Treat heavy rewrites as a delete plus an add | Renames and copies |
| `-l <num>` | Limit how many files rename detection considers | Renames and copies |
| `--color-moved[=<mode>]` | Colour moved lines differently from changed ones | Moved code |
| `--diff-algorithm=<name>` | Choose the algorithm | Algorithms |
| `--minimal`, `--patience`, `--histogram` | Shorter spellings for three algorithms | Algorithms |
| `--anchored=<text>` | Keep lines starting with `<text>` unchanged where possible | Algorithms |
| `--diff-filter=<letters>` | Keep only added, deleted, modified and so on | Keeping only some kinds of change |
| `--no-prefix`, `--src-prefix`, `--dst-prefix` | Change or remove the `a/` and `b/` prefixes | Prefixes, output files, and file names |
| `--default-prefix` | Use `a/` and `b/` whatever the configuration says | Prefixes, output files, and file names |
| `--output=<file>` | Write to a file instead of standard output | Prefixes, output files, and file names |
| `-z` | Separate paths with a zero byte (NUL) and never quote them | Prefixes, output files, and file names |
| `--binary` | Include binary content in the patch | Binary files |
| `--text`, `-a` | Treat every file as text | Binary files |
| `--exit-code`, `--quiet` | Report differences through the exit status | Exit codes |
| `--submodule[=<format>]` | How to show changed submodules | Chapter 57 |
| `--ext-diff`, `--textconv` | Use external diff drivers and converters | Chapter 65 |
| `--cc`, `-c` | Combined diff for a merge commit | Chapter 26 |

<!-- no-example: -B
     Tested on a complete rewrite, on a rewrite that kept its blank lines in
     place, and on a rewrite combined with -M where the old content had moved
     to another file. In all three the output was identical to the default, so
     an example would show the reader nothing they cannot see without it. It
     changes output only for large files rewritten past a threshold, and its
     main use is helping -M pair rewritten files in big changes. -->

<!-- no-example: -l
     A performance limit on how many files rename detection will compare before
     giving up. On any example small enough to print, the output is the same
     with or without it. -->

## Reading the output

Before any option makes sense, the output has to. Here is the plain form after
changing one word in a tracked file:

```console
$ git diff
diff --git a/story.txt b/story.txt
index 681da97..5e46c1f 100644
--- a/story.txt
+++ b/story.txt
@@ -1,4 +1,4 @@
 Once upon a time
-there was a repository.
+there was a git repository.
 It had many commits.
 The end.
```

Every diff has the same five-part shape:

| Line | Means |
|---|---|
| `diff --git a/... b/...` | The header. `a/` is the old side, `b/` the new |
| `index 681da97..5e46c1f 100644` | The two blob hashes and the file mode |
| `--- a/story.txt` | The old file. `/dev/null` if it is being created |
| `+++ b/story.txt` | The new file. `/dev/null` if it is being deleted |
| `@@ -1,4 +1,4 @@` | A hunk header: from line 1 for 4 lines, to line 1 for 4 lines |

Then the body, where a leading space means unchanged, `-` means removed, and
`+` means added.

The two hashes on the `index` line are real objects you can look up, which is
how you prove to yourself what is being compared:

```console
$ git rev-parse :story.txt
681da97093d67d54da65098864b154aed74fe3fc
$ git hash-object story.txt
5e46c1f7389fcda6430bdddb0c8266aa8b5449c4
```

The left hash is the index version, the right is the file on disk. Plain
`git diff` compares exactly those two.

### New, deleted and mode-changed files

Three kinds of change add header lines of their own between `diff --git` and
the content: creating a file, deleting one, and changing only its mode.

```console
$ git diff --staged -- new.txt
diff --git a/new.txt b/new.txt
new file mode 100644
index 0000000..d5a09df
--- /dev/null
+++ b/new.txt
@@ -0,0 +1 @@
+brand new
$ git diff --staged -- gone.txt
diff --git a/gone.txt b/gone.txt
deleted file mode 100644
index ca588c1..0000000
--- a/gone.txt
+++ /dev/null
@@ -1 +0,0 @@
-about to be deleted
$ git diff --staged -- run.sh
diff --git a/run.sh b/run.sh
old mode 100644
new mode 100755
```

| Extra header | Means |
|---|---|
| `new file mode 100644` | The file did not exist on the old side |
| `index 0000000..` | An all-zero hash stands for "no object" |
| `deleted file mode 100644` | The file does not exist on the new side |
| `old mode` and `new mode` | Only the permissions changed; there is no hunk at all |
| `@@ -0,0 +1 @@` | Zero lines on the old side, one on the new |

A mode change with no content change produces a diff with no body. Chapter 4
lists the five modes.

### No newline at end of file

Sometimes the last line of a diff is followed by a line starting with a
backslash:

```console
$ git diff --staged -- tail.txt
diff --git a/tail.txt b/tail.txt
index 9c4d1ef..cd77cc6 100644
--- a/tail.txt
+++ b/tail.txt
@@ -1 +1 @@
-ends with a newline
+no newline at the end
\ No newline at end of file
```

The backslash line is not part of the file. It is a marker attached to the line
above it, saying that line is the last in the file and has no newline
character after it. Here the new version lacks the final newline and the old
one had it.

> **Worth knowing.** This is why an editor that silently strips or adds a final
> newline produces a diff on a line you never touched. The line text is
> identical; what changed is the invisible character after it.

### A renamed file with edits

When Git detects that a file was renamed and its content also changed, the
header records both:

```console
$ git diff --staged -- mover.txt moved.txt
diff --git a/mover.txt b/moved.txt
similarity index 87%
rename from mover.txt
rename to moved.txt
index fa2da6e..c02d574 100644
--- a/mover.txt
+++ b/moved.txt
@@ -7,4 +7,4 @@ line 6
 line 7
 line 8
 line 9
-line 10
+line ten
```

`similarity index 87%` is how much of the file survived. Both paths had to be
given here, because a pathspec with only the new name would not include the old
file for Git to pair it with.

### The text after the second @@

In that last diff the hunk header ends in `line 6`, and earlier `@@ -2 +2 @@`
ended in `Once upon a time`. Git puts the nearest line above the hunk that
*looks like* the start of a function there. With no information about the
language, "looks like" means "starts with a letter, an underscore or a dollar
sign", which is why an ordinary line of text qualifies.

On real code it is much more useful:

```console
$ git diff
diff --git a/prices.py b/prices.py
index 41e5074..6501c93 100644
--- a/prices.py
+++ b/prices.py
@@ -6,7 +6,7 @@ def total(items):
         count += 1
     if count == 0:
         return 0
-    tax = subtotal * 0.2
+    tax = subtotal * 0.25
     return subtotal + tax
 
 def describe(item):
```

The change is on line 9, the hunk starts at line 6, and the header tells you
it is inside `total`. Chapter 65 shows how `.gitattributes` teaches Git the real
function syntax of a language, for the cases where the letter rule guesses
wrong.

## Choosing what to compare

The table in the Synopsis lists what each form compares. This section runs the
forms that the first example did not, and the cases where a form behaves in a
way you would not guess.

### A commit, and the index against a commit

The history here is three versions of `a.txt`: "version one" and "version two"
committed, "version three" in the working tree.

```console
$ git diff HEAD~1
diff --git a/a.txt b/a.txt
index 9bc69cf..9c89174 100644
--- a/a.txt
+++ b/a.txt
@@ -1 +1 @@
-version one
+version three
$ git add a.txt && git diff --staged HEAD~1
diff --git a/a.txt b/a.txt
index 9bc69cf..9c89174 100644
--- a/a.txt
+++ b/a.txt
@@ -1 +1 @@
-version one
+version three
```

`git diff HEAD~1` skipped right over "version two": it compares the working
tree with that one commit and ignores everything in between. `--staged` with a
commit does the same for the index.

### Swapping the sides

`-R` swaps the two sides of any diff, so additions show as removals and the
other way round:

```console
$ git diff -R HEAD~1 --staged
diff --git b/a.txt a/a.txt
index 9c89174..9bc69cf 100644
--- b/a.txt
+++ a/a.txt
@@ -1 +1 @@
-version three
+version one
```

Look closely: `-R` swaps the prefixes as well, so `b/` now comes first. A reversed diff applied as a patch undoes the original.

### One file across commits, or two different files

The content of one file in one commit can be named directly as
`<commit>:<path>`, and two such names can be compared:

```console
$ git diff HEAD~2:a.txt HEAD:a.txt
diff --git a/a.txt b/a.txt
index 9bc69cf..9c89174 100644
--- a/a.txt
+++ b/a.txt
@@ -1 +1 @@
-version one
+version three
$ git diff HEAD:a.txt HEAD:b.txt
diff --git a/a.txt b/b.txt
index 9c89174..69edd21 100644
--- a/a.txt
+++ b/b.txt
@@ -1 +1 @@
-version three
+a different file
```

That form names a blob directly (Chapter 18), so you can
compare any file at any point in history with any other, even files with
different names.

| Form | Compares | Notes |
|---|---|---|
| `git diff A B -- file` | `file` in commit A with `file` in commit B | Follows the normal diff machinery, renames included |
| `git diff A:file B:file` | two blobs, directly | Works for two different paths; rename detection does not apply |

### Only my subdirectory

`--relative` limits the diff to the directory you are standing in and shows
paths relative to it. Both commands below were run from inside `sub/`:

```console
$ git diff --stat
 outer.txt     | 2 +-
 sub/inner.txt | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)
$ git diff --relative --stat
 inner.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

Plain `git diff` shows the whole repository no matter where you stand, with
paths from the top. With `--relative`, `outer.txt` dropped out and `sub/` was
stripped from the path. `--relative=<path>` does the same for a directory you
name instead of the current one.

> **Since Git 2.28.** The `diff.relative` setting, to make this the default.

### New files do not appear

A file you have created but never added is left out of every form of
`git diff`:

```console
$ git diff --stat
$ git status --short
?? brand-new.txt
$ git add -N brand-new.txt && git diff --stat
 brand-new.txt | 1 +
 1 file changed, 1 insertion(+)
```

`git diff` compares tracked content, so an untracked file is invisible to it.
That is the usual reason for "I made changes but git diff shows nothing". `git
add -N` puts an empty placeholder in the index, which makes the file visible
without staging its content. Chapter 11 covers `-N` in detail.

### Before the first commit

In a new repository with a file staged and nothing committed yet, the forms
that mention `HEAD` behave differently from those that do not:

```console
$ git diff --staged
diff --git a/first.txt b/first.txt
new file mode 100644
index 0000000..e510380
--- /dev/null
+++ b/first.txt
@@ -0,0 +1 @@
+the very first file
$ git diff HEAD; echo exit=$?
fatal: ambiguous argument 'HEAD': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
exit=128
```

There is no `HEAD` yet. `--staged` copes, and Git's documentation says it then
shows everything that is staged. `git diff HEAD` fails with an error that talks
about paths, because Git tried to read `HEAD` as a file name after failing to
find it as a revision.

## Comparing commits

Given two commits, `git diff` compares the snapshots they record. Your working
tree and index play no part:

```console
$ git diff HEAD~2 HEAD --stat
 config.ini | 3 ++-
 story.txt  | 3 ++-
 2 files changed, 4 insertions(+), 2 deletions(-)
$ git diff HEAD~2..HEAD --stat
 config.ini | 3 ++-
 story.txt  | 3 ++-
 2 files changed, 4 insertions(+), 2 deletions(-)
$ git diff HEAD~2 HEAD -- story.txt
diff --git a/story.txt b/story.txt
index 681da97..ec8af9a 100644
--- a/story.txt
+++ b/story.txt
@@ -1,4 +1,5 @@
 Once upon a time
-there was a repository.
+there was a git repository.
 It had many commits.
+It had branches too.
 The end.
```

A space or two dots between the commits: same result. Everything after `--` is
a pathspec, limiting the diff to those paths. The `--` separates paths from
revisions and is worth typing whenever a path could be mistaken for a branch
name.

## Two dots and three dots

This is the single most common source of "that diff is wrong". Given this
history:

```console
$ git log --oneline --all --graph
* 9038d5b Add a feature
| * 92aa31c Mention branches
| * 38b2fe8 Tell a git story
|/  
* e8b4006 Add story and config
```

The two forms answer different questions:

```console
$ git diff main..feature --name-status
M	config.ini
A	feature.txt
M	story.txt
$ git diff main...feature --name-status
A	feature.txt
$ git merge-base main feature
e8b4006caa0ffd58502e41102d7e7ea8409b5d6c
$ git diff --merge-base main feature --name-status
A	feature.txt
```

| Form | Compares | Answers |
|---|---|---|
| `main..feature` | tip of `main` against tip of `feature` | What is different between these two right now? |
| `main...feature` | merge base against tip of `feature` | What did `feature` change since it diverged? |
| `--merge-base main feature` | the same as three dots | The same question, spelled out |

The *merge base* is the most recent commit that both branches have in their
history, which is the point where they went separate ways. Here it is
`e8b4006`, and `git merge-base` prints it. Chapter 76 explains how Git finds
it when the history is more tangled.

The three-dot form is almost always what you want when reviewing a branch,
because it excludes work that happened on `main` in the meantime. It is what
GitHub and GitLab show in a pull request.

`main..feature` reported `config.ini` and `story.txt` as modified, although
`feature` never touched them. Those are the commits on `main` that `feature`
does not have, seen from the other side.

> **Since Git 2.30.** `--merge-base`. It exists because three dots are easy to
> miss when reading a command, and a word is not.

> **Careful.** The meaning of `..` and `...` is *reversed* between `git diff`
> and `git log`. In `git log`, `a..b` means commits in `b` but not `a`, and
> `a...b` means commits in either but not both. Chapter 18 covers both, and
> the reversal is a genuine historical wart rather than something you can
> reason your way to.

## git diff, git show and git log -p

Three commands, and on an ordinary commit they print the same patch:

```console
$ git diff HEAD~1 HEAD
diff --git a/poem.txt b/poem.txt
index 9efff34..d531a8e 100644
--- a/poem.txt
+++ b/poem.txt
@@ -1 +1,2 @@
 roses are red
+violets are blue
$ git show HEAD
commit e093b7cfd0233971a4c674a1478b2376ae222eb0
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 10:00:00 2026 +0000

    Second

diff --git a/poem.txt b/poem.txt
index 9efff34..d531a8e 100644
--- a/poem.txt
+++ b/poem.txt
@@ -1 +1,2 @@
 roses are red
+violets are blue
$ git log -p -1
commit e093b7cfd0233971a4c674a1478b2376ae222eb0
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 10:00:00 2026 +0000

    Second

diff --git a/poem.txt b/poem.txt
index 9efff34..d531a8e 100644
--- a/poem.txt
+++ b/poem.txt
@@ -1 +1,2 @@
 roses are red
+violets are blue
$ git show --format= HEAD
diff --git a/poem.txt b/poem.txt
index 9efff34..d531a8e 100644
--- a/poem.txt
+++ b/poem.txt
@@ -1 +1,2 @@
 roses are red
+violets are blue
```

`git show` and `git log -p -1` add the commit header. With an empty format,
`git show` prints only the patch.

They are not interchangeable in every case. The first commit shows the
difference:

```console
$ git diff HEAD~2 HEAD~1; echo exit=$?
fatal: ambiguous argument 'HEAD~2': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
exit=128
$ git show --stat --oneline HEAD~1
46bcff9 First
 poem.txt | 1 +
 1 file changed, 1 insertion(+)
$ git diff 4b825dc642cb6eb9a060e54bf8d69288fbee4904 HEAD~1 --stat
 poem.txt | 1 +
 1 file changed, 1 insertion(+)
```

A root commit has no parent, so there is nothing for `git diff` to compare it
against. `git show` compares it against emptiness automatically. To make
`git diff` do the same, compare against the empty tree, whose fixed name
Chapter 4 introduced.

| | `git diff A B` | `git show B` | `git log -p` |
|---|---|---|---|
| Compares | any two things you name | a commit against its parent | each commit against its parent |
| Prints a commit header | no | yes | yes |
| Works on a root commit | only against the empty tree | yes | yes |
| Covers several commits | as one combined change | one at a time with several arguments | one at a time |
| On a merge commit | whatever you ask for | a combined diff (Chapter 26) | nothing by default (Chapter 17) |

The last row matters. On a merge, "the diff of this commit" has no single
answer, and the three commands answer it differently.

## How much context

Around each change, `git diff` prints some unchanged lines so you can see where
the change sits. `-U<n>`, or its long form `--unified=<n>`, sets how many:

```console
$ git diff -U1
diff --git a/story.txt b/story.txt
index 681da97..5e46c1f 100644
--- a/story.txt
+++ b/story.txt
@@ -1,3 +1,3 @@
 Once upon a time
-there was a repository.
+there was a git repository.
 It had many commits.
$ git diff -U0
diff --git a/story.txt b/story.txt
index 681da97..5e46c1f 100644
--- a/story.txt
+++ b/story.txt
@@ -2 +2 @@ Once upon a time
-there was a repository.
+there was a git repository.
```

Three lines of context is the default. `-U0` gives none, which is what you want
when generating a patch to apply mechanically and the worst thing to read by
eye. Note that the hunk header shrinks with the context.

### The whole function

Earlier, the change in `prices.py` was shown starting at line 6, in the middle
of `total`. `-W` extends the hunk to the whole function around the change:

```console
$ git diff -W
diff --git a/prices.py b/prices.py
index 41e5074..6501c93 100644
--- a/prices.py
+++ b/prices.py
@@ -1,12 +1,12 @@
 def total(items):
     subtotal = 0
     count = 0
     for item in items:
         subtotal += item.price
         count += 1
     if count == 0:
         return 0
-    tax = subtotal * 0.2
+    tax = subtotal * 0.25
     return subtotal + tax
 
 def describe(item):
$ git diff --function-context -U0
diff --git a/prices.py b/prices.py
index 41e5074..6501c93 100644
--- a/prices.py
+++ b/prices.py
@@ -1,10 +1,10 @@
 def total(items):
     subtotal = 0
     count = 0
     for item in items:
         subtotal += item.price
         count += 1
     if count == 0:
         return 0
-    tax = subtotal * 0.2
+    tax = subtotal * 0.25
     return subtotal + tax
```

`-W` still adds the usual three lines of context after the function, which is
how `def describe` crept in. With `-U0` you get exactly the function and
nothing else. This is the form to use when reviewing a change to a long
function, where three lines around the edit tell you nothing.

### Nearby changes, one hunk or two

When two changes are close, their context overlaps and they print as one hunk;
otherwise each gets its own. `--inter-hunk-context=<n>` joins hunks that are up
to `<n>` unchanged lines apart:

```console
$ git diff
diff --git a/n.txt b/n.txt
index 0ff3bbb..5918f43 100644
--- a/n.txt
+++ b/n.txt
@@ -1,6 +1,6 @@
 1
 2
-3
+THREE
 4
 5
 6
@@ -9,7 +9,7 @@
 9
 10
 11
-12
+TWELVE
 13
 14
 15
$ git diff --inter-hunk-context=2
diff --git a/n.txt b/n.txt
index 0ff3bbb..5918f43 100644
--- a/n.txt
+++ b/n.txt
@@ -1,15 +1,15 @@
 1
 2
-3
+THREE
 4
 5
 6
 7
 8
 9
 10
 11
-12
+TWELVE
 13
 14
 15
```

Lines 7 and 8 fell between the two hunks' context. `--inter-hunk-context=2`
says "merge hunks separated by up to two unchanged lines", so they became one.
Nothing about the changes is different; only the grouping is.

## Summaries instead of content

When you want to know which files changed and by how much, rather than every
changed line, these options print a summary instead of the diff:

```console
$ git diff --stat
 config.ini | 3 ++-
 story.txt  | 2 +-
 2 files changed, 3 insertions(+), 2 deletions(-)
$ git diff --numstat
2	1	config.ini
1	1	story.txt
$ git diff --shortstat
 2 files changed, 3 insertions(+), 2 deletions(-)
$ git diff --name-only
config.ini
story.txt
$ git diff --name-status
M	config.ini
M	story.txt
```

| Form | Gives you | Use it for |
|---|---|---|
| `--stat` | A bar chart per file | Reading |
| `--numstat` | Added, deleted, path, tab-separated | Scripts. No scaling, no truncation |
| `--shortstat` | Just the totals line | A quick size check |
| `--name-only` | Paths | Feeding into another command |
| `--name-status` | A status letter and path | Seeing what was added or deleted |
| `--summary` | Creations, deletions, renames, mode changes | Spotting structural changes |
| `--compact-summary` | `--stat` with those structural changes marked inline | Reading both at once |
| `--dirstat` | Percentage of change per directory | Seeing where a large change landed |

### Structural changes

`--summary` printed nothing for the edits above, because nothing was created,
deleted, renamed or re-moded. Here is a change that does all four:

```console
$ git diff --staged --stat
 gone.txt               | 1 -
 mover.txt => moved.txt | 0
 new.txt                | 1 +
 run.sh                 | 0
 4 files changed, 1 insertion(+), 1 deletion(-)
$ git diff --staged --summary
 delete mode 100644 gone.txt
 rename mover.txt => moved.txt (100%)
 create mode 100644 new.txt
 mode change 100644 => 100755 run.sh
$ git diff --staged --compact-summary
 gone.txt (gone)        | 1 -
 mover.txt => moved.txt | 0
 new.txt (new)          | 1 +
 run.sh (mode +x)       | 0
 4 files changed, 1 insertion(+), 1 deletion(-)
```

`--stat` alone shows `run.sh | 0`, which looks like nothing happened.
`--compact-summary` is the one that tells you what.

### What --stat scales, and what it does not

`--stat` draws a bar for each file. Here one file had all 300 of its lines
changed and another had one:

```console
$ git diff --stat
 big.txt   | 600 +++++++++++++++++++++++++++++++-------------------------------
 small.txt |   2 +-
 2 files changed, 301 insertions(+), 301 deletions(-)
$ git diff --numstat
300	300	big.txt
1	1	small.txt
$ git diff --stat=50
 big.txt   | 600 ++++++++++++++++----------------
 small.txt |   2 +-
 2 files changed, 301 insertions(+), 301 deletions(-)
```

The number is the real count of changed lines: 300 added and 300 removed is
600. The bar of `+` and `-` is what gets scaled to fit the width, which is why
`--stat=50` shortened the bar and left the number alone. On a small change the
bar is not scaled at all: `small.txt` really did have one line added and one
removed.

> **Careful.** Compare bar lengths only within one `--stat` output, never
> across two, because each is scaled to its own largest file. Read the number.

`--stat` accepts a width, and `--stat-count` limits how many files are listed:

```console
$ git diff --stat --stat-count=1
 big.txt | 600 ++++++++++++++++++++++++++++++++--------------------------------
 ...
 2 files changed, 301 insertions(+), 301 deletions(-)
```

That indented `...` is Git's own, meaning more files were left out. It is not
the book trimming output.

### Which directories changed

`--dirstat` reports what share of the change happened in each directory:

```console
$ git diff --dirstat
  23.1% docs/
  76.8% src/
$ git diff --dirstat=lines
  25.0% docs/
  75.0% src/
```

Thirty lines changed in `src/core.txt` and ten in `docs/guide.txt`. The two
answers differ because they measure differently.

`--dirstat` takes parameters after an `=`, several of them separated by commas:

| Form | Counts |
|---|---|
| `--dirstat`, `--dirstat=changes` | Changed content, not counting code that only moved. The default |
| `--dirstat=lines` | Lines added and removed, the same as `--stat` would. Slower |
| `--dirstat=files` | Changed files, each counting equally. Cheapest |
| `--dirstat=cumulative` | Also credit changes in a subdirectory to its parent |
| `--dirstat=<number>` | Hide directories below that percentage. The default is 3 |

Here is a tree where the parameters give visibly different answers: two files
heavily edited in `src/core/`, one lightly in `src/ui/`, one very lightly in
`docs/`, and one line in a file at the top level.

```console
$ git diff --stat
 docs/d.txt     |  6 ++---
 src/core/a.txt | 80 +++++++++++++++++++++++++++++-----------------------------
 src/core/b.txt | 80 +++++++++++++++++++++++++++++-----------------------------
 src/ui/c.txt   | 10 ++++----
 top.txt        |  2 +-
 5 files changed, 89 insertions(+), 89 deletions(-)
$ git diff --dirstat
  91.7% src/core/
   4.5% src/ui/
$ git diff --dirstat=files
  20.0% docs/
  40.0% src/core/
  20.0% src/ui/
$ git diff --dirstat=cumulative
  91.7% src/core/
   4.5% src/ui/
  96.3% src/
$ git diff --dirstat=files,cumulative
  20.0% docs/
  40.0% src/core/
  20.0% src/ui/
  60.0% src/
$ git diff --dirstat=10
  91.7% src/core/
```

Reading them in turn:

- **The default** hid `docs/`, whose share of the changed content fell below 3%.
- **`files`** counts files instead, so `docs/` with one of five changed files
  gets 20% and reappears.
- **`cumulative`** adds `src/` itself, crediting it with everything beneath it.
- **`10`** raised the cut-off to 10%, which removed `src/ui/`.

None of the percentages add up to 100, and that is not an error: `top.txt` is
not in any subdirectory, so its share is never listed.

## Word-level diffs

Line diffs are useless for prose, where changing one word marks the whole
paragraph as rewritten.

```console
$ git diff --word-diff story.txt
diff --git a/story.txt b/story.txt
index 681da97..5e46c1f 100644
--- a/story.txt
+++ b/story.txt
@@ -1,4 +1,4 @@
Once upon a time
there was a {+git+} repository.
It had many commits.
The end.
```

Additions in `{+ +}`, removals in `[- -]`. There is also a porcelain mode for
scripts:

```console
$ git diff --word-diff=porcelain story.txt
diff --git a/story.txt b/story.txt
index 681da97..5e46c1f 100644
--- a/story.txt
+++ b/story.txt
@@ -1,4 +1,4 @@
 Once upon a time
~
 there was a 
+git
  repository.
~
 It had many commits.
~
 The end.
~
```

Each word-level piece is on its own line with a leading space, `+` or `-`, and
`~` marks the end of an original line.

`--word-diff` takes a mode after an `=`:

| Form | Shows changes as |
|---|---|
| `--word-diff`, `--word-diff=plain` | `[-removed-]{+added+}` |
| `--word-diff=color` | Colour only, no brackets |
| `--word-diff=porcelain` | One piece per line, for scripts |
| `--word-diff=none` | An ordinary line diff; turns word diff off again |

### In colour

`--color-words` shows the same word diff, using colour instead of brackets:

```ansi
$ git diff --color-words
\e[1mdiff --git a/call.c b/call.c\e[m
\e[1mindex 1901fbc..92c34dd 100644\e[m
\e[1m--- a/call.c\e[m
\e[1m+++ b/call.c\e[m
\e[36m@@ -1 +1 @@\e[m
result = compute(alpha, \e[31mbeta);\e[m\e[32mgamma);\e[m
$ git diff --word-diff=color
\e[1mdiff --git a/call.c b/call.c\e[m
\e[1mindex 1901fbc..92c34dd 100644\e[m
\e[1m--- a/call.c\e[m
\e[1m+++ b/call.c\e[m
\e[36m@@ -1 +1 @@\e[m
result = compute(alpha, \e[31mbeta);\e[m\e[32mgamma);\e[m
```

Identical. Git's documentation defines `--color-words` as exactly
`--word-diff=color`, plus an optional word pattern. It is the nicest to read on
a terminal and the least useful to paste anywhere, because without colour the
removed and added words run together.

The table above also claims that `plain` is what you get with no mode, and that
`none` gives an ordinary diff. Comparing the saved output of each pair:

```console
$ git diff --word-diff=plain > ../a.diff; git diff --word-diff > ../b.diff; cmp ../a.diff ../b.diff && echo same
same
$ git diff --word-diff=none > ../a.diff; git diff > ../b.diff; cmp ../a.diff ../b.diff && echo same
same
```

`cmp` prints nothing when two files are byte-for-byte identical, so `same` is
printed only when they are.

### Deciding what counts as a word

Look at what changed above: `beta);` became `gamma);`. The punctuation came
along, because by default a word is anything between spaces.

```console
$ git diff --word-diff
diff --git a/call.c b/call.c
index 1901fbc..92c34dd 100644
--- a/call.c
+++ b/call.c
@@ -1 +1 @@
result = compute(alpha, [-beta);-]{+gamma);+}
$ git diff --word-diff --word-diff-regex='[A-Za-z]+|[^[:space:]]'
diff --git a/call.c b/call.c
index 1901fbc..92c34dd 100644
--- a/call.c
+++ b/call.c
@@ -1 +1 @@
result = compute(alpha, [-beta-]{+gamma+});
```

The regular expression says a word is either a run of letters or any single
non-space character. Now only the identifier is marked. For code, that is
almost always what you want; for languages written without spaces between
words, a pattern like this is the only way word diff works at all.

## Searching history through diffs

Two options select changes by their content: `-S <string>` and `-G <regex>`.
They are used mostly with `git log`, where they pick out the commits whose
changes involve some text:

```console
$ git log -S 'branches' --oneline
92aa31c Mention branches
$ git log -G 'debug' --oneline
38b2fe8 Tell a git story
e8b4006 Add story and config
```

| Option | Finds commits where |
|---|---|
| `-S <string>` | The number of occurrences of the string changed |
| `-G <regex>` | An added or removed line matches the regex |
| `--pickaxe-regex` | Treat `-S` as a regex rather than a literal string |
| `--pickaxe-all` | Show every file in a matching commit, not just the matching ones |

### When -S and -G disagree

Those two descriptions sound nearly the same. They are not. Here is a function
call that is added, then changed, then removed:

```console
$ git log --oneline
dcc3706 Remove the call
5cecf5f Change the argument
3ddf9a5 Add the call
$ git log -S 'frotz(nitfol' --oneline
dcc3706 Remove the call
3ddf9a5 Add the call
$ git log -G 'frotz\(nitfol' --oneline
dcc3706 Remove the call
5cecf5f Change the argument
3ddf9a5 Add the call
```

"Change the argument" rewrote the line `frotz(nitfol, one);` into
`frotz(nitfol, two);`. The text `frotz(nitfol` appeared once before and once
after, so its count did not change and `-S` skipped the commit. The line
containing it was removed and added, so `-G` found it.

| You want | Use |
|---|---|
| When was this introduced, and when was it deleted | `-S` |
| Every commit that touched a line mentioning this | `-G` |

`-S` is what you want more often, because it filters out every commit that
merely edited around the text. It is the only reliable way to find where a
piece of code went after it disappeared, and Chapter 21 uses it extensively.

Note the backslash in the `-G` pattern. `-G` always takes a regular expression,
so a literal parenthesis must be escaped. `-S` takes a plain string unless you
ask otherwise:

```console
$ git log -S 'frotz\(nit+' --pickaxe-regex --oneline
dcc3706 Remove the call
3ddf9a5 Add the call
```

### Seeing the whole commit

`--pickaxe-all` changes how much of each matching commit is shown:

```console
$ git log -S frotz --oneline --name-only -1
9b8cdf8 Bring the call back, and add a note
lib.c
$ git log -S frotz --pickaxe-all --oneline --name-only -1
9b8cdf8 Bring the call back, and add a note
lib.c
notes.txt
```

By default `-S` also hides the *files* in a matching commit that did not match.
`--pickaxe-all` shows the full commit, which is what you want when the context
of a change matters as much as the change.

### -S works on git diff too

The same options work when `git diff` compares two commits, where they keep
only the matching files:

```console
$ git diff HEAD~1 HEAD --name-only
lib.c
notes.txt
$ git diff HEAD~1 HEAD --name-only -S frotz
lib.c
```

They are diff options that `git log` also accepts, not log options. On
`git diff` they keep only the files where the count changed.

## Whitespace

Here is one file with three different whitespace changes: the space between
`hello` and `world` was removed, the single space in `a b` became four, and
three spaces were added after `end`.

```console
$ git diff
diff --git a/spacing.txt b/spacing.txt
index 84ee4b1..cef6a80 100644
--- a/spacing.txt
+++ b/spacing.txt
@@ -1,3 +1,3 @@
-hello world
-a b
-end
+helloworld
+a    b
+end   
$ git diff -b
diff --git a/spacing.txt b/spacing.txt
index 84ee4b1..cef6a80 100644
--- a/spacing.txt
+++ b/spacing.txt
@@ -1,3 +1,3 @@
-hello world
+helloworld
 a    b
 end   
$ git diff -w
$ git diff --ignore-space-at-eol
diff --git a/spacing.txt b/spacing.txt
index 84ee4b1..cef6a80 100644
--- a/spacing.txt
+++ b/spacing.txt
@@ -1,3 +1,3 @@
-hello world
-a b
+helloworld
+a    b
 end   
```

Three flags, three different answers, and the difference between them is exactly
which of those three changes survived:

| Flag | `helloworld` | `a    b` | `end   ` |
|---|---|---|---|
| none | shown | shown | shown |
| `--ignore-space-at-eol` | shown | shown | hidden |
| `-b`, `--ignore-space-change` | shown | hidden | hidden |
| `-w`, `--ignore-all-space` | hidden | hidden | hidden |

`-b` treats any run of whitespace as equal to any other run, and ignores it at
the end of a line. But it still sees the difference between *some* space and
*no* space, so `hello world` against `helloworld` is still a change. `-w`
ignores whitespace entirely, even where one line has it and the other has none.

Use `-b` when reviewing a reindentation. Use `-w` only when you are sure
whitespace cannot matter, which is untrue in Python, YAML and Makefiles, and
untrue in any string literal.

### Ignoring whitespace does not change what gets committed

These flags are easy to mistake for a way of ignoring whitespace changes
altogether. They are not:

```console
$ git diff -w --stat
$ git diff --stat
 spacing.txt | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)
$ git commit -qam 'Respace' && git show --stat --oneline HEAD
ae69f04 Respace
 spacing.txt | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)
```

`git diff -w` said there was nothing, and the commit still recorded all three
lines. These flags change only what the diff shows you. There is no flag on
`git diff` that stops a whitespace change from being committed.

### Blank lines

`--ignore-blank-lines` hides changes that only add or remove empty lines:

```console
$ git diff blank.txt
diff --git a/blank.txt b/blank.txt
index 814f4a4..e7940dd 100644
--- a/blank.txt
+++ b/blank.txt
@@ -1,2 +1,4 @@
 one
+
+
 two
$ git diff --ignore-blank-lines blank.txt
```

### Carriage returns

A file saved with Windows line endings looks identical in most editors and
completely changed to Git:

```console
$ git diff endings.txt | cat -A
diff --git a/endings.txt b/endings.txt$
index 814f4a4..4e349b5 100644$
--- a/endings.txt$
+++ b/endings.txt$
@@ -1,2 +1,2 @@$
-one$
-two$
+one^M$
+two^M$
$ git diff --ignore-cr-at-eol endings.txt
```

`cat -A` makes the invisible visible: `$` marks the end of each line and `^M`
is the carriage return. Every line in the file changed, and only by that one
character.

> **Windows.** This is the most common cause of a diff where every line of a
> file is shown as changed. `--ignore-cr-at-eol` hides it from view, but the
> real fix is the line-ending configuration in Chapter 66, because the commit
> would still record every line.

### Finding whitespace errors before committing

`--check` looks for whitespace problems in the changes instead of printing the
diff:

```console
$ git diff --check; echo exit=$?
check.txt:2: trailing whitespace.
+trailing spaces   
check.txt:3: space before tab in indent.
+  	space before tab
exit=2
```

`--check` prints the file, the line, and the problem, and exits non-zero, here
with 2. By default it flags trailing whitespace and a space placed before a tab
in the indentation. `core.whitespace` changes what counts (Chapter 63). Git's
documentation notes it cannot be combined with `--exit-code`.

It is the natural thing to run in a `pre-commit` hook (Chapter 67).

In colour, Git marks the same problems in the ordinary diff, with a red
background:

```ansi
$ git diff check.txt
\e[1mdiff --git a/check.txt b/check.txt\e[m
\e[1mindex 47132c2..4914716 100644\e[m
\e[1m--- a/check.txt\e[m
\e[1m+++ b/check.txt\e[m
\e[36m@@ -1 +1,3 @@\e[m
 clean line\e[m
\e[32m+\e[m\e[32mtrailing spaces\e[m\e[41m   \e[m
\e[32m+\e[m\e[41m  \e[m	\e[32mspace before tab\e[m
```

By default only added lines are highlighted; `--ws-error-highlight` extends it
to removed and context lines.

## Renames and copies

Git does not record renames or copies. It detects them when it compares two
snapshots, and these options control how. Here `story.txt` was renamed with
`git mv` and nothing else changed:

```console
$ git diff --cached --stat
 story.txt => tale.txt | 0
 1 file changed, 0 insertions(+), 0 deletions(-)
$ git diff --cached -M --name-status
R100	story.txt	tale.txt
$ git diff --cached --no-renames --name-status
D	story.txt
A	tale.txt
```

The same change, three descriptions. `R100` means "rename, 100% similar". As
Chapter 4 explained, nothing recorded the rename; Git noticed a deletion and an
addition with matching content and drew a conclusion.

| Option | Does |
|---|---|
| `-M`, `--find-renames[=<n>]` | Detect renames, optionally with a similarity threshold |
| `-C`, `--find-copies[=<n>]` | Detect copies as well |
| `--find-copies-harder` | Look for copies from files that did not change. Slow |
| `--no-renames` | Report a delete plus an add |
| `-B`, `--break-rewrites` | Treat a heavily rewritten file as a delete plus an add |
| `-l <num>` | Give up rename detection past this many files |

### The threshold, and why -M5 is not five percent

Rename detection is on by default with a 50% threshold, which Git's
documentation states. Here a file was renamed and eight of its twenty lines
were edited:

```console
$ git diff --staged --name-status
A	moved.txt
D	orig.txt
$ git diff --staged -M5 --name-status
A	moved.txt
D	orig.txt
$ git diff --staged -M05 --name-status
R025	orig.txt	moved.txt
$ git diff --staged -M50% --name-status
A	moved.txt
D	orig.txt
```

The file is 25% similar, which is below the default, so it shows as a deletion
and an addition. Lowering the threshold finds the rename.

The catch is in how the number is read. Without a `%` sign, Git puts a decimal
point in front of it. `-M5` means 0.5, which is 50%, which is the default, so it
changed nothing. `-M05` means 0.05, which is 5%. Writing the `%` avoids the
whole problem.

| Written | Means |
|---|---|
| `-M50%` | 50% |
| `-M5` | 0.5, so 50% |
| `-M05` | 0.05, so 5% |
| `-M100%` | Exact renames only |

At the other end, `-M100%` accepts only a rename with no change at all. Here the
word ` edited` was added to the last of twenty lines while renaming:

```console
$ git diff --staged --name-status
R082	before.txt	after.txt
$ git diff --staged -M100% --name-status
A	after.txt
D	before.txt
```

82% similar is a rename by default and not a rename at all under `-M100%`. One
edited line was enough to lose it. Similarity is measured on content, not on a
count of lines, which is why one line in twenty cost 18%.

This matters most when you are hunting through history for where a file went: a
file renamed and heavily edited in the same commit appears to stop existing.
`git log --follow` works around it for one file, and Chapter 17 covers its
limitations.

### Copies

`-C` finds copies, but only sometimes. Here one file was copied from a file that
was also modified in the same change, and another from a file that was not
touched:

```console
$ git diff --staged --name-status
A	copy-of-other.txt
A	copy-of-template.txt
M	other.txt
$ git diff --staged -C --name-status
C100	other.txt	copy-of-other.txt
A	copy-of-template.txt
M	other.txt
$ git diff --staged -C --find-copies-harder --name-status
C100	other.txt	copy-of-other.txt
C100	template.txt	copy-of-template.txt
M	other.txt
```

| Flags | Looks for copy sources among |
|---|---|
| none | nowhere; copies are not detected |
| `-C` | files modified in the same change |
| `-C --find-copies-harder` | every file, changed or not |

The second is a performance compromise. Comparing every new file against every
existing file is expensive in a large repository, so plain `-C` only considers
files that changed anyway. `--find-copies-harder` pays the cost.

## Moved code

When code is moved rather than changed, a normal diff shows a deletion in one
place and an addition in another, and you have to compare the two blocks by eye
to know nothing inside them was altered:

```ansi
$ git diff
\e[1mdiff --git a/m.py b/m.py\e[m
\e[1mindex b8cfe23..2d281ed 100644\e[m
\e[1m--- a/m.py\e[m
\e[1m+++ b/m.py\e[m
\e[36m@@ -1,8 +1,8 @@\e[m
\e[31m-def alpha():\e[m
\e[31m-    return "first function body"\e[m
\e[31m-\e[m
 def beta():\e[m
     return "second function body"\e[m
 \e[m
 def gamma():\e[m
     return "third function body"\e[m
\e[32m+\e[m
\e[32m+\e[m\e[32mdef alpha():\e[m
\e[32m+\e[m\e[32m    return "first function body"\e[m
$ git diff --color-moved
\e[1mdiff --git a/m.py b/m.py\e[m
\e[1mindex b8cfe23..2d281ed 100644\e[m
\e[1m--- a/m.py\e[m
\e[1m+++ b/m.py\e[m
\e[36m@@ -1,8 +1,8 @@\e[m
\e[1;35m-def alpha():\e[m
\e[1;35m-    return "first function body"\e[m
\e[31m-\e[m
 def beta():\e[m
     return "second function body"\e[m
 \e[m
 def gamma():\e[m
     return "third function body"\e[m
\e[32m+\e[m
\e[1;36m+\e[m\e[1;36mdef alpha():\e[m
\e[1;36m+\e[m\e[1;36m    return "first function body"\e[m
```

With `--color-moved`, the two lines of `alpha` that moved unchanged are drawn in
different colours from the blank lines that were genuinely removed and added.
If one character inside the moved block had changed, those lines would fall
back to ordinary red and green, and that contrast is the point.

### The modes

Plain `--color-moved` uses the default mode. A different one is chosen by adding
it after an `=`:

| Form | Behaviour |
|---|---|
| `--color-moved=no` | No move detection. Git's documentation says `--no-color-moved` is the same, and either one overrides `diff.colorMoved` for one command |
| `--color-moved`, `--color-moved=default` | The same as `zebra` |
| `--color-moved=plain` | Every moved line in the moved colours |
| `--color-moved=blocks` | Only blocks of at least 20 letters and digits count as moved |
| `--color-moved=zebra` | Like `blocks`, with alternating colours so two adjacent moved blocks can be told apart |
| `--color-moved=dimmed-zebra` | Like `zebra`, dimming the inside of moved blocks and highlighting their edges |

The difference between them only shows when there is more than one moved block.
In this file, `alpha` and `bravo` were each moved from different places and
ended up next to each other at the bottom:

```ansi
$ git diff --color-moved=no
\e[1mdiff --git a/f.txt b/f.txt\e[m
\e[1mindex f5e65bc..2722837 100644\e[m
\e[1m--- a/f.txt\e[m
\e[1m+++ b/f.txt\e[m
\e[36m@@ -1,11 +1,11 @@\e[m
\e[31m-alpha one alpha one alpha\e[m
\e[31m-alpha two alpha two alpha\e[m
 stays put number one here\e[m
 stays put number two here\e[m
 stays put number three here\e[m
\e[31m-bravo one bravo one bravo\e[m
\e[31m-bravo two bravo two bravo\e[m
 stays put number four here\e[m
 stays put number five here\e[m
 stays put number six here\e[m
\e[32m+\e[m\e[32mbravo one bravo one bravo\e[m
\e[32m+\e[m\e[32mbravo two bravo two bravo\e[m
\e[32m+\e[m\e[32malpha one alpha one alpha\e[m
\e[32m+\e[m\e[32malpha two alpha two alpha\e[m
 end\e[m
$ git diff --color-moved=plain
\e[1mdiff --git a/f.txt b/f.txt\e[m
\e[1mindex f5e65bc..2722837 100644\e[m
\e[1m--- a/f.txt\e[m
\e[1m+++ b/f.txt\e[m
\e[36m@@ -1,11 +1,11 @@\e[m
\e[1;35m-alpha one alpha one alpha\e[m
\e[1;35m-alpha two alpha two alpha\e[m
 stays put number one here\e[m
 stays put number two here\e[m
 stays put number three here\e[m
\e[1;35m-bravo one bravo one bravo\e[m
\e[1;35m-bravo two bravo two bravo\e[m
 stays put number four here\e[m
 stays put number five here\e[m
 stays put number six here\e[m
\e[1;36m+\e[m\e[1;36mbravo one bravo one bravo\e[m
\e[1;36m+\e[m\e[1;36mbravo two bravo two bravo\e[m
\e[1;36m+\e[m\e[1;36malpha one alpha one alpha\e[m
\e[1;36m+\e[m\e[1;36malpha two alpha two alpha\e[m
 end\e[m
$ git diff --color-moved=zebra
\e[1mdiff --git a/f.txt b/f.txt\e[m
\e[1mindex f5e65bc..2722837 100644\e[m
\e[1m--- a/f.txt\e[m
\e[1m+++ b/f.txt\e[m
\e[36m@@ -1,11 +1,11 @@\e[m
\e[1;35m-alpha one alpha one alpha\e[m
\e[1;35m-alpha two alpha two alpha\e[m
 stays put number one here\e[m
 stays put number two here\e[m
 stays put number three here\e[m
\e[1;35m-bravo one bravo one bravo\e[m
\e[1;35m-bravo two bravo two bravo\e[m
 stays put number four here\e[m
 stays put number five here\e[m
 stays put number six here\e[m
\e[1;36m+\e[m\e[1;36mbravo one bravo one bravo\e[m
\e[1;36m+\e[m\e[1;36mbravo two bravo two bravo\e[m
\e[1;33m+\e[m\e[1;33malpha one alpha one alpha\e[m
\e[1;33m+\e[m\e[1;33malpha two alpha two alpha\e[m
 end\e[m
$ git diff --color-moved=dimmed-zebra
\e[1mdiff --git a/f.txt b/f.txt\e[m
\e[1mindex f5e65bc..2722837 100644\e[m
\e[1m--- a/f.txt\e[m
\e[1m+++ b/f.txt\e[m
\e[36m@@ -1,11 +1,11 @@\e[m
\e[2m-alpha one alpha one alpha\e[m
\e[2m-alpha two alpha two alpha\e[m
 stays put number one here\e[m
 stays put number two here\e[m
 stays put number three here\e[m
\e[2m-bravo one bravo one bravo\e[m
\e[2m-bravo two bravo two bravo\e[m
 stays put number four here\e[m
 stays put number five here\e[m
 stays put number six here\e[m
\e[2m+\e[m\e[2mbravo one bravo one bravo\e[m
\e[1;36m+\e[m\e[1;36mbravo two bravo two bravo\e[m
\e[1;33m+\e[m\e[1;33malpha one alpha one alpha\e[m
\e[2;3m+\e[m\e[2;3malpha two alpha two alpha\e[m
 end\e[m
```

Look only at the four added lines at the bottom:

- **`no`** shows them as ordinary additions, the same green as any new line.
- **`plain`** marks all four as moved, in one colour, so nothing tells you that
  they came from two different places.
- **`zebra`** gives `bravo` one colour and `alpha` another. Where the colour
  changes is where one moved block ends and the next begins.
- **`dimmed-zebra`** dims the lines inside the moved blocks and keeps colour
  only on the two lines that meet at the boundary, which is the place most
  likely to hide a mistake.

`default` really is `zebra`:

```ansi
$ git diff --color-moved=default > ../a.diff; git diff --color-moved=zebra > ../b.diff; cmp ../a.diff ../b.diff && echo same
same
```

`blocks` differs from `plain` on short lines. Here `x = 1` moved from the top to
the bottom:

```ansi
$ git diff --color-moved=plain
\e[1mdiff --git a/s.txt b/s.txt\e[m
\e[1mindex 2d2c140..5dd8632 100644\e[m
\e[1m--- a/s.txt\e[m
\e[1m+++ b/s.txt\e[m
\e[36m@@ -1,4 +1,4 @@\e[m
\e[1;35m-x = 1\e[m
 a long enough line of real content here\e[m
 another long line of genuine content\e[m
 y = 2\e[m
\e[1;36m+\e[m\e[1;36mx = 1\e[m
$ git diff --color-moved=blocks
\e[1mdiff --git a/s.txt b/s.txt\e[m
\e[1mindex 2d2c140..5dd8632 100644\e[m
\e[1m--- a/s.txt\e[m
\e[1m+++ b/s.txt\e[m
\e[36m@@ -1,4 +1,4 @@\e[m
\e[31m-x = 1\e[m
 a long enough line of real content here\e[m
 another long line of genuine content\e[m
 y = 2\e[m
\e[32m+\e[m\e[32mx = 1\e[m
```

`plain` calls it moved. `blocks` does not, because `x = 1` has only two letters
and digits, far short of the 20 that Git's documentation sets as the minimum. That threshold exists because short lines such as
`}` or `return` repeat everywhere in code, and treating each one as "moved"
paints half the diff in move colours for no reason. The documentation says
`zebra` detects blocks the same way `blocks` does, and `dimmed-zebra` is built
on `zebra`, so both apply the same threshold. You may also meet
`dimmed_zebra` with an underscore; it is a deprecated spelling of the same mode.

Move detection needs colour, so it does nothing in a patch file or when output
is piped. Set `diff.colorMoved` to make a mode the default.

## Algorithms

A diff is not unique. Many sequences of deletions and additions turn one file
into another, and the algorithm decides which you see. Usually they agree. Here
is a case where they do not: a function `fib` was added, one `printf` was
removed, and the function `fact` was deleted.

```console
$ git diff --diff-algorithm=myers
diff --git a/frob.c b/frob.c
index 6faa5a3..e3af329 100644
--- a/frob.c
+++ b/frob.c
@@ -1,26 +1,25 @@
 #include <stdio.h>
 
-// Frobs foo heartily
-int frobnitz(int foo)
+int fib(int n)
 {
-    int i;
-    for(i = 0; i < 10; i++)
+    if(n > 2)
     {
-        printf("Your answer is: ");
-        printf("%d\n", foo);
+        return fib(n-1) + fib(n-2);
     }
+    return 1;
 }
 
-int fact(int n)
+// Frobs foo heartily
+int frobnitz(int foo)
 {
-    if(n > 1)
+    int i;
+    for(i = 0; i < 10; i++)
     {
-        return fact(n-1) * n;
+        printf("%d\n", foo);
     }
-    return 1;
 }
 
 int main(int argc, char **argv)
 {
-    frobnitz(fact(10));
+    frobnitz(fib(10));
 }
$ git diff --diff-algorithm=histogram
diff --git a/frob.c b/frob.c
index 6faa5a3..e3af329 100644
--- a/frob.c
+++ b/frob.c
@@ -1,26 +1,25 @@
 #include <stdio.h>
 
+int fib(int n)
+{
+    if(n > 2)
+    {
+        return fib(n-1) + fib(n-2);
+    }
+    return 1;
+}
+
 // Frobs foo heartily
 int frobnitz(int foo)
 {
     int i;
     for(i = 0; i < 10; i++)
     {
-        printf("Your answer is: ");
         printf("%d\n", foo);
     }
 }
 
-int fact(int n)
-{
-    if(n > 1)
-    {
-        return fact(n-1) * n;
-    }
-    return 1;
-}
-
 int main(int argc, char **argv)
 {
-    frobnitz(fact(10));
+    frobnitz(fib(10));
 }
```

Both are correct, and both have the same hunk header, the same total number of
lines, and the same result when applied. The first is nearly impossible to
review: it reused the braces and blank lines of `frobnitz` and `fact` to build
`fib`, so every function appears to have been rewritten. The second shows what
a person actually did.

The reason is in how each chooses. Myers finds the smallest edit script by
matching as many lines as possible, and braces, blank lines and `return 1;`
are excellent matches that mean nothing. Patience and histogram first anchor on
lines that appear only once in each version, such as `// Frobs foo heartily`,
and so line up the real structure.

The algorithm is chosen with `--diff-algorithm=<name>`, and three of the four
also have a shorter spelling of their own:

| Form | Character |
|---|---|
| `--diff-algorithm=myers` | The default. Fast, occasionally produces a pairing like the one above |
| `--diff-algorithm=minimal`, `--minimal` | Myers, spending extra effort for the smallest possible diff |
| `--diff-algorithm=patience`, `--patience` | Anchors on lines that are unique on both sides. Good for reordered code |
| `--diff-algorithm=histogram`, `--histogram` | An extension of patience, generally the best readability for the cost |

Myers has no shorter spelling, because it is what you get without asking. On
this file, two pairs of algorithms give byte-for-byte identical output:

```console
$ git diff --minimal > ../a.diff; git diff --diff-algorithm=myers > ../b.diff; cmp ../a.diff ../b.diff && echo same
same
$ git diff --patience > ../a.diff; git diff --histogram > ../b.diff; cmp ../a.diff ../b.diff && echo same
same
```

`--minimal` did not improve on Myers here, because the Myers result was already
the smallest; the problem was never size. `git config set diff.algorithm
histogram` is a reasonable global setting.

### Choosing which lines stay put

`--anchored=<text>` tells Git which lines to treat as not moving, when the same
change can be described in more than one way:

```console
$ git diff
diff --git a/fruit.txt b/fruit.txt
index fde8dcd..1801844 100644
--- a/fruit.txt
+++ b/fruit.txt
@@ -1,3 +1,3 @@
+cherry
 apple
 banana
-cherry
$ git diff --anchored=cherry
diff --git a/fruit.txt b/fruit.txt
index fde8dcd..1801844 100644
--- a/fruit.txt
+++ b/fruit.txt
@@ -1,3 +1,3 @@
-apple
-banana
 cherry
+apple
+banana
```

The list went from apple, banana, cherry to cherry, apple, banana. Either
`cherry` moved to the top, or `apple` and `banana` moved to the bottom. Both
describe the same change. `--anchored=cherry` tells Git which reading you mean:
keep lines starting with `cherry` unchanged if at all possible, and describe
everything else as moving around them.

## Keeping only some kinds of change

`--diff-filter` limits the diff to files that changed in a particular way. It
takes one or more letters after an `=`, the same letters `--name-status`
prints:

| Form | Keeps only files that were |
|---|---|
| `--diff-filter=A` | Added |
| `--diff-filter=D` | Deleted |
| `--diff-filter=M` | Modified |
| `--diff-filter=R` | Renamed |
| `--diff-filter=C` | Copied |
| `--diff-filter=T` | Changed type, for instance from a file to a symbolic link |
| `--diff-filter=U` | Unmerged, which only happens during a conflict (Chapter 26) |
| `--diff-filter=AD` | Added or deleted. Letters combine |
| `--diff-filter=d` | Anything except deleted. A lowercase letter excludes |

Starting from a change that adds one file, modifies one and deletes one:

```console
$ git diff --staged --name-status
A	add.txt
M	edit.txt
D	remove.txt
$ git diff --staged --name-status --diff-filter=A
A	add.txt
$ git diff --staged --name-status --diff-filter=D
D	remove.txt
$ git diff --staged --name-status --diff-filter=AD
A	add.txt
D	remove.txt
$ git diff --staged --name-status --diff-filter=d
A	add.txt
M	edit.txt
```

`d` kept the addition and the modification and dropped the deletion. Git's
documentation gives `ad` as its own example of excluding two kinds at once.

The other letters need renames, copies and a type change to exist. This change
edits a file, renames one, copies one from a file that was also edited, and
turns an ordinary file into a symbolic link. `-C` is there so copies are
detected at all (see "Renames and copies"):

```console
$ git diff --staged -C --name-status
C100	source.txt	copied.txt
M	edit.txt
T	link-me.txt
R100	rename-me.txt	renamed.txt
M	source.txt
$ git diff --staged -C --name-status --diff-filter=M
M	edit.txt
M	source.txt
$ git diff --staged -C --name-status --diff-filter=R
R100	rename-me.txt	renamed.txt
$ git diff --staged -C --name-status --diff-filter=C
C100	source.txt	copied.txt
$ git diff --staged -C --name-status --diff-filter=T
T	link-me.txt
```

Two things in that output are easy to misread. `source.txt` appears twice: once
as the source of a copy, and once in its own right as modified, because it was
both. And without `-C`, `copied.txt` would be reported as `A`, and
`--diff-filter=C` would find nothing at all, since there would be no copies for
it to keep.

> **Worth knowing.** `git diff --diff-filter=D --name-only HEAD~10 HEAD` lists
> every file deleted in the last ten commits, which answers "where did that file
> go" faster than any amount of scrolling.

## Prefixes, output files, and file names

### What a/ and b/ are for

Every path in a diff header carries a prefix, `a/` for the old side and `b/`
for the new. Three options change or remove them:

```console
$ git diff
diff --git a/p.txt b/p.txt
index 5626abf..f719efd 100644
--- a/p.txt
+++ b/p.txt
@@ -1 +1 @@
-one
+two
$ git diff --no-prefix
diff --git p.txt p.txt
index 5626abf..f719efd 100644
--- p.txt
+++ p.txt
@@ -1 +1 @@
-one
+two
$ git diff --src-prefix=old/ --dst-prefix=new/
diff --git old/p.txt new/p.txt
index 5626abf..f719efd 100644
--- old/p.txt
+++ new/p.txt
@@ -1 +1 @@
-one
+two
```

The prefixes are only labels. They are the reason `patch -p1` exists: `-p1` strips one leading directory from each path. A diff
made with `--no-prefix` needs `patch -p0` instead.

### Why some diffs say i/ and w/

The `diff.mnemonicPrefix` setting replaces `a/` and `b/` with letters that say
where each side came from. `git -c <name>=<value>` sets it here for one command
only (Chapter 62):

```console
$ git -c diff.mnemonicPrefix=true diff
diff --git i/p.txt w/p.txt
index 5626abf..f719efd 100644
--- i/p.txt
+++ w/p.txt
@@ -1 +1 @@
-one
+two
$ git add p.txt && git -c diff.mnemonicPrefix=true diff --staged
diff --git c/p.txt i/p.txt
index 5626abf..f719efd 100644
--- c/p.txt
+++ i/p.txt
@@ -1 +1 @@
-one
+two
$ git -c diff.mnemonicPrefix=true diff --staged --default-prefix
diff --git a/p.txt b/p.txt
index 5626abf..f719efd 100644
--- a/p.txt
+++ b/p.txt
@@ -1 +1 @@
-one
+two
```

If someone's diffs show `i/` and `w/`, they have `diff.mnemonicPrefix` set.
The letters say where each side came from, which makes it impossible to confuse
`git diff` with `git diff --staged` at a glance:

| Prefix | That side of the diff comes from |
|---|---|
| `c/` | a commit |
| `i/` | the index |
| `w/` | the working tree |
| `o/` | an object named directly |

`--default-prefix` forces `a/` and `b/` back for one command, whatever the
configuration says, which is what you want before saving a diff for someone
else to apply.

> **Since Git 2.45.** `diff.srcPrefix` and `diff.dstPrefix`, to set your own
> prefixes permanently.

### Writing to a file

`--output=<file>` writes the result to a file instead of the screen:

```console
$ git diff --staged --stat --output=../saved.txt
$ cat ../saved.txt
 p.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

The result is the same as redirecting with `>`. The option is useful where a
shell redirect is not available, such as in a command another program runs for
you.

### File names that come out as numbers

The staged change below adds a file whose name contains a letter outside plain
ASCII:

```console
$ git diff --staged --name-only
"caf\303\251.txt"
p.txt
$ git -c core.quotePath=false diff --staged --name-only
café.txt
p.txt
$ git diff --staged --name-only -z | tr '\000' '|'; echo
café.txt|p.txt|
```

The file is called `café.txt`. By default Git quotes any name containing bytes
outside plain ASCII and writes them as octal escapes, so `é` became `\303\251`.
Setting `core.quotePath` to `false` prints names as they are, which you almost
certainly want if you work in any language other than English.

`-z` separates names with a NUL byte instead of a newline and never quotes them.
The `tr` turns each NUL into a `|` so you can see it. That is the form to use in
scripts, because a file name can legally contain a newline, and a newline-based
script would then treat one file as two.

## Binary files

For a file Git considers binary, it does not print lines of content:

```console
$ git diff
diff --git a/image.bin b/image.bin
index 8352675..75218e8 100644
Binary files a/image.bin and b/image.bin differ
$ git diff --numstat
-	-	image.bin
$ git diff --stat
 image.bin | Bin 3 -> 4 bytes
 1 file changed, 0 insertions(+), 0 deletions(-)
```

No content, a dash where `--numstat` would count lines, and a size change in
`--stat`. Git decides a file is binary by looking at its content, and a NUL
byte, which never appears in ordinary text, is the telltale sign. Chapter 65
shows how `.gitattributes` overrides that decision.

You can force a text diff, which is rarely readable:

```console
$ git diff --text | cat -v
diff --git a/image.bin b/image.bin
index 8352675..75218e8 100644
--- a/image.bin
+++ b/image.bin
@@ -1 +1 @@
-^@^A^B
\ No newline at end of file
+^@			
\ No newline at end of file
```

`cat -v` shows the control bytes: `^@` is NUL, `^A` and `^B` are bytes 1 and 2.

### A binary patch, and who can apply it

`--binary` makes the diff carry the binary content itself, so that it can be
applied as a patch:

```console
$ git diff --binary > ../binary.diff && cat ../binary.diff
diff --git a/image.bin b/image.bin
index 8352675d67aed6625ece79af41c27fdb4ee2e867..75218e894e32342684e832bb24ab81135eac8900 100644
GIT binary patch
literal 4
LcmZSJ<m3bZ06G91

literal 3
KcmZQzWC8#H2LJ>B

$ git checkout -q -- image.bin
$ patch -p1 < ../binary.diff; echo exit=$?
File image.bin: git binary diffs are not supported.
exit=1
$ git apply ../binary.diff; echo exit=$?
exit=0
$ git status --short
 M image.bin
```

`--binary` encodes the new content into the patch, with full hashes on the
`index` line. GNU `patch`, the traditional tool for applying diffs, refuses it
outright. `git apply` applies it. The section "git diff and the diff command"
compares the two tools on ordinary text changes, where they are much closer.

Chapter 65 covers `.gitattributes`, which can teach Git to show a readable diff
for a binary format by converting it to text first.

## Exit codes

By default `git diff` exits with 0 whether or not it found a difference.
`--exit-code` and `--quiet` make the exit status report differences instead,
which is what a script needs:

```console
$ git diff --quiet && echo 'clean (exit 0)' || echo 'dirty (exit 1)'
clean (exit 0)
$ git diff --quiet && echo 'clean (exit 0)' || echo 'dirty (exit 1)'
dirty (exit 1)
$ git diff --exit-code --stat || echo '(exit was non-zero)'
 story.txt | 6 +-----
 1 file changed, 1 insertion(+), 5 deletions(-)
(exit was non-zero)
```

| Option | Prints output | Exit code |
|---|---|---|
| (neither) | yes | always 0 |
| `--exit-code` | yes | 1 if there were differences |
| `--quiet` | no | 1 if there were differences |
| `--no-index` | yes | 1 if there were differences, without asking |
| `--check` | yes | non-zero if there were whitespace errors |

`git diff --quiet` asks whether tracked files have unstaged changes, and
`git diff --quiet --staged` asks whether anything is staged. Both are much more
reliable than parsing `git status`.

But "tracked" is doing a lot of work in that sentence. Create a file and never
add it:

```console
$ git diff --quiet && echo 'clean (exit 0)' || echo 'dirty (exit 1)'
clean (exit 0)
$ git status --short
?? brand-new.txt
```

> **Careful.** `git diff --quiet` says clean while an untracked file sits in
> the working tree, because untracked files are invisible to every form of
> `git diff`. A release script that checks "is the tree clean" this way will
> happily build with a stray file present. `git status --porcelain` with an
> empty result is the check that includes untracked files (Chapter 10).

> **Careful.** In a script with `set -e`, a bare `git diff --quiet` on a dirty
> tree exits the script, because a non-zero status is the answer rather than an
> error. Write it as a condition, `if git diff --quiet; then ... fi`, or append
> `|| true` when you only want the side effect.

## git diff and the diff command

Unix has had a `diff` command since the 1970s, and Git for Windows bundles one.
Having seen everything `git diff` does, the fair question is how much of it the
ordinary `diff` could have done, and why `git diff` exists at all.

### Plain diff compares two files, and nothing else

Given only one file, `diff` cannot do anything:

```console
$ diff -u story.txt
diff: missing operand after 'story.txt'
diff: Try 'diff --help' for more information.
```

`diff` needs two files on disk. It knows nothing about commits or the index.
To compare your edited file with the last commit, you first have to get the
committed version out of Git into a file of its own. `git show HEAD:story.txt`
prints the file as it is in the last commit, using the same `<commit>:<path>`
form as the blob comparison earlier:

```console
$ git show HEAD:story.txt > ../story-committed.txt
$ diff -u ../story-committed.txt story.txt
--- ../story-committed.txt	2026-01-05 08:00:00.000000000 +0000
+++ story.txt	2026-01-05 09:00:00.000000000 +0000
@@ -1,3 +1,3 @@
 Once upon a time
-there was a repository.
+there was a git repository.
 The end.
$ git diff
diff --git a/story.txt b/story.txt
index d1747ff..e3caeae 100644
--- a/story.txt
+++ b/story.txt
@@ -1,3 +1,3 @@
 Once upon a time
-there was a repository.
+there was a git repository.
 The end.
```

The body is identical, because both use the same unified format. The headers
differ: `diff -u` prints modification times, while `git diff` prints the blob
hashes and the file mode, and adds a `diff --git` line that later tools use to
recognise renames and binary changes.

| | `diff -u` | `git diff` |
|---|---|---|
| Compares two files on disk | yes | yes, with `--no-index` |
| Compares against the index | no | yes, the default |
| Compares against any commit | only after extracting it yourself | yes |
| Compares two commits | no | yes |
| Detects renames and copies | no | yes |
| Word-level diffs | no | yes |
| Recognises binary files | only says they differ | yes, and can produce a binary patch |
| Shows moved code differently | no | yes |
| Exits 1 when files differ | yes | only with `--exit-code` or `--quiet` |

So `git diff` is not a reimplementation of `diff`. It is a diff engine that
knows where Git keeps every version of every file.

### They do not exit the same way

Both commands below compare the same two versions of `story.txt`; only the exit
status is printed:

```console
$ diff -u ../story-committed.txt story.txt > /dev/null; echo exit=$?
exit=1
$ git diff > /dev/null; echo exit=$?
exit=0
$ git diff --exit-code > /dev/null; echo exit=$?
exit=1
```

`diff` exits 1 when the files differ. `git diff` exits 0 whether or not there
are changes, because it treats showing you a diff as success. `--exit-code`
gives you `diff`'s behaviour, as the Exit codes section showed.

> **Careful.** A script that swaps `diff a b` for `git diff a b` and tests the
> exit status will silently stop detecting changes.

### Inside a repository, two paths are not two files

This one looks like it works and does not:

```console
$ git diff draft-one.txt draft-two.txt; echo exit=$?
exit=0
$ git diff --no-index draft-one.txt draft-two.txt; echo exit=$?
diff --git a/draft-one.txt b/draft-two.txt
index f8704fb..48d0939 100644
--- a/draft-one.txt
+++ b/draft-two.txt
@@ -1,2 +1,2 @@
 alpha
-bravo
+charlie
exit=1
```

Both files are tracked and differ from each other, and the first command printed
nothing. Inside a repository, `git diff a b` means "show my uncommitted changes
to `a` and to `b`", with the two names as a pathspec. Neither file had
uncommitted changes, so there was nothing to show.

`--no-index` is what turns two names into two files to compare.

### Outside a repository, --no-index is implied

In a directory that is not inside any repository, `git diff` accepts two file
names directly:

```console
$ git rev-parse --is-inside-work-tree
fatal: not a git repository (or any of the parent directories): .git
$ git diff one.txt two.txt; echo exit=$?
diff --git a/one.txt b/two.txt
index f8704fb..48d0939 100644
--- a/one.txt
+++ b/two.txt
@@ -1,2 +1,2 @@
 alpha
-bravo
+charlie
exit=1
```

Git's documentation spells out the rule: `--no-index` may be left out when you
are outside a repository, or when at least one of the two paths points outside
the working tree. In every other case, write it. And note that this form exits
1 on a difference by itself, unlike the rest of `git diff`.

That makes `git diff --no-index` a genuinely better `diff` for everyday use,
because you get rename detection, word diffs, `--stat`, and colour between any
two files or directories:

```console
$ git diff --no-index one.txt two.txt
diff --git a/one.txt b/two.txt
index f8704fb..48d0939 100644
--- a/one.txt
+++ b/two.txt
@@ -1,2 +1,2 @@
 alpha
-bravo
+charlie
$ git diff --no-index --stat one.txt two.txt
 one.txt => two.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

### Can the patch command use git diff output?

Yes, for text changes, and a current GNU `patch` even understands Git's rename
headers:

```console
$ git diff --staged > ../change.diff
$ cat ../change.diff
diff --git a/extra.txt b/renamed.txt
similarity index 100%
rename from extra.txt
rename to renamed.txt
diff --git a/story.txt b/story.txt
index d1747ff..e3caeae 100644
--- a/story.txt
+++ b/story.txt
@@ -1,3 +1,3 @@
 Once upon a time
-there was a repository.
+there was a git repository.
 The end.
$ git reset -q --hard
$ patch -p1 < ../change.diff
patching file renamed.txt (renamed from extra.txt)
patching file story.txt
$ git status --short
 D extra.txt
 M story.txt
?? renamed.txt
```

`-p1` strips the `a/` and `b/` prefixes. The rename applied, but only to the
files on disk: `patch` knows nothing about the index, so Git now sees a deleted
file and an untracked one rather than a staged rename.

Binary changes are where the two part ways, as the Binary files section showed:
`patch` refused a binary patch that `git apply` accepted. `git apply` is covered
properly in Chapter 61.

In the transcript above, `git reset -q --hard` threw away the staged rename and
the edit so that `patch` had something to apply them to. It discards every
uncommitted change in the repository, which is why it appears here only as a
setup step; Chapter 30 covers it properly.

## The pager

On a terminal, a long diff opens in a pager rather than scrolling past. People
new to Git regularly get stuck in it.

| Want | Do |
|---|---|
| Leave the pager | Press `q` |
| Scroll | Space and `b`, or the arrow keys |
| Search | `/` then a word, `n` for the next match |
| Skip the pager once | `git --no-pager diff` |
| Never page `git diff` | `git config set pager.diff false` |
| Choose another pager | `core.pager`, or the `GIT_PAGER` variable |

Git's documentation gives the order it looks in: `GIT_PAGER`, then
`core.pager`, then `PAGER`, then the built-in default, usually `less`. When
`LESS` is not set, Git sets it to `FRX`. The `F` is why a short diff prints and
returns you to the prompt immediately instead of opening the pager: `less` quits
by itself when everything fits on one screen.

`--no-pager` goes before the subcommand, because it is an option to `git`
itself, not to `diff`.

## Commands that look similar

Several other commands print diffs, or compare things in a similar way. This
table is for deciding which one you want:

| Command | Does | Difference from `git diff` |
|---|---|---|
| `diff`, `diff -u` | Compares two files on disk | Knows nothing about Git; see the first section |
| `git diff --no-index` | `git diff` between two files on disk | The same engine, no repository involved |
| `git show <commit>` | A commit's header plus its diff against its parent | Always relative to the parent; handles root commits |
| `git log -p` | That, for every commit in a range | One diff per commit instead of one combined diff |
| `git status -v` | Status plus the staged diff | The same as `git diff --staged`, printed under the status |
| `git difftool` | Opens the same comparison in an external viewer | Same arguments, shown in a graphical or side-by-side tool |
| `git range-diff` | Compares two versions of a series of commits | Compares whole commits against commits, typically before and after a rebase. Chapter 35 |
| `git diff-files` | Working tree against the index | Plumbing: meant for scripts, with output that does not change between versions. Chapter 75 |
| `git diff-index` | A commit's tree against the working tree or the index | Plumbing. Chapter 75 |
| `git diff-tree` | The blobs in two trees | Plumbing. Chapter 75 |

## The settings

These configuration settings change what `git diff` does by default, so that
you do not have to type the option every time. Set one with
`git config set --global <name> <value>` (Chapter 62); an option given on the
command line still wins for that one command.

| Setting | Effect |
|---|---|
| `diff.algorithm` | Default algorithm. `histogram` is a good choice |
| `diff.renames` | `false`, `true`, or `copies` |
| `diff.renameLimit` | The configuration form of `-l` |
| `diff.context` | Default number of context lines |
| `diff.interHunkContext` | Default for `--inter-hunk-context` |
| `diff.colorMoved` | Default mode for `--color-moved` |
| `diff.wordRegex` | Default word pattern for word diffs |
| `diff.dirstat` | Default parameters for `--dirstat` |
| `diff.mnemonicPrefix` | Use `c/`, `i/`, `w/` and `o/` instead of `a/` and `b/` |
| `diff.noPrefix` | Show no prefixes at all |
| `diff.srcPrefix`, `diff.dstPrefix` | Your own prefixes. Since Git 2.45 |
| `diff.relative` | Make `--relative` the default. Since Git 2.28 |
| `diff.external` | An external program to produce diffs (Chapter 65) |
| `color.diff` | Whether to colour diffs |
| `core.quotePath` | Whether to escape non-ASCII file names |
| `core.whitespace` | What `--check` counts as an error |
| `pager.diff` | Whether, or through what, to page `git diff` |
