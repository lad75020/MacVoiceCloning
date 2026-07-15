# Data Model: Voice Clone Synthesis

## Synthesis Request

Immutable snapshot supplied to the local engine.

### Fields

- `text: String`: Boundary-trimmed target speech.
- `language: TTSLanguage`: Exact Qwen3-TTS language identifier.
- `referenceAudioURL: URL`: Accepted 24 kHz mono WAV.
- `referenceText: String`: Boundary-trimmed transcript matching the reference.
- `maxTokens: Int`: Positive upper bound, default 2048.

### Validation

- Text is effectively non-empty.
- Reference text is effectively non-empty.
- Maximum token count is positive.
- Concrete engine validates reference readability, rate, and duration.

## Synthesis Progress

Typed progress emitted while Qwen3-TTS generates top-level codec tokens.

### Fields

- `generatedTokens: Int`: Non-negative emitted token count.

### Derived Values

- `estimatedAudioSeconds = generatedTokens / 12.5`.
- Values are monotonic within one engine invocation.

## Synthesis Statistics

Final generation performance data.

### Fields

- `generatedTokens: Int`: Number of emitted top-level codec tokens.
- `totalSeconds: TimeInterval`: Wall-clock generation time after reference preparation.

### Derived Values

- `tokensPerSecond`: `generatedTokens / totalSeconds` when time is positive; otherwise zero.

## Candidate Synthesis

Unaccepted result returned by an engine implementation.

### Fields

- `samples: [Float]`: Mono Float32 waveform.
- `sampleRate: Int`: Frames per second.
- `stats: SynthesisStats?`: Optional backend metrics.

### Validation

- Sample rate is positive.
- Samples are non-empty.
- Every sample is finite.

### State

```text
returned → validated → staged → revision-confirmed → committed → accepted
    └──────────── invalid/error/superseded ───────────────→ discarded
```

## Accepted Synthesis

Pipeline clip published only after candidate commit.

### Fields

- `samples: [Float]`: Valid finite candidate samples.
- `sampleRate: Int`: Positive rate.
- `url: URL`: Stable accepted session WAV.
- `duration`: Exact samples divided by rate.
- `stats`: Candidate statistics.

### Invariants

- URL points to committed `synthesis.wav`.
- In-memory samples correspond to the committed file.
- Downstream alteration is scheduled only after acceptance.

## Synthesis Revision

Private monotonic pipeline generation context.

### Fields

- `value: UInt`: Incremented whenever synthesis-derived state is invalidated.

### Rules

- Capture value before asynchronous generation.
- Accept progress only when captured value equals current value.
- Recheck after generation and after staged write before commit.
- Superseded work returns silently without publishing.

## Session Synthesis Files

### Candidate

- `synthesis-staging.wav`
- Exclusive to one active generation.
- Removed on every exit path.

### Accepted

- `synthesis.wav`
- Stable path used by preview, alteration, and export.
- Replaced atomically after candidate validation.

## Pipeline State Transitions

```text
ready inputs ──generate──> generating
     │                         │
     │                         ├─ backend failure ──> prior accepted state + error
     │                         ├─ invalid output ───> prior accepted state + error
     │                         ├─ write failure ────> prior accepted state + error
     │                         ├─ superseded ───────> current invalidated state
     │                         └─ commit success ───> new accepted synthesis → alteration
     └─ input change ─────────> synthesis revision + invalidated derived state
```

## Error State

Shared user-facing localized message.

### Categories

- Model not loaded.
- Invalid request.
- Bad reference audio.
- Generation failure.
- Invalid generated output.
- Staging or atomic commit failure.

Errors never carry secrets or raw audio/text content.
