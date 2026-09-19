# Chapter 8. The Lifecycle of a File

## The states

Every file in your project is in exactly one of these states:

| State | Meaning | How `git status --short` shows it |
|---|---|---|
| Untracked | Git has never been told about it | `??` |
| Ignored | Untracked, and a rule says not to mention it | nothing, or `!!` with `--ignored` |
| Unmodified | Tracked, and identical in all three areas | nothing |
| Modified | Tracked, working tree differs from the index | ` M` |
| Staged | Tracked, index differs from HEAD | `M ` or `A ` |
| Deleted | Tracked, and gone from the working tree | ` D` or `D ` |

"Tracked" simply means the file has an entry in the index. That is the whole
definition, and `git ls-files` lists exactly those files.

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[The states](#the-states)**

- [What states can a file be in?](#the-states)
- [What does "tracked" actually mean?](#the-states)

**[The map](#the-map)**

- [Which command moves a file from one state to another?](#the-map)

**[Untracked to committed](#untracked-to-committed)**

- [Why does `git status` show `A` for one file and `M` for another?](#untracked-to-committed)

**[Deleting is a change like any other](#deleting-is-a-change-like-any-other)**

- [I deleted a file by mistake. Can I get it back?](#deleting-is-a-change-like-any-other)

**[rm versus git rm](#rm-versus-git-rm)**

- [What is the difference between `rm` and `git rm`?](#rm-versus-git-rm)
- [Why does `git rm` refuse to delete my file?](#rm-versus-git-rm)

**[Ignoring](#ignoring)**

- [How do I find out why a file is ignored?](#ignoring)

**[The trap: ignoring a file that is already tracked](#the-trap-ignoring-a-file-that-is-already-tracked)**

- [I added a file to `.gitignore` and Git still shows its changes. Why?](#the-trap-ignoring-a-file-that-is-already-tracked)
- [Why does `git check-ignore` say nothing about my file?](#the-trap-ignoring-a-file-that-is-already-tracked)

**[Untracking without deleting](#untracking-without-deleting)**

- [How do I stop tracking a file but keep it on disk?](#untracking-without-deleting)

**[History still has it](#history-still-has-it)**

- [I untracked a file. Is it gone from the repository?](#history-still-has-it)

**[Pretending a tracked file has not changed](#pretending-a-tracked-file-has-not-changed)**

- [Can I make Git ignore my local changes to a tracked config file?](#pretending-a-tracked-file-has-not-changed)
- [How do I find files someone marked with `--assume-unchanged` or `--skip-worktree`?](#pretending-a-tracked-file-has-not-changed)

**[Every transition in one table](#every-transition-in-one-table)**

- [Which of these steps can lose work for good?](#every-transition-in-one-table)

</details>

## The map

```
                  ┌──────────────────────────────────────────┐
                  │                                          │
   untracked ──── git add ──▶ staged ──── git commit ──▶ unmodified
       ▲                        ▲   │                        │
       │                        │   │                        │
  git rm --cached          git add  git restore --staged   edit the file
       │                        │   │                        │
       │                        │   ▼                        ▼
       └─────────────────────── modified ◀───────────────────┘
                                    │
                            git restore
                                    │
                                    ▼
                               unmodified
```

The rest of this chapter walks every arrow.

## Untracked to committed

A new file is untracked:

```console
$ echo one > draft.txt && git status --short
?? draft.txt
```

`git add` puts it in the index. The code is `A` because the file is new to the
index, not merely changed:

```console
$ git add draft.txt
$ git status --short
A  draft.txt
```

`git commit` records it. Now it is tracked and unmodified, so `git status` has
nothing to say and `git ls-files` does:

```console
$ git commit -q -m 'Add draft'
$ git status --short
$ git ls-files
draft.txt
```

From here the cycle repeats, and the code is `M` rather than `A` because the
index already knew about the file:

```console
$ echo two >> draft.txt && git status --short
 M draft.txt
$ git add draft.txt
$ git status --short
M  draft.txt
$ git commit -q -m 'Extend draft'
$ git status --short
```

| Code | When you see it |
|---|---|
| `A ` | The file is new to the index, so this is its first commit |
| `M ` | The file was already tracked and you staged a change |

The distinction matters when reading someone else's `git status` output in a
bug report, and nowhere else.

## Deleting is a change like any other

Delete the file with your shell, and Git records the deletion as a pending
change:

```console
$ rm draft.txt && git status --short
 D draft.txt
$ git status
On branch main
Changes not staged for commit:
  (use "git add/rm <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	deleted:    draft.txt

no changes added to commit (use "git add" and/or "git commit -a")
```

That deletion is not staged, so it is not going to be committed yet, and it is
completely reversible:

```console
$ git restore draft.txt
$ git status --short
$ cat draft.txt
one
two
```

`git restore` copied the file back out of the index. Nothing was lost, because
the deletion never reached the index.

## rm versus git rm

`git rm` does two things at once: deletes the file and stages the deletion.

```console
$ git rm draft.txt
rm 'draft.txt'
$ git status --short
D  draft.txt
$ ls
```

Note the code is `D ` with the letter on the left. The deletion is staged. To
walk it back, undo both steps in order:

```console
$ git restore --staged draft.txt
$ git status --short
 D draft.txt
$ git restore draft.txt
$ git status --short
```

| Command | Deletes from disk | Stages the deletion |
|---|---|---|
| `rm file` | yes | no |
| `git rm file` | yes | yes |
| `git rm --cached file` | no | yes |

The third row is the useful one and it gets a section of its own below.

`git rm` refuses to delete a file with unstaged changes, and the refusal is
worth reading closely:

```console
$ git rm draft.txt
error: the following file has local modifications:
    draft.txt
(use --cached to keep the file, or -f to force removal)
```

> **Careful.** Git offers `--cached` before it offers `-f`, and that ordering
> is advice. `-f` throws the edits away permanently; `--cached` keeps the file
> on disk and only stops tracking it. Reach for `-f` only when you have read
> the diff and decided you want the changes gone.

## Ignoring

A rule in `.gitignore` keeps a file out of the untracked list entirely:

```console
$ cat .gitignore && ls
*.log
debug.log
draft.txt
$ git status --short
$ git status --short --ignored
!! debug.log
$ git check-ignore -v debug.log
.gitignore:1:*.log	debug.log
```

`git check-ignore -v` is the tool to remember. It answers "why is this file
ignored" by naming the file, the line number, and the pattern that matched.
Chapter 16 is about `.gitignore` in full.

## The trap: ignoring a file that is already tracked

This is the single most common `.gitignore` misunderstanding, so it gets its
own demonstration. A file is committed by mistake, then added to `.gitignore`,
and then changed:

```console
$ echo hunter2 > secrets.txt && git add secrets.txt && git commit -q -m 'Add secrets by mistake'
$ printf '*.log\nsecrets.txt\n' > .gitignore
$ echo 'changed anyway' >> secrets.txt
$ git status --short
 M .gitignore
 M secrets.txt
```

`secrets.txt` still shows as modified. The ignore rule did nothing.

**Ignore rules only apply to untracked files.** Once a file is in the index,
Git keeps tracking it and no pattern will change that. The rule exists so that
adding a broad pattern like `*.log` cannot silently stop tracking files your
project depends on.

Diagnosing it is confusing, because `check-ignore` is silent:

```console
$ git check-ignore -v secrets.txt
$ git check-ignore -v --no-index secrets.txt
.gitignore:2:secrets.txt	secrets.txt
```

The first command printed nothing because tracked files are not subject to
exclude rules at all, so there is genuinely no answer to give. `--no-index`
asks the question the other way: *if* this file were untracked, which rule
would match? Git's own documentation describes this flag as the way to debug
exactly this situation.

> **Worth knowing.** Silence from `git check-ignore` on a file you expected to
> be ignored is itself the diagnosis. It almost always means the file is
> tracked, not that your pattern is wrong.

## Untracking without deleting

The fix is to remove it from the index while leaving it on disk:

```console
$ git rm --cached secrets.txt
rm 'secrets.txt'
$ git status --short
 M .gitignore
D  secrets.txt
$ ls
debug.log
draft.txt
secrets.txt
```

The staged change says "delete", the file is still in the working directory,
and after committing, the ignore rule finally takes effect:

```console
$ git add .gitignore && git commit -q -m 'Stop tracking secrets.txt'
$ git status --short
$ git ls-files
.gitignore
draft.txt
```

`secrets.txt` is gone from the index, still on disk, and now genuinely ignored.

> **Careful.** For anyone else, this commit *is* a deletion. When they pull,
> the file disappears from their working tree. That is usually right for build
> output and usually wrong for a config file everybody needs, where the
> convention is to track `config.example.ini` and ignore `config.ini`.

## History still has it

Removing a file from the current tree does not remove it from the repository:

```console
$ git cat-file -p HEAD^{tree}
100644 blob 2ae8d8b09f8a3533327b4ae49e7d0b3f4ec91809	.gitignore
100644 blob 814f4a422927b82f5f8a43f8fab6d3839e3983f2	draft.txt
$ git log --oneline -- secrets.txt
cb2cbe2 Stop tracking secrets.txt
94dd0b5 Add secrets by mistake
$ git cat-file -p HEAD~1:secrets.txt
hunter2
```

The tip commit does not list the file. The blob is still there, still readable,
still in every earlier commit, and it will be in every clone anybody makes.

> **Careful.** If what you committed was a password, an API key, or a private
> key, removing the file is not enough and rotating the credential is not
> optional. Chapter 37 covers removing content from history, and its first
> piece of advice is to change the secret first, because history rewriting
> cannot reach copies other people have already cloned.

## Pretending a tracked file has not changed

Two flags claim to make Git overlook local changes to a tracked file:

`config.ini` is committed, holding `debug = false`:

```console
$ git update-index --skip-worktree config.ini
$ echo 'debug = true' > config.ini
$ git status --short
$ git ls-files -v | grep config
S config.ini
$ git update-index --no-skip-worktree config.ini
$ git status --short
 M config.ini
```

The file was edited, `git status` said nothing, and the `S` in `git ls-files -v`
is the marker. Turning the bit off brings the change back into view.

| Bit | Set with | `ls-files -v` letter | Meant for |
|---|---|---|---|
| assume-unchanged | `--assume-unchanged` | `h` | Filesystems where checking every file is slow |
| skip-worktree | `--skip-worktree` | `S` | Sparse checkouts, where the file is deliberately absent |

Both are widely recommended online as a way to keep local edits to a tracked
config file out of `git status`. Both are the wrong tool for that, and the
documentation says so in its own words.

For assume-unchanged, the flag means *you promise not to change the file*, so
that Git may skip checking it. Changing it anyway breaks the promise, and the
documentation warns that Git will fail when it needs to update the file, for
instance during a merge, and that you will have to sort it out by hand.

For skip-worktree, the stated purpose is sparse checkouts, the documentation
notes that not all commands respect the bit and some only partially support it,
and it strongly recommends `git sparse-checkout` over touching the bit
directly. Chapter 60 covers that command.

> **Careful.** The failure mode of both is that the bits are local and
> invisible. A colleague pulls, their merge succeeds, yours breaks in a way
> nobody can reproduce, and nothing in `git status` hints at why. If you want
> local configuration that is never committed, track an example file and ignore
> the real one. It is not clever and it always works.

To find bits somebody already set, including yourself six months ago:

```console
$ git update-index --assume-unchanged config.ini
$ git ls-files -v | grep -v '^H'
h config.ini
$ git update-index --no-assume-unchanged config.ini
```

`H` is the ordinary state, so anything else is a file that has been marked:
here `config.ini`, with the `h` of assume-unchanged, set on the first line for
the example and cleared on the last.

## Every transition in one table

| From | To | Command |
|---|---|---|
| Untracked | Staged | `git add <file>` |
| Untracked | Ignored | Add a pattern to `.gitignore` |
| Staged | Unmodified | `git commit` |
| Staged | Modified | `git restore --staged <file>` |
| Staged | Untracked | `git rm --cached <file>` |
| Unmodified | Modified | Edit the file |
| Modified | Staged | `git add <file>` |
| Modified | Unmodified | `git restore <file>` (destroys the edit) |
| Unmodified | Deleted, unstaged | `rm <file>` |
| Unmodified | Deleted, staged | `git rm <file>` |
| Deleted, unstaged | Unmodified | `git restore <file>` |
| Deleted, staged | Deleted, unstaged | `git restore --staged <file>` |
| Tracked | Untracked, file kept | `git rm --cached <file>` |
| Any committed state | Any earlier state | Chapters 30 and 78 |

The only row that destroys work with no way back is `git restore <file>` on a
modified file. Everything else above is recoverable, because everything else
either kept the bytes on disk or already wrote them into an object.
