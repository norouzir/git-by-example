# Decisions

Why the book is the way it is. Each entry records what was decided, why, and
what was rejected, so that a later reader does not reopen a settled question
without new information.

Newest entries at the bottom.

---

## 2026-09-11. The audience is someone with a phone and nothing else

No internet to search with, no computer to run commands on. Everything a reader
would normally learn by experimenting has to be on the page instead.

**Consequences.** Examples must cover the variations, not just the happy path:
what changes if you alter a flag, what error appears if you get it wrong, how
this command differs from its neighbour, what the standard practice is. Error
messages are quoted verbatim because a reader cannot paste them into a search
box. Edge cases are content, not appendix material.

**Rejected.** A conventional tutorial that introduces commands and points at
the official documentation for the rest. It fails the moment the reader has no
documentation to reach.

---

## 2026-09-11. Examples first, prose only when an example is not enough

The ordering rule for explaining anything: an example, then a short paragraph
if the example is incomplete, then a long explanation only if leaving it out
would let the reader damage something. Tables replace all three whenever the
content is a list of parallel facts.

**Why.** The user's framing, and it is right: a good example can be worth more
than two pages of description, and tables carry the same information in fewer
words and are faster to search.

**Consequence.** Long prose is allowed. It is just never the first tool
reached for, and it needs a reason to exist.

---

## 2026-09-11. Markdown source, single-file HTML and PDF as output

**Why.** A single self-contained HTML file opens in any phone browser with the
network off, has a clickable table of contents, supports find-in-page, and lets
code blocks scroll horizontally instead of wrapping into nonsense. Markdown is
the source because it is plain text, diffs well, and every other format can be
generated from it.

**Rejected.** Word, which handles long transcripts, wide tables and monospace
alignment badly and cannot be versioned sensibly. EPUB, which was considered
and can be added later, but which breaks long code blocks across lines.
PDF-only, which is the worst format for code on a small screen.

**Mechanism.** `tools/build_html.py` then `tools/build_pdf.ps1`.

---

## 2026-09-11. Scope: all of Git, plus GitHub and GitLab, plus internals

**Why.** Internals are included because questions like "why does rebase change
the hash" and "what exactly is a detached HEAD" have no satisfying answer
without them, and a reader who cannot search needs the real answer the first
time. Platform chapters are included because a reader who never opens a pull
request is not actually done learning Git in practice.

**Rejected.** CI/CD, which is a second book and is not Git.

---

## 2026-09-11. Teach switch and restore first, show checkout alongside

**Why.** `git checkout` is genuinely two unrelated commands wearing one name,
and that overloading is a large share of beginner confusion. Git 2.51 declared
`git switch` and `git restore` no longer experimental, so their interface is
now stable and safe to teach as the default.

**But.** `git checkout` is explicitly not being deprecated, and the world is
full of older scripts, tutorials and habits. So every modern form is shown with
its classic equivalent in a table. The reader should be able to read both and
write the modern one.

The same treatment applies to `git config`, whose flag-based interface was
deprecated in 2.46 in favour of subcommands.

---

## 2026-09-11. Bash is the primary shell, Windows differences are called out

**Why.** Nearly all Git documentation, tutorials and examples in the world are
written for a POSIX shell, so a reader trained on Bash can follow anything they
later encounter. Windows differences are frequent enough to deserve a dedicated
call-out box and are collected again in Appendix H.

**Rejected.** Writing every example twice, which inflates the book by roughly
half for a benefit that a call-out box already delivers.

---

## 2026-09-11. Every transcript is real and every hash is reproducible

No output in the book is typed from memory or invented. Examples are generated
by scripts under `sandbox/`, which pin the author, committer, clock,
configuration and line endings so that the same commands produce the same
commit hashes on any machine.

**Why.** A reader with no computer cannot verify anything. Reproducible hashes
are the only evidence available that the examples were actually run.

**Verified by** `sandbox/scripts/selftest-reproducibility.sh`, which builds the
same repository twice in different directories and fails if the hashes differ.

**Cost accepted.** Writing a chapter now means writing its generator script
too. This is slower and it is the point.

