#!/bin/bash
# Generates every transcript in Chapter 10, "status".
#
#   bash sandbox/scripts/ch10-status.sh [dir]

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
git init -q --bare "$SANDBOX_ROOT/server.git"
sb_fresh "$SANDBOX_ROOT/work" >/dev/null

sb_write README.md "# Project"
sb_write app.py "print('hello')"
sb_write notes.md "notes"
sb_write build/out.log "noise"
sb_write .gitignore "build/"
sb_commit "Initial commit"
git remote add origin "$SANDBOX_ROOT/server.git"
git push -q -u origin main

sb_say "--- 1. a clean tree ---"
sb_run git status
sb_run git status --short
sb_run git status -sb

sb_say "--- 2. every kind of change at once ---"
sb_write README.md "# Project" "Now with more words."
git add README.md
sb_write README.md "# Project" "Now with more words." "And more still."
sb_write app.py "print('hello')" "print('world')"
git mv notes.md docs.md
rm -f .gitignore
sb_write newfile.txt "brand new"
sb_write build/another.log "more noise"
sb_run git status
sb_run git status --short

sb_say "--- 3. the branch header ---"
sb_run git status -sb
sb_run git status --short --branch --ahead-behind

sb_say "--- 4. machine-readable output ---"
sb_run git status --porcelain
sb_run git status --porcelain=v1
sb_run "git status --porcelain=v2 --branch"

sb_say "--- 5. how much to say about untracked files ---"
sb_write extra/one.txt "a"
sb_write extra/two.txt "b"
sb_run "git status --short --untracked-files=normal"
sb_run "git status --short --untracked-files=all"
sb_run "git status --short --untracked-files=no"
sb_run git status -uno

sb_say "--- 6. ignored files ---"
git checkout -q -- .gitignore 2>/dev/null || git restore .gitignore
sb_run git status --short
sb_run git status --short --ignored
sb_run "git status --short --ignored=matching"

sb_say "--- 7. ahead and behind a remote ---"
git add -A >/dev/null && git commit -q -m "Work in progress" && sb_tick
sb_run git status -sb
sb_run git status
sb_run "git log --oneline origin/main..HEAD"

sb_say "--- 8. detached HEAD ---"
sb_run git switch -q --detach HEAD~1
sb_run git status
sb_run git status -sb
sb_run git switch -q -

sb_say "--- 9. during a conflict ---"
git switch -q -c other HEAD~1
sb_write app.py "print('hello')" "print('from other')"
sb_commit "Change app on other"
git switch -q main
sb_run "git merge other" || true
sb_run git status
sb_run git status --short
sb_run git status -sb
sb_run "git ls-files --stage app.py"
sb_run git merge --abort
sb_run git status --short

sb_say "--- 10. during a rebase ---"
sb_run "git rebase other" || true
sb_run git status
sb_run git rebase --abort
sb_run git status -sb
