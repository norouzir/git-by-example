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
sb_run "git add private-notes.txt"
sb_run "git add -f private-notes.txt && git status --short"
sb_run "git check-ignore -v private-notes.txt; echo \"exit \$?\""
sb_run "git rm -q --cached private-notes.txt"

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

# =============================================================================
# Everything below runs in repositories of its own, so nothing above changes.

sb_say "--- W1. check-ignore in full ---"
sb_fresh "$SANDBOX_ROOT/checking" >/dev/null
sb_write .gitignore "*.log" "build/"
sb_write app.py "code"
sb_write tracked.log "tracked"
git add -f tracked.log app.py .gitignore
git commit -q -m "Base"
sb_tick
sb_write debug.log "noise"
sb_write build/out.o "object"
sb_run "git check-ignore debug.log app.py build/out.o; echo \"exit \$?\""
sb_run "git check-ignore app.py; echo \"exit \$?\""
sb_run "git check-ignore -q debug.log; echo \"exit \$?\""
sb_run "git check-ignore -q debug.log app.py"
sb_run "git check-ignore -v build build/ build/out.o"
sb_run "git check-ignore tracked.log; echo \"exit \$?\""
sb_run "git check-ignore -v --no-index tracked.log"
sb_run "git check-ignore -v --no-index --index tracked.log; echo \"exit \$?\""
sb_run "printf 'debug.log\napp.py\n' | git check-ignore -v -n --stdin"
sb_run "printf 'debug.log\0app.py\0' | git check-ignore -z --stdin -n -v | tr '\0' '@'; echo"
sb_run "git check-ignore -z debug.log"
sb_run "git check-ignore -n app.py"
sb_run "git check-ignore"
sb_run "git check-ignore ../outside.txt; echo \"exit \$?\""

sb_say "--- W2. anchoring inside a subdirectory ---"
sb_fresh "$SANDBOX_ROOT/nested" >/dev/null
sb_write scratch.tmp "t"
sb_write work/scratch.tmp "t"
sb_write work/sub/scratch.tmp "t"
sb_run "printf '/scratch.tmp\n' > work/.gitignore"
sb_run "git check-ignore -v scratch.tmp work/scratch.tmp work/sub/scratch.tmp"
sb_run "printf 'sub/scratch.tmp\n' > work/.gitignore"
sb_run "git check-ignore -v scratch.tmp work/scratch.tmp work/sub/scratch.tmp"
rm work/.gitignore

sb_say "--- W3. which source wins ---"
sb_write keep.bak "k"
sb_write other.bak "o"
sb_run "printf '*.bak\n' >> .git/info/exclude && printf '!keep.bak\n' > .gitignore"
sb_run "git check-ignore -v -n keep.bak other.bak"
sb_run "printf '*.bak\n' > .gitignore && printf '!keep.bak\n' >> .git/info/exclude"
sb_run "git check-ignore -v -n keep.bak other.bak"
mkdir -p "$SANDBOX_ROOT/xdg/git"
printf '*.swp\n' > "$SANDBOX_ROOT/xdg/git/ignore"
sb_write notes.swp "s"
sb_write sub/notes.swp "s"
sb_run "cat $SANDBOX_ROOT/xdg/git/ignore"
sb_run "XDG_CONFIG_HOME=$SANDBOX_ROOT/xdg git check-ignore -v notes.swp"
sb_run "printf '/notes.swp\n' > $SANDBOX_ROOT/anchored-ignore"
sb_run "git -c core.excludesFile=$SANDBOX_ROOT/anchored-ignore check-ignore -v -n notes.swp sub/notes.swp"

sb_say "--- W4. more wildcards ---"
sb_fresh "$SANDBOX_ROOT/wildcards" >/dev/null
sb_write a.txt "a"
sb_write b.txt "b"
sb_write c.txt "c"
sb_write foo/test.json "j"
sb_write foo/bar/hello.c "h"
sb_write deep/x/foo "f"
sb_write a/b "x"
sb_write a/x/y/b "x"
sb_write '!important!.txt' "x"
sb_run "printf '[!ab].txt\n' > .gitignore && git check-ignore -v -n a.txt b.txt c.txt"
sb_run "printf '[a-b].txt\n' > .gitignore && git check-ignore -v -n a.txt b.txt c.txt"
sb_run "printf 'foo/*\n' > .gitignore && git check-ignore -v -n foo/test.json foo/bar foo/bar/hello.c"
sb_run "printf '**/foo\n' > .gitignore && git check-ignore -v -n foo deep/x/foo"
sb_run "printf 'a/**/b\n' > .gitignore && git check-ignore -v -n a/b a/x/y/b"
sb_run "printf '\\\\!important!.txt\n' > .gitignore && cat .gitignore"
sb_run "git check-ignore -v '!important!.txt'"
sb_run "printf 'a.txt\\\\\n' > .gitignore && cat .gitignore"
sb_run "git check-ignore -v a.txt; echo \"exit \$?\""
sb_run "printf '*.TXT\n' > .gitignore && git check-ignore -v a.txt"
sb_run "git -c core.ignorecase=false check-ignore -v a.txt; echo \"exit \$?\""

sb_say "--- W5. keeping one deep file, and an empty directory ---"
sb_fresh "$SANDBOX_ROOT/deepkeep" >/dev/null
sb_write a/b/c/keep.txt "k"
sb_write a/b/c/other.txt "o"
sb_write a/b/mid.txt "m"
sb_write top.txt "t"
printf '/*\n!/a/\n/a/*\n!/a/b/\n/a/b/*\n!/a/b/c/\n/a/b/c/*\n!/a/b/c/keep.txt\n!.gitignore\n' > .gitignore
sb_run "cat .gitignore"
sb_run "git status --short --ignored -uall"
sb_run "git check-ignore -v a/b/c/keep.txt a/b/c/other.txt"
sb_fresh "$SANDBOX_ROOT/emptydir" >/dev/null
sb_write readme.txt "r"
mkdir -p uploads
printf '*\n!.gitignore\n' > uploads/.gitignore
sb_write uploads/photo.jpg "p"
sb_run "cat uploads/.gitignore"
sb_run "git status --short -uall --ignored"
sb_run "git add -A && git commit -q -m 'Keep the uploads directory' && git ls-files"
sb_tick
git init -q --bare "$SANDBOX_ROOT/emptydir.git"
git push -q "$SANDBOX_ROOT/emptydir.git" HEAD:main
sb_run "git clone -q $SANDBOX_ROOT/emptydir.git $SANDBOX_ROOT/copy && ls -A $SANDBOX_ROOT/copy/uploads"

sb_say "--- W6. a tracked template and an ignored copy ---"
sb_fresh "$SANDBOX_ROOT/template" >/dev/null
sb_write config.example.ini "user = CHANGE ME"
sb_write .gitignore "config.ini"
sb_commit "Add a configuration template"
sb_run "cp config.example.ini config.ini && git status --short --ignored"