---

## 2026-09-11. Verify every Git fact against the installed documentation

Never state Git behaviour from recall. The complete upstream documentation for
the installed version ships with Git itself, so this is a local lookup.

**Why.** Training data reflects older releases. Checking against the 2.55 docs
immediately turned up three facts that recall got wrong: the `git config` flag
interface is deprecated since 2.46, Git has four configuration levels rather
than the three every summary mentions, and `git history` has `split` and
`reword` subcommands and not only `fixup`.

**How.** See CLAUDE.md for the exact paths.

---

## 2026-09-11. Deliver part by part and stop for feedback

*Refined 2026-09-14: see "A part is delivered through three checkpoints" below.*

**Why.** Correcting tone, depth or density in Part 1 is cheap. Correcting it in
Part 11, after eighty chapters have been written in the wrong register, is not.

---

## 2026-09-11. Target Git 2.55, badge anything newer than 2.23

Git was upgraded from 2.49 to 2.55.0.windows.5 before writing started, so the
examples run on a current release.

**Consequence.** A reader on an older Git needs to know which commands will not
exist for them, because the failure mode is an `unknown option` message that
does not mention versions at all. Anything introduced after Git 2.23 carries a
badge naming the release that added it.

**Baseline 2.23** because that is when `git switch` and `git restore` arrived,
and they are taught as the default.

---

## 2026-09-12. The book is bylined, and says how it was made

The book had no author, no licence and no way to report an error. That was an
omission rather than a decision, and it was noticed before publication.

Front matter now names the author, the Git version targeted, the build date and
commit, where to report a mistake, and the licence. `tools/build_html.py`
stamps the date and commit automatically so a reader can say which copy they
hold.

**Why front matter matters more here than in an ordinary book.** The reader has
no internet. They cannot look up who wrote this, when, against which Git
version, or whether a correction exists. If that information is not on the
page, it does not reach them at all.

The colophon also discloses that the prose was drafted by an AI assistant
working to the author's specification, alongside the description of how
examples were generated and verified. Both are there for the same reason: this
is a reference book that the reader has no way to check against anything else,
so they are entitled to know how it was built.

**Licence: CC BY-SA 4.0 for the text, MIT for the scripts.** Share-alike on the
prose keeps derived versions and translations open, which matters for a book
meant to be passed hand to hand. The scripts exist to be copied, so they carry
no such obligation. The MIT text in `LICENSE` was fetched verbatim from the
SPDX license list rather than written from memory, because a paraphrased
licence is worse than none.


---

## 2026-09-13. The first release waits for the complete book

No GitHub release, and no PDF handed out, until every chapter and every
appendix is written and every check passes.

**Why.** The book is designed to be copied and passed hand to hand with no
internet, and its licence encourages exactly that. So any file that leaves has
to be treated as if it will circulate forever without updates. A pre-release
label lives on GitHub, not inside the PDF. And the written chapters already
point forward to chapters up to 83: a partial copy gives an offline reader dead
ends with no way to reach the rest.

"Complete" includes the appendices, because Chapter 1 promises them as the way
to find answers.

**Rejected.** Releasing each part as it is written. The one thing that would
make that defensible is a build that replaces references to unwritten chapters
with a visible "not yet written" marker, and that is not worth building now.

---

## 2026-09-13. Part 2 was not complete enough, and what "complete" now means

The author reviewed Part 2 and found the writing good but the coverage short of
what Chapter 1 promises. Measured, not guessed: 160 option rows in Part 2's
tables, 74 with an example, 86 without. And questions a reader would obviously
ask, such as how `git diff` differs from the `diff` command, were not answered.

**The standard, agreed in discussion:**

- **An example goes in when a reader would still be unsure of the result.** The
  test is the author's own framing from the first message: the reader must not
  be left thinking "if I had a computer I would run this to see". An example is
  redundant only if a reader who has read the chapter so far could confidently
  predict its output. The same command in a different state (an empty
  repository, a detached HEAD, mid-rebase) usually passes this test.
