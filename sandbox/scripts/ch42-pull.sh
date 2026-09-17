#!/bin/bash
# Generates every transcript in Chapter 42, "pull".
#
#   bash sandbox/scripts/ch42-pull.sh [dir]
#
# No `set -e`: many pulls are shown being refused, and a refused pull exits
# with status 1 or 128.
#
# Three repositories, as in Chapter 41: the team's bare "server", Bob's clone,
# which pushes the changes Ada then pulls, and Ada's clone, where every
# transcript runs. Bob's work is done out of sight with `bob_push`; the chapter
# says what he pushed before each pull that shows it. Both clones commit on the
# one sandbox clock, so the order below is what keeps the hashes stable.
#
# Several sections show different ways of pulling the same diverged history.
# Between them Ada's branch is put back with a quiet `git reset --hard`, which
# prints nothing, so each transcript starts from the state the chapter names.
# Every section that can stop half-way ends with its --abort, so that one
# unfinished merge cannot break the sections after it.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null
SERVER="$SANDBOX_ROOT/server/atlas.git"

# bob_push <file> <message> <line>... : Bob brings his branch up to date with
# the server, writes a file, commits, and pushes the branch he is on.
bob_push() {
	local file="$1" message="$2"; shift 2
	( cd "$SANDBOX_ROOT/bob" &&
	  { git pull -q --rebase origin "$(git branch --show-current)" || true; } &&
	  sb_write "$file" "$@" && git add -A &&
	  git commit -q -m "$message" && git push -q origin HEAD ) >/dev/null 2>&1
	sb_tick
}
bob() { ( cd "$SANDBOX_ROOT/bob" && eval "$@" ) >/dev/null 2>&1; }
# ada_commit <file> <message> <line>... : a commit in Ada's clone, not shown
ada_commit() {
	local file="$1" message="$2"; shift 2
	sb_write "$file" "$@" && git add -A && git commit -q -m "$message"
	sb_tick
}

# ---------------------------------------------------------------------------
sb_fresh "$SANDBOX_ROOT/bob" >/dev/null
sb_write README.md "# Atlas"
sb_commit "Start the atlas"
sb_write maps/europe.txt "Europe"
sb_commit "Add Europe"
git switch -q -c deserts
sb_write deserts.txt "Sahara"
sb_commit "List deserts"
git switch -q -c rivers main
sb_write rivers.txt "Danube"
sb_commit "List rivers"
git switch -q main
git init -q --bare "$SERVER"
git remote add origin "$SERVER"
git push -q origin main deserts rivers
git branch -q -u origin/main

cd "$SANDBOX_ROOT"
git clone -q "$SERVER" ada
cd ada
# A relative URL keeps the sandbox's real path out of merge messages, which
# pull writes as "Merge branch 'main' of <url>", and so out of their hashes.
git remote set-url origin ../server/atlas.git
git fetch -q

sb_say "The example repository"
sb_run "git remote -v"
sb_run "git log --oneline --graph --all --decorate"

# ---------------------------------------------------------------------------
sb_say "Reading the output"
bob_push maps/africa.txt "Add Africa" "Africa" "Sahara"
sb_run "git pull"
sb_run "git pull"

# ---------------------------------------------------------------------------
sb_say "What pull runs"
bob_push maps/asia.txt "Add Asia" "Asia"
sb_run "GIT_TRACE=1 git pull 2>&1 >/dev/null | grep -o 'run_command: git \(fetch\|merge\|rebase\).*'"
sb_run "git log --oneline -1 && git reflog -1"

# ---------------------------------------------------------------------------
sb_say "When the branches have diverged"
bob_push maps/americas.txt "Add the Americas" "Americas"
ada_commit notes.txt "Write a note" "Check the borders"
NOTE=$(git rev-parse HEAD)
sb_run "git pull; echo \"exit \$?\""
sb_run "git status -sb"
sb_run "git log --oneline --graph --all -4"

sb_say "Merging"
sb_run "git pull --no-rebase"
sb_run "git log --oneline --graph -4"
git reset -q --hard "$NOTE"

sb_say "Rebasing"
sb_run "git pull --rebase"
sb_run "git log --oneline --graph -4"
git reset -q --hard "$NOTE"

sb_say "Fast-forward only"
sb_run "git pull --ff-only; echo \"exit \$?\""

# ---------------------------------------------------------------------------
sb_say "Choosing a default"
sb_run "git config set pull.rebase true && git pull -q && git log --oneline -2"
git reset -q --hard "$NOTE"
sb_run "git pull --no-rebase -q && git log --oneline -1"
git reset -q --hard "$NOTE"
sb_run "git config set branch.main.rebase false && git pull -q && git log --oneline -1"
git reset -q --hard "$NOTE"
git config unset branch.main.rebase
git config unset pull.rebase

