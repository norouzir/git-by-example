# Chapter 13. diff

`git diff` shows the difference between two versions of your files. Which two
versions is the part that trips everyone, and most of this chapter is about
that, about reading the output, and about the dozens of ways to shape it.

## git diff and the diff command

Unix has had a `diff` command since the 1970s, and Git bundles one. So the
first fair question is why `git diff` exists at all.

### Plain diff compares two files, and nothing else

```console
$ diff -u story.txt
diff: missing operand after 'story.txt'
diff: Try 'diff --help' for more information.
```

`diff` needs two files on disk. It knows nothing about commits or the index.
To compare your edited file with the last commit, you first have to get the
committed version out of Git into a file of its own:

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
gives you `diff`'s behaviour, and the Exit codes section below covers scripts.

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

Binary changes are where the two part ways; the Binary files section below
shows `patch` refusing one that `git apply` accepts. `git apply` is covered
properly in Chapter 61.

## Reading one

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

## Which two things

This is the part people get wrong, so it is worth repeating from Chapter 5:

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

`-R` reverses the direction, and look closely: it swaps the prefixes as well, so
`b/` now comes first. A reversed diff applied as a patch undoes the original.

### One file across commits, or two different files

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

The `<commit>:<path>` form names a blob directly (Chapter 18), so you can
compare any file at any point in history with any other, even files with
different names.

| Form | Compares | Notes |
|---|---|---|
| `git diff A B -- file` | `file` in commit A with `file` in commit B | Follows the normal diff machinery, renames included |
| `git diff A:file B:file` | two blobs, directly | Works for two different paths; rename detection does not apply |

### Only my subdirectory

```console
$ git diff --stat
 outer.txt     | 2 +-
 sub/inner.txt | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)
$ git diff --relative --stat
 inner.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

Both run from inside `sub/`. Plain `git diff` shows the whole repository no
matter where you stand. `--relative` limits it to the current directory and
strips that directory from the paths. `--relative=<path>` does the same for a
path you name.

> **Since Git 2.28.** The `diff.relative` setting, to make this the default.

### New files do not appear

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

```console
$ git diff --dirstat
  23.1% docs/
  76.8% src/
$ git diff --dirstat=lines
  25.0% docs/
  75.0% src/
```

Thirty lines changed in `src/core.txt` and ten in `docs/guide.txt`. The two
answers differ because they measure differently:

| Parameter | Counts |
|---|---|
| `changes` | Changed content, not counting code that only moved. The default |
| `lines` | Lines added and removed, the same as `--stat` would. Slower |
| `files` | Changed files, each counting equally. Cheapest |
| `cumulative` | Also credit changes in a subdirectory to its parent |
| a number | Hide directories below that percentage. The default is 3 |

Parameters combine with commas, for example `--dirstat=files,10`.

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

| Mode | Shows changes as |
|---|---|
| `plain` | `[-removed-]{+added+}`. The default for `--word-diff` |
| `color` | Colour only, no brackets |
| `porcelain` | One piece per line, for scripts |
| `none` | Turns word diff off again |

### In colour

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

## Comparing commits

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

## Searching history through diffs

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

```console
$ git diff HEAD~1 HEAD --name-only
lib.c
notes.txt
$ git diff HEAD~1 HEAD --name-only -S frotz
lib.c
```

The pickaxe options are diff options, not log options. On `git diff` they keep
only the files where the count changed.

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

## Renames

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

| Mode | Behaviour |
|---|---|
| `no` | No move detection |
| `default` | The same as `zebra` |
| `plain` | Moved lines in the moved colours, with no distinction between blocks |
| `blocks` | Only blocks of at least 20 alphanumeric characters count as moved |
| `zebra` | Like `blocks`, alternating colours so adjacent moved blocks can be told apart |
| `dimmed-zebra` | Like `zebra`, dimming the uninteresting parts of moved blocks |

This needs colour, so it does nothing in a patch file or when piped. Set
`diff.colorMoved` to make it the default.

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

| Algorithm | Character |
|---|---|
| `myers` | The default. Fast, occasionally produces a pairing like the one above |
| `minimal` | Myers, spending extra effort for the smallest possible diff |
| `patience` | Anchors on lines that are unique on both sides. Good for reordered code |
| `histogram` | An extension of patience, generally the best readability for the cost |

Each has a shorter spelling, and on this file two pairs give identical output:

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

| Letter | Keeps |
|---|---|
| `A` | Added |
| `C` | Copied |
| `D` | Deleted |
| `M` | Modified |
| `R` | Renamed |
| `T` | Type changed |
| `U` | Unmerged |

Letters combine, so `AD` means added or deleted. Lowercase inverts: `d` means
everything *except* deletions, and `ad` excludes both added and deleted files.

> **Worth knowing.** `git diff --diff-filter=D --name-only HEAD~10 HEAD` lists
> every file deleted in the last ten commits, which answers "where did that file
> go" faster than any amount of scrolling.

## Prefixes, output files, and file names

### What a/ and b/ are for

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

`a/` and `b/` are just labels for "old" and "new". They are the reason
`patch -p1` exists: `-p1` strips one leading directory from each path. A diff
made with `--no-prefix` needs `patch -p0` instead.

### Why some diffs say i/ and w/

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

| Prefix | Side |
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

```console
$ git diff --staged --stat --output=../saved.txt
$ cat ../saved.txt
 p.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

