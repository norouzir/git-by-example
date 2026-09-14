#!/bin/bash
# Generates every transcript in Chapter 14, "Undoing Local Changes with restore".
#
#   bash sandbox/scripts/ch14-restore.sh [dir]
#
# No `set -e`: several commands shown here fail on purpose, such as restoring
# an unmerged path or cleaning without -f, and the transcript must carry on.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
sb_fresh "$SANDBOX_ROOT/undoing" >/dev/null

sb_write a.txt "original a"
sb_write b.txt "original b"
sb_write c.txt "original c"
sb_commit "First commit"
sb_write a.txt "second version of a"
sb_commit "Second commit"

sb_say "--- 1. throwing away an unstaged edit ---"
sb_write a.txt "a mistake"
sb_run git status --short
sb_run git restore a.txt
sb_run git status --short
sb_run cat a.txt

sb_say "--- 2. unstaging without losing the edit ---"
sb_write b.txt "a good edit"
git add b.txt
sb_run git status --short
sb_run git restore --staged b.txt
sb_run git status --short
sb_run cat b.txt

sb_say "--- 3. the two flags, and both at once ---"
sb_write c.txt "staged change"
git add c.txt
sb_write c.txt "staged change" "and an unstaged one"
sb_run git status --short
sb_run git restore --staged --worktree c.txt
sb_run git status --short
sb_run cat c.txt

sb_say "--- 4. restoring from somewhere other than the index ---"
sb_run git log --oneline
sb_run "git restore --source=HEAD~1 a.txt"
sb_run git status --short
sb_run cat a.txt
sb_run git diff
sb_run "git restore --source=HEAD a.txt"
sb_run git status --short

sb_say "--- 5. bringing back a file you deleted ---"
rm b.txt
sb_run git status --short
sb_run git restore b.txt
sb_run "ls"
sb_run git status --short

sb_say "--- 6. and one you deleted and staged ---"
git rm -q b.txt
sb_run git status --short
sb_run git restore --staged --worktree b.txt
sb_run git status --short
sb_run cat b.txt

sb_say "--- 7. restoring everything ---"
sb_write a.txt "mess"
sb_write b.txt "mess"
sb_write c.txt "mess"
sb_run git status --short
sb_run "git restore ."
sb_run git status --short

sb_say "--- 8. choosing hunks to throw away ---"
sb_write poem.txt "one" "two" "three" "four" "five" "six" "seven" "eight" "nine" "ten"
sb_commit "Add poem"
sb_write poem.txt "ONE" "two" "three" "four" "five" "six" "seven" "eight" "nine" "TEN"
sb_run "printf 'y\nn\n' | git restore -p poem.txt"
sb_run cat poem.txt
sb_run git checkout -q -- poem.txt

sb_say "--- 9. what it refuses to do ---"
sb_run git restore no-such-file.txt || true
sb_run "ls poem.txt"
sb_run "git log --oneline -- poem.txt"
sb_run "git restore --source=HEAD~1 poem.txt" || true
sb_run "ls poem.txt" || true
sb_run git status --short
sb_run "git restore --staged --source=HEAD~1 poem.txt" || true
sb_run git status --short
sb_run git restore --staged poem.txt
sb_run git restore poem.txt
sb_run "ls poem.txt"

sb_say "--- 10. untracked files are not its problem ---"
sb_write junk.txt "not tracked"
sb_write build/output.o "artifact"
sb_run git status --short
sb_run "git restore ."
sb_run git status --short
sb_run "git clean -n"
sb_run "git clean -nd"
sb_run "git clean -fd"
sb_run git status --short

sb_say "--- 11. the classic equivalents ---"
sb_write a.txt "changed again"
git add a.txt
sb_run "git reset HEAD a.txt"
sb_run git status --short
sb_run "git checkout -- a.txt"
sb_run git status --short

# =============================================================================
# Everything below runs in repositories of its own, so nothing above changes.

sb_say "--- Q1. short forms, new files, and no path ---"
sb_fresh "$SANDBOX_ROOT/short" >/dev/null
sb_write a.txt "a"
sb_commit "Base"
sb_write a.txt "a2"
git add a.txt
sb_write a.txt "a3"
sb_run "git status --short"
sb_run "git restore -SW a.txt && git status --short"
sb_write a.txt "a2"
git add a.txt
sb_run "git restore -s@ -SW a.txt && git status --short"
sb_write new.txt "new"
sb_run "git add new.txt && git status --short"
sb_run "git restore --staged new.txt && git status --short"
sb_run "git restore"

