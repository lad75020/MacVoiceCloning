# Research: Voice Alteration

## Decision 1: Keep Rubber Band offline two-pass processing

**Decision**: Continue using the vendored Rubber Band 4.0.0 C API in offline mode with `study` followed by `process`, bounded blocks, expected input duration, and explicit draining.

**Rationale**: The feature transforms a complete generated clip rather than a live stream. Offline analysis provides the existing quality behavior, supports both R2 and R3 engines, and avoids adding a second audio engine.

**Alternatives considered**:

- Live shifter API: rejected because it targets real-time block processing and does not match file-preview generation.
- AVAudioUnit-only effects: rejected because independent time stretch, pitch, and formant behavior would diverge from the current product contract.
- External service: rejected because audio must remain local.

## Decision 2: Validate before crossing the C boundary

**Decision**: Reject non-positive sample rates, non-finite values, and parameter values outside product ranges before creating a Rubber Band state.

**Rationale**: Swift cannot rely on the C API to report every invalid numeric combination safely. Explicit validation produces deterministic errors and protects calculations such as reciprocal speed and exponential pitch scale.

**Alternatives considered**:

- Clamp silently: rejected because hidden corrections make tests and UI state disagree.
- Trust UI ranges: rejected because tests and future callers can construct values directly.

## Decision 3: Preserve R2/R3 semantics explicitly

**Decision**: Use R3 Finer for quality/formant-scale processing and R2 Faster for speed. Retain a user's formant-scale value while R2 is selected, but do not apply it until R3 is selected again.

**Rationale**: The vendored API exposes distinct Faster and Finer engine options. The existing interface already disables and explains independent timbre control under R2; retaining the value supports reversible engine comparison.

**Alternatives considered**:

- Reset formant scale when switching to R2: rejected because it destroys user intent.
- Apply formant scale under R2 anyway: rejected because the product declares it unsupported.
- Remove engine selection: rejected because the feature explicitly requires the quality/speed tradeoff.

## Decision 4: Revision-gated publication with unique staging files

**Decision**: Give every scheduled alteration a monotonically increasing revision and request-specific staging URL. Commit and publish only if the revision is still current after processing and WAV writing.

**Rationale**: Task cancellation is cooperative. An older request can finish after cancellation or while a newer request is running; a shared staging file would allow cross-request replacement. Revision checks plus unique staging isolate work and prevent stale results.

**Alternatives considered**:

- Cancellation alone: rejected because cancellation can race with non-cancellable file I/O.
- Serialize all requests: rejected because obsolete slider work would delay the latest preview.
- Write every request directly to the stable URL: rejected because failed, cancelled, or stale work could corrupt the current preview.

## Decision 5: Keep last successful preview during replacement

**Decision**: Retain the prior altered clip while newer non-neutral settings process and after replacement failure. Replace it only after the latest request succeeds. Identity settings select the original synthesis.

**Rationale**: This is the user's clarification. It preserves an auditionable result during interactive edits while the processing indicator communicates that a newer preview is pending.

**Alternatives considered**:

- Clear or disable Preview: rejected by user choice.
- Fall back to synthesis while processing: rejected because it makes the source change unexpectedly without bypass.

## Decision 6: Bypass is orthogonal to processing

**Decision**: Bypass changes playback source and stops active playback, but does not cancel, pause, or reschedule the latest alteration request.

**Rationale**: This is the user's clarification. The transformed result remains ready when bypass is turned off, and expensive work is not repeated.

**Alternatives considered**:

- Cancel on bypass: rejected by user choice and would require regeneration when comparing again.
- Pause/restart: rejected because offline processing has no useful resumable checkpoint contract here.

## Decision 7: Verify algorithm and orchestration separately

**Decision**: Use focused executable Swift tests for parameter and processor behavior, plus a deterministic orchestration/source contract if importing the entire `PipelineState` into the focused test target would pull model and transcription dependencies beyond feature scope.

**Rationale**: Processor correctness needs real execution against the vendored library; publication policy needs deterministic validation without model downloads or microphone/network access.

**Alternatives considered**:

- End-to-end model synthesis for every test: rejected as slow, non-deterministic, and out of feature scope.
- UI-only verification: rejected because cancellation and numeric edge cases are not reliably observable manually.
