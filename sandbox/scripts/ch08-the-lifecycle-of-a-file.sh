#!/bin/bash
# Generates every transcript in Chapter 8, "The Lifecycle of a File".
#
#   bash sandbox/scripts/ch08-the-lifecycle-of-a-file.sh [dir]

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
sb_fresh "$SANDBOX_ROOT/lifecycle" >/dev/null

sb_say "--- 1. untracked ---"
sb_run "echo one > draft.txt && git status --short"

sb_say "--- 2. staged for the first time: added ---"
sb_run git add draft.txt
sb_run git status --short

sb_say "--- 3. committed: tracked and unmodified ---"
sb_run "git commit -q -m 'Add draft'"
sb_tick
sb_run git status --short
sb_run git ls-files

sb_say "--- 4. modified, then staged, then committed again ---"
sb_run "echo two >> draft.txt && git status --short"
sb_run git add draft.txt
sb_run git status --short
sb_run "git commit -q -m 'Extend draft'"
sb_tick
sb_run git status --short

sb_say "--- 5. deleting from disk is a change like any other ---"
sb_run "rm draft.txt && git status --short"
sb_run git status

sb_say "--- 6. and it can be undone as long as it is not committed ---"
sb_run git restore draft.txt
sb_run git status --short
sb_run cat draft.txt

sb_say "--- 7. git rm deletes and stages in one step ---"
sb_run git rm draft.txt
sb_run git status --short
sb_run "ls"
sb_run git restore --staged draft.txt
sb_run git status --short
sb_run git restore draft.txt
sb_run git status --short

sb_say "--- 7b. git rm refuses a file with unstaged changes ---"
sb_write draft.txt "one" "two" "three"
sb_run git rm draft.txt || true
git restore draft.txt

sb_say "--- 8. an ignored file never reaches the untracked list ---"
sb_write .gitignore "*.log"
sb_commit "Ignore log files"
sb_write debug.log "noise"
sb_run "cat .gitignore && ls"
sb_run git status --short
sb_run git status --short --ignored
sb_run git check-ignore -v debug.log

sb_say "--- 9. the trap: ignoring a file that is already tracked ---"
sb_run "echo hunter2 > secrets.txt && git add secrets.txt && git commit -q -m 'Add secrets by mistake'"
sb_tick
sb_run "printf '*.log\nsecrets.txt\n' > .gitignore"
sb_run "echo 'changed anyway' >> secrets.txt"
sb_run git status --short
sb_run git check-ignore -v secrets.txt || true
sb_run git check-ignore -v --no-index secrets.txt
sb_run git ls-files

sb_say "--- 10. untracking without deleting ---"
sb_run git rm --cached secrets.txt
sb_run git status --short
sb_run "ls"
sb_run "git add .gitignore && git commit -q -m 'Stop tracking secrets.txt'"
sb_tick
sb_run git status --short
sb_run git ls-files

sb_say "--- 11. the file is gone from the tip but not from history ---"
sb_run "git cat-file -p HEAD^{tree}"
sb_run "git log --oneline -- secrets.txt"
sb_run "git cat-file -p HEAD~1:secrets.txt"

sb_say "--- 12. pretending a tracked file has not changed ---"
sb_write config.ini "debug = false"
sb_commit "Add config"
sb_run git update-index --skip-worktree config.ini
sb_run "echo 'debug = true' > config.ini"
sb_run git status --short
sb_run "git ls-files -v | grep config"
sb_run git update-index --no-skip-worktree config.ini
sb_run git status --short

sb_say "--- 13. finding files with either bit set ---"
sb_run git update-index --assume-unchanged config.ini
sb_run "git ls-files -v | grep -v '^H'"
sb_run git update-index --no-assume-unchanged config.ini