- **Comparisons are content, not extras.** When two commands or options look
  alike, say so and show the difference. When they are genuinely identical, say
  that too, and show it.
- **Each chapter's generator script starts with the list of questions it
  answers.** The list exists to find gaps. It only grows: an example that
  teaches something not on it means the list was incomplete. It never rejects
  an example.
- **Every option in a table needs one of three things.** An example in the
  chapter; a pointer to the chapter where its concept is taught, with the full
  example there rather than repeated; or a written reason for having none, as a
  comment in the chapter file that does not appear in the book.
- **Exceptions are reported, not buried.** Each delivery message lists every
  exception and its reason, so the author can reject one without opening a
  file.

**The first proposal was wrong in one respect.** It said an example not
answering a listed question would be left out. The author objected that an
example can carry new information without matching a listed question, and that
the list might be incomplete. Both are right: used as a gate, an incomplete
list protects itself from being corrected. The list was demoted to a tool for
finding gaps, and the inclusion test became reader uncertainty.

**Calibrated on Chapter 13 first**, before touching the other seven chapters,
so that the depth could be corrected once rather than eight times.

---

## 2026-09-13. Transcripts and options are checked by programs

Two tools, both of which must pass before a part is called done:

- `tools/verify_transcripts.py` runs a chapter's generator from nothing and
  checks every transcript in the text against the real output, allowing only
  `...` and comment lines.
- `tools/audit_examples.py` checks every option named in a table for an
  example, a pointer, or a written exception.

**Why.** Rules that depend on care alone were already broken. The first run of
the verifier over the written chapters found transcripts in Chapters 7 to 16
that did not match real output, most of them output trimmed without the `...`
marker, a few with the command simplified, and one line in Chapter 13 typed
from memory. Chapters 1 to 3 have no generator script at all, so nothing in
them can be verified yet.

**What the audit does not measure.** Comparisons and "what happens if" cases
are invisible to it. Passing means no option was forgotten, never that a
chapter is complete.

---

## 2026-09-13. Colour in transcripts, and the time zone pinned

Options such as `--color-words` and `--color-moved` mean nothing without
colour, so those transcripts are captured with colour forced on through the
environment and rendered in the book. Escape codes are stored in the Markdown
as the visible characters `\e[...m` inside `ansi` blocks, which keeps the source
readable, and `tools/build_html.py` turns them into styled text for both themes.

The time zone is now pinned to UTC in the harness. Git's default dates carry
their own offset, but `--date=local` and non-Git tools such as `diff -u` print
local time, so an example could otherwise differ between two machines.

---

## 2026-09-13. A chapter says what a command is before anything else

The reworked Chapter 13 opened with a detailed comparison between `git diff` and
the `diff` command, before explaining what `git diff` is or how to read its
output. The author caught it. The comparison had been placed first because the
author had asked about it, which is writing for the reviewer rather than for the
reader, and the section leaned on material taught later in the same chapter.

**The order is now fixed** for every chapter about a command: what it is, its
synopsis, its options at a glance, then the details in teaching order, then
comparisons with similar commands, then reference tables. CLAUDE.md spells this out.

**Corrected the same day.** A first version of this rule also required every
section to open with prose before its example, and 33 lead sentences were added
to Chapter 13 under it. The author pointed out that this contradicts the
three-layer rule: an example that is clear on its own needs no sentence in front
of it. The author's complaint had been about the order of the chapter, not of
each section. The lead sentences were removed again, apart from three that carry
something the example cannot show: why a diff chapter switches to `git log`,
what `git -c` means before Chapter 62 introduces it, and one fact about comparing
commits, which moved after its example.

**Nothing correct is removed in a rework.** Checking the reordered chapter
against its earlier versions, sentence by sentence, found content lost along
the way: the phrase describing `git range-diff` as a diff of diffs, the note
that `-G` also finds commits that only moved a line, and three smaller
sentences. They were restored, the `-G` claim after testing it, which also
showed that `-S` does find a line moved to a different file. Sentences removed
on purpose were ones that were wrong, such as the claim that the `--stat`
numbers are proportional, or that could not be verified.

