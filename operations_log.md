# Operations Log

## Common Patterns

### Full pipeline: M4B -> split -> concat range -> volume boost -> final
```bash
split_m4b "src_m4b_files/Book.m4b" "splitted_m4b_dirs/Book"
concat_mp3 "splitted_m4b_dirs/Book" 1-15
change_vol_mp3 "Book_1-15.mp3" 150
mv "Book_1-15_150pct.mp3" final_single_mp3_vol/
```

### Skip ahead + volume boost
```bash
skip_start "src_mp3/Part 01.mp3" 45 200
# Output: Part 01_45.end_200pct.mp3
```

### Sample by time then volume boost
```bash
sample_mp3 file.mp3 0:00-1:30
change_vol_mp3 file_0.00-1.30.mp3 150
```

### Join remainder of Part 1 with Part 2
```bash
skip_start "Part 01.mp3" 65 200
change_vol_mp3 "Part 02.mp3" 200
join_mp3 "Part 01_65.end_200pct.mp3" "Part 02_200pct.mp3"
# Output: single file for uninterrupted listening
```

### Concat across parts with offset and duration limit
```bash
concat_parts "Part 01.mp3" "Part 02.mp3" 45 60 200
# Output: 60-minute file starting at Part 01's 45min mark, continues into Part 02, 2x volume
```

### Extract time range from M4B with volume boost
```bash
ffmpeg -i input.m4b -ss 1:50:00 -to 3:00:00 -filter:a "volume=1.5" -codec:a libmp3lame -q:a 2 output.mp3
```

### Batch volume boost (run in parallel)
```bash
for f in src_mp3/*.mp3; do
  change_vol_mp3 "$f" 150 &
done
wait
mv src_mp3/*_150pct.mp3 final_single_mp3_vol/
```
