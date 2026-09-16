#!/bin/bash
# Generates every transcript in Chapter 32, "cherry-pick".
#
#   bash sandbox/scripts/ch32-cherry-pick.sh [dir]
#
# No `set -e`: many commands are shown refusing or conflicting on purpose.
#
# Git opens an editor only when it is talking to a terminal, which the sandbox
# never is, so commands that want one pass -e and set GIT_EDITOR.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null

# Each demonstration starts with the branch `try` recreated at release, with a
# clean working tree. The reader sees the switch; the checkout and clean before
# it only undo what the previous example left behind.
fresh() {
	git checkout -qf --detach release
	git clean -qfdx
	sb_run "${1:-git switch -q -C try release}"
}

# ---------------------------------------------------------------------------
# A small command-line tool, with a release branch that is behind main.
sb_fresh "$SANDBOX_ROOT/tool" >/dev/null
sb_write README.md "# wordcount"
sb_commit "Start the tool"
sb_write parser.py "def parse(line):" "    return line.split()"
sb_commit "Add the parser"

git switch -q -c release
sb_write VERSION "1.0"
sb_commit "Prepare release 1.0"
git switch -q main

sb_write parser.py "def parse(line):" "    if line is None:" "        return []" "    return line.split()"
sb_commit "Fix the crash on an empty line"
sb_write help.txt "Usage: wordcount FILE"
sb_commit "Add the help text"
sb_write help.txt "Usage: wordcount FILE" "Counts words, not characters."
sb_commit "Say what it counts"

git switch -q -c colour main~1
sb_write colour.py "RED = '31'"
sb_commit "Add colours"
git switch -q main
git merge -q --no-edit colour; sb_tick

sb_say "The example repository"
sb_run "git log --oneline --graph --all --decorate"
sb_run "git show --stat --oneline main~3"

# ---------------------------------------------------------------------------
sb_say "Copying one commit"
fresh
sb_run "git log --oneline -2"
sb_run "git cherry-pick main~3"; sb_tick
sb_run "git log --oneline -2"
sb_run "cat parser.py"

sb_say "What is kept and what changes"
sb_run "git log -1 --pretty=fuller"
sb_run "git log -1 --pretty=fuller main~3"
sb_run "git diff main~3 HEAD"

# ---------------------------------------------------------------------------
sb_say "Copying several commits"
fresh
sb_run "git cherry-pick main~3 main~2"; sb_tick; sb_tick
sb_run "git log --oneline -3"

sb_say "A range"
fresh
sb_run "git cherry-pick main~4..main~1"; sb_tick; sb_tick; sb_tick
sb_run "git log --oneline -4"

sb_say "Everything the other branch has that this one does not"
fresh
sb_run "git cherry-pick ..main~1"; sb_tick; sb_tick; sb_tick
sb_run "git log --oneline -4"

# ---------------------------------------------------------------------------
sb_say "Recording where the commit came from"
fresh
sb_run "git cherry-pick -x main~3"; sb_tick
sb_run "git log -1 --format=%B"

sb_say "Editing the message"
fresh
sb_run "GIT_EDITOR=cat git cherry-pick -e main~3"; sb_tick
sb_run "git log -1 --format=%s"

sb_say "Copying without committing"
fresh
sb_run "git cherry-pick -n main~3 main~2"
sb_run "git status --short"
sb_run "git commit -q -m 'Backport the crash fix and the help text' && git log --oneline -2"; sb_tick

sb_say "Signing off"
fresh
sb_run "git cherry-pick -s main~3 && git log -1 --format=%B"; sb_tick

# ---------------------------------------------------------------------------
sb_say "When the commit is already a descendant"
fresh
sb_run "git cherry-pick --ff main~3 && git log --oneline -2"; sb_tick
fresh "git switch -q -C try main~4"
sb_run "git log --oneline -1"
sb_run "git cherry-pick --ff main~3 && git log --oneline -2"
sb_run "git status --short --branch"

# ---------------------------------------------------------------------------
sb_say "A commit that is already here"
fresh
sb_run "git cherry-pick main~3"; sb_tick
sb_run "git cherry-pick main~3"
sb_run "git cherry-pick --abort"
sb_run "git log --oneline -2"

