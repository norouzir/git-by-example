# Chapter 36. reflog

## What it is

The *reflog* is a record of where each ref has pointed. Every time a branch or
`HEAD` moves — a commit, a checkout, a reset, a merge, a rebase — Git appends a
line saying where it was, where it went, when, and why.

It answers one question: *where was this branch before I broke it?*

That makes it the safety net under the whole of this part. A rewrite leaves the
old commits in the repository with nothing pointing at them (Chapter 28); the
reflog is the thing that still knows their names.

| Term | Means |
|---|---|
| *reflog* | the list of values a ref has held, newest first, kept per ref |
| *entry* | one line of it: old value, new value, who, when, and a message |
| *`<ref>@{<n>}`* | the value `<ref>` had `<n>` moves ago |
| *`<ref>@{<time>}`* | the value it had at that time |
| *unreachable* | a commit no branch or tag leads to; reflog entries about one expire sooner |
| *expire* | delete entries older than a cut-off, which `git gc` does on its own |

Two things to know before anything else. The reflog is **local**: it is never
cloned, fetched or pushed, so it knows only what *this* repository did. And it
**expires**: entries last 90 days by default, or 30 if what they point at is
unreachable, so the net is wide but not infinite.

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What is the reflog, and how is it different from the log?](#what-it-is)
- [What is it for, in one sentence?](#what-it-is)

**[Synopsis](#synopsis)**

- [What can I type after `git reflog`?](#synopsis)

**[Subcommands and options at a glance](#subcommands-and-options-at-a-glance)**

- [What are all the subcommands, and which are meant for me rather than for Git?](#subcommands-and-options-at-a-glance)

**[The example repository](#the-example-repository)**

- [What repository do the examples use?](#the-example-repository)

**[Reading the reflog](#reading-the-reflog)**

- [What do the columns in `git reflog` mean?](#reading-the-reflog)
- [Is the newest entry at the top or the bottom?](#reading-the-reflog)
- [Why do two entries have the same hash?](#reading-the-reflog)

**[The reflog of a branch](#the-reflog-of-a-branch)**

- [What is the difference between `git reflog` and `git reflog show main`?](#the-reflog-of-a-branch)
- [Why does the HEAD reflog have entries a branch's does not?](#the-reflog-of-a-branch)

**[Which refs have one](#which-refs-have-one)**

- [How do I list every ref that has a reflog?](#which-refs-have-one)
- [How do I check whether one particular ref has one?](#which-refs-have-one)

**[Naming an entry](#naming-an-entry)**

- [How do I refer to where my branch was two moves ago?](#naming-an-entry)
- [How do I say "where this branch was an hour ago"?](#naming-an-entry)
- [Why did Git warn me that the log does not go back that far?](#naming-an-entry)
- [What is the difference between `HEAD@{2}` and `HEAD~2`?](#head-2-is-not-head-2)

**[Seeing more with git log](#seeing-more-with-git-log)**

- [How do I see the reflog with dates, patches or a graph?](#seeing-more-with-git-log)
- [Which format placeholders show reflog information?](#seeing-more-with-git-log)
- [How do I search the reflog messages?](#seeing-more-with-git-log)

**[What writes an entry](#what-writes-an-entry)**

- [Which commands add a reflog entry, and what do the messages look like?](#what-writes-an-entry)
- [Does a command that changes no ref leave an entry?](#what-writes-an-entry)

**[Finding a commit you thought you lost](#finding-a-commit-you-thought-you-lost)**

- [I deleted a branch. How do I find what was on it?](#finding-a-commit-you-thought-you-lost)
- [How do I make a branch point at it again?](#finding-a-commit-you-thought-you-lost)
- [I know roughly what the message said. How do I search?](#searching-the-reflog)

**[Writing an entry by hand](#writing-an-entry-by-hand)**

- [Can I add a reflog entry myself, and why would I?](#writing-an-entry-by-hand)

**[Deleting entries](#deleting-entries)**

- [How do I remove one entry, or a whole reflog?](#deleting-entries)
- [What is the difference between `delete`, `drop` and `expire`?](#deleting-entries)
- [Does deleting an entry delete the commit?](#deleting-entries)
- [Can deleting an entry move the branch?](#moving-the-ref-with-the-entry)

**[When entries expire](#when-entries-expire)**

- [How long do reflog entries last?](#when-entries-expire)
- [Why is an entry gone after 30 days when I was told 90?](#when-entries-expire)
- [Can I stop them expiring at all?](#when-entries-expire)

**[Where reflogs are kept](#where-reflogs-are-kept)**

- [Where on disk is the reflog?](#where-reflogs-are-kept)
- [Why does my bare repository have no reflog?](#a-repository-with-no-reflog)
- [Why does a fresh clone's reflog have only one entry?](#a-fresh-clone)
- [Is the reflog pushed or fetched with the repository?](#a-fresh-clone)

**[reflog and its neighbours](#reflog-and-its-neighbours)**

- [Is `ORIG_HEAD` just a shortcut for a reflog entry?](#reflog-and-its-neighbours)
- [The commit is not in the reflog either. What now?](#reflog-and-its-neighbours)

**[The settings](#the-settings)**

- [Which settings control reflogs and their expiry?](#the-settings)

</details>

## Synopsis

```
git reflog [show] [<log-options>] [<ref>]
git reflog list
git reflog exists <ref>
git reflog write <ref> <old-oid> <new-oid> <message>
git reflog delete [--rewrite] [--updateref]
	[--dry-run | -n] [--verbose] <ref>@{<specifier>}...
git reflog drop [--all [--single-worktree] | <refs>...]
git reflog expire [--expire=<time>] [--expire-unreachable=<time>]
	[--rewrite] [--updateref] [--stale-fix]
	[--dry-run | -n] [--verbose] [--all [--single-worktree] | <refs>...]
```

| Part | Means |
|---|---|
| `<ref>` | which reflog: `HEAD` by default, or a branch, or a full name such as `refs/heads/main` |
| `<log-options>` | anything `git log` accepts, because `show` is `git log -g` |
| `<time>` | a date, a relative time such as `30.days.ago`, or the words `all` and `never` |

| Command | Does |
|---|---|
| `git reflog` | Show `HEAD`'s reflog, newest first |
| `git reflog show <branch>` | Show that branch's reflog |
| `git reflog list` | List every ref that has one |
| `git reflog expire --expire=<time> <ref>` | Delete entries older than `<time>` |
| `git reflog delete <ref>@{<n>}` | Delete one entry |
| `git reflog drop <ref>` | Delete the whole reflog of that ref |

## Subcommands and options at a glance

| Subcommand | Does | Covered in |
|---|---|---|
| `show` | Print a reflog; the default when no subcommand is given | [Reading the reflog](#reading-the-reflog) |
| `list` | List the refs that have a reflog | [Which refs have one](#which-refs-have-one) |
| `exists` | Exit 0 if that ref has one, for scripts | [Which refs have one](#which-refs-have-one) |
| `write` | Append an entry by hand | [Writing an entry by hand](#writing-an-entry-by-hand) |
| `delete` | Delete one entry, leaving the reflog | [Deleting entries](#deleting-entries) |
| `drop` | Delete a whole reflog | [Deleting entries](#deleting-entries) |
| `expire` | Delete entries older than a cut-off | [When entries expire](#when-entries-expire) |

| Option | Does | Covered in |
|---|---|---|
| `--expire=<time>` | Prune entries older than this; `all` and `never` are allowed | [When entries expire](#when-entries-expire) |
| `--expire-unreachable=<time>` | The same for entries about commits nothing reaches | [When entries expire](#when-entries-expire) |
| `-n`, `--dry-run` | Say what would be pruned, prune nothing | [When entries expire](#when-entries-expire) |
| `--verbose` | Print a line per entry | [When entries expire](#when-entries-expire) |
| `--all` | Every ref's reflog, not one | [Deleting entries](#deleting-entries) |
| `--single-worktree` | With `--all`, this worktree's refs only | Chapter 56 |
| `--updateref` | Move the ref to the newest surviving entry | [Moving the ref with the entry](#moving-the-ref-with-the-entry) |
| `--rewrite` | Fix up the old value of an entry whose predecessor was pruned | [Moving the ref with the entry](#moving-the-ref-with-the-entry) |
| `--stale-fix` | Prune entries pointing at broken commits; as expensive as `git prune` | [When entries expire](#when-entries-expire) |

<!-- no-example: --single-worktree  it only narrows --all to the current
     worktree, and the sandbox repositories have one worktree each, so the
     output is identical to --all; Chapter 56 makes a second worktree -->
<!-- no-example: --stale-fix  it prunes entries that point at commits with
     missing objects, which means deliberately corrupting a repository; that is
     Chapter 81, and the option is named here so a reader meets it -->

## The example repository

```console
$ git log --oneline --graph --all --decorate
* afbde37 (HEAD -> main) Add bread, with a rest
*   79300da Merge branch 'cake'
|\
| * 6401080 (cake) Add butter to the cake
| * bf2f513 Add cake
* | 8b517e8 Season the soup
|/
* d0d877a Add soup
* b2bc25e Add bread
* c382163 Start the collection
```

A recipe collection, built with enough different commands — commits, a branch,
a merge, an amend — that the reflog has something to say about each.

The examples run in order and change the repository as they go, so later
reflogs contain what earlier examples did. That is the point: a reflog is a
history of the session.

## Reading the reflog

```console
$ git reflog
afbde37 HEAD@{0}: commit (amend): Add bread, with a rest
8079913 HEAD@{1}: commit: Add bread
79300da HEAD@{2}: merge cake: Merge made by the 'ort' strategy.
8b517e8 HEAD@{3}: commit: Season the soup
d0d877a HEAD@{4}: checkout: moving from cake to main
6401080 HEAD@{5}: commit: Add butter to the cake
bf2f513 HEAD@{6}: commit: Add cake
d0d877a HEAD@{7}: checkout: moving from main to cake
d0d877a HEAD@{8}: commit: Add soup
b2bc25e HEAD@{9}: commit: Add bread
c382163 HEAD@{10}: commit (initial): Start the collection
```

Newest first, and every line is one movement of `HEAD`:

| Column | Is |
|---|---|
| `afbde37` | where the ref ended up after this move |
| `HEAD@{0}` | how to name that position: 0 is now, 1 is one move ago |
| `commit (amend):` | what kind of command moved it |
| `Add bread, with a rest` | the rest of the message, usually the commit's subject |

Three things are worth reading carefully. `d0d877a` appears three times,
because a checkout that changes branches without changing the commit still
records a move. `8079913` at `HEAD@{1}` is a commit that no longer exists in
any branch — it is the one the amend replaced. And `HEAD@{0}` is always where
you are now.

```console
$ git reflog -3
afbde37 HEAD@{0}: commit (amend): Add bread, with a rest
8079913 HEAD@{1}: commit: Add bread
79300da HEAD@{2}: merge cake: Merge made by the 'ort' strategy.
```

`git reflog` accepts `git log`'s options, because it *is* `git log` underneath:
Git's documentation defines `git reflog show` as an alias for
`git log -g --abbrev-commit --pretty=oneline`.

## The reflog of a branch

```console
$ git reflog show main -4
afbde37 main@{0}: commit (amend): Add bread, with a rest
8079913 main@{1}: commit: Add bread
79300da main@{2}: merge cake: Merge made by the 'ort' strategy.
8b517e8 main@{3}: commit: Season the soup
$ git reflog show cake
6401080 cake@{0}: commit: Add butter to the cake
bf2f513 cake@{1}: commit: Add cake
d0d877a cake@{2}: branch: Created from HEAD
```

Every ref has its own reflog. `main`'s holds only the moves of `main`, so the
two checkouts that appear in `HEAD`'s are not in it — `HEAD` moves whenever you
switch branches, and a branch does not.

That difference decides which one to use. `HEAD@{4}` counts every move
including switches, which is easy to get wrong; `main@{1}` counts only moves of
`main`, which is what you usually mean by "before I did that".

`cake`'s oldest entry is its creation, `branch: Created from HEAD`. A branch's
reflog starts when the branch does.

## Which refs have one

```console
$ git reflog list
HEAD
refs/heads/cake
refs/heads/main
$ git reflog exists refs/heads/cake && echo yes
yes
$ git reflog exists refs/heads/nosuch || echo no
no
```

`list` names every reflog in the repository. `exists` prints nothing and
answers with its exit status, which is what a script wants — Git's
documentation says as much.

> **Since Git 2.45.** `git reflog list`. On an older Git, `ls .git/logs/refs`
> is the equivalent.

## Naming an entry

```console
$ git log --oneline -1 HEAD@{2}
79300da Merge branch 'cake'
$ git log --oneline -1 main@{1}
8079913 Add bread
$ git rev-parse --short 'main@{1 hour ago}'
afbde37
$ git log --oneline -1 'main@{2 hours ago}'
8079913 Add bread
$ git log --oneline -1 'main@{2 weeks ago}'
warning: log for 'main' only goes back to Mon, 5 Jan 2026 09:00:00 +0000
c382163 Start the collection
$ git log --oneline -1 main@{9}
fatal: log for 'main' only has 7 entries
```

`@{...}` after a ref reads its reflog, and what goes inside is either a number
of moves or a time (Chapter 18). Any command that takes a revision takes these.

The two failures are worth knowing apart. A *time* before the reflog starts is
a warning and the oldest entry: Git assumes you want the earliest it knows. A
*number* beyond the end is a fatal error with the count, because there is no
sensible answer.

> **Windows.** The braces need quoting in some shells. In Git Bash and cmd
> `main@{1}` works unquoted; in PowerShell `@{` starts a hash table, so write
> `git log 'main@{1}'`. A time with spaces needs quotes everywhere.

### HEAD@{2} is not HEAD~2

```console
$ git log --oneline -1 HEAD@{2} && git log --oneline -1 HEAD~2
79300da Merge branch 'cake'
8b517e8 Season the soup
```

Two similar-looking notations that mean unrelated things. `HEAD~2` is two
commits back along the history — ancestry, the same for everyone who has the
repository. `HEAD@{2}` is two *moves* back in this clone's reflog — a record of
what you did, which nobody else has.

They can give the same answer, which makes the confusion worse. Here they do
not: the second move back was a merge, and the second parent back was the soup
commit.

## Seeing more with git log

```console
$ git log -g -3
commit afbde37118a183cc78e45c6e2f508d06cc24e120
Reflog: HEAD@{0} (Ada Lovelace <ada@example.com>)
Reflog message: commit (amend): Add bread, with a rest
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 16:00:00 2026 +0000

    Add bread, with a rest

commit 80799138a2fe9bf69850f04b26c3046acc05af1e
Reflog: HEAD@{1} (Ada Lovelace <ada@example.com>)
Reflog message: commit: Add bread
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 16:00:00 2026 +0000

    Add bread

commit 79300daf9060a23a99065871928c81d5ee158420
Reflog: HEAD@{2} (Ada Lovelace <ada@example.com>)
Reflog message: merge cake: Merge made by the 'ort' strategy.
Merge: 8b517e8 6401080
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 15:00:00 2026 +0000

    Merge branch 'cake'
```

`git log -g`, also spelled `--walk-reflogs`, walks the reflog instead of the
parents. Everything `git log` can do then applies: `-p` for the patches,
`--stat`, `--graph`, a date format (Chapter 17). The two extra headers name the
entry and its message.

```console
$ git log -g --oneline -3
afbde37 HEAD@{0}: commit (amend): Add bread, with a rest
8079913 HEAD@{1}: commit: Add bread
79300da HEAD@{2}: merge cake: Merge made by the 'ort' strategy.
$ git log -g --format='%gd | %gs | %h %s' -4
HEAD@{0} | commit (amend): Add bread, with a rest | afbde37 Add bread, with a rest
HEAD@{1} | commit: Add bread | 8079913 Add bread
HEAD@{2} | merge cake: Merge made by the 'ort' strategy. | 79300da Merge branch 'cake'
HEAD@{3} | commit: Season the soup | 8b517e8 Season the soup
$ git log -g --format='%gD' -2
HEAD@{0}
HEAD@{1}
```

`git log -g --oneline` is exactly what `git reflog` prints, which is the
clearest way to see that they are one command.

| Placeholder | Is |
|---|---|
| `%gd` | the short name, `main@{0}` |
| `%gD` | the long one, with the ref spelled out |
| `%gs` | the reflog message |
| `%gn`, `%ge` | who made the move, and their email |

```console
$ git log -g --grep-reflog=amend --format='%gd %gs'
HEAD@{0} commit (amend): Add bread, with a rest
$ git log --oneline --reflog | head -5
afbde37 Add bread, with a rest
8079913 Add bread
79300da Merge branch 'cake'
8b517e8 Season the soup
6401080 Add butter to the cake
```

`--grep-reflog` searches the reflog messages, as `--grep` searches commit
messages. `--reflog` is different again: it does not walk the reflog, it starts
an ordinary log from *every* commit any reflog mentions — which is how to see
commits that no branch reaches any more alongside the ones that are still
there.

## What writes an entry

```console
$ git switch -q cake && git switch -q main && git reflog -3
afbde37 HEAD@{0}: checkout: moving from cake to main
6401080 HEAD@{1}: checkout: moving from main to cake
afbde37 HEAD@{2}: commit (amend): Add bread, with a rest
$ git reset -q --hard HEAD~1 && git reflog -2
79300da HEAD@{0}: reset: moving to HEAD~1
afbde37 HEAD@{1}: checkout: moving from cake to main
$ git reset -q --hard HEAD@{1} && git reflog -2
afbde37 HEAD@{0}: reset: moving to HEAD@{1}
79300da HEAD@{1}: reset: moving to HEAD~1
$ git status --short && git reflog -1
afbde37 HEAD@{0}: reset: moving to HEAD@{1}
```

Anything that moves a ref writes an entry; anything that does not, does not.
`git status` added nothing, and neither would `git log`, `git diff` or a
command that failed.

| Message begins | Written by |
|---|---|
| `commit:` | an ordinary commit |
| `commit (initial):` | the first commit in a repository |
| `commit (amend):` | `git commit --amend` (Chapter 29) |
| `checkout: moving from X to Y` | `git switch` or `git checkout` (Chapter 24) |
| `reset: moving to X` | `git reset` (Chapter 30) |
| `merge <branch>:` | `git merge` (Chapter 25) |
| `rebase (start):`, `(pick):`, `(finish):` | the steps of a rebase (Chapter 33) |
| `branch: Created from X` | a new branch (Chapter 23) |
| `clone: from <url>` | the first entry in a clone (Chapter 9) |
| `pull:`, `fetch:` | updating from a remote (Chapter 41, Chapter 42) |

Note the third command: `git reset --hard HEAD@{1}` uses the reflog to undo the
reset before it, and is itself recorded. Undoing never removes entries; it adds
one, so you can undo the undo.

## Finding a commit you thought you lost

```console
$ git switch -q -c scratch main && git commit -q --allow-empty -m 'A note to self' && git log --oneline -1
ec5a9a4 A note to self
$ git switch -q main && git branch -D scratch
Deleted branch scratch (was ec5a9a4).
$ git log --oneline --all | grep 'A note to self' || echo 'not in any branch'
not in any branch
$ git reflog -3
afbde37 HEAD@{0}: checkout: moving from scratch to main
ec5a9a4 HEAD@{1}: commit: A note to self
afbde37 HEAD@{2}: checkout: moving from main to scratch
$ git log --oneline -1 ec5a9a4
ec5a9a4 A note to self
$ git branch -q rescued ec5a9a4 && git log --oneline --decorate -1 rescued
ec5a9a4 (rescued) A note to self
```

The whole recovery, in four steps: the branch is gone and `git log --all` does
not know the commit; `git reflog` still names it; the commit is still readable;
a new branch makes it reachable again.

Deleting the branch deleted its reflog too, which is why the answer came from
`HEAD`'s. `git branch -D` also printed the hash — `was ec5a9a4` — which is
worth copying before the terminal scrolls away.

The same shape works for a reset, a rebase, an amend or a bad merge: find the
entry from before, and give the commit a name. `git switch -c`, `git branch` and
`git reset --hard` all take a reflog name directly, so
`git reset --hard main@{1}` is often the whole fix (Chapter 30).

### Searching the reflog

```console
$ git log -g --grep='note to self' --format='%gd %gs'
HEAD@{1} commit: A note to self
$ git reflog show main --since='3 hours ago' | head -3
afbde37 main@{0}: reset: moving to HEAD@{1}
79300da main@{1}: reset: moving to HEAD~1
afbde37 main@{2}: commit (amend): Add bread, with a rest
```

When the reflog is hundreds of lines, search it. `--grep` matches the commit
message and `--grep-reflog` the reflog message; `--since` and `--until` narrow
by time, as in `git log` (Chapter 17).

## Writing an entry by hand

```console
$ git reflog write refs/heads/rescued ec5a9a42aab07542eac81b220313dfbd338a1160 afbde37118a183cc78e45c6e2f508d06cc24e120 'moved by hand'
$ git reflog show rescued
afbde37 rescued@{0}: moved by hand
ec5a9a4 rescued@{1}: branch: Created from ec5a9a4
$ git log --oneline --decorate -1 rescued
ec5a9a4 (rescued) A note to self
```

`write` appends an entry: the ref in full, the old object, the new object, and
a message. Both hashes must be complete and must name objects that exist.

Read the last command carefully. The reflog now claims `rescued` moved to
`afbde37`, and the branch is still at `ec5a9a4` — writing an entry does not
move anything. That is the point of the subcommand and the reason it is rarely
what you want: it is for tools that update refs by other means and need the
record to match.

> **Since Git 2.52.** `git reflog write`.

## Deleting entries

```console
$ git reflog delete --dry-run --verbose rescued@{0}
keep branch: Created from ec5a9a4
would prune moved by hand
$ git reflog delete rescued@{0} && git reflog show rescued
ec5a9a4 rescued@{0}: branch: Created from ec5a9a4
$ git reflog drop rescued
$ git reflog exists refs/heads/rescued || echo 'no reflog now'
no reflog now
$ git log --oneline --decorate -1 rescued
ec5a9a4 (rescued) A note to self
```

`delete` removes one named entry and leaves the rest; `drop` removes the whole
reflog of a ref. Neither touches the ref or any commit — `rescued` still points
where it did, and the commit is still there.

`--dry-run` with `--verbose` says what would happen, one line per entry, which
is worth doing first with anything that deletes.

| Subcommand | Removes | Leaves |
|---|---|---|
| `delete <ref>@{<n>}` | one entry | the reflog, and every other entry |
| `drop <ref>` | the whole reflog of that ref | the ref, and the commits |
| `drop --all` | every reflog in the repository | the same |
| `expire` | entries older than a cut-off | the newer ones |

Git's documentation says plainly that `delete` and `expire` are not usually run
by hand: `git gc` calls `expire` on its own schedule, and `delete` exists for
tools. `drop --all` is the one people do reach for, to make sure a repository
carries no record of what was done in it — see Chapter 37, and note that it
does not delete the objects.

### Moving the ref with the entry

```console
$ git switch -q -c demo main
$ git add demo.md && git commit -q -m 'Add a demo note' && git commit -q --allow-empty -m 'And another'
$ git reflog show demo && git log --oneline -1 demo
8b79bfc demo@{0}: commit: And another
0ce7847 demo@{1}: commit: Add a demo note
afbde37 demo@{2}: branch: Created from main
8b79bfc And another
$ git reflog delete --updateref --rewrite demo@{0}
$ git reflog show demo && git log --oneline -1 demo
0ce7847 demo@{0}: commit: Add a demo note
afbde37 demo@{1}: branch: Created from main
0ce7847 Add a demo note
```

`--updateref` is the exception to "deleting an entry changes nothing": when the
entry deleted is the newest one, the ref is moved to whatever is newest
afterwards. Here `demo` went back a commit because the entry that put it there
was removed.

`--rewrite` tidies up behind it. Each entry records both an old and a new value,
so removing one leaves the next entry claiming to start from a value that is no
longer above it; `--rewrite` fixes that old value so the chain reads correctly.
Both options work the same way with `expire`.

> **Careful.** `--updateref` moves a branch without making a commit or a reset,
> and leaves no entry saying so — the entry that would have recorded it is the
> one being deleted. It is the one reflog operation that can lose work.

## When entries expire

```console
$ git reflog show main | wc -l
9
$ git reflog expire --dry-run --verbose --expire=90.days.ago main
keep commit (initial): Start the collection
keep commit: Add bread
keep commit: Add soup
keep commit: Season the soup
keep merge cake: Merge made by the 'ort' strategy.
prune commit: Add bread
prune commit (amend): Add bread, with a rest
keep reset: moving to HEAD~1
keep reset: moving to HEAD@{1}
$ git reflog expire --dry-run --verbose --expire=90.days.ago --expire-unreachable=90.days.ago main
keep commit (initial): Start the collection
keep commit: Add bread
keep commit: Add soup
keep commit: Season the soup
keep merge cake: Merge made by the 'ort' strategy.
keep commit: Add bread
keep commit (amend): Add bread, with a rest
keep reset: moving to HEAD~1
keep reset: moving to HEAD@{1}
```

Two cut-offs, not one, and the first dry run shows why that matters. Every
entry here is hours old, well inside 90 days, and two of them would still be
pruned: they mention `8079913`, the commit the amend replaced, which nothing
reaches any more. Those fall under `--expire-unreachable`, which defaults to 30
days — and 30 days ago is also in the past here, because the sandbox pins
"now" to the example's own clock.

The second run sets both cut-offs and everything is kept, which is the proof
that the unreachable rule was what pruned them.

| Cut-off | Default | Applies to |
|---|---|---|
| `--expire=<time>`, `gc.reflogExpire` | 90 days | every entry |
| `--expire-unreachable=<time>`, `gc.reflogExpireUnreachable` | 30 days | entries about commits nothing reaches |

That is the answer to "the reflog is 90 days" being wrong in practice. The
entries you need after a rewrite are exactly the unreachable ones, and they get
the 30-day rule.

```console
$ git reflog expire --dry-run --verbose --expire=1.hour.ago main
prune commit (initial): Start the collection
prune commit: Add bread
prune commit: Add soup
prune commit: Season the soup
prune merge cake: Merge made by the 'ort' strategy.
prune commit: Add bread
prune commit (amend): Add bread, with a rest
prune reset: moving to HEAD~1
prune reset: moving to HEAD@{1}
$ git reflog expire --expire=1.hour.ago main && git reflog show main
$ git reflog show cake | wc -l
3
$ git reflog expire --expire=all cake && git reflog show cake
$ git log --oneline --decorate -1 cake
6401080 (cake) Add butter to the cake
```

Without `--dry-run` it happens: seven entries pruned, two left. `--expire=all`
prunes everything regardless of age, which empties the reflog — and `cake` is
still exactly where it was, because expiry deletes records, not commits.

`--expire=never` is the other end: it turns expiry off for that run.
`gc.reflogExpire=never` turns it off for good, which is one way to make the
safety net permanent at the cost of a repository that never forgets.

`--stale-fix` is a different job: it prunes entries that point at commits whose
objects are actually missing, which is repair rather than housekeeping
(Chapter 81). Git's documentation warns that it walks every reachable object,
so it costs as much as `git prune`.

## Where reflogs are kept

```console
$ ls .git/logs .git/logs/refs/heads
.git/logs:
HEAD
refs

.git/logs/refs/heads:
cake
main
$ cat .git/logs/refs/heads/main
$ git config core.logAllRefUpdates
true
```

One plain text file per ref, under `.git/logs`, mirroring the layout of
`.git/refs` (Chapter 70). Each line is: old value, new value, who, a Unix
timestamp with a zone, a tab, and the message. Oldest first — the reverse of
what `git reflog` prints.

`core.logAllRefUpdates` is what turns the whole thing on. Git's documentation
says it defaults to true in a repository with a working tree and false in a
bare one.

### A repository with no reflog

```console
$ git -C /home/ada/server.git config core.logAllRefUpdates
$ git push -q /home/ada/server.git main && git -C /home/ada/server.git reflog show main
$ ls /home/ada/server.git
HEAD
config
description
hooks
info
objects
refs
```

The bare repository has no value set, so the default applies and nothing is
recorded: `git reflog show main` prints nothing even after a push, and there is
no `logs` directory at all.

This is why a force-push is recoverable on your machine and not on the server
(Chapter 28). A hosting service may keep its own record — GitHub and GitLab
both do, by other means — but plain Git on a bare repository does not.
`git config core.logAllRefUpdates true` there turns it on.

### A fresh clone

```console
$ git -C /home/ada/clone reflog show main
afbde37 main@{0}: clone: from /home/ada/recipes
$ git -C /home/ada/clone log --oneline -3
afbde37 Add bread, with a rest
79300da Merge branch 'cake'
8b517e8 Season the soup
```

A clone copies commits, not reflogs. The new repository has the whole history
and a reflog with exactly one entry: the clone itself.

Nothing transfers a reflog — not `git clone`, `git fetch`, `git push` or
`git pull`. It is a record of what happened *here*, which is also worth
remembering the other way round: your reflog can show that you looked at a
branch, and nobody else can see it.

## reflog and its neighbours

```console
$ git log --oneline -1 ORIG_HEAD
79300da Merge branch 'cake'
$ git fsck --lost-found | head -4
dangling commit 80799138a2fe9bf69850f04b26c3046acc05af1e
dangling commit 8b79bfc19089225152845820820fc37119bd5f9a
```

| To find | Use | Chapter |
|---|---|---|
| where a ref used to point | `git reflog` | this chapter |
| where it was before the last big command | `ORIG_HEAD` | Chapter 30 |
| commits nothing points at, reflog included | `git fsck --lost-found` | Chapter 77 |
| a commit that is still on some branch | `git log --all --grep=...` | Chapter 17 |

`ORIG_HEAD` is not a reflog entry, though it often holds the same commit: it is
a ref that `git reset`, `git merge`, `git pull` and `git rebase` set before
they start (Chapter 30). It holds one value and the next such command
overwrites it, which is why the reflog is the reliable answer and `ORIG_HEAD`
the convenient one.

`git fsck` is the level below. It ignores refs entirely and looks for objects
nothing reaches, which finds work the reflog has forgotten or never knew about —
a staged change lost to `git reset --hard`, or a commit whose reflog entry has
expired. The `dangling commit` above is the one the amend replaced. Chapter 77
covers it, and Chapter 79 is the whole decision tree for recovering work.

## The settings

| Setting | Does |
|---|---|
| `core.logAllRefUpdates` | Whether reflogs are written; true with a working tree, false in a bare repository, and `always` to log every ref rather than branches, remotes, notes and `HEAD` |
| `gc.reflogExpire` | How long an entry lasts, 90 days by default; `never` keeps them |
| `gc.reflogExpireUnreachable` | The same for entries about unreachable commits, 30 days |
| `gc.<pattern>.reflogExpire` | The same, for refs matching a pattern such as `refs/stash` |
| `gc.auto` | How often `git gc`, and so the expiry, runs on its own (Chapter 77) |
| `fetch.writeCommitGraph`, `core.commitGraph` | Unrelated to reflogs, but the reason `git log --reflog` can be slower than `git log` on a large repository (Chapter 69) |
