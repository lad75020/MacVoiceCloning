# Feature Specification: Voice Clone Synthesis

**Feature Branch**: `feature/time-machine-voice-clone-synthesis`

**Created**: 2026-07-15

**Status**: Draft

**Input**: User description: "Generates speech locally with Qwen3-TTS and MLX from the reference voice, transcript, language, and target text while reporting progress and speed."

## Clarifications

### Session 2026-07-15

- Q: If regeneration fails after a valid synthesis already exists, what should happen to the accepted synthesis and its derived alteration? → Preserve both the previous synthesis and its accepted alteration.

## User Scenarios & Testing

### User Story 1 - Generate Cloned Speech Locally (Priority: P1)

A user with a loaded Base voice-cloning model, accepted reference voice, reference transcript, language, and target text generates speech without sending voice or text data off the Mac.

**Why this priority**: Producing cloned speech is the core product outcome.

**Independent Test**: Supply valid inputs to an isolated engine boundary and confirm a non-empty finite mono result with a positive sample rate is accepted and persisted as the session synthesis.

**Acceptance Scenarios**:

1. **Given** the Base model is loaded and every synthesis input is valid, **When** the user generates speech, **Then** the app passes a coherent snapshot of target text, language, reference audio, and transcript to Qwen3-TTS.
2. **Given** Qwen3-TTS returns valid finite samples, **When** generation completes, **Then** the app persists them as a playable mono WAV and exposes their duration.
3. **Given** generation succeeds, **When** the app accepts the result, **Then** downstream alteration starts from the new synthesis and no older altered result remains exportable.
4. **Given** all work is local, **When** generation runs, **Then** no reference audio, transcript, target text, or synthesized audio is uploaded.

---

### User Story 2 - Understand Generation Progress and Speed (Priority: P1)

A user can tell that a potentially long-running generation is active, see an estimate of audio produced, and inspect throughput when it completes.

**Why this priority**: Local ML generation can take minutes, so visible feedback is essential.

**Independent Test**: Feed token callbacks into the engine adapter and confirm monotonic progress estimates based on the model codec rate, then verify token-throughput statistics from elapsed time.

**Acceptance Scenarios**:

1. **Given** generation is active, **When** codec tokens are produced, **Then** the stage reports a monotonic estimated generated-audio duration.
2. **Given** the model uses a 12.5 Hz codec rate, **When** token progress is converted to seconds, **Then** the estimate uses 12.5 tokens per second rather than an arbitrary divisor.
3. **Given** generation completes, **When** statistics are available, **Then** the stage displays generated tokens per elapsed second.
4. **Given** generation is active, **When** the user inspects the controls, **Then** another generation cannot start and request-defining inputs remain locked.

---

### User Story 3 - Reject Invalid or Superseded Results Safely (Priority: P2)

A user never receives an empty, non-finite, malformed, or stale synthesis as a successful result.

**Why this priority**: Invalid samples can break playback/export, while stale asynchronous results can contradict current inputs.

**Independent Test**: Exercise pure output validation with empty samples, non-finite samples, invalid rates, and a valid clip; inspect revision guards and staged file replacement.

**Acceptance Scenarios**:

1. **Given** the backend returns no samples, a non-positive sample rate, or NaN/infinite samples, **When** the app validates the result, **Then** it reports generation failure and does not accept or persist the malformed output.
2. **Given** request-defining state changes while generation is underway through a non-UI path, **When** the earlier result returns, **Then** the stale result is discarded.
3. **Given** a valid new result is ready, **When** it is persisted, **Then** the app stages the WAV and atomically replaces the accepted synthesis.
4. **Given** staging or commit fails, **When** the error is reported, **Then** no partial synthesis becomes playable or exportable.
5. **Given** a prior synthesis and alteration exist, **When** replacement generation, validation, staging, or commit fails, **Then** both prior accepted clips remain playable and exportable.

### Edge Cases

