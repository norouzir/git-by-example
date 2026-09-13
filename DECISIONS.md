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
comparisons with similar commands, then reference tables. Within a section, the
thing being shown is named before it is shown. CLAUDE.md spells this out.

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
