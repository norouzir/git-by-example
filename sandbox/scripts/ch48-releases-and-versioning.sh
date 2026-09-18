#!/bin/bash
# Generates every transcript in Chapter 48, "Releases and Versioning".
#
#   bash sandbox/scripts/ch48-releases-and-versioning.sh [dir]
#
# No `set -e`: some commands are shown failing, and `grep -c` and
# `git describe` answer with a non-zero status when they find nothing.
#
# Ada's atlas has two releases and a release candidate on `main`, and a
# maintenance branch `maint-1.0` for fixes to 1.0, whose first fix was merged
# up into `main`. A `VERSION` file holds the number of each release; a file
# `release.txt` is filled in by `git archive`, and `notes/` is left out of
# archives, both through `.gitattributes`. A second repository, `versions`,
# holds nothing but tags, to show how Git sorts version numbers.
#
# `sb_run` runs its command in a subshell, so a `cd` inside it does not last;
# every change of directory here is a plain `cd` of its own.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null
R="$SANDBOX_ROOT"

# ---------------------------------------------------------------------------
sb_fresh "$R/atlas" >/dev/null
sb_write README.md "# Atlas"
sb_write release.txt 'Atlas $Format:%(describe)$, built from commit $Format:%h$'
sb_write notes/todo.txt "Check the Pacific islands"
printf 'release.txt export-subst\nnotes/ export-ignore\n.gitattributes export-ignore\n' > .gitattributes
sb_commit "Start the atlas"
sb_write maps/europe.txt "Europe"
sb_commit "Add Europe"
sb_write maps/asia.txt "Aisa"
sb_commit "Add Asia"
sb_write VERSION "1.0.0"
sb_commit "Release 1.0.0"
git tag -a v1.0.0 -m "Atlas 1.0.0"
git branch maint-1.0 v1.0.0
git switch -q -c africa
sb_write maps/africa.txt "Africa"
sb_commit "Add Africa"
sb_write maps/africa.txt "Africa" "Madagascar"
sb_commit "Add Madagascar"
git switch -q main
git merge -q --no-ff -m "Merge branch 'africa'" africa
sb_tick
git branch -q -d africa
git switch -q maint-1.0
sb_write maps/asia.txt "Asia"
sb_commit "Fix the spelling of Asia"
sb_write VERSION "1.0.1"
sb_commit "Release 1.0.1"
git tag -a v1.0.1 -m "Atlas 1.0.1"
git switch -q main
git merge -q --no-ff -m "Merge branch 'maint-1.0'" maint-1.0
sb_tick
sb_write VERSION "1.1.0-rc.1"
sb_commit "Release 1.1.0-rc.1"
git tag -a v1.1.0-rc.1 -m "Atlas 1.1.0, first release candidate"
sb_write maps/oceania.txt "Oceania"
sb_commit "Add Oceania"
sb_write VERSION "1.1.0"
sb_commit "Release 1.1.0"
git tag -a v1.1.0 -m "Atlas 1.1.0"
sb_write maps/americas.txt "The Americas"
sb_commit "Add the Americas"
git init -q --bare "$R/server/atlas.git"
git remote add origin "$R/server/atlas.git"
git push -q origin main maint-1.0 v1.0.0 v1.0.1 v1.1.0-rc.1 v1.1.0
git branch -q -u origin/main main
git branch -q -u origin/maint-1.0 maint-1.0

sb_say "The example repository"
sb_run "git log --oneline --graph --all --decorate"

# ---------------------------------------------------------------------------
sb_say "How Git orders versions"
# sb_fresh restarts the clock; the atlas's later tags must stay later.
SAVED_NOW="$SANDBOX_NOW"
sb_fresh "$R/versions" >/dev/null
git commit -q --allow-empty -m "Nothing but tags"
for t in v1.0.0-alpha v1.0.0-alpha.1 v1.0.0-alpha.beta v1.0.0-beta v1.0.0-beta.2 \
	v1.0.0-beta.11 v1.0.0-rc.1 v1.0.0 v1.2.0 v1.10.0 v2.0.0-rc.1; do
	git tag "$t"
done
sb_run "git tag"
sb_run "git tag --sort=version:refname"
sb_run "git -c versionsort.suffix=- tag --sort=version:refname"
cd "$R/atlas"
SANDBOX_NOW="$SAVED_NOW"
sb_settime

