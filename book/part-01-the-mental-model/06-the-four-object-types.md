# Chapter 6. The Four Object Types

## The whole vocabulary

Git's object database contains exactly four kinds of thing. There is no fifth.

| Type | Holds | Points at | Roughly |
|---|---|---|---|
| blob | Bytes | Nothing | A file's contents |
| tree | Names, modes | Blobs and trees | A directory |
| commit | Author, time, message | One tree, zero or more commits | A snapshot in history |
| tag | A message, a tagger | Any object, usually a commit | A signed label |

Everything you do in Git creates, reads, or rearranges pointers between these
four. Branches, the index, the stash and remotes are all built on top of them
without adding a fifth type.

## Blobs

A blob is bytes. You can make one without a commit, without a file, and
without touching your working tree:

```console
$ echo 'hello' | git hash-object -w --stdin
ce013625030ba8dba906f756967f9e9ca394464a
$ git cat-file -t ce013625030ba8dba906f756967f9e9ca394464a
blob
$ git cat-file -s ce013625030ba8dba906f756967f9e9ca394464a
6
$ git cat-file -p ce013625030ba8dba906f756967f9e9ca394464a
hello
```

That object now exists in the repository. Nothing references it, no file is
named after it, and `git status` has nothing to say:

```console
$ git status --short
$ git count-objects -v
count: 1
size: 0
in-pack: 0
packs: 0
size-pack: 0
prune-packable: 0
garbage: 0
size-garbage: 0
```

One object, referenced by nothing. Git calls this **unreachable**, and a later
`git gc` will eventually delete it. Chapter 77 covers when, and Chapter 79 uses
the delay to rescue work people thought they had lost.

A blob contains no filename, no path, no permissions, and no timestamps. All of
that lives in the tree that points at it.

## Trees

A tree is a list of entries, each with a mode, a type, a hash and a name. You
can write one directly:

```console
$ printf '100644 blob ce013625030ba8dba906f756967f9e9ca394464a\tgreeting.txt\n' | git mktree
57e9529754dc514a3ec10db2ff882018fbe1fcbf
$ git cat-file -t 57e9529754dc514a3ec10db2ff882018fbe1fcbf
tree
$ git cat-file -p 57e9529754dc514a3ec10db2ff882018fbe1fcbf
100644 blob ce013625030ba8dba906f756967f9e9ca394464a	greeting.txt
```

Or you can get there the ordinary way, by staging a file and asking Git to turn
the index into a tree:

```console
$ git write-tree
57e9529754dc514a3ec10db2ff882018fbe1fcbf
$ git cat-file -p 57e9529754dc514a3ec10db2ff882018fbe1fcbf
100644 blob ce013625030ba8dba906f756967f9e9ca394464a	greeting.txt
```

The same hash. Two completely different routes, one built by hand and one built
from the index, arriving at a byte-identical object. That is content addressing
working exactly as advertised: there is no "which one came first" and no
identity beyond the content.

Chapter 4 covered the five modes a tree entry can carry. The other thing worth
knowing is that entries are sorted, so the same set of files always produces the
same tree no matter what order you added them in:

```console
$ git add zebra.txt apple.txt && git write-tree
f99c50ab1cf885edcd34fda1cfbffe2e3475ece4
$ git rm -q --cached zebra.txt apple.txt
$ git add apple.txt zebra.txt && git write-tree
f99c50ab1cf885edcd34fda1cfbffe2e3475ece4
$ printf '100644 blob 587be6b4c3f93f93c489c0111bba5596147a26cb\tzebra.txt\n100644 blob 975fbec8256d3e8a3797e7a3611380f27c49f4ac\tapple.txt\n' | git mktree
f99c50ab1cf885edcd34fda1cfbffe2e3475ece4
```

Even `git mktree` fed entries in the wrong order sorts them before hashing.
Without that rule, two people committing the same files would get different
hashes and none of Git's synchronisation would work.

## Commits

A commit is a short block of text. Build one from a tree and read it back:

```console
$ git commit-tree 57e9529754dc514a3ec10db2ff882018fbe1fcbf -m 'Say hello'
fbc085cbc0b2fcadb2522133e2b5da55dfb829d7
$ git cat-file -p fbc085cbc0b2fcadb2522133e2b5da55dfb829d7
tree 57e9529754dc514a3ec10db2ff882018fbe1fcbf
author Ada Lovelace <ada@example.com> 1767603600 +0000
committer Ada Lovelace <ada@example.com> 1767603600 +0000

Say hello
```