- The engine is called before its model is loaded.
- The loaded model is not a Base voice-cloning model.
- The reference WAV cannot be read, has the wrong sample rate, or is shorter than three seconds.
- Qwen3-TTS emits no codec tokens or throws during generation.
- Generated samples are empty, non-finite, or paired with a non-positive sample rate.
- The target text or language changes through code while generation is active.
- A previous synthesis exists when a replacement generation or disk write fails.
- The output directory is unavailable or the staged WAV cannot be committed.

## Requirements

### Functional Requirements

- **FR-001**: The system MUST require a loaded engine, accepted reference audio, non-empty boundary-trimmed reference transcript, and non-empty boundary-trimmed target text before generation.
- **FR-002**: The system MUST generate through the local Qwen3-TTS Base model running with MLX.
- **FR-003**: The request MUST snapshot target text, selected language, reference URL, and boundary-trimmed reference transcript before asynchronous generation begins.
- **FR-004**: The engine MUST reject invocation before model loading with an actionable error.
- **FR-005**: The engine MUST reject reference audio with an unexpected sample rate or duration below three seconds.
- **FR-006**: The engine MUST pass the exact Qwen3-TTS language raw value and configured token limit to voice-clone generation.
- **FR-007**: Progress MUST be derived monotonically from emitted codec-token count using the model's 12.5 Hz codec rate.
- **FR-008**: Completion statistics MUST include generated token count, elapsed generation time, and derived tokens per second.
- **FR-009**: A synthesis result MUST contain at least one finite sample and a positive sample rate before acceptance.
- **FR-010**: The system MUST stage a valid synthesis WAV and atomically commit it before publishing new synthesis state.
- **FR-011**: The system MUST discard a result whose request-defining inputs were invalidated while generation was active.
- **FR-012**: The system MUST permit only one active generation and MUST prevent UI mutation of request-defining controls during that generation.
- **FR-013**: Successful acceptance MUST clear any previous alteration and schedule alteration from the new synthesis.
- **FR-014**: A failure MUST surface through shared error state, MUST NOT expose partial or malformed output as successful, and MUST preserve the previous accepted synthesis and alteration.
- **FR-015**: All reference processing, model inference, output validation, and persistence MUST remain on-device.
- **FR-016**: New synthesis state, statistics, and downstream alteration MUST publish only after the candidate WAV commits successfully; until then, the previous synthesis and alteration MUST remain accepted.
- **FR-017**: Interactive smoke generation MUST remain opt-in because it can download a multi-gigabyte model and run for an extended period.

### Key Entities

- **Synthesis Request**: Immutable snapshot of target text, language, reference URL, reference transcript, and maximum token count.
- **Generation Progress**: Monotonic estimate derived from emitted codec-token count at 12.5 tokens per second.
- **Synthesis Statistics**: Generated token count, generation elapsed time, and throughput.
- **Candidate Synthesis**: Backend sample buffer and sample rate awaiting validation and persistence.
- **Accepted Synthesis**: Valid committed WAV plus in-memory finite samples used by playback, alteration, and export.
- **Synthesis Revision**: Monotonic pipeline version that prevents superseded asynchronous work from publishing stale results.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Valid local model output becomes a committed playable synthesis with duration derived from exact sample count and rate.
- **SC-002**: Empty, non-finite, and invalid-rate outputs are rejected in 100% of focused validation cases.
- **SC-003**: Progress estimates use 12.5 emitted codec tokens per second and never decrease within one generation.
- **SC-004**: A superseded generation publishes no synthesis, statistics, alteration, or accepted WAV.
- **SC-005**: A successful generation exposes positive throughput when generated token count and elapsed time are positive.
- **SC-006**: Focused tests run without downloading or loading the multi-gigabyte model; end-to-end inference remains explicitly gated.

## Assumptions

- The selected Qwen3-TTS snapshot is the Base model required for reference-voice cloning.
- Qwen3-TTS emits one top-level codec token per 1/12.5 second of generated audio.
- The backend currently performs blocking synchronous generation on a dedicated serial executor and does not expose reliable cooperative cancellation.
- Audio preview behavior is specified separately under Audio Preview Playback.
- Alteration parameter behavior is specified separately under Voice Alteration.
