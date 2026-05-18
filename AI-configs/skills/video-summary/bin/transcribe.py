#!/usr/bin/env python3
"""Parse a WebVTT subtitle file into JSON segments matching transcribe.sh output.

YouTube auto-subs emit rolling-duplicate cues; we dedupe consecutive identical
cues and merge their time ranges.

Output: [{"start": 0.0, "end": 2.4, "text": "..."}, ...] to stdout or <out>.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path


TS_RE = re.compile(
    r"(\d{2}):(\d{2}):(\d{2})[.,](\d{3})\s+-->\s+(\d{2}):(\d{2}):(\d{2})[.,](\d{3})"
)
TAG_RE = re.compile(r"<[^>]+>")


def _to_seconds(h: str, m: str, s: str, ms: str) -> float:
    return int(h) * 3600 + int(m) * 60 + int(s) + int(ms) / 1000.0


def parse_vtt(path: str) -> list[dict]:
    text = Path(path).read_text(encoding="utf-8", errors="ignore")
    lines = text.splitlines()

    segments: list[dict] = []
    i = 0
    while i < len(lines):
        match = TS_RE.match(lines[i])
        if not match:
            i += 1
            continue

        start = _to_seconds(*match.groups()[:4])
        end = _to_seconds(*match.groups()[4:])
        i += 1

        cue_lines: list[str] = []
        while i < len(lines) and lines[i].strip():
            cleaned = TAG_RE.sub("", lines[i]).strip()
            if cleaned:
                cue_lines.append(cleaned)
            i += 1

        cue_text = " ".join(cue_lines).strip()
        if cue_text:
            segments.append({"start": round(start, 2), "end": round(end, 2), "text": cue_text})
        i += 1

    return _dedupe(segments)


def _dedupe(segments: list[dict]) -> list[dict]:
    out: list[dict] = []
    for seg in segments:
        if out and seg["text"] == out[-1]["text"]:
            out[-1]["end"] = seg["end"]
            continue
        if out and seg["text"].startswith(out[-1]["text"] + " "):
            out[-1]["text"] = seg["text"]
            out[-1]["end"] = seg["end"]
            continue
        out.append(seg)
    return out


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: transcribe.py <vtt-path> [<out.json>]", file=sys.stderr)
        raise SystemExit(2)

    segments = parse_vtt(sys.argv[1])
    payload = json.dumps(segments, indent=2)
    if len(sys.argv) >= 3:
        Path(sys.argv[2]).write_text(payload)
        print(f"[video-summary] parsed {len(segments)} caption segments -> {sys.argv[2]}", file=sys.stderr)
    else:
        print(payload)
