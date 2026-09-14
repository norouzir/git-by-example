#!/bin/bash
# Generates every transcript in Chapter 11, "add".
#
#   bash sandbox/scripts/ch11-add.sh [dir]
#
# No `set -e`: several commands shown here fail on purpose, such as adding an
# ignored file or a path that does not exist, and the transcript must carry on.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
sb_fresh "$SANDBOX_ROOT/adding" >/dev/null

sb_say "--- 1. the plain form ---"
sb_write a.txt "alpha"
sb_write b.txt "bravo"
sb_run git add a.txt
sb_run git status --short
sb_run git add a.txt b.txt
sb_run git status --short
sb_commit "Add a and b"

sb_say "--- 2. what it actually did ---"
sb_write a.txt "alpha" "second line"
sb_run "git hash-object a.txt"
sb_run git add a.txt
sb_run git ls-files --stage a.txt
sb_run "git cat-file -p :a.txt"

sb_say "--- 3. a dry run ---"
sb_write c.txt "charlie"
sb_run git add -n .
sb_run git status --short
sb_run git add --dry-run c.txt

sb_say "--- 4. the four ways to say everything ---"
sb_write src/one.txt "one"
sb_write src/two.txt "two"
rm b.txt
sb_run git status --short
sb_run "git add -u && git status --short"
sb_run git reset -q
sb_run "git add -A && git status --short"
sb_run git reset -q
sb_run "git add . && git status --short"
sb_run git reset -q

sb_say "--- 5. the difference only shows from a subdirectory ---"
cd src
sb_run "git add . && git status --short"
sb_run git reset -q
sb_run "git add -A && git status --short"
sb_run git reset -q
cd ..
sb_run "git add -A && git status --short"
sb_commit "Add src and remove b"

sb_say "--- 6. pathspecs: globs and directories ---"
sb_write docs/guide.md "guide"
sb_write docs/api.md "api"
sb_write docs/logo.png "not really a png"
sb_run "git add 'docs/*.md' && git status --short"
sb_run git reset -q
sb_run "git add docs && git status --short"
sb_run git reset -q
sb_run "git add ':(glob)**/*.md' && git status --short"
sb_run git reset -q
sb_run "git add ':!docs/logo.png' && git status --short"
sb_run git reset -q

sb_say "--- 7. adding part of a file ---"
sb_write poem.txt "one" "two" "three" "four" "five" "six" "seven" "eight" "nine" "ten"
sb_commit "Add poem"
sb_write poem.txt "ONE" "two" "three" "four" "five" "six" "seven" "eight" "nine" "TEN"
sb_run git diff
sb_run "printf 'y\nn\n' | git add -p poem.txt"
sb_run git status --short
sb_run git diff --staged
sb_run git diff

sb_say "--- 8. ignored files need forcing ---"
sb_write .gitignore "*.log"
sb_commit "Ignore logs"
sb_write debug.log "noise"
sb_run git add debug.log || true
sb_run "git add -f debug.log && git status --short"
sb_run git reset -q

sb_say "--- 9. recording that a file is coming ---"
sb_write draft.txt "unfinished"
sb_run git status --short
sb_run git add -N draft.txt
sb_run git status --short
sb_run git diff
sb_run git ls-files --stage draft.txt

sb_say "--- 10. setting the executable bit without touching the file ---"
sb_write script.sh "#!/bin/sh" "echo hi"
sb_run "git add --chmod=+x script.sh && git ls-files --stage script.sh"
sb_run git reset -q

sb_say "--- 11. errors it produces ---"
sb_run git add nothing-here || true
sb_run "git add ''" || true
cd "$SANDBOX_ROOT"
sb_run "git -C adding add ../outside" || true

# =============================================================================
# Everything below runs in repositories of its own, so nothing above changes.

