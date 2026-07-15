# Implementation Plan: Voice Alteration

**Branch**: `feature/time-machine-voice-alteration` | **Date**: 2026-07-15 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/007-voice-alteration/spec.md`

## Summary

Harden the local Rubber Band alteration pipeline around validated effect parameters, deterministic offline processing, and revision-gated publication. Preserve the last successful altered preview while a debounced replacement runs, keep bypass independent from processing, publish only the newest request through a request-specific staging file, and extend focused tests across parameter semantics, both engines, invalid input, cancellation, and latest-result behavior.

## Technical Context

**Language/Version**: Swift 6.0 language mode with Swift 6.2 toolchain

**Primary Dependencies**: SwiftUI, Observation, Swift Testing, vendored Rubber Band 4.0.0 C/C++ API, Foundation

**Storage**: Local session WAV files in Application Support; request-specific staging files committed to the stable altered preview URL

**Testing**: Swift Testing; focused processor/parameter contracts; orchestration source contract where full pipeline target isolation is impractical; XCodeMCP and `xcodebuild`

**Target Platform**: macOS 26.0+, Apple Silicon

**Project Type**: Native SwiftUI macOS application

**Performance Goals**: 300 ms control debounce; cancel superseded work promptly; process 16,384-frame blocks without blocking the main interface

**Constraints**: Entirely local; mono Float32 source; preserve the last successful preview during replacement; bypass does not cancel processing; R2 ignores independent formant scale; preserve unrelated staged asset relocation

**Scale/Scope**: One effect value model, one offline processor, one pipeline alteration lifecycle, one stage view, one focused test file, existing C bridge/vendor source

## Constitution Check

The repository constitution is still an unratified template, so project-appropriate default gates apply:

- **Local privacy**: Audio, settings, and generated artifacts stay on device.
- **Deterministic contracts**: Parameter math and processor behavior are covered without model downloads, microphone access, network access, or playback.
- **Safe publication**: Cancelled or stale requests cannot replace the latest stable preview.
- **Responsive UX**: Processing runs asynchronously, rapid edits are debounced, and activity/error state remains visible.
- **Input safety**: Invalid sample rate and non-finite/out-of-contract parameters fail explicitly rather than crossing the C boundary.
- **Scope isolation**: No synthesis, transcription, recording, export-format, or model-lifecycle behavior changes.
- **Build readiness**: Focused tests plus XCodeMCP and CLI builds are required.

**Gate result before research**: PASS

**Post-design re-check**: PASS — the design uses existing local boundaries, adds no network or persistence service, and introduces only the minimum revision/staging state needed for correct cancellation.

## Project Structure

### Documentation

```text
specs/007-voice-alteration/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── alteration.md
├── checklists/
│   └── requirements.md
├── spec.md
└── tasks.md
```

### Source

```text
App/
├── Alteration/
│   ├── RubberBandProcessor.swift
│   └── VoiceEffectParameters.swift
├── Model/
│   ├── PipelineState.swift
│   └── SessionFiles.swift
├── Support/
│   └── Bridging-Header.h
└── Views/
    └── AlterStageView.swift

Tests/
└── RubberBandProcessorTests.swift

Vendor/rubberband/
├── rubberband/rubberband-c.h
└── single/RubberBandSingle.cpp
```

**Structure Decision**: Keep the vendored processor and all user-facing effect semantics in the existing alteration module. Pipeline orchestration remains in `PipelineState`; local path helpers remain in `SessionFiles`; no new package or service layer is introduced.

## Design

### Validated Effect Contract

Keep the current immutable-by-copy `VoiceEffectParameters` value and named presets, but define explicit validation for finite pitch, speed, formant scale, and positive sample rate before invoking the C API. Preserve pitch scale `2^(semitones/12)` and time ratio `1/speed`. Treat R2 formant scale as unsupported and ignored while retaining the user-selected value for a later switch back to R3.

### Deterministic Offline Processing

Continue Rubber Band's offline study/process sequence with one mono channel, expected duration, and bounded blocks. Return the source directly for identity parameters. Check task cancellation between blocks and while draining. Convert processor creation failure and invalid input into actionable localized errors; reject empty processor output for non-empty input.

### Latest-Request Publication

Increment an alteration revision whenever effect changes schedule work or synthesis is invalidated. Each request captures source identity, effect configuration, and revision. Processing writes to a request-specific staging URL. On the main actor, only a request whose revision is still current may commit staging to the stable altered URL and publish `altered`; every path removes its staging file.

### Stable Preview Policy

Do not clear the prior altered clip when a non-neutral replacement starts or fails. Keep it playable while `isAltering` indicates newer work. Identity settings explicitly select synthesis and clear the effective altered result. Bypass only changes `previewClip`; it stops playback but does not cancel, pause, or reschedule alteration.

### Interface Behavior

Preserve existing ranges, labels, preset/reset menu, engine picker, processing indicator, bypass control, and preview control. Disable unsupported R2 timbre editing and retain the explanatory warning. Effect changes stop playback and schedule one debounced replacement; bypass changes stop playback only.

## Verification Strategy

1. Add focused parameter tests for identity, pitch/time conversion, preset completeness, range/finite validation, and R2 formant behavior.
2. Extend processor tests for empty input, invalid sample rate/parameters, identity fast path, both engines, finite output, pitch tolerance, speed tolerance, and cancellation.
3. Add a focused orchestration/source contract proving revision gating, request-specific staging, stable previous-preview retention, and bypass independence.
4. Verify project membership from `project.yml` and generated PBX entries without double-counting filename occurrences on one line.
5. Run focused tests, XCodeMCP build first, canonical CLI build/tests, and specification/task artifact validation.
6. Refresh the Codebase Memory index and inspect the change impact.

## Complexity Tracking

No gate violations. A revision counter and request-specific staging URL are the minimum state needed to prevent stale asynchronous publication while preserving a stable preview.
