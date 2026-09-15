#!/bin/bash
# Generates every transcript in Chapter 23, "branch".
#
#   bash sandbox/scripts/ch23-branch.sh [dir]
#
# No `set -e`: many commands are shown failing on purpose.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null
# %(committerdate:relative) counts from "now".
sb_pin_now

# ---------------------------------------------------------------------------
# A small web site, first built in a scratch repository and pushed to a server.
git init -q --bare "$SANDBOX_ROOT/server.git"
sb_fresh "$SANDBOX_ROOT/start" >/dev/null
sb_write index.html "<h1>Welcom</h1>"
sb_commit "Add the home page"
sb_write style.css "h1 { color: navy; }"
sb_commit "Add a style sheet"
git switch -q -c docs main~1
sb_write README.md "# The site"
sb_commit "Write the README"
git switch -q -c release main~1
sb_write VERSION "1.0"
sb_commit "Prepare release 1.0"
git switch -q -c feature/search main
sb_write search.html "<input type=search>"
sb_commit "Add a search box"
git switch -q main
git push -q "$SANDBOX_ROOT/server.git" main docs release feature/search
START_NOW=$SANDBOX_NOW

# The chapter's repository is a clone of it.
cd "$SANDBOX_ROOT"
git clone -q "$SANDBOX_ROOT/server.git" site
cd site
SANDBOX_NOW=$START_NOW; sb_settime
git tag v1.0 origin/main
git switch -q -c fix-typo
sb_write index.html "<h1>Welcome</h1>"
sb_commit "Fix a typo on the home page"
git switch -q main
git merge -q --ff-only fix-typo
git switch -q -c old-idea main~1
sb_write style.css "body { background: black; }"
sb_commit "Try a dark theme"
git switch -q main
git branch -q feature/search origin/feature/search
git worktree add -q "$SANDBOX_ROOT/site-docs" docs
SITE_NOW=$SANDBOX_NOW
back_to_site() { cd "$SANDBOX_ROOT/site"; SANDBOX_NOW=$SITE_NOW; sb_settime; }

# =============================================================================
sb_say "--- B1. listing ---"
sb_run "git log --oneline --graph --all --decorate"
sb_run "git branch"
sb_run_ansi "git branch"
sb_run "git branch --list"
sb_run "git branch -l"
sb_run "git branch -v"
sb_run "git branch -vv"
sb_run_ansi "git branch -vv"
sb_run "git branch -v --abbrev=10"
sb_run "git branch -v --no-abbrev"
sb_run "git branch -r"
sb_run "git branch -a"
sb_run_ansi "git branch -a"
sb_run "git branch -r -v"
sb_run "git branch --list 'f*'"
sb_run "git branch --list 'f*' 'd*'"
sb_run "git branch -r --list 'origin/f*'"
sb_run "git branch -a --list '*search*'"
sb_run "git branch --list '*'"
sb_run "git branch --list *"
sb_run "echo *"
sb_run "git branch --list main"
sb_run "git branch --list nosuch; echo \"exit \$?\""
sb_run "git branch 'f*'"
sb_run "git branch HEAD"
sb_run "git branch --merged"
sb_run "git branch --merged old-idea"
sb_run "git branch --no-merged"
sb_run "git branch -a --no-merged"
sb_run "git branch --contains"
sb_run "git branch --contains main~1"
sb_run "git branch --no-contains fix-typo"
sb_run "git branch --points-at HEAD"
sb_run "git branch -a --points-at origin/docs"
sb_run "git branch --merged main --no-merged docs"
sb_run "git branch --merged nosuch"
sb_run "git branch --sort=-committerdate"
sb_run "git -c branch.sort=-committerdate branch"
sb_run "git branch --sort=-committerdate --format='%(committerdate:relative) %(refname:short)'"
sb_run "git branch --format='%(refname:short) -> %(upstream:short)'"
sb_run "git branch --format='%(if)%(upstream)%(then)%(refname:short)%(end)' --omit-empty"
sb_run "git branch Zebra"
sb_run "git branch"
sb_run "git branch -i"
sb_run "git branch -i --list 'z*'"
sb_run "git branch -q -d Zebra"
sb_run "git branch --column"
sb_run "COLUMNS=40 git branch --column=always"
sb_run "COLUMNS=40 git branch --column=column"
sb_run "COLUMNS=40 git branch --column=row"
sb_run "COLUMNS=40 git branch --column=plain"
sb_run "COLUMNS=30 git branch --column=always"
sb_run "COLUMNS=30 git branch --column=dense"
sb_run "COLUMNS=30 git branch --column=nodense"
sb_run "COLUMNS=30 git branch --column=row,dense"
sb_run "git branch --column=auto"
sb_run "git branch --column=never"
sb_run "git -c column.branch=always branch --no-column"
sb_run "git branch -v --column"
sb_run "git branch --color=always | cat -A"
sb_run "git branch --color | cat -A"
sb_run "git branch --color=auto | cat -A"
sb_run "git branch --color=never | cat -A"
sb_run "git branch --no-color | cat -A"
sb_run "git branch --show-current"
sb_run "git switch -q --detach HEAD~1"
git switch -q --detach HEAD~1
sb_run "git branch"
sb_run "git branch --show-current; echo \"exit \$?\""
sb_run "git commit -q --allow-empty -m 'An experiment'"
git commit -q --allow-empty -m 'An experiment'
sb_run "git branch"
sb_run "git switch -q main"
git switch -q main
sb_run "cd ../site-docs"
cd "$SANDBOX_ROOT/site-docs"
sb_run "git branch"
sb_run "cd ../site"
cd "$SANDBOX_ROOT/site"
sb_run "git init -q ../empty"
git init -q "$SANDBOX_ROOT/empty"
sb_run "cd ../empty"
cd "$SANDBOX_ROOT/empty"
sb_run "git branch; echo \"exit \$?\""
sb_run "git branch --show-current"
sb_run "git branch topic"
sb_run "cd ../site"
back_to_site

