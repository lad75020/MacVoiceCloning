# Research: Reference Voice Capture

## Decision 1: Prepare replacements in app-owned staging

**Decision**: Convert raw or imported audio to a fixed staging WAV in the session directory, validate it, then commit it to the accepted-reference path.

**Rationale**: The current converter removes its output before writing. Passing the accepted reference directly can destroy a valid previous sample when conversion or duration validation fails.

**Alternatives considered**:

- Convert directly to the accepted path: rejected because it exposes partial output and loses prior valid audio.
- Keep every reference under a UUID: rejected because the app models one current session reference and would need cleanup/version management.
- Hold the entire converted file in memory: rejected for unnecessary memory use and complexity.

## Decision 2: Preserve prior state on failed replacement

**Decision**: Keep the previous accepted reference, transcript, synthesis, and alteration unchanged when replacement preparation fails.

**Rationale**: This is the explicit clarification outcome. Failure should be recoverable and must not discard valid user work.

**Alternatives considered**:

- Clear all prior state: rejected by the user.
- Keep audio but clear transcript and synthesis: rejected because it creates unnecessary loss without a committed input change.

## Decision 3: Prevent overlapping preparation

**Decision**: Guard `setReference` while preparation is active and disable Record and Import controls during preparation.

**Rationale**: Recording writes a fixed raw path and conversion writes a fixed staging path. Concurrent operations would race over shared session files.

**Alternatives considered**:

- Queue preparation operations: rejected because later user intent supersedes earlier work and queueing adds unclear UX.
- Generate a staging UUID for every request: rejected because it still allows ambiguous last-writer-wins state.

## Decision 4: Retain current realtime capture design

**Decision**: Keep `AVAudioEngine`, a hardware-format CAF, a 4096-frame input tap, lock-guarded statistics, and a main-actor polling task.

**Rationale**: Disk writes and RMS calculation already stay in the realtime callback while observable state updates are isolated to the main actor. Cleanup removes the tap, stops the engine, cancels polling, and closes the file.

## Decision 5: Keep transcription non-blocking and best effort

**Decision**: Accept the audio before transcription, use exact or same-language locale matching, and preserve manual editing as fallback.

**Rationale**: Speech locale support and asset installation vary by machine. Voice reference capture must remain usable without automatic text.

## Decision 6: Test deterministic boundaries

**Decision**: Extend `AudioConvertingTests` for empty input rejection, retain existing normalization tests, and use a cleaned tempfile verifier for orchestration and UI contracts.

**Rationale**: Conversion is deterministic. Microphone permissions, hardware, live level, and speech assets are not reliable CI dependencies.