sb_say "--- M1. adding again, directories, and the forms without a path ---"
sb_fresh "$SANDBOX_ROOT/again" >/dev/null
sb_write a.txt "one"
sb_write dir/x.txt "x"
sb_write dir/y.txt "y"
sb_commit "Base"
sb_write a.txt "one" "two"
sb_run "git add a.txt"
sb_write a.txt "one" "two" "three"
sb_run "git status --short"
sb_run "git diff --staged"
rm dir/x.txt
sb_write dir/y.txt "y2"
sb_write dir/z.txt "z"
sb_run "git status --short dir"
sb_run "git add dir && git status --short dir"
sb_run "git reset -q"
sb_run "git add --no-all dir && git status --short dir"
sb_run "git reset -q"
sb_run "git add --ignore-removal dir && git status --short dir"
sb_run "git reset -q"
sb_run "git add"
sb_run "git add -v dir"
sb_run "git reset -q"
sb_run "git add -n -v dir"
sb_run "cd dir && git add -u && cd .."
sb_run "git status --short"
sb_run "git reset -q"
sb_run "cd dir && git add -u . && cd .."
sb_run "git status --short"

sb_say "--- M2. ignored files in more detail ---"
sb_fresh "$SANDBOX_ROOT/ignored" >/dev/null
sb_write .gitignore "*.log"
sb_commit "Base"
sb_write debug.log "noise"
sb_write logs/app.log "noise"
sb_write notes.txt "notes"
sb_run "git add . && git status --short --ignored"
sb_run "git reset -q"
sb_run "git add debug.log notes.txt; echo \"exit \$?\""
sb_run "git status --short"
sb_run "git reset -q"
sb_run "git add 'logs/*'"
sb_run "git add -n debug.log"
sb_run "git add -n missing.log"
sb_run "git add -n --ignore-missing missing.log"
sb_run "git add -n --ignore-missing missing.txt"
sb_run "git add --ignore-missing missing.log"

sb_say "--- M3. pathspec magic, one at a time ---"
sb_fresh "$SANDBOX_ROOT/magic" >/dev/null
sb_write README.md "readme"
sb_commit "Base"
sb_write a.txt "a"
sb_write b.txt "b"
sb_write "[ab].txt" "brackets"
sb_write Notes.TXT "notes"
sb_write top.log "top"
sb_write src/debug.log "debug"
sb_write src/README.local "local"
sb_write readme.txt "lower-case readme"
sb_run "git add '[ab].txt' && git status --short"
sb_run "git reset -q"
sb_run "git add ':(literal)[ab].txt' && git status --short"
sb_run "git reset -q"
sb_run "git add '*.log' && git status --short"
sb_run "git reset -q"
sb_run "git add ':(glob)*.log' && git status --short"
sb_run "git reset -q"
sb_run "git add '*.txt' && git status --short"
sb_run "git reset -q"
sb_run "git add ':(icase)*.txt' && git status --short"
sb_run "git reset -q"
sb_run "cd src && git add ':(top,icase)README*' && cd .. && git status --short"
sb_run "git reset -q"
sb_run "git add . ':!*.log' && git status --short"
sb_run "git reset -q"
sb_run "git add ':^*.log' && git status --short"
sb_run "git reset -q"
sb_write .gitattributes "*.log generated"
sb_run "git add ':(attr:generated)' && git status --short"
sb_run "git reset -q"
sb_run "git add src/README.local && git add ':(attr:generated)' && git status --short"
sb_run "git reset -q"
rm .gitattributes
sb_run "git add ':(nonsense)x'"
sb_write ./-n.txt "starts with a dash"
sb_run "git add -n.txt"
sb_run "git add -- -n.txt && git status --short -- -n.txt"
sb_run "git reset -q"

sb_say "--- M4. pathspecs from a file ---"
printf 'a.txt\nsrc/README.local\n' > list.txt
sb_run "cat list.txt"
sb_run "git add --pathspec-from-file=list.txt && git status --short -uno"
sb_run "git reset -q"
sb_run "printf 'b.txt\n' | git add --pathspec-from-file=- && git status --short -uno"
sb_run "git reset -q"
sb_run "printf 'a.txt\0top.log\0' | git add --pathspec-from-file=- --pathspec-file-nul && git status --short -uno"
sb_run "git reset -q"
sb_run "git add --pathspec-from-file=list.txt b.txt"
sb_run "git add --pathspec-file-nul a.txt"

