# Chapter 10. status

## What it is

`git status` is the command you will run more than all the others put together.
It answers three questions at once: where am I, what have I changed, and what
is Git in the middle of doing.

"What have I changed" is really three comparisons, one for each pair of the
three areas from Chapter 5:

| Comparison | Answers |
|---|---|
| The index against `HEAD`, the last commit | What would go into a commit made now |
| The working tree against the index | What you changed but have not staged |
| Files in the working tree that are not in the index | What Git is not tracking at all |

A file in the index is *tracked*; a file only in the working tree is
*untracked*; a change copied into the index is *staged*. Chapter 8 follows one
file through all of these states.

"Where am I" is the current branch, and how it compares with its *upstream*: the
remote-tracking branch it was set up to follow, such as `origin/main` for
`main` after a clone (Chapter 9). Chapter 41 covers upstreams in full.

`git status` only reports. It never changes your files, what is staged, or a
branch, so it is always safe to run, including in the middle of a merge that has
gone wrong. The one thing it may write is cached file information inside the
index, which [Large repositories](#large-repositories) explains.

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What does `git status` actually compare?](#what-it-is)
- [Can running `git status` change or break anything?](#what-it-is)

**[Synopsis](#synopsis)**

- [What can I type after `git status`?](#synopsis)

**[Options at a glance](#options-at-a-glance)**

- [Is there a list of every option, and where each is explained?](#options-at-a-glance)

**[Reading the long format](#reading-the-long-format)**

- [Does "Your branch is up to date" mean nobody has pushed anything new?](#a-clean-tree)
- [Why is the same file listed under two different headings?](#everything-at-once)
- [Why does status show a folder instead of the new files inside it?](#everything-at-once)
- [What does status say in a brand-new repository?](#before-the-first-commit)
- [What does "not a git repository" mean?](#outside-a-repository)

**[The short format](#the-short-format)**

- [What do the two letters in front of each file mean?](#the-short-format)
- [What is the difference between ` M` and `M `?](#the-short-format)
- [What do `AM`, `MD`, `RM` and the other pairs mean?](#every-combination-of-the-two-columns)
- [What is a `T`?](#a-type-change)
- [Why does status put some file names in quotes, or show numbers like `\303\251`?](#file-names-with-spaces-and-other-characters)

**[The branch header](#the-branch-header)**

- [What do `[ahead 1]`, `[behind 3]` and `[gone]` mean after the branch name?](#the-branch-header)
- [How do I see which commits I haven't pushed yet?](#ahead-behind-and-diverged)
- [What does "have diverged" mean, and what should I do?](#ahead-behind-and-diverged)
- [Status is slow in a huge repository because of the ahead/behind count. Can I skip it?](#skipping-the-count)
- [What does "the upstream is gone" mean?](#no-upstream-or-an-upstream-that-is-gone)
- [Why does status say "HEAD detached at" instead of a branch?](#detached-head)
- [I push to my fork but pull from the original project. Can status compare with both?](#comparing-with-more-than-one-branch)

**[Limiting status to some paths](#limiting-status-to-some-paths)**

- [Can I see the status of one folder or one file only?](#limiting-status-to-some-paths)
- [Why do paths start with `../` when I'm in a subfolder?](#limiting-status-to-some-paths)
- [Status said "working tree clean" but I know I changed files. What happened?](#limiting-status-to-some-paths)

**[How much to say about untracked files](#how-much-to-say-about-untracked-files)**

- [How do I see every new file inside a new folder, not just the folder?](#how-much-to-say-about-untracked-files)
- [How do I hide untracked files completely?](#how-much-to-say-about-untracked-files)
- [I typed `git status -u no` and got no output at all. Why?](#how-much-to-say-about-untracked-files)

**[Ignored files](#ignored-files)**

- [How do I see the files Git is ignoring?](#ignored-files)
- [What is the difference between `--ignored` and `--ignored=matching`?](#ignored-files)

**[Renames](#renames)**

- [Why does status show a rename when I only deleted one file and added another?](#renames)
- [How do I make status show a delete and an add instead of a rename?](#renames)
- [I copied a file. Why doesn't status say "copied"?](#renames)

**[Showing the changes themselves](#showing-the-changes-themselves)**

- [Can status show me the actual changes, not just the file names?](#showing-the-changes-themselves)

**[The stash](#the-stash)**

- [Can status remind me that I have something stashed?](#the-stash)

**[Untracked files in columns](#untracked-files-in-columns)**

- [I have fifty new files. Can status list them more compactly?](#untracked-files-in-columns)

**[Choosing the format by default](#choosing-the-format-by-default)**

- [Can I make `git status` always use the short format?](#choosing-the-format-by-default)
- [How do I get rid of the "(use git add...)" hint lines?](#choosing-the-format-by-default)
- [Why do some people's status lines start with `#`?](#choosing-the-format-by-default)

**[Output for scripts](#output-for-scripts)**

- [How should a script read the output of `git status`?](#output-for-scripts)
- [What is the difference between `--short` and `--porcelain`?](#porcelain-version-1)
- [What do all the fields in `--porcelain=v2` mean?](#porcelain-version-2)
- [How do I handle file names with spaces or newlines in a script?](#separating-entries-with-nul)
- [How can a script tell whether there are uncommitted changes?](#is-the-tree-dirty)

**[During a conflict](#during-a-conflict)**

- [A merge stopped. What does status tell me?](#during-a-conflict)
- [What do `UU`, `AA`, `DU` and the other conflict codes mean?](#every-conflict-code)

**[During a rebase](#during-a-rebase)**

- [Why does status say "interactive rebase" when I ran a plain `git rebase`?](#during-a-rebase)

**[Other operations in progress](#other-operations-in-progress)**

- [How do I tell whether I'm in the middle of a cherry-pick, a revert or a bisect?](#other-operations-in-progress)
- [I fixed every conflict but status still says I'm merging. What now?](#other-operations-in-progress)
- [What does "sparse checkout with 67% of tracked files present" mean?](#other-operations-in-progress)

**[Colour](#colour)**

- [What do the red and green colours mean, and can I change them?](#colour)

**[Large repositories](#large-repositories)**

- [`git status` takes seconds in a big repository. What can I do?](#large-repositories)
- [A background tool running `git status` makes my own Git commands fail on a lock. Why?](#large-repositories)

**[status and its neighbours](#status-and-its-neighbours)**

- [Should I use `git status`, `git diff --name-status`, or `git ls-files`?](#status-and-its-neighbours)
- [What is the difference between `git status` and `git commit --dry-run`?](#status-and-its-neighbours)

**[The settings](#the-settings)**

- [Which settings change what `git status` shows?](#the-settings)

</details>

## Synopsis

```
git status [<options>] [--] [<pathspec>...]
```

| Part | Means |
|---|---|
| `<options>` | Any of the options below |
| `<pathspec>` | Report only on these paths. See [Limiting status to some paths](#limiting-status-to-some-paths) |
| `--` | Everything after it is a path, even if it looks like an option |

| Command | Does |
|---|---|
| `git status` | The full, human-readable report |
| `git status -s` | One line per file |
| `git status -sb` | One line per file, with the branch on top |
| `git status --porcelain=v2 --branch` | A stable format for scripts |
| `git status -- <path>` | Only what concerns `<path>` |

## Options at a glance

| Option | Does | Covered in |
|---|---|---|
| `-s`, `--short` | One line per file, two status letters each | [The short format](#the-short-format) |
| `--long`, `--no-short` | The full report, the default; overrides `status.short` | [Choosing the format by default](#choosing-the-format-by-default) |
| `-b`, `--branch` | Add the branch header, even in the short format | [The branch header](#the-branch-header) |
| `--no-branch` | Leave the header out; overrides `status.branch` | [Choosing the format by default](#choosing-the-format-by-default) |
| `--porcelain`, `--porcelain=v1` | The short format, with a promise not to change | [Output for scripts](#output-for-scripts) |
| `--porcelain=v2` | A detailed, stable format for scripts | [Output for scripts](#output-for-scripts) |
| `-z` | End each entry with a NUL, a zero byte, and never quote paths | [Output for scripts](#output-for-scripts) |
| `-u`, `--untracked-files` | Every untracked file individually, the same as `=all` | [How much to say about untracked files](#how-much-to-say-about-untracked-files) |
| `-uno`, `--untracked-files=no` | No untracked files | [How much to say about untracked files](#how-much-to-say-about-untracked-files) |
| `-unormal`, `--untracked-files=normal` | Untracked files, whole new directories as one line. The default | [How much to say about untracked files](#how-much-to-say-about-untracked-files) |
| `-uall`, `--untracked-files=all` | Every untracked file individually | [How much to say about untracked files](#how-much-to-say-about-untracked-files) |
| `--ignored`, `--ignored=traditional` | Also list ignored files | [Ignored files](#ignored-files) |
| `--ignored=matching` | List ignored paths the way the patterns matched them | [Ignored files](#ignored-files) |
| `--ignored=no` | No ignored files, the default | [Ignored files](#ignored-files) |
| `--renames`, `--no-renames` | Detect renames, or report a delete and an add | [Renames](#renames) |
| `-M[<n>]`, `--find-renames[=<n>]` | Detect renames with a similarity threshold | [Renames](#renames) |
| `-v`, `--verbose` | Also print the staged diff; twice, the unstaged one too | [Showing the changes themselves](#showing-the-changes-themselves) |
| `--show-stash` | Say how many entries the stash holds (Chapter 55) | [The stash](#the-stash) |
| `--column[=<options>]`, `--no-column` | List untracked files in columns | [Untracked files in columns](#untracked-files-in-columns) |
| `--ahead-behind`, `--no-ahead-behind` | Count commits ahead and behind the upstream, or skip it | [Skipping the count](#skipping-the-count) |
| `--ignore-submodules[=<when>]` | Ignore some or all changes inside submodules | Chapter 57 |

## Reading the long format

### A clean tree

```console
$ git status
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
$ git status --short
$ git status -sb
## main...origin/main
```

The short form prints nothing when there is nothing to say, which makes it
usable in a shell prompt or a script.

> **Careful.** "Your branch is up to date with `origin/main`" involves no
> network. It compares against your last known copy of the remote, which could
> be from a week ago. `git fetch` first if you want that sentence to mean
> anything. Chapter 41 explains why this is the right default anyway.

### Everything at once

Here is a working tree with one of every kind of change in it:

```console
$ git status
On branch main
Your branch is up to date with 'origin/main'.

Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   README.md
	renamed:    notes.md -> docs.md

Changes not staged for commit:
  (use "git add/rm <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	deleted:    .gitignore
	modified:   README.md
	modified:   app.py

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	build/
	newfile.txt

```

Three headings, and they map exactly onto the three areas from Chapter 5:

| Heading | Compares | Fixed with |
|---|---|---|
| Changes to be committed | index against HEAD | `git restore --staged` |
| Changes not staged for commit | working tree against index | `git add`, or `git restore` |
| Untracked files | not in the index at all | `git add`, or an ignore rule |

`README.md` appears under two headings. That is the staged-then-edited-again
state, and Chapter 5 takes it apart.

Notice `build/` is listed as a directory, not as the two files inside it. When
every file in a directory is untracked, Git collapses it to one line. That is a
deliberate mercy in a repository where you just unpacked a `node_modules`.

`build/` shows up at all only because `.gitignore`, which ignored it, has been
deleted in this tree. The lines in brackets are hints, and each one names the
command that moves a file out of that heading; Chapter 14 covers `restore`.

The same tree in short form:

```console
$ git status --short
 D .gitignore
MM README.md
 M app.py
R  notes.md -> docs.md
?? build/
?? newfile.txt
```

### Before the first commit

```console
$ git status
On branch main

No commits yet

nothing to commit (create/copy files and use "git add" to track)
$ git status -sb
## No commits yet on main
$ git status
On branch main

No commits yet

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	a.txt

nothing added to commit but untracked files present (use "git add" to track)
```

There is no upstream line, because there is nothing to compare, and the last
line changes to tell you why a commit would be empty.

### Outside a repository

```console
$ git status
fatal: not a git repository (or any of the parent directories): .git
```

Git looked for a `.git` in the current directory and in every directory above
it, and found none. Either you are in the wrong directory, or the repository was
never created (Chapter 9).

## The short format

```console
$ git status --short
 D .gitignore
MM README.md
 M app.py
R  notes.md -> docs.md
?? build/
?? newfile.txt
```

Two columns. The left is the index against HEAD, the right is the working tree
against the index.

| Letter | Meaning |
|---|---|
| (space) | unmodified |
| `M` | modified |
| `T` | type changed, for instance a file became a symlink |
| `A` | added |
| `D` | deleted |
| `R` | renamed |
| `C` | copied, only when `status.renames` is set to `copies` |
| `U` | unmerged, meaning a conflict |
| `?` | untracked, and always in both columns as `??` |
| `!` | ignored, and always `!!`, shown only with `--ignored` |

Chapter 5 has a table of worked examples. The one rule that catches everybody:
` M` and `M ` are different states, and the difference is a space.

### Every combination of the two columns

Each file below had something different done to it after the last commit:

```console
$ git status --short
M  a.txt
MM b.txt
MD c.txt
D  d.txt
 D e.txt
 M f.txt
R  g.txt -> g2.txt
RM h.txt -> h2.txt
RD i.txt -> i2.txt
A  new1.txt
AM new2.txt
AD new3.txt
```

| Code | What happened | Committing now would |
|---|---|---|
| `M ` | changed, then `git add` | include the change |
| `MM` | changed, `git add`, then changed again | include only the first change |
| `MD` | changed, `git add`, then the file deleted | include the change; the file stays deleted on disk |
| `D ` | `git rm` | delete the file |
| ` D` | deleted, but not with `git rm` | change nothing; the file still exists in the commit |
| ` M` | changed, not added | change nothing |
| `R ` | `git mv` | record the rename |
| `RM` | `git mv`, then changed | record the rename, without the new change |
| `RD` | `git mv`, then the new file deleted | record the rename; the file is gone on disk |
| `A ` | a new file, `git add` | add the file |
| `AM` | a new file, `git add`, then changed | add the file as it was when added |
| `AD` | a new file, `git add`, then deleted | still add the file, from the copy in the index |

The last row is the one that surprises people: the index keeps its own copy, so
deleting the file from disk does not take it out of the next commit. Chapter 14
covers taking it out.

The long format says the same, splitting each two-letter code across its two
headings:

```console
$ git status
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   a.txt
	modified:   b.txt
	modified:   c.txt
	deleted:    d.txt
	renamed:    g.txt -> g2.txt
	renamed:    h.txt -> h2.txt
	renamed:    i.txt -> i2.txt
	new file:   new1.txt
	new file:   new2.txt
	new file:   new3.txt

Changes not staged for commit:
  (use "git add/rm <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   b.txt
	deleted:    c.txt
	deleted:    e.txt
	modified:   f.txt
	modified:   h2.txt
	deleted:    i2.txt
	modified:   new2.txt
	deleted:    new3.txt

```

`R` can appear in the right column too. A file renamed on disk, whose new name
was added with `git add -N`, is a rename between the index and the working tree
(Chapter 11 covers `-N`):

```console
$ mv j.txt j2.txt && git add -N j2.txt
$ git status --short -- j.txt j2.txt
 R j.txt -> j2.txt
```

Git's documentation lists ` C` for a copy found the same way. Conflicts use
codes of their own, in [During a conflict](#during-a-conflict).

### A type change

A *type change* is a path that was one kind of thing and is now another: a
regular file, a symbolic link, or a submodule. This index entry was changed from
a file to a symbolic link with the plumbing command `git update-index`, which
Chapter 75 covers:

```console
$ git update-index --cacheinfo 120000,55562a1421e87c4c628d98a410e262f1b31512ce,link.txt
$ git status --short
T  link.txt
$ git status
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	typechange: link.txt

```

Git's documentation lists ` T` for the same change made in the working tree,
such as replacing a file by a symbolic link on a system that has them. The
sandbox runs with `core.symlinks=false`, where Git writes a link as a plain file
holding the target's name, so it cannot show that case.

### File names with spaces and other characters

```console
$ git status --short
R  "old name.txt" -> "new name.txt"
?? "caf\303\251.txt"
$ git -c core.quotePath=false status --short
R  "old name.txt" -> "new name.txt"
?? café.txt
```

The short format puts a name in double quotes when it contains a space or an
unusual character, and writes each byte outside plain ASCII as a backslash and
three octal digits: `\303\251` is the two bytes that make `é` in UTF-8.
`core.quotePath=false` shows such characters as they are; names with spaces are
still quoted. For scripts, `-z` turns quoting off entirely, in
[Separating entries with NUL](#separating-entries-with-nul).

`git -c <name>=<value>` sets a configuration value for one command only, without
changing any file (Chapter 62).

## The branch header

```console
$ git status -sb
## main...origin/main
 D .gitignore
MM README.md
 M app.py
R  notes.md -> docs.md
?? build/
?? newfile.txt
```

`-sb` is `--short --branch`. The header line follows a fixed grammar:

| Header | Means |
|---|---|
| `## main...origin/main` | On `main`, tracking `origin/main`, in step |
| `## main...origin/main [ahead 1]` | One local commit not pushed |
| `## main...origin/main [behind 3]` | Three commits fetched but not merged |
| `## main...origin/main [ahead 2, behind 3]` | Diverged. Chapter 45 |
| `## main...origin/main [different]` | Not the same commit; counting was skipped |
| `## main...origin/main [gone]` | The upstream branch no longer exists |
| `## main` | On `main`, tracking nothing |
| `## HEAD (no branch)` | Detached |
| `## No commits yet on main` | Fresh repository |

`--ahead-behind` is on by default, so adding it changes nothing:

```console
$ git status --short --branch --ahead-behind
## main...origin/main
 D .gitignore
MM README.md
 M app.py
R  notes.md -> docs.md
?? build/
?? newfile.txt
```

### Ahead, behind, and diverged

```console
$ git status -sb
## main...origin/main [ahead 1]
$ git status
On branch main
Your branch is ahead of 'origin/main' by 1 commit.
  (use "git push" to publish your local commits)

nothing to commit, working tree clean
$ git log --oneline origin/main..HEAD
7c7cb78 Work in progress
```

That last command is how you see *which* commits, and the `..` syntax is
Chapter 18.

In another repository, a colleague pushed a commit, which `git fetch` brought
in:

```console
$ git status -sb
## main...origin/main [behind 1]
$ git status
On branch main
Your branch is behind 'origin/main' by 1 commit, and can be fast-forwarded.
  (use "git pull" to update your local branch)

nothing to commit, working tree clean
```

Then a local commit on top, so both sides have one the other lacks:

```console
$ git status -sb
## main...origin/main [ahead 1, behind 1]
$ git status
On branch main
Your branch and 'origin/main' have diverged,
and have 1 and 1 different commits each, respectively.
  (use "git pull" if you want to integrate the remote branch with yours)

nothing to commit, working tree clean
```

| Long format says | Short header | What to do |
|---|---|---|
| is up to date with | nothing after the names | nothing |
| is ahead of ... by N commits | `[ahead N]` | `git push` (Chapter 43) |
| is behind ... and can be fast-forwarded | `[behind N]` | `git pull` (Chapter 42) |
| have diverged | `[ahead N, behind M]` | merge or rebase, then push (Chapter 45) |

### Skipping the count

Counting means walking history on both sides, which can take a while when the
two branches are thousands of commits apart. `--no-ahead-behind` only checks
whether they point at the same commit:

```console
$ git status --no-ahead-behind
On branch main
Your branch and 'origin/main' refer to different commits.
  (use "git status --ahead-behind" for details)

nothing to commit, working tree clean
$ git status -sb --no-ahead-behind
## main...origin/main [different]
$ git status --porcelain=v2 --branch --no-ahead-behind
# branch.oid 7471ac77eedcab3f7140c9c8721a0eea02eb73a5
# branch.head main
# branch.upstream origin/main
# branch.ab +? -?
```

`status.aheadBehind` sets the default, but only for the human formats, as Git's
documentation says and this shows:

```console
$ git -c status.aheadBehind=false status -sb
## main...origin/main [different]
$ git -c status.aheadBehind=false status --porcelain=v2 --branch
# branch.oid 7471ac77eedcab3f7140c9c8721a0eea02eb73a5
# branch.head main
# branch.upstream origin/main
# branch.ab +1 -1
```

A script that asks for `--porcelain=v2` gets the counts unless it passes
`--no-ahead-behind` itself.

### No upstream, or an upstream that is gone

```console
$ git switch -q -c solo
$ git status -sb
## solo
$ git status
On branch solo
nothing to commit, working tree clean
```

A new local branch has no upstream, so there is nothing to compare and no line
about it. Pushing it with `-u` sets one (Chapter 43); deleting the branch on the
server then leaves the setting pointing at nothing:

```console
$ git push -q -u origin solo
$ git push -q origin --delete solo
$ git status -sb
## solo...origin/solo [gone]
$ git status
On branch solo
Your branch is based on 'origin/solo', but the upstream is gone.
  (use "git branch --unset-upstream" to fixup)

nothing to commit, working tree clean
$ git status --porcelain=v2 --branch
# branch.oid 7471ac77eedcab3f7140c9c8721a0eea02eb73a5
# branch.head solo
# branch.upstream origin/solo
```

"Gone" is normal after a pull request is merged and its branch deleted on the
server. Your commits are safe; only the name you tracked has disappeared. In v2
the `branch.ab` line is simply missing. Chapter 41 covers cleaning up such
branches.

### Detached HEAD

```console
$ git status
HEAD detached at 372e727
nothing to commit, working tree clean
$ git status -sb
## HEAD (no branch)
```

Note there is no "your branch is up to date" line, because there is no branch.
Chapter 7 covers how you get here and how to keep any commits you make.

```console
$ git status --porcelain=v2 --branch
# branch.oid 7471ac77eedcab3f7140c9c8721a0eea02eb73a5
# branch.head (detached)
```

### Comparing with more than one branch

Some people pull from one remote and push to another: they fetch the original
project from `origin` and push their work to their own copy, `fork`. This
repository is set up that way with two settings Chapter 43 explains, and then
gets a commit that has been pushed nowhere:

```console
$ git remote add fork /home/ada/fork.git
$ git config set remote.pushDefault fork
$ git config set push.default current
$ git push -q
$ git status
On branch main
Your branch and 'origin/main' have diverged,
and have 2 and 1 different commits each, respectively.
  (use "git pull" if you want to integrate the remote branch with yours)

nothing to commit, working tree clean
```

By default status compares only with the upstream, `origin/main`, and says
nothing about `fork`. `status.compareBranches` lists what to compare with:

```console
$ git -c 'status.compareBranches=@{upstream} @{push}' status
On branch main
Your branch and 'origin/main' have diverged,
and have 2 and 1 different commits each, respectively.
  (use "git pull" if you want to integrate the remote branch with yours)

Your branch is ahead of 'fork/main' by 1 commit.
  (use "git push" to publish your local commits)

nothing to commit, working tree clean
$ git -c 'status.compareBranches=@{push}' status
On branch main
Your branch is ahead of 'fork/main' by 1 commit.
  (use "git push" to publish your local commits)

nothing to commit, working tree clean
$ git -c 'status.compareBranches=@{upstream} @{push}' status -sb
## main...origin/main [ahead 2, behind 1]
```

`@{upstream}` is the branch you pull from and `@{push}` the branch a plain
`git push` would update (Chapter 18). Each comparison gets its own paragraph, in
the order listed, and leaving `@{upstream}` out removes that one. Only the long
format uses the setting; the short header still shows the upstream alone. Git's
documentation adds that a comparison is shown once when two entries name the
same branch.

> **Since Git 2.54.** `status.compareBranches`.

## Limiting status to some paths

In a subdirectory, status still reports the whole repository, but writes every
path relative to where you are:

```console
$ git status
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   ../README.md
	modified:   app.py
	modified:   lib/util.py

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	new.py

no changes added to commit (use "git add" and/or "git commit -a")
$ git status --short
 M ../README.md
 M app.py
 M lib/util.py
?? new.py
$ git -c status.relativePaths=false status --short
 M README.md
 M src/app.py
 M src/lib/util.py
?? src/new.py
```

Git's documentation says the relative paths are on purpose, so that a path can
be copied from the output straight into the next command. `status.relativePaths`
set to `false` shows paths from the top of the repository instead.

Paths after the options narrow the report. They are pathspecs, the same patterns
`git add` takes (Chapter 11):

```console
$ git status --short .
 M app.py
 M lib/util.py
?? new.py
$ git status --short -- lib
 M lib/util.py
$ git status --short :/README.md
 M ../README.md
$ cd ..
$ git status --short -- '*.py'
 M src/app.py
 M src/lib/util.py
?? src/new.py
```

`.` is the current directory, and `:/` at the start means "from the top of the
repository". From the top, `'*.py'` matches in every directory, because in a
pathspec `*` also matches `/`; the quotes stop the shell expanding the pattern
first.

> **Careful.** A path that matches nothing is not an error. Status reports on
> nothing, and says so in the words it uses for a clean tree:
>
> ```console
> $ git status nothing-here
> On branch main
> nothing to commit, working tree clean
> ```
>
> Three files in this repository are modified. A typo in a path makes status
> look reassuring.

## How much to say about untracked files

```console
$ git status --short --untracked-files=normal
 D .gitignore
MM README.md
 M app.py
R  notes.md -> docs.md
?? build/
?? extra/
?? newfile.txt
$ git status --short --untracked-files=all
 D .gitignore
MM README.md
 M app.py
R  notes.md -> docs.md
?? build/another.log
?? build/out.log
?? extra/one.txt
?? extra/two.txt
?? newfile.txt
$ git status --short --untracked-files=no
 D .gitignore
MM README.md
 M app.py
R  notes.md -> docs.md
```

| Option | Shows |
|---|---|
| `--untracked-files=no`, `-uno` | No untracked files at all |
| `--untracked-files=normal`, `-unormal` | Untracked files, with whole directories collapsed. The default |
| `--untracked-files=all`, `-uall` | Every untracked file individually |
| `--untracked-files`, `-u` | The same as `all` |
| `--untracked-files=true` | The same as `normal` |
| `--untracked-files=false` | The same as `no` |

The long form tells you when it is hiding something:

```console
$ git status -uno
On branch main
Your branch is up to date with 'origin/main'.

Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   README.md
	renamed:    notes.md -> docs.md

Changes not staged for commit:
  (use "git add/rm <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	deleted:    .gitignore
	modified:   README.md
	modified:   app.py

Untracked files not listed (use -u option to show untracked files)
```

The less common spellings, in a repository with one new directory holding two
files, and one new file at the top:

```console
$ git status --short -u
?? dir/one.txt
?? dir/two.txt
?? top.txt
$ git status --short --untracked-files=true
?? dir/
?? top.txt
$ git status --short --untracked-files=false
$ git status --short --untracked-files=maybe
fatal: Invalid untracked files mode 'maybe'
$ git -c status.showUntrackedFiles=all status --short
?? dir/one.txt
?? dir/two.txt
?? top.txt
$ git -c status.showUntrackedFiles=all status --short -unormal
?? dir/
?? top.txt
```

`-u` on its own means `all`, not the default `normal`. The option on the command
line beats the setting.

The value must be attached to `-u`, with no space:

```console
$ git status --short -u no
```

Nothing at all. With a space, `-u` took no value and meant `all`, and `no`
became a path, so status reported on a path called `no`, which does not exist.

> **Careful.** Setting `status.showUntrackedFiles = no` globally is a popular
> speed tip for very large repositories. It also means you will one day commit
> a change and discover the new file you created was never added, because
> nothing ever mentioned it. If you do set it, set it per-repository, and know
> that Git will still print the "not listed" line to remind you.

## Ignored files

```console
$ git status --short
MM README.md
 M app.py
R  notes.md -> docs.md
?? extra/
?? newfile.txt
$ git status --short --ignored
MM README.md
 M app.py
R  notes.md -> docs.md
?? extra/
?? newfile.txt
!! build/
$ git status --short --ignored=matching
MM README.md
 M app.py
R  notes.md -> docs.md
?? extra/
?? newfile.txt
!! build/
```

With `.gitignore` restored, `build/` disappeared from the untracked list, and
`--ignored` brings it back under `!!`. Both modes gave the same answer here,
because the ignore rule names the directory itself. They differ when it does
not. This repository ignores `*.log` and `build/`, and has three new
directories:

```console
$ cat .gitignore
*.log
build/
$ git status --short --ignored=traditional
?? mixed/
!! build/
!! logs/
!! mixed/c.log
!! top.log
$ git status --short --ignored=matching
?? mixed/
!! build/
!! logs/a.log
!! logs/b.log
!! mixed/c.log
!! top.log
$ git status --short --ignored=no
?? mixed/
```

`logs/` holds only `.log` files. No rule names the directory, but everything in
it is ignored, so the traditional mode collapses it to `logs/` while the
matching mode lists the files the pattern actually matched. `mixed/` has an
ignored file and an untracked one, so it appears in both lists.

With `-uall`, the traditional mode opens ignored directories too, while the
matching mode still stops at a directory a rule names:

```console
$ git status --short --ignored=traditional -uall
?? mixed/keep.txt
!! build/out.bin
!! logs/a.log
!! logs/b.log
!! mixed/c.log
!! top.log
$ git status --short --ignored=matching -uall
?? mixed/keep.txt
!! build/
!! logs/a.log
!! logs/b.log
!! mixed/c.log
!! top.log
```

| Option | Lists |
|---|---|
| `--ignored`, `--ignored=traditional` | Ignored files, with a directory collapsed when everything in it is ignored; individual files with `-uall` |
| `--ignored=matching` | Exactly the paths a pattern matched: a directory if a rule names it, otherwise the files inside |
| `--ignored=no` | Nothing ignored. The default |

The long format gives ignored files a heading of their own:

```console
$ git status --ignored
On branch main
Untracked files:
  (use "git add <file>..." to include in what will be committed)
	mixed/

Ignored files:
  (use "git add -f <file>..." to include in what will be committed)
	build/
	logs/
	mixed/c.log
	top.log

nothing added to commit but untracked files present (use "git add" to track)
```

To ask why one specific file is ignored, `git check-ignore -v` is the better
tool, and Chapter 16 uses it throughout.

## Renames

Git records no renames. A rename in status is Git noticing that a file deleted
from the index and a file added to it have similar content (Chapter 13 explains
the similarity score). Here `long.txt` was moved and three of its ten lines
changed:

```console
$ git status --short
R  long.txt -> moved.txt
$ git status --short --no-renames
D  long.txt
A  moved.txt
$ git status --short --find-renames=50
R  long.txt -> moved.txt
$ git status --short -M80
D  long.txt
A  moved.txt
$ git -c status.renames=false status --short
D  long.txt
A  moved.txt
$ git -c status.renames=false status --short --renames
R  long.txt -> moved.txt
```

The file is 70% the same. With the threshold at 50% that is a rename; at 80% it
is not. `-M` is the short form of `--find-renames`. `status.renames` sets the
default, and `--renames` or `--no-renames` overrides it for one command.

Now a copy of `moved.txt`, added as `copy.txt`:

```console
$ cp moved.txt copy.txt && git add copy.txt
$ git status --short
R  long.txt -> copy.txt
A  moved.txt
$ git -c status.renames=copies status --short
C  long.txt -> copy.txt
R  long.txt -> moved.txt
```

Without copy detection, Git paired one of the two identical files with the
deleted `long.txt` and reported the other as a plain addition, so the rename it
showed a moment ago moved to a different file. `status.renames=copies` looks for
copies as well and reports both. There is no command-line option for copies in status.

| Value of `status.renames` | Status reports |
|---|---|
| `false` | a delete and an add |
| `true` | renames |
| `copies`, `copy` | renames and copies |
| not set | whatever `diff.renames` says, which is `true` by default |

## Showing the changes themselves

```console
$ git status -v
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   app.py

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   app.py

diff --git a/app.py b/app.py
index b376c99..eaa7424 100644
--- a/app.py
+++ b/app.py
@@ -1 +1,2 @@
 print('hello')
+print('staged')
$ git status -vv
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   app.py

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   app.py

Changes to be committed:
diff --git c/app.py i/app.py
index b376c99..eaa7424 100644
--- c/app.py
+++ i/app.py
@@ -1 +1,2 @@
 print('hello')
+print('staged')
--------------------------------------------------
Changes not staged for commit:
diff --git i/app.py w/app.py
index eaa7424..7819699 100644
--- i/app.py
+++ w/app.py
@@ -1,2 +1,3 @@
 print('hello')
 print('staged')
+print('not staged')
$ git status -s -v
MM app.py
```

`-v` added the staged change, what `git diff --cached` shows. `-vv` added the
unstaged change too, what `git diff` shows, and labelled both. Its prefixes
became `c/`, `i/` and `w/`, for commit, index and working tree, so you can tell
which side is which ([Chapter 13](#ch13-why-some-diffs-say-i-and-w)). In the
short format `-v` does nothing.

> **Worth knowing.** `git status -v` prints the staged diff underneath the
> status, and `-vv` adds the unstaged one. It is the quickest way to review
> exactly what you are about to commit without running a second command.
> `git commit -v` puts the same staged diff at the bottom of the commit message
> in the editor (Chapter 12).

## The stash

The stash is a place to put changes aside without committing them (Chapter 55).
It is easy to forget what is in it:

```console
$ git status --show-stash
On branch main
Your branch and 'origin/main' have diverged,
and have 2 and 1 different commits each, respectively.
  (use "git pull" if you want to integrate the remote branch with yours)

nothing to commit, working tree clean
Your stash currently has 1 entry
$ git status --porcelain=v2 --show-stash
# stash 1
$ git status -sb --show-stash
## main...origin/main [ahead 2, behind 1]
$ git -c status.showStash=true status
On branch main
Your branch and 'origin/main' have diverged,
and have 2 and 1 different commits each, respectively.
  (use "git pull" if you want to integrate the remote branch with yours)

nothing to commit, working tree clean
Your stash currently has 1 entry
```

The long format and v2 report it; the short format does not. `status.showStash`
turns it on for good.

> **Since Git 2.35.** The `# stash` line in `--porcelain=v2`. The long format
> has reported the stash for much longer.

## Untracked files in columns

```console
$ git status --column
On branch main
Untracked files:
  (use "git add <file>..." to include in what will be committed)
	alpha.txt   delta.txt   eta.txt     iota.txt    lambda.txt  zeta.txt
	beta.txt    epsilon.txt gamma.txt   kappa.txt   theta.txt

nothing added to commit but untracked files present (use "git add" to track)
$ git status --column=row
On branch main
Untracked files:
  (use "git add <file>..." to include in what will be committed)
	alpha.txt   beta.txt    delta.txt   epsilon.txt eta.txt     gamma.txt
	iota.txt    kappa.txt   lambda.txt  theta.txt   zeta.txt

nothing added to commit but untracked files present (use "git add" to track)
$ COLUMNS=40 git status --column
On branch main
Untracked files:
  (use "git add <file>..." to include in what will be committed)
	alpha.txt   eta.txt     lambda.txt
	beta.txt    gamma.txt   theta.txt
	delta.txt   iota.txt    zeta.txt
	epsilon.txt kappa.txt

nothing added to commit but untracked files present (use "git add" to track)
$ git -c column.status=always status --no-column
On branch main
Untracked files:
  (use "git add <file>..." to include in what will be committed)
	alpha.txt
	beta.txt
	delta.txt
	epsilon.txt
	eta.txt
	gamma.txt
	iota.txt
	kappa.txt
	lambda.txt
	theta.txt
	zeta.txt

nothing added to commit but untracked files present (use "git add" to track)
$ git status --short --column
?? alpha.txt
?? beta.txt
?? delta.txt
?? epsilon.txt
?? eta.txt
?? gamma.txt
?? iota.txt
?? kappa.txt
?? lambda.txt
?? theta.txt
?? zeta.txt
```

Only the untracked list in the long format is arranged; the short format ignores
the option. The columns fill downwards by default and across with `row`, and fit
the width of the terminal, which the `COLUMNS` environment variable overrides.
`column.status` sets the default and `--no-column` turns it off again.

The words after `--column=` are the same as for `column.ui`: `always`, `never`
or `auto` for whether to use columns at all; `column`, `row` or `plain` (one
column) for the layout; and `dense` or `nodense` for whether columns may have
different widths. Chapter 62 covers `column.ui`.

## Choosing the format by default

```console
$ git -c status.short=true status
 M README.md
 M src/app.py
 M src/lib/util.py
?? src/new.py
$ git -c status.short=true status --no-short
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   README.md
	modified:   src/app.py
	modified:   src/lib/util.py

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	src/new.py

no changes added to commit (use "git add" and/or "git commit -a")
$ git -c status.short=true status --long
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   README.md
	modified:   src/app.py
	modified:   src/lib/util.py

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	src/new.py

no changes added to commit (use "git add" and/or "git commit -a")
$ git -c status.short=true -c status.branch=true status
## main
 M README.md
 M src/app.py
 M src/lib/util.py
?? src/new.py
$ git -c status.branch=true status --short --no-branch
 M README.md
 M src/app.py
 M src/lib/util.py
?? src/new.py
```

`status.short` and `status.branch` make `-s` and `-b` the default. `--long` and
`--no-short` do the same thing, which is to undo the first; `--no-branch` undoes
the second.

The hint lines in brackets can go, and so can the old style of output:

```console
$ git -c advice.statusHints=false status
On branch main
Changes not staged for commit:
	modified:   README.md
	modified:   src/app.py
	modified:   src/lib/util.py

Untracked files:
	src/new.py

no changes added to commit
$ git -c status.displayCommentPrefix=true status
# On branch main
# Changes not staged for commit:
#   (use "git add <file>..." to update what will be committed)
#   (use "git restore <file>..." to discard changes in working directory)
#	modified:   README.md
#	modified:   src/app.py
#	modified:   src/lib/util.py
#
# Untracked files:
#   (use "git add <file>..." to include in what will be committed)
#	src/new.py
#
no changes added to commit (use "git add" and/or "git commit -a")
```

`advice.statusHints=false` removes the hints here, and Git's documentation says
it also removes them from the commit message template and from what
`git switch` prints. `status.displayCommentPrefix` puts `#` in front of each
line, which was how every Git printed status up to 1.8.4 and is why old
tutorials show it that way.

## Output for scripts

Never parse the human-readable output. It changes between versions and with
the user's language settings. There are two stable formats.

### Porcelain version 1

```console
$ git status --porcelain
 D .gitignore
MM README.md
 M app.py
R  notes.md -> docs.md
?? build/
?? newfile.txt
$ git status --porcelain=v1
 D .gitignore
MM README.md
 M app.py
R  notes.md -> docs.md
?? build/
?? newfile.txt
```

`--porcelain` with no version means v1, which is the short format with a
promise not to change.

It looks identical to `--short`, and in a plain terminal at the top of the
repository it is. The promise is what differs: Git's documentation says v1 does
not change between versions and ignores two settings that change `--short`,
`color.status` and `status.relativePaths`. So from a subdirectory:

```console
$ git status --porcelain
 M README.md
 M src/app.py
 M src/lib/util.py
?? src/new.py
```

Paths from the top, where `--short` gave `../README.md` in
[Limiting status to some paths](#limiting-status-to-some-paths). Also unlike
`--short`, v1 never adds the branch header unless `-b` is given, even with
`status.branch` set.

"Porcelain" is Git's word for commands meant for people, as opposed to the
"plumbing" meant for scripts (Chapter 75). The option's name sounds backwards,
because the output is for programs. It is named after its intended readers:
porcelain, in the sense of tools and scripts built on top of Git.

### Porcelain version 2

For anything beyond "is the tree dirty", use v2:

```console
$ git status --porcelain=v2 --branch
# branch.oid 372e727cc16950c590b25de0ead3d4bc06073600
# branch.head main
# branch.upstream origin/main
# branch.ab +0 -0
1 .D N... 100644 100644 000000 567609b1234a9b8806c5a05da6c866e480aa148d 567609b1234a9b8806c5a05da6c866e480aa148d .gitignore
1 MM N... 100644 100644 100644 dab306f45e6a154ab0fe50d67298f165cfc75392 a522b1689de79343672e7ae0396c58a969c4e752 README.md
1 .M N... 100644 100644 100644 b376c9941fda362c8d2c5c8ddb35db3e0b003402 b376c9941fda362c8d2c5c8ddb35db3e0b003402 app.py
2 R. N... 100644 100644 100644 bfa655111293037a5564088d1a9bbca4cbcf446b bfa655111293037a5564088d1a9bbca4cbcf446b R100 docs.md	notes.md
? build/
? newfile.txt
```

| Line starts with | Is |
|---|---|
| `#` | A header: the commit, the branch, the upstream, the ahead/behind counts |
| `1` | An ordinary changed entry |
| `2` | A renamed or copied entry, with the old path after a tab |
| `u` | An unmerged entry, with all three stage hashes |
| `?` | Untracked |
| `!` | Ignored |

On a `1` line the fields are the two status letters, the submodule state, then
three file modes for HEAD, index and working tree, then the HEAD and index
blob hashes, then the path. `R100` on the `2` line is the rename similarity
score, where 100 means the content is identical.

The status letters are the short format's, with `.` where the short format has a
space, so a script never has to count spaces. `N...` means "not a submodule".
There is no hash for the working tree version, which Git has not stored as an
object; the mode `000000` means the file does not exist there, as for the
deleted `.gitignore`.

> **Worth knowing.** `# branch.ab +0 -0` is the ahead and behind counts as
> numbers, which is far easier to act on than parsing the English sentence.
> This is the single best reason to reach for v2 in a shell prompt.

Before the first commit there is no commit to name, and in a repository with no
upstream there is nothing to count:

```console
$ git status -sb
## No commits yet on main
?? a.txt
$ git status --porcelain=v2 --branch
# branch.oid (initial)
# branch.head main
? a.txt
```

Every header line, and when it appears:

| Header | Appears |
|---|---|
| `# branch.oid <hash>` | with `--branch`; `(initial)` before the first commit |
| `# branch.head <name>` | with `--branch`; `(detached)` when detached, including during a rebase |
| `# branch.upstream <name>` | with `--branch`, when there is an upstream |
| `# branch.ab +<ahead> -<behind>` | when the upstream exists; `+? -?` with `--no-ahead-behind` |
| `# stash <n>` | with `--show-stash`, when there is at least one entry |

Git's documentation says entries come in no defined order and that a parser
should ignore header lines it does not recognise, so new headers can be added
without breaking it.

### Separating entries with NUL

A file name can contain a space, a quote, or even a newline, and quoting only
helps a script that undoes it. `-z` ends every entry with a NUL byte, which no
file name can contain, and prints names exactly as they are. `tr` shows the NUL
bytes as `@` here:

```console
$ git status -z | tr '\0' '@'; echo
R  new name.txt@old name.txt@?? café.txt@
$ git status --porcelain=v2 -z | tr '\0' '@'; echo
2 R. N... 100644 100644 100644 13e7564ea0c889e81bcba6f8e496b2a74cdb32fa 13e7564ea0c889e81bcba6f8e496b2a74cdb32fa R100 new name.txt@old name.txt@? café.txt@
```

`-z` alone means v1. No quotes and no octal escapes. The rename is written
differently from v1 without `-z`: there is no `->`, and the new name comes
first, then the old one. The `echo` only adds a final newline so the next prompt
starts on its own line.

### Is the tree dirty?

`git status` itself exits with 0 whether or not anything changed, so its exit
code cannot answer the question:

```console
$ git status --short; echo "exit $?"
 M README.md
 M src/app.py
 M src/lib/util.py
?? src/new.py
exit 0
$ test -z "$(git status --porcelain)" && echo clean || echo dirty
dirty
```

Empty porcelain output means clean, counting untracked files. For narrower
questions, other commands answer with their exit code:

```console
$ git commit --dry-run --short; echo "exit $?"
 M README.md
 M src/app.py
 M src/lib/util.py
?? src/new.py
exit 1
$ git add README.md
$ git commit --dry-run --short; echo "exit $?"
M  README.md
 M src/app.py
 M src/lib/util.py
?? src/new.py
exit 0
$ git commit --dry-run -a --short; echo "exit $?"
M  README.md
M  src/app.py
M  src/lib/util.py
?? src/new.py
exit 0
$ git diff --quiet; echo "exit $?"
exit 1
$ git diff --cached --quiet; echo "exit $?"
exit 1
```

| Question | Command | Clean means |
|---|---|---|
| Anything at all, untracked files included | `test -z "$(git status --porcelain)"` | empty output |
| Would a commit have anything in it | `git commit --dry-run` | exit 1 |
| Changes in tracked files not yet staged | `git diff --quiet` | exit 0 |
| Changes staged | `git diff --cached --quiet` | exit 0 |

`git diff` never sees untracked files
([Chapter 13](#ch13-new-files-do-not-appear)), which is the usual reason a
script built on it misses a new file.

## During a conflict

`git status` is the command to run when a merge stops. It tells you the state,
the files, and the way out:

```console
$ git merge other
Auto-merging app.py
CONFLICT (content): Merge conflict in app.py
Automatic merge failed; fix conflicts and then commit the result.
$ git status
On branch main
Your branch is ahead of 'origin/main' by 1 commit.
  (use "git push" to publish your local commits)

You have unmerged paths.
  (fix conflicts and run "git commit")
  (use "git merge --abort" to abort the merge)

Unmerged paths:
  (use "git add <file>..." to mark resolution)
	both modified:   app.py

no changes added to commit (use "git add" and/or "git commit -a")
$ git status --short
UU app.py
$ git status -sb
## main...origin/main [ahead 1]
UU app.py
```

`UU` means both sides modified the file. The index holds three versions of it
at once, which is what Chapter 5 called stages:

```console
$ git ls-files --stage app.py
100644 b376c9941fda362c8d2c5c8ddb35db3e0b003402 1	app.py
100644 8abcb7de8b060338410ba883d7d053a65c7b1d1a 2	app.py
100644 b95313905cb47424e84d03239c00de37d5650c6e 3	app.py
```

| Stage | Is |
|---|---|
| 1 | The common ancestor |
| 2 | Your side, `HEAD` |
| 3 | Their side, the branch being merged |

Chapter 26 is the full conflict chapter and uses those three stages directly.

```console
$ git merge --abort
$ git status --short
```

`git merge --abort` put everything back as it was before the merge, and the
empty short output confirms it.

### Every conflict code

This merge was set up so that each kind of conflict happens once: both sides
changed a file, both added a file with the same name, each side deleted a file
the other changed, and both renamed the same file to different names.

```console
$ git merge theirs
Auto-merging both-add.txt
CONFLICT (add/add): Merge conflict in both-add.txt
Auto-merging both-mod.txt
CONFLICT (content): Merge conflict in both-mod.txt
CONFLICT (modify/delete): del-them.txt deleted in theirs and modified in HEAD.  Version HEAD of del-them.txt left in tree.
CONFLICT (modify/delete): del-us.txt deleted in HEAD and modified in theirs.  Version theirs of del-us.txt left in tree.
CONFLICT (rename/rename): ren.txt renamed to ren-ours.txt in HEAD and to ren-theirs.txt in theirs.
Automatic merge failed; fix conflicts and then commit the result.
$ git status --short
AA both-add.txt
UU both-mod.txt
UD del-them.txt
DU del-us.txt
AU ren-ours.txt
UA ren-theirs.txt
DD ren.txt
$ git status
On branch main
You have unmerged paths.
  (fix conflicts and run "git commit")
  (use "git merge --abort" to abort the merge)

Unmerged paths:
  (use "git add/rm <file>..." as appropriate to mark resolution)
	both added:      both-add.txt
	both modified:   both-mod.txt
	deleted by them: del-them.txt
	deleted by us:   del-us.txt
	added by us:     ren-ours.txt
	added by them:   ren-theirs.txt
	both deleted:    ren.txt

no changes added to commit (use "git add" and/or "git commit -a")
```

The other two-letter conflict codes:

| Code | Git's wording | Happened here because |
|---|---|---|
| `UU` | unmerged, both modified | both sides changed `both-mod.txt` |
| `AA` | unmerged, both added | both sides created `both-add.txt` |
| `DD` | unmerged, both deleted | both sides renamed `ren.txt` away, to different names |
| `AU` | unmerged, added by us | our side's new name for `ren.txt` |
| `UA` | unmerged, added by them | their side's new name for `ren.txt` |
| `DU` | unmerged, deleted by us | we deleted `del-us.txt`, they changed it |
| `UD` | unmerged, deleted by them | they deleted `del-them.txt`, we changed it |

"Us" is the branch you are on, "them" is the branch being merged in. The two
letters are not a state and a state here; during a conflict they describe what
each side did, which is why `AU` and `UA` are different situations rather than
a typo of each other.

In v2 every one of them is a `u` line with three stage hashes, and a missing
stage has the mode `000000` and a hash of zeros:

```console
$ git status --porcelain=v2
u AA N... 000000 100644 100644 100644 0000000000000000000000000000000000000000 b19a1e93bec1317dc6097229e12afaffbfa74dc2 950b81b7eee953d050aa05a641f8e056c85dd1bd both-add.txt
u UU N... 100644 100644 100644 100644 df967b96a579e45a18b8251732d16804b2e56a55 b19a1e93bec1317dc6097229e12afaffbfa74dc2 950b81b7eee953d050aa05a641f8e056c85dd1bd both-mod.txt
u UD N... 100644 100644 000000 100644 df967b96a579e45a18b8251732d16804b2e56a55 fed33f86f3ba402e91748bc6ca06d29df7ed1a3f 0000000000000000000000000000000000000000 del-them.txt
u DU N... 100644 000000 100644 100644 df967b96a579e45a18b8251732d16804b2e56a55 0000000000000000000000000000000000000000 223181711c344a738d5e1e1e092a167527deb0d8 del-us.txt
u AU N... 000000 100644 000000 100644 0000000000000000000000000000000000000000 f31d33f2c77a766437de6ed5d0473adfae3d6c9e 0000000000000000000000000000000000000000 ren-ours.txt
u UA N... 000000 000000 100644 100644 0000000000000000000000000000000000000000 0000000000000000000000000000000000000000 f31d33f2c77a766437de6ed5d0473adfae3d6c9e ren-theirs.txt
u DD N... 100644 000000 000000 000000 f31d33f2c77a766437de6ed5d0473adfae3d6c9e 0000000000000000000000000000000000000000 0000000000000000000000000000000000000000 ren.txt
```

The fields are the two letters, the submodule state, the modes of stages 1, 2
and 3 and of the working tree, the hashes of stages 1, 2 and 3, and the path.
`AA` has no stage 1 because there was no common ancestor; `DD` has only stage 1,
because neither side kept the name.

> **Worth knowing.** Submodules report three extra letters that mean something
> else entirely: `M` for a different HEAD than the index records, `m` for
> modified content inside, and `?` for untracked files inside. They exist
> because you cannot `git add` those from the outer repository. Chapter 57
> covers submodules.

## During a rebase

```console
$ git rebase other
Rebasing (1/1)
Auto-merging app.py
CONFLICT (content): Merge conflict in app.py
error: could not apply 7c7cb78... Work in progress
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
Could not apply 7c7cb78... # Work in progress
$ git status
interactive rebase in progress; onto 206b78a
Last command done (1 command done):
   pick 7c7cb78 # Work in progress
No commands remaining.
You are currently rebasing branch 'main' on '206b78a'.
  (fix conflicts and then run "git rebase --continue")
  (use "git rebase --skip" to skip this patch)
  (use "git rebase --abort" to check out the original branch)

Changes to be committed:
...
Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
	both modified:   app.py

```

`Rebasing (1/1)` is a progress line. Git ends it with a carriage return rather
than a newline, so on a terminal the next line is written over it and you may
never see it.

It says "interactive rebase" even though this was a plain `git rebase`, because
modern Git implements both with the same machinery. That wording is not a sign
you did something unusual.

> **Since Git 2.50.** The `#` before the commit title on the `pick` line is
> new. Release notes for 2.50 record that titles in the rebase todo are now
> prefixed with `#`, matching how a replayed merge commit was already shown.
> Git's own `git-rebase` documentation still shows the old format without it,
> so the manual and the program disagree here. On an older Git that line reads
> `pick 7c7cb78 Work in progress`.

This is the single most useful thing `git status` does. When a command stops
part-way and you do not know what state you are in, `git status` names the
operation and prints the three ways out. Chapter 80 is about being stuck in the
middle of things, and every recipe in it starts here.

```console
$ git rebase --abort
$ git status -sb
## main...origin/main [ahead 1]
```

## Other operations in progress

The same repository, `main` with two commits after the one `side` started from,
stopped in turn by each command that can stop:

```console
$ git cherry-pick side
Auto-merging app.py
CONFLICT (content): Merge conflict in app.py
error: could not apply eea861e... Side change
hint: After resolving the conflicts, mark them with
hint: "git add/rm <pathspec>", then run
hint: "git cherry-pick --continue".
hint: You can instead skip this commit with "git cherry-pick --skip".
hint: To abort and get back to the state before "git cherry-pick",
hint: run "git cherry-pick --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
$ git status
On branch main
You are currently cherry-picking commit eea861e.
  (fix conflicts and run "git cherry-pick --continue")
  (use "git cherry-pick --skip" to skip this patch)
  (use "git cherry-pick --abort" to cancel the cherry-pick operation)

Unmerged paths:
  (use "git add <file>..." to mark resolution)
	both modified:   app.py

no changes added to commit (use "git add" and/or "git commit -a")
$ git cherry-pick --abort
$ git revert --no-edit HEAD~1
Auto-merging app.py
CONFLICT (content): Merge conflict in app.py
error: could not revert ac885e3... Change to two
hint: After resolving the conflicts, mark them with
hint: "git add/rm <pathspec>", then run
hint: "git revert --continue".
hint: You can instead skip this commit with "git revert --skip".
hint: To abort and get back to the state before "git revert",
hint: run "git revert --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
$ git status
On branch main
You are currently reverting commit ac885e3.
  (fix conflicts and run "git revert --continue")
  (use "git revert --skip" to skip this patch)
  (use "git revert --abort" to cancel the revert operation)

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
	both modified:   app.py

no changes added to commit (use "git add" and/or "git commit -a")
$ git revert --abort
```

A merge whose conflicts are all resolved is still a merge in progress until you
commit:

```console
$ git merge side
Auto-merging app.py
CONFLICT (content): Merge conflict in app.py
Automatic merge failed; fix conflicts and then commit the result.
$ git add app.py
$ git status
On branch main
All conflicts fixed but you are still merging.
  (use "git commit" to conclude merge)

Changes to be committed:
	modified:   app.py

$ git merge --abort
```

Some operations stop without any conflict. A bisect, the search for the commit
that introduced a bug (Chapter 20), leaves you in the middle until you reset it:

```console
$ git bisect start
status: waiting for both 'good' and 'bad' commits
$ git status
On branch main
You are currently bisecting, started from branch 'main'.
  (use "git bisect reset" to get back to the original branch)

nothing to commit, working tree clean
$ git bisect reset
Already on 'main'
```

During a rebase, `branch.head` in v2 is `(detached)`, because a rebase works on
a detached HEAD and moves the branch only when it finishes:

```console
$ git rebase side
Rebasing (1/2)
Auto-merging app.py
CONFLICT (content): Merge conflict in app.py
error: could not apply ac885e3... Change to two
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
Could not apply ac885e3... # Change to two
$ git status --porcelain=v2 --branch
# branch.oid eea861e9b4f776f6bd1ddca243211b5139ec1fc1
# branch.head (detached)
u UU N... 100644 100644 100644 100644 5626abf0f72e58d7a153368ba57db4c673c0e171 2299c37978265a95cbe835a4b0f0bbf15aad5549 f719efd430d52bcfc8566a43b2eb655688d38871 app.py
$ git rebase --abort
```

A sparse checkout, where only some of the repository's files are written to the
working tree (Chapter 60), is a lasting state rather than an operation, and
status mentions it every time:

```console
$ git sparse-checkout set a
$ git status
On branch main
You are in a sparse checkout with 67% of tracked files present.

nothing to commit, working tree clean
```

| Status says | You are in | Ways out | Chapter |
|---|---|---|---|
| You have unmerged paths / All conflicts fixed but you are still merging | a merge | `git commit`, `git merge --abort` | 25, 26 |
| interactive rebase in progress | a rebase | `git rebase --continue`, `--skip`, `--abort` | 33 |
| You are currently cherry-picking commit | a cherry-pick | `git cherry-pick --continue`, `--skip`, `--abort` | 32 |
| You are currently reverting commit | a revert | `git revert --continue`, `--skip`, `--abort` | 31 |
| You are currently bisecting | a bisect | `git bisect reset` | 20 |
| You are in a sparse checkout | a sparse checkout | `git sparse-checkout disable` | 60 |

> **Since Git 2.28.** The sparse checkout line.

## Colour

On a terminal, status is coloured unless colour has been turned off. This is the
same repository state in both formats: one staged file, one unstaged, one
untracked, and a commit not yet pushed.

```ansi
$ git status -sb
## \e[32mmain\e[m...\e[31morigin/main\e[m [ahead \e[32m1\e[m]
 \e[31mM\e[m README.md
\e[32mM\e[m  app.py
\e[31m??\e[m todo.txt
$ git status
On branch main
Your branch is ahead of 'origin/main' by 1 commit.
  (use "git push" to publish your local commits)

Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	\e[32mmodified:   app.py\e[m

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	\e[31mmodified:   README.md\e[m

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	\e[31mtodo.txt\e[m

```

Green is what the next commit would contain; red is what it would not. In the
short format that is the letter's colour, so `MM` has a green `M` and a red one.

`color.status` turns colour on or off for status alone, and
`color.status.<slot>` changes one colour. Chapter 62 covers the colour names.

| Slot in `color.status.<slot>` | Colours |
|---|---|
| `header` | The heading text |
| `added`, `updated` | Staged files |
| `changed` | Changed files not staged |
| `untracked` | Untracked files |
| `unmerged` | Files with conflicts |
| `branch` | The current branch |
| `nobranch` | The warning when you are on no branch; red by default |
| `localBranch` | The local branch in the short format's header |
| `remoteBranch` | The upstream branch in the short format's header |

`--porcelain` output is never coloured, whatever the settings say.

## Large repositories

Status has to look at every file in the working tree to find changes and
untracked files. In a repository with hundreds of thousands of files, that takes
time. Git's documentation lists what helps, from the most effective downwards:

| Setting or option | Effect |
|---|---|
| `-uno`, or `status.showUntrackedFiles=no` | Fastest: untracked files are not searched for at all, or shown |
| `core.untrackedCache=true` | Remembers untracked files per directory, and searches only directories that changed |
| `core.fsmonitor=true`, with the untracked cache | A background process tells Git which files changed, so almost nothing is searched |
| `advice.statusUoption=false` | Only removes the hint status prints when the search takes more than 2 seconds |
| `--no-ahead-behind`, or `status.aheadBehind=false` | Skips counting commits against the upstream |

The documentation also notes that after turning a cache on, status may need a
few runs before it is faster. Chapter 69 covers these settings in depth.

Status also saves a little work for the next command by writing refreshed file
information back into the index. A tool that runs `git status` in the
background, such as an editor or a shell prompt, can therefore hold the index
lock at the moment you run a command that needs it, and your command fails.
Git's documentation recommends that such tools run
`git --no-optional-locks status`, which skips the write (Chapter 62).

## status and its neighbours

Several commands answer part of what status answers. In the tree from
[Everything at once](#everything-at-once):

```console
$ git diff --cached --name-status
M	README.md
R100	notes.md	docs.md
$ git diff --name-status
D	.gitignore
M	README.md
M	app.py
$ git ls-files --others --exclude-standard
build/another.log
build/out.log
newfile.txt
```

`git diff --cached --name-status` is the left column of the short format, and
`git diff --name-status` the right one, each as a list of its own with a tab
after the letter. Neither lists untracked files. `git ls-files --others
--exclude-standard` lists exactly the untracked files, one per file rather than
collapsing directories.

| Command | Shows | Use it when |
|---|---|---|
| `git status` | Staged, unstaged and untracked, the branch, any operation in progress | you want to know where you are |
| `git status --porcelain=v2` | The same, in a stable format | a script needs it |
| `git diff --cached --name-status` | Staged changes only | you want the list of what a commit would contain |
| `git diff --name-status` | Unstaged changes in tracked files only | you want the list of what you have not staged |
| `git diff`, `git diff --cached` | The changes themselves (Chapter 13) | you want to read the changes |
| `git ls-files --others --exclude-standard` | Untracked files, each one | a script needs every new file |
| `git commit --dry-run` | Status as it would appear in the commit, with an exit code | you want to know whether a commit would succeed (Chapter 12) |
| `git log origin/main..HEAD` | Which commits are ahead (Chapter 17) | status said "ahead" and you want to see them |
| `git branch -vv` | Ahead and behind for every branch (Chapter 23) | you want it for all branches, not only the current one |
| `git stash list` | Every stash entry (Chapter 55) | status said you have one |

`git commit --dry-run` prints what status prints, as it did in
[Is the tree dirty?](#is-the-tree-dirty). The differences are its exit code, and
that it accepts the commit's own options: `git commit --dry-run -a` showed the
modified files as staged, because `-a` would stage them for that commit.

## The settings

| Setting | Effect |
|---|---|
| `status.short` | Default to the short format |
| `status.branch` | Always show the branch header |
| `status.showUntrackedFiles` | Default for `-u`: `no`, `normal` or `all` |
| `status.showStash` | Always report stash entries |
| `status.aheadBehind` | Default for computing ahead and behind, in the human formats only |
| `status.compareBranches` | Which branches to compare against, from `@{upstream}` and `@{push}`. Defaults to `@{upstream}`. Since Git 2.54 |
| `status.renames` | `false`, `true`, or `copies` to detect copies too |
| `status.renameLimit` | How many files to consider when detecting renames |
| `status.relativePaths` | Show paths relative to the current directory |
| `status.submoduleSummary` | Summarise changed submodules (Chapter 57) |
| `status.displayCommentPrefix` | Prefix long-format lines with `#`, as very old Git did |
| `color.status` | Colour in status: `always`, `auto` or `never`; follows `color.ui` if unset |
| `color.status.<slot>` | The colour of one part of the output, from the table in [Colour](#colour) |
| `column.status` | Arrange untracked files in columns |
| `core.quotePath` | `false` shows characters outside ASCII in paths as they are |
| `advice.statusHints` | `false` removes the hint lines in brackets |
| `advice.statusAheadBehind` | `false` removes the hint shown when counting ahead and behind is slow |
| `advice.statusUoption` | `false` removes the hint shown when searching for untracked files is slow |
| `core.untrackedCache` | Cache untracked files between runs (Chapter 69) |
| `core.fsmonitor` | Use a file system monitor to find changes (Chapter 69) |

Both `status.renames` and `status.renameLimit` apply to `git commit` as well,
because it shows status in the commit message template; `status.showUntrackedFiles`
does too.
