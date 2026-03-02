---
name: git-privacy-guard
description: Prevent personal details from being pushed to git by scanning outgoing commits for denylisted terms and blocking push when matches are found. Use before commit/push and when sanitizing history after accidental exposure.
---

# Git Privacy Guard

Run commands from `/Users/nrosen/code/audiobooks/audio_processing`.

## Use This Skill When

- Requests mention removing personal details before push.
- A push should be blocked if sensitive names or phrases appear.
- A branch must be sanitized after accidental exposure.

## Setup

1. Create local denylist file at `.privacy-denylist.txt` (not tracked).
2. Add one sensitive term per line.
3. You can start from `references/denylist-template.txt`.
4. Install the pre-push hook:

```bash
./codex/skills/git-privacy-guard/scripts/install_pre_push_hook.sh
```

## Scan Commands

Scan commits that will be pushed:

```bash
./codex/skills/git-privacy-guard/scripts/privacy_scan.sh --scope outgoing
```

Scan all reachable commits:

```bash
./codex/skills/git-privacy-guard/scripts/privacy_scan.sh --scope history
```

Use a custom denylist path:

```bash
./codex/skills/git-privacy-guard/scripts/privacy_scan.sh --scope outgoing --patterns-file /path/to/denylist.txt
```

## Remediation

1. If scan fails, edit files to remove sensitive terms.
2. If terms are in the latest local commit, rewrite from safe base and recommit.
3. Push with `--force-with-lease` only when history rewrite is required.
