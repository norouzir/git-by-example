#!/bin/bash
# Generates every transcript in Chapter 34, "Interactive Rebase".
#
#   bash sandbox/scripts/ch34-interactive-rebase.sh [dir]
#
# No `set -e`: several commands are shown refusing on purpose.
#
# An interactive rebase opens two editors: GIT_SEQUENCE_EDITOR on the todo list
# and GIT_EDITOR on a commit message. The sandbox is not a terminal, so every
# command that would open one sets them in the printed command, with `sed`
# standing in for the edit a reader would make by hand.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null

fresh() {
	git rebase --quit >/dev/null 2>&1
	git checkout -qf --detach main
	git clean -qfdx
	sb_run "git switch -q -C try ${1:-work}"
}

# ---------------------------------------------------------------------------
# A small parser project.
sb_fresh "$SANDBOX_ROOT/parser" >/dev/null
sb_write README.md "# parser"
sb_commit "Start the project"
sb_write parser.py "def parse(): pass"
sb_commit "Add the parser"

git switch -q -c work
sb_write reader.py "def read(): pass"
sb_commit "Add the reader"
sb_write reader.py "def read(): pass" "# reads a file"
sb_commit "Comment the reader"
sb_write writer.py "def write(): pass"
sb_commit "Add the writer"
sb_write formatter.py "def format(): pass"
sb_write linter.py "def lint(): pass"
sb_commit "Add the formatter and the linter"

# A branch with a merge in it, for --rebase-merges.
git switch -q -c topology main
sb_write cli.py "def main(): pass"
sb_commit "Add the command line"
git switch -q -c colours
sb_write colours.py "RED = 31"
sb_commit "Add colours"
git switch -q topology
sb_write cli.py "def main(): pass" "# entry point"
sb_commit "Comment the command line"
git merge -q --no-edit colours; sb_tick
sb_write cli.py "def main(): pass" "# entry point" "# coloured"
sb_commit "Say the output is coloured"

# Stacked branches, for update-ref.
git switch -q -c stack-a main
sb_write a.txt "first"
sb_commit "Add a.txt"
git switch -q -c stack-b
sb_write b.txt "second"
sb_commit "Add b.txt"

git switch -q main
sb_write parser.py "def parse(): pass" "# the parser"
sb_commit "Comment the parser"

sb_say "The example repository"
sb_run "git log --oneline --graph --all --decorate"
sb_run "git log --oneline main..work"

# ---------------------------------------------------------------------------
sb_say "The todo list"
fresh
sb_run "GIT_SEQUENCE_EDITOR=cat git rebase -i main"; sb_tick; sb_tick; sb_tick; sb_tick
sb_run "git log --oneline -5"

sb_say "Changing nothing"
fresh
sb_run "GIT_SEQUENCE_EDITOR=true git rebase -i HEAD~2"; sb_tick; sb_tick
sb_run "git log --oneline -3"

sb_say "Getting out"
fresh
sb_run "GIT_SEQUENCE_EDITOR=\"sed -i 's/^pick/# pick/'\" git rebase -i HEAD~2"
sb_run "git log --oneline -3"

# ---------------------------------------------------------------------------
sb_say "Reordering commits"
fresh
sb_run "git log --oneline -4"
sb_run "GIT_SEQUENCE_EDITOR=\"sed -i -e '1{h;d}' -e '2{G}'\" git rebase -i HEAD~3"; sb_tick; sb_tick; sb_tick
sb_run "git log --oneline -4"

sb_say "Dropping a commit"
fresh
sb_run "GIT_SEQUENCE_EDITOR=\"sed -i '2d'\" git rebase -i HEAD~3"; sb_tick; sb_tick
sb_run "git log --oneline -4"
fresh
sb_run "GIT_SEQUENCE_EDITOR=\"sed -i '2s/^pick/drop/'\" git rebase -i HEAD~3"; sb_tick; sb_tick
sb_run "git log --oneline -4"

# ---------------------------------------------------------------------------
sb_say "reword"
fresh
sb_run "GIT_SEQUENCE_EDITOR=\"sed -i '1s/^pick/reword/'\" GIT_EDITOR=\"sed -i '1s/.*/Comment the reader, saying what it reads/'\" git rebase -i HEAD~3"; sb_tick; sb_tick; sb_tick
sb_run "git log --oneline -4"

# ---------------------------------------------------------------------------
sb_say "edit"
fresh
sb_run "GIT_SEQUENCE_EDITOR=\"sed -i '1s/^pick/edit/'\" git rebase -i HEAD~3"
sb_run "git status --short --branch"
sb_write reader.py "def read(path): pass"
sb_run "git commit -q -a --amend --no-edit && git log --oneline -1"
sb_run "git rebase --continue"; sb_tick; sb_tick; sb_tick
sb_run "git log --oneline -4 && cat reader.py"

sb_say "Adding a commit at that point"
fresh
sb_run "GIT_SEQUENCE_EDITOR=\"sed -i '1s/^pick/edit/'\" git rebase -i HEAD~3"
sb_write CHANGELOG.md "- a reader"
sb_run "git add CHANGELOG.md && git commit -q -m 'Start a changelog' && git rebase --continue"; sb_tick; sb_tick; sb_tick; sb_tick
sb_run "git log --oneline -5"

