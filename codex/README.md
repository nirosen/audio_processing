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
  - Can span multiple source files to fill a target duration.
  - Supports volume and speed changes.
  - Supports auto naming format:
    `<Title> - P<part>+<offset>_vol<volume>_speed<speed>.mp3`

## Usage

Create a fixed segment:

```bash
./codex/create_track.sh "input.mp3" "output.mp3" "01:09:00" "01:30:00" 200 75
```

Create a continuation from one source file (from minute 20 to end/target):

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

Example output name:

`final_single_mp3_vol/Series Title - P03+15_vol200_speed100.mp3`
