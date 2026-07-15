# Feature Specification: Application Shell and Session

**Feature Branch**: `feature/time-machine-application-shell-and-session`

**Created**: 2026-07-15

**Status**: Draft

**Input**: User description: "Feature: Application Shell and Session. Launches a guided five-stage local workflow and coordinates shared state, errors, and working files for each voice-cloning session. Relevant files: App/MacVoiceCloningApp.swift, App/Model/AppModel.swift, App/Model/PipelineState.swift, App/Model/SessionFiles.swift, App/Views/ContentView.swift, App/Views/Components/StageCard.swift. Focus on this feature only; do not modify other features."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Follow One Guided Voice-Cloning Session (Priority: P1)

A user launches the app and sees a single, ordered workspace that guides them from preparing the voice model through recording, writing, synthesis, alteration, and final export without requiring navigation between windows.

**Why this priority**: The shell is the primary entry point and must make the complete workflow understandable before any individual processing feature can deliver value.

**Independent Test**: Launch the app with no prior session and verify that the model status and all five numbered stages appear in order in one scrollable workspace.

**Acceptance Scenarios**:

1. **Given** the app has just launched, **When** the main window appears, **Then** the user sees model status followed by Record, Write, Synthesize, Alter, and Export stages in that order.
2. **Given** the window is smaller than the full workflow height, **When** the user scrolls, **Then** every stage remains reachable in the same order.
3. **Given** the app is running, **When** a stage reads or changes session data, **Then** the other stages reflect the same shared session state.

---

### User Story 2 - Progress Without Using Invalid or Stale Inputs (Priority: P2)

A user progresses through the workflow while the app prevents actions that are not ready and clears downstream results when an upstream voice reference changes.

**Why this priority**: Guarding the workflow prevents invalid synthesis requests and avoids presenting audio that no longer matches the current inputs.

**Independent Test**: Exercise the workflow with missing inputs, then replace a prepared reference after synthesis and verify readiness and downstream results update consistently.

**Acceptance Scenarios**:

1. **Given** the voice model, reference sample, reference transcript, or target text is not ready, **When** the user reaches synthesis, **Then** synthesis cannot begin and the workspace identifies the missing prerequisite.
2. **Given** synthesis is already running, **When** the user attempts to start it again, **Then** no duplicate synthesis begins.
3. **Given** synthesized or altered audio exists, **When** the user replaces the reference sample, **Then** those downstream results are invalidated before another synthesis can begin.
4. **Given** audio is playing, **When** a new synthesis begins, **Then** current playback stops before generation proceeds.

---

### User Story 3 - Recover from Session and Launch Errors (Priority: P3)

A user receives a clear, dismissible explanation when the shell cannot prepare session storage or when a workflow operation fails, while unaffected controls remain usable.

**Why this priority**: Failures must be understandable and recoverable, but they follow the core workflow and readiness behavior in importance.

**Independent Test**: Inject a representative workflow failure and verify that one readable error is shown, can be dismissed, and does not create a second app window or reset unrelated inputs.

**Acceptance Scenarios**:

1. **Given** a workflow operation fails, **When** the failure reaches the shared session, **Then** the main window presents a readable error message.
2. **Given** an error is visible, **When** the user dismisses it, **Then** the message clears and the user can continue with unaffected stages.
3. **Given** the app-owned working directories are absent, **When** the app launches, **Then** it attempts to prepare them before workflow outputs are written.
4. **Given** a model is already available locally, **When** the app launches, **Then** the shell refreshes its availability and begins making it ready without requiring a second launch.

### Edge Cases

