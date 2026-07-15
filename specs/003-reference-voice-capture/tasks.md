# Tasks: Reference Voice Capture

**Input**: Design documents from `specs/003-reference-voice-capture/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/reference-capture.md`, `quickstart.md`

**Tests**: Deterministic audio conversion receives focused Swift Testing coverage. Microphone, permission, live meter, and SpeechAnalyzer behavior use source contracts plus manual acceptance because they depend on hardware and system assets.

**Organization**: Tasks are grouped by user story so recording, import, transcription, and replacement behavior remain independently traceable.

## Phase 1: Setup

**Purpose**: Confirm the stacked branch, active feature pointer, clarification outcome, and scoped source inventory.

- [x] T001 Confirm branch ancestry, `.specify/feature.json`, and feature artifacts against `specs/003-reference-voice-capture/plan.md`
- [x] T002 Confirm the preserve-on-failed-replacement decision across `specs/003-reference-voice-capture/spec.md`, `research.md`, `data-model.md`, and `contracts/reference-capture.md`

---

## Phase 2: Foundational Verification

**Purpose**: Establish a repeatable baseline for the current recording, conversion, transcription, and stage controls.

- [x] T003 Create and run a temporary baseline verifier for `App/Audio/AudioRecorder.swift`, `App/Audio/AudioConverting.swift`, `App/Transcription/ReferenceTranscriber.swift`, `App/Model/PipelineState.swift`, `App/Views/RecordStageView.swift`, and `App/Views/Components/LevelMeterView.swift` under `/private/var/folders/gq/fj68kcfn2t1fb21qqrt6b44h0000gn/T/hermes-verify-*.py`

**Checkpoint**: Existing permission, capture cleanup, normalization, transcription, and user-control contracts are explicitly recorded.

---

## Phase 3: User Story 1 - Record a Usable Voice Sample (Priority: P1) 🎯 MVP

**Goal**: Capture microphone input with live level and elapsed-time feedback, then stop cleanly and prepare only a usable sample.

**Independent Test**: Exercise the source contract and manual microphone flow, confirming permission handling, meter updates, duration, Stop cleanup, and minimum-duration feedback.

- [x] T004 [P] [US1] Verify permission, no-input handling, realtime tap statistics, and deterministic Stop cleanup in `App/Audio/AudioRecorder.swift`
- [x] T005 [US1] Disable Record and Import while reference preparation is active in `App/Views/RecordStageView.swift`
- [x] T006 [P] [US1] Verify meter clamping, recording duration, minimum-duration guidance, and accepted-sample status in `App/Views/RecordStageView.swift` and `App/Views/Components/LevelMeterView.swift`
- [x] T007 [US1] Extend and rerun the temporary verifier for recording lifecycle and preparation-control rules under `/private/var/folders/gq/fj68kcfn2t1fb21qqrt6b44h0000gn/T/hermes-verify-*.py`

**Checkpoint**: Recording interaction cannot conflict with preparation and capture resources always return to idle on Stop.

---

## Phase 4: User Story 2 - Import Existing Audio (Priority: P1)

**Goal**: Securely consume an imported audio file, normalize it through staging, validate it, and commit only a complete app-owned reference.

**Independent Test**: Convert readable and empty inputs, inspect the normalized format, and verify security scope and staging cleanup across success and failure.

- [x] T008 [US2] Add an app-owned prepared-reference staging path in `App/Model/SessionFiles.swift`
- [x] T009 [US2] Guard overlapping preparation, convert through staging, and commit only validated output while preserving previous state on failure in `App/Model/PipelineState.swift`
- [x] T010 [P] [US2] Surface file-importer failures while retaining full asynchronous security-scoped access in `App/Views/RecordStageView.swift`
- [x] T011 [P] [US2] Add empty-input rejection coverage to `Tests/AudioConvertingTests.swift`
- [x] T012 [US2] Extend and rerun the temporary verifier for exclusive preparation, staging cleanup, secure import, and atomic accepted-reference rules under `/private/var/folders/gq/fj68kcfn2t1fb21qqrt6b44h0000gn/T/hermes-verify-*.py`

