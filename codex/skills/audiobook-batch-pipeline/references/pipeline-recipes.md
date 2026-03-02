# Pipeline Recipes

## Pattern: Single-step command across many files

Use this for volume-only changes:

```bash
./codex/skills/audiobook-batch-pipeline/scripts/batch_volume_boost.sh \
  --percent 150 \
  --jobs 4 \
  --move-dir final_single_mp3_vol \
  src_mp3_nesbo/*.mp3
```

## Pattern: Multi-step pipeline per book

Keep each book sequential:

```bash
./split_m4b "src_m4b_files/Book A.m4b" "splitted_m4b_dirs/Book A"
./concat_mp3 "splitted_m4b_dirs/Book A" 1-30 "Book A_1-30.mp3"
./change_vol_mp3 "Book A_1-30.mp3" 150
mv "Book A_1-30_150pct.mp3" final_single_mp3_vol/
```

Run multiple books in parallel by launching one job per book with different paths.

## Pattern: Resume windows in parallel

```bash
./skip_start "src_mp3_nesbo/Knife - Part 01.mp3" 45 200 &
./skip_start "src_mp3_nesbo/Phantom - Part 01.mp3" 30 200 &
./skip_start "src_mp3_nesbo/Police - Part 01.mp3" 20 200 &
wait
```

## Safety Checks

- Ensure output names are unique per parallel job.
- Verify expected files exist before downstream joins.
- Perform `mv` operations only after all producers complete.
