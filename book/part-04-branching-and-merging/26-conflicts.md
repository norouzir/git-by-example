# Chapter 26. Conflicts

## What it is

A *conflict* is what Git leaves you when it combines two versions of a file and
cannot decide the result by itself: both sides changed the same lines
differently, one side changed a file the other deleted, or both gave a file
different names. Git does everything it can, stops, and hands you the rest.
This chapter is about seeing what happened, making each file right, and telling
Git it is done.

| Term | Means |
|---|---|
| *ours* | the side you are on: `HEAD` during a merge |
| *theirs* | the side coming in: the branch being merged |
| *base* | the file as it was in the merge base, the commit both sides started from (Chapter 25) |
| *conflict markers* | the lines `<<<<<<<`, `=======` and `>>>>>>>` that Git writes into a file around what it could not combine |
| *stage* | one of the numbered slots in the index that hold the base, our and their version of a file (Chapter 5) |
| *unmerged path* | a file with a conflict: its index entry has stages instead of one version |
| *resolve* | make the file what it should be and stage it, which replaces the stages with that one version |

Every conflict ends the same way. The file holds the result, `git add` (or
`git rm`) records it, and the command that stopped is continued: for a merge,
`git merge --continue` or `git commit` (Chapter 25).

The examples use `git merge`. `git rebase`, `git cherry-pick`, `git revert`,
`git stash pop` and `git switch -m` stop on conflicts too, and write the same
markers with different labels; [Conflicts from other
commands](#conflicts-from-other-commands) shows the differences. Besides the
commands from earlier chapters, three commands exist only for conflicts:
`git mergetool` opens a merge program on each file, `git rerere` remembers how
you resolved a conflict and repeats it, and `git merge-file` merges three
files outside any repository.

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What is a conflict, and what do "ours", "theirs" and "base" mean?](#what-it-is)
- [How do I finish once I have fixed the files?](#what-it-is)

**[Synopsis](#synopsis)**

- [What can I type after `git mergetool`, `git rerere` and `git merge-file`?](#synopsis)

**[Commands and options at a glance](#commands-and-options-at-a-glance)**

- [Is there a list of every option that helps with conflicts, and where each is explained?](#commands-and-options-at-a-glance)

**[The example repository](#the-example-repository)**

- [What repository do the examples use?](#the-example-repository)

**[Reading a conflict](#reading-a-conflict)**

- [My merge printed several CONFLICT lines. What does each kind mean?](#what-git-prints-when-it-stops)
- [Which files are in conflict, and which merged fine?](#what-git-prints-when-it-stops)
- [How do I read the `<<<<<<<` and `>>>>>>>` lines in my file?](#conflict-markers)
- [Git says a file is in conflict but it has no markers in it. Why?](#conflict-markers)
- [What happens to an image or other binary file in a conflict?](#conflict-markers)
- [Can I see what the file looked like before either side changed it?](#conflict-styles)
- [What is the difference between the `merge`, `diff3` and `zdiff3` styles?](#conflict-styles)
- [My file contains lines of seven `=` signs. Can Git use longer markers?](#marker-length)

**[The three versions in the index](#the-three-versions-in-the-index)**

- [Where does Git keep our version, their version and the original during a conflict?](#the-three-versions-in-the-index)
- [Why does `git show :1:file` say the file is not at stage 1?](#the-three-versions-in-the-index)
- [What are `MERGE_HEAD`, `AUTO_MERGE` and `MERGE_MSG`?](#the-three-versions-in-the-index)

**[Seeing the differences](#seeing-the-differences)**

- [Why does `git diff` show two columns of `+` and `-` during a conflict?](#the-combined-diff)
- [What is the difference between `git diff --cc` and `git diff -c`?](#the-combined-diff)
- [How do I compare the file with only my version, or only theirs?](#comparing-with-one-version)
- [Why does `git diff -1` print nothing but "Unmerged path"?](#comparing-with-one-version)
- [How do I list just the files that are still in conflict?](#listing-the-conflicted-files)
- [Which commits on each side changed the file I am fixing?](#the-commits-behind-a-conflict)

**[Resolving a conflict](#resolving-a-conflict)**

- [How do I check that I did not break the file or leave markers behind while editing?](#checking-what-you-changed)
- [How do I tell Git a file is resolved?](#marking-a-file-resolved)
- [I made a mess of a file. How do I get its conflict back and start again?](#starting-a-file-again)
- [I ran `git add` on a file that still had markers. What now?](#a-file-staged-with-its-markers)
- [Why does `--theirs` do nothing after I staged the file?](#a-file-staged-with-its-markers)
- [How do I keep one side of a binary file, or accept that a file was deleted?](#taking-a-side-and-accepting-a-deletion)
- [How do I finish the merge, and what message does it get?](#finishing-the-merge)
- [How can I see later how someone resolved a conflict?](#looking-at-a-resolution-afterwards)

**[restore and checkout during a conflict](#restore-and-checkout-during-a-conflict)**

- [Why does `git restore file` say "path is unmerged"?](#what-they-refuse)
- [How do I take their version of every conflicted file at once?](#taking-a-side-for-many-files)
- [Does taking a side mark the files resolved?](#taking-a-side-for-many-files)
- [What do `--ours` and `--theirs` do to a file that one side deleted?](#a-file-one-side-deleted)
- [Why are "ours" and "theirs" the wrong way round during a rebase?](#during-a-rebase-the-sides-swap)

**[Other kinds of conflict](#other-kinds-of-conflict)**

- [Both branches renamed the same file to different names. How do I resolve it?](#renamed-to-two-different-names)
- [One branch renamed a file and the other deleted it. What do I do?](#renamed-on-one-side-deleted-on-the-other)
- [What is this `name~branch` file that appeared in my working tree?](#a-file-against-a-directory)
- [Why can't I `git mv` a conflicted file?](#a-file-against-a-directory)

**[Conflicts from other commands](#conflicts-from-other-commands)**

- [What do the labels on the markers mean after a cherry-pick, a rebase or `git stash pop`?](#conflicts-from-other-commands)
- [Does `git log --merge` work outside a merge?](#conflicts-from-other-commands)

**[git mergetool](#git-mergetool)**

- [Which merge programs can Git start for me?](#which-tools-there-are)
- [How do I make `git mergetool` run a program Git does not know?](#a-tool-of-your-own)
- [What happens when I run `git mergetool`, and what is this `.orig` file?](#running-the-tool)
- [What does mergetool do with a file that one side deleted?](#a-deleted-file)
- [How do I make mergetool ask before each file?](#prompting-before-each-file)
- [How do I use a graphical tool sometimes and a terminal tool otherwise?](#graphical-tools)
- [Can I choose the order of the files, or stop the `.orig` backups?](#order-and-backup-files)

**[git rerere](#git-rerere)**

- [What does rerere do, and how do I turn it on?](#recording-a-resolution)
- [When does rerere record my resolution?](#recording-a-resolution)
- [The same conflict came back. Did Git remember my resolution?](#reusing-a-resolution)
- [Does a remembered resolution still apply if I merge in the other direction?](#merging-the-other-way-round)
- [Can Git stage the remembered resolutions for me?](#staging-reused-resolutions)
- [rerere repeated a wrong resolution. How do I make it forget?](#forgetting-a-resolution)
- [Why did `git mergetool` skip some of my conflicted files?](#rerere-and-mergetool)
- [I removed `rerere.enabled` and rerere still runs. Why?](#turning-rerere-off)

**[git merge-file](#git-merge-file)**

- [How do I merge three versions of a file without a repository?](#merging-three-files)
- [Does `git merge-file` follow `merge.conflictStyle`?](#styles-and-the-setting)
- [Can merge-file take one side automatically, or keep both?](#taking-one-side)
- [How do I change the names on the markers, or their length?](#labels-and-marker-length)
- [Where does merge-file write its result?](#writing-into-the-file)
- [Why did two separate changes end up in one conflict?](#how-many-conflicts)
- [What does merge-file's exit code mean?](#how-many-conflicts)
- [What does `-q` hide?](#binary-files-and-q)
- [Can I merge versions of a file straight from commits?](#blobs-instead-of-files)

**[Conflicts and their neighbours](#conflicts-and-their-neighbours)**

- [Is `git merge-file` the same as `diff3 -m`?](#conflicts-and-their-neighbours)
- [What is the difference between `checkout --ours`, `merge-file --ours`, `-X ours` and `-s ours`?](#conflicts-and-their-neighbours)
- [Which diff should I use to look at a conflict?](#conflicts-and-their-neighbours)
- [Should I resolve by hand, with a merge tool, or let rerere do it?](#conflicts-and-their-neighbours)

**[The settings](#the-settings)**

- [Which settings change how conflicts are shown and resolved?](#the-settings)

</details>

## Synopsis

```
git mergetool [--tool=<tool>] [-y | --[no-]prompt] [<file>...]

git rerere [clear | forget <pathspec>... | diff | status | remaining | gc]

git merge-file [-L <current-name> [-L <base-name> [-L <other-name>]]]
               [--ours|--theirs|--union] [-p|--stdout] [-q|--quiet] [--marker-size=<n>]
               [--[no-]diff3] [--object-id] <current> <base> <other>
```

These are the forms from Git's documentation. `git mergetool -h` also lists
`--tool-help`, `-g`, `--gui`, `--no-gui` and `-O<orderfile>`, and
`git merge-file -h` lists `--zdiff3` and `--diff-algorithm`.

| Part | Means |
|---|---|
| `<file>...` | For `git mergetool`: the conflicted files to work on; every conflicted file when left out |
| `<pathspec>...` | For `git rerere forget`: whose recorded resolutions to forget |
| `<current> <base> <other>` | For `git merge-file`: our version, the common ancestor, their version, in that order; the result goes into `<current>` |

| Command | Does |
|---|---|
| `git mergetool` | Start a merge program on each conflicted file, then stage the files it resolved |
| `git rerere` | Record conflicts and resolutions, and reuse them; commands that merge run it themselves |
| `git rerere status` | List the conflicted files whose resolution rerere will record |
| `git rerere diff` | Show how the files differ from the conflicts rerere recorded |
| `git rerere remaining` | List the conflicted files rerere did not resolve |
| `git rerere forget <pathspec>` | Throw away the recorded resolution for these files' current conflicts |
| `git rerere clear` | Forget what rerere is tracking for the conflict in progress |
| `git rerere gc` | Delete old records |
| `git merge-file <current> <base> <other>` | Merge the three files and write the result into `<current>` |

## Commands and options at a glance

### Options for looking at a conflict

| Option | Of | Does | Covered in |
|---|---|---|---|
| `--cc` | `git diff`, `git log`, `git show` | A combined diff, leaving out hunks where one side was taken unchanged | [The combined diff](#the-combined-diff) |
| `-c` | `git diff`, `git log`, `git show` | A combined diff with every hunk | [The combined diff](#the-combined-diff) |
| `--base`, `-1` | `git diff` | Compare the file with the base version | [Comparing with one version](#comparing-with-one-version) |
| `--ours`, `-2` | `git diff` | Compare the file with our version | [Comparing with one version](#comparing-with-one-version) |
| `--theirs`, `-3` | `git diff` | Compare the file with their version | [Comparing with one version](#comparing-with-one-version) |
| `-0` | `git diff` | Name the conflicted files without a diff | [Comparing with one version](#comparing-with-one-version) |
| `--diff-filter=U` | `git diff` | Only the conflicted files | [Listing the conflicted files](#listing-the-conflicted-files) |
| `--check` | `git diff` | Report leftover conflict markers | [Checking what you changed](#checking-what-you-changed) |
| `--merge` | `git log` | The commits on either side that touch the conflicted files | [The commits behind a conflict](#the-commits-behind-a-conflict) |
| `-u`, `--unmerged` | `git ls-files` | List the stages of the conflicted files | [The three versions in the index](#the-three-versions-in-the-index) |
| `-s`, `--stage` | `git ls-files` | List every index entry with its stage number | [The three versions in the index](#the-three-versions-in-the-index) |
| `--remerge-diff` | `git show`, `git log` | Redo a merge and show how its conflicts were resolved (Chapter 17) | [Looking at a resolution afterwards](#looking-at-a-resolution-afterwards) |

### Options for resolving

| Option | Of | Does | Covered in |
|---|---|---|---|
| `--ours` | `git restore`, `git checkout` | Write our version of the file | [Taking a side for many files](#taking-a-side-for-many-files) |
| `--theirs` | `git restore`, `git checkout` | Write their version of the file | [Taking a side for many files](#taking-a-side-for-many-files) |
| `-m`, `--merge` | `git restore`, `git checkout` | Write the conflict markers again | [Starting a file again](#starting-a-file-again) |
| `--conflict=merge` | `git restore`, `git checkout` | The same, in the default style | Chapter 14 |
| `--conflict=diff3` | `git restore`, `git checkout` | The same, with the base version too | [Conflict styles](#conflict-styles) |
| `--conflict=zdiff3` | `git restore`, `git checkout` | `diff3`, with lines both sides agree on moved out | [Conflict styles](#conflict-styles) |
| `-f`, `--force` | `git checkout` | Skip conflicted files instead of refusing | [What they refuse](#what-they-refuse) |
| `--ignore-unmerged` | `git restore` | Skip conflicted files instead of refusing | Chapter 14 |
| `--rerere-autoupdate`, `--no-rerere-autoupdate` | `git merge`, `git rebase`, `git cherry-pick`, `git revert`, `git am`, `git rerere` | Stage what rerere resolved, or leave it unstaged | [Staging reused resolutions](#staging-reused-resolutions) |

### Options of git mergetool

| Option | Does | Covered in |
|---|---|---|
| `-t <tool>`, `--tool=<tool>` | Use this tool | [Running the tool](#running-the-tool) |
| `--tool-help` | List the tools | [Which tools there are](#which-tools-there-are) |
| `-y`, `--no-prompt` | Do not ask before starting the tool on each file | [Order and backup files](#order-and-backup-files) |
| `--prompt` | Ask before starting the tool on each file | [Prompting before each file](#prompting-before-each-file) |
| `-g`, `--gui` | Use the tool in `merge.guitool` | [Graphical tools](#graphical-tools) |
| `--no-gui` | Cancel `-g` or `mergetool.guiDefault` | [Graphical tools](#graphical-tools) |
| `-O<orderfile>` | Work through the files in the order this file gives | [Order and backup files](#order-and-backup-files) |

### Options of git merge-file

| Option | Does | Covered in |
|---|---|---|
| `-p`, `--stdout` | Print the result instead of writing it into `<current>` | [Merging three files](#merging-three-files) |
| `--diff3` | Show conflicts with the base version | [Styles and the setting](#styles-and-the-setting) |
| `--zdiff3` | The same, with lines both sides agree on moved out | [Styles and the setting](#styles-and-the-setting) |
| `--ours` | Resolve each conflict with our side | [Taking one side](#taking-one-side) |
| `--theirs` | Resolve each conflict with their side | [Taking one side](#taking-one-side) |
| `--union` | Resolve each conflict with both sides' lines | [Taking one side](#taking-one-side) |
| `-L <name>` | The label for a marker; up to three times | [Labels and marker length](#labels-and-marker-length) |
| `--marker-size=<n>` | Markers of this many characters | [Labels and marker length](#labels-and-marker-length) |
| `-q`, `--quiet` | Print no error messages | [Binary files and -q](#binary-files-and-q) |
| `--object-id` | The three arguments name blobs in the repository | [Blobs instead of files](#blobs-instead-of-files) |
| `--diff-algorithm=<algorithm>` | How changes are found; the algorithms are taught in Chapter 13 | Chapter 13 |

> **Since Git 2.43.** `git merge-file --object-id`.
>
> **Since Git 2.44.** `git merge-file --diff-algorithm`.

## The example repository

```console
$ git log --oneline --graph --all --decorate
* b8d08ae (file-side) Add a kitchen file
| * faa3e38 (dir-side) Add a kitchen directory
|/  
| * 4be399f (gone) Delete the notes
|/  
| * ae7297c (right) Rename notes to a to-do list
|/  
| * 934b8b4 (left) Rename notes to Markdown
|/  
* d95d995 (HEAD -> main) Update the menu, drop specials, add hours
| * c1d7493 (prices) Raise prices, add specials, hours and drinks
|/  
* 6100575 Open the cafe
$ git diff main~1 prices --stat
 drinks.txt   |   2 ++
 hours.txt    |   1 +
 logo.png     | Bin 12 -> 14 bytes
 menu.txt     |   3 ++-
 specials.txt |   1 +
 5 files changed, 6 insertions(+), 1 deletion(-)
$ git diff main~1 main --stat
 hours.txt    |   1 +
 logo.png     | Bin 12 -> 15 bytes
 menu.txt     |   5 +++--
 specials.txt |   1 -
 4 files changed, 4 insertions(+), 3 deletions(-)
```

A cafe. `Open the cafe` is where `main` and `prices` split, so it is the merge
base, and `main~1` names it. The two branches did this to each file:

| File | On `main` | On `prices` |
|---|---|---|
| `menu.txt`, ten lines starting `Soup 4` | soup to 5, a `Bread 2` line added, juice from 4 to 3 | soup to 6, the same `Bread 2` line added |
| `hours.txt`, new | created with `Mon-Sat 7-19` | created with `Mon-Fri 8-18` |
| `specials.txt` | deleted | a Tuesday line added |
| `logo.png` | a green logo | a blue logo |
| `drinks.txt`, new | | created |

`logo.png` is a stand-in for an image: a few bytes including a zero byte, which
is what makes Git treat a file as binary (it looks for one in the first few
thousand bytes). The other branches rename or delete `notes.txt`, or add
`kitchen` as a file on one branch and a directory on the other; they are used in
[Other kinds of conflict](#other-kinds-of-conflict).

Each example starts on a fresh branch `try` at `main`, made with
`git switch -q -C try main` (Chapter 24), and merges `prices` into it.

## Reading a conflict

### What Git prints when it stops

```console
$ git switch -q -C try main
$ git merge prices
Auto-merging hours.txt
CONFLICT (add/add): Merge conflict in hours.txt
warning: Cannot merge binary files: logo.png (HEAD vs. prices)
Auto-merging logo.png
CONFLICT (content): Merge conflict in logo.png
Auto-merging menu.txt
CONFLICT (content): Merge conflict in menu.txt
CONFLICT (modify/delete): specials.txt deleted in HEAD and modified in prices.  Version prices of specials.txt left in tree.
Automatic merge failed; fix conflicts and then commit the result.
$ git status
On branch try
You have unmerged paths.
  (fix conflicts and run "git commit")
  (use "git merge --abort" to abort the merge)

Changes to be committed:
	new file:   drinks.txt

Unmerged paths:
  (use "git add/rm <file>..." as appropriate to mark resolution)
	both added:      hours.txt
	both modified:   logo.png
	both modified:   menu.txt
	deleted by us:   specials.txt

$ git status --short
A  drinks.txt
AA hours.txt
UU logo.png
UU menu.txt
DU specials.txt
```

`Auto-merging` appears for each file both sides changed, before Git combines it
line by line. Each `CONFLICT` line names a file Git could not finish:

| The line says | Both sides | What Git left in the file |
|---|---|---|
| `CONFLICT (content)` | changed the same lines differently | the file with markers around those lines |
| `CONFLICT (add/add)` | created a file with the same name and different contents | the whole file between markers, as there is no base to compare with |
| `CONFLICT (modify/delete)` | one deleted the file, the other changed it | the changed version, without markers |
| `Cannot merge binary files` then `CONFLICT (content)` | changed a binary file | our version, untouched |
| `CONFLICT (rename/rename)`, `(rename/delete)`, `(file/directory)` | disagreed about a file's name or kind | [Other kinds of conflict](#other-kinds-of-conflict) |

`drinks.txt` only changed on one side, so it merged cleanly and is already
staged, like every file that is not listed as unmerged. The codes in the short
form are all in Chapter 10: `AA` both added, `UU` both modified, `DU` deleted by
us, where "us" is the branch you are on.

### Conflict markers

```console
$ cat menu.txt
<<<<<<< HEAD
Soup 5
=======
Soup 6
>>>>>>> prices
Bread 2
Salad 5
Cake 3
Pie 4
Bun 2
Tart 5
Scone 2
Muffin 3
Cookie 1
Juice 3
$ cat hours.txt
<<<<<<< HEAD
Mon-Sat 7-19
=======
Mon-Fri 8-18
>>>>>>> prices
$ cat specials.txt
Monday: pie
Tuesday: soup of the day
$ cat -A logo.png
PNG^@logo green$
```

Between `<<<<<<< HEAD` and `=======` is our side; between `=======` and
`>>>>>>> prices` is theirs. The words after the markers are *labels* naming the
sides. Only the soup line is left for you: both sides added `Bread 2` the same
way, so it is outside the markers, and only `main` changed the juice, so
`Juice 3` was taken without a word. A resolved file must contain none of the
three marker lines.

`specials.txt` has no markers at all. Nothing inside it says it is in conflict;
only `git status` does. `logo.png` still holds our green logo, because Git never
writes markers into a binary file. `cat -A` makes invisible characters visible:
`^@` is the zero byte and `$` the end of a line.

Two conflicts a few lines apart are written as one block;
[How many conflicts](#how-many-conflicts) shows when.

### Conflict styles

```console
$ git restore --conflict=diff3 menu.txt
$ head -9 menu.txt
<<<<<<< ours
Soup 5
Bread 2
||||||| base
Soup 4
=======
Soup 6
Bread 2
>>>>>>> theirs
$ git checkout --conflict=zdiff3 menu.txt
Recreated 1 merge conflict
$ head -7 menu.txt
<<<<<<< ours
Soup 5
||||||| base
Soup 4
=======
Soup 6
>>>>>>> theirs
$ git restore -m menu.txt
$ head -5 menu.txt
<<<<<<< ours
Soup 5
=======
Soup 6
>>>>>>> theirs
$ git merge --abort
$ git -c merge.conflictStyle=diff3 merge prices >/dev/null
$ head -9 menu.txt
<<<<<<< HEAD
Soup 5
Bread 2
||||||| 6100575
Soup 4
=======
Soup 6
Bread 2
>>>>>>> prices
$ git merge --abort
```

`git restore` and `git checkout` rewrite a conflicted file from the stages in
the style you ask for (Chapter 14 has every form). `head -9` prints only the
first nine lines.

| Style | Shows | Here |
|---|---|---|
| `merge`, the default | our side and their side | `Soup 5` against `Soup 6` |
| `diff3` | also the base, after `\|\|\|\|\|\|\|` | the soup was 4 and there was no bread; both sides changed the price and added bread |
| `zdiff3` | `diff3`, with lines both sides agree on moved out of the block | `Bread 2` is no longer repeated |

The base answers the question the default style cannot: what did each side
change, rather than what does each side have. Here it shows both sides raised
the price of a soup that was 4, which tells you neither kept the old price. Set
`merge.conflictStyle=zdiff3` once, as Chapter 3 suggests.

When `restore` or `checkout` writes the markers, the labels are `ours`, `base`
and `theirs`. When the merge writes them with `merge.conflictStyle`, they are
`HEAD`, the base commit's short hash, and the branch. `git -c` sets a setting for
one command (Chapter 62), and `>/dev/null` hides the merge's messages, already
shown above.

> **Since Git 2.35.** `zdiff3`.

### Marker length

```console
$ echo 'menu.txt conflict-marker-size=12' > .gitattributes
$ git merge prices >/dev/null
$ head -5 menu.txt
<<<<<<<<<<<< HEAD
Soup 5
============
Soup 6
>>>>>>>>>>>> prices
$ git merge --abort
$ rm .gitattributes
```

The `conflict-marker-size` attribute gives markers of that many characters to
the files it matches (Chapter 65 covers attributes). It is for files that
legitimately contain a line of seven `=` or `<`, such as a heading underline in
some text formats, where the usual markers would be ambiguous.

## The three versions in the index

```console
$ git merge prices >/dev/null
$ git ls-files -u
100644 3990f0e85ddf7013cc60744cb0e134fa72ba3735 2	hours.txt
100644 89eae73bf73b87e055700b8c83f00a3f9b0d6a6d 3	hours.txt
100644 149588b8b590bc19681fec31e0f0b83643cbb34f 1	logo.png
100644 dc87869a9c97e841e2a92cf1307c0fff96c51348 2	logo.png
100644 42768ab09cfb8f89129dcc66c52745f6e2102d44 3	logo.png
100644 ab4b4ee2a615a8637b0cbc52a880fd9306178d97 1	menu.txt
100644 867d9c3f1d837ac3ee611f1aa5cdf9b4ed2337f4 2	menu.txt
100644 c6ce4fde030b05fd5e8e200dd1018614c0c197c5 3	menu.txt
100644 ffe37f6a9003baf3f2138794155310da9dc52efb 1	specials.txt
100644 5baba8fc56087a725d8e4dba521052d6b5dd4ff7 3	specials.txt
$ git ls-files --stage
100644 54f259a6ef1e4c81f17633c0eea706f51a472e44 0	drinks.txt
100644 3990f0e85ddf7013cc60744cb0e134fa72ba3735 2	hours.txt
100644 89eae73bf73b87e055700b8c83f00a3f9b0d6a6d 3	hours.txt
100644 149588b8b590bc19681fec31e0f0b83643cbb34f 1	logo.png
100644 dc87869a9c97e841e2a92cf1307c0fff96c51348 2	logo.png
100644 42768ab09cfb8f89129dcc66c52745f6e2102d44 3	logo.png
100644 ab4b4ee2a615a8637b0cbc52a880fd9306178d97 1	menu.txt
100644 867d9c3f1d837ac3ee611f1aa5cdf9b4ed2337f4 2	menu.txt
100644 c6ce4fde030b05fd5e8e200dd1018614c0c197c5 3	menu.txt
100644 3d4a7b0b522540c7a8bfab5451a77391062c23e7 0	notes.txt
100644 ffe37f6a9003baf3f2138794155310da9dc52efb 1	specials.txt
100644 5baba8fc56087a725d8e4dba521052d6b5dd4ff7 3	specials.txt
$ git show :1:menu.txt | head -3
Soup 4
Salad 5
Cake 3
$ git show :2:menu.txt | head -3
Soup 5
Bread 2
Salad 5
$ git show :3:menu.txt | head -3
Soup 6
Bread 2
Salad 5
$ git show :1:hours.txt
fatal: path 'hours.txt' is in the index, but not at stage 1
hint: Did you mean ':2:hours.txt'?
$ git show :2:specials.txt
fatal: path 'specials.txt' is in the index, but not at stage 2
hint: Did you mean ':1:specials.txt'?
$ git show :3:specials.txt
Monday: pie
Tuesday: soup of the day
$ git rev-parse MERGE_HEAD AUTO_MERGE
c1d74933d498e76558fbaaaf4f6fb7df4c145950
29c5d1f9a381338775f19222b515dcf7aad322aa
$ cat .git/MERGE_MSG
Merge branch 'prices' into try

# Conflicts:
#	hours.txt
#	logo.png
#	menu.txt
#	specials.txt
```

`git ls-files -u` lists only the unmerged entries; `--stage` lists every entry.
The number before the name is the stage:

| Stage | Holds | Read it with |
|---|---|---|
| 0 | the one version of a file with no conflict | `git show :<path>` |
| 1 | the base version | `git show :1:<path>` |
| 2 | our version, from `HEAD` | `git show :2:<path>` |
| 3 | their version, from the branch being merged | `git show :3:<path>` |

A stage is missing when that side has no file. `hours.txt` has no stage 1,
because the file did not exist in the base; `specials.txt` has no stage 2,
because we deleted it. `logo.png` has all three; Git keeps binary versions in
the stages like any other. `drinks.txt` and `notes.txt` sit at stage 0: they are
not in conflict.

`MERGE_HEAD` is the commit being merged, `c1d7493` from `prices`. `AUTO_MERGE`
is a tree holding the files as Git wrote them into the working tree, conflict
markers included; the next section compares with it. `.git/MERGE_MSG` is the
message the merge commit will start with. Its `# Conflicts:` lines are comments,
which are removed from the final message unless you delete the `#` (Chapter 12
covers comment lines).

> **Since Git 2.34.** `AUTO_MERGE` for every merge, because Git 2.34 made the
> `ort` strategy the default. Git 2.32 and 2.33 write it only for `git merge -s ort`.

## Seeing the differences

### The combined diff

```console
$ git diff
diff --cc hours.txt
index 3990f0e,89eae73..0000000
--- a/hours.txt
+++ b/hours.txt
@@@ -1,1 -1,1 +1,5 @@@
++<<<<<<< HEAD
 +Mon-Sat 7-19
++=======
+ Mon-Fri 8-18
++>>>>>>> prices
diff --cc logo.png
index dc87869,42768ab..0000000
Binary files differ
diff --cc menu.txt
index 867d9c3,c6ce4fd..0000000
--- a/menu.txt
+++ b/menu.txt
@@@ -1,4 -1,4 +1,8 @@@
++<<<<<<< HEAD
 +Soup 5
++=======
+ Soup 6
++>>>>>>> prices
  Bread 2
  Salad 5
  Cake 3
* Unmerged path specials.txt
```

During a conflict, `git diff` compares the working tree file with our version
and their version at once, and gives each a column of markers. The first column
compares with ours (stage 2), the second with theirs (stage 3):

| Columns | The line is |
|---|---|
| `++` | in neither version: here, the markers Git added |
| ` +` | in ours but not theirs: `Soup 5`, `Mon-Sat 7-19` |
| `+ ` | in theirs but not ours: `Soup 6`, `Mon-Fri 8-18` |
| two spaces | in both |
| `- `, ` -` | in ours, or in theirs, and no longer in the file |

The `index` line gives our and their blob hashes, and zeros for the working tree
file, which is not stored yet. `@@@` has three ranges: ours, theirs, the file.
`specials.txt` gets only a line saying it is unmerged, because with no version
of ours there is nothing to combine. Chapter 18 reads a combined diff of a
finished merge.

```console
$ git diff --cc menu.txt
diff --cc menu.txt
index 867d9c3,c6ce4fd..0000000
--- a/menu.txt
+++ b/menu.txt
@@@ -1,4 -1,4 +1,8 @@@
++<<<<<<< HEAD
 +Soup 5
++=======
+ Soup 6
++>>>>>>> prices
  Bread 2
  Salad 5
  Cake 3
$ git diff -c menu.txt
diff --combined menu.txt
index 867d9c3,c6ce4fd..0000000
--- a/menu.txt
+++ b/menu.txt
@@@ -1,4 -1,4 +1,8 @@@
++<<<<<<< HEAD
 +Soup 5
++=======
+ Soup 6
++>>>>>>> prices
  Bread 2
  Salad 5
  Cake 3
@@@ -8,4 -8,4 +12,4 @@@ Tart 
  Scone 2
  Muffin 3
  Cookie 1
 -Juice 4
 +Juice 3
```

`--cc` is what plain `git diff` shows. `-c` shows every hunk; `--cc` leaves out
hunks where the file simply has one side's version, as Git's documentation puts
it, "uninteresting hunks". The juice line is one: the file has our `Juice 3`,
which only differs from their `Juice 4`.

### Comparing with one version

```console
$ git diff --base menu.txt
* Unmerged path menu.txt
diff --git a/menu.txt b/menu.txt
index ab4b4ee..ce5de52 100644
--- a/menu.txt
+++ b/menu.txt
@@ -1,4 +1,9 @@
-Soup 4
+<<<<<<< HEAD
+Soup 5
+=======
+Soup 6
+>>>>>>> prices
+Bread 2
 Salad 5
 Cake 3
 Pie 4
@@ -7,4 +12,4 @@ Tart 5
 Scone 2
 Muffin 3
 Cookie 1
-Juice 4
+Juice 3
$ git diff --ours menu.txt
* Unmerged path menu.txt
diff --git a/menu.txt b/menu.txt
index 867d9c3..ce5de52 100644
--- a/menu.txt
+++ b/menu.txt
@@ -1,4 +1,8 @@
+<<<<<<< HEAD
 Soup 5
+=======
+Soup 6
+>>>>>>> prices
 Bread 2
 Salad 5
 Cake 3
$ git diff --theirs menu.txt
* Unmerged path menu.txt
diff --git a/menu.txt b/menu.txt
index c6ce4fd..ce5de52 100644
--- a/menu.txt
+++ b/menu.txt
@@ -1,4 +1,8 @@
+<<<<<<< HEAD
+Soup 5
+=======
 Soup 6
+>>>>>>> prices
 Bread 2
 Salad 5
 Cake 3
@@ -8,4 +12,4 @@ Tart 5
 Scone 2
 Muffin 3
 Cookie 1
-Juice 4
+Juice 3
$ git diff -1 hours.txt
* Unmerged path hours.txt
$ git diff -2 hours.txt
* Unmerged path hours.txt
diff --git a/hours.txt b/hours.txt
index 3990f0e..5b79742 100644
--- a/hours.txt
+++ b/hours.txt
@@ -1 +1,5 @@
+<<<<<<< HEAD
 Mon-Sat 7-19
+=======
+Mon-Fri 8-18
+>>>>>>> prices
$ git diff -3 hours.txt
* Unmerged path hours.txt
diff --git a/hours.txt b/hours.txt
index 89eae73..5b79742 100644
--- a/hours.txt
+++ b/hours.txt
@@ -1 +1,5 @@
+<<<<<<< HEAD
+Mon-Sat 7-19
+=======
 Mon-Fri 8-18
+>>>>>>> prices
$ git diff -0
* Unmerged path hours.txt
* Unmerged path logo.png
* Unmerged path menu.txt
* Unmerged path specials.txt
```

Each of these is an ordinary diff, from one stage to the working tree file.
`--ours` shows what the file has beyond our version: their soup and the markers.
`--theirs` shows what it has beyond theirs, including our juice. `--base` shows
everything both sides changed. Git's documentation lists `-1`, `-2` and `-3` as
the same options as `--base`, `--ours` and `--theirs`. `hours.txt` has no base
version, so `-1` has nothing to compare with and prints only the reminder line.
`-0` prints no diff at all, just a line for each conflicted file.

### Listing the conflicted files

```console
$ git diff --name-only --diff-filter=U
hours.txt
logo.png
menu.txt
specials.txt
$ git diff --cached --name-status
A	drinks.txt
U	hours.txt
U	logo.png
U	menu.txt
U	specials.txt
```

`--diff-filter=U` keeps only unmerged files, and with `--name-only` gives a
plain list for a script; it is how `git mergetool` finds its files. `--cached`
compares the index with `HEAD`: `drinks.txt` is staged as added, and each
conflicted file shows `U`.

### The commits behind a conflict

```console
$ git log --merge --oneline
d95d995 Update the menu, drop specials, add hours
c1d7493 Raise prices, add specials, hours and drinks
$ git log --merge --oneline --left-right
< d95d995 Update the menu, drop specials, add hours
> c1d7493 Raise prices, add specials, hours and drinks
$ git log --merge -p --format='%h %s' -- hours.txt
d95d995 Update the menu, drop specials, add hours

diff --git a/hours.txt b/hours.txt
new file mode 100644
index 0000000..3990f0e
--- /dev/null
+++ b/hours.txt
@@ -0,0 +1 @@
+Mon-Sat 7-19
c1d7493 Raise prices, add specials, hours and drinks

diff --git a/hours.txt b/hours.txt
new file mode 100644
index 0000000..89eae73
--- /dev/null
+++ b/hours.txt
@@ -0,0 +1 @@
+Mon-Fri 8-18
$ git diff HEAD -- hours.txt
diff --git a/hours.txt b/hours.txt
index 3990f0e..5b79742 100644
--- a/hours.txt
+++ b/hours.txt
@@ -1 +1,5 @@
+<<<<<<< HEAD
 Mon-Sat 7-19
+=======
+Mon-Fri 8-18
+>>>>>>> prices
$ git diff MERGE_HEAD -- hours.txt
diff --git a/hours.txt b/hours.txt
index 89eae73..5b79742 100644
--- a/hours.txt
+++ b/hours.txt
@@ -1 +1,5 @@
+<<<<<<< HEAD
+Mon-Sat 7-19
+=======
 Mon-Fri 8-18
+>>>>>>> prices
```

`git log --merge` lists the commits since the merge base, on either side, that
touch a conflicted file, as Git's documentation defines it: the range
`HEAD...MERGE_HEAD`, limited to those files. `--left-right` marks ours with `<`
and theirs with `>` (Chapter 17). With `-p` and a file, you see each side's
change and its commit message, which is usually the best clue to what the
result should be.

`git diff HEAD` compares the file with our commit rather than with stage 2, and
`git diff MERGE_HEAD` with their commit. For a merge, stage 2 holds exactly the
version in `HEAD`, so the first is the same diff as `-2` above, without the
reminder line: the blob `3990f0e` is the same.

## Resolving a conflict

### Checking what you changed

```console
$ git restore menu.txt
error: path 'menu.txt' is unmerged
$ printf 'Soup 5.5\nBread 2\n<<<<<<< HEAD\n' > menu.txt
$ git diff AUTO_MERGE -- menu.txt
diff --git a/menu.txt b/menu.txt
index ce5de52..a3707d5 100644
--- a/menu.txt
+++ b/menu.txt
@@ -1,15 +1,3 @@
-<<<<<<< HEAD
-Soup 5
-=======
-Soup 6
->>>>>>> prices
+Soup 5.5
 Bread 2
-Salad 5
-Cake 3
-Pie 4
-Bun 2
-Tart 5
-Scone 2
-Muffin 3
-Cookie 1
-Juice 3
+<<<<<<< HEAD
```

A plain `git restore` refuses a conflicted file, because it cannot know which
version you mean; [restore and checkout during a
conflict](#restore-and-checkout-during-a-conflict) has the ways it can be told.

The `printf` stands in for editing the file: a careless edit that settled the
soup at 5.5 but lost most of the menu and left a marker behind.
`git diff AUTO_MERGE` compares the file with what Git wrote into it, so it
shows exactly your edits, and every lost line appears as removed.

```console
$ git diff --check
hours.txt:1: leftover conflict marker
hours.txt:3: leftover conflict marker
hours.txt:5: leftover conflict marker
menu.txt:3: leftover conflict marker
```

`--check` reports marker lines still in any file, here the one left in
`menu.txt` and the untouched `hours.txt` (Chapter 13 shows it finding whitespace
errors too).

### Marking a file resolved

```console
$ printf 'Soup 5.5\nBread 2\nSalad 5\nCake 3\nPie 4\nBun 2\nTart 5\nScone 2\nMuffin 3\nCookie 1\nJuice 3\n' > menu.txt
$ git diff menu.txt
diff --cc menu.txt
index 867d9c3,c6ce4fd..0000000
--- a/menu.txt
+++ b/menu.txt
@@@ -1,4 -1,4 +1,4 @@@
- Soup 5
 -Soup 6
++Soup 5.5
  Bread 2
  Salad 5
  Cake 3
$ git add menu.txt
$ git status --short
A  drinks.txt
AA hours.txt
UU logo.png
M  menu.txt
DU specials.txt
```

The file is now the whole menu with soup at 5.5. The combined diff reads: `Soup 5`
from ours is gone, `Soup 6` from theirs is gone, and `Soup 5.5` is in neither.

`git add` is what resolves it: the three stages are replaced by the file, at
stage 0, and the status becomes `M`, modified compared with `HEAD`.

### Starting a file again

```console
$ git restore -m menu.txt
$ git status --short
A  drinks.txt
AA hours.txt
UU logo.png
UU menu.txt
DU specials.txt
$ head -5 menu.txt
<<<<<<< ours
Soup 5
=======
Soup 6
>>>>>>> theirs
$ printf 'Soup 5.5\nBread 2\nSalad 5\nCake 3\nPie 4\nBun 2\nTart 5\nScone 2\nMuffin 3\nCookie 1\nJuice 3\n' > menu.txt
$ git add menu.txt
$ git diff --check
hours.txt:1: leftover conflict marker
hours.txt:3: leftover conflict marker
hours.txt:5: leftover conflict marker
```

`git restore -m` puts the conflict back, even after `git add`: the file is `UU`
again and has its markers. Git keeps the three versions aside when `git add`
resolves a file, and `-m` rebuilds the conflict from them until the merge is
committed. It overwrites the file, so whatever you had written is gone. Here the
resolution was written and staged again, and `--check` now finds markers only in
`hours.txt`.

### A file staged with its markers

```console
$ git add hours.txt
$ git status --short
A  drinks.txt
M  hours.txt
UU logo.png
M  menu.txt
DU specials.txt
$ git diff --check
$ git diff --cached --check
hours.txt:1: leftover conflict marker
hours.txt:3: leftover conflict marker
hours.txt:5: leftover conflict marker
```

> **Careful.** `git add` does not look inside the file. `hours.txt`, markers and
> all, now counts as resolved, and committing would record the markers.

Plain `--check` stays silent now, because it compares the working tree with the
index and they are the same. `--cached --check` compares the index with `HEAD`
and finds the markers. It is worth running before finishing any merge.

```console
$ git restore --theirs hours.txt
$ git checkout --theirs hours.txt
Updated 0 paths from the index
$ head -1 hours.txt
<<<<<<< HEAD
$ git restore -m hours.txt
$ git restore --theirs hours.txt
$ cat hours.txt
Mon-Fri 8-18
$ git checkout --ours hours.txt
Updated 1 path from the index
$ cat hours.txt
Mon-Sat 7-19
$ git add hours.txt
```

Once a file is staged there is no stage 2 or 3 left, so `--theirs` has nothing
to take, and both commands left the staged file as it was: `Updated 0 paths`.
`git restore -m` brought the conflict back, and then `--theirs` and `--ours`
worked. The cafe keeps `main`'s opening hours.

### Taking a side and accepting a deletion

```console
$ git checkout --theirs logo.png
Updated 1 path from the index
$ git add logo.png
$ git rm specials.txt
rm 'specials.txt'
$ git status
On branch try
All conflicts fixed but you are still merging.
  (use "git commit" to conclude merge)

Changes to be committed:
	new file:   drinks.txt
	modified:   logo.png
	modified:   menu.txt

```

A binary file cannot be edited into a mix of both, so you take one version: here
the blue logo from `prices`. For a modify/delete conflict the choice is between
the two outcomes: `git rm` accepts the deletion, and `git add` would keep the
changed file.

`hours.txt` is not listed as changed: the result is exactly `HEAD`'s version.

### Finishing the merge

```console
$ GIT_EDITOR=cat git merge --continue
Merge branch 'prices' into try

# Conflicts:
#	hours.txt
#	logo.png
#	menu.txt
#	specials.txt
#
# It looks like you may be committing a merge.
# If this is not correct, please run
#	git update-ref -d MERGE_HEAD
# and try again.


# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
#
# On branch try
# All conflicts fixed but you are still merging.
#
# Changes to be committed:
#	new file:   drinks.txt
#	modified:   logo.png
#	modified:   menu.txt
#
[try 3feae46] Merge branch 'prices' into try
```

`GIT_EDITOR=cat` shows the text the editor would open with, as in Chapter 25.
The list of conflicted files is there as comments. Some projects keep it in the
message, by removing the `#` in front of those lines, so that history says which
files needed a person's decision.

### Looking at a resolution afterwards

```console
$ git show
commit 3feae46d2a1050694a8a10cbd5e3feffab959507
Merge: d95d995 c1d7493
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 17:00:00 2026 +0000

    Merge branch 'prices' into try

diff --cc menu.txt
index 867d9c3,c6ce4fd..0a80108
--- a/menu.txt
+++ b/menu.txt
@@@ -1,4 -1,4 +1,4 @@@
- Soup 5
 -Soup 6
++Soup 5.5
  Bread 2
  Salad 5
  Cake 3
$ git log -1 --cc --format=%s
Merge branch 'prices' into try

diff --cc menu.txt
index 867d9c3,c6ce4fd..0a80108
--- a/menu.txt
+++ b/menu.txt
@@@ -1,4 -1,4 +1,4 @@@
- Soup 5
 -Soup 6
++Soup 5.5
  Bread 2
  Salad 5
  Cake 3
$ git log -1 -c --format=%s -- menu.txt
Merge branch 'prices' into try

diff --combined menu.txt
index 867d9c3,c6ce4fd..0a80108
--- a/menu.txt
+++ b/menu.txt
@@@ -1,4 -1,4 +1,4 @@@
- Soup 5
 -Soup 6
++Soup 5.5
  Bread 2
  Salad 5
  Cake 3
@@@ -8,4 -8,4 +8,4 @@@ Tart 
  Scone 2
  Muffin 3
  Cookie 1
 -Juice 4
 +Juice 3
$ git log -1 --format=%s --stat --diff-merges=first-parent
Merge branch 'prices' into try

 drinks.txt |   2 ++
 logo.png   | Bin 15 -> 14 bytes
 menu.txt   |   2 +-
 3 files changed, 3 insertions(+), 1 deletion(-)
```

The combined diff of the merge commit shows only `menu.txt`, the one file where
the result is neither side. The hours, logo and specials were each resolved by
taking one side, which `--cc` counts as uninteresting, and `-c` still shows only
files whose result is not simply one parent's. A combined diff therefore never
tells you that someone threw one side away. `--diff-merges=first-parent` shows
what the merge brought into the branch, compared with its first parent.

```console
$ git show --remerge-diff --format=%s
Merge branch 'prices' into try

diff --git a/hours.txt b/hours.txt
remerge CONFLICT (add/add): Merge conflict in hours.txt
index daa2415..3990f0e 100644
--- a/hours.txt
+++ b/hours.txt
@@ -1,5 +1 @@
-<<<<<<< d95d995 (Update the menu, drop specials, add hours)
 Mon-Sat 7-19
-=======
-Mon-Fri 8-18
->>>>>>> c1d7493 (Raise prices, add specials, hours and drinks)
diff --git a/logo.png b/logo.png
remerge warning: Cannot merge binary files: logo.png (d95d995 (Update the menu, drop specials, add hours) vs. c1d7493 (Raise prices, add specials, hours and drinks))
remerge CONFLICT (content): Merge conflict in logo.png
index dc87869..42768ab 100644
Binary files a/logo.png and b/logo.png differ
diff --git a/menu.txt b/menu.txt
remerge CONFLICT (content): Merge conflict in menu.txt
index 45cbea2..0a80108 100644
--- a/menu.txt
+++ b/menu.txt
@@ -1,8 +1,4 @@
-<<<<<<< d95d995 (Update the menu, drop specials, add hours)
-Soup 5
-=======
-Soup 6
->>>>>>> c1d7493 (Raise prices, add specials, hours and drinks)
+Soup 5.5
 Bread 2
 Salad 5
 Cake 3
diff --git a/specials.txt b/specials.txt
deleted file mode 100644
remerge CONFLICT (modify/delete): specials.txt deleted in d95d995 (Update the menu, drop specials, add hours) and modified in c1d7493 (Raise prices, add specials, hours and drinks).  Version c1d7493 (Raise prices, add specials, hours and drinks) of specials.txt left in tree.
index 5baba8f..0000000
--- a/specials.txt
+++ /dev/null
@@ -1,2 +0,0 @@
-Monday: pie
-Tuesday: soup of the day
```

`--remerge-diff` (Chapter 17) redoes the merge, conflicts and all, and compares
that with the commit. Every conflict appears with its `remerge CONFLICT` line and
what replaced it, including the three resolved by taking a side. This is the
form to use when reviewing someone else's merge.

## restore and checkout during a conflict

### What they refuse

```console
$ git switch -q -C try main
$ git merge prices >/dev/null
$ git restore hours.txt
error: path 'hours.txt' is unmerged
$ git checkout -- hours.txt
error: path 'hours.txt' is unmerged
$ git checkout -f -- hours.txt
warning: path 'hours.txt' is unmerged
$ git status --short
A  drinks.txt
AA hours.txt
UU logo.png
UU menu.txt
DU specials.txt
```

Both commands refuse to restore a conflicted file from the index without being
told which version. `git checkout -f` skips it with a warning instead, and
`git restore --ignore-unmerged` does the same (Chapter 14); either way the file
is untouched and still in conflict. They matter when restoring many files at
once, some of them conflicted.

### Taking a side for many files

```console
$ git checkout --theirs .
Updated 4 paths from the index
$ git status --short
A  drinks.txt
AA hours.txt
UU logo.png
UU menu.txt
DU specials.txt
$ cat hours.txt
Mon-Fri 8-18
```

`--theirs` with `.` wrote their version of every conflicted file. The status is
unchanged: taking a side only writes the working tree file, and the file stays
unmerged until `git add`. That gives you a chance to look before staging.

> **Careful.** `--ours` and `--theirs` take the whole file from one side, not
> only the conflicting lines. `hours.txt` here is simple, but on `menu.txt`
> `--theirs` would also undo `main`'s juice price, which was never in conflict.
> Stage 3 is `prices`' file exactly as [the three versions in the
> index](#the-three-versions-in-the-index) showed.

### A file one side deleted

```console
$ git checkout --ours specials.txt
error: path 'specials.txt' does not have our version
$ ls specials.txt
specials.txt
$ git restore --ours -- '*.txt'
$ cat hours.txt
Mon-Sat 7-19
$ ls specials.txt
ls: cannot access 'specials.txt': No such file or directory
$ git merge --abort
```

`specials.txt` has no stage 2. `git checkout --ours` refuses; `git restore --ours`
takes "our version does not exist" at its word and deletes the file, without a
message. Here `'*.txt'` is quoted so that Git, not the shell, matches the
pattern (Chapter 11), and it matched `specials.txt` along with the rest.

### During a rebase the sides swap

```console
$ git switch -q -C try prices
$ git rebase main
Rebasing (1/1)
Auto-merging hours.txt
CONFLICT (add/add): Merge conflict in hours.txt
warning: Cannot merge binary files: logo.png (HEAD vs. c1d7493 (Raise prices, add specials, hours and drinks))
Auto-merging logo.png
CONFLICT (content): Merge conflict in logo.png
Auto-merging menu.txt
CONFLICT (content): Merge conflict in menu.txt
CONFLICT (modify/delete): specials.txt deleted in HEAD and modified in c1d7493 (Raise prices, add specials, hours and drinks).  Version c1d7493 (Raise prices, add specials, hours and drinks) of specials.txt left in tree.
error: could not apply c1d7493... Raise prices, add specials, hours and drinks
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
Could not apply c1d7493... # Raise prices, add specials, hours and drinks
$ head -5 menu.txt
<<<<<<< HEAD
Soup 5
=======
Soup 6
>>>>>>> c1d7493 (Raise prices, add specials, hours and drinks)
$ git checkout --ours menu.txt
Updated 1 path from the index
$ head -1 menu.txt
Soup 5
$ git checkout --theirs menu.txt
Updated 1 path from the index
$ head -1 menu.txt
Soup 6
$ git rebase --abort
```

A rebase on `try` (a copy of `prices`) replays its commit on top of `main`. The
commit being built on is `HEAD`, which is `main`'s side, and the commit being
replayed, your own work, is "theirs". So `--ours` gave `main`'s `Soup 5`.
Chapter 33 explains rebasing.

`Rebasing (1/1)` ends with a carriage return, so a terminal draws the next line
over it. The `Rebasing` line, the `error:` and `hint:` lines and the last line
go to standard error; the `Auto-merging`, `CONFLICT` and `warning:` lines go to
standard output, and Git prints them in the order shown.

## Other kinds of conflict

### Renamed to two different names

```console
$ git switch -q -C try left
$ git merge right
CONFLICT (rename/rename): notes.txt renamed to notes.md in HEAD and to todo.txt in right.
Automatic merge failed; fix conflicts and then commit the result.
$ git status --short
AU notes.md
DD notes.txt
UA todo.txt
$ git ls-files -u
100644 3d4a7b0b522540c7a8bfab5451a77391062c23e7 2	notes.md
100644 3d4a7b0b522540c7a8bfab5451a77391062c23e7 1	notes.txt
100644 3d4a7b0b522540c7a8bfab5451a77391062c23e7 3	todo.txt
$ git rm notes.txt notes.md
rm 'notes.md'
rm 'notes.txt'
$ git add todo.txt
$ git status --short
R  notes.md -> todo.txt
$ git merge --abort
```

`left` renamed `notes.txt` to `notes.md`, `right` to `todo.txt`. Git records the
disagreement as three entries holding the same blob: the old name at stage 1
only, our new name at stage 2 only, their new name at stage 3 only. To resolve
it, choose a name: remove the old name and the name you do not want, and add the
one you do. The status compares with `HEAD`, where the file was `notes.md`, so it
shows the rename to `todo.txt`.

### Renamed on one side, deleted on the other

```console
$ git switch -q -C try left
$ git merge gone
CONFLICT (rename/delete): notes.txt renamed to notes.md in HEAD, but deleted in gone.
Automatic merge failed; fix conflicts and then commit the result.
$ git status --short
UD notes.md
$ git rm notes.md
rm 'notes.md'
$ git status --short
D  notes.md
$ git merge --abort
$ git switch -q -C try gone
$ git merge left
CONFLICT (rename/delete): notes.txt renamed to notes.md in left, but deleted in HEAD.
Automatic merge failed; fix conflicts and then commit the result.
$ git status --short
DU notes.md
$ git add notes.md
$ git status --short
A  notes.md
$ git merge --abort
```

The conflict sits under the new name, and resolving it is the same choice as a
modify/delete: `git rm` accepts the deletion, `git add` keeps the renamed file.
`UD` means deleted by them, `DU` deleted by us.

### A file against a directory

```console
$ git switch -q -C try dir-side
$ git merge file-side
CONFLICT (file/directory): directory in the way of kitchen from file-side; moving it to kitchen~file-side instead.
Automatic merge failed; fix conflicts and then commit the result.
$ git status --short
UA kitchen~file-side
$ ls
hours.txt
kitchen
kitchen~file-side
logo.png
menu.txt
notes.txt
$ git mv kitchen~file-side kitchen.txt
fatal: conflicted, source=kitchen~file-side, destination=kitchen.txt
$ mv kitchen~file-side kitchen.txt
$ git add kitchen.txt kitchen~file-side
$ git status --short
A  kitchen.txt
$ git merge --abort
```

`dir-side` has a directory `kitchen`, `file-side` a file with that name, and a
path cannot be both. Git kept the directory and wrote their file as
`kitchen~file-side`, the name followed by `~` and the branch. `git mv` refuses
to move a conflicted file, so rename it with the shell's `mv` and give
`git add` both names: the new one to add it, the old one to record that it is
gone.

## Conflicts from other commands

```console
$ git switch -q -C try main
$ git cherry-pick prices >/dev/null
error: could not apply c1d7493... Raise prices, add specials, hours and drinks
hint: After resolving the conflicts, mark them with
hint: "git add/rm <pathspec>", then run
hint: "git cherry-pick --continue".
hint: You can instead skip this commit with "git cherry-pick --skip".
hint: To abort and get back to the state before "git cherry-pick",
hint: run "git cherry-pick --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
$ head -5 menu.txt
<<<<<<< HEAD
Soup 5
=======
Soup 6
>>>>>>> c1d7493 (Raise prices, add specials, hours and drinks)
$ git log --merge --oneline --left-right
< d95d995 Update the menu, drop specials, add hours
> c1d7493 Raise prices, add specials, hours and drinks
$ git cherry-pick --abort
```

`>/dev/null` hides the conflict list on standard output, leaving the error and
hints. The theirs label is the picked commit. `git log --merge` works here too,
using the commit being picked in place of `MERGE_HEAD` (Chapter 32 covers
cherry-pick).

> **Since Git 2.45.** `git log --merge` during a cherry-pick, revert or rebase.
> Before, it needed `MERGE_HEAD`.

Before the next `git stash`, `menu.txt` had an uncommitted change setting the
soup to 7:

```console
$ git switch -q -C try main~1
$ git stash -q
$ git merge -q --ff-only prices
$ git stash pop
Auto-merging menu.txt
CONFLICT (content): Merge conflict in menu.txt
On branch try
Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
	both modified:   menu.txt

no changes added to commit (use "git add" and/or "git commit -a")
The stash entry is kept in case you need it again.
$ head -5 menu.txt
<<<<<<< Updated upstream
Soup 6
Bread 2
=======
Soup 7
$ git reset -q --hard
$ git stash drop
Dropped refs/stash@{0} (b6618d7a24bb5081cc8f411af686408fd72a8d6d)
```

The branch moved on to `prices` while the change was stashed, and popping it
conflicted. The stash is kept when that happens, so here the conflict was thrown
away with `git reset --hard` and the stash dropped (Chapter 55 covers stash).

| Command that stopped | Label on our side | Label on their side |
|---|---|---|
| `git merge <branch>` | `HEAD` | the branch name |
| `git rebase` | `HEAD`, the commit being built on | the commit being replayed, with its title |
| `git cherry-pick` | `HEAD` | the picked commit, with its title |
| `git stash pop` | `Updated upstream` | `Stashed changes` |
| `git restore -m`, `git checkout -m <path>` | `ours` | `theirs` |
| `git merge-file` | the first file's name, or `-L` | the third file's name, or `-L` |

## git mergetool

`git mergetool` starts a separate merge program on each conflicted file, one
after another, and stages each file the program resolves. The programs are the
ones with three panes showing ours, theirs and the result.

### Which tools there are

```console
$ git switch -q -C try main
$ git merge prices >/dev/null
$ git mergetool --tool-help | sed -n '1,4p'
'git mergetool --tool=<tool>' may be set to one of the following:
		vimdiff          Use Vim with a custom layout (see `git help mergetool`'s `BACKEND SPECIFIC HINTS` section)
		vimdiff1         Use Vim with a 2 panes layout (LOCAL and REMOTE)
		vimdiff2         Use Vim with a 3 panes layout (LOCAL, MERGED and REMOTE)
```

The list depends on what is installed; this is its start on the machine that
ran the examples, trimmed with `sed -n '1,4p'`. The full output goes on to list
tools Git knows but could not find, under "The following tools are valid, but
not currently available", including `meld`, `kdiff3`, `p4merge`, `tortoisemerge`
and `winmerge`. With no tool configured, `git mergetool` says so, names
the tools it will try, and asks before starting the first one it finds.

### A tool of your own

A real tool opens a window and waits for you, which a transcript cannot show. So
the examples define their own tool, which resolves every file by copying their
version over it:

```console
$ git config set mergetool.take-theirs.cmd 'cp "$REMOTE" "$MERGED"'
$ git config set mergetool.take-theirs.trustExitCode true
```

`mergetool.<tool>.cmd` is a shell command, run with these variables set:

| Variable | Holds the name of |
|---|---|
| `$LOCAL` | a temporary file with our version |
| `$REMOTE` | a temporary file with their version |
| `$BASE` | a temporary file with the base version, when there is one |
| `$MERGED` | the file in your working tree, where the result must go |

With `trustExitCode`, the command's exit status says whether it resolved the
file. Without it, Git's documentation says `git mergetool` checks whether the
file changed and, if it did not, asks you. This is also how you use any program
Git has no built-in support for. For a program it knows, set
`git config set merge.tool meld` (or whichever you have) and nothing else.

> **Windows.** Tested outside the sandbox in Windows PowerShell 5.1: the command
> `git config set mergetool.take-theirs.cmd 'cp "$REMOTE" "$MERGED"'` stored
> `cp $REMOTE $MERGED`, without the inner quotes, so a file name with a space
> would be split. Writing `'cp \"$REMOTE\" \"$MERGED\"'` stored it correctly.
> Check with `git config get mergetool.take-theirs.cmd`. The command runs in the
> shell that comes with Git for Windows, so `cp` worked when `git mergetool` was
> started from PowerShell.

### Running the tool

```console
$ git mergetool --tool=take-theirs menu.txt
Merging:
menu.txt

Normal merge conflict for 'menu.txt':
  {local}: modified file
  {remote}: modified file
$ git status --short
A  drinks.txt
AA hours.txt
UU logo.png
M  menu.txt
DU specials.txt
?? menu.txt.orig
$ head -1 menu.txt
Soup 6
```

`{local}` is ours and `{remote}` theirs, the same words as the variables. The
tool reported success, so `git mergetool` staged `menu.txt`. It also left
`menu.txt.orig`, the file as it was before the tool ran, markers and all, as an
untracked backup to delete once you are satisfied. Given no file names,
`git mergetool` works through every conflicted file. `-t take-theirs` is the
short form of `--tool=take-theirs`.

### A deleted file

```console
$ printf 'd\n' | git mergetool --tool=take-theirs specials.txt; echo
Merging:
specials.txt

Deleted merge conflict for 'specials.txt':
  {local}: deleted
  {remote}: modified file
Use (m)odified or (d)eleted file, or (a)bort? 
$ git status --short
A  drinks.txt
AA hours.txt
UU logo.png
M  menu.txt
?? menu.txt.orig
```

No merge program is started for a modify/delete conflict; `git mergetool` asks.
`printf 'd\n' |` types `d` and Enter, as you would at the question, and `; echo`
ends the line, because typed input that comes through a pipe is not shown. `d`
removed the file with `git rm`; `m` keeps the changed file, as [Order and
backup files](#order-and-backup-files) shows. When the base has no such file, the question offers `(c)reated` in place of
`(m)odified`.

### Prompting before each file

```console
$ printf '\n' | git mergetool --prompt --tool=take-theirs hours.txt; echo
Merging:
hours.txt

Normal merge conflict for 'hours.txt':
  {local}: created file
  {remote}: created file
Hit return to start merge resolution tool (take-theirs): 
$ git status --short
A  drinks.txt
M  hours.txt
UU logo.png
M  menu.txt
?? hours.txt.orig
?? menu.txt.orig
```

When you name a tool, with `--tool` or `merge.tool`, `git mergetool` starts it
without asking. `--prompt`, or `mergetool.prompt=true`, makes it ask first on
each file; Enter starts the tool. It also asks when it had to guess the tool.

### Graphical tools

```console
$ git -c merge.guitool=take-theirs mergetool -g logo.png
Merging:
logo.png

Normal merge conflict for 'logo.png':
  {local}: modified file
  {remote}: modified file
$ git status --short
A  drinks.txt
M  hours.txt
M  logo.png
M  menu.txt
?? hours.txt.orig
?? logo.png.orig
?? menu.txt.orig
$ git merge --abort
$ rm *.orig
$ git merge prices >/dev/null
$ git -c merge.tool=take-theirs -c merge.guitool=nosuch mergetool --gui --no-gui logo.png
Merging:
logo.png

Normal merge conflict for 'logo.png':
  {local}: modified file
  {remote}: modified file
```

`merge.tool` and `merge.guitool` let you configure two tools: a terminal one and
one that opens a window. `-g` or `--gui` uses `merge.guitool`; no `merge.tool`
was set here, and `take-theirs` from `merge.guitool` ran. `--no-gui` cancels an
earlier `--gui`: `merge.guitool` named a tool that does not exist, and the
command still worked, with `merge.tool`. Git's documentation says `-g` falls back
to `merge.tool` when `merge.guitool` is not set, and that
`mergetool.guiDefault=true` makes `-g` the default, while `auto` uses the
graphical tool when a display is available.

> **Since Git 2.41.** `mergetool.guiDefault`.

### Order and backup files

```console
$ printf 'm\n' | git mergetool -t take-theirs specials.txt; echo
Merging:
specials.txt

Deleted merge conflict for 'specials.txt':
  {local}: deleted
  {remote}: modified file
Use (m)odified or (d)eleted file, or (a)bort? 
$ git status --short
A  drinks.txt
AA hours.txt
M  logo.png
UU menu.txt
A  specials.txt
?? logo.png.orig
?? specials.txt.orig
$ git merge --abort
$ rm *.orig
$ git merge prices >/dev/null
$ printf 'menu.txt\nhours.txt\n' > order
$ printf 'd\n' | git -c mergetool.prompt=true -c mergetool.keepBackup=false mergetool -y -Oorder --tool=take-theirs; echo
Merging:
menu.txt
hours.txt
logo.png
specials.txt

Normal merge conflict for 'menu.txt':
  {local}: modified file
  {remote}: modified file

Normal merge conflict for 'hours.txt':
  {local}: created file
  {remote}: created file

Normal merge conflict for 'logo.png':
  {local}: modified file
  {remote}: modified file

Deleted merge conflict for 'specials.txt':
  {local}: deleted
  {remote}: modified file
Use (m)odified or (d)eleted file, or (a)bort? 
$ git status --short
A  drinks.txt
M  hours.txt
M  logo.png
M  menu.txt
?? order
$ git merge --abort
$ rm order
```

`m` kept the modified `specials.txt`, staged as added, with a backup like any
other.

Without file names, `git mergetool` takes the conflicted files in the order
`git diff --name-only --diff-filter=U` gives them, which is by path unless
`diff.orderFile` says otherwise. `-O<orderfile>` names a file of patterns, one
per line, and matching files come first: `menu.txt`, then `hours.txt`, then the
rest. Note there is no space after `-O`.

`-y`, or `--no-prompt`, starts the tool without asking even though
`mergetool.prompt=true` was set; the only question left was the one about the
deleted file, which is not a prompt to start the tool. With
`mergetool.keepBackup=false` no `.orig` files were left. `order` is the pattern
file, untracked.

## git rerere

*rerere* stands for "reuse recorded resolution". When it is on, Git records each
conflict it meets, and when you commit, how you resolved it. When the same
conflict appears again, Git writes your earlier resolution into the file. It
helps when the same merge happens more than once: merging a long-lived branch
repeatedly, redoing a rebase you abandoned, or trying a merge to test and
throwing it away. Commands that merge run it themselves, and the `git rerere`
subcommands only look at or manage its records.

### Recording a resolution

```console
$ git config set rerere.enabled true
$ git switch -q -C try main
$ git merge prices
Auto-merging hours.txt
CONFLICT (add/add): Merge conflict in hours.txt
warning: Cannot merge binary files: logo.png (HEAD vs. prices)
Auto-merging logo.png
CONFLICT (content): Merge conflict in logo.png
Auto-merging menu.txt
CONFLICT (content): Merge conflict in menu.txt
CONFLICT (modify/delete): specials.txt deleted in HEAD and modified in prices.  Version prices of specials.txt left in tree.
Recorded preimage for 'hours.txt'
Recorded preimage for 'menu.txt'
Automatic merge failed; fix conflicts and then commit the result.
$ git rerere status
hours.txt
menu.txt
```

The *preimage* is the conflict as Git wrote it. rerere records one for each file
with conflict markers, so not for the binary `logo.png` or the modify/delete
`specials.txt`. The two `Recorded preimage` lines go to standard error and the
others to standard output; Git prints them in this order, recording the
preimages just before the last line. `git rerere status` lists the files whose
resolution will be recorded.

```console
$ printf 'Soup 5.5\nBread 2\nSalad 5\nCake 3\nPie 4\nBun 2\nTart 5\nScone 2\nMuffin 3\nCookie 1\nJuice 3\n' > menu.txt
$ git rerere diff
--- a/hours.txt
+++ b/hours.txt
@@ -1,5 +1,5 @@
-<<<<<<<
-Mon-Fri 8-18
-=======
+<<<<<<< HEAD
 Mon-Sat 7-19
->>>>>>>
+=======
+Mon-Fri 8-18
+>>>>>>> prices
--- a/menu.txt
+++ b/menu.txt
@@ -1,8 +1,4 @@
-<<<<<<<
-Soup 5
-=======
-Soup 6
->>>>>>>
+Soup 5.5
 Bread 2
 Salad 5
 Cake 3
$ git rerere remaining
hours.txt
menu.txt
specials.txt
$ printf 'Mon-Fri 8-18\nSat 7-19\n' > hours.txt
$ git add menu.txt hours.txt logo.png
$ git rm -q specials.txt
$ git commit --no-edit
Recorded resolution for 'hours.txt'.
Recorded resolution for 'menu.txt'.
[try e5151b9] Merge branch 'prices' into try
$ ls .git/rr-cache
273b0a9dbac82652aab4a69ae76b5564c89de62e
2da0296565a68e544a957197b54abf91450eab45
```

`git rerere diff` compares each recorded preimage with the file now. `menu.txt`
is resolved; `hours.txt` is still the conflict, but the recorded version looks
different: its markers have no labels and `Mon-Fri` comes first. rerere
*normalizes* a conflict before recording it, removing the labels and sorting the
two sides, as described in Git's technical notes on rerere; the next examples
show why. `git rerere remaining` lists the conflicted files rerere has not
resolved, including `specials.txt`, which it cannot handle.

The resolutions were recorded when the merge was committed, in `.git/rr-cache`,
one directory for each conflict. The `Recorded resolution` lines go to standard
error and the last line to standard output, and Git records the resolutions
before printing it.

### Reusing a resolution

```console
$ git switch -q -C try main
$ git merge prices
Auto-merging hours.txt
CONFLICT (add/add): Merge conflict in hours.txt
warning: Cannot merge binary files: logo.png (HEAD vs. prices)
Auto-merging logo.png
CONFLICT (content): Merge conflict in logo.png
Auto-merging menu.txt
CONFLICT (content): Merge conflict in menu.txt
CONFLICT (modify/delete): specials.txt deleted in HEAD and modified in prices.  Version prices of specials.txt left in tree.
Resolved 'hours.txt' using previous resolution.
Resolved 'menu.txt' using previous resolution.
Automatic merge failed; fix conflicts and then commit the result.
$ cat hours.txt
Mon-Fri 8-18
Sat 7-19
$ git status --short
A  drinks.txt
AA hours.txt
UU logo.png
UU menu.txt
DU specials.txt
$ git rerere remaining
specials.txt
$ git merge --abort
```

The same merge again: Git met the same two conflicts and wrote the recorded
resolutions into the files. The merge still stops, and the files are still
unmerged: rerere does not stage what it did, so you can check it. `logo.png` and
`specials.txt` still need you. `git rerere remaining` lists `specials.txt` but not
`logo.png`, although the logo is still in conflict: it lists only files rerere
tracked, or could not handle, and it never tracked the binary file.

### Merging the other way round

```console
$ git switch -q -C try prices
$ git merge main >/dev/null
Resolved 'hours.txt' using previous resolution.
Resolved 'menu.txt' using previous resolution.
$ cat hours.txt
Mon-Fri 8-18
Sat 7-19
$ git merge --abort
$ git switch -q -C try main
```

Merging `main` into `prices` swaps ours and theirs, and the labels change.
Normalizing makes it the same conflict, so the resolution still applied.

### Staging reused resolutions

```console
$ git merge --rerere-autoupdate prices >/dev/null
Staged 'hours.txt' using previous resolution.
Staged 'menu.txt' using previous resolution.
$ git status --short
A  drinks.txt
M  hours.txt
UU logo.png
M  menu.txt
DU specials.txt
$ git merge --abort
$ git -c rerere.autoUpdate=true merge prices >/dev/null
Staged 'hours.txt' using previous resolution.
Staged 'menu.txt' using previous resolution.
$ git status --short
A  drinks.txt
M  hours.txt
UU logo.png
M  menu.txt
DU specials.txt
$ git merge --abort
$ git -c rerere.autoUpdate=true merge --no-rerere-autoupdate prices >/dev/null
Resolved 'hours.txt' using previous resolution.
Resolved 'menu.txt' using previous resolution.
$ git status --short
A  drinks.txt
AA hours.txt
UU logo.png
UU menu.txt
DU specials.txt
```

`--rerere-autoupdate` stages each file rerere resolved, and the message says
`Staged`. `rerere.autoUpdate=true` makes that the default, and
`--no-rerere-autoupdate` overrides it for one command. `git rebase`,
`git cherry-pick`, `git revert` and `git am` take the same two options.

Leave it off. A resolution that was right for one merge can be wrong when the
code around it has changed, and Git's documentation recommends
`--no-rerere-autoupdate` as a way to check what rerere did before staging.

### Forgetting a resolution

```console
$ git rerere forget menu.txt
Updated preimage for 'menu.txt'
Forgot resolution for 'menu.txt'
$ head -5 menu.txt
Soup 5.5
Bread 2
Salad 5
Cake 3
Pie 4
$ git rerere clear
$ git merge --abort
$ git rerere gc
```

`git rerere forget` throws away the recorded resolution of the conflict now in
`menu.txt`, and records the conflict again as a new preimage, ready for a better
resolution. The file keeps what is in it, here the reused resolution; use
`git restore -m menu.txt` to get the markers back. Both lines go to standard
error.

`git rerere clear` drops what rerere is tracking for the conflict in progress,
without touching recorded resolutions; Git's documentation says
`git rebase --skip`, `git rebase --abort`, `git am --skip` and `git am --abort`
run it for you. `git rerere gc` deletes records of conflicts: by default,
unresolved ones older than 15 days and resolved ones older than 60, set by
`gc.rerereUnresolved` and `gc.rerereResolved`. The ones here were minutes old,
so it printed nothing. `git gc` runs it too (Chapter 77).

### rerere and mergetool

This merge runs while rerere is still active, as the next section explains.
`menu.txt`'s resolution was forgotten above; `hours.txt`'s was not.

```console
$ git config unset rerere.enabled
$ git merge prices >/dev/null
Resolved 'hours.txt' using previous resolution.
Recorded preimage for 'menu.txt'
$ printf 'd\n' | git mergetool --tool=take-theirs; echo
Merging:
menu.txt
specials.txt

Normal merge conflict for 'menu.txt':
  {local}: modified file
  {remote}: modified file

Deleted merge conflict for 'specials.txt':
  {local}: deleted
  {remote}: modified file
Use (m)odified or (d)eleted file, or (a)bort? 
$ git status --short
A  drinks.txt
AA hours.txt
UU logo.png
M  menu.txt
?? menu.txt.orig
$ git merge --abort
$ rm *.orig
```

With no file names, `git mergetool` worked through `menu.txt` and `specials.txt`
only. When rerere has a record of the merge in progress, `git mergetool` asks
`git rerere remaining` which files to take. That skips `hours.txt`, which rerere
resolved but did not stage, and `logo.png`, which rerere never tracked. Both are
still unmerged. Without rerere, the same command took all four files, as [Order
and backup files](#order-and-backup-files) showed.

> **Careful.** With rerere on, run `git status` after `git mergetool`, or name
> the files. A binary conflict can be left behind without a word.

### Turning rerere off

```console
$ git config set rerere.enabled false
$ git merge prices >/dev/null
$ git merge --abort
```

The merge before `git mergetool` above showed that removing the setting did not
turn rerere off. Git's documentation says why: with no setting, rerere is on
whenever `.git/rr-cache` exists, which it does once rerere has been used. Set
`rerere.enabled` to `false`, as here, and the merge printed nothing on standard
error. Deleting `.git/rr-cache` throws the records away.

## git merge-file

`git merge-file` does the line-by-line merge of `git merge` on three ordinary
files. It needs no repository and no index: the examples in this section, until
the last one, run in a plain directory. It is for merging files Git does not
track, for scripts, and for redoing the merge of one file by hand.

### Merging three files

The directory holds `base.txt` with two lines, `Soup 4` and `Salad 5`, and two
changed copies: `ours.txt` with `Soup 5`, `Bread 2`, `Salad 5`, and `theirs.txt`
with `Soup 6`, `Bread 2`, `Salad 5`.

```console
$ cd ../files
$ git merge-file -p ours.txt base.txt theirs.txt; echo "exit $?"
<<<<<<< ours.txt
Soup 5
=======
Soup 6
>>>>>>> theirs.txt
Bread 2
Salad 5
exit 1
```

The base goes in the middle, as the synopsis says. `-p` prints the result
instead of writing it into `ours.txt`. The labels are the file names. The exit
code, printed by `echo "exit $?"`, is the number of conflicts: 1.

### Styles and the setting

```console
$ git merge-file -p --diff3 ours.txt base.txt theirs.txt
<<<<<<< ours.txt
Soup 5
Bread 2
||||||| base.txt
Soup 4
=======
Soup 6
Bread 2
>>>>>>> theirs.txt
Salad 5
$ git merge-file -p --zdiff3 ours.txt base.txt theirs.txt
<<<<<<< ours.txt
Soup 5
||||||| base.txt
Soup 4
=======
Soup 6
>>>>>>> theirs.txt
Bread 2
Salad 5
$ git -c merge.conflictStyle=diff3 merge-file -p ours.txt base.txt theirs.txt
<<<<<<< ours.txt
Soup 5
=======
Soup 6
>>>>>>> theirs.txt
Bread 2
Salad 5
```

`--diff3` and `--zdiff3` are the styles from [Conflict
styles](#conflict-styles). Git's documentation says they default to
`merge.conflictStyle`, but outside a repository `git merge-file` ignored the
setting, even given with `-c`. Inside a repository it follows it, as [Blobs
instead of files](#blobs-instead-of-files) shows.

### Taking one side

```console
$ git merge-file -p --ours ours.txt base.txt theirs.txt; echo "exit $?"
Soup 5
Bread 2
Salad 5
exit 0
$ git merge-file -p --theirs ours.txt base.txt theirs.txt
Soup 6
Bread 2
Salad 5
$ git merge-file -p --union ours.txt base.txt theirs.txt
Soup 5
Soup 6
Bread 2
Salad 5
```

`--ours` and `--theirs` resolve each conflict with one side's lines, and the
exit code becomes 0. `--union` keeps both sides' lines, ours first, with no
markers. It suits a list where every entry should be kept, and makes nonsense of
anything else: the menu now has two soup prices. Chapter 27 shows the `union`
merge driver, which does this inside `git merge`.

### Labels and marker length

```console
$ git merge-file -p -L mine -L original -L yours ours.txt base.txt theirs.txt
<<<<<<< mine
Soup 5
=======
Soup 6
>>>>>>> yours
Bread 2
Salad 5
$ git merge-file -p --marker-size=3 ours.txt base.txt theirs.txt
<<< ours.txt
Soup 5
===
Soup 6
>>> theirs.txt
Bread 2
Salad 5
```

`-L` replaces the labels in order: ours, base, theirs. The base label only shows
in the `diff3` styles. `--marker-size` does what the `conflict-marker-size`
attribute does in a merge.

### Writing into the file

```console
$ cp ours.txt result.txt
$ git merge-file result.txt base.txt theirs.txt; echo "exit $?"
exit 1
$ cat result.txt
<<<<<<< result.txt
Soup 5
=======
Soup 6
>>>>>>> theirs.txt
Bread 2
Salad 5
```

Without `-p`, the result overwrites the first file and nothing is printed, so
the first label is that file's name. Copy the file first if you want to keep it.

### How many conflicts

`near-base.txt` has five menu lines. `near-ours.txt` changes the first and last,
to `Soup 5` and `Bun 3`; `near-theirs.txt` changes them to `Soup 6` and `Bun 4`.
Three unchanged lines lie between the two changes. The `far-` files do the same
to a ten-line menu, changing the soup and the juice, with eight lines between.

```console
$ git merge-file -p near-ours.txt near-base.txt near-theirs.txt; echo "exit $?"
<<<<<<< near-ours.txt
Soup 5
Salad 5
Cake 3
Pie 4
Bun 3
=======
Soup 6
Salad 5
Cake 3
Pie 4
Bun 4
>>>>>>> near-theirs.txt
exit 1
$ git merge-file -p far-ours.txt far-base.txt far-theirs.txt >/dev/null; echo "exit $?"
exit 2
```

Two conflicts with three or fewer lines between them were joined into one
block, the unchanged lines repeated on each side: exit 1. Eight lines apart they
stay two conflicts: exit 2. Git's merge code (`xdiff/xmerge.c` in its source)
does the joining, because one larger block is easier to read than two blocks
with a few lines between, and `git merge` uses the same code. `git merge-file`
also joins conflicts separated by any number of lines that have no letters or
digits in them, such as blank lines. Git's documentation caps the exit code at
127, and makes it negative on an error.

### Binary files and -q

The next three files are small binary files like the repository's logo.

```console
$ git merge-file ours.png base.png theirs.png; echo "exit $?"
error: Cannot merge binary files: ours.png
exit 255
$ git merge-file -q ours.png base.png theirs.png; echo "exit $?"
exit 255
```

`git merge-file` refuses binary files, and its negative error code shows in the
shell as 255. `-q` removed the message and kept the exit code. Its help says it
stops warnings about conflicts, but no conflict in this section printed one; in
Git's source, `-q` sends all error messages nowhere.

### Blobs instead of files

```console
$ cd ../cafe
$ git merge-file -p --object-id main:menu.txt main~1:menu.txt prices:menu.txt | head -5
<<<<<<< main:menu.txt
Soup 5
=======
Soup 6
>>>>>>> prices:menu.txt
$ git -c merge.conflictStyle=diff3 merge-file -p --object-id main:menu.txt main~1:menu.txt prices:menu.txt | head -9
<<<<<<< main:menu.txt
Soup 5
Bread 2
||||||| main~1:menu.txt
Soup 4
=======
Soup 6
Bread 2
>>>>>>> prices:menu.txt
$ git merge-file --object-id main:menu.txt main~1:menu.txt prices:menu.txt
46e879f0aa8eeec06fc507a6a903fbf6a672050a
$ git cat-file -p 46e879f | head -5
<<<<<<< main:menu.txt
Soup 5
=======
Soup 6
>>>>>>> prices:menu.txt
```

Back in the cafe repository, `--object-id` takes three blobs, here named as
`<commit>:<path>` (Chapter 18), and the labels are those names. `main~1` is the
merge base. Inside the repository `merge.conflictStyle` applied. Without `-p` the
result is stored as a blob and its hash printed, which a script can put into a
tree without touching any file. `git cat-file -p` prints an object (Chapter 4).

## Conflicts and their neighbours

```console
$ diff3 -m ours.txt base.txt theirs.txt
<<<<<<< ours.txt
Soup 5
Bread 2
||||||| base.txt
Soup 4
=======
Soup 6
Bread 2
>>>>>>> theirs.txt
Salad 5
```

`diff3 -m` from GNU diffutils merges three files the same way, and printed
exactly what `git merge-file -p --diff3` printed for them, in the same argument
order. `git merge-file` defaults to the shorter style, has `zdiff3`, and can take
blobs. Git for Windows includes `diff3` in Git Bash.

Four ways to "take our side" look alike and do different things:

| Command | Takes | Where |
|---|---|---|
| `git checkout --ours <path>`, `git restore --ours <path>` | our whole file, stage 2, including undoing their changes that never conflicted | one conflicted file, after the merge stopped |
| `git merge-file --ours` | our side of each conflict, everything else merged | three files |
| `git merge -X ours` | our side of each conflict, everything else merged | during a merge (Chapter 27) |
| `git merge -s ours` | our whole tree, ignoring everything the other branch did | during a merge (Chapter 27) |

Which diff to read while resolving:

| Command | Compares the file with | Good for |
|---|---|---|
| `git diff` | our and their version at once | seeing each conflict with both sides |
| `git diff --base <path>`, `-1` | the base | everything both sides changed |
| `git diff --ours <path>`, `-2`, `git diff HEAD` | our version | what the merge will change in your branch |
| `git diff --theirs <path>`, `-3`, `git diff MERGE_HEAD` | their version | what the merge will change in theirs |
| `git diff AUTO_MERGE` | what Git wrote into the file | your own edits so far |
| `git diff --cached --check` | (index against `HEAD`) | markers you already staged |
| `git log --merge -p <path>` | (each side's commits) | why each side made its change |
| `git show --remerge-diff` | (after the commit: the conflicts against the result) | reviewing a finished merge |

By hand, with a tool, or with rerere: edit by hand when the conflicts are few
and short, with `zdiff3` markers and `git log --merge -p` beside you; it is the
only way that works everywhere. A graphical tool
pays off for long conflicts in code, where seeing three panes side by side
matters. Turn rerere on everywhere (Chapter 3); it costs nothing until a
conflict repeats, and then it saves the work. Whichever you use, finish with
`git diff --cached --check` and `git status`.

## The settings

| Setting | Effect |
|---|---|
| `merge.conflictStyle` | `merge`, `diff3` or `zdiff3`: how conflicts are written into files |
| `merge.tool` | The tool `git mergetool` starts |
| `merge.guitool` | The tool `git mergetool -g` starts |
| `mergetool.<tool>.cmd` | The command for a tool Git does not know |
| `mergetool.<tool>.path` | Where to find a tool's program, when it is not on the `PATH` |
| `mergetool.<tool>.trustExitCode` | Whether a custom tool's exit status says it resolved the file |
| `mergetool.hideResolved`, `mergetool.<tool>.hideResolved` | Give the tool, in `$LOCAL` and `$REMOTE`, only the parts Git could not resolve; `false` by default |
| `mergetool.keepBackup` | Keep `.orig` backups; `true` by default |
| `mergetool.keepTemporaries` | Keep the `$LOCAL`, `$REMOTE` and `$BASE` files when a custom tool fails |
| `mergetool.writeToTemp` | Write those files to a temporary directory instead of beside the file |
| `mergetool.prompt` | Ask before starting the tool on each file |
| `mergetool.guiDefault` | `true` or `auto`: use `merge.guitool` without `-g` |
| `mergetool.<variant>.layout` | The window layout for `vimdiff`, `nvimdiff` and `gvimdiff` |
| `mergetool.meld.hasOutput`, `mergetool.meld.useAutoMerge` | Options for the `meld` tool |
| `diff.orderFile` | The order `git mergetool` works through files, as `-O` does |
| `rerere.enabled` | Record and reuse resolutions; when unset, on if `.git/rr-cache` exists |
| `rerere.autoUpdate` | Stage the resolutions rerere reuses |
| `gc.rerereResolved`, `gc.rerereUnresolved` | How long `git rerere gc` keeps records; 60 and 15 days |
| `advice.mergeConflict` | Whether commands that stop on a conflict print their `hint:` lines |

> **Since Git 2.31.** `mergetool.hideResolved`.
>
> **Since Git 2.45.** `advice.mergeConflict`.
