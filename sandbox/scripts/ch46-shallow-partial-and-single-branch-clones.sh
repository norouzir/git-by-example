#!/bin/bash
# Generates every transcript in Chapter 46, "Shallow, Partial, and
# Single-Branch Clones".
#
#   bash sandbox/scripts/ch46-shallow-partial-and-single-branch-clones.sh [dir]
#
# No `set -e`: several commands are shown failing.
#
# One bare "server" repository with three branches, a merge, two annotated tags
# and a data file large enough for a size filter, and many clones of it, each
# made the way its section describes. Shallow and partial clones need the real
# transport, so every clone uses a file:// URL (Chapter 9). The server allows
# filters, as a hosting service does.
#
# `sb_run` runs its command in a subshell, so a `cd` inside it does not last;
# every change of directory here is a plain `cd` of its own.
#
# Lazy fetches are counted from GIT_TRACE=1, which prints each command Git starts
# twice, as a `run_command:` line and a `start_command:` line. Counting both
# doubles every number, so the greps match `run_command:` only.
#
# "A filter the server chooses" changes the server and pushes a commit to it,
# so it runs last; every other section clones the server as it was built.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null
R="$SANDBOX_ROOT"
URL="file://$R/server/atlas.git"
LAZY="run_command: .*noop fetch"

# elevation <lines> <step> : a data file of <lines> lines, about 22 bytes each
elevation() {
	for i in $(seq 1 "$1"); do printf 'point %04d height %d\n' "$i" "$((i * $2 % 997))"; done
}

# ---------------------------------------------------------------------------
sb_fresh "$R/work" >/dev/null
sb_write README.md "# Atlas"
sb_commit "Start the atlas"
sb_write maps/europe.txt "Europe"
sb_commit "Add Europe"
mkdir -p data && elevation 300 7 > data/elevation.txt
sb_commit "Add the elevation data"
git tag -a v1.0 -m "First edition"
sb_write maps/asia.txt "Asia"
sb_commit "Add Asia"
git switch -q -c rivers
sb_write rivers.txt "Nile"
sb_commit "List rivers"
git switch -q main
elevation 320 11 > data/elevation.txt
sb_commit "Update the elevation data"
sb_write docs/guide/intro.md "How to read the atlas"
sb_commit "Write the guide"
git merge -q --no-ff -m "Merge branch 'rivers'" rivers
sb_tick
sb_write maps/africa.txt "Africa"
sb_commit "Add Africa"
git tag -a v2.0 -m "Second edition"
sb_write maps/oceania.txt "Oceania"
sb_commit "Add Oceania"
git switch -q -c drafts HEAD~2
sb_write drafts.txt "An idea"
sb_commit "Draft an idea"
git switch -q main
git init -q --bare "$R/server/atlas.git"
git push -q "$R/server/atlas.git" main rivers drafts v1.0 v2.0
git -C "$R/server/atlas.git" config set uploadpack.allowFilter true
cd "$R"
rm -rf work

sb_say "The example repository"
sb_run "git -C server/atlas.git log --oneline --graph --all --decorate"
sb_run "git -C server/atlas.git cat-file -s v1.0:data/elevation.txt && git -C server/atlas.git cat-file -s v2.0:data/elevation.txt"
sb_run "git clone --filter=blob:none server/atlas.git local"

# ---------------------------------------------------------------------------
sb_say "What a shallow clone has"
sb_run "git clone -q --depth 3 $URL shallow"
cd "$R/shallow"
sb_run "git log --oneline --graph --decorate --all"
sb_run "git branch -a && git tag && cat .git/shallow && git rev-parse --is-shallow-repository"

sb_say "What stops working"
sb_run "git show --stat --format=%s HEAD~2"
sb_run "git blame maps/europe.txt"
sb_run "git describe && git describe HEAD~2; echo \"exit \$?\""
sb_run "git log --oneline v1.0; echo \"exit \$?\""
sb_run "git rev-list --count HEAD && git -C ../server/atlas.git rev-list --count main"
sb_run "git bisect start HEAD v1.0"
sb_run "git bisect start HEAD v1.0 --; echo \"exit \$?\""
git bisect reset >/dev/null 2>&1

