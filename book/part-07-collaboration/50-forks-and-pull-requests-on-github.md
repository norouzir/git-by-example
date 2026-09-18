# Chapter 50. Forks and Pull Requests on GitHub

## What it is

GitHub is a service that hosts Git repositories, and two of its features are
how most projects there accept work from people who cannot push to them. A
*fork* is your own copy of someone else's repository, kept on GitHub under your
account, which you can push to. A *pull request* is a page on GitHub asking the
people who run a repository to merge a branch into it: the change is shown,
discussed, reviewed, often tested automatically, and finally merged or closed,
all on that page.

Neither is a Git feature. To Git, a fork is one more remote, and a pull request
is a branch plus a few refs GitHub adds to the original repository. This chapter
shows the Git side of every step, run against two bare repositories standing in
for GitHub's, and describes the web side as GitHub's documentation gives it,
read in September 2026; the service changes, and its own pages are the
authority for anything that is not Git. The one question it answers is: *how do
I get my change into a project I cannot push to, and what does Git have to do
with each step?*

| Term | Means |
|---|---|
| *fork* | a copy of a repository on GitHub, under your account, that you can push to |
| *upstream* | the repository a fork was made from; also, by convention, the name of the remote for it (Chapter 39) |
| *pull request*, *PR* | a request, on GitHub, to merge a branch into a repository, with a page for reviewing it |
| *base branch* | the branch the pull request is to be merged into, usually `main` of the original |
| *head branch*, *compare branch* | the branch whose commits the pull request proposes, in your fork or in the original itself |
| *maintainer* | someone with push access to the original repository, who can merge pull requests |
| *review* | a maintainer's or colleague's response to a pull request: a comment, an approval, or a request for changes |
| *draft pull request* | a pull request marked as not ready; GitHub will not merge it until it is marked ready for review |
| *merge method* | how GitHub puts the branch into the base branch: a merge commit, a squash, or a rebase |
| *protected branch* | a branch GitHub guards with rules, such as no force pushes, or no merge without an approving review |
| *personal access token* | a string GitHub issues for Git to use over HTTPS in place of your password (Chapter 40) |
| *triangular workflow* | pulling from one repository and pushing to another, here the original and your fork |

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What are a fork and a pull request, and are they part of Git?](#what-it-is)

**[The steps at a glance](#the-steps-at-a-glance)**

- [What are the steps from forking to a merged change, and which happen in Git?](#the-steps-at-a-glance)

**[The example repositories](#the-example-repositories)**

- [What repositories do the examples use, when nothing here reaches GitHub?](#the-example-repositories)

**[Forking](#forking)**

- [What exactly does the Fork button copy?](#forking)
- [Does my fork follow the original by itself once it is made?](#forking)

**[Cloning your fork](#cloning-your-fork)**

- [Should I clone the original or my fork?](#cloning-your-fork)
- [Which remote should be `origin`, and which `upstream`?](#cloning-your-fork)
- [How do I make `git pull` take from the original and `git push` go to my fork?](#pulling-from-one-pushing-to-the-other)
- [Why does `@{push}` say "cannot resolve 'simple' push to a single destination"?](#pulling-from-one-pushing-to-the-other)

**[Keeping your fork up to date](#keeping-your-fork-up-to-date)**

- [The original has new commits. How do I bring my fork up to date?](#keeping-your-fork-up-to-date)
- [What does the "Sync fork" button do, and is there a command for it?](#keeping-your-fork-up-to-date)
- [I committed on my fork's `main` by mistake. What now?](#keeping-your-fork-up-to-date)

**[A branch for the change](#a-branch-for-the-change)**

- [Which branch should my change start from?](#a-branch-for-the-change)
- [Why shouldn't I make my change on `main`?](#a-branch-for-the-change)

**[Opening the pull request](#opening-the-pull-request)**

- [How do I open a pull request from my fork?](#opening-the-pull-request)
- [What does GitHub add to the original repository when I open one?](#what-github-adds-to-the-repository)
- [How do I make merging my pull request close an issue?](#closing-issues-from-a-pull-request)

**[Reviewing a pull request](#reviewing-a-pull-request)**

- [How do I get someone's pull request into my clone to try it?](#reviewing-a-pull-request)
- [Why does `git diff main pr-1` show changes the pull request never made?](#the-diff-a-pull-request-shows)
- [What is `refs/pull/1/merge`?](#the-test-merge)
- [Can I push my fixes to `refs/pull/1/head`?](#the-pull-request-refs-are-read-only)

**[Updating the pull request](#updating-the-pull-request)**

- [The reviewer asked for changes. How do I add them to my pull request?](#updating-the-pull-request)
- [`main` moved on. Should I rebase my pull request or merge `main` into it?](#rewriting-a-pull-request)
- [What does the "Update branch" button do?](#rewriting-a-pull-request)
- [I rebased my pull request. Why is my push rejected, and how do I push it safely?](#rewriting-a-pull-request)
- [As a reviewer, how do I see what changed since I last looked?](#rewriting-a-pull-request)

**[Changing a contributor's branch](#changing-a-contributor-s-branch)**

- [As a maintainer, how do I push a fix onto someone's pull request?](#changing-a-contributor-s-branch)
- [Someone pushed to my pull request's branch. How do I get their commit?](#changing-a-contributor-s-branch)

**[Merging the pull request](#merging-the-pull-request)**

- [What do "Create a merge commit", "Squash and merge" and "Rebase and merge" each do to the history?](#merging-the-pull-request)
- [Why does "Rebase and merge" give new hashes when a plain `git rebase` would change nothing?](#merging-the-pull-request)
- [What message does GitHub give the merge commit?](#merging-the-pull-request)
- [My pull request was squashed. Can I keep working on the same branch?](#after-a-squash)

**[After the merge](#after-the-merge)**

- [My pull request was merged. What do I clean up, here and in my fork?](#after-the-merge)
- [Why won't `git branch -d` delete my branch after a squash or rebase merge?](#after-the-merge)

**[Protected branches and rules](#protected-branches-and-rules)**

- [What can a repository's owner forbid, and what does Git show when a push breaks a rule?](#protected-branches-and-rules)
- [Where do code owners come from?](#protected-branches-and-rules)

**[Secrets and push protection](#secrets-and-push-protection)**

- [GitHub refused my push because it contains a secret. What do I do?](#secrets-and-push-protection)

**[Signing in from Git](#signing-in-from-git)**

- [Where on GitHub do I add an SSH key, or make a token?](#signing-in-from-git)
- [Which permissions does a token need to push?](#signing-in-from-git)

**[Pull requests and their neighbours](#pull-requests-and-their-neighbours)**

- [Does Git itself have anything like a pull request, for use without GitHub?](#a-pull-request-without-a-hosting-service)
- [What is the difference between a fork, a clone and a branch?](#fork-clone-and-branch)
- [Is `gh` part of Git?](#the-github-command-line-tool)

**[Undoing](#undoing)**

- [How do I close a pull request, revert a merged one, or get a deleted branch back?](#undoing)

**[The settings](#the-settings)**

- [Which Git settings help with forks and pull requests?](#the-settings)

</details>

## The steps at a glance

| Step | On GitHub | In Git | Section |
|---|---|---|---|
| fork the repository | the Fork button | nothing | [Forking](#forking) |
| clone your fork | | `git clone <your fork>` | [Cloning your fork](#cloning-your-fork) |
| add the original as a remote | | `git remote add upstream <original>` | [Cloning your fork](#cloning-your-fork) |
| start a branch from the original's `main` | | `git switch -c <branch> upstream/main` | [A branch for the change](#a-branch-for-the-change) |
| commit and push to your fork | | `git commit`, `git push` | [A branch for the change](#a-branch-for-the-change) |
| open the pull request | "Compare & pull request" | | [Opening the pull request](#opening-the-pull-request) |
| respond to reviews | reviews and comments | `git commit`, `git push`; after a rewrite, `git push --force-with-lease` | [Updating the pull request](#updating-the-pull-request) |
| merge | the merge button, by one of three methods | | [Merging the pull request](#merging-the-pull-request) |
| clean up | "Delete branch" | `git fetch --prune`, `git branch -d` | [After the merge](#after-the-merge) |
| keep your fork current | "Sync fork" | `git fetch upstream`, `git merge --ff-only`, `git push` | [Keeping your fork up to date](#keeping-your-fork-up-to-date) |

A contributor who has push access to the original skips the fork: they push the
branch to the original itself and open the pull request from there. Everything
else is the same.

## The example repositories

Nothing in this chapter reaches GitHub. Two bare repositories stand in for it,
named the way GitHub names repositories, owner then project:

| Stand-in | On GitHub it would be | What it is |
|---|---|---|
| `github/ada/atlas.git` | `https://github.com/ada/atlas.git` | Ada's atlas, the original project; Ada is its maintainer |
| `github/bob/atlas.git` | `https://github.com/bob/atlas.git` | Bob's fork of it |

Ada and Bob each have a clone, and each section says whose clone it runs in.
The clones reach the stand-ins by relative paths such as
`../../github/ada/atlas.git`, which keeps the hashes of merge commits the same
on every machine (Chapter 42); against GitHub, the URL would be one of those in
the table, or its SSH form `git@github.com:ada/atlas.git` (Chapter 40). Bob's
commits carry his own name, Bob Brown.

What GitHub does on its own side, such as making the fork or recording a pull
request, was done by hand in the stand-ins, out of sight, and each section says
what. Output that only GitHub produces, such as its messages when it refuses a
push, is quoted from its documentation, never shown as a transcript.

## Forking

On GitHub, the Fork button on a repository's page makes the fork. GitHub's
documentation lists the choices it offers: the owner of the new repository, its
name, a description, and a box, "Copy the DEFAULT branch only"; without it,
every branch is copied. The command-line tool `gh` does the same with
`gh repo fork` ([The GitHub command-line tool](#the-github-command-line-tool)).

Here the fork was made with `git clone --bare`, which copies every branch:

```console
$ git ls-remote github/ada/atlas.git && git ls-remote github/bob/atlas.git
2a3eedbe5732345fc58b754b2d7c52ad63da666b	HEAD
65e4594b8937b2d07a7af075a1914e8dd23c1568	refs/heads/drafts
2a3eedbe5732345fc58b754b2d7c52ad63da666b	refs/heads/main
2a3eedbe5732345fc58b754b2d7c52ad63da666b	HEAD
65e4594b8937b2d07a7af075a1914e8dd23c1568	refs/heads/drafts
2a3eedbe5732345fc58b754b2d7c52ad63da666b	refs/heads/main
```

The two lists are the same: a fork starts as an exact copy, with the same
commits and the same hashes (Chapter 39 explains `git ls-remote`). From then on
it is a repository of its own. GitHub keeps the link between a fork and the
repository it came from, and pull requests go across it, but GitHub moves no
commits between them by itself: when the original gets new commits, the fork
stays where it was until you bring it up to date
([Keeping your fork up to date](#keeping-your-fork-up-to-date)).

## Cloning your fork

GitHub's documentation clones the fork, not the original, and then adds the
original as a second remote called `upstream`. With GitHub's placeholders, its
commands are:

```
git clone https://github.com/YOUR-USERNAME/Spoon-Knife
git remote add upstream https://github.com/ORIGINAL-OWNER/Spoon-Knife.git
```

In Bob's clone of his fork:

```console
$ git remote -v
origin	../../github/bob/atlas.git (fetch)
origin	../../github/bob/atlas.git (push)
$ git remote add upstream ../../github/ada/atlas.git && git fetch upstream
From ../../github/ada/atlas
 * [new branch]      drafts     -> upstream/drafts
 * [new branch]      main       -> upstream/main
$ git remote -v && git branch -a
origin	../../github/bob/atlas.git (fetch)
origin	../../github/bob/atlas.git (push)
upstream	../../github/ada/atlas.git (fetch)
upstream	../../github/ada/atlas.git (push)
* main
  remotes/origin/HEAD -> origin/main
  remotes/origin/drafts
  remotes/origin/main
  remotes/upstream/HEAD -> upstream/main
  remotes/upstream/drafts
  remotes/upstream/main
```

`origin` is Bob's fork, where he can push; `upstream` is Ada's original, where
he cannot. Each has its own remote-tracking branches, so `origin/main` is his
fork's `main` and `upstream/main` the project's (Chapter 41). Cloning the
original instead, with `git clone -o upstream`, and adding the fork as
`origin`, ends in the same two remotes (Chapter 9). The names are only a
convention; they matter because the commands in GitHub's documentation, and in
most instructions you will read, assume them.

### Pulling from one, pushing to the other

A contributor pulls from the original and pushes to the fork. Git can be told
so once, and then `git pull` and `git push` need no names:

```console
$ git config set remote.pushDefault origin && git config set push.default current && git branch -u upstream/main
branch 'main' set up to track 'upstream/main'.
$ git rev-parse --abbrev-ref @{upstream} @{push}
upstream/main
origin/main
```

| Setting | Makes |
|---|---|
| `branch.main.remote` and `.merge`, set by `git branch -u upstream/main` | `git pull` on `main` take from the original, and `git status` compare with it |
| `remote.pushDefault=origin` | `git push` go to the fork, whatever the branch's upstream is (Chapter 43) |
| `push.default=current` | `git push` update the branch of the same name there; and `@{push}` work |

`@{upstream}` is where this branch pulls from and `@{push}` where it pushes to
(Chapter 18). Without `push.default=current`, under the default `simple`,
`git push` still pushes to the fork under the same name, but `@{push}` fails
with "cannot resolve 'simple' push to a single destination"; Chapter 43 shows
that failure and the reason for it. `status.compareBranches`, since Git 2.54,
makes `git status` compare a branch with both (Chapter 10).

This is optional. Without it, name the remote each time: `git pull upstream
main`, `git push origin <branch>`, as GitHub's documentation does.

## Keeping your fork up to date

Ada pushed "Add Africa" to the original. In Bob's clone:

```console
$ git fetch upstream && git status -sb
From ../../github/ada/atlas
   2a3eedb..d03285d  main       -> upstream/main
## main...upstream/main [behind 1]
$ git merge --ff-only upstream/main && git push origin main
Updating 2a3eedb..d03285d
Fast-forward
 maps/africa.txt | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 maps/africa.txt
To ../../github/bob/atlas.git
   2a3eedb..d03285d  main -> main
```

These are the steps GitHub's documentation gives for syncing a fork from the
command line, fetch, merge `upstream/main`, and it adds that syncing locally
does not update the fork on GitHub until you push. `--ff-only` makes sure
`main` only moves forward to the original's commit (Chapter 25); with the
settings of the last section, `git pull --ff-only && git push` does both steps,
and [After the merge](#after-the-merge) uses it.

| Way | Does |
|---|---|
| "Sync fork", then "Update branch", on the fork's page | updates one branch of the fork from the original; when that would conflict, GitHub offers a pull request to resolve it |
| `gh repo sync owner/cli-fork -b BRANCH-NAME` | the same, from GitHub's command-line tool; `--force` overwrites the fork's branch when it cannot be synced cleanly |
| `git fetch upstream`, `git merge --ff-only upstream/main`, `git push origin main` | the same, through your clone, as above |

A fork's `main` only needs updating if you use it. Branches for pull requests
start from `upstream/main` ([A branch for the change](#a-branch-for-the-change)),
so a fork whose `main` is months old does no harm.

Keep your own commits off your fork's `main`: then updating it is always a
fast-forward. If you did commit there, `--ff-only` refuses, and the commits
belong on a branch of their own; Chapter 45 shows how to move them and put
`main` back, after which the fork's `main` needs a `git push --force-with-lease`.

## A branch for the change

Bob's change is a spelling fix. He starts a branch from the original's `main`,
not from his fork's:

```console
$ git switch -c fix-asia upstream/main
Switched to a new branch 'fix-asia'
branch 'fix-asia' set up to track 'upstream/main'.
$ echo Asia > maps/asia.txt && git commit -q -am 'Fix the spelling of Asia' && git push
To ../../github/bob/atlas.git
 * [new branch]      fix-asia -> fix-asia
$ git status -sb
## fix-asia...upstream/main [ahead 1]
```

Starting from a remote-tracking branch made `upstream/main` the new branch's
upstream (Chapter 23); on a terminal the line saying so comes first, and
Chapter 24 explains why it comes second here. The plain `git push` went to the
fork, to a branch of the same name, because of the settings above. `git status` measures the branch
against the project it is meant for: one commit ahead is exactly what the pull
request will propose. Without those settings, `git push -u origin fix-asia`
does the push, and makes `origin/fix-asia` the upstream instead.

One branch per pull request, as in Chapter 49. A pull request follows its
branch: every commit pushed to the branch becomes part of it, which is why a
second change needs a second branch, and why a pull request made from your
fork's `main` would swallow whatever you commit there next.

## Opening the pull request

GitHub's documentation for a pull request from a fork:

1. On the original repository's page, choose "Compare & pull request" on the
   banner above the list of files, and on the page that opens, "compare across
   forks".
2. Choose the base repository and base branch: where the change should go,
   here `ada/atlas` and `main`.
3. Choose the head repository and the compare branch: your fork and your
   branch, here `bob/atlas` and `fix-asia`.
4. Write a title and a description: what the change does and why.
5. On a fork owned by a user, tick "Allow edits from maintainers" if the
   maintainers may push to your branch
   ([Changing a contributor's branch](#changing-a-contributor-s-branch)).
6. Choose "Create pull request", or "Create draft pull request" from its menu
   for work not ready for review.

### What GitHub adds to the repository

Opening the pull request put two refs into the original, which the stand-in
got by hand:

```console
$ git ls-remote upstream 'refs/pull/*'
7bacdc9542dff4527038a9dba523308d3f684930	refs/pull/1/head
1e65d70afc01df3dc2f541e1158874ed9f8a84ef	refs/pull/1/merge
```

| Ref | Points at | Source |
|---|---|---|
| `refs/pull/<number>/head` | the tip of the pull request's branch, updated on every push to it | GitHub's documentation for checking out pull requests |
| `refs/pull/<number>/merge` | a merge of the branch into the base branch that GitHub makes to test it | GitHub's documentation for Actions calls it the pull request merge branch |

The number is the pull request's. The refs live in the original, so anyone who
can read it can fetch a pull request from a fork without adding the fork as a
remote; GitHub's documentation says anyone can work with a previously opened
pull request, and that its commits are in the repository before it is merged.

### Closing issues from a pull request

A pull request's description, or a commit message, can close an issue when it
is merged. GitHub's documentation lists the keywords: `close`, `closes`,
`closed`, `fix`, `fixes`, `fixed`, `resolve`, `resolves`, `resolved`.

| Written | Closes |
|---|---|
| `Fixes #10` | issue 10 in the same repository |
| `Fixes octo-org/octo-repo#100` | issue 100 in another repository |

The documentation adds two conditions. Keywords in a pull request's description
count only when the pull request targets the repository's default branch.
Keywords in a commit message close the issue when that commit reaches the
default branch, but do not link the pull request to it. To Git all of this is
text in a message; Chapter 53 covers conventions for what else a message holds.

## Reviewing a pull request

Ada, meanwhile, pushed "Add Oceania" to `main`. In Ada's clone, where `origin`
is the original:

```console
$ git fetch origin pull/1/head:pr-1
From ../../github/ada/atlas
 * [new ref]         refs/pull/1/head -> pr-1
$ git log --oneline main..pr-1
7bacdc9 Fix the spelling of Asia
```

`pull/1/head:pr-1` copies the pull request's ref into a new local branch,
`pr-1`: the command GitHub's documentation gives, `git fetch origin
pull/ID/head:BRANCH_NAME`, taught with the rest of refspecs in Chapter 44.
`git log main..pr-1` lists the commits the pull request would bring
(Chapter 18). `pr-1` is an ordinary branch: switch to it, build it, test it.

### The diff a pull request shows

```console
$ git diff --stat main pr-1 && git diff --stat main...pr-1
 maps/asia.txt    | 2 +-
 maps/oceania.txt | 1 -
 2 files changed, 1 insertion(+), 2 deletions(-)
 maps/asia.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

The first diff compares the two tips, and since `main` gained Oceania after Bob
branched, it shows Oceania as removed, a change the pull request never made.
The second, with three dots, compares `pr-1` with the commit where it left
`main`, and shows only Bob's change (Chapter 13). GitHub's documentation says
pull requests show this three-dot diff, which keeps showing only the branch's
own changes as the base branch moves on.

### The test merge

```console
$ git fetch -q origin pull/1/merge && git show -s --format=%p FETCH_HEAD && git show -s --format='%h %s' main pr-1
65d514c 7bacdc9
65d514c Add Oceania
7bacdc9 Fix the spelling of Asia
```

`refs/pull/1/merge` is a merge commit whose parents are `main` and the pull
request: what `main` would look like if the pull request were merged now.
`%p` prints a commit's parents (Chapter 17). Building it tests the combination,
not just the branch. GitHub's documentation calls it a test merge commit, made
to check that the pull request can be merged; the stand-in's was made the way a
merge would be, with `git merge-tree` (Chapter 25).

### The pull request refs are read-only

```console
$ git push origin pr-1:refs/pull/1/head
To ../../github/ada/atlas.git
 ! [remote rejected] pr-1 -> refs/pull/1/head (deny updating a hidden ref)
error: failed to push some refs to '../../github/ada/atlas.git'
```

GitHub's documentation says the `refs/pull/` namespace is read-only, and quotes
this rejection, `deny updating a hidden ref`, for a push to it. The message is
Git's own: the server refuses pushes to refs its configuration hides from
`git push`, which is how the stand-in was set up, with `receive.hideRefs`. The
pull request changes only when its branch in the fork does.

## Updating the pull request

Ada's review asked Bob to fix the same spelling in the README. In Bob's clone,
`sed -i` standing in for editing the file:

```console
$ sed -i 's/Aisa/Asia/' README.md && git commit -q -am 'Fix the spelling in the README' && git push
To ../../github/bob/atlas.git
   7bacdc9..5b6cf55  fix-asia -> fix-asia
```

A push to the branch is all it takes: GitHub's documentation of GitHub flow
says the pull request updates itself. New commits keep the review's history
intact, since the commits reviewed so far do not change.

### Rewriting a pull request

`main` had moved on, and Bob rebased the branch onto it:

```console
$ git fetch -q upstream && git rebase upstream/main
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/fix-asia.
$ git push --force-with-lease
To ../../github/bob/atlas.git
 + 5b6cf55...b2c4a2a fix-asia -> fix-asia (forced update)
```

The rebase gave both commits new hashes (Chapter 33), so the fork's branch
could only be replaced, not advanced, and a plain `git push` would have been
rejected. `--force-with-lease` replaces it only if it is still where Bob's
last fetch saw it (Chapter 43): if a maintainer had pushed to his branch in the
meantime ([Changing a contributor's branch](#changing-a-contributor-s-branch)),
the push would be refused instead of throwing their commit away. A terminal
draws the `Rebasing` lines over each other.

In Ada's clone, the reviewer's question is what changed since she last looked:

```console
$ git fetch origin +pull/1/head:pr-1 && git range-diff main pr-1@{1} pr-1
From ../../github/ada/atlas
 + 7bacdc9...b2c4a2a refs/pull/1/head -> pr-1  (forced update)
1:  7bacdc9 = 1:  ced813f Fix the spelling of Asia
-:  ------- > 2:  b2c4a2a Fix the spelling in the README
```

The `+` lets the fetch replace `pr-1` although the new commits do not descend
from the old (Chapter 44). `pr-1@{1}` is where `pr-1` was before, from its
reflog (Chapter 36), and `git range-diff` pairs the old commits with the new
(Chapter 45): the first commit is unchanged apart from its base, marked `=`, and
the second is new. Without it, a rebased pull request asks the reviewer to read
everything again.

The choice between rebasing and merging `main` into the branch is the one in
Chapter 49, with a pull request's own points:

| Compared on | Rebase onto `upstream/main`, then `--force-with-lease` | Merge `upstream/main` into the branch, then `git push` |
|---|---|---|
| The branch's commits | new hashes | kept; a merge commit is added |
| The push | must be forced | an ordinary push |
| For the reviewer | `git range-diff` shows what changed | the commits reviewed so far stay as they were |
| GitHub's "Update branch" button | "Update with rebase" in its menu | what the button does by default |
| In GitHub's documentation | offered, as the button's other choice | recommended, on comparing branches: merge the base branch in frequently |

GitHub's documentation says the "Update branch" button, on the pull request's
page, merges the base branch into the head branch, and that its menu offers to
rebase instead. Either way the change happens on GitHub, in your fork's branch,
so fetch before you commit more, or your next push is rejected. Projects differ
in which they want; a project's contribution guide, if it has one, may say.

Squashing your own commits before the merge, with `git rebase -i` or with
`--fixup` and `--autosquash`, is the same rewrite, pushed the same way
(Chapter 34, Chapter 35).

## Changing a contributor's branch

"Allow edits from maintainers", which Bob ticked, lets anyone with push
access to the original push to his pull request's branch, in his fork. GitHub's
documentation says it applies to forks owned by a user, and that a fork with
GitHub Actions workflows shows it as "Allow edits and access to secrets by
maintainers", with the risk that name describes. In Ada's clone:

```console
$ git remote add bob ../../github/bob/atlas.git && git fetch -q bob && git switch -q -c bob-fix-asia bob/fix-asia
$ sed -i 's/Maps of/Maps of the continents:/' README.md && git commit -q -am 'Reword the README' && git push bob HEAD:fix-asia
To ../../github/bob/atlas.git
   b2c4a2a..596dae7  HEAD -> fix-asia
```

A maintainer adds the contributor's fork as a remote, as Chapter 39's table
suggests for reviewing a colleague's work, makes a local branch from theirs,
and pushes back to the branch of the same name; `HEAD:fix-asia` names it,
because the local branch is called something else (Chapter 43). The pull
request now has Ada's commit on top.

In Bob's clone, `fix-asia` pulls from `upstream/main`, so a plain `git pull`
would not bring Ada's commit. He names the fork's branch:

```console
$ git pull --ff-only origin fix-asia
From ../../github/bob/atlas
 * branch            fix-asia   -> FETCH_HEAD
   b2c4a2a..596dae7  fix-asia   -> origin/fix-asia
Updating b2c4a2a..596dae7
Fast-forward
 README.md | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

Pulling before anything else keeps the next push an ordinary one. Had Bob
fetched, then rebased without taking Ada's commit and pushed with
`--force-with-lease`, the lease would have been satisfied and her commit lost;
[A lease](#ch43-a-lease) in Chapter 43 shows that case, and
`--force-if-includes`, which refuses it.

## Merging the pull request

GitHub offers three merge methods, and a repository's settings choose which
are allowed. In Ada's clone, the pull request as it now stands, and the three
methods made with Git on scratch branches from `main`:

```console
$ git fetch -q origin +pull/1/head:pr-1 && git log --format='%h %an  %s' main..pr-1
596dae7 Ada Lovelace  Reword the README
b2c4a2a Bob Brown  Fix the spelling in the README
ced813f Bob Brown  Fix the spelling of Asia
$ git switch -q -c by-merge main && git merge -q --no-ff -m 'Merge pull request #1 from bob/fix-asia' -m 'Fix the spelling of Asia' pr-1
$ git switch -q -c by-squash main && git merge -q --squash pr-1 && git commit -q -m 'Fix the spelling of Asia'
Squash commit -- not updating HEAD
$ git switch -q -c by-rebase pr-1 && git rebase -q main && git rev-parse --short HEAD && git rebase -q --force-rebase main
596dae7
$ git log --graph --format='%h %an / %cn  %s' main~1..by-merge
*   714f1da Ada Lovelace / Ada Lovelace  Merge pull request #1 from bob/fix-asia
|\  
| * 596dae7 Ada Lovelace / Ada Lovelace  Reword the README
| * b2c4a2a Bob Brown / Bob Brown  Fix the spelling in the README
| * ced813f Bob Brown / Bob Brown  Fix the spelling of Asia
|/  
* 65d514c Ada Lovelace / Ada Lovelace  Add Oceania
$ git log --graph --oneline main~1..by-squash
* d62e23a Fix the spelling of Asia
* 65d514c Add Oceania
$ git log --graph --format='%h %an / %cn  %s' main~1..by-rebase
* c3a6113 Ada Lovelace / Ada Lovelace  Reword the README
* b6252e2 Bob Brown / Ada Lovelace  Fix the spelling in the README
* 9e0f975 Bob Brown / Ada Lovelace  Fix the spelling of Asia
* 65d514c Ada Lovelace / Ada Lovelace  Add Oceania
```

`%an` is a commit's author and `%cn` its committer (Chapter 17).

| GitHub's method | GitHub's documentation says | The same in Git |
|---|---|---|
| Create a merge commit, the default | all of the branch's commits are added to the base branch in a merge commit, made with `--no-ff` | `git merge --no-ff` |
| Squash and merge | the commits are squashed into one, and it is added with a fast-forward | `git merge --squash`, then `git commit` |
| Rebase and merge | the commits are added one by one without a merge commit; unlike `git rebase`, it always updates the committer and makes new hashes, and it drops commits that were empty to begin with | `git rebase --force-rebase`, then a fast-forward |

The merge kept every commit as it was, authors and hashes included. The rebase
shows the difference the documentation describes: the branch already started at
the tip of `main`, so a plain `git rebase` changed nothing, and `HEAD` was still
`596dae7`; `--force-rebase` rewrote the commits anyway, and each now has Ada as
committer, Bob still as author, and a new hash. In the squash, three commits
became one; the documentation lists as squashing's cost that the history loses
who wrote the squashed commits and when. The stand-in's squash commit is simply
Ada's.

The messages: GitHub's documentation says the default merge commit message
holds the pull request's number and title, with the example `Merge pull request
#123 from patch-1`; the stand-in's follows it, with the branch as
`owner/branch` and the title as a second paragraph. For a squash, the default
is the commit's own title and message when the pull request has one commit,
and the pull request's title and a list of its commits when it has more. The
repository's settings can change either default, and the documentation says
the squash message can be edited when merging.

Ada chose the default, a merge commit, and pushed it as GitHub would record it:

```console
$ git merge -q --no-ff -m 'Merge pull request #1 from bob/fix-asia' -m 'Fix the spelling of Asia' pr-1 && git push -q
```

### After a squash

Had Ada squashed instead, this is what the pull request's branch would have
looked like next to the squashed `main`:

```console
$ git log --oneline by-squash..pr-1
596dae7 Reword the README
b2c4a2a Fix the spelling in the README
ced813f Fix the spelling of Asia
```

As far as Git can tell, none of the pull request's commits are in the squashed
`main`, so a later pull request from the same branch would list them all again,
and its merge would be more likely to conflict. That is the reason GitHub's
documentation gives for not reusing a branch after a squash merge. After a
squash or a rebase merge, start the next change on a new branch from the
updated `upstream/main`.

## After the merge

GitHub's merged pull request offers a "Delete branch" button, and a repository
can be set to delete head branches automatically. Bob's branch was deleted from
his fork that way. In Bob's clone:

```console
$ git fetch --prune origin
From ../../github/bob/atlas
 - [deleted]         (none)     -> origin/fix-asia
$ git switch -q main && git pull --ff-only && git push
From ../../github/ada/atlas
   65d514c..323f7d1  main       -> upstream/main
Updating d03285d..323f7d1
Fast-forward
 README.md        | 2 +-
 maps/asia.txt    | 2 +-
 maps/oceania.txt | 1 +
 3 files changed, 3 insertions(+), 2 deletions(-)
 create mode 100644 maps/oceania.txt
To ../../github/bob/atlas.git
   d03285d..323f7d1  main -> main
$ git branch -d fix-asia
Deleted branch fix-asia (was 596dae7).
```

`--prune` removed `origin/fix-asia`, whose branch no longer exists in the fork
(Chapter 41). `git pull --ff-only` brought `main` up to the original's, merge
included, and `git push` updated the fork's `main`, both without names because
of the triangular settings. `git branch -d` deleted `fix-asia` because its
commits are in `upstream/main`, its upstream (Chapter 23).

After a squash or a rebase merge, the same `git branch -d` refuses with "not
fully merged", because the commits in `main` are new ones (Chapter 49). Check
that the pull request says it was merged, then delete with `git branch -D`.

## Protected branches and rules

The owner of a repository can protect branches, with branch protection rules or
with rulesets, the newer form. GitHub's documentation lists what a protected
branch can require:

| Rule | Effect |
|---|---|
| Require a pull request, and approving reviews, before merging | no change reaches the branch without the review; optionally, new commits dismiss earlier approvals |
| Require deployments to succeed | the change must deploy successfully to chosen environments first |
| Require status checks to pass | named automatic checks must succeed on the latest commit before merging |
| Require conversation resolution | every review comment must be resolved |
| Require signed commits | only signed and verified commits may be pushed (Chapter 68) |
| Require linear history | no merge commits may be pushed, so pull requests are squashed or rebased |
| Require a merge queue | merges go through a queue that tests each against the latest branch |
| Lock the branch | the branch is read-only |
| Do not allow bypassing | the rules apply to administrators too |
| Restrict who can push | only chosen people, teams or apps may push |
| Allow force pushes, allow deletions | off by default: the documentation says each rule disables force pushes and prevents deletion unless allowed |

A push that breaks a rule is refused by GitHub's server, which says why on
lines starting with `remote:` (Chapter 43). GitHub's documentation on required
status checks quotes this one:

```
remote: error: GH006: Protected branch update failed for refs/heads/main.
remote: error: Required status check "ci-build" is failing
```

A plain Git server does part of this with `receive.denyNonFastForwards`,
`receive.denyDeletes` (Chapter 43) and hooks (Chapter 67).

A repository can name *code owners* in a file called `CODEOWNERS`, in `.github/`,
at the top, or in `docs/`, looked for in that order. Each line is a pattern,
matched much as in `.gitignore` (Chapter 16), followed by `@user` or `@org/team`
names, and the last matching line wins. GitHub then asks the owners for a review
whenever a pull request changes their files, and a protection rule can require
one owner's approval. The file that counts is the one on the pull request's base
branch.

## Secrets and push protection

GitHub's secret scanning looks for things shaped like credentials, and push
protection refuses a push that contains one. The documentation says push
protection for users is on by default for your account, and blocks your pushes
of the secrets it recognises to public repositories. The refusal lists, on
`remote:` lines, the kind of secret and each commit and file line where it
appears. The first three rows are the documentation's:

| The secret is | What to do | Covered in |
|---|---|---|
| in the last commit | remove it, `git commit --amend --all`, push again | Chapter 29 |
| in an earlier commit | find the first commit with it, `git rebase -i <commit>~1`, mark that commit `edit`, remove the secret, `git commit --amend`, `git rebase --continue`, push again | Chapter 34 |
| not really a secret | open the link in the refusal as the same user, choose a reason: used in tests, a false positive, or to be fixed later; push again within three hours | |
| already public, pushed earlier or elsewhere | a refused push no longer helps: rotate the secret and remove it from the history | Chapter 37 |

## Signing in from Git

Chapter 40 covers how Git authenticates; this is where GitHub keeps what it
needs, by GitHub's documentation:

| For | On GitHub | Notes |
|---|---|---|
| an SSH key | your profile picture, Settings, then "SSH and GPG keys" under Access; "New SSH key" | give it a title, choose "Authentication Key", paste the `.pub` file's contents |
| a fine-grained personal access token | Settings, Developer settings, Personal access tokens, Fine-grained tokens, "Generate new token" | choose the owner, the repositories, an expiry, and permissions; pushing needs Contents set to read and write |
| a classic personal access token | the same, under Tokens (classic) | the `repo` scope for repositories from the command line |

A token is typed where Git asks for the password over HTTPS. GitHub's
documentation recommends fine-grained tokens over classic ones, but says they
cannot be used for contributing to public repositories where you are not a
member, or as an outside collaborator. Pushing to your own fork is pushing to
your own repository.

## Pull requests and their neighbours

### A pull request without a hosting service

Git has its own form of the request. `gitworkflows` describes a contributor
publishing a branch and asking the maintainer, by mail, to pull it, and
`git request-pull` writes that message. In Bob's clone, with a second change
pushed to his fork:

```console
$ git switch -q -c add-rivers upstream/main && echo Nile > maps/rivers.txt && git add maps && git commit -q -m 'Add rivers' && git push -q
$ git request-pull upstream/main ../../github/bob/atlas.git add-rivers
The following changes since commit 323f7d15c52485b08b641c2bacf61709497a94c0:

  Merge pull request #1 from bob/fix-asia (2026-01-05 22:00:00 +0000)

are available in the Git repository at:

  ../../github/bob/atlas.git add-rivers

for you to fetch changes up to 1e128dd68e6e312925ca17bc4ae5f829d4b7cd7f:

  Add rivers (2026-01-05 23:00:00 +0000)

----------------------------------------------------------------
Bob Brown (1):
      Add rivers

 maps/rivers.txt | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 maps/rivers.txt
```

It prints the request: where the branch starts, where to fetch it, the commits
and the files changed. Sending it, by mail or otherwise, is up to you; the
maintainer merges with `git pull <URL> <branch>` (Chapter 42). Chapter 61
covers `git request-pull` in full, and the patch workflow beside it.

| Compared on | GitHub pull request | `git request-pull` | Patches by mail | Merge request on GitLab |
|---|---|---|---|---|
| Where the change lives | a branch in your fork or in the original | a branch in any repository the maintainer can read | in the mail itself | a branch in your fork or in the original |
| Where it is discussed | the pull request page | by mail | by mail, replying to each patch | the merge request page |
| How it is merged | a button, by one of three methods | `git pull` | `git am` | a button |
| Needs a hosting service | yes | no | no | yes |
| Covered in | this chapter | Chapter 61 | Chapter 61 | Chapter 51 |

### Fork, clone and branch

| Compared on | Fork | Clone | Branch |
|---|---|---|---|
| Is | a copy of a repository, on GitHub | a copy of a repository, on your computer | a line of work inside one repository |
| Made with | the Fork button, `gh repo fork` | `git clone` | `git branch`, `git switch -c` |
| A Git concept | no; to Git it is just another repository | yes (Chapter 9) | yes (Chapter 23) |
| Can you push to it | yes, it is yours | it is yours; others' clones cannot see it | where you push it, others can |
| Kept up to date by | you: fetch from the original, push to the fork | `git fetch`, `git pull` | merging or rebasing |

### The GitHub command-line tool

`gh`, GitHub's command-line tool, is a separate program that talks to GitHub,
not part of Git. The commands GitHub's documentation gives for this chapter's
steps:

| Command | Does |
|---|---|
| `gh repo fork REPOSITORY` | fork; `--clone=true` also clones it, `--remote=true` adds a remote for it |
| `gh repo sync owner/cli-fork -b BRANCH-NAME` | update the fork's branch from the original; `--force` overwrites it |
| `gh pr checkout PULL-REQUEST` | check out a pull request locally |

Everything `gh` does to your repository is ordinary Git, as the rest of this
chapter shows.

## Undoing

| To undo | On GitHub | In Git |
|---|---|---|
| an open pull request | "Close pull request", below the comment box, with the option to delete the branch | nothing; the branch is untouched unless you delete it |
| a pull request's last push | nothing to press: the pull request follows its branch | `git push --force-with-lease origin <old>:<branch>`, with `<old>` from the reflog (Chapter 36) |
| a merged pull request | "Revert", which opens a new pull request reverting the merge commit; it needs write access | `git revert -m 1 <merge>` (Chapter 31); after a squash, `git revert <commit>` |
| a deleted head branch | "Restore branch" on the closed pull request, when no open pull request uses the branch | your clone's branch, or its last commit from the reflog (Chapter 36), pushed again |

GitHub's documentation notes that reverting through its button may fail if the
revert conflicts, or if the pull request was not merged on GitHub, and then you
revert the individual commits yourself.

## The settings

| Setting | Does | Covered in |
|---|---|---|
| `remote.pushDefault` | the remote `git push` uses, here your fork | [Pulling from one, pushing to the other](#pulling-from-one-pushing-to-the-other), Chapter 43 |
| `branch.<name>.pushRemote` | the same, for one branch | Chapter 43 |
| `push.default` | which branch a push updates; `current` for the same name, and for `@{push}` | [Pulling from one, pushing to the other](#pulling-from-one-pushing-to-the-other), Chapter 43 |
| `push.autoSetupRemote` | the first push of a new branch sets its upstream | Chapter 43 |
| `status.compareBranches` | `git status` compares with `@{upstream}`, `@{push}` or both | Chapter 10 |
| `fetch.prune` | every fetch removes remote-tracking branches deleted on the server | Chapter 41 |
| `remote.<name>.fetch` | add `+refs/pull/*/head:refs/remotes/origin/pr/*` to fetch every pull request | Chapter 44 |
| `url.<base>.insteadOf` | use SSH for every `https://github.com/` URL | Chapter 40 |
| `receive.hideRefs` | on a server: hide refs from pushes, and refuse updates to them | [The pull request refs are read-only](#the-pull-request-refs-are-read-only) |

> **Since Git 2.54.** `status.compareBranches`. **Since Git 2.46.**
> `git config set`; on an older Git, `git config remote.pushDefault origin`
> (Chapter 3).
