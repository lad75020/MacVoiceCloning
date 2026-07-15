# Implementation Plan: Application Shell and Session

**Branch**: `feature/time-machine-application-shell-and-session` | **Date**: 2026-07-15 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-application-shell-session/spec.md`

## Summary

Document and close the remaining gap in the existing single-window voice-cloning shell. Preserve the current shared observable session, ordered five-stage composition, readiness gating, downstream invalidation, and local working-file model. Make launch-time working-directory failures visible through the shell’s existing shared error presentation, then verify the app and focused fast tests without changing the behavior of model, recording, synthesis, alteration, playback, or export features.

## Technical Context

**Language/Version**: Swift 6 mode with Swift 6.2/Xcode 26 toolchain

**Primary Dependencies**: SwiftUI, Observation, Foundation; existing stage services are injected through the shared application model

**Storage**: App-owned files under the user’s Application Support directory for model and current-session working audio; no resumable project persistence

**Testing**: XCTest through `xcodebuild`; focused existing audio-conversion and Rubber Band tests plus a full application build

**Target Platform**: macOS 26.0+ on Apple Silicon

**Project Type**: Native single-window desktop application generated with XcodeGen

**Performance Goals**: Keep the window responsive during launch and processing; propagate shared-state changes to visible stages within one UI update; prevent duplicate synthesis work

**Constraints**: One in-memory session and one primary workflow window; main-actor UI state; local-only session audio and text; model acquisition is the only network-capable adjacent feature; no behavioral expansion outside the shell/session files

**Scale/Scope**: One local user, one active session, five ordered workflow stages, and a bounded set of current-session audio artifacts

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

The repository constitution is still the untouched generated template and is not ratified. The following project-appropriate default gates apply:

- **Native platform UX — PASS**: The design preserves one SwiftUI window, ordered stage cards, native scrolling, and a dismissible alert.
- **Secure local data handling — PASS**: Session audio/text remain in app-owned local locations; no new network or secret-handling surface is introduced.
- **Testability — PASS**: The remaining behavior change is isolated to launch orchestration and is verified by build plus focused existing unit tests and an explicit launch-error contract check.
- **Build readiness — PASS**: XcodeGen remains the source of truth and the generated project/scheme remain unchanged unless source membership changes, which this plan does not require.
- **Scope control — PASS**: Specialized model, recording, transcription, synthesis, playback, alteration, and export implementations remain outside this feature.

No gate violations require justification.

## Project Structure

### Documentation (this feature)

```text
specs/001-application-shell-session/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── workflow-shell.md
├── checklists/
│   └── requirements.md
└── tasks.md
```

### Source Code (repository root)

```text
App/
├── MacVoiceCloningApp.swift
├── Model/
│   ├── AppModel.swift
│   ├── PipelineState.swift
│   └── SessionFiles.swift
└── Views/
    ├── ContentView.swift
    └── Components/
        └── StageCard.swift

Tests/
├── AudioConvertingTests.swift
└── RubberBandProcessorTests.swift
```

**Structure Decision**: Keep the existing small native application layout. `AppModel` remains the composition root, `PipelineState` remains the shared workflow state owner, `SessionFiles` remains the local working-location authority, and `ContentView` remains the ordered stage composer. The implementation requires a surgical launch-error propagation change rather than new modules or targets.

## Phase 0: Research Outcomes

Research decisions are recorded in [research.md](research.md):

1. Retain one main-actor observable composition root shared through the view environment.
2. Retain one pipeline state owner for readiness, invalidation, progress, clip selection, and error presentation.
3. Keep app-owned working paths centralized and ephemeral at the session level.
4. Convert launch directory-preparation failure from silent best-effort behavior to the existing shared user-facing error channel.
5. Verify through the real macOS build and existing fast unit tests; avoid broad stage-feature changes.

## Phase 1: Design Outcomes

- [data-model.md](data-model.md) defines session entities, invariants, and transitions.
- [contracts/workflow-shell.md](contracts/workflow-shell.md) defines the user-visible stage order, readiness, invalidation, clip-selection, and error contract.
- [quickstart.md](quickstart.md) defines build and focused acceptance verification.
- Agent context points to this plan through the existing Spec Kit marker block.

## Post-Design Constitution Re-check

- **Native platform UX — PASS**: The contract retains the current ordered single-window flow.
- **Secure local data handling — PASS**: No remote session-data path is added; errors contain only local failure descriptions.
- **Testability — PASS**: Every changed requirement maps to a source inspection, focused behavior check, or executable build/test command.
- **Build readiness — PASS**: No project structure or dependency changes are planned.
- **Scope control — PASS**: Only shell/session orchestration and its documentation are affected.

## Implementation Strategy

1. Preserve the existing stage composition and shared ownership boundaries.
2. Update `AppModel.onLaunch()` to report directory-preparation failures through `PipelineState.lastError` while continuing model-state refresh.
3. Confirm the implementation still stops playback before synthesis and delegates pipeline work without duplicating specialized feature logic.
4. Run focused static contract verification, regenerate the Xcode project only if required, build the macOS app, and run the fast unit tests documented by the repository.
5. Re-index codebase-memory after successful verification.

## Complexity Tracking

No constitution violations or additional architectural complexity are introduced.
