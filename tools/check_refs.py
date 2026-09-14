#!/usr/bin/env python3
"""Check that every cross-reference in the book points somewhere real.

A reader with no internet cannot recover from "see Chapter 47" when Chapter 47
turns out to be about something else, so the numbering in OUTLINE.md is the
contract and this checks the text against it.

It also checks links to sections. Every `[text](#slug)` must lead to a heading
in the same chapter, and every `[text](#ch13-slug)` to a heading in that
chapter. In a chapter with a question list, every section must be the target of
at least one question, so the list cannot fall behind the chapter. The only
correct response to that error is a new question; the check exists to make the
list grow with the chapter, never to make the chapter shrink to fit the list.

    python tools/check_refs.py          # report and exit non-zero on a problem
    python tools/check_refs.py --map    # also print who references what
"""

from __future__ import annotations

import pathlib
import re
import sys

import anchors

ROOT = pathlib.Path(__file__).resolve().parent.parent
BOOK = ROOT / "book"
OUTLINE = ROOT / "OUTLINE.md"

OUTLINE_CHAPTER = re.compile(r"^- \[[ x]\] (\d+)\. (.+?)\s*$", re.M)
OUTLINE_APPENDIX = re.compile(r"^- \[[ x]\] ([A-Z])\. (.+?)\s*$", re.M)
REF_CHAPTER = re.compile(r"\bChapter (\d+)\b")
REF_APPENDIX = re.compile(r"\bAppendix ([A-Z])\b")
SECTION_LINK = re.compile(r"\]\(#([^)\s]+)\)")
QUESTIONS = re.compile(r'<details class="questions"[^>]*>(.*?)</details>', re.S)


def section_link_problems() -> list[str]:
    """Links to sections that do not exist, and sections no question points to."""
    files = [p for p in sorted(BOOK.rglob("*.md")) if p.name != "SUMMARY.md"]
    headings = {}
    for path in files:
        text = path.read_text(encoding="utf-8")
        headings[anchors.chapter_prefix(path)] = (path, text, anchors.markdown_headings(text))

    problems = []
    for prefix, (path, text, heads) in headings.items():
        local = {slug for _, _, slug in heads}
        name = path.relative_to(ROOT)
        for target in SECTION_LINK.findall(text):
            if target in local:
                continue
            m = re.match(r"(ch\d+|about-this-book)(?:-(.+))?$", target)
            if m and m.group(1) in headings:
                other = {s for _, _, s in headings[m.group(1)][2]}
                if m.group(2) is None or m.group(2) in other:
                    continue
            problems.append(f"{name}: link to #{target} leads to no heading")

        block = QUESTIONS.search(text)
        if block:
            asked = set(SECTION_LINK.findall(block.group(1)))
            for level, title, slug in heads:
                if level == 2 and slug not in asked:
                    problems.append(
                        f"{name}: no question points to the section \"{title}\". "
                        "Fix it by adding a question this section answers. Never remove, "
                        "merge or retitle the section to silence this check.")
    return problems



TABLE_START = "| Chapter | Refers to |"


def write_outline_table(ref_map: dict[str, list[str]], outline_text: str) -> None:
    """Replace the cross-reference table in OUTLINE.md with current reality."""
    rows: list[str] = []
    for path in sorted(ref_map):
        own = re.search(r"/(\d+)-", "/" + pathlib.Path(path).name)
        if not own:
            continue
        number = int(own.group(1))
        # Drop the chapter's reference to itself, which is just its own title.
        refs = [r for r in ref_map[path] if r != f"Chapter {number}"]
        if refs:
            rows.append(f"| {number} | {', '.join(refs)} |")

    table = "\n".join([TABLE_START, "|---|---|", *rows])
    start = outline_text.index(TABLE_START)
    end = outline_text.index("\n\n", start)
    OUTLINE.write_text(
        outline_text[:start] + table + outline_text[end:], encoding="utf-8"
    )


def main() -> int:
    text = OUTLINE.read_text(encoding="utf-8")
    chapters = {int(n): title for n, title in OUTLINE_CHAPTER.findall(text)}
    appendices = {letter: title for letter, title in OUTLINE_APPENDIX.findall(text)}

    if not chapters:
        print("OUTLINE.md lists no chapters", file=sys.stderr)
        return 1

    problems: list[str] = []
    ref_map: dict[str, list[str]] = {}

    for path in sorted(BOOK.rglob("*.md")):
        if path.name == "SUMMARY.md":
            continue
        body = path.read_text(encoding="utf-8")
        found: set[str] = set()

        for n in map(int, REF_CHAPTER.findall(body)):
            found.add(f"Chapter {n}")
            if n not in chapters:
                problems.append(f"{path.relative_to(ROOT)}: Chapter {n} does not exist")

        for letter in REF_APPENDIX.findall(body):
            found.add(f"Appendix {letter}")
            if letter not in appendices:
                problems.append(f"{path.relative_to(ROOT)}: Appendix {letter} does not exist")

        if found:
            ref_map[str(path.relative_to(BOOK))] = sorted(
                found, key=lambda s: (s.split()[0], int(s.split()[1]) if s.split()[1].isdigit() else s)
            )

    problems += section_link_problems()

    if "--map" in sys.argv:
        width = max(len(k) for k in ref_map) if ref_map else 0
        for name, refs in ref_map.items():
            print(f"{name:<{width}}  {', '.join(refs)}")
        print()

    if "--write-table" in sys.argv:
        write_outline_table(ref_map, text)
        print("rewrote the cross-reference table in OUTLINE.md")

    print(f"{len(chapters)} chapters and {len(appendices)} appendices in OUTLINE.md")
    if problems:
        print(f"{len(problems)} broken reference(s):", file=sys.stderr)
        for p in problems:
            print("  " + p, file=sys.stderr)
        return 1
    print("all chapter, appendix and section references resolve")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
