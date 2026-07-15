# Feature Specification: Model Download and Loading

**Feature Branch**: `feature/time-machine-model-download-and-loading`

**Created**: 2026-07-15

**Status**: Draft

**Input**: User description: "Feature: Model Download and Loading. Lets users resumably download, load, unload, retry, and inspect the on-device Qwen3-TTS voice model. Relevant files: App/Model/ModelManager.swift, App/TTS/ModelDownloader.swift, App/Views/ModelStatusView.swift, App/Model/SessionFiles.swift. Focus on this feature only; do not modify other features."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Download the Voice Model (Priority: P1)

A user without the required model sees its identity and approximate size, starts the download explicitly, and follows progress until the model is ready for local synthesis.

**Why this priority**: No voice-cloning output can be generated until the model is present and usable.

**Independent Test**: Start with no complete local model, initiate the download, and verify progress advances before the lifecycle reaches ready.

**Acceptance Scenarios**:

1. **Given** no complete model snapshot is present, **When** the model status appears, **Then** the user sees that a download is required, the approximate transfer size, and an explicit Download action.
2. **Given** the user starts the download, **When** files arrive, **Then** the status shows determinate progress from the beginning through completion.
3. **Given** a previous transfer was interrupted, **When** the user retries, **Then** already valid local files are reused and the remaining snapshot is downloaded.
4. **Given** all required model and tokenizer files are available, **When** completion is recorded successfully, **Then** the model is loaded and the status reaches ready.

---

### User Story 2 - Manage Loaded Model Memory (Priority: P2)

A user can load a downloaded model for synthesis and unload it when they want to reclaim memory without deleting the downloaded files.

**Why this priority**: The model consumes substantial memory, so users need a clear distinction between on-disk availability and in-memory readiness.

**Independent Test**: Begin with a complete downloaded model, load it to ready, unload it, and verify the state returns to downloaded while the files remain available.

**Acceptance Scenarios**:

1. **Given** a complete model is on disk but not in memory, **When** the user selects Load, **Then** loading status is shown until the model becomes ready or fails.
2. **Given** the model is ready, **When** the user selects Unload, **Then** model resources are released and the state returns to downloaded.
3. **Given** a complete model is detected at app launch, **When** launch preparation finishes, **Then** the app attempts to load it automatically.
4. **Given** a load or unload operation is active, **When** the status is shown, **Then** controls do not invite a conflicting lifecycle operation.

---

### User Story 3 - Recover From Problems and Inspect Files (Priority: P3)

A user who encounters a download or load problem sees a contextual message, retries the appropriate operation, and can reveal the model location in Finder for inspection.

**Why this priority**: Large downloads and model initialization can fail for environmental reasons; clear recovery prevents reinstalling or manually locating app data.

**Independent Test**: Force a download failure and a load failure separately, verify each message identifies the failed phase, retry, and reveal the model folder.

**Acceptance Scenarios**:

1. **Given** a download fails, **When** failure is reported, **Then** the message identifies download as the failed phase and Retry resumes or restarts the download as appropriate.
2. **Given** a complete download fails to load, **When** the user retries, **Then** the app retries loading rather than downloading the full snapshot again.
3. **Given** any lifecycle state, **When** the user requests the model folder, **Then** Finder opens at the app-owned model location.

---

### Edge Cases

- The model snapshot exists partially but no durable completion evidence exists.
- The primary snapshot completes but the required tokenizer file is absent.
- Writing completion evidence fails after all remote files arrive.
- Progress callbacks arrive very frequently or repeat the same fraction.
- Download or load is invoked again while that operation is already active.
- The model folder does not yet exist when the user reveals it.
- The app relaunches after a completed download but before a successful load.
- Memory release is requested after the engine has already been cleared.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST distinguish not downloaded, downloading, downloaded, loading, ready, and failed model lifecycle states.
- **FR-002**: The status surface MUST show the model identity, approximate download size, and that processing runs locally before the user starts the transfer.
- **FR-003**: The system MUST start the multi-gigabyte model transfer only after an explicit user action.
- **FR-004**: The download operation MUST support resuming or reusing valid files after interruption rather than requiring a clean restart.
- **FR-005**: The status surface MUST report determinate download progress and MUST throttle updates that would not produce a meaningful visible change.
- **FR-006**: The system MUST retrieve the required model snapshot and ensure its required tokenizer asset is available before declaring the download complete.
- **FR-007**: The system MUST treat a snapshot as complete only when required assets exist and durable completion evidence has been written successfully.
- **FR-008**: The system MUST load the model after a successful first download and MUST offer a Load action for a complete model that is not in memory.
- **FR-009**: The system MUST attempt to load a complete downloaded model during app launch.
- **FR-010**: The system MUST prevent duplicate or conflicting load operations while the model is loading or ready.
- **FR-011**: The system MUST allow the user to unload the ready model, release its engine resources, and retain downloaded files.
- **FR-012**: The system MUST label download failures and load failures distinctly with readable diagnostic context.
- **FR-013**: Retry MUST select loading when a complete local model exists and downloading otherwise.
- **FR-014**: The user MUST be able to reveal the app-owned model location in Finder from the model status surface.
- **FR-015**: Model files MUST remain in the user's application-support area and MUST not be uploaded or shared by this feature.
- **FR-016**: A new lifecycle action MUST replace stale failure presentation with the state of the action currently being attempted.

### Key Entities

- **Model Lifecycle**: Current availability and activity state, optional progress fraction, diagnostic message, and loaded engine reference.
- **Model Snapshot**: The on-disk set of model configuration, weights, vocabulary, and tokenizer assets used by local synthesis.
- **Completion Evidence**: Durable local evidence written only after all required snapshot assets are ready; used to distinguish a complete model from a partial transfer.
- **Model Location**: App-owned application-support directory containing downloaded model snapshots.

## Assumptions

- The application supports one fixed voice-model family and one compatible tokenizer source for this feature.
- Snapshot transport and integrity checking are provided by the model-hosting client already used by the application.
- Resumption occurs when the user retries or relaunches; an in-session Cancel button is outside this feature.
- Unloading releases memory but intentionally does not delete downloaded model files.
- Model download requires network access; model loading and later synthesis are local.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In acceptance testing, every lifecycle state presents exactly one appropriate primary action or progress indicator, with no conflicting controls.
- **SC-002**: Interrupted-download testing completes successfully on retry without requiring the model directory to be deleted first.
- **SC-003**: A complete downloaded model reaches ready automatically after launch or within one explicit Load action.
- **SC-004**: Unloading returns the lifecycle to downloaded and removes the in-memory engine reference in every tested run.
- **SC-005**: Download and load failures identify the failed phase and expose Retry within one status update.
- **SC-006**: A partial snapshot missing either the tokenizer asset or durable completion evidence is never reported as complete.
- **SC-007**: Revealing the model folder opens the app-owned location in Finder in every lifecycle state.
