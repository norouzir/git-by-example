# Chapter 51. Merge Requests on GitLab

## What it is

GitLab is a service that hosts Git repositories, available at gitlab.com and as
software an organisation runs on its own servers. Its *merge request* is what
GitHub calls a pull request (Chapter 50): a page asking the people who run a
project to merge a branch, where the change is shown, discussed, reviewed and
finally merged. GitLab also has forks, for people who cannot push to the
project.

Most of the Git side is the same as on GitHub, and this chapter does not repeat
it: cloning a fork, the `upstream` remote, keeping a fork up to date, a branch
per request, and updating it with `--force-with-lease` are all in Chapter 50.
What is here is what GitLab does differently and Git can show: merge requests
created by `git push` itself, through push options; three merge methods that
are not GitHub's, and a squash that can come with a merge commit; a Rebase
button that rewrites your branch on the server; a fork that can leave out every
branch but one; pushing to a contributor's fork by URL; and push rules, which
refuse commits at the door. As in Chapter 50, bare repositories stand in for
GitLab, and GitLab's side is described from its documentation, read in
September 2026. The one question this chapter answers is: *what does working
through merge requests on GitLab ask of Git, where it differs from GitHub?*

| Term | Means |
|---|---|
| *project* | GitLab's word for a repository with its merge requests, issues and settings |
| *group*, *namespace* | a group of users and projects; a project's path is `group/project`, such as `maps/atlas` |
| *merge request*, *MR* | a request, on GitLab, to merge one branch into another, with a page for reviewing it |
| *source branch*, *target branch* | the branch with the changes, and the branch they are to be merged into |
| `!1` | merge request 1, as GitLab writes references to merge requests; issues are `#1` |
| *role* | what a member of a project may do; Developer and Maintainer are the two this chapter uses |
| *merge method* | how the merge request's branch is put into the target branch: merge commit, merge commit with semi-linear history, or fast-forward |
| *semi-linear history* | merge commits only for branches rebased onto the target first, so each side branch starts at the tip of the target |
| *push option* | a string sent with `git push -o`, which the server's hooks read (Chapter 43) |
| *push rule* | a condition GitLab checks on every pushed commit, such as a `Signed-off-by` line, refusing the push if it fails |
| *draft* | a merge request marked as not ready; GitLab will not merge it |

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What is a merge request, and how is it different from a pull request?](#what-it-is)

**[The steps at a glance](#the-steps-at-a-glance)**

- [What are the steps of a merge request, and which ones differ from GitHub's?](#the-steps-at-a-glance)

**[The example repositories](#the-example-repositories)**

- [What repositories do the examples use, when nothing here reaches GitLab?](#the-example-repositories)

**[Opening a merge request from Git](#opening-a-merge-request-from-git)**

- [I pushed a branch and GitLab printed a link. What is it?](#opening-a-merge-request-from-git)
- [Can I open a merge request without leaving the command line?](#push-options-for-merge-requests)
- [My title has spaces, and `git push -o` failed with "src refspec does not match any". Why?](#push-options-for-merge-requests)
- [Which push options does GitLab understand?](#gitlab-s-push-options)

**[Updating a merge request](#updating-a-merge-request)**

- [How do I add commits to a merge request?](#updating-a-merge-request)
- [Can I see what changed between two pushes to a merge request?](#updating-a-merge-request)
- [Why did my merge request become a draft after I pushed a `fixup!` commit?](#drafts)
- [How do I mark a merge request as a draft, or as ready?](#drafts)

**[Merge methods](#merge-methods)**

- [What do "Merge commit", "Merge commit with semi-linear history" and "Fast-forward merge" each do?](#merge-methods)
- [Why does GitLab ask me to rebase before it will merge?](#merge-methods)
- [With squashing on, why is there a merge commit as well as the squash commit?](#squashing)
- [What message does GitLab give the merge commit and the squash commit?](#the-commit-messages)

**[The Rebase button](#the-rebase-button)**

- [What does the Rebase button do to my branch?](#the-rebase-button)
- [GitLab rebased my branch. Why does `git status` say it diverged, and what do I do?](#the-rebase-button)
- [Does GitLab's rebase keep my commit signatures?](#the-rebase-button)

**[Merging and deleting the source branch](#merging-and-deleting-the-source-branch)**

- [How is the source branch deleted after the merge?](#merging-and-deleting-the-source-branch)

**[Merge requests from forks](#merge-requests-from-forks)**

- [What does "Only the default branch" leave out of a fork?](#a-fork-of-the-default-branch-only)
- [How do I open a merge request from my fork into the original project?](#a-merge-request-from-a-fork)
- [How do I get a merge request from someone's fork into my clone?](#a-merge-request-from-a-fork)
- [How long does a merge request's ref stay on the server?](#a-merge-request-from-a-fork)
- [As a maintainer, how do I push to a contributor's fork?](#pushing-to-a-contributor-s-fork)
- [Why does `--force-with-lease` to a URL say "stale info", and how do I force safely?](#pushing-to-a-contributor-s-fork)

**[Closing issues](#closing-issues)**

- [Which words in a commit message or description close an issue?](#closing-issues)

**[Protected branches](#protected-branches)**

- [Why can't I push to `main` on GitLab?](#protected-branches)
- [What can a protected branch forbid, and who may merge?](#protected-branches)

**[Push rules](#push-rules)**

- [GitLab refused my push because of a push rule. How do I fix the commits?](#push-rules)
- [My commits need a `Signed-off-by` line. How do I add one to every commit on my branch?](#push-rules)

**[Secret push protection](#secret-push-protection)**

- [GitLab refused my push because it contains a secret. What do I do?](#secret-push-protection)

**[Signing in from Git](#signing-in-from-git)**

- [Where on GitLab do I add an SSH key, or make a token for HTTPS?](#signing-in-from-git)
- [Which scopes does a token need to push?](#signing-in-from-git)

**[GitLab flow on GitLab](#gitlab-flow-on-gitlab)**

- [How do environment branches such as `production` fit GitLab's settings?](#gitlab-flow-on-gitlab)

**[Merge requests and pull requests](#merge-requests-and-pull-requests)**

- [What is the same and what is different between GitLab and GitHub?](#merge-requests-and-pull-requests)
- [Is `glab` part of Git?](#the-gitlab-command-line-tool)

**[Undoing](#undoing)**

- [How do I revert a merged merge request, or reopen a closed one?](#undoing)

**[The settings](#the-settings)**

- [Which Git settings help with GitLab?](#the-settings)

</details>

## The steps at a glance

| Step | On GitLab | In Git | Different from GitHub? |
|---|---|---|---|
| get the code | clone the project; fork first if you cannot push to it | `git clone` | forks can copy only the default branch ([A fork of the default branch only](#a-fork-of-the-default-branch-only)) |
| make a branch and commit | | `git switch -c`, `git commit` | no (Chapter 50) |
| push and open the merge request | the link GitLab prints, or "New merge request" | `git push`, or `git push -o merge_request.create` | push options open it from Git ([Opening a merge request from Git](#opening-a-merge-request-from-git)) |
| respond to reviews | comments, approvals | `git commit`, `git push`; after a rewrite, `--force-with-lease` | each push is a version you can compare ([Updating a merge request](#updating-a-merge-request)) |
| bring the branch up to date | the Rebase button | `git rebase`, `git pull --rebase` | the button rewrites your branch ([The Rebase button](#the-rebase-button)) |
| merge | the Merge button, by the project's merge method | | the methods differ ([Merge methods](#merge-methods)) |
| clean up | "Delete source branch" | `git fetch --prune`, `git branch -d` | no (Chapter 50) |

## The example repositories

Nothing in this chapter reaches GitLab. Bare repositories stand in for it,
named as GitLab names projects, group or user, then project:

| Stand-in | On gitlab.com it would be | What it is |
|---|---|---|
| `gitlab/maps/atlas.git` | `https://gitlab.com/maps/atlas.git` | the atlas, in a group `maps`; Ada is a Maintainer and Bob a Developer, who pushes his branches to it |
| `gitlab/carol/atlas.git` | `https://gitlab.com/carol/atlas.git` | Carol's fork, for [Merge requests from forks](#merge-requests-from-forks) |

Each person has a clone, reaching the stand-ins by relative paths such as
`../../gitlab/maps/atlas.git`, which keeps merge commits' hashes the same on
every machine (Chapter 42); against GitLab, the URL would be the one in the
table, or `git@gitlab.com:maps/atlas.git` over SSH (Chapter 40). Each section
says whose clone it runs in, and everyone's commits carry their own names. In
Bob's clone:

```console
$ git remote -v && git log --oneline --graph --all --decorate
origin	../../gitlab/maps/atlas.git (fetch)
origin	../../gitlab/maps/atlas.git (push)
* 65e4594 (origin/drafts) Draft Oceania
* 2a3eedb (HEAD -> main, tag: v1.0, origin/main, origin/HEAD) Add Asia
* c814e86 Add Europe
* 4a66b79 Start the atlas
```

The stand-ins accept push options, and a hook on each prints every option it
receives, as the hook in Chapter 43 did. GitLab's own replies are quoted from
its documentation where it shows them, and left out where it does not. What
GitLab does on its own side, such as recording a merge request, was done by
hand in the stand-ins, out of sight, and each section says what.

## Opening a merge request from Git

A push of a new branch to GitLab is answered with a link for opening a merge
request. GitLab's documentation shows it, for a branch `my-new-branch`:

```
...
remote: To create a merge request for my-new-branch, visit:
remote:   https://gitlab.example.com/my-group/my-project/merge_requests/new?merge_request%5Bsource_branch%5D=my-new-branch
```

Lines starting with `remote:` are the server's (Chapter 43). Opening the link
fills in the new merge request with the branch as its source; choose the target
branch, write a title and a description, and create it.

### Push options for merge requests

The same can be done by the push itself. In Bob's clone:

```console
$ git switch -q -c fix-asia && echo Asia > maps/asia.txt && git commit -q -am 'Fix the spelling of Asia'
$ git push -o merge_request.create -o merge_request.target=main -o merge_request.title="Fix the spelling of Asia" -u origin fix-asia
remote: Push option: merge_request.create        
remote: Push option: merge_request.target=main        
remote: Push option: merge_request.title=Fix the spelling of Asia        
To ../../gitlab/maps/atlas.git
 * [new branch]      fix-asia -> fix-asia
branch 'fix-asia' set up to track 'origin/fix-asia'.
```

Each `-o` sends one string to the server (Chapter 43). GitLab's documentation
says `merge_request.create` creates a merge request for the pushed branch, and
`merge_request.target` sets the branch it should go into, which is required
when pushing from the default branch. The stand-in's hook printed what arrived,
which shows what the quotes did: the shell removed them, and the title reached
the server as one string with its spaces. GitLab would now have merge request
`!1`; the stand-in recorded it by hand.

GitLab's documentation says to enclose text containing spaces in double quotes.
Without them:

```console
$ git push -o merge_request.title=Fix the spelling origin fix-asia; echo "exit $?"
error: src refspec spelling does not match any
error: failed to push some refs to 'the'
exit 1
```

The shell split the title at the spaces, so `-o` took only
`merge_request.title=Fix`, and the next word, `the`, became the repository to
push to, and `spelling`, `origin` and `fix-asia` the refspecs (Chapter 44).
`spelling` names nothing, so Git refused before connecting anywhere; `origin`
and `fix-asia` happen to name refs. Nothing was pushed.

> **Windows.** Tested outside the sandbox, with a program that prints the
> arguments it receives: in PowerShell, `-o merge_request.title="Fix the
> spelling of Asia"` and the same in single quotes both arrive as one argument,
> and without quotes the title is split as in bash. In cmd, double quotes work
> and single quotes do not: each word arrives separately, with the quote
> characters still attached.

### GitLab's push options

GitLab's documentation lists these for merge requests:

| Push option | Does |
|---|---|
| `merge_request.create` | create a merge request for the pushed branch |
| `merge_request.target=<branch>` | the branch it should be merged into; required when pushing from the default branch |
| `merge_request.target_project=<group>/<project>` | the project to merge into, for a push to a fork ([A merge request from a fork](#a-merge-request-from-a-fork)) |
| `merge_request.title="<title>"` | its title |
| `merge_request.description="<description>"` | its description |
| `merge_request.draft` | mark it as a draft ([Drafts](#drafts)) |
| `merge_request.auto_merge` | merge it automatically once it can be; `merge_request.merge_when_pipeline_succeeds`, the older name, was deprecated in GitLab 17.11 |
| `merge_request.remove_source_branch` | delete the source branch when it is merged |
| `merge_request.squash` | squash its commits when merging ([Squashing](#squashing)); since GitLab 17.2 |
| `merge_request.label="<label>"`, `merge_request.unlabel="<label>"` | add or remove a label, creating a label that does not exist |
| `merge_request.assign="<user>"`, `merge_request.unassign="<user>"` | add or remove an assignee, by username or user ID |
| `merge_request.milestone="<milestone>"` | its milestone |

Options can be repeated, one `-o` each, as in `-o merge_request.label="maps"
-o merge_request.label="spelling"`. GitLab's documentation also lists options
for its pipelines, such as `ci.skip`, which skips the pipeline for the push;
pipelines are continuous integration, outside this book. `push.pushOption`
sends an option with every push (Chapter 43).

## Updating a merge request

Ada asked Bob to fix the spelling in the README too. In Bob's clone:

```console
$ sed -i 's/Aisa/Asia/' README.md && git commit -q -am 'Fix the spelling in the README' && git push
To ../../gitlab/maps/atlas.git
   7ecc745..7cd885e  fix-asia -> fix-asia
```

`sed -i` stands for editing the file. A push to the source branch updates the
merge request. GitLab's documentation adds that every push makes a new *diff
version* of the merge request: one per push, not per commit. The Changes tab has a Compare menu for choosing two versions, which
shows what changed between pushes, much as `git range-diff` does in a clone
(Chapter 50).

### Drafts

GitLab's documentation lists the ways to mark a merge request as a draft, which
it will not merge until the mark is removed:

| Way | Draft | Ready |
|---|---|---|
| the title | starts with `Draft:`, `[Draft]` or `(Draft)` | remove the prefix |
| a comment | `/draft` | `/ready` |
| the page | "Mark as draft" | "Mark as ready" |
| a push | `-o merge_request.draft` | |
| a commit | its message starts with `draft:`, `Draft:`, `fixup!` or `Fixup!` | |

The last row matters for Git users: a commit made with `git commit --fixup`
(Chapter 35) starts with `fixup!`, so pushing one marks the merge request as a
draft, which is fair warning that it still needs `git rebase --autosquash`
before it is merged. The documentation notes that a commit does not toggle the
mark back.

## Merge methods

A project's settings choose one merge method for all its merge requests, and
whether commits may, must or must not be squashed. In Ada's clone, the merge
request and `main`, which has gained "Add Oceania" since Bob branched:

```console
$ git fetch -q && git log --oneline --graph main origin/fix-asia -5
* d2b75a1 Add Oceania
| * 7cd885e Fix the spelling in the README
| * 7ecc745 Fix the spelling of Asia
|/  
* 2a3eedb Add Asia
* c814e86 Add Europe
$ git switch -q -c rebased origin/fix-asia && git rebase -q main
$ git switch -q -c merge-commit main && git merge -q --no-ff -m "Merge branch 'fix-asia' into 'main'" -m 'Fix the spelling of Asia' -m 'See merge request maps/atlas!1' origin/fix-asia
$ git switch -q -c semi-linear main && git merge -q --no-ff -m "Merge branch 'fix-asia' into 'main'" -m 'Fix the spelling of Asia' -m 'See merge request maps/atlas!1' rebased
$ git switch -q -c fast-forward main && git merge -q --ff-only rebased
$ git log --oneline --graph main~1..merge-commit
*   f74c491 Merge branch 'fix-asia' into 'main'
|\  
| * 7cd885e Fix the spelling in the README
| * 7ecc745 Fix the spelling of Asia
* d2b75a1 Add Oceania
$ git log --oneline --graph main~1..semi-linear
*   2b8f669 Merge branch 'fix-asia' into 'main'
|\  
| * aeb26c1 Fix the spelling in the README
| * 1639a86 Fix the spelling of Asia
|/  
* d2b75a1 Add Oceania
$ git log --oneline --graph main~1..fast-forward
* aeb26c1 Fix the spelling in the README
* 1639a86 Fix the spelling of Asia
* d2b75a1 Add Oceania
```

`rebased` is the branch rebased onto `main`, what GitLab's Rebase button makes
([The Rebase button](#the-rebase-button)). Each method was made on a scratch
branch, with the Git commands GitLab's documentation gives for it:

| Merge method | GitLab's documentation says | The same in Git | Needs the branch rebased first |
|---|---|---|---|
| Merge commit, the default | a merge commit is always created | `git merge --no-ff` | no |
| Merge commit with semi-linear history | a merge commit for every merge, but only when a fast-forward would be possible | rebase, then `git merge --no-ff` | yes |
| Fast-forward merge | no merge commits, a linear history | rebase, then `git merge --ff-only` | yes |

The plain merge commit joins the branch where it started, before "Add Oceania".
Semi-linear history has the same merge commit, but the side branch starts at the
tip of `main`, so every merge request's commits sit between two consecutive
merges, rebased onto everything merged before them. The fast-forward has no
merge at all. For the last two, the documentation says
that when the branch is not up to date, the merge is not possible, and GitLab
offers to rebase it.

### Squashing

Squashing is separate from the method: with it, the merge request's commits
become one. GitLab's documentation gives the Git commands for a squash under
the merge commit method, which begin from the commit where the branch started:

```console
$ git switch -q --detach $(git merge-base origin/fix-asia main) && git merge -q --squash origin/fix-asia && git commit -q -m 'Fix the spelling of Asia'
Squash commit -- not updating HEAD
$ SOURCE_SHA=$(git rev-parse HEAD) && git switch -q -c squash-merge main && git merge -q --no-ff -m "Merge branch 'fix-asia' into 'main'" -m 'Fix the spelling of Asia' -m 'See merge request maps/atlas!1' $SOURCE_SHA
$ git switch -q -c squash-ff main && git merge -q --squash rebased && git commit -q -m 'Fix the spelling of Asia'
Squash commit -- not updating HEAD
$ git log --oneline --graph main~1..squash-merge
*   8423ba4 Merge branch 'fix-asia' into 'main'
|\  
| * 723a3e9 Fix the spelling of Asia
* d2b75a1 Add Oceania
$ git log --oneline --graph main~1..squash-ff
* 042341d Fix the spelling of Asia
* d2b75a1 Add Oceania
```

The documentation's commands use `git checkout` and `git commit --no-edit`;
these use `git switch --detach` (Chapter 24) and give the message GitLab's
default template would. The squash commit was made on a detached `HEAD` at the
merge base (Chapter 25), the one commit was saved in `SOURCE_SHA`, and merged
with a merge commit: two new commits for one merge request, which the
documentation describes as the result of squashing under the merge commit
method. Under the fast-forward method, the squash commit alone lands on top of
`main`, as `git merge --squash` would put it (Chapter 25).

| Merge method | Without squashing | With squashing |
|---|---|---|
| Merge commit | the branch's commits and a merge commit | a squash commit on a side branch and a merge commit |
| Merge commit with semi-linear history | the rebased commits and a merge commit | a squash commit and a merge commit |
| Fast-forward merge | the rebased commits, in a line | one squash commit |

GitLab's documentation lists four project settings for squashing: Do not allow;
Allow, where it is off unless chosen; Encourage, where it is on unless turned
off; and Require. The push option `merge_request.squash` asks for it on one
merge request.

### The commit messages

GitLab's documentation gives its default templates. The merge commit:

```
Merge branch '%{source_branch}' into '%{target_branch}'

%{title}

%{issues}

See merge request %{reference}
```

`%{title}` is the merge request's title, `%{issues}` the issues it closes, in a
form such as `Closes #465, #190 and #400`, and `%{reference}` the merge
request, such as `group-name/project-name!72359`. The squash commit's default
is `%{title}` alone. The stand-in's messages follow the templates with no
issues to close, which leaves that paragraph out. A project can change both
templates, with further variables such as `%{co_authored_by}`, which lists the
authors as `Co-authored-by` trailers, and `%{approved_by}`.

In the printed commands, `'See merge request maps/atlas!1'` is in single
quotes because an interactive bash treats `!` inside double quotes as a
reference to its command history.

## The Rebase button

When a merge request cannot be merged by the project's method because `main`
has moved on, GitLab offers Rebase on its page, and the `/rebase` command in a
comment does the same. It rebases the source branch onto the target, on the
server, and replaces the branch. In Git terms, from Ada's clone:

```console
$ git push --force-with-lease origin rebased:fix-asia
To ../../gitlab/maps/atlas.git
 + 7cd885e...aeb26c1 rebased -> fix-asia (forced update)
```

Bob's own `fix-asia` still has the old commits. In Bob's clone:

```console
$ git fetch && git status -sb
From ../../gitlab/maps/atlas
 + 7cd885e...aeb26c1 fix-asia   -> origin/fix-asia  (forced update)
   2a3eedb..d2b75a1  main       -> origin/main
## fix-asia...origin/fix-asia [ahead 2, behind 3]
$ git pull --rebase && git status -sb
Successfully rebased and updated refs/heads/fix-asia.
## fix-asia...origin/fix-asia
```

The server's branch was replaced, so Bob's diverged from it: two old commits
only he has, three the server has, "Add Oceania" and the two rebased copies.
`git pull --rebase` recognised his two commits as already applied and dropped
them, and the branch matches the server's (Chapter 42). Had Bob committed more
in the meantime, the same command would have put only those on top. A plain
`git pull`, merging, would have brought the old commits back beside their
copies (Chapter 45).

GitLab's documentation warns that a rebase on the server removes GPG signatures
from the commits (Chapter 68), and offers "Rebase without CI/CD pipeline" to
skip rerunning the pipeline.

## Merging and deleting the source branch

In Ada's clone, the merge as GitLab would record it, with the merge commit
method, and the source branch deleted:

```console
$ git fetch -q && git merge -q --no-ff -m "Merge branch 'fix-asia' into 'main'" -m 'Fix the spelling of Asia' -m 'See merge request maps/atlas!1' origin/fix-asia && git push -q origin main :fix-asia
```

After the Rebase button, the merge commit method gives the same shape as
semi-linear history. The source branch is deleted when the merge request says
so, by the choice on its page or `merge_request.remove_source_branch` when it
was pushed. Everyone's clean-up is then as in Chapter 50:
`git fetch --prune`, `git branch -d`.

## Merge requests from forks

### A fork of the default branch only

GitLab's documentation lists the fork's choices: a name, a namespace, a slug
for its path, a description, a visibility at least as restrictive as the
original's, and "Branches to include": all branches, the default, or only the
default branch, which it says uses Git's `--single-branch` and `--no-tags`.
Carol's fork was made that way, with `git clone --bare --single-branch
--no-tags`:

```console
$ git ls-remote gitlab/maps/atlas.git && git ls-remote gitlab/carol/atlas.git
a72cecf305aedbac464798874ea29767edb20254	HEAD
65e4594b8937b2d07a7af075a1914e8dd23c1568	refs/heads/drafts
a72cecf305aedbac464798874ea29767edb20254	refs/heads/main
aeb26c12cca26892319b085cb196a3cbd354b97f	refs/merge-requests/1/head
8a37d604c1b2b0aa1ee2de44636ca997cbf146f2	refs/tags/v1.0
2a3eedbe5732345fc58b754b2d7c52ad63da666b	refs/tags/v1.0^{}
a72cecf305aedbac464798874ea29767edb20254	HEAD
a72cecf305aedbac464798874ea29767edb20254	refs/heads/main
```

The fork has `main` and nothing else: no `drafts`, no tags, and no merge
request refs (Chapter 46 covers what `--single-branch` and `--no-tags` do).
Carol's clone gets the rest by fetching from `upstream`. GitLab's page for a
fork shows how far it is behind or ahead of the original, with "Update fork"
to bring it up to date and "Create merge request" when it is ahead; the
documentation says that updating from the page bypasses the fork's push rules.
From the command line, its documentation gives the same commands as Chapter 50:
`git fetch upstream`, `git pull upstream main`, `git push origin main`.

### A merge request from a fork

In Carol's clone, with `origin` her fork and `upstream` the project:

```console
$ git switch -q -c fix-europe upstream/main && echo 'Europe, with Iceland' > maps/europe.txt && git commit -q -am 'Add Iceland'
$ git push -o merge_request.create -o merge_request.target_project=maps/atlas -o merge_request.remove_source_branch origin fix-europe
remote: Push option: merge_request.create        
remote: Push option: merge_request.target_project=maps/atlas        
remote: Push option: merge_request.remove_source_branch        
To ../../gitlab/carol/atlas.git
 * [new branch]      fix-europe -> fix-europe
```

`merge_request.target_project` sends the merge request to the original project,
`maps/atlas`, from a push to the fork. On the page, a fork's merge request
offers "Allow commits from members who can merge to the target branch", which
GitLab's documentation says lets the project's Developers, Maintainers and
Owners push to the source branch, for a merge request from a public fork.

In Ada's clone, where `origin` is the project:

```console
$ git fetch origin merge-requests/2/head:mr-origin-2 && git log --oneline main..mr-origin-2
From ../../gitlab/maps/atlas
 * [new ref]         refs/merge-requests/2/head -> mr-origin-2
87a6bd9 Add Iceland
```

GitLab keeps each merge request's source branch as
`refs/merge-requests/<number>/head` in the target project, whichever repository
the branch is in, and its documentation gives this command, with this branch
name, `mr-origin-2`, for checking one out. Chapter 44 shows the line for
`remote.origin.fetch` that fetches every merge request, which the same
documentation gives. It also says the ref is deleted 14 days after the merge
request is closed or merged; the branch, if it still exists, is not affected.
The documentation's alias for fetching and checking out in one command, `git mr
origin 2`, is built with Chapter 64's aliases.

### Pushing to a contributor's fork

GitLab's documentation for pushing to a fork as a member of the project fetches
the branch by URL, without adding a remote. In Ada's clone:

```console
$ git fetch ../../gitlab/carol/atlas.git fix-europe && git switch -q -c carol/fix-europe FETCH_HEAD
From ../../gitlab/carol/atlas
 * branch            fix-europe -> FETCH_HEAD
$ echo 'Europe, with Iceland and Malta' > maps/europe.txt && git commit -q -am 'Add Malta' && git push ../../gitlab/carol/atlas.git carol/fix-europe:fix-europe
To ../../gitlab/carol/atlas.git
   87a6bd9..e85eb63  carol/fix-europe -> fix-europe
```

A fetch from a URL keeps the branch only in `FETCH_HEAD` (Chapter 41), and the
branch made from it is named after the contributor, as the documentation
names it. The push gives the source and the fork's branch name, because they
differ (Chapter 43).

For a rewrite, the documentation adds `--force` to that push. A force without a
lease overwrites whatever is there, including a commit Carol pushed since.
With a lease:

```console
$ git commit -q --amend -m 'Add Malta to the Europe map' && git push --force-with-lease ../../gitlab/carol/atlas.git carol/fix-europe:fix-europe
To ../../gitlab/carol/atlas.git
 ! [rejected]        carol/fix-europe -> fix-europe (stale info)
error: failed to push some refs to '../../gitlab/carol/atlas.git'
$ git push --force-with-lease=fix-europe:carol/fix-europe@{1} ../../gitlab/carol/atlas.git carol/fix-europe:fix-europe
To ../../gitlab/carol/atlas.git
 + e85eb63...01238b3 carol/fix-europe -> fix-europe (forced update)
```

A plain `--force-with-lease` compares the server's branch with your
remote-tracking branch for it (Chapter 43), and a push to a URL has none, so it
refused, as "stale info". Naming the expected value makes the lease work:
`fix-europe:carol/fix-europe@{1}` says the fork's `fix-europe` must still be
where Ada's branch was before the amend, which is what she last pushed there
(Chapter 36 explains `@{1}`). Had Carol pushed in between, it would have been
refused. Adding the fork as a remote, as Chapter 50 does, gives the plain
lease its remote-tracking branch instead.

## Closing issues

GitLab's documentation lists the words that close an issue, in any case:
`Close`, `Closes`, `Closed`, `Closing`, `Fix`, `Fixes`, `Fixed`, `Fixing`,
`Resolve`, `Resolves`, `Resolved`, `Resolving`, `Implement`, `Implements`,
`Implemented` and `Implementing`. It gives this commit message as its example:

```
Fix #20, Fixes #21 and Closes group/otherproject#22. This commit is also related to #17 and fixes #18, #19 and https://gitlab.example.com/group/otherproject/-/issues/23.
```

That closes issues 18 to 21 here and 22 and 23 in the other project; 17 has no
closing word before it. Issues close when such a commit reaches the default
branch, pushed or merged, or when a merge request whose description has them
is merged into it. A Maintainer can turn this off under Settings, Repository,
Branch defaults, with "Auto-close referenced issues on default branch".
Compared with GitHub (Chapter 50), GitLab adds the `-ing` forms and
`Implement`.

## Protected branches

GitLab's documentation says the default branch is protected by default. A
protected branch has:

| Setting | Chooses |
|---|---|
| Allowed to merge | who may merge merge requests into it: No one, Developers + Maintainers, or Maintainers |
| Allowed to push and merge | who may push to it directly; No one makes every change go through a merge request |
| Allowed to force push | off by default: nobody may force-push to a protected branch |
| Require approval from code owners | a code owner must approve changes to their files |

A role includes the roles above it: Maintainers includes Owners. The
documentation also says nobody can delete a protected branch with Git, only a
Maintainer from the page or the API, and that names can be patterns, such as
`*-stable` or `production/*`. A push that breaks a protection is refused by the
server, on `remote:` lines (Chapter 43); the change goes through a merge
request instead. Plain Git on your own server has `receive.denyNonFastForwards`,
`receive.denyDeletes` (Chapter 43) and hooks (Chapter 67).

*Code owners* are named in a file `CODEOWNERS`, which GitLab looks for at the
top of the repository, then in `docs/`, then in `.gitlab/`, using the first it
finds; each line pairs a path pattern with `@user` or `@group` names, and
sections, `[Section name]`, group them. Its documentation lists code owners as a
Premium and Ultimate feature.

## Push rules

A push rule checks every commit in a push, and GitLab's documentation says push
rules are implemented as `pre-receive` hooks on the server (Chapter 67). They
are a Premium and Ultimate feature, and it lists these:

| Push rule | Refuses |
|---|---|
| Reject unverified users | a committer email that is not one of the user's verified addresses |
| Reject inconsistent user name | an author name that differs from the user's GitLab name |
| Check whether the commit author is a GitLab user | author and committer emails that belong to no GitLab user |
| Commit author's email | author and committer emails that do not match a regular expression |
| Require expression in commit messages | a message that does not match a regular expression |
| Reject expression in commit messages | a message that does match one |
| Branch name | a branch name that does not match a regular expression; the default branch is always allowed |
| Reject unsigned commits | a commit without a valid signature (Chapter 68) |
| Do not allow users to remove Git tags with `git push` | a push that deletes a tag |
| Prevent pushing secret files | files that look like credentials, such as private keys |
| Prohibited filenames | files whose names match a regular expression |
| Maximum file size | an added or changed file over the limit; Git LFS files are exempt (Chapter 59) |
| Reject commits that aren't DCO certified | a commit without a `Signed-off-by:` trailer |

The fix is always in Git: change the commits, then push again. The stand-in
project was given a `pre-receive` hook doing what the last rule does, with
messages of its own; GitLab's words differ. In Bob's clone:

```console
$ git switch -q -c add-rivers && echo Nile > maps/rivers.txt && git add maps && git commit -q -m 'Add the Nile' && echo Amazon >> maps/rivers.txt && git commit -q -am 'Add the Amazon'
$ git push -u origin add-rivers
remote: stand-in rule: 7659fdb has no Signed-off-by line        
remote: stand-in rule: a774391 has no Signed-off-by line        
To ../../gitlab/maps/atlas.git
 ! [remote rejected] add-rivers -> add-rivers (pre-receive hook declined)
error: failed to push some refs to '../../gitlab/maps/atlas.git'
$ git rebase --signoff main && git push -u origin add-rivers
Current branch add-rivers is up to date, rebase forced.
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/add-rivers.
To ../../gitlab/maps/atlas.git
 * [new branch]      add-rivers -> add-rivers
branch 'add-rivers' set up to track 'origin/add-rivers'.
$ git log --format='%h %s%n%(trailers)' main..add-rivers
ed7a296 Add the Amazon
Signed-off-by: Bob Brown <bob@example.com>

99b058c Add the Nile
Signed-off-by: Bob Brown <bob@example.com>
```

The hook refused the whole push and named both commits. `git rebase --signoff`
added a `Signed-off-by` trailer to every commit it replayed (Chapter 33); the
branch already started at `main`, and `--signoff` made the rebase happen
anyway, as its first line says. `%(trailers)` prints a commit's trailers
(Chapter 17). For the last commit alone, `git commit --amend --signoff` does
the same (Chapter 29), and `git commit -s` adds the line from the start
(Chapter 12). The other rules are fixed the same way: `git commit --amend`
or an interactive rebase to reword messages or change authors (Chapter 34),
`git branch -m` to rename a branch (Chapter 23).

## Secret push protection

GitLab's secret push protection refuses a push whose new lines contain
something that looks like a key or a token. Its documentation says it is an
Ultimate feature, turned on per project, that it scans only changed lines, and
that the refusal gives each commit, file, line and kind of secret, beginning:

```
remote: PUSH BLOCKED: Secrets detected in code changes
```

To get past it, remove the secret from the commits, with `git commit --amend`
for the last one or an interactive rebase for older ones (Chapter 29, Chapter
34), and push again. If the secret was pushed anywhere before, removing it from
the new commits is not enough (Chapter 37). The documentation also gives two
ways to skip the check, both recorded in GitLab's audit log: the push option
`-o secret_push_protection.skip_all`, and the text `[skip secret push
protection]` in a commit message.

## Signing in from Git

Chapter 40 covers how Git authenticates; GitLab's documentation says where the
account side is:

| For | On GitLab | Notes |
|---|---|---|
| an SSH key | your avatar, Edit profile, then Access, SSH keys; "Add new key" | paste the `.pub` file's contents, give a title, choose the usage type, Authentication & Signing by default, and an optional expiry |
| a personal access token | your avatar, Edit profile, then Access, Personal access tokens; "Generate token" | a name, an expiry, and scopes: `read_repository` to pull and `write_repository` to push over HTTPS |

The documentation checks an SSH key with `ssh -T git@gitlab.example.com`, or
`git@gitlab.com`, and says a working key is greeted with `Welcome to GitLab,
<username>!`. For HTTPS, a token is typed where Git asks for the password, and
the documentation says the username can be any non-empty string. It gives an
example with the token in the URL, `https://oauth2:<token>@gitlab.example.com/...`;
Chapter 40 explains why a credential in a URL is better kept in a credential
helper. A token's expiry defaults to 365 days. The same documentation also
mentions fine-grained personal access tokens, with narrower permissions.

## GitLab flow on GitLab

Chapter 49 describes GitLab flow: everything merged into `main`, and branches
such as `production` that record what is deployed where, updated by merging
`main` into them. On GitLab itself, that is a protection pattern: protect
`production` with Allowed to merge set to Maintainers and Allowed to push and
merge set to No one, and it moves only through merge requests from `main`, by
the people allowed to deploy. A pattern such as `production/*` protects a family
of such branches at once. GitLab's own feature called *environments* belongs to
its pipelines, and so to continuous integration, outside this book.

## Merge requests and pull requests

| Compared on | GitLab | GitHub (Chapter 50) |
|---|---|---|
| The request is called | a merge request, `!1` | a pull request, `#1` |
| Its two branches | source and target | head, or compare, and base |
| Opened from | the web page, `glab`, or `git push -o merge_request.create` | the web page, or `gh` |
| Its ref in the target repository | `refs/merge-requests/<n>/head`, deleted 14 days after closing or merging | `refs/pull/<n>/head`, and `refs/pull/<n>/merge` for the test merge |
| Merge methods | merge commit, merge commit with semi-linear history, fast-forward; squashing on top of any | merge commit, squash, rebase |
| A squash, with merge commits | a squash commit and a merge commit | one squash commit |
| Updating from the target | the Rebase button, which rewrites the branch | "Update branch", which merges by default |
| Each push | a new diff version, comparable on the page | new commits on the page |
| Drafts | by title prefix, comment, button, push option or commit message | by a choice when opening, or on the page |
| Letting maintainers push to a fork | "Allow commits from members who can merge to the target branch" | "Allow edits from maintainers" |
| A fork of the default branch only | "Only the default branch", also leaving out tags | "Copy the DEFAULT branch only" |
| `CODEOWNERS` is looked for in | the top, `docs/`, `.gitlab/` | `.github/`, the top, `docs/` |
| Closing words | the same stems with `-ing`, plus `Implement` | `close`, `fix`, `resolve` in three forms each |
| Checks on every pushed commit | push rules | rulesets and protected branch rules |

### The GitLab command-line tool

`glab`, which GitLab's documentation describes as its open source command-line
tool, is a separate program, not part of Git. Its `glab mr` command has
subcommands for this chapter's steps, among them `create`, `checkout`, `list`,
`view`, `rebase`, `merge`, `close` and `reopen`. Everything they do to your
repository is ordinary Git, as the rest of this chapter shows.

## Undoing

| To undo | On GitLab | In Git |
|---|---|---|
| an open merge request | close it on its page; it can be reopened, as `glab mr reopen` does | nothing; the branch is untouched |
| a push to the source branch | nothing to press: the merge request follows the branch | `git push --force-with-lease` of the old commit, from the reflog (Chapter 36) |
| a merged merge request | Revert, which makes a revert commit, directly on a branch or in a new merge request | `git revert -m 1 <merge>` (Chapter 31); `git revert <commit>` for a squash or a single commit |
| a server-side rebase | nothing to press | `git reflog` in your clone still has the old commits (Chapter 36) |

GitLab's documentation says its Revert button needs the merge commit method,
or, with fast-forward merges, a squashed or single-commit merge request; that
it always reverts against the first parent of a merge commit, the target
branch; and that anything else is done on the command line.

## The settings

| Setting | Does | Covered in |
|---|---|---|
| `push.pushOption` | push options sent with every push that gives none on the command line | Chapter 43 |
| `remote.<name>.fetch` | add `+refs/merge-requests/*/head:refs/remotes/origin/merge-requests/*` to fetch every merge request | Chapter 44 |
| `pull.rebase` | pull with a rebase, the way to follow a branch GitLab rebased | Chapter 42 |
| `remote.pushDefault`, `push.default` | pull from the project, push to your fork | Chapter 50 |
| `fetch.prune` | remove remote-tracking branches deleted on the server | Chapter 41 |
| `url.<base>.insteadOf` | use SSH for every `https://gitlab.com/` URL | Chapter 40 |
| `receive.advertisePushOptions` | on a server: accept push options, as GitLab does | Chapter 43 |
