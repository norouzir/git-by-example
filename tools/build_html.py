#!/usr/bin/env python3
"""Build the whole book into one self-contained HTML file.

The output has no external dependencies: no web fonts, no CDN, no scripts
loaded from anywhere. It is meant to be copied to a phone and opened with no
internet connection at all.

    python tools/build_html.py
"""

from __future__ import annotations

import html
import pathlib
import re
import sys

import markdown

ROOT = pathlib.Path(__file__).resolve().parent.parent
BOOK = ROOT / "book"
OUT = ROOT / "build" / "git-by-example.html"

TITLE = "Git by Example"
SUBTITLE = "A Complete Offline Handbook"

LINK_RE = re.compile(r"^- \[(?P<label>[^\]]+)\]\((?P<path>[^)]+)\)\s*$")
PART_RE = re.compile(r"^## (?P<label>.+?)\s*$")


def read_manifest() -> list[tuple[str, list[tuple[str, pathlib.Path]]]]:
    """Return [(part label, [(chapter label, path), ...]), ...] from SUMMARY.md."""
    parts: list[tuple[str, list[tuple[str, pathlib.Path]]]] = []
    for line in (BOOK / "SUMMARY.md").read_text(encoding="utf-8").splitlines():
        part = PART_RE.match(line)
        if part:
            parts.append((part.group("label"), []))
            continue
        link = LINK_RE.match(line)
        if link and parts:
            parts[-1][1].append((link.group("label"), BOOK / link.group("path")))
    return parts


