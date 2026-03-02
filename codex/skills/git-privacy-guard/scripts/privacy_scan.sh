#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  privacy_scan.sh [--scope outgoing|history|working] [--repo <path>] [--patterns-file <path>]

Options:
  --scope <value>         Scan scope. Default: outgoing
  --repo <path>           Git repository path. Default: current git toplevel.
  --patterns-file <path>  Sensitive terms list file. Default: <repo>/.privacy-denylist.txt
  -h, --help              Show this help.

Pattern file format:
  - One term per line
  - Empty lines are ignored
  - Lines starting with # are comments
USAGE
}

scope="outgoing"
repo=""
patterns_file=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope)
      scope="${2:-}"
      shift 2
      ;;
    --repo)
      repo="${2:-}"
      shift 2
      ;;
    --patterns-file)
      patterns_file="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$repo" ]]; then
  repo="$(git rev-parse --show-toplevel 2>/dev/null || true)"
fi

if [[ -z "$repo" || ! -d "$repo/.git" ]]; then
  echo "Error: --repo must point to a git repository."
  exit 1
fi

if [[ -z "$patterns_file" ]]; then
  patterns_file="$repo/.privacy-denylist.txt"
fi

if [[ ! -f "$patterns_file" ]]; then
  echo "Error: missing patterns file: $patterns_file"
  echo "Create it with one sensitive term per line."
  exit 1
fi

patterns=()
while IFS= read -r line; do
  patterns+=("$line")
done < <(grep -v '^[[:space:]]*#' "$patterns_file" | sed '/^[[:space:]]*$/d')

if [[ ${#patterns[@]} -eq 0 ]]; then
  echo "Error: patterns file is empty: $patterns_file"
  exit 1
fi

hits=0

scan_commit() {
  local commit="$1"
  local pat=""
  local content_hits=""
  local path_hits=""

  for pat in "${patterns[@]}"; do
    content_hits="$(git -C "$repo" grep -nF -- "$pat" "$commit" -- . 2>/dev/null || true)"
    path_hits="$(git -C "$repo" ls-tree -r --name-only "$commit" | grep -nFi -- "$pat" || true)"

    if [[ -n "$content_hits" ]]; then
      echo "content match in commit $commit for pattern: $pat"
      echo "$content_hits"
      hits=$((hits + 1))
    fi

    if [[ -n "$path_hits" ]]; then
      echo "path match in commit $commit for pattern: $pat"
      echo "$path_hits"
      hits=$((hits + 1))
    fi
  done
}

scan_working_tree() {
  local pat=""
  local content_hits=""
  local path_hits=""

  for pat in "${patterns[@]}"; do
    content_hits="$(git -C "$repo" grep -nF -- "$pat" -- . 2>/dev/null || true)"
    path_hits="$(git -C "$repo" ls-files | grep -nFi -- "$pat" || true)"

    if [[ -n "$content_hits" ]]; then
      echo "content match in working tree for pattern: $pat"
      echo "$content_hits"
      hits=$((hits + 1))
    fi

    if [[ -n "$path_hits" ]]; then
      echo "path match in working tree for pattern: $pat"
      echo "$path_hits"
      hits=$((hits + 1))
    fi
  done
}

case "$scope" in
  outgoing)
    upstream="$(git -C "$repo" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
    if [[ -z "$upstream" ]]; then
      branch="$(git -C "$repo" branch --show-current 2>/dev/null || true)"
      if [[ -n "$branch" ]] && git -C "$repo" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
        upstream="origin/$branch"
      fi
    fi

    commits=()
    if [[ -n "$upstream" ]]; then
      while IFS= read -r line; do
        [[ -n "$line" ]] && commits+=("$line")
      done < <(git -C "$repo" rev-list "${upstream}..HEAD")
    else
      commits=("HEAD")
    fi

    if [[ ${#commits[@]} -eq 0 ]]; then
      echo "No outgoing commits to scan."
      exit 0
    fi

    for commit in "${commits[@]}"; do
      scan_commit "$commit"
    done
    ;;
  history)
    commits=()
    while IFS= read -r line; do
      [[ -n "$line" ]] && commits+=("$line")
    done < <(git -C "$repo" rev-list --all)
    for commit in "${commits[@]}"; do
      scan_commit "$commit"
    done
    ;;
  working)
    scan_working_tree
    ;;
  *)
    echo "Error: invalid --scope value: $scope"
    usage
    exit 1
    ;;
esac

if [[ "$hits" -gt 0 ]]; then
  echo "Privacy scan failed: $hits match group(s) found."
  exit 1
fi

echo "Privacy scan passed: no matches found."
