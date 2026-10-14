#!/usr/bin/env python3
"""Convert Markdown to Jira ADF, optionally wrapped as an acli payload.

Pure and idempotent: no network, no acli calls, same input gives identical
output. Python 3.9+, stdlib only. See ../references/md2adf.md for the grammar.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import sys
import tempfile
from typing import Any, Dict, List, Optional, Tuple

DEFAULT_CONFIG = "~/OneDrive/work/contexts/jira-data.yaml"
PANEL_TYPES = ("info", "note", "warning", "error", "success")


class UnsupportedMarkdown(Exception):
    def __init__(self, message: str, line: int) -> None:
        super().__init__(f"line {line}: {message}")
        self.line = line


class UsageError(ValueError):
    """Bad flag, config, or environment (as opposed to bad Markdown)."""


# --- inline ---------------------------------------------------------------

PUNCT = set("!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~")
MARK_ORDER = {"strong": 0, "em": 1, "strike": 2, "code": 3, "link": 4}
AUTOLINK_RE = re.compile(r"<(https?://[^>\s]+)>")
LINK_TARGET_RE = re.compile(r"^(?:https?://|mailto:)", re.I)

Marks = Tuple[Tuple[str, Optional[str]], ...]
EMPHASIS: Dict[int, Marks] = {
    1: (("em", None),),
    2: (("strong", None),),
    3: (("strong", None), ("em", None)),
}


def _emphasis(c: str, k: int) -> Optional[Marks]:
    if c == "~":
        return (("strike", None),) if k == 2 else None
    return EMPHASIS.get(k)


def _last_closer(text: str, c: str) -> int:
    """Last index where a run of `c` could close: preceded by non-space."""
    for i in range(len(text) - 1, 0, -1):
        if text[i] == c and not text[i - 1].isspace():
            return i
    return -1


def _marks_json(marks: Marks) -> List[Dict[str, Any]]:
    names = {m[0] for m in marks}
    out: List[Dict[str, Any]] = []
    for name, href in sorted(set(marks), key=lambda m: MARK_ORDER[m[0]]):
        if "code" in names and name in ("strong", "em", "strike"):
            continue  # ADF: code excludes every mark except link
        out.append({"type": "link", "attrs": {"href": href}} if name == "link" else {"type": name})
    return out


def _text(text: str, marks: Marks) -> Dict[str, Any]:
    node: Dict[str, Any] = {"type": "text", "text": text}
    mark_nodes = _marks_json(marks)
    if mark_nodes:
        node["marks"] = mark_nodes
    return node


def _merge(nodes: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    out: List[Dict[str, Any]] = []
    for node in nodes:
        prev = out[-1] if out else None
        if (
            prev
            and node["type"] == "text"
            and prev["type"] == "text"
            and prev.get("marks") == node.get("marks")
        ):
            prev["text"] += node["text"]
        else:
            out.append(node)
    return out


class Inline:
    def __init__(self, text: str, base_line: int) -> None:
        self.s = text
        self.base = base_line
        # Necessary conditions only: no later closer means the scan cannot succeed.
        # shortcut: unclosed openers that DO have a later closer still scan
        # quadratically; upgrade to a CommonMark delimiter stack if that shows up.
        self.last_bracket = text.rfind("]")
        self.last_closer = {c: _last_closer(text, c) for c in "*_~"}

    def err(self, pos: int, message: str) -> None:
        raise UnsupportedMarkdown(message, self.base + self.s.count("\n", 0, pos))

    def run(self) -> List[Dict[str, Any]]:
        return _merge(self.parse(0, len(self.s), ()))

    def run_len(self, i: int, end: int, ch: str) -> int:
        k = 0
        while i + k < end and self.s[i + k] == ch:
            k += 1
        return k

    def code_close(self, p: int, end: int, n: int) -> Optional[int]:
        while p < end:
            if self.s[p] == "`":
                k = self.run_len(p, end, "`")
                if k == n:
                    return p
                p += k
            else:
                p += 1
        return None

    def skip_code(self, p: int, end: int) -> int:
        """Index after the code span starting at p, or after its backticks if unclosed."""
        n = self.run_len(p, end, "`")
        k = self.code_close(p + n, end, n)
        return k + n if k is not None else p + n

    def link_at(self, i: int, end: int) -> Optional[Tuple[int, int, str, int]]:
        s = self.s
        if self.last_bracket <= i:
            return None
        depth, j = 0, i
        while j < end:
            ch = s[j]
            if ch == "\\":
                j += 2
                continue
            if ch == "`":
                j = self.skip_code(j, end)
                continue
            if ch == "[":
                depth += 1
            elif ch == "]":
                depth -= 1
                if depth == 0:
                    break
            j += 1
        else:
            return None
        if j + 1 >= end or s[j + 1] != "(":
            return None
        p = q = j + 2
        depth = 1
        while q < end:
            ch = s[q]
            if ch == "\\":
                q += 2
                continue
            if ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
                if depth == 0:
                    break
            q += 1
        else:
            return None
        parts = s[p:q].split(None, 1)
        if not parts:
            return None
        return (i + 1, j, parts[0], q + 1)

    def can_open(self, c: str, i: int, k: int, start: int, end: int) -> bool:
        nxt = self.s[i + k] if i + k < end else None
        prv = self.s[i - 1] if i > start else None
        if nxt is None or nxt.isspace():
            return False
        return not (c == "_" and prv is not None and prv.isalnum())

    def can_close(self, c: str, p: int, k: int, start: int, end: int) -> bool:
        prv = self.s[p - 1] if p > start else None
        nxt = self.s[p + k] if p + k < end else None
        if prv is None or prv.isspace():
            return False
        return not (c == "_" and nxt is not None and nxt.isalnum())

    def find_close(self, c: str, n: int, p: int, start: int, end: int) -> Optional[int]:
        s = self.s
        waiting = [n]
        last = self.last_closer[c]
        while p < end and p <= last:
            ch = s[p]
            if ch == "\\":
                p += 2
                continue
            if ch == "`":
                p = self.skip_code(p, end)
                continue
            if ch != c:
                p += 1
                continue
            k = self.run_len(p, end, c)
            opens = self.can_open(c, p, k, start, end)
            closes = self.can_close(c, p, k, start, end)
            q, rem = p, k
            while rem > 0:
                if closes and waiting and rem >= waiting[-1]:
                    taken = waiting.pop()
                    rem -= taken
                    q += taken
                    if not waiting:
                        return q - taken
                elif opens:
                    taken = min(rem, 3)
                    waiting.append(taken)
                    rem -= taken
                    q += taken
                else:
                    break
            p += k
        return None

    def parse(self, start: int, end: int, marks: Marks) -> List[Dict[str, Any]]:
        s = self.s
        out: List[Dict[str, Any]] = []
        buf: List[str] = []

        def flush() -> None:
            text = "".join(buf)
            buf.clear()
            if text:
                out.append(_text(text, marks))

        i = start
        while i < end:
            c = s[i]
            if c == "\\":
                if i + 1 < end and s[i + 1] == "\n":
                    flush()
                    out.append({"type": "hardBreak"})
                    i += 2
                elif i + 1 < end and s[i + 1] in PUNCT:
                    buf.append(s[i + 1])
                    i += 2
                else:
                    buf.append(c)
                    i += 1
            elif c == "\n":
                joined = "".join(buf)
                if joined.endswith("  "):
                    buf[:] = [joined.rstrip(" ")]
                    flush()
                    out.append({"type": "hardBreak"})
                else:
                    buf[:] = [joined.rstrip(" ") + " "]
                i += 1
            elif c == "`":
                n = self.run_len(i, end, "`")
                j = self.code_close(i + n, end, n)
                content = s[i + n : j].replace("\n", " ") if j is not None else ""
                if content.startswith(" ") and content.endswith(" ") and content.strip():
                    content = content[1:-1]
                if j is None or not content:
                    buf.append("`" * n)
                    i += n
                else:
                    flush()
                    out.append(_text(content, marks + (("code", None),)))
                    i = j + n
            elif c == "!" and i + 1 < end and s[i + 1] == "[" and self.link_at(i + 1, end):
                self.err(i, "images are not supported")
            elif c == "[":
                found = self.link_at(i, end)
                if not found:
                    buf.append(c)
                    i += 1
                    continue
                label_start, label_end, url, after = found
                if label_start == label_end:
                    self.err(i, "empty link text")
                if not LINK_TARGET_RE.match(url):
                    self.err(i, f"link target {url!r} must be an absolute http(s) or mailto URL")
                flush()
                inner = marks if any(m[0] == "link" for m in marks) else marks + (("link", url),)
                out.extend(self.parse(label_start, label_end, inner))
                i = after
            elif c == "<":
                m = AUTOLINK_RE.match(s, i)
                if m and m.end() <= end:
                    flush()
                    out.append({"type": "inlineCard", "attrs": {"url": m.group(1)}})
                    i = m.end()
                else:
                    buf.append(c)
                    i += 1
            elif c in "*_~":
                k = self.run_len(i, end, c)
                add = _emphasis(c, k)
                close = None
                if add and self.can_open(c, i, k, start, end):
                    close = self.find_close(c, k, i + k, start, end)
                if close is None:
                    buf.append(c * k)
                    i += k
                else:
                    flush()
                    out.extend(self.parse(i + k, close, marks + add))
                    i = close + k
            else:
                buf.append(c)
                i += 1
        flush()
        return out


def parse_inline(text: str, base_line: int) -> List[Dict[str, Any]]:
    return Inline(text, base_line).run()


# --- blocks ---------------------------------------------------------------

Line = Tuple[int, str]

FENCE_RE = re.compile(r"^ {0,3}(`{3,}|~{3,})(.*)$")
HEADING_RE = re.compile(r"^ {0,3}(#{1,6})[ \t]+(\S.*)$")
HR_RE = re.compile(r"^ {0,3}([-*_])(?:[ \t]*\1){2,}[ \t]*$")
ITEM_RE = re.compile(r"^( {0,3})(?:([-*+])|(\d{1,9})[.)])( +)(.*)$")
TASK_RE = re.compile(r"^\[([ xX])\] +(\S.*)$")
CONTAINER_RE = re.compile(r"^:::(\w+)(?:[ \t]+(.*?))?[ \t]*$")
CONTAINER_END_RE = re.compile(r"^:::[ \t]*$")
QUOTE_RE = re.compile(r"^ {0,3}> ?(.*)$")
DELIM_CELL_RE = re.compile(r":?-+:?")
SETEXT_RE = re.compile(r"^ {0,3}(?:=+|-+)[ \t]*$")
HTML_RE = re.compile(r"^ {0,3}</?[A-Za-z!]")
UNESCAPED_PIPE_RE = re.compile(r"(?<!\\)\|")


def _indent(line: str) -> int:
    return len(line) - len(line.lstrip(" "))


def _split_row(line: str) -> List[str]:
    s = line.strip()
    if s.startswith("|"):
        s = s[1:]
    if s.endswith("|") and not s.endswith("\\|"):
        s = s[:-1]
    return [cell.strip() for cell in UNESCAPED_PIPE_RE.split(s)]


def _table_header(lines: List[Line], i: int) -> Optional[List[str]]:
    """Header cells when lines[i], lines[i+1] are a table header and delimiter row."""
    if "|" not in lines[i][1] or i + 1 >= len(lines):
        return None
    delim = lines[i + 1][1]
    cells = _split_row(delim)
    if "|" not in delim or not all(DELIM_CELL_RE.fullmatch(c) for c in cells):
        return None
    header = _split_row(lines[i][1])
    return header if len(header) == len(cells) else None


LISTS = {"bulletList", "orderedList"}
ITEM_CHILDREN = LISTS | {"paragraph", "codeBlock"}  # also blockquote children
PANEL_CHILDREN = ITEM_CHILDREN | {"heading", "taskList", "rule"}


def _check(kind: str, content: List[Dict[str, Any]], allowed: Optional[set], line: int) -> None:
    """Reject what ADF cannot hold, with a line, instead of emitting a doc Jira refuses."""
    if not content:
        raise UnsupportedMarkdown(f"empty {kind}", line)
    for node in content:
        if allowed and node["type"] not in allowed:
            raise UnsupportedMarkdown(f"{node['type']} is not supported inside {kind}", line)


def _heading_text(raw: str) -> str:
    """Heading content without trailing spaces or a closing `###` run (linear, no regex)."""
    text = raw.rstrip()
    bare = text.rstrip("#")
    return bare.rstrip() if bare and bare[-1] in " \t" else text


def _fence_match(line: str):
    m = FENCE_RE.match(line)
    if m and m.group(1)[0] == "`" and "`" in m.group(2):
        return None
    return m


def _starts_block(line: str) -> bool:
    return bool(
        _fence_match(line)
        or HEADING_RE.match(line)
        or CONTAINER_RE.match(line)
        or QUOTE_RE.match(line)
        or ITEM_RE.match(line)
        or HR_RE.match(line)
    )


class Parser:
    def __init__(self) -> None:
        self.counter = 0

    def local_id(self, prefix: str, text: str) -> str:
        self.counter += 1
        digest = hashlib.sha1(f"{self.counter}|{text}".encode("utf-8")).hexdigest()
        return f"{prefix}-{digest[:10]}"

    def blocks(self, lines: List[Line]) -> List[Dict[str, Any]]:
        out: List[Dict[str, Any]] = []
        i = 0
        while i < len(lines):
            no, line = lines[i]
            if not line.strip():
                i += 1
                continue
            if _indent(line) >= 4:
                raise UnsupportedMarkdown(
                    "indented code blocks are not supported; use a fenced block", no
                )
            node, i = self.block(lines, i)
            out.append(node)
        return out

    def block(self, lines: List[Line], i: int) -> Tuple[Dict[str, Any], int]:
        no, line = lines[i]
        fence = _fence_match(line)
        if fence:
            return self.code_block(lines, i, fence)
        heading = HEADING_RE.match(line)
        if heading:
            node = {
                "type": "heading",
                "attrs": {"level": len(heading.group(1))},
                "content": parse_inline(_heading_text(heading.group(2)), no),
            }
            return node, i + 1
        container = CONTAINER_RE.match(line)
        if container:
            return self.container(lines, i, container)
        if HR_RE.match(line):
            return {"type": "rule"}, i + 1
        if QUOTE_RE.match(line):
            inner: List[Line] = []
            while i < len(lines):
                quote = QUOTE_RE.match(lines[i][1])
                if not quote:
                    break
                inner.append((lines[i][0], quote.group(1)))
                i += 1
            content = self.blocks(inner)
            _check("blockquote", content, ITEM_CHILDREN, no)
            return {"type": "blockquote", "content": content}, i
        if ITEM_RE.match(line):
            return self.list_block(lines, i)
        header = _table_header(lines, i)
        if header:
            return self.table(lines, i, header)
        return self.paragraph(lines, i)

    def code_block(self, lines: List[Line], i: int, fence) -> Tuple[Dict[str, Any], int]:
        no = lines[i][0]
        marker, info = fence.group(1), fence.group(2).strip()
        close = re.compile(r"^ {0,3}" + re.escape(marker[0]) + "{" + str(len(marker)) + r",}[ \t]*$")
        j, body = i + 1, []
        while j < len(lines) and not close.match(lines[j][1]):
            body.append(lines[j][1])
            j += 1
        if j >= len(lines):
            raise UnsupportedMarkdown("unclosed code fence", no)
        node: Dict[str, Any] = {"type": "codeBlock"}
        if info:
            node["attrs"] = {"language": info.split()[0]}
        text = "\n".join(body)
        if text:
            node["content"] = [{"type": "text", "text": text}]
        return node, j + 1

    def container(self, lines: List[Line], i: int, m) -> Tuple[Dict[str, Any], int]:
        no = lines[i][0]
        kind, arg = m.group(1), m.group(2) or ""
        if kind not in ("panel", "expand"):
            raise UnsupportedMarkdown(f"unknown container ':::{kind}'", no)
        j, inner = i + 1, []
        while j < len(lines) and not CONTAINER_END_RE.match(lines[j][1]):
            if CONTAINER_RE.match(lines[j][1]):
                raise UnsupportedMarkdown("nested containers are not supported", lines[j][0])
            inner.append(lines[j])
            j += 1
        if j >= len(lines):
            raise UnsupportedMarkdown(f"unclosed container ':::{kind}'", no)
        content = self.blocks(inner)
        if kind == "panel":
            panel_type = arg or "info"
            if panel_type not in PANEL_TYPES:
                raise UnsupportedMarkdown(
                    f"panel type {panel_type!r} must be one of {', '.join(PANEL_TYPES)}", no
                )
            _check("panel", content, PANEL_CHILDREN, no)
            return {"type": "panel", "attrs": {"panelType": panel_type}, "content": content}, j + 1
        _check("expand", content, None, no)
        node: Dict[str, Any] = {"type": "expand", "content": content}
        if arg:
            node["attrs"] = {"title": arg}
        return node, j + 1

    def table(self, lines: List[Line], i: int, header: List[str]) -> Tuple[Dict[str, Any], int]:
        no = lines[i][0]

        def cell(kind: str, text: str, line_no: int) -> Dict[str, Any]:
            para: Dict[str, Any] = {"type": "paragraph"}
            content = parse_inline(text, line_no)
            if content:
                para["content"] = content
            return {"type": kind, "content": [para]}

        rows = [
            {"type": "tableRow", "content": [cell("tableHeader", h, no) for h in header]}
        ]
        j = i + 2
        while j < len(lines) and lines[j][1].strip() and "|" in lines[j][1]:
            cells = _split_row(lines[j][1])
            if len(cells) > len(header):
                raise UnsupportedMarkdown(
                    f"row has {len(cells)} cells, header has {len(header)}", lines[j][0]
                )
            cells += [""] * (len(header) - len(cells))
            rows.append(
                {"type": "tableRow", "content": [cell("tableCell", c, lines[j][0]) for c in cells]}
            )
            j += 1
        node = {
            "type": "table",
            "attrs": {"isNumberColumnEnabled": False, "layout": "default"},
            "content": rows,
        }
        return node, j

    def paragraph(self, lines: List[Line], i: int) -> Tuple[Dict[str, Any], int]:
        no, line = lines[i]
        if HTML_RE.match(line) and not AUTOLINK_RE.match(line.lstrip()):
            raise UnsupportedMarkdown("raw HTML is not supported", no)
        text_lines = [line.lstrip()]
        j = i + 1
        while j < len(lines):
            nxt = lines[j][1]
            if not nxt.strip():
                break
            if SETEXT_RE.match(nxt):
                raise UnsupportedMarkdown(
                    "setext headings are not supported; use '#' (put a blank line before '---')",
                    lines[j][0],
                )
            if _starts_block(nxt):
                break
            if _table_header(lines, j):
                raise UnsupportedMarkdown("a table must start after a blank line", lines[j][0])
            text_lines.append(nxt.lstrip())
            j += 1
        text = "\n".join(text_lines).rstrip()
        return {"type": "paragraph", "content": parse_inline(text, no)}, j

    @staticmethod
    def item_kind(m) -> str:
        if not m.group(2):
            return "ordered"
        return "task" if TASK_RE.match(m.group(5)) else "bullet"

    def list_block(self, lines: List[Line], i: int) -> Tuple[Dict[str, Any], int]:
        kind = self.item_kind(ITEM_RE.match(lines[i][1]))
        first_number = ITEM_RE.match(lines[i][1]).group(3)
        items: List[Dict[str, Any]] = []
        while i < len(lines):
            m = ITEM_RE.match(lines[i][1])
            if not m or self.item_kind(m) != kind:
                break
            no = lines[i][0]
            marker_indent = len(m.group(1))
            marker_len = len(m.group(2)) if m.group(2) else len(m.group(3)) + 1
            gap = len(m.group(4))
            content_indent = marker_indent + marker_len + (gap if gap <= 4 else 1)
            rest, state = m.group(5), "TODO"
            if kind == "task":
                task = TASK_RE.match(rest)
                rest = task.group(2)
                state = "DONE" if task.group(1) in "xX" else "TODO"
            body: List[Line] = [(no, rest)]
            i += 1
            while i < len(lines):
                n2, l2 = lines[i]
                if not l2.strip():
                    k = i
                    while k < len(lines) and not lines[k][1].strip():
                        k += 1
                    if k < len(lines) and _indent(lines[k][1]) > marker_indent:
                        body.extend((n, "") for n, _ in lines[i:k])
                        i = k
                        continue
                    break
                if _indent(l2) <= marker_indent:
                    break
                body.append((n2, l2[min(content_indent, _indent(l2)) :]))
                i += 1
            items.extend(self.item(kind, no, state, body))
            k = i
            while k < len(lines) and not lines[k][1].strip():
                k += 1
            nxt = ITEM_RE.match(lines[k][1]) if k < len(lines) else None
            if nxt and self.item_kind(nxt) == kind:
                i = k
        if kind == "task":
            text = "|".join(str(item["attrs"]["localId"]) for item in items)
            return {
                "type": "taskList",
                "attrs": {"localId": self.local_id("tl", text)},
                "content": items,
            }, i
        node: Dict[str, Any] = {
            "type": "orderedList" if kind == "ordered" else "bulletList",
            "content": items,
        }
        if kind == "ordered" and int(first_number) != 1:
            node["attrs"] = {"order": int(first_number)}
        return node, i

    def item(self, kind: str, no: int, state: str, body: List[Line]) -> List[Dict[str, Any]]:
        content = self.blocks(body)
        if kind == "task":
            first, rest = content[0], content[1:]
            if first["type"] != "paragraph" or any(n["type"] != "taskList" for n in rest):
                raise UnsupportedMarkdown(
                    "checklist items hold inline text and nested checklists only", no
                )
            text = json.dumps(first["content"], sort_keys=True)
            item = {
                "type": "taskItem",
                "attrs": {"localId": self.local_id("ti", text), "state": state},
                "content": first["content"],
            }
            return [item] + rest  # ADF: nested taskList is a sibling after its taskItem
        if any(node["type"] == "taskList" for node in content):
            raise UnsupportedMarkdown("checklists cannot be nested inside list items", no)
        _check("list item", content, ITEM_CHILDREN, no)
        return [{"type": "listItem", "content": content}]


def markdown_to_adf(text: str) -> Dict[str, Any]:
    raw = text.removeprefix("\ufeff").replace("\r\n", "\n").replace("\r", "\n").split("\n")
    lines = [
        (n, re.sub(r"^\t+", lambda m: " " * 4 * len(m.group(0)), line))
        for n, line in enumerate(raw, 1)
    ]
    if not any(line.strip() for _, line in lines):
        raise UnsupportedMarkdown("input is empty", 1)
    return {"type": "doc", "version": 1, "content": Parser().blocks(lines)}


# --- config ---------------------------------------------------------------


def _scalar(value: str, where: str) -> Any:
    if value[:1] == "'":
        m = re.fullmatch(r"'((?:[^']|'')*)'\s*(?:#.*)?", value)
        if not m:
            raise UsageError(f"{where}: bad single-quoted value")
        return m.group(1).replace("''", "'")
    if value[:1] == '"':
        m = re.fullmatch(r'"((?:[^"\\]|\\.)*)"\s*(?:#.*)?', value)
        if not m:
            raise UsageError(f"{where}: bad double-quoted value")
        return re.sub(r'\\(["\\])', r"\1", m.group(1))
    if value[:1] in ("[", "{"):
        raise UsageError(f"{where}: flow collections are not supported")
    value = re.split(r"(?:^|\s)#", value, maxsplit=1)[0].strip()
    if not value:
        return None
    return int(value) if re.fullmatch(r"-?\d+", value) else value


def load_config(path: str) -> Dict[str, Any]:
    try:
        with open(os.path.expanduser(path), encoding="utf-8") as fh:
            text = fh.read()
    except OSError as exc:
        raise UsageError(f"cannot read config {path}: {exc.strerror}")
    root: Dict[str, Any] = {}
    stack: List[Tuple[int, Dict[str, Any]]] = [(-1, root)]
    for n, raw in enumerate(text.splitlines(), 1):
        body = raw.strip()
        if not body or body.startswith("#"):
            continue
        where = f"{path}:{n}"
        if raw[: len(raw) - len(raw.lstrip())].count("\t"):
            raise UsageError(f"{where}: tabs are not supported")
        if body.startswith("- "):
            raise UsageError(f"{where}: lists are not supported")
        key, sep, value = body.partition(":")
        if not sep:
            raise UsageError(f"{where}: expected 'key: value'")
        indent = _indent(raw)
        while stack[-1][0] >= indent:
            stack.pop()
        parent = stack[-1][1]
        scalar = _scalar(value.strip(), where) if value.strip() else None
        if scalar is None:
            child: Dict[str, Any] = {}
            parent[key.strip()] = child
            stack.append((indent, child))
        else:
            parent[key.strip()] = scalar
    return root


REQUIRED_TEAM_KEYS = ("project_key", "team_field", "team_id", "sprint_field", "refinement_sprint_id")


def resolve_team(cfg: Dict[str, Any], team: Optional[str], path: str) -> Dict[str, Any]:
    name = team or cfg.get("my_team")
    if not isinstance(name, str) or not name:
        raise UsageError(f"no --team given and no my_team in {path}")
    teams = cfg.get("teams")
    entry = teams.get(name) if isinstance(teams, dict) else None
    if not isinstance(entry, dict):
        raise UsageError(f"team {name!r} not found under 'teams' in {path}")
    bad = [k for k in REQUIRED_TEAM_KEYS if not isinstance(entry.get(k), (str, int))]
    if bad:
        raise UsageError(f"team {name!r} in {path} needs a plain value for {', '.join(bad)}")
    return entry


# --- CLI ------------------------------------------------------------------

CREATE_ONLY = ("parent", "type", "label", "sprint", "team")
EDIT_ONLY = ("issues", "label_add", "label_remove")
SHARED = ("summary", "assignee", "config")


class _Parser(argparse.ArgumentParser):
    def error(self, message: str) -> None:  # type: ignore[override]
        raise UsageError(message)


def _build_parser() -> argparse.ArgumentParser:
    p = _Parser(
        prog="md2adf.py",
        description="Markdown to Jira ADF. Reads INPUT (default stdin), writes JSON to stdout or -o.",
    )
    p.add_argument("input", nargs="?", default="-", help="Markdown file or - for stdin")
    p.add_argument("--format", choices=("adf", "acli-create", "acli-edit"), default="adf")
    p.add_argument("-o", "--output", help="write JSON here atomically; stdout stays empty")
    p.add_argument("--config", help=f"jira-data.yaml (default {DEFAULT_CONFIG})")
    p.add_argument("--summary")
    p.add_argument("--assignee", help="'me' (my_email from config) or an email; '@me' is invalid")
    p.add_argument("--parent", help="create: parent issue key")
    p.add_argument("--type", help="create: issue type (default Task)")
    p.add_argument("--label", action="append", help="create: label, repeatable")
    p.add_argument("--sprint", help="create: 'refinement' (default) or a sprint id")
    p.add_argument("--team", help="create: team key in config (default my_team)")
    p.add_argument("--issues", help="edit: comma-separated issue keys")
    p.add_argument("--label-add", action="append", help="edit: label to add, repeatable")
    p.add_argument("--label-remove", action="append", help="edit: label to remove, repeatable")
    return p


def _check_flags(args: argparse.Namespace) -> None:
    allowed: set = set()
    if args.format == "acli-create":
        allowed = set(SHARED + CREATE_ONLY)
    elif args.format == "acli-edit":
        allowed = set(SHARED + EDIT_ONLY)
    for name in SHARED + CREATE_ONLY + EDIT_ONLY:
        if getattr(args, name) is not None and name not in allowed:
            raise UsageError(f"--{name.replace('_', '-')} does not apply to --format {args.format}")
    for name in ("summary", "assignee", "parent"):
        if getattr(args, name) == "":
            raise UsageError(f"--{name} must not be empty")
    if args.format == "acli-create" and not args.summary:
        raise UsageError("--summary is required for --format acli-create")
    if args.format == "acli-edit" and not args.issues:
        raise UsageError("--issues is required for --format acli-edit")


def _assignee(value: str, config_path: str, cache: Dict[str, Any]) -> str:
    if value == "@me":
        raise UsageError("'@me' is not valid in the JSON payload (acli resolves it to the wrong user); use 'me' or an email")
    if value == "me":
        email = _config(config_path, cache).get("my_email")
        if not isinstance(email, str) or not email:
            raise UsageError(f"my_email is missing in {config_path}")
        return email
    return value


def _config(path: str, cache: Dict[str, Any]) -> Dict[str, Any]:
    if "cfg" not in cache:
        cache["cfg"] = load_config(path)
    return cache["cfg"]


def _sprint(value: Optional[str], team: Dict[str, Any]) -> int:
    value = value or "refinement"
    if value == "refinement":
        return int(team["refinement_sprint_id"])
    if re.fullmatch(r"[0-9]+", value):
        return int(value)
    raise UsageError(f"--sprint {value!r} must be 'refinement' or a numeric sprint id")


def build_payload(args: argparse.Namespace, doc: Dict[str, Any]) -> Dict[str, Any]:
    if args.format == "adf":
        return doc
    path = args.config or DEFAULT_CONFIG
    cache: Dict[str, Any] = {}
    assignee = _assignee(args.assignee, path, cache) if args.assignee else None
    if args.format == "acli-create":
        team = resolve_team(_config(path, cache), args.team, path)
        payload: Dict[str, Any] = {
            "projectKey": team["project_key"],
            "type": args.type or "Task",
            "summary": args.summary,
        }
        if args.parent:
            payload["parentIssueId"] = args.parent
        if args.label:
            payload["labels"] = args.label
        if assignee:
            payload["assignee"] = assignee
        payload["additionalAttributes"] = {
            team["team_field"]: team["team_id"],
            team["sprint_field"]: _sprint(args.sprint, team),
        }
        payload["description"] = doc
        return payload
    issues = [key.strip() for key in args.issues.split(",") if key.strip()]
    if not issues:
        raise UsageError("--issues needs at least one issue key")
    payload = {"issues": issues}
    if args.summary:
        payload["summary"] = args.summary
    if assignee:
        payload["assignee"] = assignee
    if args.label_add:
        payload["labelsToAdd"] = args.label_add
    if args.label_remove:
        payload["labelsToRemove"] = args.label_remove
    payload["description"] = doc
    return payload


def _write_atomic(path: str, data: str) -> None:
    path = os.path.realpath(path)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path), prefix=".md2adf-")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            fh.write(data)
        if os.path.exists(path):
            shutil.copymode(path, tmp)
        os.replace(tmp, path)
    except BaseException:
        if os.path.exists(tmp):
            os.unlink(tmp)
        raise


def main(argv=None, stdin=None, stdout=None, stderr=None) -> int:
    if stdin is None:
        sys.stdin.reconfigure(encoding="utf-8")
        stdin = sys.stdin
    stdout = sys.stdout if stdout is None else stdout
    stderr = sys.stderr if stderr is None else stderr
    try:
        args = _build_parser().parse_args(argv)
        _check_flags(args)
        if args.input == "-":
            text = stdin.read()
        else:
            with open(args.input, encoding="utf-8") as fh:
                text = fh.read()
        data = json.dumps(build_payload(args, markdown_to_adf(text)), separators=(",", ":")) + "\n"
        if args.output:
            _write_atomic(args.output, data)
        else:
            stdout.write(data)
    except RecursionError:
        stderr.write("md2adf: input is nested too deeply\n")
        return 2
    except (UnsupportedMarkdown, UsageError, OSError, UnicodeError) as exc:
        stderr.write(f"md2adf: {exc}\n")
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