**Tables of values show complete syntax.** The author also found a table of
`--color-moved` modes headed "Mode", with no indication of what a mode is or
where it goes. A scan of the book found eight tables with the same flaw, five of
them in Chapter 13. Rows now read `--color-moved=zebra` rather than `zebra`,
and the audit tool checks each value as its own row, so every value is either
demonstrated, pointed to, or excused in writing.

**Why a rule and not just a fix.** The author cannot read thousands of pages
word by word, so any class of mistake found once has to become something that
is checked every time, either by a tool or by the pre-delivery checklist in
CLAUDE.md.

---

## 2026-09-12. The title is Git by Example

Chosen over "Git Handbook". At least two published books and GitHub's own guide
already use "Git Handbook", so it names nothing in particular. "Handbook"
describes the format; "by example" describes what makes this book different,
and that belongs in the title. The subtitle, *A Complete Offline Handbook*,
keeps the other word.

---

## 2026-09-12. The colophon names the model, and thanks Amin Hedayati

The first version of the colophon said the prose was drafted by "an AI
assistant". That was the one vague sentence on a page that pins the Git version,
the build date and the commit. It now names Claude Opus 5 and the Ultracode
effort setting, and says later parts may name a different model so the sentence
stays true as the book grows. The effort setting is recorded as the author
stated it; the model cannot see its own setting.

The Thanks section opens with Amin Hedayati, who made the writing of this book
possible.

---

## 2026-09-13. Colour only where colour is the point

Most transcripts stay plain even though a terminal would colour them. Plain text
reads better on a phone and in both themes, and colour adds nothing to a diff
whose lines already begin with `+` and `-`. Colour is used where the option being
shown is about colour: `--color-words`, `--color-moved`, whitespace-error
highlighting. The author reviewed the coloured sections of Chapter 13 and
accepted them.

---

## 2026-09-14. Every chapter lists the questions it answers, inside the book

Chapter 13 grew to about fifty pages, and its section headings are too broad to
find an answer by: nothing in "Whitespace" says the difference between `-b` and
`-w` is in there. The author asked whether the question lists should be in the
book. They should, per chapter.

**Form.** A collapsed "Questions this chapter answers" block directly after the
chapter's "What it is" section, so the explanation of the command is still the
first thing read. In the HTML it opens with a tap; in the PDF it prints open.
The questions are grouped by the chapter's sections and each one links to the
section or subsection that answers it.

**Wording.** Questions are written from the point of view of a reader who does
not know the answer yet, in the words they would use while stuck: "I set the
rename threshold to 5 and nothing changed. Why?" rather than "Why is -M5 not
5%?". The working list that used to sit in each generator script referred to
script sections and gave answers away. It is replaced by the list in the
chapter, which becomes the single source.

**Links.** Section headings get anchors unique across the whole book, because
the book is one HTML file and headings such as "Synopsis" repeat in every
chapter. Anchors are prefixed with the chapter number. `tools/check_refs.py`
fails on a link that no longer leads to a heading, and on a section of a chapter
that no question points to, so the list and the chapter cannot drift apart. The
"Covered in" column of the options table becomes links for the same price.

**Rejected.** One list per Part, which puts hundreds of questions far from their
answers and is unusable on a phone. A separate appendix of questions and
answers, which would duplicate the book. Instead, when the appendices are
written, Appendix G will gather every chapter's questions into one linked list
beside its decision tables, for a reader who does not know which chapter to
open.

---

## 2026-09-14. Removals are reported by a tool, and the record is kept current

**The question-coverage check could be misread.** `check_refs.py` fails when a
section of a chapter has no question pointing to it. The author pointed out that
this looks as if useful material without a question would be deleted. The check
never changes a file, and it only looks at main sections, not subsections,
paragraphs or examples. But the author's instinct was right about the risk: an
error can be silenced by adding a question or by deleting the section, and a
tool cannot tell which was done. The error message now states the only correct
fix, and CLAUDE.md says the same.

