#!/bin/bash
# Generates every transcript in Chapter 1, "How to Read This Book".
#
#   bash sandbox/scripts/ch01-how-to-read-this-book.sh [dir]
#
# The chapter shows three small examples of what a transcript looks like: a
# `git init`, a commit, and the version of Git the book was made with. The
# `my-project (main) $` prompt in the chapter is an illustration of a prompt,
# not a transcript, and has nothing to generate.

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null
R="$SANDBOX_ROOT"

sb_say "The three-layer rule"
cd "$R"
sb_run "git init my-project"

sb_say "How to read a transcript"
cd "$R/my-project"
sb_write README.md "# my-project"
sb_commit "Start the project"
sb_write src/parser.py "def parse(text):" "    words = text.split()" "    return words"
git add src
sb_run 'git commit -m "Add the parser"'

sb_say "Version badges"
sb_run "git --version"
