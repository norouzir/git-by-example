#!/bin/bash
# Generates every transcript in Chapter 13, "diff".
#
#   bash sandbox/scripts/ch13-diff.sh [dir]

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
sb_fresh "$SANDBOX_ROOT/diffing" >/dev/null

sb_write story.txt "Once upon a time" "there was a repository." "It had many commits." "The end."
sb_write config.ini "debug = false" "port = 8080"
sb_commit "Add story and config"

sb_say "--- 1. reading a diff ---"
sb_write story.txt "Once upon a time" "there was a git repository." "It had many commits." "The end."
sb_run git diff

sb_say "--- 2. the header lines decoded ---"
sb_run "git diff | head -5"
sb_run "git rev-parse :story.txt"
sb_run "git hash-object story.txt"

sb_say "--- 3. how much context ---"
sb_run "git diff -U1"
sb_run "git diff -U0"
sb_run "git diff --unified=3 | head -4"

sb_say "--- 4. summaries instead of content ---"
sb_write config.ini "debug = true" "port = 8080" "timeout = 30"
sb_run git diff --stat
sb_run git diff --numstat
sb_run git diff --shortstat
sb_run git diff --name-only
sb_run git diff --name-status
sb_run git diff --summary

sb_say "--- 5. word level ---"
sb_run "git diff --word-diff story.txt"
sb_run "git diff --word-diff=porcelain story.txt"

sb_say "--- 6. comparing things other than the working tree ---"
git add -A && git commit -q -m "Tell a git story" && sb_tick
sb_write story.txt "Once upon a time" "there was a git repository." "It had many commits." "It had branches too." "The end."
sb_commit "Mention branches"
sb_run git diff HEAD~2 HEAD --stat
sb_run "git diff HEAD~2..HEAD --stat"
sb_run "git diff HEAD~2 HEAD -- story.txt"

sb_say "--- 7. two dots and three dots are not the same ---"
git switch -q -c feature HEAD~2
sb_write feature.txt "new feature"
sb_commit "Add a feature"
git switch -q main
sb_run git log --oneline --all --graph
sb_run "git diff main..feature --name-status"
sb_run "git diff main...feature --name-status"
sb_run git merge-base main feature

sb_say "--- 8. searching diffs for content ---"
sb_run "git log -S 'branches' --oneline"
sb_run "git log -G 'debug' --oneline"
sb_run "git log --oneline -- config.ini"

sb_say "--- 9. whitespace ---"
sb_write spaced.txt "hello world" "second line"
sb_commit "Add spaced file"
printf 'hello    world\nsecond line   \n' > spaced.txt
sb_run git diff spaced.txt
sb_run "git diff -b spaced.txt"
sb_run "git diff -w spaced.txt"
sb_run "git diff --ignore-all-space --stat spaced.txt"
sb_run git checkout -q -- spaced.txt

sb_say "--- 10. renames ---"
git mv story.txt tale.txt
sb_run git diff --cached --stat
sb_run "git diff --cached -M --name-status"
sb_run "git diff --cached --no-renames --name-status"
sb_run git restore --staged --worktree .

sb_say "--- 11. diff algorithms ---"
sb_write code.js "function a() {" "  return 1;" "}" "" "function b() {" "  return 2;" "}"
sb_commit "Add code"
sb_write code.js "function a() {" "  return 1;" "}" "" "function c() {" "  return 3;" "}" "" "function b() {" "  return 2;" "}"
sb_run "git diff --diff-algorithm=myers code.js"
sb_run "git diff --diff-algorithm=histogram code.js"
sb_run git checkout -q -- code.js

sb_say "--- 12. diffing files Git does not track ---"
cd "$SANDBOX_ROOT"
printf 'alpha\nbravo\n' > one.txt
printf 'alpha\ncharlie\n' > two.txt
sb_run "git diff --no-index one.txt two.txt" || true
sb_run "git --no-pager diff --no-index --stat one.txt two.txt" || true
cd "$SANDBOX_ROOT/diffing"

sb_say "--- 13. exit codes for scripts ---"
sb_run "git diff --quiet && echo 'clean (exit 0)' || echo 'dirty (exit 1)'"
sb_write story.txt "changed"
sb_run "git diff --quiet && echo 'clean (exit 0)' || echo 'dirty (exit 1)'"
sb_run "git diff --exit-code --stat || echo '(exit was non-zero)'"
sb_run git checkout -q -- story.txt
sb_run "git diff --quiet && echo 'clean (exit 0)' || echo 'dirty (exit 1)'"
