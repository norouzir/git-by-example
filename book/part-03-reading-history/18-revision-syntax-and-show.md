# Chapter 18. Revision Syntax and show

## What it is

Almost every Git command that takes a commit accepts more than a hash. `HEAD~2`
is the commit two before the current one, `v1.0^{tree}` is the tree of the
release, `main:README.md` is a file as it was on `main`, and `@{upstream}` is the
branch you pull from. Git's documentation calls these *revisions*, and the rules
for writing them *revision syntax*. A set of commits written with `..` or `...`
is a *revision range*. This chapter covers every form, and every command in the
book that takes a `<commit>` accepts them.

`git show` is the command that prints whatever a name refers to: a commit with
the changes it made, a tag, the list of files in a tree, or the content of a
file. That makes it the natural way to try a name out, and most examples here
use it.

The chapter relies on a few terms from earlier. An *object* is a commit, tree,
blob or annotated tag (Chapter 6). A *ref* is a name such as a branch or tag that
points at an object (Chapter 7). Commits have *parents*, and a merge has two or
more (Chapter 6).

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What is a "revision", and where can I use one?](#what-it-is)

**[Synopsis](#synopsis)**

- [What can I type after `git show`, and what are all the ways to name a commit?](#synopsis)

**[Options at a glance](#options-at-a-glance)**

- [Which options does `git show` take, and where is each explained?](#options-at-a-glance)

**[Reading the output](#reading-the-output)**

- [What does `git show` print, and for which commit?](#reading-the-output)

**[Tags, trees and files](#tags-trees-and-files)**

- [What does `git show` print for a tag, a directory or a file?](#tags-trees-and-files)
- [Why does `git show` on my tag print no tag message?](#tags-trees-and-files)

**[Merge commits](#merge-commits)**

- [Why does `git show` print no changes for my merge?](#merge-commits)
- [How do I see what a merge brought in, or how its conflict was resolved?](#merge-commits)

**[Several objects at once](#several-objects-at-once)**

- [Can I show several commits in one command, and in what order do they come?](#several-objects-at-once)
- [Does `git show` accept a range such as `A..B`?](#several-objects-at-once)

**[Less output, or a different shape](#less-output-or-a-different-shape)**

- [How do I show only the commit message, or only the changes?](#less-output-or-a-different-shape)
- [Are `-s`, `--no-patch` and `-q` the same in `git show`?](#less-output-or-a-different-shape)
- [How do I see only what a commit did to one file?](#less-output-or-a-different-shape)

**[Naming a commit](#naming-a-commit)**

- [How short can a hash be?](#naming-a-commit)
- [Can I use the output of `git describe` as a name?](#naming-a-commit)
- [What does `@` mean?](#naming-a-commit)
- [A branch and a tag have the same name. Which one does Git use?](#when-a-branch-and-a-tag-share-a-name)
- [Git says my short hash is ambiguous. What now?](#when-a-short-hash-is-ambiguous)
- [What do `ORIG_HEAD`, `FETCH_HEAD` and `MERGE_HEAD` mean?](#head-and-the-other-special-names)
- [What does `origin` on its own mean?](#head-and-the-other-special-names)

**[Parents and ancestors](#parents-and-ancestors)**

- [What is the difference between `HEAD^` and `HEAD~`?](#parents-and-ancestors)
- [How do I name the second parent of a merge?](#parents-and-ancestors)
- [What does `HEAD~2^2` mean?](#parents-and-ancestors)
- [Why does `HEAD~10` say "unknown revision"?](#parents-and-ancestors)

**[Tags and object types](#tags-and-object-types)**

- [How do I get from a tag to the commit it points at?](#tags-and-object-types)
- [What do `^{}`, `^{commit}`, `^{tree}` and `^0` mean?](#tags-and-object-types)
- [How do I check that a name really is an annotated tag?](#tags-and-object-types)
- [What happens with a tag that points at another tag?](#tags-and-object-types)

**[A commit by its message](#a-commit-by-its-message)**

- [Can I name a commit by words in its message instead of its hash?](#a-commit-by-its-message)
- [How do I find the newest commit that does not mention something?](#a-commit-by-its-message)

**[A file or directory in a commit](#a-file-or-directory-in-a-commit)**

- [How do I see a file as it was in an older commit, without checking it out?](#a-file-or-directory-in-a-commit)
- [I'm in a subdirectory and `HEAD:file` says the path does not exist. Why?](#a-file-or-directory-in-a-commit)
- [How do I list the files in a commit?](#a-file-or-directory-in-a-commit)
- [How do I save an old version of a file under another name?](#a-file-or-directory-in-a-commit)

**[The index and conflict stages](#the-index-and-conflict-stages)**

- [How do I see the staged version of a file?](#the-index-and-conflict-stages)
- [During a conflict, how do I see my version, their version and the original?](#the-index-and-conflict-stages)

**[Earlier positions, upstream and push](#earlier-positions-upstream-and-push)**

- [How do I name where a branch was before, or at a certain time?](#earlier-positions-upstream-and-push)
- [What is the difference between `HEAD@{1}` and `@{1}`?](#earlier-positions-upstream-and-push)
- [How do I name the branch I was on before this one?](#earlier-positions-upstream-and-push)
- [What are `@{upstream}` and `@{push}`, and when do they differ?](#earlier-positions-upstream-and-push)

**[Ranges](#ranges)**

- [What does `A..B` mean exactly, and what if I leave one side out?](#two-dots-and-three-dots)
- [What is the difference between `A..B` and `A...B`?](#two-dots-and-three-dots)
- [Why does `git log ..` say the path is outside the repository?](#two-dots-and-three-dots)
- [Can I give two ranges to `git log` at once?](#two-dots-and-three-dots)
- [What do `^@`, `^!` and `^-` mean?](#a-commit-and-its-parents)

**[The two sides of a three-dot range](#the-two-sides-of-a-three-dot-range)**

- [How do I see which side each commit in `A...B` comes from?](#the-two-sides-of-a-three-dot-range)
- [How do I leave out commits that were cherry-picked to the other branch?](#the-two-sides-of-a-three-dot-range)
- [What is the difference between `--cherry-pick`, `--cherry-mark` and `--cherry`?](#the-two-sides-of-a-three-dot-range)
- [What does `--boundary` add?](#the-two-sides-of-a-three-dot-range)

**[Dots in git log and in git diff](#dots-in-git-log-and-in-git-diff)**

- [Why do `..` and `...` mean different things in `git diff`?](#dots-in-git-log-and-in-git-diff)

**[Typing revisions in other shells](#typing-revisions-in-other-shells)**

- [`HEAD^` shows the wrong commit in cmd, and `@{u}` is an error in PowerShell. Why?](#typing-revisions-in-other-shells)

**[show and its neighbours](#show-and-its-neighbours)**

- [Should I use `git show`, `git log -p`, `git cat-file` or `git rev-parse`?](#show-and-its-neighbours)

**[The settings](#the-settings)**

- [Which settings change how names are resolved or shown?](#the-settings)

</details>

## Synopsis

```
git show [<options>] [<object>...]
```

| Part | Means |
|---|---|
| `<object>` | Anything named in this chapter: a commit, tag, tree or blob, or a range of commits. Without it, `HEAD` |
| `<options>` | How to print it. `git show` takes the formatting and diff options of `git log` (Chapter 17) |

The ways to name something, each covered below:

| Form | Example | Names | Section |
|---|---|---|---|
| `<hash>` | `98c6775` | the object with that hash | [Naming a commit](#naming-a-commit) |
| `<describe output>` | `v1.0-3-g98c6775` | the commit at the end | [Naming a commit](#naming-a-commit) |
| `<refname>` | `main`, `v1.0`, `origin/main` | what the ref points at | [Naming a commit](#naming-a-commit) |
| `@` | `@` | `HEAD` | [Naming a commit](#naming-a-commit) |
| `<rev>^<n>` | `HEAD^`, `HEAD^2` | the first, or `<n>`th, parent | [Parents and ancestors](#parents-and-ancestors) |
| `<rev>~<n>` | `HEAD~3` | `<n>` generations back, by first parents | [Parents and ancestors](#parents-and-ancestors) |
| `<rev>^{<type>}` | `v1.0^{commit}` | the object of that type the name leads to | [Tags and object types](#tags-and-object-types) |
| `<rev>^{}` | `v1.0^{}` | whatever a tag finally points at | [Tags and object types](#tags-and-object-types) |
| `:/<text>` | `:/nasty bug` | the newest commit whose message matches | [A commit by its message](#a-commit-by-its-message) |
| `<rev>^{/<text>}` | `HEAD^{/fix}` | the same, among the ancestors of `<rev>` | [A commit by its message](#a-commit-by-its-message) |
| `<rev>:<path>` | `HEAD:src/app.py` | a file or directory in that commit | [A file or directory in a commit](#a-file-or-directory-in-a-commit) |
| `:<n>:<path>` | `:src/app.py`, `:2:src/app.py` | a file in the index, at a stage | [The index and conflict stages](#the-index-and-conflict-stages) |
| `<ref>@{<n>}` | `main@{1}` | where the ref was `<n>` moves ago | [Earlier positions, upstream and push](#earlier-positions-upstream-and-push) |
| `<ref>@{<date>}` | `main@{yesterday}` | where the ref was at that time | [Earlier positions, upstream and push](#earlier-positions-upstream-and-push) |
| `@{-<n>}` | `@{-1}` | the branch checked out `<n>` switches ago | [Earlier positions, upstream and push](#earlier-positions-upstream-and-push) |
| `<branch>@{upstream}` | `@{u}` | the branch it pulls from | [Earlier positions, upstream and push](#earlier-positions-upstream-and-push) |
| `<branch>@{push}` | `@{push}` | the branch it would push to | [Earlier positions, upstream and push](#earlier-positions-upstream-and-push) |
| `^<rev>`, `<rev1>..<rev2>`, `<rev1>...<rev2>` | `main..topic` | a set of commits | [Ranges](#ranges) |
| `<rev>^@`, `<rev>^!`, `<rev>^-<n>` | `HEAD^!` | a commit and its parents, as a set | [A commit and its parents](#a-commit-and-its-parents) |

## Options at a glance

| Option | Does | Covered in |
|---|---|---|
| `-s`, `--no-patch` | Show the header and message, not the changes | [Less output, or a different shape](#less-output-or-a-different-shape) |
| `-q`, `--quiet` | The same, in `git show` | [Less output, or a different shape](#less-output-or-a-different-shape) |
| `--oneline`, `--format=<format>`, `--pretty=<format>` | Change how commits and tags are printed | [Less output, or a different shape](#less-output-or-a-different-shape); every format in Chapter 17 |
| `--stat`, and every other diff option | Change how the changes are printed | [Less output, or a different shape](#less-output-or-a-different-shape); Chapter 13 |
| `-- <path>...` | Show only the changes to these paths | [Less output, or a different shape](#less-output-or-a-different-shape) |
| `--cc` | For a merge, a dense combined diff; the default in `git show` | [Merge commits](#merge-commits) |
| `-m` | For a merge, one diff against each parent | [Merge commits](#merge-commits) |
| `--first-parent` | For a merge, a diff against the first parent | [Merge commits](#merge-commits) |
| `--diff-merges=<format>` | Choose the merge format by name | [Merge commits](#merge-commits); every value in Chapter 17 |
| `--remerge-diff` | For a merge, how the result differs from redoing the merge | [Merge commits](#merge-commits) |

These options of `git log` are taught here, because they are about ranges:

| Option | Does | Covered in |
|---|---|---|
| `--left-right` | Mark each commit of `A...B` with `<` or `>` | [The two sides of a three-dot range](#the-two-sides-of-a-three-dot-range) |
| `--left-only`, `--right-only` | List one side of `A...B` | [The two sides of a three-dot range](#the-two-sides-of-a-three-dot-range) |
| `--cherry-mark` | Mark commits with an equivalent on the other side with `=` | [The two sides of a three-dot range](#the-two-sides-of-a-three-dot-range) |
| `--cherry-pick` | Leave out commits with an equivalent on the other side | [The two sides of a three-dot range](#the-two-sides-of-a-three-dot-range) |
| `--cherry` | `--right-only --cherry-mark --no-merges` | [The two sides of a three-dot range](#the-two-sides-of-a-three-dot-range) |
| `--boundary` | Also list the excluded commits at the edge of the range | [The two sides of a three-dot range](#the-two-sides-of-a-three-dot-range) |

## Reading the output

The first examples use a small repository: a menu with a tag `v1`, a branch
`lunch` about to be merged, and two commits on `main` after the tag.

```console
$ git show
commit 142039048f91e28a9c12c56d67d4252cbdb0bc1a
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 13:00:00 2026 +0000

    Choose the salad

diff --git a/menu.txt b/menu.txt
index fec0125..f3aba04 100644
--- a/menu.txt
+++ b/menu.txt
@@ -6,4 +6,4 @@ bread
 -
 -
 -
-salad
+green salad
$ git show HEAD~2
commit 2510ac37c9d2d2fef4947976a9af5eb0c5bfbe9e
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 09:00:00 2026 +0000

    Start the menu

diff --git a/menu.txt b/menu.txt
new file mode 100644
index 0000000..41d4fa0
--- /dev/null
+++ b/menu.txt
@@ -0,0 +1,5 @@
+soup
+-
+-
+-
+bread
```

Without a name, `git show` shows `HEAD`. For a commit it prints the same header
as `git log` (Chapter 17), then the changes the commit made compared with its
parent, as a diff (Chapter 13). `HEAD~2` is two commits back, explained in
[Parents and ancestors](#parents-and-ancestors). It was the first commit, with
no parent, so every line it added shows as new.

## Tags, trees and files

```console
$ git show v1
tag v1
Tagger: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 11:00:00 2026 +0000

First menu

Printed on Monday.

commit daac6ef4cb64be0dd906be73eb526ef4dcad8836
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 10:00:00 2026 +0000

    Add salad and notes

diff --git a/menu.txt b/menu.txt
index 41d4fa0..fec0125 100644
--- a/menu.txt
+++ b/menu.txt
@@ -3,3 +3,7 @@ soup
 -
 -
 bread
+-
+-
+-
+salad
diff --git a/notes/today.txt b/notes/today.txt
new file mode 100644
index 0000000..be4b30f
--- /dev/null
+++ b/notes/today.txt
@@ -0,0 +1 @@
+busy
$ git show v1^{tree}
tree v1^{tree}

menu.txt
notes/
$ git show HEAD:notes
tree HEAD:notes

today.txt
$ git show HEAD:menu.txt
soup
-
-
-
bread
-
-
-
green salad
$ git show -s draft
commit daac6ef4cb64be0dd906be73eb526ef4dcad8836
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 10:00:00 2026 +0000

    Add salad and notes
```

| Object | `git show` prints |
|---|---|
| a commit | its header, message and diff |
| an annotated tag | the tag's own header and message, then the object it points at, shown the same way |
| a tree | `tree <name>`, a blank line, and the names inside it, with `/` after each directory |
| a blob | its content, exactly |

`v1^{tree}` is the tree of the tagged commit and `HEAD:notes` the directory
`notes` in the current commit; both forms come later in this chapter. `draft` is
a lightweight tag, which has no object of its own (Chapter 6), so `git show`
printed the commit directly, with no tag header. `-s` left out the diff.

## Merge commits

`lunch` changed the first line of the menu and `main` the last, so merging them
needed no help:

```console
$ git show
commit 05993c57b094ef35168d47a1d2a18b926b9d87ca
Merge: 1420390 7a6c603
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 14:00:00 2026 +0000

    Merge branch 'lunch'

$ git show -m --stat --oneline
05993c5 (from 1420390) Merge branch 'lunch'
 menu.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
05993c5 (from 7a6c603) Merge branch 'lunch'
 menu.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git show --first-parent --stat --oneline
05993c5 Merge branch 'lunch'
 menu.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git show --diff-merges=off --oneline
05993c5 Merge branch 'lunch'
```

For a merge, `git show` prints a *dense combined diff* by default, as Git's
documentation says, which leaves out every hunk where the result simply took one
parent's version. In a merge without conflicts that is every hunk, so nothing
is printed. That is not "the merge changed nothing".

`-m` shows the merge against each parent in turn, and `--first-parent` against
the first only, which is what the merge brought into `main`. `--stat` gives a
summary instead of lines (Chapter 13).

When a person had to resolve a conflict, the combined diff shows their work.
`dinner` changed the same line as `main`, and the conflict was resolved by
writing `green salad or steak`:

```console
$ git show
commit c9bfc467ada4986ff50669b0ce99adc4e216c6fe
Merge: 05993c5 184b408
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 16:00:00 2026 +0000

    Merge branch 'dinner'

diff --cc menu.txt
index 3b3afa6,54b0b39..c7a5ab8
--- a/menu.txt
+++ b/menu.txt
@@@ -6,4 -6,4 +6,4 @@@ brea
  -
  -
  -
- green salad
 -steak
++green salad or steak
$ diff <(git show) <(git show --cc) && echo same
same
$ git show --remerge-diff --oneline
c9bfc46 Merge branch 'dinner'
diff --git a/menu.txt b/menu.txt
remerge CONFLICT (content): Merge conflict in menu.txt
index fbd83d3..c7a5ab8 100644
--- a/menu.txt
+++ b/menu.txt
@@ -6,8 +6,4 @@ bread
 -
 -
 -
-<<<<<<< 05993c5 (Merge branch 'lunch')
-green salad
-=======
-steak
->>>>>>> 184b408 (Steak for dinner)
+green salad or steak
```

The combined diff has one column of markers per parent: `green salad` came from
the first, `steak` from the second, and `++` marks a line in neither, the
resolution. `diff` printed nothing when comparing `git show` with `git show --cc`,
so `same` appeared: they are the same; `<(...)` hands a command's output to
`diff` as a file, in bash. `--remerge-diff` shows the conflict as Git met it and
what replaced it. Chapter 17 has every merge format, and Chapter 26 reads
combined diffs in detail.

## Several objects at once

```console
$ git show -s --oneline HEAD~2 HEAD~3
daac6ef Add salad and notes
2510ac3 Start the menu
$ git show -s --oneline HEAD~3 HEAD~2
2510ac3 Start the menu
daac6ef Add salad and notes
$ git show -s --oneline HEAD~2 HEAD~2 main~2
daac6ef Add salad and notes
$ git show -s --oneline HEAD~2 HEAD:notes
daac6ef Add salad and notes

tree HEAD:notes

today.txt
$ git show -s --oneline HEAD~3..HEAD^
1420390 Choose the salad
daac6ef Add salad and notes
$ git show --oneline nosuch
fatal: ambiguous argument 'nosuch': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
```

Several names are shown in the order given, and objects of different kinds can
be mixed. A commit named twice is shown once, even under two different names:
`HEAD~2` and `main~2` are the same commit here. That makes `git show` a quick way
to check whether two names agree, and the examples below use it that way.

A range is walked like `git log` would walk it, newest first. `-s` leaves out
the diff and `--oneline` prints one line per commit, as in Chapter 17.

## Less output, or a different shape

```console
$ git show -s HEAD~1
commit 142039048f91e28a9c12c56d67d4252cbdb0bc1a
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 13:00:00 2026 +0000

    Choose the salad
$ git show --no-patch --oneline HEAD~1
1420390 Choose the salad
$ git show -q --oneline HEAD~1
1420390 Choose the salad
$ git show --stat --oneline HEAD~2
daac6ef Add salad and notes
 menu.txt        | 4 ++++
 notes/today.txt | 1 +
 2 files changed, 5 insertions(+)
$ git show --format= HEAD~1
diff --git a/menu.txt b/menu.txt
index fec0125..f3aba04 100644
--- a/menu.txt
+++ b/menu.txt
@@ -6,4 +6,4 @@ bread
 -
 -
 -
-salad
+green salad
$ git show -s --format='%h %an %s' HEAD~2
daac6ef Ada Lovelace Add salad and notes
```

`-s`, `--no-patch` and, in `git show`, `-q` all leave the diff out. (In
`git log`, `-q` has no effect; Chapter 17.) An empty `--format=` leaves the
header out instead, which prints the diff alone. Every format and placeholder in
Chapter 17 works here.

```console
$ git show --oneline HEAD~2 -- notes
daac6ef Add salad and notes
diff --git a/notes/today.txt b/notes/today.txt
new file mode 100644
index 0000000..be4b30f
--- /dev/null
+++ b/notes/today.txt
@@ -0,0 +1 @@
+busy
$ git show --oneline HEAD~2 -- nosuch.txt
daac6ef Add salad and notes
$ git show -s --oneline v1
tag v1

First menu

Printed on Monday.
daac6ef Add salad and notes
```

Paths after `--` limit the diff to those files; a path the commit did not touch
leaves just the header. `--oneline` on a tag shortens only the commit it points
at: the tag's name and message are still printed in full, without the tagger.

## Naming a commit

The next examples use a repository with a remote, three tags on `Add the app`,
and a branch `idea` besides `main`:

```console
$ git log --oneline --decorate --all
98c6775 (HEAD -> main) Add excitement
02362fb (idea) Try a nasty hack
59c45ac (origin/main) Write the guide
5ff4c4e Fix nasty bug in greeting
f97902a (tag: v1.0-approved, tag: v1.0, tag: first-app) Add the app
c2f30bb Add README
$ git show -s --format=%s 98c6775ad535481da060123c2220a747423d5214
Add excitement
$ git show -s --format=%s 98c6775
Add excitement
$ git show -s --format=%s 98c6
Add excitement
$ git show -s --format=%s 98c
fatal: ambiguous argument '98c': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
$ git describe
v1.0-3-g98c6775
$ git show -s --format=%s v1.0-3-g98c6775
Add excitement
$ git show -s --format=%s v9.9-99-g98c6775
Add excitement
$ git show -s --format=%s main
Add excitement
$ git show -s --format=%s origin/main
Write the guide
$ git show -s --format=%s @
Add excitement
```

`-s --format=%s` prints only the subject, which is all these examples need.

| Form | Rule |
|---|---|
| a full hash | always works |
| the start of a hash | works if no other object's hash starts the same way, and it is at least 4 characters long |
| `git describe` output | `<tag>-<count>-g<hash>`; Git uses only the hash after `-g` |
| a ref name | a branch, tag or remote-tracking branch, as found by the rules below |
| `@` | `HEAD` |

`98c` failed because a short hash needs at least four characters. `git describe`
names a commit by the nearest tag, and its output works as a name, but the tag
and count are not checked: `v9.9-99-g98c6775` named the same commit though no
tag `v9.9` exists. Chapter 22 covers `git describe`.

### When a branch and a tag share a name

`first-app` is a tag on `Add the app`. Here a branch `first-app` is created on
`Add README` as well:

```console
$ git show -s --format=%s first-app
warning: refname 'first-app' is ambiguous.
Add the app
$ git show -s --format=%s heads/first-app
Add README
$ git show -s --format=%s tags/first-app
Add the app
$ git show -s --format=%s refs/heads/first-app
Add README
$ git -c core.warnAmbiguousRefs=false show -s --format=%s first-app
Add the app
```

Git warned and used the tag. It tries these places in order and takes the first
that exists, as its documentation lists them:

| Order | `<name>` means | Example |
|---|---|---|
| 1 | a file directly in `.git`, such as `HEAD` or `ORIG_HEAD` | `HEAD` |
| 2 | `refs/<name>` | `heads/main` is `refs/heads/main` |
| 3 | `refs/tags/<name>` | `v1.0` |
| 4 | `refs/heads/<name>` | `main` |
| 5 | `refs/remotes/<name>` | `origin/main` |
| 6 | `refs/remotes/<name>/HEAD` | `origin`, meaning `origin/HEAD` |

A longer name, `heads/first-app` or `refs/heads/first-app`, removes the doubt.
`core.warnAmbiguousRefs=false` silences the warning without changing the
choice. Giving a branch and a tag the same name is best avoided (Chapter 7).

### When a short hash is ambiguous

A different repository, with twelve commits and 8,000 small files, has a commit
and a file whose hashes both start with `22b0`:

```console
$ git show 22b0
error: short object ID 22b0 is ambiguous
hint: The candidates are:
hint:   22b0224 commit 2026-01-05 - Count to 1
hint:   22b0356 blob
fatal: ambiguous argument '22b0': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
$ git show -s --format=%s 22b0^{commit}
Count to 1
$ git log -1 --format=%s 22b0
Count to 1
$ git -c core.disambiguate=commit show -s --format=%s 22b0
Count to 1
```

Git lists the candidates. Adding `^{commit}` asks for a commit, which only one
of them is. `git log` needs a commit anyway, so it chose without being told.
`core.disambiguate` sets that preference for every command; it is not in Git's
documentation, but Git's source accepts `none`, `commit`, `committish`, `tree`,
`treeish` and `blob`. The lasting fix is a longer prefix. Git chooses how many
characters to print from the number of objects, 7 in these small repositories,
so that short hashes stay unique for a while (`core.abbrev`, Chapter 17).

### HEAD and the other special names

```console
$ cd ../clone
$ git show -s --format=%s origin
Write the guide
$ git show -s --format=%s origin/HEAD
Write the guide
$ git fetch -q && git show -s --format=%s FETCH_HEAD
Write the guide
$ cd ../app
```

In a clone, `origin` alone is `origin/HEAD`, the remote's default branch
(Chapter 9), and `FETCH_HEAD` is what the last fetch brought.

```console
$ git reset --hard HEAD~1
HEAD is now at 59c45ac Write the guide
$ git show -s --format=%s ORIG_HEAD
Add excitement
$ git reset --hard ORIG_HEAD
HEAD is now at 98c6775 Add excitement
```

`ORIG_HEAD` held the commit `git reset` moved away from, so resetting to it undid
the reset. The names Git's documentation lists:

| Name | Holds | Chapter |
|---|---|---|
| `HEAD` | the commit you are on | 7 |
| `ORIG_HEAD` | where `HEAD` was before `git reset`, `git merge`, `git rebase` or `git am` moved it | 30 |
| `FETCH_HEAD` | what the last `git fetch` fetched | 41 |
| `MERGE_HEAD` | the commits being merged, during a merge | 26 |
| `AUTO_MERGE` | a tree with the merge result, conflict markers included, during a conflict | 26 |
| `REBASE_HEAD` | the commit a rebase stopped at | 33 |
| `CHERRY_PICK_HEAD` | the commit being cherry-picked | 32 |
| `REVERT_HEAD` | the commit being reverted | 31 |
| `BISECT_HEAD` | the commit to test, in `git bisect --no-checkout` | 20 |

`MERGE_HEAD` and `AUTO_MERGE` appear in [The index and conflict
stages](#the-index-and-conflict-stages).

## Parents and ancestors

Git's documentation explains parents with a drawing of ten commits, `A` to `J`.
This repository has exactly that shape, with each commit's subject being its
letter and a tag of the same name. `A` merges `B` and `C`; `B` merges `D`, `E`
and `F`:

```console
$ git log --graph --format=%s A
*   A
|\  
| * C
| |   
|  \  
*-. | B
|\ \| 
| | *   F
| | |\  
| | | * J
| | * I
| * E
*   D
|\  
| * H
* G
```

The graph drawing is hard to read with a three-parent merge; the table after the
next examples gives the relationships directly.

```console
$ git show -s --format=%s A^
B
$ git show -s --format=%s A^2
C
$ git show -s --format=%s A~2
D
$ git show -s --format=%s B^2
E
$ git show -s --format=%s B^3
F
$ git show -s --format=%s A~3
G
$ git show -s --format=%s A~2^2
H
$ git show -s --format=%s F^
I
$ git show -s --format=%s F^2
J
$ git show -s --format=%s A^0
A
```

| Suffix | Means |
|---|---|
| `^` | the first parent |
| `^<n>` | the `<n>`th parent; only a merge has more than one |
| `^0` | the commit itself |
| `~` | the first parent, the same as `^` |
| `~<n>` | `<n>` generations back, always through first parents |

They chain from left to right: `A~2^2` is `A~2`, which is `D`, then its second
parent, `H`. `^` picks among parents, and `~` goes back in time. On a commit with
one parent they agree, and they differ only after a merge: `A^2` is `C`, and
`A~2` is `D`.

Different spellings of one commit, each command printing one line because
`git show` lists a commit once:

```console
$ git show -s --format=%s A^ A^1 A~1
B
$ git show -s --format=%s A^^ A^1^1 A~2
D
$ git show -s --format=%s A^^^ A^1^1^1 A~3
G
$ git show -s --format=%s A^^2 B^2
E
$ git show -s --format=%s A~2^2 D^2 B^^2 A^^^2
H
$ git show -s --format=%s A^^3^2 B^3^2 F^2
J
$ git show -s --format=%s A^3
fatal: ambiguous argument 'A^3': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
$ git show -s --format=%s A~4
fatal: ambiguous argument 'A~4': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
$ git show A~2^2:name.txt
H
```

`A` has two parents, so `A^3` does not exist, and `G` has none, so `A~4` does not
either. Both give the same "unknown revision" error as a misspelled name.
Suffixes work anywhere a commit is expected, including before `:` for a file,
which is [A file or directory in a commit](#a-file-or-directory-in-a-commit).

## Tags and object types

Back in the app, `v1.0` is an annotated tag, `first-app` a lightweight tag, and
`v1.0-approved` an annotated tag that points at the tag `v1.0` rather than at a
commit. `git cat-file -t` prints the type of the object a name refers to
(Chapter 6):

```console
$ git cat-file -t v1.0
tag
$ git cat-file -t v1.0^{}
commit
$ git cat-file -t v1.0^{commit}
commit
$ git cat-file -t v1.0^0
commit
$ git cat-file -t v1.0^{tree}
tree
$ git cat-file -t v1.0^{tag}
tag
$ git cat-file -t v1.0^{object}
tag
$ git cat-file -t first-app^{object}
commit
$ git cat-file -t first-app^{tag}
error: first-app^{tag}: expected tag type, but the object dereferences to tree type
fatal: Not a valid object name first-app^{tag}
$ git cat-file -t HEAD^{blob}
error: HEAD^{blob}: expected blob type, but the object dereferences to tree type
fatal: Not a valid object name HEAD^{blob}
```

An annotated tag is an object of its own, so `v1.0` names the tag, not the
commit. Going from a name to the object it leads to is *dereferencing*, and
doing it again and again through tags is what Git's glossary calls *peeling*.
The suffixes say how far to go:

| Suffix | Means |
|---|---|
| `^{commit}` | follow until a commit; an error if there is none |
| `^0` | the same as `^{commit}` |
| `^{tree}` | follow until a tree: a commit's tree, or a tagged commit's |
| `^{blob}` | follow until a blob; an error, since a commit leads to a tree |
| `^{tag}` | the name must be an annotated tag; an error otherwise |
| `^{object}` | the name must exist; nothing is followed |
| `^{}` | follow tags until something that is not a tag |

`first-app^{tag}` failed because a lightweight tag is only a ref to a commit
(Chapter 6). Both error messages mention a tree, although `first-app` and `HEAD`
are commits.

`^{}` and `^{commit}` agree on a tag of a commit. They differ on a tag of a tree
or a blob, where `^{}` stops at that object and `^{commit}` fails, as Git's
documentation describes. `^0` is its shorthand for `^{commit}`.

A tag of a tag is followed all the way:

```console
$ git show -s --format=%s v1.0-approved
tag v1.0-approved
Tagger: Ada Lovelace <ada@example.com>

Approved for release

tag v1.0
Tagger: Ada Lovelace <ada@example.com>

Release 1.0
Add the app
$ git cat-file -t v1.0-approved^{tag}
tag
$ git cat-file -t v1.0-approved^{}
commit
```

`git show` printed both tags and then the commit. Creating such a tag prints a
hint from Git asking whether that was meant, because it rarely is.

## A commit by its message

```console
$ git show -s --format=%s ':/nasty'
Try a nasty hack
$ git show -s --format=%s 'HEAD^{/nasty}'
Fix nasty bug in greeting
$ git show -s --format=%s ':/^Add'
Add excitement
$ git show -s --format=%s 'HEAD~2^{/^Add}'
Add the app
$ git show -s --format=%s ':/!-Add'
Try a nasty hack
$ git show -s --format=%s ':/Nasty'
fatal: ambiguous argument ':/Nasty': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
```

| Form | Names |
|---|---|
| `:/<regex>` | the newest commit, reachable from any ref, whose message matches |
| `<rev>^{/<regex>}` | the newest commit reachable from `<rev>` whose message matches |
| `:/!-<regex>` | the newest commit whose message does not match |
| `:/!!<regex>` | a message matching `!` followed by `<regex>` |

`:/nasty` found `Try a nasty hack` on the branch `idea`, because it searches from
every ref; `HEAD^{/nasty}` searched only the history of `HEAD`. The text is a
regular expression matched anywhere in the message, and case matters: `Nasty`
found nothing. The quotes keep the shell from splitting text with spaces, and
Git's documentation reserves every other `:/!` form for future use.

## A file or directory in a commit

```console
$ git show HEAD:src/app.py
print('hello, world!')
$ git show HEAD~2:src/app.py
print('hello, world')
$ git show HEAD:
tree HEAD:

README.md
docs/
src/
$ git show HEAD:src
tree HEAD:src

app.py
$ git show HEAD:nosuch.txt
fatal: path 'nosuch.txt' does not exist in 'HEAD'
$ git show HEAD~3:docs/guide.md
fatal: path 'docs/guide.md' exists on disk, but not in 'HEAD~3'
$ git show HEAD^{tree}:README.md
# App
```

`<rev>:<path>` names the file or directory at that path in the commit, without
touching the working tree. An empty path, `HEAD:`, is the top directory. The
part before the colon can be any commit or tree, so `HEAD^{tree}:README.md`
works too.

Paths are counted from the top of the repository, even in a subdirectory, unless
they start with `./` or `../`:

```console
$ cd src
$ git show HEAD:app.py
fatal: path 'src/app.py' exists, but not 'app.py'
hint: Did you mean 'HEAD:src/app.py' aka 'HEAD:./app.py'?
$ git show HEAD:./app.py
print('hello, world!')
$ git show HEAD:../README.md
# App
$ cd ..
```

To save an old version to a file, redirect the output:
`git show HEAD~2:src/app.py > old.py`. Chapter 14 restores files with
`git restore --source` instead.

## The index and conflict stages

A colon with nothing before it means the index, the staging area (Chapter 5).
Here `src/app.py` has one change staged and another not yet staged:

```console
$ git show :src/app.py
print('staged')
$ git show :0:src/app.py
print('staged')
$ git show :1:src/app.py
fatal: path 'src/app.py' is in the index, but not at stage 1
hint: Did you mean ':0:src/app.py'?
$ git show HEAD:src/app.py
print('hello, world!')
```

During a merge conflict the index holds up to three versions of a file, called
*stages*, and the plain one is gone:

```console
$ git merge polite
Auto-merging src/app.py
CONFLICT (content): Merge conflict in src/app.py
Automatic merge failed; fix conflicts and then commit the result.
$ git show :1:src/app.py
print('hello, world')
$ git show :2:src/app.py
print('hello, world!')
$ git show :3:src/app.py
print('hello, world, please')
$ git show :src/app.py
fatal: path 'src/app.py' is in the index, but not at stage 0
hint: Did you mean ':1:src/app.py'?
$ git show -s --format=%s MERGE_HEAD
Be polite
$ git cat-file -t AUTO_MERGE
tree
$ git show AUTO_MERGE:src/app.py
<<<<<<< HEAD
print('hello, world!')
=======
print('hello, world, please')
>>>>>>> polite
```

| Name | Is |
|---|---|
| `:<path>`, `:0:<path>` | the file in the index, when there is no conflict |
| `:1:<path>` | the common ancestor's version |
| `:2:<path>` | your version: the branch you are on |
| `:3:<path>` | their version: the branch being merged |

`MERGE_HEAD` is the commit being merged, and `AUTO_MERGE` a tree holding what Git
wrote to the working tree, conflict markers included. Chapter 26 uses all of
these to resolve conflicts.

## Earlier positions, upstream and push

Git keeps a *reflog* for `HEAD` and for each branch: a list of where it pointed,
newest first (Chapter 36). `@{...}` after a name reads it:

```console
$ git reflog -3 main
98c6775 main@{0}: commit: Add excitement
59c45ac main@{1}: commit: Write the guide
5ff4c4e main@{2}: commit: Fix nasty bug in greeting
$ git reflog -3
98c6775 HEAD@{0}: commit: Add excitement
59c45ac HEAD@{1}: checkout: moving from idea to main
02362fb HEAD@{2}: commit: Try a nasty hack
$ git show -s --format=%s main@{1}
Write the guide
$ git show -s --format=%s @{1}
Write the guide
$ git show -s --format=%s main@{2}
Fix nasty bug in greeting
$ git show -s --format=%s HEAD@{2}
Try a nasty hack
$ git show -s --format=%s @{99}
fatal: log for 'main' only has 5 entries
```

`main@{2}` is where `main` was two moves ago. `@{1}` without a name means the
current branch, `main`, not `HEAD`: `HEAD` also moves when you switch branches,
so `HEAD@{2}` was the commit on `idea`, where `main` never was.

It is 15:00 in this repository, an hour after the last commit:

```console
$ git show -s --format=%s 'main@{3 hours ago}'
Write the guide
$ git show -s --format=%s 'main@{2026-01-05 10:30}'
Add the app
$ git show -s --format=%s 'main@{last year}'
warning: log for 'main' only goes back to Mon, 5 Jan 2026 09:00:00 +0000
Add README
```

A date in braces names where the branch was at that time. Git's documentation
gives `yesterday`, `1 month 2 weeks 3 days 1 hour 1 second ago` and
`1979-02-26 18:30:00` as examples. It is about your own reflog, not about when commits were
written, and a reflog is local and expires (Chapter 36). Before the oldest entry,
Git warns and uses it.

```console
$ git switch idea
Switched to branch 'idea'
$ git show -s --format=%s @{-1}
Add excitement
$ git show -s --format=%s @{upstream}
fatal: no upstream configured for branch 'idea'
$ git switch -
Switched to branch 'main'
Your branch is ahead of 'origin/main' by 1 commit.
  (use "git push" to publish your local commits)
$ git show -s --format=%s @{upstream}
Write the guide
$ git show -s --format=%s @{u}
Write the guide
$ git show -s --format=%s main@{u}
Write the guide
$ git show -s --format=%s @{UPSTREAM}
Write the guide
$ git show -s --format=%s idea@{u}
fatal: no upstream configured for branch 'idea'
$ git show -s --format=%s @{push}
Write the guide
```

`@{-1}` is the branch you were on before the last switch, and `git switch -` is
the same thing, as Git's documentation for `git switch` says (Chapter 24).

The *upstream* of a branch is the remote-tracking branch it pulls from
(Chapter 41). `@{upstream}`, shortened to `@{u}`, names it, for the current
branch or the one before the `@`; `idea` has none. `@{push}` is the branch a
plain `git push` would update, which here is the same.

They differ when you pull from one remote and push to another, such as your own
fork (Chapter 50). This repository gets a second remote, `fork`, whose `main`
holds the `idea` commit:

```console
$ git config push.default
current
$ git config remote.pushDefault
fork
$ git show -s --format=%s @{push}
Try a nasty hack
$ git show -s --format=%s @{upstream}
Write the guide
```

With pushes going to `fork` under the same branch name (Chapter 43), `@{push}`
became `fork/main`, while `@{upstream}` stayed `origin/main`. Git's
documentation says `@{push}` is accepted in capitals; `@{UPSTREAM}` above works
the same way, and so did `@{PUSH}` when tried.

## Ranges

A single name given to `git log` means the commit and everything reachable from
it, as Chapter 17 showed. A *range* adds names to leave out. These examples use a
kitchen repository: `topic` added cake, drinks and tea, and `main` added
specials, then copied the drinks commit with `git cherry-pick` (Chapter 32),
then added pie:

```console
$ git log --oneline --graph --all
* 85f897e Add pie
* 0b3f436 Add drinks
* 76fa371 Add specials
| * 570c8ca Add tea
| * 3573ca4 Add drinks
| * dd4af05 Add cake
|/  
* 4b3ba81 Start the menu
```

### Two dots and three dots

```console
$ git log --oneline main..topic
570c8ca Add tea
3573ca4 Add drinks
dd4af05 Add cake
$ git log --oneline topic..main
85f897e Add pie
0b3f436 Add drinks
76fa371 Add specials
$ git log --oneline main...topic
85f897e Add pie
0b3f436 Add drinks
76fa371 Add specials
570c8ca Add tea
3573ca4 Add drinks
dd4af05 Add cake
$ git log --oneline topic...main
85f897e Add pie
0b3f436 Add drinks
76fa371 Add specials
570c8ca Add tea
3573ca4 Add drinks
dd4af05 Add cake
```

| Range | Commits | Same as |
|---|---|---|
| `A..B` | reachable from `B` but not from `A`: what `B` has that `A` lacks | `^A B` |
| `A...B` | reachable from either but not from both | `A B --not $(git merge-base --all A B)` |

The "same as" column is Git's documentation. Order matters for two dots and not
for three: `main...topic` and `topic...main` listed the same commits. Two dots
answer "what is on `topic` that is not on `main`?"; three dots answer "what
happened on each side since they split?". The copied `Add drinks` counts as two
commits, one per side, because they have different hashes; [The two sides of a
three-dot range](#the-two-sides-of-a-three-dot-range) shows how to spot it.

```console
$ git log --oneline topic..
85f897e Add pie
0b3f436 Add drinks
76fa371 Add specials
$ git log --oneline ..topic
570c8ca Add tea
3573ca4 Add drinks
dd4af05 Add cake
$ git log --oneline ...
$ git log --oneline ..
fatal: ..: '..' is outside repository at '/home/ada/kitchen'
$ git log --oneline .. --
$ git log --oneline main~2..main topic~1..topic
85f897e Add pie
0b3f436 Add drinks
570c8ca Add tea
```

A missing end is `HEAD`, which is `main` here: `topic..` is `topic..HEAD`, "what
have I done since I left `topic`". `...` alone has `HEAD` at both ends and
printed nothing.
Git's documentation says `..` alone is the empty range too, but Git reads it as
the parent directory first, a path outside the repository; after `--` it is a
range again.

Two ranges together are not two lists. Git's documentation explains that
`A..B C..D` is one set: commits reachable from `B` or `D` and from neither `A`
nor `C`. `main~2` is `Add specials`, so it and everything before it were left
out, and `topic~1` is `Add drinks` on `topic`, which removed that commit and
`Add cake`. Only one of the three commits listed belongs to `topic~1..topic`.

### A commit and its parents

Three more suffixes name a commit together with its parents, which matters most
for merges. Back in the graph of `A` to `J`:

```console
$ git log --format=%s D
D
H
G
$ git log --format=%s D F
F
D
J
I
H
G
$ git log --format=%s ^G D
D
H
$ git log --format=%s ^D B
B
F
E
J
I
$ git log --format=%s ^D B C
B
C
F
E
J
I
$ git log --format=%s C
C
F
J
I
$ git log --format=%s B..C
C
$ git log --format=%s B...C
B
C
D
E
H
G
$ git log --format=%s B^-
B
F
E
J
I
$ git log --format=%s C^@
F
J
I
$ git log --format=%s B^@
F
D
E
J
I
H
G
$ git log --format=%s C^!
C
$ git log --format=%s B^!
B
$ git log --format=%s F^! D
F
D
H
G
```

These are the examples of Git's documentation, run for real; the commits come
out newest first rather than in its order, and the sets are the same.

| Form | Means | Same as |
|---|---|---|
| `<rev>^@` | all the parents, and everything they reach, but not the commit | every parent listed by name |
| `<rev>^!` | the commit alone, with all its parents left out | `<rev> ^<rev>^1 ^<rev>^2 ...` |
| `<rev>^-<n>` | the commit and what it brought in through parent `<n>` | `<rev>^<n>..<rev>` |
| `<rev>^-` | the same, for the first parent | `<rev>^1..<rev>` |

`^!` is how to hand a single commit to a command that expects a range. `^-` on a
merge lists the commit and the branch it merged: `B^-` is `B` and what came in
through `E` and `F`.

```console
$ git log --format=%s B^-2
B
F
D
J
I
H
G
$ git log --format=%s A^2^@
F
J
I
$ git log --format=%s A^@^2
fatal: ambiguous argument 'A^@^2': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
```

`B^-2` left out only the second parent `E`. These suffixes end a name: `A^2^@`
is the parents of `C`, but `A^@^2` is not valid, as Git's documentation says.

## The two sides of a three-dot range

In `A...B`, `A` is the *left* side and `B` the *right*:

```console
$ git log --oneline --left-right main...topic
< 85f897e Add pie
< 0b3f436 Add drinks
< 76fa371 Add specials
> 570c8ca Add tea
> 3573ca4 Add drinks
> dd4af05 Add cake
$ git log --oneline --left-only main...topic
85f897e Add pie
0b3f436 Add drinks
76fa371 Add specials
$ git log --oneline --right-only main...topic
570c8ca Add tea
3573ca4 Add drinks
dd4af05 Add cake
$ git log --format='%m %h %s' --left-right main...topic
< 85f897e Add pie
< 0b3f436 Add drinks
< 76fa371 Add specials
> 570c8ca Add tea
> 3573ca4 Add drinks
> dd4af05 Add cake
$ git log --oneline --left-right main..topic
> 570c8ca Add tea
> 3573ca4 Add drinks
> dd4af05 Add cake
```

`--left-right` marks each commit with `<` for the left side or `>` for the right,
and `%m` puts the same mark in a format of your own (Chapter 17). With two dots
every commit is on the right.

Two commits with different hashes can make the same change, as a cherry-picked
copy does. Git compares the changes, not the hashes:

```console
$ git log --oneline --cherry-mark main...topic
+ 85f897e Add pie
= 0b3f436 Add drinks
+ 76fa371 Add specials
+ 570c8ca Add tea
= 3573ca4 Add drinks
+ dd4af05 Add cake
$ git log --oneline --cherry-pick main...topic
85f897e Add pie
76fa371 Add specials
570c8ca Add tea
dd4af05 Add cake
$ git log --oneline --cherry-mark --left-right main...topic
< 85f897e Add pie
= 0b3f436 Add drinks
< 76fa371 Add specials
> 570c8ca Add tea
= 3573ca4 Add drinks
> dd4af05 Add cake
$ git log --oneline --cherry main...topic
+ 570c8ca Add tea
= 3573ca4 Add drinks
+ dd4af05 Add cake
$ git log --oneline --cherry-pick --right-only --no-merges main...topic
570c8ca Add tea
dd4af05 Add cake
$ git cherry -v main topic
+ dd4af057ea1b41811d9cc56629849bfd74bc1150 Add cake
- 3573ca4d82d5c339f9da95ba4ae252e64beeeb90 Add drinks
+ 570c8cac5f1855988c8478360cbc51d15ee122cc Add tea
```

| Option | Does |
|---|---|
| `--cherry-mark` | marks a commit with `=` if the other side has one making the same change, and `+` if not |
| `--cherry-pick` | leaves those `=` commits out |
| `--cherry` | `--right-only --cherry-mark --no-merges`, as Git's documentation defines it |
| `--cherry-pick --right-only --no-merges` | the commits of the right side not yet on the left |

`--cherry` answers "which of my commits are not upstream yet?" when written
`git log --cherry upstream...mybranch`. `git cherry` answers the same question
in its own format, with `-` for commits already applied; Chapter 32 covers it
with `git cherry-pick`.

```console
$ git log --oneline --boundary main..topic
570c8ca Add tea
3573ca4 Add drinks
dd4af05 Add cake
- 4b3ba81 Start the menu
$ git log --oneline --boundary --left-right main...topic
< 85f897e Add pie
< 0b3f436 Add drinks
< 76fa371 Add specials
> 570c8ca Add tea
> 3573ca4 Add drinks
> dd4af05 Add cake
- 4b3ba81 Start the menu
```

`--boundary` adds, marked `-`, the commits just outside the range: here the
commit both branches started from.

## Dots in git log and in git diff

`git diff` also accepts two and three dots, and they do not mean the same thing
(Chapter 13):

```console
$ git diff --stat main..topic
 drinks.txt   | 1 +
 menu.txt     | 1 +
 specials.txt | 2 --
 3 files changed, 2 insertions(+), 2 deletions(-)
$ git diff --stat main...topic
 drinks.txt | 2 ++
 menu.txt   | 1 +
 2 files changed, 3 insertions(+)
```

| Written | In `git log` | In `git diff` |
|---|---|---|
| `A..B` | commits on `B` that are not on `A` | the difference between `A` and `B`, the same as `git diff A B` |
| `A...B` | commits on either side but not both | what `B` changed since it split from `A` |

`git diff main..topic` compared the two ends, so the specials added on `main`
appear as deleted; `git diff main...topic` compared `topic` with the commit
they split from, and showed only `topic`'s work. For `git log` three dots are
the wider set; for `git diff` they are the narrower comparison.

## Typing revisions in other shells

The transcripts use bash, where every form works as shown, with quotes only
around text containing spaces or `!`.

> **Windows.** In cmd.exe, `^` is the escape character and disappears before
> Git sees it. `git log -1 HEAD^` printed the current commit, with no error, and
> `HEAD~1^2` reached Git as `HEAD~12`. Write `HEAD^^` for `HEAD^`, or put the
> name in double quotes: `"HEAD^"`, `"v1.0^{commit}"`. Braces are fine in cmd:
> `@{u}` and `HEAD@{1}` worked unquoted.
>
> In PowerShell 5.1, `^` and `~` are fine and braces are not. `@{u}` on its own
> is a PowerShell syntax error, "Missing '=' operator after key in hash
> literal". `HEAD@{1}` reached Git as `HEAD@` and failed, and `v1.0^{commit}`
> made Git fail with an unrelated error about options. Put these names in single
> quotes: `'@{u}'`, `'HEAD@{1}'`, `'v1.0^{commit}'`.
>
> Both shells were tried directly, outside the sandbox, on the repository of
> these examples.

## show and its neighbours

| Command | Prints | Use it when |
|---|---|---|
| `git show <commit>` | one commit, as a person reads it, with its diff; also tags, trees and files | you want to look at something |
| `git log -p -1 <commit>` | the same header and diff; nothing by default for a merge | you are already using log options (Chapter 17) |
| `git diff <commit>^!` | the commit's diff alone, without a header | you want to feed the diff to another tool (Chapter 13) |
| `git cat-file -p <object>` | the raw object, as stored | you want exactly what Git stored (Chapter 6) |
| `git rev-parse <name>` | the hash a name stands for | a script needs the hash (Chapter 22) |
| `git describe <commit>` | a name for a commit based on a tag | you want a human-readable version (Chapter 22) |
| `git ls-tree <tree>` | a tree's entries with modes, types and hashes | you want more than names (Chapter 75) |

The same name can be given to all of these, which is the point of revision
syntax.

## The settings

| Setting | Effect |
|---|---|
| `core.warnAmbiguousRefs` | Warn when a name matches more than one ref; `true` by default |
| `core.disambiguate` | Which type of object a short hash should prefer when it is ambiguous; undocumented, see [When a short hash is ambiguous](#when-a-short-hash-is-ambiguous) |
| `core.abbrev` | How long short hashes are printed (Chapter 17) |
| `branch.<name>.remote`, `branch.<name>.merge` | What `@{upstream}` means for a branch (Chapter 41) |
| `remote.pushDefault`, `branch.<name>.pushRemote`, `push.default` | What `@{push}` means (Chapter 43) |
| `format.pretty`, `log.*` | Formats and dates in `git show`, as in `git log` (Chapter 17) |
| `diff.*` | How the diff looks (Chapter 13) |
