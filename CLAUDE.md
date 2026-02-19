# Audio Processing Scripts

Bash scripts for processing audiobook files (M4B/MP3). Requires `ffmpeg`, `ffprobe`, and `python3`.

## Scripts

All scripts are in the project root directory.

- `split_m4b <file.m4b> [output_dir]` — Split M4B into numbered MP3 chapter files (128kbps)
- `concat_mp3 <dir> <range> [output.mp3]` — Concatenate a range of numbered MP3s (e.g. `1-30`)
- `change_vol_mp3 <file.mp3> <percent>` — Adjust volume by percentage (e.g. `150` = 1.5x)
- `sample_mp3 <file.mp3> <start>-<end>` — Extract time range in h:mm format (e.g. `0:00-1:30`)
- `skip_start <file> <minutes> [volume_percent]` — Skip first N minutes (MP3 or M4B), optional volume boost
- `concat_parts <file1> <file2> <start_min> [duration_min] [volume_percent]` — Concat two parts from offset, optional duration limit and volume boost
- `join_mp3 <file1.mp3> <file2.mp3> [... ] [--output name.mp3]` — Join already-processed MP3 files into one (stream copy, no re-encode)

## Conventions

- MP3 output is always 128kbps via libmp3lame
- split_m4b outputs zero-padded numbered files: `001.mp3`, `002.mp3`, etc.
- concat_mp3 outputs to current directory as `<dirname>_<start>-<end>.mp3`
- change_vol_mp3 outputs alongside input as `<name>_<percent>pct.mp3`
- sample_mp3 uses h:mm time format (first number is hours)
- skip_start takes plain minutes (e.g. 45, 110), works with MP3 and M4B
- concat_parts takes plain minutes for start and duration
- join_mp3 uses stream copy (instant, no quality loss) — use it to combine already-processed files for uninterrupted listening
- Stream copy (no re-encode) is used wherever possible (concat, sample, join)

## Parallel Processing

When processing multiple files, always use parallel execution:

- **Multiple independent files**: Launch separate background Bash calls or Task sub-agents for each file. Do NOT process sequentially when files are independent.
- **Batch volume boost**: Run all `change_vol_mp3` calls in parallel using `run_in_background`, then move results when all complete.
- **Batch split**: Run multiple `split_m4b` calls in parallel when splitting several M4B files.
- **Pipeline per book**: When a book needs split → concat → volume, the pipeline is sequential per book, but multiple books can run their pipelines in parallel.

### Patterns

**Parallel volume boost** (multiple files):
```
Launch each change_vol_mp3 as a background Bash task, wait for all to complete, then mv results.
```

**Parallel split** (multiple M4B files):
```
Launch each split_m4b as a background Bash task. They write to separate output dirs so no conflicts.
```

**Parallel pipelines** (multiple books, full processing):
```
Use Task sub-agents (subagent_type=Bash) — one per book — each running the full pipeline:
split_m4b → concat_mp3 → change_vol_mp3 → mv to final_single_mp3_vol/
```

**When to use sub-agents vs background Bash**:
- Background Bash (`run_in_background: true`): Simple single commands (one volume boost, one split)
- Task sub-agents: Multi-step pipelines per item (split + concat + volume + move for one book)

## Directory Layout

```
src_m4b_files/        — source M4B audiobook files
src_mp3/              — source MP3 files
splitted_m4b_dirs/    — split chapter files (per book)
final_single_mp3_vol/ — final processed files (volume-adjusted)
```