**"Nothing correct was removed" is now a report, not a promise.** The
sentence-by-sentence comparison that found content lost in Chapter 13's rewrites
became `tools/compare_versions.py` and a required step before every commit that
edits a chapter. It lists what a chapter no longer contains, marks each item as
`changed` or `REMOVED`, and never passes or fails on its own, because some
removals are right. Table rows are matched by their first cell rather than by
similarity: a first version matched them by similarity and reported a deleted
row as merely reworded, because rows in one table look alike, which would have
hidden exactly the loss the tool exists to find.

**The project record is updated at defined moments.** The author asked that the
documentation never again fall behind the decisions, as it had between Part 2
and this point, without turning every message into a documentation pass.
CLAUDE.md now lists the moments to stop and check: when a question is settled
with the author, when a rule or tool changes, when a chapter's status changes,
and before every delivery and every new part.

---

## 2026-09-14. A part is delivered through three checkpoints

Chapters turned out several times larger than first estimated; Chapter 13 alone
is about fifty pages. The author prefers to keep giving instructions a part at a
time and asked whether quality could be kept at that size.

**The honest answer was: yes for a part as the unit of instruction, no for a
part as one uninterrupted delivery.** The checks that tools run are per chapter
and do not weaken with size. What does not scale is every mistake no tool sees,
such as section order, ambiguous tables, question wording or an over-applied
rule. Every real problem the author found in Chapter 13 was of that kind, and in
a whole part it would have been repeated in every chapter before anyone read
one. A long run also means the conversation is summarised along the way, which
is where details such as keeping the documentation current were lost before.

**So the author still says "do Part N", and inside the part:** the question lists
of all its chapters go to the author first, in one message; chapters are then
written and committed one at a time with every check; and the first finished
chapter is sent straight away while work continues, so a systematic problem is
caught before it spreads. CLAUDE.md describes the steps.

---

## 2026-09-14. Contents with sections, and bookmarks in the PDF

**HTML.** The contents at the top of the book listed parts and chapters only. Each
chapter now has a collapsed list of its sections, with subsections indented under
them, all as links, opened by a separate arrow so that tapping a chapter's name
still goes straight to it. Two levels, not three: collapsing each section
separately would mean too many small taps on a phone. There is no second section
list inside the chapter, because the question list already links to every
section and, in Chapter 13, to every subsection.

**PDF.** The contents had been hidden in print by a rule in the build, on the
reasoning that chapter names without page numbers are little use on paper. In a
PDF the links are clickable, so the contents page now prints, with parts and
chapters as links. The full tree of sections is carried as PDF bookmarks, the
collapsible panel in a PDF reader, generated by Edge from the heading levels.
The author had assumed the PDF had no links at all; it did, 165 of them, from the
question list and section references.

**Rejected.** Printing every section in the contents page, which at the size of
the finished book would run to dozens of pages and duplicate the bookmarks.

---

## 2026-09-14. The Part 2 rework runs without the first two checkpoints

After approving Chapter 13's question list, the author asked for the other seven
Part 2 chapters to be reworked in one go, with nothing sent to them along the
way. That waives, for this round only, the question lists sent first and the
first chapter sent early. Everything else stands: each chapter is committed on
its own, after every check passes and every removal is accounted for, and the
checkpoints apply again from Part 3.

The risk this accepts is the one the checkpoints guard against: a mistake no
tool sees, repeated in every chapter before the author reads one. Chapter 13
having been corrected and approved makes that less likely, which is why the
author judged it acceptable here.

---

## 2026-09-14. Version badges confirmed from Git's source when release notes are silent

Writing badges for Chapter 9 showed that the release notes do not mention every
option. `git clone --revision`, `git clone --tags` and `git init
--initial-branch` appear in none of them, so "confirm the release from the
release notes" had no answer to give, and guessing is what the rule forbids.

`tools/first_version.py` reads a file of Git's source as it was at each release
tag and binary-searches for the first release that contains a pattern. For a
badge it searches the command's C source for the option's exact definition,
because documentation can lag behind: `git clone --tags` works from 2.49 but was
documented only in 2.52. It needs the network, which is acceptable because it is
used for writing the book, never by its reader.

