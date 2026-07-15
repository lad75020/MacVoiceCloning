# Tasks: Audio Preview Playback

**Input**: Design documents from `specs/006-audio-preview-playback/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/playback.md`, `quickstart.md`

**Tests**: Focused Swift Testing contracts use injected fake backends and emit no audio.

**Organization**: Tasks are grouped by user story so preview, mutual exclusion, and progress/error recovery remain independently traceable.

## Phase 1: Setup

**Purpose**: Confirm scope, ancestry, pointer, and the retained-completion clarification.

- [x] T001 Confirm branch ancestry, `.specify/feature.json`, and feature artifacts against `specs/006-audio-preview-playback/plan.md`
- [x] T002 Confirm natural completion retains 100% progress across `specs/006-audio-preview-playback/spec.md`, `research.md`, `data-model.md`, and `contracts/playback.md`

---

## Phase 2: Foundational Verification

**Purpose**: Record current direct AVAudioPlayer, silent failure, polling, controls, and stage invalidation behavior.

- [x] T003 Create and run a baseline source verifier for `App/Audio/AudioPlayer.swift`, `App/Views/Components/PlayerControls.swift`, `App/Views/RecordStageView.swift`, `App/Views/TextStageView.swift`, `App/Views/SynthesizeStageView.swift`, and `App/Views/AlterStageView.swift` under `/private/var/folders/gq/fj68kcfn2t1fb21qqrt6b44h0000gn/T/hermes-verify-*.py`
- [x] T004 [P] Confirm `AVAudioPlayer.play()` Boolean semantics and existing 100 ms polling behavior in `specs/006-audio-preview-playback/research.md`

**Checkpoint**: Existing playback and invalidation gaps are explicit before edits.

---

## Phase 3: User Story 1 - Preview Any Available Audio (Priority: P1) 🎯 MVP

**Goal**: Start and stop reference, synthesis, or altered clips through one reusable control with visible progress.

**Independent Test**: Start a fake-backed source, poll progress, stop it, and inspect stage control wiring.

- [x] T005 [US1] Add a minimal injectable playback backend and production AVAudioPlayer conformance in `App/Audio/AudioPlayer.swift`
- [x] T006 [US1] Publish active source, playing state, and bounded progress only after successful start in `App/Audio/AudioPlayer.swift`
- [x] T007 [US1] Render active/retained progress and accessible percentage values in `App/Views/Components/PlayerControls.swift`
- [x] T008 [P] [US1] Add fake backend, start, explicit stop, and progress polling coverage in `Tests/AudioPlayerTests.swift`
- [x] T009 [P] [US1] Verify reference, synthesis, and altered stages continue supplying their clip URLs in `App/Views/RecordStageView.swift`, `App/Views/SynthesizeStageView.swift`, and `App/Views/AlterStageView.swift`

**Checkpoint**: Every available workflow clip has one consistent preview control and safe progress.

---

## Phase 4: User Story 2 - Keep Playback Mutually Exclusive (Priority: P1)

**Goal**: Ensure one active source and stop stale playback before workflow mutations.

**Independent Test**: Start fake source A then B and verify A stops first; inspect all invalidation hooks.

- [x] T010 [US2] Stop the current or completed slot before a different source or replay begins in `App/Audio/AudioPlayer.swift`
- [x] T011 [P] [US2] Stop playback before recording, reference import, and transcript change in `App/Views/RecordStageView.swift`
- [x] T012 [P] [US2] Stop playback before target-text or synthesis-language invalidation in `App/Views/TextStageView.swift`
- [x] T013 [P] [US2] Stop playback before generation in `App/Views/SynthesizeStageView.swift`
- [x] T014 [P] [US2] Stop playback before effect or bypass changes in `App/Views/AlterStageView.swift`
- [x] T015 [US2] Add source-switching, same-source toggle, replay, and reset coverage in `Tests/AudioPlayerTests.swift`

**Checkpoint**: Only one clip can play and no stale source survives workflow mutation.

---

## Phase 5: User Story 3 - Understand and Recover From Playback State (Priority: P2)

**Goal**: Clamp timing metadata, retain natural completion at 100%, and surface actionable startup failures without false state.

**Independent Test**: Exercise invalid metric combinations, construction/start failures, early stop, and natural completion with fakes.

- [x] T016 [US3] Add typed open/start errors and transactional publication ordering in `App/Audio/AudioPlayer.swift`
- [x] T017 [US3] Add finite `0...1` normalization and monotonic active progress in `App/Audio/AudioPlayer.swift`
- [x] T018 [US3] Distinguish early stop from natural completion and retain completed URL/progress in `App/Audio/AudioPlayer.swift`
- [x] T019 [US3] Route localized playback errors to shared pipeline alert state in `App/Views/Components/PlayerControls.swift`
- [x] T020 [P] [US3] Add normalization, construction failure, start failure, early-stop, and retained-completion coverage in `Tests/AudioPlayerTests.swift`
- [x] T021 [US3] Extend and rerun the source verifier for backend injection, publication ordering, mutual exclusion, completion retention, error routing, and all invalidation hooks under `/private/var/folders/gq/fj68kcfn2t1fb21qqrt6b44h0000gn/T/hermes-verify-*.py`

**Checkpoint**: Playback state stays truthful, bounded, actionable, and completion-aware.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validate artifacts, compile, test silent contracts, and refresh structural knowledge.

- [x] T022 [P] Validate placeholders, links, task counts, completion-policy consistency, privacy, and whitespace across `specs/006-audio-preview-playback/`
- [x] T023 Regenerate `MacVoiceCloning.xcodeproj`, verify `Tests/AudioPlayerTests.swift` membership, build with XCodeMCP, and run the CLI build in `specs/006-audio-preview-playback/quickstart.md`
- [x] T024 Run focused `MacVoiceCloningTests/AudioPlayerTests` using `specs/006-audio-preview-playback/quickstart.md`
- [x] T025 Refresh and verify the persistent Codebase Memory artifact at `.codebase-memory/graph.db.zst`

---

## Dependencies & Execution Order

### Phase Dependencies

- Setup has no dependencies.
- Foundational verification depends on Setup.
- User Story 1 depends on the baseline.
- User Story 2 depends on the shared coordinator/backend seam.
- User Story 3 depends on start/switch semantics.
- Polish depends on all user stories.

### User Story Dependencies

- **US1**: Establishes reusable clip playback and progress.
- **US2**: Extends the shared slot across source and workflow invalidation boundaries.
- **US3**: Hardens invalid timing, completion, and failure behavior.

### Parallel Opportunities

- T004 can proceed with baseline verification.
- T008 and T009 cover independent tests and stage wiring.
- T011 through T014 touch independent views.
- T020 can be authored while coordinator failure/completion behavior is implemented.
- T022 can run after documentation stabilizes.

## Parallel Example: User Story 2

```text
Task: "Add stale-playback invalidation hooks to Record and Text stages"
Task: "Add stale-playback invalidation hooks to Synthesize and Alter stages"
```

## Implementation Strategy

### MVP First

1. Inject the backend seam.
2. Start/stop one source truthfully.
3. Render bounded progress.

### Incremental Delivery

1. Add source mutual exclusion and invalidation hooks.
2. Add typed failures and transactional publication.
3. Retain natural completion at 100%.
4. Add silent deterministic contracts.
5. Build, verify, and refresh Codebase Memory.
