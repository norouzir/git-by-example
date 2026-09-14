# Chapter 11. add

## What it is

`git add` copies content from the working tree into the index. That is its only
job, and everything in this chapter is a variation on which content.

The index is the snapshot the next commit will be made from (Chapter 5). Adding
a file puts its current content there; it does not mark the file to be watched
from now on. Change the file again and the index still holds the version you
added, until you add again.

`git add` never touches your files and never makes a commit. Everything it does
can be undone, and [Undoing an add](#undoing-an-add) shows how.

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What does `git add` actually do? Does it commit anything?](#what-it-is)

**[Synopsis](#synopsis)**

- [What can I type after `git add`?](#synopsis)

**[Options at a glance](#options-at-a-glance)**

- [Is there a list of every option, and where each is explained?](#options-at-a-glance)

**[The plain form](#the-plain-form)**

- [Can I add several files in one command? Does adding a file twice cause a problem?](#the-plain-form)
- [I added a file, changed it again, and committed. Why is my latest change missing?](#adding-again-after-editing)
- [If I add a folder, does Git notice files I deleted inside it?](#a-directory)

**[What it actually does](#what-it-actually-does)**

- [Where does the content go when I run `git add`?](#what-it-actually-does)

**[Checking before you commit to it](#checking-before-you-commit-to-it)**

- [Can I see what `git add` would do without doing it?](#checking-before-you-commit-to-it)
- [Can `git add` tell me which files it added?](#checking-before-you-commit-to-it)

**[The four ways to say "everything"](#the-four-ways-to-say-everything)**

- [What is the difference between `git add -u`, `git add -A` and `git add .`?](#the-four-ways-to-say-everything)
- [I typed `git add` on its own and nothing happened. Why?](#the-four-ways-to-say-everything)

**[Where `.` and `-A` differ](#where-and-a-differ)**

- [`git add .` missed a file I changed. What happened?](#where-and-a-differ)
- [How do I stage only the changed files in my current folder?](#where-and-a-differ)

**[Pathspecs](#pathspecs)**

- [Should I put quotes around `*.md`?](#pathspecs)
- [How do I add a file whose name starts with a dash?](#pathspecs)
- [How do I add everything except log files?](#pathspec-magic)
- [Why did `*.log` add log files in subfolders too?](#pathspec-magic)
- [My file name contains `[` or `*`. How do I add just that file?](#pathspec-magic)
- [Can I give `git add` a list of files from another program?](#reading-paths-from-a-file)

**[Staging part of a file](#staging-part-of-a-file)**

- [I made two unrelated changes in one file. Can I commit them separately?](#staging-part-of-a-file)
- [What do all the letters in `[y,n,q,a,d,...]` mean?](#the-keys)
- [Why is `s` sometimes missing from the list?](#splitting-a-hunk)
- [Two changes are in one hunk. How do I stage only one of them?](#splitting-a-hunk)
- [How does editing a hunk with `e` work, and what if I get it wrong?](#editing-a-hunk)
- [Can I jump straight to a particular hunk?](#jumping-to-a-hunk)
- [Can I make the hunks smaller or bigger?](#more-context-or-less)
- [Patch mode moves to the next file before I'm ready. Can I stop that?](#several-files)
- [Is there a way to edit the whole diff at once instead of hunk by hunk?](#editing-the-whole-diff-at-once)
- [What does "No changes." mean?](#when-there-is-nothing-to-stage)

**[Interactive mode](#interactive-mode)**

- [What is `git add -i`, and how is it used?](#interactive-mode)

**[Ignored files](#ignored-files)**

- [Why does `git add` refuse a file, and what does `-f` do?](#ignored-files)
- [`git add .` didn't complain about my ignored files, but naming one did. Why the difference?](#ignored-files)
- [Git said the ignored file was refused. Were the other files I named added?](#ignored-files)

**[Saying a file is coming](#saying-a-file-is-coming)**

- [What is `git add -N` for?](#saying-a-file-is-coming)
- [If I commit after `git add -N`, does Git commit an empty file?](#saying-a-file-is-coming)

**[Setting the executable bit](#setting-the-executable-bit)**

- [How do I make a script executable in the repository from Windows?](#setting-the-executable-bit)

**[Line endings](#line-endings)**

- [I changed my line-ending settings. How do I fix files already committed?](#line-endings)

**[Refreshing the index](#refreshing-the-index)**

- [What does `git add --refresh` do?](#refreshing-the-index)

**[When a file cannot be added](#when-a-file-cannot-be-added)**

- [One file fails to add and nothing else gets added. Can Git skip it and carry on?](#when-a-file-cannot-be-added)

**[Embedded repositories](#embedded-repositories)**

- [How do I add a folder that contains its own repository without the warning?](#embedded-repositories)

**[Sparse checkouts](#sparse-checkouts)**

- [Git says a path is "outside of your sparse-checkout definition". What now?](#sparse-checkouts)

**[The errors](#the-errors)**

- [What do "did not match any files", "empty string is not a valid pathspec" and "outside repository" mean?](#the-errors)

**[Undoing an add](#undoing-an-add)**

- [How do I undo `git add`?](#undoing-an-add)
- [`git restore --staged` says "could not resolve HEAD". Why?](#undoing-an-add)

**[add and its neighbours](#add-and-its-neighbours)**

- [What is `git stage`? Is it different from `git add`?](#add-and-its-neighbours)
- [Does `git commit -a` add new files too?](#add-and-its-neighbours)

**[The settings](#the-settings)**

- [Which settings change how `git add` behaves?](#the-settings)

</details>

## Synopsis

```
git add [--verbose | -v] [--dry-run | -n] [--force | -f] [--interactive | -i] [--patch | -p]
        [--edit | -e] [--[no-]all | -A | --[no-]ignore-removal | [--update | -u]] [--sparse]
        [--intent-to-add | -N] [--refresh] [--ignore-errors] [--ignore-missing] [--renormalize]
        [--chmod=(+|-)x] [--pathspec-from-file=<file> [--pathspec-file-nul]]
        [--] [<pathspec>...]
```

| Part | Means |
|---|---|
| `<pathspec>` | Which files: a name, a directory, or a pattern. See [Pathspecs](#pathspecs) |
| `--` | Everything after it is a path, even if it starts with a dash |

| Command | Does |
|---|---|
| `git add <file>` | Stage the current content of one file |
| `git add <directory>` | Stage every change under a directory, deletions included |
| `git add -A` | Stage every change in the repository |
| `git add -u` | Stage changes to tracked files only, from anywhere |
| `git add -p` | Choose which changes to stage, piece by piece |

## Options at a glance

| Option | Does | Covered in |
|---|---|---|
| `-n`, `--dry-run` | Show what would be added, change nothing | [Checking before you commit to it](#checking-before-you-commit-to-it) |
| `-v`, `--verbose` | Print each path as it is added or removed | [Checking before you commit to it](#checking-before-you-commit-to-it) |
| `-u`, `--update` | Only files already tracked | [The four ways to say "everything"](#the-four-ways-to-say-everything) |
| `-A`, `--all`, `--no-ignore-removal` | Everything, from the repository root | [The four ways to say "everything"](#the-four-ways-to-say-everything) |
| `--no-all`, `--ignore-removal` | Add and modify, but do not record deletions | [A directory](#a-directory) |
| `--pathspec-from-file=<file>` | Read pathspecs from a file, one per line | [Reading paths from a file](#reading-paths-from-a-file) |
| `--pathspec-file-nul` | Those pathspecs are NUL-separated | [Reading paths from a file](#reading-paths-from-a-file) |
| `-p`, `--patch` | Choose hunk by hunk | [Staging part of a file](#staging-part-of-a-file) |
| `-U<n>`, `--unified=<n>` | Show hunks with `<n>` lines of context in patch mode | [More context, or less](#more-context-or-less) |
| `--inter-hunk-context=<n>` | Join hunks up to `<n>` lines apart in patch mode | [More context, or less](#more-context-or-less) |
| `--auto-advance`, `--no-auto-advance` | Move to the next file on your own, or stay until you ask | [Several files](#several-files) |
| `-e`, `--edit` | Edit the whole diff in your editor before staging | [Editing the whole diff at once](#editing-the-whole-diff-at-once) |
| `-i`, `--interactive` | The older menu interface | [Interactive mode](#interactive-mode) |
| `-f`, `--force` | Add ignored files too | [Ignored files](#ignored-files) |
| `--ignore-missing` | With `-n`, check whether a path would be ignored even if it does not exist | [Ignored files](#ignored-files) |
| `-N`, `--intent-to-add` | Record the path with empty content | [Saying a file is coming](#saying-a-file-is-coming) |
| `--chmod=+x` | Set the executable bit in the index | [Setting the executable bit](#setting-the-executable-bit) |
| `--chmod=-x` | Clear the executable bit in the index | [Setting the executable bit](#setting-the-executable-bit) |
| `--renormalize` | Re-apply line ending and filter rules to tracked files (Chapter 66) | [Line endings](#line-endings) |
| `--refresh` | Only update the index's cached file stats, stage nothing | [Refreshing the index](#refreshing-the-index) |
| `--ignore-errors` | Keep going if some files cannot be added | [When a file cannot be added](#when-a-file-cannot-be-added) |
| `--no-warn-embedded-repo` | Add a repository inside the repository without the warning | [Embedded repositories](#embedded-repositories) |
| `--sparse` | Allow adding paths outside the sparse-checkout cone (Chapter 60) | [Sparse checkouts](#sparse-checkouts) |

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

### Adding again after editing

```console
$ git add a.txt
$ git status --short
MM a.txt
$ git diff --staged
diff --git a/a.txt b/a.txt
index 5626abf..814f4a4 100644
--- a/a.txt
+++ b/a.txt
@@ -1 +1,2 @@
 one
+two
```

`a.txt` was changed to two lines and added, then a third line was written. The
index kept the two-line version, which is all a commit made now would contain.
Git's documentation says it directly: `git add` adds the content as it is when
you run it, and later changes need another `git add`.

### A directory

A directory stands for everything under it, including files that were deleted:

```console
$ git status --short dir
 D dir/x.txt
 M dir/y.txt
?? dir/z.txt
$ git add dir && git status --short dir
D  dir/x.txt
M  dir/y.txt
A  dir/z.txt
$ git reset -q
$ git add --no-all dir && git status --short dir
 D dir/x.txt
M  dir/y.txt
A  dir/z.txt
$ git reset -q
$ git add --ignore-removal dir && git status --short dir
 D dir/x.txt
M  dir/y.txt
A  dir/z.txt
```

`--no-all`, also spelled `--ignore-removal`, adds and updates but leaves the
deletion unstaged. Git's release notes for 2.0 say `git add <path>` ignored
removals until then, and this option keeps the old behaviour available.
`git reset -q` unstages everything again between the attempts; Chapter 30
covers it.

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

`:a.txt` is revision syntax for "the version of `a.txt` in the index"
(Chapter 18).

## Checking before you commit to it

```console
$ git add -n .
add 'c.txt'
$ git status --short
M  a.txt
?? c.txt
$ git add --dry-run c.txt
add 'c.txt'
```

`-n` is `--dry-run`. It lists what would be added and changes nothing. Worth
using any time you are about to run `git add` with a wildcard in a repository
you do not know well.

`-v` prints the same lines while actually doing it, and says `remove` for a
deletion:

```console
$ git add -v dir
remove 'dir/x.txt'
add 'dir/y.txt'
add 'dir/z.txt'
$ git reset -q
$ git add -n -v dir
remove 'dir/x.txt'
add 'dir/y.txt'
add 'dir/z.txt'
```

The two commands print the same; only the first changed the index.

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
$ git reset -q
$ git add -A && git status --short
M  a.txt
D  b.txt
A  c.txt
A  src/one.txt
A  src/two.txt
$ git reset -q
$ git add . && git status --short
M  a.txt
D  b.txt
A  c.txt
A  src/one.txt
A  src/two.txt
$ git reset -q
```

| Form | Modified | Deleted | Untracked |
|---|---|---|---|
| `git add -u` | yes | yes | **no** |
| `git add -A` | yes | yes | yes |
| `git add .` | yes | yes | yes |
| `git add :/` | yes | yes | yes |

From the top of the repository, `.` and `-A` are identical, which is why so
many people believe they are the same command.

Without any path, and without `-u` or `-A`, nothing happens:

```console
$ git add
Nothing specified, nothing added.
hint: Maybe you wanted to say 'git add .'?
hint: Disable this message with "git config set advice.addEmptyPathspec false"
```

## Where `.` and `-A` differ

They differ the moment you are not at the top. From inside `src`:

```console
$ git add . && git status --short
 M ../a.txt
 D ../b.txt
A  one.txt
A  two.txt
?? ../c.txt
$ git reset -q
$ git add -A && git status --short
M  ../a.txt
D  ../b.txt
A  ../c.txt
A  one.txt
A  two.txt
$ git reset -q
$ git add -A && git status --short
M  a.txt
D  b.txt
A  c.txt
A  src/one.txt
A  src/two.txt
```

`git add .` staged only what is under the current directory. `git add -A`
staged the whole repository regardless of where you are standing. The last
command ran from the top again, where the two agree.

`-u` behaves like `-A`: without a path it covers the whole repository. Given `.`,
either one stays in the current directory:

```console
$ cd dir && git add -u && cd ..
$ git status --short
M  a.txt
D  dir/x.txt
M  dir/y.txt
?? dir/z.txt
$ git reset -q
$ cd dir && git add -u . && cd ..
$ git status --short
 M a.txt
D  dir/x.txt
M  dir/y.txt
?? dir/z.txt
```

| You want | Command |
|---|---|
| Everything in this directory and below | `git add .` |
| Everything in the repository, from anywhere | `git add -A` |
| Everything in the repository, from anywhere, explicitly | `git add :/` |
| Changes to tracked files in the whole repository | `git add -u` |
| Changes to tracked files in this directory and below | `git add -u .` |

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
$ git reset -q
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

Git's documentation gives the other difference: in a pathspec, `*` matches `/`
too, so a quoted `'docs/*.md'` would also match `docs/old/notes.md`, while the
shell's `*` stops at a directory.

A file name that starts with a dash looks like an option. `--` marks the end of
the options:

```console
$ git add -n.txt
error: unknown switch `.'
usage: git add [<options>] [--] <pathspec>...
...
$ git add -- -n.txt && git status --short -- -n.txt
A  -n.txt
```

Git read `-n.txt` as `-n` followed by options `.`, `t`, `x` and `t`, and stopped
at the first one it did not know.

### Pathspec magic

A pathspec starting with a colon carries **magic words** that change how it is
matched:

```console
$ git add ':(glob)**/*.md' && git status --short
A  docs/api.md
A  docs/guide.md
?? docs/logo.png
$ git reset -q
$ git add ':!docs/logo.png' && git status --short
A  docs/api.md
A  docs/guide.md
?? docs/logo.png
```

The second command gave only an exclusion, and Git's documentation says an
exclusion with nothing to exclude from applies to everything, so every other
new file was added.

| Magic | Short form | Does |
|---|---|---|
| `:(top)` | `:/` | Match from the repository root, wherever you are standing |
| `:(literal)` | | Treat `*` and `?` as ordinary characters |
| `:(icase)` | | Match without regard to case |
| `:(glob)` | | Full shell globbing, where `*` does not cross a `/` and `**` does |
| `:(exclude)` | `:!` or `:^` | Remove matching paths from the result |
| `:(attr:...)` | | Match only paths with given gitattributes (Chapter 65) |

Each of them, in a repository with these new files: `a.txt`, `b.txt`, a file
literally named `[ab].txt`, `Notes.TXT`, `readme.txt`, `top.log`,
`src/debug.log` and `src/README.local`.

```console
$ git add '[ab].txt' && git status --short
A  [ab].txt
A  a.txt
A  b.txt
?? Notes.TXT
?? readme.txt
?? src/
?? top.log
$ git reset -q
$ git add ':(literal)[ab].txt' && git status --short
A  [ab].txt
?? Notes.TXT
?? a.txt
?? b.txt
?? readme.txt
?? src/
?? top.log
```

`[ab]` is a pattern meaning "one `a` or one `b`", so it matched three files: the
one with brackets in its name, which a path always matches, and the two the
pattern describes. `literal` matches only the name as written.

```console
$ git add '*.log' && git status --short
A  src/debug.log
A  top.log
?? Notes.TXT
?? [ab].txt
?? a.txt
?? b.txt
?? readme.txt
?? src/README.local
$ git reset -q
$ git add ':(glob)*.log' && git status --short
A  top.log
?? Notes.TXT
?? [ab].txt
?? a.txt
?? b.txt
?? readme.txt
?? src/
```

A plain `*.log` reached into `src/`, because `*` crosses `/`. With `glob`, it
matched at the top only, the way a shell would.

```console
$ git add '*.txt' && git status --short
A  [ab].txt
A  a.txt
A  b.txt
A  readme.txt
?? Notes.TXT
?? src/
?? top.log
$ git reset -q
$ git add ':(icase)*.txt' && git status --short
A  Notes.TXT
A  [ab].txt
A  a.txt
A  b.txt
A  readme.txt
?? src/
?? top.log
```

`Notes.TXT` needed `icase`, even on Windows, where the file system itself does
not care about case.

```console
$ cd src && git add ':(top,icase)README*' && cd .. && git status --short
A  readme.txt
?? Notes.TXT
?? [ab].txt
?? a.txt
?? b.txt
?? src/
?? top.log
$ git reset -q
$ git add . ':!*.log' && git status --short
A  Notes.TXT
A  [ab].txt
A  a.txt
A  b.txt
A  readme.txt
A  src/README.local
?? src/debug.log
?? top.log
$ git reset -q
$ git add ':^*.log' && git status --short
A  Notes.TXT
A  [ab].txt
A  a.txt
A  b.txt
A  readme.txt
A  src/README.local
?? src/debug.log
?? top.log
```

Magic words combine: `:(top,icase)README*` ran from `src` but matched from the
root, and in any case. It did not match `src/README.local`, because the pattern
starts at the root. And `:(exclude)` is the one you will actually reach for,
because "everything except that" is a common thing to want. `:^` is the same as
`:!`, and is easier to type in shells where `!` means something.

```console
$ git add ':(attr:generated)' && git status --short
A  top.log
?? .gitattributes
?? Notes.TXT
?? [ab].txt
?? a.txt
?? b.txt
?? readme.txt
?? src/
$ git reset -q
$ git add src/README.local && git add ':(attr:generated)' && git status --short
A  src/README.local
A  src/debug.log
A  top.log
?? .gitattributes
?? Notes.TXT
?? [ab].txt
?? a.txt
?? b.txt
?? readme.txt
$ git reset -q
$ git add ':(nonsense)x'
fatal: Invalid pathspec magic 'nonsense' in ':(nonsense)x'
```

Here `.gitattributes` held `*.log generated`, giving every `.log` file an
attribute called `generated`, and `attr` selected by that attribute. The first
time, `src/debug.log` was not matched although the pattern applies at any depth.
`src/` held nothing tracked, and `attr` did not look inside such a directory.
Once another file in `src/` was added, it did. Chapter 65 covers attributes.

> **Worth knowing.** Pathspecs are not specific to `add`. The same syntax works
> in `git diff`, `git log`, `git grep`, `git restore` and `git checkout`.
> Learning it once pays off in every chapter after this one.

### Reading paths from a file

When the list of files comes from another program, it can be read from a file,
or from standard input with `-`:

```console
$ cat list.txt
a.txt
src/README.local
$ git add --pathspec-from-file=list.txt && git status --short -uno
A  a.txt
A  src/README.local
$ git reset -q
$ printf 'b.txt\n' | git add --pathspec-from-file=- && git status --short -uno
A  b.txt
$ git reset -q
$ printf 'a.txt\0top.log\0' | git add --pathspec-from-file=- --pathspec-file-nul && git status --short -uno
A  a.txt
A  top.log
$ git reset -q
$ git add --pathspec-from-file=list.txt b.txt
fatal: '--pathspec-from-file' and pathspec arguments cannot be used together
$ git add --pathspec-file-nul a.txt
fatal: the option '--pathspec-file-nul' requires '--pathspec-from-file'
```

One path per line by default. With `--pathspec-file-nul` the paths are separated
by NUL bytes, and Git's documentation says every other character is then taken
literally, including newlines and quotes, which is what a file name with a
newline in it needs. `-uno` only keeps the untracked files out of the status
output (Chapter 10).

> **Since Git 2.25.** `--pathspec-from-file` and `--pathspec-file-nul`.

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
$ printf 'y\nn\n' | git add -p poem.txt
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
(1/2) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,e,p,P,?]? @@ -7,4 +7,4 @@ six
 seven
 eight
 nine
-ten
+TEN
(2/2) Stage this hunk [y,n,q,a,d,K,J,g,/,e,p,P,?]? 
$ git status --short
MM poem.txt
```

On a terminal you type each answer after its question mark and press Enter. The
examples feed the answers in with `printf`, so the letters you would type are in
the `printf` and not on the screen, and each hunk starts on the line where the
previous question ended.

The file is now staged and modified at once, with different content in each
place:

```console
$ git diff --staged
diff --git a/poem.txt b/poem.txt
index c9e9e05..cf24bdb 100644
--- a/poem.txt
+++ b/poem.txt
@@ -1,4 +1,4 @@
-one
+ONE
 two
 three
 four
$ git diff
diff --git a/poem.txt b/poem.txt
index cf24bdb..d96039a 100644
--- a/poem.txt
+++ b/poem.txt
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
| `>` | go to the next file, with `--no-auto-advance` |
| `<` | go to the previous file, with `--no-auto-advance` |
| `p` | print the current hunk again |
| `P` | print the current hunk through the pager |
| `?` | print help |

`s` and `e` are the two that matter beyond `y` and `n`. `s` splits a hunk when
Git grouped two unrelated changes together because they were close. `e` opens
the hunk in your editor so you can stage individual lines, which is the last
resort when `s` cannot split far enough.

The prompt only offers the keys that can do something right now. The last hunk
has no `k` or `j`, because there is nothing after it that is undecided, and `s`
appears only for a hunk that can be split. `?` lists the keys on offer:

```console
$ printf '?\nq\n' | git add -p poem.txt
diff --git a/poem.txt b/poem.txt
index e031777..dcd2927 100644
--- a/poem.txt
+++ b/poem.txt
@@ -1,6 +1,6 @@
-one
+ONE
 two
-three
+THREE
 four
 five
 six
(1/2) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,s,e,p,P,?]? y - stage this hunk
n - do not stage this hunk
q - quit; do not stage this hunk or any of the remaining ones
a - stage this hunk and all later hunks in the file
d - do not stage this hunk or any of the later hunks in the file
j - go to the next undecided hunk, roll over at the bottom
J - go to the next hunk, roll over at the bottom
k - go to the previous undecided hunk, roll over at the top
K - go to the previous hunk, roll over at the top
g - select a hunk to go to
/ - search for a hunk matching the given regex
s - split the current hunk into smaller hunks
e - manually edit the current hunk
p - print the current hunk
P - print the current hunk using the pager
? - print help
(1/2) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,s,e,p,P,?]? 
```

> **Since Git 2.45.** `p`. **Since Git 2.47.** `P`. **Since Git 2.54.** `>`
> and `<`.

### Splitting a hunk

This file has three changes. The first two are close enough that Git shows them
as one hunk:

```console
$ git diff poem.txt
diff --git a/poem.txt b/poem.txt
index e031777..dcd2927 100644
--- a/poem.txt
+++ b/poem.txt
@@ -1,6 +1,6 @@
-one
+ONE
 two
-three
+THREE
 four
 five
 six
@@ -9,4 +9,4 @@ eight
 nine
 ten
 eleven
-twelve
+TWELVE
$ printf 's\ny\nn\nn\n' | git add -p poem.txt
diff --git a/poem.txt b/poem.txt
index e031777..dcd2927 100644
--- a/poem.txt
+++ b/poem.txt
@@ -1,6 +1,6 @@
-one
+ONE
 two
-three
+THREE
 four
 five
 six
(1/2) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,s,e,p,P,?]? Split into 2 hunks.
@@ -1,2 +1,2 @@
-one
+ONE
 two
(1/3) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,e,p,P,?]? @@ -2,5 +2,5 @@
 two
-three
+THREE
 four
 five
 six
(2/3) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,e,p,P,?]? @@ -9,4 +9,4 @@ eight
 nine
 ten
 eleven
-twelve
+TWELVE
(3/3) Stage this hunk [y,n,q,a,d,K,J,g,/,e,p,P,?]? 
$ git diff --staged
diff --git a/poem.txt b/poem.txt
index e031777..1c58c6d 100644
--- a/poem.txt
+++ b/poem.txt
@@ -1,4 +1,4 @@
-one
+ONE
 two
 three
 four
```

`s` split the hunk at the unchanged line between the two changes, and the count
went from 2 to 3. `y`, `n`, `n` staged only `ONE`. A hunk with no unchanged
line inside it, such as two changed lines next to each other, cannot be split,
and `s` is not offered; that is the case for `e`.

### Editing a hunk

`e` writes the hunk to a file and opens your editor on it. Here the editor is
replaced by `cat`, which prints the file and changes nothing, so you can see
what the editor would show:

```console
$ printf 'e\nq\n' | GIT_EDITOR=cat git add -p poem.txt
diff --git a/poem.txt b/poem.txt
index e031777..dcd2927 100644
--- a/poem.txt
+++ b/poem.txt
@@ -1,6 +1,6 @@
-one
+ONE
 two
-three
+THREE
 four
 five
 six
(1/2) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,s,e,p,P,?]? # Manual hunk edit mode -- see bottom for a quick guide.
@@ -1,6 +1,6 @@
-one
+ONE
 two
-three
+THREE
 four
 five
 six
# ---
# To remove '-' lines, make them ' ' lines (context).
# To remove '+' lines, delete them.
# Lines starting with # will be removed.
# If the patch applies cleanly, the edited hunk will immediately be marked for staging.
# If it does not apply cleanly, you will be given an opportunity to
# edit again.  If all lines of the hunk are removed, then the edit is
# aborted and the hunk is left unchanged.
@@ -9,4 +9,4 @@ eight
 nine
 ten
 eleven
-twelve
+TWELVE
(2/2) Stage this hunk [y,n,q,a,d,K,J,g,/,e,p,P,?]? 
$ git diff --staged --stat
 poem.txt | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
```

`GIT_EDITOR` sets the editor for one command (Chapter 62). Saving the buffer
unchanged staged the whole hunk, as the guide at the bottom promises.

> **Careful.** In the editor that `e` opens, you delete lines you do not want
> to stage, but the rules differ by line type: remove a `+` line to leave it
> unstaged, and change a `-` line's leading character to a space to keep it.
> The editor buffer explains this at the bottom. Getting it wrong produces a
> hunk that will not apply, and Git then tells you and leaves the file alone.

Deleting a context line is the classic way to get it wrong:

```console
$ printf 'e\nn\nq\n' | GIT_EDITOR="sed -i '/^ two/d'" git add -p poem.txt
diff --git a/poem.txt b/poem.txt
index e031777..dcd2927 100644
--- a/poem.txt
+++ b/poem.txt
@@ -1,6 +1,6 @@
-one
+ONE
 two
-three
+THREE
 four
 five
 six
(1/2) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,s,e,p,P,?]? error: patch failed: poem.txt:1
error: poem.txt: patch does not apply
error: 'git apply --cached' failed
Your edited hunk does not apply. Edit again (saying "no" discards!) [y/n]? (1/2) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,s,e,p,P,?]? 
$ git diff --staged --stat
```

The editor here is `sed`, deleting the line ` two`. Answering `n` to "Edit
again" threw the edit away and returned to the same hunk, and nothing was
staged.

An edit can also stage content that is in neither the commit nor the working
tree. Changing `+ONE` to `+One` stages `One`, while the file still says `ONE`:

```console
$ printf 'e\nn\n' | GIT_EDITOR="sed -i 's/^+ONE/+One/'" git add -p poem.txt
diff --git a/poem.txt b/poem.txt
index e031777..dcd2927 100644
--- a/poem.txt
+++ b/poem.txt
@@ -1,6 +1,6 @@
-one
+ONE
 two
-three
+THREE
 four
 five
 six
(1/2) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,s,e,p,P,?]? @@ -9,4 +9,4 @@ eight
 nine
 ten
 eleven
-twelve
+TWELVE
(2/2) Stage this hunk [y,n,q,a,d,K,J,g,/,e,p,P,?]? 
$ git diff --staged
diff --git a/poem.txt b/poem.txt
index e031777..6c19cbe 100644
--- a/poem.txt
+++ b/poem.txt
@@ -1,6 +1,6 @@
-one
+One
 two
-three
+THREE
 four
 five
 six
$ git diff poem.txt
diff --git a/poem.txt b/poem.txt
index 6c19cbe..dcd2927 100644
--- a/poem.txt
+++ b/poem.txt
@@ -1,4 +1,4 @@
-One
+ONE
 two
 THREE
 four
@@ -9,4 +9,4 @@ eight
 nine
 ten
 eleven
-twelve
+TWELVE
```

Git's documentation warns about exactly this: the working tree now appears to
undo the change you staged. It is occasionally useful and usually a mistake.

### Jumping to a hunk

```console
$ printf 'g\n2\ny\nq\n' | git add -p poem.txt
diff --git a/poem.txt b/poem.txt
index e031777..dcd2927 100644
--- a/poem.txt
+++ b/poem.txt
@@ -1,6 +1,6 @@
-one
+ONE
 two
-three
+THREE
 four
 five
 six
(1/2) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,s,e,p,P,?]?   1:  -1,6 +1,6          -one
  2:  -9,4 +9,4          -twelve
go to which hunk? @@ -9,4 +9,4 @@ eight
 nine
 ten
 eleven
-twelve
+TWELVE
(2/2) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,e,p,P,?]? @@ -1,6 +1,6 @@
-one
+ONE
 two
-three
+THREE
 four
 five
 six
(1/2) Stage this hunk [y,n,q,a,d,K,J,g,/,s,e,p,P,?]? 
$ git diff --staged --stat
 poem.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git reset -q
$ printf '/TWELVE\ny\nq\n' | git add -p poem.txt
diff --git a/poem.txt b/poem.txt
index e031777..dcd2927 100644
--- a/poem.txt
+++ b/poem.txt
@@ -1,6 +1,6 @@
-one
+ONE
 two
-three
+THREE
 four
 five
 six
(1/2) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,s,e,p,P,?]? @@ -9,4 +9,4 @@ eight
 nine
 ten
 eleven
-twelve
+TWELVE
(2/2) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,e,p,P,?]? @@ -1,6 +1,6 @@
-one
+ONE
 two
-three
+THREE
 four
 five
 six
(1/2) Stage this hunk [y,n,q,a,d,K,J,g,/,s,e,p,P,?]? 
$ git diff --staged --stat
 poem.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

`g` lists the hunks by their line numbers and first changed line, and asks for a
number. `/` takes a regular expression and goes to the next hunk containing it.
After `y`, patch mode went back to the one hunk still undecided, and `q` left it
unstaged.

### More context, or less

```console
$ printf 'n\nn\nn\n' | git add -p -U0 poem.txt
diff --git a/poem.txt b/poem.txt
index e031777..dcd2927 100644
--- a/poem.txt
+++ b/poem.txt
@@ -1 +1 @@
-one
+ONE
(1/3) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,e,p,P,?]? @@ -3 +3 @@ two
-three
+THREE
(2/3) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,e,p,P,?]? @@ -12 +12 @@ eleven
-twelve
+TWELVE
(3/3) Stage this hunk [y,n,q,a,d,K,J,g,/,e,p,P,?]? 
$ printf 'n\n' | git add -p --inter-hunk-context=2 poem.txt
diff --git a/poem.txt b/poem.txt
index e031777..dcd2927 100644
--- a/poem.txt
+++ b/poem.txt
@@ -1,12 +1,12 @@
-one
+ONE
 two
-three
+THREE
 four
 five
 six
 seven
 eight
 nine
 ten
 eleven
-twelve
+TWELVE
(1/1) Stage this hunk [y,n,q,a,d,s,e,p,P,?]? 
$ printf 'n\nn\n' | git -c diff.context=1 add -p poem.txt
diff --git a/poem.txt b/poem.txt
index e031777..dcd2927 100644
--- a/poem.txt
+++ b/poem.txt
@@ -1,4 +1,4 @@
-one
+ONE
 two
-three
+THREE
 four
(1/2) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,s,e,p,P,?]? @@ -11,2 +11,2 @@ ten
 eleven
-twelve
+TWELVE
(2/2) Stage this hunk [y,n,q,a,d,K,J,g,/,e,p,P,?]? 
```

With no context lines, `-U0`, every change is its own hunk and there is nothing
to split. `--inter-hunk-context=2` joined the two hunks into one, because only
two unchanged lines separated them. `diff.context` sets the default number of
context lines, here 1. These work as they do in `git diff`, where Chapter 13
covers them in full.

> **Since Git 2.51.** `-U`, `--inter-hunk-context`, and `diff.context` in patch
> mode.

### Several files

Without a path, patch mode goes through every changed file in turn:

```console
$ printf 'n\ny\nn\n' | git add -p
diff --git a/other.txt b/other.txt
index fbbee86..cd964df 100644
--- a/other.txt
+++ b/other.txt
@@ -1,2 +1,2 @@
 alpha
-beta
+BETA
(1/1) Stage this hunk [y,n,q,a,d,e,p,P,?]? 
diff --git a/poem.txt b/poem.txt
index e031777..dcd2927 100644
--- a/poem.txt
+++ b/poem.txt
@@ -1,6 +1,6 @@
-one
+ONE
 two
-three
+THREE
 four
 five
 six
(1/2) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,s,e,p,P,?]? @@ -9,4 +9,4 @@ eight
 nine
 ten
 eleven
-twelve
+TWELVE
(2/2) Stage this hunk [y,n,q,a,d,K,J,g,/,e,p,P,?]? 
$ git status --short
 M other.txt
MM poem.txt
```

As soon as every hunk in `other.txt` had an answer, it moved on to `poem.txt`,
and there was no way back to change the answer. `--no-auto-advance` stays in a
file until you leave it with `>` or `<`:

```console
$ printf 'y\n>\nq\n' | git add -p --no-auto-advance
diff --git a/other.txt b/other.txt
index fbbee86..cd964df 100644
--- a/other.txt
+++ b/other.txt
@@ -1,2 +1,2 @@
 alpha
-beta
+BETA
(1/1) Stage this hunk [y,n,q,a,d,e,>,<,p,P,?]? (1/1) Stage this hunk (was: y) [y,n,q,a,d,e,>,<,p,P,?]? 
diff --git a/poem.txt b/poem.txt
index e031777..dcd2927 100644
--- a/poem.txt
+++ b/poem.txt
@@ -1,6 +1,6 @@
-one
+ONE
 two
-three
+THREE
 four
 five
 six
(1/2) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,s,e,>,<,p,P,?]? 
$ git status --short
M  other.txt
 M poem.txt
$ git reset -q
$ git add --no-auto-advance poem.txt
fatal: the option '--no-auto-advance' requires '--interactive/--patch'
```

After `y` the same hunk was offered again, marked `(was: y)`, so the answer can
still be changed. `>` went to the next file, and `q` quit there. What had been
answered was still staged.

Git's documentation does not describe this option yet; the behaviour above is
what Git 2.55 does, and its source shows one more difference: without auto
advance, nothing is written to the index until you leave patch mode, while with
it each file is staged as you move past it.

> **Since Git 2.54.** `--auto-advance` and `--no-auto-advance`.

### Editing the whole diff at once

`-e` skips the questions and opens the entire diff of the paths given in your
editor. The editing rules are the same as for `e`. Here `sed` stands in for the
editor, and turns the removal of `twelve` into context and deletes the line
adding `TWELVE`:

```console
$ GIT_EDITOR="sed -i 's/^-twelve/ twelve/; /^+TWELVE/d'" git add -e poem.txt
$ git diff --staged
diff --git a/poem.txt b/poem.txt
index e031777..55df916 100644
--- a/poem.txt
+++ b/poem.txt
@@ -1,6 +1,6 @@
-one
+ONE
 two
-three
+THREE
 four
 five
 six
```

Everything else was staged. Git's documentation adds that deleting every line
of the patch stages nothing.

### When there is nothing to stage

```console
$ git stash -q && git add -p; git stash pop -q
No changes.
```

With the changes put aside in the stash (Chapter 55), there was nothing to show.
The same message appears for a path that has no changes.

## Interactive mode

`git add -i` is an older menu-driven interface that includes patch mode plus
other options. `-p` is the part almost everyone wants.

It starts with a status table and a menu, and reads commands by number or by
the letter in brackets:

```console
$ printf 's\nq\n' | git add -i
           staged     unstaged path
  1:    unchanged        +1/-1 other.txt
  2:    unchanged        +3/-3 poem.txt

*** Commands ***
  1: [s]tatus	  2: [u]pdate	  3: [r]evert	  4: [a]dd untracked
  5: [p]atch	  6: [d]iff	  7: [q]uit	  8: [h]elp
What now>            staged     unstaged path
  1:    unchanged        +1/-1 other.txt
  2:    unchanged        +3/-3 poem.txt

*** Commands ***
  1: [s]tatus	  2: [u]pdate	  3: [r]evert	  4: [a]dd untracked
  5: [p]atch	  6: [d]iff	  7: [q]uit	  8: [h]elp
What now> Bye.
```

The columns are lines added and removed: nothing staged yet, and unstaged
changes of one line in `other.txt` and three in `poem.txt`. `update` stages
whole files, chosen by number, and an empty line ends the choosing:

```console
$ printf 'u\n1\n\nq\n' | git add -i
           staged     unstaged path
  1:    unchanged        +1/-1 other.txt
  2:    unchanged        +3/-3 poem.txt

*** Commands ***
  1: [s]tatus	  2: [u]pdate	  3: [r]evert	  4: [a]dd untracked
  5: [p]atch	  6: [d]iff	  7: [q]uit	  8: [h]elp
What now>            staged     unstaged path
  1:    unchanged        +1/-1 [o]ther.txt
  2:    unchanged        +3/-3 [p]oem.txt
Update>>            staged     unstaged path
* 1:    unchanged        +1/-1 [o]ther.txt
  2:    unchanged        +3/-3 [p]oem.txt
Update>> updated 1 path

*** Commands ***
  1: [s]tatus	  2: [u]pdate	  3: [r]evert	  4: [a]dd untracked
  5: [p]atch	  6: [d]iff	  7: [q]uit	  8: [h]elp
What now> Bye.
$ git status --short
M  other.txt
 M poem.txt
?? new.txt
$ git reset -q
$ printf 'a\n1\n\nq\n' | git add -i
           staged     unstaged path
  1:    unchanged        +1/-1 other.txt
  2:    unchanged        +3/-3 poem.txt

*** Commands ***
  1: [s]tatus	  2: [u]pdate	  3: [r]evert	  4: [a]dd untracked
  5: [p]atch	  6: [d]iff	  7: [q]uit	  8: [h]elp
What now>            staged     unstaged path
  1: [n]ew.txt
Add untracked>>            staged     unstaged path
* 1: [n]ew.txt
Add untracked>> added 1 path

*** Commands ***
  1: [s]tatus	  2: [u]pdate	  3: [r]evert	  4: [a]dd untracked
  5: [p]atch	  6: [d]iff	  7: [q]uit	  8: [h]elp
What now> Bye.
$ git status --short
A  new.txt
 M other.txt
 M poem.txt
```

A `>>` prompt takes several choices at once. Git's documentation gives the
forms: numbers separated by spaces or commas, ranges such as `2-5`, `7-` for
everything from 7 on, `*` for all, and a leading `-` to unselect.

| Command | Does |
|---|---|
| `status` | Show the table again |
| `update` | Stage whole files |
| `revert` | Unstage whole files, back to `HEAD`; a new file becomes untracked again |
| `add untracked` | Start tracking new files |
| `patch` | Choose a file, then its hunks, as `git add -p` does |
| `diff` | Show what is staged, against `HEAD` |
| `quit` | Leave |
| `help` | Describe the commands |

`interactive.singleKey` makes patch mode act on a single key press, without
Enter. Git's documentation lists patch mode as the only place it is used, in
`git add` and in the other commands that have one.

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

Refusing happens only when you name the ignored file. A directory or a pattern
simply passes over it, as Git's documentation says:

```console
$ git add . && git status --short --ignored
A  notes.txt
!! debug.log
!! logs/
$ git reset -q
$ git add debug.log notes.txt; echo "exit $?"
The following paths are ignored by one of your .gitignore files:
debug.log
hint: Use -f if you really want to add them.
hint: Disable this message with "git config set advice.addIgnoredFile false"
exit 1
$ git status --short
A  notes.txt
$ git reset -q
$ git add 'logs/*'
fatal: pathspec 'logs/*' did not match any files
```

With an ignored name among others, the other files were added and the command
still failed, with exit code 1. A pattern that matches only ignored files is
reported as matching nothing at all, which is confusing when `logs/app.log` is
plainly there.

A dry run reports ignored files the same way, and `--ignore-missing` lets it
check a path that does not exist yet:

```console
$ git add -n debug.log
The following paths are ignored by one of your .gitignore files:
debug.log
hint: Use -f if you really want to add them.
hint: Disable this message with "git config set advice.addIgnoredFile false"
$ git add -n missing.log
fatal: pathspec 'missing.log' did not match any files
$ git add -n --ignore-missing missing.log
The following paths are ignored by one of your .gitignore files:
missing.log
hint: Use -f if you really want to add them.
hint: Disable this message with "git config set advice.addIgnoredFile false"
$ git add -n --ignore-missing missing.txt
$ git add --ignore-missing missing.log
fatal: the option '--ignore-missing' requires '--dry-run'
```

`missing.txt` would not be ignored, so there was nothing to say. To ask which
rule ignores a file, `git check-ignore -v` is the better tool (Chapter 16).

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
its content is still entirely unstaged. Three reasons to want that:

| Reason | Why it helps |
|---|---|
| You want `git diff` to show a new file | Otherwise new files are invisible to `diff`, which only looks at tracked paths |
| You want `git add -p` on a new file | Patch mode needs an index entry to diff against |
| You want `git commit -a` to include a new file | `-a` stages changes to tracked files only, and the path now counts as tracked |

What a commit does with it:

```console
$ git add -N draft.txt
$ git commit -m 'Try to commit the draft'
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	new file:   draft.txt

no changes added to commit (use "git add" and/or "git commit -a")
$ git add other.txt && git commit -q -m 'Add other' && git show --stat --oneline HEAD
ba64f5c Add other
 other.txt | 1 +
 1 file changed, 1 insertion(+)
$ git status --short
 A draft.txt
$ git commit -q -a -m 'Add the draft' && git show --stat --oneline HEAD
272e72d Add the draft
 draft.txt | 2 ++
 1 file changed, 2 insertions(+)
```

A commit with only the intent to add has nothing to commit and refuses. A commit
of something else leaves the path out entirely, neither empty nor full, and it
is still ` A` afterwards. `git commit -a` stages the real content and commits
it.

> **Careful.** The ` A` in the status output, with the letter on the right, is
> Git telling you the content is not staged. Until you add the file properly, or
> commit with `-a`, no commit contains it.

In patch mode the whole file is one hunk, offered as an addition:

```console
$ git add -N late.txt && printf 'y\n' | git add -p late.txt
diff --git a/late.txt b/late.txt
new file mode 100644
index 0000000..422c2b7
--- /dev/null
+++ b/late.txt
@@ -0,0 +1,2 @@
+a
+b
(1/1) Stage addition [y,n,q,a,d,e,p,P,?]? 
$ git status --short
A  late.txt
$ git add -N not-created-yet.txt
fatal: pathspec 'not-created-yet.txt' did not match any files
```

Despite the name, the file has to exist; `-N` records a file you have, not one
you plan to write.

## Setting the executable bit

```console
$ git add --chmod=+x script.sh && git ls-files --stage script.sh
100755 4163036efa65bd4a469e752267498f01ea36a55c 0	script.sh
```

Mode `100755` rather than `100644`, without touching the file on disk. This is
how you make a script executable in the repository from Windows, where the
filesystem has no executable bit to set. `--chmod=-x` goes the other way:

```console
$ git add --chmod=-x script.sh && git ls-files --stage script.sh && git status --short
100644 4163036efa65bd4a469e752267498f01ea36a55c 0	script.sh
M  script.sh
$ git add --chmod=x script.sh
fatal: --chmod param 'x' must be either -x or +x
```

The blob hash did not change, only the mode, and status reports that as a
modification to commit.

## Line endings

This file was committed with Windows line endings, CRLF, and then a
`.gitattributes` was added saying text files should be stored with LF:

```console
$ git ls-files --eol crlf.txt
i/crlf  w/crlf  attr/                 	crlf.txt
$ git status --short
?? .gitattributes
$ git add --renormalize . && git status --short
M  crlf.txt
?? .gitattributes
$ git ls-files --eol crlf.txt
i/lf    w/crlf  attr/text=auto        	crlf.txt
```

`i/` is the index, `w/` the working tree. The new rule did not make `crlf.txt`
look modified: the file's size and modification time still matched what the
index recorded, so Git did not read it again ([Refreshing the index](#refreshing-the-index)
shows that record at work). `--renormalize` re-staged every tracked file through
the current rules, and the index copy became LF while the file on disk kept
CRLF.

> **Worth knowing.** `--renormalize` is the fix for the day your whole
> repository shows as modified after a line-ending configuration change. It
> re-stages every tracked file through the current rules without touching your
> working tree. Chapter 66 uses it as the main remedy.

Git's documentation adds two details: `--renormalize` implies `-u`, so it never
adds untracked files, and a lone carriage return is left as it is.

## Refreshing the index

The index remembers each file's size and modification time, so Git can skip
reading files that have not changed. Here `script.sh` was only touched, its
modification time changed and its content not:

```console
$ git diff-files --name-only
script.sh
$ git add --refresh script.sh && git diff-files --name-only
```

`git diff-files` is a plumbing command (Chapter 75) that trusts those saved
times, so it listed the file. `git add --refresh` read the file, saw the content
was the same, and saved the new time. Nothing was staged. Porcelain commands
such as `git status` do this refresh for themselves.

## When a file cannot be added

Normally one failure stops the whole command, and nothing is added:

```console
$ git add inner good.txt; echo "exit $?"
error: 'inner/' does not have a commit checked out
error: unable to index file 'inner/'
fatal: adding files failed
exit 128
$ git status --short
?? good.txt
?? inner/
$ git add --ignore-errors inner good.txt; echo "exit $?"
error: 'inner/' does not have a commit checked out
error: unable to index file 'inner/'
exit 1
$ git status --short
A  good.txt
?? inner/
$ git reset -q
$ git -c add.ignoreErrors=true add inner good.txt; echo "exit $?"
error: 'inner/' does not have a commit checked out
error: unable to index file 'inner/'
exit 1
```

`inner` is a repository with no commit, which cannot be added (Chapter 9 shows
why). With `--ignore-errors` Git reported it, added `good.txt` anyway, and still
exited with a failure code. `add.ignoreErrors` makes that the default.

## Embedded repositories

Once `inner` has a commit, it can be added as a pointer to that commit, and Git
normally warns at length, as Chapter 9 shows. `--no-warn-embedded-repo` adds it
silently:

```console
$ git add --no-warn-embedded-repo inner && git status --short
A  inner
?? good.txt
```

Git's documentation suggests it for when you are managing submodules by hand
(Chapter 57). For anyone else, the warning is the useful part.

## Sparse checkouts

A sparse checkout writes only some directories to the working tree (Chapter 60).
Here only `a/` is checked out, and a file under `b/` was created by hand anyway:

```console
$ git sparse-checkout set a
$ git add b/2.txt
The following paths and/or pathspecs matched paths that exist
outside of your sparse-checkout definition, so will not be
updated in the index:
b/2.txt
hint: If you intend to update such entries, try one of the following:
hint: * Use the --sparse option.
hint: * Disable or modify the sparsity rules.
hint: Disable this message with "git config set advice.updateSparsePath false"
$ git add --sparse b/2.txt && git status --short
M  b/2.txt
```

Git refuses because, as its documentation puts it, such files might be removed
from the working tree without warning. `--sparse` stages it anyway.

> **Since Git 2.34.** `git add --sparse`.

## The errors

```console
$ git add nothing-here
fatal: pathspec 'nothing-here' did not match any files
$ git add ''
fatal: empty string is not a valid pathspec. please use . instead if you meant to match all paths
$ git -C adding add ../outside
fatal: ../outside: '../outside' is outside repository at '/home/ada/adding'
```

| Message | Cause |
|---|---|
| `pathspec ... did not match any files` | Typo, wrong directory, a glob your shell expanded to nothing, or a pattern that matches only ignored files |
| `empty string is not a valid pathspec` | A shell variable expanded to nothing. `git add "$file"` with `$file` unset |
| `is outside repository` | You are pointing above the repository root |
| `The following paths are ignored` | An ignore rule matched; use `-f` if you mean it |
| `Nothing specified, nothing added.` | No path given; you probably meant `git add .` |
| `unknown switch` | A file name starting with `-`; put `--` before it |

That second one is worth recognising, because in a script it means a variable
you expected to be set was empty, and the error is about the symptom rather
than the cause.

## Undoing an add

```console
$ git restore --staged new.txt && git status --short
?? new.txt
```

`git restore --staged` puts the index entry back as it is in the last commit,
which for a new file means removing it. The file on disk is not touched.
Chapter 14 covers `restore` in full.

Before the first commit there is no last commit to restore from:

```console
$ git add first.txt
$ git restore --staged first.txt
fatal: could not resolve 'HEAD'
$ git rm --cached -q first.txt && git status --short
?? first.txt
```

`git rm --cached` removes the entry from the index and also leaves the file on
disk (Chapter 15).

## add and its neighbours

```console
$ git stage a.txt && git status --short
M  a.txt
?? new.txt
$ git reset -q
$ git commit -q -a -m 'Commit every tracked change' && git status --short
?? new.txt
$ git update-index --add new.txt && git status --short
A  new.txt
```

`git stage` is another name for `git add`. `git commit -a` stages changes to
tracked files, like `git add -u`, and commits them in one step, but a new file
stays untracked. `git update-index --add` is a plumbing command that edits
the index directly (Chapter 75).

| Command | Stages | Also |
|---|---|---|
| `git add <path>` | the current content of `<path>`, new files included | nothing else |
| `git stage <path>` | the same | Git's documentation calls it a synonym |
| `git add -u` | changes to tracked files | nothing else |
| `git commit -a` | changes to tracked files | makes the commit (Chapter 12) |
| `git commit <path>` | the current content of `<path>`, if already tracked | commits only those paths (Chapter 12) |
| `git rm <path>` | the deletion of `<path>` | deletes the file (Chapter 15) |
| `git mv <old> <new>` | a rename | renames the file (Chapter 15) |
| `git update-index --add <path>` | the current content of `<path>` | plumbing (Chapter 75) |
| `git restore --staged <path>` | undoes staging | (Chapter 14) |

## The settings

| Setting | Effect |
|---|---|
| `add.ignoreErrors` | Make `--ignore-errors` the default |
| `interactive.singleKey` | In patch mode, act on a key press without waiting for Enter |
| `interactive.diffFilter` | A command to pass the coloured diff through in patch mode |
| `diff.context` | Lines of context in patch mode, as in `git diff`. Since Git 2.51 |
| `diff.interHunkContext` | Default for `--inter-hunk-context`, as in `git diff`. Since Git 2.51 in patch mode |
| `color.interactive` | Colour in `-i` and `-p`: `always`, `auto` or `never` |
| `color.interactive.<slot>` | The colour of `prompt`, `header`, `help` or `error` |
| `advice.addIgnoredFile` | `false` removes the hint when an ignored file is refused |
| `advice.addEmptyPathspec` | `false` removes the hint after a bare `git add` |
| `advice.addEmbeddedRepo` | `false` removes the warning about a repository inside the repository |
| `advice.updateSparsePath` | `false` removes the hint about paths outside a sparse checkout |
| `core.fileMode` | Whether Git notices executable-bit changes on disk; `false` on Windows (Chapter 63) |
