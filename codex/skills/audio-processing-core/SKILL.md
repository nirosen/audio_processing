---
name: audio-processing-core
description: Core audiobook processing with project shell scripts for splitting M4B chapters, concatenating chapter ranges, skipping listened minutes, sampling time windows, changing volume, joining parts, and building two-part continuations. Use when requests mention split_m4b, concat_mp3, skip_start, sample_mp3, change_vol_mp3, join_mp3, or concat_parts, or ask to make audio louder, skip ahead, merge chapters, or continue into the next part.
---

# Audio Processing Core

Run commands from `/Users/nrosen/code/audiobooks/audio_processing`.

## Command Selection

- Use `./split_m4b` to split one `.m4b` into numbered chapter MP3 files.
- Use `./concat_mp3` to merge a numbered chapter range from one split directory.
- Use `./skip_start` to trim the beginning by plain minutes, optionally adding volume.
- Use `./sample_mp3` to extract a `h:mm-h:mm` range from one MP3.
- Use `./change_vol_mp3` to adjust loudness by percentage.
- Use `./concat_parts` to start mid-file in part 1 and continue into part 2.
- Use `./join_mp3` to join two or more already-processed MP3 files in order.

## Command Templates

```bash
./split_m4b "src_m4b_files/Book.m4b" "splitted_m4b_dirs/Book"

./concat_mp3 "splitted_m4b_dirs/Book" 12-42 "Book_12-42.mp3"

./skip_start "src_mp3_books/Part 01.mp3" 45 200

./sample_mp3 "final_single_mp3_vol/Book_150pct.mp3" 0:00-1:30

./change_vol_mp3 "Book_12-42.mp3" 150

./concat_parts "src_mp3_nesbo/Part 01.mp3" "src_mp3_nesbo/Part 02.mp3" 45 60 200

./join_mp3 "Part 01_45.end_200pct.mp3" "Part 02_200pct.mp3" --output "Continuation.mp3"
```

## Execution Rules

- Quote every path that can contain spaces.
- Use plain integer minutes for `skip_start` and `concat_parts` offsets/durations.
- Use `h:mm` in `sample_mp3` ranges.
- Keep generated names unless the user asks for a custom output filename.
- Chain commands by passing the exact output path from one step into the next step.

## Verification

- Confirm the expected output file exists.
- Check duration when relevant:

```bash
ffprobe -v error -show_entries format=duration -of default=nk=1:nw=1 "output.mp3"
```

## References

Read `references/command-patterns.md` for filename patterns and workflow recipes.
