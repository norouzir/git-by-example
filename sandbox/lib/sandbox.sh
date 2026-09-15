#!/bin/bash
# Shared harness for every example in "Git by Example".
#
# The promise the book makes is that a commit hash printed on the page is the
# exact hash a reader would get by typing the same commands. Meeting that
# promise means eliminating every source of variation:
#
#   identity      -> pinned author and committer
#   time          -> pinned clock that advances in fixed steps
#   configuration -> the reader's own config is ignored entirely
#   line endings  -> core.autocrlf off, so blob hashes match on every platform
#   paths         -> the scratch directory is rewritten to a stable fake path

SANDBOX_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Configuration isolation -------------------------------------------------
# git(1) documents that pointing these at a file replaces that config level
# entirely, so nothing from the machine running the script leaks into output.
export GIT_CONFIG_GLOBAL="${SANDBOX_GITCONFIG:-$SANDBOX_LIB/gitconfig}"
export GIT_CONFIG_SYSTEM=/dev/null

# --- Identity ----------------------------------------------------------------
export GIT_AUTHOR_NAME="Ada Lovelace"
export GIT_AUTHOR_EMAIL="ada@example.com"
export GIT_COMMITTER_NAME="Ada Lovelace"
export GIT_COMMITTER_EMAIL="ada@example.com"

# --- Clock -------------------------------------------------------------------
# 2026-01-05 09:00:00 +0000, a Monday. Every sb_tick advances it by one hour.
SANDBOX_EPOCH_START=1767603600
SANDBOX_TICK_SECONDS=3600
SANDBOX_NOW=$SANDBOX_EPOCH_START
SANDBOX_PIN_NOW=0

sb_settime() {
	export GIT_AUTHOR_DATE="@$SANDBOX_NOW +0000"
	export GIT_COMMITTER_DATE="@$SANDBOX_NOW +0000"
	if test "$SANDBOX_PIN_NOW" = 1
	then
		export GIT_TEST_DATE_NOW="$SANDBOX_NOW"
	fi
}

# sb_pin_now : make "now" the sandbox clock too, for every later command.
#
# Relative dates ("3 hours ago", --since="2 weeks ago", --date=human) are
# computed against the current time, so without this they change as real days
# pass and a transcript stops matching. GIT_TEST_DATE_NOW is the hook Git's own
# test suite uses to fix the current time. It is opt-in, because it also moves
# "now" for things such as `git gc --prune=now`, which compare against real file
# times.
sb_pin_now() {
	SANDBOX_PIN_NOW=1
	sb_settime
}
sb_tick() {
	SANDBOX_NOW=$((SANDBOX_NOW + ${1:-$SANDBOX_TICK_SECONDS}))
	sb_settime
}
sb_settime

# sb_touch <file>... : set file modification times to the current sandbox clock,
# for tools such as diff -u that print them
sb_touch() {
	touch -d "@$SANDBOX_NOW" "$@"
}

# --- Time zone ---------------------------------------------------------------
# Git stores an offset with every date, so its default output does not depend on
# the machine. But --date=local does, and so does every non-Git tool that prints
# a time, such as diff -u. Pinning the zone removes the last clock dependency.
export TZ=UTC

# --- Path normalisation ------------------------------------------------------
# Scratch directories have machine-specific names. Transcripts show a stable
# fake home instead. This is the only edit ever made to captured output.
SANDBOX_DISPLAY_HOME="/home/ada"
SANDBOX_ROOT=""

# sb_root <dir> : make <dir> the sandbox root and move into it
sb_root() {
	mkdir -p "$1" && cd "$1" || return 1
	SANDBOX_ROOT="$PWD"
	SANDBOX_ROOT_WIN="$(cygpath -m "$PWD" 2>/dev/null || printf '%s' "$PWD")"
}

sb_filter() {
	if test -n "$SANDBOX_ROOT"
	then
		sed -e "s|$SANDBOX_ROOT_WIN|$SANDBOX_DISPLAY_HOME|g" \
		    -e "s|$SANDBOX_ROOT|$SANDBOX_DISPLAY_HOME|g"
	else
		cat
	fi
}

# --- Building example repositories -------------------------------------------

# sb_fresh <dir> : delete and recreate <dir> as an empty repository, reset clock
sb_fresh() {
	rm -rf "$1" && mkdir -p "$1" && cd "$1" || return 1
	git init -q
	SANDBOX_NOW=$SANDBOX_EPOCH_START
	sb_settime
}

# sb_write <file> <line>... : write lines to a file, creating parent directories
sb_write() {
	f="$1"; shift
	mkdir -p "$(dirname "$f")"
	printf '%s\n' "$@" > "$f"
}

# sb_commit <message> : stage everything, commit at the current clock, then tick
sb_commit() {
	git add -A && git commit -q -m "$1" && sb_tick
}

# --- Capturing transcripts ---------------------------------------------------

# sb_run <command> : print the command as the book shows it, then its real output
sb_run() {
	printf '$ %s\n' "$*" | sb_filter
	eval "$@" 2>&1 | sb_filter
}

# sb_run_ansi <command> : like sb_run, but with colour forced on.
#
# Git only colours output when writing to a terminal, and the sandbox is not
# one. Forcing color.ui=always through the environment reproduces exactly what
# a reader sees on a terminal, without adding a flag to the printed command.
# Escape bytes are written as the two visible characters \e so the Markdown
# source stays readable; tools/build_html.py turns them back into colour.
sb_run_ansi() {
	printf '$ %s\n' "$*" | sb_filter
	GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=color.ui GIT_CONFIG_VALUE_0=always \
		eval "$@" 2>&1 | sb_filter | sed 's/\x1b/\\e/g'
}

# sb_say <text> : a blank line and a comment, for separating transcript sections
sb_say() {
	printf '\n# %s\n' "$*"
}
