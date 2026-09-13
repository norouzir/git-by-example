#!/usr/bin/env python3
"""Build the whole book into one self-contained HTML file.

The output has no external dependencies: no web fonts, no CDN, no scripts
loaded from anywhere. It is meant to be copied to a phone and opened with no
internet connection at all.

    python tools/build_html.py
"""

from __future__ import annotations

import datetime
import html
import pathlib
import re
import subprocess
import sys

import markdown

ROOT = pathlib.Path(__file__).resolve().parent.parent
BOOK = ROOT / "book"
OUT = ROOT / "build" / "git-by-example.html"

TITLE = "Git by Example"
SUBTITLE = "A Complete Offline Handbook"
AUTHOR = "M. Reza Norouzi"
TARGET_GIT = "2.55"
REPO = "https://github.com/norouzir/git-by-example"

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


def build_stamp() -> str:
    """Identify this build, so a reader offline can say which copy they hold."""
    date = datetime.date.today().isoformat()
    try:
        commit = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            cwd=ROOT, capture_output=True, text=True, check=True,
        ).stdout.strip()
        dirty = subprocess.run(
            ["git", "status", "--porcelain"],
            cwd=ROOT, capture_output=True, text=True, check=True,
        ).stdout.strip()
        return f"{date}, from commit {commit}{'+changes' if dirty else ''}"
    except (subprocess.CalledProcessError, FileNotFoundError):
        return date


