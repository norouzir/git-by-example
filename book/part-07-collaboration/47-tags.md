# Chapter 47. Tags

## What it is

A tag is a name for one commit that stays where it was put. A branch moves
forward with every commit made on it (Chapter 23); a tag does not, which is what
makes it the right name for a release: `v1.1` means the same commit to everyone
who has it, today and years from now. `git tag` makes, lists and deletes tags.
Its plain form, with no arguments, answers one question: *which tags does this
repository have?*

There are two kinds, and Chapter 6 showed what each one is inside the
repository. A *lightweight* tag is only a name pointing at a commit. An
*annotated* tag points at a tag object, which records who made the tag, when,
and a message, and which can carry a signature. Most of this chapter works the
same for both; where it does not, it says so.

| Term | Means |
|---|---|
| *tag* | a ref under `refs/tags/`: a name that does not move when you commit (Chapter 7) |
| *lightweight tag* | a tag that points straight at a commit |
| *annotated tag* | a tag that points at a tag object |
| *tag object* | an object holding the tagged object's hash, the tag's name, the tagger, a date and a message (Chapter 6) |
| *tagger* | who made an annotated tag, taken from the committer identity (Chapter 3) |
| *peel* | follow a tag object to what it points at; `v1.1^{}` is the commit behind `v1.1` (Chapter 18) |
| *release tag* | an annotated tag naming a published version, such as `v1.1` |
| *contains* | a tag contains a commit when the commit is in the history of the tagged commit |
| *release candidate* | a version offered for testing before the release itself, tagged like `v1.1-rc1` |

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What is a tag, and how is it different from a branch?](#what-it-is)
- [What are the two kinds of tag?](#what-it-is)

**[Synopsis](#synopsis)**

- [What are the forms of `git tag`, and when is a tag annotated?](#synopsis)

**[Options at a glance](#options-at-a-glance)**

- [Is there a list of every option, and where each is shown?](#options-at-a-glance)

**[The example repository](#the-example-repository)**

- [What repository do the examples use?](#the-example-repository)

**[Reading the output](#reading-the-output)**

- [How do I see the tags a repository has, and their messages?](#reading-the-output)
- [Why does `git show` of a tag print two dates?](#reading-the-output)

**[Listing tags](#listing-tags)**

- [How do I list only some tags?](#patterns)
- [I typed `git tag 'v1.*'` to list tags and got an error. Why?](#patterns)
- [Why does `v1.1-rc1` come after `v1.1`, and how do I list the newest version first?](#order)
- [How do I list tags in the order they were made?](#order)
- [How do I see more of each message, or lay the list out differently?](#layout)
- [How do I leave out the blank lines my format prints for some tags?](#layout)
- [Which releases include a given commit?](#tags-by-history)
- [Which tags are on a branch, and which are not?](#tags-by-history)
- [Which tag points at this commit?](#tags-by-history)

**[Lightweight and annotated tags](#lightweight-and-annotated-tags)**

- [How can I tell whether a tag is lightweight or annotated?](#lightweight-and-annotated-tags)
- [Why does `git describe` ignore my tag?](#lightweight-and-annotated-tags)
- [Which kind should I use for a release?](#lightweight-and-annotated-tags)

**[Creating a tag](#creating-a-tag)**

- [How do I tag a commit other than the one I am on?](#where-the-tag-goes)
- [How do I write a tag message, from the command line, a file or an editor?](#the-message)
- [I closed the editor without writing anything. What happened to the tag?](#the-message)
- [Why is my tag's message empty although I gave one with `-m`?](#the-message)
- [What do the `--cleanup` modes change?](#the-message)
- [How do I add a line such as `Reviewed-by:` to a tag message?](#the-message)
- [Why does Git say my tag name is not valid?](#names-a-tag-cannot-have)
- [Why can I not make `v1.2/rc1` when `v1.2` exists?](#names-a-tag-cannot-have)
- [Can I tag a file, or tag a tag?](#tagging-something-other-than-a-commit)
- [Where do the tagger and the date come from, and can I set the date?](#the-tagger-and-the-date)

**[Deleting a tag](#deleting-a-tag)**

- [How do I delete several tags, or all tags matching a pattern?](#deleting-a-tag)
- [One of the names I deleted did not exist. Were the others deleted?](#deleting-a-tag)
- [I deleted a tag by mistake. How do I get it back?](#deleting-a-tag)
- [Does a tag keep its commit from being cleaned away?](#what-a-tag-keeps-alive)

**[Moving a tag](#moving-a-tag)**

- [How do I move a tag to another commit?](#moving-a-tag)
- [I moved an annotated tag with `-f` and lost its message. Why?](#moving-a-tag)
- [I moved a tag others had already fetched. What happens to them?](#moving-a-published-tag)
- [What should I do when I have published a tag on the wrong commit?](#moving-a-published-tag)

**[Tags and remotes](#tags-and-remotes)**

- [Where are pushing, fetching and deleting tags on a server covered?](#tags-and-remotes)
- [I deleted a tag, and the next fetch brought it back. Why?](#tags-and-remotes)
- [Why does `git push origin <name>` say "src refspec matches more than one"?](#tags-and-remotes)

**[A reflog for a tag](#a-reflog-for-a-tag)**

- [Does a tag have a reflog, and how do I give it one?](#a-reflog-for-a-tag)
- [Why does `git reflog` show nothing for my annotated tag?](#a-reflog-for-a-tag)

**[Verifying a tag](#verifying-a-tag)**

- [What does `git tag -v` say about a tag that is not signed?](#verifying-a-tag)

**[Tags and their neighbours](#tags-and-their-neighbours)**

- [What is the difference between a tag and a branch?](#tags-and-their-neighbours)
- [Which command lists tags best: `git tag`, `git for-each-ref`, `git show-ref` or `git ls-remote`?](#tags-and-their-neighbours)
- [How do `git tag --contains`, `git describe --contains` and `git branch --contains` differ?](#tags-and-their-neighbours)

**[Undoing tag operations](#undoing-tag-operations)**

- [How do I undo each thing `git tag` does?](#undoing-tag-operations)

**[The settings](#the-settings)**

- [Which settings change how tags are made and listed?](#the-settings)

</details>

## Synopsis

```
git tag [-a | -s | -u <key-id>] [-f] [-m <msg> | -F <file>] [-e]
        [(--trailer <token>[(=|:)<value>])...]
        <tagname> [<commit> | <object>]
git tag -d <tagname>...
git tag [-n[<num>]] -l [--contains <commit>] [--no-contains <commit>]
        [--points-at <object>] [--column[=<options>] | --no-column]
        [--create-reflog] [--sort=<key>] [--format=<format>]
        [--merged <commit>] [--no-merged <commit>] [<pattern>...]
git tag -v [--format=<format>] <tagname>...
```

| Form | Does |
|---|---|
| `git tag <tagname> [<commit>]` | makes a lightweight tag on `<commit>`, `HEAD` if none is given |
| `git tag -a <tagname> [<commit>]`, or with `-m`, `-F` or `--trailer` | makes an annotated tag; a message, a file or a trailer is enough, as Git's documentation says they imply `-a` |
| `git tag -s`, `git tag -u <key-id>` | makes a signed annotated tag (Chapter 68) |
| `git tag -d <tagname>...` | deletes tags |
| `git tag`, `git tag -l [<pattern>...]` | lists tags, optionally only those matching a pattern |
| `git tag -v <tagname>...` | checks the signatures of tags |

`<tagname>` must not exist yet unless `-f` is given. `<object>` is there
because a tag can name any object, although it is almost always a commit
([Tagging something other than a commit](#tagging-something-other-than-a-commit)).

## Options at a glance

### Options for creating a tag

| Option | Does | Covered in |
|---|---|---|
| `-a`, `--annotate` | Make an annotated tag, asking for a message in the editor | [The message](#the-message) |
| `-m <msg>`, `--message=<msg>` | The message; given twice, two paragraphs | [The message](#the-message) |
| `-F <file>`, `--file=<file>` | Read the message from a file, or with `-` from standard input | [The message](#the-message) |
| `-e`, `--edit` | Open the editor on a message given with `-m` or `-F` | [The message](#the-message) |
| `--cleanup=strip` | Remove comment lines, trailing spaces and extra blank lines; the default | [The message](#the-message) |
| `--cleanup=whitespace` | The same, but keep comment lines | [The message](#the-message) |
| `--cleanup=verbatim` | Keep the message exactly as given | [The message](#the-message) |
| `--trailer <token>=<value>` | Add a trailer line, such as `Reviewed-by: Bob` | [The message](#the-message) |
| `-f`, `--force` | Replace a tag that already exists | [Moving a tag](#moving-a-tag) |
| `--create-reflog` | Keep a reflog for the tag | [A reflog for a tag](#a-reflog-for-a-tag) |
| `-s`, `--sign` | Make a signed annotated tag | Chapter 68 |
| `-u <key-id>`, `--local-user=<key-id>` | Sign with this key | Chapter 68 |
| `--no-sign` | Do not sign, although `tag.gpgSign` says to | Chapter 68 |

### Options for listing tags

| Option | Does | Covered in |
|---|---|---|
| `-l`, `--list` | List tags, only those matching the patterns given | [Patterns](#patterns) |
| `-n<num>` | Print `<num>` lines of each message; `-n` alone prints one | [Layout](#layout) |
| `-i`, `--ignore-case` | Sort and match patterns regardless of case | [Patterns](#patterns) |
| `--sort=<key>` | Sort by a field of `git for-each-ref`, descending with `-` before it | [Order](#order) |
| `--sort=version:refname` | Sort names as version numbers; also written `v:refname` (Chapter 22) | [Order](#order) |
| `--column`, `--no-column` | Lay the names out in columns, or one per line | [Layout](#layout) |
| `--format=<format>` | Choose what each line shows, with the fields of `git for-each-ref` | [Layout](#layout) |
| `--color[=<when>]` | Use the colours the format names | [Layout](#layout) |
| `--omit-empty` | Print nothing for a tag whose format comes out empty | [Layout](#layout) |
| `--contains [<commit>]`, `--no-contains [<commit>]` | Tags whose history has, or lacks, a commit; `HEAD` by default | [Tags by history](#tags-by-history) |
| `--merged [<commit>]`, `--no-merged [<commit>]` | Tags on commits in, or not in, a commit's history | [Tags by history](#tags-by-history) |
| `--points-at [<object>]` | Tags on this object | [Tags by history](#tags-by-history) |

### Options for deleting and verifying

| Option | Does | Covered in |
|---|---|---|
| `-d`, `--delete` | Delete the tags named | [Deleting a tag](#deleting-a-tag) |
| `-v`, `--verify` | Check the signature of the tags named | [Verifying a tag](#verifying-a-tag), Chapter 68 |

> **Since Git 2.41.** `--omit-empty`. **Since Git 2.46.** `--trailer`.

## The example repository

```console
$ git log --oneline --graph --all --decorate
* d679034 (HEAD -> main, origin/main) Add the Americas
* 1eb8cf0 (tag: v1.1) Add Oceania
* 30e68b2 Fix the Africa map
* 307bdc7 (tag: v1.1-rc1) Add Africa
| * 05f79d9 (tag: v1.0.1, origin/maint, maint) Fix the spelling of Asia
|/  
* 3622228 (tag: v1.0) Add Asia
* 0fe19df Add Europe
* 0dd6887 Start the atlas
```

Ada's atlas, with four annotated tags: the first edition `v1.0`, a release
candidate `v1.1-rc1`, the second edition `v1.1`, and `v1.0.1`, a corrected first
edition on `maint`, a branch that started at `v1.0` for fixes to it. `main`
has one commit since the last release. Everything has been pushed to a bare
repository on the "server", `origin`.

## Reading the output

```console
$ git tag
v1.0
v1.0.1
v1.1
v1.1-rc1
$ git tag -n
v1.0            First edition
v1.0.1          First edition, corrected
v1.1            Second edition
v1.1-rc1        Second edition, first candidate
$ git show -s v1.1
tag v1.1
Tagger: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 15:00:00 2026 +0000

Second edition

commit 1eb8cf0f7a268b647c3bd441825df4eefb7efcd0
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 14:00:00 2026 +0000

    Add Oceania
```

`git tag` lists names in the order of their characters, which is why `v1.1-rc1`
comes after `v1.1` ([Order](#order)). `-n` adds the first line of each message.
`git show` of an annotated tag prints the tag object first, its tagger, the date
it was tagged and its message, and then the commit it points at; `-s` leaves out
the commit's diff (Chapter 18). The two dates differ because a tag records when
it was made, not when its commit was. On a terminal the list goes through a
pager, as `git log` does, and Git's documentation says the setting `pager.tag`
applies only to listing.

## Listing tags

### Patterns

```console
$ git tag -l 'v1.0*'
v1.0
v1.0.1
$ git tag -l 'v1.0*' 'v1.1-*'
v1.0
v1.0.1
v1.1-rc1
$ git tag 'v1.0*'; echo "exit $?"
fatal: 'v1.0*' is not a valid tag name.
exit 128
$ git tag -i -l 'V1.1*'
v1.1
v1.1-rc1
```

`-l` with patterns lists the tags matching any of them. A pattern is a shell
wildcard, `*` for any run of characters and `?` for one, matched by Git itself,
so it is quoted to keep the shell from expanding it first. Without `-l`, a
name after `git tag` is a tag to create, and `*` cannot be part of a tag's name.
`-i` matches regardless of case. Git's documentation says the other listing
options, such as `--contains`, imply `-l`.

### Order

```console
$ git tag --sort=-version:refname
v1.1-rc1
v1.1
v1.0.1
v1.0
$ git -c versionsort.suffix=-rc tag --sort=version:refname
v1.0
v1.0.1
v1.1-rc1
v1.1
$ git tag --sort=taggerdate --format='%(taggerdate:iso) %(refname:short)'
2026-01-05 12:00:00 +0000 v1.0
2026-01-05 13:00:00 +0000 v1.1-rc1
2026-01-05 15:00:00 +0000 v1.1
2026-01-05 16:00:00 +0000 v1.0.1
$ git -c tag.sort=-version:refname tag -l 'v1.0*'
v1.0.1
v1.0
```

`version:refname` compares the numbers inside the names as numbers, so `v1.10`
would come after `v1.9` (Chapter 22 shows it), and `-` in front reverses the
order: newest version first. Names with the same version and different endings
are still compared as text, which puts `v1.1-rc1` after `v1.1`, and
`versionsort.suffix=-rc` says that an ending of `-rc` comes before the release
itself. `taggerdate` sorts by when each tag was made. `tag.sort` is the order
used when no `--sort` is given. `--sort` takes every field `git for-each-ref`
knows, and Chapter 22 covers them, with the rule for several `--sort` options.

### Layout

```console
$ git tag -n3 v1.0.1
v1.0.1          First edition, corrected
    
    Fixes the spelling of Asia.
$ git tag --column
v1.0      v1.0.1    v1.1      v1.1-rc1
$ git -c column.tag=always tag --no-column -l 'v1.0*'
v1.0
v1.0.1
$ git tag --format='%(refname:short) is on %(*objectname:short), %(*subject)'
v1.0 is on 3622228, Add Asia
v1.0.1 is on 05f79d9, Fix the spelling of Asia
v1.1 is on 1eb8cf0, Add Oceania
v1.1-rc1 is on 307bdc7, Add Africa
$ git tag --format='%(if)%(contents:body)%(then)%(refname:short)%(end)'

v1.0.1

v1.1-rc1
$ git tag --omit-empty --format='%(if)%(contents:body)%(then)%(refname:short)%(end)'
v1.0.1
v1.1-rc1
```

`-n3` prints up to three lines of each message, here the subject, the blank
line after it and the body. `--column` sets the names side by side, and
`--no-column` overrides `column.tag` for one command. `--format` takes the
fields of `git for-each-ref` (Chapter 22): a `*` in front of a field reads it
from the object the tag points at, here the commit's hash and subject. The last
two print a tag's name only if its message has a body; Git still ends each
empty result with a newline, and `--omit-empty` drops those lines.

```ansi
$ git tag --color=always --format='%(color:yellow)%(refname:short)%(color:reset) %(contents:subject)' -l 'v1.1*'
\e[33mv1.1\e[m Second edition
\e[33mv1.1-rc1\e[m Second edition, first candidate
```

`%(color:...)` in a format colours what follows it. Without `--color`,
`git tag` follows `color.ui`, which by default colours output on a terminal and
not in a pipe or a file (Chapter 17). `--color=always` colours it anywhere, as
here, and `--color=never` nowhere.

### Tags by history

```console
$ git tag --contains main~3
v1.1
v1.1-rc1
$ git tag --contains maint
v1.0.1
$ git tag --no-contains main~3
v1.0
v1.0.1
$ git tag --merged main
v1.0
v1.1
v1.1-rc1
$ git tag --no-merged main
v1.0.1
$ git tag --points-at main~1
v1.1
$ git tag --contains; echo "exit $?"
exit 0
```

`main~3` is `Add Africa`. `--contains` answers "which releases have this
commit?": the ones made from it or after it. The fix on `maint` is in `v1.0.1`
only, because nothing on `main` was made from it. `--merged main` lists the tags
whose commits are part of `main`'s history, and `--no-merged` the rest, here the
maintenance release. `--points-at` finds the tags on one commit, annotated or
not. Without a commit, the first four take `HEAD`: nothing contains `main`'s
newest commit, which is not released yet, and an empty list is not an error.
Chapter 22 shows the same filters for `git for-each-ref`, and how several of them
combine.

## Lightweight and annotated tags

```console
$ git tag reviewed main~2 && git tag -n reviewed v1.1
reviewed        Fix the Africa map
v1.1            Second edition
$ git show -s reviewed
commit 30e68b24d7da54655a0c9d1506daf8c1f4adbcaf
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 13:00:00 2026 +0000

    Fix the Africa map
$ git tag --format='%(objecttype) %(refname:short)'
commit reviewed
tag v1.0
tag v1.0.1
tag v1.1
tag v1.1-rc1
$ git describe main~2 && git describe --tags main~2
v1.1-rc1-1-g30e68b2
reviewed
```

`reviewed` is lightweight: it has no message of its own, so `-n` prints the
commit's subject, as Git's documentation says it does for such a tag, and
`git show` prints the commit alone. `%(objecttype)` tells the two kinds apart:
`commit` for a lightweight tag, `tag` for an annotated one. `git describe`
ignores lightweight tags unless given `--tags` (Chapter 22), and so named the
same commit twice in two different ways.

| Where it shows | Annotated tag | Lightweight tag |
|---|---|---|
| `git tag -n` | the tag's own message | the commit's subject |
| `git show <tag>` | the tag, then the commit | the commit |
| `git tag --format='%(objecttype)'` | `tag` | `commit` |
| `git rev-parse <tag>` | the tag object's hash (Chapter 6) | the commit's hash |
| `git describe` | used | used only with `--tags` (Chapter 22) |
| `git push --follow-tags` | pushed with the commits it tags | not pushed (Chapter 43) |
| `git tag -v` | checks the signature, if there is one | refused ([Verifying a tag](#verifying-a-tag)) |

Git's documentation says annotated tags are meant for releases and lightweight
ones for private or temporary labels, and the commands above are built on that
assumption. Tag a release with a message; a lightweight tag is for your own
bookmark, such as `reviewed`.

## Creating a tag

### Where the tag goes

```console
$ git tag europe-done main~5 && git tag europe-done-2 0fe19df && git tag --points-at main~5
europe-done
europe-done-2
$ git tag nowhere nosuch; echo "exit $?"
fatal: Failed to resolve 'nosuch' as a valid ref.
exit 128
```

The commit comes after the name, in any form Chapter 18 describes, and `HEAD`
is used when there is none. A tag made while `HEAD` is detached goes on that
commit, and `HEAD` stays detached (Chapter 24). The two tags were deleted
afterwards.

### The message

```console
$ git tag -m 'Third edition' -m 'Adds the Americas.' v1.2 && git tag -n3 v1.2
v1.2            Third edition
    
    Adds the Americas.
$ GIT_EDITOR=true git tag -a try-editor; echo "exit $?"
fatal: no tag message?
exit 128
$ cat .git/TAG_EDITMSG

#
# Write a message for tag:
#   try-editor
# Lines starting with '#' will be ignored.
```

`-m` made an annotated tag without `-a`, and two `-m` became two paragraphs.
`-a` alone opens the editor. `GIT_EDITOR=true` stands in for closing the editor
without writing anything, and Git then refuses to make the tag. What the editor
showed stays in `.git/TAG_EDITMSG`, which Git's documentation says keeps a
message typed before an error, until the next `git tag` overwrites it.

```console
$ GIT_EDITOR='cp ../message.txt' git tag -a try-editor && git tag -n3 try-editor
try-editor      Third edition, from a file
    
    Written in an editor.
$ printf 'Third edition, from standard input\n' | git tag -F - try-stdin && git tag -n try-stdin
try-stdin       Third edition, from standard input
$ GIT_EDITOR=cat git tag -e -m 'Third edition, edited' try-edit
Third edition, edited
```

`GIT_EDITOR='cp ../message.txt'` stands in for typing a message in the editor:
it copies a prepared file over the one Git opened, as Chapter 35 explains.
`-F` reads the message from a file, and `-F -` from standard input. `-e` opens
the editor on a message given with `-m` or `-F`, so it can be changed before
the tag is made; `cat` stands in for the editor here and printed what it was
given, the message and nothing more.

```console
$ git tag -m '#1 in the charts' try-hash && git tag -n try-hash && git cat-file -p try-hash
try-hash
object d6790347f661e695d0c40af795f31afd89142d1d
type commit
tag try-hash
tagger Ada Lovelace <ada@example.com> 1767632400 +0000

$ git commit -q --allow-empty -m '#1 in the charts' && git log -1 --format=%s && git reset -q --hard HEAD~1
#1 in the charts
```

The tag was made, with no error, and its message is empty: a line starting with
`#` is a comment, and `git tag` removes comments even from a message given with
`-m`. `git commit -m` kept the same line, because a commit removes comments only
from a message edited in the editor (Chapter 12). The commit was removed again
by the `reset`.

```console
$ printf 'Third edition\n\n\n# Americas still to check\n' > ../draft.txt
$ git tag --cleanup=strip -F ../draft.txt cleanup-strip && git tag --cleanup=whitespace -F ../draft.txt cleanup-whitespace && git tag --cleanup=verbatim -F ../draft.txt cleanup-verbatim
$ git tag -l 'cleanup-*' --format='%(refname:short): [%(contents)]'
cleanup-strip: [Third edition
]
cleanup-verbatim: [Third edition


# Americas still to check
]
cleanup-whitespace: [Third edition

# Americas still to check
]
```

One message with two blank lines in a row and a comment, made into a tag three
ways; the brackets show where each message starts and ends. `strip`, the
default, removed the comment and the blank lines it left at the end.
`whitespace` kept the comment and reduced the two blank lines to one. `verbatim`
kept everything.

```console
$ git tag -m 'Third edition, reviewed' --trailer 'Reviewed-by: Bob <bob@example.com>' try-trailer && git cat-file -p try-trailer
object d6790347f661e695d0c40af795f31afd89142d1d
type commit
tag try-trailer
tagger Ada Lovelace <ada@example.com> 1767632400 +0000

Third edition, reviewed

Reviewed-by: Bob <bob@example.com>
$ git tag -l try-trailer --format='%(trailers:key=Reviewed-by,valueonly)'
Bob <bob@example.com>
```

`--trailer` adds a line in the `Key: value` form at the end of the message, as
`git commit --trailer` does (Chapter 12), and `%(trailers)` reads it back out.
Git's documentation says the `trailer.*` settings of `git interpret-trailers`
decide where it goes and what happens to a duplicate.

### Names a tag cannot have

```console
$ git tag 'third edition'; echo "exit $?"
fatal: 'third edition' is not a valid tag name.
exit 128
$ git tag -- -draft; echo "exit $?"
fatal: '-draft' is not a valid tag name.
exit 128
$ git tag v1.2/rc1; echo "exit $?"
fatal: cannot lock ref 'refs/tags/v1.2/rc1': 'refs/tags/v1.2' exists; cannot create 'refs/tags/v1.2/rc1'
exit 128
$ git tag v1.2; echo "exit $?"
fatal: tag 'v1.2' already exists
exit 128
```

A tag's name follows the rules for every ref name: no spaces, no `..`, no `*`,
`?`, `[` or `~`, and more, which Chapter 7 lists with `git check-ref-format`. As
with a branch, it cannot begin with `-` either. A
`/` is allowed and makes a hierarchy, such as `release/1.2`, but then `v1.2`
cannot also be a tag: a ref is stored like a file, and `v1.2` cannot be a file
and a directory at once. An existing name is refused unless `-f` replaces it
([Moving a tag](#moving-a-tag)). A tag may have the same name as a branch, but
the name is then ambiguous: Chapter 18 shows which one Git picks, and
[Tags and remotes](#tags-and-remotes) what `git push` makes of it.

### Tagging something other than a commit

```console
$ git tag readme main:README.md && git cat-file -t readme && git show readme
blob
# Atlas
$ git tag -m 'The tag of a tag' v1.2-again v1.2
hint: You have created a nested tag. The object referred to by your new tag is
hint: already a tag. If you meant to tag the object that it points to, use:
hint:
hint: 	git tag -f v1.2-again v1.2^{}
hint: Disable this message with "git config set advice.nestedTag false"
$ git cat-file -p v1.2-again | head -2
object a2973391335577ea1be6dab82f7f3f9247242965
type tag
```

`main:README.md` names a file's content (Chapter 18), and the tag points at that
blob; `git show` prints it. An annotated tag made on another annotated tag
points at the tag object, not at the commit, which is rarely what was meant, and
the hint says how to tag the commit instead with `^{}` (Chapter 18). Both tags
were deleted in the next section.

### The tagger and the date

```console
$ GIT_COMMITTER_DATE='2025-12-24 10:00:00 +0000' git tag -m 'The draft edition, tagged late' v0.9 main~5 && git tag --sort=taggerdate --format='%(taggerdate:iso) %(refname:short)' -l 'v0*' 'v1.0'
2025-12-24 10:00:00 +0000 v0.9
2026-01-05 12:00:00 +0000 v1.0
```

The tagger and the date of an annotated tag come from the committer identity and
the current time, the same as for a commit's committer (Chapter 12); Git's source
asks for the committer identity when it writes a tag. So `GIT_COMMITTER_DATE`
sets the date. Git's documentation gives this as the way to backdate a tag, for
example when adding tags for old releases to a history imported from another
system; tools that sort tags by date then put it in its place.

## Deleting a tag

```console
$ git tag -d try-editor try-stdin try-edit try-hash try-trailer v1.2-again
Deleted tag 'try-editor' (was ff9425b)
Deleted tag 'try-stdin' (was 4416d36)
Deleted tag 'try-edit' (was 627f6f0)
Deleted tag 'try-hash' (was fd21c66)
Deleted tag 'try-trailer' (was a785a80)
Deleted tag 'v1.2-again' (was bbb4130)
$ git tag -d 'cleanup-*'; echo "exit $?"
error: tag 'cleanup-*' not found.
exit 1
$ git tag -d $(git tag -l 'cleanup-*')
Deleted tag 'cleanup-strip' (was e058289)
Deleted tag 'cleanup-verbatim' (was f482b50)
Deleted tag 'cleanup-whitespace' (was 0bdc9e6)
$ git tag -d nosuch readme; echo "exit $?"
error: tag 'nosuch' not found.
Deleted tag 'readme' (was 851f7e5)
exit 1
```

`-d` takes names, not patterns; `$(git tag -l ...)` lets the shell hand it the
names a pattern matches. A name that does not exist is reported, and the others
are deleted all the same, with exit status 1. In Git's source, `git tag -d`
checks every name before deleting any, which is why the error comes first.

```console
$ git tag -d v0.9
Deleted tag 'v0.9' (was a70adba)
$ git tag v0.9 a70adba && git tag -n v0.9 && git cat-file -t v0.9
v0.9            The draft edition, tagged late
tag
```

The hash after `was` is what the tag pointed at: for an annotated tag, its tag
object. A lightweight tag made on that hash is the old tag again, message and
all, because a tag is only a name for an object and the object was never
deleted. It stays in the repository until `git gc` removes it, which the next
section shows.

### What a tag keeps alive

```console
$ git commit -q --allow-empty -m 'Try a new projection' && git tag experiment && git reset -q --hard HEAD~1
$ git branch --contains experiment; git log --oneline -1 experiment
d435054 Try a new projection
$ git reflog expire --expire=now --all && git gc -q --prune=now && git log --oneline -1 experiment
d435054 Try a new projection
$ git tag -d experiment && git reflog expire --expire=now --all && git gc -q --prune=now && git cat-file -t d435054; echo "exit $?"
Deleted tag 'experiment' (was d435054)
fatal: Not a valid object name d435054
exit 128
```

A commit was tagged, and the branch was moved back past it, so no branch
contains it. `git reflog expire --expire=now --all` and `git gc --prune=now`
together are the harshest cleanup there is: they forget every reflog entry and
remove every object nothing names (Chapters 36 and 77). The commit survived,
because the tag names it. With the tag deleted, the same cleanup removed it.
This is why a tag on a commit keeps it, and the history behind it, for as long
as the tag exists, whatever happens to the branches (Chapter 28).

## Moving a tag

```console
$ git tag -f v1.2 main && git cat-file -t v1.2
Updated tag 'v1.2' (was a297339)
commit
$ git tag -f v1.2 a297339 && git cat-file -t v1.2 && git tag -n3 v1.2
Updated tag 'v1.2' (was d679034)
tag
v1.2            Third edition
    
    Adds the Americas.
```

`-f` replaces a tag, and here it also changed its kind: without `-a` or a
message, the new `v1.2` is lightweight, and the annotated tag's message is gone
from the name. Give the message again, or `-a`, to keep a moved tag annotated.
The old tag object was still there, and a lightweight tag on its hash, the one
`was` printed, put `v1.2` back as it had been.

### Moving a published tag

`v1.2` had been pushed, and Bob had cloned since. Ada adds a commit and moves
`v1.2` to it, forcing the push with `+` (Chapter 43):

```console
$ git tag -f -m 'Third edition' -m 'Adds the Americas and Antarctica.' v1.2 && git push origin main +v1.2
Updated tag 'v1.2' (was a297339)
To /home/ada/server/atlas.git
   d679034..d43f1c7  main -> main
 + a297339...52eb5b4 v1.2 -> v1.2 (forced update)
```

In Bob's clone:

```console
$ git fetch && git log --oneline -1 v1.2
From /home/ada/server/atlas
   d679034..d43f1c7  main       -> origin/main
d679034 Add the Americas
$ git tag -d v1.2 && git fetch origin tag v1.2 && git log --oneline -1 v1.2
Deleted tag 'v1.2' (was a297339)
From /home/ada/server/atlas
 * [new tag]         v1.2       -> v1.2
d43f1c7 Add Antarctica
```

Bob's fetch brought the new commit and said nothing about the tag: his `v1.2`
still names the old commit, and nothing tells him otherwise. A fetch only adds
tags he does not have, and refuses to change one he has unless forced
(Chapter 41). Git's documentation says so on purpose: people must be able to
trust their tag names, and Git does not change a tag behind a user's back.

The same documentation gives two courses for a tag published on the wrong
commit. The one it recommends is to leave the tag alone and release the fix
under a new name, such as `v1.2.1`, so that nobody is left with two different
things both called `v1.2`. The other is to move it, as Ada did, and tell
everyone, with the commands Bob ran: delete the tag, then fetch it again by name.

## Tags and remotes

Tags travel between repositories as refs, and the chapters on remotes cover
them there:

| To | Use | Covered in |
|---|---|---|
| send one tag | `git push origin <tag>`, `git push origin tag <tag>` | Chapter 43 |
| send annotated tags along with the commits pushed | `git push --follow-tags`, or `push.followTags` | Chapter 43 |
| send every tag | `git push --tags` | Chapter 43 |
| delete a tag on the server | `git push origin --delete <tag>` | Chapter 43 |
| receive tags | automatic, for tags on fetched commits; `git fetch --tags` for all | Chapter 41 |
| receive no tags | `git fetch --no-tags`, `git clone --no-tags` | Chapters 41 and 9 |
| drop tags the server no longer has | `git fetch --prune --prune-tags` | Chapter 41 |
| accept a tag that moved on the server | `git fetch --tags --force` | Chapter 41 |
| see the server's tags | `git ls-remote --tags origin` | Chapter 39 |

Two things fall between those chapters:

```console
$ git push -q origin main v1.2 && git tag -d v1.1-rc1 && git fetch && git tag -l 'v1.1*'
Deleted tag 'v1.1-rc1' (was eb00f2e)
From /home/ada/server/atlas
 * [new tag]         v1.1-rc1   -> v1.1-rc1
v1.1
v1.1-rc1
$ git branch release main~1 && git tag release && git push origin release; echo "exit $?"
error: src refspec release matches more than one
error: failed to push some refs to '/home/ada/server/atlas.git'
exit 1
$ git push origin tag release
To /home/ada/server/atlas.git
 * [new tag]         release -> release
```

A tag deleted only locally comes back with the next fetch, because the server
still has it and it points at a commit the fetch brings: fetch follows such tags
(Chapter 41). To be rid of it, delete it on the server too, and others then
remove theirs with `--prune-tags`. A branch and a tag with the same name make
`git push origin release` ambiguous, and it refuses. `tag release` says the tag
is meant, and Git's documentation expands it to the full name
`refs/tags/release` (Chapter 43); `refs/heads/release` would name the branch. The tag and the branch `release` were deleted again afterwards.

## A reflog for a tag

```console
$ git tag --create-reflog checkpoint main~2 && git tag -f checkpoint main~1 && git reflog show checkpoint
Updated tag 'checkpoint' (was 1eb8cf0)
d679034 refs/tags/checkpoint@{0}: tag: tagging d679034 (Add the Americas, 2026-01-05)
1eb8cf0 refs/tags/checkpoint@{1}: tag: tagging 1eb8cf0 (Add Oceania, 2026-01-05)
$ git tag --create-reflog -m 'Checked' checked main~2 && git tag -f -m 'Checked' checked main~1 && git reflog show checked; echo "exit $?"
Updated tag 'checked' (was d5b52de)
exit 0
$ git log --oneline -1 checked@{1}
1eb8cf0 Add Oceania
$ git tag -d checkpoint && git reflog show checkpoint; echo "exit $?"
Deleted tag 'checkpoint' (was d679034)
fatal: ambiguous argument 'checkpoint': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
exit 128
```

Tags have no reflog by default: Git's documentation of `core.logAllRefUpdates`
says the default keeps reflogs for branches, remote-tracking branches, notes and
`HEAD`, and `always` extends it to every ref. `--create-reflog` starts one for
a single tag, and after the tag moved, `git reflog` showed where it had been
(Chapter 36). For an annotated tag it showed nothing and succeeded, although
the reflog is there: `checked@{1}` still names the old tag, and through it the
commit. An annotated tag's entries are tag objects, and in Git's source the
reflog walk (`reflog-walk.c`) skips every entry that is not a commit. Deleting
a tag deletes its reflog with it.

## Verifying a tag

```console
$ git tag -v v1.2; echo "exit $?"
object d43f1c7eab92c96379bcd0f9415457ee104d173a
type commit
tag v1.2
tagger Ada Lovelace <ada@example.com> 1767636000 +0000

Third edition

Adds the Americas and Antarctica.
error: no signature found
exit 1
$ git tag -v reviewed; echo "exit $?"
error: reviewed: cannot verify a non-tag object of type commit.
exit 1
```

`-v` checks the signature of a signed tag, which `-s` or `-u` makes, and fails
without one: an unsigned annotated tag is printed, then refused with "no
signature found", and a lightweight tag has nothing to verify at all. Signing
needs a key and a program such as GPG or SSH, so Chapter 68 covers `-s`, `-u`,
`--no-sign`, `tag.gpgSign`, `git verify-tag` and what a good signature prints.

## Tags and their neighbours

```console
$ git tag --contains 307bdc7 && git describe --contains 307bdc7 && git branch --contains 307bdc7
reviewed
v1.1
v1.1-rc1
v1.2
v1.1-rc1^0
* main
```

`307bdc7` is `Add Africa`. `git tag --contains` lists every tag whose history
has it, lightweight ones included. `git describe --contains` names the commit
by the nearest tag after it, here the commit `v1.1-rc1` points at, which
Chapter 22 explains. `git branch --contains` lists branches instead (Chapter 23).

| Compared on | Tag | Branch |
|---|---|---|
| Moves when you commit | never | yes, when it is the current branch |
| Can be checked out and committed on | no; checking it out detaches `HEAD` (Chapter 24) | yes |
| Has a message, a date and an author of its own | when annotated | no |
| Sent by a plain `git push` | no | the current branch, by default (Chapter 43) |
| Received by a plain `git fetch` | when it points at a fetched commit | yes, as a remote-tracking branch |
| Has a reflog by default | no | yes |
| Changed on the server by others | should never happen | normal |

| Command | Lists tags | Use it when |
|---|---|---|
| `git tag -l` | here, with messages, sorted and filtered | you want to see or pick tags |
| `git for-each-ref refs/tags` | here, in any format (Chapter 22) | a script needs tags, or more than `git tag` can show |
| `git show-ref --tags` | here, with their hashes (Chapter 74) | you want every tag and its hash at once |
| `git ls-remote --tags <remote>` | on a server, without fetching (Chapter 39) | you want to see what a server has |

## Undoing tag operations

| You did | Undo it with |
|---|---|
| made a tag you did not want | `git tag -d <tag>` |
| deleted a tag | `git tag <tag> <hash>`, with the hash `Deleted tag` printed after `was` |
| moved a tag with `-f` | `git tag -f <tag> <hash>`, with the hash `Updated tag` printed after `was` |
| turned an annotated tag into a lightweight one with `-f` | the same: the hash after `was` is the tag object |
| pushed a tag by mistake | `git push origin --delete <tag>` (Chapter 43), and tell anyone who may have fetched it |
| published a tag on the wrong commit | a new tag with a new name, or move it and tell everyone ([Moving a published tag](#moving-a-published-tag)) |

The first four work as long as `git gc` has not removed the old object, which it
does only once nothing names it, no reflog entry needs it, and, by default, it is
more than two weeks old, as Git's documentation of `gc.pruneExpire` says
(Chapter 77; [What a tag keeps alive](#what-a-tag-keeps-alive)).

## The settings

| Setting | Does |
|---|---|
| `tag.sort` | The order of `git tag` when no `--sort` is given |
| `versionsort.suffix` | Endings such as `-rc` that sort before the release itself; may be given several times ([Order](#order)) |
| `column.tag` | Whether `git tag` lays names out in columns |
| `pager.tag` | Whether listing tags goes through the pager; true by default |
| `advice.nestedTag` | Whether to print the hint about a tag of a tag |
| `core.logAllRefUpdates` | `always` keeps a reflog for every tag (Chapter 36) |
| `core.warnAmbiguousRefs` | Whether to warn when a tag and a branch share a name (Chapter 18) |
| `tag.gpgSign`, `tag.forceSignAnnotated` | Sign every tag, or every annotated tag (Chapter 68) |
| `push.followTags` | Push annotated tags with the commits they tag (Chapter 43) |
| `remote.<name>.tagOpt` | `--no-tags` or `--tags` for every fetch from this remote (Chapter 41) |
| `fetch.pruneTags` | When a fetch prunes, prune tags too (Chapter 41) |
