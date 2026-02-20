#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 6 ]]; then
  echo "Usage: $0 <input.mp3> <output.mp3> [start_hh:mm:ss] [duration_hh:mm:ss] [volume_pct] [speed_pct]"
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

input_file="$1"
output_file="$2"
start_time="${3:-01:09:00}"
duration="${4:-01:30:00}"
volume_pct="${5:-200}"
speed_pct="${6:-75}"

"$script_dir/create_track.sh" \
  "$input_file" \
  "$output_file" \
  "$start_time" \
  "$duration" \
  "$volume_pct" \
  "$speed_pct"
