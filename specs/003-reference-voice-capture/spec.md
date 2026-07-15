# Feature Specification: Reference Voice Capture

**Feature Branch**: `feature/time-machine-reference-voice-capture`

**Created**: 2026-07-15

**Status**: Draft

**Input**: User description: "Record or import a voice sample, normalize it for cloning, show live input feedback, and prefill an editable on-device transcript."

## User Scenarios & Testing

### User Story 1 - Record a Usable Voice Sample (Priority: P1)

A user grants microphone access, records clear speech while watching live level and elapsed-time feedback, then stops after the minimum usable duration. The application prepares the recording for voice cloning and shows it as ready for preview.

**Why this priority**: A valid voice reference is the required first input for cloning.

**Independent Test**: Start and stop a microphone recording, confirm live level and duration feedback, and verify that a sample of at least three seconds becomes a playable 24 kHz mono reference.

**Acceptance Scenarios**:

1. **Given** microphone access is available, **When** the user starts recording, **Then** recording begins, the action changes to Stop, and live input level and duration update.
2. **Given** recording is active, **When** the user stops after at least three seconds, **Then** the captured audio is normalized and displayed as an accepted reference sample.
3. **Given** recording is active, **When** the user stops before three seconds, **Then** the sample is rejected with a useful duration message.
4. **Given** microphone access is denied, **When** the user attempts to record, **Then** the application explains how to open the relevant System Settings page.

---

### User Story 2 - Import Existing Audio (Priority: P1)

A user selects an audio file already available on the Mac. The application securely reads the selected file, normalizes it into the same reference format as a recording, validates its duration, and displays the accepted sample for preview.

**Why this priority**: Import is a first-class alternative when the user already has a suitable voice sample or cannot record directly.

**Independent Test**: Import a readable stereo or non-24 kHz audio file and verify that the accepted reference is a local 24 kHz mono WAV with the expected duration.

**Acceptance Scenarios**:

1. **Given** the user selects a readable audio file, **When** preparation completes, **Then** the application stores an app-owned normalized reference and reports its duration.
2. **Given** the selected file requires temporary security-scoped access, **When** preparation finishes or fails, **Then** access is relinquished.
3. **Given** preparation is already running, **When** the user attempts another recording or import, **Then** the application prevents a conflicting preparation operation.
4. **Given** conversion fails, **When** the error is reported, **Then** no incomplete prepared file is accepted.

---

### User Story 3 - Review and Edit the Reference Transcript (Priority: P2)

After a reference is accepted, the application attempts an on-device transcription using the selected synthesis language. A successful result prefills an editable transcript; unsupported locales or transcription failures leave the field available for manual entry without invalidating the audio sample.

**Why this priority**: Qwen voice cloning needs the words spoken in the reference, but manual entry remains a reliable fallback.

**Independent Test**: Accept a reference, observe transcription progress, edit the resulting text, and verify that a transcription failure leaves the accepted sample and editable field available.

**Acceptance Scenarios**:

1. **Given** a reference sample is accepted, **When** on-device transcription succeeds, **Then** trimmed text prefills the transcript field.
2. **Given** the user types while transcription is in progress, **When** transcription completes, **Then** the user's non-empty text is preserved.
3. **Given** transcription is unavailable or fails, **When** processing ends, **Then** the transcript remains editable and the audio reference remains accepted.
4. **Given** a newer accepted reference starts transcription, **When** an older transcription task completes, **Then** the older result cannot replace the newer transcript.

---

### User Story 4 - Replace an Existing Reference Safely (Priority: P2)

A user with an accepted reference records or imports a replacement. Preparation happens without exposing a partial file, and downstream synthesis is invalidated only when a new valid reference is committed.

**Why this priority**: Re-recording is common, and failed replacement attempts must not leave mismatched audio, transcript, or synthesis results.

**Independent Test**: Start with a valid reference and synthesis, attempt both a valid and invalid replacement, and verify consistent reference and downstream state in each case.

**Acceptance Scenarios**:

1. **Given** an accepted reference exists, **When** a valid replacement finishes preparation, **Then** the replacement becomes current atomically and results derived from the prior reference are invalidated.
2. **Given** an accepted reference exists, **When** a replacement is too short or cannot be converted, **Then** the previous accepted reference, transcript, synthesis, and alteration remain available.

### Edge Cases