`--output` is the same as redirecting with `>`, except that it works even where
a shell redirect is awkward, such as inside another program's configuration.

### File names that come out as numbers

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
`index` line. GNU `patch` refuses it outright. `git apply` applies it, and this
is the practical line between the two tools: for text they are close, for
binary files only Git will do.

Chapter 65 covers `.gitattributes`, which can teach Git to show a readable diff
for a binary format by converting it to text first.

## Exit codes

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

| Command | Does | Difference from `git diff` |
|---|---|---|
| `diff`, `diff -u` | Compares two files on disk | Knows nothing about Git; see the first section |
| `git diff --no-index` | `git diff` between two files on disk | The same engine, no repository involved |
| `git show <commit>` | A commit's header plus its diff against its parent | Always relative to the parent; handles root commits |
| `git log -p` | That, for every commit in a range | One diff per commit instead of one combined diff |
| `git status -v` | Status plus the staged diff | The same as `git diff --staged`, printed under the status |
| `git difftool` | Opens the same comparison in an external viewer | Same arguments, shown in a graphical or side-by-side tool |
| `git range-diff` | Compares two *versions of a branch* | A diff of diffs, used after a rebase. Chapter 35 |
| `git diff-files`, `git diff-index`, `git diff-tree` | Plumbing that `git diff` is built on | Stable output for scripts. Chapter 75 |

## The options table

| Option | Does |
|---|---|
| `--staged`, `--cached` | Compare the index against HEAD, or against a commit you name |
| `-U<n>`, `--unified=<n>` | Context lines |
| `-W`, `--function-context` | Show the whole function around each change |
| `--inter-hunk-context=<n>` | Merge hunks separated by up to `<n>` unchanged lines |
| `--stat[=<width>]` | A bar chart per file |
| `--stat-count=<n>` | List at most `<n>` files in `--stat` |
| `--numstat`, `--shortstat` | Exact counts, or only the total |
| `--name-only`, `--name-status`, `--summary` | Path listings |
| `--compact-summary` | `--stat` with creations, deletions and mode changes marked |
| `--dirstat[=<params>]` | Share of change per directory |
| `--word-diff[=<mode>]` | Word-level output |
| `--word-diff-regex=<regex>` | What counts as a word |
| `--color-words` | Word diff in colour |
| `-w`, `--ignore-all-space` | Ignore all whitespace |
| `-b`, `--ignore-space-change` | Ignore changes in the amount of whitespace |
| `--ignore-space-at-eol` | Ignore whitespace at line ends only |
| `--ignore-blank-lines` | Ignore added or removed blank lines |
| `--ignore-cr-at-eol` | Ignore a carriage return at line end |
| `--check` | Report whitespace errors and conflict markers |
| `-M[<n>]`, `--find-renames[=<n>]` | Rename detection and its threshold |
| `-C[<n>]`, `--find-copies[=<n>]` | Copy detection from changed files |
| `--find-copies-harder` | Copy detection from every file |
| `--no-renames` | Report renames as a delete plus an add |
| `-B`, `--break-rewrites` | Treat heavy rewrites as a delete plus an add |
| `-l <num>` | Limit how many files rename detection considers |
| `-S <string>`, `-G <regex>` | Filter by content change |
| `--pickaxe-regex` | Treat `-S` as a regex |
| `--pickaxe-all` | Keep every file in a matching commit |
| `--diff-algorithm=<name>` | Choose the algorithm |
| `--minimal`, `--patience`, `--histogram` | Shorter spellings for three algorithms |
| `--anchored=<text>` | Keep lines starting with `<text>` unchanged where possible |
| `--color-moved[=<mode>]` | Colour moved lines differently from changed ones |
| `--diff-filter=<letters>` | Keep only added, deleted, modified and so on |
| `--relative[=<path>]` | Limit to a directory and show paths relative to it |
| `-R` | Swap the two sides |
| `--no-prefix`, `--src-prefix`, `--dst-prefix` | Change or remove the `a/` and `b/` prefixes |
| `--default-prefix` | Use `a/` and `b/` whatever the configuration says |
| `--output=<file>` | Write to a file instead of standard output |
| `-z` | Separate paths with NUL and never quote them |
| `--binary` | Include binary content in the patch |
| `--text`, `-a` | Treat every file as text |
| `--exit-code`, `--quiet` | Report differences through the exit status |
| `--merge-base` | Compare from the merge base, like three dots |
| `--no-index` | Compare two paths outside version control |
| `--submodule[=<format>]` | How to show changed submodules. Chapter 57 |
| `--ext-diff`, `--textconv` | Use external diff drivers and converters. Chapter 65 |
| `--cc`, `-c` | Combined diff for a merge commit. Chapter 26 |

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

## The settings

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
