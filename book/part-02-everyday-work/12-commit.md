# Chapter 12. commit

`git commit` turns whatever is in the index into a commit object and moves the
current branch to it. It never looks at your working tree, a point Chapter 5
demonstrates in detail.

## The plain form

```console
$ git commit -m 'Add the app'
[main (root-commit) e2f309a] Add the app
 1 file changed, 1 insertion(+)
 create mode 100644 app.py
```

That one line of output is worth reading properly:

| Part | Means |
|---|---|
| `main` | The branch you committed to |
| `(root-commit)` | This commit has no parent. You only see it once per history |
| `e2f309a` | The new commit's abbreviated hash |
| `Add the app` | The first line of your message |
| `1 file changed, 1 insertion(+)` | A summary of the diff |
| `create mode 100644 app.py` | A file was added, with its mode (Chapter 4) |

## When there is nothing to commit

```console
$ git commit -m 'Nothing here'
On branch main
nothing to commit, working tree clean
$ git commit -m 'Still nothing staged'
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   app.py

no changes added to commit (use "git add" and/or "git commit -a")
```

Two different situations with two different messages. The second one is the
common trap: you have edits, you just have not staged them. Git prints the
whole status rather than a one-line error, because the fix depends on what it
finds.

Both exit with a non-zero status, which matters in scripts.

## Committing everything tracked

```console
$ git commit -am 'Extend the app'
[main e48a23a] Extend the app
 1 file changed, 1 insertion(+)
$ git status --short
?? untracked.txt
```

`-a` stages every tracked file that changed, then commits. `untracked.txt` was
untouched because Git has never seen it. Chapter 5 has the full table of what
each "stage everything" form covers.

## The editor

With no `-m`, Git opens your editor with a template. Here it is, using `cat` as
the editor so you can see it:

```console
$ GIT_EDITOR='cat' git commit

# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
#
# On branch main
# Changes to be committed:
#	new file:   untracked.txt
#
Aborting commit due to empty commit message.
```

Everything starting with `#` is stripped before the message is saved. The
status summary is there so you can check what you are committing without
leaving the editor, and `git commit -v` adds the full staged diff below it.

Saving an empty file aborts the commit and changes nothing. That is the
standard way to back out once the editor is already open.

> **Careful.** If your editor returns immediately, Git sees an unchanged
> template, treats it as empty, and aborts. That is the symptom of a graphical
> editor configured without its wait flag. Chapter 3 has the table of correct
> values for each editor.

## Writing the message

```console
$ git commit -m 'Add the notes file' -m 'The file is a placeholder for now.' -m 'Refs: #42'
[main d485a1d] Add the notes file
 1 file changed, 1 insertion(+)
 create mode 100644 untracked.txt
$ git log -1 --pretty=format:'%B'
Add the notes file

The file is a placeholder for now.

Refs: #42
```

Repeating `-m` creates paragraphs, with a blank line between each. This is how
you write a full message without opening an editor, and it is the form to use
in scripts.

| Option | Message comes from |
|---|---|
| `-m <msg>` | The command line. Repeatable |
| `-F <file>` | A file. `-F -` reads standard input |
| `-C <commit>` | Another commit, reused as-is |
| `-c <commit>` | Another commit, opened in the editor first |
| `--squash <commit>`, `--fixup <commit>` | Generated for `rebase --autosquash` (Chapter 35) |
| neither | Your editor |

Chapter 53 covers what makes a message good. The short version: a summary line
under about fifty characters, a blank line, then prose explaining why.

## Author and committer

Every commit records two people and two timestamps:

```console
$ git log -1 --pretty=fuller
commit d485a1df4950caed131f2256af63069b2bbcc8ab
Author:     Ada Lovelace <ada@example.com>
AuthorDate: Mon Jan 5 11:00:00 2026 +0000
Commit:     Ada Lovelace <ada@example.com>
CommitDate: Mon Jan 5 11:00:00 2026 +0000

    Add the notes file
```

Usually they are identical and nobody notices. Set an author explicitly and
they separate:

```console
$ git log -1 --pretty=fuller
commit 73002b18f25ff99fa1dd0bee1044e60f5d025c87
Author:     Grace Hopper <grace@example.com>
AuthorDate: Mon Jan 5 12:00:00 2026 +0000
Commit:     Ada Lovelace <ada@example.com>
CommitDate: Tue Jan 6 11:46:40 2026 +0000

    Someone else wrote this
```

