#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$repo_root" ]]; then
  echo "Error: run this inside a git repository."
  exit 1
fi

hook_path="$repo_root/.git/hooks/pre-push"
scan_script="$repo_root/codex/skills/git-privacy-guard/scripts/privacy_scan.sh"

if [[ ! -x "$scan_script" ]]; then
  echo "Error: missing executable scan script: $scan_script"
  echo "Run: chmod +x \"$scan_script\""
  exit 1
fi

if [[ -f "$hook_path" ]] && ! grep -q "git-privacy-guard" "$hook_path"; then
  backup_path="${hook_path}.bak.$(date +%Y%m%d%H%M%S)"
  cp "$hook_path" "$backup_path"
  echo "Backed up existing pre-push hook to: $backup_path"
fi

cat > "$hook_path" <<'HOOK'
#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
"$repo_root/codex/skills/git-privacy-guard/scripts/privacy_scan.sh" --scope outgoing --repo "$repo_root"
HOOK

chmod +x "$hook_path"

echo "Installed pre-push hook: $hook_path"
echo "Create/update $repo_root/.privacy-denylist.txt with one sensitive term per line."
