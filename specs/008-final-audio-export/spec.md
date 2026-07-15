# Feature Specification: Final Audio Export

**Feature Branch**: `feature/time-machine-final-audio-export`

**Created**: 2026-07-15

**Status**: Draft

**Input**: User description: "Lets users save the synthesized or altered result as lossless WAV or AAC M4A and reveal the exported file in Finder."

## Clarifications

### Session 2026-07-15

- Q: While a new altered clip is still processing, what should Final Export do? → A: Disable Save As until the latest alteration completes.
- Q: After a successful export, how should Finder reveal behave? → A: Show a Reveal in Finder action.

## User Scenarios & Testing

### User Story 1 - Save the Effective Voice as WAV (Priority: P1)

A user can save the current effective voice as a lossless WAV file to a location selected with the standard macOS save panel.

**Why this priority**: WAV is the fidelity-preserving default and the minimum complete export capability.

**Independent Test**: Provide a finite synthesized clip, choose WAV, export to a temporary destination, and verify that the file is readable, mono, non-empty, and retains the source sample rate and duration within one frame.

**Acceptance Scenarios**:

1. **Given** a synthesis exists and no non-neutral effect is active, **When** the user saves as WAV, **Then** the original synthesis is written to the selected destination.
2. **Given** a current altered result exists, **When** the user saves as WAV, **Then** that altered result is written instead of the synthesis.
3. **Given** no exportable clip exists, **When** stage 5 is displayed, **Then** format and save controls are unavailable.
4. **Given** the user cancels the save panel, **When** control returns to the app, **Then** no file is written and no error is shown.

---

### User Story 2 - Save a Compact AAC M4A Copy (Priority: P1)

A user can choose AAC M4A to create a smaller, broadly playable copy of the current effective voice.

**Why this priority**: A compact shareable format is a stated product requirement alongside lossless WAV.

**Independent Test**: Export a finite clip to M4A, reopen it with AVFoundation, and verify that it contains audio with the expected sample rate and approximately the expected duration.

**Acceptance Scenarios**:

1. **Given** an exportable clip exists, **When** the user chooses M4A and confirms a destination, **Then** a readable AAC audio file is written with an `.m4a` extension.
2. **Given** a previous successful export exists, **When** a later export fails or is cancelled, **Then** the prior successful export/reveal action remains available.
3. **Given** encoding fails, **When** the error returns, **Then** the shared error surface presents an actionable message and the interface remains usable for retry.

---

### User Story 3 - Export Only the Latest Completed Result (Priority: P1)

A user cannot accidentally export stale altered audio while replacement alteration work is pending.

**Why this priority**: The saved file must correspond to the visible settings, not an earlier successful preview retained for auditioning.

**Independent Test**: Start replacement alteration work while an older altered clip exists and verify that Save As remains disabled until the latest request finishes; then verify the newly current clip is selected.

**Acceptance Scenarios**:

1. **Given** a replacement alteration is processing, **When** stage 5 is visible, **Then** Save As is disabled even if an older altered preview remains playable.
2. **Given** replacement processing succeeds, **When** stage 5 updates, **Then** Save As becomes available and exports the latest altered clip.
3. **Given** replacement processing fails, **When** the failure is shown, **Then** Save As remains unavailable for the non-neutral current settings until the user retries successfully or resets to neutral.
4. **Given** the user resets effects to neutral, **When** a synthesis exists, **Then** Save As immediately becomes available for the original synthesis.

---

### User Story 4 - Reveal a Successful Export (Priority: P2)

After saving, a user can explicitly reveal the last successfully exported file in Finder.

**Why this priority**: Users need a convenient handoff without forcing Finder to open after every save.

**Independent Test**: Complete an export, verify a Reveal in Finder action identifies the saved filename, and confirm cancelled or failed exports do not replace that target.

**Acceptance Scenarios**:

1. **Given** export succeeds, **When** stage 5 updates, **Then** a Reveal in Finder action appears with the exported filename.
2. **Given** the user activates Reveal in Finder, **When** Finder opens, **Then** the exported file is selected.
3. **Given** no export has succeeded in the current app session, **When** stage 5 is shown, **Then** no reveal action is displayed.

### Edge Cases

- The clip contains no samples, a non-positive sample rate, or non-finite samples.
- The destination extension does not initially match the selected format.
- The destination already exists and the save panel requests overwrite confirmation.
- The user cancels the save panel.
- The destination becomes unwritable after panel confirmation.
- AAC encoding is unavailable for the selected sample rate.
- Replacement alteration begins while a save panel is already open.
- The source state changes after the export captures its immutable clip value.
- A prior exported file is moved or deleted before Reveal in Finder is used.

## Requirements

### Functional Requirements

- **FR-001**: The system MUST offer WAV and AAC M4A export formats, with WAV selected by default.
- **FR-002**: The system MUST use the standard macOS save panel with a format-appropriate allowed content type and suggested extension.
- **FR-003**: Cancelling the save panel MUST return without writing a file or surfacing an error.
- **FR-004**: WAV export MUST preserve mono samples, source sample rate, finite values, and source duration within one frame.
- **FR-005**: M4A export MUST produce a readable mono AAC file with finite decoded audio and approximately the source duration.
- **FR-006**: Neutral effect settings MUST export the original synthesis.
- **FR-007**: Non-neutral settings MUST export only the latest successfully completed altered result for those settings.
- **FR-008**: Save As MUST be disabled while alteration is active for non-neutral settings, even when a previous altered preview remains available.
- **FR-009**: After failed replacement alteration, Save As MUST remain unavailable until current settings produce a successful result or return to neutral.
- **FR-010**: Export MUST capture an immutable clip before presenting/writing so later pipeline changes cannot mutate the in-flight export.
- **FR-011**: Export encoding and file writing MUST not block the main actor.
- **FR-012**: Export failures MUST surface through the shared actionable error state and leave the workflow usable for retry.
- **FR-013**: A successful export MUST expose an explicit Reveal in Finder action for the saved URL without opening Finder automatically.
- **FR-014**: A cancelled or failed export MUST NOT replace the last successful reveal target.
- **FR-015**: The feature MUST remain entirely local and MUST NOT upload audio, paths, settings, or telemetry.
- **FR-016**: Focused tests MUST cover WAV, M4A, invalid clips, cancellation/no-write contract, source selection, pending-alteration gating, and successful-target retention.

### Key Entities

- **Export Format**: WAV or M4A plus display name, content type, and required extension.
- **Exportable Clip**: An immutable snapshot of the effective current audio, its sample rate, and stable source identity.
- **Export Availability**: Whether the effective current settings have a complete, non-stale clip eligible for saving.
- **Export Result**: The last successfully written local URL shown by Reveal in Finder.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Focused WAV tests preserve sample count and sample rate exactly.
- **SC-002**: Focused M4A tests create a readable file whose decoded duration is within 5% of the source.
- **SC-003**: In 100% of pending/stale alteration state tests, Save As remains unavailable until current audio is ready.
- **SC-004**: Cancelling or failing export never replaces the last successful reveal target.
- **SC-005**: Focused export tests run without model downloads, microphone access, network access, audible playback, save-panel interaction, or Finder interaction.
- **SC-006**: The macOS application builds and the full test suite passes after export changes.

## Assumptions

- The save panel owns overwrite confirmation and destination selection.
- Export does not persist a history beyond the current app session.
- Reveal in Finder is user initiated after a successful export.
- Export uses the in-memory clip snapshot rather than re-reading session WAV files.
- The previous altered preview may remain playable during replacement processing, but it is intentionally ineligible for final export.