| Field | Is |
|---|---|
| Author | Who wrote the change |
| Committer | Who created this commit object |

They differ whenever you create a commit for somebody else's work: applying a
patch from a mailing list, cherry-picking, or rebasing. In all three the author
is preserved and the committer becomes you.

```console
$ git log -1 --pretty=format:'author=%an <%ae> %ad%ncommit=%cn <%ce> %cd' --date=iso
author=Grace Hopper <grace@example.com> 2026-01-05 12:00:00 +0000
commit=Ada Lovelace <ada@example.com> 2026-01-06 11:46:40 +0000
```

> **Careful.** `git log` shows the *author* date by default. So after a rebase,
> your commits keep their original dates and appear in an order that does not
> match when they were actually created. If you are wondering why a freshly
> rebased branch shows commits from last month, this is why. `--pretty=fuller`
> or `--date-order` shows the truth.

| To set | Use |
|---|---|
| Author name and email | `--author="Name <email>"` |
| Author date | `--date=<date>`, or `GIT_AUTHOR_DATE` |
| Committer name and email | `GIT_COMMITTER_NAME` and `GIT_COMMITTER_EMAIL` |
| Committer date | `GIT_COMMITTER_DATE` |

There is no `--committer` flag. The environment variables are the only way, and
Chapter 2 uses all four to make this book's hashes reproducible.

## Empty commits

```console
$ git commit -m 'Nothing changed'
On branch main
nothing to commit, working tree clean
$ git commit --allow-empty -m 'Deliberately empty'
[main a4364b5] Deliberately empty
$ git show --stat --oneline HEAD
a4364b5 Deliberately empty
```

An empty commit is a legal commit whose tree is identical to its parent's.
Notice the `git show --stat` output has no file list at all.

They are genuinely useful for marking a point in history, triggering a rebuild
on a system that watches for pushes, or starting a branch from a known empty
state. `--allow-empty-message` is the matching flag for a commit with no
message, which is much harder to justify.

## Amending

`--amend` replaces the last commit. Since objects are immutable (Chapter 6),
"replaces" means "builds a new one and moves the branch to it":

```console
$ git rev-parse HEAD
a4364b588d825e6fe5ab78895f03221287b742c6
$ git commit --amend -m 'Deliberately empty, now with content'
[main b10be63] Deliberately empty, now with content
 Date: Mon Jan 5 13:00:00 2026 +0000
 1 file changed, 1 insertion(+)
$ git rev-parse HEAD
b10be638d10d0b510d3a9a3d330b6c599baf9bea
```

A different hash. The old commit `a4364b5` still exists in the object database
and is reachable through the reflog (Chapter 36), which is what makes amending
recoverable.

To add forgotten changes without touching the message:

```console
$ git commit --amend --no-edit
[main 1c1e8fb] Deliberately empty, now with content
 Date: Mon Jan 5 13:00:00 2026 +0000
 1 file changed, 2 insertions(+)
$ git log -1 --pretty=fuller
commit 1c1e8fbe2350caf2e7206589469a0b92fe62c4d5
Author:     Ada Lovelace <ada@example.com>
AuthorDate: Mon Jan 5 13:00:00 2026 +0000
Commit:     Ada Lovelace <ada@example.com>
CommitDate: Mon Jan 5 14:00:00 2026 +0000
```

Amending keeps the author date and updates the committer date. That is why the
output started printing a `Date:` line: Git shows it when the two disagree.

| What amend can change | Flag |
|---|---|
| The message | `--amend -m '...'` or just `--amend` |
| The content | Stage it first, then `--amend --no-edit` |
| The author | `--amend --author='Name <email>'` |
| The author date | `--amend --date=<date>` |
| The committer date | `--amend --reset-author`, or `GIT_COMMITTER_DATE` |
| Nothing else | It cannot reach further back than one commit |

> **Careful.** Amending a commit you have already pushed rewrites shared
> history. Your next push will be rejected, and forcing it will break anyone
> who has pulled. Chapter 28 covers when this is acceptable and Chapter 43
> covers `--force-with-lease`, which is the safer way to do it.

## Reusing a message

```console
$ git commit --allow-empty -C HEAD
[main 41486c8] Deliberately empty, now with content
 Date: Mon Jan 5 13:00:00 2026 +0000
```

