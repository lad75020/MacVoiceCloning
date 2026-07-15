# Feature Specification: Voice Alteration

**Feature Branch**: `feature/time-machine-voice-alteration`

**Created**: 2026-07-15

**Status**: Draft

**Input**: User description: "Lets users reshape synthesized speech with pitch, speed, timbre, formant, engine, preset, bypass, and automatic preview controls."

## Clarifications

### Session 2026-07-15

- Q: What should Preview play after effect settings change but before the new altered clip finishes? → A: Keep the last successful altered preview.
- Q: If Bypass is enabled while an altered preview is being generated, what should happen? → A: Continue processing in the background.

## User Scenarios & Testing

### User Story 1 - Shape a Synthesized Voice (Priority: P1)

A user can change the pitch, speaking speed, and vocal character of synthesized speech, then preview the transformed result before export.

**Why this priority**: Direct control over the generated voice is the core value of the alteration stage.

**Independent Test**: Provide a synthesized clip, adjust one control at a time, and verify that a replacement preview is produced with the requested audible and duration characteristics.

**Acceptance Scenarios**:

1. **Given** a synthesized clip exists, **When** the user changes pitch, **Then** a new preview is generated at the selected pitch without unintentionally changing duration.
2. **Given** a synthesized clip exists, **When** the user changes speed, **Then** a new preview is generated with the corresponding duration change without unintentionally changing pitch.
3. **Given** the quality engine is selected, **When** the user changes timbre or formant preservation, **Then** the new preview reflects the selected vocal-character controls.
4. **Given** no synthesized clip exists, **When** the alteration stage is displayed, **Then** alteration and preview controls are unavailable.

---

### User Story 2 - Compare and Reset Effects (Priority: P1)

A user can temporarily bypass the effect, choose a named preset, or reset all controls to neutral so that comparison and recovery require no manual reconstruction.

**Why this priority**: Fast comparison and predictable reset behavior are essential for evaluating a transformed voice.

**Independent Test**: Apply a non-neutral effect, toggle bypass, select every preset, and reset; verify that the chosen preview source and visible controls remain consistent.

**Acceptance Scenarios**:

1. **Given** a transformed preview exists, **When** the user enables bypass, **Then** Preview plays the original synthesized clip without discarding the selected effect.
2. **Given** replacement processing is active, **When** the user enables bypass, **Then** processing continues in the background while Preview selects the original synthesis.
3. **Given** bypass is enabled, **When** the user disables bypass, **Then** Preview returns to the latest successfully transformed result.
4. **Given** the user selects a preset, **When** the preset is applied, **Then** all controls adopt that preset's complete settings and one replacement preview is scheduled.
5. **Given** controls are non-neutral, **When** the user selects Reset, **Then** controls return to neutral and the original synthesized clip becomes the effective result.

---

### User Story 3 - Choose Quality or Speed Safely (Priority: P2)

A user can choose between a higher-quality engine and a faster engine while the interface clearly communicates and safely handles controls unsupported by the selected engine.

**Why this priority**: Engine choice enables a useful quality/performance tradeoff without producing misleading controls or stale previews.

**Independent Test**: Switch engines with neutral and non-neutral timbre settings and verify support messaging, processing behavior, and preview consistency.

**Acceptance Scenarios**:

1. **Given** the higher-quality engine is active, **When** timbre is adjusted, **Then** the control is enabled and the resulting preview uses that setting.
2. **Given** a non-neutral timbre is selected, **When** the faster engine is chosen, **Then** the interface disables the unsupported control, explains the limitation, and does not apply the unsupported value.
3. **Given** the user returns to the higher-quality engine, **When** processing resumes, **Then** the selected timbre value is available again.

---

### User Story 4 - Receive the Latest Preview Reliably (Priority: P2)

A user can drag or change several controls rapidly without accumulating obsolete work, hearing stale audio, or blocking the interface.

**Why this priority**: Alteration controls are exploratory and must remain responsive under repeated changes.

**Independent Test**: Make rapid successive changes, cancel work in progress, and inject a processing failure; verify that only the latest requested settings can become the current preview and errors are recoverable.

**Acceptance Scenarios**:

1. **Given** the user changes a continuous control repeatedly, **When** changes occur in quick succession, **Then** obsolete pending work is cancelled or superseded and only the latest settings publish a result.
2. **Given** a prior altered preview exists, **When** replacement processing begins, **Then** the prior preview remains playable until the latest requested result replaces it successfully.
3. **Given** processing is active, **When** the user changes another setting, **Then** the interface remains responsive and clearly indicates processing activity.
4. **Given** processing fails, **When** the failure is reported, **Then** an actionable shared error appears, the last successful preview remains available, and the user can change settings to retry.
5. **Given** preview playback is active, **When** an effect or bypass setting changes, **Then** playback stops before a different preview source can be heard.

### Edge Cases

