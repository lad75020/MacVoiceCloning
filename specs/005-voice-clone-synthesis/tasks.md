# Tasks: Voice Clone Synthesis

**Input**: Design documents from `specs/005-voice-clone-synthesis/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/synthesis.md`, `quickstart.md`

**Tests**: Fast Swift Testing contracts cover progress, statistics, output validation, and staged file replacement. The existing multi-gigabyte model smoke path remains opt-in.

**Organization**: Tasks are grouped by user story so local generation, feedback, and safe result acceptance remain independently traceable.

## Phase 1: Setup

**Purpose**: Confirm feature scope, ancestry, active pointer, and preservation clarification.

- [x] T001 Confirm branch ancestry, `.specify/feature.json`, and feature artifacts against `specs/005-voice-clone-synthesis/plan.md`
- [x] T002 Confirm failed same-input regeneration preserves prior synthesis and alteration across `specs/005-voice-clone-synthesis/spec.md`, `research.md`, `data-model.md`, and `contracts/synthesis.md`

---

## Phase 2: Foundational Verification

**Purpose**: Record current request, progress, result, Qwen adapter, pipeline acceptance, and gated smoke behavior.

- [x] T003 Create and run a baseline source verifier for `App/TTS/TTSEngine.swift`, `App/TTS/QwenTTSEngine.swift`, `App/Model/PipelineState.swift`, `App/Model/SessionFiles.swift`, and `Tests/TTSSmokeTests.swift` under `/private/var/folders/gq/fj68kcfn2t1fb21qqrt6b44h0000gn/T/hermes-verify-*.py`
- [x] T004 [P] Confirm upstream Qwen3-TTS `onToken` semantics and 12.5 Hz codec rate in `specs/005-voice-clone-synthesis/research.md`

**Checkpoint**: Existing contracts and upstream semantics are explicit before edits.

---

## Phase 3: User Story 1 - Generate Cloned Speech Locally (Priority: P1) 🎯 MVP

**Goal**: Build a coherent local request, validate generated audio, and publish a committed synthesis for downstream use.

**Independent Test**: Exercise valid result acceptance contracts and inspect the Base-model Qwen call with exact request fields.

- [x] T005 [US1] Add typed request validation and generated-result validation in `App/TTS/TTSEngine.swift`
- [x] T006 [US1] Validate request and candidate output around Base-model generation in `App/TTS/QwenTTSEngine.swift`
- [x] T007 [US1] Snapshot boundary-trimmed target text and reference transcript before generation in `App/Model/PipelineState.swift`
- [x] T008 [P] [US1] Add valid and invalid candidate coverage in `Tests/SynthesisContractsTests.swift`
- [x] T009 [P] [US1] Keep all generation local and retain Base-model/load/reference guards in `App/TTS/QwenTTSEngine.swift`

**Checkpoint**: Only valid local Base-model output can advance toward persistence.

---

## Phase 4: User Story 2 - Understand Generation Progress and Speed (Priority: P1)

**Goal**: Report typed monotonic codec-token progress at 12.5 Hz and final token throughput.

**Independent Test**: Exercise progress estimates and throughput without loading model weights.

- [x] T010 [US2] Add `SynthesisProgress` with a 12.5 Hz estimated duration in `App/TTS/TTSEngine.swift`
- [x] T011 [US2] Emit throttled typed progress plus a final remainder callback in `App/TTS/QwenTTSEngine.swift`
- [x] T012 [US2] Consume active-revision progress in `App/Model/PipelineState.swift` and display estimated duration in `App/Views/SynthesizeStageView.swift`
- [x] T013 [P] [US2] Add progress and throughput coverage in `Tests/SynthesisContractsTests.swift`
- [x] T014 [P] [US2] Update typed progress reporting while preserving the opt-in gate in `Tests/TTSSmokeTests.swift`

**Checkpoint**: Long generation has accurate estimated-duration feedback and completion speed.

---

## Phase 5: User Story 3 - Reject Invalid or Superseded Results Safely (Priority: P2)

**Goal**: Prevent malformed, partial, failed, or superseded candidates from replacing accepted output.

**Independent Test**: Exercise candidate validation and file replacement; inspect revision checks and publication ordering.

- [x] T015 [US3] Add exclusive synthesis staging and atomic commit support in `App/Model/SessionFiles.swift`
- [x] T016 [US3] Add a monotonic synthesis revision and gate asynchronous progress and results in `App/Model/PipelineState.swift`
- [x] T017 [US3] Validate, stage, recheck, commit, and only then publish candidate state in `App/Model/PipelineState.swift`
- [x] T018 [P] [US3] Add first-write and replacement commit coverage in `Tests/SynthesisContractsTests.swift`
- [x] T019 [US3] Preserve prior synthesis, statistics, and alteration on same-input generation or persistence failure in `App/Model/PipelineState.swift`
- [x] T020 [US3] Extend and rerun the source verifier for revision guards, transactional ordering, prior-state preservation, staging cleanup, and no-partial-publication under `/private/var/folders/gq/fj68kcfn2t1fb21qqrt6b44h0000gn/T/hermes-verify-*.py`

**Checkpoint**: Accepted output changes atomically and only for current valid work.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validate artifacts, compile, test fast contracts, confirm smoke registration, and refresh structural knowledge.

- [x] T021 [P] Validate placeholders, links, task counts, codec-rate consistency, preservation policy, and whitespace across `specs/005-voice-clone-synthesis/`
- [x] T022 Regenerate `MacVoiceCloning.xcodeproj`, verify `Tests/SynthesisContractsTests.swift` membership, build with XCodeMCP, and run the CLI build in `specs/005-voice-clone-synthesis/quickstart.md`
- [x] T023 Run focused `MacVoiceCloningTests/SynthesisContractsTests` and disabled `MacVoiceCloningTests/TTSSmokeTests` registration using `specs/005-voice-clone-synthesis/quickstart.md`
- [x] T024 Refresh and verify the persistent Codebase Memory artifact at `.codebase-memory/graph.db.zst`

---

## Dependencies & Execution Order

### Phase Dependencies

- Setup has no dependencies.
- Foundational verification depends on Setup.
- User Story 1 depends on the baseline.
- User Story 2 depends on the typed engine boundary.
- User Story 3 depends on candidate validation and typed progress.
- Polish depends on all user stories.

### User Story Dependencies

- **US1**: Establishes valid local candidate generation.
- **US2**: Extends the engine contract with observable progress and statistics.
- **US3**: Governs candidate acceptance and stale-work rejection.

### Parallel Opportunities

- T004 can proceed alongside baseline inspection.
- T008 and T009 cover independent contract and adapter concerns.
- T013 and T014 cover fast and gated test paths independently.
- T018 can be authored while pipeline revision behavior is implemented.
- T021 can run after documentation stabilizes.

## Parallel Example: User Story 3

```text
Task: "Implement revision-gated transactional pipeline acceptance"
Task: "Test first-write and replacement commit behavior"
```

## Implementation Strategy

### MVP First

1. Validate request and generated output.
2. Generate locally through the Base model.
3. Stage and atomically commit a valid current result.

### Incremental Delivery

1. Type progress and correct codec-rate estimation.
2. Add stale-result revision guards.
3. Preserve prior accepted state on failure.
4. Add fast contracts and retain opt-in smoke coverage.
5. Build, test, and refresh Codebase Memory.
