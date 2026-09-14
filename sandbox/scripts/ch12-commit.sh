#!/bin/bash
# Generates every transcript in Chapter 12, "commit".
#
#   bash sandbox/scripts/ch12-commit.sh [dir]
#
# No `set -e`: several commands shown here fail on purpose, such as a commit
# with nothing staged or one a hook refuses, and the transcript must carry on.

set -uo pipefail
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
sb_run "GIT_COMMITTER_DATE='@1767700000 +0000' git commit -q --allow-empty --author='Grace Hopper <grace@example.com>' -m 'Someone else wrote this'"
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

# =============================================================================
# Everything below runs in repositories of its own, so nothing above changes.

sb_say "--- P1. exit codes, quiet, detached HEAD, deletions ---"
sb_fresh "$SANDBOX_ROOT/basics" >/dev/null
sb_write a.txt "a"
sb_commit "Base"
sb_run "git commit -m 'Nothing'; echo \"exit \$?\""
sb_write new.txt "new"
sb_run "git commit -m 'Only untracked'; echo \"exit \$?\""
sb_run "git add new.txt && git commit -q -m 'Quiet'; echo \"exit \$?\""
sb_tick
sb_run "git switch -q --detach"
sb_write a.txt "a" "b"
sb_run "git commit -am 'On a detached HEAD'"
sb_tick
sb_run "git switch -q main"
rm a.txt
sb_run "git commit -am 'Delete a'"
sb_tick

sb_say "--- P2. committing some paths ---"
sb_fresh "$SANDBOX_ROOT/paths" >/dev/null
sb_write a.txt "a"
sb_write b.txt "b"
sb_write c.txt "c"
sb_commit "Base"
sb_write a.txt "a2"
sb_write b.txt "b2"
sb_write c.txt "c2"
sb_run "git add a.txt"
sb_run "git status --short"
sb_run "git commit -m 'Only b' b.txt"
sb_tick
sb_run "git status --short"
sb_run "git commit -o -m 'Only c' c.txt && git status --short"
sb_tick
sb_run "git reset -q --soft HEAD~2 && git restore --staged b.txt c.txt"
sb_run "git status --short"
sb_run "git commit -i -m 'Staged plus b' b.txt"
sb_tick
sb_run "git status --short"
sb_write d.txt "d"
sb_run "git commit -m 'Untracked path' d.txt"
sb_run "git commit -i -m 'No path'"
sb_run "git commit -a -m 'Both' c.txt"
sb_run "printf 'c.txt\n' | git commit --pathspec-from-file=- -m 'From a list' && git status --short"
sb_tick
sb_write a.txt "a3"
sb_write b.txt "b3"
sb_run "printf 'a.txt\0b.txt\0' | git commit -q --pathspec-from-file=- --pathspec-file-nul -m 'From a NUL list' && git show --stat --oneline HEAD"
sb_tick
sb_write a.txt "a4"
sb_write b.txt "b4"
sb_run "git add a.txt"
sb_run "git add b.txt && git commit -q -m 'Add, then commit' && git show --stat --oneline HEAD"
sb_tick

sb_say "--- P3. choosing hunks ---"
sb_fresh "$SANDBOX_ROOT/hunks" >/dev/null
sb_write poem.txt one two three four five six seven eight nine ten
sb_commit "Add poem"
sb_write poem.txt ONE two three four five six seven eight nine TEN
sb_run "printf 'n\n' | git commit -p --inter-hunk-context=2 -m 'Nothing chosen'; echo \"exit \$?\""
sb_run "printf 'y\nn\n' | git commit -p -m 'Only the first line'"
sb_tick
sb_run "git status --short"
sb_run "printf 'n\n' | git commit -p -U0 -m 'Nothing chosen'"
sb_run "printf '5\n1\n\ny\nq\n' | git commit --interactive -m 'The last line'"
sb_tick

