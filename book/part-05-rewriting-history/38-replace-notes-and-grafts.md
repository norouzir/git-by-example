# Chapter 38. replace, notes, and grafts

## What it is

Two commands that change what Git *shows* without changing what Git *stores*.

`git replace` tells Git to use one object wherever another is asked for, so a
commit can appear to have a different message, different content or different
parents while the original is untouched. `git notes` attaches text to a commit
afterwards, which `git log` prints under the message.

They answer one question: *how do I change something about a commit without
rewriting history?*

Everything else in this part makes new commits and abandons the old ones. These
two leave every hash exactly as it was, which is why they work on commits other
people already have — and why what they do is, by default, visible only to you.

| Term | Means |
|---|---|
| *replace ref* | a ref under `refs/replace/<object>` naming what to use instead |
| *graft* | a fake parent list for a commit, so two unrelated histories look joined |
| *the grafts file* | `.git/info/grafts`, the deprecated way of doing that |
| *note* | a piece of text attached to an object, stored in a tree of its own |
| *notes ref* | the branch a set of notes lives on, `refs/notes/commits` by default |

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [Can I change what a commit says without rewriting history?](#what-it-is)
- [What is the difference between a replacement and a note?](#what-it-is)

**[Synopsis](#synopsis)**

- [What can I type after `git replace` and after `git notes`?](#synopsis)

**[Options at a glance](#options-at-a-glance)**

- [Which options belong to which subcommand?](#options-at-a-glance)

**[The example repository](#the-example-repository)**

- [What repository do the examples use?](#the-example-repository)

**[Making one object stand in for another](#making-one-object-stand-in-for-another)**

- [How do I make Git show a different commit in place of an old one?](#making-one-object-stand-in-for-another)
- [Does this change the old commit?](#making-one-object-stand-in-for-another)

**[Listing and removing](#listing-and-removing)**

- [How do I see which objects are being replaced?](#listing-and-removing)
- [How do I get rid of a replacement?](#listing-and-removing)
- [Where is a replacement stored?](#listing-and-removing)

**[Editing an object](#editing-an-object)**

- [Is there a shorter way than building the replacement by hand?](#editing-an-object)

**[Replacing with the wrong type](#replacing-with-the-wrong-type)**

- [Why did it refuse to replace a commit with a tree?](#replacing-with-the-wrong-type)
- [How do I replace something that is already replaced?](#replacing-with-the-wrong-type)

**[Joining two histories](#joining-two-histories)**

- [I have an old repository with the earlier history. How do I attach it?](#joining-two-histories)
- [How do I make a commit look as if it had different parents?](#joining-two-histories)
- [How do I cut history off at a point?](#cutting-history-off)

**[The grafts file](#the-grafts-file)**

- [I have an `info/grafts` file from an old repository. Does it still work?](#the-grafts-file)
- [How do I convert it?](#the-grafts-file)

**[Which commands ignore replacements](#which-commands-ignore-replacements)**

- [Why does `git fsck` still see the old commit?](#which-commands-ignore-replacements)
- [How do I run one command without replacements?](#which-commands-ignore-replacements)
- [Why did my repository suddenly get slower?](#which-commands-ignore-replacements)

**[Sharing replacements](#sharing-replacements)**

- [Does a clone get my replacements?](#sharing-replacements)
- [How do I push and fetch them?](#sharing-replacements)

**[Making it permanent](#making-it-permanent)**

- [How do I turn replacements into real history?](#making-it-permanent)

**[Attaching a note to a commit](#attaching-a-note-to-a-commit)**

- [How do I add information to a commit after it is made, without changing it?](#attaching-a-note-to-a-commit)
- [Where is the note stored?](#attaching-a-note-to-a-commit)

**[Seeing notes in the log](#seeing-notes-in-the-log)**

- [Why does `git log` show my note but `git log --oneline` does not?](#seeing-notes-in-the-log)
- [How do I turn notes off for one command?](#seeing-notes-in-the-log)
- [How do I get just the note in a format string?](#seeing-notes-in-the-log)

**[Editing, appending and copying](#editing-appending-and-copying)**

- [How do I add a second paragraph to a note?](#editing-appending-and-copying)
- [Can I take a note from a file?](#editing-appending-and-copying)
- [How do I copy a note from one commit to another?](#editing-appending-and-copying)
- [Why does `git notes add` refuse when there is already a note?](#editing-appending-and-copying)

**[Removing notes](#removing-notes)**

- [How do I delete a note?](#removing-notes)
- [How do I delete one that may not exist, without an error?](#removing-notes)

**[Notes in another namespace](#notes-in-another-namespace)**

- [How do I keep two independent sets of notes?](#notes-in-another-namespace)
- [How do I make `git log` show a set that is not the default?](#notes-in-another-namespace)
- [Which notes ref am I using?](#notes-in-another-namespace)
- [An old script uses `--show-notes` and `--standard-notes`. What do they do?](#notes-in-another-namespace)

**[Notes and rewritten commits](#notes-and-rewritten-commits)**

- [I amended a commit and my note is on the old one. Why?](#notes-and-rewritten-commits)
- [Can Git move notes for me automatically?](#notes-and-rewritten-commits)

**[Merging notes](#merging-notes)**

- [Two people wrote a note on the same commit. What happens?](#merging-notes)
- [How do I resolve a notes conflict by hand?](#merging-notes)
- [What do the `ours`, `theirs`, `union` and `cat_sort_uniq` strategies do?](#letting-git-resolve-it)

**[replace, notes and their neighbours](#replace-notes-and-their-neighbours)**

- [Should I use a note, a trailer in the message, or amend the commit?](#replace-notes-and-their-neighbours)
- [Are notes the right place for review comments or test results?](#replace-notes-and-their-neighbours)

**[The settings](#the-settings)**

- [Which settings control where notes are read from and written to?](#the-settings)

</details>

## Synopsis

```
git replace [-f] <object> <replacement>
git replace [-f] --edit <object>
git replace [-f] --graft <commit> [<parent>...]
git replace [-f] --convert-graft-file
git replace -d <object>...
git replace [--format=<format>] [-l [<pattern>]]

git notes [list [<object>]]
git notes add [-f] [-F <file> | -m <msg> | (-c | -C) <object>] [-e] [<object>]
git notes copy [-f] ( --stdin | <from-object> [<to-object>] )
git notes append [-F <file> | -m <msg>] [<object>]
git notes edit [<object>]
git notes show [<object>]
git notes merge [-v | -q] [-s <strategy>] <notes-ref>
git notes merge (--commit | --abort) [-v | -q]
git notes remove [--ignore-missing] [--stdin] [<object>...]
git notes prune [-n] [-v]
git notes get-ref
```

| Command | Does |
|---|---|
| `git replace <object> <replacement>` | Use `<replacement>` wherever `<object>` is asked for |
| `git replace --graft <commit> <parent>...` | Make `<commit>` appear to have those parents |
| `git replace -l` | List the replacements |
| `git replace -d <object>` | Remove one |
| `git notes add -m <msg> <object>` | Attach a note |
| `git notes show <object>` | Print it |
| `git notes remove <object>` | Delete it |
| `git notes --ref=<name> ...` | Work on a different set of notes |

## Options at a glance

### git replace

| Option | Does | Covered in |
|---|---|---|
| `-l [<pattern>]`, `--list [<pattern>]` | List replacements, all or matching | [Listing and removing](#listing-and-removing) |
| `--format=short` | Print the replaced object only; the default | [Listing and removing](#listing-and-removing) |
| `--format=medium` | Print `<replaced> -> <replacement>` | [Listing and removing](#listing-and-removing) |
| `--format=long` | The same, with both types | [Listing and removing](#listing-and-removing) |
| `-d`, `--delete` | Remove a replacement | [Listing and removing](#listing-and-removing) |
| `-f`, `--force` | Overwrite an existing replacement, or ignore the type check | [Replacing with the wrong type](#replacing-with-the-wrong-type) |
| `--edit <object>` | Open the object in an editor and replace it with the result | [Editing an object](#editing-an-object) |
| `--raw` | With `--edit`, show a tree in its binary form | [Editing an object](#editing-an-object) |
| `--graft <commit> [<parent>...]` | Replace a commit with one that has those parents | [Joining two histories](#joining-two-histories) |
| `--convert-graft-file` | Turn `.git/info/grafts` into replace refs | [The grafts file](#the-grafts-file) |

### git notes

| Option | Does | Covered in |
|---|---|---|
| `-m <msg>`, `--message=<msg>` | Use this text; repeat for paragraphs | [Attaching a note to a commit](#attaching-a-note-to-a-commit) |
| `-F <file>`, `--file=<file>` | Take the text from a file, `-` for standard input | [Editing, appending and copying](#editing-appending-and-copying) |
| `-C <object>`, `--reuse-message=<object>` | Take the text from another object, verbatim | [Editing, appending and copying](#editing-appending-and-copying) |
| `-c <object>`, `--reedit-message=<object>` | The same, then open an editor | [Editing, appending and copying](#editing-appending-and-copying) |
| `-f`, `--force` | Overwrite an existing note | [Editing, appending and copying](#editing-appending-and-copying) |
| `-e` | Edit the message from `-m` or `-F` before storing it | [Editing, appending and copying](#editing-appending-and-copying) |
| `--ref=<ref>` | Work on another notes ref | [Notes in another namespace](#notes-in-another-namespace) |
| `--ignore-missing` | Do not complain when removing a note that is not there | [Removing notes](#removing-notes) |
| `--stdin` | Read the objects from standard input, for `remove` and `copy` | [Removing notes](#removing-notes) |
| `--allow-empty` | Store an empty note instead of deleting it | [Removing notes](#removing-notes) |
| `--separator=<text>`, `--no-separator` | What goes between several `-m` paragraphs | [Editing, appending and copying](#editing-appending-and-copying) |
| `--stripspace`, `--no-stripspace` | Tidy the whitespace, or keep it exactly | [Editing, appending and copying](#editing-appending-and-copying) |
| `-s <strategy>`, `--strategy=<strategy>` | How to resolve a notes merge | [Letting Git resolve it](#letting-git-resolve-it) |
| `--commit`, `--abort` | Finish or cancel a stopped notes merge | [Merging notes](#merging-notes) |
| `-n`, `--dry-run` | For `prune`, say what would go | [Removing notes](#removing-notes) |
| `-q`, `--quiet`, `-v`, `--verbose` | How much a merge or a prune prints | [Merging notes](#merging-notes) |

<!-- no-example: --raw  it only changes how --edit presents a tree, showing the
     binary form instead of the pretty-printed one, and Git's own documentation
     says it is for repairing a tree too corrupt to print; that is Chapter 81,
     and a transcript here would show unreadable bytes -->
<!-- no-example: --stdin  it takes the same object names from standard input
     rather than the command line and does exactly what the command-line form,
     demonstrated in "Removing notes", does; it exists for feeding the
     post-rewrite hook's output to `git notes copy` -->
<!-- no-example: --allow-empty  it stores an empty note where the default
     deletes it, so the only visible difference is `git notes list` naming an
     object whose note prints nothing -->
<!-- no-example: --separator  it changes the blank line between several -m
     paragraphs to other text; the default is shown in "Editing, appending and
     copying" and the option substitutes a different string in the same place -->
<!-- no-example: --stripspace  it is the default everywhere except -C, and the
     notes in this chapter have no trailing or repeated whitespace for it to
     tidy, so both spellings store the same bytes -->
<!-- no-example: --dry-run  it belongs to `git notes prune`, which removes
     notes on objects that no longer exist; the example repository has no
     missing objects, so both the real run and the dry run print nothing -->

## The example repository

```console
$ git log --oneline --graph --all --decorate
* e51a803 (history) Prototype shelving
* ea7c31e The original prototype
* 52315a3 (HEAD -> main) Add loans
* 2483703 Add the indexr
* 7f5e3e0 Add the shelf
* f54cd9c Import the library
```

A library, with a typo in one commit's message — `Add the indexr` — and a
second, unrelated history on a branch called `history`: two commits from before
the project was imported, with no commit in common with `main`. Both of those
are things this chapter fixes without rewriting anything.

## Making one object stand in for another

```console
$ git cat-file -p HEAD~1 | head -5
tree 49c17a29edb148407b2136d61b3cb4decff1c32d
parent 7f5e3e090aa3d759a68efa33b46188cfe5e9f064
author Ada Lovelace <ada@example.com> 1767610800 +0000
committer Ada Lovelace <ada@example.com> 1767610800 +0000

$ git log -1 --format=%B HEAD~1
Add the indexr

$ git cat-file commit 2483703e02b45d4b7c4d76c8166b46705f6aecfc | sed 's/Add the indexr/Add the index/' | git hash-object -t commit -w --stdin
9dd54f25c75e56b1c2436d98f596ad9441031838
$ git replace 2483703e02b45d4b7c4d76c8166b46705f6aecfc 9dd54f25c75e56b1c2436d98f596ad9441031838
$ git log --oneline
52315a3 Add loans
2483703 Add the index
7f5e3e0 Add the shelf
f54cd9c Import the library
$ git --no-replace-objects log --oneline
52315a3 Add loans
2483703 Add the indexr
7f5e3e0 Add the shelf
f54cd9c Import the library
```

Read the two `git log` lines together: the same commit, `2483703`, with two
different messages. The first uses the replacement, the second does not.

What happened in between is worth following, because it shows what a commit
actually is (Chapter 6). `git cat-file commit` prints the raw commit; `sed`
fixes the typo; `git hash-object -w` stores the result as a new object and
prints its name. Then `git replace <old> <new>` records that when anything asks
for `2483703`, it should get `9dd54f2` instead.

Nothing was rewritten. `2483703` is still there, still says `indexr`, and every
commit after it still names it as a parent — which is why the hashes are
unchanged and why this works on commits other people have.

**The commit keeps its old name.** `git log` prints `2483703` beside the fixed
message: the replacement is looked up by the old name, so the old name is what
you see. That is either exactly what you want or deeply confusing, and it is
the main reason replacements are rare.

## Listing and removing

```console
$ git replace -l
2483703e02b45d4b7c4d76c8166b46705f6aecfc
$ git replace --format=short -l
2483703e02b45d4b7c4d76c8166b46705f6aecfc
$ git replace --format=medium -l
2483703e02b45d4b7c4d76c8166b46705f6aecfc -> 9dd54f25c75e56b1c2436d98f596ad9441031838
$ git replace --format=long -l
2483703e02b45d4b7c4d76c8166b46705f6aecfc (commit) -> 9dd54f25c75e56b1c2436d98f596ad9441031838 (commit)
$ git for-each-ref refs/replace
9dd54f25c75e56b1c2436d98f596ad9441031838 commit	refs/replace/2483703e02b45d4b7c4d76c8166b46705f6aecfc
$ git replace -d 2483703e02b45d4b7c4d76c8166b46705f6aecfc && git log --oneline -3
Deleted replace ref '2483703e02b45d4b7c4d76c8166b46705f6aecfc'
52315a3 Add loans
2483703 Add the indexr
7f5e3e0 Add the shelf
```

`-l` lists what is replaced, and `--format` says how much to show: `short`, the
default, prints the replaced object alone; `medium` adds the replacement;
`long` adds both types.

The last two commands show that there is nothing special about a replacement.
It is a ref: `refs/replace/<the-old-hash>`, whose value is the new object.
`git for-each-ref` finds it like any other (Chapter 74), and deleting the ref
undoes the whole thing — the typo is back.

## Editing an object

```console
$ GIT_EDITOR='cp ../message.txt' git replace --edit 2483703e02b45d4b7c4d76c8166b46705f6aecfc
$ git log --oneline -3
52315a3 Add loans
2483703 Add the index
7f5e3e0 Add the shelf
$ git replace -l --format=long
2483703e02b45d4b7c4d76c8166b46705f6aecfc (commit) -> 9dd54f25c75e56b1c2436d98f596ad9441031838 (commit)
$ git replace -d 2483703e02b45d4b7c4d76c8166b46705f6aecfc
Deleted replace ref '2483703e02b45d4b7c4d76c8166b46705f6aecfc'
```

`--edit` does the whole thing in one step: it pretty-prints the object into a
temporary file, opens your editor on it, and stores whatever you save as the
replacement. What you edit is the raw object — the `tree`, `parent`, `author`
and `committer` lines and then the message — so everything in it can be
changed, and anything you get wrong is a broken commit.

The editor here is `cp ../message.txt`, which writes a prepared file over the
one Git offers; the result is byte for byte the object built by hand in the
previous section, which is why the replacement hash is the same.

`--raw` changes how a *tree* is presented, showing its binary form rather than
the readable listing, for the case where the tree is too damaged to print.

## Replacing with the wrong type

```console
$ git replace 2483703e02b45d4b7c4d76c8166b46705f6aecfc $(git rev-parse HEAD^{tree})
error: Objects must be of the same type.
'2483703e02b45d4b7c4d76c8166b46705f6aecfc' points to a replaced object of type 'commit'
while '595c6edd8a8f8221f1d42fd04ba7f8d459793db4' points to a replacement object of type 'tree'.
$ git replace -f 2483703e02b45d4b7c4d76c8166b46705f6aecfc 9dd54f25c75e56b1c2436d98f596ad9441031838 && git replace -l
2483703e02b45d4b7c4d76c8166b46705f6aecfc
$ git replace 2483703e02b45d4b7c4d76c8166b46705f6aecfc 9dd54f25c75e56b1c2436d98f596ad9441031838
error: replace ref 'refs/replace/2483703e02b45d4b7c4d76c8166b46705f6aecfc' already exists
```

Two refusals, and `-f` gets past both. Git checks that the two objects are the
same type, because a commit where a tree is expected breaks everything that
walks the history; `-f` lifts that check, which Git's documentation mentions
and nobody should need. It also refuses to overwrite a replacement that already
exists, which is the useful half of `-f`.

## Joining two histories

```console
$ git log --oneline --format='%h %p %s' main | tail -2
7f5e3e0 f54cd9c Add the shelf
f54cd9c  Import the library
$ git replace --graft f54cd9c2d99de7399237506fb07328e0ce57e879 history
$ git log --oneline
52315a3 Add loans
2483703 Add the indexr
7f5e3e0 Add the shelf
f54cd9c Import the library
e51a803 Prototype shelving
ea7c31e The original prototype
$ git --no-replace-objects log --oneline
52315a3 Add loans
2483703 Add the indexr
7f5e3e0 Add the shelf
f54cd9c Import the library
$ git log --oneline --format='%h %p %s' | tail -3
f54cd9c e51a803 Import the library
e51a803 ea7c31e Prototype shelving
ea7c31e  The original prototype
```

`Import the library` had no parent — the empty column in the first listing —
and now it has one, and the history runs back through two commits that were
never connected to it.

`git replace --graft <commit> [<parent>...]` builds a copy of `<commit>` with
the parents you name and replaces the original with it. It is the short way to
do what this chapter opened with by hand, for the one field people most want to
change.

This is the answer to "we moved to Git and lost the history before the import":
keep the old history in the same repository, on a branch of its own, and graft
it on. Nothing is rewritten, so every hash anyone has ever quoted still works.

### Cutting history off

```console
$ git replace -d f54cd9c2d99de7399237506fb07328e0ce57e879
Deleted replace ref 'f54cd9c2d99de7399237506fb07328e0ce57e879'
$ git replace --graft main~1 && git log --oneline
52315a3 Add loans
2483703 Add the indexr
```

`--graft` with no parents at all makes the commit a root: `main~1` now has no
ancestry and the history is two commits long.

That is how a long history is temporarily made short — for a bisect, a
demonstration, or to see how a tool behaves on a shallow history — without
touching the repository. Deleting the replace ref brings it all back.

## The grafts file

```console
$ cat .git/info/grafts
f54cd9c2d99de7399237506fb07328e0ce57e879 e51a803bfa9cbc48531277d72c78eb4d5d95bdb5
$ git log --oneline | tail -4
hint: Support for <GIT_DIR>/info/grafts is deprecated
hint: and will be removed in a future Git version.
hint:
hint: Please use "git replace --convert-graft-file"
hint: to convert the grafts into replace refs.
hint:
hint: Turn this message off by running
hint: "git config set advice.graftFileDeprecated false"
7f5e3e0 Add the shelf
f54cd9c Import the library
e51a803 Prototype shelving
ea7c31e The original prototype
```

Before replace refs existed, the same job was done by a file: one line per
commit, listing its fake parents. It still works, and Git complains every time
it is read.

```console
$ git replace --convert-graft-file
$ ls .git/info
exclude
$ git replace -l --format=medium
f54cd9c2d99de7399237506fb07328e0ce57e879 -> 31b417f59d981c8e560c96294ba66c3dbff044e2
$ git log --oneline | tail -4
7f5e3e0 Add the shelf
f54cd9c Import the library
e51a803 Prototype shelving
ea7c31e The original prototype
```

`--convert-graft-file` makes a replace ref for every line and deletes the file.
The history looks the same afterwards, and the warning is gone.

If you inherit a repository with an `info/grafts` file, this is the whole
migration. Note that the file is per-repository and was never cloned either, so
whoever set it up has been explaining it to every new person by hand.

## Which commands ignore replacements

```console
$ git fsck --connectivity-only 2>&1 | head -3
dangling commit d2c81f8fbdcea3adbf75d4e80623e91b92538274
dangling commit 9dd54f25c75e56b1c2436d98f596ad9441031838
$ GIT_NO_REPLACE_OBJECTS=1 git log --oneline | tail -3
2483703 Add the indexr
7f5e3e0 Add the shelf
f54cd9c Import the library
$ git --no-replace-objects log --oneline | tail -3
2483703 Add the indexr
7f5e3e0 Add the shelf
f54cd9c Import the library
```

Git's documentation states the rule: replacement refs are used by every command
*except* those doing reachability traversal — `prune`, `fsck`, and packing for
transfer. That is why `git fsck` calls the replacement objects dangling: as far
as reachability is concerned, nothing points at them.

It matters more than it sounds. An object that is only reachable *through* a
replacement is not protected from `git gc`, so a graft can be collected away
while the replace ref still points at it.

`--no-replace-objects` turns replacements off for one command, and
`GIT_NO_REPLACE_OBJECTS=1` does the same through the environment. Note where
the option goes: before the subcommand, because it belongs to `git` itself, not
to `git log` (Chapter 75).

> **Worth knowing.** Git's documentation warns that replace objects and grafts
> turn off reading and writing the commit-graph, which is the cache that makes
> history traversal fast on a large repository (Chapter 69). A repository that
> became slow after a graft was added has found that out.

## Sharing replacements

```console
$ git push -q origin main && git ls-remote origin | head -3
52315a3dc4bec0a0f964ca5ba3174a34ddf3f659	HEAD
52315a3dc4bec0a0f964ca5ba3174a34ddf3f659	refs/heads/main
$ git push -q origin 'refs/replace/*:refs/replace/*' && git ls-remote origin refs/replace/*
31b417f59d981c8e560c96294ba66c3dbff044e2	refs/replace/f54cd9c2d99de7399237506fb07328e0ce57e879
$ git clone -q /home/ada/origin.git /home/ada/clone && git -C /home/ada/clone log --oneline | tail -3
2483703 Add the indexr
7f5e3e0 Add the shelf
f54cd9c Import the library
$ git -C /home/ada/clone fetch -q origin 'refs/replace/*:refs/replace/*' && git -C /home/ada/clone log --oneline | tail -3
f54cd9c Import the library
e51a803 Prototype shelving
ea7c31e The original prototype
```

Four steps that between them answer the question. An ordinary push sends
`refs/heads/*`, so the replacement did not go; pushing the refspec
`refs/replace/*:refs/replace/*` sends it (Chapter 44). A clone takes branches
and tags and not replacements, so the fresh clone sees the unjoined history;
fetching the same refspec gives it the joined one.

Two consequences worth stating plainly. A replacement you make is yours alone
until you deliberately share it — which is the whole reason it is safe to make
one on a shared repository. And a project that relies on one has to tell every
new person to fetch it, or put the refspec in the configuration for them, which
is why grafted histories tend to be made permanent instead.

## Making it permanent

```console
$ git replace -l | wc -l
1
$ FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -- --all 2>&1 | tail -2
Ref 'refs/remotes/origin/main' was rewritten
WARNING: Ref 'refs/replace/f54cd9c2d99de7399237506fb07328e0ce57e879' is unchanged
$ git replace -d $(git replace -l)
Deleted replace ref 'f54cd9c2d99de7399237506fb07328e0ce57e879'
$ git log --oneline | tail -4
7fc4c82 Add the shelf
31b417f Import the library
e51a803 Prototype shelving
ea7c31e The original prototype
```

`git filter-branch` with no filters at all rebuilds every commit — and because
it honours replace refs while it reads, what it writes is the replaced history
as real commits (Chapter 37). The replace ref can then be deleted and the
joined history stays: the hashes below `Import the library` are new, and
`git log` needs no replacement to show them.

That is the trade in one paragraph. A replacement costs nothing and is invisible
to everyone else; making it permanent rewrites every hash and everything in
Chapter 28 applies. Projects that graft in an old history usually do it once,
permanently, at the moment of the import.

## Attaching a note to a commit

```console
$ git notes add -m 'Reviewed by Sam; ships in 2.1' HEAD~1
$ git log -2
commit 99109e9702fd2d9870c9cb7ef8b613c7bc8a5959
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 12:00:00 2026 +0000

    Add loans

commit 0d92f71238146563359cd7d06891817d58315292
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 11:00:00 2026 +0000

    Add the indexr

Notes:
    Reviewed by Sam; ships in 2.1
$ git notes show HEAD~1
Reviewed by Sam; ships in 2.1
$ git notes list
be432edc075a35dbc8b77c26bfe02a18a09cfaee 0d92f71238146563359cd7d06891817d58315292
$ git log --oneline -1 refs/notes/commits
9fcebf1 Notes added by 'git notes add'
```

The note appears under the commit message, indented the same way, with an
unindented `Notes:` line above it. The commit itself is untouched: its hash,
its message and its content are what they were.

`git notes list` shows where the text actually lives — two hashes, the note's
blob and the commit it is attached to. And `refs/notes/commits` is a branch:
every change to the notes makes a commit on it, so the notes have their own
history, which `git log refs/notes/commits` reads like any other.

## Seeing notes in the log

```console
$ git log --oneline -2
99109e9 Add loans
0d92f71 Add the indexr
$ git log --no-notes -2 | head -8
commit 99109e9702fd2d9870c9cb7ef8b613c7bc8a5959
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 12:00:00 2026 +0000

    Add loans

commit 0d92f71238146563359cd7d06891817d58315292
Author: Ada Lovelace <ada@example.com>
$ git log -1 --format='%h %s | %N' HEAD~1
0d92f71 Add the indexr | Reviewed by Sam; ships in 2.1

$ git show --stat --oneline HEAD~1
0d92f71 Add the indexr
 index.py | 1 +
 1 file changed, 1 insertion(+)
```

Notes are shown by the formats that print a message body, and not by the ones
that do not: `git log` shows them, `--oneline` does not, and `--no-notes` turns
them off where they would appear. `%N` is the placeholder for a format string
of your own (Chapter 17).

`git show --stat --oneline` leaves the note out for the same reason
`--oneline` does. Without `--oneline`, `git show` prints it.

## Editing, appending and copying

```console
$ git notes append -m 'Also tested on Windows.' HEAD~1 && git notes show HEAD~1
Reviewed by Sam; ships in 2.1

Also tested on Windows.
$ git notes add -f -F ../note.txt HEAD~1 && git notes show HEAD~1
Overwriting existing notes for object 0d92f71238146563359cd7d06891817d58315292
Reviewed by Sam; ships in 2.1

Also tested on Windows, and on Linux.
$ git notes add -f -C $(git notes list HEAD~1) HEAD && git notes show HEAD
Reviewed by Sam; ships in 2.1

Also tested on Windows, and on Linux.
$ GIT_EDITOR='cp ../note2.txt' git notes add -f -c $(git notes list HEAD~1) HEAD && git notes show HEAD
Overwriting existing notes for object 99109e9702fd2d9870c9cb7ef8b613c7bc8a5959
Backported to 2.0 as well.
$ GIT_EDITOR='cp ../note2.txt' git notes add -f -e -m 'A first draft' HEAD~1 && git notes show HEAD~1
Overwriting existing notes for object 0d92f71238146563359cd7d06891817d58315292
Backported to 2.0 as well.
$ git notes add -f -F ../note.txt HEAD~1 >/dev/null && git notes show HEAD~1
Overwriting existing notes for object 0d92f71238146563359cd7d06891817d58315292
Reviewed by Sam; ships in 2.1

Also tested on Windows, and on Linux.
$ git notes copy HEAD~1 HEAD && git notes list
548dbeb7bc5cad0954dbdefb6f30073d5fb1569a 0d92f71238146563359cd7d06891817d58315292
548dbeb7bc5cad0954dbdefb6f30073d5fb1569a 99109e9702fd2d9870c9cb7ef8b613c7bc8a5959
$ git notes add -m 'second try' HEAD
error: Cannot add notes. Found existing notes for object 99109e9702fd2d9870c9cb7ef8b613c7bc8a5959. Use '-f' to overwrite existing notes
$ git notes add -f -m 'A second attempt' HEAD && git notes show HEAD
Overwriting existing notes for object 99109e9702fd2d9870c9cb7ef8b613c7bc8a5959
A second attempt
```

| Subcommand | Does |
|---|---|
| `add` | attach a note; refuses if there is one |
| `add -f` | attach it anyway, replacing what was there |
| `append` | add a paragraph to the existing note, or start one |
| `edit` | open the existing note in an editor |
| `copy <from> <to>` | give `<to>` the note that `<from>` has |
| `show` | print it |

`append` puts a blank line between the old text and the new, which
`--separator` changes and `--no-separator` removes. Several `-m` options in one
command are joined the same way.

`-F <file>` takes the text from a file and `-F -` from standard input, which is
how a script attaches the output of something.

`-C <object>` takes the text from another object verbatim, and the object it
wants is the note's *blob*, which is what `git notes list <commit>` prints —
hence the `$(...)`. Git's documentation notes that `-C` implies
`--no-stripspace`, because a copy should be a copy. `-c` is the same with an
editor opened on it, and `-e` opens an editor on a message given with `-m` or
`-F`, which is how you start from a template and finish it by hand.

`git notes copy` is the two-argument form of the same idea and the one to reach
for, since it works out the blob for you.

## Removing notes

```console
$ git notes remove HEAD && git notes list
Removing note for object HEAD
548dbeb7bc5cad0954dbdefb6f30073d5fb1569a 0d92f71238146563359cd7d06891817d58315292
$ git notes remove HEAD
Object HEAD has no note
$ git notes remove --ignore-missing HEAD && echo 'no complaint'
Object HEAD has no note
no complaint
```

`remove` deletes a note; a second attempt is an error, and `--ignore-missing`
makes it a message rather than a failure — the difference is the exit status,
which is what a script cares about. `--stdin` takes the objects from standard
input instead, and can be combined with names on the command line.

An empty note is deleted rather than stored, unless `--allow-empty` says
otherwise.

`git notes prune` removes notes attached to objects that no longer exist, which
happens after a history rewrite has left the commits they described
unreachable. `-n` says what it would remove.

## Notes in another namespace

```console
$ git notes --ref=builds add -m 'build 1482 passed' HEAD~1
$ git notes --ref=builds show HEAD~1
build 1482 passed
$ git notes list
548dbeb7bc5cad0954dbdefb6f30073d5fb1569a 0d92f71238146563359cd7d06891817d58315292
$ git log -1 HEAD~1 | tail -6
    Add the indexr

Notes:
    Reviewed by Sam; ships in 2.1

    Also tested on Windows, and on Linux.
$ git log -1 --notes=builds HEAD~1 | tail -6
Date:   Mon Jan 5 11:00:00 2026 +0000

    Add the indexr

Notes (builds):
    build 1482 passed
$ git log -1 --notes=* HEAD~1 | tail -8

Notes (builds):
    build 1482 passed

Notes:
    Reviewed by Sam; ships in 2.1

    Also tested on Windows, and on Linux.
$ git notes get-ref
refs/notes/commits
$ git -c core.notesRef=refs/notes/builds notes get-ref
refs/notes/builds
```

`--ref=<name>` puts the note on a different notes ref, and the two sets are
completely separate: `git notes list` with no `--ref` does not mention the
build note at all, because it is looking at `refs/notes/commits`.

That is what makes notes usable by more than one thing at once — review
comments, build results, release tracking — each in its own namespace, each
with its own history, none of them able to conflict with another.

`git log` shows the default set, `--notes=<ref>` shows another, and `--notes=*`
shows every one, each labelled. `core.notesRef` changes the default, and
`notes.displayRef` adds refs to what `git log` shows without changing where new
notes go. A short name such as `builds` is expanded to `refs/notes/builds`.

`git notes get-ref` prints the ref currently in use, which is how a script finds
out what it is about to write to.

Three older options, which Git's documentation calls deprecated in favour of
`--notes` and `--no-notes`, still work, and one does not mean what it seems to:

```console
$ git log -1 --show-notes=builds HEAD~1 | tail -8

Notes:
    Reviewed by Sam; ships in 2.1

    Also tested on Windows, and on Linux.

Notes (builds):
    build 1482 passed
$ git log -1 --show-notes=builds --no-standard-notes HEAD~1 | tail -3

Notes (builds):
    build 1482 passed
$ git log -1 --notes=builds --standard-notes HEAD~1 | tail -8

Notes:
    Reviewed by Sam; ships in 2.1

    Also tested on Windows, and on Linux.

Notes (builds):
    build 1482 passed
```

`--show-notes=builds` showed the default notes as well as the build note, where
`--notes=builds` above showed only the build note. `--no-standard-notes` leaves
out the default notes and keeps the ref named, and `--standard-notes` adds them
to it. `diff <(...) <(...)` compares the output of two commands, in bash, and
prints nothing when they are the same (Chapter 17 used it too):

```console
$ diff <(git log -1 --show-notes HEAD~1) <(git log -1 --notes HEAD~1) && echo same
same
$ diff <(git log -1 --show-notes=builds HEAD~1) <(git log -1 --notes=builds --notes HEAD~1) && echo same
same
$ diff <(git log -1 --show-notes=builds --no-standard-notes HEAD~1) <(git log -1 --notes=builds HEAD~1) && echo same
same
$ diff <(git log -1 --notes=builds --standard-notes HEAD~1) <(git log -1 --notes=builds --notes HEAD~1) && echo same
same
```

So a script written with the old options can be read with this table:

| Old option | Same result with |
|---|---|
| `git log --show-notes` | `git log --notes` |
| `git log --show-notes=<ref>` | `git log --notes=<ref> --notes` |
| `git log --show-notes=<ref> --no-standard-notes` | `git log --notes=<ref>` |
| `git log --notes=<ref> --standard-notes` | `git log --notes=<ref> --notes` |

## Notes and rewritten commits

```console
$ git notes list HEAD~1
548dbeb7bc5cad0954dbdefb6f30073d5fb1569a
$ git commit -q --amend --no-edit -m 'Add loans, with limits' && git log --oneline -2
9e861cd Add loans, with limits
0d92f71 Add the indexr
$ git notes list HEAD || echo 'no note on the new commit'
error: no note found for object 9e861cdfdb843303a69809edd2b50ed9ec306288.
no note on the new commit
```

A note is attached to a hash, so a rewrite leaves it behind: the amended commit
is a different object and has no note. That is the main practical objection to
notes, and it applies to every rewrite in this part.

```console
$ git switch -q -C try main~1 && git notes list HEAD
548dbeb7bc5cad0954dbdefb6f30073d5fb1569a
$ git -c notes.rewriteRef=refs/notes/commits commit -q --amend --no-edit -m 'Add the index, renamed'
$ git notes show HEAD
Reviewed by Sam; ships in 2.1

Also tested on Windows, and on Linux.
```

Git can carry them across. `notes.rewriteRef` names which notes refs to copy
when a command rewrites commits, and with it set the amended commit arrives
with the note already attached.

| Setting | Does |
|---|---|
| `notes.rewriteRef` | which notes refs to copy; has no default, so nothing is copied until it is set |
| `notes.rewrite.amend`, `notes.rewrite.rebase` | whether that happens for `git commit --amend` and `git rebase`; both true by default |
| `notes.rewriteMode` | what to do when the new commit already has a note: `overwrite`, `concatenate`, `cat_sort_uniq` or `ignore` |

The pair matters: `notes.rewrite.<command>` is on already, and does nothing
until `notes.rewriteRef` says which notes to carry. `refs/notes/commits` is the
usual value.

## Merging notes

```console
$ git notes --ref=review add -m 'Looks good to me' main~1
$ git notes --ref=review merge -v refs/notes/builds
Automatic notes merge failed. Fix conflicts in .git/NOTES_MERGE_WORKTREE and commit the result with 'git notes merge --commit', or abort the merge with 'git notes merge --abort'.
Auto-merging notes for 0d92f71238146563359cd7d06891817d58315292
CONFLICT (add/add): Merge conflict in notes for object 0d92f71238146563359cd7d06891817d58315292
$ ls .git/NOTES_MERGE_WORKTREE && cat .git/NOTES_MERGE_WORKTREE/*
0d92f71238146563359cd7d06891817d58315292
<<<<<<< refs/notes/review
Looks good to me
=======
build 1482 passed
>>>>>>> refs/notes/builds
$ git notes merge --abort && git notes --ref=review show main~1
Looks good to me
```

Notes refs are branches, so two people writing notes on the same commit
diverge like any other branch, and `git notes merge` joins them.

Where it cannot decide, it stops — and the place it stops is unusual. Instead
of putting markers in your working tree, it makes a directory,
`.git/NOTES_MERGE_WORKTREE`, with one file per conflicted note, named after the
commit the note belongs to. Edit those files, then `git notes merge --commit`;
or `git notes merge --abort` to throw it away, as above.

### Letting Git resolve it

```console
$ git notes --ref=review merge -s union refs/notes/builds
Concatenating local and remote notes for 0d92f71238146563359cd7d06891817d58315292
$ git notes --ref=review show main~1
Looks good to me

build 1482 passed
$ git notes --ref=review merge -s theirs refs/notes/builds
Already up to date.
$ git notes --ref=review show main~1
Looks good to me

build 1482 passed
$ git log --oneline refs/notes/review
61e0961 Merged notes from refs/notes/builds into refs/notes/review
7dece29 Notes added by 'git notes add'
a6a9ddb Notes added by 'git notes add'
```

`-s` picks a strategy and the merge finishes without asking:

| Strategy | Keeps |
|---|---|
| `manual` | nothing automatic; stops as above. The default |
| `ours` | the note already on this ref |
| `theirs` | the note from the ref being merged |
| `union` | both, concatenated |
| `cat_sort_uniq` | both, concatenated, sorted, with duplicate lines removed |

The second merge says `Already up to date.` and changes nothing: the build note
is now part of `refs/notes/review`, so there is nothing left to take. A
strategy only decides what happens where the two sides disagree.

`union` is the sensible default for notes that accumulate — build results, sign-offs —
and `cat_sort_uniq` for anything line-based that should not repeat. Git's
documentation warns that `cat_sort_uniq` removes duplicate lines that were
already there before the merge, not only the ones the merge created.

`notes.mergeStrategy` sets one for good, and
`notes.<name>.mergeStrategy` sets one per notes ref.

The last command is a reminder of what these are: the merge made a commit on
`refs/notes/review`, and the notes ref has an ordinary history.

## replace, notes and their neighbours

| To change | Use | Rewrites history | Chapter |
|---|---|---|---|
| the last commit's message | `git commit --amend` | yes | Chapter 29 |
| an older commit's message | `git history reword` | yes | Chapter 35 |
| what a commit appears to say | `git replace` | no | this chapter |
| what a commit appears to descend from | `git replace --graft` | no | this chapter |
| information *about* a commit | `git notes` | no | this chapter |
| information *in* the message, at commit time | a trailer such as `Reviewed-by:` | no | Chapter 53 |

**A note, a trailer, or an amend?** If you know it when you write the commit,
put it in the message, as a trailer if it is structured. If you learn it
afterwards and the commit is yours alone, amend. If you learn it afterwards and
the commit is shared, that is what notes are for.

**Are notes the right place for review comments or test results?** They can be,
and the fact that they survive without rewriting is exactly the point. Two
things to weigh before building on them. They are not fetched or pushed by
default, so a note nobody has configured a refspec for is a note only you can
see — `git log` will simply not show it to anyone else. And they are attached
to hashes, so a rebase of the branch loses every note on it unless
`notes.rewriteRef` is set everywhere.

In practice this is why review comments live on a forge rather than in notes,
and why the projects that use notes seriously — the Git project itself among
them — use them for things that are attached to commits that will never be
rewritten.

## The settings

| Setting | Does |
|---|---|
| `core.notesRef` | Which notes ref to read and write; `refs/notes/commits` by default |
| `notes.displayRef` | Extra notes refs for `git log` to show; may be a glob, and may repeat |
| `notes.rewriteRef` | Which notes to copy when a command rewrites commits; no default |
| `notes.rewriteMode` | What to do when the new commit already has a note |
| `notes.rewrite.amend`, `notes.rewrite.rebase` | Whether to copy notes for those commands; both true |
| `notes.mergeStrategy` | The default strategy for `git notes merge` |
| `notes.<name>.mergeStrategy` | The same, for one notes ref |
| `advice.graftFileDeprecated` | Whether the warning about `info/grafts` is printed |
| `core.commitGraph` | Whether the commit-graph is used; replacements and grafts turn it off (Chapter 69) |

| Environment variable | Does |
|---|---|
| `GIT_NO_REPLACE_OBJECTS` | Ignore replace refs, as `--no-replace-objects` does |
| `GIT_NOTES_REF` | Which notes ref to use, overriding `core.notesRef` |
| `GIT_NOTES_DISPLAY_REF` | Which notes to show, overriding `notes.displayRef` |
| `GIT_NOTES_REWRITE_REF`, `GIT_NOTES_REWRITE_MODE` | The same for the rewrite settings |
