# Chapter 34. Interactive Rebase

## What it is

`git rebase -i` shows you the list of commits it is about to replay and lets
you edit it first. Reorder the lines, delete one, change `pick` to something
else, and the rebase does that instead.

It answers one question: *how do I tidy up a series of commits before anyone
else sees them?*

Everything in Chapter 33 still applies — the commits are copied, the hashes
change, the branch moves at the end. What is added is the *todo list*: a file
of instructions, one per commit, which you edit and Git then carries out from
top to bottom.

| Term | Means |
|---|---|
| *the todo list* | the file of instructions, `.git/rebase-merge/git-rebase-todo`, opened in your editor |
| *the sequence editor* | the editor Git opens on that file; `GIT_SEQUENCE_EDITOR` or `sequence.editor`, falling back to your ordinary editor |
| *command* | the first word of a todo line: `pick`, `reword`, `edit`, `squash`, `fixup`, `drop`, `exec`, `break`, `label`, `reset`, `merge`, `update-ref` |
| *fold* | combine a commit into the one before it, as `squash` and `fixup` do |
| *`done`* | the part of the list Git has already carried out, kept beside the todo list |

`--exec` and `--rebase-merges` are here rather than in Chapter 33 because both
work by writing extra lines into this list, and neither can be explained
without it.

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What does the `-i` add to a rebase?](#what-it-is)
- [What can I actually change about a commit this way?](#what-it-is)

**[Synopsis](#synopsis)**

- [What can I type after `git rebase -i`?](#synopsis)
- [Which commit do I name — the one I want to change, or the one before it?](#synopsis)

**[The todo list commands at a glance](#the-todo-list-commands-at-a-glance)**

- [What is every command I can write in the todo list?](#the-todo-list-commands-at-a-glance)
- [What are the one-letter abbreviations?](#the-todo-list-commands-at-a-glance)

**[Options at a glance](#options-at-a-glance)**

- [Which of rebase's options only matter with `-i`?](#options-at-a-glance)

**[The example repository](#the-example-repository)**

- [What repository do the examples use?](#the-example-repository)

**[The todo list](#the-todo-list)**

- [What is this file the editor opened, and what happens when I save it?](#the-todo-list)
- [Why is the oldest commit at the top, the other way round from `git log`?](#the-todo-list)
- [Why is the commit's subject written after a `#`?](#the-todo-list)

**[Changing nothing, and getting out](#changing-nothing-and-getting-out)**

- [What happens if I save the list without editing it?](#changing-nothing-and-getting-out)
- [How do I cancel an interactive rebase before it starts?](#changing-nothing-and-getting-out)

**[Reordering commits](#reordering-commits)**

- [How do I change the order of two commits?](#reordering-commits)

**[Dropping a commit](#dropping-a-commit)**

- [How do I delete a commit from the middle of my branch?](#dropping-a-commit)
- [Is deleting the line the same as writing `drop`?](#dropping-a-commit)

**[reword](#reword)**

- [How do I change the message of an older commit?](#reword)

**[edit](#edit)**

- [How do I add a forgotten file to a commit several commits back?](#edit)
- [The rebase stopped at my `edit` line. What am I supposed to type?](#edit)
- [Can I add extra commits at that point instead of amending?](#adding-a-commit-at-that-point)

**[squash and fixup](#squash-and-fixup)**

- [How do I combine two commits into one?](#squash-and-fixup)
- [What is the difference between `squash` and `fixup`?](#squash-and-fixup)
- [Which message do I end up with, and can I edit it?](#squash-and-fixup)
- [I want the second commit's message, not the first. What do I write?](#keeping-the-fixup-s-message)

**[break](#break)**

- [How do I make the rebase stop at a point without changing a commit?](#break)

**[Running a command after each commit](#running-a-command-after-each-commit)**

- [How do I run the tests after every commit in a series?](#running-a-command-after-each-commit)
- [One of my `exec` commands failed. Where am I and how do I go on?](#when-the-command-fails)
- [Can I make a failed command run again after I fix it?](#running-it-again-after-the-fix)

**[Splitting a commit](#splitting-a-commit)**

- [How do I split a commit that does two unrelated things?](#splitting-a-commit)

**[update-ref in the todo list](#update-ref-in-the-todo-list)**

- [What are these `update-ref` lines in my todo list?](#update-ref-in-the-todo-list)

**[Rebasing merges](#rebasing-merges)**

- [My branch has merges in it and the rebase flattened them. How do I keep them?](#rebasing-merges)
- [What do `label`, `reset` and `merge` mean in the todo list?](#rebasing-merges)
- [What is the difference between `rebase-cousins` and `no-rebase-cousins`?](#rebasing-merges)

**[Starting from the root](#starting-from-the-root)**

- [How do I include the very first commit in the list?](#starting-from-the-root)

**[Editing the list after it has started](#editing-the-list-after-it-has-started)**

- [I want to change my mind about the remaining commits. Can I edit the list now?](#editing-the-list-after-it-has-started)

**[When the todo list is wrong](#when-the-todo-list-is-wrong)**

- [I typed a command that does not exist. What does Git do?](#when-the-todo-list-is-wrong)
- ["some commits may have been dropped accidentally" — what does that mean?](#when-the-todo-list-is-wrong)

**[Where the rebase keeps its state](#where-the-rebase-keeps-its-state)**

- [I closed the terminal in the middle of a rebase. Is my repository stuck?](#where-the-rebase-keeps-its-state)
- [Can I switch branches while a rebase is stopped?](#where-the-rebase-keeps-its-state)

**[Interactive rebase and its neighbours](#interactive-rebase-and-its-neighbours)**

- [When is `git commit --amend` enough?](#interactive-rebase-and-its-neighbours)
- [Is there a simpler way to do the same thing?](#interactive-rebase-and-its-neighbours)

**[The settings](#the-settings)**

- [Which settings change the todo list or the editor?](#the-settings)

</details>

## Synopsis

```
git rebase -i [<options>] [--exec <cmd>] [--onto <newbase> | --keep-base] [<upstream> [<branch>]]
git rebase -i [<options>] [--exec <cmd>] [--onto <newbase>] --root [<branch>]
git rebase --continue | --skip | --abort | --quit | --edit-todo
```

The argument is the last commit you want to leave alone: `git rebase -i
HEAD~3` lists the three commits after `HEAD~3`, which are the last three.
To change a particular commit, name its parent — `git rebase -i <commit>^`.

| Command | Does |
|---|---|
| `git rebase -i main` | List every commit this branch has that `main` does not |
| `git rebase -i HEAD~3` | List the last three commits |
| `git rebase -i --root` | List every commit, including the first |
| `git rebase --edit-todo` | Reopen the list of what is left to do |
| `git rebase --continue` | Carry on after a stop |

## The todo list commands at a glance

| Command | Short | Does | Covered in |
|---|---|---|---|
| `pick <commit>` | `p` | Use the commit as it is | [The todo list](#the-todo-list) |
| `reword <commit>` | `r` | Use it, but open an editor on the message | [reword](#reword) |
| `edit <commit>` | `e` | Apply it, then stop so you can change it | [edit](#edit) |
| `squash <commit>` | `s` | Fold it into the commit before, joining the messages | [squash and fixup](#squash-and-fixup) |
| `fixup <commit>` | `f` | Fold it in, keeping only the earlier message | [squash and fixup](#squash-and-fixup) |
| `fixup -C <commit>` | | Fold it in, keeping only *this* message | [Keeping the fixup's message](#keeping-the-fixup-s-message) |
| `fixup -c <commit>` | | The same, and open an editor on it | [Keeping the fixup's message](#keeping-the-fixup-s-message) |
| `drop <commit>` | `d` | Leave the commit out | [Dropping a commit](#dropping-a-commit) |
| `exec <command>` | `x` | Run a shell command here | [Running a command after each commit](#running-a-command-after-each-commit) |
| `break` | `b` | Stop here, with nothing to fix | [break](#break) |
| `label <name>` | `l` | Remember the current position under a name | [Rebasing merges](#rebasing-merges) |
| `reset <label>` | `t` | Go back to a remembered position | [Rebasing merges](#rebasing-merges) |
| `merge -C <commit> <label>` | `m` | Make a merge commit | [Rebasing merges](#rebasing-merges) |
| `update-ref <ref>` | `u` | Mark where a branch should end up | [update-ref in the todo list](#update-ref-in-the-todo-list) |

`rebase.abbreviateCommands` makes Git write the short forms; you can always
type either.

## Options at a glance

Every option in Chapter 33 works with `-i` as well. These are the ones that
only mean something here.

| Option | Does | Covered in |
|---|---|---|
| `-i`, `--interactive` | Open the todo list before replaying | [The todo list](#the-todo-list) |
| `-x <cmd>`, `--exec <cmd>` | Add an `exec` line after every commit | [Running a command after each commit](#running-a-command-after-each-commit) |
| `-r`, `--rebase-merges[=(rebase-cousins\|no-rebase-cousins)]`, `--no-rebase-merges` | Recreate merges instead of flattening them | [Rebasing merges](#rebasing-merges) |
| `--update-refs`, `--no-update-refs` | Add `update-ref` lines for branches in the range | [update-ref in the todo list](#update-ref-in-the-todo-list) |
| `--edit-todo` | Reopen the remaining list while stopped | [Editing the list after it has started](#editing-the-list-after-it-has-started) |
| `--reschedule-failed-exec`, `--no-reschedule-failed-exec` | Run a failed `exec` again after `--continue` | [Running it again after the fix](#running-it-again-after-the-fix) |
| `--root` | Include the first commit of the branch | [Starting from the root](#starting-from-the-root) |
| `--autosquash`, `--no-autosquash` | Turn `fixup!` and `squash!` commits into `fixup` and `squash` lines | Chapter 35 |

## The example repository

```console
$ git log --oneline --graph --all --decorate
* 256798b (HEAD -> main) Comment the parser
| * 0e08dae (stack-b) Add b.txt
| * f02b880 (stack-a) Add a.txt
|/
| * a2e6745 (topology) Say the output is coloured
| *   a97bde7 Merge branch 'colours' into topology
| |\
| | * 6182164 (colours) Add colours
| * | c5fa541 Comment the command line
| |/
| * a362114 Add the command line
|/
| * 044513d (work) Add the formatter and the linter
| * b972007 Add the writer
| * bbf01a9 Comment the reader
| * e1fa553 Add the reader
|/
* 9f0c1c7 Add the parser
* 844dd2e Start the project
```

A small parser project. `work` is the branch most examples tidy up: four
commits, one of which comments a file added by the commit before it, and one of
which adds two unrelated files. `topology` has a merge in it, and `stack-a` and
`stack-b` are stacked on each other.

Every example starts with `git switch -q -C try <branch>`, a scratch branch
(Chapter 24), so each begins from the same place.

**The editors.** An interactive rebase opens two: the sequence editor on the
todo list, and your ordinary editor on a commit message when one has to be
written. Git only opens an editor when it is talking to a terminal, which the
sandbox is not, so every example sets `GIT_SEQUENCE_EDITOR` or `GIT_EDITOR` in
the command itself. `cat` means "show me the file and accept it", `true` means
"accept it unchanged", and a `sed` command stands for the edit you would make by
hand — the transcripts say which edit each one makes.

## The todo list

```console
$ git switch -q -C try work
$ GIT_SEQUENCE_EDITOR=cat git rebase -i main
pick e1fa553 # Add the reader
pick bbf01a9 # Comment the reader
pick b972007 # Add the writer
pick 044513d # Add the formatter and the linter

# Rebase 256798b..044513d onto 256798b (4 commands)
#
# Commands:
# p, pick <commit> = use commit
# r, reword <commit> = use commit, but edit the commit message
# e, edit <commit> = use commit, but stop for amending
# s, squash <commit> = use commit, but meld into previous commit
# f, fixup [-C | -c] <commit> = like "squash" but keep only the previous
#                    commit's log message, unless -C is used, in which case
#                    keep only this commit's message; -c is same as -C but
#                    opens the editor
# x, exec <command> = run command (the rest of the line) using shell
# b, break = stop here (continue rebase later with 'git rebase --continue')
# d, drop <commit> = remove commit
# l, label <label> = label current HEAD with a name
# t, reset <label> = reset HEAD to a label
# m, merge [-C <commit> | -c <commit>] <label> [# <oneline>]
#         create a merge commit using the original merge commit's
#         message (or the oneline, if no original merge commit was
#         specified); use -c <commit> to reword the commit message
# u, update-ref <ref> = track a placeholder for the <ref> to be updated
#                       to this position in the new commits. The <ref> is
#                       updated at the end of the rebase
#
# These lines can be re-ordered; they are executed from top to bottom.
#
# If you remove a line here THAT COMMIT WILL BE LOST.
#
# However, if you remove everything, the rebase will be aborted.
#
Rebasing (1/4)
Rebasing (2/4)
Rebasing (3/4)
Rebasing (4/4)
Successfully rebased and updated refs/heads/try.
```

This is the whole interface. Four commits, one line each, `pick` meaning "use
it as it is", and a comment block listing everything else a line can say. Save
and close, and Git carries the list out from top to bottom.

**Oldest first.** The list is in the order the commits will be applied, which is
the reverse of `git log`. That trips everyone up once: the commit at the top is
the *earliest*, and "the one before it" for a `squash` means the line above.

**The subject is a comment.** Git 2.55 writes each line as `pick <hash> #
<subject>`, with the subject after a `#`. Git's own documentation shows the
older form without it. Either way only the command and the commit name are
read: the text after them is there for you, and editing it changes nothing.

**The hashes are what matter.** Change a hash and you change which commit is
used; delete a line and that commit is left out. There is no undo inside the
editor, but nothing has happened yet — the rebase starts when you save.

## Changing nothing, and getting out

```console
$ git switch -q -C try work
$ GIT_SEQUENCE_EDITOR=true git rebase -i HEAD~2
Successfully rebased and updated refs/heads/try.
$ git log --oneline -3
044513d Add the formatter and the linter
b972007 Add the writer
bbf01a9 Comment the reader
```

Saving the list unchanged replays every commit exactly as it was. Here the
hashes did not even change, because nothing about the commits changed and the
sandbox pins the committer date; in an ordinary repository the committer dates
would move and so would the hashes.

```console
$ git switch -q -C try work
$ GIT_SEQUENCE_EDITOR="sed -i 's/^pick/# pick/'" git rebase -i HEAD~2
error: nothing to do
$ git log --oneline -3
044513d Add the formatter and the linter
b972007 Add the writer
bbf01a9 Comment the reader
```

Emptying the list cancels the rebase: `error: nothing to do`, and the branch is
untouched. That is the way out if you opened the editor by mistake — delete
everything, or comment it out as the `sed` above does, and save. Quitting the
editor without saving does the same thing when the editor reports a failure,
but commenting the lines out works with every editor.

## Reordering commits

```console
$ git switch -q -C try work
$ git log --oneline -4
044513d Add the formatter and the linter
b972007 Add the writer
bbf01a9 Comment the reader
e1fa553 Add the reader
$ GIT_SEQUENCE_EDITOR="sed -i -e '1{h;d}' -e '2{G}'" git rebase -i HEAD~3
Rebasing (1/3)
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/try.
$ git log --oneline -4
a9a026c Add the formatter and the linter
9329df5 Comment the reader
d0a54d0 Add the writer
e1fa553 Add the reader
```

Move the lines and the commits move with them. The `sed` here swaps the first
two lines of the file, which is what dragging one line below the other in an
editor would do; `Add the writer` is now applied before `Comment the reader`.

Reordering is where a conflict is most likely, because each commit is applied
to a tree that no longer has the changes that used to come before it. Nothing
special happens if it does: the rebase stops, and Chapter 33's
[When a rebase stops](#ch33-when-a-rebase-stops) applies unchanged.

## Dropping a commit

```console
$ git switch -q -C try work
$ GIT_SEQUENCE_EDITOR="sed -i '2d'" git rebase -i HEAD~3
Rebasing (2/2)
Successfully rebased and updated refs/heads/try.
$ git log --oneline -4
34752c3 Add the formatter and the linter
bbf01a9 Comment the reader
e1fa553 Add the reader
9f0c1c7 Add the parser
$ git switch -q -C try work
$ GIT_SEQUENCE_EDITOR="sed -i '2s/^pick/drop/'" git rebase -i HEAD~3
Rebasing (3/3)
Successfully rebased and updated refs/heads/try.
$ git log --oneline -4
a86e795 Add the formatter and the linter
bbf01a9 Comment the reader
e1fa553 Add the reader
9f0c1c7 Add the parser
```

Deleting the line and writing `drop` in front of it do the same thing — `Add
the writer` is gone either way. The only visible difference is the count:
deleting leaves two commands, `drop` leaves three, because the drop is itself
an instruction.

Writing `drop` is safer, and Git can be told to insist on it: with
`rebase.missingCommitsCheck` set, a deleted line is reported as an accident
([When the todo list is wrong](#when-the-todo-list-is-wrong)).

## reword

```console
$ git switch -q -C try work
$ GIT_SEQUENCE_EDITOR="sed -i '1s/^pick/reword/'" GIT_EDITOR="sed -i '1s/.*/Comment the reader, saying what it reads/'" git rebase -i HEAD~3
Rebasing (1/3)
[detached HEAD 9dc8eb1] Comment the reader, saying what it reads
 Date: Mon Jan 5 12:00:00 2026 +0000
 1 file changed, 1 insertion(+)
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/try.
$ git log --oneline -4
3bca0d4 Add the formatter and the linter
b0c9bd3 Add the writer
9dc8eb1 Comment the reader, saying what it reads
e1fa553 Add the reader
```

`reword` applies the commit unchanged and then opens an editor on its message.
Two editors are involved, and the two `sed` commands stand for them: the first
changes `pick` to `reword` in the todo list, the second replaces the first line
of the message.

Several commits can be reworded in one rebase; the editor opens once for each,
in order.

## edit

```console
$ git switch -q -C try work
$ GIT_SEQUENCE_EDITOR="sed -i '1s/^pick/edit/'" git rebase -i HEAD~3
Rebasing (1/3)
Stopped at bbf01a9...  # Comment the reader
You can amend the commit now, with

  git commit --amend

Once you are satisfied with your changes, run

  git rebase --continue
$ git status --short --branch
## HEAD (no branch)
$ git commit -q -a --amend --no-edit && git log --oneline -1
1c9660c Comment the reader
$ git rebase --continue
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/try.
$ git log --oneline -4 && cat reader.py
884ecef Add the formatter and the linter
56c2168 Add the writer
1c9660c Comment the reader
e1fa553 Add the reader
def read(path): pass
```

`edit` applies the commit and then stops, with the commit made and `HEAD`
detached on it. Git prints the two commands you are likely to want. Anything
you do now becomes part of the history at that point: here the file was
changed and `git commit --amend` folded it into the commit, which is how a
forgotten file gets into a commit five commits back.

`git rebase --continue` replays the rest on top of what you left.

### Adding a commit at that point

```console
$ git switch -q -C try work
$ GIT_SEQUENCE_EDITOR="sed -i '1s/^pick/edit/'" git rebase -i HEAD~3
Rebasing (1/3)
Stopped at bbf01a9...  # Comment the reader
You can amend the commit now, with

  git commit --amend

Once you are satisfied with your changes, run

  git rebase --continue
$ git add CHANGELOG.md && git commit -q -m 'Start a changelog' && git rebase --continue
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/try.
$ git log --oneline -5
1a7cf89 Add the formatter and the linter
84cf2c0 Add the writer
b0ef4e5 Start a changelog
bbf01a9 Comment the reader
e1fa553 Add the reader
```

Nothing says the result of an `edit` has to be one commit. An ordinary
`git commit` inserts a new one at that point in the history, and the rest of
the list is replayed on top. Removing commits works too: `git reset HEAD^`
before continuing is the basis of [Splitting a commit](#splitting-a-commit).

## squash and fixup

```console
$ git switch -q -C try work
$ GIT_SEQUENCE_EDITOR="sed -i '2s/^pick/squash/'" GIT_EDITOR=cat git rebase -i HEAD~3
Rebasing (2/3)
# This is a combination of 2 commits.
# This is the 1st commit message:

Comment the reader

# This is the commit message #2:

Add the writer

# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
#
# Date:      Mon Jan 5 12:00:00 2026 +0000
#
# interactive rebase in progress; onto e1fa553
# Last commands done (2 commands done):
#    pick bbf01a9 # Comment the reader
#    squash b972007 # Add the writer
# Next command to do (1 remaining command):
#    pick 044513d # Add the formatter and the linter
# You are currently rebasing branch 'try' on 'e1fa553'.
#
# Changes to be committed:
#	modified:   reader.py
#	new file:   writer.py
#
[detached HEAD 30a984a] Comment the reader
 Date: Mon Jan 5 12:00:00 2026 +0000
 2 files changed, 2 insertions(+)
 create mode 100644 writer.py
Rebasing (3/3)
Successfully rebased and updated refs/heads/try.
$ git log --oneline -3 && git log -1 --format=%B HEAD~1
01a11de Add the formatter and the linter
30a984a Comment the reader
e1fa553 Add the reader
Comment the reader

Add the writer
```

`squash` folds a commit into the one on the line above it and opens an editor
with both messages, so you can write one that covers the pair. The comment
block shows where you are in the list, which is the clearest place to see that
`squash` works *upwards*.

```console
$ git switch -q -C try work
$ GIT_SEQUENCE_EDITOR="sed -i '2s/^pick/fixup/'" git rebase -i HEAD~3
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/try.
$ git log --oneline -3 && git log -1 --format=%B HEAD~1
4a73821 Add the formatter and the linter
c8827ee Comment the reader
e1fa553 Add the reader
Comment the reader
```

`fixup` does the same to the files and throws the second message away, with no
editor at all. That is the difference, and it is the whole difference:

| Command | The changes | The message | Editor |
|---|---|---|---|
| `squash` | both, in one commit | both, joined | opens |
| `fixup` | both, in one commit | the earlier one only | does not open |
| `fixup -C` | both, in one commit | *this* one only | does not open |
| `fixup -c` | both, in one commit | this one only | opens |

**Authorship.** When commits are folded together the result is attributed to
the author of the first one, as Git's documentation says. Squashing someone
else's commit into yours makes it yours.

### Keeping the fixup's message

```console
$ git switch -q -C try work
$ GIT_SEQUENCE_EDITOR="sed -i '2s/^pick/fixup -C/'" git rebase -i HEAD~3
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/try.
$ git log --oneline -3
161f14d Add the formatter and the linter
e534308 Add the writer
e1fa553 Add the reader
```

`fixup -C` keeps the *later* message: the combined commit is called `Add the
writer` and `Comment the reader` has gone. It is what `git commit
--fixup=amend:` produces automatically (Chapter 35). `fixup -c` is the same
with an editor, in case the kept message needs a word changed.

If more than one `fixup -C` folds into the same commit, the last one's message
wins.

## break

```console
$ git switch -q -C try work
$ GIT_SEQUENCE_EDITOR="sed -i '1a break'" git rebase -i HEAD~3
Rebasing (2/4)
Stopped at bbf01a9 (Comment the reader)
$ git log --oneline -2 && git status --short --branch
bbf01a9 Comment the reader
e1fa553 Add the reader
## HEAD (no branch)
$ git rebase --continue
Rebasing (3/4)
Rebasing (4/4)
Successfully rebased and updated refs/heads/try.
$ git log --oneline -4
044513d Add the formatter and the linter
b972007 Add the writer
bbf01a9 Comment the reader
e1fa553 Add the reader
```

`break` is a line of its own — it takes no commit — and stops the rebase there
with everything up to that point applied. It is `edit` without the amend: a
place to run the tests, look at the tree, or try something, before
`git rebase --continue` carries on.

The `sed` here appends `break` after the first line, which is what typing it on
a new line in the editor would do.

## Running a command after each commit

```console
$ git switch -q -C try work
$ GIT_SEQUENCE_EDITOR=cat git rebase -i --exec 'ls *.py' HEAD~3
pick bbf01a9 # Comment the reader
exec ls *.py
pick b972007 # Add the writer
exec ls *.py
pick 044513d # Add the formatter and the linter
exec ls *.py
...
Rebasing (2/6)
Executing: ls *.py
parser.py
reader.py
Rebasing (3/6)
Rebasing (4/6)
Executing: ls *.py
parser.py
reader.py
writer.py
Rebasing (5/6)
Rebasing (6/6)
Executing: ls *.py
formatter.py
linter.py
parser.py
reader.py
writer.py
Successfully rebased and updated refs/heads/try.
```

`--exec <cmd>` writes an `exec` line after every line that makes a commit, so
the command runs once per commit with the tree as it was at that point. The
todo list above is exactly what `--exec` produced; you can type `exec` lines
yourself in the editor, anywhere you like.

The usual command is a build or a test run: `git rebase -i --exec 'make test'
main` checks that every commit in the series works, not only the last one. The
command is run by the shell from the root of the working tree, so `cd`, `&&`
and `;` all work, and several `--exec` options add several lines.

The comment block is cut here with `...`; it is the same list as in
[The todo list](#the-todo-list).

### When the command fails

```console
$ git switch -q -C try work
$ GIT_SEQUENCE_EDITOR=true git rebase -i --exec 'test -f missing.py' HEAD~3
Rebasing (2/6)
Executing: test -f missing.py
warning: execution failed: test -f missing.py
You can fix the problem, and then run

  git rebase --continue


$ git status --short --branch && git log --oneline -1
## HEAD (no branch)
bbf01a9 Comment the reader
$ git add missing.py && git commit -q --amend --no-edit && git rebase --continue
Rebasing (3/6)
Rebasing (4/6)
Executing: test -f missing.py
Rebasing (5/6)
Rebasing (6/6)
Executing: test -f missing.py
Successfully rebased and updated refs/heads/try.
$ git log --oneline -4
ac8f307 Add the formatter and the linter
d1cf977 Add the writer
3b36bc3 Comment the reader
e1fa553 Add the reader
```

A command that exits non-zero stops the rebase where it is, with the commit
already made. You are on a detached `HEAD` at that commit, free to fix
whatever the command was complaining about — here by adding the missing file
and amending — and `git rebase --continue` carries on.

`--continue` does *not* run the failed command again. With
`--reschedule-failed-exec` it does, which is what you want when the command is
a test suite you expect to keep failing until it passes. Git's documentation
notes that the choice is remembered for the whole rebase, from the command line
or `rebase.rescheduleFailedExec`, and cannot be changed at `--continue` time.

### Running it again after the fix

```console
$ git switch -q -C try work
$ GIT_SEQUENCE_EDITOR=true git rebase -i --reschedule-failed-exec --exec 'test -f missing.py' HEAD~3
Rebasing (2/6)
Executing: test -f missing.py
warning: execution failed: test -f missing.py
You can fix the problem, and then run

  git rebase --continue


hint: Could not execute the todo command
hint:
hint:     exec test -f missing.py
hint:
hint: It has been rescheduled; To edit the command before continuing, please
hint: edit the todo list first:
hint:
hint:     git rebase --edit-todo
hint:     git rebase --continue
$ git add missing.py && git commit -q --amend --no-edit && git rebase --continue
Rebasing (3/7)
Executing: test -f missing.py
Rebasing (4/7)
Rebasing (5/7)
Executing: test -f missing.py
Rebasing (6/7)
Rebasing (7/7)
Executing: test -f missing.py
Successfully rebased and updated refs/heads/try.
$ git log --oneline -4
17a3c95 Add the formatter and the linter
8c8a8f9 Add the writer
95ab3c3 Comment the reader
e1fa553 Add the reader
```

With `--reschedule-failed-exec` the failed command is put back into the list —
Git says so, and the count goes from six commands to seven — so
`git rebase --continue` runs it again on the fixed tree rather than moving on.
That is what you want when the command is a test suite: without it, continuing
declares the problem solved whether or not it is.

## Splitting a commit

```console
$ git switch -q -C try work
$ git show --stat --oneline HEAD
044513d Add the formatter and the linter
 formatter.py | 1 +
 linter.py    | 1 +
 2 files changed, 2 insertions(+)
$ GIT_SEQUENCE_EDITOR="sed -i '3s/^pick/edit/'" git rebase -i HEAD~3
Rebasing (3/3)
Stopped at 044513d...  # Add the formatter and the linter
You can amend the commit now, with

  git commit --amend

Once you are satisfied with your changes, run

  git rebase --continue
$ git reset -q HEAD^ && git status --short
?? formatter.py
?? linter.py
$ git add formatter.py && git commit -q -m 'Add the formatter'
$ git add linter.py && git commit -q -m 'Add the linter'
$ git rebase --continue
Successfully rebased and updated refs/heads/try.
$ git log --oneline -5
d32ed41 Add the linter
499a74c Add the formatter
b972007 Add the writer
bbf01a9 Comment the reader
e1fa553 Add the reader
```

One commit added two unrelated files; it should have been two commits. Git's
documentation gives this recipe, and it is worth learning as a shape rather
than a spell:

1. `git rebase -i <commit>^`, and mark that commit `edit`.
2. When it stops, `git reset HEAD^` — the commit is undone, its changes are
   back in the working tree, and nothing is staged.
3. `git add` and `git commit` as many times as the commit should have been.
4. `git rebase --continue`.

Step 2 is a mixed reset (Chapter 30), which is why the files show as untracked
here: they did not exist before the commit that was just undone. For a commit
that *changed* files rather than adding them, `git add -p` is the tool for
choosing which parts go in which commit (Chapter 11).

Nothing checks that the pieces add up to the original. If you commit only some
of it and continue, the rest is lost — `git status` before `--continue` is
worth the second it takes.

## update-ref in the todo list

```console
$ git switch -q -C try stack-b
$ GIT_SEQUENCE_EDITOR=cat git rebase -i --update-refs main
pick f02b880 # Add a.txt
update-ref refs/heads/stack-a

pick 0e08dae # Add b.txt
update-ref refs/heads/stack-b

...
Rebasing (1/4)
Rebasing (2/4)
Rebasing (3/4)
Rebasing (4/4)
Successfully rebased and updated refs/heads/try.
Updated the following refs with --update-refs:
	refs/heads/stack-a
	refs/heads/stack-b
$ git log --oneline --decorate -4
95ae985 (HEAD -> try, stack-b) Add b.txt
dc18206 (stack-a) Add a.txt
256798b (main) Comment the parser
9f0c1c7 Add the parser
```

`--update-refs` writes an `update-ref` line wherever a branch pointed, and
moves those branches to the same place in the rewritten history when the rebase
finishes (Chapter 33). In the todo list they are ordinary instructions: you can
delete one to leave that branch behind, move it to a different point, or add
`update-ref refs/heads/<name>` by hand to place a branch where there was none.

The count includes them, which is why four commands replay two commits.

## Rebasing merges

```console
$ git switch -q -C try topology
$ git log --oneline --graph -5
* a2e6745 Say the output is coloured
*   a97bde7 Merge branch 'colours' into topology
|\
| * 6182164 Add colours
* | c5fa541 Comment the command line
|/
* a362114 Add the command line
$ GIT_SEQUENCE_EDITOR=true git rebase -i main
Rebasing (1/4)
Rebasing (2/4)
Rebasing (3/4)
Rebasing (4/4)
Successfully rebased and updated refs/heads/try.
$ git log --oneline --graph -5
* 4024f57 Say the output is coloured
* 208cd0c Add colours
* 7798707 Comment the command line
* 1d85ab8 Add the command line
* 256798b Comment the parser
```

By default a rebase drops merge commits and replays everything as one straight
line: four commits where there were three commits and a merge. Often that is
what you want; when it is not, the branch's shape is gone and cannot be
recovered except by starting again.

```console
$ git switch -q -C try topology
$ GIT_SEQUENCE_EDITOR=cat git rebase -i --rebase-merges main
label onto

# Branch colours
reset onto
pick a362114 # Add the command line
label branch-point
pick 6182164 # Add colours
label colours

reset branch-point # Add the command line
pick c5fa541 # Comment the command line
merge -C a97bde7 colours # Merge branch 'colours' into topology
pick a2e6745 # Say the output is coloured
...
Rebasing (1/10)
Rebasing (2/10)
Rebasing (3/10)
Rebasing (4/10)
Rebasing (5/10)
Rebasing (6/10)
Rebasing (7/10)
Rebasing (8/10)
Rebasing (9/10)
Rebasing (10/10)
Successfully rebased and updated refs/heads/try.
$ git log --oneline --graph -6
* c90107c Say the output is coloured
*   04490cb Merge branch 'colours' into topology
|\  
| * 0d8251d Add colours
* | 2485c05 Comment the command line
|/  
* ed56cc2 Add the command line
* 256798b Comment the parser
```

`--rebase-merges` keeps the shape, and the todo list shows how. Three commands
exist for it:

| Command | Does |
|---|---|
| `label <name>` | remember where `HEAD` is now, under that name |
| `reset <label>` | move `HEAD` back to a remembered point, to start another line of work |
| `merge -C <commit> <label>` | merge that remembered point in, reusing the original merge's message |

Read the list downwards: label the starting point as `onto`; go there and
replay `Add the command line`; label that as `branch-point`; replay
`Add colours` and label the result `colours`; go back to `branch-point`; replay
`Comment the command line`; merge `colours` in; replay the last commit. The
result is the same shape with all-new commits.

The labels are real refs while the rebase runs, under `refs/rewritten/`, and
they are deleted at the end. `merge -c` instead of `-C` opens an editor on the
message, and `merge <label>` with no `-C` at all creates a brand-new merge —
which is how a todo list can be edited to *split* a branch into two lines of
work that are merged at the end.

**Cousins.** A commit whose ancestry does not pass through `<upstream>` — Git's
documentation calls those cousins — keeps its original branch point by default,
`no-rebase-cousins`. `--rebase-merges=rebase-cousins` moves them onto the new
base as well. The difference only shows up in a history with side branches that
never touched the upstream.

> **Careful.** Conflicts resolved inside the original merge are not carried
> over: `--rebase-merges` remakes the merge, so a tricky resolution has to be
> made again. `git rerere` can replay it for you (Chapter 26).

## Starting from the root

```console
$ git switch -q -C try work
$ GIT_SEQUENCE_EDITOR=cat git rebase -i --root
pick 844dd2e # Start the project
pick 9f0c1c7 # Add the parser
pick e1fa553 # Add the reader
pick bbf01a9 # Comment the reader
pick b972007 # Add the writer
pick 044513d # Add the formatter and the linter
...
Rebasing (1/6)
Rebasing (2/6)
Rebasing (3/6)
Rebasing (4/6)
Rebasing (5/6)
Rebasing (6/6)
Successfully rebased and updated refs/heads/try.
$ git log --oneline -6
044513d Add the formatter and the linter
b972007 Add the writer
bbf01a9 Comment the reader
e1fa553 Add the reader
9f0c1c7 Add the parser
844dd2e Start the project
```

`--root` puts every commit in the list, including the first one, which is
otherwise unreachable: there is no `<commit>^` to name as the starting point.
It is the way to reword or amend the very first commit of a repository.

Nothing else is different. Here the list was saved unchanged, so the result is
the same six commits with the same hashes.

## Editing the list after it has started

```console
$ git switch -q -C try work
$ GIT_SEQUENCE_EDITOR="sed -i '1a break'" git rebase -i HEAD~3
Rebasing (2/4)
Stopped at bbf01a9 (Comment the reader)
$ GIT_SEQUENCE_EDITOR=cat git rebase --edit-todo
pick b972007 # Add the writer
pick 044513d # Add the formatter and the linter
# You are editing the todo file of an ongoing interactive rebase.
# To continue rebase after editing, run:
...
$ GIT_SEQUENCE_EDITOR="sed -i '2s/^pick/drop/'" git rebase --edit-todo && git rebase --continue
Rebasing (3/4)
Rebasing (4/4)
Successfully rebased and updated refs/heads/try.
$ git log --oneline -4
b972007 Add the writer
bbf01a9 Comment the reader
e1fa553 Add the reader
9f0c1c7 Add the parser
```

While a rebase is stopped, `git rebase --edit-todo` reopens what is left of the
list — only the instructions not yet carried out. Change them however you like:
here the last commit was changed to `drop`, and it was not applied.

This is the answer to "I have changed my mind halfway". It is also how to
recover from a list you got wrong: add the commit you deleted by mistake back
as a `pick` line with its hash, which the reflog or `.git/rebase-merge/done`
can tell you ([Where the rebase keeps its
state](#where-the-rebase-keeps-its-state)).

## When the todo list is wrong

```console
$ git switch -q -C try work
$ GIT_SEQUENCE_EDITOR="sed -i '1s/^pick/pluck/'" git rebase -i HEAD~3
error: invalid command 'pluck'
error: invalid line 1: pluck bbf01a9 # Comment the reader
You can fix this with 'git rebase --edit-todo' and then run 'git rebase --continue'.
Or you can abort the rebase with 'git rebase --abort'.
$ git rebase --abort
$ GIT_SEQUENCE_EDITOR="sed -i '1d'" git -c rebase.missingCommitsCheck=error rebase -i HEAD~3
Warning: some commits may have been dropped accidentally.
Dropped commits (newer to older):
 - bbf01a9 # Comment the reader
To avoid this message, use "drop" to explicitly remove a commit.

Use 'git config rebase.missingCommitsCheck' to change the level of warnings.
The possible behaviours are: ignore, warn, error.

You can fix this with 'git rebase --edit-todo' and then run 'git rebase --continue'.
Or you can abort the rebase with 'git rebase --abort'.
$ git rebase --abort 2>&1 | tail -1
$ git log --oneline -4
044513d Add the formatter and the linter
b972007 Add the writer
bbf01a9 Comment the reader
e1fa553 Add the reader
```

A word Git does not recognise stops everything before any commit is replayed,
and names the line. The rebase is left in progress so that you can fix the list
rather than start again: `--edit-todo` then `--continue`, or `--abort`.

The second message is the safety net for the commonest mistake, deleting a line
without meaning to. `rebase.missingCommitsCheck` has three values:

| Value | When a commit's line disappears |
|---|---|
| `ignore` | nothing is said; the default |
| `warn` | the warning is printed, and the rebase goes ahead |
| `error` | the warning is printed and the rebase stops, as above |

Setting it to `warn` or `error` is cheap insurance for anyone who edits todo
lists often.

## Where the rebase keeps its state

```console
$ git switch -q -C try work
$ GIT_SEQUENCE_EDITOR="sed -i '1a break'" git rebase -i HEAD~3
Rebasing (2/4)
Stopped at bbf01a9 (Comment the reader)
$ ls .git/rebase-merge
done
end
git-rebase-todo
git-rebase-todo.backup
head-name
interactive
msgnum
no-reschedule-failed-exec
onto
orig-head
$ cat .git/rebase-merge/git-rebase-todo
pick b972007b7795e13b4b420cbf6a66fa1e7b1209a1 # Add the writer
pick 044513d6cecf81d43d079ecfea8dfab34b0148d4 # Add the formatter and the linter
$ cat .git/rebase-merge/done
pick bbf01a940794e559ad0516d595477e5bdfd2c162 # Comment the reader
break
$ git switch -q main
fatal: cannot switch branch while rebasing
Consider "git rebase --quit" or "git worktree add".
$ git rebase --abort && git status --short --branch
## try
```

A stopped rebase is a directory, not a running program. Closing the terminal,
rebooting, or coming back a week later changes nothing: the state is on disk
and `git status` will tell you it is there.

| File | Holds |
|---|---|
| `git-rebase-todo` | what is left to do |
| `git-rebase-todo.backup` | the list as it was before your edit |
| `done` | what has been carried out, in order |
| `head-name` | the branch being rebased, so `--abort` knows where to go |
| `onto`, `orig-head` | the new base, and where the branch was |

`git-rebase-todo.backup` and `done` between them hold every hash the rebase
knows about, which is the fastest way to recover a commit you deleted from the
list by mistake.

You cannot switch branches while a rebase is stopped, because `HEAD` is in the
middle of being moved. Finish it, abort it, or `git rebase --quit` and deal
with the mess afterwards — or, if you genuinely need to work elsewhere
meanwhile, `git worktree add` gives you a second working tree with its own
`HEAD` (Chapter 56).

## Interactive rebase and its neighbours

| What you want | Reach for | Chapter |
|---|---|---|
| Change the last commit | `git commit --amend` | Chapter 29 |
| Change one older commit's message | `git history reword <commit>` | Chapter 35 |
| Fold a staged fix into one older commit | `git history fixup <commit>` | Chapter 35 |
| Split one older commit | `git history split <commit>` | Chapter 35 |
| Fold a series of prepared fixes in | `git rebase --autosquash` | Chapter 35 |
| Anything involving several commits at once | `git rebase -i` | this chapter |
| Drop a range of commits, without an editor | `git rebase --onto` | Chapter 33 |

An interactive rebase is the general tool, and the others are shortcuts for
cases common enough to deserve one. The shortcuts are worth knowing because
they do not open an editor on a list, which is where mistakes come from: there
is no line to delete by accident and no order to get backwards.

The rule of thumb: if you can say what you want in one sentence about one
commit, one of the shortcuts in Chapter 35 probably does it. If the sentence
has "and then" in it, use the todo list.

## The settings

| Setting | Does |
|---|---|
| `sequence.editor` | Which editor opens on the todo list; `GIT_SEQUENCE_EDITOR` overrides it, and both fall back to `core.editor` |
| `rebase.abbreviateCommands` | Write `p` and `f` rather than `pick` and `fixup` in the list |
| `rebase.instructionFormat` | How each commit is described on its line, in `git log` format; the hash is always prepended |
| `rebase.missingCommitsCheck` | `ignore`, `warn` or `error` when a line disappears |
| `rebase.rescheduleFailedExec` | Run a failed `exec` again on `--continue` |
| `rebase.autoSquash` | Turn `fixup!` commits into `fixup` lines automatically (Chapter 35) |
| `rebase.updateRefs` | Add `update-ref` lines for stacked branches (Chapter 33) |
| `rebase.rebaseMerges` | Recreate merges by default |