sb_say "--- P4. the editor and its template ---"
sb_fresh "$SANDBOX_ROOT/editor" >/dev/null
sb_write app.py "print('hello')"
sb_commit "Base"
sb_write app.py "print('hello')" "print('staged')"
git add app.py
sb_write app.py "print('hello')" "print('staged')" "print('unstaged')"
sb_write todo/one.txt "1"
sb_write todo/two.txt "2"
sb_run "GIT_EDITOR=cat git commit -v"
sb_run "GIT_EDITOR=cat git commit -vv"
sb_run "GIT_EDITOR=cat git -c commit.verbose=true commit"
sb_run "GIT_EDITOR=cat git commit -uall"
sb_run "GIT_EDITOR=cat git commit -uno"
sb_run "GIT_EDITOR=cat git commit --no-status"
sb_run "GIT_EDITOR=cat git -c commit.status=false commit --status"
printf 'Summary:\n\nWhy:\n' > .msg-template
sb_run "cat .msg-template"
sb_run "GIT_EDITOR=true git commit -t .msg-template"
sb_run "GIT_EDITOR=\"sed -i 's/^Summary:/Summary: Print a second line/'\" git commit -t .msg-template"
sb_tick
sb_run "git log -1 --format=%B"
sb_run "GIT_EDITOR=cat git -c commit.template=.msg-template commit --allow-empty -m 'Given with -m'"
sb_tick
sb_run "GIT_EDITOR=\"sed -i '1s/^/Edited: /'\" git commit -q -e --allow-empty -m 'Given with -m' && git log -1 --format=%B"
sb_tick
sb_run "git commit --allow-empty -m 'Given with -m' -F .msg-template"

sb_say "--- P5. messages from elsewhere ---"
sb_run "printf 'From a file\n\nWith a body.\n' > msg.txt && git commit --allow-empty -F msg.txt"
sb_tick
sb_run "echo 'From standard input' | git commit --allow-empty -F -"
sb_tick
sb_run "GIT_EDITOR=\"sed -i '1s/\$/, edited/'\" git commit --allow-empty -c HEAD"
sb_tick
sb_run "git log -2 --format='%h %s | %an | %ad'"
sb_run "git commit --allow-empty --reset-author -C HEAD~1"
sb_tick
sb_run "git log -1 --format='%h %s | %an | %ad'"

sb_say "--- P6. every cleanup mode ---"
sb_fresh "$SANDBOX_ROOT/cleanup" >/dev/null
printf '\n\nSubject   \n\n\n# a comment line\nBody text   \n\n\n' > messy.txt
sb_run "cat -A messy.txt"
for m in strip whitespace verbatim default; do
	sb_run "git commit -q --allow-empty --cleanup=$m -F messy.txt && git log -1 --format=%B | cat -A"
	sb_tick
done
printf 'Subject\n\nBody\n# ------------------------ >8 ------------------------\nEverything from the line above is cut\n' > scissors.txt
sb_run "cat scissors.txt"
sb_run "git commit -q --allow-empty --cleanup=scissors -F scissors.txt && git log -1 --format=%B | cat -A"
sb_tick
sb_run "GIT_EDITOR='cp scissors.txt' git commit -q --allow-empty --cleanup=scissors && git log -1 --format=%B | cat -A"
sb_tick
sb_run "GIT_EDITOR='cp messy.txt' git commit -q --allow-empty && git log -1 --format=%B | cat -A"
sb_tick
sb_run "GIT_EDITOR='cp messy.txt' git -c commit.cleanup=whitespace commit -q --allow-empty && git log -1 --format=%B | cat -A"
sb_tick
sb_run "git commit --allow-empty --cleanup=tidy -m 'Unknown mode'"
printf 'Fix the parser\n\n#42 was the report\n' > hash.txt
sb_run "cat hash.txt"
sb_run "GIT_EDITOR='cp hash.txt' git commit -q --allow-empty && git log -1 --format=%B"
sb_tick
sb_run "GIT_EDITOR='cp hash.txt' git -c core.commentChar=';' commit -q --allow-empty && git log -1 --format=%B"
sb_tick
sb_run "GIT_EDITOR=cat git -c 'core.commentString=;;' commit --allow-empty"

sb_say "--- P7. trailers ---"
sb_run "git commit -q --allow-empty -s -m 'Signed off' && git log -1 --format=%B"
sb_tick
sb_run "git commit -q --allow-empty --trailer 'Reviewed-by: Grace Hopper <grace@example.com>' --trailer 'Refs=#42' -m 'With trailers' && git log -1 --format=%B"
sb_tick
sb_run "git commit -q --allow-empty -s --no-signoff -m 'Not signed off' && git log -1 --format=%B"
sb_tick
sb_run "git commit -q --allow-empty -s --trailer 'Signed-off-by: Ada Lovelace <ada@example.com>' -m 'Signed off twice?' && git log -1 --format=%B"
sb_tick

