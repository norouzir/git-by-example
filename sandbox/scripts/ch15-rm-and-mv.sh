#!/bin/bash
# Generates every transcript in Chapter 15, "rm and mv".
#
#   bash sandbox/scripts/ch15-rm-and-mv.sh [dir]
#
# No `set -e`: several commands shown here fail on purpose, such as removing a
# modified file or moving onto an existing one, and the transcript must carry on.

set -uo pipefail
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
sb_run "git mv keep.txt KEEP.TXT"
sb_run git status --short
sb_run git ls-files

# =============================================================================
# Everything below runs in repositories of its own, so nothing above changes.

sb_say "--- U1. rm: patterns, files already gone, and --cached ---"
sb_fresh "$SANDBOX_ROOT/rmmore" >/dev/null
sb_write d/one.txt "1"
sb_write d/sub/three.txt "3"
sb_write d2/two.txt "2"
sb_write docs/a.md "a"
sb_write docs/deep/b.md "b"
sb_write top.md "top"
sb_write gone.txt "gone"
sb_write keep.txt "keep"
sb_commit "Base"
sb_run "git rm -n 'd*'"
sb_run "git rm -n 'd/*'"
sb_run "git rm -n '*.md'"
sb_run "git rm -q -r d && git status --short && ls"
sb_run "git reset -q --hard"
rm gone.txt
sb_run "git status --short"
sb_run "git rm gone.txt && git status --short"
sb_run "git reset -q --hard"
rm gone.txt top.md
sb_run "git diff --name-only --diff-filter=D -z | xargs -0 git rm --cached"
sb_run "git status --short"
sb_run "git reset -q --hard"
sb_run "printf 'top.md\0keep.txt\0' | git rm -q --pathspec-from-file=- --pathspec-file-nul && git status --short"
sb_run "git reset -q --hard"
sb_write keep.txt "keep" "staged"
git add keep.txt
sb_run "git rm --cached keep.txt && git status --short"
sb_run "git reset -q --hard"
sb_write keep.txt "keep" "staged"
git add keep.txt
sb_write keep.txt "keep" "staged" "and changed again"
sb_run "git rm --cached keep.txt"
sb_run "git rm --cached -f keep.txt && git status --short"
sb_run "git reset -q --hard"
sb_run "git rm"

sb_say "--- U2. mv: reporting, directories, and every error ---"
sb_fresh "$SANDBOX_ROOT/mvmore" >/dev/null
sb_write a.txt "a"
sb_write b.txt "b"
sb_write dir/x.txt "x"
sb_write dir/sub/y.txt "y"
sb_commit "Base"
sb_run "git mv -v a.txt c.txt && git status --short"
sb_run "git reset -q --hard"
sb_run "git mv -n a.txt c.txt && git status --short"
sb_run "git mv dir newdir && git status --short && ls"
sb_run "git reset -q --hard && rm -rf newdir"
sb_run "mkdir target && git mv a.txt b.txt target && git status --short"
sb_run "git reset -q --hard && rm -rf target"
sb_run "git mv a.txt b.txt nowhere"
sb_run "git mv a.txt nowhere/c.txt"
sb_run "git mv dir dir/sub"
sb_write untracked.txt "untracked"
sb_run "git mv -k a.txt untracked.txt nosuch.txt dir && git status --short"
sb_run "git reset -q --hard"
sb_run "git mv a.txt untracked.txt"
sb_run "git mv -f a.txt untracked.txt && git status --short"
sb_run "git reset -q --hard"
rm -f untracked.txt
sb_write a.txt "a" "edited"
sb_run "git mv a.txt c.txt && git status --short"
sb_run "git reset -q --hard"
rm -f c.txt
sb_run "mv a.txt c.txt && git add -A && git write-tree"
sb_run "git reset -q --hard"
rm -f c.txt
sb_run "git mv a.txt c.txt && git write-tree"
sb_run "git reset -q --hard"
rm -f c.txt

sb_say "--- U3. sparse checkouts ---"
sb_fresh "$SANDBOX_ROOT/sparse" >/dev/null
sb_write keep/k.txt "k"
sb_write other/o.txt "o"
sb_commit "Base"
sb_run "git sparse-checkout set keep"
sb_run "git rm other/o.txt"
sb_run "git rm --sparse other/o.txt && git status --short"
sb_run "git reset -q --hard"
sb_run "git mv other/o.txt keep/o.txt"
sb_run "git mv --sparse other/o.txt keep/o.txt && git status --short"
