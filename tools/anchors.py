"""Section anchors, shared by the build and by the reference checker.

Every section heading in the book gets an id that is unique across the whole
book, because the book is built into a single HTML file and headings such as
"Synopsis" repeat in every chapter. The id is the chapter's own prefix followed
by the heading's slug:

    Chapter 13, "## Renames and copies"   ->  ch13-renames-and-copies

Inside a chapter's Markdown, links to its own sections use the slug alone,
`[text](#renames-and-copies)`, and the build adds the prefix. A link to another
chapter's section spells out the full id, `[text](#ch5-the-map)`.
"""

from __future__ import annotations

import html
import pathlib
import re

HEADING_RE = re.compile(r"^(#{2,4})\s+(.+?)\s*#*\s*$")
FENCE_RE = re.compile(r"^```")


def slug(text: str) -> str:
    text = html.unescape(re.sub(r"<[^>]+>", "", text))
    text = re.sub(r"[`*_]", "", text)
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-") or "section"


def chapter_prefix(path: pathlib.Path) -> str:
    """ch13 for 13-diff.md; the file name itself for unnumbered pages."""
    number = re.match(r"0*(\d+)-", path.name)
    return f"ch{number.group(1)}" if number else path.stem


def unique(slugs: list[str]) -> list[str]:
    """Number repeated slugs within one chapter: x, x-2, x-3."""
    seen: dict[str, int] = {}
    out = []
    for s in slugs:
        seen[s] = seen.get(s, 0) + 1
        out.append(s if seen[s] == 1 else f"{s}-{seen[s]}")
    return out


def markdown_headings(text: str) -> list[tuple[int, str, str]]:
    """(level, heading text, slug) for every ## to #### heading outside code."""
    found, in_code = [], False
    for line in text.splitlines():
        if FENCE_RE.match(line):
            in_code = not in_code
            continue
        if in_code:
            continue
        m = HEADING_RE.match(line)
        if m:
            found.append((len(m.group(1)), m.group(2), slug(m.group(2))))
    slugs = unique([s for _, _, s in found])
    return [(level, title, s) for (level, title, _), s in zip(found, slugs)]
