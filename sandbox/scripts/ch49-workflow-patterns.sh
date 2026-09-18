#!/bin/bash
# Generates every transcript in Chapter 49, "Workflow Patterns".
#
#   bash sandbox/scripts/ch49-workflow-patterns.sh [dir]
#
# No `set -e`: a push is shown being rejected, `git flow` is shown failing, and
# `git branch -d` refuses a squash-merged branch.
#
# Three repositories, one per family of workflows:
#
#   atlas    a bare "server" with clones for Ada and Bob; working on `main`
#            alone, topic branches, the ways a branch lands, and a release
#            branch in the trunk-based style. Every command runs in Ada's
#            clone; Bob commits and pushes out of sight with `bob_push`. The
#            clones reach the server by the relative URL ../server/atlas.git,
#            because merge messages name the URL and an absolute sandbox path
#            would change their hashes on every run.
#   flow     Git flow's branches, built with the commands its article gives.
#   gitgit   Git's own integration branches, from gitworkflows(7).
#
# `sb_fresh` restarts the clock, so the separate repositories come after the
# atlas is finished and nothing returns to it.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null
R="$SANDBOX_ROOT"

# bob_push <branch> <file> <message> <line>... : Bob brings <branch> up to
# date with the server (creating it from main if it is new), commits a file on
# it, and pushes it.
bob_push() {
	local branch="$1" file="$2" message="$3"; shift 3
	( cd "$R/bob" && git fetch -q origin &&
	  if git rev-parse -q --verify "origin/$branch" >/dev/null
	  then git switch -q -C "$branch" "origin/$branch"
	  else git switch -q -C "$branch" origin/main
	  fi &&
	  sb_write "$file" "$@" && git add -A &&
	  git commit -q -m "$message" && git push -q origin "$branch" ) >/dev/null 2>&1
	sb_tick
}
# ada_commit <file> <message> <line>... : a commit in Ada's clone, not shown
ada_commit() {
	local file="$1" message="$2"; shift 2
	sb_write "$file" "$@" && git add -A && git commit -q -m "$message"
	sb_tick
}

# ---------------------------------------------------------------------------
sb_fresh "$R/work" >/dev/null
sb_write README.md "# Atlas"
sb_commit "Start the atlas"
sb_write maps/europe.txt "Europe"
sb_commit "Add Europe"
git init -q --bare "$R/server/atlas.git"
git push -q "$R/server/atlas.git" main
cd "$R"
rm -rf work
git clone -q server/atlas.git bob
git clone -q server/atlas.git ada
git -C bob remote set-url origin ../server/atlas.git
cd ada
git remote set-url origin ../server/atlas.git

sb_say "The example repositories"
sb_run "git remote -v"
sb_run "git log --oneline --graph --all --decorate"

# ---------------------------------------------------------------------------
sb_say "Everyone on main"
bob_push main maps/asia.txt "Add Asia" "Asia"
ada_commit maps/africa.txt "Add Africa" "Africa"
ada_commit maps/africa.txt "Add Madagascar" "Africa" "Madagascar"
sb_run "git push"
sb_run "git pull --no-rebase"
sb_run "git log --oneline --graph"
sb_run "git log --oneline --first-parent"
sb_run "git reset -q --hard ORIG_HEAD && git pull --rebase"
sb_run "git log --oneline --graph"
sb_run "git push -q"

# ---------------------------------------------------------------------------
sb_say "Topic branches"
git switch -q -c oceania
ada_commit maps/oceania.txt "Add Australia" "Australia"
ada_commit maps/oceania.txt "Add New Zealand" "Australia" "New Zealand"
bob_push americas maps/americas.txt "Add the Americas" "The Americas"
bob_push main maps/antarctica.txt "Add Antarctica" "Antarctica"
sb_run "git fetch -q && git switch -q main && git merge -q --ff-only"
sb_run "git merge -q --no-ff --no-edit oceania"
sb_tick
sb_run "git merge -q --no-ff --no-edit origin/americas"
sb_tick
sb_run "git log --oneline --graph -9"
sb_run "git log --oneline --first-parent -4"
sb_run "git branch --merged && git branch -r --merged"
sb_run "git branch -d oceania && git push -q origin main :americas"

sb_say "Naming branches"
sb_run "git branch fix/asia && git branch fix"
git branch -q -D fix/asia

# ---------------------------------------------------------------------------
sb_say "How a finished branch lands"
git switch -q -c rivers
ada_commit maps/rivers.txt "Add the Nile" "Nile"
ada_commit maps/rivers.txt "Add the Amazon" "Nile" "Amazon"
git switch -q main
ada_commit maps/arctic.txt "Add the Arctic" "Arctic"
git push -q
sb_run "git log --oneline --graph --all -5"
sb_run "git switch -q -c by-merge main && git merge -q --no-ff --no-edit rivers"
sb_tick
sb_run "git switch -q -c by-squash main && git merge -q --squash rivers && git commit -q -m 'Add rivers'"
sb_tick
sb_run "git switch -q -c by-rebase rivers && git rebase -q main"
sb_tick
sb_run "git switch -q -c by-ff main~1 && git merge -q rivers"
sb_run "git log --oneline --graph main~1..by-merge"
sb_run "git log --oneline --graph main~1..by-squash"
sb_run "git log --oneline --graph main~1..by-rebase"
sb_run "git log --oneline --graph -3 by-ff"

