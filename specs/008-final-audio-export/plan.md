# Implementation Plan: Final Audio Export

**Branch**: `feature/time-machine-final-audio-export` | **Date**: 2026-07-15 | **Spec**: `specs/008-final-audio-export/spec.md`

## Summary

Harden the existing stage-5 exporter so WAV and AAC M4A writes are validated, asynchronous, and atomically published; make pipeline export eligibility correspond to the current completed effect rather than a retained stale preview; preserve an explicit last-successful Reveal in Finder action; and add focused AVFoundation tests without model, microphone, network, save-panel, or Finder interaction.

## Technical Context

**Language/Version**: Swift 6.2
**Primary Dependencies**: SwiftUI, AppKit, AVFoundation, UniformTypeIdentifiers, Swift Testing
**Storage**: User-selected local destination plus same-directory temporary staging file
**Testing**: `xcodebuild test`, focused `AudioConvertingTests`
**Target Platform**: macOS 26.0+
**Project Type**: Xcode/XcodeGen macOS app
**Performance Goals**: Encoding and file writes off the main actor; no unbounded extra copies beyond the immutable clip snapshot already held by pipeline state
**Constraints**: Entirely local; preserve existing files on failed export; never export stale alteration output for current settings

## Constitution Check

- Local-first processing: PASS — no network path is introduced.
- Swift concurrency correctness: PASS — UI/save panel remains on MainActor; encoding uses `@concurrent` helpers.
- Testability: PASS — pure destination writer is separated from modal panel interaction.
- Sensitive audio handling: PASS — staging stays beside the selected local destination and is removed on completion/failure.
- Existing-work preservation: PASS — pre-existing asset relocation remains outside the feature allowlist.

## Project Structure

```text
App/
├── Audio/AudioConverting.swift
├── Export/AudioExporter.swift
├── Model/PipelineState.swift
└── Views/ExportStageView.swift
Tests/
└── AudioConvertingTests.swift
specs/008-final-audio-export/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── contracts/export.md
├── quickstart.md
└── tasks.md
```

## Design

1. Track the effect configuration associated with the latest successfully published altered clip.
2. Return an export clip only when settings are neutral or the current non-neutral effect exactly matches a completed altered clip and no replacement is running.
3. Validate sample rate, non-empty samples, and finite values before encoding.
4. Write to a unique sibling staging URL, then atomically replace/move the destination only after encoding succeeds.
5. Keep save-panel cancellation non-erroring and retain the prior reveal target unless a later export succeeds.
6. Disable format/save controls while no current export clip exists or an export is active.

## Verification Strategy

- Focused executable tests for validation, WAV fidelity, M4A readability/duration, atomic replacement, and cleanup.
- Source/state contract tests for current-effect export gating and cancelled/failed result retention where modal UI cannot be automated reliably.
- XCodeMCP build first, then canonical focused and full `xcodebuild test`.
- App smoke check for stage-5 disabled/enabled affordances without creating new biometric audio.
- Independent read-only review and persistent codebase-memory refresh.

## Complexity Tracking

No constitutional violation or additional abstraction beyond a testable writer and current-effect identity tracking is required.
