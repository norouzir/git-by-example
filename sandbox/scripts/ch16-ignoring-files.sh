#!/bin/bash
# Generates every transcript in Chapter 16, "Ignoring Files".
#
#   bash sandbox/scripts/ch16-ignoring-files.sh [dir]

# No -e here on purpose: this chapter is largely about commands that exit
# non-zero as their answer. `git check-ignore` exits 1 when nothing matched,
# which is information, not failure.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
sb_fresh "$SANDBOX_ROOT/ignoring" >/dev/null

sb_say "--- 1. the simplest rule ---"
sb_write debug.log "noise"
sb_write app.py "code"
sb_run git status --short
sb_write .gitignore "*.log"
sb_run git status --short
sb_run git status --short --ignored

sb_say "--- 2. asking why ---"
sb_run "git check-ignore -v debug.log"
sb_run "git check-ignore -v app.py"
sb_run "git check-ignore -v --non-matching app.py"

sb_say "--- 3. anchoring with a slash ---"
sb_write build/out.txt "built"
sb_write src/build/out.txt "also built"
sb_run "printf 'build/\n' > .gitignore"
sb_run "git status --short --ignored"
sb_run "printf '/build/\n' > .gitignore"
sb_run "git status --short --ignored"

sb_say "--- 4. a trailing slash means directories only ---"
sb_write cache "a file called cache"
sb_write cache_dir/x.txt "in a directory"
sb_run "printf 'cache\n' > .gitignore"
sb_run "git check-ignore -v cache"
sb_run "printf 'cache/\n' > .gitignore"
sb_run "git check-ignore -v cache"
sb_run "git check-ignore -v cache_dir/x.txt"
rm -f cache

sb_say "--- 5. wildcards ---"
sb_write a.txt "a"
sb_write ab.txt "ab"
sb_write logs/deep/nested.log "deep"
sb_run "printf '?.txt\n' > .gitignore"
sb_run "git check-ignore -v a.txt ab.txt"
sb_run "printf '[ab]*.txt\n' > .gitignore"
sb_run "git check-ignore -v a.txt ab.txt"
sb_run "printf '*.log\n' > .gitignore"
sb_run "git check-ignore -v logs/deep/nested.log"
sb_run "printf 'logs/*.log\n' > .gitignore"
sb_run "git check-ignore -v logs/deep/nested.log"
sb_run "printf 'logs/**/*.log\n' > .gitignore"
sb_run "git check-ignore -v logs/deep/nested.log"

sb_say "--- 6. negation ---"
sb_write docs/notes.txt "notes"
sb_write docs/keep.txt "keep"
sb_run "printf 'docs/*\n!docs/keep.txt\n' > .gitignore"
sb_run "git status --short --ignored"
sb_run "git check-ignore -v docs/keep.txt"
sb_run "git check-ignore -v docs/notes.txt"

sb_say "--- 7. negation cannot escape an ignored directory ---"
sb_run "printf 'docs/\n!docs/keep.txt\n' > .gitignore"
sb_run "git status --short --ignored"
sb_run "git check-ignore -v docs/keep.txt"
sb_run "printf 'docs/**\n!docs/keep.txt\n' > .gitignore"
sb_run "git status --short --ignored"

sb_say "--- 8. later rules win ---"
sb_run "printf '*.txt\n!important.txt\n' > .gitignore"
sb_write important.txt "keep me"
sb_run "git check-ignore -v important.txt"
sb_run "printf '!important.txt\n*.txt\n' > .gitignore"
sb_run "git check-ignore -v important.txt"

sb_say "--- 9. one file per directory, deepest wins ---"
sb_run "printf '*.tmp\n' > .gitignore"
sb_write work/scratch.tmp "temp"
sb_run "git check-ignore -v work/scratch.tmp"
sb_run "printf '!scratch.tmp\n' > work/.gitignore"
sb_run "git check-ignore -v work/scratch.tmp"
sb_run "git status --short"

sb_say "--- 10. the other two places rules can live ---"
sb_run "printf 'private-notes.txt\n' >> .git/info/exclude"
sb_write private-notes.txt "mine"
sb_run "git check-ignore -v private-notes.txt"
sb_run "printf '*.bak\n' > $SANDBOX_ROOT/global-ignore"
sb_run "git config set core.excludesFile $SANDBOX_ROOT/global-ignore"
sb_write draft.bak "backup"
sb_run "git check-ignore -v draft.bak"
sb_run git status --short

sb_say "--- 11. forcing past a rule ---"
sb_run "git add debug.log"
sb_run "git add -f debug.log && git status --short"
sb_run git rm -q --cached debug.log

sb_say "--- 12. listing what is ignored ---"
sb_run "git status --short --ignored"
sb_run "git ls-files --others --ignored --exclude-standard"
sb_run "git ls-files --others --exclude-standard"

sb_say "--- 13. comments, blanks and escaping ---"
sb_run "printf '# a comment\n\n\\#not-a-comment.txt\ntrailing-space  \n' > .gitignore"
sb_write '#not-a-comment.txt' "hash file"
sb_write 'trailing-space' "spaces"
sb_run "git check-ignore -v '#not-a-comment.txt'"
sb_run "git check-ignore -v trailing-space"
