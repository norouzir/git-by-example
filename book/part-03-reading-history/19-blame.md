# Chapter 19. blame

## What it is

`git blame <file>` prints a file with a note beside every line: the commit that
last changed that line, its author, its date, and the line number. It answers
"which commit put this line into its present form?", and from the commit you can
read why (Chapter 18).

The name sounds like an accusation, but the author shown is only whoever last
touched the line, which may have been a change of indentation, a rename or a
merge, and blame has options for looking past each of those. It also cannot show
lines that are no longer there; for those, see [When a line
disappeared](#when-a-line-disappeared) and Chapter 21.

A *boundary commit* is where blame stopped looking: the first commit of the
history, or the edge of a range you gave it. Lines from a boundary commit are
marked `^`.

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What does `git blame` tell me about a file?](#what-it-is)

**[Synopsis](#synopsis)**

- [What can I type after `git blame`?](#synopsis)

**[Options at a glance](#options-at-a-glance)**

- [Is there a list of every option, and where each is explained?](#options-at-a-glance)

**[Reading the output](#reading-the-output)**

- [What do the columns of `git blame` mean?](#reading-the-output)
- [What does `^` in front of a hash mean?](#reading-the-output)
- [Why does blame say "no such path in HEAD" for a file I can see?](#reading-the-output)

**[Some lines only](#some-lines-only)**

- [How do I blame only a few lines, or one function?](#some-lines-only)
- [Can I blame from a line to the end of the file?](#some-lines-only)
- [`-L '/regex/'` gives a usage error in Git Bash. Why?](#some-lines-only)

**[Changing the columns](#changing-the-columns)**

- [How do I hide the author and date to make the lines fit?](#changing-the-columns)
- [How do I show emails, full hashes, or a shorter date?](#changing-the-columns)
- [What is `git annotate`, and how does its output differ?](#changing-the-columns)
- [How do I get rid of the `^` marks?](#changing-the-columns)

**[Output for scripts](#output-for-scripts)**

- [How do I read blame output in a script?](#output-for-scripts)
- [What is the difference between `--porcelain` and `--line-porcelain`?](#output-for-scripts)
- [Why does `--progress` show nothing?](#output-for-scripts)

**[An older version, or part of history](#an-older-version-or-part-of-history)**

- [How do I blame the file as it was at a tag?](#an-older-version-or-part-of-history)
- [How do I stop blame from looking further back than a certain commit or date?](#an-older-version-or-part-of-history)

**[Lines not committed yet](#lines-not-committed-yet)**

- [What is "Not Committed Yet" with a hash of zeros?](#lines-not-committed-yet)
- [Can I blame a version of the file that is not in the repository, such as a draft?](#lines-not-committed-yet)

**[When a commit only reformatted](#when-a-commit-only-reformatted)**

- [A formatting commit is blamed for every line. How do I see past it?](#when-a-commit-only-reformatted)
- [What is the difference between `-w` and `--ignore-rev`?](#when-a-commit-only-reformatted)
- [How do I make the whole team skip the same commits?](#when-a-commit-only-reformatted)
- [What do `?` and `*` in front of a hash mean?](#when-a-commit-only-reformatted)

**[Moved and copied lines](#moved-and-copied-lines)**

- [I moved a function, and blame now says I wrote it. How do I find the real author?](#moved-and-copied-lines)
- [Code was moved to another file. Can blame follow it?](#moved-and-copied-lines)
- [What is the difference between `-C`, `-C -C` and `-C -C -C`?](#moved-and-copied-lines)
- [Is `-CCC` the same as `-C -C -C`?](#moved-and-copied-lines)

**[Renamed files and merges](#renamed-files-and-merges)**

- [Does blame follow a file that was renamed?](#renamed-files-and-merges)
- [Why is a file name shown in some blame output?](#renamed-files-and-merges)
- [How do I see which merge brought a line into my branch?](#renamed-files-and-merges)

**[When a line disappeared](#when-a-line-disappeared)**

- [How do I find the last commit where a deleted line still existed?](#when-a-line-disappeared)

**[Blaming a history you describe](#blaming-a-history-you-describe)**

- [What is `-S <revs-file>` for?](#blaming-a-history-you-describe)

**[Names, encodings and diff algorithms](#names-encodings-and-diff-algorithms)**

- [Does blame use `.mailmap`?](#names-encodings-and-diff-algorithms)
- [An author's name comes out garbled. What can I do?](#names-encodings-and-diff-algorithms)
- [Can the diff algorithm change who gets blamed?](#names-encodings-and-diff-algorithms)

**[Colour](#colour)**

- [How do I colour blame output by age, or mark repeated commits?](#colour)
- [Why does blame print colour codes into a file?](#colour)

**[blame and its neighbours](#blame-and-its-neighbours)**

- [Should I use `git blame`, `git log -L` or `git log -S`?](#blame-and-its-neighbours)

**[The settings](#the-settings)**

- [Which settings change what `git blame` shows by default?](#the-settings)

</details>

## Synopsis

```
git blame [<options>] [<rev> | --reverse <rev>..<rev>] [--] <file>
git annotate [<options>] [<rev>] [--] <file>
```

| Part | Means |
|---|---|
| `<file>` | The file to annotate; exactly one, and it must exist in `<rev>` |
| `<rev>` | Annotate the file as it was in this commit, or only within a range such as `v1..`; without it, the working tree's version |
| `--reverse <rev>..<rev>` | Walk forwards and show where each line was last present |
| `--` | Everything after it is the file, even if a branch has the same name |

| Command | Shows |
|---|---|
| `git blame <file>` | every line, with the commit that last changed it |
| `git blame -L 10,20 <file>` | only lines 10 to 20 |
| `git blame -w -M <file>` | the same, looking past whitespace changes and moved lines |
| `git blame v1.0 -- <file>` | the file as it was at `v1.0` |
| `git annotate <file>` | the same information in a tab-separated layout |

## Options at a glance

### Which lines and which history

| Option | Does | Covered in |
|---|---|---|
| `-L <start>,<end>`, `-L :<funcname>` | Annotate only these lines | [Some lines only](#some-lines-only) |
| `--since=<date>` and other range limits | Stop looking further back | [An older version, or part of history](#an-older-version-or-part-of-history) |
| `--contents <file>` | Annotate this file's content instead of the working tree's | [Lines not committed yet](#lines-not-committed-yet) |
| `-w` | Ignore whitespace changes when matching lines | [When a commit only reformatted](#when-a-commit-only-reformatted) |
| `--ignore-rev <rev>` | Blame as if this commit had not changed anything | [When a commit only reformatted](#when-a-commit-only-reformatted) |
| `--ignore-revs-file <file>` | Ignore every commit listed in a file | [When a commit only reformatted](#when-a-commit-only-reformatted) |
| `-M[<num>]` | Find lines moved or copied within the file | [Moved and copied lines](#moved-and-copied-lines) |
| `-C[<num>]` | Also find lines moved or copied from other files; repeat for wider searches | [Moved and copied lines](#moved-and-copied-lines) |
| `--first-parent` | Follow only the first parent of merges | [Renamed files and merges](#renamed-files-and-merges) |
| `--reverse <rev>..<rev>` | Show where lines were last present, walking forwards | [When a line disappeared](#when-a-line-disappeared) |
| `-S <revs-file>` | Use a history described in a file | [Blaming a history you describe](#blaming-a-history-you-describe) |
| `--diff-algorithm=<algorithm>` | Choose how versions are compared | [Names, encodings and diff algorithms](#names-encodings-and-diff-algorithms) |

### How the result is printed

| Option | Does | Covered in |
|---|---|---|
| `-s` | Leave out the author and date | [Changing the columns](#changing-the-columns) |
| `-e`, `--show-email` | Show emails instead of names | [Changing the columns](#changing-the-columns) |
| `-l` | Show full hashes | [Changing the columns](#changing-the-columns) |
| `--abbrev=<n>`, `--no-abbrev` | Choose how long hashes are | [Changing the columns](#changing-the-columns) |
| `-t` | Show dates as seconds since 1970 | [Changing the columns](#changing-the-columns) |
| `--date <format>` | Choose the date format | [Changing the columns](#changing-the-columns) |
| `-n`, `--show-number` | Show the line number in the commit the line came from | [Changing the columns](#changing-the-columns) |
| `-f`, `--show-name`, `--no-show-name` | Show the file name the line came from | [Changing the columns](#changing-the-columns) |
| `-b` | Leave boundary commits' hashes blank | [Changing the columns](#changing-the-columns) |
| `--root` | Do not treat root commits as boundaries | [Changing the columns](#changing-the-columns) |
| `-c` | Use `git annotate`'s layout | [Changing the columns](#changing-the-columns) |
| `-p`, `--porcelain` | A format for scripts | [Output for scripts](#output-for-scripts) |
| `--line-porcelain` | The same, with full details for every line | [Output for scripts](#output-for-scripts) |
| `--incremental` | A format for tools, printed as it is worked out | [Output for scripts](#output-for-scripts) |
| `--show-stats` | Print counts of the work done | [Output for scripts](#output-for-scripts) |
| `--progress`, `--no-progress` | Show progress, or not | [Output for scripts](#output-for-scripts) |
| `--score-debug` | Show the scores behind `-M` and `-C` | [Moved and copied lines](#moved-and-copied-lines) |
| `--encoding=<encoding>` | Re-encode names and subjects | [Names, encodings and diff algorithms](#names-encodings-and-diff-algorithms) |
| `--color-lines` | Colour lines from the same commit as the line above | [Colour](#colour) |
| `--color-by-age` | Colour lines by how old they are | [Colour](#colour) |

## Reading the output

The examples use a small shop written by three people: Ada started it, Grace
raised the tax, and Alan added pie and a discount.

```console
$ git blame shop.py
57f176d2 (Alan Turing  2026-01-05 11:00:00 +0000  1) PRICES = {'tea': 3, 'cake': 5, 'pie': 4}
^ecaff39 (Ada Lovelace 2026-01-05 09:00:00 +0000  2) 
^ecaff39 (Ada Lovelace 2026-01-05 09:00:00 +0000  3) def price(item):
^ecaff39 (Ada Lovelace 2026-01-05 09:00:00 +0000  4)     """Look up the price of one item."""
^ecaff39 (Ada Lovelace 2026-01-05 09:00:00 +0000  5)     return PRICES[item]
^ecaff39 (Ada Lovelace 2026-01-05 09:00:00 +0000  6) 
^ecaff39 (Ada Lovelace 2026-01-05 09:00:00 +0000  7) def tax(amount):
^ecaff39 (Ada Lovelace 2026-01-05 09:00:00 +0000  8)     """Work out the sales tax on an amount."""
7cdf4650 (Grace Hopper 2026-01-05 10:00:00 +0000  9)     return amount * 0.20
^ecaff39 (Ada Lovelace 2026-01-05 09:00:00 +0000 10) 
^ecaff39 (Ada Lovelace 2026-01-05 09:00:00 +0000 11) def total(items):
^ecaff39 (Ada Lovelace 2026-01-05 09:00:00 +0000 12)     subtotal = sum(price(i) for i in items)
^ecaff39 (Ada Lovelace 2026-01-05 09:00:00 +0000 13)     return subtotal + tax(subtotal)
57f176d2 (Alan Turing  2026-01-05 11:00:00 +0000 14) 
57f176d2 (Alan Turing  2026-01-05 11:00:00 +0000 15) def discount(amount):
57f176d2 (Alan Turing  2026-01-05 11:00:00 +0000 16)     """Take a pound off for loyal customers."""
57f176d2 (Alan Turing  2026-01-05 11:00:00 +0000 17)     return amount - 1
```

| Column | Is |
|---|---|
| `57f176d2` | the commit that last changed the line |
| `Alan Turing` | that commit's author |
| `2026-01-05 11:00:00 +0000` | its author date, in ISO format by default |
| `1` | the line's number in the file now |
| the rest | the line itself |

Alan changed line 1 to add pie, so line 1 is his even though Ada wrote most of
it: blame works by whole lines. `^ecaff39` is Ada's first commit, and `^` marks
it as a boundary: blame cannot look back beyond a commit with no parent. The
hash column is 8 characters wide, and Git's documentation explains that one of
them is kept for the `^`.

```console
$ git blame nosuch.py
fatal: no such path 'nosuch.py' in HEAD
$ git blame notes.txt
fatal: no such path 'notes.txt' in HEAD
$ git blame .
fatal: no such path '' in HEAD
```

`notes.txt` exists in the working tree but was never committed, so there is no
history to annotate; the message is the same as for a file that does not exist.
Blame takes exactly one file, not a directory.

## Some lines only

```console
$ git blame -s -L 7,9 shop.py
^ecaff39 7) def tax(amount):
^ecaff39 8)     """Work out the sales tax on an amount."""
7cdf4650 9)     return amount * 0.20
$ git blame -s -L 7,+3 shop.py
^ecaff39 7) def tax(amount):
^ecaff39 8)     """Work out the sales tax on an amount."""
7cdf4650 9)     return amount * 0.20
$ git blame -s -L 9,-3 shop.py
^ecaff39 7) def tax(amount):
^ecaff39 8)     """Work out the sales tax on an amount."""
7cdf4650 9)     return amount * 0.20
$ git blame -s -L 15 shop.py
57f176d2 15) def discount(amount):
57f176d2 16)     """Take a pound off for loyal customers."""
57f176d2 17)     return amount - 1
$ git blame -s -L ,2 shop.py
57f176d2 1) PRICES = {'tea': 3, 'cake': 5, 'pie': 4}
^ecaff39 2) 
$ git blame -s -L 9,7 shop.py
^ecaff39 7) def tax(amount):
^ecaff39 8)     """Work out the sales tax on an amount."""
7cdf4650 9)     return amount * 0.20
$ git blame -s -L :tax shop.py
^ecaff39  7) def tax(amount):
^ecaff39  8)     """Work out the sales tax on an amount."""
7cdf4650  9)     return amount * 0.20
^ecaff39 10) 
```

`-s` hides the author and date, to keep the lines short; [Changing the
columns](#changing-the-columns) covers it. `-L` takes the ranges that
`git log -L` does (Chapter 17), and blame adds two: a start with no end runs to
the end of the file, and an end with no start runs from line 1. Given backwards,
`9,7`, the range was read as `7,9`. `:tax` ran from the line matching `tax` up to
the next function.

```console
$ git blame -s -L '/^def total/,/return/' shop.py
^ecaff39 11) def total(items):
^ecaff39 12)     subtotal = sum(price(i) for i in items)
^ecaff39 13)     return subtotal + tax(subtotal)
$ git blame -s -L '/def/,+1' -L '/def/,+1' shop.py
^ecaff39 3) def price(item):
^ecaff39 7) def tax(amount):
$ git blame -s -L '/def/,+1' -L '^/def/,+1' shop.py
^ecaff39 3) def price(item):
$ git blame -s -L 1,1 -L 15,17 shop.py
57f176d2  1) PRICES = {'tea': 3, 'cake': 5, 'pie': 4}
57f176d2 15) def discount(amount):
57f176d2 16)     """Take a pound off for loyal customers."""
57f176d2 17)     return amount - 1
$ git blame -s -L 1,4 -L 3,5 shop.py
57f176d2 1) PRICES = {'tea': 3, 'cake': 5, 'pie': 4}
^ecaff39 2) 
^ecaff39 3) def price(item):
^ecaff39 4)     """Look up the price of one item."""
^ecaff39 5)     return PRICES[item]
$ git blame -s -L 40,50 shop.py
fatal: file shop.py has only 17 lines
$ git blame -s -L :nosuch shop.py
fatal: -L parameter 'nosuch' starting at line 1: no match
```

| Form | Annotates |
|---|---|
| `-L 7,9` | lines 7 to 9 |
| `-L 7,+3` | three lines from line 7 |
| `-L 9,-3` | three lines ending at line 9 |
| `-L 15` | from line 15 to the end |
| `-L ,2` | from the start to line 2 |
| `-L '/<regex>/,/<regex>/'` | from the first match of one pattern to the next match of the other |
| `-L :<funcname>` | a whole function |
| `-L '^/<regex>/,<end>'` | searching from the top of the file, even after another `-L` |

Several `-L` options add up, and overlapping ranges are shown once, as Git's
documentation allows. A second pattern searches on from the end of the first
range, so the two `/def/` found two different functions until `^` sent the
second back to the top.

> **Windows.** In Git Bash, an argument that starts with `/` looks like a path,
> and Git Bash rewrites it before Git sees it: `/^def total/,/return/` reached Git
> as `C:/Program Files/Git/^def total/,/return/`, and blame printed only its usage
> line. `git log -L` is not affected, because its value ends with `:<file>`. Two
> ways around it both worked: attach the value to the option with no space,
> `-L'/^def total/,/return/'`, or put `MSYS_NO_PATHCONV=1` in front of the
> command. In PowerShell and cmd the same pattern, in quotes, worked as it does in
> the transcripts. These were tested outside the sandbox, whose transcripts show
> bash as it behaves on Linux and macOS.

## Changing the columns

```console
$ git blame -s shop.py
57f176d2  1) PRICES = {'tea': 3, 'cake': 5, 'pie': 4}
^ecaff39  2) 
^ecaff39  3) def price(item):
^ecaff39  4)     """Look up the price of one item."""
^ecaff39  5)     return PRICES[item]
^ecaff39  6) 
^ecaff39  7) def tax(amount):
^ecaff39  8)     """Work out the sales tax on an amount."""
7cdf4650  9)     return amount * 0.20
^ecaff39 10) 
^ecaff39 11) def total(items):
^ecaff39 12)     subtotal = sum(price(i) for i in items)
^ecaff39 13)     return subtotal + tax(subtotal)
57f176d2 14) 
57f176d2 15) def discount(amount):
57f176d2 16)     """Take a pound off for loyal customers."""
57f176d2 17)     return amount - 1
$ git blame -e -L 7,9 shop.py
^ecaff39 (<ada@example.com>   2026-01-05 09:00:00 +0000 7) def tax(amount):
^ecaff39 (<ada@example.com>   2026-01-05 09:00:00 +0000 8)     """Work out the sales tax on an amount."""
7cdf4650 (<grace@example.com> 2026-01-05 10:00:00 +0000 9)     return amount * 0.20
$ git blame -l -L 7,9 shop.py
^ecaff393523018e79d3a560eedff0145d27e708 (Ada Lovelace 2026-01-05 09:00:00 +0000 7) def tax(amount):
^ecaff393523018e79d3a560eedff0145d27e708 (Ada Lovelace 2026-01-05 09:00:00 +0000 8)     """Work out the sales tax on an amount."""
7cdf4650a7e47d2bfdc1919484cec56b54c14a0c (Grace Hopper 2026-01-05 10:00:00 +0000 9)     return amount * 0.20
$ git blame -t -L 7,9 shop.py
^ecaff39 (Ada Lovelace 1767603600 +0000 7) def tax(amount):
^ecaff39 (Ada Lovelace 1767603600 +0000 8)     """Work out the sales tax on an amount."""
7cdf4650 (Grace Hopper 1767607200 +0000 9)     return amount * 0.20
$ git blame -n -L 7,9 shop.py
^ecaff39 7 (Ada Lovelace 2026-01-05 09:00:00 +0000 7) def tax(amount):
^ecaff39 8 (Ada Lovelace 2026-01-05 09:00:00 +0000 8)     """Work out the sales tax on an amount."""
7cdf4650 9 (Grace Hopper 2026-01-05 10:00:00 +0000 9)     return amount * 0.20
$ git blame -f -L 7,9 shop.py
^ecaff39 shop.py (Ada Lovelace 2026-01-05 09:00:00 +0000 7) def tax(amount):
^ecaff39 shop.py (Ada Lovelace 2026-01-05 09:00:00 +0000 8)     """Work out the sales tax on an amount."""
7cdf4650 shop.py (Grace Hopper 2026-01-05 10:00:00 +0000 9)     return amount * 0.20
```

| Option | Changes |
|---|---|
| `-s` | leaves out the author and date |
| `-e`, `--show-email` | the email instead of the name |
| `-l` | the full hash |
| `-t` | the date as seconds since 1970 and a time zone |
| `-n`, `--show-number` | adds the line's number in the commit it is blamed on |
| `-f`, `--show-name` | adds the name the file had in that commit |

With `-l` the boundary mark takes the place of the last character, so the full
hash of a boundary commit is cut by one. `-n` and `-f` matter when lines moved or
the file was renamed; here each line still has the same number and name.

```console
$ git blame --abbrev=12 -L 7,9 shop.py
^ecaff3935230 (Ada Lovelace 2026-01-05 09:00:00 +0000 7) def tax(amount):
^ecaff3935230 (Ada Lovelace 2026-01-05 09:00:00 +0000 8)     """Work out the sales tax on an amount."""
7cdf4650a7e47 (Grace Hopper 2026-01-05 10:00:00 +0000 9)     return amount * 0.20
$ git blame --abbrev=4 -L 7,9 shop.py
^ecaf (Ada Lovelace 2026-01-05 09:00:00 +0000 7) def tax(amount):
^ecaf (Ada Lovelace 2026-01-05 09:00:00 +0000 8)     """Work out the sales tax on an amount."""
7cdf4 (Grace Hopper 2026-01-05 10:00:00 +0000 9)     return amount * 0.20
$ git blame --no-abbrev -L 7,9 shop.py
^ecaff393523018e79d3a560eedff0145d27e708 (Ada Lovelace 2026-01-05 09:00:00 +0000 7) def tax(amount):
^ecaff393523018e79d3a560eedff0145d27e708 (Ada Lovelace 2026-01-05 09:00:00 +0000 8)     """Work out the sales tax on an amount."""
7cdf4650a7e47d2bfdc1919484cec56b54c14a0c (Grace Hopper 2026-01-05 10:00:00 +0000 9)     return amount * 0.20
$ git blame --date=short -L 7,9 shop.py
^ecaff39 (Ada Lovelace 2026-01-05 7) def tax(amount):
^ecaff39 (Ada Lovelace 2026-01-05 8)     """Work out the sales tax on an amount."""
7cdf4650 (Grace Hopper 2026-01-05 9)     return amount * 0.20
$ git blame --date=relative -L 7,9 shop.py
^ecaff39 (Ada Lovelace 3 hours ago            7) def tax(amount):
^ecaff39 (Ada Lovelace 3 hours ago            8)     """Work out the sales tax on an amount."""
7cdf4650 (Grace Hopper 2 hours ago            9)     return amount * 0.20
$ git -c blame.date=short blame -L 7,9 shop.py
^ecaff39 (Ada Lovelace 2026-01-05 7) def tax(amount):
^ecaff39 (Ada Lovelace 2026-01-05 8)     """Work out the sales tax on an amount."""
7cdf4650 (Grace Hopper 2026-01-05 9)     return amount * 0.20
$ git -c blame.showEmail=true blame -L 7,9 shop.py
^ecaff39 (<ada@example.com>   2026-01-05 09:00:00 +0000 7) def tax(amount):
^ecaff39 (<ada@example.com>   2026-01-05 09:00:00 +0000 8)     """Work out the sales tax on an amount."""
7cdf4650 (<grace@example.com> 2026-01-05 10:00:00 +0000 9)     return amount * 0.20
```

`--abbrev=<n>` prints `<n>` characters plus one column for the boundary mark,
as Git's documentation says; `^ecaf` is four characters after the mark. `--date`
takes every format of `git log --date` (Chapter 17). It is 12:00 in this
repository, which is why the relative dates say 2 and 3 hours. `blame.date` and
`blame.showEmail` set the defaults.

```console
$ git blame -c -L 7,9 shop.py
ecaff393	(Ada Lovelace	2026-01-05 09:00:00 +0000	7)def tax(amount):
ecaff393	(Ada Lovelace	2026-01-05 09:00:00 +0000	8)    """Work out the sales tax on an amount."""
7cdf4650	(Grace Hopper	2026-01-05 10:00:00 +0000	9)    return amount * 0.20
$ git annotate -L 7,9 shop.py
ecaff393	(Ada Lovelace	2026-01-05 09:00:00 +0000	7)def tax(amount):
ecaff393	(Ada Lovelace	2026-01-05 09:00:00 +0000	8)    """Work out the sales tax on an amount."""
7cdf4650	(Grace Hopper	2026-01-05 10:00:00 +0000	9)    return amount * 0.20
$ git blame -b -L 7,9 shop.py
         (Ada Lovelace 2026-01-05 09:00:00 +0000 7) def tax(amount):
         (Ada Lovelace 2026-01-05 09:00:00 +0000 8)     """Work out the sales tax on an amount."""
7cdf4650 (Grace Hopper 2026-01-05 10:00:00 +0000 9)     return amount * 0.20
$ git blame --root -L 7,9 shop.py
ecaff393 (Ada Lovelace 2026-01-05 09:00:00 +0000 7) def tax(amount):
ecaff393 (Ada Lovelace 2026-01-05 09:00:00 +0000 8)     """Work out the sales tax on an amount."""
7cdf4650 (Grace Hopper 2026-01-05 10:00:00 +0000 9)     return amount * 0.20
$ git -c blame.blankBoundary=true blame -L 7,9 shop.py
         (Ada Lovelace 2026-01-05 09:00:00 +0000 7) def tax(amount):
         (Ada Lovelace 2026-01-05 09:00:00 +0000 8)     """Work out the sales tax on an amount."""
7cdf4650 (Grace Hopper 2026-01-05 10:00:00 +0000 9)     return amount * 0.20
$ git -c blame.showRoot=true blame -L 7,9 shop.py
ecaff393 (Ada Lovelace 2026-01-05 09:00:00 +0000 7) def tax(amount):
ecaff393 (Ada Lovelace 2026-01-05 09:00:00 +0000 8)     """Work out the sales tax on an amount."""
7cdf4650 (Grace Hopper 2026-01-05 10:00:00 +0000 9)     return amount * 0.20
```

`git annotate` is `git blame -c`: the same information separated by tabs, with no
boundary marks and no space before the line. Git's documentation says it exists
for older scripts and for people used to that name from other version control
systems. `-b` blanks the hash of boundary commits and `--root` stops treating a
root commit as one; `blame.blankBoundary` and `blame.showRoot` make those the
default.

## Output for scripts

```console
$ git blame -p -L 8,9 shop.py
ecaff393523018e79d3a560eedff0145d27e7089 8 8 1
author Ada Lovelace
author-mail <ada@example.com>
author-time 1767603600
author-tz +0000
committer Ada Lovelace
committer-mail <ada@example.com>
committer-time 1767603600
committer-tz +0000
summary Start the shop
boundary
filename shop.py
	    """Work out the sales tax on an amount."""
7cdf4650a7e47d2bfdc1919484cec56b54c14a0c 9 9 1
author Grace Hopper
author-mail <grace@example.com>
author-time 1767607200
author-tz +0000
committer Grace Hopper
committer-mail <grace@example.com>
committer-time 1767607200
committer-tz +0000
summary Raise tax to 20%
previous ecaff393523018e79d3a560eedff0145d27e7089 shop.py
filename shop.py
	    return amount * 0.20
$ git blame -p -L 15,17 shop.py
57f176d299db8476292bbbd00a44ba3295dba9e7 15 15 3
author Alan Turing
author-mail <alan@example.com>
author-time 1767610800
author-tz +0000
committer Alan Turing
committer-mail <alan@example.com>
committer-time 1767610800
committer-tz +0000
summary Sell pie and add a discount
previous 7cdf4650a7e47d2bfdc1919484cec56b54c14a0c shop.py
filename shop.py
	def discount(amount):
57f176d299db8476292bbbd00a44ba3295dba9e7 16 16
	    """Take a pound off for loyal customers."""
57f176d299db8476292bbbd00a44ba3295dba9e7 17 17
	    return amount - 1
$ git blame --line-porcelain -L 15,17 shop.py | grep '^author '
author Alan Turing
author Alan Turing
author Alan Turing
```

In the *porcelain* format each line starts with a header: the full hash, the
line's number in that commit, its number now, and, when a group of lines from one
commit starts, how many lines the group has. The details of a commit follow the
first time it appears, then the line itself after a tab. Lines 16 and 17 came from
a commit already described, so they got the header alone.

| Header line | Is |
|---|---|
| `author`, `author-mail`, `author-time`, `author-tz` | the author, and the date as seconds and a zone |
| `committer`, `committer-mail`, `committer-time`, `committer-tz` | the same for the committer |
| `summary` | the first line of the message |
| `boundary` | present when the commit is a boundary |
| `previous <hash> <file>` | the commit before, and the file's name there |
| `filename` | the file's name in that commit |

`--line-porcelain` repeats every detail for every line, so a script can read each
line on its own; `grep` found the author three times. Git's documentation shows
counting lines per author this way.

```console
$ git blame --incremental -L 8,9 shop.py
7cdf4650a7e47d2bfdc1919484cec56b54c14a0c 9 9 1
author Grace Hopper
author-mail <grace@example.com>
author-time 1767607200
author-tz +0000
committer Grace Hopper
committer-mail <grace@example.com>
committer-time 1767607200
committer-tz +0000
summary Raise tax to 20%
previous ecaff393523018e79d3a560eedff0145d27e7089 shop.py
filename shop.py
ecaff393523018e79d3a560eedff0145d27e7089 8 8 1
author Ada Lovelace
author-mail <ada@example.com>
author-time 1767603600
author-tz +0000
committer Ada Lovelace
committer-mail <ada@example.com>
committer-time 1767603600
committer-tz +0000
summary Start the shop
boundary
filename shop.py
$ git blame --show-stats -L 8,9 shop.py
^ecaff39 (Ada Lovelace 2026-01-05 09:00:00 +0000 8)     """Work out the sales tax on an amount."""
7cdf4650 (Grace Hopper 2026-01-05 10:00:00 +0000 9)     return amount * 0.20
num read blob: 3
num get patch: 2
num commits: 2
```

`--incremental` prints each result as soon as it is found, for programs that
show blame while it runs: the newer commit came first, the lines themselves are
not printed, and every entry ends with `filename`. `--show-stats` adds counts of
the work done: file versions read, diffs computed, commits visited.

```console
$ git blame --progress -s -L 8,9 shop.py
^ecaff39 8)     """Work out the sales tax on an amount."""
7cdf4650 9)     return amount * 0.20
$ GIT_PROGRESS_DELAY=0 git blame --progress -s -L 8,9 shop.py
Blaming lines:  50% (1/2)
Blaming lines: 100% (2/2)
Blaming lines: 100% (2/2), done.
^ecaff39 8)     """Work out the sales tax on an amount."""
7cdf4650 9)     return amount * 0.20
$ git blame --progress -p shop.py
fatal: --progress can't be used with --incremental or porcelain formats
```

Progress goes to the terminal on its own, and `--progress` asks for it even when
output goes elsewhere. It still appears only after a delay, one second by
default, and this blame was faster than that. `GIT_PROGRESS_DELAY=0` removed the
delay, in bash. The three progress lines are drawn over each other on a terminal;
they end with a carriage return, not a new line. `--no-progress` turns it off.

> **Since Git 2.25.** `GIT_PROGRESS_DELAY`.

## An older version, or part of history

```console
$ git blame -s v1 -- shop.py
^ecaff39  1) PRICES = {'tea': 3, 'cake': 5}
^ecaff39  2) 
^ecaff39  3) def price(item):
^ecaff39  4)     """Look up the price of one item."""
^ecaff39  5)     return PRICES[item]
^ecaff39  6) 
^ecaff39  7) def tax(amount):
^ecaff39  8)     """Work out the sales tax on an amount."""
7cdf4650  9)     return amount * 0.20
^ecaff39 10) 
^ecaff39 11) def total(items):
^ecaff39 12)     subtotal = sum(price(i) for i in items)
^ecaff39 13)     return subtotal + tax(subtotal)
$ git blame -s v1.. -- shop.py
57f176d2  1) PRICES = {'tea': 3, 'cake': 5, 'pie': 4}
^7cdf465  2) 
^7cdf465  3) def price(item):
^7cdf465  4)     """Look up the price of one item."""
^7cdf465  5)     return PRICES[item]
^7cdf465  6) 
^7cdf465  7) def tax(amount):
^7cdf465  8)     """Work out the sales tax on an amount."""
^7cdf465  9)     return amount * 0.20
^7cdf465 10) 
^7cdf465 11) def total(items):
^7cdf465 12)     subtotal = sum(price(i) for i in items)
^7cdf465 13)     return subtotal + tax(subtotal)
57f176d2 14) 
57f176d2 15) def discount(amount):
57f176d2 16)     """Take a pound off for loyal customers."""
57f176d2 17)     return amount - 1
$ git blame -s --since='2026-01-05 10:30' -- shop.py
57f176d2  1) PRICES = {'tea': 3, 'cake': 5, 'pie': 4}
^7cdf465  2) 
^7cdf465  3) def price(item):
^7cdf465  4)     """Look up the price of one item."""
^7cdf465  5)     return PRICES[item]
^7cdf465  6) 
^7cdf465  7) def tax(amount):
^7cdf465  8)     """Work out the sales tax on an amount."""
^7cdf465  9)     return amount * 0.20
^7cdf465 10) 
^7cdf465 11) def total(items):
^7cdf465 12)     subtotal = sum(price(i) for i in items)
^7cdf465 13)     return subtotal + tax(subtotal)
57f176d2 14) 
57f176d2 15) def discount(amount):
57f176d2 16)     """Take a pound off for loyal customers."""
57f176d2 17)     return amount - 1
```

A commit before the file annotates the file as it was then; `v1` is the tag on
Grace's commit (Chapter 18). A range such as `v1..` stops at its edge, and
`--since` at the newest commit older than the date. Git's documentation explains
that lines not changed since then are blamed on that boundary commit, marked
`^`: here `^7cdf465`, Grace's commit, instead of Ada's.

## Lines not committed yet

Here line 1 has been edited in the working tree and not committed:

```console
$ git blame -s -L 1,2 shop.py
00000000 1) PRICES = {'tea': 3, 'cake': 5, 'pie': 4, 'jam': 2}
^ecaff39 2) 
$ git blame -p -L 1,1 shop.py
0000000000000000000000000000000000000000 1 1 1
author Not Committed Yet
author-mail <not.committed.yet>
...
summary Version of shop.py from shop.py
previous 57f176d299db8476292bbbd00a44ba3295dba9e7 shop.py
filename shop.py
	PRICES = {'tea': 3, 'cake': 5, 'pie': 4, 'jam': 2}
$ git blame -s -L 1,2 HEAD -- shop.py
57f176d2 1) PRICES = {'tea': 3, 'cake': 5, 'pie': 4}
^ecaff39 2) 
```

Without `<rev>`, blame annotates the file in the working tree, and a line that
differs from the last commit belongs to an imaginary commit of zeros whose author
is `Not Committed Yet`. Its date is the moment blame ran, which is why these
examples hide it with `-s` and cut it from the porcelain output with `...`.
Naming `HEAD` blames the last commit instead.

```console
$ git blame -s --contents ../draft.py shop.py
00000000 1) PRICES = {'tea': 3, 'cake': 6}
^ecaff39 2) 
^ecaff39 3) def price(item):
^ecaff39 4)     """Look up the price of one item."""
^ecaff39 5)     return PRICES[item]
$ git blame -s --contents ../draft.py v1 -- shop.py
00000000 1) PRICES = {'tea': 3, 'cake': 6}
^ecaff39 2) 
^ecaff39 3) def price(item):
^ecaff39 4)     """Look up the price of one item."""
^ecaff39 5)     return PRICES[item]
$ git blame -p --contents ../draft.py -L 1,1 shop.py
0000000000000000000000000000000000000000 1 1 1
author External file (--contents)
author-mail <external.file>
...
summary Version of shop.py from ../draft.py
previous 57f176d299db8476292bbbd00a44ba3295dba9e7 shop.py
filename shop.py
	PRICES = {'tea': 3, 'cake': 6}
$ git show v1:shop.py | git blame -s --contents - shop.py
00000000  1) PRICES = {'tea': 3, 'cake': 5}
^ecaff39  2) 
^ecaff39  3) def price(item):
^ecaff39  4)     """Look up the price of one item."""
^ecaff39  5)     return PRICES[item]
^ecaff39  6) 
^ecaff39  7) def tax(amount):
^ecaff39  8)     """Work out the sales tax on an amount."""
7cdf4650  9)     return amount * 0.20
^ecaff39 10) 
^ecaff39 11) def total(items):
^ecaff39 12)     subtotal = sum(price(i) for i in items)
^ecaff39 13)     return subtotal + tax(subtotal)
```

`--contents` blames other content as if it were the working tree's `shop.py`: a
draft kept elsewhere, or, with `-`, whatever arrives on standard input. Lines
matching the history get their commits, and the rest belong to `External file
(--contents)`. With a `<rev>` as well, the history is searched from that commit.
The last example fed in `v1`'s version, and its first line, which no longer
exists in `HEAD`, counted as new.

> **Since Git 2.41.** `--contents` together with a `<rev>`; before, the two could
> not be combined.

## When a commit only reformatted

Grace then made a commit that removed spaces around operators, changed the quotes
around the prices, and added a comment:

```console
$ git show --stat --oneline
1f244fe Format the code
 shop.py | 7 ++++---
 1 file changed, 4 insertions(+), 3 deletions(-)
$ git blame -s shop.py
1f244fe3  1) # Prices in pounds.
1f244fe3  2) PRICES = {"tea": 3, "cake": 5, "pie": 4}
^ecaff39  3) 
^ecaff39  4) def price(item):
^ecaff39  5)     """Look up the price of one item."""
^ecaff39  6)     return PRICES[item]
^ecaff39  7) 
^ecaff39  8) def tax(amount):
^ecaff39  9)     """Work out the sales tax on an amount."""
1f244fe3 10)     return amount*0.20
^ecaff39 11) 
^ecaff39 12) def total(items):
^ecaff39 13)     subtotal = sum(price(i) for i in items)
1f244fe3 14)     return subtotal+tax(subtotal)
57f176d2 15) 
57f176d2 16) def discount(amount):
57f176d2 17)     """Take a pound off for loyal customers."""
57f176d2 18)     return amount - 1
$ git blame -s -w shop.py
1f244fe3  1) # Prices in pounds.
1f244fe3  2) PRICES = {"tea": 3, "cake": 5, "pie": 4}
^ecaff39  3) 
^ecaff39  4) def price(item):
^ecaff39  5)     """Look up the price of one item."""
^ecaff39  6)     return PRICES[item]
^ecaff39  7) 
^ecaff39  8) def tax(amount):
^ecaff39  9)     """Work out the sales tax on an amount."""
7cdf4650 10)     return amount*0.20
^ecaff39 11) 
^ecaff39 12) def total(items):
^ecaff39 13)     subtotal = sum(price(i) for i in items)
^ecaff39 14)     return subtotal+tax(subtotal)
57f176d2 15) 
57f176d2 16) def discount(amount):
57f176d2 17)     """Take a pound off for loyal customers."""
57f176d2 18)     return amount - 1
$ git blame -s --ignore-rev 1f244fe shop.py
1f244fe3  1) # Prices in pounds.
57f176d2  2) PRICES = {"tea": 3, "cake": 5, "pie": 4}
^ecaff39  3) 
^ecaff39  4) def price(item):
^ecaff39  5)     """Look up the price of one item."""
^ecaff39  6)     return PRICES[item]
^ecaff39  7) 
^ecaff39  8) def tax(amount):
^ecaff39  9)     """Work out the sales tax on an amount."""
7cdf4650 10)     return amount*0.20
^ecaff39 11) 
^ecaff39 12) def total(items):
^ecaff39 13)     subtotal = sum(price(i) for i in items)
^ecaff39 14)     return subtotal+tax(subtotal)
57f176d2 15) 
57f176d2 16) def discount(amount):
57f176d2 17)     """Take a pound off for loyal customers."""
57f176d2 18)     return amount - 1
```

| Option | Looks past | Here |
|---|---|---|
| `-w` | changes to whitespace only, in any commit | lines 10 and 14 went back to their authors; line 2 did not, because quotes are not whitespace |
| `--ignore-rev <rev>` | every change one commit made | lines 2, 10 and 14 went back; line 1 stayed, because there was nothing before it |

`--ignore-rev` blames a line the ignored commit changed on the commit that last
changed it, or a line nearby, before; Git's documentation describes it as if the
change had never happened. A line the commit added from nothing cannot be given
to anyone else and stays with it.

```console
$ git -c blame.markIgnoredLines=true -c blame.markUnblamableLines=true blame -s --ignore-rev 1f244fe shop.py
*1f244fe  1) # Prices in pounds.
?57f176d  2) PRICES = {"tea": 3, "cake": 5, "pie": 4}
^ecaff39  3) 
^ecaff39  4) def price(item):
^ecaff39  5)     """Look up the price of one item."""
^ecaff39  6)     return PRICES[item]
^ecaff39  7) 
^ecaff39  8) def tax(amount):
^ecaff39  9)     """Work out the sales tax on an amount."""
?7cdf465 10)     return amount*0.20
^ecaff39 11) 
^ecaff39 12) def total(items):
^ecaff39 13)     subtotal = sum(price(i) for i in items)
^?ecaff3 14)     return subtotal+tax(subtotal)
57f176d2 15) 
57f176d2 16) def discount(amount):
57f176d2 17)     """Take a pound off for loyal customers."""
57f176d2 18)     return amount - 1
$ git -c blame.markIgnoredLines=true -c blame.markUnblamableLines=true blame --line-porcelain --ignore-rev 1f244fe -L 1,1 shop.py
1f244fe37de5ef780afd9c305559022fc80cff61 1 1 1
author Grace Hopper
author-mail <grace@example.com>
author-time 1767614400
author-tz +0000
committer Grace Hopper
committer-mail <grace@example.com>
committer-time 1767614400
committer-tz +0000
summary Format the code
previous 57f176d299db8476292bbbd00a44ba3295dba9e7 shop.py
filename shop.py
unblamable
	# Prices in pounds.
```

| Mark | Setting | Means |
|---|---|---|
| `?` | `blame.markIgnoredLines` | the ignored commit changed this line, and it was blamed on an older one |
| `*` | `blame.markUnblamableLines` | the ignored commit changed this line, and no older commit could be found |

A mark takes the place of the hash's first character, and on line 14 it follows
the boundary mark. In porcelain output the marks become a line of their own,
`ignored` or `unblamable`.

A team usually keeps the commits to ignore in a file in the repository, one full
hash per line:

```console
$ git rev-parse 1f244fe > .git-blame-ignore-revs
$ cat .git-blame-ignore-revs
1f244fe37de5ef780afd9c305559022fc80cff61
$ git blame -s --ignore-revs-file .git-blame-ignore-revs -L 8,10 shop.py
^ecaff39  8) def tax(amount):
^ecaff39  9)     """Work out the sales tax on an amount."""
7cdf4650 10)     return amount*0.20
$ git config blame.ignoreRevsFile .git-blame-ignore-revs
$ git blame -s -L 8,10 shop.py
^ecaff39  8) def tax(amount):
^ecaff39  9)     """Work out the sales tax on an amount."""
7cdf4650 10)     return amount*0.20
$ git blame -s --ignore-revs-file '' -L 8,10 shop.py
^ecaff39  8) def tax(amount):
^ecaff39  9)     """Work out the sales tax on an amount."""
1f244fe3 10)     return amount*0.20
$ git blame -s --ignore-rev nosuch -L 8,10 shop.py
fatal: cannot find revision nosuch to ignore
```

`git rev-parse` prints the full hash (Chapter 22). The file's name is your
choice, and Git reads it only when told to, with
`--ignore-revs-file` or `blame.ignoreRevsFile`, and the setting is local, so
each person sets it once (Chapter 62). Git's documentation says the file may
contain comments starting with `#`, that an empty name, `''`, clears the files
read so far, and that the files from the setting are read before those on the
command line.

## Moved and copied lines

Ada moved `discount` above `tax`, and tagged the result `v2`:

```console
$ git blame -s shop.py
1f244fe3  1) # Prices in pounds.
1f244fe3  2) PRICES = {"tea": 3, "cake": 5, "pie": 4}
^ecaff39  3) 
^ecaff39  4) def price(item):
^ecaff39  5)     """Look up the price of one item."""
^ecaff39  6)     return PRICES[item]
^ecaff39  7) 
031c436c  8) def discount(amount):
031c436c  9)     """Take a pound off for loyal customers."""
031c436c 10)     return amount - 1
031c436c 11) 
^ecaff39 12) def tax(amount):
^ecaff39 13)     """Work out the sales tax on an amount."""
1f244fe3 14)     return amount*0.20
^ecaff39 15) 
^ecaff39 16) def total(items):
^ecaff39 17)     subtotal = sum(price(i) for i in items)
1f244fe3 18)     return subtotal+tax(subtotal)
$ git blame -s -M shop.py
1f244fe3  1) # Prices in pounds.
1f244fe3  2) PRICES = {"tea": 3, "cake": 5, "pie": 4}
^ecaff39  3) 
^ecaff39  4) def price(item):
^ecaff39  5)     """Look up the price of one item."""
^ecaff39  6)     return PRICES[item]
^ecaff39  7) 
57f176d2  8) def discount(amount):
57f176d2  9)     """Take a pound off for loyal customers."""
57f176d2 10)     return amount - 1
031c436c 11) 
^ecaff39 12) def tax(amount):
^ecaff39 13)     """Work out the sales tax on an amount."""
1f244fe3 14)     return amount*0.20
^ecaff39 15) 
^ecaff39 16) def total(items):
^ecaff39 17)     subtotal = sum(price(i) for i in items)
1f244fe3 18)     return subtotal+tax(subtotal)
$ git blame -s -M --score-debug -L 7,9 shop.py
^ecaff39  1 02 7) 
57f176d2 48 01 8) def discount(amount):
57f176d2 48 01 9)     """Take a pound off for loyal customers."""
$ git blame -s -M80 -L 7,9 shop.py
^ecaff39 7) 
031c436c 8) def discount(amount):
031c436c 9)     """Take a pound off for loyal customers."""
```

A diff sees a move as a deletion in one place and an addition in another, so the
plain blame gave `discount` to Ada, who only moved it. `-M` looks for lines moved
or copied within the file and gave them back to Alan. The blank line she added
stays hers.

`--score-debug` shows why: the first number is the score, the count of letters
and digits recognised as moved, 48 here. A move counts only above a threshold,
20 by default for `-M`, as Git's documentation gives it. `-M80` asked for more
than the block had, so the move was not recognised.

Alan then moved `tax` into a file of its own:

```console
$ git show --stat --oneline
d7970ae Move tax into its own file
 shop.py | 4 +---
 tax.py  | 3 +++
 2 files changed, 4 insertions(+), 3 deletions(-)
$ git blame -s tax.py
d7970aec 1) def tax(amount):
d7970aec 2)     """Work out the sales tax on an amount."""
d7970aec 3)     return amount*0.20
$ git blame -s -M tax.py
d7970aec 1) def tax(amount):
d7970aec 2)     """Work out the sales tax on an amount."""
d7970aec 3)     return amount*0.20
$ git blame -s -C tax.py
^ecaff39 shop.py 1) def tax(amount):
^ecaff39 shop.py 2)     """Work out the sales tax on an amount."""
1f244fe3 shop.py 3)     return amount*0.20
```

`-M` stays within one file. `-C` also looks in the other files the same commit
changed, found the lines in `shop.py`, and showed that file's name, since the
lines came from somewhere else.

Grace added `receipt.py`, starting with a copy of `total`, without touching
`shop.py`; Ada later pasted `price` into an existing file, `stock.py`:

```console
$ git show --stat --oneline
6d1c58a Add a receipt and a stock list
 receipt.py | 6 ++++++
 stock.py   | 1 +
 2 files changed, 7 insertions(+)
$ git blame -s -C receipt.py
6d1c58aa 1) def total(items):
6d1c58aa 2)     subtotal = sum(price(i) for i in items)
6d1c58aa 3)     return subtotal+tax(subtotal)
6d1c58aa 4) 
6d1c58aa 5) def receipt(items):
6d1c58aa 6)     return total(items)
$ git blame -s -C -C receipt.py
^ecaff39 shop.py    1) def total(items):
^ecaff39 shop.py    2)     subtotal = sum(price(i) for i in items)
1f244fe3 shop.py    3)     return subtotal+tax(subtotal)
6d1c58aa receipt.py 4) 
6d1c58aa receipt.py 5) def receipt(items):
6d1c58aa receipt.py 6)     return total(items)
$ git show --stat --oneline
a3878a0 Look up prices from the stock list
 stock.py | 4 ++++
 1 file changed, 4 insertions(+)
$ git blame -s -C -C stock.py
6d1c58aa 1) STOCK = {'tea': 10}
a3878a02 2) 
a3878a02 3) def price(item):
a3878a02 4)     """Look up the price of one item."""
a3878a02 5)     return PRICES[item]
$ git blame -s -C -C -C stock.py
6d1c58aa stock.py 1) STOCK = {'tea': 10}
^ecaff39 shop.py  2) 
^ecaff39 shop.py  3) def price(item):
^ecaff39 shop.py  4)     """Look up the price of one item."""
^ecaff39 shop.py  5)     return PRICES[item]
$ git blame -s -CCC stock.py
6d1c58aa 1) STOCK = {'tea': 10}
a3878a02 2) 
a3878a02 3) def price(item):
a3878a02 4)     """Look up the price of one item."""
a3878a02 5)     return PRICES[item]
$ git blame -s -C -C -C60 stock.py
6d1c58aa 1) STOCK = {'tea': 10}
a3878a02 2) 
a3878a02 3) def price(item):
a3878a02 4)     """Look up the price of one item."""
a3878a02 5)     return PRICES[item]
```

| Option | Finds lines that came from |
|---|---|
| `-M` | elsewhere in the same file |
| `-C` | that, or another file changed in the same commit |
| `-C -C` | that, or any file, in the commit that created this file |
| `-C -C -C` | that, or any file in any commit |

Each searches more than the one before. `-C -C` found
the copy in the new `receipt.py`, but not in `stock.py`, which already existed;
that needed `-C -C -C`.

`-CCC` is not the same, and behaved like a single `-C`: whatever follows `-C`
without a space is where its threshold goes, `-C[<num>]`. The threshold for `-C` is 40
by default, as Git's documentation gives it, and with several `-C` the number on
the last one counts, so `-C -C -C60` missed the copied function, which is shorter
than that.

## Renamed files and merges

Grace renamed `shop.py` to `store.py`:

```console
$ git blame -s -L 1,5 store.py
1f244fe3 shop.py 1) # Prices in pounds.
1f244fe3 shop.py 2) PRICES = {"tea": 3, "cake": 5, "pie": 4}
^ecaff39 shop.py 3) 
^ecaff39 shop.py 4) def price(item):
^ecaff39 shop.py 5)     """Look up the price of one item."""
$ git blame -s --no-show-name -L 1,2 store.py
1f244fe3 shop.py 1) # Prices in pounds.
1f244fe3 shop.py 2) PRICES = {"tea": 3, "cake": 5, "pie": 4}
$ git blame -s -L 1,5 shop.py
fatal: no such path 'shop.py' in HEAD
$ git blame -s -L 1,5 HEAD~1 -- shop.py
1f244fe3 1) # Prices in pounds.
1f244fe3 2) PRICES = {"tea": 3, "cake": 5, "pie": 4}
^ecaff39 3) 
^ecaff39 4) def price(item):
^ecaff39 5)     """Look up the price of one item."""
```

Blame followed the rename by itself; Git's documentation says there is no option
to turn that off. It showed the old name, as it does whenever any line came from
a file with a different name, and `--no-show-name` did not remove it. The old
name works only with a commit that still has it.

Alan doubled the discount on a branch, and Ada merged it:

```console
$ git log --oneline --graph -4
*   70623c4 Merge the promotion
|\  
| * 45f45e5 Double the discount
|/  
* 2ea5abb Rename shop.py to store.py
* a3878a0 Look up prices from the stock list
$ git blame -s -L 8,10 store.py
031c436c shop.py   8) def discount(amount):
031c436c shop.py   9)     """Take a pound off for loyal customers."""
45f45e5f store.py 10)     return amount - 2
$ git blame -s --first-parent -L 8,10 store.py
031c436c shop.py   8) def discount(amount):
031c436c shop.py   9)     """Take a pound off for loyal customers."""
70623c46 store.py 10)     return amount - 2
```

Blame follows merges into the branch where a line was written, so line 10 is
Alan's commit. `--first-parent` stays on the main line (Chapter 17), which gave
the merge commit: when the change arrived on `main`, rather than when it was
written.

## When a line disappeared

Blame shows the lines that are there. `--reverse` answers the opposite question
for lines of an older version: until which commit did each one survive?

```console
$ git log --oneline v1..v2
031c436 Put discount before tax
1f244fe Format the code
57f176d Sell pie and add a discount
$ git blame -s --reverse v1..v2 -- shop.py
^7cdf465  1) PRICES = {'tea': 3, 'cake': 5}
031c436c  2) 
031c436c  3) def price(item):
031c436c  4)     """Look up the price of one item."""
031c436c  5)     return PRICES[item]
031c436c  6) 
031c436c  7) def tax(amount):
031c436c  8)     """Work out the sales tax on an amount."""
57f176d2  9)     return amount * 0.20
031c436c 10) 
031c436c 11) def total(items):
031c436c 12)     subtotal = sum(price(i) for i in items)
57f176d2 13)     return subtotal + tax(subtotal)
$ git blame -s --reverse v1 -- shop.py
^7cdf465 shop.py   1) PRICES = {'tea': 3, 'cake': 5}
70623c46 store.py  2) 
70623c46 store.py  3) def price(item):
70623c46 store.py  4)     """Look up the price of one item."""
70623c46 store.py  5)     return PRICES[item]
70623c46 store.py  6) 
031c436c shop.py   7) def tax(amount):
031c436c shop.py   8)     """Work out the sales tax on an amount."""
57f176d2 shop.py   9)     return amount * 0.20
70623c46 store.py 10) 
70623c46 store.py 11) def total(items):
70623c46 store.py 12)     subtotal = sum(price(i) for i in items)
57f176d2 shop.py  13)     return subtotal + tax(subtotal)
$ git blame -s --reverse v2 -- nosuch.py
fatal: no such path nosuch.py in v2
```

The lines are `v1`'s. Each is marked with the last commit in the range where it
still existed. Lines 9 and 13 lasted until Alan's commit and were changed by the
next one, the formatting. Line 1 was changed straight after `v1`, so it shows
the boundary. The rest survived to `v2`, the end of the range.

Without `..`, the range runs to `HEAD`, as Git's documentation says. There the
`tax` lines ended at `031c436c`, before they moved to `tax.py`, and the lines
still present are marked with the last commit, the merge, under the new name.
The path must exist at the start of the range.

## Blaming a history you describe

`-S <revs-file>` makes blame use the parents written in a file instead of the
real ones. Git's source describes the format, one commit and then its parents on
each line, and says the option mainly serves `git cvsserver`, which gives a
straight line of history to old CVS clients. This file claims that `v2`'s parent
is the commit before `Format the code`:

```console
$ cat ../history.txt
031c436cc293a368e4f43e11ba57c53d21e89520 57f176d299db8476292bbbd00a44ba3295dba9e7
57f176d299db8476292bbbd00a44ba3295dba9e7 7cdf4650a7e47d2bfdc1919484cec56b54c14a0c
7cdf4650a7e47d2bfdc1919484cec56b54c14a0c ecaff393523018e79d3a560eedff0145d27e7089
ecaff393523018e79d3a560eedff0145d27e7089
$ git blame -s -S ../history.txt v2 -- shop.py
031c436c  1) # Prices in pounds.
031c436c  2) PRICES = {"tea": 3, "cake": 5, "pie": 4}
^ecaff39  3) 
^ecaff39  4) def price(item):
^ecaff39  5)     """Look up the price of one item."""
^ecaff39  6)     return PRICES[item]
^ecaff39  7) 
031c436c  8) def discount(amount):
031c436c  9)     """Take a pound off for loyal customers."""
031c436c 10)     return amount - 1
031c436c 11) 
^ecaff39 12) def tax(amount):
^ecaff39 13)     """Work out the sales tax on an amount."""
031c436c 14)     return amount*0.20
^ecaff39 15) 
^ecaff39 16) def total(items):
^ecaff39 17)     subtotal = sum(price(i) for i in items)
031c436c 18)     return subtotal+tax(subtotal)
```

In that history `v2` made every change the formatting commit made, so its lines
are blamed on `v2`. `git rev-list --parents` prints this format for a real
history (Chapter 22). It is rarely needed; `--ignore-rev` is the everyday way to
look past a commit.

## Names, encodings and diff algorithms

```console
$ cat .mailmap
Grace Hopper <grace@navy.example> <grace@example.com>
$ git blame -e -L 1,2 store.py
1f244fe3 shop.py (<grace@navy.example> 2026-01-05 12:00:00 +0000 1) # Prices in pounds.
1f244fe3 shop.py (<grace@navy.example> 2026-01-05 12:00:00 +0000 2) PRICES = {"tea": 3, "cake": 5, "pie": 4}
$ git blame -L 1,2 store.py
1f244fe3 shop.py (Grace Hopper 2026-01-05 12:00:00 +0000 1) # Prices in pounds.
1f244fe3 shop.py (Grace Hopper 2026-01-05 12:00:00 +0000 2) PRICES = {"tea": 3, "cake": 5, "pie": 4}
```

Blame applies `.mailmap`, so Grace's old address was shown as her new one
(Chapter 22 covers the file).

The next commit was made by `Zoë Quill`, whose name is stored in ISO-8859-1
rather than UTF-8 (Chapter 17 shows such a commit with `git log`):

```console
$ git blame -L 1,1 store.py | cat -A
4e5731c2 (ZoM-CM-+ Quill 2026-01-05 20:00:00 +0000 1) # Prices in pounds sterling.$
$ git blame --encoding=none -L 1,1 store.py | cat -A
4e5731c2 (ZoM-k Quill 2026-01-05 20:00:00 +0000 1) # Prices in pounds sterling.$
$ git blame --encoding=ISO-8859-1 -L 1,1 store.py | cat -A
4e5731c2 (ZoM-k Quill 2026-01-05 20:00:00 +0000 1) # Prices in pounds sterling.$
```

`cat -A` shows the bytes: `ë` is two bytes in UTF-8, `M-CM-+`, and one in
ISO-8859-1, `M-k`. Blame converted the name to UTF-8 by default. `--encoding`
asks for another encoding, and `none` prints the bytes as stored.

In the example Chapter 13 uses for diff algorithms, Grace replaced a function
`fact` with `fib` above `frobnitz`, which she did not change:

```console
$ git blame -s --diff-algorithm=myers -L 12,20 frob.c
26bf0c6f 12) // Frobs foo heartily
26bf0c6f 13) int frobnitz(int foo)
^035bc7c 14) {
26bf0c6f 15)     int i;
26bf0c6f 16)     for(i = 0; i < 10; i++)
^035bc7c 17)     {
26bf0c6f 18)         printf("%d\n", foo);
^035bc7c 19)     }
^035bc7c 20) }
$ git blame -s --diff-algorithm=histogram -L 12,20 frob.c
^035bc7c 12) // Frobs foo heartily
^035bc7c 13) int frobnitz(int foo)
^035bc7c 14) {
^035bc7c 15)     int i;
^035bc7c 16)     for(i = 0; i < 10; i++)
^035bc7c 17)     {
^035bc7c 18)         printf("%d\n", foo);
^035bc7c 19)     }
^035bc7c 20) }
$ git -c diff.algorithm=histogram blame -s -L 12,20 frob.c
^035bc7c 12) // Frobs foo heartily
^035bc7c 13) int frobnitz(int foo)
^035bc7c 14) {
^035bc7c 15)     int i;
^035bc7c 16)     for(i = 0; i < 10; i++)
^035bc7c 17)     {
^035bc7c 18)         printf("%d\n", foo);
^035bc7c 19)     }
^035bc7c 20) }
```

Blame compares versions with a diff, so the diff's choices become blame's. The
default, `myers`, matched lines wrongly and gave most of `frobnitz` to Grace;
`histogram` kept it with its author. `diff.algorithm` applies to blame too.
Chapter 13 describes each algorithm.

## Colour

```console
$ git blame --color-lines -L 3,5 store.py | cat -A
^ecaff39 shop.py (Ada Lovelace 2026-01-05 09:00:00 +0000 3) $
^[[36m^ecaff39 shop.py (Ada Lovelace 2026-01-05 09:00:00 +0000 4) ^[[mdef price(item):$
^[[36m^ecaff39 shop.py (Ada Lovelace 2026-01-05 09:00:00 +0000 5) ^[[m    """Look up the price of one item."""$
```

Unlike most colour in Git, these options colour even when the output goes into
a pipe or a file, as `cat -A` shows with `^[[36m`; the sandbox has colour turned
off, and the codes still appeared. On a terminal they look like this:

```ansi
$ git blame --color-lines -L 1,9 store.py
4e5731c2 store.py (Zoë Quill    2026-01-05 20:00:00 +0000 1) # Prices in pounds sterling.
1f244fe3 shop.py  (Grace Hopper 2026-01-05 12:00:00 +0000 2) PRICES = {"tea": 3, "cake": 5, "pie": 4}
^ecaff39 shop.py  (Ada Lovelace 2026-01-05 09:00:00 +0000 3) 
\e[36m^ecaff39 shop.py  (Ada Lovelace 2026-01-05 09:00:00 +0000 4) \e[mdef price(item):
\e[36m^ecaff39 shop.py  (Ada Lovelace 2026-01-05 09:00:00 +0000 5) \e[m    """Look up the price of one item."""
\e[36m^ecaff39 shop.py  (Ada Lovelace 2026-01-05 09:00:00 +0000 6) \e[m    return PRICES[item]
\e[36m^ecaff39 shop.py  (Ada Lovelace 2026-01-05 09:00:00 +0000 7) \e[m
031c436c shop.py  (Ada Lovelace 2026-01-05 13:00:00 +0000 8) def discount(amount):
\e[36m031c436c shop.py  (Ada Lovelace 2026-01-05 13:00:00 +0000 9) \e[m    """Take a pound off for loyal customers."""
$ git -c color.blame.repeatedLines=magenta blame --color-lines -L 3,5 store.py
^ecaff39 shop.py (Ada Lovelace 2026-01-05 09:00:00 +0000 3) 
\e[35m^ecaff39 shop.py (Ada Lovelace 2026-01-05 09:00:00 +0000 4) \e[mdef price(item):
\e[35m^ecaff39 shop.py (Ada Lovelace 2026-01-05 09:00:00 +0000 5) \e[m    """Look up the price of one item."""
$ git -c blame.coloring=repeatedLines blame -L 3,5 store.py
^ecaff39 shop.py (Ada Lovelace 2026-01-05 09:00:00 +0000 3) 
\e[36m^ecaff39 shop.py (Ada Lovelace 2026-01-05 09:00:00 +0000 4) \e[mdef price(item):
\e[36m^ecaff39 shop.py (Ada Lovelace 2026-01-05 09:00:00 +0000 5) \e[m    """Look up the price of one item."""
```

`--color-lines` colours the details of a line that came from the same commit as
the line above, cyan by default, which makes each commit's block stand out.
`color.blame.repeatedLines` changes the colour, and `blame.coloring` set to
`repeatedLines` turns it on without the option.

```ansi
$ git blame --color-by-age -L 1,9 store.py
\e[31m4e5731c2 store.py (Zoë Quill    2026-01-05 20:00:00 +0000 1) \e[m# Prices in pounds sterling.
\e[31m1f244fe3 shop.py  (Grace Hopper 2026-01-05 12:00:00 +0000 2) \e[mPRICES = {"tea": 3, "cake": 5, "pie": 4}
\e[31m^ecaff39 shop.py  (Ada Lovelace 2026-01-05 09:00:00 +0000 3) \e[m
\e[31m^ecaff39 shop.py  (Ada Lovelace 2026-01-05 09:00:00 +0000 4) \e[mdef price(item):
\e[31m^ecaff39 shop.py  (Ada Lovelace 2026-01-05 09:00:00 +0000 5) \e[m    """Look up the price of one item."""
\e[31m^ecaff39 shop.py  (Ada Lovelace 2026-01-05 09:00:00 +0000 6) \e[m    return PRICES[item]
\e[31m^ecaff39 shop.py  (Ada Lovelace 2026-01-05 09:00:00 +0000 7) \e[m
\e[31m031c436c shop.py  (Ada Lovelace 2026-01-05 13:00:00 +0000 8) \e[mdef discount(amount):
\e[31m031c436c shop.py  (Ada Lovelace 2026-01-05 13:00:00 +0000 9) \e[m    """Take a pound off for loyal customers."""
$ git -c color.blame.highlightRecent='blue,6 hours ago,red' blame --color-by-age -L 1,9 store.py
\e[31m4e5731c2 store.py (Zoë Quill    2026-01-05 20:00:00 +0000 1) \e[m# Prices in pounds sterling.
\e[34m1f244fe3 shop.py  (Grace Hopper 2026-01-05 12:00:00 +0000 2) \e[mPRICES = {"tea": 3, "cake": 5, "pie": 4}
\e[34m^ecaff39 shop.py  (Ada Lovelace 2026-01-05 09:00:00 +0000 3) \e[m
\e[34m^ecaff39 shop.py  (Ada Lovelace 2026-01-05 09:00:00 +0000 4) \e[mdef price(item):
\e[34m^ecaff39 shop.py  (Ada Lovelace 2026-01-05 09:00:00 +0000 5) \e[m    """Look up the price of one item."""
\e[34m^ecaff39 shop.py  (Ada Lovelace 2026-01-05 09:00:00 +0000 6) \e[m    return PRICES[item]
\e[34m^ecaff39 shop.py  (Ada Lovelace 2026-01-05 09:00:00 +0000 7) \e[m
\e[34m031c436c shop.py  (Ada Lovelace 2026-01-05 13:00:00 +0000 8) \e[mdef discount(amount):
\e[34m031c436c shop.py  (Ada Lovelace 2026-01-05 13:00:00 +0000 9) \e[m    """Take a pound off for loyal customers."""
$ git -c blame.coloring=highlightRecent blame -L 1,3 store.py
\e[31m4e5731c2 store.py (Zoë Quill    2026-01-05 20:00:00 +0000 1) \e[m# Prices in pounds sterling.
\e[31m1f244fe3 shop.py  (Grace Hopper 2026-01-05 12:00:00 +0000 2) \e[mPRICES = {"tea": 3, "cake": 5, "pie": 4}
\e[31m^ecaff39 shop.py  (Ada Lovelace 2026-01-05 09:00:00 +0000 3) \e[m
```

`--color-by-age` colours each line by the date of its commit.
`color.blame.highlightRecent` is a list of colours and dates from oldest to
newest: a line older than a date takes the colour before it. The default, as
Git's documentation gives it, is `blue,12 month ago,white,1 month ago,red`, so
every line here, all written today, is red. With `blue,6 hours ago,red` only the
latest commit stayed red. `blame.coloring` set to `highlightRecent` turns this
on by default.

## blame and its neighbours

| Command | Answers | Use it when |
|---|---|---|
| `git blame <file>` | which commit last changed each line now | you are looking at a line and want its history |
| `git log -L <range>:<file>` | every commit that changed those lines, with the diffs (Chapter 17) | you want the whole story of a function, not the last step |
| `git log -S <text>` | which commits added or removed a piece of text (Chapter 21) | the line is gone, or you are searching for code rather than looking at it |
| `git show <commit>` | what that commit changed, and why (Chapter 18) | blame gave you a hash |
| `git annotate <file>` | the same as `git blame -c` | an older script expects its layout |

A common sequence is blame for the hash, `git show` for the commit, then
`git blame <hash>^ -- <file>` to blame the version just before it and keep going
back.

## The settings

| Setting | Effect |
|---|---|
| `blame.date` | Date format; ISO when unset |
| `blame.showEmail` | Show emails instead of names; `false` by default |
| `blame.blankBoundary` | Blank the hash of boundary commits; `false` by default |
| `blame.showRoot` | Do not treat root commits as boundaries; `false` by default |
| `blame.ignoreRevsFile` | A file of commits to ignore; may be given several times, and an empty value clears the list |
| `blame.markIgnoredLines` | Mark lines passed on from an ignored commit with `?` |
| `blame.markUnblamableLines` | Mark lines an ignored commit could not pass on with `*` |
| `blame.coloring` | `repeatedLines`, `highlightRecent` or `none`, the default |
| `color.blame.repeatedLines` | Colour for `--color-lines`; cyan by default |
| `color.blame.highlightRecent` | Colours and dates for `--color-by-age` |
| `diff.algorithm` | The diff algorithm blame uses (Chapter 13) |
| `core.abbrev` | Length of hashes (Chapter 17) |
