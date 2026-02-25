#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  create_continuation_track.sh --listen-min <minutes> --output <output.mp3> [options] <source1.mp3> [source2.mp3 ...]

Options:
  --listen-min <minutes>    Required. Minutes already read in source1.
  --output <path>           Required. Output MP3 path.
  --target-min <minutes>    Optional. Output length in minutes. Default: 60.
  --volume-pct <percent>    Optional. Volume multiplier in percent. Default: 100.
  --speed-pct <percent>     Optional. Playback speed in percent. Default: 100.

Examples:
  ./codex/create_continuation_track.sh \
    --listen-min 20 \
    --output "final_single_mp3_vol/Next Segment.mp3" \
    "final_single_mp3_vol/Current Segment.mp3"

  ./codex/create_continuation_track.sh \
    --listen-min 40 \
    --target-min 60 \
    --volume-pct 200 \
    --output "final_single_mp3_vol/Continuation_40.end.mp3" \
    "src_mp3/book_part_02.mp3" \
    "src_mp3/book_part_03.mp3" \
    "src_mp3/book_part_04.mp3"
EOF
}

listen_min=""
output=""
target_min="60"
volume_pct="100"
speed_pct="100"
sources=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --listen-min)
      listen_min="${2:-}"
      shift 2
      ;;
    --output)
      output="${2:-}"
      shift 2
      ;;
    --target-min)
      target_min="${2:-}"
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
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      while [[ $# -gt 0 ]]; do
        sources+=("$1")
        shift
      done
      ;;
    -*)
      echo "Error: unknown option: $1"
      usage
      exit 1
      ;;
    *)
      sources+=("$1")
      shift
      ;;
  esac
done

if [[ -z "$listen_min" || -z "$output" || ${#sources[@]} -lt 1 ]]; then
  usage
  exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "Error: ffmpeg is not installed."
  exit 1
fi

if ! [[ "$listen_min" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "Error: --listen-min must be numeric."
  exit 1
fi

if ! [[ "$target_min" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "Error: --target-min must be numeric."
  exit 1
fi

if ! [[ "$volume_pct" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "Error: --volume-pct must be numeric."
  exit 1
fi

if ! [[ "$speed_pct" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "Error: --speed-pct must be numeric."
  exit 1
fi

for src in "${sources[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "Error: source file not found: $src"
    exit 1
  fi
done

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

offset_sec="$(awk -v m="$listen_min" 'BEGIN { printf "%.6f", m*60 }')"
target_sec="$(awk -v m="$target_min" 'BEGIN { printf "%.6f", m*60 }')"
volume_factor="$(awk -v p="$volume_pct" 'BEGIN { printf "%.6f", p/100 }')"
speed_factor="$(awk -v p="$speed_pct" 'BEGIN { printf "%.10f", p/100 }')"
atempo_chain="$(build_atempo_chain "$speed_factor")"

input_args=()
for idx in "${!sources[@]}"; do
  if [[ "$idx" -eq 0 ]]; then
    input_args+=(-ss "$offset_sec")
  fi
  input_args+=(-i "${sources[$idx]}")
done

filter_complex=""
concat_inputs=""
for idx in "${!sources[@]}"; do
  filter_complex="${filter_complex}[${idx}:a]volume=${volume_factor},${atempo_chain}[a${idx}];"
  concat_inputs="${concat_inputs}[a${idx}]"
done

if [[ ${#sources[@]} -eq 1 ]]; then
  filter_complex="${filter_complex}${concat_inputs}anull[aout]"
else
  filter_complex="${filter_complex}${concat_inputs}concat=n=${#sources[@]}:v=0:a=1[aout]"
fi

mkdir -p "$(dirname "$output")"

ffmpeg -y -v error \
  "${input_args[@]}" \
  -filter_complex "$filter_complex" \
  -map "[aout]" \
  -t "$target_sec" \
  -c:a libmp3lame \
  -q:a 2 \
  "$output"

echo "Created: $output"
