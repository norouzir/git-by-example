# Chapter 53. Commit Message Conventions

## What it is

A commit message is text that Git stores with the commit and, for the most
part, never reads. It reads three things. The text up to the first blank line
is the *subject*, which every one-line view of history shows and which becomes
the subject of a mail when the commit is sent as a patch. The rest is the
*body*. And `Key: value` lines in the last paragraph are *trailers*, which
several commands write and read. Everything else, such as how long a subject
may be, whether it starts with a verb or a prefix like `fix:`, what the body
explains, and which trailers a project uses, is convention.

This chapter shows what Git does with each part, then the conventions: Git's
own project's, from `SubmittingPatches` and `MyFirstContribution`, which are
installed with Git's documentation; the Linux kernel's where they differ; and
Conventional Commits, a published specification many projects follow. It
covers `git interpret-trailers`, the command that reads and writes trailers, in
full. The one question it answers is: *what goes in a commit message, and what
does Git do with each part of it?*

| Term | Means |
|---|---|
| *subject*, *title*, *summary line* | the message up to the first blank line, normally a single line |
| *body* | everything after the first blank line |
| *trailer* | a `Key: value` line in the last paragraph of a message, such as `Signed-off-by: Ada Lovelace <ada@example.com>` |
| *trailer block* | that last paragraph, when Git counts it as trailers |
| *key*, *token* | the part of a trailer before the separator, such as `Signed-off-by` |
| *separator* | the character between key and value: `:`, unless configured otherwise |
| *sign-off* | a `Signed-off-by:` trailer, which certifies whatever the project says it certifies |
| *DCO* | the Developer's Certificate of Origin, what a sign-off certifies in Git's own project and in the Linux kernel |
| *Conventional Commits* | a specification that starts every subject with a type, such as `feat:` or `fix:` |
| *footer* | Conventional Commits' word for a trailer |

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [Does Git care what I write in a commit message?](#what-it-is)

**[The parts at a glance](#the-parts-at-a-glance)**

- [Which parts of a message does Git itself use, and how do I print each one?](#the-parts-at-a-glance)

**[The example repository](#the-example-repository)**

- [What repository do the examples use?](#the-example-repository)

**[The subject](#the-subject)**

- [Where does Git show the first line of my message?](#where-the-subject-appears)
- [I forgot the blank line after the first line. What happens?](#a-subject-of-more-than-one-line)
- [How long should the subject be, and what happens when it is longer?](#how-long)
- [Why is my patch's file name cut off?](#how-long)
- [Should the subject say "Add" or "Added", and should it start with a prefix?](#what-the-subject-says)
- [How do I find out what style a project uses?](#what-the-subject-says)

**[The body](#the-body)**

- [What should the body say?](#what-the-body-says)
- [Does Git wrap long lines in a message? Where should I break them?](#wrapping)
- [How do I mention another commit in a message?](#referring-to-another-commit)
- [How do I write the `Fixes:` line the Linux kernel asks for?](#referring-to-another-commit)
- [How do I refer to an issue, and why did my `#12` line disappear?](#referring-to-issues)

**[Trailers](#trailers)**

- [Which lines at the end of my message does Git treat as trailers?](#what-counts-as-a-trailer)
- [Why does Git ignore my `Refs:` line, but not when a `Signed-off-by` line is next to it?](#what-counts-as-a-trailer)
- [Can a trailer's value go over two lines?](#what-counts-as-a-trailer)
- [My message ends with a link, and `git commit -s` stuck the sign-off right under it. Why?](#a-line-that-only-looks-like-a-trailer)
- [Which trailers do projects use, and what does each mean?](#trailers-in-common-use)
- [What does `Signed-off-by` mean, and when does `-s` add it?](#signing-off)
- [Can I make Git sign off every commit automatically?](#signing-off)
- [Is signing off the same as signing a commit?](#signing-off)
- [How do I credit someone who wrote a commit with me?](#co-authors)
- [Which commands can add a trailer for me?](#adding-trailers-with-other-commands)

**[git interpret-trailers](#git-interpret-trailers)**

- [What forms does `git interpret-trailers` take?](#synopsis)
- [Which options does it have?](#options-at-a-glance)
- [How do I add a trailer to a message in a file?](#adding-a-trailer)
- [Where does a new trailer go, and how do I put it somewhere else?](#where-it-goes)
- [What happens when the message already has a trailer with that key?](#when-the-key-is-already-there)
- [Can I add a trailer only if the message has none of that kind?](#when-the-key-is-missing)
- [How do I print only the trailers of a message?](#reading-the-trailers)
- [My template has empty trailers. How do I remove the ones nobody filled in?](#reading-the-trailers)
- [Can I type `ack` and get `Acked-by`?](#keys-of-your-own)
- [Can a trailer's value come from a command?](#values-from-a-command)
- [Why does my `trailer.<key>.cmd` add nothing?](#values-from-a-command)
- [Why does a `---` line in my message move the trailer?](#patches-and-the-line)

**[Conventional Commits](#conventional-commits)**

- [What is a Conventional Commits message made of?](#the-format)
- [How do I list the features and fixes since the last release?](#reading-a-history-by-type)
- [Why doesn't Git see my `BREAKING CHANGE:` or `Refs #12` line as a trailer?](#conventional-commits-and-git-s-trailers)

**[Messages Git writes itself](#messages-git-writes-itself)**

- [Which messages does Git write for me, and where are they explained?](#messages-git-writes-itself)

**[Enforcing a convention](#enforcing-a-convention)**

- [How do I make Git refuse a message that breaks our convention?](#enforcing-a-convention)

**[Changing a message afterwards](#changing-a-message-afterwards)**

- [I wrote a bad message. How do I fix it?](#changing-a-message-afterwards)

**[Conventions compared](#conventions-compared)**

- [How do Git's own project, the Linux kernel and Conventional Commits differ?](#conventions-compared)

**[Messages and their neighbours](#messages-and-their-neighbours)**

- [Should this go in the message, a note, a tag or the pull request's description?](#messages-and-their-neighbours)

**[The settings](#the-settings)**

- [Which settings affect messages and trailers?](#the-settings)

</details>

## The parts at a glance

| Part | Where it is | Git uses it for | Printed by |
|---|---|---|---|
| subject | up to the first blank line | one-line views of history, patch subjects and file names, and the messages Git writes about a commit | `git log --format=%s` |
| body | after the first blank line | `git log`, `git show` | `git log --format=%b` |
| trailers | the last paragraph, when Git counts it as trailers | `-s`, `--trailer`, `git shortlog --group=trailer:<key>`, `git interpret-trailers` | `git log --format='%(trailers)'` |
| the whole message | | | `git log --format=%B` |

## The example repository

The `greet` project of Chapter 52: `lib.sh` holds shell functions, `test.sh`
tests them. Its history grows through the chapter, each commit written for the
section it appears in. Messages that are only read, never committed, are files
in a directory `msgs` beside the repository, and the commands read them from
there. Bob Brown's commits carry his own name.

```console
$ git log -1 --format=%B
Add a farewell

Greet people when they leave, as well as when they arrive.

Reviewed-by: Ada Lovelace <ada@example.com>
Signed-off-by: Bob Brown <bob@example.com>

$ git log -1 --format='%s'
Add a farewell
$ git log -1 --format='%b'
Greet people when they leave, as well as when they arrive.

Reviewed-by: Ada Lovelace <ada@example.com>
Signed-off-by: Bob Brown <bob@example.com>

$ git log -1 --format='%(trailers)'
Reviewed-by: Ada Lovelace <ada@example.com>
Signed-off-by: Bob Brown <bob@example.com>

```

Bob's commit, with all three parts. `%b`, the body, is everything after the
subject, trailers included; `%(trailers)` is the trailers alone (Chapter 17
covers both placeholders).

## The subject

### Where the subject appears

```console
$ git log --oneline -1 && git format-patch -q -1 -o out && ls out && grep '^Subject' out/*
9672af1 Add a farewell
0001-Add-a-farewell.patch
Subject: [PATCH] Add a farewell
```

Git's documentation for `git commit` says the text up to the first blank line
is treated as the commit's title throughout Git, and gives `git format-patch`
as an example: it makes the title the subject of the mail, and here the file
name too (Chapter 61). The other places it appears:

| Command | Shows the subject | Covered in |
|---|---|---|
| `git log --oneline`, `--format=%s` | after the short hash | Chapter 17 |
| `git shortlog` | one line per commit, under its author | Chapter 22 |
| `git rebase -i` | on each line of the todo list | Chapter 34 |
| `git branch -v` | beside each branch, for its last commit | Chapter 23 |
| `git commit --fixup` | in the new message: `fixup! <subject>` | Chapter 35 |
| `git revert` | in the new message: `Revert "<subject>"` | Chapter 31 |

### A subject of more than one line

```console
$ cat ../msg.txt && git commit -q -F ../msg.txt
Test the farewell
and the greeting together

One test run covers both functions.
$ git log --oneline -1 && git format-patch -q -1 -o out && ls out && grep '^Subject' out/*
c2b0152 Test the farewell and the greeting together
0001-Test-the-farewell.patch
Subject: [PATCH] Test the farewell and the greeting together
```

The subject is the first paragraph, not the first line: without a blank line
after it, the next line joins it, with a space between. `--oneline` and the
mail's subject show both lines as one, while the file name was made from the
first line only.

### How long

```console
$ git commit -q -m 'Explain in the README how to run the tests and what they print' && git log --oneline -1
c488410 Explain in the README how to run the tests and what they print
$ git format-patch -q -1 -o out && ls out
0001-Explain-in-the-README-how-to-run-the-tests-and-what-.patch
$ git log -1 --format='%<(50,trunc)%s'
Explain in the README how to run the tests and w..
```

Git accepts a subject of any length, and `--oneline` prints all of it. Git's
`git commit` documentation suggests no more than 50 characters, and
`SubmittingPatches` calls 50 the soft limit. `git format-patch` cuts the file
name at around 64 bytes, its documentation says; `--filename-max-length`
changes that (Chapter 61). `%<(50,trunc)` cuts at 50 characters and marks the
cut with `..` (Chapter 17), which shows where a 50-character limit would fall.
The Linux kernel's documentation sets 70 to 75 characters as the most for its
summary phrase.

### What the subject says

| Style | Example | Where it comes from |
|---|---|---|
| a verb in the imperative, no prefix | `Add a farewell` | the style of this book's examples; the imperative is what Git's project and the kernel ask for |
| an area, then a summary starting with a small letter, no full stop | `doc: clarify distinction between sign-off and pgp-signing` | Git's own project; the example is `SubmittingPatches`' own |
| a subsystem, then a summary | `subsystem: summary phrase` | the Linux kernel's documentation |
| a type, an optional scope, then a description | `fix(test): report which test failed` | Conventional Commits ([Conventional Commits](#conventional-commits)) |

*Imperative* means the form of a command: "make xyzzy do frotz", in the example
`SubmittingPatches` gives, rather than "makes" or "made", as if giving orders to
the code. The kernel's documentation asks for the same. In Git's project the
area is a file name or the name of the part of the code being changed, and the
word after it is not capitalised unless it would be anyway, as in `refs: HEAD
is also treated as a ref`.

To find what a project uses, `SubmittingPatches` says to run
`git log --no-merges` on the files you are changing and look.

## The body

### What the body says

`SubmittingPatches` asks the body to explain why the change is needed, not only
what it does, because whoever changes the code later needs to know what it was
meant to achieve. It lists what a good body covers:

- the problem: what is wrong with the code as it is;
- why the change solves it, and why that way is better;
- other solutions that were considered and rejected, if any.

It adds three rules of style. Describe the code as it is without the change in
the present tense, "the code does X", not "the code used to do X". Write the
change itself in the imperative, as for the subject. And make the message
understandable on its own: instead of a link to a discussion, summarise the
points that matter. `MyFirstContribution` puts the purpose of the body as
answering "why?", with what cannot readily be deduced from the diff.

### Wrapping

```console
$ git commit -q -m 'Say what the tests print' -m 'The README said how to run the tests but not what a successful run looks like, which left a new contributor unsure whether the silence meant success.' && git log -1
commit 71472d59557db5c9eecbc26b7f8acaf33a1d6468
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 14:00:00 2026 +0000

    Say what the tests print
    
    The README said how to run the tests but not what a successful run looks like, which left a new contributor unsure whether the silence meant success.
$ git log -1 --format='%w(72,4,4)%b'
    The README said how to run the tests but not what a successful run
    looks like, which left a new contributor unsure whether the silence
    meant success.

```

Git never breaks a line of a message. It stores each line as written and prints
it the same way, indented four spaces by `git log`: a long line stays long, and
a terminal wraps it
wherever its edge happens to be. So the convention is to break lines yourself.
`MyFirstContribution`'s example message is, in its own words, formatted to 72
columns; the kernel's documentation says 75. `-m` never breaks a line; in an
editor, breaking is up to you or to the editor's settings. `%w(72,4,4)` rewraps
a message for display only (Chapter 17); the commit is unchanged.

### Referring to another commit

```console
$ git show -s --pretty=reference HEAD~2
c2b0152 (Test the farewell and the greeting together, 2026-01-05)
$ git -c core.abbrev=12 -c pretty.fixes='Fixes: %h ("%s")' show -s --pretty=fixes HEAD~2
Fixes: c2b01522325d ("Test the farewell and the greeting together")
```

`SubmittingPatches` asks for another commit to be named as "abbreviated hash
(subject, date)", as in `Commit f86a374 (pack-bitmap.c: fix a memleak,
2015-03-30) noticed that ...`, and gives `git show -s --pretty=reference` to
print it (Chapter 17). The Linux kernel names the commit a fix repairs in a
trailer, `Fixes:`, with at least the first 12 characters of the hash and the
subject in brackets and quotes, and its documentation suggests two settings for
it: `core.abbrev = 12` and `pretty.fixes = Fixes: %h ("%s")`. `git -c` sets a
setting for one command only (Chapter 62), and `pretty.<name>` defines a format
that `--pretty=<name>` then uses (Chapter 17). The kernel's documentation adds
that a `Fixes:` line must not be split over lines.

A hash in a message is only text: when the commit it names is rewritten, by a
rebase for example, the message still names the old hash.

### Referring to issues

| Written | Means | Covered in |
|---|---|---|
| `#12` | issue 12 on GitHub and GitLab; to Git, text. At the start of a line typed in the editor, a comment, which is removed | Chapter 12 |
| `Fixes #12`, `Closes #12` | on GitHub and GitLab, close issue 12 when the commit reaches the default branch | Chapter 50, Chapter 51 |
| `Refs: #12` | a trailer; to Git, nothing more | [Trailers](#trailers) |
| `Fixes: c2b01522325d ("...")` | the Linux kernel's trailer naming the commit that introduced a bug | [Referring to another commit](#referring-to-another-commit) |
| `Closes: <url>`, `Link: <url>` | the Linux kernel's trailers for a bug report, and for a discussion or background | [Trailers in common use](#trailers-in-common-use) |

`Fixes #12` and `Fixes: c2b01522325d` look alike and mean different things. The
first is a phrase that GitHub and GitLab look for anywhere in the message; the
second is a trailer, and to Git only the second is one, because a trailer's key
is followed by its separator, `:`.

## Trailers

### What counts as a trailer

`git interpret-trailers --parse` prints the trailers Git finds in a message, and
nothing else; [git interpret-trailers](#git-interpret-trailers) covers the
command in full.

```console
$ cat ../msgs/plain.txt && git interpret-trailers --parse ../msgs/plain.txt
Fix the farewell

Keep the full stop.

Reviewed-by: Ada Lovelace <ada@example.com>
Refs: #12
Reviewed-by: Ada Lovelace <ada@example.com>
Refs: #12
$ cat ../msgs/mixed.txt && git interpret-trailers --parse ../msgs/mixed.txt
Fix the farewell

Keep the full stop.

Refs: #12
The report has the details,
and a screenshot of the
failing test.
$ tail -n 4 ../msgs/signed.txt && git interpret-trailers --parse ../msgs/signed.txt
Signed-off-by: Bob Brown <bob@example.com>
The report has the details,
and a screenshot of the
failing test.
Signed-off-by: Bob Brown <bob@example.com>
$ tail -n 5 ../msgs/signed5.txt && git interpret-trailers --parse ../msgs/signed5.txt
Signed-off-by: Bob Brown <bob@example.com>
The report has the details,
and a screenshot of the
failing test, which
shows the problem.
$ git -c trailer.refs.key=Refs interpret-trailers --parse ../msgs/mixed.txt
Refs: #12
$ cat ../msgs/noblank.txt && git interpret-trailers --parse ../msgs/noblank.txt
Fix the farewell
Refs: #12
```

Git's documentation gives the rule, and each command shows a part of it. The
trailers are the last paragraph of the message, after a blank line, and the
paragraph counts as trailers in two cases:

| The last paragraph | Counts as trailers | Shown by |
|---|---|---|
| is nothing but trailers | yes | `plain.txt` |
| has other lines too, and no trailer Git writes itself or you configured | no | `mixed.txt` |
| has a trailer Git writes, such as `Signed-off-by`, and at least a quarter of its lines are trailers | yes | `signed.txt`, one line in four |
| has such a trailer, but under a quarter of its lines are trailers | no | `signed5.txt`, one line in five |
| has a key you configured, in `trailer.<key>.key` | as for one Git writes | `mixed.txt` with `trailer.refs.key` |
| is not after a blank line, here because it is part of the subject | no | `noblank.txt` |

When the paragraph counts, only the `Key: value` lines in it are trailers;
`--parse` leaves the others out. Git's documentation adds that the block may
also end just before a line starting with `---`
([Patches and the `---` line](#patches-and-the-line)).

```console
$ cat ../msgs/spaces.txt && git interpret-trailers --parse ../msgs/spaces.txt
Fix the farewell

Keep the full stop.

Refs : #12
Note: the value of a trailer
  can go on to the next line
 Acked-by: Grace Hopper <grace@example.com>
Refs: #12
Note: the value of a trailer can go on to the next line Acked-by: Grace Hopper <grace@example.com>
```

Spaces and tabs between the key and the `:` are allowed, and Git writes the
trailer back without them. A line that starts with a space or a tab continues
the trailer above it, like a folded header in an email, which is how a long
value goes over several lines; `--parse` joins them into one. The same rule
swallowed the `Acked-by` line, which starts with a space by mistake: it became
part of the `Note` trailer. There can be no space inside a key, Git's
documentation says.

### A line that only looks like a trailer

```console
$ git commit -q --allow-empty -s -m 'Fix the link in the README' -m 'The bug report is at' -m 'https://example.com/greet/issues/7' && git log -1 --format=%B
Fix the link in the README

The bug report is at

https://example.com/greet/issues/7
Signed-off-by: Ada Lovelace <ada@example.com>

$ git log -1 --format='%(trailers)'
https://example.com/greet/issues/7
Signed-off-by: Ada Lovelace <ada@example.com>

$ git commit -q --amend --allow-empty -s -m 'Fix the link in the README' -m 'The bug report is at https://example.com/greet/issues/7.' && git log -1 --format=%B
Fix the link in the README

The bug report is at https://example.com/greet/issues/7.

Signed-off-by: Ada Lovelace <ada@example.com>

```

A last paragraph made of a single link is, to Git, one trailer: the key
`https`, the separator `:`, and the value `//example.com/...`. So `-s` took it
for a trailer block and put the sign-off straight under it, and `%(trailers)`
lists the link. A link inside a sentence, as in the second message, leaves the
paragraph as text, and the sign-off gets a paragraph of its own. The same
happens with any last line of the form `word: text`.

### Trailers in common use

| Trailer | Means | Used by |
|---|---|---|
| `Signed-off-by:` | the person certifies the change, as the project defines it; added by `-s` | Git, the Linux kernel, others ([Signing off](#signing-off)) |
| `Reviewed-by:` | the person reviewed the change and is completely satisfied with it; only they may offer it | Git, the kernel (Chapter 52) |
| `Acked-by:` | someone who knows the area, or looks after it, approves of the change | Git, the kernel |
| `Tested-by:` | the person applied the change and found it works | Git, the kernel |
| `Reported-by:` | the person found the bug the change fixes | Git, the kernel |
| `Suggested-by:` | the person had the idea | Git, the kernel |
| `Helped-by:` | the person suggested ideas, but not the change itself | Git |
| `Mentored-by:` | the person helped develop the change in a mentoring programme | Git |
| `Co-authored-by:` | the person wrote the change with the author | Git, GitHub ([Co-authors](#co-authors)) |
| `Co-developed-by:` | the same, in the kernel, where it must be followed by that person's `Signed-off-by:` | the kernel |
| `Fixes:` | the commit whose bug this fixes, as `<12-character hash> ("<subject>")` | the kernel |
| `Link:`, `Closes:` | a discussion or background, and a bug report this closes, as URLs | the kernel |
| `Change-Id:` | ties the versions of one change together on Gerrit | Gerrit (Chapter 52) |
| `BREAKING CHANGE:` | the change breaks compatibility | Conventional Commits ([Conventional Commits and Git's trailers](#conventional-commits-and-git-s-trailers)) |

The meanings are from `SubmittingPatches` for Git, from the kernel's
documentation on submitting patches, from GitHub's documentation on commits
with several authors, from Gerrit's on `Change-Id`, and from the Conventional
Commits specification. `SubmittingPatches` also asks for only the first letter
of a key to be capital: `Signed-off-by`, not `Signed-Off-By`. It allows new
trailers where needed, but asks for the common ones first.

To Git, only `Signed-off-by` and `(cherry picked from commit ...)` are its own,
the lines it writes itself; every other key is just a key.

### Signing off

```console
$ git commit -q --allow-empty -s -m 'Signed off by Bob' && git log -1 --format=%B
Signed off by Bob

Signed-off-by: Bob Brown <bob@example.com>

$ git commit -q --amend --allow-empty --no-edit -s && git log -1 --format=%B
Signed off by Bob

Signed-off-by: Bob Brown <bob@example.com>
Signed-off-by: Ada Lovelace <ada@example.com>

$ git commit -q --amend --allow-empty --no-edit -s && git log -1 --format=%B
Signed off by Bob

Signed-off-by: Bob Brown <bob@example.com>
Signed-off-by: Ada Lovelace <ada@example.com>

$ git commit -q --amend --allow-empty --no-edit --trailer 'Reviewed-by: Grace Hopper <grace@example.com>' && git commit -q --amend --allow-empty --no-edit -s && git log -1 --format=%B
Signed off by Bob

Signed-off-by: Bob Brown <bob@example.com>
Signed-off-by: Ada Lovelace <ada@example.com>
Reviewed-by: Grace Hopper <grace@example.com>
Signed-off-by: Ada Lovelace <ada@example.com>

```

Bob committed and signed off; Ada then amended the commit, in her own clone,
with `-s` three times. `-s` signs off as the committer, so it added Ada under
Bob. The second time it added nothing, because the last trailer was already
Ada's sign-off. The third time Grace's review stood last, so Ada's sign-off was
added again. That is the rule in Git's source, `sequencer.c`: the sign-off is
added unless it is already the last trailer.

What a sign-off means is up to the project, Git's documentation says. In Git's
own project and in the Linux kernel it certifies the Developer's Certificate of
Origin, which `SubmittingPatches` prints in full. In short, by signing off you
certify that you wrote the change, or that it is based on work under a
compatible open-source licence, or that it came to you from someone who
certified one of those and you did not change it; and that you understand the
contribution, and the sign-off with your name, are public and kept for good.
Git's project accepts no change without it. A chain of sign-offs is a record of
who passed the change on: `SubmittingPatches` encourages anyone forwarding
someone else's patch to add their own.

| Command | Signs off with |
|---|---|
| `git commit` | `-s`, `--signoff`; `--no-signoff` cancels an earlier `-s` (Chapter 12) |
| `git commit --amend` | the same (Chapter 29) |
| `git merge` | `--signoff` (Chapter 25) |
| `git cherry-pick`, `git revert` | `-s` (Chapter 32, Chapter 31) |
| `git rebase` | `--signoff`, for every commit it replays (Chapter 33) |
| `git am` | `-s`, for every patch it applies (Chapter 61) |
| `git format-patch` | `-s`, in the patches only, not in your commits (Chapter 61) |

There is no setting to sign off every commit, and there will not be: Git's
`gitfaq` says so, to protect the legal weight of a sign-off, which an automatic
one could be argued to lack. It calls the one setting that exists,
`format.signOff` for `git format-patch`, a historical mistake.

> **Careful.** `-s` and `-S` are different options. `-s` adds a
> `Signed-off-by:` line, which anyone can type and which proves nothing by
> itself. `-S` signs the commit cryptographically with your key, which can be
> checked (Chapter 68). Git's own project asks for the first and not the second:
> `SubmittingPatches` tells contributors not to sign their patches with PGP.

### Co-authors

A commit has one author. GitHub's documentation credits the others with a
trailer, one per person, after a blank line:

```
Co-authored-by: NAME <NAME@EXAMPLE.COM>
```

It says that for GitHub to count the commit as their contribution, the address
must be one associated with the person's GitHub account, or the private
`no-reply` address GitHub gives them. `SubmittingPatches` uses the same
trailer, for people who exchanged drafts of a patch; the kernel uses
`Co-developed-by:`, followed each time by that person's `Signed-off-by:`, since
it denotes authorship. `git shortlog --group=trailer:co-authored-by` counts
commits by co-author (Chapter 22).

### Adding trailers with other commands

```console
$ git tag -a v1.0 -m 'greet 1.0' --trailer 'Reviewed-by: Bob Brown <bob@example.com>' && git cat-file -p v1.0
object 71472d59557db5c9eecbc26b7f8acaf33a1d6468
type commit
tag v1.0
tagger Ada Lovelace <ada@example.com> 1767625200 +0000

greet 1.0

Reviewed-by: Bob Brown <bob@example.com>
```

An annotated tag's message (Chapter 47) takes trailers too, and
`git cat-file -p` shows where they went: into the tag object's message.

| Command | Adds a trailer with | Covered in |
|---|---|---|
| `git commit` | `--trailer '<key>: <value>'`, repeatable | Chapter 12 |
| `git commit --amend` | the same | Chapter 29 |
| `git rebase` | `--trailer`, to every commit it replays | Chapter 33 |
| `git tag` | `--trailer`, for an annotated tag | this section |
| any message, in a file | `git interpret-trailers` | [git interpret-trailers](#git-interpret-trailers) |

All of them go through the same machinery as `git interpret-trailers`, so the
settings in its section apply to them too: a key alias, for example, works in
`git commit --trailer`.

> **Since Git 2.32.** `git commit --trailer`. **Since Git 2.46.**
> `git tag --trailer`. **Since Git 2.54.** `git rebase --trailer`.

## git interpret-trailers

`git interpret-trailers` reads a message, from files or from standard input,
and prints it with trailers added, changed or picked out. It never touches a
commit: to change a commit's trailers, use one of the commands above.

### Synopsis

From Git's documentation:

```
git interpret-trailers [--in-place] [--trim-empty]
                       [(--trailer (<key>|<key-alias>)[(=|:)<value>])...]
                       [--parse] [<file>...]
```

| Part | Means |
|---|---|
| `<file>...` | messages to read; with none, standard input |
| `--trailer <key>:<value>` | a trailer to add; `=` works as well as `:`, and Git writes `: ` |
| `<key-alias>` | a short name configured for a key ([Keys of your own](#keys-of-your-own)) |
| `--parse` | print the trailers found, and nothing else |

The result goes to standard output, one message after another, unless
`--in-place` is given.

### Options at a glance

| Option | Does | Covered in |
|---|---|---|
| `--trailer <key>[(=\|:)<value>]` | Add a trailer; repeatable | [Adding a trailer](#adding-a-trailer) |
| `--no-trailer` | Forget the `--trailer` options given so far | [When the key is missing](#when-the-key-is-missing) |
| `--in-place` | Write the result back into the file; `--no-in-place` is the default | [Adding a trailer](#adding-a-trailer) |
| `--where=end` | Put new trailers after all the others; the default | [Where it goes](#where-it-goes) |
| `--where=start` | Put them before all the others | [Where it goes](#where-it-goes) |
| `--where=after` | Put each after the last trailer with the same key | [Where it goes](#where-it-goes) |
| `--where=before` | Put each before the first trailer with the same key | [Where it goes](#where-it-goes) |
| `--no-where` | Go back to the settings for the `--trailer` options that follow | [Where it goes](#where-it-goes) |
| `--if-exists=addIfDifferentNeighbor` | Add unless the same trailer is right where the new one would go; the default | [When the key is already there](#when-the-key-is-already-there) |
| `--if-exists=addIfDifferent` | Add unless the same trailer is anywhere | [When the key is already there](#when-the-key-is-already-there) |
| `--if-exists=add` | Always add | [When the key is already there](#when-the-key-is-already-there) |
| `--if-exists=replace` | Remove the nearest trailer with that key, then add | [When the key is already there](#when-the-key-is-already-there) |
| `--if-exists=doNothing` | Add nothing if the key is there | [When the key is already there](#when-the-key-is-already-there) |
| `--no-if-exists` | Go back to the settings | [When the key is already there](#when-the-key-is-already-there) |
| `--if-missing=add` | Add a trailer whose key is not there yet; the default | [When the key is missing](#when-the-key-is-missing) |
| `--if-missing=doNothing` | Do not | [When the key is missing](#when-the-key-is-missing) |
| `--no-if-missing` | Go back to the settings | [When the key is missing](#when-the-key-is-missing) |
| `--only-trailers` | Print only the trailers | [Reading the trailers](#reading-the-trailers) |
| `--unfold` | Join a value folded over several lines | [Reading the trailers](#reading-the-trailers) |
| `--parse` | The same as `--only-trailers --only-input --unfold` | [What counts as a trailer](#what-counts-as-a-trailer) |
| `--only-input` | Add nothing, neither from `--trailer` nor from the settings | [Values from a command](#values-from-a-command) |
| `--trim-empty` | Remove every trailer whose value is empty, old or new | [Reading the trailers](#reading-the-trailers) |
| `--no-divider` | Do not treat a line starting with `---` as the end of the message | [Patches and the `---` line](#patches-and-the-line) |

`--where`, `--if-exists` and `--if-missing` apply to every `--trailer` after
them, until the same option is given again or cancelled with its `--no-` form,
as Git's documentation says and [Where it goes](#where-it-goes) shows. Each
option also has a setting, used when the option is not given
([The settings](#the-settings)). The `--parse` equivalence is Git's
documentation's, which adds that there is no single option to undo it.

### Adding a trailer

```console
$ git interpret-trailers --trailer 'Reviewed-by: Ada Lovelace <ada@example.com>' --trailer 'Refs=#12' ../msgs/bare.txt
Fix the farewell

Keep the full stop.

Reviewed-by: Ada Lovelace <ada@example.com>
Refs: #12
$ git interpret-trailers --trailer 'Refs: #12' < ../msgs/bare.txt
Fix the farewell

Keep the full stop.

Refs: #12
$ git interpret-trailers --in-place --trailer 'Refs: #12' ../msgs/edit.txt && cat ../msgs/edit.txt
Fix the farewell

Keep the full stop.

Refs: #12
```

A message with no trailers gets a blank line and then the new ones, in the
order given. `Refs=#12` became `Refs: #12`. The file is only read, unless
`--in-place` writes the result back into it; the file `edit.txt` started as a
copy of `bare.txt`.

### Where it goes

`three.txt` ends with `Reviewed-by`, `Acked-by` and `Refs` trailers:

```console
$ git interpret-trailers --only-trailers --where=end --trailer 'Acked-by: Bob Brown <bob@example.com>' ../msgs/three.txt
Reviewed-by: Ada Lovelace <ada@example.com>
Acked-by: Grace Hopper <grace@example.com>
Refs: #9
Acked-by: Bob Brown <bob@example.com>
$ git interpret-trailers --only-trailers --where=start --trailer 'Acked-by: Bob Brown <bob@example.com>' ../msgs/three.txt
Acked-by: Bob Brown <bob@example.com>
Reviewed-by: Ada Lovelace <ada@example.com>
Acked-by: Grace Hopper <grace@example.com>
Refs: #9
$ git interpret-trailers --only-trailers --where=after --trailer 'Acked-by: Bob Brown <bob@example.com>' ../msgs/three.txt
Reviewed-by: Ada Lovelace <ada@example.com>
Acked-by: Grace Hopper <grace@example.com>
Acked-by: Bob Brown <bob@example.com>
Refs: #9
$ git interpret-trailers --only-trailers --where=before --trailer 'Acked-by: Bob Brown <bob@example.com>' ../msgs/three.txt
Reviewed-by: Ada Lovelace <ada@example.com>
Acked-by: Bob Brown <bob@example.com>
Acked-by: Grace Hopper <grace@example.com>
Refs: #9
$ git interpret-trailers --only-trailers --trailer 'Tested-by: Bob' --where=start --trailer 'Tested-by: Carol' --trailer 'Tested-by: Dan' --no-where --trailer 'Tested-by: Eve' ../msgs/three.txt
Tested-by: Dan
Tested-by: Carol
Reviewed-by: Ada Lovelace <ada@example.com>
Acked-by: Grace Hopper <grace@example.com>
Refs: #9
Tested-by: Bob
Tested-by: Eve
```

`--only-trailers` prints only the trailers, to keep the output short. `after`
and `before` place the new trailer beside the others with its key, here
`Acked-by`. In the second command, `Bob` came before any `--where` and went to
the end; `--where=start` then applied to both `Carol` and `Dan`, each going to
the start in turn, so `Dan` ended up first; and `--no-where` returned `Eve` to
the default.

### When the key is already there

```console
$ git interpret-trailers --only-trailers --trailer 'Refs: #9' ../msgs/three.txt && git interpret-trailers --only-trailers --trailer 'Acked-by: Grace Hopper <grace@example.com>' ../msgs/three.txt
Reviewed-by: Ada Lovelace <ada@example.com>
Acked-by: Grace Hopper <grace@example.com>
Refs: #9
Reviewed-by: Ada Lovelace <ada@example.com>
Acked-by: Grace Hopper <grace@example.com>
Refs: #9
Acked-by: Grace Hopper <grace@example.com>
```

By default, `addIfDifferentNeighbor`, a trailer is added unless the same key
and value sit right beside where it would go. `Refs: #9` would have gone
directly under the existing `Refs: #9`, so it was not added. Grace's `Acked-by`
would go under `Refs`, a different trailer, so it was added again, a second copy
two lines below the first.

```console
$ git interpret-trailers --only-trailers --if-exists=addIfDifferentNeighbor --trailer 'Refs: #9' --trailer 'Refs: #10' ../msgs/three.txt
Reviewed-by: Ada Lovelace <ada@example.com>
Acked-by: Grace Hopper <grace@example.com>
Refs: #9
Refs: #10
$ git interpret-trailers --only-trailers --if-exists=addIfDifferent --trailer 'Refs: #9' --trailer 'Refs: #10' ../msgs/three.txt
Reviewed-by: Ada Lovelace <ada@example.com>
Acked-by: Grace Hopper <grace@example.com>
Refs: #9
Refs: #10
$ git interpret-trailers --only-trailers --if-exists=add --trailer 'Refs: #9' --trailer 'Refs: #10' ../msgs/three.txt
Reviewed-by: Ada Lovelace <ada@example.com>
Acked-by: Grace Hopper <grace@example.com>
Refs: #9
Refs: #9
Refs: #10
$ git interpret-trailers --only-trailers --if-exists=replace --trailer 'Refs: #9' --trailer 'Refs: #10' ../msgs/three.txt
Reviewed-by: Ada Lovelace <ada@example.com>
Acked-by: Grace Hopper <grace@example.com>
Refs: #10
$ git interpret-trailers --only-trailers --if-exists=doNothing --trailer 'Refs: #9' --trailer 'Refs: #10' ../msgs/three.txt
Reviewed-by: Ada Lovelace <ada@example.com>
Acked-by: Grace Hopper <grace@example.com>
Refs: #9
$ git -c trailer.ifexists=doNothing interpret-trailers --only-trailers --if-exists=add --trailer 'Refs: #10' --no-if-exists --trailer 'Refs: #11' ../msgs/three.txt
Reviewed-by: Ada Lovelace <ada@example.com>
Acked-by: Grace Hopper <grace@example.com>
Refs: #9
Refs: #10
```

Each run tries to add `Refs: #9`, which is there already, and `Refs: #10`,
which is not.

| Value of `--if-exists` | `Refs: #9`, already there | `Refs: #10`, a new value for the key |
|---|---|---|
| `--if-exists=addIfDifferentNeighbor` | not added: it would go right under the one there | added |
| `--if-exists=addIfDifferent` | not added | added |
| `--if-exists=add` | added | added |
| `--if-exists=replace` | replaces the old one | replaces the nearest trailer with the key, here the one `#9` had just replaced |
| `--if-exists=doNothing` | not added | not added: the key is there |

The last command sets the default to `doNothing` with the setting
`trailer.ifexists`; `--if-exists=add` overrode it for `#10`, and
`--no-if-exists` went back to the setting for `#11`, which was not added.

### When the key is missing

```console
$ git interpret-trailers --if-missing=add --trailer 'Refs: #12' ../msgs/bare.txt
Fix the farewell

Keep the full stop.

Refs: #12
$ git interpret-trailers --if-missing=doNothing --trailer 'Refs: #12' ../msgs/bare.txt
Fix the farewell

Keep the full stop.

$ git interpret-trailers --only-trailers --if-missing=doNothing --trailer 'Tested-by: Bob' --no-if-missing --trailer 'Tested-by: Carol' ../msgs/three.txt
Reviewed-by: Ada Lovelace <ada@example.com>
Acked-by: Grace Hopper <grace@example.com>
Refs: #9
Tested-by: Carol
$ git interpret-trailers --only-trailers --trailer 'Refs: #12' --no-trailer --trailer 'Tested-by: Bob' ../msgs/three.txt
Reviewed-by: Ada Lovelace <ada@example.com>
Acked-by: Grace Hopper <grace@example.com>
Refs: #9
Tested-by: Bob
```

`--if-missing=add`, the default, adds a trailer whose key the message does not
have yet. `--if-missing=doNothing` adds it only when the message already has
one with that key, where `--if-exists` then decides; with no `Refs` in
`bare.txt`, nothing was added. It suits a key you want to update but never introduce. In
the second command `--no-if-missing` restored the default, `add`, so `Carol`
was added and `Bob` was not. `--no-trailer` is different: it forgets the
trailers given before it, so only `Tested-by: Bob` was added in the third.

### Reading the trailers

```console
$ git interpret-trailers --only-trailers ../msgs/spaces.txt
Refs: #12
Note: the value of a trailer
  can go on to the next line
 Acked-by: Grace Hopper <grace@example.com>
$ git interpret-trailers --only-trailers --unfold ../msgs/spaces.txt
Refs: #12
Note: the value of a trailer can go on to the next line Acked-by: Grace Hopper <grace@example.com>
$ cat ../msgs/empty.txt && git interpret-trailers --trim-empty ../msgs/empty.txt
Fix the farewell

Keep the full stop.

Fixes: 
Cc: 
Reviewed-by: Ada Lovelace <ada@example.com>
Fix the farewell

Keep the full stop.

Reviewed-by: Ada Lovelace <ada@example.com>
```

`--only-trailers` prints the trailers as they are written, apart from the space
before `:` in `Refs`; `--unfold` joins each folded value into one line;
`--parse` is both, and leaves out lines of the block that are not trailers.

`--trim-empty` removes trailers with nothing after the separator. Git's
documentation pairs it with a commit template (Chapter 12) that lists empty
trailers such as `Fixes:` and `Cc:` for the writer to fill in, and a
`commit-msg` hook that runs `git interpret-trailers --trim-empty` on the
message, so that whichever were left empty disappear (Chapter 67 covers
hooks).

### Keys of your own

```console
$ git -c trailer.ack.key=Acked-by interpret-trailers --only-trailers --trailer 'ack: Bob Brown <bob@example.com>' ../msgs/three.txt
Reviewed-by: Ada Lovelace <ada@example.com>
Acked-by: Grace Hopper <grace@example.com>
Refs: #9
Acked-by: Bob Brown <bob@example.com>
$ git -c trailer.ack.key=Acked-by -c trailer.ack.where=after -c trailer.ack.ifexists=addIfDifferent interpret-trailers --only-trailers --trailer 'ack: Bob Brown <bob@example.com>' --trailer 'ack: Grace Hopper <grace@example.com>' ../msgs/three.txt
Reviewed-by: Ada Lovelace <ada@example.com>
Acked-by: Grace Hopper <grace@example.com>
Acked-by: Bob Brown <bob@example.com>
Refs: #9
$ git -c trailer.separators=':#' interpret-trailers --parse ../msgs/hash.txt
Refs: 12
$ git -c trailer.separators=':#' -c 'trailer.fix.key=Fix #' interpret-trailers --trailer fix=42 ../msgs/bare.txt
Fix the farewell

Keep the full stop.

Fix #42
```

`trailer.<alias>.key` names a key for a short alias, which Git's documentation
says must be the start of the key, in any case: `ack` for `Acked-by`. The
alias's own `where`, `ifexists` and `ifmissing` settings then apply to it
alone, overriding the general ones: here Bob's acknowledgement went after
Grace's, and a second copy of Grace's was not added. Configuring a key also
makes it count as a trailer Git knows, as the `mixed.txt` example of
[What counts as a trailer](#what-counts-as-a-trailer) showed.

`trailer.separators` lists the characters that may separate a key from its
value; only `:` by default, and `=` always on the command line. With `#` added,
`Refs #12` is a trailer, read as the key `Refs` and the value `12`: the `#` is
taken as the separator and gone. Git's documentation shows the other use, a key
that ends in its own separator, `Fix #`, so that the trailer is written as
`Fix #42`.

### Values from a command

`git config` has `user.name` and `user.email` set in this repository, for the
commands below to read.

```console
$ git -c trailer.see.key=See-also -c 'trailer.see.cmd=git show -s --pretty=reference' interpret-trailers --only-trailers --trailer see=HEAD~1 ../msgs/three.txt
Reviewed-by: Ada Lovelace <ada@example.com>
Acked-by: Grace Hopper <grace@example.com>
Refs: #9
See-also: c488410 (Explain in the README how to run the tests and what they print, 2026-01-05)
$ git -c trailer.sign.key=Signed-off-by -c 'trailer.sign.cmd=echo "$(git config user.name) <$(git config user.email)>"' interpret-trailers --only-trailers ../msgs/three.txt
Reviewed-by: Ada Lovelace <ada@example.com>
Acked-by: Grace Hopper <grace@example.com>
Refs: #9
$ git -c trailer.sign.key=Signed-off-by -c 'trailer.sign.cmd=echo "$(git config user.name) <$(git config user.email)>"' interpret-trailers --only-trailers --trailer sign ../msgs/three.txt
Reviewed-by: Ada Lovelace <ada@example.com>
Acked-by: Grace Hopper <grace@example.com>
Refs: #9
Signed-off-by: Ada Lovelace <ada@example.com>
```

`trailer.<alias>.cmd` is a shell command whose output becomes the value. The
value given with `--trailer`, `HEAD~1` in the first command, is passed to it as
an argument, so the command run was `git show -s --pretty=reference HEAD~1`.

Git's documentation says the command is also called once to add a trailer by
itself, but in Git 2.55 it is not: the second command added nothing. The
source, `trailer.c`, adds a trailer from the settings alone only for the older
setting `trailer.<alias>.command`. With `.cmd`, name the alias with
`--trailer`, as in the third command, where `sign` with no value ran the
command.

```console
$ git -c trailer.sign.key=Signed-off-by -c 'trailer.sign.cmd=git var GIT_COMMITTER_IDENT | sed "s/>.*/>/"' interpret-trailers --only-trailers --trailer sign ../msgs/three.txt
sed: can't read : No such file or directory
error: running trailer command 'git var GIT_COMMITTER_IDENT | sed "s/>.*/>/"' failed
Reviewed-by: Ada Lovelace <ada@example.com>
Acked-by: Grace Hopper <grace@example.com>
Refs: #9
Signed-off-by: 
```

The value is passed even when it is empty, and it goes to the last program of
the command: here `sed` received an empty file name. The first line is `sed`'s
own complaint and the second Git's, both on standard error; the trailers,
printed afterwards, include one with no value. A command that is a pipeline
has to cope with that argument. In the working command above it went to
`echo`, which printed it as a trailing space, and Git trims spaces from the
ends of a value.

```console
$ git -c trailer.sign.key=Signed-off-by -c 'trailer.sign.command=echo "$(git config user.name) <$(git config user.email)>"' interpret-trailers --only-trailers ../msgs/three.txt
Reviewed-by: Ada Lovelace <ada@example.com>
Acked-by: Grace Hopper <grace@example.com>
Refs: #9
Signed-off-by: Ada Lovelace <ada@example.com>
$ git -c trailer.sign.key=Signed-off-by -c 'trailer.sign.command=echo "$(git config user.name) <$(git config user.email)>"' interpret-trailers --only-trailers --only-input ../msgs/three.txt
Reviewed-by: Ada Lovelace <ada@example.com>
Acked-by: Grace Hopper <grace@example.com>
Refs: #9
```

`trailer.<alias>.command`, which Git's documentation calls deprecated in favour
of `.cmd`, does add its trailer to every message it processes, with no
`--trailer`. The documentation says it passes no argument: the first `$ARG` in
the command is replaced by the value instead, which it calls unsafe.
`--only-input` stops everything being added, from the settings and from
`--trailer` alike.

> **Since Git 2.32.** `trailer.<alias>.cmd`.

### Patches and the `---` line

```console
$ git format-patch -q -1 -o out && git interpret-trailers --trailer 'Tested-by: Bob Brown <bob@example.com>' out/0001-*.patch
From 71472d59557db5c9eecbc26b7f8acaf33a1d6468 Mon Sep 17 00:00:00 2001
From: Ada Lovelace <ada@example.com>
Date: Mon, 5 Jan 2026 14:00:00 +0000
Subject: [PATCH] Say what the tests print

The README said how to run the tests but not what a successful run looks like, which left a new contributor unsure whether the silence meant success.

Tested-by: Bob Brown <bob@example.com>
---
 README.md | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/README.md b/README.md
index f129440..314721d 100644
--- a/README.md
+++ b/README.md
@@ -2,4 +2,4 @@
 
 Shell functions that greet people.
 
-Run the tests with sh test.sh.
+Run the tests with sh test.sh; it prints all tests passed.
...
```

A patch made by `git format-patch` has the message, a line `---`, and then the
patch. `git interpret-trailers` treats the `---` line as the end of the message,
so the trailer went at the end of the message and the patch was left as it
was; this is how a reviewer's `Tested-by:` gets into a patch before it is
applied with `git am` (Chapter 61). The patch ends with a signature, a line
`-- ` and Git's version, cut here.

```console
$ cat ../msgs/dashes.txt && git interpret-trailers --trailer 'Refs: #12' ../msgs/dashes.txt
Update the README

Add a section on the tests, which reads:
---
Run the tests with sh test.sh.
Update the README

Add a section on the tests, which reads:

Refs: #12
---
Run the tests with sh test.sh.
$ git interpret-trailers --no-divider --trailer 'Refs: #12' ../msgs/dashes.txt
Update the README

Add a section on the tests, which reads:
---
Run the tests with sh test.sh.

Refs: #12
```

A message that merely contains such a line is cut there too. `--no-divider`
reads the whole input as the message, and Git's documentation says to use it
when you know the input is a message and not a patch. `git commit --trailer`
passes it itself: Git 2.42's release notes record the fix that made it do so.

## Conventional Commits

### The format

Conventional Commits is a specification for messages, version 1.0.0, at
conventionalcommits.org, read in September 2026. It adds a structure on top of
Git's:

| Part | Written | Required |
|---|---|---|
| type | a noun at the start of the subject: `feat` for a new feature, `fix` for a bug fix, or another, such as `docs` | yes |
| scope | in brackets after the type, naming the part of the code: `fix(test)` | no |
| `!` | before the colon, for a change that breaks compatibility: `feat!:`, `feat(greet)!:` | no |
| `: ` and a description | a short summary: `fix(test): report which test failed` | yes |
| body | after a blank line, free text | no |
| footers | after a blank line, `Token: value`, or `Token #value`; a token has `-` for spaces, such as `Acked-by`, except `BREAKING CHANGE` | no |
| `BREAKING CHANGE: <description>` | a footer that marks a breaking change, in capitals; `BREAKING-CHANGE` means the same | no |

The specification links the types to Semantic Versioning (Chapter 48): `fix`
means a patch release, `feat` a minor release, and a breaking change, marked
either way, a major release. It names further types, `build`, `chore`, `ci`,
`docs`, `style`, `refactor`, `perf` and `test`, from the convention of the
Angular project, as examples rather than rules. Apart from `BREAKING CHANGE`,
which must be in capitals, it says none of it is case-sensitive.

### Reading a history by type

Since the tag `v1.0`, the project's messages follow the convention:

```console
$ git log --oneline v1.0..
371d938 fix: keep the full stop in the farewell
45633ca feat: greet in capitals on request
e220012 feat(greet)!: take the name from GREET_NAME
28fa25a docs: explain how to run the tests
7a4e619 fix(test): report which test failed
a439d4f feat: add a farewell
$ git log --format='- %s' -E --grep='^feat(\(.*\))?!?: ' v1.0..
- feat: greet in capitals on request
- feat(greet)!: take the name from GREET_NAME
- feat: add a farewell
$ git log --format='- %s' -E --grep='^fix(\(.*\))?!?: ' v1.0..
- fix: keep the full stop in the farewell
- fix(test): report which test failed
$ git log --oneline -E --grep='^[a-z]+(\(.*\))?!: ' --grep='^BREAKING[ -]CHANGE: ' v1.0..
45633ca feat: greet in capitals on request
e220012 feat(greet)!: take the name from GREET_NAME
```

`--grep` matches any line of a message, and `^` the start of a line
(Chapter 17); `-E` allows `(...)`, `?` and `+`. The pattern
`^feat(\(.*\))?!?: ` is `feat`, an optional scope in brackets, an optional `!`,
then `: `. Two `--grep` options match either, so the last command finds both
kinds of breaking change: the `!` in `e220012`'s subject, and the
`BREAKING CHANGE:` line in the body of `45633ca`. These are the lists release
notes are made from (Chapter 48), and with a breaking change among them the
next release is a major one.

### Conventional Commits and Git's trailers

```console
$ cat ../msgs/breaking.txt && git interpret-trailers --parse ../msgs/breaking.txt
feat: say goodbye

BREAKING CHANGE: bye now needs a name
Refs: #12
$ cat ../msgs/breaking2.txt && git interpret-trailers --parse ../msgs/breaking2.txt
feat: say goodbye

BREAKING-CHANGE: bye now needs a name
Refs: #12
BREAKING-CHANGE: bye now needs a name
Refs: #12
$ cat ../msgs/hash.txt && git interpret-trailers --parse ../msgs/hash.txt
fix: keep the full stop

Refs #12
```

The specification calls its footers inspired by Git's trailers, and most of
them are trailers. Two of its forms are not. `BREAKING CHANGE` has a space in
its key, which a trailer cannot have, so the line is text; and a paragraph with
text in it and no trailer Git knows is not a trailer block at all, so `Refs`
was lost with it. `BREAKING-CHANGE`, which the specification allows as a
synonym, is a trailer, and so is everything beside it. `Refs #12`, with the
footer separator ` #`, is not a trailer unless `trailer.separators` includes
`#`, and then it reads as `Refs: 12` ([Keys of your own](#keys-of-your-own)).
To `git log --grep` and to tools that read the text, all of them work; to
`%(trailers)`, `git interpret-trailers` and `git shortlog --group=trailer:`,
only the hyphenated form does.

## Messages Git writes itself

| Command | Writes | Covered in |
|---|---|---|
| `git merge` | `Merge branch '<branch>'`, with more when the target is not the default branch or the branch came from elsewhere | Chapter 25 |
| `git pull` | `Merge branch '<branch>' of <url>` | Chapter 42 |
| `git merge --squash` | `Squashed commit of the following:`, then each commit | Chapter 25 |
| `git revert` | `Revert "<subject>"` and `This reverts commit <hash>.`; reverting that gives `Reapply "<subject>"` | Chapter 31 |
| `git cherry-pick -x` | `(cherry picked from commit <hash>)` at the end | Chapter 32 |
| `git commit --fixup`, `--squash` | `fixup! <subject>`, `amend! <subject>`, `squash! <subject>` | Chapter 35 |
| `-s` on any command | `Signed-off-by: <committer>` | [Signing off](#signing-off) |

Git's documentation for `git revert` strongly recommends saying in the message
why the commit is being reverted, and rewording the subjects of reverted
reverts, which otherwise grow into `Reapply "Reapply "<subject>""`.

## Enforcing a convention

A convention nobody checks drifts. A commit template reminds (Chapter 12); a
`commit-msg` hook, which runs after the message is written and can refuse it,
enforces. This one checks the Conventional Commits type and the length of the
subject:

```console
$ cat .git/hooks/commit-msg
#!/bin/sh
subject=$(head -n 1 "$1")
if ! echo "$subject" | grep -qE '^(feat|fix|docs|test|refactor|chore)(\([a-z]+\))?!?: '
then
	echo "commit-msg: start the subject with a type, such as 'fix: '" >&2
	exit 1
fi
if test ${#subject} -gt 50
then
	echo "commit-msg: the subject has ${#subject} characters; keep it to 50" >&2
	exit 1
fi
$ git commit -q --allow-empty -m 'Tidy the tests'; echo "exit $?"
commit-msg: start the subject with a type, such as 'fix: '
exit 1
$ git commit -q --allow-empty -m 'test: run the greeting and the farewell tests together'; echo "exit $?"
commit-msg: the subject has 54 characters; keep it to 50
exit 1
$ git commit -q --allow-empty -m 'test: run both tests together' && git log --oneline -1
531f765 test: run both tests together
```

The hook gets the name of the file holding the message as `$1`, and a non-zero
exit refuses the commit; Chapter 12 shows that the refused message is kept in
`.git/COMMIT_EDITMSG`. `${#subject}` is the length of the variable, in
characters. Such a hook helps whoever installs it, but it enforces nothing:
`git commit --no-verify` skips it. Git's `gitfaq` says the only safe place to
enforce a policy is the server, in a `pre-receive` hook or in continuous
integration, which is what GitLab's push rules do (Chapter 51); Chapter 67
covers the hooks.

## Changing a message afterwards

| The commit is | Change the message with | Covered in |
|---|---|---|
| the last one, not yet shared | `git commit --amend` | Chapter 29 |
| an older one, not yet shared | `git history reword <commit>`, or `reword` in `git rebase -i` | Chapter 35, Chapter 34 |
| shared already | leave it; add what you learned as a note | Chapter 38 |
| shared, and wrong about what it does | a new commit, or a revert, that says so | Chapter 31 |

A message is part of the commit, so changing it gives the commit a new hash,
and every commit after it too: the rule of Chapter 28 applies.

## Conventions compared

| Compared on | Git's own project | The Linux kernel | Conventional Commits |
|---|---|---|---|
| Subject | `area: summary`, small letter after the colon, no full stop | `subsystem: summary phrase` | `type(scope): description` |
| Subject length | 50 characters, a soft limit | 70 to 75 characters for the summary | not specified |
| Mood | imperative | imperative | not specified |
| Body | why: the problem, the solution, the alternatives | the problem and the change, wrapped at 75 columns | free text |
| Line width | 72 columns, in `MyFirstContribution`'s example | 75 columns | not specified |
| Naming another commit | `abbreviated-hash (subject, date)` in the text | `Fixes: <12-character hash> ("subject")` trailer | not specified |
| Sign-off | `Signed-off-by:`, required | `Signed-off-by:` | not specified |
| Co-authors | `Co-authored-by:` | `Co-developed-by:` and the co-author's `Signed-off-by:` | not specified |
| Breaking changes | not specified | not specified | `!` or a `BREAKING CHANGE:` footer |
| Source | `SubmittingPatches`, `MyFirstContribution`, installed with Git | the kernel's documentation on submitting patches | conventionalcommits.org, version 1.0.0 |

The sources were read in September 2026; Git's are the ones installed with
Git 2.55.

## Messages and their neighbours

| To record | Use | Changes the commit | Covered in |
|---|---|---|---|
| what a commit does and why | its message | it is the commit | this chapter |
| structured facts known when committing: who reviewed, which issue | trailers in the message | it is the commit | [Trailers](#trailers) |
| something learned after the commit was shared | a note | no | Chapter 38 |
| what a release contains | an annotated tag's message | no; a tag is its own object | Chapter 47 |
| the case for a whole pull request, and its discussion | the pull request's description, on the hosting service | no; Git never sees it | Chapter 50 |

A pull request's description is not in the repository unless something copies
it there: GitHub's merge commit takes the pull request's number and title, and a
squash commit, by default, its title when it has several commits (Chapter 50).
What should outlive the hosting service belongs in the messages.

## The settings

| Setting | Does | Covered in |
|---|---|---|
| `commit.template` | A file to start every message from | Chapter 12 |
| `commit.cleanup` | How the message is tidied: comments, blank lines, whitespace | Chapter 12 |
| `core.commentChar`, `core.commentString` | What starts a comment line in the editor | Chapter 12 |
| `trailer.separators` | The characters that may separate key and value | [Keys of your own](#keys-of-your-own) |
| `trailer.where`, `trailer.ifexists`, `trailer.ifmissing` | Defaults for `--where`, `--if-exists` and `--if-missing` | [When the key is already there](#when-the-key-is-already-there) |
| `trailer.<alias>.key` | The key for an alias, which also makes the key known | [Keys of your own](#keys-of-your-own) |
| `trailer.<alias>.where`, `.ifexists`, `.ifmissing` | The same defaults, for one key | [Keys of your own](#keys-of-your-own) |
| `trailer.<alias>.cmd` | A command whose output is the value | [Values from a command](#values-from-a-command) |
| `trailer.<alias>.command` | The deprecated form, which adds its trailer every time | [Values from a command](#values-from-a-command) |
| `format.signOff` | Sign off patches made by `git format-patch` | Chapter 61 |
| `core.abbrev` | The length of short hashes, 12 for the kernel's `Fixes:` | Chapter 17 |
| `pretty.<name>` | A named format, such as the kernel's `pretty.fixes` | Chapter 17 |
| `i18n.commitEncoding`, `i18n.logOutputEncoding` | The encoding messages are written and shown in, when not UTF-8 | Chapter 17 |
