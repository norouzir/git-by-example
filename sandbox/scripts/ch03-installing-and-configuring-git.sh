#!/bin/bash
# Generates every transcript in Chapter 3, "Installing and Configuring Git".
#
#   bash sandbox/scripts/ch03-installing-and-configuring-git.sh [dir]
#
# No `set -e`: a commit is shown failing for want of an identity.
#
# The chapter runs `git config set --global`, so this script must never use the
# harness's own global file, sandbox/lib/gitconfig: every command here writes to
# a global file of its own inside the scratch directory, and HOME points there
# too. Two such files are used, because the chapter first shows a configured
# machine and then a fresh one: `configured.gitconfig` with a name, an email and
# `init.defaultBranch`, and `fresh.gitconfig`, empty at the start. The system
# level stays switched off, as in every generator (Chapter 2).
#
# The failed commit prints the machine's user name and host name; they are
# rewritten to <user> and <hostname>, the one edit Chapter 2 allows.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null
R="$SANDBOX_ROOT"
export HOME="$R/home"
mkdir -p "$HOME"

# sb_run_private <command> : sb_run, with the machine's user and host names
# rewritten in the output
sb_run_private() {
	local user host
	user="$(id -un 2>/dev/null || echo "${USERNAME:-}")"
	host="$(hostname)"
	printf '$ %s\n' "$*" | sb_filter
	eval "$@" 2>&1 | sb_filter | sed -e "s/$user/<user>/g" -e "s/$host/<hostname>/g"
}

# ---------------------------------------------------------------------------
sb_say "Checking what you have"
cd "$R"
sb_run "git --version"
sb_run "git version"

# ---------------------------------------------------------------------------
# A configured machine.
export GIT_CONFIG_GLOBAL="$HOME/configured.gitconfig"
printf '[user]\n\tname = Ada Lovelace\n\temail = ada@example.com\n[init]\n\tdefaultBranch = main\n' > "$GIT_CONFIG_GLOBAL"
mkdir -p "$R/project" && cd "$R/project" && git init -q

sb_say "The four configuration levels"
sb_run 'git config set user.email "ada@widget.example"'
sb_run "git config list --show-scope"
sb_run "git config get user.email"
sb_run "git config get --global user.email"
sb_run "git config unset user.email"
sb_run "git config get user.email"

sb_say "Two ways to write every config command"
sb_run 'git config set --global user.name "Ada Lovelace"'

# ---------------------------------------------------------------------------
# A fresh machine: no global settings, and no identity from the harness.
export GIT_CONFIG_GLOBAL="$HOME/fresh.gitconfig"
: > "$GIT_CONFIG_GLOBAL"
unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL EMAIL
mkdir -p "$R/fresh" && cd "$R/fresh" && git init -q 2>/dev/null
sb_write notes.txt "first"
git add notes.txt

sb_say "The one setting you must have"
sb_run_private 'git commit -m "First"'
sb_run 'git config set --global user.name "Ada Lovelace"'
sb_run 'git config set --global user.email "ada@example.com"'

sb_say "The default branch name"
cd "$R"
sb_run "git init demo1"
sb_run "git config set --global init.defaultBranch main"
sb_run "git init demo2"

sb_say "The editor"
sb_run 'git config set --global core.editor "nano"'

sb_say "Credentials"
sb_run "git config set --global credential.helper manager"