# =============================================================================
sb_say "--- B2. creating ---"
sb_run "git branch topic"
sb_run "git branch -v --list topic"
sb_run "git status | head -1"
sb_run "git branch hotfix v1.0"
sb_run "git branch -v --list hotfix"
sb_run "git branch topic v1.0"
sb_run "git branch -f topic v1.0"
sb_run "git branch -v --list topic"
sb_run "git branch -f main v1.0"
sb_run "git branch -f docs main"
sb_run "git branch start nosuch"
sb_run "git branch start 'HEAD^{tree}'"
sb_run "git branch base old-idea...main"
sb_run "git branch -v --list base"
sb_run "git branch fix-typo/v2"
sb_run "git branch search origin/feature/search"
sb_run "git branch search2 feature/search"
sb_run "git config get --all --show-names --regexp '^branch\\.search'"
sb_run "git branch --track search3 feature/search"
sb_run "git branch --track=direct search4 feature/search"
sb_run "git branch --track=inherit search5 feature/search"
sb_run "git branch --no-track search6 origin/feature/search"
sb_run "git branch -vv --list 'search*'"
sb_run "git config get --all --show-names --regexp '^branch\\.search'"
sb_run "git -c branch.autoSetupMerge=false branch s-false origin/docs"
sb_run "git -c branch.autoSetupMerge=true branch s-true main"
sb_run "git -c branch.autoSetupMerge=always branch s-always main"
sb_run "git -c branch.autoSetupMerge=inherit branch s-inherit feature/search"
sb_run "git -c branch.autoSetupMerge=simple branch s-simple origin/release"
sb_run "git -c branch.autoSetupMerge=simple branch release origin/release"
sb_run "git branch -vv --list 's-*' release"
sb_run "git -c branch.autoSetupRebase=always branch r-always origin/docs"
sb_run "git -c branch.autoSetupRebase=remote branch --track r-local main"
sb_run "git -c branch.autoSetupRebase=local branch --track r-local2 main"
sb_run "git -c branch.autoSetupRebase=never branch r-never origin/docs"
sb_run "git config get --all --show-names --regexp '^branch\\.r-'"
sb_run "git -c core.logAllRefUpdates=false branch no-log"
sb_run "git reflog show no-log; echo \"exit \$?\""
sb_run "git -c core.logAllRefUpdates=false branch --create-reflog with-log"
sb_run "git reflog show with-log"
sb_run "git branch --recurse-submodules sub-topic"
sb_run "git branch -q quiet origin/docs"
git branch -q -D search search2 search3 search4 search5 search6 s-false s-true s-always s-inherit s-simple release r-always r-local r-local2 r-never no-log with-log quiet hotfix base

