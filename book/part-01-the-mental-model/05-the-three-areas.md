# Chapter 5. The Three Areas

## The map

Git keeps three copies of your project at once, and nearly every everyday
command is a way of moving content between them.

```
   working tree            index               repository
  (what you edit)     (what you staged)    (what you committed)
        │                    │                     │
        │──── git add ──────▶│                     │
        │                    │──── git commit ────▶│
        │                    │                     │
        │◀── git restore ────│◀─ git restore ──────│
        │                       --staged           │
        │◀────────── git checkout / git switch ────│
```

| Area | Also called | Lives in | Holds |
|---|---|---|---|
| Working tree | working directory, worktree | Your project folder | The files you actually edit |
| Index | staging area, cache | `.git/index` | What the next commit will contain |
| Repository | object database, history | `.git/objects` | Every commit ever made |

The index is the one that has no equivalent in most other version control
systems, and it is the source of most early confusion. The rest of this chapter
is mostly about it.

## Walking a file through

A brand new file exists in the working tree and nowhere else:

```console
$ git status
On branch main

No commits yet

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	recipe.txt

nothing added to commit but untracked files present (use "git add" to track)
$ git status --short
?? recipe.txt
```

`git add` copies it into the index:

```console
$ git add recipe.txt
$ git status --short
A  recipe.txt
$ git ls-files --stage
100644 400b4ab3d84db71d4249998c7f8fc39899b368fe 0	recipe.txt
```

`git commit` turns the index into a tree and records it:

```console
$ git status --short
$ git status
On branch main
nothing to commit, working tree clean
$ git cat-file -p HEAD^{tree}
100644 blob 400b4ab3d84db71d4249998c7f8fc39899b368fe	recipe.txt
```

Notice the blob hash is the same in the index listing and in the committed
tree. `git add` created the object. `git commit` only wrote down which objects
belong together.

> **Worth knowing.** That is why `git add` on a huge file is the slow step and
> `git commit` is instant. The bytes were already written to the object
> database when you staged.

## Reading the short status

`git status --short` prints two columns, and this is the single most useful
thing to memorise in this chapter:

```
 X Y  path
 │ │
 │ └── working tree, compared against the index
 └──── index, compared against HEAD
```

The left column is what you have staged. The right column is what you have not.

| Letter | Meaning |
|---|---|
| (space) | unmodified |
| `M` | modified |
| `T` | file type changed, for instance a file became a symlink |
| `A` | added |
| `D` | deleted |
| `R` | renamed |
| `C` | copied, only when `status.renames` is set to `copies` |
| `U` | updated but unmerged, meaning a conflict (Chapter 26) |

Two codes do not follow the two-column rule, because an untracked file has no
index entry to compare against:

| Code | Meaning |
|---|---|
| `??` | untracked |
| `!!` | ignored, shown only with `--ignored` |

Reading real examples is faster than reading the table:

| Code | Situation |
|---|---|
| `?? notes.txt` | A new file Git has never seen |
| `A  recipe.txt` | Newly added, staged, working tree matches |
| ` M recipe.txt` | Edited, not staged |
| `M  recipe.txt` | Edited and staged, nothing since |
| `MM recipe.txt` | Edited, staged, then edited again |
| `D  old.txt` | Deletion staged |
| ` D old.txt` | Deleted from disk, deletion not staged |
| `R  a.txt -> b.txt` | Rename staged |
| `UU merged.txt` | Conflicted, both sides changed it |

> **Careful.** The space in the left column is significant, so ` M` and `M `
> mean opposite things. In a terminal they are nearly identical. When you are
> unsure, run plain `git status`, which spells it out in words under the
> headings "Changes to be committed" and "Changes not staged for commit".

## Two disagreements, two diffs

Edit the file. Now the working tree and the index disagree:

```console
$ git status --short
 M recipe.txt
$ git diff
diff --git a/recipe.txt b/recipe.txt
index 400b4ab..bd54be9 100644
--- a/recipe.txt
+++ b/recipe.txt
@@ -1,2 +1,3 @@
 flour
 water
+salt
$ git diff --staged
```

