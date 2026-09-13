# Git by Example

*A Complete Offline Handbook*

By M. Reza Norouzi. Text under CC BY-SA 4.0, scripts under MIT; see `LICENSE`.

A Git reference written for someone with a phone, no computer, and no internet
connection. Every question you would normally answer by running a command or
searching the web has to be answered on the page instead, so the book leans
hard on complete examples, exhaustive option tables, and real error messages
rather than summaries.

Every transcript in the book was produced by running the commands. Every commit
hash is real and reproducible.

## Reading it

| Format | File | Best for |
|---|---|---|
| HTML, single file | `build/git-by-example.html` | Reading on a phone with no internet |
| PDF | `build/git-by-example.pdf` | Printing and archiving |
| Markdown source | `book/` | Editing, searching, diffing |

The HTML build is self-contained. No fonts, scripts, or stylesheets are loaded
from anywhere, so it works with the network off.

## Layout

```
CLAUDE.md                 the working contract: rules, style, conventions
OUTLINE.md                approved structure; chapter numbers are stable
DECISIONS.md              why the book is the way it is
book/
  SUMMARY.md              build manifest; the order here is the book's order
  part-00-using-this-book/
  part-01-...             one directory per part, one file per chapter
sandbox/
  lib/sandbox.sh          the harness that makes example output reproducible
  lib/gitconfig           the pinned configuration examples run under
  scripts/                one script per chapter, rebuilds that chapter's repo
tools/
  build_html.py           Markdown to one self-contained HTML file
  build_pdf.ps1           that HTML to PDF via headless Edge
  check_refs.py           verifies every "see Chapter N" points somewhere real
  verify_transcripts.py   checks every transcript against a fresh run of its script
  audit_examples.py       checks every option in a table has an example
build/                    generated output, not tracked
```

Start with `CLAUDE.md` if you are picking this project up. It states the rules
the text is held to; `DECISIONS.md` records the reasoning behind them, so a
settled question is not reopened without new information.

## Building

```sh
python tools/build_html.py
powershell -File tools/build_pdf.ps1
```

The HTML build needs `markdown`. The PDF build needs Edge or Chrome installed.

```sh
python -m pip install markdown
```

## Reproducing the examples

Each chapter's example repository is built from nothing by its own script:

```sh
bash sandbox/scripts/ch12-commit.sh /tmp/playground
```

The harness pins the author, the committer, the clock, and the configuration,
so the commit hashes it produces are identical on any machine. See Chapter 2
for why that matters and how it works.

## Version

The book targets **Git 2.55**. Features that need a version newer than 2.23 are
marked in the text with the release that introduced them.

## Licence

The book text is licensed under Creative Commons Attribution-ShareAlike 4.0
International, so it can be copied, printed, translated and handed to someone
with no internet. The scripts under `sandbox/` and `tools/` are MIT, so they
can be copied and adapted with no share-alike obligation. Full terms in
`LICENSE`.