`-C` takes both the message and the author information from another commit.
`-c` does the same but opens the editor so you can adjust it first.
`--reset-author` on top of either makes you the author again.

## Empty messages abort

```console
$ git commit -m ''
Aborting commit due to empty commit message.
$ GIT_EDITOR='true' git commit
Aborting commit due to empty commit message.
$ git status --short
M  app.py
```

Both forms refuse and leave the index exactly as it was. Nothing is lost.

## What happens to your message

Git cleans the message up before storing it, and the rules depend on where it
came from:

| Mode | Does |
|---|---|
| `strip` | Remove leading and trailing blank lines, trailing whitespace, and comment lines, and collapse runs of blank lines |
| `whitespace` | Same, except `#` comment lines are kept |
| `verbatim` | Change nothing |
| `scissors` | Like `whitespace`, but also cut everything below a scissors line |
| `default` | `strip` if the message was edited, `whitespace` otherwise |

The default is the subtle one. A message you typed in the editor has its `#`
lines removed; a message from `-m` or `-F` does not, because you never saw a
template full of comments:

```console
$ git commit -F - <<'EOM'
Subject line

# this line looks like a comment
Body text.


EOM
[main fc1e4d4] Subject line
$ git log -1 --pretty=format:'%B' | cat -A | head -8
Subject line$
$
# this line looks like a comment$
Body text.$
```

The `#` line survived and the trailing blank lines were removed. That is
`whitespace` mode exactly as documented.

> **Careful.** This bites when a message legitimately starts a line with `#`,
> such as an issue reference at the start of a line, typed in the editor. It
> vanishes. Either indent it, put it mid-line, or set
> `git config set core.commentChar ';'` so `#` stops being special.

## Hooks

`git commit` runs up to four hooks, and Chapter 67 covers writing them:

| Hook | Runs | Can it stop the commit |
|---|---|---|
| `pre-commit` | Before the message is requested | Yes |
| `prepare-commit-msg` | Before the editor opens | Yes |
| `commit-msg` | After the message is written | Yes |
| `post-commit` | After the commit exists | No |

`--no-verify` skips `pre-commit` and `commit-msg`.

> **Careful.** `--no-verify` is for the moment a hook is broken and you need to
> commit anyway, not for the moment a hook is telling you something true. A
> team whose members routinely pass `--no-verify` has hooks that are too slow
> or too strict, and the fix is to the hooks.

## The options table

| Option | Does |
|---|---|
| `-m <msg>` | Message on the command line. Repeatable for paragraphs |
| `-F <file>` | Message from a file, or `-` for standard input |
| `-a`, `--all` | Stage every tracked change first |
| `--amend` | Replace the previous commit |
| `--no-edit` | Keep the existing message, do not open the editor |
| `-v`, `--verbose` | Show the staged diff in the editor. Twice shows the unstaged one too |
| `--allow-empty` | Permit a commit with no changes |
| `--allow-empty-message` | Permit a commit with no message |
| `--author=<author>` | Set the author |
| `--date=<date>` | Set the author date |
| `--reset-author` | Make yourself the author and reset the author date |
| `-C <commit>`, `--reuse-message` | Take message and authorship from another commit |
| `-c <commit>`, `--reedit-message` | Same, but edit first |
| `--fixup=<commit>`, `--squash=<commit>` | Prepare an autosquash commit (Chapter 35) |
| `-s`, `--signoff` | Add a `Signed-off-by` trailer |
| `--trailer <token>=<value>` | Add an arbitrary trailer |
| `-S`, `--gpg-sign` | Sign the commit (Chapter 68) |
| `-n`, `--no-verify` | Skip the `pre-commit` and `commit-msg` hooks |
| `--cleanup=<mode>` | How to tidy the message |
| `--dry-run` | Report what would be committed |
| `--short`, `--porcelain`, `--long` | Format for `--dry-run` output |
| `-p`, `--patch` | Choose hunks interactively, then commit |
| `-o`, `--only <path>` | Commit only these paths, ignoring the rest of the index |
| `-i`, `--include <path>` | Commit the index plus these paths |
| `--pathspec-from-file=<file>` | Read paths from a file |

> **Worth knowing.** `git commit -o <path>` is the one people never discover.
> It commits just those paths regardless of what else is staged, and leaves the
> rest of the index alone afterwards. It is the quickest way to split a
> too-large staged change into two commits without touching `git reset`.
