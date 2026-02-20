# Codex Scripts

Generic scripts for creating audiobook tracks with trim, volume change, and speed change.

## Scripts

- `create_track.sh`: Main script. Generates a processed MP3 track.
- `make_resume_track.sh`: Convenience wrapper with optional defaults.

## Usage

Main script:

```bash
./codex/create_track.sh "input.mp3" "output.mp3" "01:09:00" "01:30:00" 200 75
```

Wrapper script:

```bash
./codex/make_resume_track.sh "input.mp3" "output.mp3"
```

Wrapper optional parameters:

```bash
./codex/make_resume_track.sh "input.mp3" "output.mp3" "01:09:00" "01:30:00" 200 75
```
