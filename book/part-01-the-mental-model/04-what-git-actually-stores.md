# Chapter 4. What Git Actually Stores

## The short answer

Git stores complete snapshots of your files, not the changes between them.

Almost everything that confuses people about Git dissolves once that sentence
is really believed. This chapter makes you believe it by showing you the bytes.

## Following the chain

Here is a repository with one file in it, committed once. A commit is a small
object you can read:

```console
$ git cat-file -p HEAD
tree 1ecfd378024876328025e3d4452e15a1adfa56fd
author Ada Lovelace <ada@example.com> 1767603600 +0000
committer Ada Lovelace <ada@example.com> 1767603600 +0000

Add the poem
```

The commit does not contain the file. It points at a **tree**, which is Git's
word for a directory:

```console
$ git cat-file -p HEAD^{tree}
100644 blob d531a8e56cfd2440190959775e87a1162a38907b	poem.txt
```

The tree does not contain the file either. It points at a **blob**, which is
Git's word for file contents:

```console
$ git cat-file -p HEAD:poem.txt
roses are red
violets are blue
```

Three objects, three levels. The commit knows when and who and why. The tree
knows the names and the layout. The blob knows the bytes and nothing else, not
even its own filename.

```
commit ──▶ tree ──▶ blob
 who        names     bytes
 when       modes
 message    layout
```

You can ask any object what it is and how big it is:

```console
$ git cat-file -t HEAD
commit
$ git cat-file -t HEAD^{tree}
tree
$ git cat-file -t HEAD:poem.txt
blob
$ git cat-file -s HEAD:poem.txt
31
```

| Flag | Prints |
|---|---|
| `-t` | The object's type |
| `-s` | Its size in bytes |
| `-p` | Its contents, formatted for the type |
| `-e` | Nothing; exits 0 if the object exists, non-zero if not |

## The name is the content

An object's name is not assigned. It is computed from the content, and you can
compute it yourself. Git hashes the bytes `blob`, a space, the length in
bytes, a zero byte, and then the content:

```console
$ printf 'roses are red\nviolets are blue\n' | git hash-object --stdin
d531a8e56cfd2440190959775e87a1162a38907b
$ printf 'roses are red\nviolets are blue\n' | wc -c
31
$ printf 'blob 31\0roses are red\nviolets are blue\n' | sha1sum | cut -d' ' -f1
d531a8e56cfd2440190959775e87a1162a38907b
```

The same hash, twice, one of them produced without Git being involved at all.
That is the whole naming scheme. Two files with the same bytes have the same
name, everywhere in the world, in every repository, forever.

> **Worth knowing.** `git hash-object` computes a hash without writing
> anything. Add `-w` and it writes the object into the repository as well,
> which is how Chapter 75 builds a commit by hand.

The header is why you cannot just run `sha1sum` on a file and get its blob
hash. The length prefix is part of what gets hashed.

> **Since Git 2.29.** A repository can use SHA-256 instead, giving
> 64-character names rather than 40. Create one with
> `git init --object-format=sha256`. It is opt-in today and Git 3.0 will make
> it the default for new repositories. The catch, stated plainly in Git's own
> documentation, is that there is still no interoperability between SHA-1 and
> SHA-256 repositories: you cannot push between them. Chapter 71 covers the
> transition.

## Editing one line rewrites the whole file

Change the second line of the poem and commit again. The tree now points at a
different blob:

```console
$ git cat-file -p HEAD^{tree}
100644 blob 075a712659d88c132785b0d4b344927abe86ca58	poem.txt
$ git cat-file -p HEAD~1^{tree}
100644 blob d531a8e56cfd2440190959775e87a1162a38907b	poem.txt
```

And both blobs hold the whole file, not a difference between them:

```console
$ git cat-file -p HEAD:poem.txt
roses are red
violets are violet
$ git cat-file -p HEAD~1:poem.txt
roses are red
violets are blue
$ git cat-file -s HEAD:poem.txt
33
$ git cat-file -s HEAD~1:poem.txt
31
```

Thirty-three bytes and thirty-one bytes. Two complete copies of a nearly
identical file.

This is the opposite of how Subversion, CVS and their generation worked. Those
systems stored an original plus a chain of deltas, and reconstructing an old
version meant replaying the chain. Git stores the versions and computes the
differences on demand. When you run `git diff`, Git is comparing two complete
snapshots right then. It is not reading a stored diff, because there is no
stored diff.

> **Worth knowing.** "But that wastes enormous space" is the correct first
> reaction and the wrong conclusion. Git does compress objects, and it does
> store some of them as deltas against each other. It just does that later, as
> a storage optimisation inside packfiles, and never as part of the data model.
> Chapter 72 covers packfiles. The model you reason about stays snapshots.