`git diff` showed the change. `git diff --staged` showed nothing. Stage the
file and the two swap places exactly:

```console
$ git add recipe.txt
$ git status --short
M  recipe.txt
$ git diff
$ git diff --staged
diff --git a/recipe.txt b/recipe.txt
index 400b4ab..bd54be9 100644
--- a/recipe.txt
+++ b/recipe.txt
@@ -1,2 +1,3 @@
 flour
 water
+salt
```

This is the thing people get wrong for years: **`git diff` with no arguments
does not show you what you are about to commit.** It shows you what you are
about to *miss*.

| Command | Compares | Answers |
|---|---|---|
| `git diff` | working tree against index | What have I not staged yet? |
| `git diff --staged` | index against HEAD | What would `git commit` record? |
| `git diff HEAD` | working tree against HEAD | What would `git commit -a` record? |

Those last two descriptions are Git's own, from the documentation, and they are
a better way to remember the pair than "staged versus unstaged".

`--cached` is an older spelling of `--staged` and the documentation calls them
synonyms. Both work, and you will meet `--cached` in older scripts and answers.

## One file, two states at once

Because there are three areas, a single file can be in two different states
simultaneously. Stage a change, then edit the file again:

```console
$ git status --short
MM recipe.txt
$ git status
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   recipe.txt

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   recipe.txt
```

The same filename appears under both headings. That is not a bug and not a
display glitch. There genuinely are three versions of `recipe.txt` in play, and
all three diffs now show something different:

```console
$ git diff
diff --git a/recipe.txt b/recipe.txt
index bd54be9..296df62 100644
--- a/recipe.txt
+++ b/recipe.txt
@@ -1,3 +1,4 @@
 flour
 water
 salt
+yeast
$ git diff --staged
diff --git a/recipe.txt b/recipe.txt
index 400b4ab..bd54be9 100644
--- a/recipe.txt
+++ b/recipe.txt
@@ -1,2 +1,3 @@
 flour
 water
+salt
$ git diff HEAD
diff --git a/recipe.txt b/recipe.txt
index 400b4ab..296df62 100644
--- a/recipe.txt
+++ b/recipe.txt
@@ -1,2 +1,4 @@
 flour
 water
+salt
+yeast
```

Three commands, three answers, all correct. `salt` is staged, `yeast` is not,
and together they are the full change since the last commit.

## What actually gets committed

Now commit, and watch which version is recorded:

```console
$ git commit -m 'Add salt'
[main ef6ad05] Add salt
 1 file changed, 1 insertion(+)
$ git show --stat --oneline HEAD
ef6ad05 Add salt
 recipe.txt | 1 +
 1 file changed, 1 insertion(+)
$ git cat-file -p HEAD:recipe.txt
flour
water
salt
$ cat recipe.txt
flour
water
salt
yeast
```

The commit contains three lines. The file on disk has four. `git commit` never
looks at your working tree; it turns the index into a tree and records that.

```console
$ git status --short
 M recipe.txt
$ git diff --staged
$ git diff HEAD
diff --git a/recipe.txt b/recipe.txt
index bd54be9..296df62 100644
--- a/recipe.txt
+++ b/recipe.txt
@@ -1,3 +1,4 @@
 flour
 water
 salt
+yeast
```

Afterwards the index and HEAD agree, and the `yeast` line is still sitting in
the working tree waiting to be staged.

> **Careful.** This is how people accidentally commit half a change. You edit
> five files, stage three, keep working, then commit. The commit has three
> files in it and your tests still pass locally because your working tree has
> all five. Reviewing `git diff --staged` before every commit costs two seconds
> and prevents this entirely.

## The index holds hashes, not contents

The index is a real file at `.git/index`, and what it stores for each path is a
mode, a blob hash, and a stage number:

```console
$ git ls-files --stage
100644 bd54be9d262258435499ffd5642be3f041a8d4ee 0	recipe.txt
```

