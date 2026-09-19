#!/bin/bash
# Generates every transcript in Chapter 2, "The Sandbox".
#
#   bash sandbox/scripts/ch02-the-sandbox.sh [dir]
#
# The example repository is the one the reproducibility self-test builds, so
# the hashes in this chapter are the self-test's: `demo`, with "Add README" at
# the sandbox clock's first moment. A bare repository beside it, `origin.git`,
# stands in for a server.
#
# The self-test itself is run from the root of the book's repository, as a
# reader would run it.

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null
R="$SANDBOX_ROOT"

sb_fresh "$R/demo" >/dev/null
sb_write README.md "# Widget" "" "A small thing."
sb_commit "Add README"

sb_say "Why hashes normally differ"
sb_run "git cat-file -p HEAD"
first="$(git rev-parse HEAD)"
sb_run "git log -1 --format='%H %cd'"
sb_run "GIT_COMMITTER_DATE='2026-01-05 09:00:01 +0000' git commit -q --amend --no-edit && git log -1 --format='%H %cd'"
git reset -q --hard "$first"

sb_say "Ignoring your configuration"
cd "$R"
sb_run "GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null git config list"

sb_say "Proof that it works"
( cd "$HERE/../.." && sb_run "bash sandbox/scripts/selftest-reproducibility.sh" )

sb_say "Remotes without a network"
cd "$R/demo"
sb_run "git init --bare ../origin.git"
sb_run "git remote add origin $R/origin.git"
sb_run "git push -u origin main"
sb_run "cd .."
cd "$R"
sb_run "git clone origin.git clone2"
sb_run "cd clone2"
cd "$R/clone2"
sb_run "git log --oneline"
sb_run "git remote -v"
