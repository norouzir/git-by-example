# Chapter 27. Merge Strategies and Options

## What it is

A *merge strategy* is the code Git runs to combine the branches: `-s <name>`
chooses it. A *strategy option*, `-X <option>`, changes how that code decides
something, such as which side to prefer or whether whitespace counts. Both go on
`git merge`, and on every command that merges underneath: `git rebase`,
`git cherry-pick`, `git revert`, `git pull` and `git merge-tree`.

Almost every merge uses the default strategy with no options, and should. These
options are for the merge where you can say in advance what the answer is:
"their side wins", "ignore the re-indentation", "the file moved", "this file is
a log, keep both sets of lines".

| Term | Means |
|---|---|
| *three-way merge* | combining two versions by comparing each with the version they both started from (Chapter 25) |
| *merge base* | that starting version: the commit where the branches split |
| *virtual merge base* | when there is more than one merge base, a merged tree of them, made to serve as the one starting point |
| *rename detection* | noticing that a file one side changed is the file the other side renamed |
| *merge driver* | the code that merges one file's contents, chosen per file by the `merge` attribute |
| *strategy option* | a setting for the strategy, given as `-X <option>` |

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What is a merge strategy, and when would I choose one?](#what-it-is)

**[Synopsis](#synopsis)**

- [Where can I put `-s` and `-X`?](#synopsis)

**[The strategies at a glance](#the-strategies-at-a-glance)**

- [Which strategies exist, and what is each for?](#the-strategies-at-a-glance)

**[The options at a glance](#the-options-at-a-glance)**

- [Is there a list of every `-X` option, and where each is explained?](#the-options-at-a-glance)

**[The example repository](#the-example-repository)**

- [What repository do the examples use?](#the-example-repository)

**[Which strategy runs](#which-strategy-runs)**

- [Which strategy does a plain `git merge` use?](#which-strategy-runs)
- [Is `recursive` still a thing?](#which-strategy-runs)
- [Why does `git merge -s theirs` say it cannot find that strategy?](#which-strategy-runs)
- [What happens if I merge two branches at once and they conflict?](#which-strategy-runs)
- [Can I tell Git to try one strategy and fall back to another?](#which-strategy-runs)

**[ort, the default](#ort-the-default)**

- [What does the default strategy actually do?](#ort-the-default)

**[resolve](#resolve)**

- [What does `-s resolve` print, and how is it different?](#resolve)
- [Why did `-s resolve` label my conflict with a temporary file name?](#resolve)
- [Why did `-s resolve` fail on a file the default strategy merged?](#resolve)

**[The ours strategy](#the-ours-strategy)**

- [How do I record a merge that keeps my tree exactly as it is?](#the-ours-strategy)
- [Why did `-s ours` throw away the other branch's new file?](#the-ours-strategy)

**[subtree](#subtree)**

- [How do I merge another project into a subdirectory of mine?](#subtree)
- [What is the difference between `-s subtree` and `-X subtree=<path>`?](#subtree)

**[-X ours and -X theirs](#x-ours-and-x-theirs)**

- [How do I resolve every conflict in favour of one side without editing files?](#x-ours-and-x-theirs)
- [What is the difference between `-s ours` and `-X ours`?](#x-ours-and-x-theirs)

**[Ignoring whitespace](#ignoring-whitespace)**

- [Someone re-indented the file and now everything conflicts. What do I do?](#ignoring-whitespace)
- [Which whitespace option should I use, and what do they leave in the file?](#ignoring-whitespace)
- [My branch has CRLF line endings and theirs does not. Can the merge ignore that?](#ignoring-whitespace)

**[Renames](#renames)**

- [One branch renamed a file and the other edited it. Does the merge keep the edit?](#renames)
- [Can I turn rename detection off, or back on?](#renames)
- [I rewrote a file while renaming it and the merge lost the other side's change. Why?](#renames)
- [I set the rename threshold and the conflict changed shape. What happened?](#renames)

**[Directory renames](#directory-renames)**

- [I moved a directory, they added a file to the old one. Where does the file end up?](#directory-renames)
- [How do I stop Git asking about that, in either direction?](#directory-renames)

**[Diff algorithms](#diff-algorithms)**

- [Can the merge algorithm itself cause a conflict?](#diff-algorithms)
- [What do `-X patience` and `-X histogram` do?](#diff-algorithms)

**[How much the merge prints](#how-much-the-merge-prints)**

- [How do I make a merge quieter, or noisier?](#how-much-the-merge-prints)

**[Merge drivers](#merge-drivers)**

- [Both sides appended a line to a log file. Can Git keep both?](#merge-drivers)
- [How do I stop Git from ever merging a file's contents?](#merge-drivers)
- [How do I always keep my version of one file?](#merge-drivers)
- [How do I merge a file with my own program?](#merge-drivers)
- [What happens when my merge program fails?](#merge-drivers)
- [Why did my driver run twice on one file?](#more-than-one-merge-base)

**[More than one merge base](#more-than-one-merge-base)**

- [What is "merged common ancestors" in my conflict markers?](#more-than-one-merge-base)
- [Why are there `Temporary merge branch 1` and `2` labels?](#more-than-one-merge-base)

**[A change undone on one side](#a-change-undone-on-one-side)**

- [I undid a change on my branch and the merge brought it back. Why?](#a-change-undone-on-one-side)

**[The same options in other commands](#the-same-options-in-other-commands)**

- [Can I use `-X` with cherry-pick, rebase, revert or pull?](#the-same-options-in-other-commands)
- [How do I see what a merge would produce without doing it?](#the-same-options-in-other-commands)

**[Strategies and their neighbours](#strategies-and-their-neighbours)**

- [Which "take one side" should I use?](#strategies-and-their-neighbours)

**[The settings](#the-settings)**

- [Which settings change how merges combine files?](#the-settings)

</details>

## Synopsis

```
git merge [-s <strategy>] [-X <strategy-option>] [<commit>...]
git rebase [-s <strategy>] [-X <strategy-option>] [<upstream>]
git cherry-pick [--strategy=<strategy>] [-X <strategy-option>] <commit>...
git revert [--strategy=<strategy>] [-X <strategy-option>] <commit>...
git pull [-s <strategy>] [-X <strategy-option>] [<repository>]
git merge-tree --write-tree [-X <strategy-option>] <branch1> <branch2>
```

| Part | Means |
|---|---|
| `<strategy>` | `ort`, `recursive`, `resolve`, `octopus`, `ours` or `subtree` |
| `<strategy-option>` | one of the `-X` options below; repeat `-X` for more than one |

`-s` can be given more than once: Git tries the strategies in order until one
succeeds. Git's documentation says that with no `-s`, it uses `ort` for one
other branch and `octopus` for several.

## The strategies at a glance

| Strategy | Merges | Does | Covered in |
|---|---|---|---|
| `git merge -s ort` | two heads | The default: three-way merge with rename detection, and a virtual merge base when there is more than one | [ort, the default](#ort-the-default) |
| `git merge -s recursive` | two heads | A synonym for `ort` since Git 2.50; the old implementation before that | [Which strategy runs](#which-strategy-runs) |
| `git merge -s resolve` | two heads | An older three-way merge, without rename detection, that picks one merge base | [resolve](#resolve) |
| `git merge -s octopus` | any number | The default for more than one branch; refuses any merge that needs a person | [Which strategy runs](#which-strategy-runs) |
| `git merge -s ours` | any number | Records a merge whose tree is exactly ours, ignoring the other branches | [The ours strategy](#the-ours-strategy) |
| `git merge -s subtree` | two heads | `ort`, after shifting one tree so it matches the other | [subtree](#subtree) |

## The options at a glance

| Option | Does | Covered in |
|---|---|---|
| `-X ours` | Resolve each conflicting hunk with our side | [-X ours and -X theirs](#x-ours-and-x-theirs) |
| `-X theirs` | Resolve each conflicting hunk with their side | [-X ours and -X theirs](#x-ours-and-x-theirs) |
| `-X ignore-space-change` | Treat a change in the amount of whitespace as no change | [Ignoring whitespace](#ignoring-whitespace) |
| `-X ignore-all-space` | Treat any whitespace difference as no change | [Ignoring whitespace](#ignoring-whitespace) |
| `-X ignore-space-at-eol` | Ignore whitespace at the end of a line | [Ignoring whitespace](#ignoring-whitespace) |
| `-X ignore-cr-at-eol` | Ignore a carriage return at the end of a line | [Ignoring whitespace](#ignoring-whitespace) |
| `-X renormalize` | Check each version out and back in before merging, so that line-ending and filter rules match | [The settings](#the-settings) |
| `-X no-renormalize` | Turn that off, overriding `merge.renormalize` | [The settings](#the-settings) |
| `-X find-renames` | Detect renames, the default; overrides `merge.renames` | [Renames](#renames) |
| `-X find-renames=<n>` | The same, with this similarity threshold | [Renames](#renames) |
| `-X rename-threshold=<n>` | A deprecated synonym for `find-renames=<n>` | [Renames](#renames) |
| `-X no-renames` | Do not detect renames | [Renames](#renames) |
| `-X diff-algorithm=<algorithm>` | Use this algorithm to find the changes: `histogram`, `minimal`, `myers` or `patience` | [Diff algorithms](#diff-algorithms) |
| `-X patience` | A deprecated synonym for `diff-algorithm=patience` | [Diff algorithms](#diff-algorithms) |
| `-X histogram` | A deprecated synonym for `diff-algorithm=histogram` | [Diff algorithms](#diff-algorithms) |
| `-X subtree` | Guess how far to shift one tree, as `-s subtree` does | [subtree](#subtree) |
| `-X subtree=<path>` | Shift the other tree to this path | [subtree](#subtree) |

<!-- no-example: -X renormalize
     it changes nothing unless the branches were committed under different
     line-ending or clean-filter rules, which are Chapter 65 and Chapter 66;
     shown here would need an attributes and filter setup those chapters build,
     and the transcript would differ only in whether a whole file conflicts -->
<!-- no-example: -X no-renormalize
     it only cancels merge.renormalize, which has no example here for the
     reason above -->

## The example repository

```console
$ git log --oneline --graph --decorate main sale renamed
* a4527c0 (renamed) Rename the notes
* 4e61f72 (HEAD -> main) Raise the tea price
| * 176f844 (sale) Cut prices for the sale
|/  
* 74e6376 Open the shop
$ git branch
  bump
  cr-ours
  cross-a
  cross-b
  cross1
  cross2
  dir-added
  dir-moved
  edited
  eol-ours
  eol-theirs
  flip
  list
  list-a
  list-b
* main
  renamed
  rewritten
  sale
  space-ours
  space-theirs
  steps-ours
  steps-theirs
  work
```

A shop, with one branch pair for each thing a strategy or option changes. Every
branch starts at `Open the shop` or at `Raise the tea price`:

| Branches | Differ in |
|---|---|
| `main`, `sale` | the tea price, on the same line of `prices.txt`; `sale` also adds `flyer.txt` |
| `renamed`, `edited` | `notes.txt` renamed to `kitchen-notes.txt`, against a changed line in `notes.txt` |
| `rewritten`, `edited` | the same, but `renamed` also rewrote most of the file, as `jobs.txt` |
| `dir-moved`, `dir-added` | `src/` renamed to `lib/`, against a new file added in `src/` |
| `space-ours`, `space-theirs` | re-spaced lines against changed lines in `recipe.txt` |
| `eol-ours`, `cr-ours`, `eol-theirs` | trailing spaces, and a CRLF line ending, against a changed line in `eol.txt` |
| `steps-ours`, `steps-theirs` | a file of repeated lines, changed at both ends |
| `cross-a`, `cross-b`, `cross1`, `cross2` | a criss-cross history with two merge bases |
| `flip`, `bump` | a change made and undone, against the same change kept |
| `list`, `list-a`, `list-b` | a line appended to `log.txt` on each side |
| `work` | adds `src/`, the directory the `dir-` branches move |

Each example starts on a fresh `try` branch, made with `git switch -q -C try
<branch>` (Chapter 24). A second repository, `lib`, is used by
[subtree](#subtree).

## Which strategy runs

```console
$ git switch -q -C try main
$ git merge --no-edit sale
Auto-merging prices.txt
CONFLICT (content): Merge conflict in prices.txt
Automatic merge failed; fix conflicts and then commit the result.
$ git merge --abort
$ git merge --no-edit -s ort sale
Auto-merging prices.txt
CONFLICT (content): Merge conflict in prices.txt
Automatic merge failed; fix conflicts and then commit the result.
$ git merge --abort
$ git merge --no-edit -s recursive sale
Auto-merging prices.txt
CONFLICT (content): Merge conflict in prices.txt
Automatic merge failed; fix conflicts and then commit the result.
$ git merge --abort
```

The plain merge, `-s ort` and `-s recursive` all did the same thing: `ort` is
the default, and `recursive` is now another name for it. Both branches changed
the tea price, so the merge conflicts (Chapter 26).

> **Since Git 2.34.** `ort` is the default. Git 2.33 and older used a separate
> `recursive` implementation, which Git 2.50 removed; `-s recursive` has meant
> `ort` since then, and the strategy in `git merge`'s own output is `ort`.

```console
$ git merge -s theirs sale
Could not find merge strategy 'theirs'.
Available strategies are: octopus ours recursive resolve subtree.
$ git merge -X nosuch sale
fatal: unknown strategy option: -Xnosuch
```

There is no `theirs` strategy: the way to prefer their side is `-X theirs`,
which is not the same thing ([-X ours and -X theirs](#x-ours-and-x-theirs)).
The list of available strategies leaves out `ort` itself, although `-s ort`
works, as above. An unknown `-X` option is a fatal error before anything is
merged.

```console
$ git merge --no-edit sale cross-a
Trying simple merge with sale
Simple merge did not work, trying automatic merge.
Auto-merging prices.txt
ERROR: content conflict in prices.txt
fatal: merge program failed
Automated merge did not work.
Should not be doing an octopus.
Merge with strategy octopus failed.
$ git merge --no-edit -s ort sale cross-a
error: Not handling anything other than two heads merge.
Merge with strategy ort failed.
$ git switch -q -C try main
$ git merge --no-edit -s octopus sale
error: Merge requires file-level merging
Trying really trivial in-index merge...
Nope.
Merge with strategy octopus failed.
```

Two branches at once means `octopus`, which gives up as soon as a merge needs a
person: "Should not be doing an octopus". Nothing is left half-merged, so the
next command can run straight away. `ort` refuses more than two heads, and
`octopus` on a single branch is allowed but just as unwilling to face a
conflict. Chapter 25 covers octopus merges that work.

```console
$ git merge --no-edit -s resolve -s ort sale
Trying merge strategy resolve...
Trying simple merge.
Simple merge failed, trying Automatic merge.
Auto-merging prices.txt
ERROR: content conflict in prices.txt
fatal: merge program failed
Rewinding the tree to pristine...
Trying merge strategy ort...
Auto-merging prices.txt
CONFLICT (content): Merge conflict in prices.txt
Automatic merge failed; fix conflicts and then commit the result.
$ git merge --abort
```

With several `-s`, Git tries them in the order given, rewinding the tree between
attempts, and keeps the result of the first one that works. Here neither could
finish, so the last one's conflicts were left for you.

## ort, the default

`ort` is a three-way merge: it compares each branch with the merge base and
takes every change that only one side made. Its own additions, from Git's
documentation, are rename detection, a merged tree of the common ancestors when
there is more than one ([More than one merge base](#more-than-one-merge-base)),
and for submodules, a fast-forward when one side's submodule commit is a
descendant of the other's. It does not detect copies. The name is an acronym for
"Ostensibly Recursive's Twin".

One thing it does silently is worth knowing: `ort` finds the changes with the
histogram algorithm, while `git diff` uses Myers unless told otherwise. That is
in its documentation, and in Git's source it is set when the merge options are
initialised, so a merge and a diff of the same two files can disagree about
which lines changed ([Diff algorithms](#diff-algorithms)).

## resolve

```console
$ git switch -q -C try work
$ git merge --no-edit -s resolve edited
Trying really trivial in-index merge...
Wonderful.
In-index merge
 notes.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ cat notes.txt
Order flour on Fridays
Call the baker
Check the oven twice
Count the cups
Water the plant
```

`resolve` is the older three-way merge. When only one side touched each file, it
finishes in the index without looking at contents at all: "Trying really trivial
in-index merge... Wonderful."

```console
$ git switch -q -C try main
$ git merge --no-edit -s resolve sale
error: Merge requires file-level merging
Trying really trivial in-index merge...
Nope.
Trying simple merge.
Simple merge failed, trying Automatic merge.
Auto-merging prices.txt
ERROR: content conflict in prices.txt
fatal: merge program failed
Automatic merge failed; fix conflicts and then commit the result.
$ git status --short
A  flyer.txt
UU prices.txt
$ sed -n '2p;4p' prices.txt
Tea 3
Tea 4
$ git merge --abort
```

When it has to merge contents it says so, and a conflict leaves the same
unmerged state as any other strategy. The `fatal: merge program failed` line is
not the end of the world; the merge stopped in the ordinary way, for you to
resolve.

One difference shows in the file: `resolve` labels the conflict markers with the
names of the temporary files it merged, such as `.merge_file_K24XKO`, instead of
`HEAD` and the branch name. `sed -n '2p;4p'` prints the second and fourth lines,
which are our version and theirs.

```console
$ git switch -q -C try renamed
$ git merge --no-edit edited
Merge made by the 'ort' strategy.
 kitchen-notes.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ cat kitchen-notes.txt
Order flour on Fridays
Call the baker
Check the oven twice
Count the cups
Water the plant
```

```console
$ git switch -q -C try renamed
$ git merge --no-edit -s resolve edited
error: Merge requires file-level merging
Trying really trivial in-index merge...
Nope.
Trying simple merge.
Simple merge failed, trying Automatic merge.
ERROR: notes.txt: Not handling case eb8b7d4c044cc768d3ffa3c89fc388a45df62a2d ->  -> 424af94990086f8b47b1e57da21732963fdc8147
fatal: merge program failed
Automatic merge failed; fix conflicts and then commit the result.
$ git status --short
DU notes.txt
$ git merge --abort
```

`renamed` renamed `notes.txt`; `edited` changed a line in it. The default
strategy noticed the rename and put the change into the new name. `resolve` does
not detect renames, so it saw a file deleted on one side and modified on the
other and gave up, with the three blob hashes of a case it does not handle. That
is the reason to leave `resolve` alone unless you have a specific reason.

## The ours strategy

```console
$ git switch -q -C try main
$ git merge --no-edit -s ours sale
Merge made by the 'ours' strategy.
$ git show --stat --format=%s
Merge branch 'sale' into try

$ cat prices.txt
Tea 3
Coffee 3
Cake 4
Bun 1
$ ls
cross.txt
eol.txt
notes.txt
prices.txt
recipe.txt
size.txt
steps.txt
$ git log --oneline --graph -3
*   440fbdc Merge branch 'sale' into try
|\  
| * 176f844 Cut prices for the sale
* | 4e61f72 Raise the tea price
|/  
$ git merge --no-edit sale
Already up to date.
$ git branch --merged
  main
  sale
* try
```

`-s ours` records a merge commit with both parents, whose tree is exactly what
`try` already had. Nothing from `sale` arrived: the tea price is still ours, and
`flyer.txt`, which only `sale` had, is not there. `git show` prints no diff for
it, because against the first parent nothing changed.

It is for telling Git, and everyone reading the history, that a branch has been
dealt with: its work is superseded, or was released from another line, and it
should never be merged again. Afterwards Git agrees the branch is finished:
merging it again says "Already up to date", and it is listed by
`git branch --merged`, which is what `git branch -d` checks before deleting
(Chapter 23).

> **Careful.** `-s ours` is not a way to resolve conflicts in your favour; it
> ignores the other branch's work entirely, including files you never touched.
> The one that resolves conflicts is `-X ours`, below.

## subtree

Another project lives in the repository `../lib`, with one file, `lib.txt`. The
classic way to vendor it into a subdirectory takes an empty `-s ours` merge to
record the relationship, then `git read-tree` to put its files in place:

```console
$ git switch -q -C vendored main
$ git remote add lib ../lib
$ git fetch -q lib
$ git merge -s ours --no-commit --allow-unrelated-histories lib/main
Automatic merge went well; stopped before committing as requested
$ git read-tree --prefix=vendor/lib -u lib/main
$ git commit -q -m 'Vendor the library'
$ git ls-files vendor
vendor/lib/lib.txt
```

`--allow-unrelated-histories` is needed because the two projects share no commit
(Chapter 25), and `-s ours --no-commit` keeps our tree while staging the
relationship; `git read-tree --prefix` then reads their tree into `vendor/lib`
and `-u` writes the files out. Chapter 58 covers `git subtree`, which wraps all
of this.

The library then gains a commit, and it has to reach `vendor/lib`:

```console
$ git fetch -q lib
$ git switch -q -C try vendored
$ git merge --no-edit lib/main
Merge made by the 'ort' strategy.
 vendor/lib/lib.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ cat vendor/lib/lib.txt
parse 2
print 1
$ git switch -q -C try vendored
$ git merge --no-edit -s subtree lib/main
Merge made by the 'subtree' strategy.
 vendor/lib/lib.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ cat vendor/lib/lib.txt
parse 2
print 1
$ git switch -q -C try vendored
$ git merge --no-edit -X subtree=vendor/lib lib/main
Merge made by the 'ort' strategy.
 vendor/lib/lib.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ cat vendor/lib/lib.txt
parse 2
print 1
```

All three worked. The plain merge worked because rename detection saw `lib.txt`
and `vendor/lib/lib.txt` as the same file; `-s subtree` guesses the shift
between the two trees and then merges as `ort`; `-X subtree=vendor/lib` is told
where to shift to, and is the one to use when the guess is wrong or the files
have changed too much to be recognised. That last case is what it looks like
without any of the three:

```console
$ git switch -q -C try vendored
$ git merge --no-edit -X no-renames lib/main
CONFLICT (modify/delete): lib.txt deleted in HEAD and modified in lib/main.  Version lib/main of lib.txt left in tree.
Automatic merge failed; fix conflicts and then commit the result.
$ git status --short
DU lib.txt
$ git merge --abort
```

With rename detection off, Git sees a file it has at the top level on one side
and nowhere on the other, and the merge falls apart.

## -X ours and -X theirs

```console
$ git switch -q -C try main
$ git merge --no-edit -X ours sale
Auto-merging prices.txt
Merge made by the 'ort' strategy.
 flyer.txt  | 1 +
 prices.txt | 2 +-
 2 files changed, 2 insertions(+), 1 deletion(-)
 create mode 100644 flyer.txt
$ cat prices.txt
Tea 3
Coffee 3
Cake 4
Bun 2
$ ls flyer.txt
flyer.txt
$ git switch -q -C try main
$ git merge --no-edit -X theirs sale
Auto-merging prices.txt
Merge made by the 'ort' strategy.
 flyer.txt  | 1 +
 prices.txt | 4 ++--
 2 files changed, 3 insertions(+), 2 deletions(-)
 create mode 100644 flyer.txt
$ cat prices.txt
Tea 4
Coffee 3
Cake 4
Bun 2
```

Both branches changed the tea line, and only `sale` changed the bun line and
added `flyer.txt`. `-X ours` resolved the conflicting line with our `Tea 3` and
took everything else from `sale` anyway: `Bun 2` and the flyer are there. `-X
theirs` did the same with their tea price. Where the default stops and asks,
these two make the choice for every conflicting hunk in every file, silently.
For a binary file, Git's documentation says the whole file comes from the chosen
side.

That "everything else still arrives" is the whole difference from `-s ours`,
which took nothing at all. Use `-X theirs` when you know the other branch is
right about every clash, `-X ours` when yours is, and neither when you do not
know: a wrong choice is invisible afterwards, because the merge commit looks
clean.

## Ignoring whitespace

```console
$ git switch -q -C try space-ours
$ git merge --no-edit space-theirs
Auto-merging recipe.txt
CONFLICT (content): Merge conflict in recipe.txt
Automatic merge failed; fix conflicts and then commit the result.
$ cat recipe.txt
<<<<<<< HEAD
mix   flour
bake it
=======
mix  water
bake  it now
>>>>>>> space-theirs
serve it
$ git merge --abort
$ git merge --no-edit -X ignore-space-change space-theirs
Auto-merging recipe.txt
Merge made by the 'ort' strategy.
 recipe.txt | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
$ cat recipe.txt
mix  water
bake  it now
serve it
```

Our side only changed spacing: `mix  flour` became `mix   flour`, and
`bake  it` became `bake it`. Their side changed the words. Without the option
that is a conflict on both lines; with `-X ignore-space-change` Git treats our
whitespace-only change as no change at all and takes their lines whole.

Git's documentation gives the rule in three parts: if only their version changes
whitespace on a line, ours is used; if ours changes only whitespace and theirs
changes something real, theirs is used; otherwise the merge runs as usual. So
the result keeps their spacing, not ours, and a whitespace change mixed into a
line with a real change is never ignored.

```console
$ git switch -q -C try space-ours
$ git merge --no-edit -X ignore-all-space space-theirs
Auto-merging recipe.txt
Merge made by the 'ort' strategy.
 recipe.txt | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
$ cat recipe.txt
mix  water
bake  it now
serve it
```

`ignore-all-space` ignores every whitespace difference, including whitespace
added where there was none; `ignore-space-change` only ignores a change in how
much there is. On this example they agree. They are the merge's versions of
`git diff -w` and `-b` (Chapter 13).

```console
$ git switch -q -C try eol-ours
$ git merge --no-edit eol-theirs
Auto-merging eol.txt
CONFLICT (content): Merge conflict in eol.txt
Automatic merge failed; fix conflicts and then commit the result.
$ git merge --abort
$ git merge --no-edit -X ignore-space-at-eol eol-theirs
Auto-merging eol.txt
Merge made by the 'ort' strategy.
 eol.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ cat eol.txt
mix batter
bake it
serve it
```

`eol-ours` added three spaces to the end of the first line, and `eol-theirs`
changed that line's words. `ignore-space-at-eol` ignores only what is at the end
of a line, which is enough here.

```console
$ git switch -q -C try cr-ours
$ git merge --no-edit eol-theirs
Auto-merging eol.txt
CONFLICT (content): Merge conflict in eol.txt
Automatic merge failed; fix conflicts and then commit the result.
$ git merge --abort
$ git merge --no-edit -X ignore-cr-at-eol eol-theirs
Auto-merging eol.txt
Merge made by the 'ort' strategy.
 eol.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ cat -A eol.txt
mix batter$
bake it$
serve it$
```

`cr-ours` committed the first line with a CRLF line ending, which to Git is a
carriage return at the end of the line; the other branch changed the same line
without one. `ignore-cr-at-eol` ignores that difference, and their line wins, so
the result has no carriage return: `cat -A` marks each line's end with `$` and
would show `^M` before it. Chapter 66 is about line endings, and
`-X renormalize` with the `text` attribute is the proper cure for a repository
where they are mixed.

## Renames

```console
$ git switch -q -C try renamed
$ git merge --no-edit -X no-renames edited
CONFLICT (modify/delete): notes.txt deleted in HEAD and modified in edited.  Version edited of notes.txt left in tree.
Automatic merge failed; fix conflicts and then commit the result.
$ git status --short
DU notes.txt
$ git merge --abort
$ git -c merge.renames=false merge --no-edit edited
CONFLICT (modify/delete): notes.txt deleted in HEAD and modified in edited.  Version edited of notes.txt left in tree.
Automatic merge failed; fix conflicts and then commit the result.
$ git merge --abort
$ git -c merge.renames=false merge --no-edit -X find-renames edited
Merge made by the 'ort' strategy.
 kitchen-notes.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

The same merge that succeeded in [resolve](#resolve) falls apart with rename
detection off, whether it is turned off for one merge with `-X no-renames` or
for the repository with `merge.renames=false`. `-X find-renames` turns it back
on for one command. There is rarely a reason to turn it off; the setting exists
because rename detection on a very large tree costs time.

```console
$ git switch -q -C try rewritten
$ git merge --no-edit edited
CONFLICT (modify/delete): notes.txt deleted in HEAD and modified in edited.  Version edited of notes.txt left in tree.
Automatic merge failed; fix conflicts and then commit the result.
$ git merge --abort
$ git merge --no-edit -X find-renames=30% edited
Auto-merging jobs.txt
CONFLICT (content): Merge conflict in jobs.txt
Automatic merge failed; fix conflicts and then commit the result.
$ cat jobs.txt
<<<<<<< HEAD:jobs.txt
Sweep the floor
Wipe the tables
Check the oven
=======
Order flour on Fridays
Call the baker
Check the oven twice
>>>>>>> edited:notes.txt
Count the cups
Lock the door
$ git merge --abort
```

`rewritten` renamed `notes.txt` to `jobs.txt` and rewrote most of it in the same
commit. Too little is left for Git's default threshold of 50% similarity, so it
saw a delete and a modify. `-X find-renames=30%` lowers the bar until Git pairs
the two files, and the merge becomes a content conflict inside one file —
whose markers name both paths, `HEAD:jobs.txt` and `edited:notes.txt`, because
the two sides call the file different things.

Lowering the threshold does not make the merge automatic; it only changes the
shape of the question. The value takes a percentage, with or without the `%`,
and `-X rename-threshold=30` is the same option under its deprecated name:

```console
$ git merge --no-edit -X rename-threshold=30 edited
Auto-merging jobs.txt
CONFLICT (content): Merge conflict in jobs.txt
Automatic merge failed; fix conflicts and then commit the result.
$ git status --short
UU jobs.txt
$ git merge --abort
```

## Directory renames

```console
$ git switch -q -C try dir-moved
$ git merge --no-edit dir-added
CONFLICT (file location): src/extra.txt added in dir-added inside a directory that was renamed in HEAD, suggesting it should perhaps be moved to lib/extra.txt.
Automatic merge failed; fix conflicts and then commit the result.
$ git status --short
UA lib/extra.txt
$ ls lib
app.txt
extra.txt
util.txt
$ git merge --abort
```

We renamed `src/` to `lib/`; they added `src/extra.txt`, which we never saw. Git
guesses the file belongs in the new directory, writes it there, and stops to ask,
because the default for `merge.directoryRenames` is `conflict`. Note that the
file is already in `lib/` and staged as added by them; `git add lib/extra.txt`
would be the whole resolution.

```console
$ git -c merge.directoryRenames=true merge --no-edit dir-added
Path updated: src/extra.txt added in dir-added inside a directory that was renamed in HEAD; moving it to lib/extra.txt.
Merge made by the 'ort' strategy.
 lib/extra.txt | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 lib/extra.txt
$ ls lib
app.txt
extra.txt
util.txt
$ git switch -q -C try dir-moved
$ git -c merge.directoryRenames=false merge --no-edit dir-added
Merge made by the 'ort' strategy.
 src/extra.txt | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 src/extra.txt
$ ls lib src
lib:
app.txt
util.txt

src:
extra.txt
```

`true` moves the file without asking, `false` leaves it where they put it, in a
directory nobody else uses any more. The setting has no `-X` form; it is
`merge.directoryRenames`, and it is ignored when `merge.renames` is `false`.

## Diff algorithms

`steps.txt` is a short file with many repeated lines: `steps-ours` moved some
around, `steps-theirs` added two more.

```console
$ git switch -q -C try steps-ours
$ git merge --no-edit steps-theirs
Auto-merging steps.txt
CONFLICT (content): Merge conflict in steps.txt
Automatic merge failed; fix conflicts and then commit the result.
$ cat steps.txt
<<<<<<< HEAD
Step:
=======
>>>>>>> steps-theirs
check
Step:
check
Step:
wait 1
start
Step:
Stop:
Stop:
Step:
$ git merge --abort
$ git merge --no-edit -X diff-algorithm=myers steps-theirs
Auto-merging steps.txt
Merge made by the 'ort' strategy.
 steps.txt | 2 ++
 1 file changed, 2 insertions(+)
$ cat steps.txt
check
Step:
check
Step:
wait 1
start
Step:
Stop:
Stop:
Step:
```

The same two commits, merged twice, with different results. The algorithm
decides which lines it thinks are "the same" lines, and where repeated lines
make that ambiguous, the answer changes: with the default the sides disagree
about one `Step:` line and Git asks; with Myers the changes line up and the
merge is clean.

```console
$ git switch -q -C try steps-ours
$ git merge --no-edit -X patience steps-theirs
Auto-merging steps.txt
Merge made by the 'ort' strategy.
 steps.txt | 2 ++
 1 file changed, 2 insertions(+)
$ git switch -q -C try steps-ours
$ git merge --no-edit -X histogram steps-theirs
Auto-merging steps.txt
CONFLICT (content): Merge conflict in steps.txt
Automatic merge failed; fix conflicts and then commit the result.
$ git merge --abort
$ git switch -q -C try steps-ours
$ git merge --no-edit -X diff-algorithm=minimal steps-theirs
Auto-merging steps.txt
Merge made by the 'ort' strategy.
 steps.txt | 2 ++
 1 file changed, 2 insertions(+)
```

`-X patience` and `-X histogram` are the old spellings of
`-X diff-algorithm=patience` and `=histogram`, which Git's documentation calls
deprecated synonyms; `histogram` is what the merge does anyway, so it conflicted
like the plain merge. Chapter 13 explains what the four algorithms do.

A clean merge from a different algorithm is not automatically the right one:
both results here are defensible, and neither is what a person would call
correct without reading the file. Reach for this option when a merge conflicts
in a place where nothing really changed, and check the result.

## How much the merge prints

```console
$ git switch -q -C try main
$ git -c merge.verbosity=0 merge --no-edit sale
Automatic merge failed; fix conflicts and then commit the result.
$ git status --short
A  flyer.txt
UU prices.txt
$ git merge --abort
$ GIT_MERGE_VERBOSITY=0 git merge --no-edit sale
Automatic merge failed; fix conflicts and then commit the result.
$ git merge --abort
```

`merge.verbosity` is how much the strategy says while it works: level 0 prints
only the final error, level 1 conflicts, level 2 (the default) conflicts and the
`Auto-merging` lines, and 5 and above debugging information, according to the
documentation. `GIT_MERGE_VERBOSITY` overrides the setting for one command.
Tested here at 5, `ort` printed nothing beyond the usual output; the debugging
levels belong to the old `recursive` implementation.

Note what level 0 does not do: the merge still stopped with a conflict, and
`git status` still shows it. Quieter is not safer.

## Merge drivers

Which code merges a file's contents is decided per file by the `merge`
attribute, in `.gitattributes` (Chapter 65). Both `list-a` and `list-b` appended
a line to `log.txt`:

```console
$ git switch -q -C try list-a
$ git merge --no-edit list-b
Auto-merging log.txt
CONFLICT (content): Merge conflict in log.txt
Automatic merge failed; fix conflicts and then commit the result.
$ cat log.txt
opened Monday
<<<<<<< HEAD
cleaned Tuesday
=======
painted Wednesday
>>>>>>> list-b
$ git merge --abort
$ echo 'log.txt merge=union' > .gitattributes
$ git merge --no-edit list-b
Auto-merging log.txt
Merge made by the 'ort' strategy.
 log.txt | 1 +
 1 file changed, 1 insertion(+)
$ cat log.txt
opened Monday
cleaned Tuesday
painted Wednesday
```

The `union` driver keeps both sides' lines instead of writing markers. It is
right for a file that is a set of independent lines — a changelog, a list of
contributors, a `.gitignore` — and wrong for anything where order or syntax
matters, because, as Git's documentation warns, the added lines land in no
particular order and nobody checks the result.

```console
$ git switch -q -C try list-a
$ rm .gitattributes
$ git -c merge.default=union merge --no-edit list-b
Auto-merging log.txt
Merge made by the 'ort' strategy.
 log.txt | 1 +
 1 file changed, 1 insertion(+)
$ cat log.txt
opened Monday
cleaned Tuesday
painted Wednesday
```

`merge.default` names the driver for every file whose `merge` attribute is not
set, which is how you would make `union` the rule for a whole repository. Rarely
what you want, but it shows where the default comes from.

```console
$ git switch -q -C try list-a
$ echo 'log.txt merge=binary' > .gitattributes
$ git merge --no-edit list-b
warning: Cannot merge binary files: log.txt (HEAD vs. list-b)
Auto-merging log.txt
CONFLICT (content): Merge conflict in log.txt
Automatic merge failed; fix conflicts and then commit the result.
$ cat log.txt
opened Monday
cleaned Tuesday
$ git status --short
UU log.txt
?? .gitattributes
$ git merge --abort
$ echo 'log.txt -merge' > .gitattributes
$ git merge --no-edit list-b
warning: Cannot merge binary files: log.txt (HEAD vs. list-b)
Auto-merging log.txt
CONFLICT (content): Merge conflict in log.txt
Automatic merge failed; fix conflicts and then commit the result.
$ git merge --abort
```

The `binary` driver never merges contents: it leaves our version in the working
tree and marks the file conflicted, for a person to sort out. Unsetting the
attribute with `-merge` does the same thing, and so does the built-in `binary`
macro attribute, which unsets `merge` along with `text` and `diff`. This is what
happens to files Git decides are binary by their contents (Chapter 26).

| Value of the `merge` attribute | The file is merged |
|---|---|
| `merge` (set) | by the built-in three-way driver, the same as `merge=text` |
| `-merge` (unset) | not at all: our version stays and the file is left conflicted |
| unspecified | by the built-in driver, or by `merge.default` when that is set |
| `merge=text` | by the built-in three-way driver |
| `merge=binary` | not at all, as with `-merge` |
| `merge=union` | by the built-in driver, taking both sides' lines with no markers |
| `merge=<name>` | by the command in `merge.<name>.driver` |

A driver of your own is a command in the configuration, not in the attributes
file. This one always keeps our version:

```console
$ git config set merge.keep-ours.name 'always keep our version'
$ git config set merge.keep-ours.driver true
$ echo 'log.txt merge=keep-ours' > .gitattributes
$ git merge --no-edit list-b
Auto-merging log.txt
Merge made by the 'ort' strategy.
$ cat log.txt
opened Monday
cleaned Tuesday
```

`merge.<name>.driver` is a shell command; `true` is the program that does
nothing and succeeds, which leaves the file as the driver found it — our
version — and reports success, so the merge is clean.
`merge.<name>.name` is a description, for people reading the configuration.

> **Careful.** A driver only runs when both sides changed the file. Merge the
> same branch into `list`, where only their side changed `log.txt`, and Git
> takes their version without asking any driver:

```console
$ git switch -q -C try list
$ git merge --no-edit list-b
Updating 922206c..03489ab
Fast-forward
 log.txt | 1 +
 1 file changed, 1 insertion(+)
$ cat log.txt
opened Monday
painted Wednesday
```

A real driver gets the three versions as temporary files and writes the result:

```console
$ git switch -q -C try list-a
$ git config set merge.show-args.driver 'echo "driver ran: marker size %L, path %P, labels %S %X %Y" >&2; cp %B %A'
$ echo 'log.txt merge=show-args' > .gitattributes
$ git merge --no-edit list-b
driver ran: marker size 7, path 'log.txt', labels '922206c' 'HEAD' 'list-b'
Auto-merging log.txt
Merge made by the 'ort' strategy.
 log.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ cat log.txt
opened Monday
painted Wednesday
```

| Placeholder | Is the name of |
|---|---|
| `%O` | a file holding the base version |
| `%A` | a file holding our version, which the driver must overwrite with the result |
| `%B` | a file holding their version |
| `%L` | the conflict marker size (Chapter 26) |
| `%P` | the path of the file in the working tree |
| `%S`, `%X`, `%Y` | the conflict labels for the base, our side and theirs |

This driver printed its placeholders and then copied their version over ours,
which is why the log holds `painted Wednesday`. The driver's exit status says
whether it managed a clean merge:

```console
$ git switch -q -C try list-a
$ git config set merge.give-up.driver 'exit 1'
$ echo 'log.txt merge=give-up' > .gitattributes
$ git merge --no-edit list-b
Auto-merging log.txt
CONFLICT (content): Merge conflict in log.txt
Automatic merge failed; fix conflicts and then commit the result.
$ git status --short
UU log.txt
?? .gitattributes
$ cat log.txt
opened Monday
cleaned Tuesday
$ git merge --abort
$ rm .gitattributes
```

A non-zero status means "conflict", and the merge stops with whatever the driver
left in `%A`. Git's documentation adds that a status above 128, as a crashed
program returns, is treated as a failure of the merge itself rather than a
conflict.

## More than one merge base

```console
$ git switch -q -C try cross1
$ git log --oneline --graph cross1 cross2
* 3b60ec0 Number seven, take two
*   3d5d968 Merge branch 'cross-a' into cross2
|\  
| | * fbf0e17 Number seven, take one
| | * caf2663 Merge branch 'cross-b' into cross1
| |/| 
| |/  
|/|   
* | 5cb05c9 Shout two
| * 5e773a7 Shout one
|/  
* 4e61f72 Raise the tea price
* 74e6376 Open the shop
$ git merge-base --all cross1 cross2
5cb05c9a7abcbe2d1f48634987e862cce5fa691b
5e773a7765341b91ff08b517acb79bd4fcc02bc3
```

`cross1` and `cross2` each merged the other's starting branch, so neither
`Shout one` nor `Shout two` is "the" point where they split: `git merge-base
--all` prints both. This shape is called a criss-cross merge, and it is common
in a busy repository.

```console
$ git -c merge.conflictStyle=diff3 merge --no-edit cross2
Auto-merging cross.txt
CONFLICT (content): Merge conflict in cross.txt
Automatic merge failed; fix conflicts and then commit the result.
$ cat cross.txt
ONE
two
three
four
FIVE
six
<<<<<<< HEAD
seventh
||||||| merged common ancestors
seven
=======
7
>>>>>>> cross2
$ git merge --abort
```

`ort` merges the merge bases into one temporary tree and uses that as the
starting point, which is why the base in the markers is labelled `merged common
ancestors` rather than a commit. Both sides changed the last line, so this
conflict remains for a person either way.

```console
$ git merge --no-edit -s resolve cross2
Trying simple merge.
Simple merge failed, trying Automatic merge.
Auto-merging cross.txt
ERROR: content conflict in cross.txt
fatal: merge program failed
Automatic merge failed; fix conflicts and then commit the result.
$ git status --short
UU cross.txt
$ git merge --abort
```

`resolve` picks one of the bases and merges against that. When the bases differ
in a part of a file that both branches also touched, the two strategies can
produce different results; `ort`'s virtual base is the reason Git's
documentation says it reports fewer conflicts.

The merging of the bases is a merge of its own, and a custom driver sees it:

```console
$ echo 'cross.txt merge=show-args' > .gitattributes
$ git merge --no-edit cross2
driver ran: marker size 9, path 'cross.txt', labels '4e61f72' 'Temporary merge branch 1' 'Temporary merge branch 2'
driver ran: marker size 7, path 'cross.txt', labels 'merged common ancestors' 'HEAD' 'cross2'
Auto-merging cross.txt
Merge made by the 'ort' strategy.
 cross.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git switch -q -C try cross1
$ git config set merge.show-args.recursive binary
$ git merge --no-edit cross2
driver ran: marker size 7, path 'cross.txt', labels 'merged common ancestors' 'HEAD' 'cross2'
Auto-merging cross.txt
Merge made by the 'ort' strategy.
 cross.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ cat cross.txt
ONE
two
three
four
FIVE
six
7
$ git switch -q -C try cross1
$ rm .gitattributes
```

The driver ran twice: once for the two bases, labelled `Temporary merge branch 1`
and `2` and with longer markers so that any it writes cannot be confused with
the outer merge's, and once for the real merge. `merge.<name>.recursive` names a
different driver for that inner merge, here `binary`, and the second run is
gone. Set it whenever your driver is expensive or would produce nonsense on a
pair of ancestors.

## A change undone on one side

```console
$ git switch -q -C try flip
$ git log --oneline -3
2588d37 Put the size back
2c3e77d Make it bigger
4e61f72 Raise the tea price
$ git merge --no-edit bump
Merge made by the 'ort' strategy.
 size.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ cat size.txt
size 2
```

`flip` made a change and then undid it, so its file is back to `size 1`, the
same as the merge base. `bump` made the same change and kept it. The merge takes
their change, because a three-way merge compares the two tips with the base and
nothing else: from where it stands, our side did nothing and theirs changed the
line. Git's documentation calls this out as behaviour people find confusing.

Two ways out: revert the revert after merging, or, if the point is that the
change must never come back, `git merge -s ours` the other branch to record that
it is dealt with, or record the undo as a `git revert` of the merge (Chapter
25).

## The same options in other commands

```console
$ git switch -q -C try main
$ git cherry-pick -X theirs sale
Auto-merging prices.txt
[try dcdc7ab] Cut prices for the sale
 Date: Mon Jan 5 10:00:00 2026 +0000
 2 files changed, 3 insertions(+), 2 deletions(-)
 create mode 100644 flyer.txt
$ cat prices.txt
Tea 4
Coffee 3
Cake 4
Bun 2
```

`git cherry-pick`, `git revert`, `git rebase` and `git pull` all merge
underneath, and take `-X`, and all but `cherry-pick` and `revert` take `-s` too
(Chapters 31 to 33 and 42). During a rebase or a cherry-pick, remember that
"ours" is the branch you are replaying onto (Chapter 26).

```console
$ git switch -q -C try main
$ git show $(git merge-tree --write-tree -X theirs main sale):prices.txt
Tea 4
Coffee 3
Cake 4
Bun 2
$ git merge-tree --write-tree --name-only main sale
f2b3d1b3ae385b2cc1c7fde31bf094285ac0f6f0
prices.txt

Auto-merging prices.txt
CONFLICT (content): Merge conflict in prices.txt
```

`git merge-tree --write-tree` (Chapter 25) does a merge without touching your
branch or files, and takes `-X` as well, so it can answer "what would this
option give me?" before you commit to it. `$( )` passes its output, the tree
hash, to `git show`. Without the option the same merge conflicts: it exits 1,
lists the conflicted files, and prints the messages after a blank line.

> **Since Git 2.43.** `git merge-tree -X`.

## Strategies and their neighbours

| Command | Result |
|---|---|
| `git merge -s ours <branch>` | Our tree, unchanged; the branch is recorded as merged and nothing of it arrives |
| `git merge -X ours <branch>` | A real merge; only the conflicting hunks go our way |
| `git merge -X theirs <branch>` | A real merge; only the conflicting hunks go their way |
| `git checkout --ours <path>` | During a conflict, our whole version of one file (Chapter 26) |
| `git merge-file --ours` | Outside a merge, our side of each conflict in three files (Chapter 26) |
| `git restore --source=<branch> <path>` | Not a merge at all: the file as that branch has it (Chapter 14) |

For the everyday cases, the order to reach for things: let the default strategy
run; if it conflicts, read the conflict (Chapter 26); use `-X` only when you can
say why every clash in the merge goes one way; use `-s ours` only to close a
branch; leave `resolve` and `octopus` for the rare cases that name them.

## The settings

| Setting | Effect |
|---|---|
| `merge.renames` | `false` turns rename detection off; `true` is the default, taken from `diff.renames` |
| `merge.renameLimit` | How many files the exhaustive rename search may consider; defaults to `diff.renameLimit`, and to 7000 if neither is set |
| `merge.directoryRenames` | `conflict` (the default), `true` or `false`: what happens to a file added to a directory the other side renamed |
| `merge.renormalize` | Check every version in and out before merging, so old line endings or filters do not conflict (Chapter 66) |
| `merge.verbosity` | 0 to 5: how much the strategy prints |
| `merge.default` | The merge driver for files whose `merge` attribute is unspecified |
| `merge.<driver>.name` | A description of a custom driver |
| `merge.<driver>.driver` | The command a custom driver runs |
| `merge.<driver>.recursive` | The driver to use when merging the common ancestors |
| `pull.twohead` | The strategy `git pull` uses for one branch (Chapter 42) |
| `pull.octopus` | The strategy `git pull` uses for several (Chapter 42) |
| `GIT_MERGE_VERBOSITY` | An environment variable that overrides `merge.verbosity` |

`merge.conflictStyle`, `merge.tool` and the rest of the conflict settings are in
Chapter 26; `merge.ff`, `merge.log` and the other settings about the merge
commit itself are in Chapter 25.

<!-- no-example: merge.renameLimit
     tested at merge.renameLimit=1 on the rename examples here: the merge and
     every line of its output were identical, because the limit only bounds the
     exhaustive search for inexact renames, which needs far more files than any
     example in this book has -->