sb_say "--- P8. who and when ---"
sb_fresh "$SANDBOX_ROOT/identity" >/dev/null
sb_write a.txt "a"
sb_commit "Base"
GIT_AUTHOR_NAME="Grace Hopper" GIT_AUTHOR_EMAIL="grace@example.com" git commit -q --allow-empty -m "By Grace"
sb_tick
sb_run "git commit -q --allow-empty --author=Grace -m 'Author found by search' && git log -1 --format='%an <%ae>'"
sb_tick
sb_run "git commit -q --allow-empty --author=Nobody -m 'No such author'"
sb_run "git commit -q --allow-empty --date='2025-12-24 18:00:00 +0100' -m 'Dated' && git log -1 --format='%ad | %cd'"
sb_tick
sb_run "git commit -q --allow-empty --date=bogus -m 'Bad date'"
sb_run "env -u GIT_AUTHOR_NAME -u GIT_AUTHOR_EMAIL git -c user.name=Configured -c user.email=me@work.example commit -q --allow-empty -m 'From config' && git log -1 --format='%an <%ae> / %cn <%ce>'"
sb_tick
sb_run "env -u GIT_COMMITTER_NAME -u GIT_COMMITTER_EMAIL git -c committer.name='Build Robot' -c committer.email=robot@example.com commit -q --allow-empty -m 'Committer from config' && git log -1 --format='%an <%ae> / %cn <%ce>'"
sb_tick
sb_run "env -u GIT_AUTHOR_NAME -u GIT_AUTHOR_EMAIL -u GIT_COMMITTER_NAME -u GIT_COMMITTER_EMAIL -u EMAIL git -c user.useConfigOnly=true commit --allow-empty -m 'Nobody'"

sb_say "--- P9. empty messages and amending, further ---"
sb_run "git commit -q --allow-empty --allow-empty-message -m '' && git log --format='%h [%s]' -1"
sb_tick
sb_write a.txt "a" "b"
sb_write b.txt "b"
git add a.txt b.txt
git commit -q -m "Two files"
sb_tick
sb_write c.txt "c"
sb_run "git add c.txt"
sb_run "git commit --amend --only -m 'Two files, reworded' && git status --short"
sb_tick
sb_run "git commit -q --amend --reset-author --no-edit && git log -1 --format='%h %an %ad'"
sb_tick
sb_fresh "$SANDBOX_ROOT/amendroot" >/dev/null
sb_write a.txt "a"
sb_commit "First"
sb_run "git commit --amend -m 'First, amended' && git log --oneline"
sb_tick
sb_fresh "$SANDBOX_ROOT/amendnothing" >/dev/null
sb_run "git commit --amend -m 'Nothing to amend'"

sb_say "--- P10. commits meant to be squashed ---"
sb_fresh "$SANDBOX_ROOT/fixups" >/dev/null
sb_write a.txt "a"
sb_commit "Add a"
sb_write b.txt "b"
sb_commit "Add b"
sb_write a.txt "a" "fix"
git add a.txt
sb_run "git commit -q --fixup=HEAD~1 && git log -1 --format=%B"
sb_tick
sb_run "git commit -q --allow-empty --squash=HEAD~2 -m 'Extra words' && git log -1 --format=%B"
sb_tick
sb_run "GIT_EDITOR=true git commit -q --fixup=reword:HEAD~3 && git log -1 --format=%B"
sb_tick
sb_run "git show --stat --oneline HEAD"
sb_write a.txt "a" "fix" "more"
git add a.txt
sb_run "GIT_EDITOR=\"sed -i '3s/.*/Add a, better/'\" git commit -q --fixup=amend:HEAD~4 && git log -1 --format=%B"
sb_tick
sb_run "git log --oneline"

