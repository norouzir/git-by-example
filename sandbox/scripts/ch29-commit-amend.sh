#!/bin/bash
# Generates every transcript in Chapter 29, "commit --amend".
#
#   bash sandbox/scripts/ch29-commit-amend.sh [dir]
#
# No `set -e`: many commands are shown refusing on purpose.
#
# Git only opens an editor when standard input and output are a terminal, which
# the sandbox never is. Commands that would open one therefore say --no-edit,
# -m, or set GIT_EDITOR in the printed command, so that what a reader types
# behaves the way the transcript shows.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null

# Every demonstration starts from the same place: the branch `try` recreated at
# main, a clean working tree and an empty index. The reader sees the switch;
# the checkout and clean before it only undo whatever the previous example left
# behind, so that the printed command produces the printed output.
fresh() {
	git checkout -qf --detach main
	git clean -qfdx
	sb_run "${1:-git switch -q -C try main}"
}

# ---------------------------------------------------------------------------
# A bakery's order book.
sb_fresh "$SANDBOX_ROOT/orders" >/dev/null
sb_write README.md "# Order book"
sb_commit "Start the order book"
sb_write bread.md "Sourdough 12" "Rye 10"
sb_commit "Add the bread list"
sb_write cakes.md "Carrot 20"
sb_commit "Add the cake list"
git tag v1
git branch -q keep

git switch -q -c pastry HEAD~1
sb_write pastry.md "Croissant 4"
sb_commit "Add the pastry list"
git switch -q main

sb_say "The example repository"
sb_run "git log --oneline --graph --all --decorate"
sb_run "git show --stat --oneline HEAD"

# ---------------------------------------------------------------------------
sb_say "Changing the message"
git checkout -qf --detach main; git clean -qfdx; sb_run "git switch -C try main"
sb_run "git commit --amend -m 'Add the cake list, with prices'"; sb_tick
sb_run "git log --oneline -2"

sb_say "The editor amend opens"
sb_run "GIT_EDITOR=cat git commit --amend"; sb_tick

sb_say "Keeping the message"
sb_run "git commit --amend --no-edit"; sb_tick

sb_say "A message from a file, or from another commit"
sb_write msg.txt "Add the cake list" "" "Prices are per cake, not per slice."
sb_run "git commit --amend -q -F msg.txt && git log -1 --format=%B"; sb_tick
rm msg.txt
sb_run "git commit --amend -q -C pastry && git log -1 --format='%s | %an %ad'"; sb_tick
sb_run "GIT_EDITOR=cat git commit --amend -q -c pastry"; sb_tick
sb_run "GIT_EDITOR=cat git commit --amend -q -e -m 'Add the cake list'"; sb_tick
sb_run "git log -1 --format=%s"

# ---------------------------------------------------------------------------
sb_say "Changing what the commit contains"
fresh "git switch -q -C try main && git show --stat --oneline HEAD"
sb_write cakes.md "Carrot 20" "Lemon 18"
sb_run "git add cakes.md"
sb_run "git commit --amend --no-edit"; sb_tick
sb_run "git show --stat --oneline HEAD"

sb_say "Amending without staging first"
sb_write cakes.md "Carrot 20" "Lemon 18" "Coffee and walnut 19"
sb_run "git commit --amend -a --no-edit"; sb_tick
sb_run "git show --stat --oneline HEAD"

sb_say "Taking a file back out of the commit"
fresh "git switch -q -C try main"
sb_write tarts.md "Bakewell 16"
sb_write prices.ods.tmp "a spreadsheet Git should not have"
sb_run "git add -A && git commit -q -m 'Add the tart list' && git show --stat --oneline HEAD"; sb_tick
sb_run "git rm --cached -q prices.ods.tmp && git commit --amend --no-edit"; sb_tick
sb_run "git show --stat --oneline HEAD"
sb_run "git status --short"
rm prices.ods.tmp

sb_say "Amending some of what is staged"
fresh "git switch -q -C try main"
sb_write cakes.md "Carrot 20" "Lemon 18"
sb_write bread.md "Sourdough 12" "Rye 10" "Focaccia 9"
sb_run "git add cakes.md bread.md && git status --short"
sb_run "git commit --amend --only -m 'Add the cake list, priced'"; sb_tick
sb_run "git status --short"

sb_say "Amending what is staged plus one more file"
fresh "git switch -q -C try main"
sb_write cakes.md "Carrot 20" "Lemon 18"
sb_write bread.md "Sourdough 12" "Rye 10" "Focaccia 9"
sb_run "git add cakes.md && git status --short"
sb_run "git commit --amend --include bread.md --no-edit"; sb_tick
sb_run "git show --stat --oneline HEAD && git status --short"

sb_say "Amending a path from the working tree"
fresh "git switch -q -C try main"
sb_write cakes.md "Carrot 20" "Lemon 18"
sb_write bread.md "Sourdough 12" "Rye 10" "Focaccia 9"
sb_run "git commit --amend --no-edit -- cakes.md"; sb_tick
sb_run "git show --stat --oneline HEAD && git status --short"

# ---------------------------------------------------------------------------
sb_say "What amend keeps and what it replaces"
fresh "git switch -q -C try main && git log -1 --pretty=fuller"
sb_run "git log -1 --format='commit %h  tree %t  parent %p'"
sb_write cakes.md "Carrot 20" "Lemon 18"
sb_run "git commit --amend -q -a --no-edit && git log -1 --pretty=fuller"; sb_tick
sb_run "git log -1 --format='commit %h  tree %t  parent %p'"
sb_run "git log --oneline --decorate --all"

