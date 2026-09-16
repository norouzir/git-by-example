#!/bin/bash
# Generates every transcript in Chapter 33, "rebase".
#
#   bash sandbox/scripts/ch33-rebase.sh [dir]
#
# No `set -e`: many commands are shown refusing or conflicting on purpose.
#
# Everything about the todo list -- -i, --exec, --rebase-merges -- is Chapter 34.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null

# try is recreated from whichever branch a demonstration needs; the checkout and
# clean before it only undo what the previous example left behind.
fresh() {
	git rebase --quit >/dev/null 2>&1
	git checkout -qf --detach main
	git clean -qfdx
	sb_run "git switch -q -C try ${1:-contact}"
}

# ---------------------------------------------------------------------------
# A small static site.
sb_fresh "$SANDBOX_ROOT/site" >/dev/null
sb_write index.md "# My sight" "Welcome."
sb_commit "Start the site"
sb_write about.md "About us."
sb_commit "Add an about page"
sb_write style.css "body { margin: 2em; }"
sb_commit "Add a stylesheet"

fork=$(git rev-parse --short HEAD)

# Branches that fork here, one per situation the chapter needs.
git switch -q -c contact
sb_write contact.md "Write to hello@example.com."
sb_commit "Add a contact page"
sb_write about.md "About us." "Contact details are on the contact page."
sb_commit "Mention contact in the about page"

git switch -q -c heading main
sb_write index.md "# My site" "Welcome."
sb_commit "Fix the heading"

git switch -q -c footer main
sb_write index.md "# My sight" "Welcome." "Built by hand."
sb_commit "Add our own footer"

git switch -q -c stack-a main
sb_write robots.txt "User-agent: *"
sb_commit "Add robots.txt"
git switch -q -c stack-b
sb_write sitemap.xml "<urlset/>"
sb_commit "Add a sitemap"

# main moves on.
git switch -q main
sb_write index.md "# My site" "Welcome."
sb_write style.css "body { margin: 2em; padding: 0; }"
sb_commit "Fix the heading and tidy the stylesheet"
sb_write LICENSE "MIT"
sb_commit "Add a licence"
sb_write index.md "# My site" "Welcome." "Footer: 2026"
sb_commit "Add a footer"

# A branch holding a clean copy of one of main's commits.
git switch -q -c licence "$fork"
git cherry-pick main~1 >/dev/null 2>&1; sb_tick
sb_write humans.txt "Made by Ada."
sb_commit "Add humans.txt"

git switch -q main

sb_say "The example repository"
sb_run "git log --oneline --graph --all --decorate"
sb_run "git log --oneline main..contact"

# ---------------------------------------------------------------------------
sb_say "What a plain rebase does"
fresh
sb_run "git log --oneline --graph HEAD main"
sb_run "git rebase main"; sb_tick; sb_tick
sb_run "git log --oneline --graph -6"
sb_run "git status --short --branch"

sb_say "What changes in the copied commits"
fresh
sb_run "git log --format='%h %p %s' -3"
sb_run "git log -1 --pretty=fuller"
sb_run "git rebase main"; sb_tick; sb_tick
sb_run "git log --format='%h %p %s' -3"
sb_run "git log -1 --pretty=fuller"

sb_say "Rebasing when there is nothing to do"
sb_run "git rebase main"

sb_say "How much rebase prints"
fresh
sb_run "git rebase --stat main"; sb_tick; sb_tick
fresh
sb_run "git rebase -q main"; sb_tick; sb_tick
sb_run "git log --oneline -1"

# ---------------------------------------------------------------------------
sb_say "Choosing the new base with --onto"
fresh
sb_run "git rebase --onto main~2 main~3"; sb_tick; sb_tick
sb_run "git log --oneline --graph -5"

sb_say "Dropping commits out of the middle"
fresh
sb_run "git log --oneline -3"
sb_run "git rebase --onto HEAD~2 HEAD~1"; sb_tick
sb_run "git log --oneline -3"

sb_say "Rebasing a branch you are not on"
git branch -qf spare contact
fresh
sb_run "git switch -q main && git rebase main~1 spare"; sb_tick; sb_tick
sb_run "git status --short --branch && git log --oneline -3"

sb_say "--keep-base"
fresh
sb_run "git rebase --keep-base main"; sb_tick; sb_tick
sb_run "git log --oneline --graph -5"

# ---------------------------------------------------------------------------
sb_say "Commits that are already upstream"
fresh licence
sb_run "git log --oneline -3"
sb_run "git rebase main"; sb_tick
sb_run "git log --oneline -4"

sb_say "Reapplying them anyway"
fresh licence
sb_run "git rebase --reapply-cherry-picks main"; sb_tick; sb_tick
sb_run "git log --oneline -4"

