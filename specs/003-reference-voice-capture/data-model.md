# Data Model: Reference Voice Capture

## Raw Capture

A transient source awaiting normalization.

### Fields

- `url`: Recording CAF or security-scoped imported audio URL.
- `origin`: Recorded or imported, implicit from the interaction path.
- `duration`: Known for completed recordings; recomputed from normalized output for imports.

### Rules

- The imported URL is accessed only during preparation.
- The fixed raw recording is never the accepted reference.
- Raw capture may be overwritten by a later recording only when no preparation is active.

## Reference Preparation

An exclusive conversion and validation operation.

### Fields

- `isPreparing`: Observable operation flag.
- `stagingURL`: App-owned temporary WAV in the session directory.
- `minimumDuration`: Three seconds.
- `outputFormat`: Float32 PCM, 24,000 Hz, mono, WAV container.

### State Transitions

```text
idle ──record/import──▶ preparing
preparing ──valid output──▶ commit ──▶ idle
preparing ──short/error──▶ preserve previous ──▶ idle
```

### Invariants

- At most one preparation is active.
- Staging is never exposed as the accepted reference.
- Leftover staging is removed after every attempt.
- Failed preparation does not mutate accepted or derived state.

## Prepared Reference

The current validated TTS conditioning audio.

### Fields

- `url`: Stable app-owned accepted-reference URL.
- `duration`: Duration in seconds, at least three.

### Invariants

- Audio is readable as 24 kHz mono Float32 WAV.
- A new valid reference replaces the previous file before metadata changes.
- Committing a new valid reference invalidates synthesis and alteration.

## Recorder State

Observable microphone capture lifecycle.

### States

- `idle`: No input tap, engine, file, or polling task is active.
- `recording`: Input tap writes hardware-format frames and statistics are polled.

### Observable Values

- `level`: Smoothed zero-to-one RMS-derived input level.
- `duration`: Captured frames divided by hardware sample rate.

### Invariants

- Starting while recording is a no-op.
- Stopping removes tap, stops engine, cancels polling, closes file, and returns to idle.
- No-input and disk-write failures are surfaced.

## Reference Transcript

Editable words spoken in the accepted reference.

### Fields

- `text`: User-editable string.
- `isTranscribing`: Observable best-effort analysis flag.
- `localeIdentifier`: Derived from the selected synthesis language.

### Rules

- A newly accepted reference cancels older transcription.
- Successful text is trimmed.
- Automatic text applies only while current text is empty.
- Failure or unsupported locale leaves manual entry available.
- A canceled stale task cannot mutate current text.

## Derived State

Synthesis, statistics, and altered audio associated with the accepted reference.

### Rules

- Valid replacement invalidates all prior derived state.
- Failed replacement preserves all prior derived state.
