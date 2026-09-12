#!/bin/bash
# Generates every transcript in Chapter 15, "rm and mv".
#
#   bash sandbox/scripts/ch15-rm-and-mv.sh [dir]

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
sb_fresh "$SANDBOX_ROOT/moving" >/dev/null

sb_write keep.txt "keep me"
sb_write doomed.txt "delete me"
sb_write logs/one.log "log one"
sb_write logs/two.log "log two"
sb_write src/main.py "print(1)"
sb_commit "Initial commit"

sb_say "--- 1. git rm ---"
sb_run git rm doomed.txt
sb_run git status --short
sb_run "ls"
sb_commit "Remove doomed.txt"

sb_say "--- 2. a dry run first ---"
sb_run "git rm -r -n logs"
sb_run "ls logs"

sb_say "--- 3. directories need -r ---"
sb_run git rm logs || true
sb_run "git rm -r logs"
sb_run git status --short
sb_run "ls"
sb_run git restore --staged --worktree .
sb_run "ls logs"

sb_say "--- 4. rm refuses when the file has unstaged changes ---"
sb_write keep.txt "keep me" "edited"
sb_run git rm keep.txt || true
sb_run git status --short
sb_run "git rm -f keep.txt"
sb_run git status --short
sb_run git restore --staged --worktree keep.txt
sb_run cat keep.txt

sb_say "--- 5. and when the change is staged ---"
sb_write keep.txt "keep me" "staged edit"
git add keep.txt
sb_run git rm keep.txt || true
sb_run "git rm -f keep.txt"
sb_run git restore --staged --worktree keep.txt

sb_say "--- 6. untracking without deleting ---"
sb_run "git rm --cached src/main.py"
sb_run git status --short
sb_run "ls src"
sb_run git restore --staged src/main.py
sb_run git status --short

sb_say "--- 7. rm on something Git does not track ---"
sb_write untracked.txt "hello"
sb_run git rm untracked.txt || true
sb_run "git rm --ignore-unmatch untracked.txt; echo exit=\$?"
rm -f untracked.txt

sb_say "--- 8. git mv ---"
sb_run git mv src/main.py src/app.py
sb_run git status --short
sb_run "ls src"
sb_run git commit -q -m "'Rename main to app'"
sb_tick
sb_run git show --stat --oneline HEAD

sb_say "--- 9. mv is three commands in one ---"
sb_run "mv src/app.py src/program.py"
sb_run git status --short
sb_run "git add -A && git status --short"
sb_run git restore --staged --worktree .
sb_run "ls src"

sb_say "--- 10. mv will not overwrite without -f ---"
sb_write other.txt "already here"
sb_commit "Add other.txt"
sb_run "git mv keep.txt other.txt" || true
sb_run "git mv -f keep.txt other.txt"
sb_run git status --short
sb_run cat other.txt
sb_run git restore --staged --worktree .
sb_run "ls"

sb_say "--- 11. mv errors ---"
sb_run "git mv no-such.txt anywhere.txt" || true
sb_write plain.txt "not added yet"
sb_run "git mv plain.txt renamed.txt" || true
rm -f plain.txt

sb_say "--- 12. changing only the case of a name ---"
sb_run "git config get core.ignorecase" || true
sb_say "    first with the shell's own mv"
sb_run "mv keep.txt KEEP.TXT"
sb_run git status --short
sb_run "ls KEEP.TXT"
sb_run "mv KEEP.TXT keep.txt"
sb_say "    now with git mv"
sb_run "git mv keep.txt KEEP.TXT" || true
sb_run git ls-files
sb_run "git mv -f keep.txt KEEP.TXT" || true
sb_run git status --short
sb_run git ls-files
