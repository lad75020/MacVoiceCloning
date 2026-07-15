# Tasks: Voice Alteration

**Input**: Design documents from `specs/007-voice-alteration/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/alteration.md`, `quickstart.md`

**Tests**: Deterministic focused tests are required by the specification and plan. Add or strengthen tests before implementation and verify the new assertions fail for the intended reason.

**Organization**: Tasks are grouped by user story so each behavior can be implemented and verified independently.

## Phase 1: Setup and Baseline

**Purpose**: Confirm current alteration wiring and preserve pre-existing workspace changes.

- [x] T001 Record baseline focused-test and build outcomes plus the pre-existing asset relocation in `specs/007-voice-alteration/quickstart.md`
- [x] T002 [P] Verify alteration sources, tests, C bridge, and vendored source membership in `project.yml` and `MacVoiceCloning.xcodeproj/project.pbxproj`
- [x] T003 [P] Document the current Rubber Band 4.0 engine/formant/offline API assumptions from `Vendor/rubberband/rubberband/rubberband-c.h` in `specs/007-voice-alteration/research.md`

---

## Phase 2: Foundational Safety

**Purpose**: Establish validated parameters and isolated request staging required by every story.

**⚠️ CRITICAL**: Complete this phase before story implementation.

- [x] T004 Add failing finite/range/sample-rate/identity contract coverage in `Tests/RubberBandProcessorTests.swift`
- [x] T005 Implement effect and processor input validation with actionable localized errors in `App/Alteration/VoiceEffectParameters.swift` and `App/Alteration/RubberBandProcessor.swift`
- [x] T006 [P] Add request-specific altered staging URL and atomic altered-file commit helpers in `App/Model/SessionFiles.swift`
- [x] T007 Verify only the required C interface remains exposed through `App/Support/Bridging-Header.h` and `Vendor/rubberband/rubberband/rubberband-c.h`

**Checkpoint**: Invalid values cannot cross the C boundary, and concurrent requests have isolated local staging destinations.

---

## Phase 3: User Story 1 - Shape a Synthesized Voice (Priority: P1) 🎯 MVP

**Goal**: Produce deterministic local pitch, speed, and vocal-character transformations from the original synthesis.

**Independent Test**: Process deterministic mono sine input with pitch-only, speed-only, formant-preserved, and neutral configurations; verify frequency, duration, finite output, and unchanged sample-rate contracts.

### Tests for User Story 1

- [x] T008 [US1] Add failing pitch-frequency, speed-duration, finite-output, identity-fast-path, and cancellation tests in `Tests/RubberBandProcessorTests.swift`

### Implementation for User Story 1

- [x] T009 [US1] Harden offline study/process/drain behavior, cancellation checks, identity fast path, and empty-output handling in `App/Alteration/RubberBandProcessor.swift`
- [x] T010 [US1] Keep pitch, speed, timbre, and formant-preservation controls aligned with validated product ranges in `App/Views/AlterStageView.swift` and `App/Alteration/VoiceEffectParameters.swift`

**Checkpoint**: Core voice shaping is executable and testable without model downloads, microphone access, network access, or playback.

---

## Phase 4: User Story 2 - Compare and Reset Effects (Priority: P1)

**Goal**: Make bypass, presets, and reset predictable without discarding settings or background work.

**Independent Test**: Apply every preset, reset to neutral, toggle bypass during processing, and verify complete configuration replacement plus correct effective preview selection.

### Tests for User Story 2

- [x] T011 [US2] Add failing preset completeness, reset identity, bypass-source, and bypass-does-not-cancel source contracts in `Tests/RubberBandProcessorTests.swift`

### Implementation for User Story 2

- [x] T012 [US2] Make built-in presets complete deterministic configurations and preserve neutral identity semantics in `App/Alteration/VoiceEffectParameters.swift`
- [x] T013 [US2] Preserve effect settings and active alteration work while bypass changes only preview selection in `App/Model/PipelineState.swift`
- [x] T014 [US2] Keep preset/reset and bypass controls synchronized with pipeline state and stop playback before preview-source changes in `App/Views/AlterStageView.swift`

**Checkpoint**: Users can compare original and altered audio, apply presets, and recover to neutral settings independently of engine-specific behavior.

---

## Phase 5: User Story 3 - Choose Quality or Speed Safely (Priority: P2)

**Goal**: Support R3 quality and R2 speed modes without applying unsupported timbre behavior or losing the retained selection.

**Independent Test**: Process deterministic audio with both engines, select non-neutral timbre under R2, and verify safe ignore/retention plus restoration under R3.

### Tests for User Story 3

- [x] T015 [US3] Add failing R2/R3 option, unsupported-formant, and retained-timbre tests in `Tests/RubberBandProcessorTests.swift`

### Implementation for User Story 3

- [x] T016 [US3] Apply explicit R2 Faster and R3 Finer options while limiting independent formant scale to R3 in `App/Alteration/RubberBandProcessor.swift`
- [x] T017 [US3] Preserve retained timbre state, disable unsupported editing, and present the engine limitation accessibly in `App/Views/AlterStageView.swift` and `App/Alteration/VoiceEffectParameters.swift`

