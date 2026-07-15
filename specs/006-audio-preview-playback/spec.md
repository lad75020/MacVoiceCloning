# Feature Specification: Audio Preview Playback

**Feature Branch**: `feature/time-machine-audio-preview-playback`

**Created**: 2026-07-15

**Status**: Draft

**Input**: User description: "Provides mutually exclusive playback controls with progress for reference, synthesized, and altered audio throughout the workflow."

## Clarifications

### Session 2026-07-15

- Q: What should the progress indicator do when playback reaches its natural end? → A: Stay at 100% until replayed.

## User Scenarios & Testing

### User Story 1 - Preview Any Available Audio (Priority: P1)

A user can play an accepted reference sample, generated synthesis, or altered preview from the stage where it is relevant.

**Why this priority**: Auditioning each artifact is essential to deciding whether to proceed or regenerate.

**Independent Test**: Make one clip available at each stage and verify its player starts, reports progress, and stops.

**Acceptance Scenarios**:

1. **Given** an accepted reference exists, **When** the user selects Play in stage 1, **Then** the reference plays and the control changes to Stop.
2. **Given** a synthesis exists, **When** the user selects Play in stage 3, **Then** the synthesis plays and progress becomes visible.
3. **Given** an altered preview or bypass source exists, **When** the user selects Preview in stage 4, **Then** the selected source plays.
4. **Given** no clip exists for a control, **When** the stage renders, **Then** that control is disabled.

---

### User Story 2 - Keep Playback Mutually Exclusive (Priority: P1)

A user hears at most one preview at a time, even when moving between workflow stages.

**Why this priority**: Overlapping reference, synthesis, and altered playback is confusing and prevents meaningful comparison.

**Independent Test**: Start one source, then start another and verify the first backend is stopped before the second starts.

**Acceptance Scenarios**:

1. **Given** one clip is playing, **When** the user starts a different clip, **Then** the first stops and the second becomes current.
2. **Given** the current clip is playing, **When** the user selects its Stop control, **Then** playback ends and current-source state clears.
3. **Given** playback is active, **When** recording begins, generation begins, or an input/effect/bypass change invalidates the preview, **Then** playback stops before work continues.

---

### User Story 3 - Understand and Recover From Playback State (Priority: P2)

A user sees bounded playback progress and receives an actionable error if a file cannot be opened or playback cannot start.

**Why this priority**: Silent playback failure and unbounded progress leave the user unable to tell whether the control worked.

**Independent Test**: Exercise duration normalization, natural completion, backend construction failure, and backend start failure with deterministic fakes.

**Acceptance Scenarios**:

1. **Given** a clip is playing, **When** its current time advances, **Then** visible progress advances monotonically between 0% and 100%.
2. **Given** a source has invalid or unavailable duration metadata, **When** progress is polled, **Then** progress remains safely at 0%.
3. **Given** the file cannot be opened, **When** the user selects Play, **Then** no source becomes current and an actionable error appears.
4. **Given** the backend cannot start, **When** the user selects Play, **Then** no false playing state is published and an actionable error appears.
5. **Given** playback reaches its natural end, **When** completion is detected, **Then** the control returns to Play while progress remains at 100% until replayed or another source is selected.

### Edge Cases

- The requested URL is already playing.
- A different URL is already playing.
- A source file is replaced at the same URL.
- Duration is zero, negative, NaN, or infinite.
- Current time is negative, beyond duration, NaN, or infinite.
- Backend construction throws.
- Backend `play()` returns false.
- The poll task is cancelled while sleeping.
- Effect, bypass, text, language, transcript, reference, or synthesis state changes during playback.

## Requirements

### Functional Requirements

- **FR-001**: The system MUST use one shared playback coordinator for reference, synthesis, and altered previews.
- **FR-002**: Starting a source MUST stop any currently active source first.
- **FR-003**: Selecting the active source MUST stop it rather than restart it.
- **FR-004**: The coordinator MUST publish current source, playing state, and normalized progress.
- **FR-005**: Progress MUST remain finite and bounded from 0 through 1 for all backend time and duration values.
- **FR-006**: Controls MUST display Play or Preview when idle and Stop for the active source.
- **FR-007**: Controls MUST expose visible progress for the active source.
- **FR-008**: Controls MUST be disabled when their source is unavailable.
- **FR-009**: File-open and playback-start failures MUST leave the coordinator stopped and surface an actionable shared error.
- **FR-010**: Recording, reference replacement, generation, input invalidation, effect changes, and bypass changes MUST stop stale playback before continuing.
- **FR-011**: The system MUST poll progress without blocking the main interface.
- **FR-012**: The system MUST cancel progress polling when playback stops or changes source.
- **FR-013**: Natural completion MUST return the control to Play while retaining the completed source and 100% progress until replay or source replacement.
- **FR-014**: Playback tests MUST use deterministic fake backends and MUST NOT emit sound.
- **FR-015**: Playback MUST remain local and MUST NOT upload audio or telemetry.

### Key Entities

- **Playback Source**: URL identifying the one clip currently selected for playback.
- **Playback Backend**: Small local interface exposing duration, current time, playing state, start, and stop.
- **Playback Coordinator**: Shared observable owner of the backend, poll task, source identity, playing state, progress, and errors.
- **Player Control**: Stage-level UI that starts/stops a source and renders progress.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Starting a second source stops the first in 100% of deterministic playback tests.
- **SC-002**: Published progress remains finite and inside 0...1 for all tested invalid and out-of-range inputs.
- **SC-003**: Backend construction and start failures publish no false current/playing state in 100% of tests.
- **SC-004**: Reference, synthesis, and altered stages all expose the shared control when their source exists.
- **SC-005**: Focused playback contracts run without model downloads, microphone access, or audible output.
- **SC-006**: The macOS application builds successfully after the playback contract and UI changes.
