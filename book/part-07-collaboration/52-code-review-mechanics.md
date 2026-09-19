# Chapter 52. Code Review Mechanics

## What it is

*Code review* is someone other than the author reading a change before it is
merged: to find mistakes, to ask why, and finally to agree that it can go in.
Git has no review command and keeps no review comments. The comments live on a
hosting service's page (Chapters 50 and 51), in replies to patches sent by mail
(Chapter 61), or on a review server such as Gerrit. What Git has is a tool for
every step around them: fetching the change, reading it as a whole and commit by
commit, trying it without disturbing your own work, testing every commit,
handing a fix back as a commit, and, when the author sends a new version,
seeing exactly what changed. That last one is `git range-diff`, which this
chapter covers in full; Chapters 35 and 45 used it without its options.

The chapter follows one change through two rounds of review, from both sides.
Where it describes how a project reviews, it quotes Git's own project, from
three guides installed with Git's documentation: `ReviewingGuidelines`,
`SubmittingPatches` and `MyFirstContribution`. The one question it answers is:
*how do I review a change with Git, and how do I answer a review of mine?*

| Term | Means |
|---|---|
| *author* | whoever wrote the change under review |
| *reviewer* | whoever reads it and comments |
| *series*, *patch series* | the commits of one change, in order, reviewed together |
| *version*, *round*, *iteration* | the series as first sent, v1, and each time it is sent again after review, v2, v3 |
| *reroll* | sending a new version |
| *interdiff* | a diff between the files at the tips of two versions |
| *range-diff* | a comparison of two versions commit by commit, made by `git range-diff` |
| *cover letter* | the message that introduces a series sent by mail, before its patches |
| *patch set* | Gerrit's name for one version of a change |

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What does Git itself do for code review, and what does it leave to GitHub or GitLab?](#what-it-is)

**[The review at a glance](#the-review-at-a-glance)**

- [What are the steps of a review, and which Git command goes with each?](#the-review-at-a-glance)

**[The example repository](#the-example-repository)**

- [What project and people do the examples use?](#the-example-repository)

**[Asking for a review](#asking-for-a-review)**

- [Who should I ask to review my change?](#asking-for-a-review)
- [What should I check myself before I ask?](#asking-for-a-review)

**[What is under review](#what-is-under-review)**

- [Someone asked me to review their branch. How do I see which commits and files it changes?](#what-is-under-review)

**[Reading the change](#reading-the-change)**

- [Should I read the whole diff at once, or each commit on its own?](#all-at-once-or-one-commit-at-a-time)
- [The whole diff looks fine. Can a problem still hide in the commits?](#all-at-once-or-one-commit-at-a-time)
- [The diff is hard to read because code moved or was re-indented. What helps?](#views-that-make-a-change-easier-to-read)
- [The branch has a merge commit in it. How do I see what the author did in that merge?](#views-that-make-a-change-easier-to-read)

**[Trying it without disturbing your work](#trying-it-without-disturbing-your-work)**

- [I'm in the middle of my own work. How do I try someone's branch without stashing or committing?](#trying-it-without-disturbing-your-work)

**[Checking the change](#checking-the-change)**

- [How do I check a branch for whitespace errors?](#whitespace-errors)
- [How do I check that every commit passes the tests, not just the last one?](#every-commit-not-only-the-last)
- [Why use `--keep-base` when testing each commit?](#every-commit-not-only-the-last)
- [Why does the progress count start at 2?](#every-commit-not-only-the-last)
- [How do I find out whether the branch still merges cleanly?](#whether-it-still-merges)

**[Leaving a review](#leaving-a-review)**

- [Where do review comments go, when Git has no place for them?](#leaving-a-review)
- [What do "nit", "non-blocking" and "s/foo/bar/" mean in a review?](#words-reviewers-use)
- [Can I hand the author a fix as a commit instead of describing it?](#suggesting-a-change-as-a-commit)
- [How do I get rid of the second working tree afterwards?](#suggesting-a-change-as-a-commit)

**[Responding to a review](#responding-to-a-review)**

- [Before I change my branch, how do I keep the version that was reviewed?](#keeping-the-version-that-was-reviewed)
- [Should I fix my commits or add new ones on top?](#a-new-version-or-new-commits)
- [The reviewer's fixup was folded into my commit. Whose name is on it now?](#a-new-version-or-new-commits)
- [How do I tell the reviewer what changed since the last version?](#telling-the-reviewer-what-changed)
- [How do I put a range-diff in the cover letter of a series I send by mail?](#telling-the-reviewer-what-changed)

**[Comparing two versions with range-diff](#comparing-two-versions-with-range-diff)**

- [The author pushed a new version. Why doesn't `git diff` between the two show what changed?](#comparing-two-versions-with-range-diff)
- [What are the ways to name the two versions?](#the-three-forms)
- [Can I compare just one commit from each version?](#the-three-forms)
- [Which options does `git range-diff` take?](#options-at-a-glance)
- [How do I read the lines and the indented diff that `git range-diff` prints?](#reading-the-output)
- [The author reordered the commits. What does that look like?](#reading-the-output)
- [Why did `git range-diff` list a commit from `main` as new?](#choosing-the-base)
- [Can I see only the commits of one version?](#choosing-the-base)
- [One commit shows up as removed and again as added. How do I make range-diff pair them?](#when-a-commit-is-shown-as-removed-and-added)
- [Can I compare only the commits that touch one file?](#only-some-files)
- [What do the colours mean?](#colour)
- [Why does range-diff show my notes, and how do I hide them?](#notes)
- [The new version merged `main` instead of rebasing. Why does range-diff say nothing changed?](#merges)
- [How do I get longer hashes, less context, or just the summary lines?](#output-options)
- [`git range-diff` stopped with "exceeds the maximum memory". What now?](#output-options)

**[Approving](#approving)**

- [Before approving, how do I test the new version without changing it?](#approving)
- [How do I say a change is ready, and how does that end up in Git?](#approving)

**[Three ways projects review](#three-ways-projects-review)**

- [How is review different on GitHub, by mail and on Gerrit?](#three-ways-projects-review)
- [What are Gerrit's `Change-Id` and patch sets?](#on-gerrit)

**[range-diff and its neighbours](#range-diff-and-its-neighbours)**

- [What is the difference between `git range-diff`, `git diff`, `--cherry-mark` and `git patch-id`?](#range-diff-and-its-neighbours)

**[Undoing](#undoing)**

- [I rewrote my branch after a review and want the old version back. How?](#undoing)

**[The settings](#the-settings)**

- [Which settings help with reviewing?](#the-settings)

</details>

## The review at a glance

| Step | Who | In Git | Section |
|---|---|---|---|
| choose reviewers, check your own change | author | `git shortlog -s -n -- <path>`, `git diff --check` | [Asking for a review](#asking-for-a-review) |
| fetch the change and list it | reviewer | `git fetch`, `git log main..<branch>`, `git diff --stat main...<branch>` | [What is under review](#what-is-under-review) |
| read it, whole and commit by commit | reviewer | `git diff main...<branch>`, `git log -p --reverse main..<branch>` | [Reading the change](#reading-the-change) |
| try it | reviewer | `git worktree add --detach <dir> <branch>` | [Trying it without disturbing your work](#trying-it-without-disturbing-your-work) |
| check it | reviewer | `git diff --check`, `git rebase -x <test> --keep-base main` | [Checking the change](#checking-the-change) |
| comment | reviewer | nothing: the service's page, or a reply by mail | [Leaving a review](#leaving-a-review) |
| suggest a fix as a commit | reviewer | `git commit --fixup`, `git push` | [Suggesting a change as a commit](#suggesting-a-change-as-a-commit) |
| make version 2 | author | `git branch <branch>-v1`, `git rebase --autosquash`, `git push --force-with-lease` | [Responding to a review](#responding-to-a-review) |
| say what changed | author | `git range-diff`, `git format-patch --range-diff` | [Telling the reviewer what changed](#telling-the-reviewer-what-changed) |
| see what changed | reviewer | `git range-diff` | [Comparing two versions with range-diff](#comparing-two-versions-with-range-diff) |
| approve | reviewer | the service's button, or a `Reviewed-by:` trailer | [Approving](#approving) |

## The example repository

In Ada's clone:

```console
$ git log --oneline && cat lib.sh test.sh
2bb41ae Add the tests
3b8ec82 Start the greeter
hello() {
	echo "Hello, $1!"
}
. ./lib.sh
test "$(hello Ada)" = "Hello, Ada!" || { echo "FAIL: hello"; exit 1; }
echo "all tests passed"
```

A small project, `greet`: `lib.sh` holds shell functions, and `test.sh` runs
them and prints `all tests passed`, or the name of the test that failed and an
exit status of 1. `sh test.sh` runs the tests.

The project lives on a server, a bare repository standing in for GitHub, GitLab
or any shared server, and Ada and Bob each have a clone, which reaches it by the
relative path `../../server/greet.git` (Chapter 42 says why a relative URL). Ada
maintains the project and does the reviewing; Bob wrote the change. Bob can push
to the project, so his branch goes to the project itself; from a fork, as in
Chapter 50, only the remote names differ. Each section says whose clone it runs
in.

## Asking for a review

Bob has three commits on a branch called `farewell`. In Bob's clone:

```console
$ git shortlog -s -n origin/main -- lib.sh test.sh
     2	Ada Lovelace
$ git push -u origin farewell
To ../../server/greet.git
 * [new branch]      farewell -> farewell
branch 'farewell' set up to track 'origin/farewell'.
```

`git shortlog -s -n` with paths counts who wrote the commits that touched those
files (Chapter 22): here only Ada, so she is the one to ask. Git's
`SubmittingPatches` gives the same advice with `git log -p -- <area>`: the
people who worked on the code you are changing are the ones best able to help.
On GitHub, a `CODEOWNERS` file can ask them automatically (Chapter 50).

What to check before asking, so that the reviewer's time goes on what only a
reviewer can see:

| Check | Command | Covered in |
|---|---|---|
| the branch has the commits you meant, and no others | `git log --oneline origin/main..` | Chapter 17 |
| no whitespace errors | `git diff --check origin/main...HEAD` | [Whitespace errors](#whitespace-errors) |
| every commit passes the tests | `git rebase -x <test> --keep-base origin/main` | [Every commit, not only the last](#every-commit-not-only-the-last) |
| no `fixup!` commits left, no debugging lines | `git rebase --autosquash`, `git rebase -i` | Chapter 35, Chapter 34 |
| each message says why | | Chapter 53 |

Bob checked none of these. The review finds what they would have.

## What is under review

In Ada's clone:

```console
$ git fetch origin
From ../../server/greet
 * [new branch]      farewell   -> origin/farewell
$ git log --reverse --format='%h %an  %s' main..origin/farewell
3d40c1f Bob Brown  Add a farewell
68f5ea3 Bob Brown  Test the farewell
572d983 Bob Brown  fixup! Add a farewell
$ git diff --stat main...origin/farewell
 lib.sh  | 4 ++++
 test.sh | 1 +
 2 files changed, 5 insertions(+)
```

`main..origin/farewell` is the commits on Bob's branch that `main` does not
have (Chapter 18); `--reverse` lists them in the order they were made, and `%an`
is the author (Chapter 17). The three-dot diff compares the branch with the
point where it left `main`, which is what the change itself does; Chapter 50
shows the two-dot diff getting that wrong once `main` moves on. On a hosting
service the branch comes from a pull or merge request's ref or from a fork
(Chapters 50 and 51), and every command after the fetch is the same.

The last subject already says something. `fixup! Add a farewell` is a commit
meant to be folded into another by `git rebase --autosquash` (Chapter 35), and
Bob forgot to fold it in.

## Reading the change

### All at once, or one commit at a time

```console
$ git diff main...origin/farewell
diff --git a/lib.sh b/lib.sh
index e1e0d9e..7625676 100644
--- a/lib.sh
+++ b/lib.sh
@@ -1,3 +1,7 @@
 hello() {
 	echo "Hello, $1!"
 }
+
+bye() {
+ 	echo "Goodbye, $1."
+}
diff --git a/test.sh b/test.sh
index 1bbcc66..65926a8 100644
--- a/test.sh
+++ b/test.sh
@@ -1,3 +1,4 @@
 . ./lib.sh
 test "$(hello Ada)" = "Hello, Ada!" || { echo "FAIL: hello"; exit 1; }
+test "$(bye Ada)" = "Goodbye, Ada." || { echo "FAIL: bye"; exit 1; }
 echo "all tests passed"
$ git log -p --reverse --oneline main..origin/farewell
3d40c1f Add a farewell
diff --git a/lib.sh b/lib.sh
index e1e0d9e..df9d71e 100644
--- a/lib.sh
+++ b/lib.sh
@@ -1,3 +1,8 @@
 hello() {
 	echo "Hello, $1!"
 }
+
+bye() {
+	echo "DEBUG: bye $1"
+ 	echo "Goodbye, $1."
+}
68f5ea3 Test the farewell
diff --git a/test.sh b/test.sh
index 1bbcc66..65926a8 100644
--- a/test.sh
+++ b/test.sh
@@ -1,3 +1,4 @@
 . ./lib.sh
 test "$(hello Ada)" = "Hello, Ada!" || { echo "FAIL: hello"; exit 1; }
+test "$(bye Ada)" = "Goodbye, Ada." || { echo "FAIL: bye"; exit 1; }
 echo "all tests passed"
572d983 fixup! Add a farewell
diff --git a/lib.sh b/lib.sh
index df9d71e..7625676 100644
--- a/lib.sh
+++ b/lib.sh
@@ -3,6 +3,5 @@ hello() {
 }
 
 bye() {
-	echo "DEBUG: bye $1"
  	echo "Goodbye, $1."
 }
```

The whole diff is what `main` would gain, and it looks clean: a function and
its test. The commits tell more. The first added a debugging line,
`echo "DEBUG: bye $1"`, and the third took it out again. A whole diff never
shows a line that a later commit removes, so a problem that exists only in the
middle of a series cannot be seen in it: here, the test added by the second
commit fails at that commit, as [Every commit, not only the
last](#every-commit-not-only-the-last) shows.

Read both. The whole diff says what the change does; the commits say whether
each step is sound, which matters because `git bisect` (Chapter 20),
`git revert` (Chapter 31) and `git cherry-pick` (Chapter 32) work one commit at
a time. `git log -p --reverse` prints each commit's summary line and its diff,
oldest first; `git show <commit>` shows one (Chapter 18). Git's
`ReviewingGuidelines` adds the messages to what is reviewed: each should
explain its change fully and correctly (Chapter 53).

### Views that make a change easier to read

| The change | Try | Covered in |
|---|---|---|
| moves code, and changes some of it | `--color-moved`, with `--color-moved-ws=allow-indentation-change` | Chapter 13 |
| re-indents code | `-b`, `-w` | Chapter 13 |
| edits prose | `--word-diff`, `--color-words` | Chapter 13 |
| needs more context than three lines | `-W`, `-U<n>` | Chapter 13 |
| renames files | `-M` | Chapter 13 |
| contains a merge commit, perhaps with a conflict resolved in it | `git show --remerge-diff <merge>` | Chapter 26 |

Each works with `git diff`, `git log -p` and `git show` alike. For a large
refactoring, `ReviewingGuidelines` suggests `--color-moved`, `--ignore-space-change`
(the long form of `-b`), or both.

## Trying it without disturbing your work

Ada has an unfinished change of her own. In Ada's clone:

```console
$ git status --short
 M README.md
$ git worktree add --detach ../review origin/farewell
Preparing worktree (detached HEAD 572d983)
HEAD is now at 572d983 fixup! Add a farewell
$ cd ../review
$ sh test.sh
all tests passed
```

`git worktree add` makes a second working tree, here the directory `../review`
beside Ada's clone, attached to the same repository: the same commits,
branches and remotes, with its own files and its own `HEAD` (Chapter 56 covers
worktrees in full). `--detach` checks the commit out with no branch
(Chapter 24), since nothing done here is meant to stay on a branch of Ada's.
Her own change stays where it was, untouched, in the first directory.

The tests pass: on the last commit. The next section checks the others.
Stashing (Chapter 55) or a second clone would do too; the worktree leaves
Ada's own work exactly as it is, and shares the repository instead of copying
it.

## Checking the change

### Whitespace errors

In `../review`:

```console
$ git diff --check main...origin/farewell; echo "exit $?"
lib.sh:6: space before tab in indent.
+ 	echo "Goodbye, $1."
exit 2
```

`--check` reports whitespace errors in the lines a diff adds, with the file and
line number (Chapter 13); `core.whitespace` decides what counts as one. This
line looked fine in the diffs above: its indentation is a space and then a tab.
The non-zero exit status makes it usable in a script. `SubmittingPatches` asks
contributors to run `git diff --check` before committing; a reviewer runs it on
the whole branch, with three dots.

### Every commit, not only the last

```console
$ git rebase -x 'sh test.sh' --keep-base main
Rebasing (2/6)
Executing: sh test.sh
all tests passed
Rebasing (3/6)
Rebasing (4/6)
Executing: sh test.sh
FAIL: bye
warning: execution failed: sh test.sh
You can fix the problem, and then run

  git rebase --continue


$ git rebase --abort && git log --oneline -1
572d983 fixup! Add a farewell
```

`-x <command>` runs a command after each commit a rebase replays, and stops at
the first one that fails (Chapter 34). `--keep-base` replays the commits onto
the base they already have (Chapter 33), so nothing moves: Git reuses each
commit as it is, and the command runs on exactly the commits under review.
Without it, the rebase would first move them onto the tip of `main`, and the
tests would run on commits nobody has reviewed. [Approving](#approving) shows a
run that passes, with the hash unchanged at the end.

The first commit passes. The second, which adds the test for `bye`, fails,
because the debugging line from the first commit is still there at that point:
the series is broken in the middle and repaired at the end.
`git rebase --abort` goes back to where the check started, the commit under
review.

A terminal draws each `Rebasing` line over the one before it. The count is of
the todo list's lines, a `pick` and an `exec` for each commit, six in all. It
starts at 2 because a `pick` at the very start whose commit already sits on the
base is skipped before the rebase begins and counted as done, with no line of
its own; Git's `sequencer.c` calls this skipping unnecessary picks.

> **Since Git 2.24.** `git rebase --keep-base`.

### Whether it still merges

A branch can be sound on its own and still conflict with what reached `main`
since it started. `git merge-tree --write-tree main origin/farewell` does the
merge without touching any branch, index or file, and exits with 1 and lists
the conflicts if there are any (Chapter 25; Chapter 45 shows `--name-only`). On
GitHub the test merge in `refs/pull/<n>/merge` answers the same question
(Chapter 50).

> **Since Git 2.38.** `git merge-tree --write-tree`.

## Leaving a review

Git records no comments. Where they go depends on how the project reviews:

| The project reviews | Comments go | Covered in |
|---|---|---|
| on GitHub or GitLab | on the pull or merge request's page, on a line of the diff or on the whole | Chapter 50, Chapter 51 |
| by mail | in a reply to each patch, below the lines they are about, which are quoted | Chapter 61 |
| on Gerrit | on the change's page, for each patch set | [On Gerrit](#on-gerrit) |
| in the repository itself | `git notes`, under a ref of their own such as `refs/notes/review` | Chapter 38 |

Git's `ReviewingGuidelines` gives advice that holds on any of them: say whether
each comment must be dealt with before the change can go in; suggest how to fix
what you point out; review the tests and the commit messages as well as the
code; and say so when something is good, since a positive review tells the
author that someone other than them cares about the change. For a review by
mail, it suggests a plain-text reply to all, one reply per patch, with the
comments inline below the part they discuss, and parts of a long patch that
the comments are not about deleted from the quote. None of it is binding, the
guide says; it is advice.

### Words reviewers use

`ReviewingGuidelines` lists the shorthand of Git's own reviews, which is common
elsewhere too:

| Written | Means |
|---|---|
| `nit:` | a small problem that should be fixed, such as a typing mistake |
| `aside:`, `optional:`, `non-blocking:` | a comment that should not stop the change being accepted |
| `s/<before>/<after>/` | "you wrote `<before>`, and I think you meant `<after>`", after the substitute command of `sed` and `vim` |
| `#leftoverbits` | something outside the scope of this change, worth doing later |

A comment that is *blocking* is one the reviewer thinks would leave the code
broken or worse if ignored; the guide asks reviewers to say which kind each
comment is.

### Suggesting a change as a commit

Sometimes the quickest way to say what should change is to change it. Ada is
still in `../review`, where `sed -i` stands in for editing the file:

```console
$ sed -i 's/^ //' lib.sh && git commit -q -a --fixup=HEAD~2 && git push -q origin HEAD:farewell
$ cd ../greet
$ git worktree remove ../review
```

The `sed` command removes the space before the tab. `--fixup=HEAD~2` makes a
commit marked to be folded into `Add a farewell` (Chapter 35), and
`HEAD:farewell` pushes it onto the end of Bob's branch (Chapter 43): the commit
was made on a detached `HEAD`, so the branch has to be named. `git worktree
remove` then deletes the second working tree; Ada's commit survives it, since it
is on `farewell` now, on the server and in her `origin/farewell`.

Ada can push there because she can push to the project. Elsewhere:

| The project reviews | A fix as a commit goes |
|---|---|
| on GitHub | to the contributor's branch in their fork, when they allow maintainers to push (Chapter 50); or as a *suggested change* in a review comment, which becomes one commit on the branch when applied |
| on GitLab | to the contributor's fork, by URL (Chapter 51) |
| by mail | as a patch in the reply, which `SubmittingPatches` calls a change "on top of your change" |

GitHub's documentation says that everyone whose suggestion goes into such a
commit becomes a co-author of it, and whoever applies it becomes a co-author and
its committer. Co-authors are named in `Co-authored-by:` lines at the end of
the message (Chapter 53).

## Responding to a review

Ada's review said three things: the second commit fails the tests, the fixup
should have been folded in, and there is a whitespace error, which she fixed
herself in her own fixup. Meanwhile she committed her README line on `main` and
pushed it, so `main` has moved on.

### Keeping the version that was reviewed

In Bob's clone:

```console
$ git branch farewell-v1 && git pull -q --ff-only && git log --format='%h %an  %s' origin/main..
5d5da1f Ada Lovelace  fixup! Add a farewell
572d983 Bob Brown  fixup! Add a farewell
68f5ea3 Bob Brown  Test the farewell
3d40c1f Bob Brown  Add a farewell
```

`git branch farewell-v1` marks version 1 before anything changes it, as Git's
`MyFirstContribution` does for its example series. It costs nothing, and every
later comparison can name the old version instead of digging it out of a reflog
(Chapter 36). `git pull --ff-only` brought in Ada's fixup (Chapter 42), and its
fetch updated `origin/main` too, so `origin/main..` lists the four commits the
branch has that the new `main` does not.

### A new version, or new commits

```console
$ git rebase --autosquash origin/main
Rebasing (1/4)
Rebasing (2/4)
Rebasing (3/4)
Rebasing (4/4)
Successfully rebased and updated refs/heads/farewell.
$ git log --format='%h %an  %s' origin/main..
e329ce1 Bob Brown  Test the farewell
47d7e1b Bob Brown  Add a farewell
$ git push --force-with-lease
To ../../server/greet.git
 + 5d5da1f...e329ce1 farewell -> farewell (forced update)
```

`--autosquash` folded both `fixup!` commits into `Add a farewell`
(Chapter 35), and the rebase moved the series onto the new `main` on the way.
Version 2 has two commits, and both are Bob's: a folded-in fixup takes the
author of the commit it joins, so Ada's part in the first commit no longer
shows. Projects credit it with a trailer at the end of the message,
`Helped-by:` in Git's own project, `Co-authored-by:` on GitHub (Chapter 53).
The branch was rewritten, so the push needed `--force-with-lease`
(Chapter 43). A terminal draws the `Rebasing` lines over each other.

> **Since Git 2.44.** `git rebase --autosquash` without `-i`.

Bob could instead have left his three commits alone and added commits on top.
Projects differ on which they want:

| Compared on | A new version: rewrite the commits | New commits on top |
|---|---|---|
| The history that gets merged | each commit correct, and each passing the tests | the mistakes and their repairs, one after another |
| What the reviewer reads next | a range-diff between the versions | only the new commits; what was reviewed stays as it was |
| The push | `--force-with-lease` | an ordinary push |
| Whose practice | Git's own project, for every round until the change is accepted; Gerrit, where a new version is the amended commit | GitHub's documentation for pull requests (Chapter 50) |

`SubmittingPatches` puts Git's practice plainly: early rounds are full
replacements, and a mistake a reviewer found is fixed by rewriting the series
with `git rebase -i`, as if it had never been made. It changes once a topic has
been merged into Git's `next` branch (Chapter 49): after that, improvements come
as new commits on top. A project that squashes each pull request when merging it
(Chapter 50) keeps neither form in `main`.

`MyFirstContribution` adds one more thing: reply to each comment, saying whether
you made the change, prefer your original and why, or did something better than
either, so the reviewer does not have to hunt through the new version to find
out.

### Telling the reviewer what changed

```console
$ git range-diff origin/main farewell-v1 farewell
1:  3d40c1f ! 1:  47d7e1b Add a farewell
    @@ lib.sh
      }
     +
     +bye() {
    -+	echo "DEBUG: bye $1"
    -+ 	echo "Goodbye, $1."
    ++	echo "Goodbye, $1."
     +}
2:  68f5ea3 = 2:  e329ce1 Test the farewell
3:  572d983 < -:  ------- fixup! Add a farewell
```

Bob compares his two versions, commit by commit: the first commit lost its
debugging line and its stray space, the second is the same, the fixup is gone.
Chapter 35 explains the markers, and [Comparing two versions with
range-diff](#comparing-two-versions-with-range-diff) the whole output. On a
hosting service this goes in a comment under the pull request. By mail it goes
in the cover letter, and `git format-patch` puts it there:

```console
$ git format-patch -q -v2 --cover-letter --range-diff=farewell-v1 -o outgoing origin/main && ls outgoing
v2-0000-cover-letter.patch
v2-0001-Add-a-farewell.patch
v2-0002-Test-the-farewell.patch
$ cat outgoing/v2-0000-cover-letter.patch
From e329ce11736970963340b7971228516f1712f520 Mon Sep 17 00:00:00 2001
From: Bob Brown <bob@example.com>
Date: Mon, 5 Jan 2026 17:00:00 +0000
Subject: [PATCH v2 0/2] *** SUBJECT HERE ***

*** BLURB HERE ***

Bob Brown (2):
  Add a farewell
  Test the farewell

 lib.sh  | 4 ++++
 test.sh | 1 +
 2 files changed, 5 insertions(+)

Range-diff against v1:
1:  3d40c1f ! 1:  47d7e1b Add a farewell
    @@ lib.sh
      }
     +
     +bye() {
    -+	echo "DEBUG: bye $1"
    -+ 	echo "Goodbye, $1."
    ++	echo "Goodbye, $1."
     +}
2:  68f5ea3 = 2:  e329ce1 Test the farewell
3:  572d983 < -:  ------- fixup! Add a farewell
...
```

`git format-patch` writes a series as files ready to be mailed, one per commit
(Chapter 61 covers it with `git send-email` and `git am`). `-v2` marks them as
version 2, in the file names and as `[PATCH v2 0/2]` in the subject;
`--cover-letter` adds the introduction, in which Bob replaces the two lines
marked `***` with a subject and a summary; and `--range-diff=farewell-v1` ends
it with the comparison against version 1. The file ends with a signature, a line
`-- ` and the version of Git, cut here. This is the command
`MyFirstContribution` gives, where the old version is written as a range,
`master..psuh-v1`; a branch, as here, works as well.

`--interdiff` puts a plain diff between the two versions there instead:

```console
$ git format-patch -q -v2 --cover-letter --interdiff=farewell-v1 -o outgoing2 origin/main && sed -n '/^Interdiff/,$p' outgoing2/v2-0000-cover-letter.patch
Interdiff against v1:
diff --git a/README.md b/README.md
index d3c24cd..9ed4d3e 100644
--- a/README.md
+++ b/README.md
@@ -1,3 +1,4 @@
 # greet
 
 Shell functions that greet people.
+Say hello to people by name.
diff --git a/lib.sh b/lib.sh
index 7625676..469b554 100644
--- a/lib.sh
+++ b/lib.sh
@@ -3,5 +3,5 @@ hello() {
 }
 
 bye() {
- 	echo "Goodbye, $1."
+	echo "Goodbye, $1."
 }
...
```

It shows the stray space going, and also Ada's README line, which came from
`main` and is no part of Bob's change; and it cannot show that the debugging
line has left the first commit, because neither version's last commit has it.
The signature is cut here as before.

`SubmittingPatches` suggests one more place for a summary of what changed:
notes on the commits themselves, which `git format-patch --notes` puts into each
patch and which `git range-diff` compares along with the commits
([Notes](#notes)).

## Comparing two versions with range-diff

In Ada's clone:

```console
$ git fetch origin
From ../../server/greet
 + 5d5da1f...e329ce1 farewell   -> origin/farewell  (forced update)
$ git diff --stat origin/farewell@{1} origin/farewell
 README.md | 1 +
 1 file changed, 1 insertion(+)
$ git range-diff main origin/farewell@{1} origin/farewell
1:  3d40c1f ! 1:  47d7e1b Add a farewell
    @@ lib.sh
      }
     +
     +bye() {
    -+	echo "DEBUG: bye $1"
    -+ 	echo "Goodbye, $1."
    ++	echo "Goodbye, $1."
     +}
2:  68f5ea3 = 2:  e329ce1 Test the farewell
3:  572d983 < -:  ------- fixup! Add a farewell
4:  5d5da1f < -:  ------- fixup! Add a farewell
```

`origin/farewell@{1}` is where `origin/farewell` was before this fetch
(Chapter 36): version 1 with Ada's fixup on top, where her own push had put it.
A plain diff between the two versions shows one line of the README, which came
from `main`, and nothing of Bob's: the last commits of the two versions have
the same `lib.sh` and `test.sh`, because the fixups had already repaired them.
What changed is inside the series, and that is what `git range-diff` compares:
it pairs each commit of one version with its counterpart in the other, and for
each pair shows the difference between the two commits' patches, a diff of
diffs (Chapter 13). The first commit no longer adds the debugging line or the
stray space, the second is the same, and both fixups are gone.

### The three forms

`git range-diff -h`:

```
git range-diff [<options>] <old-base>..<old-tip> <new-base>..<new-tip>
git range-diff [<options>] <old-tip>...<new-tip>
git range-diff [<options>] <base> <old-tip> <new-tip>
```

Any form can end with `-- <path>...` ([Only some files](#only-some-files)).

| Form | Compares | Use it when |
|---|---|---|
| `<old-base>..<old-tip> <new-base>..<new-tip>` | two ranges, each written in full | the two versions need different bases, or you want one commit of each |
| `<old-tip>...<new-tip>` | the commits of each tip that the other does not have | both versions start from the same commit |
| `<base> <old-tip> <new-tip>` | `<base>..<old-tip>` with `<base>..<new-tip>` | one base serves both, such as `main` after fetching; the usual case |

Git's documentation says the second and third forms are the first written
shorter. `diff <(...) <(...)` compares the output of two commands, in bash
(Chapter 17 used it too):

```console
$ diff <(git range-diff main origin/farewell@{1} origin/farewell) <(git range-diff main..origin/farewell@{1} main..origin/farewell) && echo same
same
$ diff <(git range-diff origin/farewell@{1}...origin/farewell) <(git range-diff origin/farewell..origin/farewell@{1} origin/farewell@{1}..origin/farewell) && echo same
same
```

A range can also be one commit, `<commit>^!`, or a merge and what it brought in,
`<commit>^-<n>` (Chapter 18), which compares two chosen commits directly,
whatever else is in either version:

```console
$ git range-diff origin/farewell@{1}~3^! origin/farewell~1^!
1:  3d40c1f ! 1:  47d7e1b Add a farewell
    @@ lib.sh
      }
     +
     +bye() {
    -+	echo "DEBUG: bye $1"
    -+ 	echo "Goodbye, $1."
    ++	echo "Goodbye, $1."
     +}
```

### Options at a glance

| Option | Does | Covered in |
|---|---|---|
| `--creation-factor=<percent>` | How different two commits may be and still be paired; 60 by default | [When a commit is shown as removed and added](#when-a-commit-is-shown-as-removed-and-added) |
| `--no-dual-color` | Colour whole lines red or green, instead of keeping each patch's own colours; `--dual-color` is the default | [Colour](#colour) |
| `--left-only` | Leave out commits that are only in the new version | [Choosing the base](#choosing-the-base) |
| `--right-only` | Leave out commits that are only in the old version | [Choosing the base](#choosing-the-base) |
| `--notes`, `--notes=<ref>`, `--no-notes` | Which notes are compared with each commit | [Notes](#notes) |
| `--diff-merges=<format>` | Compare merge commits too, with their diffs made in this format | [Merges](#merges) |
| `--remerge-diff` | The same, in the format `remerge` | [Merges](#merges) |
| `--max-memory=<size>` | The most memory the pairing may use; 4G by default | [Output options](#output-options) |
| `--abbrev=<n>` | Show hashes `<n>` characters long | [Output options](#output-options) |
| `-s`, `--no-patch` | Only the summary lines | [Output options](#output-options), Chapter 35 |
| `-U<n>` | Lines of context in the diff between the patches | [Output options](#output-options) |
| `--stat` | A diffstat of the diff between the patches | [Output options](#output-options) |
| `--color`, `--no-color` | Colour on or off | [Colour](#colour) |

<!-- no-example: --color
     The coloured transcripts under "Colour" are exactly what --color prints:
     the sandbox forces colour through the environment so that the printed
     command stays what a reader types at a terminal, where colour is on
     without the option. Every plain transcript is what --no-color prints,
     since the sandbox is not a terminal. -->

`git range-diff` also takes the other options of `git diff` (Chapter 13). They
apply to the diff between the patches; Git's documentation says there is at
present no way to change most of the options used to make the patches
themselves.

> **Since Git 2.25.** `--notes` and `--no-notes`. **Since Git 2.31.**
> `--left-only` and `--right-only`. **Since Git 2.38.** Paths after `--`.
> **Since Git 2.40.** `--abbrev`. **Since Git 2.48.** `--diff-merges` and
> `--remerge-diff`. **Since Git 2.52.** `--max-memory`.

### Reading the output

Each commit gets one line, in five parts:

| Part, in `1:  3d40c1f ! 1:  47d7e1b Add a farewell` | Means |
|---|---|
| `1:  3d40c1f` | the commit's position in the old version, counting from the base, and its hash |
| `!` | `=` the same commit; `!` a pair, changed; `<` only in the old version; `>` only in the new |
| `1:  47d7e1b` | its position and hash in the new version; `-:  -------` when there is none |
| `Add a farewell` | the subject, of the old commit when there is one |

`=` means the author's name and address, the message and the diff are all the
same; the hash differs because something else did, such as the parent or a
date. Git's
documentation says two commits are paired when the difference between their
patches, author and message included, is small compared with the patches.

Under a `!` line comes the difference between the two commits' patches,
indented four spaces. It is a diff whose lines are themselves diff lines, and
it has two columns of markers. The first says how the patch changed between the
versions: `-` a line only in the old patch, `+` only in the new, a space in
both. The second is the patch's own marker. So `-+	echo "DEBUG: bye $1"` is a
line the old commit added and the new one does not, and `++	echo "Goodbye, $1."`
a line only the new commit adds. `@@ lib.sh` says which part of the patch the
hunk is in; the parts are the author, headed `Metadata`, then
`## Commit message ##`, `## Notes ##` when there are notes, and one part for each
file, headed `## <file> ##`, as [Notes](#notes) shows in full.

The list follows the new version's order, and a commit only in the old version
comes after everything it was built on, as Git's documentation puts it. Here
the two commits of version 2 were copied in the opposite order, in Bob's clone:

```console
$ git switch -q --detach origin/main && git cherry-pick farewell farewell~1 && git range-diff origin/main farewell HEAD
[detached HEAD 9e4308a] Test the farewell
 Date: Mon Jan 5 12:00:00 2026 +0000
 1 file changed, 1 insertion(+)
[detached HEAD 8f0e27d] Add a farewell
 Date: Mon Jan 5 11:00:00 2026 +0000
 1 file changed, 4 insertions(+)
2:  e329ce1 = 1:  9e4308a Test the farewell
1:  47d7e1b = 2:  8f0e27d Add a farewell
```

Both commits are `=`: the same change, author and message. The numbers show the
swap: the old second commit is the new first.

### Choosing the base

In Ada's clone:

```console
$ git range-diff origin/farewell@{1}...origin/farewell
-:  ------- > 1:  a2f1044 Say what greet is for
1:  3d40c1f ! 2:  47d7e1b Add a farewell
    @@ lib.sh
      }
     +
     +bye() {
    -+	echo "DEBUG: bye $1"
    -+ 	echo "Goodbye, $1."
    ++	echo "Goodbye, $1."
     +}
2:  68f5ea3 = 3:  e329ce1 Test the farewell
3:  572d983 < -:  ------- fixup! Add a farewell
4:  5d5da1f < -:  ------- fixup! Add a farewell
```

The three-dot form takes, on each side, the commits the other tip does not
have. Version 2 was rebased onto the new `main`, so Ada's `Say what greet is
for` is in version 2 and not in version 1, and it appears as a commit the
series gained. The base form avoids that: `main..<old>` and `main..<new>` both
leave out everything `main` has, and after the fetch `main` has both versions'
bases. Git's documentation adds that the base need not be the exact commit a
branch starts from, and gives this command for checking a rebase you have just
made: `git range-diff @{u} @{1} @`, the upstream, the branch before the rebase,
and the branch now.

```console
$ git range-diff --right-only origin/farewell@{1}...origin/farewell
-:  ------- > 1:  a2f1044 Say what greet is for
1:  3d40c1f ! 2:  47d7e1b Add a farewell
    @@ lib.sh
      }
     +
     +bye() {
    -+	echo "DEBUG: bye $1"
    -+ 	echo "Goodbye, $1."
    ++	echo "Goodbye, $1."
     +}
2:  68f5ea3 = 3:  e329ce1 Test the farewell
$ git range-diff --left-only origin/farewell@{1}...origin/farewell
1:  3d40c1f ! 2:  47d7e1b Add a farewell
    @@ lib.sh
      }
     +
     +bye() {
    -+	echo "DEBUG: bye $1"
    -+ 	echo "Goodbye, $1."
    ++	echo "Goodbye, $1."
     +}
2:  68f5ea3 = 3:  e329ce1 Test the farewell
3:  572d983 < -:  ------- fixup! Add a farewell
4:  5d5da1f < -:  ------- fixup! Add a farewell
```

`--right-only` leaves out the `<` lines, commits only in the old version, and
`--left-only` the `>` lines, commits only in the new. Here `--left-only` hid
the commit from `main`, but it would hide a commit the author really added in
version 2 just the same, so it is no substitute for the right base. On a long
series, `--right-only` answers "what is in the new version, and how did each
commit change", and `--left-only` "what happened to each commit I reviewed".

### When a commit is shown as removed and added

```console
$ git range-diff --creation-factor=20 main origin/farewell@{1} origin/farewell
1:  3d40c1f < -:  ------- Add a farewell
-:  ------- > 1:  47d7e1b Add a farewell
2:  68f5ea3 = 2:  e329ce1 Test the farewell
3:  572d983 < -:  ------- fixup! Add a farewell
4:  5d5da1f < -:  ------- fixup! Add a farewell
```

The same two `Add a farewell` commits that the default paired are now one
commit removed and another added, with nothing shown about how they differ.
Git's documentation describes the pairing as the cheapest match between the old
commits and the new: pairing two commits costs the size of the diff between
their patches, and treating a commit as removed or added costs its own size
multiplied by the creation factor, 60 percent unless `--creation-factor` says
otherwise. A higher factor makes pairing cheaper by comparison, and a lower one
dearer, as here at 20.

So when `git range-diff` lists a commit you know was only reworked as removed
and added, raise the value; Chapter 35 has such a case, where a fixup changed
all of a small commit. When it pairs two commits that have nothing to do with
each other, lower it.

### Only some files

```console
$ git range-diff main origin/farewell@{1} origin/farewell -- test.sh
1:  68f5ea3 = 1:  e329ce1 Test the farewell
```

With paths, each range keeps only the commits that touch them, as
`git log -- <path>` would, and the positions count those commits only.

### Colour

On a terminal:

```ansi
$ git range-diff main origin/farewell@{1} origin/farewell -- lib.sh
\e[31m1:  3d40c1f \e[m\e[33m!\e[m\e[32m 1:  47d7e1b\e[m\e[33m Add a farewell\e[m
    \e[7m\e[36m@@\e[m \e[mlib.sh\e[m
      }\e[m
    \e[32m +\e[m
    \e[32m +bye() {\e[m
    \e[7m\e[31m-\e[m\e[2;32m+	echo "DEBUG: bye $1"\e[m
    \e[7m\e[31m-\e[m\e[2;32m+ 	echo "Goodbye, $1."\e[m
    \e[7m\e[32m+\e[m\e[1;32m+	echo "Goodbye, $1."\e[m
    \e[32m +}\e[m
\e[31m2:  572d983 < -:  ------- fixup! Add a farewell\e[m
\e[31m3:  5d5da1f < -:  ------- fixup! Add a farewell\e[m
$ git range-diff --no-dual-color main origin/farewell@{1} origin/farewell -- lib.sh
\e[31m1:  3d40c1f \e[m\e[33m!\e[m\e[32m 1:  47d7e1b\e[m\e[33m Add a farewell\e[m
    \e[36m@@\e[m \e[mlib.sh\e[m
      }\e[m
     +\e[m
     +bye() {\e[m
    \e[31m-+	echo "DEBUG: bye $1"\e[m
    \e[31m-+ 	echo "Goodbye, $1."\e[m
    \e[32m+\e[m\e[32m+	echo "Goodbye, $1."\e[m
     +}\e[m
\e[31m2:  572d983 < -:  ------- fixup! Add a farewell\e[m
\e[31m3:  5d5da1f < -:  ------- fixup! Add a farewell\e[m
```

In the summary line the old commit is red, the new one green, and the marker
and subject yellow; a line for a commit on one side only is all red or all
green. In the diff between the patches, by default, the outer marker is drawn
on a red or green background, and the rest of the line keeps the colour it had
in its own patch: dimmed when only the old patch has it, bold when only the new
one does. Git calls this *dual colour*. With `--no-dual-color` each line is
coloured by the outer marker alone, so the two lines the old commit added are
simply red. The `color.diff.<slot>` settings change the dimmed and bold colours
([The settings](#the-settings)).

### Notes

In Bob's clone:

```console
$ git notes add -m 'v2: fold in both fixups' HEAD~1 && git range-diff origin/main farewell-v1 farewell
1:  3d40c1f ! 1:  47d7e1b Add a farewell
    @@ Metadata
      ## Commit message ##
         Add a farewell
     
    +
    + ## Notes ##
    +    v2: fold in both fixups
    +
      ## lib.sh ##
     @@
      hello() {
    @@ lib.sh
      }
     +
     +bye() {
    -+	echo "DEBUG: bye $1"
    -+ 	echo "Goodbye, $1."
    ++	echo "Goodbye, $1."
     +}
2:  68f5ea3 = 2:  e329ce1 Test the farewell
3:  572d983 < -:  ------- fixup! Add a farewell
$ git range-diff --no-notes origin/main farewell-v1 farewell
1:  3d40c1f ! 1:  47d7e1b Add a farewell
    @@ lib.sh
      }
     +
     +bye() {
    -+	echo "DEBUG: bye $1"
    -+ 	echo "Goodbye, $1."
    ++	echo "Goodbye, $1."
     +}
2:  68f5ea3 = 2:  e329ce1 Test the farewell
3:  572d983 < -:  ------- fixup! Add a farewell
$ git notes --ref=changes add -m 'v2: test unchanged' HEAD && git range-diff --notes=changes origin/main farewell-v1 farewell
1:  3d40c1f ! 1:  47d7e1b Add a farewell
    @@ lib.sh
      }
     +
     +bye() {
    -+	echo "DEBUG: bye $1"
    -+ 	echo "Goodbye, $1."
    ++	echo "Goodbye, $1."
     +}
2:  68f5ea3 ! 2:  e329ce1 Test the farewell
    @@ Metadata
      ## Commit message ##
         Test the farewell
     
    +
    + ## Notes (changes) ##
    +    v2: test unchanged
    +
      ## test.sh ##
     @@
      . ./lib.sh
3:  572d983 < -:  ------- fixup! Add a farewell
```

A note on a commit (Chapter 38) is compared along with it, since
`git range-diff` makes each patch with `git log`, which shows notes: by default
those of the default notes ref, as the `## Notes ##` part of the first command
shows. That makes a note a place to say, commit by commit, what a version
changed. `--no-notes` compares without them, and `--notes=<ref>` with the notes
of that ref only. In the last command, the note on the first commit, in the
default ref, was left out, and the note on the second, in `refs/notes/changes`,
was not, which made that commit `!` where it had been `=`.

The first transcript also shows the parts of a patch in full: the author, under
`@@ Metadata`, then the message, the notes, and the file.

### Merges

In Bob's clone, had he merged `main` into version 1 instead of rebasing it, as
GitHub's "Update branch" button does (Chapter 50):

```console
$ git switch -q -c farewell-merged farewell-v1 && git merge -q --no-edit origin/main && git range-diff origin/main farewell-v1 farewell-merged
1:  3d40c1f = 1:  3d40c1f Add a farewell
2:  68f5ea3 = 2:  68f5ea3 Test the farewell
3:  572d983 = 3:  572d983 fixup! Add a farewell
$ git range-diff --remerge-diff origin/main farewell-v1 farewell-merged
1:  3d40c1f = 1:  3d40c1f Add a farewell
2:  68f5ea3 = 2:  68f5ea3 Test the farewell
3:  572d983 = 3:  572d983 fixup! Add a farewell
-:  ------- > 4:  1aa728b Merge remote-tracking branch 'origin/main' into farewell-merged
$ git range-diff --diff-merges=first-parent origin/main farewell-v1 farewell-merged
1:  3d40c1f = 1:  3d40c1f Add a farewell
2:  68f5ea3 = 2:  68f5ea3 Test the farewell
3:  572d983 = 3:  572d983 fixup! Add a farewell
-:  ------- > 4:  1aa728b Merge remote-tracking branch 'origin/main' into farewell-merged
```

Plain `git range-diff` ignores merge commits, as its documentation says, so it
reported no change at all. `--diff-merges=<format>` takes merges into account,
with their diffs made as `git log --diff-merges=<format>` would make them
(Chapter 17). `--remerge-diff`, which the documentation says is the same as
`--diff-merges=remerge`, is the format it calls the most natural: a merge that needed no conflict
resolution then has an empty diff, and one that did shows what the author
changed while resolving it. A merge in only one of the versions is listed as
`>` or `<`, with no diff, whatever the format, as both commands show.

### Output options

In Ada's clone:

```console
$ git range-diff --abbrev=12 -s main origin/farewell@{1} origin/farewell
1:  3d40c1fd325f ! 1:  47d7e1b54634 Add a farewell
2:  68f5ea37cd45 = 2:  e329ce117369 Test the farewell
3:  572d98331626 < -:  ------------ fixup! Add a farewell
4:  5d5da1fa8993 < -:  ------------ fixup! Add a farewell
$ git range-diff -U1 main origin/farewell@{1} origin/farewell
1:  3d40c1f ! 1:  47d7e1b Add a farewell
    @@ lib.sh
     +bye() {
    -+	echo "DEBUG: bye $1"
    -+ 	echo "Goodbye, $1."
    ++	echo "Goodbye, $1."
     +}
2:  68f5ea3 = 2:  e329ce1 Test the farewell
3:  572d983 < -:  ------- fixup! Add a farewell
4:  5d5da1f < -:  ------- fixup! Add a farewell
$ git range-diff --stat main origin/farewell@{1} origin/farewell
1:  3d40c1f ! 1:  47d7e1b Add a farewell
     a => b | 3 +--
     1 file changed, 1 insertion(+), 2 deletions(-)
2:  68f5ea3 = 2:  e329ce1 Test the farewell
3:  572d983 < -:  ------- fixup! Add a farewell
4:  5d5da1f < -:  ------- fixup! Add a farewell
$ git range-diff --max-memory=1 main origin/farewell@{1} origin/farewell
fatal: range-diff: unable to compute the range-diff, since it exceeds the maximum memory for the cost matrix: 144 bytes (144 bytes) needed, limited to 1 byte (1 bytes)
```

`--abbrev=12` gives twelve characters of each hash, and `-s` only the summary
lines (Chapter 35). `-U1` keeps one line of context around each change in the
diff between the patches instead of three. `--stat` counts the lines of that
diff, under the made-up names `a` and `b`; Git's documentation warns that
options such as `--stat` can give output of no use in `git range-diff`, as this
is.

`--max-memory` limits the table of costs that pairing uses, which grows with
the number of old commits times the number of new ones; a range-diff that would
need more stops with the message above, here with an absurd limit of one byte.
The default, 4G, is printed by `git range-diff -h`; the manual page installed
with Git 2.55 does not describe the option. A series big enough to reach the
limit can be compared a part at a time, with narrower ranges or with paths.

## Approving

Ada's own work is committed by now, so she checks version 2 in her clone
itself, on a detached `HEAD` (Chapter 24):

```console
$ git switch -q --detach origin/farewell && git rebase -x 'sh test.sh' --keep-base main
Rebasing (2/4)
Executing: sh test.sh
all tests passed
Rebasing (3/4)
Rebasing (4/4)
Executing: sh test.sh
all tests passed
Successfully rebased and updated detached HEAD.
$ git rev-parse HEAD origin/farewell && git switch -q main
e329ce11736970963340b7971228516f1712f520
e329ce11736970963340b7971228516f1712f520
```

Every commit passes, and afterwards `HEAD` is exactly the commit on the server:
with `--keep-base`, nothing was rewritten.

How the approval itself is given, and what Git ends up holding of it:

| The project reviews | Approval is | In the history |
|---|---|---|
| on GitHub | an approving review on the pull request | nothing of the review; the merge commit names the pull request (Chapter 50) |
| on GitLab | an approval on the merge request | nothing, unless the project's merge commit template includes approvers (Chapter 51) |
| by mail | a reply saying so, often offering `Reviewed-by: <name>` | a `Reviewed-by:` trailer, which the author adds when sending the next version |
| on Gerrit | a vote on each review label | nothing of the vote |

`ReviewingGuidelines` asks a reviewer who is happy with a series to say so
explicitly, usually in a reply to the latest version's cover letter, and says
they may let the author add `Reviewed-by: <you>` if the reviewed patch is sent
again unchanged. `SubmittingPatches` is stricter than for any other trailer:
`Reviewed-by:` may only be offered by the reviewer, after a detailed analysis
that left them fully satisfied. Adding a trailer to every commit of a branch is
`git rebase --trailer` (Chapter 33); what each trailer means is Chapter 53's
subject.

## Three ways projects review

### On a hosting service

A pull request (Chapter 50) or merge request (Chapter 51) is a branch with a
page. A new version is a push to the branch, with new commits or rewritten
ones; the page updates itself, and the reviewer fetches it and uses
`git range-diff` as above. The change lands through the service's merge button,
by one of its merge methods.

### By mail

Git's own project, and others such as the Linux kernel, review patches sent by
mail. The author sends the series with `git format-patch` and
`git send-email`, each patch one message, after a cover letter; the subjects
read `[PATCH 1/2]`, then `[PATCH v2 1/2]` for the next round, and
`MyFirstContribution` sends each new round's cover letter as a reply to the
previous round's, so that every version stays in one thread. Reviewers reply
inline. When the series is agreed, the
maintainer applies it with `git am` (Chapter 61 covers all three commands).
Chapter 49 describes what then happens to it in Git's `seen`, `next` and
`master` branches.

### On Gerrit

Gerrit is a code review server that hosts Git repositories, and it reviews
commits rather than branches. Its documentation, read in September 2026, says:

| Gerrit's term or command | Means |
|---|---|
| a *change* | one commit under review |
| a *patch set* | one version of the change; amending the commit and pushing it again makes a new one |
| `git push origin HEAD:refs/for/main` | send `HEAD` for review into `main`; each commit pushed becomes a change (Chapter 44 shows such a push to a plain Git server, which just stores the ref) |
| `Change-Id: I<hex digits>` | a line in the last paragraph of the message, beside trailers such as `Signed-off-by`, which ties every patch set of a change together, across amends, rebases and cherry-picks |
| the `commit-msg` hook | a hook Gerrit provides, copied into `.git/hooks`, which adds a `Change-Id` to each new commit (Chapter 67 covers hooks) |
| `refs/changes/<last two digits>/<change>/<patch set>` | where each patch set can be fetched: patch set 2 of change 263270 is `refs/changes/70/263270/2` |
| submit | apply the latest patch set to the branch; by default only when every review label has its highest vote and none has its lowest |

So on Gerrit an amended commit is not a new change as long as its `Change-Id`
line is kept, and the documentation says to leave that line alone when running
`git commit --amend`. Fetching a patch set to try it is the same as fetching a
pull request's ref (Chapter 50):
`git fetch <url> refs/changes/74/67374/2 && git switch --detach FETCH_HEAD`.

| Compared on | A hosting service | Mail | Gerrit |
|---|---|---|---|
| What is reviewed | a branch | a series of patches | one commit |
| A new version | a push to the branch | the series sent again as `[PATCH v2]` | the amended commit pushed to `refs/for/<branch>` |
| What ties the versions together | the pull or merge request | the mail thread | the `Change-Id:` line |
| Seeing what changed | `git range-diff`, run by the reviewer | the range-diff in the cover letter | the change's page, one patch set against another |
| Approval | a review, or an approval | a reply, and a `Reviewed-by:` trailer | votes on labels |
| How it lands | a merge button | `git am`, by the maintainer | submit |
| Covered in | Chapter 50, Chapter 51 | Chapter 61 | this section |

## range-diff and its neighbours

| Command | Compares | Answers |
|---|---|---|
| `git range-diff <base> <v1> <v2>` | the commits of two versions, pair by pair | what happened to each commit |
| `git diff <v1> <v2>` | the files at the two tips | the net difference, including whatever a new base brought ([Comparing two versions with range-diff](#comparing-two-versions-with-range-diff)) |
| `git diff <base>...<v2>` | the files where the branch starts and at its tip | what the whole change does now (Chapter 13) |
| `git log --cherry-mark --left-right <v1>...<v2>` | the commits of both sides | which commits have an identical change on the other side, marked `=` (Chapter 17, Chapter 45) |
| `git cherry -v <upstream> <branch>` | a branch with its upstream | which of the branch's commits the upstream already has a copy of (Chapter 18) |
| `git patch-id` | one patch | an identifier that is the same for the same change, whatever commit it is in |

In Bob's clone:

```console
$ for c in farewell-v1~2 farewell~1 farewell-v1~1 farewell; do git show $c | git patch-id; done
2b90efc16558d5cd0dcdd9f80e5fd7d4c122e9e3 3d40c1fd325fbe87a78ef15a92aad5fb99412852
8b330fe3203f380523cc0f02688746fbfa6a9801 47d7e1b5463483b5b7e3cc71d288dc7b7d486b5c
c42f809076afd83ab829367294994c9dd8961c89 68f5ea37cd45edc97436213d24cb0f19b300bd2e
c42f809076afd83ab829367294994c9dd8961c89 e329ce11736970963340b7971228516f1712f520
```

`git patch-id` reads a patch and prints an identifier made from the changes to
the files, ignoring line numbers, then the commit the patch came from. The two
`Add a farewell` commits get different identifiers, since version 2 adds
different lines; the two `Test the farewell` commits get the same one: the same
change, on a different base. Git's documentation gives finding likely duplicate
commits as its main use, and says `git cherry` shows which commits of a branch
have a commit with an equivalent patch ID upstream. Neither looks at the
message or the author, which `git range-diff` compares too; and where the
identifiers only say that the first commits differ, `git range-diff` pairs them
and shows how.

## Undoing

| To undo | Do | Covered in |
|---|---|---|
| a new version you are not happy with, before pushing | `git reset --hard <branch>-v1`, or `ORIG_HEAD` straight after the rebase | Chapter 30 |
| a new version already pushed | `git push --force-with-lease origin <branch>-v1:<branch>` | Chapter 43 |
| a fixup you pushed onto someone else's branch | ask the author to drop it in their next rebase, or `git revert` it | Chapter 34, Chapter 31 |
| a second working tree | `git worktree remove <dir>`; after deleting its directory by hand, `git worktree prune` | Chapter 56 |
| a `git rebase -x` check that stopped | `git rebase --abort` | [Every commit, not only the last](#every-commit-not-only-the-last) |

Nothing in a review changes the reviewer's repository unless they commit: the
fetches, diffs, range-diffs and a `--keep-base` check leave every branch where
it was.

## The settings

| Setting | Does | Covered in |
|---|---|---|
| `diff.colorMoved`, `diff.colorMovedWS` | Colour moved code in every diff, and how whitespace counts | Chapter 13 |
| `core.whitespace` | What `git diff --check` reports | Chapter 13 |
| `color.diff.oldDimmed`, `color.diff.newDimmed`, `color.diff.contextDimmed` | In `git range-diff`, the colours of lines only in the old patch | [Colour](#colour) |
| `color.diff.oldBold`, `color.diff.newBold`, `color.diff.contextBold` | The colours of lines only in the new patch | [Colour](#colour) |
| `pager.range-diff` | Whether `git range-diff` output goes through the pager; on by default | Chapter 13 |
| `rebase.autoSquash` | Fold `fixup!` commits in every rebase | Chapter 35 |
| `notes.displayRef` | Which notes refs `git log` shows besides the default | Chapter 38 |