sb_say "Commits that become empty"
fresh heading
sb_run "git log --oneline -2 && git show --stat --oneline HEAD"
sb_run "git rebase main"
sb_run "git log --oneline -3"

sb_say "Saying it explicitly"
fresh heading
sb_run "git rebase --empty=drop main"
sb_run "git log --oneline -2"

sb_say "Keeping them"
fresh heading
sb_run "git rebase --empty=keep main"; sb_tick
sb_run "git log --oneline -3 && git show --stat --oneline HEAD"

sb_say "Stopping to ask"
fresh heading
sb_run "git rebase --empty=stop main"
sb_run "git status | head -6"
sb_run "git rebase --skip"
sb_run "git log --oneline -2"

sb_say "A commit that was empty to start with"
fresh
sb_run "git commit -q --allow-empty -m 'A marker commit' && git log --oneline -3"; sb_tick
sb_run "git rebase main"; sb_tick; sb_tick; sb_tick
sb_run "git log --oneline -4"
fresh
sb_run "git commit -q --allow-empty -m 'A marker commit'"; sb_tick
sb_run "git rebase --no-keep-empty main"; sb_tick; sb_tick
sb_run "git log --oneline -4"

# ---------------------------------------------------------------------------
sb_say "Fast-forwarding"
fresh
sb_run "git switch -q -C try main~1 && git rebase main"
sb_run "git log --oneline -2"
sb_run "git switch -q -C try main~1 && git rebase --no-ff main"; sb_tick
sb_run "git log --format='%h %p %s' -3"

# ---------------------------------------------------------------------------
sb_say "When a rebase stops"
fresh footer
sb_run "git rebase main"
sb_run "git status --short --branch"
sb_run "git status | head -10"
sb_run "cat index.md"
sb_run "git log --oneline -1 REBASE_HEAD"
sb_run "git rebase --show-current-patch | head -12"

sb_say "Finishing it"
sb_write index.md "# My site" "Welcome." "Footer: 2026" "Built by hand."
sb_run "git add index.md && GIT_EDITOR=true git rebase --continue"; sb_tick
sb_run "git log --oneline -3 && cat index.md"

sb_say "Abandoning it"
fresh footer
sb_run "git rebase main"
sb_run "git rebase --abort && git status --short && git log --oneline -1"
sb_run "git rebase main"
sb_run "git rebase --skip"
sb_run "git log --oneline -2"
fresh footer
sb_run "git rebase main"
sb_run "git rebase --quit && git status --short && git log --oneline -1"
sb_run "git reset -q --hard HEAD"

# ---------------------------------------------------------------------------
sb_say "Rebasing with uncommitted changes"
fresh
sb_write about.md "About us." "Contact details are on the contact page." "Updated today."
sb_run "git rebase main"
sb_run "git rebase --autostash main"; sb_tick; sb_tick
sb_run "git status --short && git log --oneline -3"

# ---------------------------------------------------------------------------
sb_say "Moving the other branches too"
fresh stack-b
sb_run "git log --oneline --decorate -3"
sb_run "git rebase main"; sb_tick; sb_tick
sb_run "git log --oneline --decorate -4"
fresh stack-b
sb_run "git rebase --update-refs main"; sb_tick; sb_tick
sb_run "git log --oneline --decorate -4"

# ---------------------------------------------------------------------------
sb_say "Rebasing from the root"
fresh
git switch -q --orphan newbase
sb_write NOTICE "This history starts here."
git add NOTICE >/dev/null; git commit -q -m "Start a new history"; sb_tick
git switch -q try
sb_run "git log --oneline newbase"
sb_run "git rebase --onto newbase --root"; sb_tick; sb_tick; sb_tick; sb_tick; sb_tick
sb_run "git log --oneline --graph -6"

# ---------------------------------------------------------------------------
sb_say "The two backends"
fresh
sb_run "git rebase --apply main"; sb_tick; sb_tick
sb_run "git log --oneline -3"
fresh footer
sb_run "git rebase --apply main"
sb_run "cat index.md"
sb_run "git rebase --abort"

sb_say "Whitespace"
fresh
sb_write about.md "About us.  " "Contact details are on the contact page."
sb_run "git commit -q -am 'Add trailing space' && git rebase --ignore-whitespace main"; sb_tick; sb_tick; sb_tick
sb_run "git log --oneline -4"
fresh
sb_run "git rebase --whitespace=fix main"; sb_tick; sb_tick
sb_run "git log --oneline -3"
fresh
sb_run "git rebase -C1 main"; sb_tick; sb_tick
sb_run "git log --oneline -3"

