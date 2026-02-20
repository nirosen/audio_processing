#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 6 ]]; then
  echo "Usage: $0 <input.mp3> <output.mp3> <start_hh:mm:ss> <duration_hh:mm:ss> <volume_pct> <speed_pct>"
  exit 1
fi

input="$1"
output="$2"
start_time="$3"
duration="$4"
volume_pct="$5"
speed_pct="$6"

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "Error: ffmpeg is not installed."
  exit 1
fi

if [[ ! -f "$input" ]]; then
  echo "Error: input file not found: $input"
  exit 1
fi

if ! [[ "$volume_pct" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "Error: volume_pct must be numeric."
  exit 1
fi

if ! [[ "$speed_pct" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "Error: speed_pct must be numeric."
  exit 1
fi

volume_factor="$(awk -v p="$volume_pct" 'BEGIN { printf "%.6f", p/100 }')"
speed_factor="$(awk -v p="$speed_pct" 'BEGIN { printf "%.10f", p/100 }')"

build_atempo_chain() {
  local factor="$1"
  local chain=""

  while awk -v x="$factor" 'BEGIN { exit !(x > 2.0) }'; do
    if [[ -n "$chain" ]]; then
      chain="${chain},"
    fi
    chain="${chain}atempo=2.0"
    factor="$(awk -v x="$factor" 'BEGIN { printf "%.10f", x/2.0 }')"
  done

  while awk -v x="$factor" 'BEGIN { exit !(x < 0.5) }'; do
    if [[ -n "$chain" ]]; then
      chain="${chain},"
    fi
    chain="${chain}atempo=0.5"
    factor="$(awk -v x="$factor" 'BEGIN { printf "%.10f", x*2.0 }')"
  done

  if [[ -n "$chain" ]]; then
    chain="${chain},"
  fi
  chain="${chain}atempo=${factor}"
  echo "$chain"
}

atempo_chain="$(build_atempo_chain "$speed_factor")"
audio_filters="volume=${volume_factor},${atempo_chain}"

mkdir -p "$(dirname "$output")"

ffmpeg -y -v error \
  -ss "$start_time" \
  -i "$input" \
  -af "$audio_filters" \
  -t "$duration" \
  -c:a libmp3lame \
  -q:a 2 \
  "$output"

echo "Created: $output"