sb_say "--- Q2. choosing the source ---"
sb_fresh "$SANDBOX_ROOT/source" >/dev/null
sb_write a.txt "v1"
sb_write dir/x.txt "x1"
sb_commit "One"
git switch -q -c other
sb_write a.txt "from other"
sb_commit "On other"
git switch -q main
sb_write a.txt "v2"
sb_write dir/y.txt "y2"
sb_commit "Two"
sb_run "git restore --source=other a.txt && cat a.txt"
sb_run "git restore --source=main...other a.txt && cat a.txt"
sb_run "git restore -s ...other a.txt && cat a.txt"
sb_run "git restore --source=HEAD~1 --staged a.txt && git status --short"
sb_run "git restore -SW a.txt"
sb_run "git restore --source=nonexistent a.txt"
sb_run "git restore --source=HEAD~1 dir && git status --short"
sb_run "git restore dir"
sb_run "git restore --source=HEAD~1 --overlay dir && git status --short && ls dir"
sb_run "git checkout HEAD~1 -- dir && git status --short && ls dir"

sb_say "--- Q3. a file deleted long ago, globs, and where you stand ---"
sb_fresh "$SANDBOX_ROOT/deleted" >/dev/null
sb_write keep.txt "keep"
sb_write old.txt "old content"
sb_write src/a.c "a"
sb_write src/b.c "b"
sb_commit "Base"
git rm -q old.txt
git commit -q -m "Remove old.txt"
sb_tick
sb_write keep.txt "keep, edited"
sb_commit "Later"
sb_run "git log --oneline --diff-filter=D -- old.txt"
sb_run "git restore --source=HEAD~1^ old.txt && cat old.txt && git status --short"
rm old.txt
rm src/a.c src/b.c
sb_run "git status --short"
sb_run "git restore 'src/*.c' && git status --short"
rm src/a.c
sb_write keep.txt "keep, changed again"
sb_run "cd src"
cd src
sb_run "git restore . && git status --short"
sb_run "git restore :/ && git status --short"
cd ..

sb_say "--- Q4. choosing hunks, in every direction ---"
sb_fresh "$SANDBOX_ROOT/hunks" >/dev/null
sb_write poem.txt one two three four five six seven eight nine ten
sb_commit "Add poem"
sb_write poem.txt ONE two three four five six seven eight nine TEN
sb_run "git add poem.txt"
sb_run "printf 'y\nn\n' | git restore --staged -p poem.txt"
sb_run "git status --short && git diff --staged --stat"
sb_run "git add poem.txt"
sb_run "printf 'y\nn\n' | git restore -SW -p poem.txt"
sb_run "git status --short && head -1 poem.txt"
sb_run "git restore --staged poem.txt"
sb_run "printf 'y\ny\n' | git restore -SW -p poem.txt"
sb_run "git status --short && tail -1 poem.txt"
sb_run "git restore poem.txt"
sb_write poem.txt ONE two three four five six seven eight nine TEN
sb_commit "Capitals"
sb_run "printf 'y\nn\n' | git restore --source=HEAD~1 -p poem.txt && cat poem.txt"
sb_run "git restore poem.txt"
sb_write poem.txt one two three four five six seven eight nine ten
sb_run "printf 'n\nn\n' | git restore -p -U1 poem.txt"
sb_run "printf 'n\n' | git restore -p --inter-hunk-context=4 poem.txt"
sb_run "printf 'n\nn\n' | git restore -p"

