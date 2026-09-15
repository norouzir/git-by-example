# Chapter 24. switch, checkout, and detached HEAD

## What it is

`git switch <branch>` makes another branch the current one. It points `HEAD` at
that branch (Chapter 7) and updates the index and your files to match the
branch's commit, so the next commit goes on that branch. Changes you have not
committed come along, as long as they do not collide with the switch. The plain
form answers "take me to that branch".

`git checkout` is the older command. It switches branches the same way, and it
also restores files, a second job `git restore` took over (Chapter 14). This
chapter teaches `git switch` and shows the `checkout` form beside each one, as
the book does throughout.

A *detached HEAD* is the state where `HEAD` names a commit directly instead of a
branch (Chapter 7 introduced it). You can look around and even commit there, but
no branch moves with you. The second half of the chapter is about getting into
that state, working in it, and getting out without losing anything.

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What do `git switch` and `git checkout` do, and which should I use?](#what-it-is)
- [What is a detached HEAD?](#what-it-is)

**[Synopsis](#synopsis)**

- [What can I type after `git switch` and `git checkout`?](#synopsis)

**[Options at a glance](#options-at-a-glance)**

- [Is there a list of every option, and where each is explained?](#options-at-a-glance)

**[The example repository](#the-example-repository)**

- [What repository do the examples use?](#the-example-repository)

**[Switching branches](#switching-branches)**

- [What happens to my files when I switch branches?](#what-switching-changes)
- [How do I go back to the branch I was on before?](#going-back)
- [What does "Already on 'main'" mean?](#going-back)
- [Why does `git switch` say "a branch is expected, got commit"?](#what-switch-refuses)
- [It says the branch "is already used by worktree". What now?](#what-switch-refuses)
- [How do I switch to a branch that is only on the server?](#branches-that-exist-only-on-a-remote)
- [`git switch drinks` says it "matched multiple remote tracking branches". What do I do?](#branches-that-exist-only-on-a-remote)

**[Uncommitted changes](#uncommitted-changes)**

- [Do my uncommitted changes come with me when I switch?](#changes-that-do-not-get-in-the-way)
- [Why does Git refuse to switch because my changes "would be overwritten"?](#changes-that-would-be-overwritten)
- [How do I take my changes to the other branch anyway?](#carrying-changes-with-merge)
- [`git switch -m` stopped with conflicts. How do I get out, and where did my changes go?](#carrying-changes-with-merge)
- [How do I switch and throw my changes away?](#throwing-changes-away)
- [An untracked file is in the way of switching. What are my options?](#untracked-and-ignored-files)
- [Can switching branches overwrite an ignored file?](#untracked-and-ignored-files)

**[Creating a branch and switching to it](#creating-a-branch-and-switching-to-it)**

- [How do I create a branch and switch to it in one step?](#creating-a-branch-and-switching-to-it)
- [How do I start the new branch from a tag or an old commit?](#creating-a-branch-and-switching-to-it)
- [What does `-C` do that `-c` does not?](#creating-a-branch-and-switching-to-it)
- [If creating the branch fails, is the branch left behind?](#creating-a-branch-and-switching-to-it)

**[Detached HEAD](#detached-head)**

- [How do I look at an old commit without making a branch?](#detaching-on-purpose)
- [What happens if I commit while HEAD is detached?](#committing-on-a-detached-head-and-leaving-it)
- [Git warned that I am "leaving 1 commit behind". How do I get it back?](#committing-on-a-detached-head-and-leaving-it)
- [How do I keep the commits I made on a detached HEAD?](#keeping-what-you-made)
- [Why did `git checkout v1.0` print a long message about detached HEAD?](#how-checkout-detaches)
- [How do I turn that message off?](#how-checkout-detaches)

**[Orphan branches](#orphan-branches)**

- [How do I start a branch with no history, such as `gh-pages`?](#orphan-branches)
- [What is the difference between `git switch --orphan` and `git checkout --orphan`?](#orphan-branches)

**[checkout, the classic command](#checkout-the-classic-command)**

- [What are the `git checkout` equivalents of the `git switch` commands?](#the-same-jobs)
- [What does `git checkout` with no arguments do?](#the-same-jobs)
- [Git says my name "could be both a local file and a tracking branch". What do I do?](#a-name-that-could-be-a-file-or-a-branch)
- [Where are the `git checkout` options for files and conflicts explained?](#files-conflicts-and-patches)

**[Progress, quiet and submodules](#progress-quiet-and-submodules)**

- [How do I see progress, or silence the messages?](#progress-quiet-and-submodules)
- [Does switching update my submodules?](#progress-quiet-and-submodules)

**[switch, checkout and their neighbours](#switch-checkout-and-their-neighbours)**

- [Should I use `git switch`, `git checkout`, `git restore`, `git reset` or a worktree?](#switch-checkout-and-their-neighbours)

**[The settings](#the-settings)**

- [Which settings change what `git switch` and `git checkout` do?](#the-settings)

</details>

## Synopsis

```
git switch [<options>] [--no-guess] <branch>
git switch [<options>] --detach [<start-point>]
git switch [<options>] (-c|-C) <new-branch> [<start-point>]
git switch [<options>] --orphan <new-branch>

git checkout [-q] [-f] [-m] [<branch>]
git checkout [-q] [-f] [-m] --detach [<branch>]
git checkout [-q] [-f] [-m] [--detach] <commit>
git checkout [-q] [-f] [-m] [[-b|-B|--orphan] <new-branch>] [<start-point>]
git checkout <tree-ish> [--] <pathspec>...
git checkout [-f|--ours|--theirs|-m|--conflict=<style>] [--] <pathspec>...
git checkout (-p|--patch) [<tree-ish>] [--] [<pathspec>...]
```

Git's documentation lists two more `checkout` forms, which read the paths from a
file with `--pathspec-from-file` instead of the command line.

| Part | Means |
|---|---|
| `<branch>` | The branch to switch to; `-` means the previous one |
| `<new-branch>` | The name of a branch to create |
| `<start-point>` | The commit a new branch, or a detached `HEAD`, starts at; `HEAD` if left out |
| `<commit>` | Any name for a commit: a hash, a tag, `HEAD~2`, `origin/main` (Chapter 18) |
| `<tree-ish>`, `<pathspec>` | For `checkout`'s file forms: where to take files from, and which files (Chapter 14) |

| Command | Does |
|---|---|
| `git switch <branch>` | Switch to a branch |
| `git switch --detach <commit>` | Detach `HEAD` at a commit |
| `git switch -c <new-branch>` | Create a branch and switch to it |
| `git switch --orphan <new-branch>` | Start a branch with no history and no files |
| `git checkout <branch>` | Switch to a branch |
| `git checkout <commit>` | Detach `HEAD` at a commit, which `switch` only does with `--detach` |
| `git checkout -b <new-branch>` | Create a branch and switch to it |
| `git checkout [<tree-ish>] -- <pathspec>` | Restore files; Chapter 14 |

## Options at a glance

### Options of git switch

`git checkout` accepts these too, except `-c`, `-C` and `--discard-changes`,
which it spells differently.

| Option | Does | Covered in |
|---|---|---|
| `-c <new-branch>`, `--create <new-branch>` | Create a branch and switch to it | [Creating a branch and switching to it](#creating-a-branch-and-switching-to-it) |
| `-C <new-branch>`, `--force-create <new-branch>` | The same, resetting a branch that exists | [Creating a branch and switching to it](#creating-a-branch-and-switching-to-it) |
| `-d`, `--detach` | Detach `HEAD` at a commit | [Detaching on purpose](#detaching-on-purpose) |
| `--guess`, `--no-guess` | Create a branch from a remote branch of the same name, or not | [Branches that exist only on a remote](#branches-that-exist-only-on-a-remote) |
| `-t`, `--track[=(direct\|inherit)]` | Create a tracking branch; the values are in Chapter 23 | [Branches that exist only on a remote](#branches-that-exist-only-on-a-remote) |
| `--no-track` | Create a branch with no upstream | [Branches that exist only on a remote](#branches-that-exist-only-on-a-remote) |
| `-m`, `--merge` | Carry changes that collide, by merging them | [Carrying changes with --merge](#carrying-changes-with-merge) |
| `--conflict=<style>` | The same, with conflict markers in this style (Chapter 26) | [Carrying changes with --merge](#carrying-changes-with-merge) |
| `--discard-changes`, `-f`, `--force` | Throw uncommitted changes away | [Throwing changes away](#throwing-changes-away) |
| `--overwrite-ignore`, `--no-overwrite-ignore` | Overwrite ignored files in the way, the default, or refuse | [Untracked and ignored files](#untracked-and-ignored-files) |
| `--ignore-other-worktrees` | Switch to a branch another worktree has checked out | [What switch refuses](#what-switch-refuses) |
| `--orphan <new-branch>` | Start a branch with no history | [Orphan branches](#orphan-branches) |
| `-q`, `--quiet` | No messages | [Progress, quiet and submodules](#progress-quiet-and-submodules) |
| `--progress`, `--no-progress` | Show progress, or not | [Progress, quiet and submodules](#progress-quiet-and-submodules) |
| `--recurse-submodules`, `--no-recurse-submodules` | Update submodules too, Chapter 57 | [Progress, quiet and submodules](#progress-quiet-and-submodules) |

### Options only git checkout has

| Option | Does | Covered in |
|---|---|---|
| `-b <new-branch>` | Create a branch and switch to it, like `switch -c` | [The same jobs](#the-same-jobs) |
| `-B <new-branch>` | The same, resetting a branch that exists, like `switch -C` | [The same jobs](#the-same-jobs) |
| `-l` | Create a reflog for the new branch | [The same jobs](#the-same-jobs) |
| `--ours`, `--theirs` | During a conflict, take one side of a file | Chapter 26 |
| `-p`, `--patch` | Choose hunks to discard | Chapter 14 |
| `-U<n>`, `--unified=<n>`, `--inter-hunk-context=<n>` | Hunk size for `-p` | Chapter 14 |
| `--auto-advance`, `--no-auto-advance` | Move to the next file in `-p` on your own, or not | Chapter 11 |
| `--overlay`, `--no-overlay` | Whether restoring a directory deletes files missing from the source | Chapter 14 |
| `--pathspec-from-file=<file>`, `--pathspec-file-nul` | Read the paths from a file | Chapter 14 |
| `--ignore-skip-worktree-bits` | In a sparse checkout, restore paths outside it too | Chapter 60 |

## The example repository

```console
$ git log --oneline --graph --all --decorate
* 4aed0bd (logs) Track a log on purpose
* bacdce1 (HEAD -> main) Make more soup
| * 9cea87e (origin/pies) Add apple pie
|/  
| * 8be0ecb (origin/drinks, backup/drinks) Add lemonade
|/  
| * f8fdf97 (desserts) Add cake, sweeten the bread
|/  
* 8de51b0 (tag: v1.0, origin/main, origin/HEAD, docs) Add bread
* a8868ab Start the collection
$ git branch -vv
  desserts f8fdf97 Add cake, sweeten the bread
+ docs     8de51b0 (/home/ada/recipes-docs) Add bread
  logs     4aed0bd Track a log on purpose
* main     bacdce1 [origin/main: ahead 1] Make more soup
```

`recipes` is a collection of recipes with two remotes, `origin` and `backup`.

| Name | What it is |
|---|---|
| `main` | the current branch, one commit ahead of `origin/main` |
| `desserts` | adds `cake.txt` and a line to `bread.txt` |
| `docs` | checked out in a second worktree, `../recipes-docs` |
| `logs` | tracks `debug.log`, although `.gitignore` ignores `*.log` |
| `origin/pies` | a branch only on the server |
| `origin/drinks`, `backup/drinks` | a branch on both remotes, not local |
| `v1.0` | a tag on `Add bread` |

## Switching branches

### What switching changes

```console
$ ls
README.md
bread.txt
soup.txt
$ git switch desserts
Switched to branch 'desserts'
$ ls
README.md
bread.txt
cake.txt
soup.txt
$ cat .git/HEAD
ref: refs/heads/desserts
$ cat bread.txt
Flour
Water
Salt
Sugar
$ git switch main
Switched to branch 'main'
Your branch is ahead of 'origin/main' by 1 commit.
  (use "git push" to publish your local commits)
$ ls
README.md
bread.txt
soup.txt
```

Switching rewrote the working tree to `desserts`' commit: `cake.txt` appeared,
`bread.txt` got its extra line, and `.git/HEAD` now names the branch. Switching
back removed `cake.txt` again. Nothing is lost by this, because both versions
are in commits. On a branch with an upstream, Git also reports how it compares,
as `git status` does (Chapter 10).

### Going back

```console
$ git switch -
Switched to branch 'desserts'
$ git switch -
Switched to branch 'main'
Your branch is ahead of 'origin/main' by 1 commit.
  (use "git push" to publish your local commits)
$ git switch @{-1}
Switched to branch 'desserts'
$ git switch -q main
$ git switch main
Already on 'main'
Your branch is ahead of 'origin/main' by 1 commit.
  (use "git push" to publish your local commits)
```

`-` is the branch you were on before, so repeating it goes back and forth.
`@{-1}` is the same, and `@{-2}` the one before that (Chapter 18). Switching to
the branch you are on changes nothing and says "Already on".

### What switch refuses

```console
$ git switch nosuch
fatal: invalid reference: nosuch
$ git switch soup.txt
fatal: invalid reference: soup.txt
$ git switch desserts soup.txt
fatal: only one reference expected
$ git switch HEAD~1
fatal: a branch is expected, got commit 'HEAD~1'
hint: If you want to detach HEAD at the commit, try again with the --detach option.
$ git switch v1.0
fatal: a branch is expected, got tag 'v1.0'
hint: If you want to detach HEAD at the commit, try again with the --detach option.
$ git switch origin/main
fatal: a branch is expected, got remote branch 'origin/main'
hint: If you want to detach HEAD at the commit, try again with the --detach option.
$ git switch docs
fatal: 'docs' is already used by worktree at '/home/ada/recipes-docs'
$ git switch --ignore-other-worktrees docs
Switched to branch 'docs'
$ git switch -q main
$ git -C ../fresh switch -
fatal: invalid reference: @{-1}
```

`git switch` takes only branches. It never treats a name as a file, so it cannot
restore one by accident, and it will not go to a commit, a tag or a
remote-tracking branch unless you ask for a detached `HEAD`
([Detached HEAD](#detached-head)).

A branch checked out in another worktree is refused, because committing in one
worktree would change the files under the other. `--ignore-other-worktrees`
overrides that. In a repository where you have never switched, there is no
previous branch for `-`; `git -C <dir>` runs a command in another directory
(Chapter 9).

> **Careful.** With `--ignore-other-worktrees`, a commit made in one worktree
> moves the branch under the other. Tried here, `git status` in the other worktree
> then showed the commit's change reversed, staged, as if someone had undone it
> there. Use it only for a quick look.

### Branches that exist only on a remote

```console
$ git branch -r
  backup/drinks
  origin/HEAD -> origin/main
  origin/drinks
  origin/main
  origin/pies
$ git switch pies
Switched to a new branch 'pies'
branch 'pies' set up to track 'origin/pies'.
$ git branch -vv --list pies
* pies 9cea87e [origin/pies] Add apple pie
$ git switch -q main
$ git switch drinks
hint: If you meant to check out a remote tracking branch on, e.g. 'origin',
hint: you can do so by fully qualifying the name with the --track option:
hint:
hint:     git switch --track origin/<name>
hint:
hint: If you'd like to always have checkouts of an ambiguous <name> prefer
hint: one remote, e.g. the 'origin' remote, consider setting
hint: checkout.defaultRemote=origin in your config.
fatal: 'drinks' matched multiple (2) remote tracking branches
$ git remote -v
backup	/home/ada/backup.git (fetch)
backup	/home/ada/backup.git (push)
origin	/home/ada/server.git (fetch)
origin	/home/ada/server.git (push)
$ git -c checkout.defaultRemote=origin switch drinks
Switched to a new branch 'drinks'
branch 'drinks' set up to track 'origin/drinks'.
$ git switch -q main
$ git branch -q -D drinks pies
$ git switch --no-guess pies
fatal: invalid reference: pies
$ git -c checkout.guess=false switch pies
fatal: invalid reference: pies
```

There was no local `pies`, but exactly one remote-tracking branch of that name,
so Git created `pies` from `origin/pies`, with it as the upstream, and switched
to it. Git's documentation calls this *guessing*. It is how people usually start
working on a branch a colleague pushed.

`drinks` is on two remotes, so Git would not guess which one. The hint gives two
ways out: name the remote with `--track`, below, or set `checkout.defaultRemote`
to the remote that should win. `git -c <name>=<value>` sets it for one command
(Chapter 62). `--no-guess`, or the setting `checkout.guess=false`, turns guessing
off, and the name must then be a local branch.

> **Worth knowing.** "branch ... set up to track" goes to standard output and
> "Switched to a new branch" to standard error. Git's source prints the tracking
> line first. The examples capture both streams through a pipe, which holds
> standard output back until the end, so here it comes second.

```console
$ git switch --track origin/drinks
Switched to a new branch 'drinks'
branch 'drinks' set up to track 'origin/drinks'.
$ git switch -q main
$ git branch -q -D drinks
$ git switch -c my-drinks origin/drinks
Switched to a new branch 'my-drinks'
branch 'my-drinks' set up to track 'origin/drinks'.
$ git switch -q main
$ git switch --no-track -c drinks2 origin/drinks
Switched to a new branch 'drinks2'
$ git switch -q main
$ git branch -vv --list 'my-drinks' 'drinks2'
  drinks2   8be0ecb Add lemonade
  my-drinks 8be0ecb [origin/drinks] Add lemonade
$ git branch -q -D my-drinks drinks2
```

`--track origin/drinks` without `-c` names the new branch after the part after
the remote's name, `drinks`. With `-c`, you choose the name, and a start point
on a remote still becomes the upstream; `--no-track` prevents that. Chapter 23
covers `--track=inherit` and the setting `branch.autoSetupMerge`, which apply
here too.

## Uncommitted changes

### Changes that do not get in the way

Here `README.md` has an uncommitted edit, and the file is the same on `main` and
`desserts`:

```console
$ git status --short
 M README.md
$ git switch desserts
Switched to branch 'desserts'
M	README.md
$ git status --short
 M README.md
$ git switch -q main
```

Switching does not need a clean working tree. Git updates only the files that
differ between the two commits, so an edit to any other file stays as it is, and
Git lists the files with changes you brought along. This is how you start a
branch for work you have already begun: `git switch -c <name>` takes the edits
with it.

> **Worth knowing.** The list of changed files goes to standard output and
> "Switched to branch" to standard error. Git's source prints the list first; the
> pipe the examples run through shows it second.

### Changes that would be overwritten

Now `bread.txt` has an edit too, and `bread.txt` differs between the branches:

```console
$ git status --short
 M README.md
 M bread.txt
$ git switch desserts
error: Your local changes to the following files would be overwritten by checkout:
	bread.txt
Please commit your changes or stash them before you switch branches.
Aborting
$ git branch --show-current
main
```

Switching would have to replace `bread.txt` with `desserts`' version and lose the
edit, so Git refused and changed nothing, not even `README.md`. The usual ways
on are to commit the edit, to put it aside with `git stash` (Chapter 55), or one
of the options in the next sections.

### Carrying changes with --merge

```console
$ git switch -m desserts
Your local changes are stashed, however applying them
resulted in conflicts.  You can either resolve the conflicts
and then discard the stash with "git stash drop", or, if you
do not want to resolve them now, run "git reset --hard" and
apply the local changes later by running "git stash pop".
Switched to branch 'desserts'
The following paths have local changes:
M	README.md
M	bread.txt
$ git status --short
M  README.md
UU bread.txt
$ cat bread.txt
Flour
Water
Salt
<<<<<<< desserts
Sugar
=======
Yeast
>>>>>>> local
$ git stash list
stash@{0}: autostash while switching to 'desserts'
$ git reset -q --hard
$ git switch -q main
$ git stash pop
On branch main
Your branch is ahead of 'origin/main' by 1 commit.
  (use "git push" to publish your local commits)

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   README.md
	modified:   bread.txt

no changes added to commit (use "git add" and/or "git commit -a")
Dropped refs/stash@{0} (a28709be081fa7c5442b40ece0d385224993c3ef)
$ git stash list
```

`-m` saves your changes in a *stash*, a commit kept aside (Chapter 55), switches,
and applies the stash on top of the new branch. Both sides changed the last
line of `bread.txt`, so applying it conflicted: the file got *conflict markers*,
with `desserts`' line above `=======` and yours, labelled `local`, below, and
`git status` marks it `UU`. Chapter 26 is about resolving conflicts.

Because it conflicted, the stash was kept. Git offers two ways on. Resolve the
file, then `git stash drop`. Or, as here, give up for now: `git reset --hard`
(Chapter 30) throws away the half-merged files, and `git stash pop` puts your
changes back on the original branch, where they came from.

> **Since Git 2.55.** `-m` keeps a stash. Git's release notes say that before,
> it merged your changes directly and gave only one chance to resolve the
> conflict, with nothing to fall back on.

```console
$ git switch --conflict=diff3 desserts
Your local changes are stashed, however applying them
resulted in conflicts.  You can either resolve the conflicts
and then discard the stash with "git stash drop", or, if you
do not want to resolve them now, run "git reset --hard" and
apply the local changes later by running "git stash pop".
Switched to branch 'desserts'
The following paths have local changes:
M	README.md
M	bread.txt
$ cat bread.txt
Flour
Water
Salt
<<<<<<< desserts
Sugar
||||||| main
=======
Yeast
>>>>>>> local
$ git reset -q --hard
$ git switch -q main
$ git stash drop
Dropped refs/stash@{0} (a28709be081fa7c5442b40ece0d385224993c3ef)
```

`--conflict=<style>` is `-m` with a different marker style: `diff3` adds the
original lines, from `main`, between `|||||||` and `=======`, here none.
Chapter 26 compares the styles `merge`, `diff3` and `zdiff3`, and the setting
`merge.conflictStyle` that sets the default. Dropping the stash this time threw
the two edits away for good.

```console
$ git diff
diff --git a/bread.txt b/bread.txt
index 6693c53..e88ad38 100644
--- a/bread.txt
+++ b/bread.txt
@@ -1,3 +1,3 @@
-Flour
+Strong flour
 Water
 Salt
$ git switch desserts
error: Your local changes to the following files would be overwritten by checkout:
	bread.txt
Please commit your changes or stash them before you switch branches.
Aborting
$ git switch -m desserts
Applied autostash.
Switched to branch 'desserts'
The following paths have local changes:
M	bread.txt
$ cat bread.txt
Strong flour
Water
Salt
Sugar
$ git stash list
$ git switch -m main
Applied autostash.
Switched to branch 'main'
Your branch is ahead of 'origin/main' by 1 commit.
  (use "git push" to publish your local commits)
The following paths have local changes:
M	bread.txt
$ cat bread.txt
Strong flour
Water
Salt
```

An edit to the first line does not collide with `desserts`' change to the last,
but plain `git switch` still refused: Git's documentation says it fails for any
file with uncommitted changes whose content differs between the two commits.
`-m` merged the two cleanly, said "Applied autostash", and left no stash behind. Switching back with `-m` took the edit
back without `Sugar`.

### Throwing changes away

```console
$ git add bread.txt
$ git status --short
M  bread.txt
$ git switch desserts
error: Your local changes to the following files would be overwritten by checkout:
	bread.txt
Please commit your changes or stash them before you switch branches.
Aborting
$ git switch --discard-changes desserts
Switched to branch 'desserts'
$ git status --short
$ cat bread.txt
Flour
Water
Salt
Sugar
$ git switch -q main
$ git switch -f desserts
Switched to branch 'desserts'
$ git switch -q main
```

Staged changes are protected the same way. `--discard-changes` switches and makes
the index and every tracked file match the new branch, throwing all uncommitted
changes away, including those to files the switch did not need to touch. `-f`
and `--force` are other names for it. The last `-f` threw away an edit that is
not shown, the same `Yeast` line again.

> **Careful.** Changes thrown away by `--discard-changes` or `-f` were never
> committed, so no Git command brings them back.

### Untracked and ignored files

```console
$ git status --short
?? cake.txt
$ git switch desserts
error: The following untracked working tree files would be overwritten by checkout:
	cake.txt
Please move or remove them before you switch branches.
Aborting
$ git switch -f desserts
Switched to branch 'desserts'
$ cat cake.txt
Chocolate cake
$ git switch -q main
$ git checkout -f desserts
Switched to branch 'desserts'
$ cat cake.txt
Chocolate cake
$ git switch -q main
```

An untracked `cake.txt` of your own was where `desserts` has a tracked one, so
switching would replace it, and Git refused. `-f` replaced it, for `switch` and
`checkout` alike; your own `cake.txt` is gone. Rename the file instead to keep
it. Switching back to `main` removed `desserts`' `cake.txt` as a tracked file
that `main` does not have.

```console
$ git status --short --ignored
!! debug.log
$ git switch --no-overwrite-ignore logs
error: The following untracked working tree files would be overwritten by checkout:
	debug.log
Please move or remove them before you switch branches.
Aborting
$ git switch --overwrite-ignore logs
Switched to branch 'logs'
$ cat debug.log
tracked log
$ git switch -q main
$ git switch logs
Switched to branch 'logs'
$ cat debug.log
tracked log
$ git switch -q main
```

`debug.log` is ignored on `main` (Chapter 16) and holds `my local log`, but
`logs` tracks a file of that name. An ignored file counts as expendable:
`--overwrite-ignore`, the default, replaced it without a word, as the last
switch did. `--no-overwrite-ignore` protects it like an untracked file.

> **Careful.** A file you ignore because it holds local settings or data can be
> overwritten by switching to a branch that tracks a file of the same name.

## Creating a branch and switching to it

```console
$ git switch -c topic
Switched to a new branch 'topic'
$ git switch -c topic
fatal: a branch named 'topic' already exists
$ git switch -C topic v1.0
Reset branch 'topic'
$ git log --oneline -1
8de51b0 Add bread
$ git switch -q main
$ git switch -c fix v1.0
Switched to a new branch 'fix'
$ git switch -q main
$ git switch -c base desserts...main
Switched to a new branch 'base'
$ git log --oneline -1
8de51b0 Add bread
$ git switch -q main
$ git switch -c draft
Switched to a new branch 'draft'
$ git status --short
 M README.md
$ git switch -q main
$ git restore README.md
$ git switch -C docs main
fatal: 'docs' is already used by worktree at '/home/ada/recipes-docs'
$ git branch -v --list docs
+ docs 8de51b0 Add bread
$ git switch -c docs2 nosuch
fatal: invalid reference: nosuch
$ git branch --list docs2
$ git branch -q -D topic fix base draft
```

`-c <name>` creates the branch at `HEAD`, or at a start point, and switches to
it; `-C` moves a branch of that name if there is one, like `git branch -f`
(Chapter 23). `desserts...main` means the commit where the two branches split,
their merge base. An uncommitted edit, here to `README.md`, comes along to the
new branch.

Git's documentation calls `-c` the *transactional* form of `git branch` followed
by `git switch`: if the switch fails, the branch is not created or moved either.
`-C docs` failed because `docs` is in another worktree, and `docs` still points
where it did; `docs2` was never created.

> **Since Git 2.44.** `git checkout -B` refuses a branch in use in another
> worktree, as `switch -C` does. Git's release notes call the older behaviour a
> mistake; `--ignore-other-worktrees` restores it.

## Detached HEAD

### Detaching on purpose

```console
$ git switch --detach v1.0
HEAD is now at 8de51b0 Add bread
$ git status
HEAD detached at v1.0
nothing to commit, working tree clean
$ git branch
* (HEAD detached at v1.0)
  desserts
+ docs
  logs
  main
$ cat .git/HEAD
8de51b0cfe66b7dc166d6bd8f841bd31a407bee8
```

`--detach` puts `HEAD` at a commit, here the one the tag `v1.0` names, and the
files become that commit's. It is the way to build, test or read an old version
without making a branch. `.git/HEAD` holds a hash instead of `ref: refs/heads/...`,
and `git status` and `git branch` say where you detached.

### Committing on a detached HEAD, and leaving it

```console
$ git commit -q -am 'Try rosemary bread'
$ git status | head -1
HEAD detached from v1.0
$ git log --oneline --graph --decorate HEAD main
* 350a492 (HEAD) Try rosemary bread
| * bacdce1 (main) Make more soup
|/  
* 8de51b0 (tag: v1.0, origin/main, origin/HEAD, docs) Add bread
* a8868ab Start the collection
$ git switch main
Warning: you are leaving 1 commit behind, not connected to
any of your branches:

  350a492 Try rosemary bread

If you want to keep it by creating a new branch, this may be a good time
to do so with:

 git branch <new-branch-name> 350a492

Switched to branch 'main'
Your branch is ahead of 'origin/main' by 1 commit.
  (use "git push" to publish your local commits)
$ git reflog -3
bacdce1 HEAD@{0}: checkout: moving from 350a492dfa7405ec5f6f81aeb2a1ef9a783d9e95 to main
350a492 HEAD@{1}: commit: Try rosemary bread
8de51b0 HEAD@{2}: checkout: moving from main to v1.0
$ git branch rosemary 350a492
```

Committing works, and `HEAD` moves to the new commit, but no branch does: the
commit hangs off `v1.0` with only `HEAD` pointing at it. Status now says
"detached from".

Switching away left it pointed at by nothing, and Git warned and printed the
hash. Once that message has scrolled away, the reflog of `HEAD` (Chapter 36)
still has it. `git branch rosemary 350a492` gave it a name, and it is safe.

> **Careful.** A commit that no branch or tag reaches is removed eventually by
> garbage collection, once its reflog entries expire (Chapter 77). Name it soon.

### Keeping what you made

```console
$ git switch -d
HEAD is now at bacdce1 Make more soup
$ git switch main
Switched to branch 'main'
Your branch is ahead of 'origin/main' by 1 commit.
  (use "git push" to publish your local commits)
$ git switch --detach HEAD~1
HEAD is now at 8de51b0 Add bread
$ git switch -c fix-soup
Switched to a new branch 'fix-soup'
$ git switch -q main
$ git switch -q --detach
$ git commit -q --allow-empty -m 'Keep me'
$ git branch keep-me
$ git status | head -1
HEAD detached from bacdce1
$ git switch main
Previous HEAD position was 7a571e9 Keep me
Switched to branch 'main'
Your branch is ahead of 'origin/main' by 1 commit.
  (use "git push" to publish your local commits)
```

`--detach` with no commit, or `-d`, detaches at the current commit. Leaving a
detached `HEAD` that has no new commits needs no warning.

| While still detached | Result |
|---|---|
| `git switch -c <name>` | a branch at `HEAD`, and you are on it, no longer detached |
| `git branch <name>` | a branch at `HEAD`, but `HEAD` stays detached |
| `git tag <name>` | a tag at `HEAD`, `HEAD` stays detached (Chapter 47) |

`keep-me` named the commit, so leaving printed only "Previous HEAD position was"
instead of the warning.

### How checkout detaches

```console
$ git checkout v1.0
Note: switching to 'v1.0'.

You are in 'detached HEAD' state. You can look around, make experimental
changes and commit them, and you can discard any commits you make in this
state without impacting any branches by switching back to a branch.

If you want to create a new branch to retain commits you create, you may
do so (now or later) by using -c with the switch command. Example:

  git switch -c <new-branch-name>

Or undo this operation with:

  git switch -

Turn off this advice by setting config variable advice.detachedHead to false

HEAD is now at 8de51b0 Add bread
$ git checkout -q main
$ git -c advice.detachedHead=false checkout v1.0
HEAD is now at 8de51b0 Add bread
$ git checkout -q main
$ git checkout origin/main
Note: switching to 'origin/main'.

You are in 'detached HEAD' state. You can look around, make experimental
changes and commit them, and you can discard any commits you make in this
state without impacting any branches by switching back to a branch.

If you want to create a new branch to retain commits you create, you may
do so (now or later) by using -c with the switch command. Example:

  git switch -c <new-branch-name>

Or undo this operation with:

  git switch -

Turn off this advice by setting config variable advice.detachedHead to false

HEAD is now at 8de51b0 Add bread
$ git checkout -q main
$ git checkout --detach
HEAD is now at bacdce1 Make more soup
$ git checkout -q main
```

`git checkout` detaches whenever it is given a commit rather than a local branch,
or a remote branch it can guess: a tag, a hash, or a remote-tracking branch such
as `origin/main`. Because that may be unintended, it prints a long note; with
`--detach` it does not. `advice.detachedHead=false` turns the note off. A
remote-tracking branch moves only when you fetch, so to work on one, create a
local branch from it ([Branches that exist only on a remote](#branches-that-exist-only-on-a-remote)).

Other commands detach `HEAD` while they work: `git bisect` checks out commits to
test (Chapter 20), and Git's documentation says `--recurse-submodules` detaches
the `HEAD` of each submodule (Chapter 57).

## Orphan branches

```console
$ git switch --orphan gh-pages
Switched to a new branch 'gh-pages'
$ ls
notes.txt
$ git status --short
?? notes.txt
$ git log; echo "exit $?"
fatal: your current branch 'gh-pages' does not have any commits yet
exit 128
$ git add index.html
$ git commit -q -m 'Publish the site'
$ git log --oneline
035fb4c Publish the site
$ git switch -q main
$ ls
README.md
bread.txt
notes.txt
soup.txt
$ git checkout --orphan snapshot
Switched to a new branch 'snapshot'
$ git status --short
A  .gitignore
A  README.md
A  bread.txt
A  soup.txt
?? notes.txt
$ git commit -q -m 'History starts here'
$ git log --oneline
772588b History starts here
$ git switch -q main
$ git switch --orphan gh-pages2 v1.0
fatal: '--orphan' cannot take <start-point>
$ git checkout --orphan snapshot2 v1.0
Switched to a new branch 'snapshot2'
$ git status --short
A  .gitignore
A  README.md
A  bread.txt
A  soup.txt
?? notes.txt
```

An *orphan* branch is unborn (Chapter 23): it has a name but no commit, and its
first commit will have no parent, so it shares no history with any other branch.
Projects use one for things kept apart from the code, such as a web site.

| Command | Index and files afterwards | Start point |
|---|---|---|
| `git switch --orphan <new-branch>` | empty: every tracked file is removed | not accepted |
| `git checkout --orphan <new-branch> [<start-point>]` | as at the start point, staged, ready to commit as a new root | allowed |

Both kept the untracked `notes.txt`. `git switch --orphan` is for new, unrelated
content; `index.html` was written after the switch. `git checkout --orphan`
keeps the files: committing at once made a copy of the project with no history,
which Git's documentation suggests for publishing code whose history must stay
private. Its documentation also says to run `git rm -rf .` for a start with
different files.

## checkout, the classic command

### The same jobs

```console
$ git checkout
Your branch is ahead of 'origin/main' by 1 commit.
  (use "git push" to publish your local commits)
$ git checkout desserts
Switched to branch 'desserts'
$ git checkout -
Switched to branch 'main'
Your branch is ahead of 'origin/main' by 1 commit.
  (use "git push" to publish your local commits)
$ git checkout -b topic v1.0
Switched to a new branch 'topic'
$ git checkout -B topic main
Reset branch 'topic'
$ git checkout -q main
$ git checkout -l -b with-log
Switched to a new branch 'with-log'
$ git reflog show with-log
bacdce1 with-log@{0}: branch: Created from HEAD
$ git checkout -q main
$ git checkout --track origin/drinks
Switched to a new branch 'drinks'
branch 'drinks' set up to track 'origin/drinks'.
$ git checkout -q main
```

`git checkout` with no arguments only reports how the current branch compares
with its upstream. `-l` creates a reflog for the new branch, which a repository
with a working tree gets anyway (Chapter 23).

| Modern | Classic |
|---|---|
| `git switch <branch>` | `git checkout <branch>` |
| `git switch -` | `git checkout -` |
| `git switch -c <new-branch> [<start-point>]` | `git checkout -b <new-branch> [<start-point>]` |
| `git switch -C <new-branch> [<start-point>]` | `git checkout -B <new-branch> [<start-point>]` |
| `git switch --detach <commit>` | `git checkout <commit>`, or `git checkout --detach <commit>` |
| `git switch --discard-changes <branch>` | `git checkout -f <branch>` |
| `git switch -m <branch>` | `git checkout -m <branch>` |
| `git switch --track <remote>/<branch>` | `git checkout --track <remote>/<branch>` |
| `git switch --orphan <new-branch>` | `git checkout --orphan <new-branch>`, then `git rm -rf .` |

### A name that could be a file or a branch

Here an untracked file is called `pies`, like the branch on the server:

```console
$ git status --short
?? pies
$ git checkout pies
fatal: 'pies' could be both a local file and a tracking branch.
Please use -- (and optionally --no-guess) to disambiguate
$ git switch pies
Switched to a new branch 'pies'
branch 'pies' set up to track 'origin/pies'.
$ git switch -q main
$ git checkout pies --
Switched to a new branch 'pies'
branch 'pies' set up to track 'origin/pies'.
$ git checkout -q main
$ git checkout -- pies
error: pathspec 'pies' did not match any file(s) known to git
$ git add pies
$ git checkout pies
fatal: 'pies' could be both a local file and a tracking branch.
Please use -- (and optionally --no-guess) to disambiguate
$ git checkout pies --
Switched to a new branch 'pies'
A	pies
branch 'pies' set up to track 'origin/pies'.
$ git branch --show-current
pies
$ git checkout -q main
```

`git checkout <name>` can mean a branch or a file, and when guessing a remote
branch collides with a file of the same name, it refuses to choose. `--` settles
it: before `--` is a branch, after it are files. `git switch` never has the
problem. `git checkout -- pies` failed because Git does not know an untracked
file. Chapter 14 shows the case of a local branch and a tracked file sharing a
name, where `checkout` silently picks the branch. In the last switch, Git's source
prints the line for `pies` first, then the tracking line, then "Switched"; the
pipe put "Switched" first.

### Files, conflicts and patches

`git checkout` given paths restores files instead of switching, and has options
only for that. They are taught with the commands that replaced them:

| Classic | Modern | Covered in |
|---|---|---|
| `git checkout [--] <path>` | `git restore <path>` | Chapter 14 |
| `git checkout <commit> -- <path>` | `git restore --source=<commit> --staged --worktree <path>` | Chapter 14, with the differences |
| `git checkout -p [<commit>] [--] [<path>]` | `git restore -p` | Chapter 14 |
| `git checkout --ours <path>`, `--theirs` | `git restore --ours <path>`, `--theirs` | Chapter 26 |
| `git checkout -m <path>`, `--conflict=<style> <path>` | `git restore -m <path>` | Chapter 26 |

## Progress, quiet and submodules

```console
$ git switch -q desserts
$ git switch --progress main
Switched to branch 'main'
Your branch is ahead of 'origin/main' by 1 commit.
  (use "git push" to publish your local commits)
$ GIT_PROGRESS_DELAY=0 git switch --progress desserts
Updating files:  33% (1/3)
Updating files:  66% (2/3)
Updating files: 100% (3/3)
Updating files: 100% (3/3), done.
Switched to branch 'desserts'
$ GIT_PROGRESS_DELAY=0 git switch --progress -q main
Updating files:  33% (1/3)
Updating files:  66% (2/3)
Updating files: 100% (3/3)
Updating files: 100% (3/3), done.
$ GIT_PROGRESS_DELAY=0 git switch --no-progress desserts
Switched to branch 'desserts'
$ git switch -q main
$ git switch --recurse-submodules desserts
Switched to branch 'desserts'
$ git switch -q main
```

`-q` removes every message. Progress appears on a terminal for a switch that
takes a while; Git's documentation says `--progress` asks for it anywhere, even
with `-q`. It still waits a moment before showing, and this switch was quicker,
so the first `--progress` showed nothing. `GIT_PROGRESS_DELAY=0` removed the
delay, in bash (Chapter 19). On a terminal the progress lines are drawn over each
other; they end with a carriage return, not a new line.

`--recurse-submodules` also updates submodules to the commits the new branch
records; this repository has none, so nothing changed. Chapter 57 covers
submodules and the setting `submodule.recurse`.

## switch, checkout and their neighbours

| Command | Changes | Use it when |
|---|---|---|
| `git switch` | which branch is current, and the files to match | you want to work on another branch |
| `git checkout` | the same, or files | you read older instructions or scripts; it does both jobs |
| `git restore` | files only, never the branch (Chapter 14) | you want to undo changes to files |
| `git reset` | where the current branch points (Chapter 30) | you want to move the branch itself |
| `git worktree add` | nothing here; a second directory on another branch (Chapter 56) | you need two branches checked out at once |
| `git stash` | puts uncommitted work aside (Chapter 55) | you must switch but cannot commit yet |

`git switch` and `git reset --hard <commit>` can both leave your files looking
like another commit. The difference is the branch: `switch` moves `HEAD` to
another branch and leaves every branch where it is, while `reset` drags the
current branch to the commit, and commits only that branch reached are left
behind.

> **Since Git 2.23.** `git switch` itself. Git 2.51 declared it no longer
> experimental. On an older Git, use the classic column.

## The settings

| Setting | Effect |
|---|---|
| `checkout.defaultRemote` | The remote whose branch wins when guessing finds the name on several |
| `checkout.guess` | Whether guessing is on; `true` by default |
| `advice.detachedHead` | Whether `git checkout` explains a detached `HEAD` |
| `merge.conflictStyle` | Default marker style for `-m` (Chapter 26) |
| `branch.autoSetupMerge`, `branch.autoSetupRebase` | Upstream of branches created by `-c` and guessing (Chapter 23) |
| `submodule.recurse` | Default for `--recurse-submodules` (Chapter 57) |
| `checkout.workers`, `checkout.thresholdForParallelism` | How many processes write files, and for how many files; Git's documentation says one process by default and a threshold of 100 |