| Line | Meaning |
|---|---|
| `tree` | The snapshot this commit records. Exactly one, always |
| `parent` | The commit before this one. Zero, one, or many |
| `author` | Who wrote the change, and when |
| `committer` | Who created this commit object, and when |
| (blank line) | Separates headers from the message |
| the rest | The commit message, verbatim |

Author and committer are usually the same person and usually differ after a
rebase or a cherry-pick, where you are creating a commit object for somebody
else's change. Chapter 12 covers the distinction and what each date means.

### Zero, one, or two parents

The number of `parent` lines is what gives history its shape. A first commit
has none:

```console
$ git cat-file -p fbc085cbc0b2fcadb2522133e2b5da55dfb829d7 | head -1
tree 57e9529754dc514a3ec10db2ff882018fbe1fcbf
```

The line straight after `tree` is `author`, so there is no parent at all. This
is a **root commit**.

An ordinary commit has one:

```console
$ git cat-file -p HEAD
tree cdc65aac916e7f13704121291856be3e95a8d4c1
parent fbc085cbc0b2fcadb2522133e2b5da55dfb829d7
author Ada Lovelace <ada@example.com> 1767607200 +0000
committer Ada Lovelace <ada@example.com> 1767607200 +0000

Say goodbye too
```

A merge commit has two, in order:

```console
$ git cat-file -p HEAD
tree 01fa8851e5afab4e6fb2feb005b85cea38afa535
parent 6f7ab800b534855810925b9225a206f4a1c5c6e7
parent c357f58dc901ac70a81a42390f95094c5d742cb2
author Ada Lovelace <ada@example.com> 1767614400 +0000
committer Ada Lovelace <ada@example.com> 1767614400 +0000

Merge side into main
$ git log --graph --oneline
*   3bf8f77 Merge side into main
|\  
| * c357f58 Add a side file
* | 6f7ab80 Say goodbye too
|/
* fbc085c Say hello
```

| Parents | Called | Created by |
|---|---|---|
| 0 | Root commit | The first commit, or `git switch --orphan` |
| 1 | Ordinary commit | `git commit` |
| 2 | Merge commit | `git merge` |
| 3 or more | Octopus merge | `git merge` with several branches at once (Chapter 27) |

The order of the parent lines is not decoration. The first parent is the branch
you were on, the second is the branch you merged in. Commands like
`git log --first-parent` and the `^1` and `^2` suffixes depend on it, and
Chapter 18 covers how to use that.

> **Worth knowing.** A repository can have more than one root commit. It
> happens when unrelated histories are joined, which is why `git merge` has a
> `--allow-unrelated-histories` flag and why it refuses without it.

## Tags, and the one real trap

There are two things called a tag and they are not the same kind of object. An
**annotated** tag is a genuine object in the database:

```console
$ git tag -a v1.0 -m 'First release'
$ git cat-file -t v1.0
tag
$ git cat-file -p v1.0
object 3bf8f778a66677627af069c22b95f1bdd0ab9aaa
type commit
tag v1.0
tagger Ada Lovelace <ada@example.com> 1767618000 +0000

First release
```

It has its own hash, different from the commit it labels:

```console
$ git rev-parse v1.0
7a60e68d1e0c5d1a7fb4f789aa1c89397e440401
$ git rev-parse v1.0^{commit}
3bf8f778a66677627af069c22b95f1bdd0ab9aaa
```

A **lightweight** tag is not an object. It is a file containing a hash:

```console
$ git tag v1.0-light
$ git cat-file -t v1.0-light
commit
$ git rev-parse v1.0-light
3bf8f778a66677627af069c22b95f1bdd0ab9aaa
$ cat .git/refs/tags/v1.0-light
3bf8f778a66677627af069c22b95f1bdd0ab9aaa
$ cat .git/refs/tags/v1.0
7a60e68d1e0c5d1a7fb4f789aa1c89397e440401
```

Look at the last two lines carefully. The lightweight tag's file contains the
commit hash. The annotated tag's file contains the tag object's hash, and that
object in turn names the commit.

```
lightweight:   refs/tags/v1.0-light ──────────────▶ commit
annotated:     refs/tags/v1.0 ──▶ tag object ─────▶ commit
```

| | Annotated | Lightweight |
|---|---|---|
| Created by | `git tag -a`, `git tag -m`, `git tag -s` | `git tag <name>` |
| Is an object | Yes | No |
| Has a message | Yes | No |
| Has a tagger and date | Yes | No |
| Can be signed | Yes | No |
| `git cat-file -t` reports | `tag` | `commit` |
| `git describe` finds it by default | Yes | No |
| Suitable for releases | Yes | No |
| Suitable for a private bookmark | Overkill | Yes |