**Rejected.** Badging from the documentation's history alone, which gives the
wrong release when the documentation lagged; and a loose pattern such as the
bare option name, which matched an unrelated string and answered 2.11 for an
option added in 2.49.

---

## 2026-09-15. Shell-dependent commands: bash transcripts, other shells in prose

The author asked why `git add *` was missing from Chapter 11's ways to stage
everything, then suggested adding the quoted forms too. Testing showed the
result depends on the shell. In Git Bash the shell expands `*`, so names
starting with a dot and deletions at the top are left out, and an ignored name
makes the command fail. In PowerShell and cmd, `*` reaches Git unchanged and
behaves like `git add .`. Single quotes fail in cmd, while double quotes work
in all three shells.

**Decided.** Both forms became rows of the table, with columns for names
starting with a dot and for ignored files, so the difference is visible in the
table itself, followed by bash transcripts. The PowerShell and cmd results are
described in a Windows call-out, because the sandbox can only produce bash
output and a transcript must never be anything but real sandbox output.

**Rejected.** Separate rows for `'*'` and `"*"`, which differ only in cmd, where
one sentence says so.

---

## 2026-09-15. Part 3 runs without the first two checkpoints

The author asked for Part 3 to be written from start to finish with nothing sent
to them along the way ("no need to show me anything; go to the end if you can").
As for the Part 2 rework, that waives the question lists sent first and the
first chapter sent early, for this part only. Each chapter is still committed
on its own after every check passes, and the part is delivered and stops for
feedback at the end.

The risk is the same one: a mistake no tool sees, repeated across six chapters.
The author accepted it, with Chapter 13, approved, as the calibration.

---

## 2026-09-15. Relative dates pinned through Git's test clock, opt-in

Chapter 17 needs `--since='3 hours ago'`, `--date=relative` and `--date=human`,
which are computed against the current time, so their transcripts would stop
matching as real days pass. Git's own test suite fixes "now" with the
`GIT_TEST_DATE_NOW` environment variable. The harness gained `sb_pin_now`, which
sets it to the sandbox clock and keeps it there as the clock ticks.

**Decided.** Opt-in, called once at the top of a generator that shows relative
dates. The reader never sees it: the printed commands are unchanged, and the
chapter says what "now" is in the example.

**Rejected.** Setting it for every generator, because it also moves "now" for
commands that compare against real file times, such as `git gc --prune=now`,
and could change transcripts that are correct today. Also rejected: avoiding
relative dates in examples, which would leave the options that most need an
example without one.

---

## 2026-09-15. Part 4 runs without the first two checkpoints

As for Part 3, the author asked for Part 4 to be written to the end with nothing
sent along the way ("no need to send me anything; do it to the end of Part 4"),
after Part 3 was delivered. The question lists sent first and the first chapter
sent early are waived for this part only. Each chapter is still committed on its
own after every check passes, and the part is delivered and stops for feedback
at the end.

---

## 2026-09-16. The checkpoints are removed; a part runs to the end

Part 5 opened with the first checkpoint: the question lists for all eleven
chapters, sent for approval before any chapter was written. The author's answer
was to delete the rule. Parts run from start to finish with nothing sent along
the way, and the assistant interrupts only for a question that genuinely
changes the work.

**Why.** The checkpoints were agreed on 2026-09-14 and then waived by the
author for Part 2's rework, for Part 3 and for Part 4 — every part since they
were written. A rule waived every time it applies is not the rule; the waiver
is. Keeping it meant renegotiating the same exemption at the start of each
part, which costs the author a message and the assistant a stop.

**What stays.** Chapters are written, checked and committed one at a time, so
each is a complete unit in the history and a systematic problem is fixable
without unpicking a part-sized commit. The part is still delivered at the end
and still stops for feedback before the next one begins. Every tool check still
has to pass before a part is called done.

**What replaces the checkpoint.** A question is asked when it materially
changes what gets written and cannot be settled from the installed
documentation, the source, or a test in the sandbox — and then it is asked
rather than guessed at. The three questions that opened Part 5 were of that
kind: one was answered, and two the author handed back to the assistant's
judgement.

