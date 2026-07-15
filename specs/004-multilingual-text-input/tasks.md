# Tasks: Multilingual Text Input

**Input**: Design documents from `specs/004-multilingual-text-input/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/multilingual-input.md`, `quickstart.md`

**Tests**: Pure language and request contracts use Swift Testing. Pipeline invalidation and SwiftUI integration use a cleaned temporary source-contract verifier because the test target does not compile application orchestration.

**Organization**: Tasks are grouped by user story so text entry, language selection, and stale-output prevention remain independently traceable.

## Phase 1: Setup

**Purpose**: Confirm feature scope, branch ancestry, active pointer, and the Auto-detect clarification outcome.

- [x] T001 Confirm branch ancestry, `.specify/feature.json`, and feature artifacts against `specs/004-multilingual-text-input/plan.md`
- [x] T002 Confirm Auto-detect as the initial selection across `specs/004-multilingual-text-input/spec.md`, `research.md`, `data-model.md`, and `contracts/multilingual-input.md`

---

## Phase 2: Foundational Verification

**Purpose**: Record the existing language catalog, pipeline defaults, readiness behavior, and stage controls.

- [x] T003 Create and run a temporary baseline verifier for `App/TTS/TTSEngine.swift`, `App/Model/PipelineState.swift`, and `App/Views/TextStageView.swift` under `/private/var/folders/gq/fj68kcfn2t1fb21qqrt6b44h0000gn/T/hermes-verify-*.py`

**Checkpoint**: Existing raw values, defaults, request construction, whitespace readiness, and picker bindings are explicit.

---

## Phase 3: User Story 1 - Enter Target Speech (Priority: P1) 🎯 MVP

**Goal**: Accept editable multilingual and multiline target text while rejecting effective emptiness and preserving exact editable content.

**Independent Test**: Exercise Unicode and whitespace source contracts, then manually confirm placeholder and editor behavior.

- [x] T004 [US1] Add a boundary-trimmed synthesis text value and use it for readiness and request construction in `App/Model/PipelineState.swift`
- [x] T005 [P] [US1] Show placeholder guidance for effectively empty input and add an explicit accessibility label in `App/Views/TextStageView.swift`
- [x] T006 [P] [US1] Verify no transliteration, silent truncation, or input-field mutation occurs in `App/Model/PipelineState.swift` and `App/Views/TextStageView.swift`
- [x] T007 [US1] Extend and rerun the temporary verifier for whitespace readiness, boundary trimming, and Unicode-preserving editor bindings under `/private/var/folders/gq/fj68kcfn2t1fb21qqrt6b44h0000gn/T/hermes-verify-*.py`

**Checkpoint**: Editable content stays exact while synthesis receives only a non-empty boundary-trimmed value.

---

## Phase 4: User Story 2 - Select a Supported Language (Priority: P1)

**Goal**: Offer Auto-detect and every model-supported language with exact backend identity, using Auto-detect initially.

**Independent Test**: Run pure Swift tests for ordered cases, raw values, display names, locale identifiers, and request defaults.

- [x] T008 [US2] Make Auto-detect the initial pipeline language and retain exact backend raw values in `App/Model/PipelineState.swift` and `App/TTS/TTSEngine.swift`
- [x] T009 [P] [US2] Add ordered catalog, display-name, and locale-mapping coverage in `Tests/TTSLanguageTests.swift`
- [x] T010 [P] [US2] Add synthesis-request Auto-detect default coverage in `Tests/TTSLanguageTests.swift`
- [x] T011 [US2] Regenerate `MacVoiceCloning.xcodeproj` with `xcodegen generate` and confirm `Tests/TTSLanguageTests.swift` belongs to the test target

**Checkpoint**: All eleven options map one-to-one to Qwen3-TTS identifiers and new sessions start with Auto-detect.

---

## Phase 5: User Story 3 - Keep Output Consistent with Inputs (Priority: P2)

**Goal**: Remove stale generated output after actual input changes and prevent mutation during active generation.

**Independent Test**: Inspect actual-change observers, invalidation ordering, request snapshots, and disabled controls; verify unchanged assignments are no-ops.

- [x] T012 [US3] Invalidate synthesis-derived state only when target text changes to a different value in `App/Model/PipelineState.swift`
- [x] T013 [US3] Invalidate synthesis-derived state only when language changes to a different value in `App/Model/PipelineState.swift`
- [x] T014 [P] [US3] Disable the editor and picker throughout active synthesis in `App/Views/TextStageView.swift`
- [x] T015 [US3] Extend and rerun the temporary verifier for actual-change guards, invalidation scope, normalized request construction, and synthesis control locking under `/private/var/folders/gq/fj68kcfn2t1fb21qqrt6b44h0000gn/T/hermes-verify-*.py`

**Checkpoint**: Visible and exportable audio always corresponds to the current editable text and language.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validate artifacts, compile, test pure contracts, and refresh structural knowledge.

- [x] T016 [P] Validate placeholders, links, task counts, raw-value consistency, and whitespace across `specs/004-multilingual-text-input/`
- [x] T017 Build `MacVoiceCloning.xcodeproj` with XCodeMCP, then run the CLI build command in `specs/004-multilingual-text-input/quickstart.md`
- [x] T018 Run `MacVoiceCloningTests/TTSLanguageTests` using the focused command in `specs/004-multilingual-text-input/quickstart.md`
- [x] T019 Refresh and verify the persistent Codebase Memory artifact at `.codebase-memory/graph.db.zst`

---

## Dependencies & Execution Order

### Phase Dependencies

- Setup has no dependencies.
- Foundational verification depends on Setup.
- User Story 1 depends on the baseline.
- User Story 2 can proceed after the baseline and clarification.
- User Story 3 depends on the normalized text and language defaults.
- Polish depends on all user stories.

### User Story Dependencies

- **US1**: Defines valid request text.
- **US2**: Defines valid request language.
- **US3**: Maintains consistency when either input changes.

### Parallel Opportunities

- T005 and T006 inspect presentation and state independently after T004.
- T009 and T010 share one new focused test file and can be authored together after T008.
- T014 can proceed while pipeline observers are implemented.
- T016 can run independently after documentation stabilizes.

## Parallel Example: User Story 2

```text
Task: "Verify the ordered language catalog and locale mapping"
Task: "Verify SynthesisRequest defaults to Auto-detect"
```

## Implementation Strategy

### MVP First

1. Normalize readiness and request text without mutating the field.
2. Make Auto-detect the default.
3. Verify exact model language identifiers.

### Incremental Delivery

1. Harden text semantics.
2. Harden language semantics.
3. Invalidate stale output on actual changes.
4. Lock inputs during generation.
5. Build, test, and refresh Codebase Memory.
