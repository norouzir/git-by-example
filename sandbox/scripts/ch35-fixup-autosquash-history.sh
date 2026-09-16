#!/bin/bash
# Generates every transcript in Chapter 35, "fixup, autosquash, and git history".
#
#   bash sandbox/scripts/ch35-fixup-autosquash-history.sh [dir]
#
# No `set -e`: several commands are shown refusing on purpose.
#
# Editors are set in the printed command, as in Chapter 34: GIT_SEQUENCE_EDITOR
# for a todo list, GIT_EDITOR for a message.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null

# `git history` moves every branch that descends from the commit it rewrites,
# `work` included, so each demonstration puts `work` back where it started.
fresh() {
	git rebase --quit >/dev/null 2>&1
	git checkout -qf --detach main
	git clean -qfdx
	git branch -qf work "$WORK_TIP"
	sb_run "git switch -q -C try ${1:-work}"
}

# ---------------------------------------------------------------------------
# A small tool.
sb_fresh "$SANDBOX_ROOT/tool" >/dev/null
sb_write README.md "# tool"
sb_commit "Start the tool"

git switch -q -c work
sb_write config.py "def read_config(): return {}"
sb_commit "Add the config reader"
sb_write logger.py "def log(msg): print(msg)"
sb_commit "Add the loger"
sb_write cache.py "def cache(): pass"
sb_commit "Add the cache"
WORK_TIP=$(git rev-parse HEAD)
git switch -q main

sb_say "The example repository"
sb_run "git log --oneline --graph --all --decorate"
sb_run "git show --stat --oneline work~1"

# ---------------------------------------------------------------------------
sb_say "Making a fixup commit"
fresh
sb_write config.py "def read_config(): return {}" "" "def write_config(c): pass"
sb_run "git add config.py && git commit -q --fixup=HEAD~1 && git log --oneline -4"; sb_tick
sb_run "git log -1 --format=%B"

sb_say "Naming the target another way"
fresh
sb_write config.py "def read_config(): return {}" "" "def write_config(c): pass"
target=$(git rev-parse --short HEAD~1)
sb_run "git add config.py && git commit -q --fixup=$target && git log -1 --format=%s"; sb_tick
fresh
sb_write config.py "def read_config(): return {}" "" "def write_config(c): pass"
sb_run "git add config.py && git commit -q --fixup=:/loger && git log -1 --format=%s"; sb_tick

sb_say "Making a squash commit"
fresh
sb_write config.py "def read_config(): return {}" "" "def write_config(c): pass"
sb_run "git add config.py && git commit -q --squash=HEAD~1 -m 'and a writer too' && git log -1 --format=%B"; sb_tick

sb_say "Replacing the message too"
fresh
sb_write config.py "def read_config(): return {}" "" "def write_config(c): pass"
sb_run "git add config.py && GIT_EDITOR=cat git commit -q --fixup=amend:HEAD~1"; sb_tick
sb_run "git log -1 --format=%B"
fresh
sb_run "GIT_EDITOR=\"sed -i '3s/.*/Add the logger/'\" git commit -q --fixup=reword:HEAD~1 && git log -1 --format=%B"; sb_tick
sb_run "git show --stat --oneline HEAD"

# ---------------------------------------------------------------------------
sb_say "Folding them in"
fresh
sb_write config.py "def read_config(): return {}" "" "def write_config(c): pass"
sb_run "git add config.py && git commit -q --fixup=:/config"; sb_tick
sb_write logger.py "def log(msg): print(msg)" "def warn(msg): print(msg)"
sb_run "git add logger.py && git commit -q --fixup=:/loger && git log --oneline -5"; sb_tick
sb_run "GIT_SEQUENCE_EDITOR=cat git rebase -i --autosquash main"; sb_tick; sb_tick; sb_tick
sb_run "git log --oneline -4"
sb_run "git show --stat --oneline HEAD~1"

sb_say "Without the editor"
fresh
sb_write config.py "def read_config(): return {}" "" "def write_config(c): pass"
sb_run "git add config.py && git commit -q --fixup=HEAD~1"; sb_tick
sb_run "git rebase --autosquash main"; sb_tick; sb_tick
sb_run "git log --oneline -4"

sb_say "Turning it on for good"
fresh
sb_write config.py "def read_config(): return {}" "" "def write_config(c): pass"
sb_run "git add config.py && git commit -q --fixup=HEAD~1"; sb_tick
sb_run "GIT_SEQUENCE_EDITOR=cat git -c rebase.autoSquash=true rebase -i main | head -5"; sb_tick; sb_tick

sb_say "Turning it off again"
fresh
sb_write config.py "def read_config(): return {}" "" "def write_config(c): pass"
sb_run "git add config.py && git commit -q --fixup=HEAD~1"; sb_tick
sb_run "GIT_SEQUENCE_EDITOR=cat git -c rebase.autoSquash=true rebase -i --no-autosquash main | head -5"; sb_tick; sb_tick

sb_say "Where the rebase has to start"
fresh
sb_write config.py "def read_config(): return {}" "" "def write_config(c): pass"
sb_run "git add config.py && git commit -q --fixup=HEAD~2"; sb_tick
sb_run "GIT_SEQUENCE_EDITOR=cat git rebase -i --autosquash HEAD~2 | head -4"
sb_run "GIT_SEQUENCE_EDITOR=cat git rebase -i --autosquash HEAD~4 | head -5"; sb_tick; sb_tick; sb_tick
sb_run "git log --oneline -4"

