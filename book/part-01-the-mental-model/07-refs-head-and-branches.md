# Chapter 7. Refs, HEAD, and Branches as Pointers

## A branch is a file

Everything people find mysterious about branches stops being mysterious once
you look at one:

```console
$ cat .git/refs/heads/main
fc91c231377e56c565047ff1da3e39e165519133
$ wc -c < .git/refs/heads/main
41
$ git rev-parse main
fc91c231377e56c565047ff1da3e39e165519133
```

Forty-one bytes. Forty hex characters and a newline. That is the entire branch.

A branch does not contain commits. It does not own commits. It is a name for
one commit, and because a commit names its parent, naming one commit is enough
to reach the whole history behind it.

This is why Git branching is instant and why it was a genuine breakthrough
compared to the systems before it, which copied directories to make a branch.
Creating a branch in a repository with a million commits writes forty-one bytes.

The general name for such a file is a **ref**.

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[A branch is a file](#a-branch-is-a-file)**

- [What is a branch, physically?](#a-branch-is-a-file)
- [Why is creating a branch instant, even in a huge repository?](#a-branch-is-a-file)

**[HEAD is a file too](#head-is-a-file-too)**

- [What is `HEAD`?](#head-is-a-file-too)
- [How do I find out which branch I am on?](#head-is-a-file-too)

**[Creating a branch writes one file](#creating-a-branch-writes-one-file)**

- [What does `git branch` write to disk?](#creating-a-branch-writes-one-file)

**[Switching a branch rewrites HEAD](#switching-a-branch-rewrites-head)**

- [What does `git switch` change in the repository?](#switching-a-branch-rewrites-head)

**[Committing moves the ref](#committing-moves-the-ref)**

- [What happens to the branch when I commit?](#committing-moves-the-ref)

**[Detached HEAD](#detached-head)**

- [What is a detached HEAD, and is it an error?](#detached-head)
- [Why did `git checkout` print a long warning where `git switch --detach` printed one line?](#two-ways-in-two-very-different-messages)

**[Moving a branch by hand](#moving-a-branch-by-hand)**

- [Can I point a branch at another commit without committing?](#moving-a-branch-by-hand)
- [Why not just edit the file in `.git/refs`?](#moving-a-branch-by-hand)

**[Listing refs](#listing-refs)**

- [How do I list every ref and what it points at?](#listing-refs)

**[Packed refs](#packed-refs)**

- [My branch exists, so why is there no file for it in `.git/refs/heads`?](#packed-refs)
- [What is reftable?](#packed-refs)

**[The ref namespaces](#the-ref-namespaces)**

- [What lives under `refs/`?](#the-ref-namespaces)
- [What happens when a tag and a branch have the same name?](#the-ref-namespaces)

**[A ref is a path, and paths collide](#a-ref-is-a-path-and-paths-collide)**

- [Why can't I create `feature/login` when `feature` exists?](#a-ref-is-a-path-and-paths-collide)

**[What names are legal](#what-names-are-legal)**

- [Which characters can't a branch name contain?](#what-names-are-legal)
- [Can a branch be called `@`?](#what-names-are-legal)
- [How do I check a name in a script before using it?](#what-names-are-legal)

**[The whole picture](#the-whole-picture)**

- [What does the ref part of `.git` look like, all together?](#the-whole-picture)

</details>

## HEAD is a file too

```console
$ cat .git/HEAD
ref: refs/heads/main
$ git symbolic-ref HEAD
refs/heads/main
$ git rev-parse HEAD main refs/heads/main
fc91c231377e56c565047ff1da3e39e165519133
fc91c231377e56c565047ff1da3e39e165519133
fc91c231377e56c565047ff1da3e39e165519133
```

`HEAD` does not contain a hash. It contains the name of a branch. That extra
level of indirection is the whole design:

```
HEAD ──▶ refs/heads/main ──▶ commit fc91c23 ──▶ parent ──▶ parent ──▶ ...
```

A ref that points at another ref instead of at an object is a **symbolic ref**.
`HEAD` is the one you use constantly; there are others, and `git symbolic-ref`
is the command that reads and writes them.

| Question | Command |
|---|---|
| Which branch am I on? | `git branch --show-current` |
| What does HEAD literally contain? | `git symbolic-ref HEAD` |
| What commit does HEAD resolve to? | `git rev-parse HEAD` |

## Creating a branch writes one file

```console
$ ls .git/refs/heads
main
$ git branch feature
$ ls .git/refs/heads
feature
main
$ cat .git/refs/heads/feature
fc91c231377e56c565047ff1da3e39e165519133
$ git branch -v
  feature fc91c23 Second commit
* main    fc91c23 Second commit
```

Two branches, same commit, no duplication of anything. The asterisk in
`git branch -v` marks where `HEAD` points.

## Switching a branch rewrites HEAD

```console
$ git switch feature
Switched to branch 'feature'
$ cat .git/HEAD
ref: refs/heads/feature
$ git switch main
Switched to branch 'main'
$ cat .git/HEAD
ref: refs/heads/main
```

That is all `git switch` does to the repository. It also updates your working
tree and index to match the new branch's commit, which is the part that takes
time, but the branch bookkeeping is one line in one file.

## Committing moves the ref

```console
$ cat .git/refs/heads/main
fc91c231377e56c565047ff1da3e39e165519133
$ echo third > c.txt && git add c.txt && git commit -m 'Third commit'
[main bbe2461] Third commit
 1 file changed, 1 insertion(+)
 create mode 100644 c.txt
$ cat .git/refs/heads/main
bbe24619aaf32918c971f64744c8593e996f3ff9
$ cat .git/refs/heads/feature
fc91c231377e56c565047ff1da3e39e165519133
```

`main` now holds the new commit's hash, and `feature` is untouched, still
pointing where it always did.

So the sequence for every ordinary commit is:

1. Write the blobs for changed files.
2. Write the trees.
3. Write a commit object whose parent is the current `HEAD`.
4. Overwrite the file for the branch `HEAD` names with the new commit's hash.

Step four is what "the branch advanced" means. Nothing else moved.

## Detached HEAD

If `HEAD` can hold a branch name, it can also hold a hash directly. That state
is called **detached HEAD** and it is not an error:

```console
$ git switch --detach HEAD~1
HEAD is now at fc91c23 Second commit
$ cat .git/HEAD
fc91c231377e56c565047ff1da3e39e165519133
$ git symbolic-ref HEAD
fatal: ref HEAD is not a symbolic ref
$ git status
HEAD detached at fc91c23
nothing to commit, working tree clean
$ git branch --show-current
```

`HEAD` now contains a raw hash, `git symbolic-ref` refuses because there is no
name to report, and `git branch --show-current` prints nothing at all because
there is no current branch.

Everything still works. You can look at files, run the code, and even commit.
The only thing missing is a branch that moves when you commit, which means new
commits are reachable from nothing but `HEAD` itself. Switch away and they
become unreachable.

> **Careful.** Commits made on a detached HEAD are not lost immediately when
> you switch away, because the reflog still records them (Chapter 36). But they
> are unreferenced, and `git gc` will eventually delete them. If you committed
> something you want, run `git switch -c <name>` before you go anywhere else.

### Two ways in, two very different messages

```console
$ git checkout HEAD~1
Note: switching to 'HEAD~1'.

You are in 'detached HEAD' state. You can look around, make experimental
changes and commit them, and you can discard any commits you make in this
state without impacting any branches by switching back to a branch.

If you want to create a new branch to retain commits you create, you may
do so (now or later) by using -c with the switch command. Example:

  git switch -c <new-branch-name>

Or undo this operation with:

  git switch -

Turn off this advice by setting config variable advice.detachedHead to false

HEAD is now at fc91c23 Second commit
```

`git switch --detach` said one line. `git checkout` said seventeen. The
difference is intent: with `--detach` you asked for this explicitly, so Git
assumes you know. With `checkout` it happened as a side effect of naming a
commit instead of a branch, so Git warns you.

This is the clearest single illustration of why `switch` and `restore` were
split out of `checkout`. Note that Git's own advice text now recommends
`git switch -c` as the fix.

| Situation | Modern | Classic |
|---|---|---|
| Deliberately detach | `git switch --detach <commit>` | `git checkout <commit>` |
| Keep the commits you made while detached | `git switch -c <name>` | `git checkout -b <name>` |
| Go back where you were | `git switch -` | `git checkout -` |

## Moving a branch by hand

Since a branch is a file holding a hash, moving one is writing a different
hash. `git update-ref` does it safely:

```console
$ git log --oneline
bbe2461 Third commit
fc91c23 Second commit
769daaa First commit
$ git update-ref refs/heads/feature HEAD~2
$ git branch -v
  feature 769daaa First commit
* main    bbe2461 Third commit
$ git update-ref refs/heads/feature HEAD
$ git branch -v
  feature bbe2461 Third commit
* main    bbe2461 Third commit
```

The branch jumped back two commits and then forward again, and no commits were
created or destroyed. This is exactly what `git reset --hard` does to the
current branch, and Chapter 30 explains the rest of what `reset` touches.

> **Careful.** Write refs with `git update-ref`, not with a text editor.
> `update-ref` takes a lock, writes atomically, and records the change in the
> reflog. Editing `.git/refs/heads/main` by hand skips all three, so a crash
> can leave a half-written ref and you lose the reflog entry that would have
> let you undo it.

## Listing refs

```console
$ git show-ref
bbe24619aaf32918c971f64744c8593e996f3ff9 refs/heads/feature
bbe24619aaf32918c971f64744c8593e996f3ff9 refs/heads/main
$ git for-each-ref --format='%(refname) %(objecttype) %(objectname:short)'
refs/heads/feature commit bbe2461
refs/heads/main commit bbe2461
```

| Command | Best for |
|---|---|
| `git branch` | Humans, branches only |
| `git show-ref` | A quick dump of every ref and its hash |
| `git for-each-ref` | Scripts. It has a format language and can sort and filter |

`git for-each-ref` is the one worth learning. It is how you answer questions
like "which branches were merged" or "which tag is newest" without parsing
human-readable output, and Chapter 22 uses it repeatedly.

## Packed refs

Ten thousand branches would mean ten thousand tiny files. Git avoids that by
packing refs into one file:

```console
$ ls .git/refs/heads
feature
main
$ git pack-refs --all
$ ls .git/refs/heads || true
$ cat .git/packed-refs
# pack-refs with: peeled fully-peeled sorted 
bbe24619aaf32918c971f64744c8593e996f3ff9 refs/heads/feature
bbe24619aaf32918c971f64744c8593e996f3ff9 refs/heads/main
$ git rev-parse main
bbe24619aaf32918c971f64744c8593e996f3ff9
$ git branch -v
  feature bbe2461 Third commit
* main    bbe2461 Third commit
```

The individual files are gone and everything still works. Git looks for a
loose ref file first and falls back to `packed-refs`.

> **Worth knowing.** This is why `cat .git/refs/heads/main` sometimes says "No
> such file or directory" in a repository that definitely has a `main` branch.
> The ref is packed. Use `git rev-parse main`, which checks both places, rather
> than reading files directly. Fresh clones arrive with their refs packed, so
> this is the normal state, not the exception.

When you update a packed ref, Git writes a new loose file that shadows the
packed entry, and a later `git pack-refs` or `git gc` folds it back in.

> **Since Git 2.45.** There is a second storage format called **reftable**,
> a binary format designed for repositories with very large numbers of refs.
> It is opt-in today, through `git init --ref-format=reftable`, and Git 3.0
> will make it the default for new repositories. In a reftable repository the
> files shown in this chapter do not hold the refs, as
> [A ref is a path, and paths collide](#a-ref-is-a-path-and-paths-collide)
> shows, so read refs with `git rev-parse` and `git for-each-ref` if you want
> your habits to survive that change.

## The ref namespaces

Refs live under `refs/` in named namespaces:

| Namespace | Holds | Created by |
|---|---|---|
| `refs/heads/` | Local branches | `git branch`, `git switch -c` |
| `refs/tags/` | Tags | `git tag` |
| `refs/remotes/` | Remote-tracking branches | `git fetch`, `git clone` |
| `refs/stash` | The stash stack | `git stash` |
| `refs/notes/` | Notes attached to commits | `git notes` |

When you write `main`, Git searches the namespaces in a fixed order to work out
what you meant (Chapter 18 gives it). That is why a tag and a branch with the
same name is a bad idea: Git lets you create one, and from then on warns
`refname 'v1.0' is ambiguous` whenever you use the name, as Chapter 18 shows. The unambiguous forms are always
available:

| Shorthand | Full form |
|---|---|
| `main` | `refs/heads/main` |
| `v1.0` | `refs/tags/v1.0` |
| `origin/main` | `refs/remotes/origin/main` |

## A ref is a path, and paths collide

Because a ref is a file inside a directory, a branch name that contains a slash
creates a directory. And a name cannot be both a file and a directory:

```console
$ git branch feature/login
fatal: 'refs/heads/feature' exists; cannot create 'refs/heads/feature/login'
$ git branch -D feature
Deleted branch feature (was bbe2461).
$ git branch feature/login
$ find .git/refs -type f | sort
.git/refs/heads/feature/login
$ git branch feature
fatal: cannot lock ref 'refs/heads/feature': 'refs/heads/feature/login' exists; cannot create 'refs/heads/feature'
$ git branch feature/login/deeper
fatal: cannot lock ref 'refs/heads/feature/login/deeper': 'refs/heads/feature/login' exists; cannot create 'refs/heads/feature/login/deeper'
```

Three refusals, all the same rule from three directions:

| You have | You cannot also have | Because |
|---|---|---|
| `feature` | `feature/login` | `feature` is a file, not a directory |
| `feature/login` | `feature` | `feature` is a directory, not a file |
| `feature/login` | `feature/login/deeper` | `feature/login` is a file, not a directory |

This is the reason teams that use `feature/` prefixes never also use a bare
`feature` branch, and why a colleague deleting their `feature` branch can
suddenly unblock your `feature/login`. It is not a naming policy. It is a
filesystem.

The rule holds in a reftable repository too, where refs are not files at all.
In one made with `git init --ref-format=reftable`:

```console
$ git branch feature && git branch feature/login
fatal: 'refs/heads/feature' exists; cannot create 'refs/heads/feature/login'
$ cat .git/HEAD && git symbolic-ref HEAD
ref: refs/heads/.invalid
refs/heads/main
```

The same refusal, word for word. `.git/HEAD` there is only a placeholder,
pointing at a name no branch can have, and the real value is in the reftable
files; `git symbolic-ref` reads it.

## What names are legal

```console
$ git check-ref-format --branch 'good-name'
good-name
$ git check-ref-format --branch 'bad name'
fatal: 'bad name' is not a valid branch name
$ git branch 'bad name'
fatal: 'bad name' is not a valid branch name
hint: See 'git help check-ref-format'
hint: Disable this message with "git config set advice.refSyntax false"
$ git branch 'ends.lock'
fatal: 'ends.lock' is not a valid branch name
hint: See 'git help check-ref-format'
hint: Disable this message with "git config set advice.refSyntax false"
$ git branch 'has..dots'
fatal: 'has..dots' is not a valid branch name
hint: See 'git help check-ref-format'
hint: Disable this message with "git config set advice.refSyntax false"
$ git branch -- '-leading-dash'
fatal: '-leading-dash' is not a valid branch name
hint: See 'git help check-ref-format'
hint: Disable this message with "git config set advice.refSyntax false"
```

`git branch` adds the same two hint lines to every refusal, not only the first;
`git check-ref-format` does not.

The rules, as Git's own documentation states them:

| Not allowed | Reason |
|---|---|
| Space, and ASCII control characters | They break shell and script handling |
| `~`, `^`, `:` | Revision syntax (Chapter 18) |
| `?`, `*`, `[` | Glob characters the shell would expand |
| `\` | Path separator confusion |
| Two consecutive dots, `..` | Range syntax (Chapter 18) |
| The sequence `@{` | Reflog and upstream syntax (Chapter 18) |
| A component beginning with a dot | Hidden-file conventions |
| A component ending in `.lock` | Collides with Git's own lock files |
| Ending with a dot, or with a slash | Path rules |
| Two consecutive slashes | Path rules |
| A ref whose entire name is `@` | `@` is shorthand for `HEAD` |

One rule applies to branch names but not to refs in general, and Git's
documentation calls it out explicitly: **a dash may begin a ref component, but
never a branch name.** So `refs/heads/-x` is a legal refname while the branch
name `-x` is refused, which is why `--branch` is described as stricter than a
plain check:

```console
$ git check-ref-format refs/heads/-x && echo valid
valid
$ git check-ref-format --branch -x
fatal: '-x' is not a valid branch name
```

The last row is narrower than it looks. A ref named exactly `@` is forbidden,
but a *branch* named `@` is legal, because its full name is `refs/heads/@` and
only the last component is `@`:

```console
$ git branch @ HEAD~1 && git log --oneline -1 @ && git log --oneline -1 heads/@
bbe2461 Third commit
fc91c23 Second commit
$ git switch @
fatal: a branch is expected, got 'refs/heads/main'
hint: If you want to detach HEAD at the commit, try again with the --detach option.
```

Git created it, pointing at the second commit. But `@` in a command still means
`HEAD`, with no warning: `git log @` showed the third commit, and `git switch @`
read it as `HEAD`, which is `main`. The branch can be reached only by a longer
name such as `heads/@`. Legal is not the same as advisable.

`git check-ref-format` is the authority, and it is what Git itself calls. If
you generate branch names in a script, validating with
`git check-ref-format --branch "$name"` before using them is cheaper than
handling the failure afterwards. Note that with `--branch`, Git first expands
the previous-checkout syntax `@{-1}`, so a name of that shape is rewritten
rather than rejected.

> **Worth knowing.** Slashes are fine and widely used, so `feature/login`,
> `release/2.1` and `user/ada/experiment` are all legal, subject to the
> collision rule above. Unicode is also fine, though it makes life harder for
> anyone on a different keyboard.

## The whole picture

```
.git/
├── HEAD                      "ref: refs/heads/main"
├── packed-refs               many refs in one file
└── refs/
    ├── heads/
    │   ├── main              one hash
    │   └── feature/
    │       └── login         one hash
    ├── tags/
    │   └── v1.0              one hash
    └── remotes/
        └── origin/
            ├── HEAD          "ref: refs/remotes/origin/main"
            └── main          one hash
```

Every file in that tree is either forty-one bytes of hash or a short line
naming another ref. That is the complete machinery behind branching,
switching, tagging and tracking remotes. Chapter 70 opens the rest of the
`.git` directory.
