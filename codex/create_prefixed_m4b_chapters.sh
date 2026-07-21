#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  create_prefixed_m4b_chapters.sh [options] <source.m4b>

Required options:
  --output-dir <dir>        Directory for numbered MP3 chapter files.
  --book-name <name>        Spoken title used in: <name>, chapter N.

Optional:
  --volume-pct <percent>    Volume multiplier in percent. Default: 100.
  --speed-pct <percent>     Playback speed in percent. Default: 100.
  --voice <name>            macOS voice passed to say. Default: system voice.
  -h, --help                Show this help.

Behavior:
  - Reads embedded M4B chapter metadata.
  - Exports only markers named "Chapter NN"; credit markers are skipped.
  - Names outputs 01.mp3, 02.mp3, and so on.
  - Prepends "<book name>, chapter N." to each chapter.

Example:
  ./codex/create_prefixed_m4b_chapters.sh \
    --output-dir "../final/Series Title" \
    --book-name "Series Title" \
    --speed-pct 90 \
    --volume-pct 300 \
    "../sources/Series Title.m4b"
EOF
}

output_dir=""
book_name=""
volume_pct="100"
speed_pct="100"
voice=""
source=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output-dir)
      output_dir="${2:-}"
      shift 2
      ;;
    --book-name)
      book_name="${2:-}"
      shift 2
      ;;
    --volume-pct)
      volume_pct="${2:-}"
      shift 2
      ;;
    --speed-pct)
      speed_pct="${2:-}"
      shift 2
      ;;
    --voice)
      voice="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [[ -n "$source" ]]; then
        echo "Error: only one source M4B is supported." >&2
        usage >&2
        exit 1
      fi
      source="$1"
      shift
      ;;
  esac
done

if [[ -z "$source" || -z "$output_dir" || -z "$book_name" ]]; then
  echo "Error: source, --output-dir, and --book-name are required." >&2
  usage >&2
  exit 1
fi

if [[ ! -f "$source" ]]; then
  echo "Error: source file not found: $source" >&2
  exit 1
fi

for required_command in ffmpeg ffprobe python3 say; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    echo "Error: required command not found: $required_command" >&2
    exit 1
  fi
done

if ! [[ "$volume_pct" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "Error: --volume-pct must be numeric." >&2
  exit 1
fi

if ! [[ "$speed_pct" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "Error: --speed-pct must be numeric." >&2
  exit 1
fi

if ! awk -v value="$volume_pct" 'BEGIN { exit !(value > 0) }'; then
  echo "Error: --volume-pct must be greater than zero." >&2
  exit 1
fi

if ! awk -v value="$speed_pct" 'BEGIN { exit !(value > 0) }'; then
  echo "Error: --speed-pct must be greater than zero." >&2
  exit 1
fi

build_atempo_chain() {
  local factor="$1"
  local chain=""

  while awk -v value="$factor" 'BEGIN { exit !(value > 2.0) }'; do
    [[ -z "$chain" ]] || chain="${chain},"
    chain="${chain}atempo=2.0"
    factor="$(awk -v value="$factor" 'BEGIN { printf "%.10f", value/2.0 }')"
  done

  while awk -v value="$factor" 'BEGIN { exit !(value < 0.5) }'; do
    [[ -z "$chain" ]] || chain="${chain},"
    chain="${chain}atempo=0.5"
    factor="$(awk -v value="$factor" 'BEGIN { printf "%.10f", value*2.0 }')"
  done

  [[ -z "$chain" ]] || chain="${chain},"
  printf '%satempo=%s\n' "$chain" "$factor"
}

volume_factor="$(awk -v value="$volume_pct" 'BEGIN { printf "%.6f", value/100 }')"
speed_factor="$(awk -v value="$speed_pct" 'BEGIN { printf "%.10f", value/100 }')"
atempo_chain="$(build_atempo_chain "$speed_factor")"

temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/m4b-prefixed-chapters.XXXXXX")"
chapter_list="$temp_dir/chapters.tsv"

cleanup() {
  rm -rf "$temp_dir"
}
trap cleanup EXIT INT TERM

ffprobe -v error -show_chapters -print_format json "$source" |
  python3 -c '
import json
import re
import sys

chapters = json.load(sys.stdin).get("chapters", [])
rows = []

for chapter in chapters:
    title = chapter.get("tags", {}).get("title", "")
    match = re.fullmatch(r"Chapter\s+(\d+)", title, flags=re.IGNORECASE)
    if not match:
        continue

    number = int(match.group(1))
    start = float(chapter["start_time"])
    end = float(chapter["end_time"])
    if end <= start:
        raise SystemExit(f"Invalid chapter duration for {title}")
    rows.append((number, start, end - start))

if not rows:
    raise SystemExit("No Chapter NN markers found")

width = max(2, len(str(max(number for number, _, _ in rows))))
for number, start, duration in rows:
    filename = f"{number:0{width}d}.mp3"
    print(f"{number}\t{start:.6f}\t{duration:.6f}\t{filename}")
' > "$chapter_list"

chapter_count="$(wc -l < "$chapter_list" | tr -d ' ')"
mkdir -p "$output_dir"

current=0
while IFS=$'\t' read -r chapter_number start duration filename; do
  current=$((current + 1))
  prefix_file="$temp_dir/${filename%.mp3}.aiff"
  temp_output="$temp_dir/${filename%.mp3}.mp3"
  final_output="${output_dir%/}/$filename"

  echo "[$current/$chapter_count] Chapter $chapter_number -> $final_output"

  say_args=(say)
  if [[ -n "$voice" ]]; then
    say_args+=(-v "$voice")
  fi
  say_args+=(-o "$prefix_file" --file-format=AIFF "$book_name, chapter $chapter_number.")
  "${say_args[@]}"

  ffmpeg -y -v error \
    -i "$prefix_file" \
    -ss "$start" \
    -t "$duration" \
    -i "$source" \
    -filter_complex \
      "[0:a][1:a]concat=n=2:v=0:a=1[combined];[combined]volume=${volume_factor},${atempo_chain}[final]" \
    -map '[final]' \
    -c:a libmp3lame \
    -q:a 2 \
    "$temp_output"

  mv "$temp_output" "$final_output"
done < "$chapter_list"

echo "Created $chapter_count chapter files in: $output_dir"