**Checkpoint**: Both engines work locally, and unsupported combinations are visible, reversible, and safe.

---

## Phase 6: User Story 4 - Receive the Latest Preview Reliably (Priority: P2)

**Goal**: Debounce rapid edits, publish only the newest request, and retain the last successful preview during pending or failed replacement work.

**Independent Test**: Supersede multiple requests around processing and file-write boundaries; verify unique staging cleanup, current-revision publication, prior-preview retention, and retryable failure behavior.

### Tests for User Story 4

- [x] T018 [US4] Add failing revision, unique-staging, stale-publication, prior-preview-retention, and failure-retry source contracts in `Tests/RubberBandProcessorTests.swift`

### Implementation for User Story 4

- [x] T019 [US4] Add alteration revision capture, latest-request guards, and stable prior-preview semantics in `App/Model/PipelineState.swift`
- [x] T020 [US4] Write each request through its unique staging URL and atomically publish only the current revision using `App/Model/SessionFiles.swift` and `App/Model/PipelineState.swift`
- [x] T021 [US4] Keep debounced activity, playback stop, stale-preview availability, and shared error presentation coherent in `App/Views/AlterStageView.swift`

**Checkpoint**: Rapid controls cannot publish stale audio, and the last successful preview remains available until a latest replacement succeeds.

---

## Phase 7: Polish and Cross-Cutting Verification

**Purpose**: Regenerate metadata, run authoritative checks, and synchronize design evidence.

- [x] T022 Regenerate `MacVoiceCloning.xcodeproj/project.pbxproj` from `project.yml` only if source membership changed, then verify PBX membership by matching lines rather than raw filename occurrences
- [x] T023 Run focused alteration tests from `specs/007-voice-alteration/quickstart.md` and record real outcomes in `specs/007-voice-alteration/quickstart.md`
- [x] T024 Run the configured XCodeMCP build before canonical CLI verification and record diagnostics in `specs/007-voice-alteration/quickstart.md`
- [x] T025 Run full `xcodebuild` build/tests and the manual local-only behavior checks from `specs/007-voice-alteration/quickstart.md`
- [x] T026 [P] Validate requirement-to-task coverage and remove stale placeholders across `specs/007-voice-alteration/spec.md`, `specs/007-voice-alteration/plan.md`, and `specs/007-voice-alteration/contracts/alteration.md`
- [x] T027 Refresh and inspect the persistent architecture index artifact under `.codebase-memory/graph.db.zst` for the implemented alteration changes

---

## Dependencies and Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies; captures baseline and project wiring.
- **Foundational (Phase 2)**: Depends on Setup and blocks all user stories.
- **US1 (Phase 3)**: Depends on Foundational and delivers the core transformation MVP.
- **US2 (Phase 4)**: Depends on Foundational; integrates with effective preview state but is independently testable.
- **US3 (Phase 5)**: Depends on Foundational and processor contract; can proceed alongside US2 after US1 parameter semantics are stable.
- **US4 (Phase 6)**: Depends on Foundational and the processor result contract from US1; integrates all preview lifecycle behavior.
- **Polish (Phase 7)**: Depends on all desired user-story phases.

### User Story Dependencies

- **US1 (P1)**: Foundational only; MVP.
- **US2 (P1)**: Foundational only for parameter/preset behavior; pipeline integration reuses the preview model.
- **US3 (P2)**: Foundational plus stable effect validation from US1.
- **US4 (P2)**: Stable processor contract from US1 plus staging helper from Foundational.

### Parallel Opportunities

- T002 and T003 can run in parallel after T001.
- T006 can run in parallel with T004-T005 because it touches session-file infrastructure.
- US2 and US3 can proceed in parallel after foundational contracts stabilize.
- T026 can run in parallel with project/index verification once implementation is complete.

## Parallel Example: User Stories 2 and 3

```text
Task: "Implement preset/reset/bypass behavior in App/Alteration/VoiceEffectParameters.swift, App/Model/PipelineState.swift, and App/Views/AlterStageView.swift"
Task: "Implement R2/R3 formant behavior in App/Alteration/RubberBandProcessor.swift, App/Alteration/VoiceEffectParameters.swift, and App/Views/AlterStageView.swift"
```

## Implementation Strategy

### MVP First

1. Complete Setup and Foundational phases.
2. Complete US1 processor and control contracts.
3. Run focused deterministic alteration tests.
4. Stop and validate the core local transformation before orchestration hardening.

### Incremental Delivery

1. Core shaping: validated pitch, speed, and formant processing.
2. Comparison: presets, reset, and non-destructive bypass.
3. Engine safety: R2/R3 behavior and accessible limitations.
4. Reliability: latest-request publication and stable preview lifecycle.
5. Full XCodeMCP, CLI, manual, documentation, and index verification.

## Notes

- Preserve unrelated staged and unstaged asset relocation exactly as found.
- Do not modify vendored Rubber Band implementation unless an executable test proves a wrapper cannot satisfy the contract.
- Keep alteration local and deterministic; do not introduce telemetry, services, model downloads, or audible tests.
- Mark tasks complete only after their stated code or verification artifact exists and has been exercised.