# =============================================================================
sb_say "--- B3. upstream ---"
sb_run "git branch -vv --list topic"
sb_run "git branch -u origin/main topic"
sb_run "git branch -vv --list topic"
sb_run "git switch -q topic"
git switch -q topic
sb_run "git status | head -2"
sb_run "git rev-parse --abbrev-ref @{upstream}"
sb_run "git branch --unset-upstream"
sb_run "git status | head -2"
sb_run "git rev-parse --abbrev-ref @{upstream}"
sb_run "git branch --unset-upstream"
sb_run "git branch --set-upstream-to=origin/nosuch"
sb_run "git branch --set-upstream-to=main"
sb_run "git branch -vv --list topic"
sb_run "git config get --all --show-names --regexp '^branch\\.topic'"
sb_run "git branch --set-upstream origin/main"
sb_run "git switch -q main"
git switch -q main

# =============================================================================
sb_say "--- B4. renaming and copying ---"
sb_run "git branch -m topic feature/login"
sb_run "git branch -vv --list feature/login"
sb_run "git config get --all --show-names --regexp '^branch\\.feature/login'"
sb_run "git reflog show feature/login"
sb_run "git branch draft main"
sb_run "git branch -m feature/login draft"
sb_run "git branch -M feature/login draft"
sb_run "git branch -vv --list draft"
sb_run "git branch -m main trunk"
sb_run "git branch --show-current"
sb_run "git branch -m main"
sb_run "git branch --show-current"
sb_run "git branch -m docs manual"
sb_run "cd ../site-docs"
cd "$SANDBOX_ROOT/site-docs"
sb_run "git branch --show-current"
sb_run "cd ../site"
cd "$SANDBOX_ROOT/site"
sb_run "git branch -m manual docs"
sb_run "git branch -m nosuch other"
sb_run "git branch -m draft 'bad name'"
sb_run "git -c init.defaultBranch=master init -q ../old"
git -c init.defaultBranch=master init -q "$SANDBOX_ROOT/old"
sb_run "cd ../old"
cd "$SANDBOX_ROOT/old"
sb_run "git branch --show-current"
sb_run "git branch -m main"
sb_run "git branch --show-current"
sb_run "cd ../site"
back_to_site
sb_run "git branch -c fix-typo fix-typo-copy"
sb_run "git branch -c main main-backup"
sb_run "git branch --show-current"
sb_run "git branch -vv --list 'fix-typo*' 'main*'"
sb_run "git config get --all --show-names --regexp '^branch\\.main'"
sb_run "git branch -c fix-typo draft"
sb_run "git branch -C fix-typo draft"
sb_run "git branch -vv --list draft"

# =============================================================================
sb_say "--- B5. deleting ---"
sb_run "git branch -d fix-typo-copy draft"
sb_run "git branch -d main-backup"
sb_run "git branch --delete --force main-backup"
old=$(git rev-parse --short old-idea)
sb_run "git branch -d old-idea"
sb_run "git branch -D old-idea"
sb_run "git reflog show old-idea"
sb_run "git branch old-idea $old"
sb_run "git reflog | grep 'dark theme'"
sb_run "git reflog show old-idea"
sb_run "git branch -d main"
sb_run "git branch -D docs"
sb_run "git branch -d nosuch"
sb_run "git branch -d feature/search"
sb_run "git branch -d origin/docs"
sb_run "git branch -d -r origin/docs"
sb_run "git branch -r"
sb_run "git branch -vv --list docs"
sb_run "git branch -q -d fix-typo"
sb_run "git branch"

# =============================================================================
sb_say "--- B6. descriptions ---"
sb_run "GIT_EDITOR=cat git branch --edit-description old-idea"
sb_run "GIT_EDITOR=\"sed -i '1i A dark theme, on hold until the redesign.'\" git branch --edit-description old-idea"
sb_run "git config get branch.old-idea.description"
sb_run "git -c merge.branchdesc=true merge --no-ff --no-commit old-idea"
sb_run "cat .git/MERGE_MSG"
sb_run "git merge --abort"
sb_run "git -c merge.branchdesc=true merge --no-ff --no-commit --log old-idea"
sb_run "cat .git/MERGE_MSG"
sb_run "git merge --abort"
sb_run "git switch -q --detach"
git switch -q --detach
sb_run "GIT_EDITOR=cat git branch --edit-description"
sb_run "git switch -q main"
git switch -q main

# =============================================================================
sb_say "--- B7. neighbours ---"
sb_run "git show-branch main old-idea"
sb_run "git switch -c topic2"
sb_run "git checkout -b topic3"
sb_run "git switch -q main"
git switch -q main
sb_run "git update-ref refs/heads/raw HEAD"
sb_run "git branch --list raw"
