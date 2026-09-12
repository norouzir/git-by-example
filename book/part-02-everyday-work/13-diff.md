# Chapter 13. diff

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

## Which two things

This is the part people get wrong, so it is worth repeating from Chapter 5:

| Command | Compares |
|---|---|
| `git diff` | working tree against index |
| `git diff --staged` | index against HEAD |
| `git diff HEAD` | working tree against HEAD |
| `git diff <commit>` | working tree against that commit |
| `git diff <a> <b>` | commit `a` against commit `b` |
| `git diff <a>..<b>` | the same thing; the dots are optional here |
| `git diff <a>...<b>` | the merge base of `a` and `b` against `b` |
| `git diff --no-index <f1> <f2>` | two files, with no repository involved |

## How much context

```console
$ git diff -U1
@@ -1,3 +1,3 @@
 Once upon a time
-there was a repository.
+there was a git repository.
 It had many commits.
$ git diff -U0
@@ -2 +2 @@ Once upon a time
-there was a repository.
+there was a git repository.
```

Three lines of context is the default. `-U0` gives none, which is what you want
when generating a patch to apply mechanically and the worst thing to read by
eye. Note the hunk header shrinks with the context, and that the text after
`@@` is the enclosing function or section Git guessed at.

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
| `--stat` | A bar chart per file | Reading. The bars are scaled, not literal |
| `--numstat` | Added, deleted, path, tab-separated | Scripts. No scaling, no truncation |
| `--shortstat` | Just the totals line | A quick size check |
| `--name-only` | Paths | Feeding into another command |
| `--name-status` | A status letter and path | Seeing what was added or deleted |
| `--summary` | Creations, deletions, renames, mode changes | Spotting structural changes |

> **Careful.** The `+` and `-` characters in `--stat` are proportional, not a
> count. A file showing `2 +-` may have had a hundred lines changed. Use
> `--numstat` whenever the number matters.

## Word-level diffs

Line diffs are useless for prose, where changing one word marks the whole
paragraph as rewritten.

```console
$ git diff --word-diff story.txt
@@ -1,4 +1,4 @@
Once upon a time
there was a {+git+} repository.
It had many commits.
The end.
```

Additions in `{+ +}`, removals in `[- -]`. There is also
`--word-diff=porcelain` for scripts, and `--color-words`, which shows the same
information using colour instead of brackets and is the nicest to read on a
terminal.

`--word-diff-regex=<regex>` changes what counts as a word, which matters for
languages that do not put spaces between them.

## Comparing commits

```console
$ git diff HEAD~2 HEAD --stat
 config.ini | 3 ++-
 story.txt  | 3 ++-
 2 files changed, 4 insertions(+), 2 deletions(-)
$ git diff HEAD~2 HEAD -- story.txt
@@ -1,4 +1,5 @@
 Once upon a time
-there was a repository.
+there was a git repository.
 It had many commits.
+It had branches too.
 The end.
```

Everything after `--` is a pathspec, limiting the diff to those paths. The `--`
separates paths from revisions and is worth typing whenever a path could be
mistaken for a branch name.

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
```

| Form | Compares | Answers |
|---|---|---|
| `main..feature` | tip of `main` against tip of `feature` | What is different between these two right now? |
| `main...feature` | merge base against tip of `feature` | What did `feature` change since it diverged? |

The three-dot form is almost always what you want when reviewing a branch,
because it excludes work that happened on `main` in the meantime. It is what
GitHub and GitLab show in a pull request.

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
| `-G <regex>` | The diff text itself matches the regex |
| `--pickaxe-regex` | Treat `-S` as a regex rather than a literal string |
| `--pickaxe-all` | Show the whole commit, not just the matching file |

`-S` is the tool for "when was this function introduced or deleted". `-G` is
for "when did any line mentioning this change at all", which includes commits
that moved the line around. `-S` is what you want more often, because it
filters out noise.

This is the only reliable way to find where a piece of code went after it
disappeared. Chapter 21 uses it extensively.

## Whitespace

```console
$ git diff spaced.txt
@@ -1,2 +1,2 @@
-hello world
-second line
+hello    world
+second line   
$ git diff -b spaced.txt
$ git diff -w spaced.txt
```

Both flags suppressed a change that was entirely whitespace.

| Flag | Ignores |
|---|---|
| `--ignore-space-at-eol` | Whitespace at the end of lines only |
| `-b`, `--ignore-space-change` | Changes in the *amount* of whitespace, and trailing whitespace |
| `-w`, `--ignore-all-space` | Whitespace entirely, including indentation |
| `--ignore-blank-lines` | Lines that are only added or removed blank lines |
| `--ignore-cr-at-eol` | Carriage returns at end of line, useful across platforms |

`-b` still shows a line where whitespace appeared between two words that had
none. `-w` does not. Use `-b` when reviewing a reindentation and `-w` only when
you are sure whitespace cannot matter, which is untrue in Python, YAML and
Makefiles.

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

Rename detection is on by default, with `-M50%` as the effective threshold. So
a file that was renamed *and* half rewritten in one commit shows up as a
delete and an add, and its history appears to stop. That is the usual reason
`git log <file>` seems to lose the trail. `--follow` on `git log` works around
it for a single file, and Chapter 17 covers its limitations.

## Algorithms

```console
$ git diff --diff-algorithm=myers code.js
@@ -2,6 +2,10 @@ function a() {
   return 1;
 }
 