sb_say "--- Q5. conflicts ---"
sb_fresh "$SANDBOX_ROOT/conflict" >/dev/null
sb_write app.py "start" "shared" "end"
sb_write other.py "other"
sb_commit "Base"
git switch -q -c side
sb_write app.py "start" "common" "from side" "end"
sb_commit "Side"
git switch -q main
sb_write app.py "start" "common" "from main" "end"
sb_commit "Main"
sb_run "git merge side"
sb_run "cat app.py"
sb_run "git restore --ours app.py && cat app.py && git status --short"
sb_run "git restore --theirs app.py && cat app.py"
sb_run "git restore -2 app.py && sed -n 3p app.py"
sb_run "git restore -3 app.py && sed -n 3p app.py"
sb_run "git restore -m app.py && cat app.py"
sb_run "git restore --conflict=diff3 app.py && cat app.py"
sb_run "git restore --conflict=zdiff3 app.py && cat app.py"
sb_run "git restore --conflict=merge app.py && cat app.py"
sb_run "git restore --conflict=tidy app.py"
sb_run "git restore --ours --source=HEAD app.py"
sb_write other.py "other, changed"
sb_run "git restore app.py other.py"
sb_run "git status --short"
sb_run "git restore --ignore-unmerged app.py other.py && git status --short"
sb_write other.py "other, changed"
sb_run "git restore -q --ignore-unmerged app.py other.py && git status --short"
sb_write app.py "start" "common" "resolved" "end"
sb_run "git add app.py && git status --short"
sb_run "git restore -m app.py && git status --short && cat app.py"
sb_run "git merge --abort"

sb_say "--- Q6. paths from a file, and sparse checkouts ---"
sb_fresh "$SANDBOX_ROOT/listsparse" >/dev/null
sb_write a.txt "a"
sb_write b.txt "b"
sb_write keep/k.txt "k"
sb_write other/o.txt "o"
sb_commit "Base"
sb_write a.txt "a, changed"
sb_write b.txt "b, changed"
sb_run "printf 'a.txt\n' | git restore --pathspec-from-file=- && git status --short"
sb_run "printf 'b.txt\0' | git restore --pathspec-from-file=- --pathspec-file-nul && git status --short"
sb_run "git sparse-checkout set keep && ls"
sb_run "git restore other/o.txt"
sb_run "git restore --ignore-skip-worktree-bits other/o.txt && ls other"

sb_say "--- Q7. git clean in full ---"
sb_fresh "$SANDBOX_ROOT/clean" >/dev/null
sb_write .gitignore "*.log" "venv/"
sb_write keep.txt "keep"
sb_commit "Base"
sb_write notes.txt "notes"
sb_write draft.md "draft"
sb_write debug.log "log"
sb_write venv/lib.py "library"
sb_write build/out.o "object"
sb_write src/tmp.txt "scratch"
sb_write src/main.c "main"
git add src/main.c
git commit -q -m "Add main.c"
sb_tick
git init -q nested
(cd nested && sb_write f.txt "f" && git add f.txt && git commit -q -m "Nested")
mkdir empty
sb_run "git clean"
sb_run "git clean -n"
sb_run "git clean -nd"
sb_run "git clean -ndx"
sb_run "git clean -ndX"
sb_run "git clean -nd -e '*.md'"
sb_run "git clean -ndx -e '*.log'"
sb_run "git clean -n draft.md build"
sb_run "cd src"
cd src
sb_run "git clean -n"
cd ..
sb_run "git clean -fd nested && ls -d nested"
sb_run "git clean -ffd nested"
sb_run "git clean -fq notes.txt && git status --short"
sb_run "git -c clean.requireForce=false clean draft.md"
sb_run "printf '4\ny\nn\nn\n' | git clean -id"
sb_run "git status --short --ignored"
sb_run "printf '2\n*.log\n\n5\n' | git clean -idx"
sb_run "printf '3\n2\n\n1\n' | git clean -idx"
sb_run "git status --short --ignored"

sb_say "--- Q8. where the classic forms differ ---"
sb_fresh "$SANDBOX_ROOT/classic" >/dev/null
sb_write notes "first notes"
sb_write a.txt "v1"
sb_commit "Base"
git branch notes
sb_write a.txt "v2"
sb_commit "Second"
sb_run "git branch"
sb_write notes "notes, edited"
sb_run "git checkout notes"
sb_run "git branch --show-current && git status --short"
sb_run "git checkout -- notes && cat notes"
sb_run "git switch -q main"
sb_write notes "notes, edited"
sb_run "git restore notes && cat notes"
sb_run "git restore --source=HEAD~1 a.txt && git status --short"
sb_run "git restore a.txt"
sb_run "git checkout HEAD~1 -- a.txt && git status --short"
