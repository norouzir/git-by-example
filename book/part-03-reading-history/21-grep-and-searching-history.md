# Chapter 21. grep and Searching History

## What it is

`git grep <pattern>` prints every line that matches a pattern in the files Git
tracks, with the file's name in front. It is `grep -r` that knows about the
repository: it skips files Git does not track, never looks inside `.git`, and can
search the index or any old commit as easily as the working tree.

Searching *history* is a different question with different tools. `git grep`
searches one snapshot at a time: "where is this text in that version?".
`git log -S` searches the changes: "which commits added or removed this text?".
The last part of this chapter, [Searching history](#searching-history), puts
them together with the other searches from Chapters 17 and 18 to find code that
is gone.

A *pattern* is a regular expression unless you say otherwise: `.` matches any
character, `*` repeats what comes before it, `^` and `$` stand for the start and
end of a line. Chapter 17 compares the kinds of regular expression Git accepts.

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What does `git grep` search, and how is it different from `grep -r`?](#what-it-is)

**[Synopsis](#synopsis)**

- [What can I type after `git grep`?](#synopsis)

**[Options at a glance](#options-at-a-glance)**

- [Is there a list of every option, and where each is explained?](#options-at-a-glance)

**[The example](#the-example)**

- [What files do the examples search?](#the-example)

**[Reading the output](#reading-the-output)**

- [What does each line of `git grep` output mean?](#reading-the-output)
- [Why did `git grep` not find text in my new file?](#reading-the-output)
- [Why are the paths different when I run it in a subdirectory?](#reading-the-output)

**[Matching](#matching)**

- [How do I search without regard to case, or for whole words only?](#matching)
- [How do I search for text containing `.` or `(` without it being a pattern?](#matching)
- [My pattern starts with `-` and Git says "unknown option". How do I search for it?](#matching)
- [Can I keep a list of patterns in a file?](#matching)

**[Combining patterns](#combining-patterns)**

- [How do I find lines that contain two words, or one but not the other?](#combining-patterns)
- [How do I find files that contain both words, not necessarily on one line?](#combining-patterns)

**[What is printed](#what-is-printed)**

- [How do I show line numbers, or only the matching part?](#what-is-printed)
- [How do I list only the names of files that match, or that do not?](#what-is-printed)
- [How do I count matches in each file?](#what-is-printed)
- [How do I test in a script whether something matches?](#what-is-printed)

**[Context around a match](#context-around-a-match)**

- [How do I see the lines around each match?](#context-around-a-match)
- [How do I see which function a match is in, or the whole function?](#context-around-a-match)

**[Which files are searched](#which-files-are-searched)**

- [How do I search only some files or directories, or leave some out?](#which-files-are-searched)
- [How do I stop the search going into subdirectories?](#which-files-are-searched)
- [What does "Binary file matches" mean, and how do I avoid it?](#which-files-are-searched)

**[Where to search: tree, index or history](#where-to-search-tree-index-or-history)**

- [How do I search the staged version of files?](#where-to-search-tree-index-or-history)
- [How do I search an old version, a tag or another branch without checking it out?](#where-to-search-tree-index-or-history)
- [Can I give `git grep` a range such as `v1.0..HEAD`?](#where-to-search-tree-index-or-history)
- [How do I include untracked or ignored files?](#where-to-search-tree-index-or-history)
- [Can I use `git grep` outside a repository?](#where-to-search-tree-index-or-history)

**[Colour](#colour)**

- [Why is my `git grep` output in colour, and how do I turn it off or force it?](#colour)

**[Searching history](#searching-history)**

- [A function existed once and is gone now. How do I find it?](#searching-history)
- [How do I search every commit in the repository for some text?](#searching-history)
- [When was a line of code removed, and by which commit?](#searching-history)
- [How do I find a change that is on another branch?](#searching-history)
- [How do I find a file that was deleted?](#searching-history)

**[grep and its neighbours](#grep-and-its-neighbours)**

- [Should I use `git grep`, `grep -r`, `git log -S` or `git blame`?](#grep-and-its-neighbours)

**[The settings](#the-settings)**

- [Which settings change what `git grep` does by default?](#the-settings)

</details>

## Synopsis

```
git grep [<options>] [-e] <pattern> [<tree>...] [[--] <pathspec>...]
```

| Part | Means |
|---|---|
| `<pattern>` | What to look for; a basic regular expression by default |
| `-e` | The next argument is a pattern, even if it starts with `-` |
| `<tree>` | Search this commit, tag or tree instead of the working tree |
| `<pathspec>` | Search only these paths (Chapter 11) |
| `--` | Everything after it is a path |

| Command | Searches |
|---|---|
| `git grep <pattern>` | tracked files, as they are in the working tree |
| `git grep --cached <pattern>` | the staged versions of tracked files |
| `git grep <pattern> <commit>` | the files in that commit |
| `git grep --untracked <pattern>` | tracked and untracked files, not ignored ones |
| `git grep --no-index <pattern>` | every file under the current directory, as `grep -r` would |

Git's documentation also lists `--parent-basename <basename>` in the synopsis,
but the installed `git grep` rejects it as an unknown option and does not list it
under `-h`.

## Options at a glance

### What matches

| Option | Does | Covered in |
|---|---|---|
| `-i`, `--ignore-case` | Ignore case | [Matching](#matching) |
| `-w`, `--word-regexp` | Match only whole words | [Matching](#matching) |
| `-v`, `--invert-match` | Show lines that do not match | [Matching](#matching) |
| `-G`, `--basic-regexp` | Patterns are basic regular expressions, the default | [Matching](#matching) |
| `-E`, `--extended-regexp` | Extended regular expressions | [Matching](#matching) |
| `-F`, `--fixed-strings` | Plain text | [Matching](#matching) |
| `-P`, `--perl-regexp` | Perl-compatible regular expressions | [Matching](#matching) |
| `-e <pattern>` | The next argument is a pattern | [Matching](#matching) |
| `-f <file>` | Read patterns from a file, one per line | [Matching](#matching) |
| `--and`, `--or`, `--not`, `(`, `)` | Combine patterns given with `-e` | [Combining patterns](#combining-patterns) |
| `--all-match` | Only files matching every pattern | [Combining patterns](#combining-patterns) |

### Output

| Option | Does | Covered in |
|---|---|---|
| `-n`, `--line-number` | Show line numbers | [What is printed](#what-is-printed) |
| `--column` | Show where on the line the match starts | [What is printed](#what-is-printed) |
| `-o`, `--only-matching` | Show only the matching part | [What is printed](#what-is-printed) |
| `-c`, `--count` | Show how many lines match in each file | [What is printed](#what-is-printed) |
| `-l`, `--files-with-matches`, `--name-only` | Show only names of files that match | [What is printed](#what-is-printed) |
| `-L`, `--files-without-match` | Show only names of files that do not | [What is printed](#what-is-printed) |
| `-h`, `-H` | Hide file names, or show them again | [What is printed](#what-is-printed) |
| `--full-name` | Paths from the top of the repository | [Reading the output](#reading-the-output) |
| `-z`, `--null` | End file names with a NUL byte | [What is printed](#what-is-printed) |
| `-m <num>`, `--max-count <num>` | Stop after `<num>` matches in each file | [What is printed](#what-is-printed) |
| `-q`, `--quiet` | Print nothing; answer with the exit code | [What is printed](#what-is-printed) |
| `-O[<pager>]`, `--open-files-in-pager[=<pager>]` | Open the matching files instead | [What is printed](#what-is-printed) |
| `-A <num>`, `--after-context <num>` | Lines after each match | [Context around a match](#context-around-a-match) |
| `-B <num>`, `--before-context <num>` | Lines before each match | [Context around a match](#context-around-a-match) |
| `-C <num>`, `--context <num>`, `-<num>` | Lines before and after | [Context around a match](#context-around-a-match) |
| `--break` | A blank line between files | [Context around a match](#context-around-a-match) |
| `--heading` | The file name once, above its matches | [Context around a match](#context-around-a-match) |
| `-p`, `--show-function` | The function each match is in | [Context around a match](#context-around-a-match) |
| `-W`, `--function-context` | The whole function each match is in | [Context around a match](#context-around-a-match) |
| `--color[=<when>]`, `--no-color` | Highlight matches, or not | [Colour](#colour) |

### What is searched

| Option | Does | Covered in |
|---|---|---|
| `--cached` | The index instead of the working tree | [Where to search: tree, index or history](#where-to-search-tree-index-or-history) |
| `--untracked` | Untracked files as well | [Where to search: tree, index or history](#where-to-search-tree-index-or-history) |
| `--no-exclude-standard` | With `--untracked`, ignored files as well | [Where to search: tree, index or history](#where-to-search-tree-index-or-history) |
| `--no-index` | Files on disk, repository or not | [Where to search: tree, index or history](#where-to-search-tree-index-or-history) |
| `--exclude-standard` | With `--no-index`, leave ignored files out | [Where to search: tree, index or history](#where-to-search-tree-index-or-history) |
| `--index` | The opposite of `--no-index`, the default | [Where to search: tree, index or history](#where-to-search-tree-index-or-history) |
| `--max-depth <depth>` | Go at most this many directories down | [Which files are searched](#which-files-are-searched) |
| `-r`, `--recursive`, `--no-recursive` | Go into subdirectories, the default, or not | [Which files are searched](#which-files-are-searched) |
| `-a`, `--text` | Search binary files as text | [Which files are searched](#which-files-are-searched) |
| `-I` | Leave binary files out | [Which files are searched](#which-files-are-searched) |
| `--textconv`, `--no-textconv` | Search a file's converted text, or not, the default | [Which files are searched](#which-files-are-searched) |
| `--recurse-submodules` | Search inside submodules too | Chapter 57 |
| `--threads <num>` | Use this many threads | [The settings](#the-settings) |
| `--ext-grep` | Accepted and ignored | [The settings](#the-settings) |

<!-- no-example: --threads
     only changes speed; tested with --threads 1 on this repository and the
     output was identical to the default -->
<!-- no-example: --ext-grep
     git grep -h describes it as ignored by this build; tested and the output
     was identical to the command without it -->
<!-- no-example: --index
     the default; it only cancels an earlier --no-index, which the row says -->

## The example

A library catalogue: Python code in `src/`, notes in `docs/`, a small binary file
`logo.png`, and a branch `fines` not yet merged. Two files are not tracked:
`notes.txt`, and `build/cache.txt`, which `.gitignore` ignores. Every example
searches for words such as `lend`, `book` and `LOAN_DAYS`.

## Reading the output

```console
$ git grep lend
docs/guide/lending.md:Use lend() to lend a book.
Binary file logo.png matches
src/books.py:def lend(book, member):
$ git grep nosuch; echo "exit $?"
exit 1
$ grep -rI lend . | sort
./build/cache.txt:lend cache
./docs/guide/lending.md:Use lend() to lend a book.
./notes.txt:Ask about lend limits.
./src/books.py:def lend(book, member):
```

Each line is `<file>:<line>`, sorted by file. For a binary file Git reports that
it matches without printing the bytes. Nothing matched `nosuch`, so nothing was
printed and the exit code was 1; `echo "exit $?"` shows it.

`grep -r` is the same idea outside Git. `-I` made it skip binary files and
`sort` put its results in order, since it lists files in whatever order the disk
returns them. It found the untracked `notes.txt` and the ignored
`build/cache.txt`, which `git grep` did not search, because they are not tracked.

```console
$ cd src
$ git grep lend
books.py:def lend(book, member):
$ git grep --full-name lend
src/books.py:def lend(book, member):
$ git grep lend -- ../docs
../docs/guide/lending.md:Use lend() to lend a book.
$ cd ..
```

In a subdirectory, `git grep` searches only that directory and prints paths
relative to it. `--full-name` prints them from the top of the repository, and a
path such as `../docs` searches elsewhere.

## Matching

```console
$ git grep -i todo
src/books.py:    # TODO: check the member's limit
src/members.py:    # todo: search by card number too
$ git grep todo
src/members.py:    # todo: search by card number too
$ git grep -c book
docs/README.md:1
docs/guide/lending.md:1
src/books.py:6
$ git grep -c -w book
docs/guide/lending.md:1
src/books.py:6
$ git grep -v -e '^$' -e '^ ' -- src/members.py
src/members.py:class Member:
src/members.py:def find_member(name):
```

Case matters unless `-i` is given. `-w` accepts only whole words: the README's
match was inside `books`. `-c` counts matching lines per file, and is covered
below. `-v` prints the lines that do not match; here, lines that are neither
empty nor indented.

```console
$ git grep 'book\.due = .*DAYS'
src/books.py:    book.due = today() + LOAN_DAYS
$ git grep 'book.' -- docs
docs/README.md:Members may borrow books for 21 days.
docs/guide/lending.md:Use lend() to lend a book.
$ git grep -F 'book.' -- docs
docs/guide/lending.md:Use lend() to lend a book.
$ git grep -E 'borrower|loans'
src/books.py:    book.borrower = member
src/books.py:    book.borrower = None
src/members.py:        self.loans = []
$ git grep 'borrower\|loans'
src/books.py:    book.borrower = member
src/books.py:    book.borrower = None
src/members.py:        self.loans = []
$ git grep -G 'borrower|loans'
$ git grep -P 'due(?= =)'
src/books.py:    book.due = today() + LOAN_DAYS
src/books.py:    book.due = None
```

| Option | Pattern is |
|---|---|
| `-G`, `--basic-regexp` | a basic regular expression, the default |
| `-E`, `--extended-regexp` | an extended regular expression |
| `-F`, `--fixed-strings` | plain text: `.` is a dot |
| `-P`, `--perl-regexp` | a Perl-compatible regular expression, with extras such as `(?= )`, "followed by" |

"borrower or loans" is written `borrower\|loans` in a basic expression and
`borrower|loans` in an extended or Perl-compatible one; plain text has no way to
say it. `\.` is a literal dot in a regular expression; unescaped, `book.` matched `books`
too, while `-F` matched only the real `book.`. In a basic expression `|` is an
ordinary character, so `-G 'borrower|loans'` found nothing. These are the same
kinds `git log --grep` uses (Chapter 17). The `-P` pattern matched `due` only
where ` =` follows; Git's documentation notes that `-P` works only when Git was
built with support for it.

```console
$ git grep '-- is'
error: unknown option ` is'
usage: git grep [<options>] [-e] <pattern> [<rev>...] [[--] <path>...]
...
$ git grep -e '-- is'
docs/guide/lending.md:-- is not a valid loan period.
$ printf 'borrower\nloans\n' > ../patterns.txt
$ git grep -f ../patterns.txt
src/books.py:    book.borrower = member
src/books.py:    book.borrower = None
src/members.py:        self.loans = []
$ git grep ''  -- docs/README.md
docs/README.md:# Library
docs/README.md:
docs/README.md:Members may borrow books for 21 days.
docs/README.md:Loans cannot be renewed.
```

A pattern starting with `-` looks like an option, and Git printed its usage
(trimmed here). `-e` marks the next argument as a pattern; Git's documentation
recommends it in scripts that search for text a user typed. `-f` reads one
pattern per line from a file, and several patterns match any of them. An empty
pattern matches every line, as the documentation says.

## Combining patterns

```console
$ git grep -e book -e name -- src
src/books.py:def lend(book, member):
src/books.py:    book.borrower = member
src/books.py:    book.due = today() + LOAN_DAYS
src/books.py:def give_back(book):
src/books.py:    book.borrower = None
src/books.py:    book.due = None
src/members.py:    def __init__(self, name):
src/members.py:        self.name = name
src/members.py:def find_member(name):
src/members.py:    return MEMBERS[name]
$ git grep -e book --and -e due
src/books.py:    book.due = today() + LOAN_DAYS
src/books.py:    book.due = None
$ git grep -e book --and --not -e due -- src
src/books.py:def lend(book, member):
src/books.py:    book.borrower = member
src/books.py:def give_back(book):
src/books.py:    book.borrower = None
$ git grep -e def --and \( -e lend -e give \)
src/books.py:def lend(book, member):
src/books.py:def give_back(book):
$ git grep --and -e book
fatal: --and not preceded by pattern expression
```

| Written | Matches a line with |
|---|---|
| `-e A -e B` | `A` or `B` |
| `-e A --or -e B` | the same; `--or` is the default |
| `-e A --and -e B` | both |
| `-e A --and --not -e B` | `A` and not `B` |
| `-e A --and \( -e B -e C \)` | `A`, and `B` or `C` |

Git's documentation says `--and` binds more tightly than `--or`, and every pattern
must be given with `-e`. The brackets are escaped with `\` so that bash passes
them to Git instead of treating them itself.

```console
$ git grep --all-match -e borrower -e LOAN_DAYS
src/books.py:LOAN_DAYS = 21
src/books.py:    book.borrower = member
src/books.py:    book.due = today() + LOAN_DAYS
src/books.py:    book.borrower = None
$ git grep --all-match -e borrower -e name
```

`--all-match` works on files, not lines: it keeps the files in which every
pattern matches somewhere, and prints their lines that match any of them. No
single file has both `borrower` and `name`.

## What is printed

```console
$ git grep -n LOAN_DAYS
src/books.py:1:LOAN_DAYS = 21
src/books.py:6:    book.due = today() + LOAN_DAYS
$ git grep --column LOAN_DAYS
src/books.py:1:LOAN_DAYS = 21
src/books.py:26:    book.due = today() + LOAN_DAYS
$ git grep -o 'book\.[a-z]*'
docs/guide/lending.md:book.
src/books.py:book.borrower
src/books.py:book.due
src/books.py:book.borrower
src/books.py:book.due
$ git grep -c book
docs/README.md:1
docs/guide/lending.md:1
src/books.py:6
$ git grep -l book
docs/README.md
docs/guide/lending.md
src/books.py
$ git grep --name-only book
docs/README.md
docs/guide/lending.md
src/books.py
$ git grep -L book
.gitignore
logo.png
src/members.py
```

`-n` adds the line number and `--column` the column where the first match on the
line starts, counted in bytes from 1, as Git's documentation says. `-o` prints
only the matched text, one match per line. `-c` counts matching lines, `-l`
lists files that match, and `-L` files that do not. Git's documentation gives
`--name-only` as another name for `-l`, to match `git diff`.

```console
$ git grep -h book -- src/books.py
def lend(book, member):
    book.borrower = member
    book.due = today() + LOAN_DAYS
def give_back(book):
    book.borrower = None
    book.due = None
$ git grep -h -H book -- src/books.py
src/books.py:def lend(book, member):
src/books.py:    book.borrower = member
src/books.py:    book.due = today() + LOAN_DAYS
src/books.py:def give_back(book):
src/books.py:    book.borrower = None
src/books.py:    book.due = None
$ git grep -m 1 book
docs/README.md:Members may borrow books for 21 days.
docs/guide/lending.md:Use lend() to lend a book.
src/books.py:def lend(book, member):
$ git grep -m 0 book; echo "exit $?"
exit 1
$ git grep -q LOAN_DAYS; echo "exit $?"
exit 0
$ git grep -q nosuch; echo "exit $?"
exit 1
$ git grep -l -z book | cat -A; echo
docs/README.md^@docs/guide/lending.md^@src/books.py^@
$ git grep -Ocat -e 'renewed'
# Library

Members may borrow books for 21 days.
Loans cannot be renewed.
```

| Option | Does |
|---|---|
| `-h` | leaves out the file names; `-H` brings them back, as Git's documentation says it exists only for that |
| `-m <num>` | stops after `<num>` matches in each file; `-m 0` exits at once with 1 |
| `-q` | prints nothing; exit code 0 means a match was found, 1 none |
| `-z` | ends each file name with a NUL byte, shown by `cat -A` as `^@`, for names with spaces or newlines |
| `-O<pager>` | runs `<pager>` on the matching files, instead of printing lines |

`-q` is the one for scripts: `if git grep -q TODO; then ...`. `-O` opens the files
in your pager, `less` by default, and here `cat` printed the only file containing
`renewed`. Git's documentation says the program must be attached to `-O` with no
space, and that `less` or `vi` start at the first match. With `-z`, the names end
with NUL instead of a newline, so `echo` ended the line.

> **Since Git 2.38.** `-m`, `--max-count`.

## Context around a match

```console
$ git grep -A 1 borrower
src/books.py:    book.borrower = member
src/books.py-    book.due = today() + LOAN_DAYS
--
src/books.py:    book.borrower = None
src/books.py-    book.due = None
$ git grep -B 1 borrower
src/books.py-    # TODO: check the member's limit
src/books.py:    book.borrower = member
--
src/books.py-def give_back(book):
src/books.py:    book.borrower = None
$ git grep -C 1 LOAN_DAYS -- src
src/books.py:LOAN_DAYS = 21
src/books.py-
--
src/books.py-    book.borrower = member
src/books.py:    book.due = today() + LOAN_DAYS
src/books.py-
$ git grep -1 LOAN_DAYS -- src
src/books.py:LOAN_DAYS = 21
src/books.py-
--
src/books.py-    book.borrower = member
src/books.py:    book.due = today() + LOAN_DAYS
src/books.py-
$ git grep --break -n member
src/books.py:3:def lend(book, member):
src/books.py:4:    # TODO: check the member's limit
src/books.py:5:    book.borrower = member

src/members.py:6:def find_member(name):
$ git grep --heading -n member
src/books.py
3:def lend(book, member):
4:    # TODO: check the member's limit
5:    book.borrower = member
src/members.py
6:def find_member(name):
```

`-A` adds lines after each match, `-B` before, and `-C` or `-<num>` both. The
separator after the file name tells them apart: `:` for a matching line, `-` for
context, and a line of `--` between groups that are not next to each other.
`--break` puts a blank line between files and `--heading` prints each file's name
once above its lines.

```console
$ git grep -p TODO
src/books.py=def lend(book, member):
src/books.py:    # TODO: check the member's limit
$ git grep -W TODO
src/books.py=def lend(book, member):
src/books.py:    # TODO: check the member's limit
src/books.py-    book.borrower = member
src/books.py-    book.due = today() + LOAN_DAYS
$ git grep -n -p -i todo
src/books.py=3=def lend(book, member):
src/books.py:4:    # TODO: check the member's limit
src/members.py=6=def find_member(name):
src/members.py:7:    # todo: search by card number too
```

`-p` adds the line naming the function the match is in, marked with `=`. `-W`
prints the whole function, from that line up to the next function. Git finds
function lines the way `git diff` does for hunk headers (Chapter 13), and
Chapter 65 shows how to teach it a language's functions.

## Which files are searched

```console
$ git grep lend -- '*.md'
docs/guide/lending.md:Use lend() to lend a book.
$ git grep lend -- ':!docs'
Binary file logo.png matches
src/books.py:def lend(book, member):
$ git grep -e Lend -e lend -- docs
docs/guide/lending.md:Lending
docs/guide/lending.md:Use lend() to lend a book.
```

Paths after `--` limit the search, with every pathspec form from Chapter 11:
`'*.md'` matches in any directory, and `':!docs'` leaves `docs` out. Quote them so
that the shell leaves them to Git.

```console
$ git grep book -- docs
docs/README.md:Members may borrow books for 21 days.
docs/guide/lending.md:Use lend() to lend a book.
$ git grep --max-depth 0 book -- docs
docs/README.md:Members may borrow books for 21 days.
$ git grep --max-depth 1 book -- docs
docs/README.md:Members may borrow books for 21 days.
docs/guide/lending.md:Use lend() to lend a book.
$ git grep --no-recursive book -- docs
docs/README.md:Members may borrow books for 21 days.
$ git grep --no-recursive -r book -- docs
docs/README.md:Members may borrow books for 21 days.
docs/guide/lending.md:Use lend() to lend a book.
```

`--max-depth` counts directories below each path given: 0 stays in `docs`, 1 goes
one level further. `--no-recursive` is `--max-depth 0` and `-r` is no limit, the
default, as Git's documentation defines them, and the last one given wins. The
documentation adds that `--max-depth` is ignored for a path containing wildcards.

```console
$ git grep -I lend
docs/guide/lending.md:Use lend() to lend a book.
src/books.py:def lend(book, member):
$ git grep -a lend -- logo.png | cat -A
logo.png:PNG^@^@ lend lend$
$ cat .gitattributes
*.png diff=png
$ git -c diff.png.textconv='sed s/lend/LOAN/g' grep LOAN -- logo.png; echo "exit $?"
exit 1
$ git -c diff.png.textconv='sed s/lend/LOAN/g' grep --textconv LOAN -- logo.png | cat -A
logo.png:PNG^@^@ LOAN LOAN$
```

Git treats a file as binary when a NUL byte appears near its start, within the
first 8,000 bytes according to Git's source; `logo.png` has two. `-I` leaves such files out and
`-a` searches them as text, printing whatever bytes the line holds. A *textconv*
filter turns a binary file into text for display, and `--textconv` makes
`git grep` search that text instead; it is off by default, as the documentation
says, so `LOAN` was not found without it. Here the filter is a `sed` command
named in the attribute file (Chapter 65 sets these up properly).

## Where to search: tree, index or history

Here `src/books.py` has `LOAN_DAYS = 28` staged and `7` in the working tree; the
last commit has 21, and the tag `v1.0` has 14:

```console
$ git grep 'LOAN_DAYS ='
src/books.py:LOAN_DAYS = 7
$ git grep --cached 'LOAN_DAYS ='
src/books.py:LOAN_DAYS = 28
$ git grep 'LOAN_DAYS =' HEAD
HEAD:src/books.py:LOAN_DAYS = 21
$ git grep 'LOAN_DAYS =' v1.0
v1.0:src/books.py:LOAN_DAYS = 14
$ git grep 'LOAN_DAYS =' HEAD v1.0 fines
HEAD:src/books.py:LOAN_DAYS = 21
v1.0:src/books.py:LOAN_DAYS = 14
fines:src/books.py:LOAN_DAYS = 21
$ git grep 'LOAN_DAYS =' v1.0 -- src
v1.0:src/books.py:LOAN_DAYS = 14
$ git grep 'LOAN_DAYS =' v1.0:src
v1.0:src:books.py:LOAN_DAYS = 14
$ git grep 'LOAN_DAYS =' HEAD~2..HEAD
fatal: ambiguous argument 'HEAD~2..HEAD': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
```

| Searched | Command | Each line starts with |
|---|---|---|
| the working tree | `git grep <pattern>` | the path |
| the index | `git grep --cached <pattern>` | the path |
| a commit, tag or branch | `git grep <pattern> <commit>` | `<commit>:` and the path |
| a directory of a commit | `git grep <pattern> <commit>:<dir>` | `<commit>:<dir>:` and the path inside it |

Any name from Chapter 18 works, and several may be given. No checkout is needed:
the fines branch was searched from `main`. A range is not accepted, because
`git grep` searches snapshots, not a set of commits; [Searching
history](#searching-history) shows how to search every commit.

```console
$ git grep --cached --untracked lend
fatal: options '--untracked' and '--cached' cannot be used together
$ git grep --untracked lend
docs/guide/lending.md:Use lend() to lend a book.
Binary file logo.png matches
notes.txt:Ask about lend limits.
src/books.py:def lend(book, member):
$ git grep --untracked --no-exclude-standard lend
build/cache.txt:lend cache
docs/guide/lending.md:Use lend() to lend a book.
Binary file logo.png matches
notes.txt:Ask about lend limits.
src/books.py:def lend(book, member):
$ git grep --no-index lend
build/cache.txt:lend cache
docs/guide/lending.md:Use lend() to lend a book.
Binary file logo.png matches
notes.txt:Ask about lend limits.
src/books.py:def lend(book, member):
$ git grep --no-index --exclude-standard lend
docs/guide/lending.md:Use lend() to lend a book.
Binary file logo.png matches
notes.txt:Ask about lend limits.
src/books.py:def lend(book, member):
```

| Command | Tracked | Untracked | Ignored |
|---|---|---|---|
| `git grep` | yes | no | no |
| `git grep --untracked` | yes | yes | no |
| `git grep --untracked --no-exclude-standard` | yes | yes | yes |
| `git grep --no-index` | yes | yes | yes |
| `git grep --no-index --exclude-standard` | yes | yes | no |

`--untracked` adds files on disk to a working-tree search, so it makes no sense
with the index. `--no-index` searches files regardless of Git, like `grep -r`,
and Git's documentation lists what it keeps from Git: pathspecs, for one.
`--exclude-standard` makes it respect `.gitignore` after all.

```console
$ cd ..
$ cd plain
$ git grep lend
fatal: not a git repository (or any of the parent directories): .git
$ git grep --no-index lend
todo.txt:lend the atlas
$ git -c grep.fallbackToNoIndex=true grep lend
todo.txt:lend the atlas
$ cd ../library
```

Outside a repository, `git grep` fails unless given `--no-index`, or unless
`grep.fallbackToNoIndex` is true, which makes it act as if it had been.

## Colour

```ansi
$ git grep -n -p LOAN_DAYS -- src
\e[35msrc/books.py\e[m\e[36m:\e[m\e[32m1\e[m\e[36m:\e[m\e[1;31mLOAN_DAYS\e[m = 21
\e[35msrc/books.py\e[m\e[36m=\e[m\e[32m3\e[m\e[36m=\e[mdef lend(book, member):
\e[35msrc/books.py\e[m\e[36m:\e[m\e[32m6\e[m\e[36m:\e[m    book.due = today() + \e[1;31mLOAN_DAYS\e[m
$ git grep --no-color -n LOAN_DAYS -- src
src/books.py:1:LOAN_DAYS = 21
src/books.py:6:    book.due = today() + LOAN_DAYS
```

On a terminal, `git grep` colours file names, line numbers, separators and the
matched text. `--no-color` turns it off even where colour is configured.

```console
$ git grep --color=always -n LOAN_DAYS -- src | cat -A
^[[35msrc/books.py^[[m^[[36m:^[[m^[[32m1^[[m^[[36m:^[[m^[[1;31mLOAN_DAYS^[[m = 21$
^[[35msrc/books.py^[[m^[[36m:^[[m^[[32m6^[[m^[[36m:^[[m    book.due = today() + ^[[1;31mLOAN_DAYS^[[m$
$ git grep --color=auto -n LOAN_DAYS -- src | cat -A
src/books.py:1:LOAN_DAYS = 21$
src/books.py:6:    book.due = today() + LOAN_DAYS$
```

| Option | Colours |
|---|---|
| `--color`, `--color=always` | always, even into a pipe or file |
| `--color=auto` | only on a terminal |
| `--color=never`, `--no-color` | never |

Git's documentation says `always` is what `--color` alone means. `color.grep`
sets the default, and `color.grep.<slot>` each colour.

> **Since Git 2.35.** These colours, which match GNU grep. Older versions use a
> different set.

## Searching history

A function `renew_loan` used to exist. It is not in the current files:

```console
$ git log --oneline --all
5a59836 Charge fines for late books
a50bf5d Update the README
1a29d56 Lend for three weeks and drop renewals
088d1e3 Start the catalogue
$ git grep renew_loan
$ git grep renew_loan $(git rev-list --all)
088d1e399def4492073e328109bcba198c9af82c:src/books.py:def renew_loan(book):
$ git grep renew_loan HEAD~1 HEAD~2
HEAD~2:src/books.py:def renew_loan(book):
```

`git rev-list --all` prints the hash of every commit (Chapter 22), and `$(...)`
passes them all to `git grep`, in bash. It searched every snapshot and found the
function in the first commit only. In a real history the same line is found
again in every commit that contains it, so this answers "which versions contain
this", not "when did it appear".

`git log -S` answers that:

```console
$ git log --oneline -S renew_loan
1a29d56 Lend for three weeks and drop renewals
088d1e3 Start the catalogue
$ git log --oneline -S renew_loan -p -- src/books.py
1a29d56 Lend for three weeks and drop renewals
diff --git a/src/books.py b/src/books.py
index 40b91d9..f07d7f9 100644
--- a/src/books.py
+++ b/src/books.py
@@ -1,12 +1,10 @@
-LOAN_DAYS = 14
+LOAN_DAYS = 21
 
 def lend(book, member):
     # TODO: check the member's limit
     book.borrower = member
     book.due = today() + LOAN_DAYS
 
-def renew_loan(book):
-    book.due = book.due + LOAN_DAYS
-
 def give_back(book):
     book.borrower = None
+    book.due = None
088d1e3 Start the catalogue
diff --git a/src/books.py b/src/books.py
new file mode 100644
index 0000000..40b91d9
--- /dev/null
+++ b/src/books.py
@@ -0,0 +1,12 @@
+LOAN_DAYS = 14
+
+def lend(book, member):
+    # TODO: check the member's limit
+    book.borrower = member
+    book.due = today() + LOAN_DAYS
+
+def renew_loan(book):
+    book.due = book.due + LOAN_DAYS
+
+def give_back(book):
+    book.borrower = None
$ git show HEAD~2:src/books.py
LOAN_DAYS = 14

def lend(book, member):
    # TODO: check the member's limit
    book.borrower = member
    book.due = today() + LOAN_DAYS

def renew_loan(book):
    book.due = book.due + LOAN_DAYS

def give_back(book):
    book.borrower = None
```

`-S` lists the commits where the number of times the text appears changed: the
one that added `renew_loan` and the one that removed it. `-p` shows how. With
the commit known, `git show <commit>^:<path>`, or here `HEAD~2:src/books.py`,
prints the whole file from before it was removed (Chapter 18), ready to copy the
function back.

```console
$ git log --oneline -G 'LOAN_DAYS = [0-9]+' -p -- src/books.py
1a29d56 Lend for three weeks and drop renewals
diff --git a/src/books.py b/src/books.py
index 40b91d9..f07d7f9 100644
--- a/src/books.py
+++ b/src/books.py
@@ -1,12 +1,10 @@
-LOAN_DAYS = 14
+LOAN_DAYS = 21
 
 def lend(book, member):
     # TODO: check the member's limit
     book.borrower = member
     book.due = today() + LOAN_DAYS
 
-def renew_loan(book):
-    book.due = book.due + LOAN_DAYS
-
 def give_back(book):
     book.borrower = None
+    book.due = None
088d1e3 Start the catalogue
diff --git a/src/books.py b/src/books.py
new file mode 100644
index 0000000..40b91d9
--- /dev/null
+++ b/src/books.py
@@ -0,0 +1,12 @@
+LOAN_DAYS = 14
+
+def lend(book, member):
+    # TODO: check the member's limit
+    book.borrower = member
+    book.due = today() + LOAN_DAYS
+
+def renew_loan(book):
+    book.due = book.due + LOAN_DAYS
+
+def give_back(book):
+    book.borrower = None
```

`-G` takes a regular expression and lists commits that added or removed a line
matching it, which finds every change to the value, not only where the name
appeared. Chapter 13 shows exactly where `-S` and `-G` disagree, and the
options that go with them.

Commits on other branches are found only when asked for:

```console
$ git grep FINE_PER_DAY
$ git log --oneline -S FINE_PER_DAY
$ git log --oneline --all -S FINE_PER_DAY
5a59836 Charge fines for late books
$ git branch --contains 5a59836
  fines
$ git log --oneline --all -i --grep=fine
5a59836 Charge fines for late books
$ git log --oneline --all -- src/fines.py
5a59836 Charge fines for late books
$ git grep -c FINE_PER_DAY $(git rev-list --all) -- src/fines.py
5a59836c2d79d423568522307928f6095887a65a:src/fines.py:2
$ git rev-list --all | xargs git grep renew_loan
088d1e399def4492073e328109bcba198c9af82c:src/books.py:def renew_loan(book):
```

`--all` searches every branch and tag instead of the current branch.
`git branch --contains` names the branches that have the commit found
(Chapter 23). The last commands search messages (Chapter 17), follow a path
through every branch (Chapter 17), and count occurrences in every snapshot.
With thousands of commits the list of hashes can be too long for one command
line, and `xargs` passes it in pieces, as the last command shows.

| To find | Use |
|---|---|
| text in the files now, or in one version | `git grep <pattern> [<commit>]` |
| every version that contains some text | `git grep <pattern> $(git rev-list --all)` |
| the commits that added or removed some text | `git log -S <text>` (Chapter 13) |
| the commits that changed lines matching a pattern | `git log -G <regex>` (Chapter 13) |
| a commit by words in its message | `git log --grep=<pattern>` (Chapter 17), or `:/<text>` (Chapter 18) |
| the history of some lines | `git log -L` (Chapter 17) |
| a deleted file | `git log --all -- <path>`, or `--diff-filter=D` (Chapter 17) |
| the last commit that changed each line | `git blame` (Chapter 19) |
| the commit that broke something | `git bisect` (Chapter 20) |
| commits no branch contains any more | `git reflog` (Chapter 36), `git fsck --lost-found` (Chapter 77) |

> **Windows.** In PowerShell, `git grep renew_loan (git rev-list --all)` does the
> same as the bash `$(...)` form and gave the same result when tried outside the
> sandbox. cmd has no equivalent; use Git Bash or PowerShell for it.

## grep and its neighbours

| Command | Searches | Use it when |
|---|---|---|
| `git grep` | tracked files, the index, or any commit | you want to know where something is in the project |
| `grep -r` | every file on disk, `.git` included unless excluded | the files are not in Git, or you need `grep`'s own options |
| `git grep --no-index` | every file on disk, with Git's pattern and pathspec handling | the same, with Git's syntax |
| `git log -S`, `git log -G` | the changes made by commits | you want *when* something appeared or went |
| `git blame` | the last change to each line of one file (Chapter 19) | you are looking at a line |

In a repository `git grep` has less to read than `grep -r`, since it skips
untracked files and `.git`, and it can search with several threads.

## The settings

| Setting | Effect |
|---|---|
| `grep.lineNumber` | Behave as if `-n` were given |
| `grep.column` | Behave as if `--column` were given |
| `grep.patternType` | `basic`, `extended`, `fixed` or `perl` for the matching option of that name; `default` uses `grep.extendedRegexp` |
| `grep.extendedRegexp` | Behave as if `-E` were given, unless `grep.patternType` says otherwise |
| `grep.fullName` | Behave as if `--full-name` were given |
| `grep.fallbackToNoIndex` | Outside a repository, behave as if `--no-index` were given; `false` by default |
| `grep.threads` | Number of threads; as many as the machine has cores when unset or 0 |
| `color.grep` | When to colour: `always`, `auto`, `never`; `color.ui` when unset |
| `color.grep.<slot>` | Colours of `filename`, `lineNumber`, `column`, `separator`, `function`, `match`, `matchContext`, `matchSelected`, `selected` and `context` |

Git's documentation notes that `color.grep.matchSelected` and
`color.grep.selected` also colour the lines `git log --grep`, `--author` and
`--committer` match. `--threads <num>` overrides `grep.threads` for one command;
it changes only speed.