+function c() {
+  return 3;
+}
+
 function b() {
   return 2;
 }
$ git diff --diff-algorithm=histogram code.js
@@ -2,6 +2,10 @@ function a() {
   return 1;
 }
 
+function c() {
+  return 3;
+}
+
 function b() {
   return 2;
 }
```

Identical, and that is the normal case. The algorithms agree on most real
changes. They diverge on files with many near-identical blocks, where a bad
choice produces a diff that pairs the closing brace of one function with the
opening of another.

| Algorithm | Character |
|---|---|
| `myers` | The default. Fast, occasionally produces an ugly pairing |
| `minimal` | Myers, but spending extra effort for the smallest possible diff |
| `patience` | Anchors on lines that appear exactly once on each side. Good for reordered code |
| `histogram` | An extension of patience, generally the best readability for the cost |

`git config set diff.algorithm histogram` is a reasonable global setting. It
costs a little time and produces diffs that more often match what a human would
have written.

## Diffing files that are not in a repository

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

This works outside any repository at all. It is a genuinely better `diff` for
day-to-day use, because you get colour, word diffs, `--stat`, and rename
detection between two directories. Worth remembering when you are comparing two
downloaded files and there is no Git project in sight.

> **Worth knowing.** `--no-index` exits 1 when the files differ, so it composes
> with shell logic the same way `diff` does.

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

`git diff --quiet` is the correct way to ask "is the working tree dirty" in a
script. `git diff --quiet --staged` asks whether anything is staged. Both are
much more reliable than parsing `git status`.

> **Careful.** In a script with `set -e`, a bare `git diff --quiet` on a dirty
> tree exits the script, because a non-zero status is the answer rather than an
> error. Write it as a condition: `if git diff --quiet; then ... fi`, or append
> `|| true` when you only want the side effect.

## Binary files

Git will not print a diff of a binary file. It says so instead:

```
Binary files a/logo.png and b/logo.png differ
```

| Option | Does |
|---|---|
| `--binary` | Emit a binary patch that `git apply` can use |
| `--text`, `-a` | Treat the file as text and print it anyway |
| `--stat` | Still reports a size change |

Chapter 65 covers `.gitattributes` and how to teach Git to produce a readable
diff for a format it does not understand, for example by converting a document
to text first.

## The options worth knowing

| Option | Does |
|---|---|
| `--staged`, `--cached` | Compare the index against HEAD |
| `-U<n>`, `--unified=<n>` | Context lines |
| `--stat`, `--numstat`, `--shortstat` | Summaries |
| `--name-only`, `--name-status`, `--summary` | Path listings |
| `--word-diff[=<mode>]`, `--color-words` | Word-level output |
| `-w`, `-b`, `--ignore-blank-lines` | Whitespace handling |
| `-M`, `-C`, `--no-renames` | Rename and copy detection |
| `-S <string>`, `-G <regex>` | Search history by content change |
| `--diff-algorithm=<name>` | Choose the algorithm |
| `--diff-filter=<letters>` | Keep only Added, Modified, Deleted, Renamed and so on |
| `--exit-code`, `--quiet` | Report differences through the exit status |
| `--no-index` | Compare two paths outside version control |
| `-R` | Swap the two sides |
| `--src-prefix`, `--dst-prefix`, `--no-prefix` | Change or remove the `a/` and `b/` prefixes |
| `--color-moved` | Show moved blocks in a distinct colour rather than as add plus delete |
| `--submodule=<format>` | How to summarise submodule changes (Chapter 57) |

> **Worth knowing.** `--diff-filter` is underused. `git diff --diff-filter=D
> --name-only HEAD~10 HEAD` lists every file deleted in the last ten commits,
> which answers "where did that file go" faster than any amount of scrolling.
> Lowercase letters invert the selection, so `d` means "everything except
> deletions".
