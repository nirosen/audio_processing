#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  batch_volume_boost.sh --percent <value> [--jobs <count>] [--move-dir <dir>] [--dry-run] <file1.mp3> [file2.mp3 ...]

Options:
  --percent <value>   Required. Volume percentage (e.g. 150, 200).
  --jobs <count>      Optional. Max concurrent jobs. Default: 4.
  --move-dir <dir>    Optional. Move generated *_<percent>pct.mp3 files into this directory.
  --dry-run           Optional. Print actions without running commands.

Example:
  ./codex/skills/audiobook-batch-pipeline/scripts/batch_volume_boost.sh \
    --percent 150 \
    --jobs 4 \
    --move-dir final_single_mp3_vol \
    "src_mp3_nesbo/Police - Part 01.mp3" \
    "src_mp3_nesbo/Police - Part 02.mp3"
USAGE
}

percent=""
jobs="4"
move_dir=""
dry_run="0"
files=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --percent)
      percent="${2:-}"
      shift 2
      ;;
    --jobs)
      jobs="${2:-}"
      shift 2
      ;;
    --move-dir)
      move_dir="${2:-}"
      shift 2
      ;;
    --dry-run)
      dry_run="1"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      while [[ $# -gt 0 ]]; do
        files+=("$1")
        shift
      done
      ;;
    -*)
      echo "Error: unknown option: $1"
      usage
      exit 1
      ;;
    *)
      files+=("$1")
      shift
      ;;
  esac
done

if [[ -z "$percent" || ${#files[@]} -eq 0 ]]; then
  usage
  exit 1
fi

if ! [[ "$percent" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "Error: --percent must be numeric."
  exit 1
fi

if ! [[ "$jobs" =~ ^[1-9][0-9]*$ ]]; then
  echo "Error: --jobs must be a positive integer."
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
audio_processing_dir="$(cd "$script_dir/../../../.." && pwd)"
change_vol_script="$audio_processing_dir/change_vol_mp3"

if [[ ! -x "$change_vol_script" ]]; then
  echo "Error: missing executable: $change_vol_script"
  exit 1
fi

outputs=()
for file in "${files[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "Error: file not found: $file"
    exit 1
  fi
  if [[ "$file" != *.mp3 ]]; then
    echo "Error: expected .mp3 input: $file"
    exit 1
  fi

  dir="$(dirname "$file")"
  base="$(basename "$file" .mp3)"
  outputs+=("${dir}/${base}_${percent}pct.mp3")
done

echo "Batch volume boost: ${#files[@]} file(s), percent=$percent, jobs=$jobs"
[[ -n "$move_dir" ]] && echo "Move dir: $move_dir"

if [[ "$dry_run" == "1" ]]; then
  for file in "${files[@]}"; do
    echo "$change_vol_script \"$file\" \"$percent\""
  done
  exit 0
fi

pids=()
failed=0

for file in "${files[@]}"; do
  "$change_vol_script" "$file" "$percent" &
  pids+=("$!")

  if [[ ${#pids[@]} -ge "$jobs" ]]; then
    pid="${pids[0]}"
    if ! wait "$pid"; then
      failed=$((failed + 1))
    fi
    pids=("${pids[@]:1}")
  fi
done

for pid in "${pids[@]}"; do
  if ! wait "$pid"; then
    failed=$((failed + 1))
  fi
done

if [[ "$failed" -ne 0 ]]; then
  echo "Error: $failed job(s) failed."
  exit 1
fi

if [[ -n "$move_dir" ]]; then
  mkdir -p "$move_dir"
  for output in "${outputs[@]}"; do
    if [[ -f "$output" ]]; then
      mv "$output" "$move_dir/"
    else
      echo "Warning: expected output not found: $output"
    fi
  done
fi

echo "Done."