- App-owned storage cannot be created because the location is unavailable or permission is denied.
- Launch initialization runs more than once during the same app lifetime.
- A locally available model fails to become ready during launch.
- The user changes an upstream input while downstream processing is pending.
- A stage reports an empty or non-user-readable error description.
- The main window is resized near its minimum supported dimensions.
- No model or prior working files exist on first launch.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The application MUST open a primary window containing one scrollable, ordered voice-cloning workflow.
- **FR-002**: The workflow MUST present model status before five numbered stages: reference recording, target text, synthesis, voice alteration, and final export.
- **FR-003**: All workflow stages MUST observe one shared session so a state change made by one stage is immediately available to the others.
- **FR-004**: On launch, the application MUST prepare its app-owned model and session working locations before they are needed for output.
- **FR-005**: On launch, the application MUST refresh locally available model status and attempt to make an already-downloaded model ready.
- **FR-006**: The application MUST permit synthesis only when the model is ready, a reference sample exists, both required text inputs are non-empty after trimming, and no synthesis is already running.
- **FR-007**: Starting synthesis MUST stop current audio playback before generation begins.
- **FR-008**: Replacing the reference sample MUST invalidate prior synthesized audio, synthesis statistics, altered audio, and obsolete progress.
- **FR-009**: The shared session MUST distinguish source inputs, synthesis output, altered output, preview selection, progress, and processing activity so each stage can present the correct state.
- **FR-010**: The export source MUST resolve to altered audio when alteration produced a result and otherwise to the original synthesized audio.
- **FR-011**: Preview selection MUST respect bypass state by choosing the original synthesis when bypass is active and the altered result when it is available and bypass is inactive.
- **FR-012**: Workflow failures MUST be exposed through one shared user-facing error state and presented as a dismissible message in the primary window.
- **FR-013**: Dismissing an error MUST clear that error without discarding unrelated valid session inputs or outputs.
- **FR-014**: The shell MUST keep text, reference metadata, progress, generated clips, effects, and error state in memory for the current app session.
- **FR-015**: The application shell MUST NOT send session audio, session text, or workflow state to a remote service; one-time model acquisition is handled by a separate feature.

### Key Entities

- **Application Session**: The shared lifetime of one open app workspace, including model lifecycle, pipeline state, recording, and playback coordination.
- **Pipeline State**: The current reference input, target text and language, synthesis activity and result, alteration settings and result, export source, and error state.
- **Reference Sample**: A prepared voice sample identified by its working-file location and duration.
- **Audio Clip**: Generated mono audio samples with a sample rate, working-file location, and derived duration.
- **Workflow Stage**: A numbered user-facing step that consumes shared session state and exposes actions only when its prerequisites are met.

## Scope Boundaries

### In Scope

- Primary app window and ordered stage composition.
- Shared in-memory session and pipeline orchestration.
- Launch preparation, readiness gating, invalidation, preview/export selection, and error presentation.
- App-owned working-location definitions for models and current-session audio.

### Out of Scope

- Model download mechanics and model-specific loading behavior.
- Microphone capture, import conversion, and speech transcription details.
- Speech generation internals.
- Playback implementation, voice-effect processing, and export encoding.
- Persisting or restoring a workflow session across app restarts.
- Multiple simultaneous workflow sessions or multiple document windows.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In usability testing, at least 90% of first-time users can identify the five workflow stages and their order within 10 seconds of opening the app.
- **SC-002**: In every tested prerequisite combination, synthesis is available only when all required inputs are ready and never starts twice concurrently.
- **SC-003**: Replacing a reference sample removes all stale downstream synthesis and alteration results before the user can generate again in 100% of tested cases.
- **SC-004**: A workflow failure produces one readable, dismissible message within one second of the failure reaching the shared session in 100% of tested cases.
- **SC-005**: Dismissing an error preserves all unrelated valid session state in 100% of tested cases.
- **SC-006**: All five stages remain reachable and correctly ordered at the minimum supported window size.
- **SC-007**: Session audio and text remain on the user’s Mac throughout the workflow in 100% of privacy verification checks.

## Assumptions

- The application supports one primary workflow window and one in-memory session at a time.
- Working audio files may be replaced during a session and are not restored as a resumable project after relaunch.
- Individual stages own their specialized user interactions while the shell owns composition and shared orchestration.
- Model acquisition may require network access, but that behavior belongs to the separate model lifecycle feature.
- Existing stage-specific features provide their own detailed progress, empty-state, and error messages where needed.