**The risk this accepts** is the one the checkpoints guarded against: a mistake
no tool can see, repeated across a whole part before the author reads a word of
it. Four parts have now been written this way without one being found, and
Chapter 13 stays the calibration for what "complete" means.

---

## 2026-09-16. Part 5 scope: filter-repo, git replay, and where rebase is cut

Three questions settled at the start of Part 5.

**`git filter-repo` is installed into the sandbox and shown working.** Git's
own documentation puts a warning at the top of `git filter-branch` telling the
reader to use `git filter-repo` instead, so a chapter that demonstrates only
`filter-branch` teaches the tool Git calls dangerous and leaves the recommended
one as hearsay. It is not part of Git and had to be installed, which is
acceptable for writing the book in the same way `tools/first_version.py` uses
the network. Chapter 37 keeps full `filter-branch` coverage for a reader who
cannot install anything, and says plainly that `filter-repo` is a separate
download. The BFG is Java and stays prose-only.

**`git replay` is a section of Chapter 33, not a chapter.** Git 2.54 added it
and 2.55 gave it `--revert`; it is a rebase that needs no working tree and runs
in a bare repository. It is experimental and small, and the outline has no
number for it. Inserting a chapter would mean a gap in reading order or
renumbering the whole book, which OUTLINE.md forbids for something this size,
so it goes among rebase's neighbours where a reader meets it in context.

**Chapter 33 is rebase without the todo list; Chapter 34 is the todo list.**
`--exec` and `--rebase-merges` go to Chapter 34 although neither needs `-i`,
because both work by writing lines into the todo list and cannot be explained
without it. `--update-refs` stays in Chapter 33 because it works without the
list, with its `update-ref` todo line in Chapter 34. Chapter 33's options table
points at Chapter 34 for the rows it does not demonstrate.

---

## 2026-09-16. Transcripts that cannot be reproducible, and how they are handled

Part 5 turned up three kinds of output that no amount of pinning makes stable,
and each needed a decision rather than a workaround.

**Timings and progress counters.** `git filter-branch` prints
`Rewrite <hash> (3/7) (1 seconds passed, remaining 2 predicted)`, and
`git filter-repo` prints `New history written in 0.40 seconds`. Both depend on
how fast the machine is. They are cut from the transcript with `...`, which the
verifier already allows, and the chapter says the progress lines were cut. The
alternative — filtering the command's output through `grep -v` — was rejected
because the printed command must be exactly what a reader types.

**Options that read the real clock.** `git rebase --reset-author-date` sets the
author date to the moment it runs, which changes the resulting hash on every
run. `GIT_TEST_DATE_NOW`, which `sb_pin_now` uses to fix relative dates, does
not reach it; that was tested, not assumed. The option gets a written exception
saying so, because a transcript of it cannot exist.

**Editors that rename a temporary file.** `sed -i` works as `GIT_EDITOR` for
`git commit`, but not for `git history` or `git replace --edit`, which hold the
message file open: MSYS then fails with "Device or resource busy". The
stand-in editor in those chapters is `cp ../message.txt`, which writes over the
file in place. It also reads better: the reader sees a prepared message being
put in, rather than a `sed` script.

**And one case of the opposite.** Chapter 37 deliberately does *not* call
`sb_pin_now`, because `git gc --prune=now` compares against real file times and
a pinned clock would stop it pruning anything, which is the whole point of that
section.

---

## 2026-09-16. Part 5 is written, and what the reader can now do

Chapters 28 to 38 cover rewriting history: the rule itself, `commit --amend`,
`reset`, `revert`, `cherry-pick`, `rebase` in two chapters, the fixup and
`git history` shortcuts, `reflog`, removing secrets, and `replace` and `notes`.

Three decisions inside the part are worth keeping:

**The two rebase chapters are cut at the todo list.** `--exec` and
`--rebase-merges` are in Chapter 34 with `-i`, although neither requires it,
because both work by writing lines into the todo list and cannot be explained
without showing it.

**`git history` moves every descendant branch.** Its default is
`--update-refs=branches`, which surprised the examples themselves: the first
draft of Chapter 35's generator silently rewrote the branch its scratch copies
were made from. The chapter says so twice, and the generator restores the
branch before each demonstration.

