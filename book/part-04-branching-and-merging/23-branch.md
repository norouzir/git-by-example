# Chapter 23. branch

## What it is

`git branch` lists, creates, renames, copies and deletes branches. On its own it
answers "which branches are there, and which one am I on?"

A *branch* is a name under `refs/heads/` that points at one commit (Chapter 7).
Creating a branch writes that name and nothing else, and committing moves the
branch you are on to the new commit. `git branch` never switches branches: it
does not change `HEAD`, the index or your files. `git switch` does that
(Chapter 24).

A few more terms the chapter uses:

| Term | Means |
|---|---|
| current branch | the branch `HEAD` names, where the next commit goes |
| remote-tracking branch | a copy of a branch on a remote, as it was when last fetched, such as `origin/main` (Chapter 41) |
| upstream | the branch a local branch is compared with, and pulls from by default |
| merged | a branch is merged into a commit when its tip is in that commit's history |
| worktree | an extra working directory for the same repository, with its own current branch (Chapter 56) |

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What does `git branch` do, and does it switch me to the new branch?](#what-it-is)

**[Synopsis](#synopsis)**

- [What can I type after `git branch`?](#synopsis)

**[Options at a glance](#options-at-a-glance)**

- [Is there a list of every option, and where each is explained?](#options-at-a-glance)

**[The example repository](#the-example-repository)**

- [What repository do the examples use?](#the-example-repository)

**[Listing branches](#listing-branches)**

- [What do the `*` and `+` in front of branch names mean?](#reading-the-list)
- [How do I see the last commit on each branch, and whether it is ahead of its upstream?](#reading-the-list)
- [How do I see branches from the remote, not only my own?](#remote-tracking-branches)
- [How do I list only branches whose names match a pattern?](#listing-by-name)
- [I typed `git branch 'f*'` to list branches and got an error. Why?](#listing-by-name)
- [`git branch --list *` printed nothing. Why?](#listing-by-name)
- [Which branches are already merged, and which still have work in them?](#listing-by-history)
- [Which branches contain a particular commit?](#listing-by-history)
- [How do I list the branches I worked on most recently first?](#order-format-and-case)
- [How do I print branch names in my own format for a script?](#order-format-and-case)
- [Why is `Zebra` listed before `docs`?](#order-format-and-case)
- [How do I show a long list of branches in columns?](#columns)
- [How do I turn the colours on or off?](#colour)
- [How do I print just the name of the current branch?](#the-current-branch-a-detached-head-and-an-empty-repository)
- [What does "(HEAD detached at ...)" in the list mean?](#the-current-branch-a-detached-head-and-an-empty-repository)
- [Why does `git branch` show nothing in a new repository?](#the-current-branch-a-detached-head-and-an-empty-repository)

**[Creating a branch](#creating-a-branch)**

- [How do I create a branch, and why am I still on the old one?](#from-head-or-another-commit)
- [How do I start a branch from a tag or an older commit?](#from-head-or-another-commit)
- [It says a branch with that name already exists. How do I move it?](#a-branch-that-already-exists)
- [Why can't I force-move the branch I am on?](#a-branch-that-already-exists)
- [What start points does `git branch` refuse?](#start-points-and-names-that-cannot-be-used)
- [How do I start a branch where two branches split apart?](#start-points-and-names-that-cannot-be-used)
- [Why can't I create `fix-typo/v2` when `fix-typo` exists?](#start-points-and-names-that-cannot-be-used)
- [Why did creating a branch from `origin/...` print "set up to track"?](#tracking-from-the-start)
- [What is the difference between `--track`, `--track=inherit` and `--no-track`?](#tracking-from-the-start)
- [How do I make new branches track, or not track, by default?](#branch-autosetupmerge-and-branch-autosetuprebase)
- [How do I make new branches pull with rebase by default?](#branch-autosetupmerge-and-branch-autosetuprebase)
- [What are `--create-reflog`, `--recurse-submodules` and `-q` for?](#reflogs-submodules-and-quiet)

**[Setting and removing an upstream](#setting-and-removing-an-upstream)**

- [How do I tell a branch which remote branch it goes with?](#setting-and-removing-an-upstream)
- [Can a local branch be another local branch's upstream?](#setting-and-removing-an-upstream)
- [How do I remove the upstream again?](#setting-and-removing-an-upstream)
- [Why does `--set-upstream` not work?](#setting-and-removing-an-upstream)

**[Renaming a branch](#renaming-a-branch)**

- [How do I rename a branch, and what happens to its upstream and history?](#renaming-a-branch)
- [How do I rename a branch to a name that is already taken?](#renaming-a-branch)
- [Can I rename the branch I am on, or one checked out in another worktree?](#renaming-a-branch)
- [How do I rename `master` to `main`?](#renaming-a-branch)

**[Copying a branch](#copying-a-branch)**

- [How do I copy a branch, and what is copied with it?](#copying-a-branch)

**[Deleting a branch](#deleting-a-branch)**

- [How do I delete a branch?](#merged-and-unmerged-branches)
- [It says my branch "is not fully merged". What do I do?](#merged-and-unmerged-branches)
- [Why won't `git branch -d` delete a branch that is merged into my current branch?](#merged-and-unmerged-branches)
- [I deleted a branch by mistake. How do I get it back?](#getting-a-deleted-branch-back)
- [Why can't I delete the branch I am on?](#branches-that-cannot-be-deleted)
- [Why did Git delete a branch that is not merged into mine, with a warning?](#branches-that-cannot-be-deleted)
- [How do I delete a remote-tracking branch such as `origin/docs`?](#remote-tracking-branches-and-gone-upstreams)
- [What does `[origin/docs: gone]` mean?](#remote-tracking-branches-and-gone-upstreams)

**[Branch descriptions](#branch-descriptions)**

- [How do I write down what a branch is for?](#branch-descriptions)
- [Where does the description appear?](#branch-descriptions)

**[branch and its neighbours](#branch-and-its-neighbours)**

- [Should I use `git branch`, `git switch -c` or `git checkout -b` to make a branch?](#branch-and-its-neighbours)
- [What does `git show-branch` show that `git branch` does not?](#branch-and-its-neighbours)

**[The settings](#the-settings)**

- [Which settings change what `git branch` does?](#the-settings)

</details>

## Synopsis

```
git branch [--color[=<when>] | --no-color] [--show-current]
           [-v [--abbrev=<n> | --no-abbrev]]
           [--column[=<options>] | --no-column] [--sort=<key>]
           [--merged [<commit>]] [--no-merged [<commit>]]
           [--contains [<commit>]] [--no-contains [<commit>]]
           [--points-at <object>] [--format=<format>]
           [(-r|--remotes) | (-a|--all)]
           [--list] [<pattern>...]
git branch [--track[=(direct|inherit)] | --no-track] [-f]
           [--recurse-submodules] <branch-name> [<start-point>]
git branch (--set-upstream-to=<upstream>|-u <upstream>) [<branch-name>]
git branch --unset-upstream [<branch-name>]
git branch (-m|-M) [<old-branch>] <new-branch>
git branch (-c|-C) [<old-branch>] <new-branch>
git branch (-d|-D) [-r] <branch-name>...
git branch --edit-description [<branch-name>]
```

| Part | Means |
|---|---|
| `<pattern>` | A name with `*`, `?` or `[...]` in it, matched against branch names |
| `<branch-name>` | The branch to create, delete, or set up; the current branch where it may be left out |
| `<start-point>` | The commit a new branch points at: a branch, tag, hash or any revision (Chapter 18); `HEAD` if left out |
| `<upstream>` | The branch to compare with and pull from, such as `origin/main` |
| `<old-branch>` | The branch to rename or copy; the current branch if left out |
| `<new-branch>` | The new name |
| `<commit>`, `<object>` | A commit to filter branches by; `HEAD` where it may be left out |

| Command | Does |
|---|---|
| `git branch` | List local branches |
| `git branch <branch-name>` | Create a branch at `HEAD`, without switching to it |
| `git branch <branch-name> <start-point>` | Create a branch at another commit |
| `git branch -u <upstream>` | Set the current branch's upstream |
| `git branch --unset-upstream` | Remove it |
| `git branch -m <new-branch>` | Rename the current branch |
| `git branch -c <old-branch> <new-branch>` | Copy a branch |
| `git branch -d <branch-name>` | Delete a merged branch |
| `git branch -D <branch-name>` | Delete a branch whether merged or not |
| `git branch --edit-description` | Write a description of the current branch |

## Options at a glance

### Options for listing

| Option | Does | Covered in |
|---|---|---|
| `-l`, `--list` | List branches; needed before a pattern | [Listing by name](#listing-by-name) |
| `-v`, `--verbose` | Also the hash, title and distance from the upstream | [Reading the list](#reading-the-list) |
| `-vv` | Also the upstream's name and a worktree's path | [Reading the list](#reading-the-list) |
| `--abbrev=<n>`, `--no-abbrev` | Hash length in `-v` output | [Reading the list](#reading-the-list) |
| `-r`, `--remotes` | Remote-tracking branches instead | [Remote-tracking branches](#remote-tracking-branches) |
| `-a`, `--all` | Both local and remote-tracking branches | [Remote-tracking branches](#remote-tracking-branches) |
| `--merged [<commit>]`, `--no-merged [<commit>]` | Branches whose tip is, or is not, in `<commit>`'s history | [Listing by history](#listing-by-history) |
| `--contains [<commit>]`, `--no-contains [<commit>]` | Branches that have, or lack, `<commit>` | [Listing by history](#listing-by-history) |
| `--points-at <object>` | Branches pointing at `<object>` | [Listing by history](#listing-by-history) |
| `--sort=<key>` | Order by a field such as `-committerdate` | [Order, format and case](#order-format-and-case) |
| `--format=<format>` | Print fields as `git for-each-ref` does | [Order, format and case](#order-format-and-case) |
| `--omit-empty` | No blank line where the format came out empty | [Order, format and case](#order-format-and-case) |
| `-i`, `--ignore-case` | Sort and match patterns regardless of case | [Order, format and case](#order-format-and-case) |
| `--column[=<options>]`, `--no-column` | Lay the list out in columns, or not | [Columns](#columns) |
| `--color[=<when>]`, `--no-color` | Colour the list, or not | [Colour](#colour) |
| `--show-current` | Print only the current branch's name | [The current branch, a detached HEAD and an empty repository](#the-current-branch-a-detached-head-and-an-empty-repository) |

### Options for creating

| Option | Does | Covered in |
|---|---|---|
| `-f`, `--force` | Move a branch that already exists | [A branch that already exists](#a-branch-that-already-exists) |
| `-t`, `--track`, `--track=direct` | Make the start point the new branch's upstream | [Tracking from the start](#tracking-from-the-start) |
| `--track=inherit` | Copy the start point's own upstream | [Tracking from the start](#tracking-from-the-start) |
| `--no-track` | Set no upstream, whatever the settings say | [Tracking from the start](#tracking-from-the-start) |
| `--create-reflog` | Keep a reflog even where reflogs are off | [Reflogs, submodules and quiet](#reflogs-submodules-and-quiet) |
| `--recurse-submodules` | Create the branch in submodules too | [Reflogs, submodules and quiet](#reflogs-submodules-and-quiet) |
| `-q`, `--quiet` | Print no messages, only errors | [Reflogs, submodules and quiet](#reflogs-submodules-and-quiet) |

### Options for upstreams

| Option | Does | Covered in |
|---|---|---|
| `-u <upstream>`, `--set-upstream-to=<upstream>` | Set a branch's upstream | [Setting and removing an upstream](#setting-and-removing-an-upstream) |
| `--unset-upstream` | Remove it | [Setting and removing an upstream](#setting-and-removing-an-upstream) |
| `--set-upstream` | No longer supported | [Setting and removing an upstream](#setting-and-removing-an-upstream) |

### Options for renaming, copying and deleting

| Option | Does | Covered in |
|---|---|---|
| `-m`, `--move` | Rename, refusing to replace a branch | [Renaming a branch](#renaming-a-branch) |
| `-M` | Rename, replacing a branch of that name | [Renaming a branch](#renaming-a-branch) |
| `-c`, `--copy` | Copy, refusing to replace a branch | [Copying a branch](#copying-a-branch) |
| `-C` | Copy, replacing a branch of that name | [Copying a branch](#copying-a-branch) |
| `-d`, `--delete` | Delete a merged branch | [Merged and unmerged branches](#merged-and-unmerged-branches) |
| `-D`, `--delete --force` | Delete, merged or not | [Merged and unmerged branches](#merged-and-unmerged-branches) |
| `-r` with `-d` | Delete remote-tracking branches | [Remote-tracking branches and gone upstreams](#remote-tracking-branches-and-gone-upstreams) |
| `--edit-description` | Write a description in an editor | [Branch descriptions](#branch-descriptions) |

## The example repository

```console
$ git log --oneline --graph --all --decorate
* 1f0d93b (old-idea) Try a dark theme
| * b293e3e (HEAD -> main, fix-typo) Fix a typo on the home page
|/  
| * b34c401 (origin/feature/search, feature/search) Add a search box
|/  
* edd63cb (tag: v1.0, origin/main, origin/HEAD) Add a style sheet
| * 87af931 (origin/release) Prepare release 1.0
|/  
| * 5975a71 (origin/docs, docs) Write the README
|/  
* dcb40f7 Add the home page
```

`site` is a web site cloned from a server that has the branches `main`, `docs`,
`release` and `feature/search`. Since cloning:

| Branch | State |
|---|---|
| `main` | the current branch; `fix-typo` was merged into it, so it has one commit the server lacks |
| `fix-typo` | points at the same commit as `main` |
| `old-idea` | one commit of its own, never merged |
| `feature/search` | a local branch made from `origin/feature/search`, which it tracks |
| `docs` | checked out in a second worktree, `../site-docs`, and tracking `origin/docs` |

There is no local `release` branch. `--decorate` shows the names in the graph;
Chapter 17 explains why it is written out.

## Listing branches

### Reading the list

```console
$ git branch
+ docs
  feature/search
  fix-typo
* main
  old-idea
```

```ansi
$ git branch
+ \e[36mdocs\e[m
  feature/search\e[m
  fix-typo\e[m
* \e[32mmain\e[m
  old-idea\e[m
```

```console
$ git branch --list
+ docs
  feature/search
  fix-typo
* main
  old-idea
$ git branch -l
+ docs
  feature/search
  fix-typo
* main
  old-idea
```

Branches are sorted by name. `*` marks the current branch, shown in green on a
terminal. `+` marks a branch checked out in another worktree, in cyan; one branch
cannot be checked out in two worktrees at once (Chapter 56). `--list` and `-l` are
what plain `git branch` does, and matter with a pattern.

```console
$ git branch -v
+ docs           5975a71 Write the README
  feature/search b34c401 Add a search box
  fix-typo       b293e3e Fix a typo on the home page
* main           b293e3e [ahead 1] Fix a typo on the home page
  old-idea       1f0d93b Try a dark theme
$ git branch -vv
+ docs           5975a71 (/home/ada/site-docs) [origin/docs] Write the README
  feature/search b34c401 [origin/feature/search] Add a search box
  fix-typo       b293e3e Fix a typo on the home page
* main           b293e3e [origin/main: ahead 1] Fix a typo on the home page
  old-idea       1f0d93b Try a dark theme
```

```ansi
$ git branch -vv
+ \e[36mdocs          \e[m 5975a71 (\e[36m/home/ada/site-docs\e[m) [\e[34morigin/docs\e[m] Write the README
  feature/search\e[m b34c401 [\e[34morigin/feature/search\e[m] Add a search box
  fix-typo      \e[m b293e3e Fix a typo on the home page
* \e[32mmain          \e[m b293e3e [\e[34morigin/main\e[m: ahead 1] Fix a typo on the home page
  old-idea      \e[m 1f0d93b Try a dark theme
```

```console
$ git branch -v --abbrev=10
+ docs           5975a71157 Write the README
  feature/search b34c40139f Add a search box
  fix-typo       b293e3eca1 Fix a typo on the home page
* main           b293e3eca1 [ahead 1] Fix a typo on the home page
  old-idea       1f0d93ba8e Try a dark theme
$ git branch -v --no-abbrev
+ docs           5975a7115719ba77eb0b39ab95ac9559ebbdb9f7 Write the README
  feature/search b34c40139fb8516d640a2ccb5c96d3c8ec256edd Add a search box
  fix-typo       b293e3eca1563418027879270d4750b0293400d7 Fix a typo on the home page
* main           b293e3eca1563418027879270d4750b0293400d7 [ahead 1] Fix a typo on the home page
  old-idea       1f0d93ba8e590b914d5d8d9bd18c4f5c1e14a56f Try a dark theme
```

| Form | Adds after the name |
|---|---|
| `git branch -v` | the tip's short hash and title, and `[ahead N]`, `[behind N]` or both when the branch differs from its upstream |
| `git branch -vv` | also the upstream's name in brackets, in blue, even when the two are level, and the path of another worktree using the branch |

`main` has one commit `origin/main` lacks, so it is ahead 1; a branch in step
with its upstream shows no count. `--abbrev=<n>` sets the hash length and
`--no-abbrev` prints it whole. Chapter 10 shows the same count in `git status`
for the current branch only.

### Remote-tracking branches

```console
$ git branch -r
  origin/HEAD -> origin/main
  origin/docs
  origin/feature/search
  origin/main
  origin/release
$ git branch -a
+ docs
  feature/search
  fix-typo
* main
  old-idea
  remotes/origin/HEAD -> origin/main
  remotes/origin/docs
  remotes/origin/feature/search
  remotes/origin/main
  remotes/origin/release
```

```ansi
$ git branch -a
+ \e[36mdocs\e[m
  feature/search\e[m
  fix-typo\e[m
* \e[32mmain\e[m
  old-idea\e[m
  \e[31mremotes/origin/HEAD\e[m -> origin/main
  \e[31mremotes/origin/docs\e[m
  \e[31mremotes/origin/feature/search\e[m
  \e[31mremotes/origin/main\e[m
  \e[31mremotes/origin/release\e[m
```

```console
$ git branch -r -v
  origin/HEAD           -> origin/main
  origin/docs           5975a71 Write the README
  origin/feature/search b34c401 Add a search box
  origin/main           edd63cb Add a style sheet
  origin/release        87af931 Prepare release 1.0
```

`-r` lists the remote-tracking branches, and `-a` both kinds, with `remotes/` in
front of the remote ones, which are red on a terminal. `origin/HEAD` is a
symbolic ref naming the remote's default branch (Chapter 41). These are Git's
record of the server as last fetched, not the server itself: the list does not
change until the next `git fetch`. `origin/release` has no local branch yet.

### Listing by name

```console
$ git branch --list 'f*'
  feature/search
  fix-typo
$ git branch --list 'f*' 'd*'
+ docs
  feature/search
  fix-typo
$ git branch -r --list 'origin/f*'
  origin/feature/search
$ git branch -a --list '*search*'
  feature/search
  remotes/origin/feature/search
$ git branch --list '*'
+ docs
  feature/search
  fix-typo
* main
  old-idea
$ git branch --list *
$ echo *
index.html style.css
$ git branch --list main
* main
$ git branch --list nosuch; echo "exit $?"
exit 0
$ git branch 'f*'
fatal: 'f*' is not a valid branch name
hint: See 'git help check-ref-format'
hint: Disable this message with "git config set advice.refSyntax false"
$ git branch HEAD
fatal: 'HEAD' is not a valid branch name
hint: See 'git help check-ref-format'
hint: Disable this message with "git config set advice.refSyntax false"
```

A pattern uses `*`, `?` and `[...]` the way the shell does, and several patterns
list branches matching any. With `-r` the pattern includes `origin/`; with `-a`,
`*search*` matched both kinds. A name with no wildcard lists that branch if it
exists, and a name that matches nothing prints nothing and still succeeds.

> **Careful.** Without `--list`, a name is a branch to create. `git branch 'f*'`
> only failed because `*` cannot be in a branch name (Chapter 7);
> `git branch fix` would quietly have created a branch called `fix`.

The pattern must be quoted. Unquoted, bash replaced `*` with the files in the
directory before Git saw it, as `echo *` shows, so Git looked for branches named
`index.html` and `style.css` and found none.

> **Windows.** Tested outside the sandbox with Git 2.55. PowerShell passes
> `git branch --list 't*'` and `git branch --list t*` to Git unchanged, and both
> work. In cmd, `git branch --list t*` and `git branch --list "t*"` work, but
> single quotes reach Git as part of the pattern and nothing matches.

### Listing by history

```console
$ git branch --merged
  fix-typo
* main
$ git branch --merged old-idea
  old-idea
$ git branch --no-merged
+ docs
  feature/search
  old-idea
$ git branch -a --no-merged
+ docs
  feature/search
  old-idea
  remotes/origin/docs
  remotes/origin/feature/search
  remotes/origin/release
$ git branch --contains
  fix-typo
* main
$ git branch --contains main~1
  feature/search
  fix-typo
* main
  old-idea
$ git branch --no-contains fix-typo
+ docs
  feature/search
  old-idea
$ git branch --points-at HEAD
  fix-typo
* main
$ git branch -a --points-at origin/docs
+ docs
  remotes/origin/docs
$ git branch --merged main --no-merged docs
  fix-typo
* main
$ git branch --merged nosuch
fatal: malformed object name nosuch
```

| Option | Lists branches whose tip | Answers |
|---|---|---|
| `--merged [<commit>]` | is in `<commit>`'s history | "which branches can I delete?" |
| `--no-merged [<commit>]` | is not | "which branches still have work to merge?" |
| `--contains [<commit>]` | has `<commit>` in its history | "which branches have this fix?" |
| `--no-contains [<commit>]` | does not | "which branches still lack it?" |
| `--points-at <object>` | is exactly `<object>` | "which branches are at this commit?" |

Each defaults to `HEAD` without a commit, except `--points-at`, which needs one.
A branch is always merged into itself, so `--merged old-idea` listed only
`old-idea`; `main~1` is in the history of every branch except `docs`, which
split off before it. `-a` or `-r` apply the filter to remote-tracking branches
too.

Filters of different kinds combine: the last example listed the branches merged
into `main` but not into `docs`. Git's documentation adds that several
`--contains` accept a branch containing any of them, several `--no-contains`
reject one containing any, and `--merged` and `--no-merged` combine the same way.

> **Careful.** `--merged` answers whether the branch's commits are in another
> branch's history, not whether its changes are. A branch whose work was
> cherry-picked (Chapter 32) or squashed into a different commit counts as not
> merged.

### Order, format and case

```console
$ git branch --sort=-committerdate
  old-idea
  fix-typo
* main
  feature/search
+ docs
$ git -c branch.sort=-committerdate branch
  old-idea
  fix-typo
* main
  feature/search
+ docs
$ git branch --sort=-committerdate --format='%(committerdate:relative) %(refname:short)'
60 minutes ago old-idea
2 hours ago fix-typo
2 hours ago main
3 hours ago feature/search
5 hours ago docs
$ git branch --format='%(refname:short) -> %(upstream:short)'
docs -> origin/docs
feature/search -> origin/feature/search
fix-typo -> 
main -> origin/main
old-idea -> 
$ git branch --format='%(if)%(upstream)%(then)%(refname:short)%(end)' --omit-empty
docs
feature/search
main
```

`--sort` takes any field of `git for-each-ref` (Chapter 22), and `-` in front
reverses it: `--sort=-committerdate` puts the branches with the newest commits
first, the usual way to find recent work. `git -c <name>=<value>` sets a
configuration value for one command (Chapter 62); `branch.sort` makes an order
the default.

`--format` takes the same fields as `for-each-ref`, and gives a script a stable
list without the `*` and spaces. `relative` dates count from the moment the
command runs. `--omit-empty` leaves out the lines a format left empty, here the
branches with no upstream.

```console
$ git branch Zebra
$ git branch
  Zebra
+ docs
  feature/search
  fix-typo
* main
  old-idea
$ git branch -i
+ docs
  feature/search
  fix-typo
* main
  old-idea
  Zebra
$ git branch -i --list 'z*'
  Zebra
$ git branch -q -d Zebra
```

Names are sorted by their bytes, and every upper-case letter comes before every
lower-case one. `-i` sorts and matches patterns regardless of case.

> **Since Git 2.41.** `--omit-empty`.

### Columns

```console
$ git branch --column
+ docs             fix-typo         old-idea
  feature/search * main
$ COLUMNS=40 git branch --column=always
+ docs           * main
  feature/search   old-idea
  fix-typo
$ COLUMNS=40 git branch --column=column
+ docs           * main
  feature/search   old-idea
  fix-typo
$ COLUMNS=40 git branch --column=row
+ docs             feature/search
  fix-typo       * main
  old-idea
$ COLUMNS=40 git branch --column=plain
+ docs
  feature/search
  fix-typo
* main
  old-idea
$ COLUMNS=30 git branch --column=always
+ docs
  feature/search
  fix-typo
* main
  old-idea
$ COLUMNS=30 git branch --column=dense
+ docs           * main
  feature/search   old-idea
  fix-typo
$ COLUMNS=30 git branch --column=nodense
+ docs
  feature/search
  fix-typo
* main
  old-idea
$ COLUMNS=30 git branch --column=row,dense
+ docs       feature/search
  fix-typo * main
  old-idea
$ git branch --column=auto
+ docs
  feature/search
  fix-typo
* main
  old-idea
$ git branch --column=never
+ docs
  feature/search
  fix-typo
* main
  old-idea
$ git -c column.branch=always branch --no-column
+ docs
  feature/search
  fix-typo
* main
  old-idea
$ git branch -v --column
fatal: options '--column' and '--verbose' cannot be used together
```

`COLUMNS=<n>` in front of the command sets the screen width Git lays columns out
for, in bash. The first command, without it, went into a pipe rather than to a
terminal, and Git used a width of its own.

| Option | Effect |
|---|---|
| `--column`, `--column=always` | columns, even into a pipe |
| `--column=never`, `--no-column` | one branch per line |
| `--column=auto` | columns only on a terminal; none here |
| `--column=column` | fill each column top to bottom, the default layout |
| `--column=row` | fill each row left to right |
| `--column=plain` | one column |
| `--column=nodense` | columns of equal width, the default |
| `--column=dense` | columns only as wide as they need |

Words combine with commas, as in `row,dense`, and Git's documentation says a
layout word alone implies `always`. At 30 characters two equal columns did not
fit, so `always` fell back to one, while `dense` still fitted two. The setting
`column.branch`, or `column.ui` for every command that has columns, makes it the
default, and `--no-column` overrides it.
Columns cannot be combined with `-v`.

### Colour

```console
$ git branch --color=always | cat -A
+ ^[[36mdocs^[[m$
  feature/search^[[m$
  fix-typo^[[m$
* ^[[32mmain^[[m$
  old-idea^[[m$
$ git branch --color | cat -A
+ ^[[36mdocs^[[m$
  feature/search^[[m$
  fix-typo^[[m$
* ^[[32mmain^[[m$
  old-idea^[[m$
$ git branch --color=auto | cat -A
+ docs$
  feature/search$
  fix-typo$
* main$
  old-idea$
$ git branch --color=never | cat -A
+ docs$
  feature/search$
  fix-typo$
* main$
  old-idea$
$ git branch --no-color | cat -A
+ docs$
  feature/search$
  fix-typo$
* main$
  old-idea$
```

`cat -A` makes the colour codes visible as `^[[...m`. `--color` alone means
`always`, `auto` colours only on a terminal, and `never` and `--no-color` turn it
off. The setting `color.branch`, or `color.ui`, sets the default, and
`color.branch.<slot>` changes a colour; Git's documentation lists the slots
`current`, `local`, `remote`, `upstream` and `plain` (Chapter 62).

### The current branch, a detached HEAD and an empty repository

```console
$ git branch --show-current
main
$ git switch -q --detach HEAD~1
$ git branch
* (HEAD detached at dcb40f7)
+ docs
  feature/search
  fix-typo
  main
  old-idea
$ git branch --show-current; echo "exit $?"
exit 0
$ git commit -q --allow-empty -m 'An experiment'
$ git branch
* (HEAD detached from dcb40f7)
+ docs
  feature/search
  fix-typo
  main
  old-idea
$ git switch -q main
$ cd ../site-docs
$ git branch
* docs
  feature/search
  fix-typo
+ main
  old-idea
$ cd ../site
```

`--show-current` prints only the name, which is what a script or a shell prompt
wants. A *detached HEAD* points at a commit instead of a branch (Chapter 24).
`git branch` then lists it first: "detached at" while `HEAD` is still at the
commit it was detached at, "detached from" once a commit moved it on. On a
detached `HEAD`, `--show-current` prints nothing and still succeeds, so a script
must test for an empty result rather than the exit code. In the other worktree,
`docs` is current and `main` gets the `+`.

```console
$ git init -q ../empty
$ cd ../empty
$ git branch; echo "exit $?"
exit 0
$ git branch --show-current
main
$ git branch topic
fatal: not a valid object name: 'main'
$ cd ../site
```

A new repository has a current branch with no commit yet, called *unborn*, so
`git branch` lists nothing although `--show-current` knows its name. A branch
needs a commit to point at, so none can be created until the first commit.

## Creating a branch

### From HEAD or another commit

```console
$ git branch topic
$ git branch -v --list topic
  topic b293e3e Fix a typo on the home page
$ git status | head -1
On branch main
$ git branch hotfix v1.0
$ git branch -v --list hotfix
  hotfix edd63cb Add a style sheet
```

`git branch <name>` creates the branch at `HEAD` and prints nothing; the current
branch is still `main`. A second argument is the start point, any name for a
commit: here the tag `v1.0`.

### A branch that already exists

```console
$ git branch topic v1.0
fatal: a branch named 'topic' already exists
$ git branch -f topic v1.0
$ git branch -v --list topic
  topic edd63cb Add a style sheet
$ git branch -f main v1.0
fatal: cannot force update the branch 'main' used by worktree at '/home/ada/site'
$ git branch -f docs main
fatal: cannot force update the branch 'docs' used by worktree at '/home/ada/site-docs'
```

`-f` moves an existing branch to the start point. Commits only that branch named
are not deleted, but no branch names them any more; the reflog (Chapter 36) still
finds them. A branch checked out in any worktree, the current one included,
cannot be moved this way; `git reset` (Chapter 30) is how to move the current
branch.

### Start points, and names that cannot be used

```console
$ git branch start nosuch
fatal: not a valid object name: 'nosuch'
$ git branch start 'HEAD^{tree}'
error: object 4c743243ec7a7b8e7dcd1e29b4a0b798db07c962 is a tree, not a commit
fatal: not a valid branch point: 'HEAD^{tree}'
$ git branch base old-idea...main
$ git branch -v --list base
  base edd63cb Add a style sheet
$ git branch fix-typo/v2
fatal: cannot lock ref 'refs/heads/fix-typo/v2': 'refs/heads/fix-typo' exists; cannot create 'refs/heads/fix-typo/v2'
```

A start point must be a commit, or a tag pointing at one; `HEAD^{tree}` is the
commit's directory tree (Chapter 18). As a special case, Git's documentation says
`<a>...<b>` means the commit where the two branches split, their *merge base*,
if there is exactly one; `base` is at `Add a style sheet`, where `old-idea` left
`main`. One side can be left out and means `HEAD`.

`fix-typo/v2` would need `fix-typo` to be a directory, and it is already a branch
(Chapter 7 explains, with every rule a name must follow).

### Tracking from the start

```console
$ git branch search origin/feature/search
branch 'search' set up to track 'origin/feature/search'.
$ git branch search2 feature/search
$ git config get --all --show-names --regexp '^branch\.search'
branch.search.remote origin
branch.search.merge refs/heads/feature/search
$ git branch --track search3 feature/search
branch 'search3' set up to track 'feature/search'.
$ git branch --track=direct search4 feature/search
branch 'search4' set up to track 'feature/search'.
$ git branch --track=inherit search5 feature/search
branch 'search5' set up to track 'origin/feature/search'.
$ git branch --no-track search6 origin/feature/search
$ git branch -vv --list 'search*'
  search  b34c401 [origin/feature/search] Add a search box
  search2 b34c401 Add a search box
  search3 b34c401 [feature/search] Add a search box
  search4 b34c401 [feature/search] Add a search box
  search5 b34c401 [origin/feature/search] Add a search box
  search6 b34c401 Add a search box
$ git config get --all --show-names --regexp '^branch\.search'
branch.search.remote origin
branch.search.merge refs/heads/feature/search
branch.search3.remote .
branch.search3.merge refs/heads/feature/search
branch.search4.remote .
branch.search4.merge refs/heads/feature/search
branch.search5.remote origin
branch.search5.merge refs/heads/feature/search
```

A branch started from a remote-tracking branch gets it as its upstream by
default, and Git says so. Started from a local branch, it gets none. The
upstream is stored as two settings, printed with `git config get` (Chapter 3):
`branch.<name>.remote`, the remote, and `branch.<name>.merge`, the branch's name
there. A remote of `.` means this repository.

| Option | Upstream of the new branch |
|---|---|
| none | the start point if it is a remote-tracking branch, otherwise none |
| `--track`, `-t`, `--track=direct` | the start point itself, local or remote |
| `--track=inherit` | the start point's own upstream: `feature/search` tracks `origin/feature/search`, so `search5` does too |
| `--no-track` | none, even from a remote-tracking branch |

> **Since Git 2.35.** `--track=inherit`.

### branch.autoSetupMerge and branch.autoSetupRebase

```console
$ git -c branch.autoSetupMerge=false branch s-false origin/docs
$ git -c branch.autoSetupMerge=true branch s-true main
$ git -c branch.autoSetupMerge=always branch s-always main
branch 's-always' set up to track 'main'.
$ git -c branch.autoSetupMerge=inherit branch s-inherit feature/search
branch 's-inherit' set up to track 'origin/feature/search'.
$ git -c branch.autoSetupMerge=simple branch s-simple origin/release
$ git -c branch.autoSetupMerge=simple branch release origin/release
branch 'release' set up to track 'origin/release'.
$ git branch -vv --list 's-*' release
  release   87af931 [origin/release] Prepare release 1.0
  s-always  b293e3e [main] Fix a typo on the home page
  s-false   5975a71 Write the README
  s-inherit b34c401 [origin/feature/search] Add a search box
  s-simple  87af931 Prepare release 1.0
  s-true    b293e3e Fix a typo on the home page
```

`branch.autoSetupMerge` decides what happens when neither `--track` nor
`--no-track` is given, for `git switch -c` and `git checkout -b` as well.

| Value of `branch.autoSetupMerge` | New branch tracks its start point when |
|---|---|
| `true`, the default | the start point is a remote-tracking branch |
| `false` | never |
| `always` | the start point is any branch |
| `inherit` | the start point has an upstream, which is copied |
| `simple` | the start point is a remote-tracking branch with the same name as the new branch |

`simple` is for people who keep one local branch per remote branch under the
same name: `release` tracked `origin/release`, `s-simple` did not.

> **Since Git 2.35.** `inherit`. **Since Git 2.37.** `simple`.

```console
$ git -c branch.autoSetupRebase=always branch r-always origin/docs
branch 'r-always' set up to track 'origin/docs' by rebasing.
$ git -c branch.autoSetupRebase=remote branch --track r-local main
branch 'r-local' set up to track 'main'.
$ git -c branch.autoSetupRebase=local branch --track r-local2 main
branch 'r-local2' set up to track 'main' by rebasing.
$ git -c branch.autoSetupRebase=never branch r-never origin/docs
branch 'r-never' set up to track 'origin/docs'.
$ git config get --all --show-names --regexp '^branch\.r-'
branch.r-always.remote origin
branch.r-always.merge refs/heads/docs
branch.r-always.rebase true
branch.r-local.remote .
branch.r-local.merge refs/heads/main
branch.r-local2.remote .
branch.r-local2.merge refs/heads/main
branch.r-local2.rebase true
branch.r-never.remote origin
branch.r-never.merge refs/heads/docs
```

`branch.autoSetupRebase` also sets `branch.<name>.rebase=true` on a new tracking
branch, so that `git pull` rebases instead of merging (Chapter 42).

| Value of `branch.autoSetupRebase` | Sets `rebase` for a new branch tracking |
|---|---|
| `never`, the default | nothing |
| `local` | a local branch |
| `remote` | a remote-tracking branch |
| `always` | either |

### Reflogs, submodules and quiet

```console
$ git -c core.logAllRefUpdates=false branch no-log
$ git reflog show no-log; echo "exit $?"
exit 0
$ git -c core.logAllRefUpdates=false branch --create-reflog with-log
$ git reflog show with-log
b293e3e with-log@{0}: branch: Created from main
$ git branch --recurse-submodules sub-topic
fatal: branch with --recurse-submodules can only be used if submodule.propagateBranches is enabled
$ git branch -q quiet origin/docs
```

A branch's *reflog* records where it has pointed (Chapter 36). Git's
documentation says `core.logAllRefUpdates` turns reflogs on by default in any
repository with a working tree. With it off, `no-log` got none, and
`--create-reflog` kept one for `with-log` anyway.

`--recurse-submodules` creates the branch in every submodule too, only when
`submodule.propagateBranches` is on; Git's documentation marks it experimental,
and Chapter 57 covers submodules. `-q` silenced the "set up to track" message.

> **Since Git 2.36.** `--recurse-submodules`.

## Setting and removing an upstream

```console
$ git branch -vv --list topic
  topic edd63cb Add a style sheet
$ git branch -u origin/main topic
branch 'topic' set up to track 'origin/main'.
$ git branch -vv --list topic
  topic edd63cb [origin/main] Add a style sheet
$ git switch -q topic
$ git status | head -2
On branch topic
Your branch is up to date with 'origin/main'.
$ git rev-parse --abbrev-ref @{upstream}
origin/main
$ git branch --unset-upstream
$ git status | head -2
On branch topic
nothing to commit, working tree clean
$ git rev-parse --abbrev-ref @{upstream}
fatal: no upstream configured for branch 'topic'
$ git branch --unset-upstream
fatal: branch 'topic' has no upstream information
$ git branch --set-upstream-to=origin/nosuch
fatal: the requested upstream branch 'origin/nosuch' does not exist
hint:
hint: If you are planning on basing your work on an upstream
hint: branch that already exists at the remote, you may need to
hint: run "git fetch" to retrieve it.
hint:
hint: If you are planning to push out a new local branch that
hint: will track its remote counterpart, you may want to use
hint: "git push -u" to set the upstream config as you push.
hint: Disable this message with "git config set advice.setUpstreamFailure false"
$ git branch --set-upstream-to=main
branch 'topic' set up to track 'main'.
$ git branch -vv --list topic
* topic edd63cb [main: behind 1] Add a style sheet
$ git config get --all --show-names --regexp '^branch\.topic'
branch.topic.remote .
branch.topic.merge refs/heads/main
$ git branch --set-upstream origin/main
fatal: the '--set-upstream' option is no longer supported. Please use '--track' or '--set-upstream-to' instead
$ git switch -q main
```

Git's documentation gives `-u <upstream>` and `--set-upstream-to=<upstream>` as
one option, and both act on the current branch when no branch is named. The upstream is
what `git status` compares with, what `@{upstream}` means (Chapter 18), and what
`git pull` uses by default (Chapter 42). `--unset-upstream` removes it.

The upstream must exist: a branch that is only on the server needs `git fetch`
first, and a new branch not yet on the server gets its upstream with
`git push -u`, as the hint says. A local branch can be the upstream too, and then
`git branch -vv` reports how far behind `main` the topic branch is. The old
`--set-upstream` was removed because its syntax was confusing, Git's
documentation says.

## Renaming a branch

```console
$ git branch -m topic feature/login
$ git branch -vv --list feature/login
  feature/login edd63cb [main: behind 1] Add a style sheet
$ git config get --all --show-names --regexp '^branch\.feature/login'
branch.feature/login.remote .
branch.feature/login.merge refs/heads/main
$ git reflog show feature/login
edd63cb feature/login@{0}: Branch: renamed refs/heads/topic to refs/heads/feature/login
edd63cb feature/login@{1}: branch: Reset to v1.0
b293e3e feature/login@{2}: branch: Created from main
$ git branch draft main
$ git branch -m feature/login draft
fatal: a branch named 'draft' already exists
$ git branch -M feature/login draft
$ git branch -vv --list draft
  draft edd63cb [main: behind 1] Add a style sheet
$ git branch -m main trunk
$ git branch --show-current
trunk
$ git branch -m main
$ git branch --show-current
main
$ git branch -m docs manual
$ cd ../site-docs
$ git branch --show-current
manual
$ cd ../site
$ git branch -m manual docs
$ git branch -m nosuch other
fatal: no branch named 'nosuch'
$ git branch -m draft 'bad name'
fatal: 'bad name' is not a valid branch name
hint: See 'git help check-ref-format'
hint: Disable this message with "git config set advice.refSyntax false"
```

`-m <old> <new>` renames a branch, and its upstream settings and reflog go with
it; the reflog gains a line recording the rename. With one name, `-m` renames the
current branch, and you stay on it under the new name. A branch checked out in
another worktree can be renamed too, and that worktree follows.

`-m` refuses a name that is taken. `-M` replaces that branch: `draft` pointed at
`main`'s commit and now points where `feature/login` did, and the old `draft` is
gone without a warning.

> **Careful.** Renaming changes only your repository. A branch already on the
> server keeps its old name there, and your upstream setting still names it.
> Pushing the new name and deleting the old one on the server is Chapter 43.

```console
$ git -c init.defaultBranch=master init -q ../old
$ cd ../old
$ git branch --show-current
master
$ git branch -m main
$ git branch --show-current
main
$ cd ../site
```

A repository made with the default branch `master` (Chapter 3 explains the
setting) can be renamed straight away, even before its first commit.

## Copying a branch

```console
$ git branch -c fix-typo fix-typo-copy
$ git branch -c main main-backup
$ git branch --show-current
main
$ git branch -vv --list 'fix-typo*' 'main*'
  fix-typo      b293e3e Fix a typo on the home page
  fix-typo-copy b293e3e Fix a typo on the home page
* main          b293e3e [origin/main: ahead 1] Fix a typo on the home page
  main-backup   b293e3e [origin/main: ahead 1] Fix a typo on the home page
$ git config get --all --show-names --regexp '^branch\.main'
branch.main.remote origin
branch.main.merge refs/heads/main
branch.main-backup.remote origin
branch.main-backup.merge refs/heads/main
$ git branch -c fix-typo draft
fatal: a branch named 'draft' already exists
$ git branch -C fix-typo draft
$ git branch -vv --list draft
  draft b293e3e [main] Fix a typo on the home page
```

`-c` makes a second branch at the same commit, with a copy of the upstream
settings and reflog, and leaves you on the branch you were on. `-C` replaces an
existing branch. Copying `draft`'s name over kept `draft`'s own upstream,
`main`, rather than `fix-typo`'s, which had none.

`git branch main-backup main` would also create a branch at the same commit, but
would copy neither the upstream settings nor the reflog's history.

## Deleting a branch

### Merged and unmerged branches

```console
$ git branch -d fix-typo-copy draft
Deleted branch fix-typo-copy (was b293e3e).
Deleted branch draft (was b293e3e).
$ git branch -d main-backup
warning: not deleting branch 'main-backup' that is not yet merged to
         'refs/remotes/origin/main', even though it is merged to HEAD
error: the branch 'main-backup' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D main-backup'
hint: Disable this message with "git config set advice.forceDeleteBranch false"
$ git branch --delete --force main-backup
Deleted branch main-backup (was b293e3e).
$ git branch -d old-idea
error: the branch 'old-idea' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D old-idea'
hint: Disable this message with "git config set advice.forceDeleteBranch false"
$ git branch -D old-idea
Deleted branch old-idea (was 1f0d93b).
```

`-d` deletes only a branch that is fully merged, and prints the hash the branch
pointed at. Git's documentation defines merged here as merged into the branch's
upstream, or into `HEAD` if it has none. `main-backup` was a copy of `main`, so
it tracked `origin/main`, which lacks its last commit: merged into `HEAD`, but
not into its upstream, and refused.

`-D`, the same as `--delete --force`, deletes whatever the branch holds. The
commits themselves are not deleted at once; they are only unnamed, which is what
the next section relies on.

### Getting a deleted branch back

```console
$ git reflog show old-idea
fatal: ambiguous argument 'old-idea': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
$ git branch old-idea 1f0d93b
$ git reflog | grep 'dark theme'
1f0d93b HEAD@{15}: commit: Try a dark theme
$ git reflog show old-idea
1f0d93b old-idea@{0}: branch: Created from 1f0d93b
```

The branch's own reflog was deleted with it. The hash in "Deleted branch old-idea
(was 1f0d93b)" is enough to create the branch again. If that message is gone,
the reflog of `HEAD` still lists the commits made in this repository, and
searching it for the commit's title found the hash. The new branch starts a
new reflog.

> **Careful.** Unnamed commits are kept only for a while. Git's documentation
> gives reflog entries for commits no longer on any branch 30 days by default,
> and garbage collection may then remove the commits (Chapter 77). Chapter 79
> covers recovering branches in depth.

### Branches that cannot be deleted

```console
$ git branch -d main
error: cannot delete branch 'main' used by worktree at '/home/ada/site'
$ git branch -D docs
error: cannot delete branch 'docs' used by worktree at '/home/ada/site-docs'
$ git branch -d nosuch
error: branch 'nosuch' not found
$ git branch -d feature/search
warning: deleting branch 'feature/search' that has been merged to
         'refs/remotes/origin/feature/search', but not yet merged to HEAD
Deleted branch feature/search (was b34c401).
$ git branch -d origin/docs
error: branch 'origin/docs' not found.
Did you forget --remote?
```

Neither `-d` nor `-D` deletes a branch checked out in a worktree: switch away
first, or remove the worktree (Chapter 56). `feature/search` was not merged into
`main`, but it was merged into its upstream, and that is the rule, so Git deleted
it and warned. Its commits are still on `origin/feature/search`.

### Remote-tracking branches and gone upstreams

```console
$ git branch -d -r origin/docs
Deleted remote-tracking branch origin/docs (was 5975a71).
$ git branch -r
  origin/HEAD -> origin/main
  origin/feature/search
  origin/main
  origin/release
$ git branch -vv --list docs
+ docs 5975a71 (/home/ada/site-docs) [origin/docs: gone] Write the README
$ git branch -q -d fix-typo
$ git branch
+ docs
* main
  old-idea
```

`-d -r` deletes a remote-tracking branch from your repository only; the branch on
the server is untouched, and Git's documentation notes the next `git fetch`
creates it again unless fetching is configured not to. It is for cleaning up
branches deleted on the server, which `git fetch --prune` does for all of them
(Chapter 41). Deleting a branch on the server is Chapter 43.

A local branch whose upstream no longer exists shows `gone`. `-q` deleted
`fix-typo` without a message.

## Branch descriptions

```console
$ GIT_EDITOR=cat git branch --edit-description old-idea

# Please edit the description for the branch
#   old-idea
# Lines starting with '#' will be stripped.
$ GIT_EDITOR="sed -i '1i A dark theme, on hold until the redesign.'" git branch --edit-description old-idea
$ git config get branch.old-idea.description
A dark theme, on hold until the redesign.

$ git -c merge.branchdesc=true merge --no-ff --no-commit old-idea
Automatic merge went well; stopped before committing as requested
$ cat .git/MERGE_MSG
Merge branch 'old-idea'
$ git merge --abort
$ git -c merge.branchdesc=true merge --no-ff --no-commit --log old-idea
Automatic merge went well; stopped before committing as requested
$ cat .git/MERGE_MSG
Merge branch 'old-idea'

* old-idea:
  : A dark theme, on hold until the redesign.
  Try a dark theme
$ git merge --abort
$ git switch -q --detach
$ GIT_EDITOR=cat git branch --edit-description
fatal: cannot give description to detached HEAD
$ git switch -q main
```

`--edit-description` opens your editor on a template; lines starting with `#`
are dropped. `GIT_EDITOR` sets the editor for one command (Chapter 62): `cat`
showed the template, and `sed` wrote a line into it the way you would type one.
The description is stored as the setting `branch.<name>.description`, so it stays
in your repository and is not pushed.

Git's documentation says the description is used by `git format-patch` and
`git request-pull` (Chapter 61), and by `git merge` when `merge.branchdesc` is
on. Tried here, the merge message included it only together with `--log`, which
lists the merged commits (Chapter 25). `git merge --no-commit` stopped before
committing, so `.git/MERGE_MSG` could be read, and `--abort` undid the merge.

## branch and its neighbours

```console
$ git show-branch main old-idea
* [main] Fix a typo on the home page
 ! [old-idea] Try a dark theme
--
 + [old-idea] Try a dark theme
*  [main] Fix a typo on the home page
*+ [old-idea^] Add a style sheet
$ git switch -c topic2
Switched to a new branch 'topic2'
$ git checkout -b topic3
Switched to a new branch 'topic3'
$ git switch -q main
$ git update-ref refs/heads/raw HEAD
$ git branch --list raw
  raw
```

| Modern | Classic | Does |
|---|---|---|
| `git switch -c <branch> [<start-point>]` | `git checkout -b <branch> [<start-point>]` | create a branch and switch to it |
| `git branch <branch> [<start-point>]` | `git branch <branch> [<start-point>]` | create a branch and stay where you are |

Most of the time a new branch is for working on straight away, and
`git switch -c` does both steps (Chapter 24). `git branch` is for making a branch
you will come back to, or moving and managing branches.

| Command | Use it when |
|---|---|
| `git branch` | you want to see, create, rename or delete branches |
| `git for-each-ref refs/heads` | a script needs branches in a custom format with more filters (Chapter 22) |
| `git show-branch` | you want to see, side by side, which commits each of a few branches has |
| `git update-ref` | a script must set a ref directly, without `git branch`'s checks (Chapter 74) |
| `git tag` | you want a name that does not move when you commit (Chapter 47) |

`git show-branch` above lists each branch first, `*` for the current one and `!`
for others, then one line per commit with a column for each branch: a mark in a
column means that branch has the commit, `*` in the current branch's column and
`+` in the others. `old-idea` has a commit `main` lacks, `main` has one
`old-idea` lacks, and the last line is the commit both contain. `git update-ref` created a branch the
plumbing way, with no message (Chapter 74).

## The settings

| Setting | Effect |
|---|---|
| `branch.sort` | Default `--sort` for listing |
| `column.branch`, `column.ui` | Default `--column` |
| `color.branch`, `color.ui` | Default `--color` |
| `color.branch.<slot>` | Colours of `current`, `local`, `remote`, `upstream`, `worktree` and `plain` |
| `branch.autoSetupMerge` | When new branches track their start point; `true` by default |
| `branch.autoSetupRebase` | When new tracking branches pull with rebase; `never` by default |
| `branch.<name>.remote`, `branch.<name>.merge` | The branch's upstream, as `-u` sets it |
| `branch.<name>.rebase` | Whether `git pull` rebases this branch (Chapter 42) |
| `branch.<name>.pushRemote` | Where `git push` sends this branch, if not its upstream's remote (Chapter 43) |
| `branch.<name>.mergeOptions` | Default options for merging into this branch (Chapter 25) |
| `branch.<name>.description` | The description `--edit-description` writes |
| `core.logAllRefUpdates` | Whether new branches get a reflog; on by default with a working tree |
| `merge.branchdesc` | Put branch descriptions in merge messages, with `--log` |
| `pager.branch` | Whether the list goes through a pager; Git's documentation says it applies only when listing |
| `submodule.propagateBranches` | Allow `--recurse-submodules` |
