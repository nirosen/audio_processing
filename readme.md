# Audiobook Tools

Bash scripts for processing audiobook files — adjust volume, skip ahead, combine parts, and more.

## Prerequisites

Install these before using the scripts:

```
brew install ffmpeg python3
```

## Quick Start — Common Tasks

**"The audiobook is too quiet"** — boost the volume:
```
./change_vol_mp3 "my-audiobook.mp3" 200
# Creates: my-audiobook_200pct.mp3 (twice as loud)
```

**"I already listened to the first 45 minutes"** — skip ahead:
```
./skip_start "my-audiobook.mp3" 45 200
# Creates: my-audiobook_45.end_200pct.mp3 (from 45min to end, 2x volume)
```

**"I'm near the end of Part 1 and want Part 2 to play without stopping"** — join files:
```
./skip_start "Part 01.mp3" 60 200
./change_vol_mp3 "Part 02.mp3" 200
./join_mp3 "Part 01_60.end_200pct.mp3" "Part 02_200pct.mp3"
# Creates a single file: Part 01_60.end_200pct+Part 02_200pct.mp3
```

**"I have an M4B file and want MP3s"** — split by chapter:
```
./split_m4b "my-audiobook.m4b" "output-folder"
# Creates: output-folder/001.mp3, 002.mp3, 003.mp3, etc.
```

## Scripts Reference

### skip_start

Skip the first N minutes of an audio file. Use when you've already listened to the beginning.

```
./skip_start <file> <minutes> [volume_percent]
```

- Works with both MP3 and M4B files
- Time is in **minutes** (e.g. `45`, or `110` for 1 hour 50 minutes)
- Volume is optional (e.g. `200` = twice as loud)

```
./skip_start "chapter1.mp3" 20 200
# Output: chapter1_20.end_200pct.mp3

./skip_start "my-audiobook.m4b" 110 150
# Output: my-audiobook_110.end_150pct.mp3
```

### change_vol_mp3

Make an MP3 file louder or quieter.

```
./change_vol_mp3 <file.mp3> <percent>
```

- `150` = 1.5x louder, `200` = 2x louder, `50` = half volume
- Output goes in the same folder as the input file

```
./change_vol_mp3 "chapter1.mp3" 200
# Output: chapter1_200pct.mp3
```

### join_mp3

Combine multiple MP3 files into one for uninterrupted listening.

```
./join_mp3 <file1.mp3> <file2.mp3> [file3.mp3 ...] [--output name.mp3]
```

- Accepts 2 or more files — they play in the order listed
- Instant (no re-encoding)
- Use `--output` to choose the output filename

```
./join_mp3 "Part 01_60.end_200pct.mp3" "Part 02_200pct.mp3"
# Output: Part 01_60.end_200pct+Part 02_200pct.mp3

./join_mp3 part1.mp3 part2.mp3 part3.mp3 --output "Full Book.mp3"
```

### concat_parts

Combine two sequential part files starting from a specific point. Use when your listening position is near the end of Part 1 and you want a single file that continues into Part 2.

```
./concat_parts <file1> <file2> <start_minutes> [duration_minutes] [volume_percent]
```

- `start_minutes`: where you left off in file1 (in minutes)
- `duration_minutes`: optional — total length of the output file (in minutes)
- `volume_percent`: optional — volume boost (e.g. `200` = 2x louder)

```
./concat_parts "Part 01.mp3" "Part 02.mp3" 45 60 200
# Creates a 60-minute file starting at Part 01's 45min mark, continues into Part 02, 2x volume
```

### sample_mp3

Extract a specific time range from an MP3 file.

```
./sample_mp3 <file.mp3> <start>-<end>
```

- Time format: `hours:minutes` (e.g. `0:00` = beginning, `1:30` = 1 hour 30 minutes)
- Instant (no re-encoding)

```
./sample_mp3 "my-audiobook.mp3" 0:00-1:30
# Output: my-audiobook_0.00-1.30.mp3 (first 1 hour 30 minutes)
```

### split_m4b

Split an M4B audiobook into individual MP3 chapter files.

```
./split_m4b <file.m4b> [output_dir]
```

- Creates numbered files: `001.mp3`, `002.mp3`, etc.
- If no output folder is given, creates one named after the file

```
./split_m4b "my-audiobook.m4b" "my-audiobook-chapters"
# Output: my-audiobook-chapters/001.mp3, 002.mp3, ..., 128.mp3
```

### concat_mp3

Combine a range of numbered chapter files into a single MP3.

```
./concat_mp3 <dir> <start-end> [output.mp3]
```

- Use after `split_m4b` to merge specific chapters together
- Instant (no re-encoding)

```
./concat_mp3 "my-audiobook-chapters" 12-42
# Output: my-audiobook-chapters_12-42.mp3
```

## Directory Structure

```
./                    — scripts live here
src_m4b_files/        — source M4B audiobook files
src_mp3/              — source MP3 files
splitted_m4b_dirs/    — chapter files from split_m4b (per book)
final_single_mp3_vol/ — final processed files ready to listen
```

## Tips

- Always use **quotes** around filenames with spaces: `"My Audiobook.mp3"`
- Volume of `200` (2x) works well for quiet audiobooks; use `150` (1.5x) for slightly quiet ones
- All output files are MP3 format
- Scripts that say "instant" use stream copy (no quality loss); others re-encode the audio
