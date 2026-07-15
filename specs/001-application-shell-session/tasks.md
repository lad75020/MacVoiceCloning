# Tasks: Application Shell and Session

**Input**: Design documents from `specs/001-application-shell-session/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/workflow-shell.md`, `quickstart.md`

**Tests**: The plan requires a full macOS build, existing fast unit tests, and focused ad-hoc contract verification. The multi-gigabyte model smoke test is outside this feature’s default gate.

**Organization**: Tasks are grouped by user story so each behavior slice can be reviewed and verified independently.

## Phase 1: Setup and Baseline

**Purpose**: Confirm the retro-specification points at the intended branch, sources, and current behavior before making a surgical correction.

- [x] T001 Confirm branch, feature pointer, and scoped source inventory against specs/001-application-shell-session/plan.md and .specify/feature.json
- [x] T002 Record any implementation-to-contract discrepancy found in App/Model/AppModel.swift or App/Model/PipelineState.swift in specs/001-application-shell-session/research.md before editing

---

## Phase 2: Foundational Contract Guard

**Purpose**: Establish a repeatable focused check for the shared shell invariants used by every user story.

- [x] T003 Create and run a temporary source-contract verifier for App/MacVoiceCloningApp.swift, App/Model/AppModel.swift, App/Model/PipelineState.swift, App/Views/ContentView.swift, and App/Views/Components/StageCard.swift under /private/var/folders/gq/fj68kcfn2t1fb21qqrt6b44h0000gn/T/hermes-verify-*.py

**Checkpoint**: Baseline shell ownership, stage order, readiness, and error-channel behavior are explicitly checked.

---

## Phase 3: User Story 1 — Follow One Guided Voice-Cloning Session (Priority: P1) 🎯 MVP

**Goal**: Preserve one shared session and the ordered, scrollable five-stage workflow.

**Independent Test**: Launch or inspect the primary window and verify model status precedes Record, Write, Synthesize, Alter, and Export stages, all receiving the same environment session.

- [x] T004 [P] [US1] Verify and preserve the single primary-window entry point in App/MacVoiceCloningApp.swift
- [x] T005 [P] [US1] Verify and preserve shared AppModel environment injection and ordered stage composition in App/Views/ContentView.swift
- [x] T006 [US1] Verify numbered stage presentation remains reusable and native in App/Views/Components/StageCard.swift

**Checkpoint**: User Story 1 is independently demonstrable without changing specialized stage implementations.

---

## Phase 4: User Story 2 — Progress Without Invalid or Stale Inputs (Priority: P2)

**Goal**: Preserve synthesis readiness, playback coordination, downstream invalidation, and preview/export selection.

**Independent Test**: Evaluate all prerequisite combinations, trigger synthesis while playback is active, and replace a reference after synthesis; verify no duplicate work or stale result remains available.

- [x] T007 [P] [US2] Verify synthesis readiness and stop-before-synthesize orchestration against specs/001-application-shell-session/contracts/workflow-shell.md in App/Model/AppModel.swift
- [x] T008 [P] [US2] Verify reference invalidation, alteration cancellation, and preview/export clip selection against specs/001-application-shell-session/contracts/workflow-shell.md in App/Model/PipelineState.swift
- [x] T009 [US2] Extend and rerun the temporary source-contract verifier for readiness and invalidation rules in /private/var/folders/gq/fj68kcfn2t1fb21qqrt6b44h0000gn/T/hermes-verify-*.py

**Checkpoint**: User Story 2 contract checks pass without expanding model, synthesis, playback, alteration, or export internals.

---

## Phase 5: User Story 3 — Recover from Session and Launch Errors (Priority: P3)

**Goal**: Surface launch storage-preparation failures through the existing shared alert while preserving unrelated session state and model refresh.

**Independent Test**: Inspect and exercise the launch failure path; verify a readable shared error is produced, model availability still refreshes, and dismissing the alert clears only the error.

