---
name: audiobook-batch-pipeline
description: Parallel audiobook processing for batches of files or books. Use when requests involve many independent files, repeated processing across multiple books, or end-to-end pipelines that should run concurrently while keeping per-book steps in sequence.
---

# Audiobook Batch Pipeline

Run commands from `/Users/nrosen/code/audiobooks/audio_processing`.

## Parallelization Model

- Keep each single-book pipeline sequential.
- Run separate books or independent files in parallel.
- Avoid writing two jobs to the same output filename.
- Wait for all upstream jobs before merge or move steps.

## Workflow

1. Group work items by independent outputs.
2. Choose a per-item pipeline.
3. Launch one job per item in parallel.
4. Wait for completion and check exit status.
5. Move or publish final outputs only after all jobs succeed.

## Recommended Tools

- Use `scripts/batch_volume_boost.sh` for parallel volume adjustments across many MP3 files.
- Use one background job or sub-agent per book for full pipelines such as split, concat, volume, move.
- Reuse project scripts (`split_m4b`, `concat_mp3`, `change_vol_mp3`, `skip_start`, `concat_parts`, `join_mp3`) inside each per-book job.

## Batch Volume Template

```bash
./codex/skills/audiobook-batch-pipeline/scripts/batch_volume_boost.sh \
  --percent 150 \
  --jobs 4 \
  --move-dir "final_single_mp3_vol" \
  "src_mp3_nesbo/Police - Part 01.mp3" \
  "src_mp3_nesbo/Police - Part 02.mp3" \
  "src_mp3_nesbo/Police - Part 03.mp3"
```

## References

Read `references/pipeline-recipes.md` for per-book and multi-book execution patterns.
