# Chapter 17. log

## What it is

`git log` lists commits. It starts from the commit you are on, prints it, moves
to its parent, prints that, and carries on until it runs out of parents. The
result is the history that led to where you are, newest first.

Everything else in this chapter changes one of four things: which commits are
listed, in what order, how each one is printed, and whether the changes inside
each commit are shown too. It never changes the repository.

Two terms are used throughout. A commit is *reachable* from another if you can
get to it by following parents, which is what "the history of a branch" means
(Chapter 7). And a *merge commit* has two or more parents (Chapter 6), which is
where history stops being a single line.

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What does `git log` show, and in what order?](#what-it-is)

**[Synopsis](#synopsis)**

- [What can I type after `git log`?](#synopsis)

**[Options at a glance](#options-at-a-glance)**

- [Is there a list of every option, and where each is explained?](#options-at-a-glance)

**[The example history](#the-example-history)**

- [What repository do the examples use?](#the-example-history)

**[Reading the output](#reading-the-output)**

- [What do the lines of `git log` output mean?](#reading-the-output)
- [Why does my `git log` show `(HEAD -> main)` and open a screen I have to quit?](#reading-the-output)
- [What does "does not have any commits yet" mean?](#reading-the-output)

**[Which commits log starts from](#which-commits-log-starts-from)**

- [How do I see the history of another branch without switching to it?](#which-commits-log-starts-from)
- [How do I list commits that are on one branch but not another?](#which-commits-log-starts-from)
- [How do I see the history of every branch at once?](#every-branch-tag-or-remote)
- [Why does `--glob=refs/tags/v1.1` show nothing?](#every-branch-tag-or-remote)
- [How do I show a few specific commits without their history?](#only-the-commits-named)
- [Why does `--no-walk` do nothing with `A..B`?](#only-the-commits-named)

**[How many commits](#how-many-commits)**

- [How do I show only the last few commits, or skip some?](#how-many-commits)
- [How do I see the first commits ever made?](#how-many-commits)

**[By date](#by-date)**

- [How do I see what was committed since yesterday, or between two dates?](#by-date)
- [What date formats can I give to `--since`?](#dates-git-understands)
- [I misspelled a date and log showed nothing, without an error. Why?](#dates-git-understands)
- [`--since=2026-01-05` shows nothing, although I committed that day. Why?](#dates-git-understands)
- [Is the time I give to `--since` in my time zone or in UTC?](#dates-git-understands)
- [`--since` missed commits I know are newer. Why?](#when-a-clock-was-wrong)

**[By author, committer or message](#by-author-committer-or-message)**

- [How do I see only one person's commits?](#by-author-committer-or-message)
- [How do I find commits whose message mentions an issue number?](#by-author-committer-or-message)
- [How do I search messages for two words at once, or exclude a word?](#by-author-committer-or-message)
- [Does `--grep` use regular expressions? Can I switch that off?](#by-author-committer-or-message)
- [My `--grep='(this|that)'` finds nothing. Why?](#by-author-committer-or-message)

**[Merge commits](#merge-commits)**

- [How do I hide merge commits, or show only them?](#merge-commits)
- [How do I see only the main line of history, without the commits merged in?](#merge-commits)
- [A topic was merged, so `main..topic` shows nothing. How do I still list its commits?](#merge-commits)

**[History of a file](#history-of-a-file)**

- [How do I see the commits that changed one file?](#history-of-a-file)
- [The history of my file stops at a rename. How do I see further back?](#history-of-a-file)
- [`--follow` still stops at the rename. Why?](#history-of-a-file)
- [How do I see the history of a file that no longer exists?](#history-of-a-file)
- [How do I find the commit that deleted or added a file?](#history-of-a-file)
- [`--stat -- file` only shows that file. How do I see everything that commit changed?](#history-of-a-file)

**[History of some lines](#history-of-some-lines)**

- [How do I see how one function changed over time?](#history-of-some-lines)
- [Why does my second `-L` say "no match"?](#history-of-some-lines)
- [Can I give `-L` a range counted backwards, or between two patterns?](#history-of-some-lines)
- [Why does `-L` refuse `--stat`?](#history-of-some-lines)

**[Simplified history](#simplified-history)**

- [I know a commit changed this file, but `git log file` doesn't show it. Why?](#simplified-history)
- [Which merge brought a change into my branch?](#simplified-history)
- [How do I see only the commits between two points that actually lead from one to the other?](#simplified-history)

**[Order](#order)**

- [Can I list history oldest first?](#order)
- [Why are commits from two branches mixed together in the list?](#order)
- [Why is a commit listed below its own parent?](#order)

**[Built-in formats](#built-in-formats)**

- [How do I get one line per commit?](#built-in-formats)
- [What do the `short`, `full`, `fuller`, `reference`, `email` and `raw` formats look like?](#built-in-formats)
- [How do I make my favourite format the default, or give it a name?](#built-in-formats)

**[Format strings](#format-strings)**

- [How do I print exactly the fields I want, such as hash, author and date?](#format-strings)
- [What is the difference between `format:` and `tformat:`?](#format-strings)
- [How do I print trailers such as `Refs:` from messages?](#placeholders-for-messages-trailers-and-names)
- [Why does `%(trailers)` print a line that is not a trailer?](#placeholders-for-messages-trailers-and-names)
- [How do I line up output in columns or cut long subjects?](#layout-colour-and-special-characters)
- [I used `%Cred` in my format and see no colour. Why?](#layout-colour-and-special-characters)

**[Dates](#dates)**

- [How do I show dates as ISO, as "3 hours ago", or in my own format?](#dates)
- [How do I see dates in my own time zone?](#dates)

**[Decorations](#decorations)**

- [What are the names in brackets after a hash, and how do I control them?](#decorations)
- [How do I see only the commits that have a branch or tag?](#decorations)

**[The graph](#the-graph)**

- [How do I see branches and merges as a drawing?](#the-graph)
- [How do I print each commit's parents or children?](#the-graph)
- [My graph is too wide. Can I limit it?](#the-graph)

**[Each commit's changes](#each-commit-s-changes)**

- [How do I see which files each commit changed, or its full diff?](#each-commit-s-changes)
- [I put `-s` after `--stat` and got no stat. Why?](#each-commit-s-changes)
- [Does `-q` hide the diff in `git log`?](#each-commit-s-changes)

**[Merges and their changes](#merges-and-their-changes)**

- [`git log -p` shows nothing for a merge commit. Why?](#merges-and-their-changes)
- [What do `-m`, `-c`, `--cc`, `--dd` and `--remerge-diff` show for a merge?](#merges-and-their-changes)
- [How can I see what someone changed while resolving a merge conflict?](#merges-and-their-changes)
- [Are `-c` and `--diff-merges=combined` the same thing?](#merges-and-their-changes)
- [`--diff-merges=first-parent` shows no diff for ordinary commits. Why?](#merges-and-their-changes)
- [Why does the first commit show every file as added?](#merges-and-their-changes)

**[Other options](#other-options)**

- [Why do tabs in my commit message look wrong?](#other-options)
- [Why does log show a different name than the one that made the commit?](#other-options)
- [Can log read revisions from a script, or ignore ones that don't exist?](#other-options)
- [My message is in an old encoding. How does log show it?](#other-options)
- [How do I list what a repository I borrow objects from has, or what a server hides?](#other-options)

**[log and its neighbours](#log-and-its-neighbours)**

- [Should I use `git log`, `git show`, `git rev-list`, `git shortlog` or `git reflog`?](#log-and-its-neighbours)
- [What happened to `git whatchanged`?](#log-and-its-neighbours)

**[The settings](#the-settings)**

- [Which settings change what `git log` shows by default?](#the-settings)

</details>

## Synopsis

```
git log [<options>] [<revision-range>] [[--] <path>...]
```

| Part | Means |
|---|---|
| `<revision-range>` | Where to start, and what to leave out. Without it, `HEAD`. Chapter 18 has every way to write one |
| `<path>` | Only commits that changed these paths |
| `--` | Everything after it is a path, even if a branch has the same name |

| Command | Shows |
|---|---|
| `git log` | The history of the current branch, in full |
| `git log --oneline` | The same, one line per commit |
| `git log <branch>` | The history of another branch |
| `git log A..B` | Commits reachable from `B` but not from `A` |
| `git log -- <path>` | Commits that changed `<path>` |
| `git log -p` | Each commit with its changes |
| `git log --oneline --graph --all` | Every branch, drawn as a graph |

## Options at a glance

### Choosing commits

| Option | Does | Covered in |
|---|---|---|
| `--all` | Start from every ref and `HEAD` | [Every branch, tag or remote](#every-branch-tag-or-remote) |
| `--branches[=<pattern>]` | Start from every branch, or those matching | [Every branch, tag or remote](#every-branch-tag-or-remote) |
| `--tags[=<pattern>]` | Start from every tag | [Every branch, tag or remote](#every-branch-tag-or-remote) |
| `--remotes[=<pattern>]` | Start from every remote-tracking branch | [Every branch, tag or remote](#every-branch-tag-or-remote) |
| `--glob=<pattern>` | Start from every ref matching a pattern | [Every branch, tag or remote](#every-branch-tag-or-remote) |
| `--exclude=<pattern>` | Leave refs out of the next `--all`, `--branches` and similar | [Every branch, tag or remote](#every-branch-tag-or-remote) |
| `--not` | Reverse the meaning of `^` for the refs that follow | [Which commits log starts from](#which-commits-log-starts-from) |
| `--no-walk[=(sorted\|unsorted)]`, `--do-walk` | Show only the commits named, not their history, or undo that | [Only the commits named](#only-the-commits-named) |
| `--maximal-only` | Show only commits no other listed commit can reach | [Only the commits named](#only-the-commits-named) |
| `-<n>`, `-n <n>`, `--max-count=<n>` | Show at most `<n>` commits | [How many commits](#how-many-commits) |
| `--max-count-oldest=<n>` | Show the oldest `<n>` commits | [How many commits](#how-many-commits) |
| `--skip=<n>` | Skip the first `<n>` commits | [How many commits](#how-many-commits) |
| `--since=<date>`, `--after=<date>` | Commits newer than a date | [By date](#by-date) |
| `--until=<date>`, `--before=<date>` | Commits older than a date | [By date](#by-date) |
| `--since-as-filter=<date>` | Like `--since`, but check every commit | [When a clock was wrong](#when-a-clock-was-wrong) |
| `--author=<pattern>` | Commits whose author matches | [By author, committer or message](#by-author-committer-or-message) |
| `--committer=<pattern>` | Commits whose committer matches | [By author, committer or message](#by-author-committer-or-message) |
| `--grep=<pattern>` | Commits whose message matches | [By author, committer or message](#by-author-committer-or-message) |
| `--all-match` | A commit must match every `--grep` | [By author, committer or message](#by-author-committer-or-message) |
| `--invert-grep` | Commits whose message does not match | [By author, committer or message](#by-author-committer-or-message) |
| `-i`, `--regexp-ignore-case` | Match patterns without regard to case | [By author, committer or message](#by-author-committer-or-message) |
| `--basic-regexp` | Patterns are basic regular expressions, the default | [By author, committer or message](#by-author-committer-or-message) |
| `-E`, `--extended-regexp` | Patterns are extended regular expressions | [By author, committer or message](#by-author-committer-or-message) |
| `-F`, `--fixed-strings` | Patterns are plain text | [By author, committer or message](#by-author-committer-or-message) |
| `-P`, `--perl-regexp` | Patterns are Perl-compatible regular expressions | [By author, committer or message](#by-author-committer-or-message) |
| `--merges` | Only merge commits | [Merge commits](#merge-commits) |
| `--no-merges` | No merge commits | [Merge commits](#merge-commits) |
| `--min-parents=<n>`, `--no-min-parents` | Commits with at least `<n>` parents, or no minimum | [Merge commits](#merge-commits) |
| `--max-parents=<n>`, `--no-max-parents` | Commits with at most `<n>` parents, or no maximum | [Merge commits](#merge-commits) |
| `--first-parent` | Follow only the first parent of each merge | [Merge commits](#merge-commits) |
| `--exclude-first-parent-only` | Follow only first parents when finding commits to leave out | [Merge commits](#merge-commits) |
| `--ignore-missing` | Ignore revisions that do not exist | [Other options](#other-options) |
| `--stdin` | Read revisions from standard input as well | [Other options](#other-options) |
| `--alternate-refs` | Also start from the branch tips of repositories this one borrows objects from | [Other options](#other-options) |
| `--exclude-hidden=(fetch\|receive\|uploadpack)` | Leave out refs a server is configured to hide | [Other options](#other-options) |

### Following files and lines

| Option | Does | Covered in |
|---|---|---|
| `--follow` | Follow one file across renames | [History of a file](#history-of-a-file) |
| `--full-diff` | With paths, show the whole diff of each commit found | [History of a file](#history-of-a-file) |
| `--remove-empty` | Stop where the path disappears | [History of a file](#history-of-a-file) |
| `-L <start>,<end>:<file>`, `-L :<funcname>:<file>` | Follow some lines, or a function, through history | [History of some lines](#history-of-some-lines) |
| `--full-history` | Do not prune merges that leave a file unchanged | [Simplified history](#simplified-history) |
| `--simplify-merges` | With `--full-history`, drop merges that add nothing | [Simplified history](#simplified-history) |
| `--show-pulls` | Also show the merges that brought a change in | [Simplified history](#simplified-history) |
| `--dense` | Show only commits that change the paths, the default | [Simplified history](#simplified-history) |
| `--sparse` | Show every commit walked | [Simplified history](#simplified-history) |
| `--ancestry-path[=<commit>]` | Only commits on a path between the ends of a range | [Simplified history](#simplified-history) |
| `--simplify-by-decoration` | Only commits that a branch or tag points to | [Decorations](#decorations) |

### Commit order

| Option | Does | Covered in |
|---|---|---|
| `--date-order` | Commit date order, never a parent before its children | [Order](#order) |
| `--author-date-order` | Author date order, never a parent before its children | [Order](#order) |
| `--topo-order` | Keep each line of history together | [Order](#order) |
| `--reverse` | Oldest first | [Order](#order) |

### Formatting

| Option | Does | Covered in |
|---|---|---|
| `--oneline` | One line per commit, short hash | [Built-in formats](#built-in-formats) |
| `--pretty=oneline` | Full hash and subject on one line | [Built-in formats](#built-in-formats) |
| `--pretty=short` | Hash, author and subject | [Built-in formats](#built-in-formats) |
| `--pretty=medium`, `--pretty` | The default | [Built-in formats](#built-in-formats) |
| `--pretty=full` | Author and committer, no dates | [Built-in formats](#built-in-formats) |
| `--pretty=fuller` | Author, committer and both dates | [Built-in formats](#built-in-formats) |
| `--pretty=reference` | Short hash, subject and date, for quoting a commit | [Built-in formats](#built-in-formats) |
| `--pretty=email` | Shaped like an email | [Built-in formats](#built-in-formats) |
| `--pretty=mboxrd` | Like `email`, with lines starting "From " quoted | [Built-in formats](#built-in-formats) |
| `--pretty=raw` | The commit object as stored | [Built-in formats](#built-in-formats) |
| `--pretty=format:<string>` | Your own format, with a newline between commits | [Format strings](#format-strings) |
| `--pretty=tformat:<string>`, `--format=<string>` | Your own format, with a newline after each commit | [Format strings](#format-strings) |
| `--abbrev-commit`, `--no-abbrev-commit` | Short or full commit hashes | [Built-in formats](#built-in-formats) |
| `--abbrev=<n>` | Hash length | [Built-in formats](#built-in-formats) |
| `--date=default` | `Thu Jan 1 10:00:00 2026 +0330` | [Dates](#dates) |
| `--date=relative`, `--relative-date` | `5 days ago` | [Dates](#dates) |
| `--date=local` | The default format, in your time zone | [Dates](#dates) |
| `--date=iso`, `--date=iso8601` | `2026-01-01 10:00:00 +0330` | [Dates](#dates) |
| `--date=iso-strict`, `--date=iso8601-strict` | `2026-01-01T10:00:00+03:30` | [Dates](#dates) |
| `--date=rfc`, `--date=rfc2822` | `Thu, 1 Jan 2026 10:00:00 +0330` | [Dates](#dates) |
| `--date=short` | `2026-01-01` | [Dates](#dates) |
| `--date=raw` | `1767249000 +0330` | [Dates](#dates) |
| `--date=unix` | `1767249000` | [Dates](#dates) |
| `--date=human` | Shorter the more recent the date | [Dates](#dates) |
| `--date=format:<strftime>` | Your own date format | [Dates](#dates) |
| `--date=<format>-local` | Any of the above in your time zone | [Dates](#dates) |
| `--decorate`, `--decorate=short` | Show branch and tag names | [Decorations](#decorations) |
| `--decorate=full` | Show them in full, `refs/heads/main` | [Decorations](#decorations) |
| `--decorate=auto` | Show them only on a terminal, the default | [Decorations](#decorations) |
| `--decorate=no`, `--no-decorate` | Do not show them | [Decorations](#decorations) |
| `--decorate-refs=<pattern>`, `--decorate-refs-exclude=<pattern>` | Choose which refs to show | [Decorations](#decorations) |
| `--clear-decorations` | Show every kind of ref | [Decorations](#decorations) |
| `--source` | Show which ref each commit was reached from | [Format strings](#format-strings) |
| `--graph` | Draw the history | [The graph](#the-graph) |
| `--graph-lane-limit=<n>` | Draw at most `<n>` lanes | [The graph](#the-graph) |
| `--parents`, `--children` | Print parent or child hashes | [The graph](#the-graph) |
| `--show-linear-break[=<barrier>]` | Mark where one line of history ends, without a graph | [The graph](#the-graph) |
| `--log-size` | Print each message's size in bytes | [Other options](#other-options) |
| `--expand-tabs[=<n>]`, `--no-expand-tabs` | Expand tabs in messages, or not | [Other options](#other-options) |
| `--encoding=<encoding>` | Re-encode messages | [Other options](#other-options) |
| `--mailmap`, `--use-mailmap`, `--no-mailmap`, `--no-use-mailmap` | Apply `.mailmap` to names, or not | [Other options](#other-options) |

### Showing changes

| Option | Does | Covered in |
|---|---|---|
| `-p`, `--patch` | Show each commit's changes | [Each commit's changes](#each-commit-s-changes) |
| `--stat`, `--name-only`, `--name-status` | Summaries of each commit's changes, as in Chapter 13 | [Each commit's changes](#each-commit-s-changes) |
| `-s`, `--no-patch` | Turn off diff output given earlier | [Each commit's changes](#each-commit-s-changes) |
| `--raw` | One line per changed file, with modes and hashes | [Each commit's changes](#each-commit-s-changes) |
| `-t` | With `--raw`, list the changed directories too | [Each commit's changes](#each-commit-s-changes) |
| `-q`, `--quiet` | Listed as "suppress diff output"; no effect on `git log` | [Each commit's changes](#each-commit-s-changes) |
| `--diff-filter=<letters>` | Only commits with changes of these kinds | [History of a file](#history-of-a-file) |
| `-S<string>`, `-G<regex>` | Commits that add or remove text | Chapter 13 |
| `-m` | Show merges in the default merge format, with `-p` | [Merges and their changes](#merges-and-their-changes) |
| `--diff-merges=off`, `--diff-merges=none`, `--no-diff-merges` | No diff for merges, the default | [Merges and their changes](#merges-and-their-changes) |
| `--diff-merges=on`, `--diff-merges=m` | Merges in the format `log.diffMerges` names | [Merges and their changes](#merges-and-their-changes) |
| `--diff-merges=separate` | One diff against each parent | [Merges and their changes](#merges-and-their-changes) |
| `--diff-merges=first-parent`, `--diff-merges=1`, `--dd` | One diff against the first parent | [Merges and their changes](#merges-and-their-changes) |
| `--diff-merges=combined`, `--diff-merges=c`, `-c` | A combined diff | [Merges and their changes](#merges-and-their-changes) |
| `--diff-merges=dense-combined`, `--diff-merges=cc`, `--cc` | A combined diff without uninteresting hunks | [Merges and their changes](#merges-and-their-changes) |
| `--diff-merges=remerge`, `--diff-merges=r`, `--remerge-diff` | How the result differs from redoing the merge | [Merges and their changes](#merges-and-their-changes) |
| `--combined-all-paths` | Name every parent's path in a combined diff | [Merges and their changes](#merges-and-their-changes) |

### Options covered in other chapters

| Option | Does | Covered in |
|---|---|---|
| `--left-right`, `--left-only`, `--right-only` | Mark or pick the sides of `A...B` | Chapter 18 |
| `--cherry-pick`, `--cherry-mark`, `--cherry` | Leave out or mark commits applied to both sides | Chapter 18 |
| `--boundary` | Also show the commits just outside a range | Chapter 18 |
| `-g`, `--walk-reflogs`, `--grep-reflog=<pattern>`, `--reflog` | Walk the reflog instead of parents | Chapter 36 |
| `--bisect` | The commits still in question during a bisect | Chapter 20 |
| `--merge` | Commits touching paths in conflict | Chapter 26 |
| `--notes[=<ref>]`, `--no-notes`, `--show-notes-by-default` | Show notes attached to commits | Chapter 38 |
| `--show-notes[=<ref>]`, `--standard-notes`, `--no-standard-notes` | Older spellings of the notes options, which Git's documentation calls deprecated | Chapter 38 |
| `--show-signature` | Check each commit's signature | Chapter 68 |
| `--single-worktree` | Look only at this working tree's refs | Chapter 56 |

## The example history

Most examples use one small repository: a calculator written by three people,
with a branch that was merged, a renamed file, two tags, and a remote whose
`main` stopped at the first tag. Here is its whole history. `--oneline` prints
each commit as a short hash and the first line of its message, `--all` includes
every branch and tag instead of only the current branch, and `--graph` draws the
lines between commits, as [The graph](#the-graph) explains:

```console
$ git log --oneline --graph --all
* 9f9d4d2 A commit with a wrong clock
* 758934f Backport logging notes
* cc42788 Add divide
* f83a6b7 Rename the test file
*   e2f0758 Merge branch 'feature'
|\  
| * ff8f73f Document multiply
| * ba5c7a0 Add multiply
* | 7b32ffd Fix subtraction
|/  
* e1e8cdc Add tests
* f47fa3b Add the calculator
* c44dc25 Add README
```

`A commit with a wrong clock` is on a branch of its own called `wrong-clock`, and
`Backport logging notes` was written on 1 January in a time zone of +03:30 and
committed on 5 January. Both matter in [By date](#by-date). In this repository it
is now 19:00 on 5 January 2026, an hour after the last commit, and relative dates
such as "3 hours ago" count from then.

## Reading the output

```console
$ git log -3
commit 758934f771cbd277828115b51855b772bdbd3a69
Author: Alan Turing <alan@example.com>
Date:   Thu Jan 1 10:00:00 2026 +0330

    Backport logging notes

commit cc427888f2333ae3ad689bbb443909de24f9f485
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 17:00:00 2026 +0000

    Add divide
    
    Dividing by zero raises ZeroDivisionError.

commit f83a6b70dddf7d32be53a3537e35939f43492d07
Author: Grace Hopper <grace@example.com>
Date:   Mon Jan 5 16:00:00 2026 +0000

    Rename the test file
```

| Line | Is |
|---|---|
| `commit <hash>` | The commit's full hash (Chapter 4) |
| `Merge: <hash> <hash>` | Only on a merge commit: its parents, abbreviated |
| `Author:` | Who wrote the change |
| `Date:` | When it was written: the *author* date, not when it was committed (Chapter 12) |
| the indented text | The message, indented by four spaces |

`-3` limited the list to three commits. The first line of each message is its
*subject*; anything after the blank line is the *body*.

> **Worth knowing.** On your screen `git log` looks different in two ways from
> the transcripts. It adds branch and tag names, such as
> `commit 758934f... (HEAD -> main)`, and it shows long output one screen at a
> time in a *pager*, normally `less`, where you press `q` to get back to the
> prompt. Git does both only when writing to a terminal, and the sandbox is not
> one (Chapter 2). [Decorations](#decorations) shows the names, and Chapter 13 has
> [the keys for the pager](#ch13-the-pager).

In a repository with no commits there is nothing to walk:

```console
$ git log
fatal: your current branch 'main' does not have any commits yet
```

## Which commits log starts from

```console
$ git log --oneline
758934f Backport logging notes
cc42788 Add divide
f83a6b7 Rename the test file
e2f0758 Merge branch 'feature'
7b32ffd Fix subtraction
ff8f73f Document multiply
ba5c7a0 Add multiply
e1e8cdc Add tests
f47fa3b Add the calculator
c44dc25 Add README
$ git log --oneline feature
ff8f73f Document multiply
ba5c7a0 Add multiply
e1e8cdc Add tests
f47fa3b Add the calculator
c44dc25 Add README
$ git log --oneline feature main
758934f Backport logging notes
cc42788 Add divide
f83a6b7 Rename the test file
e2f0758 Merge branch 'feature'
7b32ffd Fix subtraction
ff8f73f Document multiply
ba5c7a0 Add multiply
e1e8cdc Add tests
f47fa3b Add the calculator
c44dc25 Add README
```

Without a starting point, log starts from `HEAD`. Name a branch and it starts
there instead, without switching to it. Name two and it lists everything
reachable from either, each commit once.

A `^` in front of a name takes that name's history away:

```console
$ git log --oneline main ^feature
758934f Backport logging notes
cc42788 Add divide
f83a6b7 Rename the test file
e2f0758 Merge branch 'feature'
7b32ffd Fix subtraction
$ git log --oneline feature..main
758934f Backport logging notes
cc42788 Add divide
f83a6b7 Rename the test file
e2f0758 Merge branch 'feature'
7b32ffd Fix subtraction
$ git log --oneline --not feature --not main
758934f Backport logging notes
cc42788 Add divide
f83a6b7 Rename the test file
e2f0758 Merge branch 'feature'
7b32ffd Fix subtraction
$ git log --oneline origin/main..main
758934f Backport logging notes
cc42788 Add divide
f83a6b7 Rename the test file
e2f0758 Merge branch 'feature'
7b32ffd Fix subtraction
ff8f73f Document multiply
ba5c7a0 Add multiply
```

`main ^feature` is "what `main` has that `feature` does not", and `feature..main`
is a shorter way to write exactly that, as Git's documentation says. `--not`
reverses `^` for every name after it until the next `--not`, so here it put `^`
on `feature` and the second `--not` switched it off again for `main`.

`origin/main..main` is the everyday use: the commits on your `main` that the
server's `main` does not have yet, as far as your last fetch knows (Chapter 41).
Chapter 18 covers `..`, `...` and every other way to write a range.

### Every branch, tag or remote

```console
$ git log --oneline --tags
cc42788 Add divide
f83a6b7 Rename the test file
e2f0758 Merge branch 'feature'
7b32ffd Fix subtraction
ff8f73f Document multiply
ba5c7a0 Add multiply
e1e8cdc Add tests
f47fa3b Add the calculator
c44dc25 Add README
$ git log --oneline --remotes
e1e8cdc Add tests
f47fa3b Add the calculator
c44dc25 Add README
```

`--tags` starts from every tag, so the commit made after `v1.1` is missing.
`--remotes` starts from every remote-tracking branch; `origin/main` is at
`v1.0`. `--all` and `--branches` work the same way, from every ref and every
branch:

```console
$ git log --oneline --all
758934f Backport logging notes
cc42788 Add divide
f83a6b7 Rename the test file
e2f0758 Merge branch 'feature'
7b32ffd Fix subtraction
ff8f73f Document multiply
ba5c7a0 Add multiply
e1e8cdc Add tests
f47fa3b Add the calculator
c44dc25 Add README
$ git log --oneline --branches
758934f Backport logging notes
cc42788 Add divide
f83a6b7 Rename the test file
e2f0758 Merge branch 'feature'
7b32ffd Fix subtraction
ff8f73f Document multiply
ba5c7a0 Add multiply
e1e8cdc Add tests
f47fa3b Add the calculator
c44dc25 Add README
$ git log --oneline --branches='old*'
ff8f73f Document multiply
ba5c7a0 Add multiply
e1e8cdc Add tests
f47fa3b Add the calculator
c44dc25 Add README
```

None of these list `A commit with a wrong clock`: the branch `wrong-clock` was
created after them, for [When a clock was wrong](#when-a-clock-was-wrong). Each
option also takes a pattern, as `--branches='old*'` did for the branch
`old-feature`.

A pattern with no `*`, `?` or `[` in it gets `/*` added, according to Git's
documentation, which surprises anyone who names one ref exactly:

```console
$ git log --oneline --glob='refs/tags/v1.1'
$ git log --oneline --glob='refs/tags/v1.[1]'
cc42788 Add divide
f83a6b7 Rename the test file
e2f0758 Merge branch 'feature'
7b32ffd Fix subtraction
ff8f73f Document multiply
ba5c7a0 Add multiply
e1e8cdc Add tests
f47fa3b Add the calculator
c44dc25 Add README
$ git log --oneline --glob='tags/v1.1*'
cc42788 Add divide
f83a6b7 Rename the test file
e2f0758 Merge branch 'feature'
7b32ffd Fix subtraction
ff8f73f Document multiply
ba5c7a0 Add multiply
e1e8cdc Add tests
f47fa3b Add the calculator
c44dc25 Add README
$ git log --oneline --exclude=main --branches
ff8f73f Document multiply
ba5c7a0 Add multiply
e1e8cdc Add tests
f47fa3b Add the calculator
c44dc25 Add README
```

`refs/tags/v1.1` became `refs/tags/v1.1/*`, which matches nothing, and log
printed nothing without complaint. Any wildcard stops that. `--glob` adds
`refs/` when it is missing. `--exclude` removes refs from the next `--all`,
`--branches`, `--tags`, `--remotes` or `--glob` only, and here left the two
feature branches.

A name that is not a revision is an error:

```console
$ git log --oneline nosuch
fatal: ambiguous argument 'nosuch': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
```

"Ambiguous" because `nosuch` could also have been a file name; [History of a
file](#history-of-a-file) comes back to that.

### Only the commits named

```console
$ git log --oneline --no-walk v1.0 v1.1 feature
cc42788 Add divide
ff8f73f Document multiply
e1e8cdc Add tests
$ git log --oneline --no-walk=unsorted v1.1 v1.0
cc42788 Add divide
e1e8cdc Add tests
$ git log --oneline --no-walk --do-walk v1.0
e1e8cdc Add tests
f47fa3b Add the calculator
c44dc25 Add README
$ git log --oneline --no-walk feature..main
758934f Backport logging notes
cc42788 Add divide
f83a6b7 Rename the test file
e2f0758 Merge branch 'feature'
7b32ffd Fix subtraction
$ git log --oneline --maximal-only --all
758934f Backport logging notes
```

`--no-walk` shows the named commits and none of their parents, newest first, or
in the order given with `=unsorted`. `--do-walk` cancels it. With a range,
`--no-walk` has no effect, as Git's documentation warns. `--maximal-only`
keeps only commits that no other commit in the list can reach: of everything
`--all` found, only the newest, because every other commit is in its history.

> **Since Git 2.54.** `--maximal-only`.

## How many commits

```console
$ git log --oneline -2
758934f Backport logging notes
cc42788 Add divide
$ git log --oneline -n 2
758934f Backport logging notes
cc42788 Add divide
$ git log --oneline --max-count=2
758934f Backport logging notes
cc42788 Add divide
$ git log --oneline --skip=2 -2
f83a6b7 Rename the test file
e2f0758 Merge branch 'feature'
$ git log --oneline --max-count-oldest=2
f47fa3b Add the calculator
c44dc25 Add README
$ git log --oneline --reverse -2
cc42788 Add divide
758934f Backport logging notes
$ git log --oneline -2 --reverse --max-count-oldest=2
fatal: options '--max-count' and '--max-count-oldest' cannot be used together
```

`-2`, `-n 2` and `--max-count=2` are three spellings of one limit. `--skip`
skips before counting. `--max-count-oldest` keeps the oldest commits instead,
still listed newest first.

`--reverse` does not find the oldest commits: it reverses the list after it has
been cut. `-2 --reverse` gave the newest two, oldest of those first. Git's documentation
says so for every option that limits which commits are shown: they apply before
ordering options such as `--reverse`.

> **Since Git 2.55.** `--max-count-oldest`.

## By date

```console
$ git log --format='%h %ad %s' --date=iso
758934f 2026-01-01 10:00:00 +0330 Backport logging notes
cc42788 2026-01-05 17:00:00 +0000 Add divide
f83a6b7 2026-01-05 16:00:00 +0000 Rename the test file
e2f0758 2026-01-05 15:00:00 +0000 Merge branch 'feature'
7b32ffd 2026-01-05 14:00:00 +0000 Fix subtraction
ff8f73f 2026-01-05 13:00:00 +0000 Document multiply
ba5c7a0 2026-01-05 12:00:00 +0000 Add multiply
e1e8cdc 2026-01-05 11:00:00 +0000 Add tests
f47fa3b 2026-01-05 10:00:00 +0000 Add the calculator
c44dc25 2026-01-05 09:00:00 +0000 Add README
$ git log --oneline --since='2026-01-05 13:00'
758934f Backport logging notes
cc42788 Add divide
f83a6b7 Rename the test file
e2f0758 Merge branch 'feature'
7b32ffd Fix subtraction
ff8f73f Document multiply
$ git log --oneline --after='2026-01-05 13:00'
758934f Backport logging notes
cc42788 Add divide
f83a6b7 Rename the test file
e2f0758 Merge branch 'feature'
7b32ffd Fix subtraction
ff8f73f Document multiply
$ git log --oneline --until='2026-01-05 11:30'
e1e8cdc Add tests
f47fa3b Add the calculator
c44dc25 Add README
$ git log --oneline --before='2026-01-05 11:30'
e1e8cdc Add tests
f47fa3b Add the calculator
c44dc25 Add README
```

The first command prints each commit's author date, in a format explained in
[Format strings](#format-strings). `--since` and `--after` are the same option,
and so are `--until` and `--before`. A commit made exactly at the time given
counts as inside.

Both compare the *committer* date, not the author date that log prints. That is
why `Backport logging notes`, written on 1 January but committed on 5 January at
18:00, counted as newer than 13:00. Chapter 12 explains the two dates.

### Dates Git understands

```console
$ git log --oneline --since='3 hours ago'
758934f Backport logging notes
cc42788 Add divide
f83a6b7 Rename the test file
$ git log --oneline --until=yesterday
$ git log --oneline --since=today
758934f Backport logging notes
cc42788 Add divide
f83a6b7 Rename the test file
e2f0758 Merge branch 'feature'
7b32ffd Fix subtraction
ff8f73f Document multiply
ba5c7a0 Add multiply
e1e8cdc Add tests
f47fa3b Add the calculator
c44dc25 Add README
$ git log --oneline --since='2026-01-05 12:30' --until='2026-01-05 15:30'
e2f0758 Merge branch 'feature'
7b32ffd Fix subtraction
ff8f73f Document multiply
$ git log --oneline --since=nonsense
$ git log --oneline --until=nonsense -2
758934f Backport logging notes
cc42788 Add divide
```

"3 hours ago" counted back from 19:00. Every commit was made today, so
`--until=yesterday` found none. `today`, as Git's documentation puts it, means
the last midnight, and every commit was made after it. The two options together give a window.

The last two are the trap. `nonsense` is not a date, and log did not say so:
`--since=nonsense` matched nothing and `--until=nonsense` matched everything,
exactly as if the word meant "now". Check a date that returns nothing before
concluding there were no commits.

The same moment can be written in many ways. Each command below prints only the
oldest commit it let in, through `tail -1`, which keeps the last line:

```console
$ git log --oneline --since='2026-01-05 13:00' | tail -1
ff8f73f Document multiply
$ git log --oneline --since='2026.01.05 13:00' | tail -1
ff8f73f Document multiply
$ git log --oneline --since='01/05/2026 13:00' | tail -1
ff8f73f Document multiply
$ git log --oneline --since='05.01.2026 13:00' | tail -1
ff8f73f Document multiply
$ git log --oneline --since='5 Jan 2026 13:00' | tail -1
ff8f73f Document multiply
$ git log --oneline --since='Mon, 5 Jan 2026 13:00:00 +0000' | tail -1
ff8f73f Document multiply
$ git log --oneline --since='@1767618000 +0000' | tail -1
ff8f73f Document multiply
$ git log --oneline --since=13:00 | tail -1
ff8f73f Document multiply
$ git log --oneline --since='2026-01-05 13:00 +0330' | tail -1
f47fa3b Add the calculator
$ git log --oneline --since='2026-01-05T13:00:00+03:30' | tail -1
f47fa3b Add the calculator
$ TZ=EST5 git log --oneline --since='2026-01-05 13:00' | tail -1
758934f Backport logging notes
$ git log --oneline --since=noon | tail -1
ba5c7a0 Add multiply
$ git log --oneline --since='5 hours ago' | tail -1
7b32ffd Fix subtraction
$ git log --oneline --since=2026-01-05
$ git log --oneline --since='2026-01-05 00:00' | tail -1
c44dc25 Add README
```

| Form | Example |
|---|---|
| ISO 8601, with a space or a `T` | `--since='2026-01-05 13:00'`, `--since='2026-01-05T13:00:00+03:30'` |
| Other day orders | `--since='2026.01.05 13:00'`, `--since='01/05/2026 13:00'`, `--since='05.01.2026 13:00'` |
| RFC 2822, as in email | `--since='Mon, 5 Jan 2026 13:00:00 +0000'` |
| Seconds since 1970, with `@` | `--since='@1767618000 +0000'` |
| A time alone, meaning today | `--since=13:00`, `--since=noon` |
| Relative | `--since='5 hours ago'`, `--until=yesterday`, `--since=today` |

Git's documentation lists the ISO, RFC 2822 and raw forms, and the three day
orders, as what `GIT_AUTHOR_DATE` accepts (Chapter 12). `--since` took all of
them, and more loosely written dates too. `01/05/2026` is month first and
`05.01.2026` day first, as the documentation says; both meant 5 January here.

An offset after the time moves the moment: 13:00 at +03:30 is 09:30 in UTC, which
let in the commits from 10:00. Without an offset, Git reads the time in your own
time zone, which in the sandbox is UTC. `TZ=EST5` in front of a command changes
that for the one command, in bash; `EST5` is five hours behind UTC, so 13:00
became 18:00 in UTC and only the last commit was newer.

The empty result is the second trap. A date with no time takes the time of day
from now, so `--since=2026-01-05` meant 19:00 on that day, after every commit.
Write `00:00` to mean the start of the day.

### When a clock was wrong

`wrong-clock` has one commit on top of `main`, made on a computer whose clock
said 08:00:

```console
$ git log --format='%h %cd %s' --date=iso -3 wrong-clock
9f9d4d2 2026-01-05 08:00:00 +0000 A commit with a wrong clock
758934f 2026-01-05 18:00:00 +0000 Backport logging notes
cc42788 2026-01-05 17:00:00 +0000 Add divide
$ git log --oneline --since='2026-01-05 12:00' wrong-clock
$ git log --oneline --since-as-filter='2026-01-05 12:00' wrong-clock
758934f Backport logging notes
cc42788 Add divide
f83a6b7 Rename the test file
e2f0758 Merge branch 'feature'
7b32ffd Fix subtraction
ff8f73f Document multiply
ba5c7a0 Add multiply
```

`--since` stops walking at the first commit older than the date, and the very
first commit was. `--since-as-filter`, as Git's documentation describes it,
visits every commit in the range and keeps the newer ones, which is slower on a
long history and correct when clocks disagree.

> **Since Git 2.37.** `--since-as-filter`.

## By author, committer or message

```console
$ git log --oneline --author=Grace
f83a6b7 Rename the test file
e1e8cdc Add tests
$ git log --oneline --author=GRACE
$ git log --oneline --author=GRACE -i
f83a6b7 Rename the test file
e1e8cdc Add tests
$ git log --oneline --author=Grace --author=Alan
758934f Backport logging notes
f83a6b7 Rename the test file
ff8f73f Document multiply
ba5c7a0 Add multiply
e1e8cdc Add tests
$ git log --oneline --committer=alan@
758934f Backport logging notes
ff8f73f Document multiply
ba5c7a0 Add multiply
```

`--author` matches anywhere in the author's name and email, so part of either
is enough. It is case-sensitive: `GRACE` matched nothing until `-i` was given. Several `--author` options
match any of them. `--committer` does the same for the committer.

```console
$ git log --oneline --grep=multiply
ff8f73f Document multiply
ba5c7a0 Add multiply
$ git log --oneline --grep='#12'
7b32ffd Fix subtraction
e1e8cdc Add tests
$ git log --oneline --grep=multiply --grep=divide
cc42788 Add divide
ff8f73f Document multiply
ba5c7a0 Add multiply
$ git log --oneline --grep=Refs --grep=wrong --all-match
e1e8cdc Add tests
$ git log --oneline --grep=Refs --invert-grep
758934f Backport logging notes
cc42788 Add divide
f83a6b7 Rename the test file
e2f0758 Merge branch 'feature'
ff8f73f Document multiply
ba5c7a0 Add multiply
f47fa3b Add the calculator
c44dc25 Add README
$ git log --oneline --author=Ada --grep=Add
cc42788 Add divide
f47fa3b Add the calculator
c44dc25 Add README
```

`--grep` searches the whole message, body and trailers included: `#12` is in a
`Refs:` line. Several `--grep` options match any of them, and `--all-match`
requires all. Git's documentation adds that when notes are shown (Chapter 38),
`--grep` searches them as part of the message. `--invert-grep` keeps the commits that do not match. Different
kinds of limit combine the other way: `--author=Ada --grep=Add` needs both.

The patterns are regular expressions:

```console
$ git log --oneline --grep='^Add'
cc42788 Add divide
ba5c7a0 Add multiply
e1e8cdc Add tests
f47fa3b Add the calculator
c44dc25 Add README
$ git log --oneline --grep='^Refs'
7b32ffd Fix subtraction
e1e8cdc Add tests
$ git log --oneline -E --grep='(mul|div)'
cc42788 Add divide
ff8f73f Document multiply
ba5c7a0 Add multiply
$ git log --oneline --basic-regexp --grep='\(mul\|div\)'
cc42788 Add divide
ff8f73f Document multiply
ba5c7a0 Add multiply
$ git log --oneline --grep='(mul|div)'
$ git log --oneline --grep='sub.'
7b32ffd Fix subtraction
e1e8cdc Add tests
$ git log --oneline -F --grep='sub.'
$ git log --oneline -P --grep='(?i)DIVIDE'
cc42788 Add divide
```

| Option | Pattern is |
|---|---|
| `--basic-regexp` | a basic regular expression, the default |
| `-E`, `--extended-regexp` | an extended regular expression |
| `-F`, `--fixed-strings` | plain text; nothing is special |
| `-P`, `--perl-regexp` | a Perl-compatible regular expression, with extras such as `(?i)` |

"mul or div" is written `\(mul\|div\)` in a basic expression and `(mul|div)` in
an extended or Perl-compatible one; plain text has no way to say it.

`^` matches at the start of any line of the message, not only the subject:
`Refs:` is never the first line. The
extended form typed without `-E` found nothing, because in a basic expression
`(`, `|` and `)` are ordinary characters. `.` means any character, so `sub.`
matched `subt` and `sub(`; with `-F` it is a real dot, and no message has
`sub.` in it. Git's documentation notes that `-P` works only if Git was built
with support for it; the Git used here was.

## Merge commits

```console
$ git log --oneline --merges
e2f0758 Merge branch 'feature'
$ git log --oneline --no-merges -4
758934f Backport logging notes
cc42788 Add divide
f83a6b7 Rename the test file
7b32ffd Fix subtraction
$ git log --oneline --min-parents=2
e2f0758 Merge branch 'feature'
$ git log --oneline --max-parents=1 -4
758934f Backport logging notes
cc42788 Add divide
f83a6b7 Rename the test file
7b32ffd Fix subtraction
$ git log --oneline --max-parents=0
c44dc25 Add README
$ git log --oneline --max-parents=0 --no-max-parents -3
758934f Backport logging notes
cc42788 Add divide
f83a6b7 Rename the test file
$ git log --oneline --max-parents=0 --max-parents=-1 -3
758934f Backport logging notes
cc42788 Add divide
f83a6b7 Rename the test file
$ git log --oneline --min-parents=2 --no-min-parents -3
758934f Backport logging notes
cc42788 Add divide
f83a6b7 Rename the test file
$ git log --oneline --min-parents=2 --min-parents=0 -3
758934f Backport logging notes
cc42788 Add divide
f83a6b7 Rename the test file
```

| Option | Keeps commits with | Same as |
|---|---|---|
| `--merges` | two or more parents | `--min-parents=2` |
| `--no-merges` | one parent or none | `--max-parents=1` |
| `--max-parents=0` | no parents: root commits | |
| `--min-parents=3` | three or more: octopus merges (Chapter 25; the strategy in Chapter 27) | |
| `--no-min-parents` | any number again, after an earlier minimum | `--min-parents=0` |
| `--no-max-parents` | any number again, after an earlier maximum | `--max-parents=-1` |

The "same as" column is Git's documentation, and the transcript shows each pair
giving the same list. A later option replaces an earlier one of the same kind.

```console
$ git log --oneline --first-parent
758934f Backport logging notes
cc42788 Add divide
f83a6b7 Rename the test file
e2f0758 Merge branch 'feature'
7b32ffd Fix subtraction
e1e8cdc Add tests
f47fa3b Add the calculator
c44dc25 Add README
```

`--first-parent` follows only the first parent of each merge, which is the
branch that was merged *into*. `Add multiply` and `Document multiply` came in
through the merge's second parent and are gone, leaving the main line of work:
one merge standing for the whole feature.

In a second repository, `topic` has been merged into `main`:

```console
$ git log --oneline --graph --all
*   c1191fe Merge branch 'topic'
|\  
| * 91d5458 Topic two
| * e2c4911 Topic one
* | d7d38da Main work
|/  
* 1d0cedb Base
$ git log --oneline main..topic
$ git log --oneline --exclude-first-parent-only main..topic
91d5458 Topic two
e2c4911 Topic one
```

`main..topic` is empty, because `main` now contains every commit of `topic`.
`--exclude-first-parent-only` follows only first parents when working out what
to leave out, so commits that reached `main` through a merge's second parent are
not taken away. It answers "which commits were the topic's own work", even after
the merge.

> **Since Git 2.36.** `--exclude-first-parent-only`.

## History of a file

```console
$ git log --oneline -- calc.py
cc42788 Add divide
e2f0758 Merge branch 'feature'
7b32ffd Fix subtraction
ba5c7a0 Add multiply
f47fa3b Add the calculator
$ git log --oneline calc.py README.md
cc42788 Add divide
e2f0758 Merge branch 'feature'
7b32ffd Fix subtraction
ff8f73f Document multiply
ba5c7a0 Add multiply
f47fa3b Add the calculator
c44dc25 Add README
```

With paths, log lists only the commits that changed them. The merge is there
because its result for `calc.py` differs from each parent's: it combined the
fix from one side with `mul()` from the other. [Simplified
history](#simplified-history) explains when merges are shown.

`tests_calc.py` used to be called `test_calc.py`:

```console
$ git log --oneline tests_calc.py
f83a6b7 Rename the test file
$ git log --oneline --follow tests_calc.py
f83a6b7 Rename the test file
e1e8cdc Add tests
$ git log --oneline --follow tests_calc.py README.md
fatal: --follow requires exactly one pathspec
$ git -c log.follow=true log --oneline tests_calc.py
f83a6b7 Rename the test file
e1e8cdc Add tests
```

The plain history begins at the rename, as if the file had been created there.
`--follow` notices the rename and carries on under the old name. It works for
exactly one path. `log.follow` turns it on whenever one path is given, and Git's
documentation warns that it has the same limits, including working poorly on
history that is not a straight line.

The rename is found by comparing content. In a fourth repository, `notes.txt`
was renamed to `diary.txt` and half its lines rewritten in the same commit:

```console
$ git log --oneline --follow diary.txt
95b0e78 Rename and rewrite half
$ git log --oneline -1 --stat
95b0e78 Rename and rewrite half
 diary.txt | 10 ++++++++++
 notes.txt | 10 ----------
 2 files changed, 10 insertions(+), 10 deletions(-)
$ git log --oneline --follow -M40% diary.txt
95b0e78 Rename and rewrite half
1031d50 Add notes
```

The two versions were too different to count as a rename at the default
threshold of 50%, so `--stat` shows a deletion and an addition, and `--follow`
stopped. Lowering the threshold with `-M40%` let it find the rename and carry on.
Chapter 13 explains [the threshold](#ch13-the-threshold-and-why-m5-is-not-five-percent).

A path that no longer exists needs `--`:

```console
$ git log --oneline test_calc.py
fatal: ambiguous argument 'test_calc.py': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
$ git log --oneline -- test_calc.py
f83a6b7 Rename the test file
e1e8cdc Add tests
```

Without `--`, Git could not tell whether `test_calc.py` was a revision or a
file, because it is neither a branch nor a file on disk. After `--` it can only
be a path.

`--diff-filter` keeps commits by the kind of change they made, with the letters
from Chapter 13:

```console
$ git log --oneline --diff-filter=A --name-only
758934f Backport logging notes
notes/LOG.txt
e1e8cdc Add tests
test_calc.py
f47fa3b Add the calculator
calc.py
c44dc25 Add README
README.md
$ git log --oneline --diff-filter=D --name-only
$ git log --oneline --diff-filter=R --name-status
f83a6b7 Rename the test file
R100	test_calc.py	tests_calc.py
$ git log --oneline --diff-filter=D --name-only --no-renames
f83a6b7 Rename the test file
test_calc.py
```

`A` found the commit that added each file. `D` found nothing, because the only
file ever removed was renamed, and log reports renames as `R`. With
`--no-renames` the rename counts as a deletion and an addition, and `D` finds
it. `--name-only` and `--name-status` list the files (Chapter 13).

```console
$ git log --oneline -1 --stat -- README.md
cc42788 Add divide
 README.md | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --oneline -1 --stat --full-diff -- README.md
cc42788 Add divide
 README.md | 2 +-
 calc.py   | 4 ++++
 2 files changed, 5 insertions(+), 1 deletion(-)
$ cd notes && git log --oneline . && cd ..
758934f Backport logging notes
```

Paths limit the diff as well as the commits: `Add divide` also changed
`calc.py`, which `--full-diff` shows. Paths are relative to where you are, so
`.` inside `notes` means that directory.

In a third repository, `config.ini` was added, removed, and added again:

```console
$ git log --oneline -- config.ini
c56834f Bring config back
186cca0 Remove config
5d5184b Add config
$ git log --oneline --remove-empty -- config.ini
c56834f Bring config back
```

`--remove-empty` stops at the point where, walking back, the path disappears:
before `Bring config back` there was no `config.ini`, so the earlier life of the
file is left out.

## History of some lines

```console
$ git log --oneline -L 5,6:calc.py
f47fa3b Add the calculator
diff --git a/calc.py b/calc.py
new file mode 100644
index 0000000..a3bb3c0
--- /dev/null
+++ b/calc.py
@@ -0,0 +5,2 @@
+def add(a, b):
+    return a + b
$ git log --oneline -L :sub:calc.py --no-patch
7b32ffd Fix subtraction
f47fa3b Add the calculator
```

`-L` follows a range of lines through history, however they moved, and shows
each change as a diff of just those lines. Lines 5 and 6 of `calc.py` today,
`add()`, were never changed after they were written. `:sub:calc.py` is the
function `sub()`, found the way `git diff` finds function names for hunk
headers (Chapter 13), and two commits touched it. `--no-patch` leaves the diffs
out.

```console
$ git log --oneline -L '/def mul/,+1:calc.py'
ba5c7a0 Add multiply
diff --git a/calc.py b/calc.py
index a3bb3c0..761eda1 100644
--- a/calc.py
+++ b/calc.py
@@ -7,0 +9,1 @@ def sub(a, b):
+def mul(a, b):
$ git log --oneline -L '/def mul/,+2:calc.py' --no-patch
ba5c7a0 Add multiply
$ git log --oneline -L :div:calc.py -L :add:calc.py --no-patch
fatal: -L parameter 'add' starting at line 15: no match
$ git log --oneline -L :div:calc.py -L ^:add:calc.py --no-patch
cc42788 Add divide
ba5c7a0 Add multiply
f47fa3b Add the calculator
$ git log --oneline -L :nosuch:calc.py
fatal: -L parameter 'nosuch' starting at line 1: no match
$ git log --oneline -L 5,6:calc.py -- README.md
fatal: -L<range>:<file> cannot be used with pathspec
```

`+1` after a pattern counts the matching line itself, so `/def mul/,+1` is that
one line. Several `-L` options can be given, and a search in the second starts
where the first range ended, as Git's documentation says. `add()` comes before
`div()`, so the plain search failed, and `^:add` searched from the top of the
file instead. `-L` cannot be combined with other paths.

```console
$ git log --oneline -L 6,-2:calc.py
f47fa3b Add the calculator
diff --git a/calc.py b/calc.py
new file mode 100644
index 0000000..a3bb3c0
--- /dev/null
+++ b/calc.py
@@ -0,0 +5,2 @@
+def add(a, b):
+    return a + b
$ git log --oneline -L '/def mul/,/def div/:calc.py' --no-patch
cc42788 Add divide
ba5c7a0 Add multiply
$ git log --oneline -L :sub:calc.py --name-only
7b32ffd Fix subtraction
calc.py
f47fa3b Add the calculator
calc.py
$ git log --oneline -L :sub:calc.py --no-patch --name-only
fatal: options '--name-only', '--name-status', '--check', and '-s' cannot be used together
$ git log --oneline -L 5,6:calc.py --stat
fatal: -L does not yet support the requested diff format
$ git log --oneline -L 5,6:calc.py main feature
fatal: More than one commit to dig from: feature and main?
$ git log --oneline -L 20,30:calc.py
fatal: file calc.py has only 14 lines
```

`6,-2` counts back: two lines ending at line 6, the same `add()` as `5,6`. A
second pattern ends the range at its first match after the start, so
`/def mul/,/def div/` ran from `mul()` down to the line `def div`.

`--name-only` replaces the line diffs rather than adding to them, and cannot be
combined with `--no-patch`. Git's documentation lists what works with `-L`:
`--raw`, `--name-only`, `--name-status` and `--summary`, but none of the
`--stat` family yet. It also allows only one starting commit, and the range must
exist in it.

| Form | Follows |
|---|---|
| `-L 5,6:<file>` | lines 5 to 6 |
| `-L 6,-2:<file>` | two lines ending at line 6 |
| `-L /<regex>/,+2:<file>` | two lines, starting at the first line matching |
| `-L /<regex>/,/<regex>/:<file>` | from the first match of one pattern to the next match of the other |
| `-L :<funcname>:<file>` | the function whose name matches, up to the next function |
| `-L ^/<regex>/,<end>:<file>`, `-L ^:<funcname>:<file>` | the same, searching from the top of the file even after another `-L` |

`git blame` (Chapter 19) answers the neighbouring question: who last changed
each line.

## Simplified history

In this repository `file.txt` was changed on `topic`, and `topic` was merged.
Then it was changed on `lost`, and `lost` was merged with `-s ours`, which records
the merge but keeps `main`'s content, throwing that change away (Chapter 27):

```console
$ git log --oneline --graph --all
*   569ae23 Merge branch 'lost'
|\  
| * af8b3de Change file on lost
|/  
*   af368f3 Merge branch 'topic'
|\  
| * e9b1cc0 Change file on topic
* | 55890f7 Change other on main
|/  
* c22977e Base
$ git log --oneline -- file.txt
e9b1cc0 Change file on topic
c22977e Base
$ git log --oneline --full-history -- file.txt
569ae23 Merge branch 'lost'
af8b3de Change file on lost
af368f3 Merge branch 'topic'
e9b1cc0 Change file on topic
c22977e Base
```

The plain history of `file.txt` does not show `Change file on lost` at all, and
this is the usual reason for "I know that commit touched the file". By default
log explains how the file came to be what it is now. At a merge whose result
matches one parent for that file, it follows only that parent, and the lost
change is on the other side. `--full-history` follows every parent and shows it.

```console
$ git log --oneline --graph --full-history -- file.txt
*   569ae23 Merge branch 'lost'
|\  
| * af8b3de Change file on lost
|/  
*   af368f3 Merge branch 'topic'
|\  
| * e9b1cc0 Change file on topic
|/  
* c22977e Base
$ git log --oneline --graph --full-history --simplify-merges -- file.txt
*   569ae23 Merge branch 'lost'
|\  
| * af8b3de Change file on lost
|/  
* e9b1cc0 Change file on topic
* c22977e Base
$ git log --oneline --show-pulls -- file.txt
af368f3 Merge branch 'topic'
e9b1cc0 Change file on topic
c22977e Base
```

`--full-history` keeps every merge on the way, including `Merge branch 'topic'`,
whose result for `file.txt` is simply the topic's version. `--simplify-merges`
removes such merges, keeping the one where the change was dropped.
`--show-pulls` keeps the default history and adds each merge whose result
matches its second parent but not its first: the merge that "pulled" the change
into `main`.

> **Since Git 2.27.** `--show-pulls`.

```console
$ git log --oneline --sparse -- file.txt
569ae23 Merge branch 'lost'
af368f3 Merge branch 'topic'
e9b1cc0 Change file on topic
c22977e Base
$ git log --oneline --full-history --sparse -- file.txt
569ae23 Merge branch 'lost'
af8b3de Change file on lost
af368f3 Merge branch 'topic'
55890f7 Change other on main
e9b1cc0 Change file on topic
c22977e Base
$ git log --oneline --dense -- file.txt
e9b1cc0 Change file on topic
c22977e Base
```

`--sparse` shows every commit walked, changed or not; with `--full-history` that
is everything. `--dense` shows only commits that change the path, which is the
default.

| Option | For a path, log shows |
|---|---|
| (none), `--dense` | the commits that explain the file's current content |
| `--full-history` | every commit that changed it, on every branch, and the merges joining them |
| `--full-history --simplify-merges` | the same, without merges that add nothing |
| `--show-pulls` | the default, plus the merges that brought changes in |
| `--sparse` | every commit walked, whether it changed the path or not |

Git's documentation has a long section, "History Simplification", with larger
examples of each.

`--ancestry-path` works on ranges rather than paths:

```console
$ git log --oneline topic..main
569ae23 Merge branch 'lost'
af8b3de Change file on lost
af368f3 Merge branch 'topic'
55890f7 Change other on main
$ git log --oneline --ancestry-path topic..main
569ae23 Merge branch 'lost'
af8b3de Change file on lost
af368f3 Merge branch 'topic'
$ git log --oneline --ancestry-path=lost topic..main
569ae23 Merge branch 'lost'
af8b3de Change file on lost
af368f3 Merge branch 'topic'
55890f7 Change other on main
```

`topic..main` includes `Change other on main`, which is on `main` but has nothing
to do with `topic`. `--ancestry-path` keeps only commits that descend from
`topic`: what happened after it. With `=lost` it keeps commits in the range that
are ancestors or descendants of `lost`, or `lost` itself, which brings that
commit back, since `lost` grew out of it. Git's documentation adds that the
option can be given several times, keeping commits related to any of them.

> **Since Git 2.38.** `--ancestry-path=<commit>`. Plain `--ancestry-path` is
> much older.

## Order

This repository has two branches whose commits alternate in time, merged
together. `Right one, written earlier` has an author date of 09:30 and a
committer date of 11:00:

```console
$ git log --graph --format='%h %ad %cd %s' --date=format:%H:%M
*   1d9b49b 14:00 14:00 Merge branch 'right' into both
|\  
| * 908daab 13:00 13:00 Right two
| * de530b2 09:30 11:00 Right one, written earlier
* | 300a216 12:00 12:00 Left two
* | 9319cae 10:00 10:00 Left one
|/  
* 1d0cedb 09:00 09:00 Base
$ git log --format='%h %ad %cd %s' --date=format:%H:%M
1d9b49b 14:00 14:00 Merge branch 'right' into both
908daab 13:00 13:00 Right two
300a216 12:00 12:00 Left two
de530b2 09:30 11:00 Right one, written earlier
9319cae 10:00 10:00 Left one
1d0cedb 09:00 09:00 Base
$ git log --format='%h %ad %cd %s' --date=format:%H:%M --date-order
1d9b49b 14:00 14:00 Merge branch 'right' into both
908daab 13:00 13:00 Right two
300a216 12:00 12:00 Left two
de530b2 09:30 11:00 Right one, written earlier
9319cae 10:00 10:00 Left one
1d0cedb 09:00 09:00 Base
$ git log --format='%h %ad %cd %s' --date=format:%H:%M --author-date-order
1d9b49b 14:00 14:00 Merge branch 'right' into both
908daab 13:00 13:00 Right two
300a216 12:00 12:00 Left two
9319cae 10:00 10:00 Left one
de530b2 09:30 11:00 Right one, written earlier
1d0cedb 09:00 09:00 Base
$ git log --format='%h %ad %cd %s' --date=format:%H:%M --topo-order
1d9b49b 14:00 14:00 Merge branch 'right' into both
908daab 13:00 13:00 Right two
de530b2 09:30 11:00 Right one, written earlier
300a216 12:00 12:00 Left two
9319cae 10:00 10:00 Left one
1d0cedb 09:00 09:00 Base
$ git log --format='%h %s' --reverse
1d0cedb Base
9319cae Left one
de530b2 Right one, written earlier
300a216 Left two
908daab Right two
1d9b49b Merge branch 'right' into both
```

The columns are the author time and the committer time. By default the two
branches are interleaved by committer date. `--author-date-order` sorts by
author date instead, which moved `Right one` below `Left one`. `--topo-order`
keeps each branch's commits together. `--reverse` prints the list oldest first.

`--date-order` gave the same list as the default here. The difference, in Git's
documentation, is a guarantee: it never shows a parent before all of its
children. The same guarantee holds for `--author-date-order` and
`--topo-order`. The default order makes no such promise, and a wrong clock
breaks it. Back in the calculator repository, starting from `main` and from
`wrong-clock`:

```console
$ git log --oneline main wrong-clock | tail -2
c44dc25 Add README
9f9d4d2 A commit with a wrong clock
$ git log --oneline --date-order main wrong-clock | head -2
9f9d4d2 A commit with a wrong clock
758934f Backport logging notes
```

By default the commit that claims 08:00 came last, below its own parent
`Backport logging notes` and everything else. `--date-order` put it first,
where it belongs, and kept date order for the rest. `head -2` keeps the first two
lines.

| Option | Order | Never a parent before a child |
|---|---|---|
| (none) | newest committer date first, as commits are walked | not guaranteed |
| `--date-order` | committer date | yes |
| `--author-date-order` | author date | yes |
| `--topo-order` | each line of history kept together | yes |
| `--reverse` | the list, reversed | as the order it reverses |

`--graph` implies `--topo-order`, according to Git's documentation, unless
`--date-order` is given too.

## Built-in formats

```console
$ git log -1 --pretty=oneline main~1
cc427888f2333ae3ad689bbb443909de24f9f485 Add divide
$ git log -1 --pretty=short main~1
commit cc427888f2333ae3ad689bbb443909de24f9f485
Author: Ada Lovelace <ada@example.com>

    Add divide
$ git log -1 --pretty=medium main~1
commit cc427888f2333ae3ad689bbb443909de24f9f485
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 17:00:00 2026 +0000

    Add divide
    
    Dividing by zero raises ZeroDivisionError.
$ git log -1 --pretty=full main~1
commit cc427888f2333ae3ad689bbb443909de24f9f485
Author: Ada Lovelace <ada@example.com>
Commit: Ada Lovelace <ada@example.com>

    Add divide
    
    Dividing by zero raises ZeroDivisionError.
$ git log -1 --pretty=fuller main~1
commit cc427888f2333ae3ad689bbb443909de24f9f485
Author:     Ada Lovelace <ada@example.com>
AuthorDate: Mon Jan 5 17:00:00 2026 +0000
Commit:     Ada Lovelace <ada@example.com>
CommitDate: Mon Jan 5 17:00:00 2026 +0000

    Add divide
    
    Dividing by zero raises ZeroDivisionError.
$ git log -1 --pretty=reference main~1
cc42788 (Add divide, 2026-01-05)
$ git log -1 --pretty=email main~1
From cc427888f2333ae3ad689bbb443909de24f9f485 Mon Sep 17 00:00:00 2001
From: Ada Lovelace <ada@example.com>
Date: Mon, 5 Jan 2026 17:00:00 +0000
Subject: [PATCH] Add divide

Dividing by zero raises ZeroDivisionError.
$ git log -1 --pretty=mboxrd main~1
From cc427888f2333ae3ad689bbb443909de24f9f485 Mon Sep 17 00:00:00 2001
From: Ada Lovelace <ada@example.com>
Date: Mon, 5 Jan 2026 17:00:00 +0000
Subject: [PATCH] Add divide

Dividing by zero raises ZeroDivisionError.
$ git log -1 --pretty=raw main~1
commit cc427888f2333ae3ad689bbb443909de24f9f485
tree 14e6e9a719a497cc8351b93dcc087e6d7e7a24cf
parent f83a6b70dddf7d32be53a3537e35939f43492d07
author Ada Lovelace <ada@example.com> 1767632400 +0000
committer Ada Lovelace <ada@example.com> 1767632400 +0000

    Add divide
    
    Dividing by zero raises ZeroDivisionError.
$ git log -1 --pretty main~1
commit cc427888f2333ae3ad689bbb443909de24f9f485
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 17:00:00 2026 +0000

    Add divide
    
    Dividing by zero raises ZeroDivisionError.
```

`main~1` is the commit before `main` (Chapter 18). `--pretty` on its own means
`medium`, the default.

| Option | Use it for |
|---|---|
| `--pretty=oneline` | a full hash per line, for scripts that need it |
| `--pretty=short` | a quick look without dates |
| `--pretty=medium` | reading history; the default |
| `--pretty=full` | seeing who committed as well as who wrote |
| `--pretty=fuller` | both people and both dates |
| `--pretty=reference` | quoting a commit in another message: `cc42788 (Add divide, 2026-01-05)` |
| `--pretty=email` | the start of a patch email (Chapter 61) |
| `--pretty=mboxrd` | the same, safe to store with other emails in one file |
| `--pretty=raw` | the commit object exactly as stored, dates as seconds (Chapter 6) |

Git's documentation describes the difference in `mboxrd`: message lines
starting with "From " are quoted with `>`, so a mail program does not take them
for the start of the next message. This message had no such line, so the two
look the same.

> **Since Git 2.25.** `--pretty=reference`.

```console
$ git log -2 --oneline --no-abbrev-commit
758934f771cbd277828115b51855b772bdbd3a69 Backport logging notes
cc427888f2333ae3ad689bbb443909de24f9f485 Add divide
$ git log -2 --oneline --abbrev=10
758934f771 Backport logging notes
cc427888f2 Add divide
$ git log -2 --pretty=oneline
758934f771cbd277828115b51855b772bdbd3a69 Backport logging notes
cc427888f2333ae3ad689bbb443909de24f9f485 Add divide
$ git log -2 --pretty=oneline --abbrev-commit
758934f Backport logging notes
cc42788 Add divide
$ git -c log.abbrevCommit=true log -1 --pretty=oneline
758934f Backport logging notes
$ git log -1 --format=fullest
fatal: invalid --pretty format: fullest
```

`--oneline` is `--pretty=oneline --abbrev-commit`, as the last two show.
`--abbrev` sets the length, and `log.abbrevCommit` makes short hashes the default.
Short hashes have a limit in the `raw` format:

```console
$ git log -2 --format=raw --abbrev-commit
commit 758934f
tree c5a555bfa96e261c6247754cf3be47458767e651
parent cc427888f2333ae3ad689bbb443909de24f9f485
author Alan Turing <alan@example.com> 1767249000 +0330
committer Alan Turing <alan@example.com> 1767636000 +0000

    Backport logging notes

commit cc42788
tree 14e6e9a719a497cc8351b93dcc087e6d7e7a24cf
parent f83a6b70dddf7d32be53a3537e35939f43492d07
author Ada Lovelace <ada@example.com> 1767632400 +0000
committer Ada Lovelace <ada@example.com> 1767632400 +0000

    Add divide
    
    Dividing by zero raises ZeroDivisionError.
```

Only the `commit` line was shortened; the tree and parent stay in full.
`Backport logging notes` also shows its two dates as Git stores them, in seconds
and a time zone: written on 1 January at +03:30, committed on 5 January in UTC.

A format can be made the default, or given a name:

```console
$ git -c format.pretty=reference log -2
758934f (Backport logging notes, 2026-01-01)
cc42788 (Add divide, 2026-01-05)
$ git -c pretty.changes='format:* %h %s (%an)' log -2 --pretty=changes
* 758934f Backport logging notes (Alan Turing)
* cc42788 Add divide (Ada Lovelace)
```

`format.pretty` sets the default. `pretty.<name>` defines a named format, which
Git's documentation says is silently ignored if the name is one of the built-in
formats.

## Format strings

```console
$ git log -3 --format='%h %an <%ae> %s'
758934f Alan Turing <alan@example.com> Backport logging notes
cc42788 Ada Lovelace <ada@example.com> Add divide
f83a6b7 Grace Hopper <grace@example.com> Rename the test file
$ git log -2 --pretty=format:'%h %s' | cat -A; echo
758934f Backport logging notes$
cc42788 Add divide
$ git log -2 --pretty=tformat:'%h %s' | cat -A
758934f Backport logging notes$
cc42788 Add divide$
$ git log -2 --format='%h %s' | cat -A
758934f Backport logging notes$
cc42788 Add divide$
```

A format string mixes text with *placeholders* that start with `%`. `format:`
puts a newline between commits and none after the last, which `cat -A` shows by
marking each line end with `$`; the `echo` only moves the next prompt onto a new
line. `tformat:` ends every commit with a newline. A string with a `%` in it and
no prefix is `tformat:`, as Git's documentation says and the last two show.
`--format` and `--pretty` are one option under two names, listed together in
Git's documentation.

### Placeholders for the commit and its people

```console
$ git log -1 --format='commit %H%ntree %T%nparents %P%nshort %h %t %p'
commit 758934f771cbd277828115b51855b772bdbd3a69
tree c5a555bfa96e261c6247754cf3be47458767e651
parents cc427888f2333ae3ad689bbb443909de24f9f485
short 758934f c5a555b cc42788
$ git log -1 --format='%an|%ae|%al|%ad|%aD|%ai|%aI|%as|%at|%ar|%ah' v1.0
Grace Hopper|grace@example.com|grace|Mon Jan 5 11:00:00 2026 +0000|Mon, 5 Jan 2026 11:00:00 +0000|2026-01-05 11:00:00 +0000|2026-01-05T11:00:00Z|2026-01-05|1767610800|8 hours ago|8 hours ago
$ git log -1 --format='%cn|%ce|%cl|%cd|%cD|%ci|%cI|%cs|%ct|%cr|%ch' v1.0
Grace Hopper|grace@example.com|grace|Mon Jan 5 11:00:00 2026 +0000|Mon, 5 Jan 2026 11:00:00 +0000|2026-01-05 11:00:00 +0000|2026-01-05T11:00:00Z|2026-01-05|1767610800|8 hours ago|8 hours ago
```

| Placeholder | Is | Placeholder | Is |
|---|---|---|---|
| `%H` | commit hash | `%h` | short commit hash |
| `%T` | tree hash | `%t` | short tree hash |
| `%P` | parent hashes | `%p` | short parent hashes |
| `%an` | author name | `%cn` | committer name |
| `%ae` | author email | `%ce` | committer email |
| `%al` | author email before the `@` | `%cl` | committer email before the `@` |
| `%ad` | author date, in the `--date` format | `%cd` | committer date, in the `--date` format |
| `%aD` | author date, RFC 2822 | `%cD` | committer date, RFC 2822 |
| `%ai` | author date, ISO-like | `%ci` | committer date, ISO-like |
| `%aI` | author date, strict ISO | `%cI` | committer date, strict ISO |
| `%as` | author date, `YYYY-MM-DD` | `%cs` | committer date, `YYYY-MM-DD` |
| `%at` | author date, seconds since 1970 | `%ct` | committer date, seconds since 1970 |
| `%ar` | author date, relative | `%cr` | committer date, relative |
| `%ah` | author date, `--date=human` style | `%ch` | committer date, `--date=human` style |
| `%aN`, `%aE`, `%aL` | author name, email and local part after `.mailmap` | `%cN`, `%cE`, `%cL` | committer name, email and local part after `.mailmap` |
| `%n` | a newline | | |

`%ah` and `%ar` both said "8 hours ago" here, because `--date=human` uses
relative wording for dates this recent. `%aN` is in [Other
options](#other-options).

> **Since Git 2.25.** `%as`, `%cs`, `%al` and `%cl`. **Since Git 2.32.** `%ah`
> and `%ch`.

### Placeholders for messages, trailers and names

```console
$ git log -1 --format='[%s]%n[%f]%n[%b]%n[%B]' v1.0
[Add tests]
[Add-tests]
[Cover add() for now; sub() is still wrong.

Refs: #12
Reviewed-by: Ada Lovelace <ada@example.com>
]
[Add tests

Cover add() for now; sub() is still wrong.

Refs: #12
Reviewed-by: Ada Lovelace <ada@example.com>
]
$ git log -1 --format='%d%n%D' v1.0
 (tag: v1.0, origin/main)
tag: v1.0, origin/main
$ git log -4 --format='%h%d'
758934f (HEAD -> main)
cc42788 (tag: v1.1)
f83a6b7
e2f0758
```

| Placeholder | Is |
|---|---|
| `%s` | subject, the first line |
| `%f` | subject made safe for a file name |
| `%b` | body, everything after the subject |
| `%B` | the whole message |
| `%d` | branch and tag names, with ` (` and `)` |
| `%D` | branch and tag names, bare |

`%d` adds its brackets and leading space only when there is something to show.

`%(trailers)` extracts trailers, the `Key: value` lines at the end of a message
(Chapter 12), and takes options:

```console
$ git log -1 --format='%(trailers)' v1.0
Refs: #12
Reviewed-by: Ada Lovelace <ada@example.com>

$ git log -1 --format='%(trailers:key=Refs)' v1.0
Refs: #12

$ git log -1 --format='%(trailers:key=Refs,valueonly)' v1.0
#12

$ git log -1 --format='%(trailers:keyonly,separator=%x2C )' v1.0
Refs, Reviewed-by
$ git log -1 --format='%(trailers:key_value_separator==)' v1.0
Refs=#12
Reviewed-by=Ada Lovelace <ada@example.com>

```

A comma inside an option is written `%x2C`, because a plain comma separates
options. With `separator`, the newline after the last trailer goes too.

The block of trailers can hold other lines, and a trailer can be folded onto a
second line that starts with spaces. For the next commands only, `HEAD` is a
commit with this message:

```console
$ git log -1 --format=%B
Trailer demo

Body.

Refs: #12
see also the wiki
Signed-off-by: Ada Lovelace
  <ada@example.com>

$ git log -1 --format='%(trailers)'
Refs: #12
see also the wiki
Signed-off-by: Ada Lovelace
  <ada@example.com>

$ git log -1 --format='%(trailers:only)'
Refs: #12
Signed-off-by: Ada Lovelace
  <ada@example.com>

$ git log -1 --format='%(trailers:key=signed-off-by)'
Signed-off-by: Ada Lovelace
  <ada@example.com>

$ git log -1 --format='%(trailers:key=Refs,only=false)'
Refs: #12
see also the wiki

$ git log -1 --format='%(trailers:unfold)'
Refs: #12
see also the wiki
Signed-off-by: Ada Lovelace <ada@example.com>

```

Plain `%(trailers)` printed `see also the wiki` with the trailers; `only` left it
out. `key` matched `Signed-off-by` without regard to case, and turns `only` on by
itself, as Git's documentation says, so `only=false` brought the other line back.
`unfold` joined the folded trailer into one line.

Which lines count as a trailer block has rules of its own. Here the block
qualified because of `Signed-off-by`, a trailer Git itself writes; with only
`Refs` and `Reviewed-by` around a line that is not a trailer, the same test
found no trailers at all. Chapter 53 covers the rules and
`git interpret-trailers`.

| Option of `%(trailers)` | Does |
|---|---|
| `%(trailers:key=<key>)` | Only trailers with this key, in any case; repeat for several keys. Turns `only` on |
| `%(trailers:only)`, `%(trailers:only=false)` | Leave out, or keep, lines in the block that are not trailers |
| `%(trailers:valueonly)`, `%(trailers:keyonly)` | Only the value, or only the key |
| `%(trailers:separator=<text>)` | Between trailers, instead of a newline |
| `%(trailers:key_value_separator=<text>)` | Between key and value, instead of `: ` |
| `%(trailers:unfold)` | Join a trailer folded over several lines |

Options combine with commas, as in `%(trailers:key=Refs,valueonly)`. Git's
documentation adds that a repeated option other than `key` keeps its last value.

> **Since Git 2.31.** `keyonly`, `valueonly` and `key_value_separator`.

`%(describe)` names a commit by the nearest tag, as `git describe` does
(Chapter 22):

```console
$ git log -1 --format='%(describe)'
v1.0-7-g758934f
$ git log -1 --format='%(describe:tags)'
v1.1-1-g758934f
$ git log -1 --format='%(describe:tags,abbrev=4)'
v1.1-1-g7589
$ git log -1 --format='%(describe:tags,match=v1.0)'
v1.0-7-g758934f
$ git log -1 --format='%(describe:tags,exclude=v1.1)'
v1.0-7-g758934f
$ git log -1 --format='[%(describe)]' v1.0~2
[]
```

`v1.0-7-g758934f` means seven commits after `v1.0`, at commit `758934f`. Plain
`describe` uses annotated tags only; `tags` accepts lightweight tags such as
`v1.1` (Chapter 47). `match` and `exclude` pick the tags by pattern, and `abbrev`
sets the hash length. Before any tag there is nothing to describe, and the
placeholder is empty.

> **Since Git 2.32.** `%(describe)`, with `match` and `exclude`. **Since Git
> 2.35.** `tags` and `abbrev`.

`%(decorate)` is `%d` with every part replaceable:

```console
$ git log -2 --format='%h%(decorate)'
758934f (HEAD -> main)
cc42788 (tag: v1.1)
$ git log -2 --format='%h%(decorate:prefix=[,suffix=],separator=%x2C,tag=)'
758934f[HEAD -> main]
cc42788[v1.1]
$ git log -1 --format='%h%(decorate:pointer=>)'
758934f (HEAD>main)
```

| Option of `%(decorate)` | Replaces | Normally |
|---|---|---|
| `%(decorate:prefix=<text>)` | what comes before the names | ` (` |
| `%(decorate:suffix=<text>)` | what comes after them | `)` |
| `%(decorate:separator=<text>)` | what goes between two names | `, ` |
| `%(decorate:pointer=<text>)` | the arrow between `HEAD` and its branch | ` -> ` |
| `%(decorate:tag=<text>)` | the label before a tag | `tag: ` |

Git's documentation says a comma in a value is written `%x2C` and a closing
bracket `%x29`.

> **Since Git 2.43.** `%(decorate)`.

`%S` is the ref each commit was reached from, and works with `--source`:

```console
$ git log -2 --source --all --format='%h %S %s'
758934f refs/heads/main Backport logging notes
cc42788 refs/tags/v1.1 Add divide
$ git log -2 --oneline --source --all
758934f	refs/heads/main Backport logging notes
cc42788	refs/tags/v1.1 Add divide
```

With `--all` there are many starting points, and `--source` says which one led
to each commit: `Add divide` was first reached from the tag `v1.1`. Without a
format of your own, `--source` puts the name after the hash, separated by a tab.

Some placeholders only mean something with options from other chapters:

| Placeholder | Is | Covered in |
|---|---|---|
| `%m` | `<`, `>` or `-`: which side of `A...B` a commit is on, or a boundary | Chapter 18 |
| `%gD`, `%gd`, `%gn`, `%gN`, `%ge`, `%gE`, `%gs` | reflog entry, its short form, identity and subject, with `-g` | Chapter 36 |
| `%N` | the commit's notes | Chapter 38 |
| `%GG`, `%G?`, `%GS`, `%GK`, `%GF`, `%GP`, `%GT` | signature check, status, signer, key, fingerprints and trust | Chapter 68 |
| `%(count)`, `%(total)` | a patch's number in a series, and the series length; used only by `git format-patch` | Chapter 61 |

### Layout, colour and special characters

```console
$ git log -3 --format='%h %<(22)%s|%an'
758934f Backport logging notes|Alan Turing
cc42788 Add divide            |Ada Lovelace
f83a6b7 Rename the test file  |Grace Hopper
$ git log -3 --format='%h %<(12,trunc)%s|'
758934f Backport l..|
cc42788 Add divide  |
f83a6b7 Rename the..|
$ git log -3 --format='%h %<(12,ltrunc)%s|'
758934f ..ging notes|
cc42788 Add divide  |
f83a6b7 .. test file|
$ git log -3 --format='%h %<(12,mtrunc)%s|'
758934f Backp..notes|
cc42788 Add divide  |
f83a6b7 Renam.. file|
$ git log -3 --format='%h %>(22)%s|'
758934f Backport logging notes|
cc42788             Add divide|
f83a6b7   Rename the test file|
$ git log -3 --format='%h %><(22)%s|'
758934f Backport logging notes|
cc42788       Add divide      |
f83a6b7  Rename the test file |
$ git log -3 --format='%<|(12)%h|%s'
758934f     |Backport logging notes
cc42788     |Add divide
f83a6b7     |Rename the test file
$ git log -3 --format='%h %>|(30)%s|'
758934f Backport logging notes|
cc42788             Add divide|
f83a6b7   Rename the test file|
$ git log -3 --format='%h %><|(30)%s|'
758934f Backport logging notes|
cc42788       Add divide      |
f83a6b7  Rename the test file |
$ git log -3 --format='%<(12)%h%>(8)%s|'
758934f     Backport logging notes|
cc42788     Add divide|
f83a6b7     Rename the test file|
$ git log -3 --format='%<(12)%h%>>(8)%s|'
758934fBackport logging notes|
cc42788   Add divide|
f83a6b7Rename the test file|
```

Each of these applies to the placeholder right after it. Text too long for the
width is left whole unless a `trunc` option cuts it, with `..` marking the cut.

| Placeholder | Makes the next placeholder |
|---|---|
| `%<(<n>)` | at least `<n>` columns wide, padded on the right |
| `%>(<n>)` | the same, padded on the left |
| `%><(<n>)` | the same, centred |
| `%<(<n>,trunc)`, `%<(<n>,ltrunc)`, `%<(<n>,mtrunc)` | also cut to `<n>` columns, at the end, start or middle; the same options work with `%>` and `%><` |
| `%<\|(<m>)`, `%>\|(<m>)`, `%><\|(<m>)` | reach column `<m>` of the line, padded on the right, left or both sides |
| `%>>(<n>)`, `%>>\|(<m>)` | like `%>(<n>)` and `%>\|(<m>)`, but when the text is too long, it uses spaces left over on its left |

In the last pair, `%<(12)` left five spaces after each hash. `%>(8)` kept them,
and `%>>(8)` used them for text longer than 8 columns: all five for the long
subjects, two for `Add divide`, which is 10 columns. Git's documentation adds
that a negative `<m>` counts from the right edge of the terminal, and that wide
characters such as emoji take two columns and can spoil the alignment.

```console
$ git log -1 --format='%w(30,0,4)%B' v1.0
Add tests

    Cover add() for now; sub()
    is still wrong.

    Refs: #12 Reviewed-by: Ada
    Lovelace <ada@example.com>

$ git log -3 --format='%h%+b'
758934f
cc42788
Dividing by zero raises ZeroDivisionError.

f83a6b7
$ git log -3 --format='%s%n%-b'
Backport logging notes
Add divide
Dividing by zero raises ZeroDivisionError.

Rename the test file
$ git log -3 --format='%h% d'
758934f  (HEAD -> main)
cc42788  (tag: v1.1)
f83a6b7
$ git log -1 --format='100%% %x41%x42'
100% AB
```

`%w(30,0,4)` wraps what follows at 30 columns, indenting the very first line by
0 and every later line by 4. It rewraps whole paragraphs, so the two trailers,
which form one paragraph, were joined. Git's documentation compares it to
`git shortlog -w` (Chapter 22).

Between `%` and a placeholder's letter, `+` adds a newline before it only if it
is not empty, `-` removes the newlines before it if it is empty, and a space adds
a space only if it is not empty. `%%` is a percent sign, and `%x41` is the byte
with hexadecimal value 41, `A`.

```console
$ git log --format='%h %e %s' -1
758934f  Backport logging notes
$ git log -1 --format='%Cred%h%Creset %Cgreen%s%Creset' | cat -A
758934f Backport logging notes$
$ git log -1 --format='%C(always,yellow)%h%C(reset) %s' | cat -A
^[[33m758934f Backport logging notes$
$ git log -1 --color=always --format='%C(auto)%h%d %s' | cat -A
^[[33m758934f^[[m^[[33m (^[[m^[[1;36mHEAD^[[m^[[33m -> ^[[m^[[1;32mmain^[[m^[[33m)^[[m Backport logging notes$
```

`%e` is the message's encoding, empty for UTF-8 ([Other options](#other-options)
shows another). `%Cred`, `%Cgreen`, `%Cblue` and `%Creset` switch colours, and
`%C(<colour>)` takes any colour Chapter 62 describes, such as `%C(bold blue)`.

They obey the colour settings, as Git's documentation says: `color.diff`,
`color.ui` or `--color`, and with `auto`, only on a terminal. Colour is off in the sandbox
(Chapter 2), so the first command printed none, and `cat -A` shows escape codes
as `^[`. `%C(always,<colour>)` colours regardless; `%C(reset)` was still left
out, because only the placeholder marked `always` is forced. `%C(auto)` colours
the placeholders after it the way log would, here with `--color=always` turning
colour on: a yellow hash, and the decoration in the colours shown in [The
graph](#the-graph).

## Dates

`%ad` and the `Date:` line follow `--date`. `HEAD` here is `Backport logging
notes`, written at 10:00 in a zone 3 hours 30 minutes ahead of UTC:

```console
$ git log -1 --format=%ad --date=default
Thu Jan 1 10:00:00 2026 +0330
$ git log -1 --format=%ad --date=relative
5 days ago
$ git log -1 --format=%ad --date=local
Thu Jan 1 06:30:00 2026
$ git log -1 --format=%ad --date=iso
2026-01-01 10:00:00 +0330
$ git log -1 --format=%ad --date=iso8601
2026-01-01 10:00:00 +0330
$ git log -1 --format=%ad --date=iso-strict
2026-01-01T10:00:00+03:30
$ git log -1 --format=%ad --date=iso8601-strict
2026-01-01T10:00:00+03:30
$ git log -1 --format=%ad --date=rfc
Thu, 1 Jan 2026 10:00:00 +0330
$ git log -1 --format=%ad --date=rfc2822
Thu, 1 Jan 2026 10:00:00 +0330
$ git log -1 --format=%ad --date=short
2026-01-01
$ git log -1 --format=%ad --date=raw
1767249000 +0330
$ git log -1 --format=%ad --date=human
Thu 10:00 +0330
$ git log -1 --format=%ad --date=unix
1767249000
```

| Option | Shows |
|---|---|
| `--date=default` | the date in the time zone it was made in, as `git log` prints it |
| `--date=relative` | how long ago, from now |
| `--date=local` | the default format, converted to your time zone and without the offset |
| `--date=iso`, `--date=iso8601` | ISO-like, with spaces, readable and sortable |
| `--date=iso-strict`, `--date=iso8601-strict` | strict ISO 8601 |
| `--date=rfc`, `--date=rfc2822` | as in email headers |
| `--date=short` | the date alone |
| `--date=raw` | seconds since 1970 and the offset, as Git stores it |
| `--date=unix` | seconds since 1970 only |
| `--date=human` | as much as the distance needs: see below |

The sandbox's own time zone is UTC (Chapter 2), which is why `local` showed
06:30. `--date=local` is `--date=default-local`, in Git's documentation.

`human` drops whatever is obvious from today's date. Git's documentation says it
omits the year for this year, the whole date for the last few days, where the
weekday is enough, and the time for older dates, and shows the time zone only
when it is not yours. Trying one commit at different distances from now gave:

| Written | `--date=human` showed |
|---|---|
| earlier today | `8 hours ago` |
| a few days ago, in another time zone | `Thu 10:00 +0330` |
| earlier this year | `Mon Jan 5 11:00` |
| in an earlier year | `Jan 5 2026` |

```console
$ git log -2 --format='%ad' --date=iso
2026-01-01 10:00:00 +0330
2026-01-05 17:00:00 +0000
$ git log -2 --format='%ad' --date=iso-local
2026-01-01 06:30:00 +0000
2026-01-05 17:00:00 +0000
$ git log -2 --format='%ad' --date=raw-local
1767249000 +0000
1767632400 +0000
$ git log -1 --format='%ad' --date=format:'%A %d %B %Y, %H:%M'
Thursday 01 January 2026, 10:00
$ git log -2 --format='%ad' --date=format-local:'%H:%M %z'
06:30 +0000
17:00 +0000
$ git log -1 --format=%ad --relative-date
5 days ago
$ git log -1 --date=bogus
fatal: unknown date format bogus
```

`-local` after any format converts to your time zone. For `raw` only the offset
changes, since the number of seconds is the same everywhere; Git's documentation
adds that it changes nothing for `relative` and `unix`. `format:` takes the `%`
codes of the C library's `strftime`, such as `%A` for the weekday and `%c` for
your system's usual format; Git's documentation says `%s`, `%z` and `%Z` are
handled by Git itself, and that the local form is spelled `format-local:`.
`--relative-date` is `--date=relative`.

```console
$ git log -1 | grep Date
Date:   Thu Jan 1 10:00:00 2026 +0330
$ git -c log.date=short log -1 | grep Date
Date:   2026-01-01
$ git -c log.date=auto:short log -1 | grep Date
Date:   Thu Jan 1 10:00:00 2026 +0330
```

`log.date` sets the default. With `auto:` in front, the format is used only when
the output goes to a pager, and otherwise the default, which is why `auto:short`
gave the default here: the sandbox writes to a pipe.

## Decorations

```console
$ git log --oneline --decorate -3
758934f (HEAD -> main) Backport logging notes
cc42788 (tag: v1.1) Add divide
f83a6b7 Rename the test file
$ git log --oneline --decorate=short -2
758934f (HEAD -> main) Backport logging notes
cc42788 (tag: v1.1) Add divide
$ git log --oneline --decorate=full -2
758934f (HEAD -> refs/heads/main) Backport logging notes
cc42788 (tag: refs/tags/v1.1) Add divide
$ git log --oneline --decorate=no -2
758934f Backport logging notes
cc42788 Add divide
$ git log --oneline --no-decorate -2
758934f Backport logging notes
cc42788 Add divide
$ git log --oneline --decorate=auto -2
758934f Backport logging notes
cc42788 Add divide
$ git -c log.decorate=full log --oneline -2
758934f (HEAD -> refs/heads/main) Backport logging notes
cc42788 (tag: refs/tags/v1.1) Add divide
```

A *decoration* is the list of refs pointing at a commit. `HEAD -> main` means
`HEAD` is on the branch `main`, which points here; `tag:` marks a tag.

`auto`, the default, decorates only on a terminal, so in these transcripts
decorations appear only when asked for. `log.decorate` sets the default.

```console
$ git log --oneline --decorate --decorate-refs=refs/tags -6
758934f Backport logging notes
cc42788 (tag: v1.1) Add divide
f83a6b7 Rename the test file
e2f0758 Merge branch 'feature'
7b32ffd Fix subtraction
ff8f73f Document multiply
$ git log --oneline --decorate --decorate-refs-exclude=refs/tags -6
758934f (HEAD -> main) Backport logging notes
cc42788 Add divide
f83a6b7 Rename the test file
e2f0758 Merge branch 'feature'
7b32ffd Fix subtraction
ff8f73f (old-feature, feature) Document multiply
$ git -c log.excludeDecoration=refs/remotes log --oneline --decorate -6 v1.0
e1e8cdc (tag: v1.0) Add tests
f47fa3b Add the calculator
c44dc25 Add README
$ git -c log.excludeDecoration=refs/remotes log --oneline --decorate --decorate-refs=refs/remotes -6 v1.0
e1e8cdc (origin/main) Add tests
f47fa3b Add the calculator
c44dc25 Add README
$ git log --oneline -1 --decorate
758934f (HEAD -> main) Backport logging notes
$ git log --oneline -1 --decorate --clear-decorations
758934f (HEAD -> main, refs/notes/example) Backport logging notes
$ git log --oneline -1 --decorate --decorate-refs=refs/tags --clear-decorations
758934f (HEAD -> main, refs/notes/example) Backport logging notes
$ git -c log.initialDecorationSet=all log --oneline -1 --decorate
758934f (HEAD -> main, refs/notes/example) Backport logging notes
```

`--decorate-refs` shows only refs matching the pattern and
`--decorate-refs-exclude` hides them. `log.excludeDecoration` hides them by
default, and an explicit `--decorate-refs` wins over it. Git's documentation
lists what is decorated by default: `HEAD` and refs under `refs/heads/`,
`refs/remotes/`, `refs/stash/` and `refs/tags/`. `refs/notes/example` is none of
those, so it appeared only with `--clear-decorations`, or with
`log.initialDecorationSet=all`. `--clear-decorations` also cancels any
`--decorate-refs` and `--decorate-refs-exclude` given before it.

> **Since Git 2.38.** `--clear-decorations` and `log.initialDecorationSet`.

```console
$ git log --oneline --simplify-by-decoration --all
9f9d4d2 A commit with a wrong clock
758934f Backport logging notes
cc42788 Add divide
ff8f73f Document multiply
e1e8cdc Add tests
c44dc25 Add README
```

`--simplify-by-decoration` keeps the commits that a branch or tag points to,
which gives the shape of the history in a few lines. `Add README` has no ref;
Git's documentation warns that extra commits can be shown to give a meaningful
history, and the root commit was one here.

## The graph

```console
$ git log --oneline --graph --all
* 9f9d4d2 A commit with a wrong clock
* 758934f Backport logging notes
* cc42788 Add divide
* f83a6b7 Rename the test file
*   e2f0758 Merge branch 'feature'
|\  
| * ff8f73f Document multiply
| * ba5c7a0 Add multiply
* | 7b32ffd Fix subtraction
|/  
* e1e8cdc Add tests
* f47fa3b Add the calculator
* c44dc25 Add README
```

Each `*` is a commit, and the lines join it to its parents. Read from the top:
`e2f0758` has two parents, drawn by `|\`, one on each line; `|/` is where
`feature` started from `e1e8cdc`. `--graph` works with any format:

```console
$ git log --graph -3 --format='%h %s'
* 758934f Backport logging notes
* cc42788 Add divide
* f83a6b7 Rename the test file
$ git log --oneline --graph --no-walk
fatal: options '--no-walk' and '--graph' cannot be used together
```

On a terminal the graph is in colour, each line of history in its own colour, as
are the decorations:

```ansi
$ git log --oneline --graph --decorate --all -9
* \e[33m9f9d4d2\e[m\e[33m (\e[m\e[1;32mwrong-clock\e[m\e[33m)\e[m A commit with a wrong clock
* \e[33m758934f\e[m\e[33m (\e[m\e[1;36mHEAD\e[m\e[33m -> \e[m\e[1;32mmain\e[m\e[33m)\e[m Backport logging notes
* \e[33mcc42788\e[m\e[33m (\e[m\e[1;33mtag: \e[m\e[1;33mv1.1\e[m\e[33m)\e[m Add divide
* \e[33mf83a6b7\e[m Rename the test file
*   \e[33me2f0758\e[m Merge branch 'feature'
\e[32m|\e[m\e[33m\\e[m  
\e[32m|\e[m * \e[33mff8f73f\e[m\e[33m (\e[m\e[1;32mold-feature\e[m\e[33m, \e[m\e[1;32mfeature\e[m\e[33m)\e[m Document multiply
\e[32m|\e[m * \e[33mba5c7a0\e[m Add multiply
* \e[33m|\e[m \e[33m7b32ffd\e[m Fix subtraction
\e[33m|\e[m\e[33m/\e[m  
* \e[33me1e8cdc\e[m\e[33m (\e[m\e[1;33mtag: \e[m\e[1;33mv1.0\e[m\e[33m, \e[m\e[1;31morigin/main\e[m\e[33m)\e[m Add tests
```

Local branches are green, remote-tracking branches red, tags yellow and `HEAD`
cyan. `color.decorate.<slot>` changes them and `log.graphColors` sets the colours
of the lines.

```console
$ git log --oneline --parents -4
758934f cc42788 Backport logging notes
cc42788 f83a6b7 Add divide
f83a6b7 e2f0758 Rename the test file
e2f0758 7b32ffd ff8f73f Merge branch 'feature'
$ git log --oneline --children -4
758934f Backport logging notes
cc42788 758934f Add divide
f83a6b7 cc42788 Rename the test file
e2f0758 f83a6b7 Merge branch 'feature'
$ git log --oneline --show-linear-break --all
758934f Backport logging notes
cc42788 Add divide
f83a6b7 Rename the test file
e2f0758 Merge branch 'feature'
7b32ffd Fix subtraction

                    ..........
ff8f73f Document multiply
ba5c7a0 Add multiply
e1e8cdc Add tests
f47fa3b Add the calculator
c44dc25 Add README

                    ..........
9f9d4d2 A commit with a wrong clock
$ git log --oneline --show-linear-break='  ~~~' --all -8
758934f Backport logging notes
cc42788 Add divide
f83a6b7 Rename the test file
e2f0758 Merge branch 'feature'
7b32ffd Fix subtraction

  ~~~
ff8f73f Document multiply
ba5c7a0 Add multiply
e1e8cdc Add tests
```

`--parents` and `--children` print the hashes of each commit's parents or
children after its own, which scripts use to rebuild the graph. Without a graph,
`--show-linear-break` marks the places where the next commit listed is not the
parent of the one before. The last break shows the wrong clock again: the commit
on top of `main` was listed last, as the oldest.

With many branches the graph grows wide, and `--graph-lane-limit` cuts it. This
repository has four more branches, `lane1` to `lane4`:

```console
$ git log --oneline --graph --branches='lane*' -8
* adf4625 Work on lane 4
| * d9e6391 Work on lane 3
| | * e88930b Work on lane 2
| | | * 8844070 Work on lane 1
| | | * cc42788 Add divide
| | |/  
| | * f83a6b7 Rename the test file
| |/  
| * e2f0758 Merge branch 'feature'
|/| 
| * ff8f73f Document multiply
$ git log --oneline --graph --branches='lane*' -8 --graph-lane-limit=2
* adf4625 Work on lane 4
| * d9e6391 Work on lane 3
| | * e88930b Work on lane 2
| | ~ 8844070 Work on lane 1
| | ~ cc42788 Add divide
| | ~ 
| | * f83a6b7 Rename the test file
| |/  
| * e2f0758 Merge branch 'feature'
|/| 
| * ff8f73f Document multiply
```

Lanes beyond the limit are replaced by `~`, as Git's documentation says, which
adds that `0` or a negative number means no limit.

> **Since Git 2.55.** `--graph-lane-limit`.

## Each commit's changes

```console
$ git log --oneline -2 --stat
758934f Backport logging notes
 notes/LOG.txt | 1 +
 1 file changed, 1 insertion(+)
cc42788 Add divide
 README.md | 2 +-
 calc.py   | 4 ++++
 2 files changed, 5 insertions(+), 1 deletion(-)
$ git log --oneline -1 -p
758934f Backport logging notes
diff --git a/notes/LOG.txt b/notes/LOG.txt
new file mode 100644
index 0000000..4e0d385
--- /dev/null
+++ b/notes/LOG.txt
@@ -0,0 +1 @@
+Logging was written in December and committed now.
```

Every diff option from Chapter 13 works here, applied to each commit against its
parent. Chapter 13 also compares [`git log -p` with `git diff` and
`git show`](#ch13-git-diff-git-show-and-git-log-p).

```console
$ git log --oneline -1 --stat -s
758934f Backport logging notes
$ git log --oneline -1 -s --stat
758934f Backport logging notes
 notes/LOG.txt | 1 +
 1 file changed, 1 insertion(+)
$ git log --oneline -1 -p --no-patch
758934f Backport logging notes
```

`-s`, or `--no-patch`, turns off every diff output given before it, and the
order matters: after it, `--stat` works again. Git's documentation gives the
reason it exists: to cancel `-p` or `--stat` that an alias (Chapter 64) already
added.

```console
$ git log --oneline -1 --raw
758934f Backport logging notes
:000000 100644 0000000 4e0d385 A	notes/LOG.txt
$ git log --oneline -1 --raw -t
758934f Backport logging notes
:000000 040000 0000000 b933028 A	notes
:000000 100644 0000000 4e0d385 A	notes/LOG.txt
$ git log --oneline -1 -p -q
758934f Backport logging notes
diff --git a/notes/LOG.txt b/notes/LOG.txt
new file mode 100644
index 0000000..4e0d385
--- /dev/null
+++ b/notes/LOG.txt
@@ -0,0 +1 @@
+Logging was written in December and committed now.
```

`--raw` prints one line per changed file: the old and new modes, the old and
new blob hashes, and a status letter, with zeros where nothing existed before
(Chapter 75). `-t` adds the directories, as tree objects (Chapter 6). `-q`, or
`--quiet`, appears in `git log -h` as "suppress diff output" but changed nothing
here, in either order with `-p`. In `git show` it does hide the diff (Chapter 18);
in `git log`, use `-s`.

## Merges and their changes

A merge is the one place where `-p` needs choices. In this repository both sides
changed the start of `greeting.txt`, which conflicted and was resolved by hand;
one side also changed the last line, which merged cleanly:

```console
$ git log --oneline --graph
*   77f8dee Merge branch 'side'
|\  
| * 2e1e4aa Say planet
* | 220dbc5 Say hi
|/  
* 54af481 Base
$ git log -p -1
commit 77f8dee88179f6c7f1f3d054e43386ff653015c2
Merge: 220dbc5 2e1e4aa
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 12:00:00 2026 +0000

    Merge branch 'side'
```

Nothing but the header and its `Merge:` line. Git's documentation explains that
without a `--diff-merges` choice, merges show no diff even with `-p`, and search
options such as `-S` skip them too.

```console
$ git log -p -m -1
commit 77f8dee88179f6c7f1f3d054e43386ff653015c2 (from 220dbc536b9de0adf780a0c6ead577591dcb97bc)
Merge: 220dbc5 2e1e4aa
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 12:00:00 2026 +0000

    Merge branch 'side'

diff --git a/greeting.txt b/greeting.txt
index 40d7d49..c5eaaf5 100644
--- a/greeting.txt
+++ b/greeting.txt
@@ -1,5 +1,5 @@
 hi
-world
+planet and world
 3
 4
 5
@@ -9,4 +9,4 @@ world
 9
 10
 11
-end
+the end

commit 77f8dee88179f6c7f1f3d054e43386ff653015c2 (from 2e1e4aa846859a7b86e156787bb22abcd2ecc85a)
Merge: 220dbc5 2e1e4aa
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 12:00:00 2026 +0000

    Merge branch 'side'

diff --git a/greeting.txt b/greeting.txt
index 00e0ecc..c5eaaf5 100644
--- a/greeting.txt
+++ b/greeting.txt
@@ -1,5 +1,5 @@
-hello
-planet
+hi
+planet and world
 3
 4
 5
$ git log -m -1 --oneline
77f8dee Merge branch 'side'
```

`-m` shows the merge in the default merge format, `separate`: one diff against
each parent, marked `(from ...)`. On its own, without `-p`, it shows nothing.

```console
$ git log -1 --oneline --diff-merges=off -p
77f8dee Merge branch 'side'
$ git log -1 --oneline --diff-merges=first-parent -p
77f8dee Merge branch 'side'
diff --git a/greeting.txt b/greeting.txt
index 40d7d49..c5eaaf5 100644
--- a/greeting.txt
+++ b/greeting.txt
@@ -1,5 +1,5 @@
 hi
-world
+planet and world
 3
 4
 5
@@ -9,4 +9,4 @@ world
 9
 10
 11
-end
+the end
$ git log -1 --oneline --dd
77f8dee Merge branch 'side'
diff --git a/greeting.txt b/greeting.txt
index 40d7d49..c5eaaf5 100644
--- a/greeting.txt
+++ b/greeting.txt
@@ -1,5 +1,5 @@
 hi
-world
+planet and world
 3
 4
 5
@@ -9,4 +9,4 @@ world
 9
 10
 11
-end
+the end
```

`first-parent` shows what the merge brought into the branch it was made on, the
same way `-p` shows an ordinary commit. `--dd` is that with `-p`.

```console
$ git log -1 --oneline --diff-merges=combined -p
77f8dee Merge branch 'side'

diff --combined greeting.txt
index 40d7d49,00e0ecc..c5eaaf5
--- a/greeting.txt
+++ b/greeting.txt
@@@ -1,5 -1,5 +1,5 @@@
 -hello
 -planet
 +hi
- world
++planet and world
  3
  4
  5
@@@ -9,4 -9,4 +9,4 @@@
  9
  10
  11
- end
+ the end
$ git log -1 --oneline --cc
77f8dee Merge branch 'side'

diff --cc greeting.txt
index 40d7d49,00e0ecc..c5eaaf5
--- a/greeting.txt
+++ b/greeting.txt
@@@ -1,5 -1,5 +1,5 @@@
 -hello
 -planet
 +hi
- world
++planet and world
  3
  4
  5
```

A *combined diff* compares the result with both parents at once, with two
marker columns, one per parent. In the first hunk `++planet and world` is new to
both, which is the hand resolution. The dense form, `--cc`, drops the second
hunk: there the result simply took one side's line, which Git's documentation
calls uninteresting. Chapter 26 reads combined diffs in detail.

```console
$ git log -1 --oneline --remerge-diff
77f8dee Merge branch 'side'
diff --git a/greeting.txt b/greeting.txt
remerge CONFLICT (content): Merge conflict in greeting.txt
index ff60e34..c5eaaf5 100644
--- a/greeting.txt
+++ b/greeting.txt
@@ -1,10 +1,5 @@
-<<<<<<< 220dbc5 (Say hi)
 hi
-world
-=======
-hello
-planet
->>>>>>> 2e1e4aa (Say planet)
+planet and world
 3
 4
 5
```

`--remerge-diff` redoes the merge automatically, conflict markers and all, and
shows how the recorded result differs from that. It answers the question the
others cannot: what did the person resolving the merge actually change? Here,
they replaced the conflict with `planet and world`. The cleanly merged last line
does not appear, because the automatic merge already had it.

The other spellings, and the settings around them:

```console
$ git log -1 --oneline --diff-merges=none -p
77f8dee Merge branch 'side'
$ git log -1 --oneline --no-diff-merges -p
77f8dee Merge branch 'side'
$ git log -1 --oneline --diff-merges=on -p
77f8dee (from 220dbc5) Merge branch 'side'
diff --git a/greeting.txt b/greeting.txt
index 40d7d49..c5eaaf5 100644
--- a/greeting.txt
+++ b/greeting.txt
@@ -1,5 +1,5 @@
 hi
-world
+planet and world
 3
 4
 5
@@ -9,4 +9,4 @@ world
 9
 10
 11
-end
+the end
77f8dee (from 2e1e4aa) Merge branch 'side'
diff --git a/greeting.txt b/greeting.txt
index 00e0ecc..c5eaaf5 100644
--- a/greeting.txt
+++ b/greeting.txt
@@ -1,5 +1,5 @@
-hello
-planet
+hi
+planet and world
 3
 4
 5
```

Rather than print the same diffs again, the remaining spellings can be compared
with the ones above. `diff` prints nothing when its two inputs are identical, so
`same` appears only then; `<(...)` hands a command's output to `diff` as if it
were a file, in bash:

```console
$ diff <(git log -1 --diff-merges=on -p) <(git log -1 -m -p) && echo same
same
$ diff <(git log -1 --diff-merges=on -p) <(git log -1 --diff-merges=m -p) && echo same
same
$ diff <(git log -1 --diff-merges=on -p) <(git log -1 --diff-merges=separate -p) && echo same
same
$ diff <(git log -1 --dd) <(git log -1 --diff-merges=1 -p) && echo same
same
$ diff <(git log -1 --diff-merges=combined -p) <(git log -1 --diff-merges=c -p) && echo same
same
$ diff <(git log -1 --diff-merges=combined -p) <(git log -1 -c) && echo same
same
$ diff <(git log -1 --cc) <(git log -1 --diff-merges=dense-combined -p) && echo same
same
$ diff <(git log -1 --cc) <(git log -1 --diff-merges=cc -p) && echo same
same
$ diff <(git log -1 --remerge-diff) <(git log -1 --diff-merges=remerge -p) && echo same
same
$ diff <(git log -1 --remerge-diff) <(git log -1 --diff-merges=r -p) && echo same
same
```

```console
$ git -c log.diffMerges=first-parent log -1 --oneline -m -p
77f8dee Merge branch 'side'
diff --git a/greeting.txt b/greeting.txt
index 40d7d49..c5eaaf5 100644
--- a/greeting.txt
+++ b/greeting.txt
@@ -1,5 +1,5 @@
 hi
-world
+planet and world
 3
 4
 5
@@ -9,4 +9,4 @@ world
 9
 10
 11
-end
+the end
$ git log --oneline --first-parent -p -1
77f8dee Merge branch 'side'
diff --git a/greeting.txt b/greeting.txt
index 40d7d49..c5eaaf5 100644
--- a/greeting.txt
+++ b/greeting.txt
@@ -1,5 +1,5 @@
 hi
-world
+planet and world
 3
 4
 5
@@ -9,4 +9,4 @@ world
 9
 10
 11
-end
+the end
$ git log -1 --oneline --diff-merges=bogus -p
fatal: invalid value for '--diff-merges': 'bogus'
```

`log.diffMerges` changed what `-m` means to `first-parent`. With
`--first-parent`, merges get the first-parent diff without being asked, which
Git's documentation states as that option changing the default.

| Option | For a merge, `-p` shows |
|---|---|
| (none), `--diff-merges=off`, `--diff-merges=none`, `--no-diff-merges` | nothing |
| `-m`, `--diff-merges=on`, `--diff-merges=m` | the format named by `log.diffMerges`, `separate` by default |
| `--diff-merges=separate` | a diff against each parent in turn |
| `--diff-merges=first-parent`, `--diff-merges=1`, `--dd` | a diff against the first parent |
| `--diff-merges=combined`, `--diff-merges=c`, `-c` | a combined diff of all parents |
| `--diff-merges=dense-combined`, `--diff-merges=cc`, `--cc` | a combined diff without hunks where the result took one side |
| `--diff-merges=remerge`, `--diff-merges=r`, `--remerge-diff` | the difference from an automatic re-merge |
| `--first-parent` | the first-parent diff |

The table pairs each option with `-p`, and that is not the whole story:

```console
$ git log -2 --oneline --diff-merges=first-parent
77f8dee Merge branch 'side'
diff --git a/greeting.txt b/greeting.txt
index 40d7d49..c5eaaf5 100644
--- a/greeting.txt
+++ b/greeting.txt
@@ -1,5 +1,5 @@
 hi
-world
+planet and world
 3
 4
 5
@@ -9,4 +9,4 @@ world
 9
 10
 11
-end
+the end
220dbc5 Say hi
$ git log -2 --oneline --dd
77f8dee Merge branch 'side'
diff --git a/greeting.txt b/greeting.txt
index 40d7d49..c5eaaf5 100644
--- a/greeting.txt
+++ b/greeting.txt
@@ -1,5 +1,5 @@
 hi
-world
+planet and world
 3
 4
 5
@@ -9,4 +9,4 @@ world
 9
 10
 11
-end
+the end
220dbc5 Say hi
diff --git a/greeting.txt b/greeting.txt
index 0bb4562..40d7d49 100644
--- a/greeting.txt
+++ b/greeting.txt
@@ -1,4 +1,4 @@
-hello
+hi
 world
 3
 4
```

`--diff-merges=<format>` on its own shows diffs for merges and nothing for other
commits. `--dd`, `-c`, `--cc` and `--remerge-diff` add `-p`, as Git's
documentation defines them, so every commit gets its diff. `-m` adds nothing:
without `-p` it showed no diff at all, earlier in this section.

> **Since Git 2.29.** `--no-diff-merges`. **Since Git 2.31.** `--diff-merges`.
> **Since Git 2.32.** `log.diffMerges`. **Since Git 2.36.** `--remerge-diff`.
> **Since Git 2.43.** `--dd`.

In another merge, one side had renamed `greeting.txt` to `hello.txt`:

```console
$ git log -1 --format=%h -c --name-status -M
7bb21da

RM	hello.txt
$ git log -1 --format=%h -c --name-status -M --combined-all-paths
7bb21da

RM	greeting.txt	hello.txt	hello.txt
```

`--name-status` with a combined diff has one status letter per parent: renamed
from one, modified from the other. `--combined-all-paths` names the file as each
parent had it, then the result. `-M` turns on rename detection (Chapter 13).

The root commit, which has no parent, is shown as creating every file unless
`log.showRoot` is false:

```console
$ git log --stat --format='%h %s' --max-parents=0
54af481 Base

 greeting.txt | 12 ++++++++++++
 1 file changed, 12 insertions(+)
$ git -c log.showRoot=false log --stat --format='%h %s' --max-parents=0
54af481 Base

```

## Other options

```console
$ git log -1 --log-size --format='%h %s'
log size 30
758934f Backport logging notes
$ git log -1 --log-size v1.0
commit e1e8cdc5e8619659867296846d8d8d5b8d619dfd
log size 213
Author: Grace Hopper <grace@example.com>
Date:   Mon Jan 5 11:00:00 2026 +0000

    Add tests
    
    Cover add() for now; sub() is still wrong.
    
    Refs: #12
    Reviewed-by: Ada Lovelace <ada@example.com>
```

`--log-size` adds each message's length in bytes, which Git's documentation says
is for tools reading the output.

A message indented with tabs:

```console
$ git log -1 | cat -A
commit 73a68be1cc1369ccc0d75ca1c4c64fe871be89f8$
Author: Ada Lovelace <ada@example.com>$
Date:   Mon Jan 5 19:00:00 2026 +0000$
$
    Tabs$
    $
            indented        with    tabs$
$ git log -1 --expand-tabs=4 | cat -A
commit 73a68be1cc1369ccc0d75ca1c4c64fe871be89f8$
Author: Ada Lovelace <ada@example.com>$
Date:   Mon Jan 5 19:00:00 2026 +0000$
$
    Tabs$
    $
        indented    with    tabs$
$ git log -1 --no-expand-tabs | cat -A
commit 73a68be1cc1369ccc0d75ca1c4c64fe871be89f8$
Author: Ada Lovelace <ada@example.com>$
Date:   Mon Jan 5 19:00:00 2026 +0000$
$
    Tabs$
    $
    ^Iindented^Iwith^Itabs$
$ git log -1 --expand-tabs | cat -A
commit 73a68be1cc1369ccc0d75ca1c4c64fe871be89f8$
Author: Ada Lovelace <ada@example.com>$
Date:   Mon Jan 5 19:00:00 2026 +0000$
$
    Tabs$
    $
            indented        with    tabs$
```

`cat -A` shows a tab as `^I`. The formats that indent messages by four spaces
turn tabs into spaces, every 8 columns by default, so that the indent does not
knock them out of line. `--expand-tabs=4` changes the width, `--expand-tabs` is
8, and `--no-expand-tabs` leaves the tabs alone.

A message written in the old ISO-8859-1 encoding instead of UTF-8:

```console
$ git cat-file commit HEAD | tail -3 | cat -A
encoding ISO-8859-1$
$
cafM-i au lait$
$ git log -1 --format='%e %s' | cat -A
ISO-8859-1 cafM-CM-) au lait$
$ git log -1 --format=%s --encoding=ISO-8859-1 | cat -A
cafM-i au lait$
```

The commit was made with `i18n.commitEncoding` set, and records the encoding in a
header of its own, which `git cat-file` shows (Chapter 6). `é` is one byte in ISO-8859-1,
shown by `cat -A` as `M-i`, and two in UTF-8, `M-CM-)`. log converted it to
UTF-8 by default; `--encoding` asks for another encoding.

`.mailmap` maps old names and addresses to current ones (Chapter 22):

```console
$ cat .mailmap
Grace Hopper <grace@example.com> Grace H <grace@old.example>
$ git log -1 --format='%an <%ae> | %aN <%aE>'
Grace H <grace@old.example> | Grace Hopper <grace@example.com>
$ git log -1 | grep Author
Author: Grace Hopper <grace@example.com>
$ git log -1 --no-mailmap | grep Author
Author: Grace H <grace@old.example>
$ git log -1 --no-use-mailmap | grep Author
Author: Grace H <grace@old.example>
$ git -c log.mailmap=false log -1 | grep Author
Author: Grace H <grace@old.example>
$ git -c log.mailmap=false log -1 --mailmap | grep Author
Author: Grace Hopper <grace@example.com>
$ git -c log.mailmap=false log -1 --use-mailmap | grep Author
Author: Grace Hopper <grace@example.com>
$ git log -1 --no-mailmap --format='%an | %aN'
Grace H | Grace Hopper
```

The commit was made as `Grace H <grace@old.example>`, and the built-in formats
print the mapped name. That is why log can show a name that differs from what is
stored. `--no-mailmap` and `log.mailmap=false` turn the mapping off, and
`--mailmap` or `--use-mailmap` back on. In a format of your own, `%an` is always
the stored name and `%aN` always the mapped one, even with `--no-mailmap`.

Revisions that do not exist can be ignored, and revisions can come from standard
input as well as the command line:

```console
$ git log --oneline --ignore-missing nosuch feature
ff8f73f Document multiply
ba5c7a0 Add multiply
e1e8cdc Add tests
f47fa3b Add the calculator
c44dc25 Add README
$ echo feature | git log --oneline --stdin
ff8f73f Document multiply
ba5c7a0 Add multiply
e1e8cdc Add tests
f47fa3b Add the calculator
c44dc25 Add README
```

Git's documentation adds that standard input can also carry options such as
`--all`, and paths after a line with `--`, and that a `--not` on one side, the
command line or the input, does not affect the other.

Two options add or remove starting points. `borrower` is a clone made with
`--shared`, which reads this repository's objects (Chapter 9), and has only
`main`:

```console
$ cd ../borrower
$ git log --oneline --all --no-walk
758934f Backport logging notes
$ git log --oneline --all --no-walk --alternate-refs
758934f Backport logging notes
cc42788 Add divide
ff8f73f Document multiply
e1e8cdc Add tests
9f9d4d2 A commit with a wrong clock
$ cd ../calc
$ git log --oneline --all --no-walk
758934f Backport logging notes
cc42788 Add divide
ff8f73f Document multiply
e1e8cdc Add tests
9f9d4d2 A commit with a wrong clock
$ git -c transfer.hideRefs=refs/tags log --oneline --exclude-hidden=fetch --all --no-walk
758934f Backport logging notes
ff8f73f Document multiply
e1e8cdc Add tests
9f9d4d2 A commit with a wrong clock
$ git -c uploadpack.hideRefs=refs/tags log --oneline --exclude-hidden=uploadpack --all --no-walk
758934f Backport logging notes
ff8f73f Document multiply
e1e8cdc Add tests
9f9d4d2 A commit with a wrong clock
$ git -c uploadpack.hideRefs=refs/tags log --oneline --exclude-hidden=receive --all --no-walk
758934f Backport logging notes
cc42788 Add divide
ff8f73f Document multiply
e1e8cdc Add tests
9f9d4d2 A commit with a wrong clock
```

`--alternate-refs` also starts from every commit that a ref of the borrowed-from
repository points to, its tags included. `transfer.hideRefs` is a server
setting: refs under the prefixes it lists are hidden from people fetching from or
pushing to the repository. `--exclude-hidden` leaves those refs out of the next
`--all` or `--glob`. Here it hid every tag, and `cc42788` disappeared because only the tag
`v1.1` pointed at it. `uploadpack.hideRefs` applies only to fetches and
`receive.hideRefs` only to pushes, so `--exclude-hidden=receive` ignored the
first of those.

> **Since Git 2.39.** `--exclude-hidden`.

## log and its neighbours

| Command | Shows | Use it when |
|---|---|---|
| `git log` | a list of commits, with every option in this chapter | you want history |
| `git show <commit>` | one commit with its diff, and also tags, trees and blobs (Chapter 18) | you want one object in detail |
| `git log -p A..B` | each commit's changes in turn | you want the changes commit by commit |
| `git diff A B` | the total change between two commits, as one diff (Chapter 13) | you want the net result |
| `git rev-list` | the same commit selection, as bare hashes (Chapter 22) | a script needs a list of commits |
| `git shortlog` | commits grouped by author (Chapter 22) | you want a summary, such as release notes |
| `git reflog` | where `HEAD` or a branch has pointed, in time order (Chapter 36) | you lost a commit |
| `git blame <file>` | the last commit for each line (Chapter 19) | you want to know who changed a line |
| `git log -S`, `git grep` | commits adding or removing text, or text in any version (Chapter 21) | you are searching history |

`git whatchanged` still exists and refuses to run. Git's list of breaking
changes nominates it for removal, calling `git log --raw` its rough equivalent,
and the command itself suggests `git log <options> --raw --no-merges` instead.

## The settings

| Setting | Effect |
|---|---|
| `format.pretty` | Default for `--pretty` |
| `pretty.<name>` | A named format |
| `log.abbrevCommit` | Make `--abbrev-commit` the default |
| `core.abbrev` | Length of short hashes; `auto` by default |
| `log.date` | Default for `--date`; `auto:<format>` only when using a pager |
| `log.decorate` | Default for `--decorate` |
| `log.excludeDecoration` | Refs to leave out of decorations. Since Git 2.27 |
| `log.initialDecorationSet` | `all` to decorate every kind of ref. Since Git 2.38 |
| `color.decorate.<slot>` | Colours of decorations: `branch`, `remoteBranch`, `tag`, `stash`, `HEAD`, `grafted` |
| `log.graphColors` | Colours for the lines of `--graph` |
| `log.follow` | Behave as if `--follow` were given when one path is |
| `log.diffMerges` | Format used by `-m` and `--diff-merges=on`; `separate` by default. Since Git 2.32 |
| `log.showRoot` | Show the root commit's changes; `true` by default |
| `log.showSignature` | Make `--show-signature` the default (Chapter 68) |
| `log.mailmap` | Apply `.mailmap`; `true` by default |
| `i18n.logOutputEncoding` | Encoding to show messages in; `i18n.commitEncoding` if that is set, otherwise UTF-8 |
| `core.pager`, `pager.log` | The pager, or none ([Chapter 13](#ch13-the-pager)) |
| `diff.*` | How `-p` and the other diff options look (Chapter 13) |
