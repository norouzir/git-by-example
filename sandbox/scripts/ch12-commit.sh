#!/bin/bash
# Generates every transcript in Chapter 12, "commit".
#
#   bash sandbox/scripts/ch12-commit.sh [dir]

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
sb_fresh "$SANDBOX_ROOT/committing" >/dev/null

sb_say "--- 1. the plain form and what it reports ---"
sb_write app.py "print('hello')"
git add app.py
sb_run git commit -m "'Add the app'"
sb_tick
sb_run git log --oneline

sb_say "--- 2. nothing staged ---"
sb_run git commit -m "'Nothing here'" || true
sb_write app.py "print('hello')" "print('world')"
sb_run git commit -m "'Still nothing staged'" || true

sb_say "--- 3. committing everything tracked ---"
sb_write untracked.txt "new"
sb_run git commit -am "'Extend the app'" || true
sb_tick
sb_run git status --short
sb_run git show --stat --oneline HEAD

sb_say "--- 4. what the editor would have shown you ---"
git add untracked.txt
sb_run "GIT_EDITOR='cat' git commit" || true
sb_run git status --short

sb_say "--- 5. a multi-paragraph message ---"
sb_run git commit -m "'Add the notes file'" -m "'The file is a placeholder for now.'" -m "'Refs: #42'"
sb_tick
sb_run "git log -1 --pretty=format:'%B'"
sb_run git log -1 --oneline

sb_say "--- 6. author and committer are two different people ---"
sb_run "git log -1 --pretty=fuller"
GIT_COMMITTER_DATE="@1767700000 +0000" git commit -q --allow-empty --author="Grace Hopper <grace@example.com>" -m "Someone else wrote this"
sb_run "git log -1 --pretty=fuller"
sb_run "git log -1 --pretty=format:'author=%an <%ae> %ad%ncommit=%cn <%ce> %cd' --date=iso"
sb_tick

sb_say "--- 7. empty commits ---"
sb_run git commit -m "'Nothing changed'" || true
sb_run git commit --allow-empty -m "'Deliberately empty'"
sb_tick
sb_run git log --oneline -2
sb_run git show --stat --oneline HEAD

sb_say "--- 8. amending ---"
sb_write app.py "print('hello')" "print('world')" "print('again')"
git add app.py
sb_run git rev-parse HEAD
sb_run git commit --amend -m "'Deliberately empty, now with content'"
sb_run git rev-parse HEAD
sb_run git log --oneline -2
sb_run git show --stat --oneline HEAD

sb_say "--- 9. amending without changing the message ---"
sb_write app.py "print('hello')" "print('world')" "print('again')" "print('more')"
git add app.py
sb_run "git commit --amend --no-edit"
sb_run git log --oneline -1
sb_run "git log -1 --pretty=fuller"

sb_say "--- 10. reusing another commit's message ---"
sb_run git commit --allow-empty -C HEAD
sb_tick
sb_run git log --oneline -3

sb_say "--- 11. an empty message aborts ---"
sb_write app.py "print('x')"
git add app.py
sb_run "git commit -m ''" || true
sb_run "GIT_EDITOR='true' git commit" || true
sb_run git status --short

sb_say "--- 12. what --cleanup does to your message ---"
sb_run "git commit -F - <<'EOM'
Subject line

# this line looks like a comment
Body text.


EOM"
sb_tick
sb_run "git log -1 --pretty=format:'%B' | cat -A | head -8"
