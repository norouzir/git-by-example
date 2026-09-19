# Chapter 33. rebase

## What it is

`git rebase` takes the commits on your branch and makes them again on top of
somewhere else. The originals are left behind unreferenced; the branch moves to
the copies.

It answers one question: *how do I get my work on top of the latest `main`,
without a merge commit?*

Underneath it is a run of cherry-picks (Chapter 32): Git works out which
commits are yours, checks out the new base, and applies each one in turn. That
is why the copies have different hashes, why a rebase can stop on a conflict
halfway through, and why rebasing a branch other people have is the thing
Chapter 28 is about.

| Term | Means |
|---|---|
| *`<upstream>`* | the branch your work is compared against; commits you have that it does not are the ones to be copied |
| *`<branch>`* | the branch being rebased; defaults to the one you are on |
| *`<newbase>`* | where the copies go, with `--onto`; without it, `<upstream>` |
| *merge base* | the commit where the two branches last agreed (Chapter 25) |
| *backend* | which machinery does the replaying: `merge`, the default, or `apply` |
| *patch id* | a hash of a change that ignores line numbers, used to spot commits that are already upstream (Chapter 32) |
| *`REBASE_HEAD`* | while a rebase is stopped, the commit that could not be applied |

This chapter is `git rebase` without the todo list. `-i`, `--exec` and
`--rebase-merges` all work by writing a list of instructions you can edit, and
they are Chapter 34.

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What does rebasing do, in terms of commits?](#what-it-is)
- [Why would I rebase instead of merge?](#what-it-is)

**[Synopsis](#synopsis)**

- [What can I type after `git rebase`, and what does each argument mean?](#synopsis)
- [What does `git rebase` with no arguments do?](#synopsis)

**[Options at a glance](#options-at-a-glance)**

- [Is there a list of every option and where each one is shown?](#options-at-a-glance)

**[The example repository](#the-example-repository)**

- [What repository do the examples use?](#the-example-repository)

**[What a plain rebase does](#what-a-plain-rebase-does)**

- [What are the steps Git goes through during `git rebase main`?](#what-a-plain-rebase-does)
- [Which commits get copied, and onto what?](#what-a-plain-rebase-does)
- [What does "Successfully rebased and updated" actually tell me?](#what-a-plain-rebase-does)
- [What are the `Rebasing (1/2)` lines?](#what-a-plain-rebase-does)

**[What changes in the copied commits](#what-changes-in-the-copied-commits)**

- [Why did every hash change when I rebased?](#what-changes-in-the-copied-commits)
- [Did my commit dates change?](#what-changes-in-the-copied-commits)
- [Are my old commits gone?](#what-changes-in-the-copied-commits)

**[Rebasing when there is nothing to do](#rebasing-when-there-is-nothing-to-do)**

- [It said "Current branch is up to date". Did it do anything?](#rebasing-when-there-is-nothing-to-do)

**[How much rebase prints](#how-much-rebase-prints)**

- [How do I see what changed upstream since I last rebased?](#how-much-rebase-prints)
- [How do I make rebase quiet?](#how-much-rebase-prints)

**[Choosing the new base with --onto](#choosing-the-new-base-with-onto)**

- [How do I move only some of my commits onto another branch?](#choosing-the-new-base-with-onto)
- [What is the difference between `--onto X Y` and rebasing onto X?](#choosing-the-new-base-with-onto)
- [How do I drop a range of commits out of the middle of a branch?](#dropping-commits-out-of-the-middle)

**[Rebasing a branch you are not on](#rebasing-a-branch-you-are-not-on)**

- [Can I rebase a branch without checking it out first?](#rebasing-a-branch-you-are-not-on)
- [Which branch am I on when it finishes?](#rebasing-a-branch-you-are-not-on)

**[--keep-base](#keep-base)**

- [My upstream keeps moving and I do not want to keep landing on its tip. What do I use?](#keep-base)

**[--fork-point](#fork-point)**

- [What does `--fork-point` do, and why is it sometimes on by default?](#fork-point)
- [My rebase dropped commits I did not expect it to. Was this it?](#fork-point)

**[Commits that are already upstream](#commits-that-are-already-upstream)**

- ["warning: skipped previously applied commit" — why, and is that safe?](#commits-that-are-already-upstream)
- [How do I make it apply them anyway?](#reapplying-them-anyway)
- [How does Git decide two commits are the same change?](#commits-that-are-already-upstream)

**[Commits that become empty](#commits-that-become-empty)**

- [A commit became empty during the rebase. What happened to it?](#commits-that-become-empty)
- [What is the difference between `--empty=drop`, `--empty=keep` and `--empty=stop`?](#keeping-them)
- [What about commits that were empty before I started?](#a-commit-that-was-empty-to-start-with)

**[Fast-forwarding](#fast-forwarding)**

- [I rebased and some commits kept their hashes. Why?](#fast-forwarding)
- [How do I force every commit to be replayed as a new one?](#fast-forwarding)

**[When a rebase stops](#when-a-rebase-stops)**

- [The rebase stopped with a conflict. Where am I, and what does `git status` say?](#when-a-rebase-stops)
- [Why is "ours" the branch I am rebasing onto?](#when-a-rebase-stops)
- [How do I see the commit that failed to apply?](#when-a-rebase-stops)
- [I fixed the conflict. Which command carries on?](#finishing-it)
- [Why did continuing open an editor?](#finishing-it)
- [How do I cancel, or drop the commit that is causing trouble?](#abandoning-it)
- [`--abort` or `--quit` — what is the difference?](#abandoning-it)

**[Rebasing with uncommitted changes](#rebasing-with-uncommitted-changes)**

- ["cannot rebase: You have unstaged changes" — do I have to commit them?](#rebasing-with-uncommitted-changes)

**[Moving the other branches too](#moving-the-other-branches-too)**

- [I have branches stacked on each other. Do I have to rebase each one?](#moving-the-other-branches-too)
- [Why does the progress count go up when I use `--update-refs`?](#moving-the-other-branches-too)

**[Rebasing from the root](#rebasing-from-the-root)**

- [How do I include the very first commit of a branch?](#rebasing-from-the-root)

**[The two backends](#the-two-backends)**

- [What are the "apply" and "merge" backends, and which am I using?](#the-two-backends)
- [When would I want `--apply`?](#the-two-backends)

**[Whitespace and context](#whitespace-and-context)**

- [How do I rebase ignoring whitespace-only differences?](#whitespace-and-context)
- [What does `-C<n>` do, and why did it change the messages?](#whitespace-and-context)

**[Dates, authorship and trailers](#dates-authorship-and-trailers)**

- [How do I keep the original dates instead of today's?](#dates-authorship-and-trailers)
- [How do I make the rebased commits look like they were written now?](#dates-authorship-and-trailers)
- [How do I add a `Signed-off-by` or another trailer to every rebased commit?](#dates-authorship-and-trailers)

**[Strategies](#strategies)**

- [Can I rebase preferring one side automatically when it conflicts?](#strategies)
- [Why does `-s ours` do something surprising in a rebase?](#strategies)

**[The pre-rebase hook](#the-pre-rebase-hook)**

- [Can I stop a rebase from happening on certain branches?](#the-pre-rebase-hook)
- [How do I bypass a hook that is blocking me?](#the-pre-rebase-hook)

**[Options that cannot be combined](#options-that-cannot-be-combined)**

- ["cannot be used together" — which options conflict with which?](#options-that-cannot-be-combined)

**[Undoing a rebase](#undoing-a-rebase)**

- [I rebased onto the wrong branch. How do I get back?](#undoing-a-rebase)

**[When the upstream was rebased under you](#when-the-upstream-was-rebased-under-you)**

- [The branch I built on was rebased and now my rebase conflicts with itself. What do I do?](#when-the-upstream-was-rebased-under-you)

**[rebase and its neighbours](#rebase-and-its-neighbours)**

- [Should I rebase or merge?](#rebase-and-its-neighbours)
- [Is rebasing just cherry-picking every commit?](#rebase-and-its-neighbours)
- [Is there a rebase that works without a working tree?](#git-replay)

**[The settings](#the-settings)**

- [Which settings change what rebase does by default?](#the-settings)

</details>

## Synopsis

```
git rebase [-i | --interactive] [<options>] [--exec <cmd>]
	[--onto <newbase> | --keep-base] [<upstream> [<branch>]]
git rebase [-i | --interactive] [<options>] [--exec <cmd>] [--onto <newbase>]
	--root [<branch>]
git rebase (--continue|--skip|--abort|--quit|--edit-todo|--show-current-patch)
```

| Part | Means |
|---|---|
| `<upstream>` | any commit; the commits to copy are those in `<branch>` and not in it |
| `<branch>` | the branch to rebase; with it, Git checks it out first |
| `<newbase>` | where the copies are placed, if not on `<upstream>` |

| Command | Does |
|---|---|
| `git rebase main` | Copy this branch's commits on top of `main` |
| `git rebase` | The same, against the branch's configured upstream |
| `git rebase main topic` | Check out `topic` first, then do the same |
| `git rebase --onto main~2 main~3` | Copy the commits after `main~3` onto `main~2` |
| `git rebase --root` | Include the branch's very first commit |
| `git rebase --continue` | Carry on after resolving a conflict |
| `git rebase --skip` | Drop the commit that stopped it and carry on |
| `git rebase --abort` | Cancel, and put the branch back where it was |
| `git rebase --quit` | Forget the rebase, leaving `HEAD` where it stopped |

With no `<upstream>`, Git uses the branch's configured upstream — usually
`origin/main` — and `--fork-point` is assumed. Off a branch, or on one with no
upstream, it stops rather than guessing.

## Options at a glance

### Choosing what is copied and where

| Option | Does | Covered in |
|---|---|---|
| `--onto <newbase>` | Put the copies on `<newbase>` instead of `<upstream>` | [Choosing the new base with --onto](#choosing-the-new-base-with-onto) |
| `--keep-base` | Keep the current base; only take in what is new upstream | [--keep-base](#keep-base) |
| `--root` | Include the first commit of the branch | [Rebasing from the root](#rebasing-from-the-root) |
| `--fork-point`, `--no-fork-point` | Use the upstream's reflog to work out where the branch forked | [--fork-point](#fork-point) |
| `--reapply-cherry-picks`, `--no-reapply-cherry-picks` | Replay commits already upstream instead of dropping them first | [Reapplying them anyway](#reapplying-them-anyway) |
| `--empty=drop`, `--empty=keep`, `--empty=stop` | What to do with a commit that becomes empty | [Commits that become empty](#commits-that-become-empty) |
| `--keep-empty`, `--no-keep-empty` | Keep or drop commits that were already empty | [A commit that was empty to start with](#a-commit-that-was-empty-to-start-with) |
| `--no-ff`, `-f`, `--force-rebase` | Replay every commit, even ones that could be kept as they are | [Fast-forwarding](#fast-forwarding) |
| `--update-refs`, `--no-update-refs` | Move other branches that point into the range | [Moving the other branches too](#moving-the-other-branches-too) |

### While it runs

| Option | Does | Covered in |
|---|---|---|
| `--continue` | Carry on after a conflict | [Finishing it](#finishing-it) |
| `--skip` | Drop the commit that stopped it | [Abandoning it](#abandoning-it) |
| `--abort` | Cancel and restore the branch | [Abandoning it](#abandoning-it) |
| `--quit` | Forget the rebase without restoring anything | [Abandoning it](#abandoning-it) |
| `--show-current-patch` | Show the commit that could not be applied | [When a rebase stops](#when-a-rebase-stops) |
| `--autostash`, `--no-autostash` | Stash uncommitted changes first and put them back after | [Rebasing with uncommitted changes](#rebasing-with-uncommitted-changes) |
| `--edit-todo` | Edit the remaining instructions | Chapter 34 |

### How the replay is done

| Option | Does | Covered in |
|---|---|---|
| `-m`, `--merge` | Use the merge backend, the default | [The two backends](#the-two-backends) |
| `--apply` | Use the apply backend, which works through patches | [The two backends](#the-two-backends) |
| `-s <strategy>`, `--strategy=<strategy>` | Merge strategy to replay with | [Strategies](#strategies) |
| `-X <option>`, `--strategy-option=<option>` | Pass an option to that strategy | [Strategies](#strategies) |
| `--ignore-whitespace` | Treat whitespace-only differences as no change | [Whitespace and context](#whitespace-and-context) |
| `--whitespace=<action>` | Pass a whitespace action to `git apply`; implies `--apply` | [Whitespace and context](#whitespace-and-context) |
| `-C<n>` | Require `<n>` lines of matching context; implies `--apply` | [Whitespace and context](#whitespace-and-context) |
| `--rerere-autoupdate`, `--no-rerere-autoupdate` | Stage resolutions rerere remembers | Chapter 26 |

### What the copies look like

| Option | Does | Covered in |
|---|---|---|
| `--committer-date-is-author-date` | Give each copy its original author date as committer date | [Dates, authorship and trailers](#dates-authorship-and-trailers) |
| `--reset-author-date`, `--ignore-date` | Set the author date to now | [Dates, authorship and trailers](#dates-authorship-and-trailers) |
| `--signoff` | Add a `Signed-off-by` trailer to every copy | [Dates, authorship and trailers](#dates-authorship-and-trailers) |
| `--trailer=<trailer>` | Add any trailer to every copy | [Dates, authorship and trailers](#dates-authorship-and-trailers) |
| `-S[<keyid>]`, `--gpg-sign[=<keyid>]`, `--no-gpg-sign` | Sign the copies | Chapter 68 |
| `--allow-empty-message` | A no-op kept for old scripts | [A commit that was empty to start with](#a-commit-that-was-empty-to-start-with) |

### Output and hooks

| Option | Does | Covered in |
|---|---|---|
| `-q`, `--quiet` | Print as little as possible | [How much rebase prints](#how-much-rebase-prints) |
| `-v`, `--verbose` | Print more, including the diffstat | [How much rebase prints](#how-much-rebase-prints) |
| `--stat` | Show what changed upstream before starting | [How much rebase prints](#how-much-rebase-prints) |
| `-n`, `--no-stat` | Leave that out | [How much rebase prints](#how-much-rebase-prints) |
| `--no-verify`, `--verify` | Skip the `pre-rebase` hook, or run it | [The pre-rebase hook](#the-pre-rebase-hook) |

### The todo list, in Chapter 34

| Option | Does | Covered in |
|---|---|---|
| `-i`, `--interactive` | Edit the list of commits before they are replayed | Chapter 34 |
| `-x <cmd>`, `--exec <cmd>` | Run a command after each commit | Chapter 34 |
| `-r`, `--rebase-merges[=(rebase-cousins\|no-rebase-cousins)]`, `--no-rebase-merges` | Recreate merge commits instead of flattening them | Chapter 34 |
| `--autosquash`, `--no-autosquash` | Move `fixup!` and `squash!` commits into place | Chapter 35 |
| `--reschedule-failed-exec`, `--no-reschedule-failed-exec` | Run a failed `exec` again after you fix it | Chapter 34 |

<!-- no-example: --reset-author-date  it sets the author date to the moment the
     rebase runs, so the date and the resulting hash differ on every run and no
     transcript of the result can be reproducible. The sandbox clock does not
     reach it: GIT_TEST_DATE_NOW, which fixes "now" for relative dates, does not
     apply to this option, tested in Git 2.55 -->
<!-- no-example: --ignore-date  the other spelling of --reset-author-date, with
     the same problem -->
<!-- no-example: -v  it implies --stat, which is demonstrated, and adds nothing
     else to the output of a rebase that succeeds -->
<!-- no-example: -n  it turns off --stat, which is the default when rebase.stat
     is unset, so on a stock installation the output is identical -->
<!-- no-example: --keep-empty  the default; --no-keep-empty is demonstrated
     beside it in the same section and this is its opposite -->
<!-- no-example: --allow-empty-message  Git's documentation records it as a
     no-op: commits with an empty message no longer stop a rebase, so there is
     no behaviour to show -->

## The example repository

```console
$ git log --oneline --graph --all --decorate
* d6287db (licence) Add humans.txt
* cfb9c37 Add a licence
| * 4adc846 (HEAD -> main) Add a footer
| * 365e69c Add a licence
| * 315a24e Fix the heading and tidy the stylesheet
|/
| * 2ffdc25 (stack-b) Add a sitemap
| * f7fd1a5 (stack-a) Add robots.txt
|/
| * 1c314ba (footer) Add our own footer
|/
| * 086db5d (heading) Fix the heading
|/
| * 76fe3f2 (contact) Mention contact in the about page
| * f925873 Add a contact page
|/
* 5a60db1 Add a stylesheet
* cc016fe Add an about page
* 31c4060 Start the site
```

A small static site. Every branch forked at `Add a stylesheet`, and `main` has
three commits since. Each branch exists to show one situation:

| Branch | Is |
|---|---|
| `contact` | two ordinary commits, which rebase cleanly |
| `heading` | one commit that does part of what a `main` commit does, so it becomes empty |
| `footer` | one commit that touches the same line as `main`'s footer, so it conflicts |
| `stack-a`, `stack-b` | two branches stacked on each other |
| `licence` | a clean copy of `main`'s `Add a licence`, plus one commit of its own |

```console
$ git log --oneline main..contact
76fe3f2 Mention contact in the about page
f925873 Add a contact page
```

`main..contact` is the set of commits a rebase onto `main` would copy
(Chapter 18); it is worth running before a rebase to see what is about to
happen.

Every example starts with `git switch -q -C try <branch>`, a scratch branch at
one of them (Chapter 24), so each begins from the same place and the named
branches stay where they are.

## What a plain rebase does

```console
$ git switch -q -C try contact
$ git log --oneline --graph HEAD main
* 4adc846 Add a footer
* 365e69c Add a licence
* 315a24e Fix the heading and tidy the stylesheet
| * 76fe3f2 Mention contact in the about page
| * f925873 Add a contact page
|/
* 5a60db1 Add a stylesheet
* cc016fe Add an about page
* 31c4060 Start the site
$ git rebase main
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/try.
$ git log --oneline --graph -6
* 4429156 Mention contact in the about page
* 8e3f1ae Add a contact page
* 4adc846 Add a footer
* 365e69c Add a licence
* 315a24e Fix the heading and tidy the stylesheet
* 5a60db1 Add a stylesheet
$ git status --short --branch
## try
```

The fork is gone and the history is a straight line. Git's documentation
describes the steps:

1. List the commits on this branch that are not in `<upstream>` — here the two
   from `main..contact`.
2. Check out `<upstream>`, detached.
3. Apply each of those commits in turn, as `git cherry-pick` would.
4. Move the branch to the last one and check it out again.

The `Rebasing (1/2)` lines are that third step counting through. Git ends each
with a carriage return rather than a newline, so on a terminal they are drawn
over one another and you see one changing line; in a transcript they are
separate lines.

`Successfully rebased and updated refs/heads/try` is the fourth step: the
branch, named in full, now points at the last copy. Until that line appears the
branch has not moved at all — which is why an interrupted rebase leaves the
branch where it was.

## What changes in the copied commits

```console
$ git switch -q -C try contact
$ git log --format='%h %p %s' -3
76fe3f2 f925873 Mention contact in the about page
f925873 5a60db1 Add a contact page
5a60db1 cc016fe Add a stylesheet
$ git log -1 --pretty=fuller
commit 76fe3f29e3d949340a33746917620bb63c93ac89
Author:     Ada Lovelace <ada@example.com>
AuthorDate: Mon Jan 5 13:00:00 2026 +0000
Commit:     Ada Lovelace <ada@example.com>
CommitDate: Mon Jan 5 13:00:00 2026 +0000

    Mention contact in the about page
$ git rebase main
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/try.
$ git log --format='%h %p %s' -3
f1555e9 77f1947 Mention contact in the about page
77f1947 4adc846 Add a contact page
4adc846 365e69c Add a footer
$ git log -1 --pretty=fuller
commit f1555e9da97dd1eab3f6b8d0c96ba34f0046bcf4
Author:     Ada Lovelace <ada@example.com>
AuthorDate: Mon Jan 5 13:00:00 2026 +0000
Commit:     Ada Lovelace <ada@example.com>
CommitDate: Tue Jan 6 01:00:00 2026 +0000

    Mention contact in the about page
```

| Part of the commit | In the copy |
|---|---|
| the parent | the new base, or the previous copy |
| the commit's own name | new, because the parent and the committer date are |
| the message | the same |
| the author and author date | the same |
| the committer and committer date | you, now |

`%p` makes the mechanism visible: `Add a contact page` used to sit on
`5a60db1` and now sits on `4adc846`, which is enough to rename it, and
renaming it renames everything after it (Chapter 28).

The originals are untouched and still in the repository. `contact` still points
at `76fe3f2`; if the rebase had been done on `contact` itself, the reflog would
name them instead ([Undoing a rebase](#undoing-a-rebase)).

## Rebasing when there is nothing to do

```console
$ git rebase main
Current branch try is up to date.
```

When the branch already contains every commit in `<upstream>`, there is nothing
to copy. The message is not an error, and nothing was changed — not even the
committer dates, because no commit was made.

## How much rebase prints

```console
$ git switch -q -C try contact
$ git rebase --stat main
 LICENSE   | 1 +
 index.md  | 3 ++-
 style.css | 2 +-
 3 files changed, 4 insertions(+), 2 deletions(-)
 create mode 100644 LICENSE
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/try.
```

`--stat` prints a diffstat of what changed *upstream* since the branch forked,
before anything is replayed: it answers "what am I rebasing onto?". It is off
by default and `rebase.stat` turns it on for good. `-v` implies it, and `-n`
turns it off again.

```console
$ git switch -q -C try contact
$ git rebase -q main
$ git log --oneline -1
897d42a Mention contact in the about page
```

`-q` prints nothing at all, progress lines included, and implies `-n`. It is
what a script wants; at a terminal the progress lines are the only sign that a
long rebase is still moving.

## Choosing the new base with --onto

```console
$ git switch -q -C try contact
$ git rebase --onto main~2 main~3
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/try.
$ git log --oneline --graph -5
* 6119639 Mention contact in the about page
* 564d872 Add a contact page
* 315a24e Fix the heading and tidy the stylesheet
* 5a60db1 Add a stylesheet
* cc016fe Add an about page
```

`--onto` separates the two jobs the single-argument form does at once.
`<upstream>` decides *which* commits are copied — everything in this branch
that is not in `main~3` — and `--onto` decides *where* they go, here `main~2`
rather than the tip of `main`.

| Form | Which commits | Where they go |
|---|---|---|
| `git rebase main` | not in `main` | the tip of `main` |
| `git rebase --onto X main` | not in `main` | `X` |
| `git rebase --onto X Y` | not in `Y` | `X` |

The usual reason is a topic branch built on another topic branch: when the one
underneath is merged, `git rebase --onto main old-base` moves your commits to
`main` without dragging the other branch's commits along.

As a special case, Git's documentation allows `--onto A...B`, which means the
merge base of A and B when there is exactly one.

### Dropping commits out of the middle

```console
$ git switch -q -C try contact
$ git log --oneline -3
76fe3f2 Mention contact in the about page
f925873 Add a contact page
5a60db1 Add a stylesheet
$ git rebase --onto HEAD~2 HEAD~1
Rebasing (1/1)
Successfully rebased and updated refs/heads/try.
$ git log --oneline -3
2aafb81 Mention contact in the about page
5a60db1 Add a stylesheet
cc016fe Add an about page
```

The same two arguments with both ends inside your own branch remove commits.
`--onto HEAD~2` is where to land, `HEAD~1` is what to skip past, so the one
commit between them — `Add a contact page` — is gone and the one after it was
replayed.

That is a whole feature of an interactive rebase (`drop`, Chapter 34) done
without an editor. It is also the only way to do it in a script.

## Rebasing a branch you are not on

```console
$ git switch -q -C try contact
$ git switch -q main && git rebase main~1 spare
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/spare.
$ git status --short --branch && git log --oneline -3
## spare
ba5eee0 Mention contact in the about page
7991379 Add a contact page
365e69c Add a licence
```

A second argument names the branch to rebase, and Git checks it out first.
Git's documentation puts it as a shortcut for `git checkout <branch>` followed
by the rebase — and the checkout is not undone afterwards, which is the part
that surprises people: the command started on `main` and finished on `spare`.

## --keep-base

```console
$ git switch -q -C try contact
$ git rebase --keep-base main
Current branch try is up to date.
$ git log --oneline --graph -5
* 76fe3f2 Mention contact in the about page
* f925873 Add a contact page
* 5a60db1 Add a stylesheet
* cc016fe Add an about page
* 31c4060 Start the site
```

`--keep-base` puts the copies back on the *merge base* — where the branch
already forked — instead of the tip of `<upstream>`. Here that base has not
moved, so there is nothing to do and the branch stays where it is, three
commits behind `main`. A plain `git rebase main` would have moved it onto
`main`'s tip.

That is the point: a long-lived branch can be tidied up, or rebuilt after an
interactive rebase, without being dragged forward onto every new upstream
commit each time. Git's documentation gives the equivalent spelling,
`git rebase --reapply-cherry-picks --no-fork-point --onto <upstream>...<branch>
<upstream> <branch>`, and notes that it implies `--reapply-cherry-picks` so that
nothing is lost.

> **Since Git 2.24.** `--keep-base`.

## --fork-point

```console
$ git log --oneline --graph --all --decorate
* 147d1ef (HEAD -> work) Add four
* ab9bb68 (up) Add three
* a03ecc3 Add two
* ec613fd (main) Add one
$ git switch -q up && git reset -q --hard up~1 && git log --oneline up
a03ecc3 Add two
ec613fd Add one
$ git switch -q work && git rebase --no-fork-point up
Current branch work is up to date.
$ git log --oneline
147d1ef Add four
ab9bb68 Add three
a03ecc3 Add two
ec613fd Add one
$ git reset -q --hard 147d1ef && git rebase --fork-point up
Rebasing (1/1)
Successfully rebased and updated refs/heads/work.
$ git log --oneline
f29d05e Add four
a03ecc3 Add two
ec613fd Add one
```

This runs in a separate small repository, because it needs an upstream that has
been rewound. `work` forked from `up` when `up` had three commits; then `up`
was reset back by one, abandoning `Add three`.

With `--no-fork-point`, `<upstream>` is taken literally: `up` is an ancestor of
`work`, so there is nothing to copy and `Add three` stays on the branch.

With `--fork-point`, Git reads `up`'s reflog, sees that `work` forked at
`Add three`, and treats *that* as the base — so only `Add four` is copied, and
`Add three` is dropped as something the upstream no longer wants.

| When | The default is |
|---|---|
| `git rebase` with no `<upstream>` | `--fork-point` |
| `git rebase <upstream>` | `--no-fork-point` |
| `git rebase --keep-base ...` | `--no-fork-point` |

`rebase.forkpoint` changes the default. This is the usual explanation for "my
rebase dropped a commit I did not ask it to": the upstream had been rewound, and
Git believed the reflog.

## Commits that are already upstream

```console
$ git switch -q -C try licence
$ git log --oneline -3
d6287db Add humans.txt
cfb9c37 Add a licence
5a60db1 Add a stylesheet
$ git rebase main
warning: skipped previously applied commit cfb9c37
hint: use --reapply-cherry-picks to include skipped commits
hint: Disable this message with "git config set advice.skippedCherryPicks false"
Rebasing (1/1)
Successfully rebased and updated refs/heads/try.
$ git log --oneline -4
8de1f88 Add humans.txt
4adc846 Add a footer
365e69c Add a licence
315a24e Fix the heading and tidy the stylesheet
```

`licence` holds a copy of `main`'s `Add a licence`, made with a cherry-pick.
Before replaying anything, rebase compares every commit it is about to copy
with every commit in the upstream by *patch id* — a hash of the change that
ignores line numbers and the commit's own name — and drops the ones that are
already there. Only `Add humans.txt` was replayed, and the result has one
`Add a licence` rather than two.

It is safe because the change really is upstream. The cost is that Git has to
read every upstream commit to do the comparison, which in a repository with a
long history is the slow part of a rebase.

### Reapplying them anyway

```console
$ git switch -q -C try licence
$ git rebase --reapply-cherry-picks main
Rebasing (1/2)
dropping cfb9c3707585e20988ebfcd62829ceb6bca3712a Add a licence -- patch contents already upstream
Rebasing (2/2)
Successfully rebased and updated refs/heads/try.
$ git log --oneline -4
b576cdc Add humans.txt
4adc846 Add a footer
365e69c Add a licence
315a24e Fix the heading and tidy the stylesheet
```

`--reapply-cherry-picks` turns the preliminary comparison off, so the commit is
replayed instead of skipped — and then, because its change is already in the
tree, it comes out empty and is dropped anyway, with a different message:
`dropping ... -- patch contents already upstream`.

Two different mechanisms, two different messages, and it is worth telling them
apart:

| Message | Means |
|---|---|
| `warning: skipped previously applied commit <hash>` | dropped before replaying, by patch id |
| `dropping <hash> ... -- patch contents already upstream` | replayed, came out empty, dropped by `--empty=drop` |

The reason to use `--reapply-cherry-picks` is speed: it lets rebase skip
reading the upstream commits. `--keep-base` implies it for a different reason —
the base is not moving, so nothing can be already upstream that was not already
upstream before.

## Commits that become empty

```console
$ git switch -q -C try heading
$ git log --oneline -2 && git show --stat --oneline HEAD
086db5d Fix the heading
5a60db1 Add a stylesheet
086db5d Fix the heading
 index.md | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git rebase main
Rebasing (1/1)
dropping 086db5da033d2e4e6fb361f740e85757d605609c Fix the heading -- patch contents already upstream
Successfully rebased and updated refs/heads/try.
$ git log --oneline -3
4adc846 Add a footer
365e69c Add a licence
315a24e Fix the heading and tidy the stylesheet
```

`heading` fixes the same typo that `main`'s `Fix the heading and tidy the
stylesheet` fixes, but does not touch the stylesheet — so it is not a copy of
that commit and the patch-id check does not catch it. It is replayed, the
change turns out to be there already, and the result is empty. The default,
`--empty=drop`, throws it away.

`--empty=drop` is the default, so it is rarely typed; spelling it out does the
same thing:

```console
$ git switch -q -C try heading
$ git rebase --empty=drop main
Rebasing (1/1)
dropping 086db5da033d2e4e6fb361f740e85757d605609c Fix the heading -- patch contents already upstream
Successfully rebased and updated refs/heads/try.
$ git log --oneline -2
4adc846 Add a footer
365e69c Add a licence
```

### Keeping them

```console
$ git switch -q -C try heading
$ git rebase --empty=keep main
Rebasing (1/1)
Successfully rebased and updated refs/heads/try.
$ git log --oneline -3 && git show --stat --oneline HEAD
8476472 Fix the heading
4adc846 Add a footer
365e69c Add a licence
8476472 Fix the heading
```

`--empty=keep` commits it anyway. `git show --stat` prints the subject and no
file list, because there are no files in it.

### Stopping to ask

```console
$ git switch -q -C try heading
$ git rebase --empty=stop main
Rebasing (1/1)
The previous cherry-pick is now empty, possibly due to conflict resolution.
If you wish to commit it anyway, use:

    git commit --allow-empty

Otherwise, please use 'git rebase --skip'
interactive rebase in progress; onto 4adc846
Last command done (1 command done):
   pick 086db5d # Fix the heading
No commands remaining.
You are currently rebasing branch 'try' on '4adc846'.
  (all conflicts fixed: run "git rebase --continue")

nothing to commit, working tree clean
Could not apply 086db5d... # Fix the heading
$ git status | head -6
interactive rebase in progress; onto 4adc846
Last command done (1 command done):
   pick 086db5d # Fix the heading
No commands remaining.
You are currently rebasing branch 'try' on '4adc846'.
  (all conflicts fixed: run "git rebase --continue")
$ git rebase --skip
Successfully rebased and updated refs/heads/try.
$ git log --oneline -2
4adc846 Add a footer
365e69c Add a licence
```

`--empty=stop` halts and lets you decide: `git commit --allow-empty` then
`git rebase --continue` to keep it, or `git rebase --skip` to drop it.

Two things in that output are worth knowing. `git status` says *interactive*
rebase in progress even though no `-i` was given: the merge backend uses the
same machinery either way, and a todo list exists whether or not you were shown
it (Chapter 34). And `--empty=stop` is the default when `-i` is given, since
someone editing a todo list is already deciding what happens to each commit.

| Value | What happens to a commit that becomes empty |
|---|---|
| `--empty=drop` | dropped, with a `dropping ...` line; the default |
| `--empty=keep` | committed with no changes in it |
| `--empty=stop` | the rebase halts and asks; the default with `-i` |

### A commit that was empty to start with

```console
$ git switch -q -C try contact
$ git commit -q --allow-empty -m 'A marker commit' && git log --oneline -3
cdc5d5d A marker commit
76fe3f2 Mention contact in the about page
f925873 Add a contact page
$ git rebase main
Rebasing (1/3)
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/try.
$ git log --oneline -4
fd9868f A marker commit
c79e14a Mention contact in the about page
70c059a Add a contact page
4adc846 Add a footer
$ git switch -q -C try contact
$ git commit -q --allow-empty -m 'A marker commit'
$ git rebase --no-keep-empty main
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/try.
$ git log --oneline -4
2040cce Mention contact in the about page
0879451 Add a contact page
4adc846 Add a footer
365e69c Add a licence
```

A commit that was empty when it was made is kept by default, and `--empty` has
nothing to say about it. The reasoning in Git's documentation: making one
requires `git commit --allow-empty`, so it was deliberate. `--no-keep-empty`
drops them, which is a convenience for cleaning up after a tool that generated
a lot of them.

`--allow-empty-message` is listed for compatibility and does nothing: a commit
with an empty message no longer stops a rebase.

## Fast-forwarding

```console
$ git switch -q -C try contact
$ git switch -q -C try main~1 && git rebase main
Successfully rebased and updated refs/heads/try.
$ git log --oneline -2
4adc846 Add a footer
365e69c Add a licence
$ git switch -q -C try main~1 && git rebase --no-ff main
Rebasing (1/1)
Successfully rebased and updated refs/heads/try.
$ git log --format='%h %p %s' -3
4adc846 365e69c Add a footer
365e69c 315a24e Add a licence
315a24e 5a60db1 Fix the heading and tidy the stylesheet
```

When the branch is simply behind, there is nothing to copy: rebase moves it
forward and says so, with no `Rebasing (n/m)` lines at all. More generally, a
commit that would come out identical is kept as it is rather than rebuilt, so
some hashes survive a rebase.

`--no-ff`, also spelled `-f` and `--force-rebase`, replays everything
regardless, so every commit in the result is new. Git's documentation gives the
reason to want that: after reverting a merge of a topic branch, replaying the
branch with fresh commits lets it be merged again without reverting the
revert (Chapter 31).

Here `--no-ff` still printed `Rebasing (1/1)` and produced `4adc846` — the same
hash — because nothing about the commit changed, not even its committer date,
which the sandbox pins.

## When a rebase stops

```console
$ git switch -q -C try footer
$ git rebase main
Rebasing (1/1)
Auto-merging index.md
CONFLICT (content): Merge conflict in index.md
error: could not apply 1c314ba... Add our own footer
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
Could not apply 1c314ba... # Add our own footer
$ git status --short --branch
## HEAD (no branch)
UU index.md
$ git status | head -10
interactive rebase in progress; onto 4adc846
Last command done (1 command done):
   pick 1c314ba # Add our own footer
No commands remaining.
You are currently rebasing branch 'try' on '4adc846'.
  (fix conflicts and then run "git rebase --continue")
  (use "git rebase --skip" to skip this patch)
  (use "git rebase --abort" to check out the original branch)

Unmerged paths:
$ cat index.md
# My site
Welcome.
<<<<<<< HEAD
Footer: 2026
=======
Built by hand.
>>>>>>> 1c314ba (Add our own footer)
$ git log --oneline -1 REBASE_HEAD
1c314ba Add our own footer
$ git rebase --show-current-patch | head -12
commit 1c314ba8a334e81cdea0e7aaec177c454c09f20c
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 15:00:00 2026 +0000

    Add our own footer

diff --git a/index.md b/index.md
index 477f9e4..5340af3 100644
--- a/index.md
+++ b/index.md
@@ -1,2 +1,3 @@
 # My sight
```

`## HEAD (no branch)` is the shape of the whole thing: during a rebase you are
on a detached `HEAD` at the new base, with your commits being applied one at a
time. The branch is not moved until the end.

**Ours and theirs are the other way round.** `HEAD` in the conflict markers is
`Footer: 2026`, which came from `main` — the branch being rebased *onto* — and
the incoming side is your own commit. Git's documentation states it plainly:
because each commit of the working branch is replayed on top of the upstream,
`ours` is the so-far-rebased series and `theirs` is your work. Every `--ours`
and `--theirs` during a rebase means the opposite of what it means during a
merge (Chapter 26).

`REBASE_HEAD` names the commit that could not be applied, and
`git rebase --show-current-patch` shows it in full — Git's documentation says
the option is the equivalent of `git show REBASE_HEAD`.

### Finishing it

```console
$ git add index.md && GIT_EDITOR=true git rebase --continue
[detached HEAD e2df1c5] Add our own footer
 1 file changed, 1 insertion(+)
Successfully rebased and updated refs/heads/try.
$ git log --oneline -3 && cat index.md
e2df1c5 Add our own footer
4adc846 Add a footer
365e69c Add a licence
# My site
Welcome.
Footer: 2026
Built by hand.
```

Resolve the file, `git add` it, `git rebase --continue`.

`--continue` opens an editor on the commit message, which is the merge
backend's deliberate behaviour: resolving a conflict may change what the commit
does, so the message gets a chance to change with it. `GIT_EDITOR=true` stands
in for accepting it unchanged — `true` exits successfully without touching the
file. The apply backend does not ask.

The commit is made on the detached `HEAD` — `[detached HEAD e2df1c5]` — and the
branch catches up when the rebase finishes.

### Abandoning it

```console
$ git switch -q -C try footer
$ git rebase main
Rebasing (1/1)
Auto-merging index.md
CONFLICT (content): Merge conflict in index.md
error: could not apply 1c314ba... Add our own footer
...
$ git rebase --abort && git status --short && git log --oneline -1
1c314ba Add our own footer
$ git rebase main
Rebasing (1/1)
Auto-merging index.md
CONFLICT (content): Merge conflict in index.md
error: could not apply 1c314ba... Add our own footer
...
$ git rebase --skip
Successfully rebased and updated refs/heads/try.
$ git log --oneline -2
4adc846 Add a footer
365e69c Add a licence
```

`--abort` puts the branch back where it was and restores the files: after it,
`try` is at `1c314ba` again, its own commit, and `git status` is clean.

`--skip` drops the commit that conflicted and carries on. Here it was the only
commit, so the branch ends up at `main` with the work gone — which is worth
noticing before typing it.

```console
$ git switch -q -C try footer
$ git rebase main
Rebasing (1/1)
Auto-merging index.md
CONFLICT (content): Merge conflict in index.md
error: could not apply 1c314ba... Add our own footer
...
$ git rebase --quit && git status --short && git log --oneline -1
UU index.md
4adc846 Add a footer
```

`--quit` forgets the rebase and changes nothing else: the conflicted file stays
conflicted, and `HEAD` stays detached where the rebase stopped. It is the way
out when the rebase has become the wrong tool and you want the half-finished
state as ordinary changes.

| Command | The files | The branch | `HEAD` |
|---|---|---|---|
| `--continue` | committed, and the rebase goes on | moves at the end | reattached at the end |
| `--skip` | this commit dropped, and the rebase goes on | moves at the end | reattached at the end |
| `--abort` | back as they were | back as it was | reattached |
| `--quit` | left exactly as they are | not moved | left detached |

## Rebasing with uncommitted changes

```console
$ git switch -q -C try contact
$ git rebase main
error: cannot rebase: You have unstaged changes.
error: Please commit or stash them.
$ git rebase --autostash main
Created autostash: dc24047
Rebasing (1/2)
Rebasing (2/2)
Applied autostash.
Successfully rebased and updated refs/heads/try.
$ git status --short && git log --oneline -3
 M about.md
bc68e06 Mention contact in the about page
7d6a03c Add a contact page
4adc846 Add a footer
```

A rebase checks out another commit, so it refuses to start with uncommitted
changes in the way. `--autostash` stashes them, rebases, and puts them back —
the two extra lines in the output are it doing so.

The catch is in Git's own warning: the stash is applied *after* the rebase, so
it can conflict with the result, and then you have a conflict to resolve with no
rebase in progress to abort. `rebase.autoStash` makes it the default.

## Moving the other branches too

```console
$ git switch -q -C try stack-b
$ git log --oneline --decorate -3
2ffdc25 (HEAD -> try, stack-b) Add a sitemap
f7fd1a5 (stack-a) Add robots.txt
5a60db1 Add a stylesheet
$ git rebase main
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/try.
$ git log --oneline --decorate -4
f184fac (HEAD -> try) Add a sitemap
1757770 Add robots.txt
4adc846 (main) Add a footer
365e69c Add a licence
$ git switch -q -C try stack-b
$ git rebase --update-refs main
Rebasing (1/4)
Rebasing (2/4)
Rebasing (3/4)
Rebasing (4/4)
Successfully rebased and updated refs/heads/try.
Updated the following refs with --update-refs:
	refs/heads/stack-a
	refs/heads/stack-b
$ git log --oneline --decorate -4
793e50a (HEAD -> try, stack-b) Add a sitemap
175953f (stack-a) Add robots.txt
4adc846 (main) Add a footer
365e69c Add a licence
```

`stack-a` and `stack-b` are stacked: `stack-b` builds on `stack-a`. A plain
rebase copies both commits and moves only the branch being rebased, leaving
`stack-a` pointing at the original — which is how a stack of branches falls
apart one rebase at a time.

`--update-refs` moves every branch that pointed into the range, and says which.
The progress count goes from 2 to 4 because the todo list now has an
`update-ref` instruction after each commit as well (Chapter 34).

Branches checked out in another worktree are left alone (Chapter 56).
`rebase.updateRefs` makes it the default.

> **Since Git 2.38.** `--update-refs` and `rebase.updateRefs`.

## Rebasing from the root

```console
$ git switch -q -C try contact
$ git log --oneline newbase
31210fd Start a new history
$ git rebase --onto newbase --root
Rebasing (1/5)
Rebasing (2/5)
Rebasing (3/5)
Rebasing (4/5)
Rebasing (5/5)
Successfully rebased and updated refs/heads/try.
$ git log --oneline --graph -6
* 9721d88 Mention contact in the about page
* 4376f46 Add a contact page
* a16b7da Add a stylesheet
* ab4ab2c Add an about page
* a14055b Start the site
* 31210fd Start a new history
```

Without `--root`, the earliest commit a rebase can copy is the one after
`<upstream>`; the branch's own first commit has no parent to rebase from.
`--root` includes it, so every commit reachable from the branch is replayed —
five here rather than two.

`newbase` is an unrelated branch made with `git switch --orphan`
(Chapter 24). With `--onto`, `--root` grafts a whole history onto another one;
without `--onto` it is mostly used with `-i` to edit or reword the very first
commit (Chapter 34).

## The two backends

```console
$ git switch -q -C try contact
$ git rebase --apply main
First, rewinding head to replay your work on top of it...
Applying: Add a contact page
Applying: Mention contact in the about page
$ git log --oneline -3
fda7392 Mention contact in the about page
b95820a Add a contact page
4adc846 Add a footer
```

Git has two machines for replaying commits. The default is the *merge* backend,
which three-way merges each commit and prints `Rebasing (n/m)`. `--apply` uses
the older *apply* backend, which turns each commit into a patch with
`git format-patch` and applies it with `git am`, printing `Applying: <subject>`.

```console
$ git switch -q -C try footer
$ git rebase --apply main
First, rewinding head to replay your work on top of it...
Applying: Add our own footer
Using index info to reconstruct a base tree...
M	index.md
Falling back to patching base and 3-way merge...
Auto-merging index.md
CONFLICT (content): Merge conflict in index.md
error: Failed to merge in the changes.
hint: Use 'git am --show-current-patch=diff' to see the failed patch
...
$ cat index.md
# My site
Welcome.
<<<<<<< HEAD
Footer: 2026
=======
Built by hand.
>>>>>>> Add our own footer
$ git rebase --abort
```

The same conflict as before, with two differences that show what the backend
costs. The hint names `git am`, because that is what is running. And the label
on the incoming side is `Add our own footer` — a subject, not
`1c314ba (Add our own footer)` — because the apply backend has thrown away the
commits and works only from patches, so it has no hash to name.

Git's documentation lists the other differences: the apply backend drops empty
commits with no way to control it, cannot detect directory renames, can apply a
change in the wrong place when several parts of a file have the same context,
has no `--update-refs` or `--empty`, cannot be interrupted safely, and does not
open an editor after a conflict. It exists for what `--whitespace` and `-C` do,
and Git's documentation says it may become a no-op once the merge backend
covers everything.

## Whitespace and context

```console
$ git switch -q -C try contact
$ git commit -q -am 'Add trailing space' && git rebase --ignore-whitespace main
Rebasing (1/3)
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/try.
$ git log --oneline -4
ce479b2 Add trailing space
e300ad5 Mention contact in the about page
7d95e43 Add a contact page
4adc846 Add a footer
$ git switch -q -C try contact
$ git rebase --whitespace=fix main
First, rewinding head to replay your work on top of it...
Applying: Add a contact page
Applying: Mention contact in the about page
$ git log --oneline -3
3328b85 Mention contact in the about page
a73c43f Add a contact page
4adc846 Add a footer
$ git switch -q -C try contact
$ git rebase -C1 main
First, rewinding head to replay your work on top of it...
Applying: Add a contact page
Applying: Mention contact in the about page
$ git log --oneline -3
c9dc28b Mention contact in the about page
755e669 Add a contact page
4adc846 Add a footer
```

`--ignore-whitespace` makes both backends treat lines that differ only in
whitespace as unchanged, which avoids a conflict when someone has reindented
the file you are rebasing onto. Git's documentation warns about the other side
of that: a commit whose whole point is a whitespace change can be dropped.

`--whitespace=<action>` passes an action such as `fix` or `error` through to
`git apply` (Chapter 61), and `-C<n>` demands at least `<n>` lines of matching
context around each change. Both are patch-application ideas, so both imply
`--apply` — which is visible in the output above: the moment either appears,
the messages change from `Rebasing (n/m)` to `Applying:`.

## Dates, authorship and trailers

```console
$ git switch -q -C try contact
$ git rebase main
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/try.
$ git log -1 --format='%ad | %cd'
Mon Jan 5 13:00:00 2026 +0000 | Thu Jan 8 00:00:00 2026 +0000
$ git switch -q -C try contact
$ git rebase --committer-date-is-author-date main
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/try.
$ git log -1 --format='%ad | %cd'
Mon Jan 5 13:00:00 2026 +0000 | Mon Jan 5 13:00:00 2026 +0000
```

A rebase keeps the author date and sets the committer date to now, so a rebased
branch looks like old work committed today. `--committer-date-is-author-date`
copies the author date across instead, and the two agree again.

Git's documentation attaches a warning: history traversal assumes commit
timestamps do not go backwards, so this should only be used when the new base is
older than the commits being replayed.

`--reset-author-date`, also spelled `--ignore-date`, does the opposite: it sets
the *author* date to now, so the copies look freshly written. Both imply
`--force-rebase`.

```console
$ git switch -q -C try contact
$ git rebase --signoff main
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/try.
$ git log -1 --format=%B
Mention contact in the about page

Signed-off-by: Ada Lovelace <ada@example.com>

$ git switch -q -C try contact
$ git rebase --trailer 'Reviewed-by: Sam Chen <sam@example.com>' main
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/try.
$ git log -1 --format=%B
Mention contact in the about page

Reviewed-by: Sam Chen <sam@example.com>
```

`--signoff` adds a `Signed-off-by` trailer to every commit it replays, and
`--trailer` adds any trailer you like, through `git interpret-trailers`
(Chapter 53). With `-i`, only commits marked `pick`, `edit` or `reword` get
them.

> **Since Git 2.54.** `git rebase --trailer`.

## Strategies

```console
$ git switch -q -C try footer
$ git rebase -Xtheirs main
Rebasing (1/1)
Successfully rebased and updated refs/heads/try.
$ git log --oneline -2 && cat index.md
e05f23b Add our own footer
4adc846 Add a footer
# My site
Welcome.
Built by hand.
```

`-X` passes an option to the merge strategy (Chapter 27). Remember that the
sides are swapped: `-Xtheirs` here means *your own* commit wins, which is why
`Footer: 2026` — `main`'s line — is gone from the result.

```console
$ git switch -q -C try contact
$ git rebase --strategy=resolve main
Rebasing (1/2)
Trying simple merge.
Rebasing (2/2)
Trying simple merge.
Successfully rebased and updated refs/heads/try.
$ git log --oneline -3
134c2b2 Mention contact in the about page
9313e6e Add a contact page
4adc846 Add a footer
```

`-s` or `--strategy` chooses the strategy itself and implies `--merge`. `ort`
is the default; `resolve` announces each step with `Trying simple merge.`

Git's documentation points out one that makes no sense here: `-s ours` empties
every commit being replayed, because each one is resolved in favour of what is
already there. The result is a branch that has thrown away all its own work.

## The pre-rebase hook

```console
$ git switch -q -C try contact
$ git rebase main
pre-rebase: upstream=main branch=HEAD
error: The pre-rebase hook refused to rebase.
$ git rebase --no-verify main
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/try.
$ git log --oneline -1
482fbc3 Mention contact in the about page
```

`pre-rebase` runs before anything else and can stop the rebase by exiting
non-zero. It is given the upstream and, when one was named, the branch — the
example hook prints both. The sample hook Git ships refuses to rebase a branch
that has already been merged into `next`, which is the intended use: stopping
people from rewriting what has been published.

`--no-verify` skips it, `--verify` is the default. Chapter 67 covers hooks.

## Options that cannot be combined

```console
$ git switch -q -C try contact
$ git rebase --apply --update-refs main
fatal: --update-refs requires the merge backend
$ git rebase --keep-base --onto main~1 main
fatal: options '--keep-base' and '--onto' cannot be used together
$ git rebase --fork-point --root
fatal: options '--root' and '--fork-point' cannot be used together
```

Most of the incompatibilities come from the two backends. Git's documentation
lists them: `--apply`, `--whitespace` and `-C` cannot be used with `--merge`,
`--strategy`, `--strategy-option`, `--autosquash`, `--rebase-merges`,
`--interactive`, `--exec`, `--no-keep-empty`, `--empty=`, `--update-refs`,
`--trailer`, `--root` without `--onto`, or `--reapply-cherry-picks` without
`--keep-base`.

And three pairs that are simply contradictory: `--keep-base` with `--onto`,
`--keep-base` with `--root`, `--fork-point` with `--root`.

The first message is the useful one to recognise: an option that says it
*requires the merge backend* means something else on the command line has
quietly selected the apply backend, usually `--whitespace` or `-C`.

## Undoing a rebase

```console
$ git switch -q -C try contact
$ git rebase main
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/try.
$ git log --oneline -1 && git log --oneline -1 ORIG_HEAD
65963f8 Mention contact in the about page
76fe3f2 Mention contact in the about page
$ git reset --hard ORIG_HEAD && git log --oneline -2
HEAD is now at 76fe3f2 Mention contact in the about page
76fe3f2 Mention contact in the about page
f925873 Add a contact page
$ git reflog show try -4
76fe3f2 try@{0}: reset: moving to ORIG_HEAD
65963f8 try@{1}: rebase (finish): refs/heads/try onto 4adc846df794bd15995728b7b6edd58bb18abb8f
76fe3f2 try@{2}: branch: Reset to contact
482fbc3 try@{3}: rebase (finish): refs/heads/try onto 4adc846df794bd15995728b7b6edd58bb18abb8f
```

A rebase sets `ORIG_HEAD` to the tip of the branch before it starts, so
`git reset --hard ORIG_HEAD` undoes it (Chapter 30).

Git's documentation adds a caution: `ORIG_HEAD` is not guaranteed to survive
the rebase, because anything run during it — a `git reset` while resolving a
conflict, say — overwrites it. The reflog is the reliable answer. The entry
marked `rebase (finish)` is where the branch landed, and the one below it is
where it started.

## When the upstream was rebased under you

```console
$ git log --oneline --graph --all --decorate
* b2e8ffb (subsystem) Add the subsystem
| * 6d2951a (HEAD -> topic) Add the topic
| * 595e758 Add the subsystem
|/  
* 433fdcd (main) Start the notes
$ git rebase subsystem
Rebasing (1/2)
Auto-merging subsystem.md
CONFLICT (add/add): Merge conflict in subsystem.md
error: could not apply 595e758... Add the subsystem
...
$ git rebase --abort
$ git rebase --onto subsystem 595e758
Rebasing (1/1)
Successfully rebased and updated refs/heads/topic.
$ git log --oneline --graph --all --decorate
* a5b3d13 (HEAD -> topic) Add the topic
* b2e8ffb (subsystem) Add the subsystem
* 433fdcd (main) Start the notes
```

In this separate repository, `topic` was built on `subsystem`, and then
`subsystem` was amended — the same commit with different content. `topic` still
carries the *old* version of it.

A plain `git rebase subsystem` tries to replay both of `topic`'s commits,
including the old copy of `Add the subsystem`, and that copy conflicts with the
new one. Git's documentation calls this the hard case: it happens whenever the
rewrite changed content rather than just moving commits, which covers amending,
squashing, dropping and resolving a conflict differently.

The answer is to tell Git where your own work starts: `--onto subsystem
595e758` replays only what comes after the old upstream tip. Chapter 28 shows
the easy case, where the changes are identical and a plain rebase skips them by
patch id, and how to tell which case you are in.

## rebase and its neighbours

| Command | Result | Chapter |
|---|---|---|
| `git rebase` | your commits copied onto a new base; the branch is a straight line | this chapter |
| `git merge` | one commit joining the two histories; nothing is copied | Chapter 25 |
| `git cherry-pick` | chosen commits copied, both branches left where they were | Chapter 32 |
| `git revert` | a new commit undoing an old one | Chapter 31 |
| `git replay` | the same copying as a rebase, with no working tree involved | [git replay](#git-replay) |
| `git history` | one commit in the middle replaced, without a todo list | Chapter 35 |

**Rebase or merge?** A merge records what happened: two lines of work, joined
on a date, with both sets of commits intact. A rebase records what you wish had
happened: one line, as if the work had been done last. Merging is safe on any
branch; rebasing rewrites, so the whole of Chapter 28 applies. Most teams settle
on rebasing private branches to tidy them and merging them in.

**Is rebasing just cherry-picking every commit?** Effectively yes, and the
merge backend is built on the same machinery — which is why the conflicts look
identical and why `git status` during a rebase talks about cherry-picks. The
differences are that rebase works out the list for you, moves the branch at the
end, and can drop commits that are already upstream.

### git replay

```console
$ git -C /home/ada/bare.git log --oneline --all --decorate
a5b3d13 (topic) Add the topic
b2e8ffb (subsystem) Add the subsystem
433fdcd Start the notes
$ git -C /home/ada/bare.git replay --ref-action=print --onto subsystem subsystem..topic
update refs/heads/topic b30d9f1280680b9b264efce00ba84802cb782cb9 a5b3d13d9fc7d9651577ff488cacd173bc282380
$ git -C /home/ada/bare.git replay --onto subsystem subsystem..topic
$ git -C /home/ada/bare.git log --oneline --all --decorate
b30d9f1 (topic) Add the topic
b2e8ffb (subsystem) Add the subsystem
433fdcd Start the notes
```

`git replay` does a rebase's copying without a working tree or an index, which
means it runs in a bare repository — the one place `git rebase` cannot go.
`--ref-action=print` prints the ref updates it would make, in the format
`git update-ref --stdin` reads (Chapter 74), instead of making them; the default
updates every ref in one transaction.

It has `--onto` as rebase does, `--advance <branch>` to move a branch forward
instead, and since Git 2.55 `--revert <branch>` to apply a range backwards. It
stops on a conflict rather than asking, because there is no working tree to
resolve one in.

> **Since Git 2.54.** `git replay`. It is marked EXPERIMENTAL in its own
> documentation, so its interface may change; it exists for servers and
> automation, not for everyday use.

## The settings

| Setting | Does |
|---|---|
| `rebase.stat` | Show the diffstat of what changed upstream, as `--stat` does |
| `rebase.autoStash` | Stash uncommitted changes and restore them, as `--autostash` does |
| `rebase.updateRefs` | Move stacked branches, as `--update-refs` does |
| `rebase.forkpoint` | Set to false to make `--no-fork-point` the default |
| `rebase.backend` | Which backend to use when neither is asked for |
| `rebase.missingCommitsCheck` | Warn or fail when the todo list loses commits (Chapter 34) |
| `rebase.instructionFormat` | How commits are shown in the todo list (Chapter 34) |
| `rebase.autoSquash` | Fold `fixup!` commits in by default (Chapter 35) |
| `advice.skippedCherryPicks` | Whether the "skipped previously applied commit" warning is printed |
| `merge.conflictStyle` | How a conflict from a rebase is written into the file (Chapter 26) |
| `rerere.enabled` | Whether Git replays a resolution it has seen before (Chapter 26) |