sb_say "Writing the marker by hand"
fresh
sb_write config.py "def read_config(): return {}" "" "def write_config(c): pass"
sb_run "git add config.py && git commit -q -m 'fixup! Add the config reader'"; sb_tick
sb_run "git rebase --autosquash main"; sb_tick; sb_tick
sb_run "git log --oneline -4"

sb_say "When the target is ambiguous"
fresh
sb_write notes.md "one"
sb_run "git commit -q -am 'Add the cache' --allow-empty && git log --oneline -4"; sb_tick
sb_write config.py "def read_config(): return {}" "" "def write_config(c): pass"
sb_run "git add config.py && git commit -q -m 'fixup! Add the cache'"; sb_tick
sb_run "GIT_SEQUENCE_EDITOR=cat git rebase -i --autosquash main | head -6"

# ---------------------------------------------------------------------------
sb_say "git history fixup"
fresh
sb_run "git log --oneline -4"
sb_write config.py "def read_config(): return {}" "" "def write_config(c): pass"
sb_run "git add config.py && git history fixup HEAD~1"; sb_tick
sb_run "git log --oneline -4 && git show --stat --oneline HEAD~1"
sb_run "git log -1 --pretty=fuller HEAD~1"

sb_say "Seeing what it would do first"
fresh
sb_write config.py "def read_config(): return {}" "" "def write_config(c): pass"
sb_run "git add config.py && git history fixup --dry-run HEAD~1"
sb_run "git log --oneline -4"

sb_say "Changing the message as well"
fresh
sb_write config.py "def read_config(): return {}" "" "def write_config(c): pass"
sb_write ../message.txt "Add the logger, and the config writer"
sb_run "git add config.py && GIT_EDITOR='cp ../message.txt' git history fixup --reedit-message HEAD~1"; sb_tick
sb_run "git log --oneline -4"

sb_say "When the fixup empties the commit"
fresh
sb_run "git show HEAD~1 | git apply -R && git add -A && git status --short"
sb_run "git history fixup --empty=drop HEAD~1"; sb_tick
sb_run "git log --oneline -4"
fresh
sb_run "git show HEAD~1 | git apply -R && git add -A && git history fixup --empty=keep HEAD~1"; sb_tick
sb_run "git log --oneline -4 && git show --stat --oneline HEAD~1"
fresh
sb_run "git show HEAD~1 | git apply -R && git add -A && git history fixup --empty=abort HEAD~1"
sb_run "git log --oneline -4"

sb_say "git history reword"
fresh
sb_write ../message.txt "Add the logger"
sb_run "GIT_EDITOR='cp ../message.txt' git history reword HEAD~1"; sb_tick
sb_run "git log --oneline -4"

sb_say "git history split"
fresh
sb_write parser.py "def parse(): pass"
sb_write printer.py "def show(): pass"
sb_run "git add -A && git commit -q -m 'Add the parser and the printer' && git show --stat --oneline HEAD"; sb_tick
sb_run "printf 'y\nn\n' | GIT_EDITOR=true git history split HEAD; echo"
sb_run "git log --oneline -3"
sb_run "git show --stat --oneline HEAD && git show --stat --oneline HEAD~1"
sb_write ../message.txt "Add the parser"
sb_run "GIT_EDITOR='cp ../message.txt' git history reword HEAD~1 && git log --oneline -3"; sb_tick

sb_say "Which branches move"
fresh
sb_run "git branch -q later && git log --oneline --decorate -2"
sb_write config.py "def read_config(): return {}" "" "def write_config(c): pass"
sb_run "git add config.py && git history fixup --update-refs=head HEAD~1"; sb_tick
sb_run "git log --oneline --decorate -3 && git log --oneline --decorate -1 later"
git branch -qD later
fresh
sb_run "git branch -q later && git log --oneline --decorate -1"
sb_write config.py "def read_config(): return {}" "" "def write_config(c): pass"
sb_run "git add config.py && git history fixup --update-refs=branches HEAD~1"; sb_tick
sb_run "git log --oneline --decorate -3"
git branch -qD later

sb_say "What git history refuses"
fresh
git switch -q -c side main
sb_write side.py "def side(): pass"
sb_commit "Add a side file"
git switch -q try
sb_run "git merge --no-edit side"; sb_tick
sb_run "git history reword HEAD~1"
sb_run "git log --oneline --graph -4"
fresh
sb_write logger.py "def log(msg): print(msg, flush=True)"
sb_run "git add logger.py && git history fixup HEAD~2"
sb_run "git log --oneline -3"

# ---------------------------------------------------------------------------
sb_say "Checking a rewrite with range-diff"
fresh
before=$(git rev-parse --short HEAD)
sb_write config.py "def read_config(): return {}" "" "def write_config(c): pass"
sb_run "git add config.py && git history fixup HEAD~1"; sb_tick
sb_run "git range-diff main $before HEAD"
sb_run "git range-diff --no-patch main $before HEAD"

sb_say "A smaller change, seen as a change"
fresh
before=$(git rev-parse --short HEAD)
sb_write ../message.txt "Add the logger"
sb_run "GIT_EDITOR='cp ../message.txt' git history reword HEAD~1"; sb_tick
sb_run "git range-diff main $before HEAD"
sb_run "git range-diff --no-patch main $before HEAD"