# ---------------------------------------------------------------------------
sb_say "What changed since the last release"
sb_run "git describe --abbrev=0"
sb_run "git log --oneline v1.1.0.."
sb_run "git log --oneline --no-merges v1.0.0..v1.1.0"
sb_run "git log --oneline --first-parent v1.0.0..v1.1.0"
sb_run "git diff --stat v1.0.0 v1.1.0"
sb_run "git shortlog -sn v1.0.0..v1.1.0"

sb_say "Release notes from the history"
sb_run "git log --no-merges --reverse --format='- %s' v1.0.0..v1.1.0 -- maps"

# ---------------------------------------------------------------------------
sb_say "The release commit and its tag"
sb_run "git status --short && echo 1.2.0 > VERSION && git commit -q -am 'Release 1.2.0' && git tag -a v1.2.0 -m 'Atlas 1.2.0'"
sb_tick
sb_run "git push --follow-tags"
sb_run "git log -1 --format='%h %s' v1.2.0 && git show v1.2.0:VERSION"

sb_say "The version inside a build"
sb_run "git describe"
sb_write maps/antarctica.txt "Antarctica"
git add maps/antarctica.txt
git commit -q -m "Add Antarctica"
sb_tick
sb_run "git describe && git tag reviewed && git describe --tags"
sb_run "git describe --tags --match 'v[0-9]*' --dirty --always"
sb_run "echo 'Antarctica, draft' >> maps/antarctica.txt && git describe --tags --match 'v[0-9]*' --dirty --always"
git checkout -q maps/antarctica.txt
git tag -d reviewed >/dev/null

sb_say "Release archives"
sb_run "git ls-tree --name-only v1.2.0"
sb_run "git archive --prefix=atlas-1.2.0/ -o ../atlas-1.2.0.tar.gz v1.2.0 && tar -tzf ../atlas-1.2.0.tar.gz"
sb_run "tar -xzOf ../atlas-1.2.0.tar.gz atlas-1.2.0/release.txt"
sb_run "gzip -dc ../atlas-1.2.0.tar.gz | git get-tar-commit-id && git rev-parse v1.2.0^{commit}"
sb_run "cat .gitattributes"
sb_run "git archive -o ../atlas-1.2.0.zip v1.2.0 && unzip -l ../atlas-1.2.0.zip"

# ---------------------------------------------------------------------------
sb_say "Release candidates"
sb_run "git describe v1.1.0~1 && git describe --exclude '*-rc.*' v1.1.0~1"
sb_run "git -c versionsort.suffix=- tag --sort=-version:refname -l 'v*'"

# ---------------------------------------------------------------------------
sb_say "Fixing the oldest branch and merging up"
FIX="$(git rev-parse --short 'maint-1.0^{/Fix the spelling}')"
sb_run "git tag --contains $FIX"

sb_say "Backporting with cherry-pick"
sb_write maps/europe.txt "Europe" "Iceland"
git add maps/europe.txt
git commit -q -m "Fix the Europe map"
sb_tick
ICE="$(git rev-parse --short HEAD)"
sb_run "git switch -q maint-1.0 && git cherry-pick -x $ICE"
sb_tick
sb_run "echo 1.0.2 > VERSION && git commit -q -am 'Release 1.0.2' && git tag -a v1.0.2 -m 'Atlas 1.0.2'"
sb_tick
sb_run "git log -1 --format=%B HEAD~1"
sb_run "git tag --contains $ICE; echo \"exit \$?\""
sb_run "git log --all --oneline --grep='cherry picked from commit $(git rev-parse "$ICE")'"
COPY="$(git rev-parse --short HEAD~1)"
sb_run "git tag --contains $COPY"
git push -q origin maint-1.0 v1.0.2
git switch -q main

# ---------------------------------------------------------------------------
sb_say "Which release is the latest"
sb_run "git describe --abbrev=0 main && git describe --abbrev=0 maint-1.0"
sb_run "git -c versionsort.suffix=- tag --sort=-version:refname -l 'v*' | head -1"
sb_run "git for-each-ref --sort=-taggerdate --count=1 --format='%(refname:short)' 'refs/tags/v*'"

# ---------------------------------------------------------------------------
sb_say "Releases on hosting services"
# Stand in for a release made in a hosting service's web page: someone else's
# clone creates the tag on the server, on a commit Ada already has.
git clone -q "$R/server/atlas.git" "$R/web"
git -C "$R/web" tag -a v1.3.0-rc.1 -m "Atlas 1.3.0, first release candidate" origin/main
git -C "$R/web" push -q origin v1.3.0-rc.1
sb_run "git fetch"
sb_run "git tag -l 'v1.3*'"
