---
name: audiobook-continuation
description: Build continuation tracks from a known listening position, including fixed-length continuations that can span multiple source files with optional volume and speed changes. Use when a user says they already listened to N minutes and wants the next segment from that point.
---

# Audiobook Continuation

Run commands from `/Users/nrosen/code/audiobooks/audio_processing`.

## Workflow

1. Determine listened minutes in the first source file.
2. Set target length in minutes. Default to 60 when unspecified.
3. Order source files from current segment to subsequent parts.
4. Run `./codex/create_continuation_track.sh` with required arguments.
5. Validate resulting duration with `ffprobe`.

## Command Templates

Single-source continuation:

```bash
./codex/create_continuation_track.sh \
  --listen-min 20 \
  --output "final_single_mp3_vol/Continuation_20.end.mp3" \
  "final_single_mp3_vol/Current Segment.mp3"
```

Fixed-length continuation across parts:

```bash
./codex/create_continuation_track.sh \
  --listen-min 40 \
  --target-min 60 \
  --volume-pct 200 \
  --speed-pct 75 \
  --output "final_single_mp3_vol/Continuation_40.end_200pct_75speed.mp3" \
  "src_mp3_nesbo/Knife - Part 02.mp3" \
  "src_mp3_nesbo/Knife - Part 03.mp3" \
  "src_mp3_nesbo/Knife - Part 04.mp3"
```

Duration check:

```bash
ffprobe -v error -show_entries format=duration -of default=nk=1:nw=1 "final_single_mp3_vol/Continuation_40.end_200pct_75speed.mp3"
```

## Guardrails

- Use numeric values for `--listen-min`, `--target-min`, `--volume-pct`, and `--speed-pct`.
- Keep source files in playback order.
- Prefer explicit output paths under `final_single_mp3_vol/`.