sb_say "Deepening"
sb_run "git fetch -q --deepen 2 && git rev-list --count HEAD && cat .git/shallow"
sb_run "git fetch -q --depth 2 && git rev-list --count HEAD && cat .git/shallow"
sb_run "git cat-file -t 49dd93b && git show -s --format=%s 49dd93b"
sb_run "git fetch -q --shallow-exclude=v1.0 && git log --oneline | tail -2"
sb_run "git fetch -q --shallow-since=2026-01-05T15:30:00Z && git log --format='%h %ad %s' --date=iso | tail -2"
sb_run "git fetch --unshallow && git rev-parse --is-shallow-repository && git rev-list --count HEAD"
sb_run "git fetch --unshallow; echo \"exit \$?\""
sb_run "git fetch -q --depth 1 && git rev-parse --is-shallow-repository && git rev-list --count HEAD"

sb_say "Merging in a shallow clone"
cd "$R"
git clone -q --depth 1 --no-single-branch "$URL" merging
cd "$R/merging"
sb_write maps/europe.txt "Europe" "Including the islands"
git commit -q -am "Include the islands"
sb_tick
sb_run "git merge origin/drafts; echo \"exit \$?\""
sb_run "git merge --allow-unrelated-histories origin/drafts; echo \"exit \$?\""
sb_run "git merge --abort && git fetch -q --deepen 2 && git merge --no-edit origin/drafts"
git reset -q --hard origin/main

sb_say "Pushing from a shallow clone"
cd "$R"
git clone -q --depth 1 "$URL" pushing
cd "$R/pushing"
sb_write maps/arctic.txt "Arctic"
git add -A && git commit -q -m "Add the Arctic"
sb_tick
git init -q --bare "$R/server/new.git"
sb_run "git push ../server/new.git main; echo \"exit \$?\""
sb_run "git -C ../server/new.git config set receive.shallowUpdate true"
sb_run "git push --progress ../server/new.git main 2>&1 | tr '\\r' '\\n' | grep -E 'Total|->'"
sb_run "git -C ../server/new.git rev-parse --is-shallow-repository"
sb_run "git push --progress origin main 2>&1 | tr '\\r' '\\n' | grep -E 'Total|->'"
# Put the server's main back where it was, so that every later clone gets the
# history shown in "The example repository". The pushed objects stay on the
# server, unreachable, and no clone receives them.
git -C "$R/server/atlas.git" update-ref refs/heads/main "$(git rev-parse HEAD~1)"

sb_say "Fetching from a shallow repository"
cd "$R"
git init -q empty
cd "$R/empty"
sb_run "git fetch ../merging main; echo \"exit \$?\""
sb_run "git fetch --update-shallow ../merging main && git rev-parse --is-shallow-repository"

# ---------------------------------------------------------------------------
sb_say "What a single-branch clone sees"
cd "$R"
git clone -q --single-branch --branch drafts "$URL" one-branch
cd "$R/one-branch"
sb_run "git branch -a && git tag && git config get --all remote.origin.fetch"
sb_run "git switch rivers; echo \"exit \$?\""
sb_run "git fetch origin rivers && git branch -r"

sb_say "Widening a single-branch clone"
sb_run "git remote set-branches --add origin rivers && git fetch && git switch -q rivers && git branch -vv"

sb_say "A tag as the one branch"
cd "$R"
sb_run "git clone -q --single-branch --branch v1.0 $URL one-tag 2>&1 | head -2 && git -C one-tag config get --all remote.origin.fetch"

