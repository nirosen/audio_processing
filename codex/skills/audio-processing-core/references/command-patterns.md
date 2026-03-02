# Command Patterns

## Output Naming Rules

- `split_m4b`: writes numbered files into the target directory (`001.mp3`, `002.mp3`, ...).
- `concat_mp3`: default output is `<dir_name>_<start>-<end>.mp3`.
- `skip_start`: output is `<base>_<minutes>.end.mp3` or `<base>_<minutes>.end_<percent>pct.mp3`.
- `sample_mp3`: output is `<base>_<start>-<end>.mp3` with colons converted to dots.
- `change_vol_mp3`: output is `<base>_<percent>pct.mp3`.
- `concat_parts`: output embeds both source basenames plus start/duration/volume tags.
- `join_mp3`: default output is `<first_base>+<last_base>.mp3`.

## Chaining Recipes

## M4B to single louder segment

```bash
./split_m4b "src_m4b_files/Book.m4b" "splitted_m4b_dirs/Book"
./concat_mp3 "splitted_m4b_dirs/Book" 12-42 "Book_12-42.mp3"
./change_vol_mp3 "Book_12-42.mp3" 150
mv "Book_12-42_150pct.mp3" final_single_mp3_vol/
```

## Skip already-listened section and continue into next part

```bash
./skip_start "src_mp3_books/Part 01.mp3" 65 200
./change_vol_mp3 "src_mp3_books/Part 02.mp3" 200
./join_mp3 \
  "src_mp3_books/Part 01_65.end_200pct.mp3" \
  "src_mp3_books/Part 02_200pct.mp3" \
  --output "final_single_mp3_vol/continuation.mp3"
```

## Concat across two parts with fixed total duration

```bash
./concat_parts \
  "src_mp3_books/Part 01.mp3" \
  "src_mp3_books/Part 02.mp3" \
  45 60 200
```

## Common Failure Checks

- Missing source chapters in `concat_mp3` range.
- Wrong time format passed to `sample_mp3`.
- Non-MP3 input passed to scripts that require MP3.
- Unquoted paths with spaces.