sb_say "Which setting wins"
sb_run "git -c pull.ff=only pull -q --rebase && git log --oneline -1"
git reset -q --hard "$NOTE"
sb_run "git pull -q --ff-only --rebase 2>&1 | tail -1"
sb_run "git -c pull.ff=only -c pull.rebase=true pull -q 2>&1 | tail -1"
sb_run "git pull -q --ff && git log --oneline -1"
git reset -q --hard "$NOTE"
sb_run "git pull --rebase=preserve; echo \"exit \$?\""
sb_run "git -c pull.rebase=sometimes pull; echo \"exit \$?\""

# ---------------------------------------------------------------------------
sb_say "Local merge commits"
git switch -q -c borders
ada_commit borders.txt "Draw the borders" "Borders"
git switch -q main
git merge -q --no-ff --no-edit borders
sb_tick
git branch -q -d borders
MERGED=$(git rev-parse HEAD)
sb_run "git log --oneline --graph -5"
sb_run "git pull -q --rebase && git log --oneline --graph -5"
git reset -q --hard "$MERGED"
sb_run "git pull -q --rebase=merges && git log --oneline --graph -6"
git reset -q --hard "$MERGED"

sb_say "Interactive"
sb_run "GIT_SEQUENCE_EDITOR=cat git pull --rebase=interactive"
git reset -q --hard "$NOTE"

sb_say "A rewritten upstream"
git pull -q --rebase
bob "sb_write maps/americas.txt Americas Canada && git commit -q -a --amend -m 'Add the Americas, with Canada' && git push -q -f origin main"
sb_tick
sb_run "git log --oneline --graph -3"
sb_run "git fetch && git rebase origin/main; echo \"exit \$?\""
sb_run "git rebase --abort"
sb_run "git merge-base --fork-point origin/main main"
sb_run "GIT_TRACE=1 git pull --rebase 2>&1 >/dev/null | grep -o 'run_command: git \(fetch\|merge\|rebase\).*'"
sb_run "git log --oneline --graph -3"
# Ada publishes her note, so that her main and the server's agree again.
git push -q origin main 2>/dev/null

# ---------------------------------------------------------------------------
sb_say "Uncommitted changes"
bob_push maps/asia.txt "Add the Gobi" "Asia" "Gobi"
sb_write notes.txt "Check the borders" "Check the rivers"
sb_run "git status --short && git pull --rebase; echo \"exit \$?\""
sb_run "git pull && git status --short"
bob_push maps/asia.txt "Add Tibet" "Asia" "Gobi" "Tibet"
sb_write maps/asia.txt "Asia" "Gobi" "Mongolia"
sb_run "git pull; echo \"exit \$?\""
git checkout -q -- maps/asia.txt notes.txt
git pull -q

sb_say "Untracked files"
bob_push maps/oceania.txt "Add Oceania" "Oceania"
sb_write maps/oceania.txt "My Oceania"
sb_run "git status --short && git pull; echo \"exit \$?\""
rm maps/oceania.txt
git pull -q

sb_say "Autostash"
bob_push maps/asia.txt "Add Nepal" "Asia" "Gobi" "Tibet" "Nepal"
sb_write notes.txt "Check the borders" "Check the rivers"
sb_run "git pull --rebase --autostash && git status --short"
bob_push maps/oceania.txt "Add Fiji" "Oceania" "Fiji"
sb_run "git config set pull.autoStash true && git pull --rebase && git status --short"
git config unset pull.autoStash
bob_push notes.txt "Check the seas" "Check the borders" "Check the seas"
sb_run "git pull --autostash; echo \"exit \$?\""
sb_run "git status --short && git stash list"
sb_run "printf 'Check the borders\nCheck the rivers\nCheck the seas\n' > notes.txt && git restore --staged notes.txt && git stash drop && git status --short"
git checkout -q -- notes.txt

# ---------------------------------------------------------------------------
sb_say "When a pull stops with a conflict"
bob_push maps/europe.txt "Add France" "Europe" "France"
ada_commit maps/europe.txt "Add Spain" "Europe" "Spain"
sb_run "git pull --no-rebase; echo \"exit \$?\""
sb_run "git pull; echo \"exit \$?\""
sb_run "printf 'Europe\nFrance\nSpain\n' > maps/europe.txt && git add maps/europe.txt && git pull; echo \"exit \$?\""
sb_run "git merge --abort && git log --oneline -1"
sb_run "git pull --rebase; echo \"exit \$?\""
sb_run "git rebase --abort && git log --oneline -1"
git reset -q --hard origin/main