# ---------------------------------------------------------------------------
sb_say "Authorship and dates"
fresh "git switch -q -C try main && git log -1 --format='%an <%ae> %ad'"
sb_run "git commit --amend -q --author='Mary Berry <mary@example.com>' --no-edit && git log -1 --pretty=fuller"; sb_tick
sb_run "git commit --amend -q --reset-author --no-edit && git log -1 --pretty=fuller"; sb_tick
sb_run "git commit --amend -q --date='2026-03-01 09:00:00 +0000' --no-edit && git log -1 --format='%ad | %cd'"; sb_tick

# ---------------------------------------------------------------------------
sb_say "Amending a merge"
fresh "git switch -q -C try main && git merge --no-edit pastry"; sb_tick
sb_run "git log -1 --format='%h  parents %p  %s'"
sb_run "git commit --amend -q -m 'Merge the pastry list into the order book'"; sb_tick
sb_run "git log -1 --format='%h  parents %p  %s'"
sb_run "git log --oneline --graph -4"

# ---------------------------------------------------------------------------
sb_say "Amending the first commit"
sb_run "git switch --orphan first-draft"
sb_write notes.md "Ideas for next season."
sb_run "git add notes.md && git commit -q -m 'Start the ideas list' && git log -1 --format='%h  parents [%p]  %s'"; sb_tick
sb_run "git commit --amend -q -m 'Start a list of ideas' && git log -1 --format='%h  parents [%p]  %s'"; sb_tick

# ---------------------------------------------------------------------------
sb_say "When amend refuses: nothing to amend"
sb_run "git switch --orphan nothing-yet"
sb_run "git commit --amend -m 'anything'"
git switch -q main

sb_say "When amend refuses: a merge in progress"
fresh "git switch -q -C try main && git switch -q -c rival main~1"
sb_write cakes.md "Battenberg 22"
sb_commit "A different cake list"
sb_run "git switch -q try && git merge rival"
sb_run "git commit --amend --no-edit"
sb_run "git merge --abort"

sb_say "When amend refuses: a cherry-pick in progress"
sb_run "git cherry-pick rival"
sb_run "git commit --amend --no-edit"
sb_run "git cherry-pick --abort"

sb_say "When amend refuses: a rebase stopped on a conflict"
sb_run "git rebase rival"
sb_run "git commit --amend --no-edit"
sb_run "git rebase --abort"

sb_say "When amend would empty the commit"
fresh "git switch -q -C try main && git rm -q cakes.md"
sb_run "git commit --amend --no-edit"
sb_run "git commit --amend --no-edit --allow-empty"; sb_tick
sb_run "git show --stat --oneline HEAD"

sb_say "Amending with no message"
fresh "git switch -q -C try main"
sb_write cakes.md "Carrot 20" "Lemon 18"
sb_run "git commit --amend -q -a --allow-empty-message -m '' && git log -2 --format='[%s]'"; sb_tick

sb_say "Amending when HEAD is detached"
fresh "git switch -q -C try main && git switch -q --detach"
sb_write cakes.md "Carrot 20" "Lemon 18"
sb_run "git commit --amend -q -a --no-edit && git log --oneline -1"; sb_tick
sb_run "git status -sb"
sb_run "git log --oneline --decorate -1 try"

# ---------------------------------------------------------------------------
sb_say "Undoing an amend"
fresh "git switch -q -C try main"
sb_write cakes.md "Carrot 20" "Lemon 18"
sb_run "git commit --amend -q -a -m 'Add the cake list, priced' && git log --oneline -1"; sb_tick
sb_run "git reflog show try -3"
sb_run "git reset --hard try@{1}"
sb_run "git log --oneline -1 && git show --stat --oneline HEAD"

sb_say "Keeping the new content and the old message"
sb_write cakes.md "Carrot 20" "Lemon 18"
sb_run "git commit --amend -q -a -m 'Cakes' && git log -1 --format=%s"; sb_tick
sb_run "git commit --amend -q -C try@{1} && git log -1 --format=%s && git show --stat --oneline HEAD"; sb_tick

# ---------------------------------------------------------------------------
sb_say "Hooks"
cat > .git/hooks/post-rewrite <<'HOOK'
#!/bin/sh
echo "post-rewrite: $1"
cat
HOOK
chmod +x .git/hooks/post-rewrite
fresh "git switch -q -C try main && git commit --amend -q -m 'Cakes, and a hook' && git log --oneline -1"; sb_tick
sb_run "git commit --amend -q --no-post-rewrite -m 'Cakes, without the hook' && git log --oneline -1"; sb_tick
rm .git/hooks/post-rewrite

cat > .git/hooks/prepare-commit-msg <<'HOOK'
#!/bin/sh
echo "# the hook was called with: $2 $3" >> "$1"
HOOK
chmod +x .git/hooks/prepare-commit-msg
sb_run "GIT_EDITOR=cat git commit --amend"; sb_tick
rm .git/hooks/prepare-commit-msg

# ---------------------------------------------------------------------------
sb_say "amend and reset --soft"

fresh "git switch -q -C try main"
sb_write cakes.md "Carrot 20" "Lemon 18"
sb_run "git add cakes.md && git commit --amend -q --no-edit && git rev-parse HEAD"
sb_settime
sb_run "git switch -q -C try2 main"
sb_write cakes.md "Carrot 20" "Lemon 18"
sb_run "git add cakes.md && git reset -q --soft HEAD^ && git commit -q -C ORIG_HEAD && git rev-parse HEAD"
sb_tick

sb_say "Where the two stop being the same"
sb_run "git switch -q -C try3 main && git merge --no-edit pastry"; sb_tick
sb_run "git log -1 --format='%h  parents %p'"
sb_run "git reset -q --soft HEAD^ && git commit -q -C ORIG_HEAD && git log -1 --format='%h  parents %p'"; sb_tick