## Identical content is stored once

Because the name is the content, deduplication is automatic rather than a
feature anyone had to build. Three files, two of them identical:

```console
$ git cat-file -p HEAD^{tree}
100644 blob c735202fb0d3c35e7fa4675a376d62142f607ef2	a.txt
100644 blob c735202fb0d3c35e7fa4675a376d62142f607ef2	b.txt
100644 blob 001ecae9f972539ba371ac23e9ce04086b7f1d36	c.txt
100644 blob 075a712659d88c132785b0d4b344927abe86ca58	poem.txt
```

`a.txt` and `b.txt` are two names pointing at one object. There is no second
copy on disk.

The same mechanism means an unchanged file costs nothing across commits. Here
the poem is untouched between two commits, so both commits' trees reference the
identical blob:

```console
$ git rev-parse HEAD:a.txt HEAD~1:poem.txt HEAD:poem.txt
c735202fb0d3c35e7fa4675a376d62142f607ef2
075a712659d88c132785b0d4b344927abe86ca58
075a712659d88c132785b0d4b344927abe86ca58
```

A commit in a repository of ten thousand files where you changed one file
creates one new blob, a handful of new trees along the path to it, and one new
commit. The other 9,999 files are references to objects that already exist.

## Trees, nesting, and modes

A directory containing a directory is a tree containing a tree:

```console
$ git cat-file -p HEAD^{tree}
100644 blob c735202fb0d3c35e7fa4675a376d62142f607ef2	a.txt
100644 blob c735202fb0d3c35e7fa4675a376d62142f607ef2	b.txt
100644 blob 001ecae9f972539ba371ac23e9ce04086b7f1d36	c.txt
040000 tree 0c822c78a3896665c88e8b5f1028e6214d1373a8	nested
100644 blob 075a712659d88c132785b0d4b344927abe86ca58	poem.txt
$ git cat-file -p HEAD:nested
040000 tree 4cf9f177c4c015836fca6a31f9c3917e89ae29ec	deep
$ git cat-file -p HEAD:nested/deep
100644 blob ce013625030ba8dba906f756967f9e9ca394464a	file.txt
```

The number at the front of each line is the mode. There are exactly five:

| Mode | Meaning |
|---|---|
| `100644` | An ordinary file |
| `100755` | An executable file |
| `120000` | A symbolic link; the blob holds the link target as text |
| `160000` | A gitlink, naming a commit in another repository. This is a submodule, see Chapter 57 |
| `040000` | A subdirectory, so the entry is a tree |

Git records only whether a file is executable. It does not store read or write
permissions, owners, groups, or timestamps. If your project needs those, it
needs a build step that sets them, not a version control system that carries
them.

The mode lives in the tree, not in the blob, so a file and an executable copy
of the same file share one blob:

```console
100644 blob 587be6b4c3f93f93c489c0111bba5596147a26cb	plain.txt
100755 blob 587be6b4c3f93f93c489c0111bba5596147a26cb	script.sh
```

> **Worth knowing.** The empty tree has a fixed name in every SHA-1 repository
> that has ever existed: `4b825dc642cb6eb9a060e54bf8d69288fbee4904`. You can
> verify it with `git hash-object -t tree /dev/null`. It occasionally shows up
> in scripts as a stand-in for "nothing", for instance to diff a first commit
> against an empty state.

## Git does not store directories

There is no object type for an empty directory, so an empty directory cannot be
committed. Watch a perfectly successful `git add` do nothing at all:

```console
$ git status --short
$ git add empty-dir
$ git status --short
```

No error, no output, no change. Contrast that with a path that does not exist,
which does complain:

```console
$ git add no-such-path
fatal: pathspec 'no-such-path' did not match any files
```

So Git distinguishes "that path is not there" from "that path is there and
contains nothing worth recording", and only the first is an error. The second
is silence, which is a worse way to learn the rule.

The standard workaround is to put a file in the directory. By convention it is
called `.gitkeep`, though nothing in Git knows that name. Any file works; the
name is purely a message to other humans.

| Goal | What to do |
|---|---|
| Keep an empty directory in the repository | Add a placeholder file, conventionally `.gitkeep` |
| Keep the directory but ignore its contents | Add `.gitignore` inside it containing `*` and `!.gitignore` |
| Have the directory created at build time | Create it in your build script, not in Git |

## Renames are not stored either

Rename a file and commit. The blob is untouched:

```console
$ git rev-parse HEAD:c.txt
001ecae9f972539ba371ac23e9ce04086b7f1d36
$ git rev-parse HEAD:renamed.txt
001ecae9f972539ba371ac23e9ce04086b7f1d36
```

Same object, new name. The tree changed, nothing else did:

