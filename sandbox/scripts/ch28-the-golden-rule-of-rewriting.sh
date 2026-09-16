#!/bin/bash
# Generates every transcript in Chapter 28, "The Golden Rule of Rewriting".
#
#   bash sandbox/scripts/ch28-the-golden-rule-of-rewriting.sh [dir]
#
# No `set -e`: several commands are shown being rejected on purpose.
#
# The chapter needs two clones of one repository, so the harness identity is
# switched with who() while the script works in the second clone. The remote is
# a bare repository on disk, so nothing here touches a network.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null

who() {
	export GIT_AUTHOR_NAME="$1" GIT_AUTHOR_EMAIL="$2"
	export GIT_COMMITTER_NAME="$1" GIT_COMMITTER_EMAIL="$2"
}
ada() { who "Ada Lovelace" "ada@example.com"; }
sam() { who "Sam Chen" "sam@example.com"; }

# ---------------------------------------------------------------------------
# The example repository: a shared server, Ada's clone, Sam's clone.
git init -q --bare "$SANDBOX_ROOT/server.git"
sb_fresh "$SANDBOX_ROOT/handbook" >/dev/null
# origin is spelled as a relative path so that the merge message `git pull`
# writes does not contain the scratch directory name, which would otherwise
# change the merge commit's hash on every run.
git remote add origin ../server.git
sb_write README.md "# Team handbook"
sb_commit "Start the handbook"
sb_write hours.md "Open 09:00 to 17:00."
sb_commit "Add the opening hours"
sb_write address.md "12 Baker Street."
sb_commit "Add the address"
git push -q -u origin main

# Ada's topic branch, pushed so that Sam can build on it.
git switch -q -c keys
sb_write keys.md "Spare key is in the top drawer."
sb_commit "Note where the spare key is"
sb_write keys.md "Spare key is in the top drawer." "The cabinet key is on the same ring."
sb_commit "Mention the cabinet key"
git push -q -u origin keys

# Sam clones, moves main on, and builds one commit on Ada's branch.
git clone -q "$SANDBOX_ROOT/server.git" "$SANDBOX_ROOT/handbook-sam"
cd "$SANDBOX_ROOT/handbook-sam"
git remote set-url origin ../server.git
sam
sb_write phone.md "Reception: 555 0101."
sb_commit "Add the phone number"
git push -q origin main
git switch -q -c keys origin/keys
sb_write alarm.md "The alarm code is on the key ring label."
sb_commit "Add a note about the alarm"
git push -q origin keys

cd "$SANDBOX_ROOT/handbook"
ada
git fetch -q origin

sb_say "The example repository"
sb_run "git log --oneline --graph --all --decorate"
sb_run "git log -2 --format='%h %an %s' origin/keys"

# ---------------------------------------------------------------------------
sb_say "What counts as rewriting"
git switch -q -c scratch main
sb_run "git log --oneline -2"
sb_run "git revert --no-edit HEAD"; sb_tick
sb_run "git log --oneline -3"
sb_run "git commit --amend -q -m 'Take the address out again, it was wrong' && git log --oneline -3"

# ---------------------------------------------------------------------------
sb_say "Why a rewritten commit is a new commit"
git switch -q keys
sb_run "git log --format='%h %p %s' -4"
old_tip=$(git rev-parse --short HEAD)
old_root=$(git rev-parse --short HEAD~1)
sb_run "git rebase origin/main"
sb_run "git log --format='%h %p %s' -4"

sb_say "Where the old commits go"
sb_run "git reflog -3"
sb_run "git cat-file -t $old_tip"
sb_run "git show -s --oneline $old_tip"
sb_run "git log --oneline -1 keys@{1}"

# ---------------------------------------------------------------------------
sb_say "Telling whether a commit has left your machine"
sb_run "git branch -r --contains $old_root"
sb_run "git branch -r --contains HEAD"
sb_run "git status -sb"
sb_run "git log --oneline HEAD..@{upstream}"
sb_run "git log --oneline @{upstream}..HEAD"
sb_run "git log --oneline --graph HEAD @{upstream}"

# ---------------------------------------------------------------------------
sb_say "What a rewrite does to someone else's clone"
sb_run "git push --force-with-lease origin keys"

sb_run "cd ../handbook-sam"
cd "$SANDBOX_ROOT/handbook-sam"
sam
sb_run "git fetch origin"
sb_run "git status -sb"
sam_old=$(git rev-parse --short HEAD)
sb_run "git pull --no-rebase --no-edit"; sb_tick
sb_run "git log --oneline --graph -7"
sb_run "git log --oneline --grep='Note where the spare key is'"

# ---------------------------------------------------------------------------
sb_say "When someone else rewrites under you"
sb_run "git reset --hard $sam_old"
sb_run "git rebase origin/keys"
sb_run "git log --oneline --graph -5"

sb_say "Saying where your own work starts"
sb_run "git reset --hard $sam_old"
sb_run "git rebase --onto origin/keys $sam_old~1"
sb_run "git log --oneline -5"
sb_run "git push -q origin keys && git log --oneline -1 origin/keys"

# ---------------------------------------------------------------------------
sb_say "Rewriting a branch other people use"
sb_run "cd ../handbook"
cd "$SANDBOX_ROOT/handbook"
ada
sb_write keys.md "Spare key is in the top drawer." "The cabinet key is on the same ring." "Both go back to reception at night."
sb_run "git add keys.md && git commit --amend -q --no-edit && git log --oneline -1"
sb_run "git push --force-with-lease origin keys"
sb_run "git fetch origin"
sb_run "git log --oneline HEAD..@{upstream}"

sb_say "What --force would have done"
git switch -q -c spike main
sb_write spike.md "Trying an idea."
sb_commit "Start a spike"
git push -q -u origin spike
old_spike=$(git rev-parse --short HEAD)
cd "$SANDBOX_ROOT/handbook-sam"
sam
git fetch -q origin
git switch -q -c spike origin/spike
sb_write spike.md "Trying an idea." "Sam tried it too."
sb_commit "Add to the spike"
sam_spike=$(git rev-parse --short HEAD)
git push -q origin spike
cd "$SANDBOX_ROOT/handbook"
ada
sb_write spike.md "Trying the idea again."
sb_run "git add spike.md && git commit --amend -q -m 'Start the spike again' && git log --oneline -1"
sb_run "git push --force-with-lease origin spike"
sb_run "git push --force origin spike"
sb_run "git -C $SANDBOX_ROOT/server.git log --oneline spike"
sb_run "git -C $SANDBOX_ROOT/server.git branch --contains $sam_spike"
git switch -q keys

sb_say "Backing out of the rewrite"
sb_run "git reset --hard origin/keys"
sb_write keys.md "Spare key is in the top drawer." "The cabinet key is on the same ring." "Both go back to reception at night."
sb_run "git commit -q -am 'Say when the keys go back' && git push -q origin keys"; sb_tick
sb_run "git log --oneline --graph -4"

# ---------------------------------------------------------------------------
sb_say "A rewrite does not delete anything"
sb_run "git cat-file -t $old_tip"
sb_run "git -C $SANDBOX_ROOT/server.git cat-file -t $old_tip"
sb_run "git -C $SANDBOX_ROOT/server.git log --oneline -1 $old_tip"
sb_run "git -C $SANDBOX_ROOT/server.git branch --contains $old_tip"

# ---------------------------------------------------------------------------
sb_say "Rewriting or a new commit"
sb_run "git log --oneline --graph -4 scratch"