sb_say "--- M5. patch mode in detail ---"
sb_fresh "$SANDBOX_ROOT/patch" >/dev/null
sb_write poem.txt one two three four five six seven eight nine ten eleven twelve
sb_write other.txt alpha beta
sb_commit "Base"
sb_write poem.txt ONE two THREE four five six seven eight nine ten eleven TWELVE
sb_write other.txt alpha BETA
sb_run "git diff poem.txt"
sb_run "printf 's\ny\nn\nn\n' | git add -p poem.txt"
sb_run "git diff --staged"
sb_run "git reset -q"
sb_run "printf '?\nq\n' | git add -p poem.txt"
sb_run "printf 'n\nn\nn\n' | git add -p -U0 poem.txt"
sb_run "printf 'n\n' | git add -p --inter-hunk-context=2 poem.txt"
sb_run "printf 'n\nn\n' | git -c diff.context=1 add -p poem.txt"
sb_run "printf 'g\n2\ny\nq\n' | git add -p poem.txt"
sb_run "git diff --staged --stat"
sb_run "git reset -q"
sb_run "printf '/TWELVE\ny\nq\n' | git add -p poem.txt"
sb_run "git diff --staged --stat"
sb_run "git reset -q"
sb_run "printf 'n\ny\nn\n' | git add -p"
sb_run "git status --short"
sb_run "git reset -q"
sb_run "printf 'y\n>\nq\n' | git add -p --no-auto-advance"
sb_run "git status --short"
sb_run "git reset -q"
sb_run "git add --no-auto-advance poem.txt"
sb_run "printf 'e\nq\n' | GIT_EDITOR=cat git add -p poem.txt"
sb_run "git diff --staged --stat"
sb_run "git reset -q"
sb_run "printf 'e\nn\nq\n' | GIT_EDITOR=\"sed -i '/^ two/d'\" git add -p poem.txt"
sb_run "git diff --staged --stat"
sb_run "printf 'e\nn\n' | GIT_EDITOR=\"sed -i 's/^+ONE/+One/'\" git add -p poem.txt"
sb_run "git diff --staged"
sb_run "git diff poem.txt"
sb_run "git reset -q"
sb_run "GIT_EDITOR=\"sed -i 's/^-twelve/ twelve/; /^+TWELVE/d'\" git add -e poem.txt"
sb_run "git diff --staged"
sb_run "git reset -q"
sb_run "git stash -q && git add -p; git stash pop -q"

sb_say "--- M6. interactive mode ---"
sb_write new.txt "new"
sb_run "printf 's\nq\n' | git add -i"
sb_run "printf 'u\n1\n\nq\n' | git add -i"
sb_run "git status --short"
sb_run "git reset -q"
sb_run "printf 'a\n1\n\nq\n' | git add -i"
sb_run "git status --short"
sb_run "git reset -q"

sb_say "--- M7. intent to add, and committing ---"
sb_fresh "$SANDBOX_ROOT/intent" >/dev/null
sb_write keep.txt "keep"
sb_commit "Base"
sb_write draft.txt "line one" "line two"
sb_run "git add -N draft.txt"
sb_run "git commit -m 'Try to commit the draft'"
sb_write other.txt "other"
sb_run "git add other.txt && git commit -q -m 'Add other' && git show --stat --oneline HEAD"
sb_run "git status --short"
sb_run "git commit -q -a -m 'Add the draft' && git show --stat --oneline HEAD"
sb_write late.txt "a" "b"
sb_run "git add -N late.txt && printf 'y\n' | git add -p late.txt"
sb_run "git status --short"
sb_run "git add -N not-created-yet.txt"

