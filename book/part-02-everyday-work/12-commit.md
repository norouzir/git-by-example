# Chapter 12. commit

## What it is

`git commit` turns whatever is in the index into a commit object and moves the
current branch to it. It never looks at your working tree, a point Chapter 5
demonstrates in detail. The exceptions are the options that stage something
first, such as `-a` or a list of paths, and they are covered below.

A commit records a snapshot of the whole project, the commit it follows (its
*parent*), who made it and when, and a message (Chapter 6). It is local: nothing
is sent anywhere, and nobody else sees it until you push (Chapter 43).

The plain form answers one question: "record what I have staged, with this
message". Everything else in this chapter changes where the content, the
message, or the names and dates come from.

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What does `git commit` save, and does it send anything to the server?](#what-it-is)

**[Synopsis](#synopsis)**

- [What can I type after `git commit`?](#synopsis)

**[Options at a glance](#options-at-a-glance)**

- [Is there a list of every option, and where each is explained?](#options-at-a-glance)

**[The plain form](#the-plain-form)**

- [What does the line `[main (root-commit) e2f309a]` mean?](#the-plain-form)
- [What does commit print when I'm not on a branch?](#the-plain-form)
- [Can I make commit print nothing?](#the-plain-form)

**[When there is nothing to commit](#when-there-is-nothing-to-commit)**

- [I edited files but commit says "no changes added to commit". Why?](#when-there-is-nothing-to-commit)
- [How can a script tell that a commit did not happen?](#when-there-is-nothing-to-commit)

**[Committing everything tracked](#committing-everything-tracked)**

- [Does `git commit -a` include new files? Deleted files?](#committing-everything-tracked)

**[Committing some paths](#committing-some-paths)**

- [I have several files staged. Can I commit just one of them?](#committing-some-paths)
- [What is the difference between `git commit <file>` and `git add <file>` then `git commit`?](#committing-some-paths)
- [What do `--only` and `--include` do?](#committing-some-paths)

**[Choosing hunks while committing](#choosing-hunks-while-committing)**

- [Can I pick parts of a file directly in `git commit`?](#choosing-hunks-while-committing)

**[The editor](#the-editor)**

- [What is the text Git puts in the editor, and do I need to delete it?](#the-editor)
- [How do I get out of the editor without committing?](#the-editor)
- [Can I see the diff while writing the message?](#seeing-the-changes-while-you-write)
- [Can I stop the file list from appearing in the editor?](#seeing-the-changes-while-you-write)
- [Can my team start every message from the same outline?](#a-template-to-start-from)
- [I gave `-m` but want to tweak the message in the editor. How?](#a-template-to-start-from)

**[Writing the message](#writing-the-message)**

- [How do I write a message with several paragraphs without an editor?](#writing-the-message)
- [How do I take the message from a file or from another program?](#writing-the-message)
- [Can I reuse the message of an earlier commit?](#reusing-a-message)

**[Author and committer](#author-and-committer)**

- [Why does a commit have both an author and a committer?](#author-and-committer)
- [How do I commit on behalf of someone else, or with a different date?](#author-and-committer)
- [Git says "Author identity unknown". What do I do?](#where-the-names-come-from)
- [Can I use a different name or email in one repository?](#where-the-names-come-from)

**[Empty commits](#empty-commits)**

- [Can I make a commit that changes nothing? Why would I?](#empty-commits)

**[Amending](#amending)**

- [How do I fix the message or add a forgotten file to the last commit?](#amending)
- [Can I change only the message while other changes are staged?](#amending)
- [Can I amend the very first commit?](#amending)

**[Empty messages abort](#empty-messages-abort)**

- [What happens if I leave the message empty?](#empty-messages-abort)

**[What happens to your message](#what-happens-to-your-message)**

- [Why did a line starting with `#` disappear from my message?](#what-happens-to-your-message)
- [What exactly do the `--cleanup` modes change?](#every-cleanup-mode)
- [What is the "scissors" line?](#every-cleanup-mode)
- [How do I keep `#` lines in messages I type in the editor?](#choosing-the-comment-character)

**[Trailers](#trailers)**

- [What is `Signed-off-by`, and how do I add it or other lines like it?](#trailers)

**[Commits meant to be squashed](#commits-meant-to-be-squashed)**

- [What do `fixup!`, `squash!` and `amend!` commits contain?](#commits-meant-to-be-squashed)

**[Hooks](#hooks)**

- [A hook stopped my commit. How do I get past it, and should I?](#hooks)
- [Where did my message go when a hook refused the commit?](#hooks)
- [Which hooks does `--no-verify` not skip?](#hooks)

**[A dry run](#a-dry-run)**

- [Can I see what a commit would contain without making it?](#a-dry-run)

**[Finishing a merge](#finishing-a-merge)**

- [Why does `git commit <file>` fail during a merge?](#finishing-a-merge)

**[Signing](#signing)**

- [How do I turn off signing for one commit?](#signing)

**[Undoing a commit](#undoing-a-commit)**

- [I committed too early or with the wrong message. How do I undo it?](#undoing-a-commit)

**[commit and its neighbours](#commit-and-its-neighbours)**

- [What is `git commit-tree`, and how is it different?](#commit-and-its-neighbours)
- [Which "commit" option do I need for which situation?](#commit-and-its-neighbours)

**[The settings](#the-settings)**

- [Which settings change how `git commit` behaves?](#the-settings)

</details>

## Synopsis

```
git commit [-a | --interactive | --patch] [-s] [-v] [-u[<mode>]] [--amend]
           [--dry-run] [(-c | -C | --squash) <commit> | --fixup [(amend|reword):]<commit>]
           [-F <file> | -m <msg>] [--reset-author] [--allow-empty]
           [--allow-empty-message] [--no-verify] [-e] [--author=<author>]
           [--date=<date>] [--cleanup=<mode>] [--[no-]status]
           [-i | -o] [--pathspec-from-file=<file> [--pathspec-file-nul]]
           [(--trailer <token>[(=|:)<value>])...] [-S[<keyid>]]
           [--] [<pathspec>...]
```

| Part | Means |
|---|---|
| `<pathspec>` | Commit the current content of these tracked paths, ignoring what else is staged. See [Committing some paths](#committing-some-paths) |
| `<commit>` | A commit, named any way Chapter 18 describes: a hash, a branch, `HEAD~1` |
| `--` | Everything after it is a path |

| Command | Does |
|---|---|
| `git commit` | Commit the index, writing the message in the editor |
| `git commit -m <msg>` | Commit the index with this message |
| `git commit -a` | Stage every change to tracked files, then commit |
| `git commit <path>` | Commit only these paths, as they are in the working tree |
| `git commit --amend` | Replace the last commit |

## Options at a glance

| Option | Does | Covered in |
|---|---|---|
| `-q`, `--quiet` | Print nothing after a successful commit | [The plain form](#the-plain-form) |
| `-a`, `--all` | Stage every tracked change first | [Committing everything tracked](#committing-everything-tracked) |
| `-o`, `--only` | Commit only the paths given, ignoring the rest of the index. The default when paths are given | [Committing some paths](#committing-some-paths) |
| `-i`, `--include` | Commit the index plus these paths | [Committing some paths](#committing-some-paths) |
| `--pathspec-from-file=<file>` | Read paths from a file | [Committing some paths](#committing-some-paths) |
| `--pathspec-file-nul` | Those paths are NUL-separated | [Committing some paths](#committing-some-paths) |
| `-p`, `--patch` | Choose hunks interactively, then commit | [Choosing hunks while committing](#choosing-hunks-while-committing) |
| `-U<n>`, `--unified=<n>` | Context lines for `-p` | [Choosing hunks while committing](#choosing-hunks-while-committing) |
| `--inter-hunk-context=<n>` | Join nearby hunks for `-p` | [Choosing hunks while committing](#choosing-hunks-while-committing) |
| `--interactive` | Choose with the `git add -i` menu, then commit | [Choosing hunks while committing](#choosing-hunks-while-committing) |
| `-v`, `--verbose` | Show the staged diff in the editor. Twice shows the unstaged one too | [Seeing the changes while you write](#seeing-the-changes-while-you-write) |
| `-u<mode>`, `--untracked-files=<mode>` | Which untracked files the editor template lists; the modes are Chapter 10's | [Seeing the changes while you write](#seeing-the-changes-while-you-write) |
| `--status`, `--no-status` | Include the status in the editor template, or leave it out | [Seeing the changes while you write](#seeing-the-changes-while-you-write) |
| `-t <file>`, `--template=<file>` | Start the message in the editor from a file | [A template to start from](#a-template-to-start-from) |
| `-e`, `--edit` | Open the editor even though the message came from `-m`, `-F` or `-C` | [A template to start from](#a-template-to-start-from) |
| `-m <msg>`, `--message=<msg>` | Message on the command line. Repeatable for paragraphs | [Writing the message](#writing-the-message) |
| `-F <file>`, `--file=<file>` | Message from a file, or `-` for standard input | [Writing the message](#writing-the-message) |
| `-C <commit>`, `--reuse-message=<commit>` | Take message and authorship from another commit | [Reusing a message](#reusing-a-message) |
| `-c <commit>`, `--reedit-message=<commit>` | Same, but edit first | [Reusing a message](#reusing-a-message) |
| `--author=<author>` | Set the author | [Author and committer](#author-and-committer) |
| `--date=<date>` | Set the author date | [Author and committer](#author-and-committer) |
| `--reset-author` | Make yourself the author and reset the author date | [Reusing a message](#reusing-a-message) |
| `--allow-empty` | Permit a commit with no changes | [Empty commits](#empty-commits) |
| `--allow-empty-message` | Permit a commit with no message | [Empty commits](#empty-commits) |
| `--amend` | Replace the previous commit | [Amending](#amending) |
| `--no-edit` | Keep the existing message, do not open the editor | [Amending](#amending) |
| `--cleanup=strip` | Remove comments, blank lines at the ends, trailing spaces | [Every cleanup mode](#every-cleanup-mode) |
| `--cleanup=whitespace` | The same, but keep comment lines | [Every cleanup mode](#every-cleanup-mode) |
| `--cleanup=verbatim` | Change nothing | [Every cleanup mode](#every-cleanup-mode) |
| `--cleanup=scissors` | Like `whitespace`, and cut everything from the `>8` scissors line down when editing | [Every cleanup mode](#every-cleanup-mode) |
| `--cleanup=default` | `strip` for a message edited in the editor, `whitespace` otherwise | [Every cleanup mode](#every-cleanup-mode) |
| `-s`, `--signoff`, `--no-signoff` | Add a `Signed-off-by:` line at the end of the message, a *trailer*, or cancel an earlier `-s` | [Trailers](#trailers) |
| `--trailer <token>=<value>` | Add any `Key: value` trailer | [Trailers](#trailers) |
| `--fixup=<commit>` | Prepare a commit that `rebase --autosquash` folds into `<commit>` (Chapter 35) | [Commits meant to be squashed](#commits-meant-to-be-squashed) |
| `--fixup=amend:<commit>` | The same, and replace that commit's message | [Commits meant to be squashed](#commits-meant-to-be-squashed) |
| `--fixup=reword:<commit>` | Replace only that commit's message | [Commits meant to be squashed](#commits-meant-to-be-squashed) |
| `--squash=<commit>` | Prepare a commit to be squashed, keeping both messages | [Commits meant to be squashed](#commits-meant-to-be-squashed) |
| `-n`, `--no-verify`, `--verify` | Skip the `pre-commit` and `commit-msg` hooks, the scripts a repository can run to check a commit, or run them | [Hooks](#hooks) |
| `--no-post-rewrite`, `--post-rewrite` | Skip the `post-rewrite` hook after `--amend`, or run it | [Hooks](#hooks) |
| `--dry-run` | Report what would be committed | [A dry run](#a-dry-run) |
| `--short`, `--porcelain`, `--long` | Format for `--dry-run` output; each implies `--dry-run` | [A dry run](#a-dry-run) |
| `--branch` | Add the branch line to a short dry run | [A dry run](#a-dry-run) |
| `-z`, `--null` | NUL-terminated dry-run output | [A dry run](#a-dry-run) |
| `--ahead-behind`, `--no-ahead-behind` | Count commits against the upstream in a dry run, as in status (Chapter 10) | Chapter 10 |
| `-S[<keyid>]`, `--gpg-sign[=<keyid>]` | Sign the commit (Chapter 68) | Chapter 68 |
| `--no-gpg-sign` | Do not sign, even if `commit.gpgSign` says to | [Signing](#signing) |

## The plain form

```console
$ git commit -m 'Add the app'
[main (root-commit) e2f309a] Add the app
 1 file changed, 1 insertion(+)
 create mode 100644 app.py
$ git log --oneline
e2f309a Add the app
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

On a detached HEAD (Chapter 7) the branch name is replaced, and a deleted file
gets its own line. `-q` prints nothing at all:

```console
$ git commit -m 'Nothing'; echo "exit $?"
On branch main
nothing to commit, working tree clean
exit 1
$ git commit -m 'Only untracked'; echo "exit $?"
On branch main
Untracked files:
  (use "git add <file>..." to include in what will be committed)
	new.txt

nothing added to commit but untracked files present (use "git add" to track)
exit 1
$ git add new.txt && git commit -q -m 'Quiet'; echo "exit $?"
exit 0
$ git switch -q --detach
$ git commit -am 'On a detached HEAD'
[detached HEAD 1c2a9b9] On a detached HEAD
 1 file changed, 1 insertion(+)
$ git switch -q main
$ git commit -am 'Delete a'
[main 6c0bb97] Delete a
 1 file changed, 1 deletion(-)
 delete mode 100644 a.txt
```

The commit made on the detached HEAD belongs to no branch; after switching back
to `main` it is reachable only through the reflog (Chapter 36).

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

Both exit with a non-zero status, which matters in scripts. So does the third
variant in [The plain form](#the-plain-form), where the only new files are
untracked.

## Committing everything tracked

```console
$ git commit -am 'Extend the app'
[main e48a23a] Extend the app
 1 file changed, 1 insertion(+)
$ git status --short
?? untracked.txt
$ git show --stat --oneline HEAD
e48a23a Extend the app
 app.py | 1 +
 1 file changed, 1 insertion(+)
```

`-a` stages every tracked file that changed, then commits. `untracked.txt` was
untouched because Git has never seen it. Chapter 5 has the full table of what
each "stage everything" form covers, and Chapter 11 runs each of them.

`-a` also records deleted files, as the `Delete a` commit in
[The plain form](#the-plain-form) showed: `a.txt` was removed with plain `rm`,
never with `git rm`.

## Committing some paths

With paths, commit takes those files as they are in the working tree and
commits only them, whatever else is staged:

```console
$ git add a.txt
$ git status --short
M  a.txt
 M b.txt
 M c.txt
$ git commit -m 'Only b' b.txt
[main dce6a25] Only b
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git status --short
M  a.txt
 M c.txt
$ git commit -o -m 'Only c' c.txt && git status --short
[main 8a5a65b] Only c
 1 file changed, 1 insertion(+), 1 deletion(-)
M  a.txt
```

`a.txt` stayed staged through both commits. `-o`, `--only`, is what paths do
anyway; the option exists to be explicit, and for `--amend` without paths in
[Amending](#amending).

`-i`, `--include`, adds the paths to what is already staged instead:

```console
$ git reset -q --soft HEAD~2 && git restore --staged b.txt c.txt
$ git status --short
M  a.txt
 M b.txt
 M c.txt
$ git commit -i -m 'Staged plus b' b.txt
[main 2b4483f] Staged plus b
 2 files changed, 2 insertions(+), 2 deletions(-)
$ git status --short
 M c.txt
```

The first command undid the two commits and unstaged `b.txt` and `c.txt`, to
start again from the same state (Chapter 30 covers `reset`).

Paths must already be tracked, and a few combinations make no sense:

```console
$ git commit -m 'Untracked path' d.txt
error: pathspec 'd.txt' did not match any file(s) known to git
$ git commit -i -m 'No path'
fatal: No paths with --include/--only does not make sense.
$ git commit -a -m 'Both' c.txt
fatal: paths 'c.txt ...' with -a does not make sense
```

The paths can come from a file or standard input, as for `git add`
(Chapter 11):

```console
$ printf 'c.txt\n' | git commit --pathspec-from-file=- -m 'From a list' && git status --short
[main 7bb688d] From a list
 1 file changed, 1 insertion(+), 1 deletion(-)
?? d.txt
$ printf 'a.txt\0b.txt\0' | git commit -q --pathspec-from-file=- --pathspec-file-nul -m 'From a NUL list' && git show --stat --oneline HEAD
c16d037 From a NUL list
 a.txt | 2 +-
 b.txt | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)
```

> **Since Git 2.25.** `--pathspec-from-file` and `--pathspec-file-nul`.

The difference between committing a path and adding it first:

```console
$ git add a.txt
$ git add b.txt && git commit -q -m 'Add, then commit' && git show --stat --oneline HEAD
d92d3a0 Add, then commit
 a.txt | 2 +-
 b.txt | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)
```

| Command | The commit contains |
|---|---|
| `git commit <path>`, `git commit -o <path>` | `<path>` only, as it is on disk |
| `git add <path> && git commit` | `<path>` and everything else already staged |
| `git commit -i <path>` | the same as `git add <path> && git commit` |
| `git commit -a` | every change to a tracked file |

Git's documentation adds that after `git commit <path>` the committed content
is staged too, so the index and the new commit agree for that path.

> **Worth knowing.** `git commit -o <path>` is the one people never discover.
> It commits just those paths regardless of what else is staged, and leaves the
> rest of the index alone afterwards. It is the quickest way to split a
> too-large staged change into two commits without touching `git reset`.

## Choosing hunks while committing

`-p` runs the same patch mode as `git add -p` (Chapter 11), then commits what you
chose:

```console
$ printf 'n\n' | git commit -p --inter-hunk-context=2 -m 'Nothing chosen'; echo "exit $?"
diff --git a/poem.txt b/poem.txt
index c9e9e05..d96039a 100644
--- a/poem.txt
+++ b/poem.txt
@@ -1,10 +1,10 @@
-one
+ONE
 two
 three
 four
 five
 six
 seven
 eight
 nine
-ten
+TEN
(1/1) Stage this hunk [y,n,q,a,d,s,e,p,P,?]? 
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   poem.txt

no changes added to commit (use "git add" and/or "git commit -a")
exit 1
$ printf 'y\nn\n' | git commit -p -m 'Only the first line'
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
[main 369d5cb] Only the first line
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git status --short
 M poem.txt
```

Choosing nothing leaves nothing to commit, with the usual status and exit code.
`--inter-hunk-context` and `-U` shape the hunks as in `git add -p`:

```console
$ printf 'n\n' | git commit -p -U0 -m 'Nothing chosen'
diff --git a/poem.txt b/poem.txt
index cf24bdb..d96039a 100644
--- a/poem.txt
+++ b/poem.txt
@@ -10 +10 @@ nine
-ten
+TEN
(1/1) Stage this hunk [y,n,q,a,d,e,p,P,?]? 
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   poem.txt

no changes added to commit (use "git add" and/or "git commit -a")
```

`--interactive` opens the `git add -i` menu instead, and commits when you quit
it. Here the answers are `5` for patch, `1` for the file, an empty line to end
the choice, `y` for the hunk and `q` to quit:

```console
$ printf '5\n1\n\ny\nq\n' | git commit --interactive -m 'The last line'
           staged     unstaged path
  1:    unchanged        +1/-1 poem.txt

*** Commands ***
  1: [s]tatus	  2: [u]pdate	  3: [r]evert	  4: [a]dd untracked
  5: [p]atch	  6: [d]iff	  7: [q]uit	  8: [h]elp
What now>            staged     unstaged path
  1:    unchanged        +1/-1 [p]oem.txt
Patch update>>            staged     unstaged path
* 1:    unchanged        +1/-1 [p]oem.txt
Patch update>> diff --git a/poem.txt b/poem.txt
index cf24bdb..d96039a 100644
--- a/poem.txt
+++ b/poem.txt
@@ -7,4 +7,4 @@ six
 seven
 eight
 nine
-ten
+TEN
(1/1) Stage this hunk [y,n,q,a,d,e,p,P,?]? 
*** Commands ***
  1: [s]tatus	  2: [u]pdate	  3: [r]evert	  4: [a]dd untracked
  5: [p]atch	  6: [d]iff	  7: [q]uit	  8: [h]elp
What now> Bye.
[main 6cee710] The last line
 1 file changed, 1 insertion(+), 1 deletion(-)
```

Unlike paths, `-p` and `--interactive` add to what is already staged, as Git's
documentation says.

> **Since Git 2.51.** `-U` and `--inter-hunk-context`.

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
$ git status --short
A  untracked.txt
```

Everything starting with `#` is stripped before the message is saved. The
status summary is there so you can check what you are committing without
leaving the editor, and `git commit -v` adds the full staged diff below it.

Saving an empty file aborts the commit and changes nothing. That is the
standard way to back out once the editor is already open.

`GIT_EDITOR` sets the editor for one command. Git's documentation gives the order
it looks in: `GIT_EDITOR`, then `core.editor`, then the `VISUAL` and `EDITOR`
environment variables (Chapter 3).

> **Careful.** If your editor returns immediately, Git sees an unchanged
> template, treats it as empty, and aborts. That is the symptom of a graphical
> editor configured without its wait flag. Chapter 3 has the table of correct
> values for each editor.

### Seeing the changes while you write

```console
$ GIT_EDITOR=cat git commit -v

# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
#
# On branch main
# Changes to be committed:
#	modified:   app.py
#
# Changes not staged for commit:
#	modified:   app.py
#
# Untracked files:
#	todo/
#
# ------------------------ >8 ------------------------
# Do not modify or remove the line above.
# Everything below it will be ignored.
diff --git a/app.py b/app.py
index b376c99..eaa7424 100644
--- a/app.py
+++ b/app.py
@@ -1 +1,2 @@
 print('hello')
+print('staged')
Aborting commit due to empty commit message.
$ GIT_EDITOR=cat git commit -vv

# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
#
# On branch main
# Changes to be committed:
#	modified:   app.py
#
# Changes not staged for commit:
#	modified:   app.py
#
# Untracked files:
#	todo/
#
# ------------------------ >8 ------------------------
# Do not modify or remove the line above.
# Everything below it will be ignored.
#
# Changes to be committed:
diff --git c/app.py i/app.py
index b376c99..eaa7424 100644
--- c/app.py
+++ i/app.py
@@ -1 +1,2 @@
 print('hello')
+print('staged')
# --------------------------------------------------
# Changes not staged for commit:
diff --git i/app.py w/app.py
index eaa7424..f6c1e31 100644
--- i/app.py
+++ w/app.py
@@ -1,2 +1,3 @@
 print('hello')
 print('staged')
+print('unstaged')
Aborting commit due to empty commit message.
$ GIT_EDITOR=cat git -c commit.verbose=true commit

# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
#
# On branch main
# Changes to be committed:
#	modified:   app.py
#
# Changes not staged for commit:
#	modified:   app.py
#
# Untracked files:
#	todo/
#
# ------------------------ >8 ------------------------
# Do not modify or remove the line above.
# Everything below it will be ignored.
diff --git a/app.py b/app.py
index b376c99..eaa7424 100644
--- a/app.py
+++ b/app.py
@@ -1 +1,2 @@
 print('hello')
+print('staged')
Aborting commit due to empty commit message.
```

The diff lines have no `#` in front of them, so the *scissors line*, the one
with `>8` drawn like a pair of scissors, marks where the message ends: Git cuts
everything from it down. `-vv` adds the unstaged changes, with the `c/`, `i/`
and `w/` prefixes Chapter 10 explains. `commit.verbose` makes `-v` the default.

`git -c <name>=<value>` sets a configuration value for one command only
(Chapter 62).

The untracked list follows `-u`, as in status, and the status can be left out:

```console
$ GIT_EDITOR=cat git commit -uall

# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
#
# On branch main
# Changes to be committed:
#	modified:   app.py
#
# Changes not staged for commit:
#	modified:   app.py
#
# Untracked files:
#	todo/one.txt
#	todo/two.txt
#
Aborting commit due to empty commit message.
$ GIT_EDITOR=cat git commit -uno

# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
#
# On branch main
# Changes to be committed:
#	modified:   app.py
#
# Changes not staged for commit:
#	modified:   app.py
#
# Untracked files not listed
Aborting commit due to empty commit message.
$ GIT_EDITOR=cat git commit --no-status
Aborting commit due to empty commit message.
$ GIT_EDITOR=cat git -c commit.status=false commit --status

# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
#
# On branch main
# Changes to be committed:
#	modified:   app.py
#
# Changes not staged for commit:
#	modified:   app.py
#
# Untracked files:
#	todo/
#
Aborting commit due to empty commit message.
```

With `--no-status` the editor opened on an empty file: the help lines went too.
`commit.status=false` does the same by default, and `--status` brings it back.

### A template to start from

```console
$ cat .msg-template
Summary:

Why:
$ GIT_EDITOR=true git commit -t .msg-template
Aborting commit; you did not edit the message.
$ GIT_EDITOR="sed -i 's/^Summary:/Summary: Print a second line/'" git commit -t .msg-template
[main 9c736a6] Summary: Print a second line
 1 file changed, 1 insertion(+)
$ git log -1 --format=%B
Summary: Print a second line

Why:

```

`-t` fills the editor with the file. Leaving it unchanged aborts, as Git's
documentation says, so an outline nobody filled in is never committed. Here
`sed` plays the editor, filling in the summary line. `commit.template` makes
the file the default, and it is ignored when the message is given another way:

```console
$ GIT_EDITOR=cat git -c commit.template=.msg-template commit --allow-empty -m 'Given with -m'
[main 476edd2] Given with -m
$ GIT_EDITOR="sed -i '1s/^/Edited: /'" git commit -q -e --allow-empty -m 'Given with -m' && git log -1 --format=%B
Edited: Given with -m

$ git commit --allow-empty -m 'Given with -m' -F .msg-template
fatal: options '-m' and '-F' cannot be used together
```

`cat` as the editor was never run: `-m` means no editor. `-e` opens it anyway,
starting from the `-m` message. Only one source of message is allowed at a time.

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

```console
$ printf 'From a file\n\nWith a body.\n' > msg.txt && git commit --allow-empty -F msg.txt
[main e1c29b5] From a file
$ echo 'From standard input' | git commit --allow-empty -F -
[main b44183c] From standard input
```

`-F` reads the message from a file, and `-F -` from whatever is piped in, which
suits a message another program produces.

| Option | Message comes from |
|---|---|
| `-m <msg>` | The command line. Repeatable |
| `-F <file>` | A file. `-F -` reads standard input |
| `-C <commit>` | Another commit, reused as-is |
| `-c <commit>` | Another commit, opened in the editor first |
| `--squash <commit>`, `--fixup <commit>` | Generated for `rebase --autosquash` (Chapter 35) |
| `-t <file>` | A file, opened in the editor as a starting point |
| neither | Your editor |

Chapter 53 covers what makes a message good. The short version: a summary line
under about fifty characters, a blank line, then prose explaining why. Git's
documentation gives the same advice, and adds that the text up to the first
blank line is the title used throughout Git, for example as the subject line
when a commit is turned into an email (Chapter 61).

### Reusing a message

```console
$ git commit --allow-empty -C HEAD
[main 41486c8] Deliberately empty, now with content
 Date: Mon Jan 5 13:00:00 2026 +0000
$ git log --oneline -3
41486c8 Deliberately empty, now with content
1c1e8fb Deliberately empty, now with content
73002b1 Someone else wrote this
```

`-C` takes both the message and the author information from another commit.
`-c` does the same but opens the editor so you can adjust it first.
`--reset-author` on top of either makes you the author again.

```console
$ GIT_EDITOR="sed -i '1s/$/, edited/'" git commit --allow-empty -c HEAD
[main 8f70674] From standard input, edited
 Date: Mon Jan 5 14:00:00 2026 +0000
$ git log -2 --format='%h %s | %an | %ad'
8f70674 From standard input, edited | Ada Lovelace | Mon Jan 5 14:00:00 2026 +0000
b44183c From standard input | Ada Lovelace | Mon Jan 5 14:00:00 2026 +0000
$ git commit --allow-empty --reset-author -C HEAD~1
[main 7396693] From standard input
$ git log -1 --format='%h %s | %an | %ad'
7396693 From standard input | Ada Lovelace | Mon Jan 5 16:00:00 2026 +0000
```

`-c` kept the original author date, which is why the output printed a `Date:`
line: Git prints one when the author date and the committer date differ.
`--reset-author` took the current time instead, and the line disappeared.
`%h %s | %an | %ad` asks `git log` for the short hash, title, author name and
author date (Chapter 17).

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
    
    The file is a placeholder for now.
    
    Refs: #42
```

Usually they are identical and nobody notices. Set an author explicitly and
they separate. This commit also sets the committer date by hand, to stand for a
commit made a day later:

```console
$ GIT_COMMITTER_DATE='@1767700000 +0000' git commit -q --allow-empty --author='Grace Hopper <grace@example.com>' -m 'Someone else wrote this'
$ git log -1 --pretty=fuller
commit 73002b18f25ff99fa1dd0bee1044e60f5d025c87
Author:     Grace Hopper <grace@example.com>
AuthorDate: Mon Jan 5 12:00:00 2026 +0000
Commit:     Ada Lovelace <ada@example.com>
CommitDate: Tue Jan 6 11:46:40 2026 +0000

    Someone else wrote this
```

`@1767700000 +0000` is a date as seconds since 1970 and a time zone, the form Git
stores (Chapter 2).

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

`--author` with a plain word, rather than `Name <email>`, searches earlier
commits for an author matching it. `--date` accepts the formats Git's
documentation lists, and, only for this option, human phrases such as
`yesterday`:

```console
$ git commit -q --allow-empty --author=Grace -m 'Author found by search' && git log -1 --format='%an <%ae>'
Grace Hopper <grace@example.com>
$ git commit -q --allow-empty --author=Nobody -m 'No such author'
fatal: --author 'Nobody' is not 'Name <email>' and matches no existing author
$ git commit -q --allow-empty --date='2025-12-24 18:00:00 +0100' -m 'Dated' && git log -1 --format='%ad | %cd'
Wed Dec 24 18:00:00 2025 +0100 | Mon Jan 5 12:00:00 2026 +0000
$ git commit -q --allow-empty --date=bogus -m 'Bad date'
fatal: invalid date format: bogus
```

`--date` changed the author date only; the committer date is still the moment
of committing.

### Where the names come from

| To set | Use |
|---|---|
| Author name and email | `--author="Name <email>"`, `GIT_AUTHOR_NAME` and `GIT_AUTHOR_EMAIL`, or `author.name` and `author.email` |
| Author date | `--date=<date>`, or `GIT_AUTHOR_DATE` |
| Committer name and email | `GIT_COMMITTER_NAME` and `GIT_COMMITTER_EMAIL`, or `committer.name` and `committer.email` |
| Committer date | `GIT_COMMITTER_DATE` |
| Both, the usual way | `user.name` and `user.email` (Chapter 3) |

There is no `--committer` flag. The environment variables and the `committer.*`
settings are the only ways, and Chapter 2 uses the environment variables to make
this book's hashes reproducible. The sandbox sets all of them, so the
environment variables are removed with `env -u` for these examples:

```console
$ env -u GIT_AUTHOR_NAME -u GIT_AUTHOR_EMAIL git -c user.name=Configured -c user.email=me@work.example commit -q --allow-empty -m 'From config' && git log -1 --format='%an <%ae> / %cn <%ce>'
Configured <me@work.example> / Ada Lovelace <ada@example.com>
$ env -u GIT_COMMITTER_NAME -u GIT_COMMITTER_EMAIL git -c committer.name='Build Robot' -c committer.email=robot@example.com commit -q --allow-empty -m 'Committer from config' && git log -1 --format='%an <%ae> / %cn <%ce>'
Ada Lovelace <ada@example.com> / Build Robot <robot@example.com>
$ env -u GIT_AUTHOR_NAME -u GIT_AUTHOR_EMAIL -u GIT_COMMITTER_NAME -u GIT_COMMITTER_EMAIL -u EMAIL git -c user.useConfigOnly=true commit --allow-empty -m 'Nobody'
Author identity unknown

*** Please tell me who you are.

Run

  git config --global user.email "you@example.com"
  git config --global user.name "Your Name"

to set your account's default identity.
Omit --global to set the identity only in this repository.

fatal: no email was given and auto-detection is disabled
```

Git's documentation gives the order: the environment variables win, then
`author.*` and `committer.*`, then `user.name` and `user.email`, then the
`EMAIL` environment variable, and last a name and address guessed from the
system account and host name. `user.useConfigOnly=true` forbids the guess, so a
missing setting stops the commit instead of recording an address nobody can
reply to. Setting it globally, with no email in the global configuration,
makes Git ask for an email in every new repository, which suits someone who
uses a different address for work and for personal projects.

## Empty commits

```console
$ git commit -m 'Nothing changed'
On branch main
nothing to commit, working tree clean
$ git commit --allow-empty -m 'Deliberately empty'
[main a4364b5] Deliberately empty
$ git log --oneline -2
a4364b5 Deliberately empty
73002b1 Someone else wrote this
$ git show --stat --oneline HEAD
a4364b5 Deliberately empty
```

An empty commit is a legal commit whose tree is identical to its parent's.
Notice the `git show --stat` output has no file list at all.

They are genuinely useful for marking a point in history, triggering a rebuild
on a system that watches for pushes, or starting a branch from a known empty
state. `--allow-empty-message` is the matching flag for a commit with no
message, which is much harder to justify:

```console
$ git commit -q --allow-empty --allow-empty-message -m '' && git log --format='%h [%s]' -1
0c0a41a []
```

The brackets show the title is empty. Git's documentation describes both options
as meant mainly for scripts that import history from other version control
systems.

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
$ git log --oneline -1
1c1e8fb Deliberately empty, now with content
$ git log -1 --pretty=fuller
commit 1c1e8fbe2350caf2e7206589469a0b92fe62c4d5
Author:     Ada Lovelace <ada@example.com>
AuthorDate: Mon Jan 5 13:00:00 2026 +0000
Commit:     Ada Lovelace <ada@example.com>
CommitDate: Mon Jan 5 14:00:00 2026 +0000

    Deliberately empty, now with content
```

Amending keeps the author date and updates the committer date. That is why the
output started printing a `Date:` line: Git shows it when the two disagree.

To change only the message while something else is staged, `--only` with no
paths leaves the index out of it:

```console
$ git add c.txt
$ git commit --amend --only -m 'Two files, reworded' && git status --short
[main 4129bec] Two files, reworded
 Date: Mon Jan 5 16:00:00 2026 +0000
 2 files changed, 2 insertions(+)
 create mode 100644 b.txt
A  c.txt
$ git commit -q --amend --reset-author --no-edit && git log -1 --format='%h %an %ad'
bb5997a Ada Lovelace Mon Jan 5 18:00:00 2026 +0000
```

`c.txt` stayed staged. The summary lists what the amended commit contains
compared with its parent, which was already `a.txt` and `b.txt`.
`--reset-author` then moved the author date to now.

The first commit can be amended too, and there has to be a commit:

```console
$ git commit --amend -m 'First, amended' && git log --oneline
[main ba6f4f9] First, amended
 Date: Mon Jan 5 09:00:00 2026 +0000
 1 file changed, 1 insertion(+)
 create mode 100644 a.txt
ba6f4f9 First, amended
$ git commit --amend -m 'Nothing to amend'
fatal: You have nothing to amend.
```

| What amend can change | Flag |
|---|---|
| The message | `--amend -m '...'` or just `--amend` |
| Only the message, with other changes staged | `--amend --only -m '...'` |
| The content | Stage it first, then `--amend --no-edit` |
| The author | `--amend --author='Name <email>'` |
| The author date | `--amend --date=<date>` |
| The author and author date, to you and now | `--amend --reset-author` |
| The committer date | Always updated to now; `GIT_COMMITTER_DATE` sets another |
| Nothing else | It cannot reach further back than one commit |

Git's documentation describes amending as roughly
`git reset --soft HEAD^` followed by `git commit -c ORIG_HEAD`, and notes that
unlike that sequence it can also amend a merge commit.

> **Careful.** Amending a commit you have already pushed rewrites shared
> history. Your next push will be rejected, and forcing it will break anyone
> who has pulled. Chapter 28 covers when this is acceptable and Chapter 43
> covers `--force-with-lease`, which is the safer way to do it.

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

`true` is a command that does nothing and succeeds, so it stands for an editor
closed without saving.

## What happens to your message

Git cleans the message up before storing it, and the rules depend on where it
came from. The default is the subtle one. A message you typed in the editor has
its `#` lines removed; a message from `-m` or `-F` does not, because you never
saw a template full of comments:

```console
$ git commit -F - <<'EOM'
Subject line

# this line looks like a comment
Body text.


EOM
[main fc1e4d4] Subject line
 1 file changed, 1 insertion(+), 4 deletions(-)
$ git log -1 --pretty=format:'%B' | cat -A | head -8
Subject line$
$
# this line looks like a comment$
Body text.$
```

The `#` line survived and the trailing blank lines were removed. That is
`whitespace` mode exactly as documented. `cat -A` marks the end of each line
with `$`, so blank lines and trailing spaces become visible. The staged change
to `app.py` from the previous section went into this commit too.

`<<'EOM'` is a shell *here-document*: the lines up to `EOM` are fed to the
command as its standard input, which `-F -` reads.

### Every cleanup mode

The same untidy message, committed with each mode. It has two blank lines at
the start, trailing spaces, a run of blank lines, a comment line, and blank
lines at the end:

```console
$ cat -A messy.txt
$
$
Subject   $
$
$
# a comment line$
Body text   $
$
$
$ git commit -q --allow-empty --cleanup=strip -F messy.txt && git log -1 --format=%B | cat -A
Subject$
$
Body text$
$
$ git commit -q --allow-empty --cleanup=whitespace -F messy.txt && git log -1 --format=%B | cat -A
Subject$
$
# a comment line$
Body text$
$
$ git commit -q --allow-empty --cleanup=verbatim -F messy.txt && git log -1 --format=%B | cat -A
$
$
Subject   $
$
$
# a comment line$
Body text   $
$
$
$
$ git commit -q --allow-empty --cleanup=default -F messy.txt && git log -1 --format=%B | cat -A
Subject$
$
# a comment line$
Body text$
$
```

`git log --format=%B` adds one blank line of its own after each message, which
is why every result ends with an extra `$`.

The scissors line only matters for a message that goes through the editor:

```console
$ cat scissors.txt
Subject

Body
# ------------------------ >8 ------------------------
Everything from the line above is cut
$ git commit -q --allow-empty --cleanup=scissors -F scissors.txt && git log -1 --format=%B | cat -A
Subject$
$
Body$
# ------------------------ >8 ------------------------$
Everything from the line above is cut$
$
$ GIT_EDITOR='cp scissors.txt' git commit -q --allow-empty --cleanup=scissors && git log -1 --format=%B | cat -A
Subject$
$
Body$
$
```

In the second command the "editor" is `cp`, which copies the file over the
message Git prepared, as if you had typed it. The same trick shows the default
for an edited message, and `commit.cleanup` changing it:

```console
$ GIT_EDITOR='cp messy.txt' git commit -q --allow-empty && git log -1 --format=%B | cat -A
Subject$
$
Body text$
$
$ GIT_EDITOR='cp messy.txt' git -c commit.cleanup=whitespace commit -q --allow-empty && git log -1 --format=%B | cat -A
Subject$
$
# a comment line$
Body text$
$
$ git commit --allow-empty --cleanup=tidy -m 'Unknown mode'
fatal: Invalid cleanup mode tidy
```

| Option | Blank lines at the ends, trailing spaces, runs of blank lines | `#` lines |
|---|---|---|
| `--cleanup=strip` | removed | removed |
| `--cleanup=whitespace` | removed | kept |
| `--cleanup=verbatim` | kept | kept |
| `--cleanup=scissors` | removed | kept, and everything from a scissors line down is cut when the message was edited in the editor |
| `--cleanup=default` | removed | removed when the message was edited in the editor, otherwise kept |

The scissors line is also what `git commit -v` writes above the diff, with a
note saying everything below it will be ignored, which is why the diff never
ends up in the message.

### Choosing the comment character

```console
$ cat hash.txt
Fix the parser

#42 was the report
$ GIT_EDITOR='cp hash.txt' git commit -q --allow-empty && git log -1 --format=%B
Fix the parser

$ GIT_EDITOR='cp hash.txt' git -c core.commentChar=';' commit -q --allow-empty && git log -1 --format=%B
Fix the parser

#42 was the report

$ GIT_EDITOR=cat git -c 'core.commentString=;;' commit --allow-empty

;; Please enter the commit message for your changes. Lines starting
;; with ';;' will be ignored, and an empty message aborts the commit.
;;
;; On branch main
;; Untracked files:
;;	hash.txt
;;	messy.txt
;;	scissors.txt
;;
Aborting commit due to empty commit message.
```

> **Careful.** This bites when a message legitimately starts a line with `#`,
> such as an issue reference at the start of a line, typed in the editor. It
> vanishes. Either indent it, put it mid-line, or set
> `git config set core.commentChar ';'` so `#` stops being special.

The template follows the setting, so its instructions stay correct.
`core.commentChar` and `core.commentString` are the same setting under two
names, and since Git 2.45 either accepts more than one character. Git's
documentation explains why both exist: older versions ignore `commentString`
and reject a `commentChar` longer than one character, so a configuration shared
with an old Git can set `commentChar` to one character and `commentString` to
the longer string. It also says the value `auto`, which picks a character no
line of the message starts with, is deprecated and will be removed in Git 3.0.

> **Since Git 2.45.** `core.commentString`, and comment strings longer than one
> character.

## Trailers

A *trailer* is a `Key: value` line at the end of a message, in the style of an
email header. `git interpret-trailers` reads and writes them, and Chapter 53
covers the conventions projects build on them.

```console
$ git commit -q --allow-empty -s -m 'Signed off' && git log -1 --format=%B
Signed off

Signed-off-by: Ada Lovelace <ada@example.com>

$ git commit -q --allow-empty --trailer 'Reviewed-by: Grace Hopper <grace@example.com>' --trailer 'Refs=#42' -m 'With trailers' && git log -1 --format=%B
With trailers

Reviewed-by: Grace Hopper <grace@example.com>
Refs: #42

$ git commit -q --allow-empty -s --no-signoff -m 'Not signed off' && git log -1 --format=%B
Not signed off

$ git commit -q --allow-empty -s --trailer 'Signed-off-by: Ada Lovelace <ada@example.com>' -m 'Signed off twice?' && git log -1 --format=%B
Signed off twice?

Signed-off-by: Ada Lovelace <ada@example.com>

```

`-s` adds `Signed-off-by` with the committer's name. `--trailer` accepts `=` as
well as `:` and writes `:`. An identical trailer is not added twice.

What a sign-off means is up to the project. Git's documentation gives the
example of certifying that you have the right to submit the work under the
project's licence, pointing to the certificate the Linux kernel and Git
projects use, and says there is
deliberately no setting to add it automatically. `--no-signoff` cancels an
earlier `-s`, such as one in an alias.

> **Since Git 2.32.** `--trailer`.

## Commits meant to be squashed

Some commits exist only to be folded into an earlier one later, by
`git rebase --autosquash` (Chapter 35). These options write the message that
rebase looks for:

```console
$ git commit -q --fixup=HEAD~1 && git log -1 --format=%B
fixup! Add a

$ git commit -q --allow-empty --squash=HEAD~2 -m 'Extra words' && git log -1 --format=%B
squash! Add a

Extra words

$ GIT_EDITOR=true git commit -q --fixup=reword:HEAD~3 && git log -1 --format=%B
amend! Add a

Add a

$ git show --stat --oneline HEAD
727fae4 amend! Add a
$ GIT_EDITOR="sed -i '3s/.*/Add a, better/'" git commit -q --fixup=amend:HEAD~4 && git log -1 --format=%B
amend! Add a

Add a, better

$ git log --oneline
3c66e28 amend! Add a
727fae4 amend! Add a
1c91d6c squash! Add a
97c339d fixup! Add a
d9c867f Add b
ba193c9 Add a
```

| Option | Title | When squashed, the target's message |
|---|---|---|
| `--fixup=<commit>` | `fixup! <title>` | stays as it was; this commit's message is thrown away |
| `--squash=<commit>` | `squash! <title>` | is combined with this commit's message in the editor |
| `--fixup=amend:<commit>` | `amend! <title>` | is replaced by this commit's body |
| `--fixup=reword:<commit>` | `amend! <title>` | is replaced, and no content changes |

`--fixup=reword:` committed no files even though `a.txt` was staged, as the
empty `--stat` shows; Git's documentation calls it shorthand for
`--fixup=amend:<commit> --only`. For `amend!`, the editor opens on the target's
message to be rewritten, which is what the `sed` editor did on line 3.

> **Since Git 2.32.** `--fixup=amend:` and `--fixup=reword:`.

## Hooks

`git commit` runs up to four hooks, and Chapter 67 covers writing them:

| Hook | Runs | Can it stop the commit |
|---|---|---|
| `pre-commit` | Before the message is requested | Yes |
| `prepare-commit-msg` | Before the editor opens | Yes |
| `commit-msg` | After the message is written | Yes |
| `post-commit` | After the commit exists | No |

`--no-verify` skips `pre-commit` and `commit-msg`.

A hook is an executable file in `.git/hooks` with the hook's name. This one
refuses every commit:

```console
$ cat .git/hooks/pre-commit
#!/bin/sh
echo "pre-commit: refusing, TODO found" >&2
exit 1
$ git commit -m 'Blocked'; echo "exit $?"
pre-commit: refusing, TODO found
exit 1
$ git commit -n -m 'Skipped the hook'
[main 3e7cf70] Skipped the hook
 1 file changed, 1 insertion(+)
```

`-n` is `--no-verify`. A `commit-msg` hook sees the message, and when it refuses,
the message is not lost:

```console
$ cat .git/hooks/commit-msg
#!/bin/sh
grep -q "^Refs: " "$1" || { echo "commit-msg: add a Refs: line" >&2; exit 1; }
$ git commit -m 'No refs'; echo "exit $?"
commit-msg: add a Refs: line
exit 1
$ cat .git/COMMIT_EDITMSG
No refs
$ git commit --no-verify -m 'No refs, not checked'
[main 21a260f] No refs, not checked
 1 file changed, 1 insertion(+), 1 deletion(-)
```

Git's documentation says `.git/COMMIT_EDITMSG` keeps the message of a commit that
failed, until the next `git commit` overwrites it. After a long message is
refused, copy it from there.

Three more hooks, which only print, except that `post-commit` also fails:

```console
$ git commit -q --no-verify -m 'Three hooks'; echo "exit $?"
prepare-commit-msg: message from message
post-commit: exiting with 1
exit 0
$ git commit -q --no-verify --amend --no-edit
prepare-commit-msg: message from commit
post-commit: exiting with 1
post-rewrite: after amend
$ git commit -q --no-verify --amend --no-edit --no-post-rewrite
prepare-commit-msg: message from commit
post-commit: exiting with 1
```

`prepare-commit-msg` ran despite `--no-verify`, and was told where the message
came from: `message` for `-m`, `commit` for an amend. `post-commit` failing
changed nothing; the commit was made and the exit code was 0. `post-rewrite`
runs after `--amend`, because a commit was replaced, and `--no-post-rewrite`
skips it.

> **Careful.** `--no-verify` is for the moment a hook is broken and you need to
> commit anyway, not for the moment a hook is telling you something true. A
> team whose members routinely pass `--no-verify` has hooks that are too slow
> or too strict, and the fix is to the hooks.

## A dry run

```console
$ git commit --dry-run; echo "exit $?"
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   a.txt

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   b.txt

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	new.txt

exit 0
$ git commit --short; echo "exit $?"
M  a.txt
 M b.txt
?? new.txt
exit 0
$ git commit --porcelain
M  a.txt
 M b.txt
?? new.txt
$ git commit --short --branch
## main
M  a.txt
 M b.txt
?? new.txt
$ git commit --long -uno
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   a.txt

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   b.txt

Untracked files not listed (use -u option to show untracked files)
$ git commit -z | tr '\0' '@'; echo
M  a.txt@ M b.txt@?? new.txt@
$ git commit --dry-run -a --short
M  a.txt
M  b.txt
?? new.txt
$ git commit --dry-run --short b.txt
 M a.txt
M  b.txt
?? new.txt
$ git log --oneline
fefc1c5 Base
```

The output is `git status` in each of its formats (Chapter 10), with two
differences. A dry run with something to commit exits with 0 and one with
nothing exits with 1, so a script can ask whether a commit would happen;
Chapter 10 shows both. And it
takes the same options as the real commit: with `-a`, `b.txt` shows as staged;
with the path `b.txt`, `a.txt` shows as not staged, because that commit would
leave it out. `--short`, `--porcelain`, `--long` and `-z` each imply
`--dry-run`, and the log confirms no commit was made.

## Finishing a merge

When `git merge` stops on a conflict (Chapter 26), `git commit` records the merge
once everything is resolved:

```console
$ git merge side
Auto-merging a.txt
CONFLICT (content): Merge conflict in a.txt
Automatic merge failed; fix conflicts and then commit the result.
$ git commit -m 'Merge' a.txt
fatal: cannot do a partial commit during a merge.
$ git commit -i -m 'Merge side' a.txt
[main bc7897a] Merge side
$ git log --oneline --graph
*   bc7897a Merge side
|\  
| * 7bc0b5d Side
* | 81d4f95 Main
|/  
* 20d7ad2 Base
$ git status --short
 M b.txt
```

A merge commit must contain the whole merge, so committing only some paths is
refused. `-i` is allowed, because it adds the resolved file to everything else
the merge staged, and Git's documentation names finishing a conflicted merge as
the case `-i` is meant for. `b.txt`, changed but not part of the merge, stayed
out.

## Signing

`-S` signs a commit with a GPG, SSH or X.509 key, and `commit.gpgSign` signs
every commit; Chapter 68 covers the keys and the setup. `--no-gpg-sign` turns
signing off for one commit:

```console
$ git -c commit.gpgSign=true commit -q --allow-empty --no-gpg-sign -m 'Not signed' && git log -1 --format=%s
Not signed
```

The sandbox has no signing key, so without `--no-gpg-sign` this command would
have failed.

## Undoing a commit

```console
$ git reset --soft HEAD~1 && git status --short
M  a.txt
$ git commit -q -m 'Right message' && git log --oneline
8a06df8 Right message
215f6e7 Base
```

`git reset --soft HEAD~1` moved the branch back one commit and left the changes
staged, ready to commit again. Chapter 30 covers `reset` in full.

| You want to | Use | Chapter |
|---|---|---|
| Fix the last commit's message or content | `git commit --amend` | this one |
| Take the last commit back, keeping its changes staged | `git reset --soft HEAD~1` | 30 |
| Take it back, keeping the changes but unstaged | `git reset HEAD~1` | 30 |
| Undo a commit that is already pushed | `git revert <commit>`, which adds a commit that reverses it | 31 |
| Get back a commit you amended or reset away | `git reflog` | 36 |

## commit and its neighbours

```console
$ git commit-tree -p HEAD -m 'Made by commit-tree' HEAD^{tree}
2af6581539134a6391e80e0564913cbfc3ce8c91
$ git log --oneline
8a06df8 Right message
215f6e7 Base
```

`git commit-tree` is the plumbing underneath (Chapter 75). Given a tree, a
parent and a message, it writes a commit object and prints its hash, and does
nothing else: no branch moved, which is why the log does not show it. `HEAD^{tree}` names the tree of the current commit (Chapter 18).

| Situation | Command |
|---|---|
| Record what is staged | `git commit` |
| Record every change to tracked files | `git commit -a` |
| Record one file, leaving other staged changes for later | `git commit <path>` |
| Record part of a file | `git commit -p`, or `git add -p` then `git commit` |
| Fix the commit just made | `git commit --amend` |
| Fix an older commit | `git commit --fixup=<commit>`, then `git rebase --autosquash` (Chapter 35) |
| Mark a point in history with no change | `git commit --allow-empty` |
| Write a commit object without moving a branch | `git commit-tree` (Chapter 75) |
| Save work without committing it | `git stash` (Chapter 55) |

## The settings

| Setting | Effect |
|---|---|
| `user.name`, `user.email` | Your name and email for author and committer (Chapter 3) |
| `author.name`, `author.email` | Override `user.*` for the author only |
| `committer.name`, `committer.email` | Override `user.*` for the committer only |
| `user.useConfigOnly` | Refuse to guess a name or email that is not configured |
| `core.editor` | The editor for messages (Chapter 3) |
| `commit.template` | A file to start every message from |
| `commit.verbose` | Make `-v` the default |
| `commit.status` | `false` leaves the status out of the editor template |
| `commit.cleanup` | Default for `--cleanup` |
| `core.commentChar`, `core.commentString` | The character, or since Git 2.45 the string, that starts a comment line |
| `commit.gpgSign` | Sign every commit (Chapter 68) |
| `status.showUntrackedFiles` | Default for `-u` in the template (Chapter 10) |
| `status.renames`, `status.renameLimit` | Rename detection in the template (Chapter 10) |
| `trailer.*` | How `--trailer` places and formats trailers (Chapter 53) |
| `i18n.commitEncoding` | The character encoding messages are written in, if not UTF-8 |
| `diff.context`, `diff.interHunkContext` | Hunk size in `-p`. Since Git 2.51 |
