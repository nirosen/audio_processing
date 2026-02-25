---
name: audiobook-continuation
description: Use when a user says they have read or listened to part of an audiobook segment and needs the next continuation track, especially a fixed-length continuation that may span multiple source files.
---

# Audiobook Continuation

Use this skill for requests like:
- "I read 20 min of <file>"
- "Create the next 1 hour from where I stopped"
- "Continue this segment into the next parts"

## Workflow

1. Identify the current segment file and the listened minutes.
2. Decide the target length:
   - If unspecified, default to 60 minutes.
3. Choose source files in order:
   - Start with the current segment.
   - If remaining time is too short, append the next source parts.
4. Generate output with `./codex/create_continuation_track.sh`.
5. Verify output duration with `ffprobe`.

## Commands

Single-file continuation:

```bash
./codex/create_continuation_track.sh \
  --listen-min <minutes> \
  --output "<output.mp3>" \
  "<current_segment.mp3>"
```

Multi-file continuation (fixed 60 minutes):

```bash
./codex/create_continuation_track.sh \
  --listen-min <minutes_in_first_source> \
  --target-min 60 \
  --volume-pct <percent> \
  --output "<output.mp3>" \
  "<part_1.mp3>" \
  "<part_2.mp3>" \
  "<part_3.mp3>"
```

Verification:

```bash
ffprobe -v error -show_entries format=duration -of default=nk=1:nw=1 "<output.mp3>"
```