# ---------------------------------------------------------------------------
sb_say "Dates, authorship and trailers"
fresh
sb_run "git rebase main"; sb_tick; sb_tick
sb_run "git log -1 --format='%ad | %cd'"
fresh
sb_run "git rebase --committer-date-is-author-date main"; sb_tick; sb_tick
sb_run "git log -1 --format='%ad | %cd'"
fresh
sb_run "git rebase --signoff main"; sb_tick; sb_tick
sb_run "git log -1 --format=%B"
fresh
sb_run "git rebase --trailer 'Reviewed-by: Sam Chen <sam@example.com>' main"; sb_tick; sb_tick
sb_run "git log -1 --format=%B"

# ---------------------------------------------------------------------------
sb_say "Strategies"
fresh footer
sb_run "git rebase -Xtheirs main"; sb_tick
sb_run "git log --oneline -2 && cat index.md"
fresh
sb_run "git rebase --strategy=resolve main"; sb_tick; sb_tick
sb_run "git log --oneline -3"

# ---------------------------------------------------------------------------
sb_say "The pre-rebase hook"
cat > .git/hooks/pre-rebase <<'HOOK'
#!/bin/sh
echo "pre-rebase: upstream=$1 branch=${2:-HEAD}"
exit 1
HOOK
chmod +x .git/hooks/pre-rebase
fresh
sb_run "git rebase main"
sb_run "git rebase --no-verify main"; sb_tick; sb_tick
sb_run "git log --oneline -1"
rm .git/hooks/pre-rebase

# ---------------------------------------------------------------------------
sb_say "Options that cannot be combined"
fresh
sb_run "git rebase --apply --update-refs main"
sb_run "git rebase --keep-base --onto main~1 main"
sb_run "git rebase --fork-point --root"

# ---------------------------------------------------------------------------
sb_say "Undoing a rebase"
fresh
sb_run "git rebase main"; sb_tick; sb_tick
sb_run "git log --oneline -1 && git log --oneline -1 ORIG_HEAD"
sb_run "git reset --hard ORIG_HEAD && git log --oneline -2"
sb_run "git reflog show try -4"

# ---------------------------------------------------------------------------
# A second small repository, so that the upstream can be rewound and rewritten
# without disturbing the branches the rest of the chapter uses.
sb_say "--fork-point"
keep_now=$SANDBOX_NOW
sb_fresh "$SANDBOX_ROOT/fork-point" >/dev/null
sb_write a.txt "one"
sb_commit "Add one"
git switch -q -c up
sb_write b.txt "two"
sb_commit "Add two"
sb_write c.txt "three"
sb_commit "Add three"
git switch -q -c work up
sb_write d.txt "four"
sb_commit "Add four"
work_tip=$(git rev-parse --short HEAD)
sb_run "git log --oneline --graph --all --decorate"
sb_run "git switch -q up && git reset -q --hard up~1 && git log --oneline up"
sb_run "git switch -q work && git rebase --no-fork-point up"
sb_run "git log --oneline"
sb_run "git reset -q --hard $work_tip && git rebase --fork-point up"; sb_tick
sb_run "git log --oneline"

# ---------------------------------------------------------------------------
sb_say "When the upstream was rebased under you"
sb_fresh "$SANDBOX_ROOT/upstream-rebase" >/dev/null
sb_write notes.md "First note."
sb_commit "Start the notes"
git switch -q -c subsystem
sb_write subsystem.md "A subsystem."
sb_commit "Add the subsystem"
git switch -q -c topic
sb_write topic.md "A topic."
sb_commit "Add the topic"
old_tip=$(git rev-parse --short subsystem)
git switch -q subsystem
sb_write subsystem.md "A subsystem, described properly."
git commit -q --amend -a --no-edit; sb_tick
git switch -q topic
sb_run "git log --oneline --graph --all --decorate"
sb_run "git rebase subsystem"
sb_run "git rebase --abort"
sb_run "git rebase --onto subsystem $old_tip"; sb_tick
sb_run "git log --oneline --graph --all --decorate"

# ---------------------------------------------------------------------------
sb_say "git replay"
git init -q --bare "$SANDBOX_ROOT/bare.git"
git push -q "$SANDBOX_ROOT/bare.git" subsystem topic
sb_run "git -C $SANDBOX_ROOT/bare.git log --oneline --all --decorate"
sb_run "git -C $SANDBOX_ROOT/bare.git replay --ref-action=print --onto subsystem subsystem..topic"
sb_run "git -C $SANDBOX_ROOT/bare.git replay --onto subsystem subsystem..topic"
sb_run "git -C $SANDBOX_ROOT/bare.git log --oneline --all --decorate"
SANDBOX_NOW=$keep_now
sb_settime
cd "$SANDBOX_ROOT/site"