def slugify(text: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    return slug or "section"


def wrap_tables(body: str) -> str:
    """Tables must scroll inside their own box, never widen the page."""
    return body.replace("<table>", '<div class="table-wrap"><table>').replace(
        "</table>", "</table></div>"
    )


ANSI_BLOCK_RE = re.compile(r'<pre><code class="language-ansi">(.*?)</code></pre>', re.S)
CSI_RE = re.compile(r"\\e\[([0-9;]*)([A-Za-z])")
BASIC = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"]


def _xterm256(n: int) -> tuple[str, str]:
    """An xterm 256-colour index as ("class", name) or ("rgb", "#rrggbb")."""
    if n < 8:
        return ("class", BASIC[n])
    if n < 16:
        return ("class", "bright-" + BASIC[n - 8])
    if n < 232:
        n -= 16
        steps = [0, 95, 135, 175, 215, 255]
        r, g, b = steps[n // 36], steps[(n // 6) % 6], steps[n % 6]
        return ("rgb", f"#{r:02x}{g:02x}{b:02x}")
    level = 8 + (n - 232) * 10
    return ("rgb", f"#{level:02x}{level:02x}{level:02x}")


def _apply_sgr(state: dict, params: str) -> None:
    codes = [int(c) if c else 0 for c in params.split(";")] if params else [0]
    i = 0
    while i < len(codes):
        c = codes[i]
        if c == 0:
            state.clear()
        elif c == 1:
            state["bold"] = True
        elif c == 2:
            state["dim"] = True
        elif c == 3:
            state["italic"] = True
        elif c == 4:
            state["underline"] = True
        elif c == 7:
            state["reverse"] = True
        elif c == 22:
            state.pop("bold", None)
            state.pop("dim", None)
        elif c == 23:
            state.pop("italic", None)
        elif c == 24:
            state.pop("underline", None)
        elif c == 27:
            state.pop("reverse", None)
        elif 30 <= c <= 37:
            state["fg"] = ("class", BASIC[c - 30])
        elif 90 <= c <= 97:
            state["fg"] = ("class", "bright-" + BASIC[c - 90])
        elif 40 <= c <= 47:
            state["bg"] = ("class", BASIC[c - 40])
        elif 100 <= c <= 107:
            state["bg"] = ("class", "bright-" + BASIC[c - 100])
        elif c == 39:
            state.pop("fg", None)
        elif c == 49:
            state.pop("bg", None)
        elif c in (38, 48) and i + 1 < len(codes):
            key = "fg" if c == 38 else "bg"
            if codes[i + 1] == 5 and i + 2 < len(codes):
                state[key] = _xterm256(codes[i + 2])
                i += 2
            elif codes[i + 1] == 2 and i + 4 < len(codes):
                r, g, b = codes[i + 2:i + 5]
                state[key] = ("rgb", f"#{r:02x}{g:02x}{b:02x}")
                i += 4
        i += 1


def _open_span(state: dict) -> str:
    if not state:
        return ""
    classes, styles = [], []
    fg, bg = state.get("fg"), state.get("bg")
    if state.get("reverse"):
        fg, bg = bg, fg
        if bg is None:
            classes.append("ansi-bg-fg")
        if fg is None:
            classes.append("ansi-fg-bg")
    for value, prefix, prop in ((fg, "ansi-fg-", "color"), (bg, "ansi-bg-", "background")):
        if value is None:
            continue
        if value[0] == "class":
            classes.append(prefix + value[1])
        else:
            styles.append(f"{prop}:{value[1]}")
    for flag in ("bold", "dim", "italic", "underline"):
        if state.get(flag):
            classes.append("ansi-" + flag)
    attrs = f' class="{" ".join(classes)}"' if classes else ""
    attrs += f' style="{";".join(styles)}"' if styles else ""
    return f"<span{attrs}>"


def _render_ansi_text(text: str) -> str:
    out, state, pos, open_ = [], {}, 0, False
    for m in CSI_RE.finditer(text):
        out.append(text[pos:m.start()])
        pos = m.end()
        if m.group(2) != "m":
            continue  # cursor movement and line erasing mean nothing on a page
        if open_:
            out.append("</span>")
            open_ = False
        _apply_sgr(state, m.group(1))
        span = _open_span(state)
        if span:
            out.append(span)
            open_ = True
    out.append(text[pos:])
    if open_:
        out.append("</span>")
    return "".join(out)


def render_ansi(body: str) -> str:
    """Colour ```ansi blocks, whose escapes are written as the characters \\e."""
    return ANSI_BLOCK_RE.sub(
        lambda m: '<pre class="ansi"><code>' + _render_ansi_text(m.group(1)) + "</code></pre>",
        body,
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
            body = render_ansi(wrap_tables(md.convert(path.read_text(encoding="utf-8"))))
            # The chapter's own H1 becomes the anchor target.
            body = body.replace("<h1>", f'<h1 id="{chapter_id}">', 1)
            chapters.append(f'<section class="chapter">{body}</section>')
            toc.append(f'<li><a href="#{chapter_id}">{html.escape(label)}</a></li>')

        toc.append("</ul></li>")

    page = TEMPLATE.format(
        title=html.escape(TITLE),
        subtitle=html.escape(SUBTITLE),
        author=html.escape(AUTHOR),
        target_git=html.escape(TARGET_GIT),
        repo=html.escape(REPO),
        stamp=html.escape(build_stamp()),
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
  --ansi-black: #1c1b19; --ansi-red: #b3261e; --ansi-green: #1f7a33;
  --ansi-yellow: #8a6100; --ansi-blue: #1f5fbf; --ansi-magenta: #8e3aa8;
  --ansi-cyan: #0e7a86; --ansi-white: #6b6862;
  --ansi-bg-red: #eeb0a9; --ansi-bg-green: #d4ecd9; --ansi-bg-yellow: #f3e5bf;
  --ansi-bg-blue: #d5e2f6; --ansi-bg-magenta: #ead7f1; --ansi-bg-cyan: #cfeaec;
  --ansi-bg-white: #e4e1da; --ansi-bg-black: #3a3833;
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
    --ansi-black: #8b949e; --ansi-red: #ff7b72; --ansi-green: #7ee787;
    --ansi-yellow: #e3b341; --ansi-blue: #79c0ff; --ansi-magenta: #d2a8ff;
    --ansi-cyan: #56d4dd; --ansi-white: #e6e3dd;
    --ansi-bg-red: #5a1e1b; --ansi-bg-green: #1b4527; --ansi-bg-yellow: #4d3b0f;
    --ansi-bg-blue: #1a3558; --ansi-bg-magenta: #43245a; --ansi-bg-cyan: #144449;
    --ansi-bg-white: #3a3940; --ansi-bg-black: #0d0c10;
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
header.book .subtitle { margin: 0 0 .9rem; color: var(--muted); font-style: italic; }
header.book .byline { margin: 0; font-size: .9rem; letter-spacing: .04em;
  font-family: system-ui, sans-serif; }
footer.book { max-width: 40rem; margin: 5rem auto 0; padding: 2rem 1.25rem 4rem;
  border-top: 1px solid var(--rule); color: var(--muted); font-size: .8rem;
  font-family: system-ui, sans-serif; text-align: center; }
footer.book p { margin: .25rem 0; word-break: break-word; }
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
.ansi-fg-black, .ansi-fg-bright-black { color: var(--ansi-black); }
.ansi-bg-black, .ansi-bg-bright-black { background: var(--ansi-bg-black); }
.ansi-fg-red, .ansi-fg-bright-red { color: var(--ansi-red); }
.ansi-bg-red, .ansi-bg-bright-red { background: var(--ansi-bg-red); }
.ansi-fg-green, .ansi-fg-bright-green { color: var(--ansi-green); }
.ansi-bg-green, .ansi-bg-bright-green { background: var(--ansi-bg-green); }
.ansi-fg-yellow, .ansi-fg-bright-yellow { color: var(--ansi-yellow); }
.ansi-bg-yellow, .ansi-bg-bright-yellow { background: var(--ansi-bg-yellow); }
.ansi-fg-blue, .ansi-fg-bright-blue { color: var(--ansi-blue); }
.ansi-bg-blue, .ansi-bg-bright-blue { background: var(--ansi-bg-blue); }
.ansi-fg-magenta, .ansi-fg-bright-magenta { color: var(--ansi-magenta); }
.ansi-bg-magenta, .ansi-bg-bright-magenta { background: var(--ansi-bg-magenta); }
.ansi-fg-cyan, .ansi-fg-bright-cyan { color: var(--ansi-cyan); }
.ansi-bg-cyan, .ansi-bg-bright-cyan { background: var(--ansi-bg-cyan); }
.ansi-fg-white, .ansi-fg-bright-white { color: var(--ansi-white); }
.ansi-bg-white, .ansi-bg-bright-white { background: var(--ansi-bg-white); }
.ansi-fg-bright-red, .ansi-fg-bright-green, .ansi-fg-bright-yellow, .ansi-fg-bright-blue,
.ansi-fg-bright-magenta, .ansi-fg-bright-cyan { filter: saturate(1.25); }
.ansi-fg-bg { color: var(--code-bg); }
.ansi-bg-fg { background: var(--fg); }
.ansi-bold { font-weight: 700; }
.ansi-dim { opacity: .6; }
.ansi-italic { font-style: italic; }
.ansi-underline { text-decoration: underline; }
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
  footer.book { color: #444; page-break-before: avoid; }
  main { max-width: none; }
  .chapter { page-break-before: always; }
  h1.part-title { page-break-before: always; }
  pre, .ansi span { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
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
  <p class="subtitle">{subtitle}</p>
  <p class="byline">{author}</p>
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

<footer class="book">
  <p>{title} &middot; {author}</p>
  <p>Written against Git {target_git}. Built {stamp}.</p>
  <p>Text under CC BY-SA 4.0. Scripts under MIT.</p>
  <p>{repo}</p>
</footer>

<a id="top-link" href="#" aria-label="Back to top">&#8593;</a>
<script>{js}</script>
</body>
</html>
"""


if __name__ == "__main__":
    build()
