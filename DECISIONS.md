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

