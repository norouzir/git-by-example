# Chapter 10. status

`git status` is the command you will run more than all the others put together.
It answers three questions at once: where am I, what have I changed, and what
is Git in the middle of doing.

## A clean tree

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

## Everything at once

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

## The short format in full

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

## The branch header

```console
$ git status -sb
## main...origin/main
 D .gitignore
MM README.md
...
```

`-sb` is `--short --branch`. The header line follows a fixed grammar:

| Header | Means |
|---|---|
| `## main...origin/main` | On `main`, tracking `origin/main`, in step |
| `## main...origin/main [ahead 1]` | One local commit not pushed |
| `## main...origin/main [behind 3]` | Three commits fetched but not merged |
| `## main...origin/main [ahead 2, behind 3]` | Diverged. Chapter 45 |
| `## main` | On `main`, tracking nothing |
| `## HEAD (no branch)` | Detached |
| `## No commits yet on main` | Fresh repository |

## Output for scripts

Never parse the human-readable output. It changes between versions and with
the user's language settings. There are two stable formats:

```console
$ git status --porcelain
 D .gitignore
MM README.md
 M app.py
R  notes.md -> docs.md
?? build/
?? newfile.txt
```

`--porcelain` with no version means v1, which is the short format with a
promise not to change. For anything beyond "is the tree dirty", use v2:

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

> **Worth knowing.** `# branch.ab +0 -0` is the ahead and behind counts as
> numbers, which is far easier to act on than parsing the English sentence.
> This is the single best reason to reach for v2 in a shell prompt.

## How much to say about untracked files

```console
$ git status --short --untracked-files=normal
...
?? build/
?? extra/
?? newfile.txt
$ git status --short --untracked-files=all
...
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

| Value | Short | Shows |
|---|---|---|
| `no` | `-uno` | No untracked files at all |
| `normal` | `-unormal` | Untracked files, with whole directories collapsed. The default |
| `all` | `-uall` | Every untracked file individually |

The long form tells you when it is hiding something:

```console
$ git status -uno
...
Untracked files not listed (use -u option to show untracked files)
```

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
```

`--ignored` takes an optional value. `traditional` is the default and shows
ignored directories collapsed; `matching` shows only files that a pattern
actually matched; `no` turns it off again.

To ask why one specific file is ignored, `git check-ignore -v` is the better
tool, and Chapter 16 uses it throughout.

## Ahead and behind

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

`--no-ahead-behind` skips the calculation, which is worth knowing in a
repository where it is slow. `status.aheadBehind` sets the default.

## Detached HEAD

```console
$ git status
HEAD detached at 372e727
nothing to commit, working tree clean
$ git status -sb
## HEAD (no branch)
```

Note there is no "your branch is up to date" line, because there is no branch.
Chapter 7 covers how you get here and how to keep any commits you make.

## During a conflict

`git status` is the command to run when a merge stops. It tells you the state,
the files, and the way out:

```console
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
The other two-letter conflict codes:

| Code | Git's wording |
|---|---|
| `UU` | unmerged, both modified |
| `AA` | unmerged, both added |
| `DD` | unmerged, both deleted |
| `AU` | unmerged, added by us |
| `UA` | unmerged, added by them |
| `DU` | unmerged, deleted by us |
| `UD` | unmerged, deleted by them |

"Us" is the branch you are on, "them" is the branch being merged in. The two
letters are not a state and a state here; during a conflict they describe what
each side did, which is why `AU` and `UA` are different situations rather than
a typo of each other.

> **Worth knowing.** Submodules report three extra letters that mean something
> else entirely: `M` for a different HEAD than the index records, `m` for
> modified content inside, and `?` for untracked files inside. They exist
> because you cannot `git add` those from the outer repository. Chapter 57
> covers submodules.

## During a rebase

```console
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

## The options worth knowing

| Option | Does |
|---|---|
| `-s`, `--short` | Two-column format |
| `-b`, `--branch` | Add the branch header, even in long format |
| `--porcelain[=v1\|v2]` | Stable output for scripts |
| `-u<mode>`, `--untracked-files=<mode>` | `no`, `normal` or `all` |
| `--ignored[=<mode>]` | `traditional`, `matching` or `no` |
| `-z` | Terminate entries with NUL instead of newline, for paths with odd characters |
| `--column` | List untracked files in columns |
| `--no-renames` | Report renames as a delete plus an add |
| `--find-renames[=<n>]` | Set the rename similarity threshold |
| `--ahead-behind`, `--no-ahead-behind` | Compute the counts, or skip it |
| `--show-stash` | Say how many stash entries you have |
| `-v`, `--verbose` | Also print the staged diff. Twice prints the unstaged one too |

## The settings

| Setting | Effect |
|---|---|
| `status.short` | Default to the short format |
| `status.branch` | Always show the branch header |
| `status.showUntrackedFiles` | Default for `-u` |
| `status.showStash` | Always report stash entries |
| `status.aheadBehind` | Default for computing ahead and behind |
| `status.renames` | `false`, `true`, or `copies` to detect copies too |
| `status.renameLimit` | How many files to consider when detecting renames |
| `status.relativePaths` | Show paths relative to the current directory |
| `status.submoduleSummary` | Summarise changed submodules (Chapter 57) |
| `status.displayCommentPrefix` | Prefix long-format lines with `#`, as very old Git did |
| `status.compareBranches` | Which branches to compare against, from `@{upstream}` and `@{push}`. Defaults to `@{upstream}` |

> **Worth knowing.** `git status -v` prints the staged diff underneath the
> status, and `-vv` adds the unstaged one. It is the quickest way to review
> exactly what you are about to commit without running a second command, and
> it is what `git commit` itself shows you in the editor.
