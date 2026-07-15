# Reference Capture Contract

## Purpose

Define observable behavior for microphone recording, audio import, normalization, replacement, and transcript preparation.

## Control Contract

| Condition | Record | Import | Transcript |
|---|---|---|---|
| Idle, no preparation | Enabled | Enabled | Editable |
| Recording | Stop enabled | Disabled | Editable |
| Preparing reference | Disabled | Disabled | Editable unless transcription is active |
| Transcribing | Enabled unless preparing | Enabled unless preparing | Temporarily disabled with progress |

## Recording Contract

1. Request microphone permission before installing an input tap.
2. On denial, present a path to microphone privacy settings.
3. Stop existing playback before recording.
4. Write hardware-format frames to the app-owned raw recording.
5. Poll lock-guarded RMS and frame counts for meter and elapsed duration.
6. On Stop, remove the tap, stop the engine, cancel polling, close the file, and pass a non-empty capture to preparation.

## Import Contract

1. Present the system file importer restricted to audio.
2. Acquire security-scoped access when available.
3. Keep access for the complete asynchronous preparation operation.
4. Relinquish access on every return path.
5. Surface importer failures through the shared error state.

## Preparation Contract

1. Ignore a new request while preparation is active.
2. Ensure app-owned directories exist.
3. Remove stale staging, then convert input into staging as 24 kHz mono Float32 WAV.
4. Reject normalized duration below three seconds.
5. Preserve the previous reference and all derived state on rejection or failure.
6. Replace or move staging to the stable accepted-reference URL only after validation.
7. Update reference metadata, invalidate old synthesis and alteration, then begin transcription.
8. Remove staging in all outcomes.

## Transcription Contract

1. Cancel the prior run only when a new valid reference commits.
2. Prefer exact BCP-47 locale support, then same-language support.
3. Install required system speech assets when offered.
4. Analyze the accepted app-owned WAV and trim collected text.
5. Apply non-empty automatic text only if the user field remains empty.
6. Check cancellation before changing current state.
7. Treat unsupported locale, installation failure, and analysis failure as non-fatal.

## Error Contract

| Failure | User-visible outcome | Prior accepted state |
|---|---|---|
| Microphone denied | Privacy guidance alert | Preserved |
| Missing input device | Shared error | Preserved |
| Realtime disk write | Shared error after cleanup | Preserved |
| Empty/unreadable import | Shared error | Preserved |
| Conversion failure | Shared error | Preserved |
| Sample shorter than three seconds | Duration-specific shared error | Preserved |
| Transcription failure | Manual transcript remains available | Preserved |
