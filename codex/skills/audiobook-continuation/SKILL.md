---
name: audiobook-continuation
description: Build continuation tracks from a known listening position, including fixed-length continuations that can span multiple source files with optional volume and speed changes. Use when a user says they already listened to N minutes and wants the next segment from that point.
---

# Audiobook Continuation

Run commands from `/Users/nrosen/code/audiobooks/audio_processing`.

## Workflow

1. Determine listened minutes in the first source file.
2. Choose output mode:
   - Fixed-length mode: add `--target-min` (example: 60).
   - To-end mode: omit `--target-min` to run until all provided sources end.
3. Use original source-part files as inputs (not previously generated continuation files).
4. Order source files from current segment to subsequent parts.
5. If resuming from a completed progress file, map its endpoint to the original
   source part timeline first, then cut from that exact original offset.
6. If the finished file crossed a part boundary, subtract the fully consumed
   earlier part duration(s) and resume inside the next original part.
7. Use the exact computed minute value for `--listen-min`, even if the filename
   offset is rounded to whole seconds.
8. Run `./codex/create_continuation_track.sh` with required arguments.
9. Validate resulting duration with `ffprobe`.

## Output Naming Standard

Default continuation filename format:

`<Title> - P<part>+<offset>_vol<volume>_speed<speed>.mp3`

Examples:
- `Series Title - P03+15_vol200_speed100.mp3`
- `Series Title - P04+66m43s_vol200_speed100.mp3`

Rules:
- `<part>` is the start part of the generated track (2-digit, e.g. `03`).
- `<offset>` is listened position in that part:
  - whole minute: `15`
  - minute+seconds: `66m43s`
- `<volume>` and `<speed>` are percentages passed to the command.

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
  --listen-min 15 \
  --target-min 60 \
  --volume-pct 200 \
  --speed-pct 100 \
  --name-title "Series Title" \
  --part 3 \
  "src_mp3_books/Part 03.mp3" \
  "src_mp3_books/Part 04.mp3"
```

To-end continuation (cut from point to end, then append next parts):

```bash
./codex/create_continuation_track.sh \
  --listen-min 54 \
  --volume-pct 200 \
  --speed-pct 100 \
  --name-title "Series Title" \
  --part 5 \
  --offset-label "54_to_P06.end" \
  "src_mp3_books/Part 05.mp3" \
  "src_mp3_books/Part 06.mp3"
```

Resume from a completed progress file endpoint (generic template):

```bash
./codex/create_continuation_track.sh \
  --listen-min 30 \
  --volume-pct 200 \
  --speed-pct 100 \
  --name-title "Series Title" \
  --part 3 \
  --offset-label "30_to_P04.end" \
  "src_mp3_books/Part 03.mp3" \
  "src_mp3_books/Part 04.mp3"
```

Resume after a capped file crossed into the next part:

```bash
./codex/create_continuation_track.sh \
  --listen-min 6.681639583 \
  --target-min 60 \
  --volume-pct 200 \
  --speed-pct 100 \
  --name-title "Series Title" \
  --part 8 \
  "src_mp3_books/Part 08.mp3" \
  "src_mp3_books/Part 09.mp3"
```

Duration check:

```bash
ffprobe -v error -show_entries format=duration -of default=nk=1:nw=1 "final_single_mp3_vol/Series Title - P03+15_vol200_speed100.mp3"
```

## Guardrails

- Use numeric values for `--listen-min`, `--target-min` (when present), `--volume-pct`, and `--speed-pct`.
- Keep source files in playback order.
- Prefer auto naming with `--name-title` (+ optional `--part`) to keep filenames consistent.
- If the user says "to end then append", do not pass `--target-min`.
- Do not feed generated continuation files into new continuation builds unless explicitly requested.
- For resumed progress, always cut from the mapped original source offset and append next original parts.
- When a prior capped file spans a part boundary, compute the carryover into the next part before building the next file.