def slugify(text: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    return slug or "section"


def wrap_tables(body: str) -> str:
    """Tables must scroll inside their own box, never widen the page."""
    return body.replace("<table>", '<div class="table-wrap"><table>').replace(
        "</table>", "</table></div>"
    )


def build() -> None:
    parts = read_manifest()
    if not parts:
        sys.exit("SUMMARY.md lists no chapters")

    md = markdown.Markdown(extensions=["tables", "fenced_code", "sane_lists", "attr_list"])

    toc: list[str] = []
    chapters: list[str] = []
    counter = 0

    for part_label, entries in parts:
        if not entries:
            continue
        part_id = slugify(part_label)
        toc.append(f'<li class="toc-part"><a href="#{part_id}">{html.escape(part_label)}</a><ul>')
        chapters.append(f'<h1 class="part-title" id="{part_id}">{html.escape(part_label)}</h1>')

        for label, path in entries:
            counter += 1
            if not path.exists():
                sys.exit(f"missing chapter file: {path}")
            chapter_id = f"ch{counter}-{slugify(label)}"
            md.reset()
            body = wrap_tables(md.convert(path.read_text(encoding="utf-8")))
            # The chapter's own H1 becomes the anchor target.
            body = body.replace("<h1>", f'<h1 id="{chapter_id}">', 1)
            chapters.append(f'<section class="chapter">{body}</section>')
            toc.append(f'<li><a href="#{chapter_id}">{html.escape(label)}</a></li>')

        toc.append("</ul></li>")

    page = TEMPLATE.format(
        title=html.escape(TITLE),
        subtitle=html.escape(SUBTITLE),
        css=CSS,
        js=JS,
        toc="\n".join(toc),
        chapters="\n".join(chapters),
        chapter_count=counter,
    )

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(page, encoding="utf-8")
    size_kb = OUT.stat().st_size / 1024
    print(f"{OUT.relative_to(ROOT)}  {counter} chapters  {size_kb:.0f} KB")


CSS = """
:root {
  --bg: #fbfaf8;
  --fg: #1c1b19;
  --muted: #6b6862;
  --rule: #e0ddd6;
  --code-bg: #f2efe9;
  --accent: #7a3b12;
  --quote-bg: #f4f1ea;
  color-scheme: light dark;
}
@media (prefers-color-scheme: dark) {
  :root {
    --bg: #16151a;
    --fg: #e6e3dd;
    --muted: #9a958c;
    --rule: #33313a;
    --code-bg: #201f26;
    --accent: #e0a878;
    --quote-bg: #1d1c23;
  }
}
* { box-sizing: border-box; }
body {
  margin: 0;
  background: var(--bg);
  color: var(--fg);
  font: 17px/1.65 Georgia, "Iowan Old Style", "Times New Roman", serif;
  -webkit-text-size-adjust: 100%;
}
header.book {
  padding: 3.5rem 1.25rem 2rem;
  border-bottom: 1px solid var(--rule);
  text-align: center;
}
header.book h1 { font-size: 2.1rem; margin: 0 0 .3rem; letter-spacing: -.02em; }
header.book p { margin: 0; color: var(--muted); font-style: italic; }
nav.toc, main { max-width: 40rem; margin: 0 auto; padding: 0 1.25rem; }
nav.toc { padding-top: 2rem; padding-bottom: 1rem; }
nav.toc h2 { font-size: .8rem; text-transform: uppercase; letter-spacing: .1em;
  color: var(--muted); font-family: system-ui, sans-serif; }
nav.toc ul { list-style: none; padding-left: 0; margin: 0; }
nav.toc ul ul { padding-left: 1rem; margin-bottom: 1rem; }
nav.toc li { margin: .3rem 0; }
nav.toc .toc-part > a { font-weight: 700; }
nav.toc a { color: var(--fg); text-decoration: none; border-bottom: 1px solid transparent; }
nav.toc a:hover { border-bottom-color: var(--accent); }
main { padding-bottom: 6rem; }
h1.part-title {
  margin: 5rem 0 0; padding-top: 2.5rem; border-top: 3px double var(--rule);
  font-size: 1.1rem; text-transform: uppercase; letter-spacing: .14em;
  color: var(--muted); font-family: system-ui, sans-serif; font-weight: 600;
}
.chapter { margin-top: 3rem; }
.chapter h1 { font-size: 1.75rem; line-height: 1.25; margin: 0 0 1.5rem;
  letter-spacing: -.015em; }
.chapter h2 { font-size: 1.2rem; margin: 2.5rem 0 .8rem;
  font-family: system-ui, sans-serif; }
.chapter h3 { font-size: 1.02rem; margin: 1.8rem 0 .6rem;
  font-family: system-ui, sans-serif; }
p { margin: 0 0 1.1rem; }
a { color: var(--accent); }
code, pre, kbd {
  font-family: "SF Mono", "Cascadia Mono", "DejaVu Sans Mono", Consolas, monospace;
}
code { background: var(--code-bg); padding: .12em .35em; border-radius: 3px;
  font-size: .85em; }
pre {
  background: var(--code-bg); border-left: 3px solid var(--rule);
  padding: .9rem 1rem; overflow-x: auto; border-radius: 0 4px 4px 0;
  font-size: .82rem; line-height: 1.5; margin: 0 0 1.3rem;
}
pre code { background: none; padding: 0; font-size: inherit; }
blockquote {
  margin: 1.3rem 0; padding: .8rem 1rem; background: var(--quote-bg);
  border-left: 3px solid var(--accent); border-radius: 0 4px 4px 0;
  font-size: .93rem;
}
blockquote p:last-child { margin-bottom: 0; }
.table-wrap { overflow-x: auto; margin: 0 0 1.3rem; }
table { border-collapse: collapse; width: 100%; font-size: .86rem;
  font-family: system-ui, sans-serif; }
th, td { text-align: left; padding: .5rem .7rem; border-bottom: 1px solid var(--rule);
  vertical-align: top; }
th { font-weight: 600; border-bottom-width: 2px; white-space: nowrap; }
td code { font-size: .95em; white-space: nowrap; }
ul, ol { padding-left: 1.3rem; margin: 0 0 1.1rem; }
li { margin: .3rem 0; }
hr { border: 0; border-top: 1px solid var(--rule); margin: 2.5rem 0; }
#top-link {
  position: fixed; right: 1rem; bottom: 1rem; background: var(--code-bg);
  border: 1px solid var(--rule); color: var(--fg); border-radius: 50%;
  width: 2.6rem; height: 2.6rem; display: none; align-items: center;
  justify-content: center; text-decoration: none; font-size: 1.1rem;
}
#top-link.show { display: flex; }
@media print {
  body { background: #fff; color: #000; font-size: 10.5pt; }
  nav.toc, #top-link { display: none; }
  main { max-width: none; }
  .chapter { page-break-before: always; }
  h1.part-title { page-break-before: always; }
  pre { border: 1px solid #ccc; background: #f6f6f6;
    white-space: pre-wrap; word-break: break-word; }
  h1, h2, h3 { page-break-after: avoid; }
  table, pre, blockquote { page-break-inside: avoid; }
}
"""

JS = """
var topLink = document.getElementById('top-link');
window.addEventListener('scroll', function () {
  topLink.classList.toggle('show', window.scrollY > 900);
}, { passive: true });
"""

TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title}</title>
<style>{css}</style>
</head>
<body>
<header class="book">
  <h1>{title}</h1>
  <p>{subtitle}</p>
</header>

<nav class="toc">
  <h2>Contents</h2>
  <ul>
{toc}
  </ul>
</nav>

<main>
{chapters}
</main>

<a id="top-link" href="#" aria-label="Back to top">&#8593;</a>
<script>{js}</script>
</body>
</html>
"""


if __name__ == "__main__":
    build()
