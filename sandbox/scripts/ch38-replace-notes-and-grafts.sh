#!/bin/bash
# Generates every transcript in Chapter 38, "replace, notes, and grafts".
#
#   bash sandbox/scripts/ch38-replace-notes-and-grafts.sh [dir]
#
# No `set -e`: several commands are shown refusing on purpose.
#
# Editors are set in the printed command; `cp` writes a prepared file over the
# one Git offers, because an editor that renames a temporary file fails while
# Git holds the file open.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null

# ---------------------------------------------------------------------------
# A library, with an older history that was kept in another system.
sb_fresh "$SANDBOX_ROOT/library" >/dev/null
sb_write README.md "# library"
sb_commit "Import the library"
sb_write shelf.py "def shelve(): pass"
sb_commit "Add the shelf"
sb_write index.py "def find(): pass"
sb_commit "Add the indexr"
sb_write loans.py "def lend(): pass"
sb_commit "Add loans"

# The history from before the import, on an unrelated branch.
git switch -q --orphan history
sb_write README.md "# library" "Version 0."
git add README.md >/dev/null
git commit -q -m "The original prototype"; sb_tick
sb_write shelf.py "def shelve(): pass  # v0"
git add shelf.py >/dev/null
git commit -q -m "Prototype shelving"; sb_tick
git switch -q main

sb_say "The example repository"
sb_run "git log --oneline --graph --all --decorate"
sb_run "git log --oneline main"

# ---------------------------------------------------------------------------
sb_say "Making one object stand in for another"
sb_run "git cat-file -p HEAD~1 | head -5"
sb_run "git log -1 --format=%B HEAD~1"
old=$(git rev-parse HEAD~1)
sb_run "git cat-file commit $old | sed 's/Add the indexr/Add the index/' | git hash-object -t commit -w --stdin"
new=$(git cat-file commit "$old" | sed 's/Add the indexr/Add the index/' | git hash-object -t commit -w --stdin)
sb_run "git replace $old $new"
sb_run "git log --oneline"
sb_run "git --no-replace-objects log --oneline"

sb_say "Listing and removing"
sb_run "git replace -l"
sb_run "git replace --format=short -l"
sb_run "git replace --format=medium -l"
sb_run "git replace --format=long -l"
sb_run "git for-each-ref refs/replace"
sb_run "git replace -d $old && git log --oneline -3"

sb_say "Editing an object"
sb_write ../message.txt "tree $(git rev-parse HEAD~1^{tree})" "parent $(git rev-parse HEAD~2)" "author Ada Lovelace <ada@example.com> 1767610800 +0000" "committer Ada Lovelace <ada@example.com> 1767610800 +0000" "" "Add the index"
sb_run "GIT_EDITOR='cp ../message.txt' git replace --edit $old"
sb_run "git log --oneline -3"
sb_run "git replace -l --format=long"
sb_run "git replace -d $old"

sb_say "Replacing with the wrong type"
sb_run "git replace $old \$(git rev-parse HEAD^{tree})"
sb_run "git replace -f $old $new && git replace -l"
sb_run "git replace $old $new"
sb_run "git replace -d $old"

# ---------------------------------------------------------------------------
sb_say "Joining two histories"
root=$(git rev-list --max-parents=0 main)
sb_run "git log --oneline --format='%h %p %s' main | tail -2"
sb_run "git replace --graft $root history"
sb_run "git log --oneline"
sb_run "git --no-replace-objects log --oneline"
sb_run "git log --oneline --format='%h %p %s' | tail -3"

sb_say "Cutting history off"
sb_run "git replace -d $root"
sb_run "git replace --graft main~1 && git log --oneline"
sb_run "git replace -d \$(git rev-parse main~1)"

sb_say "The grafts file"
sb_write .git/info/grafts "$root $(git rev-parse history)"
sb_run "cat .git/info/grafts"
sb_run "git log --oneline | tail -4"
sb_run "git replace --convert-graft-file"
sb_run "ls .git/info"
sb_run "git replace -l --format=medium"
sb_run "git log --oneline | tail -4"

# ---------------------------------------------------------------------------
sb_say "Which commands ignore replacements"
sb_run "git fsck --connectivity-only 2>&1 | head -3"
sb_run "GIT_NO_REPLACE_OBJECTS=1 git log --oneline | tail -3"
sb_run "git --no-replace-objects log --oneline | tail -3"
sb_run "git commit-graph write --reachable 2>&1 | head -3"

sb_say "Sharing replacements"
git init -q --bare "$SANDBOX_ROOT/origin.git"
git remote add origin "$SANDBOX_ROOT/origin.git"
sb_run "git push -q origin main && git ls-remote origin | head -3"
sb_run "git push -q origin 'refs/replace/*:refs/replace/*' && git ls-remote origin refs/replace/*"
sb_run "git clone -q $SANDBOX_ROOT/origin.git $SANDBOX_ROOT/clone && git -C $SANDBOX_ROOT/clone log --oneline | tail -3"
sb_run "git -C $SANDBOX_ROOT/clone fetch -q origin 'refs/replace/*:refs/replace/*' && git -C $SANDBOX_ROOT/clone log --oneline | tail -3"