```console
$ git cat-file -p HEAD^{tree}
100644 blob c735202fb0d3c35e7fa4675a376d62142f607ef2	a.txt
100644 blob c735202fb0d3c35e7fa4675a376d62142f607ef2	b.txt
040000 tree 0c822c78a3896665c88e8b5f1028e6214d1373a8	nested
100644 blob 075a712659d88c132785b0d4b344927abe86ca58	poem.txt
100644 blob 001ecae9f972539ba371ac23e9ce04086b7f1d36	renamed.txt
```

Nothing anywhere records that `c.txt` became `renamed.txt`. There is no rename
field, because a snapshot has no concept of what happened between snapshots.

And yet Git reports the rename:

```console
$ git show --stat --oneline HEAD
27dad27 Rename c.txt
 c.txt => renamed.txt | 0
 1 file changed, 0 insertions(+), 0 deletions(-)
```

That is detection, not retrieval. When comparing two snapshots, Git notices a
file disappeared, notices another appeared with identical or similar content,
and concludes it was probably a rename. It is a heuristic computed at display
time, and it can be wrong.

```console
$ git log --follow --oneline -- renamed.txt
27dad27 Rename c.txt
22a0bf3 Add three files, two of them identical
```

> **Careful.** Rename detection has a similarity threshold. A file that is
> renamed and heavily edited in the same commit may be reported as a delete
> plus an add. Chapter 13 covers `-M` and `--find-renames` and how to change
> the threshold. This matters most when you are hunting through history for
> where a piece of code went.

> **Worth knowing.** `git mv old new` is not a special operation. It is exactly
> `mv old new` followed by `git rm old` and `git add new`, and it produces an
> identical commit. Chapter 15 covers the one case where it is genuinely more
> convenient.

## The whole repository, laid out

A small repository, listed object by object:

```console
$ git count-objects -v
count: 17
size: 1
in-pack: 0
packs: 0
size-pack: 0
prune-packable: 0
garbage: 0
size-garbage: 0
$ git cat-file --batch-all-objects --batch-check='%(objecttype) %(objectsize) %(objectname)' | sort
blob 11 c735202fb0d3c35e7fa4675a376d62142f607ef2
blob 16 001ecae9f972539ba371ac23e9ce04086b7f1d36
blob 31 d531a8e56cfd2440190959775e87a1162a38907b
blob 33 075a712659d88c132785b0d4b344927abe86ca58
blob 6 ce013625030ba8dba906f756967f9e9ca394464a
commit 173 ea0ec17ac1de394f9338b47bc258dcbde5dfddfc
commit 221 27dad275666a1426d7b3fbcea3bc4ccc9f0e5935
commit 226 35e0ddca1bf76e6c6f556b49528a31be2b504849
commit 228 a04d563699b58ce718bb5047acba26fbcc8ae389
commit 247 22a0bf37dbea0f06a3b6b6425da5ecb637b6043b
tree 135 1959ab6db7a06e52d74d939aea7c0b5ab58b43b4
tree 168 756c5fa8af5a53512374a896ed91ddf7ceee8ff1
tree 174 302eb56bdace0df031ccfa80241bc82094da0e55
tree 31 0c822c78a3896665c88e8b5f1028e6214d1373a8
tree 36 1ecfd378024876328025e3d4452e15a1adfa56fd
tree 36 4cf9f177c4c015836fca6a31f9c3917e89ae29ec
tree 36 af0cb546cd4de68a7a54047a825c57d9905f6880
```

Five commits, seven trees, five blobs. Five blobs for a history that touched
six named files, because two of them were identical and one was only renamed.
That is the entire contents of the repository. There is nothing else in there.

## What this explains

Nearly everything later in the book is a consequence of this chapter.

| Behaviour that surprises people | Because Git stores snapshots |
|---|---|
| `git rebase` produces new commit hashes | The hash covers the parent and the tree, so moving a commit necessarily renames it (Chapter 33) |
| `git commit --amend` does not edit a commit | Objects are named by content and therefore immutable; amending builds a new one (Chapter 29) |
| Renames sometimes vanish from history | They were never recorded, only detected (Chapter 13) |
| Empty directories disappear on clone | They were never stored (this chapter) |
| Checking out an old commit is fast | It is a snapshot, not a replay of deltas |
| A committed secret survives deleting the file | The old blob is still an object; the new commit just stops referencing it (Chapter 37) |
| Two branches with the same content merge cleanly | Identical content is literally the same object |

That last row in the table is worth holding on to. Deleting a file in a new
commit does not remove anything. It creates a tree that does not mention it.
The blob stays exactly where it was, reachable from every earlier commit, which
is why Chapter 37 exists and why it is the hardest chapter in the book.