**Git 2.55 writes the todo list's onelines as comments.** A line reads
`pick e1fa553 # Add the reader`, where Git's own documentation still shows
`pick e1fa553 Add the reader`. Verified against the installed binary with an
explicit `rebase.instructionFormat`, so it is the version's behaviour and not
a configuration; Chapters 34 and 35 describe what a reader will actually see.

---

## 2026-09-17. Part 6 starts with Chapters 39 to 41, and git ls-remote goes in 39

The author asked for Chapters 39, 40 and 41 of Part 6 rather than the whole
part. They were written, checked and committed one at a time, and delivered
together; Chapters 42 to 46 wait for the author's next instruction.

**`git ls-remote` is a section of Chapter 39.** The outline gives it no chapter.
Chapter 40 needs it to show what a transport returns, and Chapter 41 to show the
server before a fetch, so it has to be taught before both; `git remote show`
answers the same question in Chapter 39, which makes that its natural
neighbour. Putting it in Chapter 41 would have made Chapter 40 use a command it
had not yet explained.

---

## 2026-09-17. Chapter 40 is demonstrated without a server

Authentication and the network were the one thing Chapter 2 said the sandbox
cannot show. Chapter 40 shows everything Git itself does, and stops where a
server would answer.

**How.** A stand-in `ssh`, a four-line script the chapter prints, logs the
command line Git gives `ssh` and runs the command locally. That turned out to be
the most useful example in the chapter: it shows the real arguments for every
URL form, for each SSH variant (`plink`, `tortoiseplink`, `simple`), with a
port, with `-4`, and without protocol version 2, which a real `ssh` would never
show. A stand-in askpass program shows the exact questions Git asks. Credential
helpers run with their files and sockets inside the sandbox, whose `HOME` is
the sandbox root. `https://` URLs appear only in commands Git refuses before it
connects.

**What is quoted instead.** Git's HTTP error messages are quoted from its
source (`remote-curl.c`, `http.c`); `ssh`'s from OpenSSH's source; GitHub's
greeting, its 13 August 2021 end of password authentication and its 15 March
2022 end of `git://` from GitHub's documentation and announcements. None of
them is presented as a transcript.

**Rejected.** A local HTTP server, such as `git http-backend` behind Python,
to produce real HTTPS transcripts. Its output would show a test server and a
port number rather than anything a reader meets on a real host, the messages
that matter most come from the host rather than from Git, and it would bring a
background process, a port that may be taken and a firewall prompt into a
generator whose only job is to be reproducible. Also rejected: leaving
credentials out of transcripts entirely, which the rule "no credential commands
in generators" would have implied; the rule's reason is not touching the real
machine, and a sandboxed `HOME` meets it. CLAUDE.md records the safeguards.

**A mistake made on the way.** One experiment, not the generator, ran
`git ls-remote ftp://example.com/...`, which connected to the network before
failing. Nothing was sent but the connection attempt. CLAUDE.md now says to try
a new URL scheme in scratch first.

---

## 2026-09-17. Git 2.55 behaviour that looks like a bug is documented as observed

Running the examples found four behaviours of Git 2.55 that contradict its
own documentation or hints, or leave a repository in a half-changed state:

- `git remote set-branches` without `--add` fails silently, with exit status 1,
  once a remote has no fetch refspecs (Chapter 39).
- `git remote remove` of a remote made with `-t` leaves `<name>/HEAD`, and a
  later `git remote rename` to that name renames the configuration and then
  stops, with "dangling symref already exists" (Chapter 39).
- The hint printed by `remote.<name>.followRemoteHEAD=warn` suggests the value
  `warn-if-not-branch-<name>`, which Git reads as a branch called
  `branch-<name>` (Chapter 41).
- `git fetch --atomic` prints the update it then does not make (Chapter 41).

**Decided.** Each is shown as a transcript, with what the source says causes it
and, where there is one, the repair. The book describes the Git a reader has.
Whether to report them to the Git project is left to the author.