sb_say "Making it permanent"
sb_run "git replace -l | wc -l"
sb_run "FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -- --all 2>&1 | tail -2"
sb_run "git replace -d \$(git replace -l)"
sb_run "git log --oneline | tail -4"

# ---------------------------------------------------------------------------
sb_say "Attaching a note to a commit"
sb_run "git notes add -m 'Reviewed by Sam; ships in 2.1' HEAD~1"
sb_run "git log -2"
sb_run "git notes show HEAD~1"
sb_run "git notes list"
sb_run "git log --oneline -1 refs/notes/commits"

sb_say "Seeing notes in the log"
sb_run "git log --oneline -2"
sb_run "git log --no-notes -2 | head -8"
sb_run "git log -1 --format='%h %s | %N' HEAD~1"
sb_run "git show --stat --oneline HEAD~1"

sb_say "Editing, appending and copying"
sb_run "git notes append -m 'Also tested on Windows.' HEAD~1 && git notes show HEAD~1"
sb_write ../note.txt "Reviewed by Sam; ships in 2.1" "" "Also tested on Windows, and on Linux."
sb_run "git notes add -f -F ../note.txt HEAD~1 && git notes show HEAD~1"
sb_write ../note2.txt "Backported to 2.0 as well."
sb_run "git notes add -f -C \$(git notes list HEAD~1) HEAD && git notes show HEAD"
sb_run "GIT_EDITOR='cp ../note2.txt' git notes add -f -c \$(git notes list HEAD~1) HEAD && git notes show HEAD"
sb_run "GIT_EDITOR='cp ../note2.txt' git notes add -f -e -m 'A first draft' HEAD~1 && git notes show HEAD~1"
sb_write ../note.txt "Reviewed by Sam; ships in 2.1" "" "Also tested on Windows, and on Linux."
sb_run "git notes add -f -F ../note.txt HEAD~1 >/dev/null && git notes show HEAD~1"
git notes remove HEAD >/dev/null 2>&1
sb_run "git notes copy HEAD~1 HEAD && git notes list"
sb_run "git notes add -m 'second try' HEAD"
sb_run "git notes add -f -m 'A second attempt' HEAD && git notes show HEAD"

sb_say "Removing notes"
sb_run "git notes remove HEAD && git notes list"
sb_run "git notes remove HEAD"
sb_run "git notes remove --ignore-missing HEAD && echo 'no complaint'"

sb_say "Notes in another namespace"
sb_run "git notes --ref=builds add -m 'build 1482 passed' HEAD~1"
sb_run "git notes --ref=builds show HEAD~1"
sb_run "git notes list"
sb_run "git log -1 HEAD~1 | tail -6"
sb_run "git log -1 --notes=builds HEAD~1 | tail -6"
sb_run "git log -1 --notes=* HEAD~1 | tail -8"
sb_run "git notes get-ref"
sb_run "git -c core.notesRef=refs/notes/builds notes get-ref"
sb_run "git log -1 --show-notes=builds HEAD~1 | tail -8"
sb_run "git log -1 --show-notes=builds --no-standard-notes HEAD~1 | tail -3"
sb_run "git log -1 --notes=builds --standard-notes HEAD~1 | tail -8"
sb_run "diff <(git log -1 --show-notes HEAD~1) <(git log -1 --notes HEAD~1) && echo same"
sb_run "diff <(git log -1 --show-notes=builds HEAD~1) <(git log -1 --notes=builds --notes HEAD~1) && echo same"
sb_run "diff <(git log -1 --show-notes=builds --no-standard-notes HEAD~1) <(git log -1 --notes=builds HEAD~1) && echo same"
sb_run "diff <(git log -1 --notes=builds --standard-notes HEAD~1) <(git log -1 --notes=builds --notes HEAD~1) && echo same"

sb_say "Notes and rewritten commits"
sb_run "git notes list HEAD~1"
sb_run "git commit -q --amend --no-edit -m 'Add loans, with limits' && git log --oneline -2"; sb_tick
sb_run "git notes list HEAD || echo 'no note on the new commit'"
sb_run "git switch -q -C try main~1 && git notes list HEAD"
sb_run "git -c notes.rewriteRef=refs/notes/commits commit -q --amend --no-edit -m 'Add the index, renamed'"; sb_tick
sb_run "git notes show HEAD"

sb_say "Merging notes"
sb_run "git notes --ref=review add -m 'Looks good to me' main~1"
sb_run "git notes --ref=review merge -v refs/notes/builds"
sb_run "ls .git/NOTES_MERGE_WORKTREE && cat .git/NOTES_MERGE_WORKTREE/*"
sb_run "git notes merge --abort && git notes --ref=review show main~1"

sb_say "Letting Git resolve it"
sb_run "git notes --ref=review merge -s union refs/notes/builds"
sb_run "git notes --ref=review show main~1"
sb_run "git notes --ref=review merge -s theirs refs/notes/builds"
sb_run "git notes --ref=review show main~1"
sb_run "git log --oneline refs/notes/review"