> **Careful.** `git rev-parse v1.0` gives you the tag object, not the commit.
> Scripts that compare `git rev-parse v1.0` against a commit hash will fail on
> annotated tags and pass on lightweight ones, which is a bug that hides until
> somebody makes a proper release. Write `git rev-parse v1.0^{commit}` when you
> want the commit, and Chapter 18 explains that syntax.

Chapter 47 covers tags as a working tool: pushing them, deleting them, moving
them, and why moving them is a bad idea.

## The type is part of the name

Hashing includes a header naming the type, so the same bytes hashed as
different types give different names. Git will not let you lie about it:

```console
$ printf 'hello\n' | git hash-object --stdin -t blob
ce013625030ba8dba906f756967f9e9ca394464a
$ printf 'hello\n' | git hash-object --stdin -t commit
error: object fails fsck: missingTree: invalid format - expected 'tree' line
fatal: refusing to create malformed object
```

Git parsed the content as a commit, found no `tree` line, and refused. You can
force it past this check with `--literally`, which exists so that Git's own
test suite can create broken objects on purpose. There is no legitimate
day-to-day use for it.

## Counting what is there

```console
$ git cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c
      3 blob
      4 commit
      1 tag
      4 tree
$ git cat-file --batch-all-objects --batch-check='%(objecttype) %(objectsize) %(objectname)' | sort
blob 14 a32119c8aa4c3edcb7043d8f665b94cb52a922e7
blob 21 24e6d70d3853d8f3b8fd511e97d1fd07845beab8
blob 6 ce013625030ba8dba906f756967f9e9ca394464a
commit 170 fbc085cbc0b2fcadb2522133e2b5da55dfb829d7
commit 224 6f7ab800b534855810925b9225a206f4a1c5c6e7
commit 224 c357f58dc901ac70a81a42390f95094c5d742cb2
commit 277 3bf8f778a66677627af069c22b95f1bdd0ab9aaa
tag 139 7a60e68d1e0c5d1a7fb4f789aa1c89397e440401
tree 40 57e9529754dc514a3ec10db2ff882018fbe1fcbf
tree 40 cdc65aac916e7f13704121291856be3e95a8d4c1
tree 77 01fa8851e5afab4e6fb2feb005b85cea38afa535
tree 77 a114cd102fbc79d623d73637daacdd2d1285d08f
```

Twelve objects is the entire repository: four commits, four trees, three blobs
and one tag.

## The cat-file reference

`git cat-file` is how you look at any object, and it is worth knowing properly
because it appears throughout the rest of this book.

| Form | Does |
|---|---|
| `git cat-file -t <object>` | Print the type |
| `git cat-file -s <object>` | Print the size in bytes |
| `git cat-file -p <object>` | Pretty-print, formatted according to the type |
| `git cat-file -e <object>` | Print nothing; exit 0 if it exists, non-zero otherwise |
| `git cat-file blob <object>` | Print raw contents, failing if it is not a blob |
| `git cat-file --batch-all-objects --batch-check` | Walk every object in the repository |

The `--batch-check` format string takes `%(objecttype)`, `%(objectsize)` and
`%(objectname)`, among others.

> **Worth knowing.** `-p` is the one you want almost always. `-e` is for
> scripts: `git cat-file -e $hash 2>/dev/null` is the clean way to ask "does
> this object exist here" without printing anything.

## Why objects are immutable

Because the name is computed from the content, changing the content changes the
name, which means you have not changed the object. You have made a second one.

This single fact is behind a large share of the rest of this book:

| Consequence | Where it bites |
|---|---|
| You cannot edit a commit | `--amend` creates a new commit (Chapter 29) |
| You cannot edit history | Rebase rewrites every commit downstream (Chapter 33) |
| Rewriting shared history breaks other people | Their commits reference names that no longer lead anywhere (Chapter 28) |
| Deleting a file does not remove its content | The blob is still an object (Chapter 37) |
| A commit hash is a checksum of everything before it | Tampering with old history changes every hash after it |

That last row is the quiet one. Because a commit names its parent, and the
parent names its parent, a commit hash covers the entire history leading up to
it. Two people with the same commit hash have provably identical histories, all
the way back. That property is why Git can synchronise over an untrusted
network by exchanging hashes, and Chapter 41 shows the conversation.
