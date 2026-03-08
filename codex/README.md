# Codex Scripts

Generic scripts for audiobook trim/continuation workflows.

## Scripts

- `create_track.sh`
  - Build a track from a specific start time and duration.
  - Supports volume and speed changes.
- `make_resume_track.sh`
  - Thin convenience wrapper around `create_track.sh`.
- `create_continuation_track.sh`
  - Build a continuation track based on minutes already read.
  - Can span multiple source files.
  - Supports two modes:
    - fixed-length cap via `--target-min`
    - uncapped to end of provided sources (omit `--target-min`)
  - For "resume from progress file" cases, derive the resume offset on the
    original source part and build from source parts only.
  - Supports volume and speed changes.
  - Supports auto naming format:
    `<Title> - P<part>+<offset>_vol<volume>_speed<speed>.mp3`

## Usage

Create a fixed segment:

```bash
./codex/create_track.sh "input.mp3" "output.mp3" "01:09:00" "01:30:00" 200 75
```

Create an uncapped continuation from one source file (from minute 20 to end):

```bash
./codex/create_continuation_track.sh \
  --listen-min 20 \
  --output "final_single_mp3_vol/book_segment_20.end.mp3" \
  "final_single_mp3_vol/book_segment.mp3"
```

Create a 60-minute continuation across multiple files:

```bash
./codex/create_continuation_track.sh \
  --listen-min 40 \
  --target-min 60 \
  --volume-pct 200 \
  --output "final_single_mp3_vol/book_continuation_40.end.mp3" \
  "src_mp3/book_part_02.mp3" \
  "src_mp3/book_part_03.mp3" \
  "src_mp3/book_part_04.mp3"
```

Create an uncapped continuation across parts (cut from point to end, then append next part):

```bash
./codex/create_continuation_track.sh \
  --listen-min 54 \
  --volume-pct 200 \
  --speed-pct 100 \
  --name-title "Series Title" \
  --part 5 \
  --offset-label "54_to_P06.end" \
  "src_mp3/book_part_05.mp3" \
  "src_mp3/book_part_06.mp3"
```

Resume rule used for verified progress files:

1. Find where the finished progress file ends in the original part timeline.
2. Start the next build from that original part offset.
3. Append subsequent original parts in order.
4. Do not use prior generated continuation files as input sources.
5. For "to end then append", omit `--target-min`.
6. If the finished file consumed all of one part and continued into the next,
   carry the remaining seconds into the next part and start there.
7. Use the exact computed offset for `--listen-min`; the filename label may be
   rounded to the nearest second for readability.
8. If the user says "until the end" of the current part, use only that original
   part as input and omit `--target-min`.
9. If that current-part remainder is too short and the user wants more,
   rebuild from the same original offset and append the next original part(s).

Create a 60-minute continuation with automatic standardized naming:

```bash
./codex/create_continuation_track.sh \
  --listen-min 15 \
  --target-min 60 \
  --volume-pct 200 \
  --speed-pct 100 \
  --name-title "Series Title" \
  --part 3 \
  "src_mp3/book_part_03.mp3" \
  "src_mp3/book_part_04.mp3"
```

Resume after a 60-minute file crossed from one part into the next:

```bash
./codex/create_continuation_track.sh \
  --listen-min 6.681639583 \
  --target-min 60 \
  --volume-pct 200 \
  --speed-pct 100 \
  --name-title "Series Title" \
  --part 8 \
  "src_mp3/book_part_08.mp3" \
  "src_mp3/book_part_09.mp3"
```

Resume from a mapped offset to the end of the current part only:

```bash
./codex/create_continuation_track.sh \
  --listen-min 7.8073 \
  --volume-pct 200 \
  --speed-pct 100 \
  --name-title "Series Title" \
  --part 4 \
  --offset-label "7m48s_to_P04.end" \
  "src_mp3/book_part_04.mp3"
```

Extend a current-part remainder by appending the next part:

```bash
./codex/create_continuation_track.sh \
  --listen-min 47.8073 \
  --volume-pct 200 \
  --speed-pct 100 \
  --name-title "Series Title" \
  --part 4 \
  --offset-label "47m48s_to_P05.end" \
  "src_mp3/book_part_04.mp3" \
  "src_mp3/book_part_05.mp3"
```

Example output name:

`final_single_mp3_vol/Series Title - P03+15_vol200_speed100.mp3`