# ---------------------------------------------------------------------------
sb_say "squash and fixup"
fresh
sb_run "GIT_SEQUENCE_EDITOR=\"sed -i '2s/^pick/squash/'\" GIT_EDITOR=cat git rebase -i HEAD~3"; sb_tick; sb_tick
sb_run "git log --oneline -3 && git log -1 --format=%B HEAD~1"
fresh
sb_run "GIT_SEQUENCE_EDITOR=\"sed -i '2s/^pick/fixup/'\" git rebase -i HEAD~3"; sb_tick; sb_tick
sb_run "git log --oneline -3 && git log -1 --format=%B HEAD~1"

sb_say "Keeping the fixup's message"
fresh
sb_run "GIT_SEQUENCE_EDITOR=\"sed -i '2s/^pick/fixup -C/'\" git rebase -i HEAD~3"; sb_tick; sb_tick
sb_run "git log --oneline -3"

# ---------------------------------------------------------------------------
sb_say "break"
fresh
sb_run "GIT_SEQUENCE_EDITOR=\"sed -i '1a break'\" git rebase -i HEAD~3"
sb_run "git log --oneline -2 && git status --short --branch"
sb_run "git rebase --continue"; sb_tick; sb_tick; sb_tick
sb_run "git log --oneline -4"

# ---------------------------------------------------------------------------
sb_say "Running a command after each commit"
fresh
sb_run "GIT_SEQUENCE_EDITOR=cat git rebase -i --exec 'ls *.py' HEAD~3"; sb_tick; sb_tick; sb_tick
sb_run "git log --oneline -4"

sb_say "When the command fails"
fresh
sb_run "GIT_SEQUENCE_EDITOR=true git rebase -i --exec 'test -f missing.py' HEAD~3"
sb_run "git status --short --branch && git log --oneline -1"
sb_write missing.py "def missing(): pass"
sb_run "git add missing.py && git commit -q --amend --no-edit && git rebase --continue"; sb_tick; sb_tick; sb_tick
sb_run "git log --oneline -4"

sb_say "Running it again after the fix"
fresh
sb_run "GIT_SEQUENCE_EDITOR=true git rebase -i --reschedule-failed-exec --exec 'test -f missing.py' HEAD~3"
sb_write missing.py "def missing(): pass"
sb_run "git add missing.py && git commit -q --amend --no-edit && git rebase --continue"; sb_tick; sb_tick; sb_tick
sb_run "git log --oneline -4"

# ---------------------------------------------------------------------------
sb_say "Splitting a commit"
fresh
sb_run "git show --stat --oneline HEAD"
sb_run "GIT_SEQUENCE_EDITOR=\"sed -i '3s/^pick/edit/'\" git rebase -i HEAD~3"
sb_run "git reset -q HEAD^ && git status --short"
sb_run "git add formatter.py && git commit -q -m 'Add the formatter'"; sb_tick
sb_run "git add linter.py && git commit -q -m 'Add the linter'"; sb_tick
sb_run "git rebase --continue"
sb_run "git log --oneline -5"

# ---------------------------------------------------------------------------
sb_say "update-ref in the todo list"
fresh stack-b
sb_run "GIT_SEQUENCE_EDITOR=cat git rebase -i --update-refs main"; sb_tick; sb_tick
sb_run "git log --oneline --decorate -4"

# ---------------------------------------------------------------------------
sb_say "Rebasing merges"
fresh topology
sb_run "git log --oneline --graph -5"
sb_run "GIT_SEQUENCE_EDITOR=true git rebase -i main"; sb_tick; sb_tick; sb_tick
sb_run "git log --oneline --graph -5"
fresh topology
sb_run "GIT_SEQUENCE_EDITOR=cat git rebase -i --rebase-merges main"; sb_tick; sb_tick; sb_tick; sb_tick
sb_run "git log --oneline --graph -6"

# ---------------------------------------------------------------------------
sb_say "Starting from the root"
fresh
sb_run "GIT_SEQUENCE_EDITOR=cat git rebase -i --root"; sb_tick; sb_tick; sb_tick; sb_tick; sb_tick; sb_tick
sb_run "git log --oneline -6"

# ---------------------------------------------------------------------------
sb_say "Editing the list after it has started"
fresh
sb_run "GIT_SEQUENCE_EDITOR=\"sed -i '1a break'\" git rebase -i HEAD~3"
sb_run "GIT_SEQUENCE_EDITOR=cat git rebase --edit-todo"
sb_run "GIT_SEQUENCE_EDITOR=\"sed -i '2s/^pick/drop/'\" git rebase --edit-todo && git rebase --continue"; sb_tick; sb_tick
sb_run "git log --oneline -4"

# ---------------------------------------------------------------------------
sb_say "When the todo list is wrong"
fresh
sb_run "GIT_SEQUENCE_EDITOR=\"sed -i '1s/^pick/pluck/'\" git rebase -i HEAD~3"
sb_run "git rebase --abort"
sb_run "GIT_SEQUENCE_EDITOR=\"sed -i '1d'\" git -c rebase.missingCommitsCheck=error rebase -i HEAD~3"
sb_run "git rebase --abort 2>&1 | tail -1"
sb_run "git log --oneline -4"

# ---------------------------------------------------------------------------
sb_say "Where the rebase keeps its state"
fresh
sb_run "GIT_SEQUENCE_EDITOR=\"sed -i '1a break'\" git rebase -i HEAD~3"
sb_run "ls .git/rebase-merge"
sb_run "cat .git/rebase-merge/git-rebase-todo"
sb_run "cat .git/rebase-merge/done"
sb_run "git switch -q main"
sb_run "git rebase --abort && git status --short --branch"