sb_say "Dropping it instead"
sb_run "git cherry-pick --empty=stop main~3"
sb_run "git cherry-pick --abort"
sb_run "git cherry-pick --empty=drop main~3 && git log --oneline -2"
sb_run "git cherry-pick --empty=keep main~3 && git log --oneline -3"; sb_tick
sb_run "git show --stat --oneline HEAD"

sb_say "A commit that was empty to start with"
fresh
sb_run "git switch -q -C empties main"
sb_run "git commit -q --allow-empty -m 'A deliberately empty commit' && git log --oneline -1"; sb_tick
sb_run "git switch -q try && git cherry-pick empties"
sb_run "git cherry-pick --allow-empty empties && git log --oneline -2"; sb_tick
sb_run "git show --stat --oneline HEAD"

# ---------------------------------------------------------------------------
sb_say "Copying a merge"
fresh
sb_run "git cherry-pick main"
sb_run "git cherry-pick -m 1 main"; sb_tick
sb_run "git log --oneline -2 && ls"
sb_run "git show --stat --oneline HEAD"

# ---------------------------------------------------------------------------
sb_say "When a cherry-pick conflicts"
fresh
sb_write parser.py "def parse(line):" "    return line.strip().split()"
sb_run "git commit -q -am 'Strip whitespace first' && git log --oneline -1"; sb_tick
sb_run "git cherry-pick main~3"
sb_run "git status --short --branch"
sb_run "git status | head -8"
sb_run "cat parser.py"
sb_run "git log --oneline -1 CHERRY_PICK_HEAD"
sb_run "git show --stat --oneline CHERRY_PICK_HEAD"

sb_say "Finishing the cherry-pick"
sb_write parser.py "def parse(line):" "    if line is None:" "        return []" "    return line.strip().split()"
sb_run "git add parser.py && git cherry-pick --continue --no-edit"; sb_tick
sb_run "git log --oneline -2 && cat parser.py"

sb_say "Abandoning it"
fresh
sb_write parser.py "def parse(line):" "    return line.strip().split()"
sb_run "git commit -q -am 'Strip whitespace first'"; sb_tick
sb_run "git cherry-pick main~3 main~2"
sb_run "git cherry-pick --skip"; sb_tick
sb_run "git log --oneline -3"
sb_run "git cherry-pick main~3"
sb_run "git cherry-pick --quit && git status --short"
sb_run "git reset -q --hard HEAD && git cherry-pick main~3"
sb_run "git cherry-pick --abort && git status --short && git log --oneline -1"

sb_say "Taking a side automatically"
fresh
sb_write parser.py "def parse(line):" "    return line.strip().split()"
sb_run "git commit -q -am 'Strip whitespace first'"; sb_tick
sb_run "git cherry-pick -Xtheirs main~3"; sb_tick
sb_run "git log --oneline -2 && cat parser.py"

sb_say "Another strategy"
fresh
sb_run "git cherry-pick --strategy=resolve main~3 && git log --oneline -1"; sb_tick

# ---------------------------------------------------------------------------
sb_say "Finding out what has already been copied"
fresh
sb_run "git cherry-pick -x main~3 main~2"; sb_tick; sb_tick
sb_run "git cherry -v main try"
sb_run "git cherry main try"
sb_run "git log --oneline --cherry-mark --left-right main...try"
sb_run "git log --oneline --cherry-pick --left-right main...try"
sb_run "git rev-list --count --cherry-pick --right-only main...try"

# ---------------------------------------------------------------------------
sb_say "When cherry-pick refuses"
fresh
sb_write parser.py "def parse(line):" "    return line.strip().split()"
sb_run "git cherry-pick main~3"
sb_run "git checkout -q -- . && git switch -q -c rival release"
sb_write VERSION "1.0.1"
sb_run "git commit -q -am 'Bump to 1.0.1'"; sb_tick
git switch -q try
sb_write VERSION "1.0-hotfix"
sb_run "git switch -q try && git commit -q -am 'Mark the hotfix' && git merge rival"; sb_tick
sb_run "git cherry-pick main~3"
sb_run "git merge --abort"

sb_say "Onto a branch with nothing in it"
sb_run "git switch -q --orphan nothing-yet && git cherry-pick main~3"
sb_run "git cherry-pick --abort"
sb_run "git cherry-pick --quit && git status --short --branch"
git switch -qf main
