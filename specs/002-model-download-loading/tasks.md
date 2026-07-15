# Tasks: Model Download and Loading

**Input**: Design documents from `specs/002-model-download-loading/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/model-lifecycle.md`, `quickstart.md`

**Tests**: Focused tests are required for local snapshot completeness. Network transfer and multi-gigabyte model loading remain manual acceptance paths.

**Organization**: Tasks are grouped by user story so each lifecycle outcome can be implemented and verified independently.

## Phase 1: Setup

**Purpose**: Confirm the stacked branch, active feature pointer, design artifacts, and existing lifecycle baseline.

- [x] T001 Confirm the stacked branch ancestry, feature pointer, and scoped source inventory against `specs/002-model-download-loading/plan.md` and `.specify/feature.json`
- [x] T002 Record implementation gaps for completion evidence and Finder reveal behavior in `specs/002-model-download-loading/research.md` before source edits

---

## Phase 2: Foundational Verification

**Purpose**: Establish a repeatable source-contract baseline before modifying lifecycle behavior.

- [x] T003 Create and run a temporary baseline verifier for `App/Model/ModelManager.swift`, `App/TTS/ModelDownloader.swift`, `App/Views/ModelStatusView.swift`, and `App/Model/SessionFiles.swift` under `/private/var/folders/gq/fj68kcfn2t1fb21qqrt6b44h0000gn/T/hermes-verify-*.py`

**Checkpoint**: Existing state transitions, progress throttling, retry selection, app-owned storage, and status controls are explicitly checked.

---

## Phase 3: User Story 1 - Download the Voice Model (Priority: P1) 🎯 MVP

**Goal**: Download the fixed model resumably, report meaningful progress, ensure the tokenizer, and persist trustworthy completion evidence.

**Independent Test**: Use an isolated temporary models root to verify incomplete, tokenizer-only, marker-only, and complete snapshot states without network access.

- [x] T004 [US1] Add local snapshot completeness cases to `Tests/ModelDownloaderTests.swift`
- [x] T005 [US1] Replace best-effort completion-marker creation with a throwing atomic write in `App/TTS/ModelDownloader.swift`
- [x] T006 [P] [US1] Verify progress throttling and download-to-load state transitions against `specs/002-model-download-loading/contracts/model-lifecycle.md` in `App/Model/ModelManager.swift`
- [x] T007 [P] [US1] Verify model identity, approximate size, determinate progress, and Download control mapping in `App/Views/ModelStatusView.swift`
- [x] T008 [US1] Extend and rerun the temporary verifier for tokenizer and atomic completion-evidence rules under `/private/var/folders/gq/fj68kcfn2t1fb21qqrt6b44h0000gn/T/hermes-verify-*.py`

**Checkpoint**: A snapshot is complete only when tokenizer and atomically persisted completion evidence exist.

---

## Phase 4: User Story 2 - Manage Loaded Model Memory (Priority: P2)

**Goal**: Load complete snapshots, auto-load at launch, prevent conflicting load operations, and unload memory without deleting files.

**Independent Test**: Inspect lifecycle transitions and build the app; verify ready stores an engine and unload clears it while returning to downloaded.

- [x] T009 [P] [US2] Verify load guards, successful engine assignment, failure cleanup, and unload state restoration in `App/Model/ModelManager.swift`
- [x] T010 [P] [US2] Verify downloaded, loading, ready, Load, and Unload status mappings in `App/Views/ModelStatusView.swift`
- [x] T011 [US2] Extend and rerun the temporary verifier for launch auto-load and memory lifecycle rules in `App/Model/AppModel.swift` and `App/Model/ModelManager.swift`

**Checkpoint**: On-disk availability remains distinct from in-memory readiness and unload retains downloaded files.

---

## Phase 5: User Story 3 - Recover From Problems and Inspect Files (Priority: P3)

**Goal**: Retry the correct operation after failure and reveal an existing app-owned model location in Finder.

**Independent Test**: Verify retry branches on local completeness and reveal selects the model snapshot when present or models root before download.

- [x] T012 [US3] Add an existing-location fallback for Finder reveal in `App/Model/ModelManager.swift`
- [x] T013 [P] [US3] Verify phase-specific download/load failures and completeness-based retry selection in `App/Model/ModelManager.swift`
- [x] T014 [US3] Extend and rerun the temporary verifier for Retry and Finder fallback rules under `/private/var/folders/gq/fj68kcfn2t1fb21qqrt6b44h0000gn/T/hermes-verify-*.py`

**Checkpoint**: Failure recovery chooses the correct lifecycle operation and Finder always receives an existing app-owned location.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Regenerate project metadata, validate documentation, build, test, and refresh structural knowledge.

- [x] T015 Regenerate `MacVoiceCloning.xcodeproj` from `project.yml` so `Tests/ModelDownloaderTests.swift` is included
- [x] T016 [P] Validate placeholders, relative links, task completion counts, and whitespace across `specs/002-model-download-loading/`
- [x] T017 Build `MacVoiceCloning.xcodeproj` with XCodeMCP, then run the CLI build command from `specs/002-model-download-loading/quickstart.md`
- [x] T018 Run `MacVoiceCloningTests/ModelDownloaderTests` using the focused command in `specs/002-model-download-loading/quickstart.md`
- [x] T019 Refresh and verify the persistent Codebase Memory artifact at `.codebase-memory/graph.db.zst`

---

## Dependencies & Execution Order

### Phase Dependencies

- Setup has no dependencies.
- Foundational verification depends on Setup.
- User Story 1 depends on the baseline verifier and provides completion semantics used by later stories.
- User Story 2 depends on User Story 1's complete-snapshot invariant.
- User Story 3 depends on the same completeness invariant and can then finalize recovery behavior.
- Polish depends on all user stories.

### User Story Dependencies

- **US1**: Establishes trustworthy on-disk completion.
- **US2**: Consumes a complete snapshot and manages its in-memory engine.
- **US3**: Uses completeness to choose retry behavior and safely exposes storage in Finder.

### Parallel Opportunities

- T006 and T007 touch different files and can run in parallel after T005.
- T009 and T010 are independent inspections of manager and view mappings.
- T013 can run while T012 is implemented because it inspects separate methods in the same file only if edits are coordinated.
- T016 can run independently after documentation stabilizes.

## Parallel Example: User Story 1

```text
Task: "Verify progress and download transitions in App/Model/ModelManager.swift"
Task: "Verify identity, size, progress, and controls in App/Views/ModelStatusView.swift"
```

## Implementation Strategy

### MVP First

1. Establish the baseline verifier.
2. Add local completeness tests.
3. Make completion evidence atomic and throwing.
4. Run User Story 1 verification.

### Incremental Delivery

1. Complete download integrity.
2. Verify load/unload memory lifecycle.
3. Add reliable Finder fallback and verify Retry.
4. Regenerate, build, run focused tests, and refresh Codebase Memory.
