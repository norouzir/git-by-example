# Chapter 20. bisect

## What it is

Something worked in an old version and is broken now, and a long history lies
between. `git bisect` finds the commit that broke it by *binary search*: it
checks out a commit halfway between one you know is good and one you know is
bad, you test it and say which it is, and it halves the remaining commits again.
Each answer throws away half the suspects, so a thousand commits take about ten
tests.

You do the testing: by hand, by typing `git bisect good` or `git bisect bad`
after each check, or by giving `git bisect run` a script that answers for you.
The commit it names is the first one that is bad, whatever "bad" means for you;
[Other words for good and bad](#other-words-for-good-and-bad) shows it looking for
a fix instead of a bug.

While bisecting, you are not on a branch: Git checks out commits directly, which
is a *detached HEAD* (Chapter 24). `git bisect reset` puts you back.

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What does `git bisect` do, and how many tests will it take?](#what-it-is)

**[Synopsis](#synopsis)**

- [What are all the `git bisect` subcommands?](#synopsis)

**[Options at a glance](#options-at-a-glance)**

- [Which options does `git bisect start` take?](#options-at-a-glance)

**[The example](#the-example)**

- [What bug do the examples look for?](#the-example)

**[Bisecting by hand](#bisecting-by-hand)**

- [How do I start, and what do I tell Git after each test?](#bisecting-by-hand)
- [What does "7 revisions left to test after this (roughly 3 steps)" mean?](#bisecting-by-hand)
- [What do I do with a commit I cannot test?](#bisecting-by-hand)
- [How do I see what I have marked so far?](#bisecting-by-hand)
- [How do I stop bisecting and get my branch back?](#bisecting-by-hand)

**[When you marked a commit wrongly](#when-you-marked-a-commit-wrongly)**

- [I typed `good` instead of `bad`. Do I have to start again?](#when-you-marked-a-commit-wrongly)
- [Why does `git bisect good` say I need to start?](#when-you-marked-a-commit-wrongly)

**[Skipping commits](#skipping-commits)**

- [What happens if I skip the commit next to the bad one?](#skipping-commits)
- [Can I skip a whole range of commits at once?](#skipping-commits)

**[Letting a script decide](#letting-a-script-decide)**

- [How do I make Git run my test at every step?](#letting-a-script-decide)
- [What exit codes does `git bisect run` understand?](#letting-a-script-decide)
- [Why should my test script live outside the repository?](#letting-a-script-decide)
- [My script was not found, and bisect stopped at once. Why?](#letting-a-script-decide)

**[Other words for good and bad](#other-words-for-good-and-bad)**

- [How do I find the commit that fixed something, not broke it?](#other-words-for-good-and-bad)
- [Can I use my own words instead of good and bad?](#other-words-for-good-and-bad)
- [Why does `git bisect bad` say I am in a new/old bisect?](#other-words-for-good-and-bad)

**[Fewer commits to test](#fewer-commits-to-test)**

- [I know several good commits. Does telling Git help?](#fewer-commits-to-test)
- [Can I bisect only the commits that touched certain files?](#fewer-commits-to-test)
- [How do I list the commits still in question?](#fewer-commits-to-test)

**[Testing without checking out](#testing-without-checking-out)**

- [Can bisect leave my working tree alone?](#testing-without-checking-out)

**[Moving about during a bisection](#moving-about-during-a-bisection)**

- [I checked out another commit in the middle. How do I get back on track?](#moving-about-during-a-bisection)
- [Can I mark a commit other than the one checked out?](#moving-about-during-a-bisection)
- [How do I finish on the bad commit instead of my branch?](#moving-about-during-a-bisection)
- [Git says some good revs are not ancestors of the bad rev. What did I do?](#moving-about-during-a-bisection)

**[Merges](#merges)**

- [The bug came in with a merge. How do I find the merge rather than the branch commit?](#merges)

**[bisect and its neighbours](#bisect-and-its-neighbours)**

- [Should I use `git bisect`, `git blame` or `git log -S`?](#bisect-and-its-neighbours)

</details>

## Synopsis

```
git bisect start [--term-(bad|new)=<term-new> --term-(good|old)=<term-old>]
                 [--no-checkout] [--first-parent] [<bad> [<good>...]] [--] [<pathspec>...]
git bisect (bad|new|<term-new>) [<rev>]
git bisect (good|old|<term-old>) [<rev>...]
git bisect terms [--term-(good|old) | --term-(bad|new)]
git bisect skip [(<rev>|<range>)...]
git bisect next
git bisect reset [<commit>]
git bisect (visualize|view)
git bisect replay <logfile>
git bisect log
git bisect run <cmd> [<arg>...]
git bisect help
```

| Subcommand | Does | Covered in |
|---|---|---|
| `git bisect start` | Begin, optionally naming the bad and good commits | [Bisecting by hand](#bisecting-by-hand) |
| `git bisect bad [<rev>]` | Mark a commit, the current one by default, as bad | [Bisecting by hand](#bisecting-by-hand) |
| `git bisect good [<rev>...]` | Mark commits as good | [Bisecting by hand](#bisecting-by-hand) |
| `git bisect new`, `git bisect old` | The same, under other names | [Other words for good and bad](#other-words-for-good-and-bad) |
| `git bisect skip [<rev>...]` | Leave commits out, as untestable | [Skipping commits](#skipping-commits) |
| `git bisect terms` | Show the words in use | [Other words for good and bad](#other-words-for-good-and-bad) |
| `git bisect log` | Print the marks so far, as commands | [Bisecting by hand](#bisecting-by-hand) |
| `git bisect replay <logfile>` | Redo a saved log | [When you marked a commit wrongly](#when-you-marked-a-commit-wrongly) |
| `git bisect run <cmd>` | Test every step with a command | [Letting a script decide](#letting-a-script-decide) |
| `git bisect visualize`, `git bisect view` | Show the commits still in question | [Fewer commits to test](#fewer-commits-to-test) |
| `git bisect next` | Check out the next commit to test again | [Moving about during a bisection](#moving-about-during-a-bisection) |
| `git bisect reset [<commit>]` | Stop, and go back or to `<commit>` | [Bisecting by hand](#bisecting-by-hand) |
| `git bisect help` | Print the usage | [Moving about during a bisection](#moving-about-during-a-bisection) |

## Options at a glance

| Option of `git bisect start` | Does | Covered in |
|---|---|---|
| `<bad> [<good>...]` | Mark these at the start | [When you marked a commit wrongly](#when-you-marked-a-commit-wrongly) |
| `-- <pathspec>...` | Test only commits that touch these paths | [Fewer commits to test](#fewer-commits-to-test) |
| `--term-new=<term>`, `--term-bad=<term>` | Your word for the newer state | [Other words for good and bad](#other-words-for-good-and-bad) |
| `--term-old=<term>`, `--term-good=<term>` | Your word for the older state | [Other words for good and bad](#other-words-for-good-and-bad) |
| `--no-checkout` | Do not check out commits; move `BISECT_HEAD` instead | [Testing without checking out](#testing-without-checking-out) |
| `--first-parent` | Follow only the first parent of merges | [Merges](#merges) |

| Option of `git bisect terms` | Prints |
|---|---|
| `--term-bad`, `--term-new` | the word for the newer state |
| `--term-good`, `--term-old` | the word for the older state |

<!-- no-example: --term-good
     the table and the section attribute these spellings to Git's
     documentation; --term-old and --term-bad are demonstrated, and the
     documentation lists each pair as the same option -->

## The example

A calculator written in shell adds two numbers. It is broken now and worked when
it was tagged `v1.0`, fifteen commits ago:

```console
$ git log --oneline
afc361a Write note 16
b5d4ac3 Write note 15
93e3d3e Write note 14
c98edb1 Write note 13
cde530b Write note 12
d28dcd5 Write note 11
d0023a0 Write note 10
07a8fd7 Finish moving the calculator
f33ede3 Start moving the calculator
88a1f84 Share code between add and sub
e9253b2 Tidy the adder
0c9d884 Write note 5
d8c07c4 Write note 4
032ee13 Write note 3
c5584f9 Write note 2
e8f1111 Add the calculator
$ sh calc.sh add 2 3
-1
$ git switch --detach v1.0
HEAD is now at e8f1111 Add the calculator
$ sh calc.sh add 2 3
5
$ git switch main
Previous HEAD position was e8f1111 Add the calculator
Switched to branch 'main'
```

`sh calc.sh add 2 3` is the test: `5` is right, anything else is the bug.
`git switch --detach` checked out the old version to confirm it was good
(Chapter 24). One commit, `Start moving the calculator`, renamed the file away and
the next brought it back, so the calculator cannot be tested there.

## Bisecting by hand

```console
$ git bisect start
status: waiting for both 'good' and 'bad' commits
$ git bisect bad
status: waiting for 'good' commit(s), 'bad' commit known
$ git bisect good v1.0
Bisecting: 7 revisions left to test after this (roughly 3 steps)
[f33ede328af97e8001699778f23307b804668490] Start moving the calculator
$ git status
HEAD detached at f33ede3
You are currently bisecting, started from branch 'main'.
  (use "git bisect reset" to get back to the original branch)

nothing to commit, working tree clean
```

`git bisect bad` with no commit marks the current one, `main`. Once both ends
are known, Git checks out a commit in the middle and says how many suspects will
remain after you test it, and how many more tests that makes. `git status`
reminds you that a bisection is running.

```console
$ sh calc.sh add 2 3
sh: calc.sh: No such file or directory
$ git bisect skip
Bisecting: 6 revisions left to test after this (roughly 3 steps)
[07a8fd731f0fd3d86bb7f0dad0bb4d94ac017e3f] Finish moving the calculator
$ sh calc.sh add 2 3
-1
$ git bisect bad
Bisecting: 3 revisions left to test after this (roughly 2 steps)
[0c9d884079adbe419f01bca4e38d42341889125d] Write note 5
$ sh calc.sh add 2 3
5
$ git bisect good
Bisecting: 1 revision left to test after this (roughly 1 step)
[88a1f8400fed0337a3d510cac7230446be2d407f] Share code between add and sub
$ sh calc.sh add 2 3
-1
$ git bisect bad
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[e9253b2b2e7f9d4220aeca224bfad44622732f1b] Tidy the adder
$ sh calc.sh add 2 3
5
$ git bisect good
88a1f8400fed0337a3d510cac7230446be2d407f is the first 'bad' commit
commit 88a1f8400fed0337a3d510cac7230446be2d407f
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 15:00:00 2026 +0000

    Share code between add and sub

 calc.sh | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

The first commit offered had no calculator to test, so `git bisect skip` asked
for a different one nearby. After that, each answer halved the rest, and five
tests out of fifteen commits named `Share code between add and sub`, shown the
way `git show --stat` shows a commit. The name `Tidy the adder` sounded more
likely, which is why testing beats guessing.

> **Since Git 2.45.** The report of the first bad commit uses `git show`, so it
> follows settings such as `log.date`. Older versions print it in a fixed format.

```console
$ git bisect log
git bisect start
# status: waiting for both 'good' and 'bad' commits
# bad: [afc361a525080d9beb60303e80f8f483cada26ab] Write note 16
git bisect bad afc361a525080d9beb60303e80f8f483cada26ab
# status: waiting for 'good' commit(s), 'bad' commit known
# good: [e8f1111f38a1686197f76b79b459dd45de44e20c] Add the calculator
git bisect good e8f1111f38a1686197f76b79b459dd45de44e20c
# skip: [f33ede328af97e8001699778f23307b804668490] Start moving the calculator
git bisect skip f33ede328af97e8001699778f23307b804668490
# bad: [07a8fd731f0fd3d86bb7f0dad0bb4d94ac017e3f] Finish moving the calculator
git bisect bad 07a8fd731f0fd3d86bb7f0dad0bb4d94ac017e3f
# good: [0c9d884079adbe419f01bca4e38d42341889125d] Write note 5
git bisect good 0c9d884079adbe419f01bca4e38d42341889125d
# bad: [88a1f8400fed0337a3d510cac7230446be2d407f] Share code between add and sub
git bisect bad 88a1f8400fed0337a3d510cac7230446be2d407f
# good: [e9253b2b2e7f9d4220aeca224bfad44622732f1b] Tidy the adder
git bisect good e9253b2b2e7f9d4220aeca224bfad44622732f1b
# first 'bad' commit: [88a1f8400fed0337a3d510cac7230446be2d407f] Share code between add and sub
$ git for-each-ref refs/bisect
88a1f8400fed0337a3d510cac7230446be2d407f commit	refs/bisect/bad
0c9d884079adbe419f01bca4e38d42341889125d commit	refs/bisect/good-0c9d884079adbe419f01bca4e38d42341889125d
e8f1111f38a1686197f76b79b459dd45de44e20c commit	refs/bisect/good-e8f1111f38a1686197f76b79b459dd45de44e20c
e9253b2b2e7f9d4220aeca224bfad44622732f1b commit	refs/bisect/good-e9253b2b2e7f9d4220aeca224bfad44622732f1b
f33ede328af97e8001699778f23307b804668490 commit	refs/bisect/skip-f33ede328af97e8001699778f23307b804668490
$ git log --oneline -1
e9253b2 Tidy the adder
$ git bisect reset
Previous HEAD position was e9253b2 Tidy the adder
Switched to branch 'main'
$ git status -sb
## main
```

`git bisect log` lists every mark as a command, with the commit's subject in a
comment. Git keeps the marks as refs under `refs/bisect/`, which
`git for-each-ref` lists (Chapter 22): `refs/bisect/bad` is the first bad commit,
as Git's documentation says. The session ended where the last test left `HEAD`,
not on the bad commit; `git bisect reset` returned to `main` and removed the
bisection state.

## When you marked a commit wrongly

```console
$ git bisect good
You need to start by "git bisect start"

$ git bisect start HEAD v1.0
Bisecting: 7 revisions left to test after this (roughly 3 steps)
[f33ede328af97e8001699778f23307b804668490] Start moving the calculator
$ sh calc.sh add 2 3
sh: calc.sh: No such file or directory
$ git bisect good
Bisecting: 3 revisions left to test after this (roughly 2 steps)
[cde530bab69b79c431f20a1702c63d760ffb1035] Write note 12
```

Marks need a session first. `git bisect start HEAD v1.0` starts one and marks
both ends at once: the first commit named is bad, the rest good.

Then the untestable commit was marked `good`. Git cannot know: it trusts every
answer, so from here on it searches the wrong half, and would name a wrong
commit. Nothing needs to be started again by hand:

```console
$ git bisect log > ../bisect.log
$ cat ../bisect.log
# bad: [afc361a525080d9beb60303e80f8f483cada26ab] Write note 16
# good: [e8f1111f38a1686197f76b79b459dd45de44e20c] Add the calculator
git bisect start 'HEAD' 'v1.0'
# good: [f33ede328af97e8001699778f23307b804668490] Start moving the calculator
git bisect good f33ede328af97e8001699778f23307b804668490
$ git bisect reset
Previous HEAD position was cde530b Write note 12
Switched to branch 'main'
$ sed -i '/^git bisect good f33ede3/d' ../bisect.log
$ git bisect replay ../bisect.log
Bisecting: 7 revisions left to test after this (roughly 3 steps)
[f33ede328af97e8001699778f23307b804668490] Start moving the calculator
Bisecting: 7 revisions left to test after this (roughly 3 steps)
[f33ede328af97e8001699778f23307b804668490] Start moving the calculator
$ git bisect terms
Your current terms are 'good' for the old state
and 'bad' for the new state.
$ git bisect reset
Previous HEAD position was f33ede3 Start moving the calculator
Switched to branch 'main'
```

Save the log to a file, outside the repository so that checkouts cannot touch it,
remove the wrong line, reset, and replay the file. `sed -i '/<pattern>/d'` deletes
the matching lines in place; any editor does the same. Git's documentation gives
this procedure. The replay repeated the start and every remaining mark and
stopped where the mistake had been, ready for the right answer.

## Skipping commits

```console
$ git bisect start HEAD v1.0
Bisecting: 7 revisions left to test after this (roughly 3 steps)
[f33ede328af97e8001699778f23307b804668490] Start moving the calculator
$ sh calc.sh add 2 3
sh: calc.sh: No such file or directory
$ git bisect skip
Bisecting: 6 revisions left to test after this (roughly 3 steps)
[07a8fd731f0fd3d86bb7f0dad0bb4d94ac017e3f] Finish moving the calculator
$ sh calc.sh add 2 3
-1
$ git bisect bad
Bisecting: 3 revisions left to test after this (roughly 2 steps)
[0c9d884079adbe419f01bca4e38d42341889125d] Write note 5
$ sh calc.sh add 2 3
5
$ git bisect good
Bisecting: 1 revision left to test after this (roughly 1 step)
[88a1f8400fed0337a3d510cac7230446be2d407f] Share code between add and sub
$ git bisect skip
Bisecting: 1 revision left to test after this (roughly 1 step)
[e9253b2b2e7f9d4220aeca224bfad44622732f1b] Tidy the adder
$ sh calc.sh add 2 3
5
$ git bisect good
There are only 'skip'ped commits left to test.
The first 'bad' commit could be any of:
88a1f8400fed0337a3d510cac7230446be2d407f
f33ede328af97e8001699778f23307b804668490
07a8fd731f0fd3d86bb7f0dad0bb4d94ac017e3f
We cannot bisect more!
$ git bisect reset
Previous HEAD position was e9253b2 Tidy the adder
Switched to branch 'main'
```

This time the culprit itself was skipped. A skipped commit is not tested, so
Git could only narrow the answer down to the skipped commits between the last
good and the first bad, and listed them. Git's documentation warns of exactly
this: skip a commit next to the one you are looking for, and the exact answer is
lost. Test a skipped commit by hand if it matters.

```console
$ git bisect start HEAD v1.0
Bisecting: 7 revisions left to test after this (roughly 3 steps)
[f33ede328af97e8001699778f23307b804668490] Start moving the calculator
$ git bisect skip v1.0..main~12
Bisecting: 6 revisions left to test after this (roughly 3 steps)
[07a8fd731f0fd3d86bb7f0dad0bb4d94ac017e3f] Finish moving the calculator
$ git bisect log | grep '^git bisect skip'
git bisect skip d8c07c4dfba18a29002f1fc2f705de8920681428
git bisect skip 032ee136ca4e437976520ec9478553d5014d4282
git bisect skip c5584f9eb19d0d598201549de26e2f8e79e5ff4f
$ git bisect reset
Previous HEAD position was 07a8fd7 Finish moving the calculator
Switched to branch 'main'
```

`git bisect skip` takes commits and ranges. `v1.0..main~12` is the three notes
after `v1.0` (Chapter 18), written with `main` because during a bisection `HEAD`
is the commit being tested, not the branch. The log shows exactly those three
skipped; with fewer suspects Git chose a different commit to test. Git's
documentation adds that to skip the first commit of a range as well, you name it
separately: `git bisect skip v2.5 v2.5..v2.6`.

## Letting a script decide

```console
$ cat ../test.sh
test -f calc.sh || exit 125
test "$(sh calc.sh add 2 3)" = 5
$ git bisect start HEAD v1.0
Bisecting: 7 revisions left to test after this (roughly 3 steps)
[f33ede328af97e8001699778f23307b804668490] Start moving the calculator
$ git bisect run sh ../test.sh
running 'sh' '../test.sh'
Bisecting: 6 revisions left to test after this (roughly 3 steps)
[07a8fd731f0fd3d86bb7f0dad0bb4d94ac017e3f] Finish moving the calculator
running 'sh' '../test.sh'
Bisecting: 3 revisions left to test after this (roughly 2 steps)
[0c9d884079adbe419f01bca4e38d42341889125d] Write note 5
running 'sh' '../test.sh'
Bisecting: 1 revision left to test after this (roughly 1 step)
[88a1f8400fed0337a3d510cac7230446be2d407f] Share code between add and sub
running 'sh' '../test.sh'
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[e9253b2b2e7f9d4220aeca224bfad44622732f1b] Tidy the adder
running 'sh' '../test.sh'
88a1f8400fed0337a3d510cac7230446be2d407f is the first 'bad' commit
commit 88a1f8400fed0337a3d510cac7230446be2d407f
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 15:00:00 2026 +0000

    Share code between add and sub

 calc.sh | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
bisect found first 'bad' commit
$ git bisect reset
Previous HEAD position was e9253b2 Tidy the adder
Switched to branch 'main'
```

`git bisect run` runs the command on every commit it checks out and marks the
commit from the exit code, until it names one. The script did the same tests as
the manual session, and in the same order.

| Exit code of the command | `git bisect run` |
|---|---|
| `0` | marks the commit good |
| `1` to `127`, except `125` | marks it bad |
| `125` | skips it, because it cannot be tested |
| `126`, `127` on the starting good commit | stops: the command itself is probably missing or not executable |
| anything else, such as `128` to `255` | stops the bisection |

The table is Git's documentation. `test` exits with `0` when true and `1` when
not, which is why a one-line test is enough. The script keeps the untestable
commit out with `exit 125`. It lives outside the repository, as Git's
documentation advises, so that checking out old commits cannot change it or
make it disappear.

```console
$ git bisect start HEAD v1.0
Bisecting: 7 revisions left to test after this (roughly 3 steps)
[f33ede328af97e8001699778f23307b804668490] Start moving the calculator
$ git bisect run sh -c 'test "$(sh calc.sh add 2 3)" = 5'
running 'sh' '-c' 'test "$(sh calc.sh add 2 3)" = 5'
sh: calc.sh: No such file or directory
Bisecting: 3 revisions left to test after this (roughly 2 steps)
[d8c07c4dfba18a29002f1fc2f705de8920681428] Write note 4
running 'sh' '-c' 'test "$(sh calc.sh add 2 3)" = 5'
Bisecting: 1 revision left to test after this (roughly 1 step)
[e9253b2b2e7f9d4220aeca224bfad44622732f1b] Tidy the adder
running 'sh' '-c' 'test "$(sh calc.sh add 2 3)" = 5'
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[88a1f8400fed0337a3d510cac7230446be2d407f] Share code between add and sub
running 'sh' '-c' 'test "$(sh calc.sh add 2 3)" = 5'
88a1f8400fed0337a3d510cac7230446be2d407f is the first 'bad' commit
commit 88a1f8400fed0337a3d510cac7230446be2d407f
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 15:00:00 2026 +0000

    Share code between add and sub

 calc.sh | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
bisect found first 'bad' commit
$ git bisect reset
Previous HEAD position was 88a1f84 Share code between add and sub
Switched to branch 'main'
```

A test can be given inline with `sh -c`, as in Git's documentation. This one
has no `exit 125`, so the commit without a calculator counted as bad. The answer
came out right anyway, because the bug is older than that commit; had it been
newer, the answer would have been wrong. Say what cannot be tested.

```console
$ git bisect start HEAD v1.0
Bisecting: 7 revisions left to test after this (roughly 3 steps)
[f33ede328af97e8001699778f23307b804668490] Start moving the calculator
$ git bisect run sh ../abort.sh
running 'sh' '../abort.sh'
error: bisect run failed: exit code 200 from 'sh' '../abort.sh' is < 0 or >= 128
$ git bisect reset
Previous HEAD position was f33ede3 Start moving the calculator
Switched to branch 'main'
$ git bisect start HEAD v1.0
Bisecting: 7 revisions left to test after this (roughly 3 steps)
[f33ede328af97e8001699778f23307b804668490] Start moving the calculator
$ git bisect run ../nosuch.sh
running '../nosuch.sh'
'../nosuch.sh': line 1: ../nosuch.sh: No such file or directory
[e8f1111f38a1686197f76b79b459dd45de44e20c] Add the calculator
running '../nosuch.sh'
'../nosuch.sh': line 1: ../nosuch.sh: No such file or directory
error: bogus exit code 127 for 'good' revision
[f33ede328af97e8001699778f23307b804668490] Start moving the calculator
$ git bisect reset
Previous HEAD position was f33ede3 Start moving the calculator
Switched to branch 'main'
```

`abort.sh` exits with 200, and the bisection stopped without a mark. A command
that does not exist exits with 127 on every commit, which would mark them all
bad. Git noticed and checked the commit already marked good: it failed there too,
so Git stopped. The bisection itself is still in progress after either failure,
waiting for `git bisect reset` or a better command.

> **Since Git 2.36.** The check of the good commit when the command exits with
> 126 or 127.

## Other words for good and bad

"Good" and "bad" are confusing when you look for the commit that *fixed*
something. `new` and `old` work in their place:

```console
$ git bisect start
status: waiting for both 'good' and 'bad' commits
$ git bisect new
status: waiting for 'old' commit(s), 'new' commit known
$ git bisect old v1.0
Bisecting: 7 revisions left to test after this (roughly 3 steps)
[f33ede328af97e8001699778f23307b804668490] Start moving the calculator
$ git bisect terms
Your current terms are 'old' for the old state
and 'new' for the new state.
$ git bisect bad
error: Invalid command: you're currently in a new/old bisect
fatal: unknown command: 'bad'

usage: git bisect start [--term-(bad|new)=<term-new> --term-(good|old)=<term-old>]
                        [--no-checkout] [--first-parent] [<bad> [<good>...]] [--] [<pathspec>...]
   or: git bisect (bad|new|<term-new>) [<rev>]
   or: git bisect (good|old|<term-old>) [<rev>...]
   or: git bisect terms [--term-(good|old) | --term-(bad|new)]
   or: git bisect skip [(<rev>|<range>)...]
   or: git bisect next
   or: git bisect reset [<commit>]
   or: git bisect (visualize|view)
   or: git bisect replay <logfile>
   or: git bisect log
   or: git bisect run <cmd> [<arg>...]
   or: git bisect help

$ git bisect reset
Previous HEAD position was f33ede3 Start moving the calculator
Switched to branch 'main'
```

`new` is a commit with the property you are looking for, `old` one without it;
the first word used decides the pair, and Git's documentation says the two pairs
cannot be mixed in one session.

```console
$ git bisect start --term-new=broken --term-old=working HEAD v1.0
Bisecting: 7 revisions left to test after this (roughly 3 steps)
[f33ede328af97e8001699778f23307b804668490] Start moving the calculator
$ git bisect terms --term-bad
broken
$ git bisect terms --term-old
working
$ git bisect run sh ../test.sh
running 'sh' '../test.sh'
Bisecting: 6 revisions left to test after this (roughly 3 steps)
[07a8fd731f0fd3d86bb7f0dad0bb4d94ac017e3f] Finish moving the calculator
running 'sh' '../test.sh'
Bisecting: 3 revisions left to test after this (roughly 2 steps)
[0c9d884079adbe419f01bca4e38d42341889125d] Write note 5
running 'sh' '../test.sh'
Bisecting: 1 revision left to test after this (roughly 1 step)
[88a1f8400fed0337a3d510cac7230446be2d407f] Share code between add and sub
running 'sh' '../test.sh'
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[e9253b2b2e7f9d4220aeca224bfad44622732f1b] Tidy the adder
running 'sh' '../test.sh'
88a1f8400fed0337a3d510cac7230446be2d407f is the first 'broken' commit
commit 88a1f8400fed0337a3d510cac7230446be2d407f
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 15:00:00 2026 +0000

    Share code between add and sub

 calc.sh | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
bisect found first 'broken' commit
$ git bisect reset
Previous HEAD position was e9253b2 Tidy the adder
Switched to branch 'main'
$ git bisect start --term-old=reset --term-new=wrong
error: can't use the builtin command 'reset' as a term
```

With `--term-new` and `--term-old` you choose the words, and then type
`git bisect broken` and `git bisect working`. `git bisect run` works the same
way, exit code 0 still meaning the old state, and the report used the new word.
`git bisect terms` prints both, or one with `--term-bad` or `--term-old`; Git's
documentation gives `--term-new` and `--term-good` as other spellings. A
subcommand's name cannot be a term.

| To find | Mark as new, or bad | Mark as old, or good |
|---|---|---|
| the commit that broke something | commits where it is broken | commits where it works |
| the commit that fixed something | commits where it works | commits where it is broken |
| when anything changed | commits after the change | commits before it |

## Fewer commits to test

```console
$ git bisect start HEAD v1.0 HEAD~11
Already on 'main'
Bisecting: 5 revisions left to test after this (roughly 3 steps)
[d0023a078144634b7900587212858d42e69a1da8] Write note 10
$ git bisect reset
Previous HEAD position was d0023a0 Write note 10
Switched to branch 'main'
$ git bisect start HEAD v1.0 -- calc.sh
Bisecting: 1 revision left to test after this (roughly 1 step)
[88a1f8400fed0337a3d510cac7230446be2d407f] Share code between add and sub
$ git bisect run sh ../test.sh
running 'sh' '../test.sh'
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[e9253b2b2e7f9d4220aeca224bfad44622732f1b] Tidy the adder
running 'sh' '../test.sh'
88a1f8400fed0337a3d510cac7230446be2d407f is the first 'bad' commit
commit 88a1f8400fed0337a3d510cac7230446be2d407f
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 15:00:00 2026 +0000

    Share code between add and sub

 calc.sh | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
bisect found first 'bad' commit
$ git bisect reset
Previous HEAD position was e9253b2 Tidy the adder
Switched to branch 'main'
```

Every good commit you already know removes its history from the search:
`HEAD~11`, `Write note 5`, left 5 suspects instead of 7. Paths after `--` limit
the search to commits that touched them, here the four that changed `calc.sh`,
and two tests were enough. That is safe only when you know the bug is in those
paths.

```console
$ git bisect start HEAD v1.0
Bisecting: 7 revisions left to test after this (roughly 3 steps)
[f33ede328af97e8001699778f23307b804668490] Start moving the calculator
$ git log --oneline --bisect
afc361a Write note 16
b5d4ac3 Write note 15
93e3d3e Write note 14
c98edb1 Write note 13
cde530b Write note 12
d28dcd5 Write note 11
d0023a0 Write note 10
07a8fd7 Finish moving the calculator
f33ede3 Start moving the calculator
88a1f84 Share code between add and sub
e9253b2 Tidy the adder
0c9d884 Write note 5
d8c07c4 Write note 4
032ee13 Write note 3
c5584f9 Write note 2
$ git bisect visualize --oneline
afc361a Write note 16
b5d4ac3 Write note 15
93e3d3e Write note 14
c98edb1 Write note 13
cde530b Write note 12
d28dcd5 Write note 11
d0023a0 Write note 10
07a8fd7 Finish moving the calculator
f33ede3 Start moving the calculator
88a1f84 Share code between add and sub
e9253b2 Tidy the adder
0c9d884 Write note 5
d8c07c4 Write note 4
032ee13 Write note 3
c5584f9 Write note 2
$ git bisect view shortlog
Ada Lovelace (15):
      Write note 2
      Write note 3
      Write note 4
      Write note 5
      Tidy the adder
      Share code between add and sub
      Start moving the calculator
      Finish moving the calculator
      Write note 10
      Write note 11
      Write note 12
      Write note 13
      Write note 14
      Write note 15
      Write note 16

```

`git log --bisect` lists the commits still in question: the bad commit and
everything back to the good ones. `git bisect visualize`, or `view`, shows the
same list.

| Form | Runs |
|---|---|
| `git bisect visualize` | `gitk` if a graphical environment is detected and `gitk` is installed, otherwise `git log` |
| `git bisect visualize --<option>...` | `git log` with those options |
| `git bisect visualize <command>...` | that Git command, such as `git shortlog` (Chapter 22) |

Git's documentation lists the environment variables that count as graphical:
`DISPLAY`, `SESSIONNAME`, `MSYSTEM` and `SECURITYSESSIONID`. The third and last
rows come from Git's source. Each form is given `--bisect`, and the paths from
`git bisect start`.

> **Windows.** Git Bash sets `MSYSTEM`, so plain `git bisect visualize` opens
> `gitk` in a separate window when it is installed, as it is with Git for Windows.
> Give an option, such as `--oneline`, to stay in the terminal.

## Testing without checking out

```console
$ git bisect start --no-checkout HEAD v1.0
Bisecting: 7 revisions left to test after this (roughly 3 steps)
[f33ede328af97e8001699778f23307b804668490] Start moving the calculator
$ git log --oneline -1
afc361a Write note 16
$ git log --oneline -1 BISECT_HEAD
f33ede3 Start moving the calculator
$ git status -sb
## main
$ git bisect run sh -c 'git cat-file -e BISECT_HEAD:calc.sh || exit 125; git show BISECT_HEAD:calc.sh | grep -q "2 + \$3"'
running 'sh' '-c' 'git cat-file -e BISECT_HEAD:calc.sh || exit 125; git show BISECT_HEAD:calc.sh | grep -q "2 + \$3"'
fatal: path 'calc.sh' exists on disk, but not in 'BISECT_HEAD'
Bisecting: 6 revisions left to test after this (roughly 3 steps)
[07a8fd731f0fd3d86bb7f0dad0bb4d94ac017e3f] Finish moving the calculator
running 'sh' '-c' 'git cat-file -e BISECT_HEAD:calc.sh || exit 125; git show BISECT_HEAD:calc.sh | grep -q "2 + \$3"'
Bisecting: 3 revisions left to test after this (roughly 2 steps)
[0c9d884079adbe419f01bca4e38d42341889125d] Write note 5
running 'sh' '-c' 'git cat-file -e BISECT_HEAD:calc.sh || exit 125; git show BISECT_HEAD:calc.sh | grep -q "2 + \$3"'
Bisecting: 1 revision left to test after this (roughly 1 step)
[88a1f8400fed0337a3d510cac7230446be2d407f] Share code between add and sub
running 'sh' '-c' 'git cat-file -e BISECT_HEAD:calc.sh || exit 125; git show BISECT_HEAD:calc.sh | grep -q "2 + \$3"'
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[e9253b2b2e7f9d4220aeca224bfad44622732f1b] Tidy the adder
running 'sh' '-c' 'git cat-file -e BISECT_HEAD:calc.sh || exit 125; git show BISECT_HEAD:calc.sh | grep -q "2 + \$3"'
88a1f8400fed0337a3d510cac7230446be2d407f is the first 'bad' commit
commit 88a1f8400fed0337a3d510cac7230446be2d407f
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 15:00:00 2026 +0000

    Share code between add and sub

 calc.sh | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
bisect found first 'bad' commit
$ git bisect reset
```

With `--no-checkout`, `HEAD` and the working tree stay on `main`, and the commit to
test is `BISECT_HEAD` instead (Chapter 18). The test must then read that commit
directly: `git cat-file -e` checks that the file exists in it (Chapter 6), and
`git show BISECT_HEAD:calc.sh` prints it, here searched with `grep` for the
correct sum. It suits tests that do not need to run the code; Git's documentation
adds that in a bare repository, which has no working tree, `--no-checkout` is
assumed.

## Moving about during a bisection

```console
$ git bisect start HEAD v1.0
Bisecting: 7 revisions left to test after this (roughly 3 steps)
[f33ede328af97e8001699778f23307b804668490] Start moving the calculator
$ git switch --detach HEAD~2
warning: you are switching branch while bisecting
Previous HEAD position was f33ede3 Start moving the calculator
HEAD is now at e9253b2 Tidy the adder
$ git bisect next
Bisecting: 7 revisions left to test after this (roughly 3 steps)
[f33ede328af97e8001699778f23307b804668490] Start moving the calculator
$ git bisect good HEAD~3
Bisecting: 5 revisions left to test after this (roughly 3 steps)
[d0023a078144634b7900587212858d42e69a1da8] Write note 10
$ git bisect bad HEAD~1
Bisecting: 1 revision left to test after this (roughly 1 step)
[88a1f8400fed0337a3d510cac7230446be2d407f] Share code between add and sub
$ git bisect reset bisect/bad
Previous HEAD position was 88a1f84 Share code between add and sub
HEAD is now at 07a8fd7 Finish moving the calculator
$ git log --oneline -1
07a8fd7 Finish moving the calculator
$ git switch main
Previous HEAD position was 07a8fd7 Finish moving the calculator
Switched to branch 'main'
```

You may check out another commit and test that instead; Git's documentation
suggests it for a commit that is awkward to test, and Git warns when you do.
`git bisect next` went back to the commit Git had chosen. `good` and `bad` take a
commit, so you can mark commits you have tested before, without checking them out.

`git bisect reset <commit>` ends the session on that commit instead of the
original branch: `bisect/bad` is the bad commit found so far, and Git's
documentation gives `git bisect reset HEAD` for staying where you are.

```console
$ git bisect start v1.0 HEAD
Some 'good' revs are not ancestors of the 'bad' rev.
git bisect cannot work properly in this case.
Maybe you mistook 'good' and 'bad' revs?
$ git bisect reset
$ git bisect
fatal: need a command

usage: git bisect start [--term-(bad|new)=<term-new> --term-(good|old)=<term-old>]
                        [--no-checkout] [--first-parent] [<bad> [<good>...]] [--] [<pathspec>...]
   or: git bisect (bad|new|<term-new>) [<rev>]
   or: git bisect (good|old|<term-old>) [<rev>...]
   or: git bisect terms [--term-(good|old) | --term-(bad|new)]
   or: git bisect skip [(<rev>|<range>)...]
   or: git bisect next
   or: git bisect reset [<commit>]
   or: git bisect (visualize|view)
   or: git bisect replay <logfile>
   or: git bisect log
   or: git bisect run <cmd> [<arg>...]
   or: git bisect help

```

The bad commit comes first: `git bisect start v1.0 HEAD` made the newest commit
good, which cannot be. `git bisect` on its own prints the usage, and Git's
documentation says `git bisect help` and `git bisect -h` print it too.

## Merges

A branch rewrote the adder and was merged into `main`:

```console
$ git log --oneline --graph
* 9e8987f Write note 4
* d022e3e Write note 3
*   05c5cfe Merge the new adder
|\  
| * 7cfcbc3 Document the new adder
| * b6cb870 Rewrite the adder
* | 8e59970 Write note 2
|/  
* 6974d63 Write note 1
* e8f1111 Add the calculator
$ git bisect start HEAD v1.0
Bisecting: 3 revisions left to test after this (roughly 2 steps)
[7cfcbc3a5657a68220b052c0798d570dc7cc6b1c] Document the new adder
$ git bisect run sh ../test.sh
running 'sh' '../test.sh'
Bisecting: 0 revisions left to test after this (roughly 1 step)
[b6cb870c5aea7a8f5eb1fb0e5d01eec92514c162] Rewrite the adder
running 'sh' '../test.sh'
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[6974d6325f0b6a42615a5794cddff279c2e55943] Write note 1
running 'sh' '../test.sh'
b6cb870c5aea7a8f5eb1fb0e5d01eec92514c162 is the first 'bad' commit
commit b6cb870c5aea7a8f5eb1fb0e5d01eec92514c162
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 11:00:00 2026 +0000

    Rewrite the adder

 calc.sh | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
bisect found first 'bad' commit
$ git bisect reset
Previous HEAD position was 6974d63 Write note 1
Switched to branch 'main'
$ git bisect start --first-parent HEAD v1.0
Bisecting: 2 revisions left to test after this (roughly 1 step)
[8e59970eb4935c1bcf6c2c150357fbe098ed6243] Write note 2
$ git bisect run sh ../test.sh
running 'sh' '../test.sh'
Bisecting: 0 revisions left to test after this (roughly 1 step)
[d022e3edbdd9e125851863c710b04846c40978c4] Write note 3
running 'sh' '../test.sh'
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[05c5cfe83cdead7750fd369c2d4e894963d774e7] Merge the new adder
running 'sh' '../test.sh'
05c5cfe83cdead7750fd369c2d4e894963d774e7 is the first 'bad' commit
commit 05c5cfe83cdead7750fd369c2d4e894963d774e7
Merge: 8e59970 7cfcbc3
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 5 14:00:00 2026 +0000

    Merge the new adder

 calc.sh  | 2 +-
 docs.txt | 1 +
 2 files changed, 2 insertions(+), 1 deletion(-)
 create mode 100644 docs.txt
bisect found first 'bad' commit
$ git bisect reset
Previous HEAD position was 05c5cfe Merge the new adder
Switched to branch 'main'
```

Plain bisect searched the branch too and named the commit that wrote the bug.
`--first-parent` tested only commits on `main`'s own line and named the merge
that brought the bug in, whose changes were then shown against `main`
(Chapter 17). Git's documentation recommends it when a merged branch had commits
that were broken or would not build, but the merge was fine, so that those
commits cannot mislead the search.

> **Since Git 2.29.** `git bisect start --first-parent`.

## bisect and its neighbours

| Command | Finds | Needs |
|---|---|---|
| `git bisect` | the first commit where a test fails | a test you can run on any commit |
| `git blame <file>` | the last commit that changed each line (Chapter 19) | to know which line is wrong |
| `git log -S <text>`, `git log -G <regex>` | commits that added or removed some text (Chapter 21) | to know what the bad code looks like |
| `git log -L <range>:<file>` | every commit that changed some lines (Chapter 17) | to know where the bug is |

Bisect is the one that needs no idea where the bug is, only a way to tell good
from bad. When you do know the line, `git blame` is faster.