- [x] T010 [US3] Replace silent launch directory-preparation failure handling with shared pipeline error propagation in App/Model/AppModel.swift
- [x] T011 [P] [US3] Verify dismissing the shared alert clears only PipelineState.lastError in App/Views/ContentView.swift
- [x] T012 [P] [US3] Verify app-owned model/session location preparation remains centralized in App/Model/SessionFiles.swift
- [x] T013 [US3] Extend and rerun the temporary source-contract verifier for launch error propagation in /private/var/folders/gq/fj68kcfn2t1fb21qqrt6b44h0000gn/T/hermes-verify-*.py

**Checkpoint**: Launch preparation failures are visible and recoverable through the existing shell error channel.

---

## Phase 6: Polish and Cross-Cutting Verification

**Purpose**: Validate artifacts, buildability, regression safety, privacy boundaries, and graph freshness.

- [x] T014 [P] Reconcile final behavior and manual acceptance steps across specs/001-application-shell-session/spec.md, specs/001-application-shell-session/plan.md, and specs/001-application-shell-session/quickstart.md
- [x] T015 [P] Validate placeholders, relative links, task completion counts, and whitespace across specs/001-application-shell-session/
- [x] T016 Build the MacVoiceCloning scheme from MacVoiceCloning.xcodeproj using the command in specs/001-application-shell-session/quickstart.md
- [x] T017 Run AudioConvertingTests and RubberBandProcessorTests from Tests/ using the focused command in specs/001-application-shell-session/quickstart.md
- [x] T018 Refresh and verify the persistent codebase-memory artifact at .codebase-memory/graph.db.zst after all source verification passes

---

## Dependencies and Execution Order

### Phase Dependencies

- **Setup and Baseline (Phase 1)**: Starts immediately.
- **Foundational Contract Guard (Phase 2)**: Depends on Phase 1.
- **User Story 1 (Phase 3)**: Depends on Phase 2.
- **User Story 2 (Phase 4)**: Depends on Phase 2 and may proceed after User Story 1 review.
- **User Story 3 (Phase 5)**: Depends on Phase 2; its AppModel edit should follow the User Story 2 AppModel review.
- **Polish (Phase 6)**: Depends on all selected user stories.

### User Story Dependency Graph

```text
US1 (shared window/session)
 └── US2 (readiness and invalidation)
      └── US3 (launch error recovery)
```

### Parallel Opportunities

- T004 and T005 touch separate entry/composition files and can be reviewed in parallel.
- T007 and T008 inspect separate state owners and can run in parallel.
- T011 and T012 inspect separate alert/storage boundaries and can run in parallel after T010.
- T014 and T015 can run in parallel after source behavior is final.

## Parallel Execution Examples

### User Story 1

```text
Task A: Verify App/MacVoiceCloningApp.swift single-window entry.
Task B: Verify App/Views/ContentView.swift shared environment and stage order.
```

### User Story 2

```text
Task A: Verify App/Model/AppModel.swift readiness and playback coordination.
Task B: Verify App/Model/PipelineState.swift invalidation and clip selection.
```

### User Story 3

```text
After App/Model/AppModel.swift is corrected:
Task A: Verify App/Views/ContentView.swift alert dismissal semantics.
Task B: Verify App/Model/SessionFiles.swift location ownership.
```

## Implementation Strategy

### MVP First

1. Complete Phases 1–2.
2. Complete User Story 1 and confirm the five-stage shell contract.
3. Stop for a review checkpoint if only the visible guided workflow is required.

### Incremental Delivery

1. Preserve the shared shell and stage order (US1).
2. Prove readiness and stale-data protections (US2).
3. Correct launch failure visibility (US3).
4. Run docs, build, fast tests, and codebase-memory verification.

## Notes

- Keep edits surgical; this feature is predominantly a retro-specification of existing behavior.
- Do not modify specialized model, capture, transcription, synthesis, playback, alteration, or export internals.
- Temporary `hermes-verify-*` scripts must be cleaned after execution and reported as ad-hoc verification, not as a full suite result.
- Mark tasks `[x]` only after the named file or command has been verified.