sb_say "--- M8. executable bit, line endings, and refreshing ---"
sb_fresh "$SANDBOX_ROOT/modes" >/dev/null
sb_write script.sh "#!/bin/sh" "echo hi"
git add --chmod=+x script.sh
sb_commit "Base"
sb_run "git add --chmod=-x script.sh && git ls-files --stage script.sh && git status --short"
sb_run "git add --chmod=x script.sh"
sb_run "git reset -q"
printf 'one\r\ntwo\r\n' > crlf.txt
git add crlf.txt
git commit -q -m "Add a file with CRLF line endings"
sb_tick
sb_run "git ls-files --eol crlf.txt"
sb_write .gitattributes "* text=auto"
sb_run "git status --short"
sb_run "git add --renormalize . && git status --short"
sb_run "git ls-files --eol crlf.txt"
sb_run "git reset -q --hard"
touch -d "@1800000000" script.sh
sb_run "git diff-files --name-only"
sb_run "git add --refresh script.sh && git diff-files --name-only"

sb_say "--- M9. errors, embedded repositories, sparse checkouts ---"
sb_fresh "$SANDBOX_ROOT/errors" >/dev/null
sb_write keep.txt "keep"
sb_commit "Base"
git init -q inner
sb_write good.txt "good"
sb_run "git add inner good.txt; echo \"exit \$?\""
sb_run "git status --short"
sb_run "git add --ignore-errors inner good.txt; echo \"exit \$?\""
sb_run "git status --short"
sb_run "git reset -q"
sb_run "git -c add.ignoreErrors=true add inner good.txt; echo \"exit \$?\""
sb_run "git reset -q"
(cd inner && sb_write f.txt "f" && git add f.txt && git commit -q -m "Inner")
sb_run "git add --no-warn-embedded-repo inner && git status --short"
sb_run "git reset -q"
rm -rf inner good.txt
sb_write a/1.txt "1"
sb_write b/2.txt "2"
sb_commit "Two directories"
sb_run "git sparse-checkout set a"
sb_write b/2.txt "changed outside the sparse checkout"
sb_run "git add b/2.txt"
sb_run "git add --sparse b/2.txt && git status --short"

sb_say "--- M10. add and its neighbours ---"
sb_fresh "$SANDBOX_ROOT/neighbours" >/dev/null
sb_write a.txt "a"
sb_commit "Base"
sb_write a.txt "a" "b"
sb_write new.txt "new"
sb_run "git stage a.txt && git status --short"
sb_run "git reset -q"
sb_run "git commit -q -a -m 'Commit every tracked change' && git status --short"
sb_run "git update-index --add new.txt && git status --short"
sb_run "git restore --staged new.txt && git status --short"
sb_fresh "$SANDBOX_ROOT/unborn" >/dev/null
sb_write first.txt "first"
sb_run "git add first.txt"
sb_run "git restore --staged first.txt"
sb_run "git rm --cached -q first.txt && git status --short"

sb_say "--- M11. a star, with and without quotes ---"
sb_fresh "$SANDBOX_ROOT/star" >/dev/null
sb_write .gitignore "*.log"
sb_write a.txt "a"
sb_write b.txt "b"
sb_write src/one.txt "one"
sb_write src/gone.txt "gone"
sb_commit "Base"
sb_write a.txt "a, changed"
sb_write .gitignore "*.log" "*.tmp"
rm b.txt src/gone.txt
sb_write c.txt "new"
sb_write src/new.txt "new"
sb_write .env "SECRET=1"
sb_write debug.log "noise"
sb_run "git status --short"
sb_run "echo *"
sb_run "git add *; echo \"exit \$?\""
sb_run "git status --short"
sb_run "git reset -q"
sb_run 'git add "*" && git status --short'
sb_run "git reset -q"
sb_run "git add '*' && git status --short"
sb_run "git reset -q"
sb_run "git add . && git status --short"
sb_run "git reset -q"
sb_run "cd src"
cd src
sb_run 'git add "*" && git status --short'
sb_run "git reset -q"
sb_run "git add . && git status --short"
sb_run "git reset -q"
cd ..
