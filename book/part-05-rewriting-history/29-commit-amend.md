# Chapter 29. commit --amend

## What it is

`git commit --amend` replaces the commit at the tip of the current branch with
a new one. It is the smallest rewrite there is, and the one you will reach for
most often: the message was wrong, or a file was missing, and the commit has
not gone anywhere yet.

It answers one question: *how do I change the commit I just made?*

Nothing is edited. Git builds a second commit from the same parent, with
whatever message and content you give it, and moves the branch to the new
commit. The old one stays in the repository, reachable through the reflog,
until it expires (Chapter 28, Chapter 36).

| Term | Means |
|---|---|
| *amend* | replace the commit at `HEAD` with a new one built from the same parent |
| *the index* | what the next commit will contain; `git add` puts things in it (Chapter 5, Chapter 11) |
| *author* | who wrote the change, with the date they wrote it; set once and normally kept |
| *committer* | who created this commit object, with the date they did; replaced on every amend |
| *tree* | the snapshot of the files a commit points at (Chapter 6) |

`--amend` reaches exactly one commit back. To change something older, see
Chapter 34 for an interactive rebase and Chapter 35 for `git commit --fixup`
and `git history`.

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What does `--amend` change, and what does it leave alone?](#what-it-is)
- [Does it edit my last commit or make a new one?](#what-it-is)

**[Synopsis](#synopsis)**

- [What can I type after `git commit --amend`?](#synopsis)

**[Options at a glance](#options-at-a-glance)**

- [Which of `git commit`'s options mean something different with `--amend`?](#options-at-a-glance)

**[The example repository](#the-example-repository)**

- [What repository do the examples use?](#the-example-repository)

**[Changing the message](#changing-the-message)**

- [I typed the wrong commit message. How do I fix it?](#changing-the-message)
- [What is in the editor when I run `git commit --amend` with no options?](#the-editor-amend-opens)
- [How do I amend without the editor opening at all?](#keeping-the-message)
- [How do I take the new message from a file?](#a-message-from-a-file-or-from-another-commit)
- [Can I copy the message from another commit?](#a-message-from-a-file-or-from-another-commit)
- [I gave a message with `-m` and now want to edit it after all. Can I?](#a-message-from-a-file-or-from-another-commit)

**[Changing what the commit contains](#changing-what-the-commit-contains)**

- [I forgot a file in my last commit. How do I put it in?](#changing-what-the-commit-contains)
- [Do I have to run `git add` first?](#amending-without-staging-first)
- [I committed a file I did not mean to. How do I take it out?](#taking-a-file-back-out-of-the-commit)
- [Several things are staged and I only want to fix the message. How?](#amending-some-of-what-is-staged)
- [How do I add one more file without staging it first?](#amending-what-is-staged-plus-one-more-file)
- [What happens if I name a file on the command line?](#amending-a-path-from-the-working-tree)

**[What amend keeps and what it replaces](#what-amend-keeps-and-what-it-replaces)**

- [Does amending change the date on my commit?](#what-amend-keeps-and-what-it-replaces)
- [Why did the output grow a `Date:` line it did not have before?](#what-amend-keeps-and-what-it-replaces)
- [Does amending touch the commits before it?](#what-amend-keeps-and-what-it-replaces)
- [What happens to a tag, or to another branch on the same commit?](#what-amend-keeps-and-what-it-replaces)

**[Authorship and dates](#authorship-and-dates)**

- [I amended someone else's commit and it is still in their name. How do I make it mine?](#authorship-and-dates)
- [How do I set the author or the author date by hand?](#authorship-and-dates)
- [Why does `git log` show one date and `--pretty=fuller` show two?](#authorship-and-dates)

**[Amending a merge](#amending-a-merge)**

- [Can I amend a merge commit without flattening it?](#amending-a-merge)
- [How do I fix the message of a merge I just made?](#amending-a-merge)

**[Amending the first commit](#amending-the-first-commit)**

- [Can I amend the very first commit in a repository?](#amending-the-first-commit)

**[When amend refuses](#when-amend-refuses)**

- [`git commit --amend` says there is nothing to amend. Why?](#when-amend-refuses-nothing-to-amend)
- [Can I amend while a merge, cherry-pick or rebase is stopped?](#when-amend-refuses-something-is-in-progress)
- [Why did amend give a different error during a rebase than during a merge?](#when-amend-refuses-something-is-in-progress)
- [My amend would leave the commit with no changes. What then?](#when-amend-would-empty-the-commit)
- [Can a commit have no message at all?](#amending-with-no-message)
- [What does amending do when I am not on a branch?](#amending-when-head-is-detached)

**[Undoing an amend](#undoing-an-amend)**

- [I amended and want the old commit back. Where is it?](#undoing-an-amend)
- [I only want the old message back, not the old files. Can I?](#keeping-the-new-content-and-the-old-message)

**[Amending a commit you have pushed](#amending-a-commit-you-have-pushed)**

- [I amended a commit that is already pushed. What happens now?](#amending-a-commit-you-have-pushed)

**[Hooks](#hooks)**

- [Which hooks run when I amend?](#hooks)
- [How does a hook tell an amend from an ordinary commit?](#hooks)

**[amend and its neighbours](#amend-and-its-neighbours)**

- [What is the difference between amending and `git reset --soft HEAD~1`?](#amend-and-its-neighbours)
- [Git's documentation says they are roughly the same. Where is the "roughly"?](#where-the-two-stop-being-the-same)
- [How do I amend a commit that is not the last one?](#amend-and-its-neighbours)

**[The settings](#the-settings)**

- [Which settings change what amend does?](#the-settings)

</details>

## Synopsis

```
git commit --amend [--no-edit | -e] [-m <msg> | -F <file> | -C <commit> | -c <commit>]
                   [--reset-author] [--author=<author>] [--date=<date>]
                   [-a] [-i | -o] [--allow-empty] [--allow-empty-message]
                   [--no-post-rewrite] [-n] [-S[<keyid>]] [-q] [--] [<pathspec>...]
```

| Part | Means |
|---|---|
| `<msg>`, `<file>`, `<commit>` | where the new message comes from: typed, a file, or another commit |
| `<author>` | `Name <email>`, in that form, quotes included |
| `<date>` | any date Git accepts, such as `2026-03-01 09:00:00 +0000` or `yesterday` |
| `<pathspec>...` | files to take from the working tree into the amended commit |

| Command | Does |
|---|---|
| `git commit --amend` | Open an editor on the old message, commit the index |
| `git commit --amend --no-edit` | Keep the old message, commit the index |
| `git commit --amend -m <msg>` | Replace the message, commit the index |
| `git commit --amend -a --no-edit` | Also stage every tracked file's changes first |

## Options at a glance

The whole of `git commit` is in Chapter 12; these are the options that matter
when `--amend` is there.

### Options for the message

| Option | Does | Covered in |
|---|---|---|
| `--amend` | Replace the commit at `HEAD` | every section |
| `--no-edit` | Keep the existing message and do not open an editor | [Keeping the message](#keeping-the-message) |
| `-e`, `--edit` | Open the editor even when a message was given another way | [A message from a file, or from another commit](#a-message-from-a-file-or-from-another-commit) |
| `-m <msg>`, `--message=<msg>` | Use this message | [Changing the message](#changing-the-message) |
| `-F <file>`, `--file=<file>` | Take the message from a file, `-` for standard input | [A message from a file, or from another commit](#a-message-from-a-file-or-from-another-commit) |
| `-C <commit>`, `--reuse-message=<commit>` | Take the message and the authorship from another commit | [A message from a file, or from another commit](#a-message-from-a-file-or-from-another-commit) |
| `-c <commit>`, `--reedit-message=<commit>` | The same, then open the editor | [A message from a file, or from another commit](#a-message-from-a-file-or-from-another-commit) |
| `--allow-empty-message` | Allow the amended commit to have no message | [Amending with no message](#amending-with-no-message) |
| `--cleanup=<mode>` | How the message is tidied; the modes are in Chapter 12 | Chapter 12 |
| `-s`, `--signoff` | Add a `Signed-off-by` trailer | Chapter 12 |
| `--trailer <token>=<value>` | Add a trailer to the message | Chapter 53 |

### Options for authorship

| Option | Does | Covered in |
|---|---|---|
| `--reset-author` | Make yourself the author, with the date now | [Authorship and dates](#authorship-and-dates) |
| `--author=<author>` | Set the author to someone else | [Authorship and dates](#authorship-and-dates) |
| `--date=<date>` | Set the author date | [Authorship and dates](#authorship-and-dates) |

### Options for what goes in

| Option | Does | Covered in |
|---|---|---|
| `-a`, `--all` | Stage every tracked file's changes first | [Amending without staging first](#amending-without-staging-first) |
| `-o`, `--only` | Commit only the named paths; with no paths, only the message changes | [Amending some of what is staged](#amending-some-of-what-is-staged) |
| `-i`, `--include` | Commit what is staged plus the named paths | [Amending some of what is staged](#amending-some-of-what-is-staged) |
| `--allow-empty` | Allow the amended commit to contain no change | [When amend would empty the commit](#when-amend-would-empty-the-commit) |
| `-p`, `--patch`, `--interactive` | Choose changes to stage first, as in Chapter 11 | Chapter 11 |
| `--pathspec-from-file=<file>`, `--pathspec-file-nul` | Read the paths from a file instead of the command line | Chapter 11 |

### Options for hooks, signing and output

| Option | Does | Covered in |
|---|---|---|
| `--no-post-rewrite`, `--post-rewrite` | Skip the `post-rewrite` hook after an amend, or run it | [Hooks](#hooks) |
| `-n`, `--no-verify`, `--verify` | Skip the `pre-commit` and `commit-msg` hooks, or run them | Chapter 67 |
| `-S[<keyid>]`, `--gpg-sign[=<keyid>]`, `--no-gpg-sign` | Sign the amended commit | Chapter 68 |
| `-q`, `--quiet` | Do not print the summary | [Changing the message](#changing-the-message) |
| `-v`, `--verbose` | Put the diff in the editor | Chapter 12 |
| `--dry-run` | Say what would be committed and stop | Chapter 12 |
| `--fixup=<commit>`, `--squash=<commit>` | Prepare a commit to be folded into an older one instead of amending | Chapter 35 |

## The example repository

```console
$ git log --oneline --graph --all --decorate
* 3efe604 (pastry) Add the pastry list
| * 7d8b54c (HEAD -> main, tag: v1, keep) Add the cake list
|/
* fb49cc3 Add the bread list
* 98748bc Start the order book
$ git show --stat --oneline HEAD
7d8b54c Add the cake list
 cakes.md | 1 +
 1 file changed, 1 insertion(+)
```

A bakery's order book. `main` ends with `Add the cake list`, which is the
commit almost every example amends; a tag `v1` and a branch `keep` sit on it,
so that what happens to them is visible. `pastry` is one commit off `main~1`,
for the merge.

Every example starts with `git switch -C try main`, which puts a scratch branch
`try` at `main` and switches to it (Chapter 24), so each one begins from the
same commit no matter what the last one did. After the first, that line is
shown as `git switch -q -C try main` to keep the transcripts short.

Amending opens an editor unless told otherwise, and Git only opens one when it
is talking to a terminal, which the sandbox is not. The examples therefore
pass `-m` or `--no-edit`, or set `GIT_EDITOR` in the command itself, so that
what is printed behaves for a reader the way it behaves here.

## Changing the message

```console
$ git switch -C try main
Switched to a new branch 'try'
$ git commit --amend -m 'Add the cake list, with prices'
[try 11bd1ea] Add the cake list, with prices
 Date: Mon Jan 5 11:00:00 2026 +0000
 1 file changed, 1 insertion(+)
 create mode 100644 cakes.md
$ git log --oneline -2
11bd1ea Add the cake list, with prices
fb49cc3 Add the bread list
```

The message is replaced and nothing else is. The summary line names the new
commit, `11bd1ea` where `main` still has `7d8b54c`, and the file list is what
the commit contains compared with its parent — not what the amend changed.
That is worth remembering: `1 file changed, 1 insertion(+)` describes the whole
commit, exactly as it did the first time round.

The `Date:` line appears because the author date and the committer date are now
different; [What amend keeps and what it
replaces](#what-amend-keeps-and-what-it-replaces) explains why.

### The editor amend opens

```console
$ GIT_EDITOR=cat git commit --amend
Add the cake list, with prices

# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
#
# Date:      Mon Jan 5 11:00:00 2026 +0000
#
# On branch try
# Changes to be committed:
#	new file:   cakes.md
#
[try f99335d] Add the cake list, with prices
 Date: Mon Jan 5 11:00:00 2026 +0000
 1 file changed, 1 insertion(+)
 create mode 100644 cakes.md
```

With no message option, the editor opens on the *old* message, ready to be
edited — that is the difference from an ordinary `git commit`, which opens on
an empty message. Everything from `#` onwards is stripped out (Chapter 12), and
`Changes to be committed` lists what the amended commit will contain.

`GIT_EDITOR=cat` stands in for your editor opening: `cat` prints the file and
exits successfully, so Git takes the message unchanged. Saving without changing
anything has the same effect as `--no-edit`, except that the commit is still
rebuilt.

> **Careful.** Deleting every line in the editor and saving aborts the amend
> with `Aborting commit due to empty commit message.` and leaves the original
> commit alone. That is the way out if you opened the editor by mistake.

### Keeping the message

```console
$ git commit --amend --no-edit
[try 1439657] Add the cake list, with prices
 Date: Mon Jan 5 11:00:00 2026 +0000
 1 file changed, 1 insertion(+)
 create mode 100644 cakes.md
```

`--no-edit` is what you want when the message is fine and only the content is
changing. Note that the commit was still replaced — `1439657` is a third hash
for the same three-line message — because the committer date moved on.

### A message from a file, or from another commit

```console
$ git commit --amend -q -F msg.txt && git log -1 --format=%B
Add the cake list

Prices are per cake, not per slice.
```

`-F` takes the whole message, subject and body, from a file. `-F -` reads
standard input, which is how a script writes a message, and `%B` prints the
message back exactly as it was stored (Chapter 17).

```console
$ git commit --amend -q -C pastry && git log -1 --format='%s | %an %ad'
Add the pastry list | Ada Lovelace Mon Jan 5 12:00:00 2026 +0000
```

`-C <commit>` copies the message from another commit *and its authorship*: the
author name and the author date shown here are `pastry`'s, not the ones the
amended commit had. Add `--reset-author` if you want the message but not the
authorship.

```console
$ GIT_EDITOR=cat git commit --amend -q -c pastry
Add the pastry list

# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
#
# Date:      Mon Jan 5 12:00:00 2026 +0000
#
# On branch try
# Changes to be committed:
#	new file:   cakes.md
#
$ GIT_EDITOR=cat git commit --amend -q -e -m 'Add the cake list'
Add the cake list

# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
#
# Date:      Mon Jan 5 12:00:00 2026 +0000
#
# On branch try
# Changes to be committed:
#	new file:   cakes.md
#
$ git log -1 --format=%s
Add the cake list
```

Lower-case `-c` is `-C` and then the editor, so the copied message can be
adjusted before it is used. `-e` does the same for a message given any other
way: `-m` normally skips the editor, and `-e` puts it back, which is how you
start from a line you typed and finish it properly. Both are shown here with
`GIT_EDITOR=cat`, which prints the file and accepts it unchanged, so the final
message is the one that went in.

`-q` suppresses the summary; the examples use it where the summary has nothing
new to say.

## Changing what the commit contains

```console
$ git switch -q -C try main && git show --stat --oneline HEAD
7d8b54c Add the cake list
 cakes.md | 1 +
 1 file changed, 1 insertion(+)
$ git add cakes.md
$ git commit --amend --no-edit
[try 18d9c62] Add the cake list
 Date: Mon Jan 5 11:00:00 2026 +0000
 1 file changed, 2 insertions(+)
 create mode 100644 cakes.md
$ git show --stat --oneline HEAD
18d9c62 Add the cake list
 cakes.md | 2 ++
 1 file changed, 2 insertions(+)
```

This is the everyday use: a line was missing from `cakes.md`, it is written and
staged, and the amend folds it into the commit that should have had it. The
amended commit contains two lines where the original contained one, and there
is no second commit to explain.

An amend commits *the index*, exactly as an ordinary commit does. Anything
staged goes in, anything unstaged does not.

### Amending without staging first

```console
$ git commit --amend -a --no-edit
[try 049c8a2] Add the cake list
 Date: Mon Jan 5 11:00:00 2026 +0000
 1 file changed, 3 insertions(+)
 create mode 100644 cakes.md
$ git show --stat --oneline HEAD
049c8a2 Add the cake list
 cakes.md | 3 +++
 1 file changed, 3 insertions(+)
```

`-a` stages every tracked file's changes first, so `git add` is not needed. It
does not add files Git has never seen: a new file still has to be staged by
hand.

### Taking a file back out of the commit

```console
$ git switch -q -C try main
$ git add -A && git commit -q -m 'Add the tart list' && git show --stat --oneline HEAD
7c7cfc3 Add the tart list
 prices.ods.tmp | 1 +
 tarts.md       | 1 +
 2 files changed, 2 insertions(+)
$ git rm --cached -q prices.ods.tmp && git commit --amend --no-edit
[try 42bb7aa] Add the tart list
 Date: Mon Jan 5 22:00:00 2026 +0000
 1 file changed, 1 insertion(+)
 create mode 100644 tarts.md
$ git show --stat --oneline HEAD
42bb7aa Add the tart list
 tarts.md | 1 +
 1 file changed, 1 insertion(+)
$ git status --short
?? prices.ods.tmp
```

`git add -A` swept up a temporary file that should never have been committed.
`git rm --cached` takes it out of the index without deleting it from disk
(Chapter 15), and the amend then commits an index that no longer has it.

The file is now untracked, which is what `??` means (Chapter 10) — so the next
`git add -A` would put it back. Add it to `.gitignore` as well (Chapter 16).

> **Careful.** This removes the file from the *new* commit only. If the file
> was added several commits ago, or has been pushed, its content is still in
> the repository and amending does not help; that is Chapter 37.

### Amending some of what is staged

```console
$ git switch -q -C try main
$ git add cakes.md bread.md && git status --short
M  bread.md
M  cakes.md
$ git commit --amend --only -m 'Add the cake list, priced'
[try 13b60a8] Add the cake list, priced
 Date: Mon Jan 5 11:00:00 2026 +0000
 1 file changed, 1 insertion(+)
 create mode 100644 cakes.md
$ git status --short
M  bread.md
M  cakes.md
```

Two files are staged and neither belongs in the commit being amended — only the
message needs fixing. `--only` with no paths after it means "commit no paths at
all", so the amended commit has the same content as the original and both
staged changes are still staged afterwards, ready for a commit of their own.

Without `--only`, that same command would have swept both staged files into the
commit.

With paths, `--only` amends the commit with those paths and leaves the rest of
the index alone.

### Amending what is staged plus one more file

```console
$ git switch -q -C try main
$ git add cakes.md && git status --short
 M bread.md
M  cakes.md
$ git commit --amend --include bread.md --no-edit
[try aa1aeb9] Add the cake list
 Date: Mon Jan 5 11:00:00 2026 +0000
 2 files changed, 3 insertions(+)
 create mode 100644 cakes.md
$ git show --stat --oneline HEAD && git status --short
aa1aeb9 Add the cake list
 bread.md | 1 +
 cakes.md | 2 ++
 2 files changed, 3 insertions(+)
```

`--include` is the opposite of `--only`: it commits everything staged *plus*
the paths named, taking those from the working tree. Here `cakes.md` was staged
and `bread.md` was not, and both went in; `git status` afterwards is empty
because nothing is left over.

| Form | The amended commit gets |
|---|---|
| `git commit --amend` | everything staged |
| `git commit --amend --only` | nothing new; only the message changes |
| `git commit --amend --only <path>` | `<path>` from the working tree, nothing else staged |
| `git commit --amend --include <path>` | everything staged, plus `<path>` |
| `git commit --amend -a` | everything staged, plus every modified tracked file |

### Amending a path from the working tree

```console
$ git switch -q -C try main
$ git commit --amend --no-edit -- cakes.md
[try af2c4c8] Add the cake list
 Date: Mon Jan 5 11:00:00 2026 +0000
 1 file changed, 2 insertions(+)
 create mode 100644 cakes.md
$ git show --stat --oneline HEAD && git status --short
af2c4c8 Add the cake list
 cakes.md | 2 ++
 1 file changed, 2 insertions(+)
 M bread.md
```

Naming paths implies `--only`. Both `cakes.md` and `bread.md` had been edited
and neither was staged; the amended commit took `cakes.md` from the working
tree and left `bread.md` untouched — ` M` with the mark in the second column
meaning modified but not staged.

This is the same rule as `git commit <path>` in Chapter 12: a path on the
command line is read from the *working tree*, not from the index, and it does
not matter what was staged.

## What amend keeps and what it replaces

```console
$ git switch -q -C try main && git log -1 --pretty=fuller
commit 7d8b54c1024d6068347de1f114a4788f83f7f868
Author:     Ada Lovelace <ada@example.com>
AuthorDate: Mon Jan 5 11:00:00 2026 +0000
Commit:     Ada Lovelace <ada@example.com>
CommitDate: Mon Jan 5 11:00:00 2026 +0000

    Add the cake list
$ git log -1 --format='commit %h  tree %t  parent %p'
commit 7d8b54c  tree 5f4eb5e  parent fb49cc3
$ git commit --amend -q -a --no-edit && git log -1 --pretty=fuller
commit a71da24f85e773459842ff38fa0fdf264d712692
Author:     Ada Lovelace <ada@example.com>
AuthorDate: Mon Jan 5 11:00:00 2026 +0000
Commit:     Ada Lovelace <ada@example.com>
CommitDate: Tue Jan 6 03:00:00 2026 +0000

    Add the cake list
$ git log -1 --format='commit %h  tree %t  parent %p'
commit a71da24  tree f190cfd  parent fb49cc3
```

Side by side, with `--pretty=fuller` showing both identities and both dates
(Chapter 17):

| Part of the commit | After an amend |
|---|---|
| the commit's own name | new, always |
| the parent | the same, so nothing before it moves |
| the tree | the index at the moment of the amend |
| the message | the old one unless you replace it |
| the author and author date | kept |
| the committer and committer date | set to you, now |

`git log` without `--pretty=fuller` shows only the author date, which is why
an amended commit can look untouched in a log while being a different object.
It is also why `git commit` prints a `Date:` line in its summary after an
amend: Git adds that line when the two dates disagree, as a hint that the
commit is older than it looks.

```console
$ git log --oneline --decorate --all
a71da24 (HEAD -> try) Add the cake list
3efe604 (pastry) Add the pastry list
7d8b54c (tag: v1, main, keep) Add the cake list
fb49cc3 Add the bread list
98748bc Start the order book
```

Only the current branch moves. The tag `v1` and the branch `keep` still point
at `7d8b54c`, which is why the original is still in this listing at all: a tag
on a commit keeps it alive and reachable for as long as the tag exists
(Chapter 47), and an amend will not quietly take a release tag with it.

## Authorship and dates

```console
$ git switch -q -C try main && git log -1 --format='%an <%ae> %ad'
Ada Lovelace <ada@example.com> Mon Jan 5 11:00:00 2026 +0000
$ git commit --amend -q --author='Mary Berry <mary@example.com>' --no-edit && git log -1 --pretty=fuller
commit 5bf3784afeaff68c5b56ecf354d2039d7c88d2c6
Author:     Mary Berry <mary@example.com>
AuthorDate: Mon Jan 5 11:00:00 2026 +0000
Commit:     Ada Lovelace <ada@example.com>
CommitDate: Tue Jan 6 04:00:00 2026 +0000

    Add the cake list
```

`--author` sets who wrote it and keeps the author date. The committer is still
you: that pair is exactly how Git records "someone else wrote this, I applied
it", and it is why you can amend a colleague's commit without stealing it.

```console
$ git commit --amend -q --reset-author --no-edit && git log -1 --pretty=fuller
commit 4783f23b73de394ffa1a7a22ad6bcbd35c62699e
Author:     Ada Lovelace <ada@example.com>
AuthorDate: Tue Jan 6 05:00:00 2026 +0000
Commit:     Ada Lovelace <ada@example.com>
CommitDate: Tue Jan 6 05:00:00 2026 +0000

    Add the cake list
```

`--reset-author` does the opposite: it takes the authorship for yourself and
sets the author date to now, so both lines agree again. Use it when you have
rewritten someone else's commit enough that it is really yours, or when a
commit was made with the wrong `user.email` configured (Chapter 3).

```console
$ git commit --amend -q --date='2026-03-01 09:00:00 +0000' --no-edit && git log -1 --format='%ad | %cd'
Sun Mar 1 09:00:00 2026 +0000 | Tue Jan 6 06:00:00 2026 +0000
```

`--date` sets the author date alone. There is no `--committer-date`: the
committer date is always now, and the only way to set it is the
`GIT_COMMITTER_DATE` environment variable (Chapter 12).

> **Careful.** `--date` accepts anything Git can parse, including `yesterday`
> and `2 hours ago`, and it does not check that the result is sensible. A commit
> dated after the commits that follow it will sort strangely in `git log`, which
> orders by commit date within a topological pass (Chapter 17).

## Amending a merge

```console
$ git switch -q -C try main && git merge --no-edit pastry
Merge made by the 'ort' strategy.
 pastry.md | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 pastry.md
$ git log -1 --format='%h  parents %p  %s'
5a6ca5a  parents 7d8b54c 3efe604  Merge branch 'pastry' into try
$ git commit --amend -q -m 'Merge the pastry list into the order book'
$ git log -1 --format='%h  parents %p  %s'
8363285  parents 7d8b54c 3efe604  Merge the pastry list into the order book
$ git log --oneline --graph -4
*   8363285 Merge the pastry list into the order book
|\
| * 3efe604 Add the pastry list
* | 7d8b54c Add the cake list
|/
* fb49cc3 Add the bread list
```

A merge commit amends like any other, and keeps both parents: `%p` prints two
hashes before and after. The graph is unchanged apart from the message.

This is the usual way to fix the message Git generated for a merge, which is
often the wrong branch name or says nothing about why the merge happened
(Chapter 25). It also works for fixing the *content* of a merge — resolving a
conflict better, or removing something that should not have come across — by
editing the files, staging them, and amending.

> **Careful.** Amending a merge is one of the few places where
> `git reset --soft HEAD^` is not an equivalent: see [Where the two stop being
> the same](#where-the-two-stop-being-the-same).

## Amending the first commit

```console
$ git switch --orphan first-draft
Switched to a new branch 'first-draft'
$ git add notes.md && git commit -q -m 'Start the ideas list' && git log -1 --format='%h  parents [%p]  %s'
0b685d3  parents []  Start the ideas list
$ git commit --amend -q -m 'Start a list of ideas' && git log -1 --format='%h  parents [%p]  %s'
6ce3bc6  parents []  Start a list of ideas
```

A root commit — one with no parent, shown here by the empty brackets — amends
like any other. This is the one rewrite that an interactive rebase cannot do
without `--root` (Chapter 34), because there is nothing before it to start
from.

`git switch --orphan <name>` starts a branch with no history and an empty
working tree, which is how the example got a root commit to amend in a
repository that already had some (Chapter 24).

## When amend refuses

### When amend refuses: nothing to amend

```console
$ git switch --orphan nothing-yet
Switched to a new branch 'nothing-yet'
$ git commit --amend -m 'anything'
fatal: You have nothing to amend.
```

There is no commit to replace. This is what you get in a repository where
nothing has been committed yet, and on a branch that has just been created with
`--orphan`.

### When amend refuses: something is in progress

```console
$ git switch -q -C try main && git switch -q -c rival main~1
$ git switch -q try && git merge rival
Auto-merging cakes.md
CONFLICT (add/add): Merge conflict in cakes.md
Automatic merge failed; fix conflicts and then commit the result.
$ git commit --amend --no-edit
fatal: You are in the middle of a merge -- cannot amend.
$ git merge --abort
```

While a merge is unfinished, `HEAD` is still the commit before the merge, and
amending it would throw the merge away without saying so. Git refuses instead.
Finish the merge, then amend the merge commit if you want to.

```console
$ git cherry-pick rival
Auto-merging cakes.md
CONFLICT (add/add): Merge conflict in cakes.md
error: could not apply 79846f0... A different cake list
...
$ git commit --amend --no-edit
fatal: You are in the middle of a cherry-pick -- cannot amend.
$ git cherry-pick --abort
```

The same for a stopped cherry-pick, with the command named in the message
(Chapter 32).

```console
$ git rebase rival
Rebasing (1/1)
Auto-merging cakes.md
CONFLICT (add/add): Merge conflict in cakes.md
error: could not apply 7d8b54c... Add the cake list
...
$ git commit --amend --no-edit
error: Committing is not possible because you have unmerged files.
hint: Fix them up in the work tree, and then use 'git add/rm <file>'
hint: as appropriate to mark resolution and make a commit.
fatal: Exiting because of an unresolved conflict.
U	cakes.md
$ git rebase --abort
```

A stopped rebase gives a different message, because the objection is different:
there are unmerged files in the index, and no commit of any kind can be made
until they are resolved (Chapter 26). The `U` line lists them.

Once they *are* resolved, amending during a rebase is allowed, and is exactly
what a rebase stopped at an `edit` instruction expects you to do — Git even
prints the command to run. Chapter 34 shows it.

### When amend would empty the commit

```console
$ git switch -q -C try main && git rm -q cakes.md
$ git commit --amend --no-edit
You asked to amend the most recent commit, but doing so would make
it empty. You can repeat your command with --allow-empty, or you can
remove the commit entirely with "git reset HEAD^".
On branch try
No changes
$ git commit --amend --no-edit --allow-empty
[try 5e9a1ff] Add the cake list
 Date: Mon Jan 5 11:00:00 2026 +0000
$ git show --stat --oneline HEAD
5e9a1ff Add the cake list
```

Removing the only file the commit added leaves it with nothing to say, and Git
stops to ask whether that is what you meant. The message gives both answers:
`--allow-empty` to keep an empty commit, or `git reset HEAD^` to remove the
commit and keep the change staged (Chapter 30) — which is usually what you
actually want.

An empty commit is a legitimate thing to have; `git show --stat` simply has no
file list to print.

### Amending with no message

```console
$ git switch -q -C try main
$ git commit --amend -q -a --allow-empty-message -m '' && git log -2 --format='[%s]'
[]
[Add the bread list]
```

A commit with no message at all is possible, and takes an explicit option to
say you meant it. It is worth knowing mostly because it explains the error when
you did *not* mean it: without `--allow-empty-message`, an empty message aborts
the amend and leaves the original commit alone.

### Amending when HEAD is detached

```console
$ git switch -q -C try main && git switch -q --detach
$ git commit --amend -q -a --no-edit && git log --oneline -1
fc55816 Add the cake list
$ git status -sb
## HEAD (no branch)
$ git log --oneline --decorate -1 try
7d8b54c (tag: v1, try, main, keep) Add the cake list
```

With `HEAD` detached, the amend works and moves `HEAD` — but no branch follows
it, so `try` is still on the original commit, and the amended commit is
reachable only through the reflog once you switch away (Chapter 24).

This is the one case where amending can genuinely lose work, so check
`git status` first: `## HEAD (no branch)` is the warning.

## Undoing an amend

```console
$ git switch -q -C try main
$ git commit --amend -q -a -m 'Add the cake list, priced' && git log --oneline -1
7c60553 Add the cake list, priced
$ git reflog show try -3
7c60553 try@{0}: commit (amend): Add the cake list, priced
7d8b54c try@{1}: branch: Reset to main
b652035 try@{2}: commit (amend):
$ git reset --hard try@{1}
HEAD is now at 7d8b54c Add the cake list
$ git log --oneline -1 && git show --stat --oneline HEAD
7d8b54c Add the cake list
7d8b54c Add the cake list
 cakes.md | 1 +
 1 file changed, 1 insertion(+)
```

An amend is recorded in the reflog as `commit (amend):`, and the entry below it
is where the branch stood beforehand. `try@{1}` names that position — the hash
printed on a reflog line is where the ref stood at that point — so
`git reset --hard try@{1}` puts the branch and the files back as they were
before the amend (Chapter 30, Chapter 36).

`--hard` throws away the working tree changes too. Use
`git reset --soft try@{1}` to put the branch back but keep the edits staged,
ready to amend again more carefully.

> **Careful.** `@{1}` counts moves of the ref, not amends. `HEAD@{1}` works
> the same way but counts every move of `HEAD`, switching branches included, so
> it is easy to be off by one; naming the branch is safer. Here `try@{1}` is
> the `branch: Reset to main` entry, because that is how each example in this
> chapter recreates the scratch branch. Read the reflog rather than counting in
> your head.

### Keeping the new content and the old message

```console
$ git commit --amend -q -a -m 'Cakes' && git log -1 --format=%s
Cakes
$ git commit --amend -q -C try@{1} && git log -1 --format=%s && git show --stat --oneline HEAD
Add the cake list
a42932e Add the cake list
 cakes.md | 2 ++
 1 file changed, 2 insertions(+)
```

When only the message went wrong, there is no need to undo the whole amend:
`-C try@{1}` amends again, taking the message and authorship from the commit as
it was before, and keeps the content you had just fixed.

## Amending a commit you have pushed

An amend replaces a commit, so a commit that has been pushed and then amended
leaves your branch and its upstream diverged, your next push rejected, and
anyone who has the original needing to recover from it.

That is the whole subject of Chapter 28: the test for whether it is safe, how
to check what a force-push would throw away, and what the other people have to
run. Chapter 43 covers `git push --force-with-lease` itself.

The rule of thumb is small enough to keep here: amend freely until you push,
and after that only on a branch you are sure is yours alone.

## Hooks

```console
$ git switch -q -C try main && git commit --amend -q -m 'Cakes, and a hook' && git log --oneline -1
post-rewrite: amend
7d8b54c1024d6068347de1f114a4788f83f7f868 079668783ec07727fa82b57df760bb1c15a861a6
0796687 Cakes, and a hook
$ git commit --amend -q --no-post-rewrite -m 'Cakes, without the hook' && git log --oneline -1
6acb8a8 Cakes, without the hook
```

An amend runs the same `pre-commit` and `commit-msg` hooks as any commit, and
then one more: `post-rewrite`, which exists to tell tools that a commit has been
replaced. It is called with the argument `amend`, and is fed the old and new
hashes on standard input — the two lines above are the example hook printing
both. `git rebase` calls the same hook with `rebase`.

`--no-post-rewrite` skips it. `--no-verify` skips the other two (Chapter 67).

```console
$ GIT_EDITOR=cat git commit --amend
Cakes, without the hook

# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
#
# Date:      Mon Jan 5 11:00:00 2026 +0000
#
# On branch try
# Changes to be committed:
#	new file:   cakes.md
#
# the hook was called with: commit HEAD
[try e5fe7d4] Cakes, without the hook
 Date: Mon Jan 5 11:00:00 2026 +0000
 1 file changed, 1 insertion(+)
 create mode 100644 cakes.md
```

`prepare-commit-msg` runs before the editor and can change the message. On an
amend it is told the source is `commit` and the commit is `HEAD`, which is how
a hook distinguishes an amend from an ordinary commit, a merge or a template.
Chapter 67 covers all of them.

## amend and its neighbours

```console
$ git switch -q -C try main
$ git add cakes.md && git commit --amend -q --no-edit && git rev-parse HEAD
e3f605a540dadc4e33e6c529ae0a0f8d4a5f5265
$ git switch -q -C try2 main
$ git add cakes.md && git reset -q --soft HEAD^ && git commit -q -C ORIG_HEAD && git rev-parse HEAD
e3f605a540dadc4e33e6c529ae0a0f8d4a5f5265
```

Git's documentation describes `--amend` as a rough equivalent of
`git reset --soft HEAD^` followed by `git commit -c ORIG_HEAD`, and on an
ordinary commit the two really do produce the same object: the same forty
characters, from the same starting commit with the same change staged.

`git reset --soft` moves the branch back one commit and leaves the index and
working tree alone, so the index still holds the staged change on top of the
older parent; `ORIG_HEAD` is where the branch was before the reset (Chapter 30),
and `-C` takes the message and authorship from it. The example uses `-C` rather
than the documentation's `-c` only because `-c` opens an editor.

### Where the two stop being the same

```console
$ git switch -q -C try3 main && git merge --no-edit pastry
Merge made by the 'ort' strategy.
 pastry.md | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 pastry.md
$ git log -1 --format='%h  parents %p'
9b42260  parents 7d8b54c 3efe604
$ git reset -q --soft HEAD^ && git commit -q -C ORIG_HEAD && git log -1 --format='%h  parents %p'
55cfa53  parents 7d8b54c
```

On a merge commit they are not equivalent at all. `HEAD^` is the *first*
parent, so the reset moves the branch to the side the merge was made on, and
the commit that follows has one parent: the merge is gone and its second parent
with it. `git commit --amend` keeps both, as [Amending a
merge](#amending-a-merge) showed.

The other differences are small but worth knowing: the two-command form sets
`ORIG_HEAD` and writes two reflog entries rather than one, and it briefly
leaves the branch one commit shorter, which matters if anything else reads the
repository in between.

**And the neighbours that reach further back.** `--amend` only ever touches
`HEAD`. For anything older:

| What you want | Command | Chapter |
|---|---|---|
| Change the last commit | `git commit --amend` | this chapter |
| Change an older commit's message | `git rebase -i`, with `reword` | Chapter 34 |
| Change an older commit's message, in one command | `git history reword <commit>` | Chapter 35 |
| Fold a fix into an older commit | `git commit --fixup=<commit>` then `git rebase --autosquash` | Chapter 35 |
| Fold a staged fix into an older commit, in one command | `git history fixup <commit>` | Chapter 35 |
| Split the last commit in two | `git reset HEAD^` then commit twice | Chapter 30 |
| Undo the last commit and keep the changes | `git reset --soft HEAD^` | Chapter 30 |
| Undo a commit other people have | `git revert` | Chapter 31 |

## The settings

`git commit --amend` has no settings of its own; it takes the same ones as
`git commit` (Chapter 12). These are the ones that change what an amend does.

| Setting | Does |
|---|---|
| `core.editor` | Which editor opens on the old message; `GIT_EDITOR` overrides it (Chapter 62) |
| `commit.cleanup` | How the message is tidied before it is stored (Chapter 12) |
| `commit.status` | Whether the `Changes to be committed` block appears in the editor (Chapter 12) |
| `commit.verbose` | Whether the diff appears in the editor too (Chapter 12) |
| `commit.gpgSign` | Sign every commit, amended ones included (Chapter 68) |
| `user.name`, `user.email` | Who the committer is, and the author unless one is kept or given (Chapter 3) |
