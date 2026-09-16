# Chapter 35. fixup, autosquash, and git history

## What it is

You have found a mistake in a commit that is not the last one. This chapter is
about the two ways to fix it without editing a todo list by hand.

The first is a pair: `git commit --fixup=<commit>` records the fix as a commit
marked for a particular target, and `git rebase --autosquash` later folds every
such commit into the commit it names. The work is split in two — mark now, fold
later — which is what makes it comfortable while you are still working.

The second is `git history`, added in Git 2.54 and still experimental: one
command that rewrites one commit in the middle of a branch, with no todo list
at all.

| Term | Means |
|---|---|
| *fixup commit* | an ordinary commit whose subject is `fixup! <target subject>` |
| *squash commit* | the same, with `squash!`, keeping its own message as well |
| *amend commit* | the same, with `amend!`, replacing the target's message |
| *autosquash* | a rebase that turns those markers into `fixup` and `squash` lines and moves them next to their targets |
| *target* | the commit a marker names |

Everything here is a rewrite in the sense of Chapter 28, and everything the
markers do could be done by editing a todo list by hand (Chapter 34). What they
add is that you can record the fix the moment you find it, keep working, and
fold everything in at the end in one step.

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [I found a bug in a commit I made yesterday. What is the least painful fix?](#what-it-is)
- [What is a "fixup commit", and how is it different from an ordinary one?](#what-it-is)

**[Synopsis](#synopsis)**

- [What are the forms of `git commit --fixup`, `git rebase --autosquash` and `git history`?](#synopsis)

**[Options at a glance](#options-at-a-glance)**

- [Which options belong to which of these commands?](#options-at-a-glance)

**[The example repository](#the-example-repository)**

- [What repository do the examples use?](#the-example-repository)

**[Making a fixup commit](#making-a-fixup-commit)**

- [How do I record a fix that belongs to an older commit?](#making-a-fixup-commit)
- [What message does the fixup commit get?](#making-a-fixup-commit)
- [Do I have to name the target by hash?](#naming-the-target-another-way)

**[Making a squash commit](#making-a-squash-commit)**

- [What is the difference between `--squash` and `--fixup`?](#making-a-squash-commit)

**[Replacing the message too](#replacing-the-message-too)**

- [I want to fix an old commit's message as well as its content. What do I use?](#replacing-the-message-too)
- [What does `--fixup=reword:` do that `--fixup=amend:` does not?](#replacing-the-message-too)

**[Folding them in](#folding-them-in)**

- [How do I actually apply my fixup commits?](#folding-them-in)
- [What do the todo lines look like after autosquash has rearranged them?](#folding-them-in)
- [Can I autosquash without an editor opening?](#without-the-editor)
- [How do I turn autosquash on for every rebase?](#turning-it-on-for-good)
- [How do I turn it off again for one command?](#turning-it-off-again)
- [Where does the rebase have to start for the fixups to be picked up?](#where-the-rebase-has-to-start)

**[Writing the marker by hand](#writing-the-marker-by-hand)**

- [Can I just write `fixup!` in a message myself?](#writing-the-marker-by-hand)

**[When the target is ambiguous](#when-the-target-is-ambiguous)**

- [I have two commits with the same subject. Which one does my fixup land on?](#when-the-target-is-ambiguous)

**[git history fixup](#git-history-fixup)**

- [Is there a way to fold a staged fix into an old commit in one command?](#git-history-fixup)
- [What happens to the message and the author of the commit I fixed?](#git-history-fixup)
- [How do I see what it would change before it changes it?](#seeing-what-it-would-do-first)
- [How do I change the message at the same time?](#changing-the-message-as-well)
- [The target commit would become empty. What happens to it?](#when-the-fixup-empties-the-commit)

**[git history reword](#git-history-reword)**

- [How do I change an old commit's message without starting a rebase?](#git-history-reword)

**[git history split](#git-history-split)**

- [How do I split an old commit in two without an interactive rebase?](#git-history-split)
- [Which of the two commits keeps the original message?](#git-history-split)

**[Which branches move](#which-branches-move)**

- [Other branches point into the part of history I rewrote. What happens to them?](#which-branches-move)
- [How do I move only the current branch?](#which-branches-move)

**[What git history refuses](#what-git-history-refuses)**

- [It says replaying merge commits is not supported. What do I use instead?](#what-git-history-refuses)
- [Why does it refuse when there would be a conflict?](#what-git-history-refuses)

**[Checking a rewrite with range-diff](#checking-a-rewrite-with-range-diff)**

- [How do I check that a rewrite changed only what I meant it to?](#checking-a-rewrite-with-range-diff)
- [What do the `=`, `!`, `<` and `>` in the left column mean?](#checking-a-rewrite-with-range-diff)
- [How do I see only the summary, without the diffs?](#a-smaller-change-seen-as-a-change)

**[Which tool for which job](#which-tool-for-which-job)**

- [Amend, fixup, interactive rebase or `git history` — which one for my case?](#which-tool-for-which-job)

**[The settings](#the-settings)**

- [Which settings affect fixups and autosquash?](#the-settings)

</details>

## Synopsis

```
git commit --fixup=[(amend|reword):]<commit> [<options>]
git commit --squash=<commit> [<options>]
git rebase [-i] --autosquash [<options>] [<upstream> [<branch>]]

git history fixup <commit> [--dry-run] [--update-refs=(branches|head)] [--reedit-message] [--empty=(drop|keep|abort)]
git history reword <commit> [--dry-run] [--update-refs=(branches|head)]
git history split <commit> [--dry-run] [--update-refs=(branches|head)] [--] [<pathspec>...]
```

| Command | Does |
|---|---|
| `git commit --fixup=<commit>` | Commit the staged changes, marked to be folded into `<commit>` |
| `git commit --squash=<commit>` | The same, keeping this commit's message as well |
| `git commit --fixup=amend:<commit>` | The same, and replace `<commit>`'s message |
| `git commit --fixup=reword:<commit>` | Replace `<commit>`'s message and nothing else |
| `git rebase --autosquash <upstream>` | Fold every marked commit into its target |
| `git history fixup <commit>` | Fold the staged changes into `<commit>`, now |
| `git history reword <commit>` | Change `<commit>`'s message, now |
| `git history split <commit>` | Split `<commit>` in two, choosing hunks |

> **Since Git 2.54.** `git history`, with `reword` and `split`.
>
> **Since Git 2.55.** `git history fixup`.

## Options at a glance

### git commit

| Option | Does | Covered in |
|---|---|---|
| `--fixup=<commit>` | Write `fixup! <subject>` as the message | [Making a fixup commit](#making-a-fixup-commit) |
| `--squash=<commit>` | Write `squash! <subject>`, and keep a message of your own | [Making a squash commit](#making-a-squash-commit) |
| `--fixup=amend:<commit>` | Write `amend! <subject>`, with the target's message to edit | [Replacing the message too](#replacing-the-message-too) |
| `--fixup=reword:<commit>` | The same, ignoring anything staged | [Replacing the message too](#replacing-the-message-too) |

### git rebase

| Option | Does | Covered in |
|---|---|---|
| `--autosquash` | Turn the markers into `fixup` and `squash` lines, in place | [Folding them in](#folding-them-in) |
| `--no-autosquash` | Do not, whatever `rebase.autoSquash` says | [Turning it off again](#turning-it-off-again) |

### git history

| Option | Does | Covered in |
|---|---|---|
| `--dry-run` | Print the ref updates instead of making them | [Seeing what it would do first](#seeing-what-it-would-do-first) |
| `--reedit-message` | Open an editor on the target's message as well | [Changing the message as well](#changing-the-message-as-well) |
| `--empty=drop` | Drop the commit if the fixup empties it; the default | [When the fixup empties the commit](#when-the-fixup-empties-the-commit) |
| `--empty=keep` | Keep it as an empty commit | [When the fixup empties the commit](#when-the-fixup-empties-the-commit) |
| `--empty=abort` | Stop with an error instead | [When the fixup empties the commit](#when-the-fixup-empties-the-commit) |
| `--update-refs=branches` | Move every branch that descends from the target; the default | [Which branches move](#which-branches-move) |
| `--update-refs=head` | Move only the current branch | [Which branches move](#which-branches-move) |

### git range-diff

| Option | Does | Covered in |
|---|---|---|
| `--no-patch`, `-s` | Show only the summary lines | [A smaller change, seen as a change](#a-smaller-change-seen-as-a-change) |

## The example repository

```console
$ git log --oneline --graph --all --decorate
* 8d80740 (work) Add the cache
* b6e2cf0 Add the loger
* a974b54 Add the config reader
* 5416911 (HEAD -> main) Start the tool
$ git show --stat --oneline work~1
b6e2cf0 Add the loger
 logger.py | 1 +
 1 file changed, 1 insertion(+)
```

A small tool, with three commits on `work`. The middle one has a typo in its
subject — `Add the loger` — which several examples fix, and its content is
what the fixups attach to.

Every example starts with `git switch -q -C try work`, a scratch branch
(Chapter 24). `git history` moves every branch that descends from the commit it
rewrites, `work` included, so the examples also put `work` back where it
started before each one; the reader sees only the switch.

Where an editor would open, the examples set `GIT_EDITOR` or
`GIT_SEQUENCE_EDITOR` in the command, as in Chapter 34. `cat` shows the file
and accepts it, `true` accepts it unchanged, and `cp ../message.txt` writes a
prepared message over it — that last one because `git history` holds the
message file open while the editor runs, which an in-place editor such as
`sed -i` cannot cope with.

## Making a fixup commit

```console
$ git switch -q -C try work
$ git add config.py && git commit -q --fixup=HEAD~1 && git log --oneline -4
521a96a fixup! Add the loger
8d80740 Add the cache
b6e2cf0 Add the loger
a974b54 Add the config reader
$ git log -1 --format=%B
fixup! Add the loger
```

`--fixup=<commit>` makes an ordinary commit out of whatever is staged and
writes the message for you: `fixup!` followed by the target's subject. Nothing
is rewritten yet — the fix sits at the tip of the branch like any other commit,
and you carry on working.

The subject is the whole message. Git's documentation notes that `-m` can add a
body, and that the body is thrown away when the commit is folded in, so it is
only a note to yourself.

### Naming the target another way

```console
$ git switch -q -C try work
$ git add config.py && git commit -q --fixup=b6e2cf0 && git log -1 --format=%s
fixup! Add the loger
$ git switch -q -C try work
$ git add config.py && git commit -q --fixup=:/loger && git log -1 --format=%s
fixup! Add the loger
```

The target is any revision (Chapter 18): a hash, `HEAD~2`, a branch name, or
`:/text` to mean the most recent commit whose message contains `text`. What
ends up in the message is always the target's subject, whichever way you named
it — which is what the rebase matches on later.

## Making a squash commit

```console
$ git switch -q -C try work
$ git add config.py && git commit -q --squash=HEAD~1 -m 'and a writer too' && git log -1 --format=%B
squash! Add the loger

and a writer too
```

`--squash` is the same idea for a fix that deserves to be mentioned in the
message. The marker is `squash!`, and anything you add with `-m` is kept: when
the commit is folded in, the target's message and this one are joined, with an
editor open on the result (Chapter 34).

| Marker | Changes | Message afterwards |
|---|---|---|
| `fixup!` | folded in | the target's, unchanged |
| `squash!` | folded in | the target's and this one, joined, in an editor |
| `amend!` | folded in | this one's, replacing the target's |

## Replacing the message too

```console
$ git switch -q -C try work
$ git add config.py && GIT_EDITOR=cat git commit -q --fixup=amend:HEAD~1
amend! Add the loger

Add the loger

# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
#
# On branch try
# Changes to be committed:
#	modified:   config.py
#
$ git log -1 --format=%B
amend! Add the loger

Add the loger
```

`--fixup=amend:<commit>` writes an `amend!` commit: the subject is the marker,
and the body starts as a copy of the target's message, opened in an editor so
you can rewrite it. When the rebase folds it in, that body becomes the target's
new message.

The editor here is `cat`, so the message was accepted as it came; a real edit
would replace `Add the loger` in the body with the message you want.

```console
$ git switch -q -C try work
$ GIT_EDITOR="sed -i '3s/.*/Add the logger/'" git commit -q --fixup=reword:HEAD~1 && git log -1 --format=%B
amend! Add the loger

Add the logger

$ git show --stat --oneline HEAD
7afac4d amend! Add the loger
```

`--fixup=reword:<commit>` is the same thing for a message-only fix: Git's
documentation defines it as `--fixup=amend: --only`, so nothing staged is
included. `git show --stat` confirms it — the commit has no files in it at all.

The `sed` replaces the third line, which is the body: the `amend!` subject on
line one has to stay, because that is what the rebase matches.

> **Careful.** An `amend!` commit with an empty body is an error unless
> `--allow-empty-message` is given, because the empty body would become the
> target's new message.

## Folding them in

```console
$ git switch -q -C try work
$ git add config.py && git commit -q --fixup=:/config
$ git add logger.py && git commit -q --fixup=:/loger && git log --oneline -5
67fbb8f fixup! Add the loger
c8e77d0 fixup! Add the config reader
8d80740 Add the cache
b6e2cf0 Add the loger
a974b54 Add the config reader
$ GIT_SEQUENCE_EDITOR=cat git rebase -i --autosquash main
pick a974b54 # Add the config reader
fixup c8e77d0 # fixup! Add the config reader
pick b6e2cf0 # Add the loger
fixup 67fbb8f # fixup! Add the loger
pick 8d80740 # Add the cache
...
Rebasing (2/5)
Rebasing (3/5)
Rebasing (4/5)
Rebasing (5/5)
Successfully rebased and updated refs/heads/try.
$ git log --oneline -4
be6012e Add the cache
94ab8d2 Add the loger
2b2b7b8 Add the config reader
5416911 Start the tool
$ git show --stat --oneline HEAD~1
94ab8d2 Add the loger
 logger.py | 2 ++
 1 file changed, 2 insertions(+)
```

Two fixups, made in the order the fixes were found, and one rebase. This is the
whole point of the pair: `--autosquash` reads the markers, moves each fixup
commit to sit directly after its target, and changes its `pick` to `fixup`.
The todo list above is what it produced, and the result has three commits
again, each containing its own fix.

The comment block is cut with `...`; it is the list in Chapter 34.

### Without the editor

```console
$ git switch -q -C try work
$ git add config.py && git commit -q --fixup=HEAD~1
$ git rebase --autosquash main
Rebasing (3/4)
Rebasing (4/4)
Successfully rebased and updated refs/heads/try.
$ git log --oneline -4
515eb10 Add the cache
675404a Add the loger
a974b54 Add the config reader
5416911 Start the tool
```

`--autosquash` without `-i` does the whole thing without opening anything. That
is the everyday form once you trust it; `-i` is for when you want to see the
list before it happens, which is worth doing the first few times and whenever
the branch is long.

### Turning it on for good

```console
$ git switch -q -C try work
$ git add config.py && git commit -q --fixup=HEAD~1
$ GIT_SEQUENCE_EDITOR=cat git -c rebase.autoSquash=true rebase -i main | head -5
pick a974b54 # Add the config reader
pick b6e2cf0 # Add the loger
fixup 8e8e18c # fixup! Add the loger
pick 8d80740 # Add the cache

Rebasing (3/4)
Rebasing (4/4)
Successfully rebased and updated refs/heads/try.
```

`rebase.autoSquash=true` makes every interactive rebase autosquash without the
option. Git's documentation is precise about the scope: the setting applies to
interactive rebases, and `--no-autosquash` overrides it. `git -c <name>=<value>`
sets a variable for one command (Chapter 62); `head -5` cuts the comment block.

### Turning it off again

```console
$ git switch -q -C try work
$ git add config.py && git commit -q --fixup=HEAD~1
$ GIT_SEQUENCE_EDITOR=cat git -c rebase.autoSquash=true rebase -i --no-autosquash main | head -5
pick a974b54 # Add the config reader
pick b6e2cf0 # Add the loger
pick 8d80740 # Add the cache
pick f8ea18c # fixup! Add the loger

Successfully rebased and updated refs/heads/try.
```

`--no-autosquash` overrides the setting for one command: the fixup commit is
listed last as an ordinary `pick`, exactly where it was made, and nothing is
folded. That is what you want when the branch has fixups for several targets
and you mean to deal with them by hand.

### Where the rebase has to start

```console
$ git switch -q -C try work
$ git add config.py && git commit -q --fixup=HEAD~2
$ GIT_SEQUENCE_EDITOR=cat git rebase -i --autosquash HEAD~2 | head -4
pick 8d80740 # Add the cache
pick d2b4e6b # fixup! Add the config reader

# Rebase b6e2cf0..d2b4e6b onto b6e2cf0 (2 commands)
Successfully rebased and updated refs/heads/try.
$ GIT_SEQUENCE_EDITOR=cat git rebase -i --autosquash HEAD~4 | head -5
pick a974b54 # Add the config reader
fixup d2b4e6b # fixup! Add the config reader
pick b6e2cf0 # Add the loger
pick 8d80740 # Add the cache

Rebasing (2/4)
Rebasing (3/4)
Rebasing (4/4)
Successfully rebased and updated refs/heads/try.
$ git log --oneline -4
4851ed5 Add the cache
22f10f7 Add the loger
be0aa2a Add the config reader
5416911 Start the tool
```

A fixup can only be moved if its target is in the list. In the first rebase the
range started after `Add the config reader`, so the fixup stayed where it was,
as a plain `pick` — the rebase succeeded and changed nothing useful.

The second rebase starts far enough back, the target is in the list, and the
fixup is moved and folded. Start the rebase at or before the oldest target, or
just use the upstream branch, which is what `git rebase --autosquash main` does
in every other example here.

## Writing the marker by hand

```console
$ git switch -q -C try work
$ git add config.py && git commit -q -m 'fixup! Add the config reader'
$ git rebase --autosquash main
Rebasing (2/4)
Rebasing (3/4)
Rebasing (4/4)
Successfully rebased and updated refs/heads/try.
$ git log --oneline -4
b25e5d7 Add the cache
02d81f4 Add the loger
66384ee Add the config reader
5416911 Start the tool
```

There is nothing magic about `--fixup`: it writes a message, and a message
typed by hand works exactly the same. That matters when the fix was already
committed with an ordinary message — `git commit --amend -m 'fixup! ...'`
turns it into a fixup — and when a tool or a colleague made the commit.

Git's documentation describes the matching: a subject beginning `fixup! `,
`squash! ` or `amend! ` is taken as naming a commit, matching a subject or a
hash, and if nothing matches exactly, a commit whose subject *starts* with the
text.

## When the target is ambiguous

```console
$ git switch -q -C try work
$ git commit -q -am 'Add the cache' --allow-empty && git log --oneline -4
e2f3c9a Add the cache
8d80740 Add the cache
b6e2cf0 Add the loger
a974b54 Add the config reader
$ git add config.py && git commit -q -m 'fixup! Add the cache'
$ GIT_SEQUENCE_EDITOR=cat git rebase -i --autosquash main | head -6
pick a974b54 # Add the config reader
pick b6e2cf0 # Add the loger
pick 8d80740 # Add the cache
fixup cbfbca5 # fixup! Add the cache
pick e2f3c9a # Add the cache # empty

Rebasing (4/5)
Rebasing (5/5)
Successfully rebased and updated refs/heads/try.
```

With two commits called `Add the cache`, the fixup was attached to the *older*
one. Nothing warns you: the marker names a subject, and if two commits share a
subject the first one in the list wins.

Name the target by hash when subjects repeat — `--fixup=<hash>` still writes
the subject into the message, but you can change the line by hand to something
unambiguous, or fold that one in with an interactive rebase instead. The
`# empty` on the last line is Git noting that the commit contains no changes.

## git history fixup

```console
$ git switch -q -C try work
$ git log --oneline -4
8d80740 Add the cache
b6e2cf0 Add the loger
a974b54 Add the config reader
5416911 Start the tool
$ git add config.py && git history fixup HEAD~1
$ git log --oneline -4 && git show --stat --oneline HEAD~1
df55a43 Add the cache
d12f90a Add the loger
a974b54 Add the config reader
5416911 Start the tool
d12f90a Add the loger
 config.py | 2 ++
 logger.py | 1 +
 2 files changed, 3 insertions(+)
$ git log -1 --pretty=fuller HEAD~1
commit d12f90a7c8596d333e0c99d73ecd5f1acf5f1dc1
Author:     Ada Lovelace <ada@example.com>
AuthorDate: Mon Jan 5 11:00:00 2026 +0000
Commit:     Ada Lovelace <ada@example.com>
CommitDate: Tue Jan 6 18:00:00 2026 +0000

    Add the loger
```

One command, no markers and no todo list: the staged changes are folded into
the commit named, and everything after it is replayed. It prints nothing when
it works.

The target keeps its message and its author — the author date is still the
original — while the committer date is now, exactly as an amend does
(Chapter 29). Git's documentation describes the mechanism as a three-way merge
between `HEAD`, the target, and the tree the staged changes make, which is why
it can fold a change into a commit several steps back without replaying
anything by hand.

### Seeing what it would do first

```console
$ git switch -q -C try work
$ git add config.py && git history fixup --dry-run HEAD~1
update refs/heads/work 421ed72ad0c63e5df313da80ddb440b763a8f1a6 8d80740bede8b84c00da0b9f3cf9273518537eff
update refs/heads/try 421ed72ad0c63e5df313da80ddb440b763a8f1a6 8d80740bede8b84c00da0b9f3cf9273518537eff
$ git log --oneline -4
8d80740 Add the cache
b6e2cf0 Add the loger
a974b54 Add the config reader
5416911 Start the tool
```

`--dry-run` makes the new commits but moves nothing, and prints what it would
have moved in the format `git update-ref --stdin` reads: the ref, the new
value, the old value (Chapter 74). Nothing changed — the branches are where
they were.

It is the honest way to find out which branches a rewrite would touch before it
touches them; here it names two, `work` and `try`, which is the subject of
[Which branches move](#which-branches-move). Git's documentation notes that the
objects are written, so applying the printed updates later is safe.

### Changing the message as well

```console
$ git switch -q -C try work
$ git add config.py && GIT_EDITOR='cp ../message.txt' git history fixup --reedit-message HEAD~1
$ git log --oneline -4
feb3313 Add the cache
91872a7 Add the logger, and the config writer
a974b54 Add the config reader
5416911 Start the tool
```

By default the message is left alone. `--reedit-message` opens an editor on it
first, so the content fix and the message fix happen in one command — which is
what `git commit --fixup=amend:` prepares for a later rebase.

The editor here is `cp ../message.txt`, which writes a prepared message over
the file Git offers; a reader would type the new message instead.

### When the fixup empties the commit

```console
$ git switch -q -C try work
$ git show HEAD~1 | git apply -R && git add -A && git status --short
D  logger.py
$ git history fixup --empty=drop HEAD~1
$ git log --oneline -4
d953bee Add the cache
a974b54 Add the config reader
5416911 Start the tool
```

Staging the exact reverse of what a commit did — here by applying its own diff
backwards — leaves that commit with nothing in it. The default, `--empty=drop`,
removes it: three commits become two, and the commits after it are replayed
onto its parent.

```console
$ git switch -q -C try work
$ git show HEAD~1 | git apply -R && git add -A && git history fixup --empty=keep HEAD~1
$ git log --oneline -4 && git show --stat --oneline HEAD~1
253a00b Add the cache
6ef20d5 Add the loger
a974b54 Add the config reader
5416911 Start the tool
6ef20d5 Add the loger
$ git switch -q -C try work
$ git show HEAD~1 | git apply -R && git add -A && git history fixup --empty=abort HEAD~1
error: fixup makes commit HEAD~1 empty
$ git log --oneline -4
8d80740 Add the cache
b6e2cf0 Add the loger
a974b54 Add the config reader
5416911 Start the tool
```

`--empty=drop` is the default; the command above spells it out, and leaving it
off does the same thing.

`--empty=keep` leaves the commit in place with no changes in it, which
`git show --stat` shows as a subject and no file list. `--empty=abort` refuses
and changes nothing, which is the safe setting when a fixup emptying its target
would mean you had staged the wrong thing.

The same three values apply to a *descendant* that becomes empty because it made
the same change as the fixup. Git's documentation records one limitation:
dropping the root commit is not supported.

## git history reword

```console
$ git switch -q -C try work
$ GIT_EDITOR='cp ../message.txt' git history reword HEAD~1
$ git log --oneline -4
78bc9a4 Add the cache
6192eee Add the logger
a974b54 Add the config reader
5416911 Start the tool
```

The typo is fixed, everything else about the commit is untouched, and the
commits after it were replayed. This is the whole command: no todo list, no
`reword` line, no `--continue`.

It needs nothing staged and touches no files, which is why Git's documentation
says it works in a bare repository — the `fixup` subcommand is the exception,
because it has to read the index.

## git history split

```console
$ git switch -q -C try work
$ git add -A && git commit -q -m 'Add the parser and the printer' && git show --stat --oneline HEAD
6921709 Add the parser and the printer
 parser.py  | 1 +
 printer.py | 1 +
 2 files changed, 2 insertions(+)
$ printf 'y\nn\n' | GIT_EDITOR=true git history split HEAD; echo
diff --git a/parser.py b/parser.py
new file mode 100644
index 0000000..94336b1
--- /dev/null
+++ b/parser.py
@@ -0,0 +1 @@
+def parse(): pass
(1/1) Stage addition [y,n,q,a,d,?]?
diff --git a/printer.py b/printer.py
new file mode 100644
index 0000000..ecf6693
--- /dev/null
+++ b/printer.py
@@ -0,0 +1 @@
+def show(): pass
(1/1) Stage addition [y,n,q,a,d,?]?

$ git log --oneline -3
eb5f501 Add the parser and the printer
6c6c5a4 Add the parser and the printer
8d80740 Add the cache
$ git show --stat --oneline HEAD && git show --stat --oneline HEAD~1
eb5f501 Add the parser and the printer
 printer.py | 1 +
 1 file changed, 1 insertion(+)
6c6c5a4 Add the parser and the printer
 parser.py | 1 +
 1 file changed, 1 insertion(+)
$ GIT_EDITOR='cp ../message.txt' git history reword HEAD~1 && git log --oneline -3
26913db Add the parser and the printer
ae4d4e6 Add the parser
8d80740 Add the cache
```

`git history split` asks about each hunk the commit introduced, in the same way
as `git add -p` (Chapter 11), and the ones you say yes to are moved into a new
commit that becomes the target's *parent*. The original commit stays, with what
is left.

The `printf` stands for typing the answers — `y` to the parser, `n` to the
printer — and the piped input is not echoed, which is why the questions and the
next diff run together.

Git asks for a message for each of the two commits; `GIT_EDITOR=true` accepted
both unchanged, so both are called `Add the parser and the printer` and the
last command renames the split-out one. In practice you would type the two
messages as the editor opens.

| Refuses when | Because |
|---|---|
| you choose every hunk | the original commit would be left empty |
| you choose no hunks | the new commit would be empty |

A pathspec limits what is offered: `git history split <commit> -- src/` asks
only about hunks under `src/`, and everything else stays in the original commit.

## Which branches move

```console
$ git switch -q -C try work
$ git branch -q later && git log --oneline --decorate -2
8d80740 (HEAD -> try, work, later) Add the cache
b6e2cf0 Add the loger
$ git add config.py && git history fixup --update-refs=head HEAD~1
$ git log --oneline --decorate -3 && git log --oneline --decorate -1 later
6d70e22 (HEAD -> try) Add the cache
3511feb Add the loger
a974b54 Add the config reader
8d80740 (work, later) Add the cache
```

This is the most surprising thing about `git history`, and the reason the
examples in this chapter restore `work` each time. **By default it moves every
local branch that descends from the commit it rewrites**, not only the one you
are on — which is usually what you want for a stack of branches, and startling
if you expected `git rebase`'s behaviour.

`--update-refs=head` limits it to `HEAD`: above, `try` moved and `work` and
`later` stayed on the old commits. `--update-refs=branches` is the default and
would have moved all three.

```console
$ git switch -q -C try work
$ git branch -q later && git log --oneline --decorate -1
8d80740 (HEAD -> try, work, later) Add the cache
$ git add config.py && git history fixup --update-refs=branches HEAD~1
$ git log --oneline --decorate -3
93ce5a7 (HEAD -> try, work, later) Add the cache
54c889f Add the loger
a974b54 Add the config reader
```

`--update-refs=branches` spelled out: all three branches moved together onto the
rewritten history, which is the behaviour a stack of branches wants and the
reason the default is what it is.

Use `--dry-run` first if you are not sure which branches are involved; it names
every one it would update.

## What git history refuses

```console
$ git switch -q -C try work
$ git merge --no-edit side
Merge made by the 'ort' strategy.
 side.py | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 side.py
$ git history reword HEAD~1
error: replaying merge commits is not supported yet!
$ git log --oneline --graph -4
*   7a1cced Merge branch 'side' into try
|\
| * 9a913f3 Add a side file
* | 8d80740 Add the cache
* | b6e2cf0 Add the loger
```

A merge anywhere in the range being replayed stops it. Git's documentation says
so plainly and points at `git rebase --rebase-merges` instead (Chapter 34).

```console
$ git switch -q -C try work
$ git add logger.py && git history fixup HEAD~2
error: fixup would produce conflicts; aborting
$ git log --oneline -3
8d80740 Add the cache
b6e2cf0 Add the loger
a974b54 Add the config reader
```

The other refusal is a conflict. The staged change touches `logger.py`, which
the target commit does not contain, so folding it in cannot be done cleanly —
and `git history` stops rather than leaving you in a conflicted state.

That is deliberate, not a gap: Git's documentation explains that history
rewrites here are not meant to be stateful operations, so there is no
`--continue` and nothing to abort. The limitation can be lifted if Git ever
gains first-class conflicts. When you hit it, use an interactive rebase
(Chapter 34), which can stop and ask.

Nothing was changed by either refusal — the branch is exactly where it was.

> **Worth knowing.** `git history` runs no hooks at all at present, Git's
> documentation says, which is a difference from `git rebase` worth knowing if
> your project relies on `post-rewrite` (Chapter 67).

## Checking a rewrite with range-diff

```console
$ git switch -q -C try work
$ git add config.py && git history fixup HEAD~1
$ git range-diff main 8d80740 HEAD
1:  a974b54 = 1:  a974b54 Add the config reader
2:  b6e2cf0 < -:  ------- Add the loger
-:  ------- > 2:  c5834e4 Add the loger
3:  8d80740 = 3:  f505f01 Add the cache
```

After any rewrite the question is the same: did it change what I meant, and
nothing else? `git range-diff <base> <old-tip> <new-tip>` lines the two
versions of the series up against each other and says what happened to each
commit.

| Left column | Means |
|---|---|
| `=` | the same change, in the same place |
| `!` | the same commit, but its change or its message differs; the difference follows |
| `<` | only in the old series |
| `>` | only in the new series |

Here commit 1 is unchanged and commit 3 is unchanged except for its hash.
Commit 2 differs too much to be paired — its whole content changed when the
fixup was folded in — so it is shown as one gone and one arrived.

### A smaller change, seen as a change

```console
$ git switch -q -C try work
$ GIT_EDITOR='cp ../message.txt' git history reword HEAD~1
$ git range-diff main 8d80740 HEAD
1:  a974b54 = 1:  a974b54 Add the config reader
2:  b6e2cf0 ! 2:  7366008 Add the loger
    @@ Metadata
     Author: Ada Lovelace <ada@example.com>

      ## Commit message ##
    -    Add the loger
    +    Add the logger

      ## logger.py (new) ##
     @@
3:  8d80740 = 3:  daeb6c8 Add the cache
$ git range-diff --no-patch main 8d80740 HEAD
1:  a974b54 = 1:  a974b54 Add the config reader
2:  b6e2cf0 ! 2:  7366008 Add the loger
3:  8d80740 = 3:  daeb6c8 Add the cache
```

A smaller change is recognised as a change: `!` in the middle, with a diff of
diffs underneath. The indented block is read like any diff, except that what is
being compared is the commits themselves: the `## Commit message ##` section
shows the typo fixed, and the unchanged `## logger.py (new) ##` section below
it confirms that the content was not touched.

`--no-patch` prints only the summary lines, which is the form to use on a long
series: one line per commit, and the `!` lines are the ones to look at.

Chapter 13 introduced `git range-diff` as a diff of diffs; this is its main
use. It is also how a reviewer checks what changed between two versions of a
pull request (Chapter 52).

## Which tool for which job

| Your case | Reach for | Chapter |
|---|---|---|
| The commit is the last one | `git commit --amend` | Chapter 29 |
| One older commit, content | `git history fixup <commit>` | this chapter |
| One older commit, message | `git history reword <commit>` | this chapter |
| One older commit, split in two | `git history split <commit>` | this chapter |
| Several fixes, found while working | `git commit --fixup=` now, `git rebase --autosquash` later | this chapter |
| Reorder, drop, or anything with "and then" in it | `git rebase -i` | Chapter 34 |
| The range contains a merge | `git rebase -i --rebase-merges` | Chapter 34 |
| The fix conflicts with what came after | `git rebase -i`, which can stop and ask | Chapter 34 |
| The commits are already shared | `git revert`, or agree the rewrite first | Chapter 31, Chapter 28 |

The two approaches in this chapter suit different moments.
`git commit --fixup` is for while you are still working: it costs nothing to
record a fix and get back to what you were doing, and one rebase at the end
tidies everything at once. `git history` is for when you have already stopped
and know exactly what you want changed.

## The settings

| Setting | Does |
|---|---|
| `rebase.autoSquash` | Autosquash in every interactive rebase without the option |
| `rebase.instructionFormat` | How the todo list describes each commit, fixups included (Chapter 34) |
| `core.editor` | Which editor opens for `amend!` messages and `--reedit-message` (Chapter 62) |
| `commit.cleanup` | How the message is tidied before it is stored (Chapter 12) |
| `diff.algorithm`, `diff.context` | How `git range-diff` compares the two series (Chapter 13) |
