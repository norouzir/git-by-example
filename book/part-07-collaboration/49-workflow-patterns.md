# Chapter 49. Workflow Patterns

## What it is

A workflow is what a team agrees about its branches: which ones exist and for
how long, where a new piece of work starts, who commits or pushes to which, and
how finished work reaches the branch everyone shares. Git has no command for it
and enforces none of it. The same `git switch`, `git merge`, `git rebase` and
`git push` serve every workflow; what differs is which of them a team uses, on
which branches, in which order, and so what the history looks like afterwards.

The workflows in this chapter have names, because people describe them in
articles and hosting services build on them: GitHub flow, Git flow,
trunk-based development, and the workflow Git's own developers describe in its
documentation, `gitworkflows`. Each is a set of choices from the same few
questions, and the chapter shows each choice as a history you can read. The
one question it answers is: *how should the people on a project combine their
work, and what will the history look like if they do it this way?*

| Term | Means |
|---|---|
| *workflow*, *branching model* | a team's agreement on branches and how work moves between them |
| *main branch*, *trunk*, *mainline* | the branch everyone's work ends up on: `main`, `master` or `trunk` |
| *topic branch*, *feature branch* | a short-lived branch for one piece of work, deleted once it is merged |
| *long-running branch* | a branch that lives as long as the project, such as `main`, `develop` or `maint` |
| *integration branch* | a long-running branch whose commits are mostly merges of topic branches; Git's documentation uses the term |
| *release branch* | a branch for preparing, or for fixing, one release |
| *hotfix* | an urgent fix to the version already released |
| *first parent* | the parent a merge commit records first: the branch that was checked out when it was made (Chapter 25) |
| *first-parent history* | the commits reached by following only first parents, which `git log --first-parent` shows (Chapter 17) |
| *land* | reach the main branch; a branch lands by a merge, a squash or a rebase |
| *pull request* | a request, on a hosting service such as GitHub, to merge a branch, with a page where it is reviewed first (Chapter 50) |
| *feature flag* | a setting in the program that turns unfinished code off, so it can be merged before it is finished; not a Git feature |

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What is a workflow, and does Git make me use one?](#what-it-is)

**[The patterns at a glance](#the-patterns-at-a-glance)**

- [What workflows are there, and how do they differ?](#the-patterns-at-a-glance)

**[The example repositories](#the-example-repositories)**

- [What repositories do the examples use?](#the-example-repositories)

**[Everyone on one branch](#everyone-on-one-branch)**

- [Can a team just commit to `main` and push?](#everyone-on-one-branch)
- [My push was rejected because a colleague pushed first. Should I pull with a merge or with a rebase?](#everyone-on-one-branch)
- [After I pulled and pushed, `git log --first-parent` shows my colleague's commit as a side branch. Why?](#everyone-on-one-branch)

**[Topic branches](#topic-branches)**

- [Why make a branch for every piece of work?](#topic-branches)
- [Which branch should a new topic start from?](#topic-branches)
- [How do I see which branches are finished and can be deleted?](#finishing-a-topic)
- [How do I delete a finished branch here and on the server?](#finishing-a-topic)
- [`main` moved on while I worked on my branch. Should I merge `main` into it, rebase it, or leave it?](#keeping-a-topic-up-to-date)
- [My topic needs another topic that is not merged yet. What do I do?](#keeping-a-topic-up-to-date)
- [What should I call my branches?](#naming-branches)

**[How a finished branch lands](#how-a-finished-branch-lands)**

- [What does the history look like if a branch is merged, squashed, rebased or fast-forwarded?](#four-ways-to-land)
- [Which way keeps the branch visible in the history?](#four-ways-to-land)
- [Why can't I delete my branch after it was squashed into `main`?](#what-each-way-leaves-behind)
- [How can I tell whether my commits are in `main` when their hashes changed?](#what-each-way-leaves-behind)
- [Which merge brought a given commit into `main`?](#what-each-way-leaves-behind)
- [How do I undo a whole feature later, under each way?](#what-each-way-leaves-behind)
- [Which way works best with `git bisect` and `git blame`?](#what-each-way-leaves-behind)

**[GitHub flow](#github-flow)**

- [What is GitHub flow?](#github-flow)

**[Trunk-based development](#trunk-based-development)**

- [What is trunk-based development, and how short is a short-lived branch?](#trunk-based-development)
- [How can unfinished work be merged into the trunk?](#trunk-based-development)
- [In trunk-based development, where is a bug in a release fixed?](#release-branches-cut-from-the-trunk)
- [How do I check that every fix on a release branch is also on the trunk?](#release-branches-cut-from-the-trunk)

**[Environment branches](#environment-branches)**

- [What are environment branches, such as `production`?](#environment-branches)
- [How do I see what has not been deployed yet?](#environment-branches)

**[Git flow](#git-flow)**

- [What branches does Git flow use, and what is each for?](#git-flow)
- [Why does `git flow init` say "flow is not a git command"?](#git-flow)
- [What are the exact commands for a feature, a release and a hotfix in Git flow?](#the-steps-of-git-flow)
- [What does a Git flow history look like?](#the-steps-of-git-flow)
- [Is Git flow still recommended?](#is-git-flow-still-recommended)

**[Git's own workflow](#git-s-own-workflow)**

- [How do Git's own developers organise their branches?](#git-s-own-workflow)
- [What are `maint`, `master`, `next` and `seen` for?](#git-s-own-workflow)
- [How do I test several topics together without merging them anywhere permanent?](#topics-and-a-throw-away-integration-branch)
- [How do I drop a topic that turned out to be bad, after it was merged for testing?](#topics-and-a-throw-away-integration-branch)
- [How does a topic move from testing to the release, without bringing everything else along?](#graduation-and-merging-upwards)
- [Where should a fix be committed, and how does it reach every branch?](#graduation-and-merging-upwards)
- [How do I check that the next release has every fix from the maintenance branch?](#graduation-and-merging-upwards)

**[Between repositories](#between-repositories)**

- [How do people work together when they cannot all push to one repository?](#between-repositories)

**[Making a workflow stick](#making-a-workflow-stick)**

- [Can Git make everyone follow the workflow?](#making-a-workflow-stick)
- [How do I make every merge a merge commit, or forbid them?](#making-a-workflow-stick)

**[The workflows compared](#the-workflows-compared)**

- [What is the difference between Git flow, GitHub flow and trunk-based development?](#the-workflows-compared)
- [Where does each workflow put a fix for a released version?](#the-workflows-compared)

**[Choosing a workflow](#choosing-a-workflow)**

- [Which workflow should my project use?](#choosing-a-workflow)

**[The settings](#the-settings)**

- [Which settings support a workflow?](#the-settings)

</details>

## The patterns at a glance

| Pattern | Long-running branches | Where work is done | How it reaches the main branch | Section |
|---|---|---|---|---|
| everyone on one branch | `main` | on `main` itself | pull, then push | [Everyone on one branch](#everyone-on-one-branch) |
| topic branches | `main` | a branch per piece of work | merged, squashed or rebased when finished | [Topic branches](#topic-branches) |
| GitHub flow | `main`, deployable at all times | a branch per piece of work | a pull request, reviewed and merged | [GitHub flow](#github-flow) |
| trunk-based development | the trunk | on the trunk, or a branch of a day or two | small, frequent merges; unfinished code behind feature flags | [Trunk-based development](#trunk-based-development) |
| environment branches | `main`, plus `production` and the like | a branch per piece of work | merged into `main`, then `main` into each environment | [Environment branches](#environment-branches) |
| Git flow | `main` for releases, `develop` for development | feature branches from `develop` | merged into `develop`; release and hotfix branches into both | [Git flow](#git-flow) |
| Git's own | `maint`, `master`, `next`, `seen` | a topic branch from the oldest branch that needs it | merged into `seen` and `next` to be tested, then into `master` or `maint` | [Git's own workflow](#git-s-own-workflow) |
| forks and patches | each person's own repository | anywhere in their own repository | the maintainer pulls, or applies mailed patches | [Between repositories](#between-repositories) |

Every pattern after the first uses topic branches; they differ in how many
long-running branches they add, where releases are made, and how a finished
branch lands.

## The example repositories

```console
$ git remote -v
origin	../server/atlas.git (fetch)
origin	../server/atlas.git (push)
$ git log --oneline --graph --all --decorate
* 0fe19df (HEAD -> main, origin/main, origin/HEAD) Add Europe
* 0dd6887 Start the atlas
```

The atlas, on a bare repository standing in for the team's server, with clones
for Ada and Bob. Every command runs in Ada's clone, and each section says what
Bob pushed in the meantime. The clones reach the server by the relative path
`../server/atlas.git`, which keeps the hashes of merge commits the same on
every machine (Chapter 42). Two later sections use repositories of their own:
[Git flow](#git-flow) and [Git's own workflow](#git-s-own-workflow).

## Everyone on one branch

The simplest workflow has no branches but `main`: everyone commits on it and
pushes. Bob pushed "Add Asia"; Ada, meanwhile, committed "Add Africa" and "Add
Madagascar":

```console
$ git push
To ../server/atlas.git
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs to '../server/atlas.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
$ git pull --no-rebase
From ../server/atlas
   0fe19df..30ed75e  main       -> origin/main
Merge made by the 'ort' strategy.
 maps/asia.txt | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 maps/asia.txt
$ git log --oneline --graph
*   c6f281b Merge branch 'main' of ../server/atlas
|\  
| * 30ed75e Add Asia
* | db7a2c9 Add Madagascar
* | 23547ae Add Africa
|/  
* 0fe19df Add Europe
* 0dd6887 Start the atlas
$ git log --oneline --first-parent
c6f281b Merge branch 'main' of ../server/atlas
db7a2c9 Add Madagascar
23547ae Add Africa
0fe19df Add Europe
0dd6887 Start the atlas
```

The push was refused because the server had a commit Ada did not (Chapter 43).
Pulling with a merge made it pushable, and it also turned the history inside
out. On the server, `main` went `Add Europe`, `Add Asia`. Ada's merge was made
while her own `main` was checked out, so her commits are its first parent and
Bob's is the second: pushed, `git log --first-parent`, which many people read
as "what happened on `main`", would show Ada's commits as the main line and
Bob's, which was on `main` first, as a side branch. Git's own documentation
describes exactly this in `howto/keep-canonical-history-correct`, installed with
Git: to everyone who saw the server's `main` before the push, the history now
looks backwards.

```console
$ git reset -q --hard ORIG_HEAD && git pull --rebase
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/main.
$ git log --oneline --graph
* 3d3e338 Add Madagascar
* b2eb37a Add Africa
* 30ed75e Add Asia
* 0fe19df Add Europe
* 0dd6887 Start the atlas
$ git push -q
```

`ORIG_HEAD` is where `main` was before the pull (Chapter 30), so the reset undid
the merge. Pulling with a rebase put Ada's two commits after Bob's, with new
hashes, in the order the server received them, and the push went through. A
terminal draws the two `Rebasing` lines over each other; they end with a
carriage return, not a new line.

This workflow is what `pull.rebase=true` is for (Chapter 42), and it suits one
person or a small team whose commits are each complete. It has the costs the
rest of this chapter avoids: unfinished work cannot be committed without
reaching everyone at the next push, each person's pushes race everyone
else's (Chapter 45), and nothing in the history groups the commits of one piece
of work.

## Topic branches

Ada made two commits on a new branch, `oceania`, and Bob pushed a branch
`americas` and one more commit on `main`:

```console
$ git fetch -q && git switch -q main && git merge -q --ff-only
$ git merge -q --no-ff --no-edit oceania
$ git merge -q --no-ff --no-edit origin/americas
$ git log --oneline --graph -9
*   f49aef4 Merge remote-tracking branch 'origin/americas'
|\  
| * 3c20e1e Add the Americas
* |   cd942e1 Merge branch 'oceania'
|\ \  
| * | 897b1f0 Add New Zealand
| * | 68c6176 Add Australia
| |/  
* / 39f2a4b Add Antarctica
|/  
* 3d3e338 Add Madagascar
* b2eb37a Add Africa
* 30ed75e Add Asia
$ git log --oneline --first-parent -4
f49aef4 Merge remote-tracking branch 'origin/americas'
cd942e1 Merge branch 'oceania'
39f2a4b Add Antarctica
3d3e338 Add Madagascar
```

Ada's two commits, "Add Australia" and "Add New Zealand", were made on
`oceania` while `main` stayed where it was. When the work was finished, she
brought `main` up to date with a fast-forward, and merged each topic with
`--no-ff`, which makes a merge commit even when a fast-forward was possible
(Chapter 25). `git log --first-parent` now reads as a list of what happened to
`main`: one line per piece of work, whoever did it.

`gitworkflows`, installed with Git, states the rule: make a side branch for
every topic, whether a feature or a bug fix, and start it at the oldest
integration branch you will eventually want to merge it into. For a project
with only `main`, that is `main`. What the rule buys:

- Unfinished work can be committed, and even pushed as its own branch, without
  reaching anyone's `main`.
- A branch only you push to cannot diverge because of other people's pushes
  (Chapter 45).
- A piece of work that turns out wrong is dropped by not merging it, instead of
  reverting its commits one by one on `main`, which the same documentation
  calls a source of confusing histories.
- Each topic can be reviewed on its own, which is what a pull request does
  (Chapter 50).

### Finishing a topic

```console
$ git branch --merged && git branch -r --merged
* main
  oceania
  origin/HEAD -> origin/main
  origin/americas
  origin/main
$ git branch -d oceania && git push -q origin main :americas
Deleted branch oceania (was 897b1f0).
```

`--merged` lists branches whose commits are all in `HEAD`, so every branch it
lists is finished and can be deleted (Chapter 23). The push sent the merges and
deleted `americas` on the server in one command: `:americas`, an empty source,
means delete (Chapter 44). Deleting finished branches is part of the workflow:
the list of branches is then the list of work still going on.

### Keeping a topic up to date

While a topic is being written, `main` moves on. There are three things to do
about it, and the sources disagree on which:

| Approach | Result | Said by |
|---|---|---|
| leave the topic alone until it is merged | the merge combines both; the topic contains only its own work | `gitworkflows`: merge `main` into a topic only for a good reason, such as a change in `main` that the topic needs, or a topic that no longer merges cleanly |
| merge `main` into the topic now and then | the topic gains merge commits of `main` | GitHub's documentation on comparing branches recommends it, so a pull request's diff stays easy to read (Chapter 50) |
| rebase the topic onto `main` | the topic's commits get new hashes on top of `main` | fine while nobody else has the commits; otherwise the rule of Chapter 28 applies |

`gitworkflows` gives the reason for its rule: a topic that has merged `main` into
itself many times no longer contains one well-separated change, and whoever
later reads the history of a file has to work out whether each of those merges
touched it. A topic that needs another topic still under way can merge that
topic when it needs it, which the same document allows; a chain of topics each
started on the one before is rebased all at once with `--update-refs`
(Chapter 33).

### Naming branches

Git allows any valid branch name (Chapter 23), and each workflow brings a
convention:

| Convention | Example | Used by |
|---|---|---|
| a short description | `oceania`, `fix-login` | GitHub's documentation of GitHub flow asks for a short, descriptive name |
| a kind, a slash, a description | `feature/search`, `fix/login` | many teams; the slash groups branches in `git branch --list 'feature/*'` |
| the author's initials, a slash, a description | `ab/fix-asia` | Git's own project; `gitworkflows` writes `ai/topic` |
| a fixed prefix for the workflow's own branches | `release-1.2`, `hotfix-1.2.1` | Git flow |

```console
$ git branch fix/asia && git branch fix
fatal: cannot lock ref 'refs/heads/fix': 'refs/heads/fix/asia' exists; cannot create 'refs/heads/fix'
```

A name with a slash is a path in `refs/heads/`, so a branch `fix/asia` rules out
a branch called `fix`, just as a tag `v1.2` rules out `v1.2/rc1` (Chapter 47).
Choose between prefixes and plain names before the first branch is made.

## How a finished branch lands

When a topic is finished, it can reach `main` in four ways, and the choice
decides what the history of `main` looks like. Ada's `rivers` branch has two
commits, and `main` has moved on by one since it started:

### Four ways to land

```console
$ git log --oneline --graph --all -5
* eee8ab2 Add the Arctic
| * 0a2e2d5 Add the Amazon
| * bee7d9c Add the Nile
|/  
*   f49aef4 Merge remote-tracking branch 'origin/americas'
|\  
| * 3c20e1e Add the Americas
$ git switch -q -c by-merge main && git merge -q --no-ff --no-edit rivers
$ git switch -q -c by-squash main && git merge -q --squash rivers && git commit -q -m 'Add rivers'
Automatic merge went well; stopped before committing as requested
Squash commit -- not updating HEAD
$ git switch -q -c by-rebase rivers && git rebase -q main
$ git switch -q -c by-ff main~1 && git merge -q rivers
$ git log --oneline --graph main~1..by-merge
*   9a7d535 Merge branch 'rivers' into by-merge
|\  
| * 0a2e2d5 Add the Amazon
| * bee7d9c Add the Nile
* eee8ab2 Add the Arctic
$ git log --oneline --graph main~1..by-squash
* e693d32 Add rivers
* eee8ab2 Add the Arctic
$ git log --oneline --graph main~1..by-rebase
* abffac9 Add the Amazon
* fbf4b5f Add the Nile
* eee8ab2 Add the Arctic
$ git log --oneline --graph -3 by-ff
* 0a2e2d5 Add the Amazon
* bee7d9c Add the Nile
*   f49aef4 Merge remote-tracking branch 'origin/americas'
|\  
```

Each way was made on a scratch branch standing in for `main`, so the merge's
message names `by-merge`; made on `main`, it would read `Merge branch 'rivers'`
(Chapter 25).

| Way | Commands | What `main` gains | The topic's commits |
|---|---|---|---|
| merge commit | `git merge --no-ff` | the topic's commits and a merge commit joining them | kept, same hashes |
| squash | `git merge --squash`, then `git commit` | one new commit with all of the topic's changes | not in `main` at all |
| rebase, then fast-forward | `git rebase main` on the topic, then `git merge --ff-only` | copies of the topic's commits in a line | replaced by copies with new hashes |
| fast-forward | `git merge`, when `main` has not moved | the topic's commits in a line | kept, same hashes |

The last row happened only because `by-ff` started where `rivers` did, before
"Add the Arctic": a plain `git merge` fast-forwards whenever it can, and then
nothing in the history says a branch existed. When `main` has moved on, as
here, a fast-forward is impossible unless the topic is rebased first, which is
the third row. GitHub offers the first three as its merge methods (Chapter 50).

### What each way leaves behind

```console
$ git log --oneline --first-parent main..by-merge && echo --- && git log --oneline --first-parent main..by-rebase && echo --- && git log --oneline --first-parent main..by-squash
9a7d535 Merge branch 'rivers' into by-merge
---
abffac9 Add the Amazon
fbf4b5f Add the Nile
---
e693d32 Add rivers
$ git branch --contains rivers
* by-ff
  by-merge
  rivers
$ git cherry -v by-rebase rivers && git cherry -v by-squash rivers
- bee7d9cd5285857008ba0c3c49375f52a6b83a06 Add the Nile
- 0a2e2d51ad0685e4c3225a699c46fa39210ccd7b Add the Amazon
+ bee7d9cd5285857008ba0c3c49375f52a6b83a06 Add the Nile
+ 0a2e2d51ad0685e4c3225a699c46fa39210ccd7b Add the Amazon
$ git switch -q by-squash && git branch -d rivers
error: the branch 'rivers' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D rivers'
hint: Disable this message with "git config set advice.forceDeleteBranch false"
$ git log --oneline --ancestry-path=rivers~1 --merges rivers~1..by-merge
9a7d535 Merge branch 'rivers' into by-merge
```

After a merge, the first-parent history has one line for the whole topic;
after a rebase, one line per commit; after a squash, one line and one commit.
`git branch --contains rivers` lists only the branches that have `rivers`'s own
commits, the merge and the fast-forward: the rebase and the squash put new
commits into their branches, and as far as Git's history is concerned, `rivers`
is merged into neither. So `git branch -d` refuses to delete it after a squash,
and `--merged` does not list it (Chapter 23).

`git cherry` compares changes instead of hashes (Chapter 32). A `-` means an
equivalent commit is already in the first branch, so the rebased copies were
recognised; a `+` means none is, which is what a squash of two commits gives,
because the squash commit is equivalent to neither on its own. After a squash,
the evidence that a topic has landed is outside Git: the pull request that says
"merged", or reading the diff.

The last command answers "which merge brought 'Add the Nile' into this
branch?". `--ancestry-path=<commit>` keeps only commits descended from it, and
`--merges` only merges (Chapter 17). Under a merge policy that names every
topic; under the other three there is no merge to find.

| Later, you want to | After merge commits | After rebase and fast-forward | After squashes |
|---|---|---|---|
| read `main` one topic at a time | `git log --first-parent` | not possible; commits of one topic are not grouped | `git log`, one commit per topic |
| undo a whole topic | `git revert -m 1 <merge>`, one commit (Chapter 31) | revert each of its commits, which you first have to find | `git revert <commit>` |
| find the topic that changed a line | `git blame` names the commit; the merge above finds the topic | `git blame` names the commit | `git blame` names the squash commit, the whole topic |
| find a bug with `git bisect` | down to the commit; `--first-parent` finds the merge first (Chapter 20) | down to the commit | down to the squash commit, however big the topic was |
| delete the topic branch | `git branch -d` | `-d` only if you rebased it yourself; after a server's rebase, `-D` | `git branch -D` |

Git's own howto `keep-canonical-history-correct` sets out three schools of
thought about the main branch: a strictly linear history, with rebasing; merges
allowed but first parents not cared about; and a main branch whose every
first-parent commit completes one topic, either a merge of it or a single
commit. It places Git itself in the third.

## GitHub flow

GitHub's documentation describes GitHub flow as a lightweight workflow built on
branches, in six steps:

| Step | In Git | On GitHub |
|---|---|---|
| create a branch, with a short, descriptive name | `git switch -c <branch>` | |
| make changes, committing each with a descriptive message | `git commit`, `git push` | |
| create a pull request, saying what the change does and why | | the pull request page |
| address review comments with more commits | `git commit`, `git push`; the pull request updates itself | reviews |
| merge the pull request | | the merge button |
| delete the branch | `git branch -d`, `git fetch --prune` | the delete button |

It is the topic-branch workflow of [Topic branches](#topic-branches), with a
pull request as the place where each branch is reviewed and merged, and one
long-running branch, `main`. GitHub's page does not mention deployment. Scott
Chacon's post that first described GitHub flow, in August 2011, did: its first
rule is that anything in the main branch (then `master`) is deployable, and its
last, that once a branch is merged it should be deployed immediately. The Git
side of every step is in Chapter 50. Both were read in September 2026.

## Trunk-based development

Trunk-based development is described on trunkbaseddevelopment.com as a model in
which developers work on a single branch, the trunk, and resist any pressure to
create other long-lived development branches. Checked in September 2026, the
site says:

- Very small teams may commit straight to the trunk; larger ones use
  short-lived feature branches, for review and for automatic builds.
- A short-lived branch has one developer, or two pairing, and lasts a couple of
  days at most; longer, and it risks becoming the long-lived branch the model
  exists to avoid.
- Feature flags belong in day-to-day development, so that work can be merged
  into the trunk before it is released, and the order of releases can change.
  Git has no part in them: a feature flag is a setting in the program itself.
- A release is made from the trunk, or from a release branch cut from the trunk
  just in time.

In Git terms it is the topic-branch workflow with very short topics, landing by
any of the [four ways](#four-ways-to-land), plus release branches.

### Release branches cut from the trunk

Ada cut `release-1.0` from `main` and pushed it. `main` then got "Add Iceland"
and a fix to the Asia map, commit `0ef3672`, which the release needs too:

```console
$ git switch -q -c release-1.0 && git push -q -u origin release-1.0 && git switch -q main
$ git switch -q release-1.0 && git cherry-pick -x 0ef3672
[release-1.0 7ad52e3] Fix the Asia map
 Date: Tue Jan 6 04:00:00 2026 +0000
 1 file changed, 1 insertion(+)
$ git cherry -v main release-1.0
- 7ad52e34e1d5903470184645c0607951ba42f116 Fix the Asia map
$ git log --oneline main..release-1.0
7ad52e3 Fix the Asia map
```

The site is specific about fixes: reproduce the bug on the trunk, fix it there,
and cherry-pick the fix to the release branch; never fix the release branch
expecting to cherry-pick back, because in a hurry the second step gets
forgotten. Release branches are not merged back into the trunk, and are deleted
some time after a later release has gone live. `-x` records the original commit
in the copy's message (Chapter 32).

Because the branch is never merged back, `git log main..release-1.0` lists the
copy as missing from `main`, although its change is there. `git cherry` answers
the question that matters: the `-` says an equivalent commit is on `main`, so
the release branch has no fix the trunk lacks. A `+` there would be a fix
someone made on the release branch alone.

This is the opposite of what Git's own documentation recommends, which is to
fix the oldest branch that needs it and merge upwards
([Git's own workflow](#graduation-and-merging-upwards)); Chapter 48 shows both
ways on one repository and what `git tag --contains` makes of each.

## Environment branches

GitLab's description of GitLab flow, read in September 2026, has every feature
and fix go to `main`, and adds branches named after where the code runs, such as
`production`: when `main` is ready to be deployed, it is merged into
`production`, and the deployment is made from there. The same page describes a
chain of such branches between `main` and `production`, through which commits
only flow downstream, so that every change is tested in every environment. For
software that ships versions, it uses release branches instead, such as a `v1`
and a `v2` maintained separately.

The Git side is that an environment branch is a record of what is deployed. Here
`production` was last updated three commits before the tip of `main`:

```console
$ git log --oneline origin/production..main
0ef3672 Fix the Asia map
5793d21 Add Iceland
adab0ba Merge branch 'rivers'
0a2e2d5 Add the Amazon
bee7d9c Add the Nile
```

Everything listed is on `main` and not yet deployed; `--first-parent` would
shorten the list to one line per topic. Deploying is `git merge` of `main` into
`production`, which fast-forwards when `production` has nothing of its own, and
a push. Chapter 51 covers GitLab itself.

## Git flow

Git flow is the branching model Vincent Driessen published in January 2010 in
an article called "A successful Git branching model", on nvie.com. It has two
long-running branches and three kinds of short ones:

| Branch | Starts from | Merges into | Holds |
|---|---|---|---|
| `main` (the article says `master`) | | | production-ready code; each merge into it is a new release |
| `develop` | created once, at the start | | the latest development, towards the next release |
| a feature branch, any name but the others | `develop` | `develop` | one feature |
| `release-*` | `develop` | `main` and `develop` | the preparation of one release: its version number and last fixes |
| `hotfix-*` | `main` | `main` and `develop`; into the release branch instead of `develop` while one exists | an urgent fix to the release in production |

The article merges with `--no-ff` every time, so that the history keeps a
record that each branch existed.

```console
$ git flow init
git: 'flow' is not a git command. See 'git --help'.

The most similar commands are
	reflog
	show
```

`git flow` is a separate program that some people install to run these steps
for them. It is not part of Git: Git's documentation says that for a command it
does not have, `git <name>` runs a program called `git-<name>` from a directory
on `PATH`, and without one installed, Git answers as for any unknown command.
Everything it does is ordinary Git, as the next section shows.

### The steps of Git flow

The article's own commands, with `git switch` in place of `git checkout`
(Chapter 24). A feature:

```console
$ git switch -q -c develop main
$ git switch -q -c add-asia develop
$ echo Aisa > asia.txt && git add asia.txt && git commit -q -m 'Add Asia'
$ git switch -q develop && git merge -q --no-ff --no-edit add-asia && git branch -d add-asia
Deleted branch add-asia (was 307a16f).
```

A release: the branch gets the version number, is merged into `main` and
tagged, and then merged back into `develop` so that whatever was fixed on it
is not lost:

```console
$ git switch -q -c release-1.0 develop && echo 1.0 > VERSION && git add VERSION && git commit -q -m 'Bump version to 1.0'
$ git switch -q main && git merge -q --no-ff --no-edit release-1.0 && git tag -a 1.0 -m 'Atlas 1.0'
$ git switch -q develop && git merge -q --no-ff --no-edit release-1.0 && git branch -d release-1.0
Deleted branch release-1.0 (was 4274b95).
```

A hotfix: the released "Aisa" is wrong. The branch starts from `main`, not
`develop`, so it contains nothing but the release and the fix:

```console
$ git switch -q -c hotfix-1.0.1 main && echo 1.0.1 > VERSION && git commit -q -am 'Bump version to 1.0.1'
$ echo Asia > asia.txt && git commit -q -am 'Fix the spelling of Asia'
$ git switch -q main && git merge -q --no-ff --no-edit hotfix-1.0.1 && git tag -a 1.0.1 -m 'Atlas 1.0.1'
$ git switch -q develop && git merge -q --no-ff --no-edit hotfix-1.0.1 && git branch -d hotfix-1.0.1
Deleted branch hotfix-1.0.1 (was 3ee64e4).
$ git log --oneline --graph --all --decorate
*   32b5b52 (HEAD -> develop) Merge branch 'hotfix-1.0.1' into develop
|\  
* \   05e6b75 Merge branch 'release-1.0' into develop
|\ \  
| | | *   88b5cbe (tag: 1.0.1, main) Merge branch 'hotfix-1.0.1'
| | | |\  
| | | |/  
| | |/|   
| | * | 3ee64e4 Fix the spelling of Asia
| | * | 294150f Bump version to 1.0.1
| | |/  
| | *   65f980a (tag: 1.0) Merge branch 'release-1.0'
| | |\  
| | |/  
| |/|   
| * | 4274b95 Bump version to 1.0
|/ /  
* |   04dca82 Merge branch 'add-asia' into develop
|\ \  
| |/  
|/|   
| * 307a16f Add Asia
|/  
* 0dd6887 Start the atlas
$ git log --oneline --first-parent main
88b5cbe Merge branch 'hotfix-1.0.1'
65f980a Merge branch 'release-1.0'
0dd6887 Start the atlas
```

The tags follow the article, which writes `1.2` rather than `v1.2`
(Chapter 48). Every change crosses at least two merges, and the graph shows
it: one feature, one release and one hotfix already give six lines of branches.
The first-parent history of `main` is the part that pays for it: one line per
release, each tagged.

### Is Git flow still recommended

In March 2020 the author added a note of reflection to the top of the article.
It says that web applications are typically delivered continuously, not rolled
back, with no old versions to support, and that for such software he would
suggest a much simpler workflow, such as GitHub flow, rather than Git flow.
Git flow, the note says, still fits software that is explicitly versioned, or
that must support several versions at once. It asks the reader not to treat any
model as dogma and to decide from their own situation. Read on nvie.com in
September 2026.

## Git's own workflow

Git's documentation includes `gitworkflows`, which writes down the workflow of
the Git project itself, with its reasons, and a maintainer's guide,
`howto/maintain-git`. Both are installed with Git. It uses four integration
branches, each normally a descendant of the one before:

| Branch | Holds |
|---|---|
| `maint` | fixes for the next maintenance release of the latest release, `vX.Y.1`, `vX.Y.2` |
| `master` | what goes into the next feature release |
| `next` | topics being tested before they go into `master`; the maintainer's guide says for at least seven days |
| `seen` | topics seen by the maintainer and not yet ready for `next`; rebuilt from `master`, and never built on |

Every change is a topic branch, and a topic is merged, not cherry-picked, into
each integration branch it is meant for; `gitworkflows` keeps cherry-picking for
the occasional fix that was made on a newer branch first. This example starts
from a release tagged `v1.0` on `maint` and one commit on `master` since:

```console
$ git branch
  maint
* master
  next
  seen
$ git log --oneline --graph --all --decorate
* a4a5852 (HEAD -> master, seen, next) Add Europe
* 7ca9595 (tag: v1.0, maint) Add Asia
* 0dd6887 Start the atlas
```

### Topics and a throw-away integration branch

Three topics: a fix to the released spelling of Asia, which 1.0 needs, so it
starts from `maint`; and two features, which start from `master`:

```console
$ git switch -q -c ab/fix-asia maint && echo Asia > maps/asia.txt && git commit -q -am 'Fix the spelling of Asia'
$ git switch -q -c cd/oceania master && echo Oceania > maps/oceania.txt && git add maps && git commit -q -m 'Add Oceania'
$ git switch -q -c ef/rivers master && echo Nile > maps/rivers.txt && git add maps && git commit -q -m 'Add rivers'
$ git switch -q -C seen master && git merge -q --no-edit ab/fix-asia && git merge -q --no-edit cd/oceania && git merge -q --no-edit ef/rivers
$ git log --oneline --first-parent master..seen
835178d Merge branch 'ef/rivers' into seen
cfab79d Merge branch 'cd/oceania' into seen
83a06c5 Merge branch 'ab/fix-asia' into seen
```

`gitworkflows` calls `seen` a throw-away integration branch: to test how several
topics work together, merge them into a branch that will be thrown away, and
never base any work on it. `git switch -C` recreates `seen` from `master`, so
the merges are made afresh every time and nothing of the last round remains
(Chapter 24). Two topics then went to `next`:

```console
$ git switch -q next && git merge -q --no-edit ab/fix-asia && git merge -q --no-edit cd/oceania
$ git branch --no-merged next
  ef/rivers
  seen
$ git switch -q -C seen master && git merge -q --no-edit ab/fix-asia && git merge -q --no-edit cd/oceania
$ git log --oneline --first-parent master..seen && git branch --no-merged seen
a37157c Merge branch 'cd/oceania' into seen
77643e7 Merge branch 'ab/fix-asia' into seen
  ef/rivers
  next
```

`git branch --no-merged next` is the list of topics still waiting for `next`.
`ef/rivers` then turned out not to work, and it was dropped from `seen` by
rebuilding `seen` without it: no revert, and no trace in any branch that will
be kept. The branch `ef/rivers` itself still exists, for its author to fix.
`next`, which people build on, is not rebuilt like this during a release cycle;
the maintainer's guide says it is rewound once, early in each cycle, and
`gitworkflows` asks for an announcement when it is.

### Graduation and merging upwards

A topic that has proved itself in `next` *graduates*: the topic, not `next`, is
merged into `master`. The fix goes to `maint` and is released:

```console
$ git switch -q master && git merge -q --no-ff --no-edit cd/oceania
$ git log --oneline master..next
4048920 Merge branch 'cd/oceania' into next
acb36b0 Merge branch 'ab/fix-asia' into next
58882d8 Fix the spelling of Asia
$ git switch -q maint && git merge -q --no-ff --no-edit ab/fix-asia && git tag -a v1.0.1 -m 'Atlas 1.0.1'
$ git switch -q master && git merge -q --no-edit maint && git log --oneline master..maint
$ git log --oneline --graph master
*   1040ce3 Merge branch 'maint'
|\  
| *   60cd2a6 Merge branch 'ab/fix-asia' into maint
| |\  
| | * 58882d8 Fix the spelling of Asia
| |/  
* |   0b5905f Merge branch 'cd/oceania'
|\ \  
| * | 2a3546b Add Oceania
|/ /  
* / a4a5852 Add Europe
|/  
* 7ca9595 Add Asia
* 0dd6887 Start the atlas
```

`git log master..next` lists what `next` has and `master` still lacks: the fix,
which had not been merged there yet, and the merge commits made in `next`.
Merging `next` into `master` would have brought all of that; merging the topic
brought only "Add Oceania". This is why `gitworkflows` rules out merging
downwards, from a less stable branch into a more stable one, and why every
change has to be its own topic for graduation to work.

The fix shows the other rule, which Chapter 48 quotes: commit a fix to the
oldest supported branch that needs it, then merge the integration branches
upwards. `maint` got the fix and the tag `v1.0.1`, and merging `maint` into
`master` carried it up. `git log master..maint` printed nothing, which is the
check `gitworkflows` gives before a feature release: every fix on `maint` is in
`master`.

| Rule from `gitworkflows` | Shown in |
|---|---|
| make a side branch for every topic, from the oldest integration branch it will be merged into | [Topics and a throw-away integration branch](#topics-and-a-throw-away-integration-branch) |
| commit fixes to the oldest supported branch that needs them, and merge upwards | this section |
| do not merge to downstream except with a good reason | [Keeping a topic up to date](#keeping-a-topic-up-to-date) |
| test topics together on a throw-away branch, and never build on it | [Topics and a throw-away integration branch](#topics-and-a-throw-away-integration-branch) |

## Between repositories

Every pattern so far assumed one repository that the whole team can push to.
When that is not so, as with most open-source projects, `gitworkflows`
describes two ways to send work to the people who can:

| Way | The contributor | The maintainer | Covered in |
|---|---|---|---|
| merge workflow | pushes a topic branch to a repository of their own that others can read, and asks for it to be pulled; `git request-pull` writes the request | `git pull <URL> <branch>` | Chapter 42, Chapter 61 |
| patch workflow | turns the topic into patch files with `git format-patch` and mails them | applies them to a new topic branch with `git am` | Chapter 61 |
| a fork and a pull request | pushes to a fork on a hosting service and opens a pull request | reviews and merges it on the service | Chapter 50, Chapter 51 |

The same documentation notes that only the merge workflow can carry merges; a
patch series is always a line of commits. Git itself uses both: its subsystem
maintainers send merges, and everyone else sends patches. The pull request is
the merge workflow with the request, the review and the merge moved onto a web
page.

## Making a workflow stick

Git does not know a workflow exists. What it can do is change defaults on each
person's machine, and refuse pushes on the server:

| To make sure that | Set or use | Where | Covered in |
|---|---|---|---|
| every merge makes a merge commit | `merge.ff=false` | each clone | Chapter 25 |
| no merge commit is made by accident | `merge.ff=only`, `pull.ff=only` | each clone | Chapter 25, Chapter 42 |
| pulls rebase instead of merging | `pull.rebase=true` | each clone | Chapter 42 |
| nobody rewrites a shared branch | `receive.denyNonFastForwards=true` | the server | Chapter 43 |
| nobody deletes a branch | `receive.denyDeletes=true` | the server | Chapter 43 |
| any other rule: branch names, who may push where, a linear history | a `pre-receive` or `update` hook | the server | Chapter 67 |
| review before merging, a linear history, passing tests | protected branches and rules | GitHub, GitLab | Chapter 50, Chapter 51 |

Settings in a clone are advice, because each person controls their own; only
the server can refuse. Git ships an example, `howto/update-hook-example`, of an
`update` hook that decides who may push to which branch.

## The workflows compared

| Compared on | GitHub flow | Trunk-based | Git flow | Git's own |
|---|---|---|---|---|
| Long-running branches | `main` | the trunk | `main`, `develop` | `maint`, `master`, `next`, `seen` |
| A topic lives | until reviewed and merged | a day or two | until the feature is done | until it graduates |
| Unfinished work | stays on its branch | merged, behind a feature flag | stays on its branch | stays on its branch, or in `seen` |
| Where releases are made | `main`, continuously | the trunk, or a release branch cut from it | a release branch, merged into `main` and tagged | a tag on `master` or `maint` |
| Where a fix for a released version is made | `main`, released again | the trunk, then cherry-picked to the release branch | a hotfix branch from `main`, merged into `main` and `develop` | the oldest branch that needs it, merged upwards |
| Fits | one version in use, deployed often | many developers, one version, frequent releases | versioned software, several versions supported | a long-lived project with maintenance releases and a testing period |

GitHub flow and trunk-based development are close relatives: both keep one
long-running branch and short topics. The difference is emphasis: trunk-based
development insists on topics of a day or two and on feature flags for anything
longer, where GitHub flow asks only that each topic go through a pull request.
Git flow and Git's own workflow both keep several long-running branches, for
opposite reasons: Git flow separates released code from development, while Git's
own workflow separates degrees of testing, and keeps each change a topic so that
it can move between them alone.

## Choosing a workflow

| Situation | Start with | Because |
|---|---|---|
| you alone, one machine | one branch; topic branches when you want to try something | nothing to coordinate |
| a small team, everyone can push | topic branches, merged with `--no-ff` or through pull requests | work is grouped and reviewed; `main` stays usable |
| a web service deployed from `main` | GitHub flow or trunk-based development | one version in use; old releases are never patched |
| a product with versions users stay on | topic branches plus maintenance branches, as in Chapter 48; or Git flow | fixes must reach old versions |
| a large team, many merges a day | trunk-based development, short topics, feature flags | long branches conflict more the longer they live |
| an open-source project | forks and pull requests (Chapter 50) | contributors cannot push to the project |

Whichever you choose, write it down where the team will read it, and make the
server enforce what matters most ([Making a workflow stick](#making-a-workflow-stick)).
A workflow can be changed at any time, but only for the work done afterwards:
the history already made keeps the shape the old workflow gave it.

## The settings

| Setting | Does | Covered in |
|---|---|---|
| `merge.ff` | `false`: always a merge commit; `only`: never one | Chapter 25 |
| `pull.rebase` | pull with a rebase instead of a merge | Chapter 42 |
| `pull.ff` | `only`: a pull that cannot fast-forward stops | Chapter 42 |
| `branch.autoSetupRebase` | new branches pull with a rebase | Chapter 23 |
| `rebase.updateRefs` | rebasing a topic moves the topics stacked on it | Chapter 33 |
| `push.autoSetupRemote` | the first `git push` of a new topic sets its upstream | Chapter 43 |
| `fetch.prune` | a fetch removes remote-tracking branches deleted on the server | Chapter 41 |
| `receive.denyNonFastForwards`, `receive.denyDeletes` | the server refuses rewrites and deletions of branches | Chapter 43 |

> **Since Git 2.38.** `--ancestry-path=<commit>`, used in
> [What each way leaves behind](#what-each-way-leaves-behind); plain
> `--ancestry-path` is older (Chapter 17).