- The default input device disappears or reports no usable channels.
- The realtime audio tap reports a disk write failure.
- A selected audio file is empty, corrupt, or unreadable.
- Conversion returns zero frames or a duration just below the minimum.
- A user stops recording while player audio is active.
- The user edits the transcript while asynchronous transcription is still running.
- Speech support is unavailable for the selected language or required on-device assets cannot be installed.
- A previous transcription completes after a newer reference has been accepted.

## Requirements

### Functional Requirements

- **FR-001**: The system MUST request microphone permission before starting a recording.
- **FR-002**: The system MUST explain how to open microphone privacy settings when permission is denied.
- **FR-003**: The system MUST record from a usable default input device into app-owned session storage.
- **FR-004**: The system MUST expose live normalized input level and elapsed duration while recording.
- **FR-005**: The system MUST stop and clean up the audio tap, engine, polling task, and file before preparing the captured sample.
- **FR-006**: The system MUST allow the user to import supported audio files through the system file importer.
- **FR-007**: The system MUST hold security-scoped file access only while the selected file is being consumed.
- **FR-008**: The system MUST prevent overlapping reference-preparation operations and conflicting Record or Import actions.
- **FR-009**: The system MUST normalize recorded and imported audio to a 24 kHz mono floating-point WAV in app-owned storage.
- **FR-010**: The system MUST reject unreadable, empty, or shorter-than-three-second samples with an actionable error.
- **FR-011**: The system MUST prepare a replacement in a staging file and commit it only after conversion and duration validation succeed.
- **FR-012**: The system MUST never expose a partial staging file as the accepted reference.
- **FR-013**: The system MUST report the accepted sample's duration and offer preview playback.
- **FR-014**: The system MUST start best-effort on-device transcription after accepting a reference.
- **FR-015**: The system MUST select an exact or same-language supported transcription locale before analysis.
- **FR-016**: The system MUST trim a successful transcript before presenting it.
- **FR-017**: The system MUST preserve non-empty user-entered transcript text when asynchronous transcription completes.
- **FR-018**: The system MUST prevent stale transcription results from an older reference from updating current state.
- **FR-019**: The system MUST leave the transcript editable when transcription fails or is unsupported.
- **FR-020**: The system MUST invalidate synthesis and altered results when a new valid reference is accepted.
- **FR-021**: The system MUST surface recording, conversion, and storage errors through the shared user-visible error channel.
- **FR-022**: The system MUST preserve the previous accepted reference, transcript, synthesis, and alteration when replacement preparation fails validation or conversion.

### Key Entities

- **Raw Capture**: Hardware-format recording or user-selected source file awaiting preparation.
- **Prepared Reference**: Validated app-owned 24 kHz mono WAV with duration metadata.
- **Reference Preparation**: Exclusive conversion and validation operation that produces a staging file.
- **Reference Transcript**: Editable text representing the words spoken in the current reference.
- **Transcription Run**: Best-effort asynchronous analysis associated with one accepted reference generation.
- **Input Level Snapshot**: Smoothed zero-to-one meter value and elapsed frame-derived duration.

### Assumptions

- Three seconds is the hard minimum; five to fifteen seconds of clear speech is recommended.
- Recording uses the current default input device and does not provide device selection in this feature.
- Transcription is additive convenience; inability to transcribe does not invalidate usable audio.
- Imported media is copied through normalization, so long-term access to the external source is unnecessary.
- Cancellation controls for conversion and transcription are outside this feature; new conflicting preparation is prevented.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Every accepted reference is readable as a 24,000 Hz mono WAV and reports at least three seconds of duration.
- **SC-002**: Live meter and duration feedback update throughout a recording without blocking user interaction.
- **SC-003**: An overlapping Record or Import action cannot start while reference preparation is active.
- **SC-004**: Invalid or failed preparation never leaves a partial file marked as the accepted reference.
- **SC-005**: Successful transcription prefills trimmed text while preserving any non-empty user edit.
- **SC-006**: Failed or unsupported transcription leaves accepted audio and manual transcript entry usable.
- **SC-007**: A newly accepted reference invalidates all synthesis and alteration derived from its predecessor.
- **SC-008**: Stale transcription completion cannot update state after a newer reference has been accepted.
- **SC-009**: A failed replacement attempt leaves every previously accepted reference-derived value unchanged.