The trailing `0` is the stage. It is always zero except during an unresolved
merge, when the same path appears three times at stages 1, 2 and 3 for the
common ancestor, our side, and their side. Chapter 26 uses that directly.

The blob already exists in the object database, so you can address the index
version of a file with a colon:

```console
$ git rev-parse :recipe.txt HEAD:recipe.txt
bd54be9d262258435499ffd5642be3f041a8d4ee
bd54be9d262258435499ffd5642be3f041a8d4ee
```

| Syntax | Means |
|---|---|
| `:path` | The version in the index |
| `HEAD:path` | The version in the last commit |
| `:0:path` | The index, stage 0, explicitly |
| `:1:path` | Common ancestor during a conflict |
| `:2:path` | Our side during a conflict |
| `:3:path` | Their side during a conflict |

The index also caches the size and modification time of each file, which is how
`git status` can be fast in a large repository without reading every file.
Chapter 73 takes the file apart byte by byte.

## Skipping the index with commit -a

`git commit -a` stages every tracked file that changed, then commits, in one
step:

```console
$ git status --short
 M recipe.txt
?? notes.txt
$ git status --short
?? notes.txt
$ git show --stat --oneline HEAD
59c1851 Add yeast and sugar
 recipe.txt | 2 ++
 1 file changed, 2 insertions(+)
```

`recipe.txt` was committed. `notes.txt` is still untracked and was not.

> **Careful.** `-a` means "all tracked files", not "all files". It will never
> add something Git has not seen before, which is usually what saves you and
> occasionally what confuses you. There is no flag that means "commit
> everything including untracked files"; `git add -A` followed by
> `git commit` is the way to do that.

| Command | Stages tracked changes | Stages new files | Stages deletions |
|---|---|---|---|
| `git commit -a` | yes | no | yes |
| `git add -A` | yes | yes | yes |
| `git add .` | yes | yes | yes |
| `git add -u` | yes | no | yes |

`git add .` and `git add -A` differ only when you are standing in a
subdirectory. Chapter 11 covers that difference, which has bitten a lot of
people.

## Moving backwards

Every arrow in the map at the top of this chapter runs both ways:

```console
$ git add recipe.txt
$ git status --short
M  recipe.txt
?? notes.txt
$ git restore --staged recipe.txt
$ git status --short
 M recipe.txt
?? notes.txt
$ git restore recipe.txt
$ git status --short
?? notes.txt
```

Two commands, two very different risk levels:

| Command | Copies | Loses work? |
|---|---|---|
| `git restore --staged <file>` | HEAD into the index | No. Your edits stay in the working tree |
| `git restore <file>` | Index into the working tree | **Yes.** Unstaged edits are gone with no undo |

> **Careful.** `git restore <file>` is one of the few Git commands that can
> destroy work permanently. The content it overwrites was never committed and
> was never an object, so there is nothing to recover it from. Chapter 78 is
> the recovery chapter and its honest answer for this case is "you cannot".
> Stage early; a staged change can always be recovered (Chapter 79).

## The areas people forget

Three is the useful simplification. Two more places hold content:

| Area | What it is | Chapter |
|---|---|---|
| The stash | A stack of saved working tree and index states | 55 |
| Remote-tracking refs | Your last known copy of a remote's branches | 41 |

Remote-tracking refs matter sooner than you would expect. When `git status`
says you are "ahead of origin/main by 2 commits", it is comparing against a
local copy of where `origin/main` was the last time you talked to the server,
not against the server. Nothing in that message involves a network connection.

## Why the index exists at all

It would be simpler without it. `git commit` could just take the working tree.
Some version control systems do exactly that.

The index earns its place by letting a commit be a deliberate selection rather
than a snapshot of whatever state you happened to be in. That enables:

| Capability | Chapter |
|---|---|
| Committing part of a file with `git add -p` | 11 |
| Splitting one messy change into several clean commits | 34 |
| Reviewing precisely what you are about to record | this one |
| Resolving a merge conflict path by path | 26 |

The cost is that you have to learn it. The benefit is that your history can be
a sequence of coherent changes instead of a log of when you happened to save.
