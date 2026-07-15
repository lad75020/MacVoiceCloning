# Voice Clone Synthesis Contract

## Purpose

Define the local engine, progress, validation, and transactional acceptance boundaries for voice-clone synthesis.

## Engine Lifecycle

```swift
func load() async throws
func synthesize(
    _ request: SynthesisRequest,
    onProgress: @escaping @Sendable (SynthesisProgress) -> Void
) async throws -> SynthesisResult
func unload() async
```

- `load` is idempotent and accepts only a Base model.
- `synthesize` requires a loaded model.
- `unload` releases model state and clears GPU cache.
- No reference audio, transcript, target text, or output leaves the process.

## Request Contract

```swift
SynthesisRequest(
    text: trimmedTargetText,
    language: selectedLanguage,
    referenceAudioURL: acceptedReferenceURL,
    referenceText: trimmedReferenceTranscript,
    maxTokens: 2048)
```

### Preconditions

- `text` is not empty after boundary trimming.
- `referenceText` is not empty after boundary trimming.
- `maxTokens > 0`.
- Reference is readable mono audio at the loaded model rate.
- Reference duration is at least three seconds.

## Progress Contract

Each progress value contains the total emitted top-level codec tokens.

```text
estimatedAudioSeconds = Double(generatedTokens) / 12.5
```

- `generatedTokens >= 0`.
- Values never decrease during one request.
- The concrete adapter may throttle callback frequency.
- The adapter emits a final callback for any remainder after throttling.
- Pipeline accepts callbacks only for the active synthesis revision.

## Result Contract

A result is acceptable only if:

```text
sampleRate > 0
samples.count > 0
samples.allSatisfy(isFinite)
```

Invalid results throw an actionable `TTSEngineError.invalidOutput` and never reach accepted state.

## Statistics Contract

```text
tokensPerSecond = generatedTokens / totalSeconds, when totalSeconds > 0
```

A successful concrete Qwen generation records emitted token count and elapsed generation time.

## Transaction Contract

1. Capture request and synthesis revision.
2. Generate candidate.
3. Confirm revision.
4. Validate candidate.
5. Write `synthesis-staging.wav`.
6. Confirm revision again.
7. Atomically replace `synthesis.wav`.
8. Publish in-memory synthesis and statistics.
9. Clear prior alteration and schedule alteration from the new synthesis.
10. Remove staging on all exit paths.

## Failure Contract

For same-input regeneration failure:

- Keep prior `synthesis.wav`.
- Keep prior in-memory synthesis.
- Keep prior alteration and altered file.
- Keep prior statistics.
- Surface a localized shared error.

For input invalidation while generation is active:

- Increment synthesis revision.
- Clear now-stale synthesis, statistics, and alteration.
- Discard the superseded result without publishing it.

## UI Contract

During generation:

- Generate is disabled.
- Text and language controls remain disabled.
- A spinner and estimated generated-audio duration are visible.

After success:

- Duration is based on accepted sample count and rate.
- Token throughput is displayed when statistics exist.

## Smoke-Test Contract

The end-to-end model test runs only when:

```text
MVC_TTS_SMOKE=1
```

Routine focused tests must not download or load model weights.