# ---------------------------------------------------------------------------
sb_say "Filters"
cd "$R"
sb_run "git clone -q --no-checkout --filter=blob:none $URL blobless && git -C blobless rev-list --objects --all --missing=print | grep -c '^?'"
sb_run "git clone -q --filter=blob:none $URL blobless-checked-out && git -C blobless-checked-out rev-list --objects --all --missing=print | grep -c '^?'"
sb_run "git clone -q --filter=blob:limit=1k $URL small-blobs && git -C small-blobs rev-list --objects --all --missing=print | grep '^?' && git -C small-blobs rev-list --objects --all | grep elevation"
sb_run "git clone -q --no-checkout $URL everything && git -C everything count-objects -v | grep in-pack"
sb_run "git clone -q --no-checkout --filter=tree:0 $URL treeless && git -C treeless count-objects -v | grep in-pack"
sb_run "git clone -q --no-checkout --filter=object:type=commit $URL commits-only && git -C commits-only count-objects -v | grep in-pack"
sb_run "git clone -q --no-checkout --filter=tree:2 $URL two-levels && git -C two-levels count-objects -v | grep in-pack"
sb_run "git clone -q --no-checkout --filter=blob:none --filter=tree:2 $URL combined && git -C combined count-objects -v | grep in-pack && git -C combined config get remote.origin.partialclonefilter"
sb_run "git clone -q --no-checkout --filter=combine:blob:none+tree:2 $URL combined-long && git -C combined-long count-objects -v | grep in-pack"

sb_say "What the server allows"
sb_run "git -C server/atlas.git config set uploadpackfilter.tree.allow false && git clone --filter=tree:0 $URL refused; echo \"exit \$?\""
git -C server/atlas.git config unset uploadpackfilter.tree.allow
sb_run "git clone -q --no-checkout --filter=blob:none $URL old-protocol && git -C old-protocol -c protocol.version=0 show v1.0:maps/europe.txt; echo \"exit \$?\""
sb_run "git -C server/atlas.git config set uploadpack.allowAnySHA1InWant true && git -C old-protocol -c protocol.version=0 show v1.0:maps/europe.txt"
git -C server/atlas.git config unset uploadpack.allowAnySHA1InWant

sb_say "What a partial clone keeps"
sb_run "ls blobless/.git/objects/pack | sed 's/pack-[0-9a-f]*/pack-<hash>/'"

sb_say "Commands that fetch on demand"
cd "$R/blobless-checked-out"
sb_run "GIT_TRACE=1 git log --oneline 2>&1 >/dev/null | grep -c 'fetch'"
sb_run "GIT_TRACE=1 git log -p 2>&1 >/dev/null | grep -o '$LAZY.*'"
cd "$R/blobless"
sb_run "GIT_TRACE=1 git blame main -- data/elevation.txt 2>&1 >/dev/null | grep -c '$LAZY'"
sb_run "GIT_TRACE=1 git log -p 2>&1 >/dev/null | grep -c '$LAZY'"
cd "$R/treeless"
sb_run "GIT_TRACE=1 git log --stat --oneline 2>&1 >/dev/null | grep -c '$LAZY'"

sb_say "Without the server"
cd "$R"
git clone -q --no-checkout --filter=blob:none "$URL" offline
mv server/atlas.git server/away.git
cd "$R/offline"
sb_run "git log --oneline -2 && git show v1.0:maps/europe.txt; echo \"exit \$?\""
sb_run "git --no-lazy-fetch cat-file -e v1.0:maps/europe.txt; echo \"exit \$?\""
sb_run "GIT_NO_LAZY_FETCH=1 git show v1.0:maps/europe.txt; echo \"exit \$?\""
cd "$R"
mv server/away.git server/atlas.git