sb_say "--- P11. hooks ---"
sb_fresh "$SANDBOX_ROOT/hooks" >/dev/null
sb_write a.txt "a"
sb_commit "Base"
printf '#!/bin/sh\necho "pre-commit: refusing, TODO found" >&2\nexit 1\n' > .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
sb_run "cat .git/hooks/pre-commit"
sb_write a.txt "a" "TODO"
git add a.txt
sb_run "git commit -m 'Blocked'; echo \"exit \$?\""
sb_run "git commit -n -m 'Skipped the hook'"
sb_tick
rm .git/hooks/pre-commit
printf '#!/bin/sh\ngrep -q "^Refs: " "$1" || { echo "commit-msg: add a Refs: line" >&2; exit 1; }\n' > .git/hooks/commit-msg
chmod +x .git/hooks/commit-msg
sb_run "cat .git/hooks/commit-msg"
sb_write a.txt "a" "b"
git add a.txt
sb_run "git commit -m 'No refs'; echo \"exit \$?\""
sb_run "cat .git/COMMIT_EDITMSG"
sb_run "git commit --no-verify -m 'No refs, not checked'"
sb_tick
printf '#!/bin/sh\necho "prepare-commit-msg: message from $2" >&2\n' > .git/hooks/prepare-commit-msg
chmod +x .git/hooks/prepare-commit-msg
printf '#!/bin/sh\necho "post-commit: exiting with 1" >&2\nexit 1\n' > .git/hooks/post-commit
chmod +x .git/hooks/post-commit
printf '#!/bin/sh\necho "post-rewrite: after $1" >&2\n' > .git/hooks/post-rewrite
chmod +x .git/hooks/post-rewrite
sb_write a.txt "a" "b" "c"
git add a.txt
sb_run "git commit -q --no-verify -m 'Three hooks'; echo \"exit \$?\""
sb_tick
sb_write a.txt "a" "b" "c" "d"
git add a.txt
sb_run "git commit -q --no-verify --amend --no-edit"
sb_tick
sb_write a.txt "a" "b" "c" "d" "e"
git add a.txt
sb_run "git commit -q --no-verify --amend --no-edit --no-post-rewrite"
sb_tick

sb_say "--- P12. a dry run ---"
sb_fresh "$SANDBOX_ROOT/dryrun" >/dev/null
sb_write a.txt "a"
sb_write b.txt "b"
sb_commit "Base"
sb_write a.txt "a2"
sb_write b.txt "b2"
sb_write new.txt "n"
git add a.txt
sb_run "git commit --dry-run; echo \"exit \$?\""
sb_run "git commit --short; echo \"exit \$?\""
sb_run "git commit --porcelain"
sb_run "git commit --short --branch"
sb_run "git commit --long -uno"
sb_run "git commit -z | tr '\0' '@'; echo"
sb_run "git commit --dry-run -a --short"
sb_run "git commit --dry-run --short b.txt"
sb_run "git log --oneline"

sb_say "--- P13. finishing a merge ---"
sb_fresh "$SANDBOX_ROOT/merge" >/dev/null
sb_write a.txt "one"
sb_write b.txt "one"
sb_commit "Base"
git switch -q -c side
sb_write a.txt "side"
sb_commit "Side"
git switch -q main
sb_write a.txt "main"
sb_commit "Main"
sb_run "git merge side"
sb_write a.txt "resolved"
sb_write b.txt "also changed"
sb_run "git commit -m 'Merge' a.txt"
sb_run "git commit -i -m 'Merge side' a.txt"
sb_tick
sb_run "git log --oneline --graph"
sb_run "git status --short"

sb_say "--- P14. signing turned off for one commit ---"
sb_run "git -c commit.gpgSign=true commit -q --allow-empty --no-gpg-sign -m 'Not signed' && git log -1 --format=%s"
sb_tick

sb_say "--- P15. undoing a commit, and the plumbing underneath ---"
sb_fresh "$SANDBOX_ROOT/undo" >/dev/null
sb_write a.txt "a"
sb_commit "Base"
sb_write a.txt "a" "b"
git add a.txt
git commit -q -m "Wrong message"
sb_tick
sb_run "git reset --soft HEAD~1 && git status --short"
sb_run "git commit -q -m 'Right message' && git log --oneline"
sb_tick
sb_run "git commit-tree -p HEAD -m 'Made by commit-tree' HEAD^{tree}"
sb_run "git log --oneline"
