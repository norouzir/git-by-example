#!/bin/bash
# Proves the claim Chapter 2 makes: the same commands produce the same commit
# hashes, in a different directory, at a different moment in real time.
#
#   bash sandbox/scripts/selftest-reproducibility.sh
#
# Exits non-zero if the two runs disagree.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

build_once() {
	# shellcheck source=../lib/sandbox.sh
	. "$HERE/../lib/sandbox.sh"
	sb_root "$1" >/dev/null
	sb_fresh "$SANDBOX_ROOT/demo" >/dev/null

	sb_write README.md "# Widget" "" "A small thing."
	sb_commit "Add README"

	sb_write src/app.py "print('hi')"
	sb_commit "Add the app"

	git log --oneline
	git rev-parse HEAD HEAD~1
}

one="$(mktemp -d)"
two="$(mktemp -d)"

echo "===== RUN 1 ====="
first="$(build_once "$one")"
echo "$first"

echo
echo "===== RUN 2 ====="
second="$(build_once "$two")"
echo "$second"

echo
if test "$first" = "$second"
then
	echo "OK: both runs produced identical hashes."
else
	echo "FAIL: the two runs disagree." >&2
	diff <(echo "$first") <(echo "$second") >&2 || true
	exit 1
fi
