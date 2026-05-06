#!/usr/bin/env python3
"""Extract frames at an auto-scaled fps with a tiered budget by duration.

Usage: extract-frames.py <video> <out-dir> [options]

Options:
  --max-frames N    override the duration-based budget (still capped at 100)
  --resolution W    frame width in px (default 480)
  --fps F           override auto-fps (still capped at 2)
  --start T         seconds (or MM:SS / HH:MM:SS)
  --end T           seconds (or MM:SS / HH:MM:SS)

Stdout: one line per frame "<timestamp_seconds>\\t<path>", chronological.
Stderr: progress (duration, fps, target).

Tiered curve (full mode): 20/25/35/50/70/100 by duration buckets.
Focused mode (--start or --end set): denser curve.
2 fps ceiling enforced everywhere.
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path


MAX_FPS = 2.0
HARD_CAP = 100


def parse_time(value: str | None) -> float | None:
    if not value:
        return None
    parts = value.split(":")
    try:
        if len(parts) == 1:
            return float(parts[0])
        if len(parts) == 2:
            return int(parts[0]) * 60 + float(parts[1])
        if len(parts) == 3:
            return int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])
    except ValueError:
        pass
    raise SystemExit(f"[video-summary] cannot parse time: {value!r}")


def probe_duration(video: str) -> float:
    out = subprocess.check_output(
        ["ffprobe", "-v", "quiet", "-print_format", "json",
         "-show_format", "-show_streams", video],
        text=True,
    )
    data = json.loads(out)
    if dur := data.get("format", {}).get("duration"):
        return float(dur)
    for stream in data.get("streams", []):
        if stream.get("codec_type") == "video" and (dur := stream.get("duration")):
            return float(dur)
    raise SystemExit("[video-summary] ffprobe could not read duration")


def tiered_target(duration: float, focused: bool, cap: int) -> int:
    if duration <= 0:
        return 1
    if focused:
        if duration <= 5:    return min(cap, max(10, int(duration * 6)))
        if duration <= 15:   return min(cap, max(30, int(duration * 4)))
        if duration <= 30:   return min(cap, 60)
        if duration <= 60:   return min(cap, 80)
        return cap
    if duration <= 30:   return min(cap, max(1, min(20, round(duration))))
    if duration <= 60:   return min(cap, 25)
    if duration <= 180:  return min(cap, 35)
    if duration <= 600:  return min(cap, 50)
    if duration <= 1800: return min(cap, 70)
    return cap


def auto_fps(duration: float, focused: bool, cap: int) -> tuple[float, int]:
    if duration <= 0:
        return 1.0, 1
    target = tiered_target(duration, focused, cap)
    fps = target / duration
    if fps > MAX_FPS:
        fps = MAX_FPS
        target = max(1, min(cap, round(fps * duration)))
    return fps, target


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("video")
    ap.add_argument("out_dir")
    ap.add_argument("--max-frames", type=int, default=None)
    ap.add_argument("--resolution", type=int, default=480)
    ap.add_argument("--fps", type=float, default=None)
    ap.add_argument("--start", default=None)
    ap.add_argument("--end", default=None)
    args = ap.parse_args()

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    for old in out_dir.glob("frame_*.jpg"):
        old.unlink()

    full_duration = probe_duration(args.video)
    start_sec = parse_time(args.start)
    end_sec = parse_time(args.end)
    focused = start_sec is not None or end_sec is not None

    effective_start = start_sec if start_sec is not None else 0.0
    effective_end = end_sec if end_sec is not None else full_duration
    effective_dur = max(0.0, effective_end - effective_start)

    cap = args.max_frames if args.max_frames is not None else HARD_CAP

    if args.fps is not None:
        fps = min(args.fps, MAX_FPS)
        target = max(1, min(cap, round(fps * effective_dur)))
    else:
        fps, target = auto_fps(effective_dur, focused, cap)

    mode = "focused" if focused else "full"
    print(
        f"[video-summary] duration {effective_dur:.3f}s, {mode} mode, "
        f"target {target} frames @ {fps:.4f} fps",
        file=sys.stderr,
    )

    cmd = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y"]
    if start_sec is not None:
        cmd += ["-ss", f"{start_sec:.3f}"]
    if end_sec is not None:
        cmd += ["-to", f"{end_sec:.3f}"]
    cmd += [
        "-i", args.video,
        "-vf", f"fps={fps},scale={args.resolution}:-2",
        "-frames:v", str(target),
        "-q:v", "4",
        str(out_dir / "frame_%04d.jpg"),
    ]
    subprocess.run(cmd, check=True, stderr=sys.stderr)

    offset = start_sec or 0.0
    for i, frame in enumerate(sorted(out_dir.glob("frame_*.jpg"))):
        ts = offset + (i / fps if fps > 0 else 0.0)
        print(f"{ts:.2f}\t{frame}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
