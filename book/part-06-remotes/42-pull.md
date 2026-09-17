# Chapter 42. pull

## What it is

`git pull` brings the commits from another repository into the branch you are
on. It does it in two steps: a `git fetch`, which downloads the commits and
updates the remote-tracking branches (Chapter 41), and then a second step that
*integrates* what was fetched into your current branch, by moving the branch
forward, merging, or rebasing. On its own it answers one question: *can my
branch have what is on the server now?*

The first step never touches your work. The second one does: it changes your
current branch and your files, it can stop with a conflict, and when both sides
have new commits it has to be told which way to combine them. Most of this
chapter is about that second step.

| Term | Means |
|---|---|
| *integrate* | bring fetched commits into your branch: by a fast-forward, a merge, or a rebase |
| *upstream* | the branch on the remote that a local branch pulls from, set by `branch.<name>.remote` and `branch.<name>.merge` (Chapter 23) |
| *fast-forward* | moving your branch forward to the fetched commit, possible when your branch has no commits the fetched one lacks (Chapter 25) |
| *diverged* | your branch and its upstream each have commits the other does not |
| *merge commit* | a commit with two or more parents, joining lines of history (Chapter 25) |
| *rebase* | replaying your commits on top of other commits, as new commits with new hashes (Chapter 33) |
| *`FETCH_HEAD`* | the file where fetch records what it fetched, and marks what is for merging (Chapter 41) |
| *fork point* | the commit your branch was built on, found from the upstream's reflog even after the upstream was rewritten (Chapter 33) |
| *autostash* | stashing uncommitted changes before an operation and restoring them after it (Chapter 55) |
| *`ORIG_HEAD`* | a ref that merge, rebase and reset set to where `HEAD` was before they moved it (Chapter 30) |

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What does `git pull` do, and how is it different from `git fetch`?](#what-it-is)
- [Which part of a pull can change my files?](#what-it-is)

**[Synopsis](#synopsis)**

- [What can I type after `git pull`?](#synopsis)

**[Options at a glance](#options-at-a-glance)**

- [Is there a list of every option, and where each is shown?](#options-at-a-glance)

**[The example repository](#the-example-repository)**

- [What repositories do the examples use?](#the-example-repository)

**[Reading the output](#reading-the-output)**

- [What do the lines `git pull` prints mean?](#reading-the-output)
- [Which lines come from the download, and which from updating my branch?](#reading-the-output)

**[What pull runs](#what-pull-runs)**

- [What commands does `git pull` actually run?](#what-pull-runs)
- [Which branch does a plain `git pull` bring into mine?](#what-pull-runs)
- [What does a pull write in the reflog?](#what-pull-runs)

**[When the branches have diverged](#when-the-branches-have-diverged)**

- [Git says "Need to specify how to reconcile divergent branches". What does it want from me?](#when-the-branches-have-diverged)
- [How do I see that my branch and the server's have diverged?](#when-the-branches-have-diverged)
- [What does `git pull --no-rebase` do to my history?](#merging)
- [What does `git pull --rebase` do to my commits?](#rebasing)
- [What does `git pull --ff-only` do when the branches have diverged?](#fast-forward-only)
- [Should I merge or rebase when I pull?](#which-to-choose)

**[Choosing a default](#choosing-a-default)**

- [How do I make `git pull` always rebase, or always merge?](#choosing-a-default)
- [Can one branch pull differently from the others?](#choosing-a-default)
- [I set `pull.ff=only` and `git pull --rebase` still rebased. Which setting wins?](#which-setting-wins)
- [Why did `git pull --ff` make a merge commit without asking?](#which-setting-wins)
- [Git says "'preserve' superseded by 'merges'". What do I change?](#which-setting-wins)

**[More about pulling with rebase](#more-about-pulling-with-rebase)**

- [What happens to my merge commits when I pull with rebase?](#local-merge-commits)
- [Can I reorder or squash my commits during a pull, as with `git rebase -i`?](#choosing-what-to-replay)
- [Someone force-pushed a branch I had built on. Why does `git pull --rebase` work when `git rebase origin/main` conflicts?](#when-the-server-s-branch-was-rewritten)

**[Uncommitted changes](#uncommitted-changes)**

- [Can I pull while I have uncommitted changes?](#uncommitted-changes)
- [Why does `git pull --rebase` refuse with "You have unstaged changes" when `git pull` does not?](#uncommitted-changes)
- [Pull says my local changes "would be overwritten by merge". What now?](#uncommitted-changes)
- [Pull says an untracked file "would be overwritten". It isn't even in Git. Why?](#untracked-files)
- [How do I pull without committing or stashing my changes first?](#autostash)
- [My autostash conflicted. Where are my changes, and how do I finish?](#autostash)

**[When a pull stops with a conflict](#when-a-pull-stops-with-a-conflict)**

- [The pull stopped with a conflict. How do I finish it, or back out?](#when-a-pull-stops-with-a-conflict)
- [Why does `git pull` say "Pulling is not possible because you have unmerged files"?](#when-a-pull-stops-with-a-conflict)
- [I fixed the conflict and pull says "MERGE_HEAD exists". What does it want?](#when-a-pull-stops-with-a-conflict)

**[Pulling a particular branch](#pulling-a-particular-branch)**

- [How do I bring the server's `main` into my feature branch?](#pulling-a-particular-branch)
- [Why does the merge message say "into deserts"?](#pulling-a-particular-branch)
- [What happens if I name two branches after `git pull origin`?](#several-branches-at-once)
- [Can I pull from a repository that is not a remote?](#from-a-url)
- [What does `git pull .` do?](#from-this-repository)

**[When pull does not know what to merge](#when-pull-does-not-know-what-to-merge)**

- ["There is no tracking information for the current branch". How do I fix it?](#when-pull-does-not-know-what-to-merge)
- [Can I set the upstream while pulling?](#when-pull-does-not-know-what-to-merge)
- [Why must I name a branch when I pull from a second remote?](#when-pull-does-not-know-what-to-merge)
- [Why doesn't `git pull` work with a detached HEAD?](#when-pull-does-not-know-what-to-merge)
- ["Your configuration specifies to merge with the ref ... but no such ref was fetched". What happened?](#when-pull-does-not-know-what-to-merge)
- ["There are no candidates for merging among the refs that you just fetched". What does that mean?](#when-pull-does-not-know-what-to-merge)

**[Pulling into an empty repository](#pulling-into-an-empty-repository)**

- [Can I pull into a repository that has no commits yet?](#pulling-into-an-empty-repository)
- [Why can't I pull two branches into an empty repository?](#pulling-into-an-empty-repository)

**[Fetch options through pull](#fetch-options-through-pull)**

- [Does `git pull --dry-run` show me what the merge would do?](#fetch-options-through-pull)
- [Which of fetch's options can I give to `git pull`?](#fetch-options-through-pull)
- [Why did `git pull --append` merge a branch I never asked for?](#appending-to-fetchhead)
- [What does "fetch updated the current branch head" mean?](#into-the-current-branch)

**[Unrelated histories](#unrelated-histories)**

- [Pull says "refusing to merge unrelated histories". When is it safe to override that?](#unrelated-histories)

**[Undoing a pull](#undoing-a-pull)**

- [How do I undo a pull that merged, rebased or fast-forwarded?](#undoing-a-pull)

**[pull and its neighbours](#pull-and-its-neighbours)**

- [Is `git pull` exactly `git fetch` followed by `git merge`?](#pull-and-its-neighbours)
- [What is the difference between merging `FETCH_HEAD` and merging `origin/main`?](#pull-and-its-neighbours)
- [When should I fetch and merge by hand instead of pulling?](#pull-and-its-neighbours)

**[The settings](#the-settings)**

- [Which settings change what pull does?](#the-settings)

</details>

## Synopsis

```
git pull [<options>] [<repository> [<refspec>...]]
```

| Part | Means |
|---|---|
| `<repository>` | A remote's name or a URL; left out, the current branch's remote, or `origin` |
| `<refspec>` | The branch or branches to fetch and integrate, such as `main`; left out, the current branch's upstream. The full syntax is Chapter 44 |

| Command | Does |
|---|---|
| `git pull` | Fetch from the current branch's remote, then integrate its upstream |
| `git pull --ff-only` | The same, but only if that is a fast-forward |
| `git pull --rebase` | Fetch, then rebase your commits onto the upstream |
| `git pull --no-rebase` | Fetch, then merge the upstream |
| `git pull origin main` | Fetch `main` from `origin` and integrate it, whatever the upstream is |
| `git pull origin deserts rivers` | Fetch two branches and merge both at once |
| `git pull <url> <branch>` | Fetch from a repository that is not a remote, and integrate |
| `git pull . <branch>` | Integrate a branch of this repository, like `git merge` |

## Options at a glance

### How to integrate

| Option | Does | Covered in |
|---|---|---|
| `--no-rebase`, `--rebase=false` | Merge what was fetched | [Merging](#merging) |
| `-r`, `--rebase`, `--rebase=true` | Rebase your commits onto what was fetched | [Rebasing](#rebasing) |
| `--rebase=merges` | Rebase, and keep your merge commits | [Local merge commits](#local-merge-commits) |
| `--rebase=interactive` | Rebase interactively, as `git rebase -i` does (Chapter 34) | [Choosing what to replay](#choosing-what-to-replay) |
| `--ff-only` | Only fast-forward; refuse when the branches have diverged | [Fast-forward only](#fast-forward-only) |
| `--ff` | Fast-forward when possible, merge otherwise, without asking | [Which setting wins](#which-setting-wins) |
| `--no-ff` | Make a merge commit even when a fast-forward is possible | Chapter 25 |
| `--autostash`, `--no-autostash` | Stash uncommitted changes first and restore them after | [Autostash](#autostash) |
| `--allow-unrelated-histories` | Merge a history that shares no commit with yours | [Unrelated histories](#unrelated-histories) |

### The merge commit

These are passed to `git merge`, and do what they do there. With `--rebase`
most of them are ignored; `--stat`, `-n`, `-s`, `-X` and `--signoff` are passed
to `git rebase` instead.

| Option | Does | Covered in |
|---|---|---|
| `--commit`, `--no-commit` | Commit the merge, or stop before committing | Chapter 25 |
| `-e`, `--edit`, `--no-edit` | Open an editor on the merge message, or accept it | Chapter 25 |
| `--cleanup=<mode>` | How the message is tidied | Chapter 25 |
| `--log[=<n>]`, `--no-log` | List the merged commits' subjects in the message | Chapter 25 |
| `--signoff`, `--no-signoff` | Add a `Signed-off-by` trailer | Chapter 25 |
| `--squash`, `--no-squash` | Stage the result without committing or recording a merge | Chapter 25 |
| `--stat`, `-n`, `--no-stat` | Show the list of changed files at the end, the *diffstat*, or not | [Pulling a particular branch](#pulling-a-particular-branch) |
| `--compact-summary` | A shorter summary instead of the diffstat | Chapter 25 |
| `--summary`, `--no-summary` | Deprecated names for `--stat` and `--no-stat` | Chapter 25 |
| `-s <strategy>`, `--strategy=<strategy>` | The merge strategy | Chapter 27 |
| `-X <option>`, `--strategy-option=<option>` | An option for the strategy | Chapter 27 |

> **Since Git 2.51.** `--compact-summary`.

### Output

| Option | Does | Covered in |
|---|---|---|
| `-q`, `--quiet` | Print nothing but errors, from fetch and from the merge | [Choosing a default](#choosing-a-default) |
| `-v`, `--verbose` | Passed to fetch and merge | Chapter 41 |
| `--progress` | Show fetch's progress even when not on a terminal | Chapter 41 |

### Passed to fetch

| Option | Does | Covered in |
|---|---|---|
| `--dry-run` | Fetch as `git fetch --dry-run` does, and stop | [Fetch options through pull](#fetch-options-through-pull) |
| `--set-upstream` | Make what is pulled the current branch's upstream | [When pull does not know what to merge](#when-pull-does-not-know-what-to-merge) |
| `-a`, `--append` | Add to `FETCH_HEAD` instead of replacing it | [Appending to FETCH_HEAD](#appending-to-fetchhead) |
| `--all` | Fetch from every remote | Chapter 41 |
| `-f`, `--force` | Allow non-fast-forward updates of the refs fetched into | Chapter 41 |
| `-t`, `--tags` | Fetch every tag | Chapter 41 |
| `-p`, `--prune` | Delete stale remote-tracking branches | Chapter 41 |
| `-k`, `--keep` | Keep the downloaded pack | Chapter 41 |
| `--refmap=<refspec>` | Store fetched refs by this rule | Chapter 41 |
| `--show-forced-updates`, `--no-show-forced-updates` | Check for forced updates, or skip the check | Chapter 41 |
| `--negotiation-restrict=<revision>`, `--negotiation-tip=<revision>`, `--negotiation-include=<revision>` | Which commits to tell the server about | Chapter 41 |
| `--upload-pack <program>` | The program to run on the server | Chapter 39 |
| `-o <option>`, `--server-option=<option>` | Send a string to the server | Chapter 39 |
| `-4`, `-6` | Use only IPv4, or only IPv6; also `--ipv4`, `--ipv6` | Chapter 40 |

### Covered in other chapters

| Option | Does | Covered in |
|---|---|---|
| `--depth=<n>`, `--deepen=<n>`, `--shallow-since=<date>`, `--shallow-exclude=<ref>`, `--unshallow`, `--update-shallow` | Shallow history | Chapter 46 |
| `--recurse-submodules[=<when>]`, `--no-recurse-submodules`, `-j <n>`, `--jobs=<n>` | Pull in submodules too, and how many at once | Chapter 57 |
| `--verify`, `--no-verify` | Run or skip the hooks a merge runs | Chapter 67 |
| `-S[<key-id>]`, `--gpg-sign[=<key-id>]`, `--no-gpg-sign` | Sign the merge commit | Chapter 68 |
| `--verify-signatures`, `--no-verify-signatures` | Refuse to merge a commit without a valid signature | Chapter 68 |

## The example repository

```console
$ git remote -v
origin	../server/atlas.git (fetch)
origin	../server/atlas.git (push)
$ git log --oneline --graph --all --decorate
* f5776f0 (origin/rivers) List rivers
| * b51ebb0 (origin/deserts) List deserts
|/  
* 0fe19df (HEAD -> main, origin/main, origin/HEAD) Add Europe
* 0dd6887 Start the atlas
```

The same atlas as Chapter 41: a bare repository on the "server", Bob's clone,
and Ada's clone. Every command in this chapter runs in Ada's clone, and each
section says what Bob pushed before it.

Ada's `origin` is the relative path `../server/atlas.git`, which Chapter 39
explains. A merge commit made by a pull records the URL in its message, and a
relative path keeps the examples' hashes the same on every machine; with a
hosted repository the message names its `https://` or SSH address instead.

## Reading the output

Bob pushed a commit to `main`:

```console
$ git pull
From ../server/atlas
   0fe19df..3fa97e2  main       -> origin/main
Updating 0fe19df..3fa97e2
Fast-forward
 maps/africa.txt | 2 ++
 1 file changed, 2 insertions(+)
 create mode 100644 maps/africa.txt
$ git pull
Already up to date.
```

The output is two commands' output, one after the other. The first two lines are
`git fetch`'s, read as Chapter 41 describes: `origin/main` moved from `0fe19df`
to `3fa97e2`. The rest is `git merge`'s: `Updating` names the old and new
commit of Ada's `main`, `Fast-forward` says the branch simply moved forward, and
the diffstat lists the files that changed in the working tree (Chapter 25).

The second pull found nothing to fetch, printed no fetch lines, and had nothing
to merge.

## What pull runs

Bob pushed another commit:

```console
$ GIT_TRACE=1 git pull 2>&1 >/dev/null | grep -o 'run_command: git \(fetch\|merge\|rebase\).*'
run_command: git fetch --update-head-ok
run_command: git merge FETCH_HEAD
$ git log --oneline -1 && git reflog -1
975678a Add Asia
975678a HEAD@{0}: pull: Fast-forward
```

`GIT_TRACE=1` makes Git print every command it starts, on standard error;
`2>&1 >/dev/null` sends that into the pipe and throws the ordinary output away,
and `grep` keeps the commands. A pull is these two: a fetch, with
`--update-head-ok` so that it may update the checked-out branch if a refspec
names it (Chapter 41), and a merge of `FETCH_HEAD`.

Which branch gets merged is decided by the fetch. It writes a line to
`FETCH_HEAD` for every branch it fetched, and marks every line
`not-for-merge` except the current branch's upstream, as Chapter 41 showed; the
merge takes the lines without the mark. So a plain `git pull` on `main`, whose
upstream is `origin/main`, brings in the server's `main`, and nothing else.

The reflog records the pull under its own name, `pull:`, followed by what the
merge did (Chapter 36).

## When the branches have diverged

Bob pushed a commit, and Ada, without pulling, committed a note:

```console
$ git pull; echo "exit $?"
From ../server/atlas
   975678a..f0947d0  main       -> origin/main
hint: You have divergent branches and need to specify how to reconcile them.
hint: You can do so by running one of the following commands sometime before
hint: your next pull:
hint:
hint:   git config pull.rebase false  # merge
hint:   git config pull.rebase true   # rebase
hint:   git config pull.ff only       # fast-forward only
hint:
hint: You can replace "git config" with "git config --global" to set a default
hint: preference for all repositories. You can also pass --rebase, --no-rebase,
hint: or --ff-only on the command line to override the configured default per
hint: invocation.
fatal: Need to specify how to reconcile divergent branches.
exit 128
$ git status -sb
## main...origin/main [ahead 1, behind 1]
$ git log --oneline --graph --all -4
* 824cd19 Write a note
| * f0947d0 Add the Americas
|/  
* 975678a Add Asia
* 3fa97e2 Add Africa
```

The fetch happened, and then pull stopped before changing anything. Ada's
branch and the server's have *diverged*: each has a commit the other lacks,
`[ahead 1, behind 1]` in `git status` (Chapter 10), a fork in the graph. Moving
`main` forward to `f0947d0` would drop Ada's note, so there is no fast-forward,
and Git will not choose between the two ways of keeping both without being told.

The hint's commands are in the older `git config <name> <value>` form, which
still works; `git config set pull.rebase false` is the current spelling
(Chapter 62).

> **Since Git 2.34.** This refusal, also in the 2.33.1 maintenance release,
> confirmed from Git's source. An older Git merges instead, and from Git 2.27
> prints a warning that pulling without choosing is discouraged.

The three answers, each shown from this same state:

### Merging

```console
$ git pull --no-rebase
Merge made by the 'ort' strategy.
 maps/americas.txt | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 maps/americas.txt
$ git log --oneline --graph -4
*   a085811 Merge branch 'main' of ../server/atlas
|\  
| * f0947d0 Add the Americas
* | 824cd19 Write a note
|/  
* 975678a Add Asia
```

`--no-rebase` merges: a merge commit joins Ada's note and Bob's commit, and both
keep their hashes. Git's documentation calls `--no-rebase` shorthand for
`--rebase=false`. The message names the branch and the repository it came
from. There was no fetch output, because the refused pull had already fetched.

On a terminal, a merge that makes a commit opens your editor on this message
first, as `git merge` does (Chapter 25); `--no-edit` accepts it without asking.
The sandbox is not a terminal, so no editor opened here.

### Rebasing

```console
$ git pull --rebase
Rebasing (1/1)
Successfully rebased and updated refs/heads/main.
$ git log --oneline --graph -4
* e572ee6 Write a note
* f0947d0 Add the Americas
* 975678a Add Asia
* 3fa97e2 Add Africa
```

`--rebase`, or `-r`, replays Ada's commit on top of Bob's; the documentation
gives `--rebase=true` as the same thing spelled out. The history is a
straight line and there is no merge commit, but "Write a note" is a new commit,
`e572ee6` instead of `824cd19`, because its parent changed (Chapter 33). On a
terminal, `Rebasing (1/1)` is redrawn in place and the next line replaces it.

### Fast-forward only

```console
$ git pull --ff-only; echo "exit $?"
hint: Diverging branches can't be fast-forwarded, you need to either:
hint:
hint: 	git merge --no-ff
hint:
hint: or:
hint:
hint: 	git rebase
hint:
hint: Disable this message with "git config set advice.diverging false"
fatal: Not possible to fast-forward, aborting.
exit 128
```

`--ff-only` refuses too, with a different message: it is not asking you to
choose, it is telling you that the one thing it is allowed to do is impossible.
Nothing changed. When a fast-forward is possible, it makes one, like the pulls
in [Reading the output](#reading-the-output). The hint's `git merge --no-ff` and
`git rebase` work on what was fetched, since `origin/main` is already up to date.

### Which to choose

| Command | Your branch after a diverged pull | Your commits | When it fits |
|---|---|---|---|
| `git pull --no-rebase` | a merge commit on top | kept as they were | the commits are already shared, or the team wants merges recorded |
| `git pull --rebase` | your commits on top of the server's, in a line | replaced by copies with new hashes | the commits are only in your clone, which is the usual case before a push |
| `git pull --ff-only` | unchanged, and an error | kept | you want to look first, then decide |

Rebasing rewrites your commits, so the rule of Chapter 28 applies: do it only to
commits nobody else has. Commits you have not pushed qualify, which is why
`--rebase` is the common choice for pulling before a push, and why it avoids a
history full of "Merge branch 'main' of ..." commits that record nothing but the
timing of two people's work. `pull.ff=only`, suggested in Chapter 3, never
changes history behind your back: an ordinary pull fast-forwards, and a diverged
one stops and waits for `--rebase` or `--no-rebase`.

## Choosing a default

The same diverged state, with Ada's branch put back before each command:

```console
$ git config set pull.rebase true && git pull -q && git log --oneline -2
e572ee6 Write a note
f0947d0 Add the Americas
$ git pull --no-rebase -q && git log --oneline -1
a085811 Merge branch 'main' of ../server/atlas
$ git config set branch.main.rebase false && git pull -q && git log --oneline -1
a085811 Merge branch 'main' of ../server/atlas
```

`pull.rebase=true` made a plain pull rebase, and `-q` kept the pulls quiet. On
the command line, `--no-rebase` overrode the setting for one pull.
`branch.<name>.rebase` sets it for one branch and wins over `pull.rebase`, so
`main` merged again. The two merges produced the same commit, `a085811`, as the
merge in [Merging](#merging): the same parents, files and message, and in the
sandbox the same time (Chapter 2).

| Value of `pull.rebase` or `branch.<name>.rebase` | A pull on a diverged branch |
|---|---|
| `pull.rebase=false` | merges |
| `pull.rebase=true` | rebases |
| `pull.rebase=merges` | rebases, keeping local merge commits |
| `pull.rebase=interactive` | rebases, opening the todo list |
| not set | refuses, unless `pull.ff` says otherwise |

| Value of `pull.ff` | A pull that could fast-forward | A pull on a diverged branch |
|---|---|---|
| `pull.ff=only` | fast-forwards | refuses |
| `pull.ff=true` | fast-forwards | merges, without asking |
| `pull.ff=false` | makes a merge commit anyway | merges |
| not set | fast-forwards | depends on `pull.rebase` |

`branch.autoSetupRebase` sets `branch.<name>.rebase=true` on new branches
automatically, as Chapter 23 shows. Chapter 39 shows how `git remote show`
reports a branch that pulls with rebase.

### Which setting wins

`git -c <name>=<value>` sets a configuration value for one command only
(Chapter 62), which makes the combinations quick to try:

```console
$ git -c pull.ff=only pull -q --rebase && git log --oneline -1
e572ee6 Write a note
$ git pull -q --ff-only --rebase 2>&1 | tail -1
fatal: Not possible to fast-forward, aborting.
$ git -c pull.ff=only -c pull.rebase=true pull -q 2>&1 | tail -1
fatal: Not possible to fast-forward, aborting.
$ git pull -q --ff && git log --oneline -1
a085811 Merge branch 'main' of ../server/atlas
```

An explicit `--rebase` on the command line overrides `pull.ff=only` from the
configuration, and rebased. Both on the command line, `--ff-only` wins over
`--rebase`, and both in the configuration, `pull.ff=only` wins over
`pull.rebase=true`; `tail -1` kept only the last line of the refusal. Git's
source says so in as many words: `--ff-only` takes precedence over rebase, except
that a `--rebase` typed on the command line cancels an `only` read from the
configuration.

`--ff`, or `pull.ff=true`, counts as a decision, so a diverged pull merged
without the hint. That is the one way to get a merge while believing you asked
only for fast-forwards.

```console
$ git pull --rebase=preserve; echo "exit $?"
error: preserve: 'preserve' superseded by 'merges'
error: invalid value for '--rebase': 'preserve'
exit 129
$ git -c pull.rebase=sometimes pull; echo "exit $?"
fatal: invalid value for 'pull.rebase': 'sometimes'
exit 128
```

`preserve` was the old way to keep merge commits in a rebase; Git 2.34 removed
it, and a configuration that still says `pull.rebase=preserve` stops every pull.
Change it to `merges`. Any other unknown value is an error too, and nothing is
fetched.

| Situation | What decides |
|---|---|
| `--ff-only` and `--rebase` both typed | `--ff-only` |
| `--rebase` or `--no-rebase` typed | it, over any setting |
| `--ff`, `--no-ff` or `--ff-only` typed | it, over `pull.ff` |
| nothing typed | `branch.<name>.rebase`, else `pull.rebase`; and `pull.ff`, with `pull.ff=only` winning over a rebase setting |
| nothing typed or set, branches diverged | the refusal |

## More about pulling with rebase

### Local merge commits

Ada had merged a branch of her own into `main` before pulling:

```console
$ git log --oneline --graph -5
*   274adae Merge branch 'borders'
|\  
| * f0aa472 Draw the borders
|/  
* 824cd19 Write a note
* 975678a Add Asia
* 3fa97e2 Add Africa
$ git pull -q --rebase && git log --oneline --graph -5
* 15e854f Draw the borders
* 2ae6f41 Write a note
* f0947d0 Add the Americas
* 975678a Add Asia
* 3fa97e2 Add Africa
$ git pull -q --rebase=merges && git log --oneline --graph -6
*   959b4c0 Merge branch 'borders'
|\  
| * 15e854f Draw the borders
|/  
* 2ae6f41 Write a note
* f0947d0 Add the Americas
* 975678a Add Asia
* 3fa97e2 Add Africa
```

A plain rebase replays commits one after another, so the merge disappeared and
its branch's commit joined the line. `--rebase=merges` passes
`--rebase-merges` to `git rebase` and rebuilds the merge on top of Bob's commit
(Chapter 34). The second command started from the state in the first block.

### Choosing what to replay

```console
$ GIT_SEQUENCE_EDITOR=cat git pull --rebase=interactive
pick 824cd19 # Write a note
pick f0aa472 # Draw the borders

# Rebase f0947d0..274adae onto f0947d0 (2 commands)
...
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/main.
```

`--rebase=interactive` runs `git rebase --interactive`, so the todo list opens in
your editor before anything is replayed, and you can reorder, squash or drop
commits as Chapter 34 describes. `GIT_SEQUENCE_EDITOR=cat` stands in for the
editor: it prints the list and accepts it unchanged. The command help after the
first lines is cut.

### When the server's branch was rewritten

Ada rebased her note onto Bob's "Add the Americas". Bob then rewrote that commit,
adding Canada to the file, and force-pushed it:

```console
$ git log --oneline --graph -3
* 2ae6f41 Write a note
* f0947d0 Add the Americas
* 975678a Add Asia
$ git fetch && git rebase origin/main; echo "exit $?"
From ../server/atlas
 + f0947d0...665b254 main       -> origin/main  (forced update)
Rebasing (1/2)
Auto-merging maps/americas.txt
CONFLICT (add/add): Merge conflict in maps/americas.txt
error: could not apply f0947d0... Add the Americas
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
Could not apply f0947d0... # Add the Americas
exit 1
$ git rebase --abort
```

Rebasing onto `origin/main` replays every commit Ada's branch has that the new
`origin/main` lacks, and that includes Bob's old "Add the Americas", which is not
Ada's at all. Its file clashes with the rewritten one. This is the situation
Chapter 28 describes, from the side of the person it happens to.

```console
$ git merge-base --fork-point origin/main main
f0947d046f416b6247c15e7cc85fe4c714842100
$ GIT_TRACE=1 git pull --rebase 2>&1 >/dev/null | grep -o 'run_command: git \(fetch\|merge\|rebase\).*'
run_command: git merge-base --fork-point refs/remotes/origin/main main
run_command: git fetch --update-head-ok
run_command: git rebase --no-autostash --onto 665b254b81753136b3ff9df4d3fcccae64d8287a f0947d046f416b6247c15e7cc85fe4c714842100
$ git log --oneline --graph -3
* be097ba Write a note
* 665b254 Add the Americas, with Canada
* 975678a Add Asia
```

`git merge-base --fork-point` looks through the reflog of `origin/main`, which
recorded that it once pointed at `f0947d0`, and answers that Ada's branch was
built on that commit (Chapter 33). The trace shows a pull with rebase asking the
same question before it fetches, and then running
`git rebase --onto <new origin/main> <fork point>`: replay only what came after
the fork point. So only Ada's note was moved onto the rewritten commit. The
`--no-autostash` is pull passing on `rebase.autoStash`, which is not set. Git's documentation for `--rebase` describes this as using the
remote-tracking branch's record "to avoid rebasing non-local changes".

`git rebase` with no upstream named uses the fork point in the same way; naming
`origin/main`, as above, turns it off (Chapter 33).

## Uncommitted changes

Bob pushed a commit, and Ada had edited `notes.txt` without committing:

```console
$ git status --short && git pull --rebase; echo "exit $?"
 M notes.txt
error: cannot pull with rebase: You have unstaged changes.
error: Please commit or stash them.
exit 128
$ git pull && git status --short
From ../server/atlas
   be097ba..ffb83e3  main       -> origin/main
Updating be097ba..ffb83e3
Fast-forward
 maps/asia.txt | 1 +
 1 file changed, 1 insertion(+)
 M notes.txt
```

A pull with rebase refuses any uncommitted change to a tracked file, before it
even fetches. A pull that merges or fast-forwards does not ask: it goes ahead
whenever the files it has to change are not the ones you changed, and the edit to
`notes.txt` was still there afterwards.

Bob pushed a change to `maps/asia.txt`, which Ada had also edited:

```console
$ git pull; echo "exit $?"
From ../server/atlas
   ffb83e3..abf607a  main       -> origin/main
error: Your local changes to the following files would be overwritten by merge:
	maps/asia.txt
Please commit your changes or stash them before you merge.
Aborting
Updating ffb83e3..abf607a
exit 1
```

Now the merge would have had to overwrite the edit, so it refused, and changed
nothing; the fetch had already happened. `Updating` appears after the error, but
Git's source prints it first, to standard output, which reached the pipe later
than the error on standard error; a terminal shows it first. Commit the change,
stash it (Chapter 55), or use [autostash](#autostash).

### Untracked files

Bob pushed a new file, `maps/oceania.txt`, and Ada had a file of that name that
she had never added:

```console
$ git status --short && git pull; echo "exit $?"
?? maps/oceania.txt
From ../server/atlas
   abf607a..9953502  main       -> origin/main
error: The following untracked working tree files would be overwritten by merge:
	maps/oceania.txt
Please move or remove them before you merge.
Aborting
Updating abf607a..9953502
exit 1
```

Git does not track the file, but the pull would have to create a file at that
path, and it will not throw away a file it cannot get back. Rename or move yours,
pull, and compare. An ignored file in the same place is treated differently: it
is overwritten without a word, which was tested for this chapter, and is the rule
Chapter 24 shows for `git switch`.

### Autostash

```console
$ git pull --rebase --autostash && git status --short
From ../server/atlas
   9953502..b5cccfb  main       -> origin/main
Updating 9953502..b5cccfb
Created autostash: 5871c12
Fast-forward
 maps/asia.txt | 1 +
 1 file changed, 1 insertion(+)
Applied autostash.
 M notes.txt
$ git config set pull.autoStash true && git pull --rebase && git status --short
From ../server/atlas
   b5cccfb..05b1f04  main       -> origin/main
Updating b5cccfb..05b1f04
Created autostash: 965d038
Fast-forward
 maps/oceania.txt | 1 +
 1 file changed, 1 insertion(+)
Applied autostash.
 M notes.txt
```

`--autostash` stashed the uncommitted change, pulled, and applied the stash
again: the rebase that refused before went ahead, and `notes.txt` is still
modified. `pull.autoStash=true` does the same for every pull; without it, the
second command would have refused as the first section's did. Neither pull had
anything of Ada's to replay, so each fast-forwarded, which is why the output is
a merge's: Git's source skips the rebase when a fast-forward will do.

| Setting | Applies to |
|---|---|
| `pull.autoStash` | every pull; when set, the two below are ignored for pulls |
| `rebase.autoStash` | `git rebase`, and a pull with rebase |
| `merge.autoStash` | `git merge`, and a pull that merges |

> **Since Git 2.27.** `--autostash` for a pull that merges; before, it worked
> only with `--rebase`. **Since Git 2.51.** `pull.autoStash`.

Bob pushed a change to `notes.txt`, the file Ada had edited:

```console
$ git pull --autostash; echo "exit $?"
From ../server/atlas
   05b1f04..0342def  main       -> origin/main
Updating 05b1f04..0342def
Created autostash: 6b3677f
Fast-forward
 notes.txt | 1 +
 1 file changed, 1 insertion(+)
Your local changes are stashed, however applying them
resulted in conflicts.  You can either resolve the conflicts
and then discard the stash with "git stash drop", or, if you
do not want to resolve them now, run "git reset --hard" and
apply the local changes later by running "git stash pop".
exit 0
$ git status --short && git stash list
UU notes.txt
stash@{0}: autostash
$ printf 'Check the borders\nCheck the rivers\nCheck the seas\n' > notes.txt && git restore --staged notes.txt && git stash drop && git status --short
Dropped refs/stash@{0} (6b3677fdf9d11d915c323237f47050eb2a66af42)
 M notes.txt
```

The pull itself succeeded, and the exit status says so, but putting the change
back conflicted with Bob's. The file has conflict markers, and the change is
also kept as a stash entry, so nothing is lost whichever way you go. Here the
file was written with both lines, `git restore --staged` cleared the conflict
from the index while keeping the file (Chapter 14), and the stash was dropped
because its content was now in the file.

## When a pull stops with a conflict

Bob pushed "Add France" and Ada committed "Add Spain", on the same line of the
same file:

```console
$ git pull --no-rebase; echo "exit $?"
From ../server/atlas
   0342def..9fbe458  main       -> origin/main
Auto-merging maps/europe.txt
CONFLICT (content): Merge conflict in maps/europe.txt
Automatic merge failed; fix conflicts and then commit the result.
exit 1
$ git pull; echo "exit $?"
error: Pulling is not possible because you have unmerged files.
hint: Fix them up in the work tree, and then use 'git add/rm <file>'
hint: as appropriate to mark resolution and make a commit.
fatal: Exiting because of an unresolved conflict.
exit 128
$ printf 'Europe\nFrance\nSpain\n' > maps/europe.txt && git add maps/europe.txt && git pull; echo "exit $?"
error: You have not concluded your merge (MERGE_HEAD exists).
hint: Please, commit your changes before merging.
fatal: Exiting because of unfinished merge.
exit 128
$ git merge --abort && git log --oneline -1
565677f Add Spain
```

A pull that stops with a conflict leaves an ordinary unfinished merge, and
Chapter 26 covers resolving it. What matters here is that it has to be
finished before you pull again. With conflicts still marked, pull refuses; with
them resolved and added, it still refuses, because the merge commit has not
been made: `MERGE_HEAD`, the file recording the other parent, still exists.
Finish with `git commit`, or back out with `git merge --abort`, which put `main`
back on "Add Spain".

```console
$ git pull --rebase; echo "exit $?"
Rebasing (1/1)
Auto-merging maps/europe.txt
CONFLICT (content): Merge conflict in maps/europe.txt
error: could not apply 565677f... Add Spain
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
Could not apply 565677f... # Add Spain
exit 1
$ git rebase --abort && git log --oneline -1
565677f Add Spain
```

With rebase, the stop is an unfinished rebase: finish with `git add` and
`git rebase --continue`, or `git rebase --abort` (Chapter 33). The fetch is not
undone by either, and does not need to be.

| The pull stopped in | Finish with | Back out with |
|---|---|---|
| a merge | `git add`, then `git commit` | `git merge --abort` |
| a rebase | `git add`, then `git rebase --continue` | `git rebase --abort` |
| an autostash that conflicted | resolve, then `git stash drop` | `git reset --hard`, then `git stash pop` later |

## Pulling a particular branch

Ada's `main` was put back to match the server. Bob pushed a commit to `deserts`:

```console
$ git switch -q deserts && git branch -vv --list deserts
* deserts b51ebb0 [origin/deserts] List deserts
$ git pull && git pull --no-rebase -n origin main && git log --oneline --graph -4
From ../server/atlas
   b51ebb0..744bdd5  deserts    -> origin/deserts
Updating b51ebb0..744bdd5
Fast-forward
 deserts.txt | 1 +
 1 file changed, 1 insertion(+)
From ../server/atlas
 * branch            main       -> FETCH_HEAD
Merge made by the 'ort' strategy.
*   7ebb4ec Merge branch 'main' of ../server/atlas into deserts
|\  
| * 9fbe458 Add France
| * 0342def Check the seas
| * 05b1f04 Add Fiji
```

`git switch deserts` made a local branch with `origin/deserts` as its upstream
(Chapter 24), and a plain `git pull` on it fast-forwarded to Bob's commit: a
pull works on whichever branch you are on, with that branch's upstream.

`git pull origin main` names the branch to bring in instead, which is how you
update a feature branch with the latest `main`: the server's `main` was merged
into `deserts`. Because `deserts` is not `main`, the message ends in
`into deserts`; Chapter 25 explains which branch names leave that out. `-n`, or
`--no-stat`, left out the diffstat. Only the branch you
name is merged, and only the branch you are on changes; Ada's local `main` was
not touched.

### Several branches at once

```console
$ git pull --no-rebase origin deserts rivers && git log --oneline --graph -4
From ../server/atlas
 * branch            deserts    -> FETCH_HEAD
 * branch            rivers     -> FETCH_HEAD
Trying simple merge with 744bdd5ee2dd9a28a015913c9e388ff4c4877f38
Trying simple merge with f5776f0ab994df8a27ee370f02a39dbe1fe2e312
Merge made by the 'octopus' strategy.
 deserts.txt | 2 ++
 rivers.txt  | 1 +
 2 files changed, 3 insertions(+)
 create mode 100644 deserts.txt
 create mode 100644 rivers.txt
*-.   ff758bf Merge branches 'deserts' and 'rivers' of ../server/atlas
|\ \  
| | * f5776f0 List rivers
| * | 744bdd5 Add the Gobi desert
| * | b51ebb0 List deserts
| |/  
$ git pull --rebase origin deserts rivers; echo "exit $?"
From ../server/atlas
 * branch            deserts    -> FETCH_HEAD
 * branch            rivers     -> FETCH_HEAD
fatal: Cannot rebase onto multiple branches.
exit 128
```

Every branch named on the command line is for merging, so two branches make an
*octopus* merge, one commit with three parents (Chapter 25). Git's documentation
points out the difference from the configuration: several `remote.<name>.fetch`
lines fetch several branches but merge only one. A rebase, or a fast-forward, can
only go onto one commit, so `--rebase` refused; `--ff-only` refuses the same way,
with "Cannot fast-forward to multiple branches."

### From a URL

Bob pushed a new branch, `lakes`:

```console
$ git pull --no-rebase ../server/atlas.git lakes && git branch -r --list origin/lakes
From ../server/atlas
 * branch            lakes      -> FETCH_HEAD
Updating 9fbe458..be995c0
Fast-forward
 lakes.txt | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 lakes.txt
```

A URL works where a remote's name does. The branch was fetched into
`FETCH_HEAD` only and merged, here as a fast-forward, and no `origin/lakes` was
created, as the empty output of `git branch -r` shows: without a remote there is
no fetch refspec to say where a copy would go (Chapter 41). This is how you pull
once from someone's repository without adding it as a remote.

### From this repository

```console
$ git pull --no-rebase . deserts && git log --oneline --graph -4
From .
 * branch            deserts    -> FETCH_HEAD
Merge made by the 'ort' strategy.
 deserts.txt | 2 ++
 1 file changed, 2 insertions(+)
 create mode 100644 deserts.txt
*   bf7929d Merge branch 'deserts'
|\  
| * 744bdd5 Add the Gobi desert
| * b51ebb0 List deserts
* | 9fbe458 Add France
```

`.` is the current repository used as a URL, so this pulls the local branch
`deserts`: `git merge deserts` by a longer road, and tried from the same state
for this chapter, the two made the same commit. A branch whose
upstream is another local branch has `branch.<name>.remote` set to `.`
(Chapter 23), and a plain `git pull` on it does exactly this.

## When pull does not know what to merge

```console
$ git switch -q -c maps && git pull; echo "exit $?"
There is no tracking information for the current branch.
Please specify which branch you want to merge with.
See git-pull(1) for details.

    git pull <remote> <branch>

If you wish to set tracking information for this branch you can do so with:

    git branch --set-upstream-to=origin/<branch> maps

exit 1
$ git pull --set-upstream origin main && git branch -vv --list maps
From ../server/atlas
 * branch            main       -> FETCH_HEAD
Already up to date.
* maps 9fbe458 [origin/main] Add France
```

A new local branch has no upstream, so a plain pull fetches and then has nothing
marked for merging. The message offers both fixes: name the branch this time, or
set an upstream with `git branch --set-upstream-to` (Chapter 23).
`--set-upstream` does both in one command: it pulled `main` and made `origin/main`
the upstream of `maps`.

> **Since Git 2.24.** `--set-upstream`.

```console
$ git remote add bob-fork ../server/atlas.git && git pull bob-fork; echo "exit $?"
From ../server/atlas
 * [new branch]      deserts    -> bob-fork/deserts
 * [new branch]      lakes      -> bob-fork/lakes
 * [new branch]      main       -> bob-fork/main
 * [new branch]      rivers     -> bob-fork/rivers
You asked to pull from the remote 'bob-fork', but did not specify
a branch. Because this is not the default configured remote
for your current branch, you must specify a branch on the command line.
exit 1
$ git switch -q --detach && git pull; echo "exit $?"
You are not currently on a branch.
Please specify which branch you want to merge with.
See git-pull(1) for details.

    git pull <remote> <branch>

exit 1
```

A remote other than the branch's own has no upstream to offer, so pulling from
it needs a branch name: `git pull bob-fork main`. The fetch happened anyway, and
created the remote-tracking branches. A detached `HEAD` has no branch and so no
upstream (Chapter 24); it too needs a branch named.

Ada had a branch `old-idea` whose upstream was `origin/old-idea`, and Bob deleted
that branch on the server:

```console
$ git pull; echo "exit $?"
Your configuration specifies to merge with the ref 'refs/heads/old-idea'
from the remote, but no such ref was fetched.
exit 1
$ git pull origin 'refs/heads/nosuch/*:refs/remotes/origin/nosuch/*'; echo "exit $?"
There are no candidates for merging among the refs that you just fetched.
Generally this means that you provided a wildcard refspec which had no
matches on the remote end.
exit 1
```

The upstream is configured, but the server no longer has the branch, so the
fetch brought nothing to merge. Point the branch at another upstream, or remove
the setting with `git branch --unset-upstream` (Chapter 23); `git status` calls
this upstream `gone` once a fetch has pruned it (Chapter 41).

A refspec with `*` that matches nothing on the server leaves nothing to merge
either. Refspecs with `*` are Chapter 44.

| Message | Cause | Fix |
|---|---|---|
| There is no tracking information for the current branch | the branch has no upstream | `git pull <remote> <branch>`, or `--set-upstream`, or `git branch -u` |
| You asked to pull from the remote '...', but did not specify a branch | the remote is not the branch's | name the branch |
| You are not currently on a branch | detached `HEAD` | switch to a branch, or name one |
| Your configuration specifies to merge with the ref '...' | the upstream was deleted on the server | set another upstream, or unset it |
| There are no candidates for merging | a pattern refspec matched nothing | check the pattern |

## Pulling into an empty repository

In a new, empty repository with `origin` added:

```console
$ git remote add origin ../server/atlas.git && git pull origin deserts rivers; echo "exit $?"
From ../server/atlas
 * branch            deserts    -> FETCH_HEAD
 * branch            rivers     -> FETCH_HEAD
 * [new branch]      deserts    -> origin/deserts
 * [new branch]      rivers     -> origin/rivers
fatal: Cannot merge multiple branches into empty head.
exit 128
$ git pull origin main && git log --oneline -2 && git status -sb
From ../server/atlas
 * branch            main       -> FETCH_HEAD
 * [new branch]      main       -> origin/main
9fbe458 Add France
0342def Check the seas
## main
```

With no commit on the current branch, there is nothing to merge with, so pull
simply makes the branch point at what it fetched and checks out its files. That
works for one branch and not for two, which have no single commit to point at.
`main` has no upstream afterwards, as `## main` shows; `--set-upstream` or
`git clone` (Chapter 9) would have set one.

## Fetch options through pull

Bob pushed a commit:

```console
$ git pull --dry-run && git log --oneline -1 && git log --oneline -1 origin/main
From ../server/atlas
   9fbe458..c92c059  main       -> origin/main
9fbe458 Add France
9fbe458 Add France
$ git pull -q && git log --oneline -1
c92c059 Add Antarctica
```

`--dry-run` is passed to fetch, and then pull stops: it printed what the fetch
would do, and neither `main` nor `origin/main` moved. It does not show what the
merge would do. To see that, fetch, and compare with `git log main..origin/main`
or `git diff main...origin/main` (Chapter 18, Chapter 13).

The options in the "Passed to fetch" table above behave as Chapter 41 describes,
and then the pull integrates as usual. Two of them change what gets merged.

### Appending to FETCH_HEAD

Bob pushed a commit to `deserts` and another to `main`:

```console
$ git fetch origin deserts && git pull --append --no-rebase && cat .git/FETCH_HEAD
From ../server/atlas
 * branch            deserts    -> FETCH_HEAD
   744bdd5..85ce980  deserts    -> origin/deserts
From ../server/atlas
   c92c059..55adaeb  main       -> origin/main
Trying simple merge with 85ce980546af7168288b2d5299b9f0aadf603895
Trying simple merge with 55adaeb1b401963a219afd978b7024d4dbef8d81
Merge made by the 'octopus' strategy.
 deserts.txt     | 3 +++
 maps/arctic.txt | 1 +
 2 files changed, 4 insertions(+)
 create mode 100644 deserts.txt
 create mode 100644 maps/arctic.txt
85ce980546af7168288b2d5299b9f0aadf603895		branch 'deserts' of ../server/atlas
55adaeb1b401963a219afd978b7024d4dbef8d81		branch 'main' of ../server/atlas
85ce980546af7168288b2d5299b9f0aadf603895	not-for-merge	branch 'deserts' of ../server/atlas
be995c079265e7b72846580b85f97ea2f1661b10	not-for-merge	branch 'lakes' of ../server/atlas
f5776f0ab994df8a27ee370f02a39dbe1fe2e312	not-for-merge	branch 'rivers' of ../server/atlas
$ git log --oneline --graph -4
*   add01b4 Merge branches 'deserts' and 'main' of ../server/atlas
|\  
| * 55adaeb Add the Arctic
| * c92c059 Add Antarctica
| * 9fbe458 Add France
```

A pull merges every line of `FETCH_HEAD` not marked `not-for-merge`, and with
`--append` the file still held the earlier `git fetch origin deserts`, where
`deserts`, named on the command line, was for merging. So the pull made an
octopus merge of `deserts` and `main` into Ada's `main`. `-a` exists for scripts
that fetch in several steps; with pull, leave it out.

```console
$ git pull --no-rebase && git log --oneline -1
Updating c92c059..55adaeb
Fast-forward
 maps/arctic.txt | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 maps/arctic.txt
55adaeb Add the Arctic
```

Undone with `git reset --hard ORIG_HEAD` ([Undoing a pull](#undoing-a-pull)),
the same pull without `--append` merged only `main`, as a fast-forward.

### Into the current branch

Bob pushed a commit:

```console
$ git pull origin main:main
From ../server/atlas
   55adaeb..4e45bb2  main       -> main
   55adaeb..4e45bb2  main       -> origin/main
warning: fetch updated the current branch head.
fast-forwarding your working tree from
commit 55adaeb1b401963a219afd978b7024d4dbef8d81.
Already up to date.
```

The refspec `main:main` told the fetch to update Ada's local `main`, the branch
she is on, which fetch alone refuses and pull allows through
`--update-head-ok`. The branch moved during the fetch, so pull warned and
brought the working tree up to the new commit itself, and the merge then had
nothing left to do. It worked because it was a fast-forward; had Ada's `main`
had commits of its own, the fetch would have rejected the update. Name only the
source, `git pull origin main`, and none of this happens.

## Unrelated histories

`../gazetteer` is a separate repository, started on its own:

```console
$ git pull --no-rebase ../gazetteer main; echo "exit $?"
From ../gazetteer
 * branch            main       -> FETCH_HEAD
fatal: refusing to merge unrelated histories
exit 128
$ git pull --no-rebase --allow-unrelated-histories ../gazetteer main && git log --oneline --graph -3
From ../gazetteer
 * branch            main       -> FETCH_HEAD
Merge made by the 'ort' strategy.
 places.txt | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 places.txt
*   233554a Merge branch 'main' of ../gazetteer
|\  
| * 22c3837 Start the gazetteer
* 4e45bb2 Add islands
```

Two histories with no commit in common are usually a mistake: the wrong URL, or
a repository created on a server with a README and then pulled into a project
started locally. `--allow-unrelated-histories` merges them anyway, into one
commit whose parents have no shared past; it is the right choice when combining
two projects on purpose (Chapter 25).

## Undoing a pull

Bob pushed a commit and Ada committed another note:

```console
$ git pull --no-rebase && git reset --hard ORIG_HEAD && git reflog -2
From ../server/atlas
   4e45bb2..c2c00b7  main       -> origin/main
Merge made by the 'ort' strategy.
 maps/volcanoes.txt | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 maps/volcanoes.txt
HEAD is now at 41074c7 Write another note
41074c7 HEAD@{0}: reset: moving to ORIG_HEAD
0d279e1 HEAD@{1}: pull --no-rebase: Merge made by the 'ort' strategy.
$ git pull -q --rebase && git log --oneline -2 && git reset --hard ORIG_HEAD
6ba3c0e Write another note
c2c00b7 Map the volcanoes
HEAD is now at 41074c7 Write another note
$ git status -sb
## main...origin/main [ahead 1, behind 1]
```

A merge, a rebase and a fast-forward all set `ORIG_HEAD` to where the branch was
before, and `git reset --hard ORIG_HEAD` puts it back (Chapter 30). Both pulls
were undone, and Ada's `main` is where it started, with her own note
`41074c7`. The fetch is not undone, and does not need to be: `origin/main` is
only a record of the server.

`ORIG_HEAD` is overwritten by the next command that sets it. When something
else has happened since, find the position before the pull in the reflog, where
the pull is labelled `pull`, and reset to that entry (Chapter 36).

> **Careful.** `git reset --hard` also throws away uncommitted changes. Commit
> or stash them first. A pull that has been pushed is no longer yours alone to
> undo; `git revert` is the tool for that (Chapter 31).

## pull and its neighbours

```console
$ git pull -q --no-rebase && git rev-parse HEAD
0d279e15fafec2e1b88ff284aecf8bfcbbecea21
$ git merge -q FETCH_HEAD && git rev-parse HEAD
0d279e15fafec2e1b88ff284aecf8bfcbbecea21
$ git merge -q origin/main && git rev-parse HEAD && git log --format=%s -1
40870cae93e54356ec83839507b1c949c6cb1f25
Merge remote-tracking branch 'origin/main'
```

Each command started from the same state. The pull and a plain
`git merge FETCH_HEAD` after it made the same commit, hash for hash. Merging
`origin/main` joins the same commits, but writes the message "Merge
remote-tracking branch 'origin/main'", so it is a different commit. The files are
identical either way.

So a pull is a fetch and a merge, and the reasons to do the two separately are
about the pause in between: after `git fetch` you can look at what arrived with
`git log main..origin/main`, and then decide to merge, rebase or wait.

| To | Use | Difference |
|---|---|---|
| download, and look before changing anything | `git fetch` (Chapter 41) | changes no branch of yours |
| download and update the current branch | `git pull` | fetch, then fast-forward, merge or rebase |
| integrate what you already fetched | `git merge @{u}` (Chapter 25) or `git rebase` (Chapter 33) | no network; message names `origin/main` |
| move forward only if nothing diverged | `git merge --ff-only @{u}`, or `git pull --ff-only` | the same check, without or with a fetch |
| update a branch you are not on | `git fetch origin main:main` (Chapter 41) | fast-forward only, no working tree |
| send your commits | `git push` (Chapter 43) | the other direction |

## The settings

| Setting | Does |
|---|---|
| `pull.rebase` | `true`, `false`, `merges` or `interactive`: how a pull integrates |
| `branch.<name>.rebase` | The same for one branch; wins over `pull.rebase` |
| `branch.autoSetupRebase` | Set `branch.<name>.rebase=true` on new tracking branches (Chapter 23) |
| `pull.ff` | `only`, `true` or `false`; wins over `merge.ff` for pulls |
| `pull.autoStash` | Autostash on every pull; overrides `merge.autoStash` and `rebase.autoStash` for pulls |
| `merge.autoStash`, `rebase.autoStash` | Autostash for merges and rebases, pulls included when `pull.autoStash` is not set |
| `pull.twohead` | The merge strategy for pulling one branch (Chapter 27) |
| `pull.octopus` | The merge strategy for pulling several (Chapter 27) |
| `branch.<name>.remote`, `branch.<name>.merge` | The upstream a plain pull fetches and merges (Chapter 23) |
| `branch.<name>.mergeOptions` | Default options for merges into this branch, pulls included (Chapter 25) |
| `merge.stat`, `merge.log` | The diffstat and the list of commits in the message, as for `git merge` (Chapter 25) |
| `advice.diverging` | `false` removes the hint printed by a refused `--ff-only` |