sb_say "What each way leaves behind"
sb_run "git log --oneline --first-parent main..by-merge && echo --- && git log --oneline --first-parent main..by-rebase && echo --- && git log --oneline --first-parent main..by-squash"
sb_run "git branch --contains rivers"
sb_run "git cherry -v by-rebase rivers && git cherry -v by-squash rivers"
sb_run "git switch -q by-squash && git branch -d rivers"
sb_run "git log --oneline --ancestry-path=rivers~1 --merges rivers~1..by-merge"
git switch -q main
git branch -q -D by-merge by-squash by-rebase by-ff
git merge -q --no-ff --no-edit rivers
sb_tick
git branch -q -d rivers
git push -q

# ---------------------------------------------------------------------------
sb_say "Release branches in the trunk-based style"
sb_run "git switch -q -c release-1.0 && git push -q -u origin release-1.0 && git switch -q main"
ada_commit maps/europe.txt "Add Iceland" "Europe" "Iceland"
ada_commit maps/asia.txt "Fix the Asia map" "Asia" "Japan"
FIX="$(git rev-parse --short HEAD)"
sb_run "git switch -q release-1.0 && git cherry-pick -x $FIX"
sb_tick
sb_run "git cherry -v main release-1.0"
sb_run "git log --oneline main..release-1.0"
git switch -q main

# ---------------------------------------------------------------------------
sb_say "Environment branches"
# The atlas was last deployed three commits ago.
git branch production main~3
git push -q origin production
sb_run "git log --oneline origin/production..main"

# ---------------------------------------------------------------------------
sb_say "Git flow"
sb_fresh "$R/flow" >/dev/null
sb_write README.md "# Atlas"
sb_commit "Start the atlas"
sb_run "git flow init"
sb_run "git switch -q -c develop main"
sb_run "git switch -q -c add-asia develop"
sb_run "echo Aisa > asia.txt && git add asia.txt && git commit -q -m 'Add Asia'"
sb_tick
sb_run "git switch -q develop && git merge -q --no-ff --no-edit add-asia && git branch -d add-asia"
sb_tick
sb_run "git switch -q -c release-1.0 develop && echo 1.0 > VERSION && git add VERSION && git commit -q -m 'Bump version to 1.0'"
sb_tick
sb_run "git switch -q main && git merge -q --no-ff --no-edit release-1.0 && git tag -a 1.0 -m 'Atlas 1.0'"
sb_tick
sb_run "git switch -q develop && git merge -q --no-ff --no-edit release-1.0 && git branch -d release-1.0"
sb_tick
sb_run "git switch -q -c hotfix-1.0.1 main && echo 1.0.1 > VERSION && git commit -q -am 'Bump version to 1.0.1'"
sb_tick
sb_run "echo Asia > asia.txt && git commit -q -am 'Fix the spelling of Asia'"
sb_tick
sb_run "git switch -q main && git merge -q --no-ff --no-edit hotfix-1.0.1 && git tag -a 1.0.1 -m 'Atlas 1.0.1'"
sb_tick
sb_run "git switch -q develop && git merge -q --no-ff --no-edit hotfix-1.0.1 && git branch -d hotfix-1.0.1"
sb_tick
sb_run "git log --oneline --graph --all --decorate"
sb_run "git log --oneline --first-parent main"

# ---------------------------------------------------------------------------
sb_say "Git's own workflow"
sb_fresh "$R/gitgit" >/dev/null
sb_write README.md "# Atlas"
sb_commit "Start the atlas"
sb_write maps/asia.txt "Aisa"
sb_commit "Add Asia"
git branch -q -m main master
git tag -a v1.0 -m "Atlas 1.0"
git branch maint
sb_write maps/europe.txt "Europe"
sb_commit "Add Europe"
git branch next
git branch seen
sb_run "git branch"
sb_run "git log --oneline --graph --all --decorate"
sb_run "git switch -q -c ab/fix-asia maint && echo Asia > maps/asia.txt && git commit -q -am 'Fix the spelling of Asia'"
sb_tick
sb_run "git switch -q -c cd/oceania master && echo Oceania > maps/oceania.txt && git add maps && git commit -q -m 'Add Oceania'"
sb_tick
sb_run "git switch -q -c ef/rivers master && echo Nile > maps/rivers.txt && git add maps && git commit -q -m 'Add rivers'"
sb_tick
sb_run "git switch -q -C seen master && git merge -q --no-edit ab/fix-asia && git merge -q --no-edit cd/oceania && git merge -q --no-edit ef/rivers"
sb_tick
sb_run "git log --oneline --first-parent master..seen"
sb_run "git switch -q next && git merge -q --no-edit ab/fix-asia && git merge -q --no-edit cd/oceania"
sb_tick
sb_run "git branch --no-merged next"
sb_run "git switch -q -C seen master && git merge -q --no-edit ab/fix-asia && git merge -q --no-edit cd/oceania"
sb_tick
sb_run "git log --oneline --first-parent master..seen && git branch --no-merged seen"
sb_run "git switch -q master && git merge -q --no-ff --no-edit cd/oceania"
sb_tick
sb_run "git log --oneline master..next"
sb_run "git switch -q maint && git merge -q --no-ff --no-edit ab/fix-asia && git tag -a v1.0.1 -m 'Atlas 1.0.1'"
sb_tick
sb_run "git switch -q master && git merge -q --no-edit maint && git log --oneline master..maint"
sb_tick
sb_run "git log --oneline --graph master"