- The source sample array is empty.
- The sample rate is zero or otherwise invalid.
- Pitch, speed, or timbre values are outside supported ranges or are not finite.
- Neutral settings are selected while an altered result from earlier settings exists.
- The faster engine is selected while a non-neutral timbre value is retained.
- A processing task is cancelled during either analysis or output generation.
- A newer request finishes before an older cancelled request unwinds.
- The processor cannot initialize or returns no output.
- The transformed file cannot be written or replaced.
- The user switches bypass while transformation or playback is active.
- A preset combines several simultaneous control changes.

## Requirements

### Functional Requirements

- **FR-001**: The system MUST expose pitch control from -12 through +12 semitones in whole-semitone steps.
- **FR-002**: The system MUST expose speed control from 0.5× through 2.0×.
- **FR-003**: The system MUST expose timbre/formant scale control from 0.5× through 2.0× when the selected engine supports it.
- **FR-004**: The system MUST expose a formant-preservation choice independently of pitch and speed.
- **FR-005**: The system MUST offer a higher-quality engine and a faster engine with clear user-facing names.
- **FR-006**: Unsupported engine/control combinations MUST be disabled, explained, and ignored during processing without silently mutating the retained user value.
- **FR-007**: The system MUST provide named presets for common voice effects and a Reset action that restores neutral settings.
- **FR-008**: Applying a preset MUST replace the entire effect configuration rather than merging with stale settings.
- **FR-009**: Neutral settings MUST use the original synthesis as the effective result and MUST NOT require an unnecessary transformation.
- **FR-010**: Bypass MUST switch preview playback to the original synthesis without discarding effect settings, the transformed artifact, or alteration work already in progress.
- **FR-011**: Enabling bypass MUST NOT cancel, pause, or reschedule the current latest alteration request; successful background completion MUST be available when bypass is disabled.
- **FR-012**: Effect changes MUST automatically schedule replacement processing after a short settling interval suitable for slider interaction.
- **FR-013**: A newer request MUST supersede pending or active older requests, and only the latest request may publish a transformed clip.
- **FR-014**: The last successfully altered preview MUST remain available while replacement processing is pending and after replacement failure; it MUST be replaced only by a successful result for the latest request.
- **FR-015**: Processing MUST run without blocking interface interaction and MUST expose visible activity state.
- **FR-016**: Effect and bypass changes MUST stop active playback before changing the effective preview source.
- **FR-017**: Processing failures MUST surface an actionable shared error and MUST leave the workflow usable for retry.
- **FR-018**: The generated transformed clip MUST preserve finite samples and the input sample rate.
- **FR-019**: Pitch-only changes MUST preserve duration within a defined processing tolerance; speed changes MUST alter duration according to the selected speed within a defined processing tolerance.
- **FR-020**: Processing MUST remain entirely local and MUST NOT upload voice audio, effect settings, or telemetry.
- **FR-021**: Focused tests MUST cover neutral processing, pitch, speed, both engines, cancellation/supersession, invalid inputs, and unsupported timbre handling.

### Key Entities

- **Effect Configuration**: Pitch, speed, timbre/formant scale, formant-preservation choice, and selected processing engine.
- **Effect Preset**: A named, complete effect configuration that replaces the current configuration when selected.
- **Synthesis Clip**: The original generated audio used as the immutable source for transformations and bypass preview.
- **Altered Clip**: The latest successfully transformed local audio and its matching effect configuration.
- **Alteration Request**: A cancellable request identified by the effect configuration and source generation it represents.
- **Effective Preview**: The clip selected for playback based on bypass state, neutral settings, and availability of a current altered result.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Pitch-only focused tests preserve output duration within 5% and produce the expected frequency shift within 10%.
- **SC-002**: Speed-focused tests produce output duration within 10% of the requested ratio while keeping all samples finite.
- **SC-003**: In rapid-change tests, 100% of published altered clips correspond to the latest requested settings.
- **SC-004**: Neutral settings and bypass select the original synthesis in 100% of focused state tests.
- **SC-005**: All unsupported timbre/engine combinations are visibly explained and ignored safely without losing the retained timbre selection.
- **SC-006**: Focused alteration tests run without model downloads, microphone access, network access, or audible playback.
- **SC-007**: The macOS application builds successfully after alteration contract, orchestration, and interface changes.

## Assumptions

- Automatic preview means automatically regenerating the preview artifact after controls settle; playback still starts only when the user selects Preview.
- Alteration always starts from the original synthesized clip rather than repeatedly processing an already altered clip.
- Presets are built in and are not created, renamed, persisted, imported, or exported by users in this feature.
- The quality engine supports independent timbre/formant scaling; the faster engine does not.
- Export format selection and Finder reveal behavior belong to the separate final-audio-export feature.
- The vendored local processor and its bridge remain the alteration dependency; network services are out of scope.
