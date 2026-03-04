#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  create_continuation_track.sh --listen-min <minutes> [--output <output.mp3> | --name-title <title>] [options] <source1.mp3> [source2.mp3 ...]

Options:
  --listen-min <minutes>    Required. Minutes already read in source1.
  --output <path>           Optional. Explicit output MP3 path.
  --name-title <title>      Optional. Auto-generate output name:
                            <title> - Pxx+offset_volNNN_speedNNN.mp3
  --part <number>           Optional. Part number for auto name (e.g. 3 -> P03).
                            If omitted, inferred from source1 filename.
  --offset-label <label>    Optional. Override offset label in auto name.
                            Defaults to listened minutes (e.g. 15, 66m43s).
  --out-dir <dir>           Optional. Output directory for auto name.
                            Default: final_single_mp3_vol
  --target-min <minutes>    Optional. Output length in minutes. Default: 60.
  --volume-pct <percent>    Optional. Volume multiplier in percent. Default: 100.
  --speed-pct <percent>     Optional. Playback speed in percent. Default: 100.

Examples:
  ./codex/create_continuation_track.sh \
    --listen-min 20 \
    --output "final_single_mp3_vol/Next Segment.mp3" \
    "final_single_mp3_vol/Current Segment.mp3"

  ./codex/create_continuation_track.sh \
    --listen-min 15 \
    --target-min 60 \
    --volume-pct 200 \
    --speed-pct 100 \
    --name-title "Series Title" \
    --part 3 \
    "src_mp3/Part 03.mp3" \
    "src_mp3/Part 04.mp3"

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
name_title=""
part_override=""
offset_label=""
out_dir="final_single_mp3_vol"
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
    --name-title)
      name_title="${2:-}"
      shift 2
      ;;
    --part)
      part_override="${2:-}"
      shift 2
      ;;
    --offset-label)
      offset_label="${2:-}"
      shift 2
      ;;
    --out-dir)
      out_dir="${2:-}"
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

if [[ -z "$listen_min" || ${#sources[@]} -lt 1 || ( -z "$output" && -z "$name_title" ) ]]; then
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

if [[ -n "$part_override" ]] && ! [[ "$part_override" =~ ^[0-9]+$ ]]; then
  echo "Error: --part must be a positive integer."
  exit 1
fi

for src in "${sources[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "Error: source file not found: $src"
    exit 1
  fi
done

trim_num_for_name() {
  echo "$1" | sed -E 's/([0-9]*\.[0-9]*[1-9])0+$/\1/; s/\.0+$//'
}

infer_part_number() {
  local src="$1"
  local base
  base="$(basename "$src")"
  if [[ "$base" =~ [Pp]art[[:space:]_-]*0*([0-9]+) ]]; then
    printf "%02d" "$((10#${BASH_REMATCH[1]}))"
    return 0
  fi
  return 1
}

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

if [[ -z "$output" ]]; then
  part_num=""
  if [[ -n "$part_override" ]]; then
    part_num="$(printf "%02d" "$((10#$part_override))")"
  else
    if ! part_num="$(infer_part_number "${sources[0]}")"; then
      echo "Error: cannot infer part number from source filename. Use --part."
      exit 1
    fi
  fi

  if [[ -z "$offset_label" ]]; then
    offset_total_sec="$(awk -v m="$listen_min" 'BEGIN { printf "%d", (m*60)+0.5 }')"
    offset_min=$((offset_total_sec / 60))
    offset_sec=$((offset_total_sec % 60))
    if [[ "$offset_sec" -eq 0 ]]; then
      offset_label="$offset_min"
    else
      offset_label="${offset_min}m${offset_sec}s"
    fi
  fi

  vol_tag="$(trim_num_for_name "$volume_pct")"
  speed_tag="$(trim_num_for_name "$speed_pct")"
  output="${out_dir%/}/${name_title} - P${part_num}+${offset_label}_vol${vol_tag}_speed${speed_tag}.mp3"
fi

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