# ---------------------------------------------------------------------------
sb_say "Pulling a particular branch"
bob "git switch -q deserts"
bob_push deserts.txt "Add the Gobi desert" "Sahara" "Gobi"
bob "git switch -q main"
sb_run "git switch -q deserts && git branch -vv --list deserts"
sb_run "git pull && git pull --no-rebase -n origin main && git log --oneline --graph -4"
git switch -q main
git branch -q -D deserts

sb_say "Several branches at once"
sb_run "git pull --no-rebase origin deserts rivers && git log --oneline --graph -4"
git reset -q --hard origin/main
sb_run "git pull --rebase origin deserts rivers; echo \"exit \$?\""

sb_say "From a URL"
bob "git switch -q -c lakes main"
bob_push lakes.txt "List lakes" "Baikal"
bob "git switch -q main"
sb_run "git pull --no-rebase ../server/atlas.git lakes && git branch -r --list origin/lakes"
git reset -q --hard origin/main
git fetch -q

sb_say "From this repository"
git branch -q deserts origin/deserts
sb_run "git pull --no-rebase . deserts && git log --oneline --graph -4"
git reset -q --hard origin/main
git branch -q -D deserts

# ---------------------------------------------------------------------------
sb_say "When pull does not know what to merge"
sb_run "git switch -q -c maps && git pull; echo \"exit \$?\""
sb_run "git pull --set-upstream origin main && git branch -vv --list maps"
git switch -q main
git branch -q -D maps
sb_run "git remote add bob-fork ../server/atlas.git && git pull bob-fork; echo \"exit \$?\""
git remote remove bob-fork
sb_run "git switch -q --detach && git pull; echo \"exit \$?\""
git switch -q main
git push -q origin main:old-idea 2>/dev/null
git switch -q -c old-idea
git branch -q -u origin/old-idea
bob "git push -q origin --delete old-idea"
sb_run "git pull; echo \"exit \$?\""
git switch -q main
git branch -q -D old-idea
git fetch -q --prune
sb_run "git pull origin 'refs/heads/nosuch/*:refs/remotes/origin/nosuch/*'; echo \"exit \$?\""

# ---------------------------------------------------------------------------
sb_say "Pulling into an empty repository"
cd "$SANDBOX_ROOT"
git init -q fresh
cd fresh
sb_run "git remote add origin ../server/atlas.git && git pull origin deserts rivers; echo \"exit \$?\""
sb_run "git pull origin main && git log --oneline -2 && git status -sb"
cd "$SANDBOX_ROOT/ada"

# ---------------------------------------------------------------------------
sb_say "Fetch options through pull"
bob_push maps/antarctica.txt "Add Antarctica" "Antarctica"
sb_run "git pull --dry-run && git log --oneline -1 && git log --oneline -1 origin/main"
sb_run "git pull -q && git log --oneline -1"

sb_say "Appending to FETCH_HEAD"
bob "git switch -q deserts"
bob_push deserts.txt "Add the Atacama" "Sahara" "Gobi" "Atacama"
bob "git switch -q main"
bob_push maps/arctic.txt "Add the Arctic" "Arctic"
sb_run "git fetch origin deserts && git pull --append --no-rebase && cat .git/FETCH_HEAD"
sb_run "git log --oneline --graph -4"
git reset -q --hard ORIG_HEAD
sb_run "git pull --no-rebase && git log --oneline -1"

sb_say "Into the current branch"
bob_push maps/islands.txt "Add islands" "Islands"
sb_run "git pull origin main:main"

# ---------------------------------------------------------------------------
sb_say "Unrelated histories"
( sb_fresh "$SANDBOX_ROOT/gazetteer" >/dev/null && sb_write places.txt "Paris" &&
  git add -A && git commit -q -m "Start the gazetteer" ) >/dev/null
sb_run "git pull --no-rebase ../gazetteer main; echo \"exit \$?\""
sb_run "git pull --no-rebase --allow-unrelated-histories ../gazetteer main && git log --oneline --graph -3"
git reset -q --hard origin/main

# ---------------------------------------------------------------------------
sb_say "Undoing a pull"
bob_push maps/volcanoes.txt "Map the volcanoes" "Etna"
ada_commit notes.txt "Write another note" "Check the borders" "Check the seas" "Check the volcanoes"
sb_run "git pull --no-rebase && git reset --hard ORIG_HEAD && git reflog -2"
sb_run "git pull -q --rebase && git log --oneline -2 && git reset --hard ORIG_HEAD"
sb_run "git status -sb"

# ---------------------------------------------------------------------------
sb_say "pull and its neighbours"
sb_run "git pull -q --no-rebase && git rev-parse HEAD"
git reset -q --hard ORIG_HEAD
sb_run "git merge -q FETCH_HEAD && git rev-parse HEAD"
git reset -q --hard ORIG_HEAD
sb_run "git merge -q origin/main && git rev-parse HEAD && git log --format=%s -1"
git reset -q --hard ORIG_HEAD
