# Tasks: Final Audio Export

**Input**: Design documents from `specs/008-final-audio-export/`

**Tests**: Focused executable coverage is required by FR-016 and the constitution.

## Phase 1: Setup

- [x] T001 Record baseline exporter behavior, full-test result, and preserved asset relocation in `specs/008-final-audio-export/quickstart.md`
- [x] T002 [P] Verify `App/Export/AudioExporter.swift`, `App/Views/ExportStageView.swift`, `App/Audio/AudioConverting.swift`, `App/Model/PipelineState.swift`, and `Tests/AudioConvertingTests.swift` remain project members

---

## Phase 2: Foundational

- [x] T003 Add focused invalid-clip and destination-publication tests in `Tests/AudioConvertingTests.swift`
- [x] T004 Implement non-empty, positive-rate, finite-sample validation with localized errors in `App/Export/AudioExporter.swift`
- [x] T005 Implement unique same-directory staging, cleanup, and atomic destination publication in `App/Export/AudioExporter.swift`

**Checkpoint**: Invalid audio cannot reach encoders and failed writes cannot truncate an existing destination.

---

## Phase 3: User Story 1 - Save WAV (Priority: P1)

**Goal**: Save the current eligible voice as a fidelity-preserving WAV.

- [x] T006 [US1] Add WAV sample-rate, sample-count, duration, and replacement tests in `Tests/AudioConvertingTests.swift`
- [x] T007 [US1] Route WAV destination writes through the validated asynchronous writer in `App/Export/AudioExporter.swift` and `App/Audio/AudioConverting.swift`

**Checkpoint**: WAV export is readable and fidelity-preserving.

---

## Phase 4: User Story 2 - Save M4A (Priority: P1)

**Goal**: Save a compact readable mono AAC M4A copy.

- [x] T008 [US2] Add M4A readability, finite decode, sample-rate, and duration-tolerance tests in `Tests/AudioConvertingTests.swift`
- [x] T009 [US2] Route AAC M4A writes through validated staging and actionable error propagation in `App/Export/AudioExporter.swift` and `App/Audio/AudioConverting.swift`

**Checkpoint**: M4A export is readable and approximately duration preserving.

---

## Phase 5: User Story 3 - Export Only Current Audio (Priority: P1)

**Goal**: Prevent stale retained previews from being exported for newer visible settings.

- [x] T010 [US3] Add executable current-effect identity and source-selection tests plus pipeline source contracts in `Tests/AudioConvertingTests.swift`
- [x] T011 [US3] Track the effect configuration represented by the latest successful altered clip in `App/Model/PipelineState.swift`
- [x] T012 [US3] Return an export clip only for neutral synthesis or a completed altered result matching current settings in `App/Model/PipelineState.swift`
- [x] T013 [US3] Disable stage-5 save controls while no current clip is eligible or an export is active in `App/Views/ExportStageView.swift`

**Checkpoint**: Pending and failed replacement alterations cannot export stale audio.

---

## Phase 6: User Story 4 - Reveal Successful Export (Priority: P2)

**Goal**: Retain an explicit Finder reveal action for only the latest successful destination.

- [x] T014 [US4] Add save-panel cancellation and successful-target-retention source contracts in `Tests/AudioConvertingTests.swift`
- [x] T015 [US4] Capture an immutable clip before showing the panel and return `nil` without error on cancellation in `App/Export/AudioExporter.swift`
- [x] T016 [US4] Preserve the prior reveal URL on cancellation/failure and update it only after success in `App/Views/ExportStageView.swift`
- [x] T017 [US4] Keep Finder reveal explicit and label it with the last successful filename in `App/Views/ExportStageView.swift`

**Checkpoint**: Finder opens only on user request and always targets the last successful export.

---

## Phase 7: Polish & Verification

- [x] T018 Run focused `AudioConvertingTests`, XCodeMCP build, and full test suite; record exact outcomes in `specs/008-final-audio-export/quickstart.md`
- [x] T019 Launch the built app and smoke-check disabled stage-5 controls without creating new biometric audio; record outcome in `specs/008-final-audio-export/quickstart.md`
- [x] T020 Run local-only security/correctness review, resolve blockers, and validate all spec placeholders/tasks
- [x] T021 Refresh `.codebase-memory/graph.db.zst` and confirm export symbols are searchable

## Dependencies

`T001-T002 → T003-T005 → T006-T009 → T010-T013 → T014-T017 → T018-T021`

User Stories 1 and 2 can be verified independently after foundation. User Story 3 gates final source correctness; User Story 4 depends on successful writes but not a specific format.
