#!/bin/bash
# Generates every transcript in Chapter 47, "Tags".
#
#   bash sandbox/scripts/ch47-tags.sh [dir]
#
# No `set -e`: several commands are shown failing, and `git tag -d` of a name
# that does not exist answers with exit status 1.
#
# Ada's atlas has four annotated release tags, one of them on a maintenance
# branch, and a bare "server" she pushes to. Bob's clone appears where a tag
# moves under him.
#
# HOME is the sandbox root, as in Chapter 40: `git tag -v` looks for a
# signature, and although an unsigned tag never reaches a signing program,
# nothing here may touch the real home directory. No tag is signed; Chapter 68
# covers signing.
#
# `sb_run` runs its command in a subshell, so a `cd` inside it does not last;
# every change of directory here is a plain `cd` of its own.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null
R="$SANDBOX_ROOT"
export HOME="$R"
unset GIT_ASKPASS SSH_ASKPASS

# ---------------------------------------------------------------------------
sb_fresh "$R/atlas" >/dev/null
sb_write README.md "# Atlas"
sb_commit "Start the atlas"
sb_write maps/europe.txt "Europe"
sb_commit "Add Europe"
sb_write maps/asia.txt "Aisa"
sb_commit "Add Asia"
git tag -a v1.0 -m "First edition"
sb_write maps/africa.txt "Africa"
sb_commit "Add Africa"
git tag -a v1.1-rc1 -m "Second edition, first candidate" -m "Africa still to be checked."
sb_write maps/africa.txt "Africa" "with Madagascar"
sb_commit "Fix the Africa map"
sb_write maps/oceania.txt "Oceania"
sb_commit "Add Oceania"
git tag -a v1.1 -m "Second edition"
git switch -q -c maint v1.0
sb_write maps/asia.txt "Asia"
sb_commit "Fix the spelling of Asia"
git tag -a v1.0.1 -m "First edition, corrected" -m "Fixes the spelling of Asia."
git switch -q main
sb_write maps/americas.txt "The Americas"
sb_commit "Add the Americas"
git init -q --bare "$R/server/atlas.git"
git remote add origin "$R/server/atlas.git"
git push -q origin main maint v1.0 v1.0.1 v1.1-rc1 v1.1
git branch -q -u origin/main main
git branch -q -u origin/maint maint

sb_say "The example repository"
sb_run "git log --oneline --graph --all --decorate"

# ---------------------------------------------------------------------------
sb_say "Reading the output"
sb_run "git tag"
sb_run "git tag -n"
sb_run "git show -s v1.1"

# ---------------------------------------------------------------------------
sb_say "Patterns"
sb_run "git tag -l 'v1.0*'"
sb_run "git tag -l 'v1.0*' 'v1.1-*'"
sb_run "git tag 'v1.0*'; echo \"exit \$?\""
sb_run "git tag -i -l 'V1.1*'"

sb_say "Order"
sb_run "git tag --sort=-version:refname"
sb_run "git -c versionsort.suffix=-rc tag --sort=version:refname"
sb_run "git tag --sort=taggerdate --format='%(taggerdate:iso) %(refname:short)'"
sb_run "git -c tag.sort=-version:refname tag -l 'v1.0*'"

sb_say "Layout"
sb_run "git tag -n3 v1.0.1"
sb_run "git tag --column"
sb_run "git -c column.tag=always tag --no-column -l 'v1.0*'"
sb_run "git tag --format='%(refname:short) is on %(*objectname:short), %(*subject)'"
sb_run "git tag --format='%(if)%(contents:body)%(then)%(refname:short)%(end)'"
sb_run "git tag --omit-empty --format='%(if)%(contents:body)%(then)%(refname:short)%(end)'"
sb_run_ansi "git tag --color=always --format='%(color:yellow)%(refname:short)%(color:reset) %(contents:subject)' -l 'v1.1*'"

sb_say "Tags by history"
sb_run "git tag --contains main~3"
sb_run "git tag --contains maint"
sb_run "git tag --no-contains main~3"
sb_run "git tag --merged main"
sb_run "git tag --no-merged main"
sb_run "git tag --points-at main~1"
sb_run "git tag --contains; echo \"exit \$?\""

# ---------------------------------------------------------------------------
sb_say "Lightweight and annotated tags"
sb_run "git tag reviewed main~2 && git tag -n reviewed v1.1"
sb_run "git show -s reviewed"
sb_run "git tag --format='%(objecttype) %(refname:short)'"
sb_run "git describe main~2 && git describe --tags main~2"

# ---------------------------------------------------------------------------
sb_say "Where the tag goes"
sb_run "git tag europe-done main~5 && git tag europe-done-2 $(git rev-parse --short main~5) && git tag --points-at main~5"
sb_run "git tag nowhere nosuch; echo \"exit \$?\""
git tag -d europe-done europe-done-2 >/dev/null