**Checkpoint**: External input is consumed only within scope and no invalid or partial output replaces the accepted reference.

---

## Phase 5: User Story 3 - Review and Edit the Reference Transcript (Priority: P2)

**Goal**: Prefill a trimmed best-effort on-device transcript without overwriting user text or allowing stale runs to update current state.

**Independent Test**: Inspect locale selection, cancellation, mutation guards, and failure fallback; manually confirm the accepted sample remains usable when transcription is unavailable.

- [x] T013 [P] [US3] Verify exact and same-language locale selection, speech asset installation, trimmed results, and non-fatal failure handling in `App/Transcription/ReferenceTranscriber.swift`
- [x] T014 [US3] Verify prior-task cancellation, cancellation-before-mutation, user-text preservation, and progress reset in `App/Model/PipelineState.swift` with the temporary verifier

**Checkpoint**: Automatic transcript text is additive, generation-safe, and never required for accepting audio.

---

## Phase 6: User Story 4 - Replace an Existing Reference Safely (Priority: P2)

**Goal**: Preserve all valid state after a failed replacement and invalidate downstream state only after a new valid reference commits.

**Independent Test**: Start from a modeled valid reference, inspect failure and success paths, and verify mutation ordering against the reference-capture contract.

- [x] T015 [US4] Verify failed preparation mutates only `lastError` while successful commit updates reference before invalidating synthesis in `App/Model/PipelineState.swift`
- [x] T016 [US4] Extend and rerun the temporary verifier for preserve-on-failure, commit ordering, derived-state invalidation, and stale-transcription prevention under `/private/var/folders/gq/fj68kcfn2t1fb21qqrt6b44h0000gn/T/hermes-verify-*.py`

**Checkpoint**: Reference audio, transcript, synthesis, and alteration remain internally consistent after every replacement attempt.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Validate documentation, compile, run focused tests, and refresh structural knowledge.

- [x] T017 [P] Validate placeholders, links, task completion counts, and whitespace across `specs/003-reference-voice-capture/`
- [x] T018 Build `MacVoiceCloning.xcodeproj` with XCodeMCP, then run the CLI build command in `specs/003-reference-voice-capture/quickstart.md`
- [x] T019 Run `MacVoiceCloningTests/AudioConvertingTests` using the focused command in `specs/003-reference-voice-capture/quickstart.md`
- [x] T020 Refresh and verify the persistent Codebase Memory artifact at `.codebase-memory/graph.db.zst`

---

## Dependencies & Execution Order

### Phase Dependencies

- Setup has no dependencies.
- Foundational verification depends on Setup.
- User Story 1 depends on the baseline verifier.
- User Story 2 depends on the preparation-control guard introduced for User Story 1.
- User Story 3 depends on accepted-reference commit behavior from User Story 2.
- User Story 4 depends on staging and transcript cancellation semantics.
- Polish depends on all user stories.

### User Story Dependencies

- **US1**: Protects capture and controls from concurrent preparation.
- **US2**: Establishes secure staging, validation, and accepted-reference commit.
- **US3**: Runs only after a valid reference commit.
- **US4**: Verifies success and failure consistency across the previous stories.

### Parallel Opportunities

- T004 and T006 inspect distinct recorder and view files.
- T010 and T011 touch independent view and test files after staging design is fixed.
- T013 can run while preparation work proceeds because it is read-only transcription verification.
- T017 can run independently after documentation stabilizes.

## Parallel Example: User Story 2

```text
Task: "Surface importer failures in App/Views/RecordStageView.swift"
Task: "Add empty-input rejection coverage to Tests/AudioConvertingTests.swift"
```

## Implementation Strategy

### MVP First

1. Establish the baseline verifier.
2. Prevent conflicting Record and Import actions.
3. Convert through staging and commit only validated audio.
4. Run focused capture/import verification.

### Incremental Delivery

1. Harden recording controls.
2. Make imports and replacement transactional.
3. Verify transcript generation safety.
4. Validate preservation and downstream invalidation.
5. Build, test, and refresh Codebase Memory.