sb_say "Downloading ahead"
cd "$R"
git clone -q --no-checkout --filter=blob:none "$URL" backfill
cd "$R/backfill"
sb_run "git backfill v1.0 && git rev-list --objects --all --missing=print | grep -c '^?'"
sb_run "git backfill && git rev-list --objects --all --missing=print | grep '^?'"
sb_run "git log --oneline -1 --all -- drafts.txt"
sb_run "git backfill drafts; echo \"exit \$?\""
sb_run "git backfill --all && git rev-list --objects --all --missing=print | grep -c '^?'"
cd "$R"
git clone -q --no-checkout --filter=blob:none "$URL" backfill-batches
cd "$R/backfill-batches"
sb_run "GIT_TRACE=1 git backfill 2>&1 | grep -c '$LAZY'"
cd "$R"
git clone -q --no-checkout --filter=blob:none "$URL" backfill-small-batches
cd "$R/backfill-small-batches"
sb_run "GIT_TRACE=1 git backfill --min-batch-size=1 2>&1 | grep -c '$LAZY'"
cd "$R"
git clone -q --no-checkout --filter=blob:none "$URL" backfill-edges
cd "$R/backfill-edges"
sb_run "git backfill main~5..main~4 && git --no-lazy-fetch cat-file -e main~5:data/elevation.txt; echo \"exit \$?\""
cd "$R"
git clone -q --no-checkout --filter=blob:none "$URL" backfill-no-edges
cd "$R/backfill-no-edges"
sb_run "git backfill --no-include-edges main~5..main~4 && git --no-lazy-fetch cat-file -e main~5:data/elevation.txt; echo \"exit \$?\""

sb_say "Changing the filter"
cd "$R"
git clone -q --no-checkout --filter=blob:none "$URL" refilter
cd "$R/refilter"
sb_run "git rev-list --objects --all --missing=print | grep -c '^?'"
sb_run "git fetch -q --refetch --filter=blob:limit=1k && git rev-list --objects --all --missing=print | grep -c '^?' && git config get remote.origin.partialclonefilter"
sb_run "git config unset remote.origin.partialclonefilter && git fetch -q --refetch && git rev-list --objects --all --missing=print | grep -c '^?'"

# ---------------------------------------------------------------------------
sb_say "How much each one downloads"
cd "$R"
sb_run "git clone -q --no-checkout $URL c-full && git -C c-full count-objects -v | grep in-pack"
sb_run "git clone -q --no-checkout --single-branch $URL c-single && git -C c-single count-objects -v | grep in-pack"
sb_run "git clone -q --no-checkout --depth 1 $URL c-depth && git -C c-depth count-objects -v | grep in-pack"
sb_run "git clone -q --no-checkout --filter=blob:none $URL c-blobless && git -C c-blobless count-objects -v | grep in-pack"
sb_run "git clone -q --no-checkout --filter=tree:0 $URL c-treeless && git -C c-treeless count-objects -v | grep in-pack"
sb_run "git clone -q --no-checkout --depth 1 --filter=blob:none $URL c-both && git -C c-both count-objects -v | grep in-pack"

# ---------------------------------------------------------------------------
sb_say "A filter the server chooses"
cd "$R"
git init -q --bare "$R/server/large-files.git"
git -C server/atlas.git push -q "$R/server/large-files.git" main rivers drafts
git -C server/large-files.git config set uploadpack.allowFilter true
git -C server/atlas.git remote add large-files "$R/server/large-files.git"
git -C server/atlas.git config set remote.large-files.partialCloneFilter blob:limit=1k
git -C server/atlas.git config set promisor.advertise true
git -C server/atlas.git config set promisor.sendFields partialCloneFilter
TRACE='clone< promisor-remote=.*\|clone> filter .*'
sb_run "GIT_TRACE_PACKET=1 git clone --filter=auto $URL auto-default 2>&1 | grep -o '$TRACE'"
sb_run "GIT_TRACE_PACKET=1 git -c promisor.acceptFromServer=all clone --filter=auto $URL auto-all 2>&1 | grep -o '$TRACE'"
sb_run "GIT_TRACE_PACKET=1 git clone -c promisor.acceptFromServer=knownUrl -c remote.large-files.url=$R/server/large-files.git -c remote.large-files.promisor=true --filter=auto $URL auto 2>&1 | grep -o '$TRACE'"
sb_run "git -C auto config get --all --show-names --regexp '^remote\\.origin\\.(promisor|partialclonefilter)'"
# A new commit on the server, so that the next fetch has something to ask for.
git clone -q "$URL" "$R/writer"
cd "$R/writer"
sb_write maps/antarctica.txt "Antarctica"
git add -A && git commit -q -m "Add Antarctica"
sb_tick
git push -q origin main
cd "$R/auto"
sb_run "GIT_TRACE_PACKET=1 git fetch 2>&1 | grep -o 'fetch> filter .*'"
