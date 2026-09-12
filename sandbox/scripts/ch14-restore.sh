#!/bin/bash
# Generates every transcript in Chapter 14, "Undoing Local Changes with restore".
#
#   bash sandbox/scripts/ch14-restore.sh [dir]

set -euo pipefail
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