sb_say "The message"
sb_run "git tag -m 'Third edition' -m 'Adds the Americas.' v1.2 && git tag -n3 v1.2"
sb_run "GIT_EDITOR=true git tag -a try-editor; echo \"exit \$?\""
sb_run "cat .git/TAG_EDITMSG"
printf 'Third edition, from a file\n\nWritten in an editor.\n' > "$R/message.txt"
sb_run "GIT_EDITOR='cp ../message.txt' git tag -a try-editor && git tag -n3 try-editor"
sb_run "printf 'Third edition, from standard input\n' | git tag -F - try-stdin && git tag -n try-stdin"
sb_run "GIT_EDITOR=cat git tag -e -m 'Third edition, edited' try-edit"
sb_run "git tag -m '#1 in the charts' try-hash && git tag -n try-hash && git cat-file -p try-hash"
sb_run "git commit -q --allow-empty -m '#1 in the charts' && git log -1 --format=%s && git reset -q --hard HEAD~1"
sb_run "printf 'Third edition\n\n\n# Americas still to check\n' > ../draft.txt"
sb_run "git tag --cleanup=strip -F ../draft.txt cleanup-strip && git tag --cleanup=whitespace -F ../draft.txt cleanup-whitespace && git tag --cleanup=verbatim -F ../draft.txt cleanup-verbatim"
sb_run "git tag -l 'cleanup-*' --format='%(refname:short): [%(contents)]'"
sb_run "git tag -m 'Third edition, reviewed' --trailer 'Reviewed-by: Bob <bob@example.com>' try-trailer && git cat-file -p try-trailer"
sb_run "git tag -l try-trailer --format='%(trailers:key=Reviewed-by,valueonly)'"

sb_say "Names a tag cannot have"
sb_run "git tag 'third edition'; echo \"exit \$?\""
sb_run "git tag -- -draft; echo \"exit \$?\""
sb_run "git tag v1.2/rc1; echo \"exit \$?\""
sb_run "git tag v1.2; echo \"exit \$?\""

sb_say "Tagging something other than a commit"
sb_run "git tag readme main:README.md && git cat-file -t readme && git show readme"
sb_run "git tag -m 'The tag of a tag' v1.2-again v1.2"
sb_run "git cat-file -p v1.2-again | head -2"

sb_say "The tagger and the date"
sb_run "GIT_COMMITTER_DATE='2025-12-24 10:00:00 +0000' git tag -m 'The draft edition, tagged late' v0.9 main~5 && git tag --sort=taggerdate --format='%(taggerdate:iso) %(refname:short)' -l 'v0*' 'v1.0'"

# ---------------------------------------------------------------------------
sb_say "Deleting a tag"
sb_run "git tag -d try-editor try-stdin try-edit try-hash try-trailer v1.2-again"
sb_run "git tag -d 'cleanup-*'; echo \"exit \$?\""
sb_run "git tag -d \$(git tag -l 'cleanup-*')"
sb_run "git tag -d nosuch readme; echo \"exit \$?\""
# The hash `git tag -d` prints is the tag object's, which puts the tag back.
OLD="$(git rev-parse --short v0.9)"
sb_run "git tag -d v0.9"
sb_run "git tag v0.9 $OLD && git tag -n v0.9 && git cat-file -t v0.9"

sb_say "What a tag keeps alive"
sb_run "git commit -q --allow-empty -m 'Try a new projection' && git tag experiment && git reset -q --hard HEAD~1"
sb_run "git branch --contains experiment; git log --oneline -1 experiment"
sb_run "git reflog expire --expire=now --all && git gc -q --prune=now && git log --oneline -1 experiment"
GONE="$(git rev-parse --short experiment)"
sb_run "git tag -d experiment && git reflog expire --expire=now --all && git gc -q --prune=now && git cat-file -t $GONE; echo \"exit \$?\""

# ---------------------------------------------------------------------------
sb_say "Moving a tag"
# The hash `git tag -f` prints as "was" is the tag object's, which puts it back.
OLD="$(git rev-parse --short v1.2)"
sb_run "git tag -f v1.2 main && git cat-file -t v1.2"
sb_run "git tag -f v1.2 $OLD && git cat-file -t v1.2 && git tag -n3 v1.2"

# ---------------------------------------------------------------------------
sb_say "Tags and remotes"
sb_run "git push -q origin main v1.2 && git tag -d v1.1-rc1 && git fetch && git tag -l 'v1.1*'"
sb_run "git branch release main~1 && git tag release && git push origin release; echo \"exit \$?\""
sb_run "git push origin tag release"
git push -q origin --delete release
git tag -d release >/dev/null
git branch -q -D release

sb_say "Moving a published tag"
cd "$R"
git clone -q "$R/server/atlas.git" bob
cd "$R/atlas"
sb_write maps/antarctica.txt "Antarctica"
sb_commit "Add Antarctica"
sb_run "git tag -f -m 'Third edition' -m 'Adds the Americas and Antarctica.' v1.2 && git push origin main +v1.2"
cd "$R/bob"
sb_run "git fetch && git log --oneline -1 v1.2"
sb_run "git tag -d v1.2 && git fetch origin tag v1.2 && git log --oneline -1 v1.2"

# ---------------------------------------------------------------------------
sb_say "A reflog for a tag"
cd "$R/atlas"
sb_run "git tag --create-reflog checkpoint main~2 && git tag -f checkpoint main~1 && git reflog show checkpoint"
sb_run "git tag --create-reflog -m 'Checked' checked main~2 && git tag -f -m 'Checked' checked main~1 && git reflog show checked; echo \"exit \$?\""
sb_run "git log --oneline -1 checked@{1}"
sb_run "git tag -d checkpoint && git reflog show checkpoint; echo \"exit \$?\""
git tag -d checked >/dev/null

# ---------------------------------------------------------------------------
sb_say "Verifying a tag"
sb_run "git tag -v v1.2; echo \"exit \$?\""
sb_run "git tag -v reviewed; echo \"exit \$?\""

# ---------------------------------------------------------------------------
sb_say "Tags and their neighbours"
AFRICA="$(git rev-parse --short v1.1-rc1^{})"
sb_run "git tag --contains $AFRICA && git describe --contains $AFRICA && git branch --contains $AFRICA"
