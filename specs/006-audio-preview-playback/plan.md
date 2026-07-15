# Implementation Plan: Audio Preview Playback

**Branch**: `feature/time-machine-audio-preview-playback` | **Date**: 2026-07-15 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/006-audio-preview-playback/spec.md`

## Summary

Harden the shared `AudioPlayer` behind a tiny injectable backend interface so mutual exclusion, startup failure, bounded progress, explicit stop, and natural completion are deterministic and silent to test. Expose active-source progress beside each `PlayerControls` button, route thrown playback errors to the existing shared alert, and stop stale playback before recording, reference replacement, generation, text/language/transcript invalidation, effect changes, or bypass changes.

## Technical Context

**Language/Version**: Swift 6.2

**Primary Dependencies**: SwiftUI, Observation, AVFoundation, Swift Testing

**Storage**: Existing local audio URLs only; no new persistence

**Testing**: Swift Testing with injected fake playback backends; XCodeMCP and `xcodebuild`

**Target Platform**: macOS 26.0+, Apple Silicon

**Project Type**: Native SwiftUI macOS application

**Performance Goals**: Poll no more often than every 100 ms; control updates remain responsive

**Constraints**: One local playback slot; no sound in focused tests; no network; retain 100% natural-completion progress; preserve unrelated asset relocation

**Scale/Scope**: One coordinator, one reusable control, five stage integrations, one focused test file

## Constitution Check

- **Local-first**: AVFoundation reads only local clip URLs.
- **Deterministic contracts**: A small backend interface permits silent fake-driven tests.
- **Single responsibility**: `AudioPlayer` owns playback state; views only invoke it and present state/errors.
- **Safe state**: Failed starts publish no false active state; invalid metrics are clamped.
- **Minimal UI**: Existing labels/buttons remain, with one compact progress bar.
- **Scope isolation**: No alteration, synthesis, recording, or export algorithms change.

**Gate result**: PASS

## Project Structure

### Documentation

```text
specs/006-audio-preview-playback/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── playback.md
├── checklists/
│   └── requirements.md
├── spec.md
└── tasks.md
```

### Source

```text
App/
├── Audio/
│   └── AudioPlayer.swift
└── Views/
    ├── Components/
    │   └── PlayerControls.swift
    ├── RecordStageView.swift
    ├── TextStageView.swift
    ├── SynthesizeStageView.swift
    └── AlterStageView.swift

Tests/
└── AudioPlayerTests.swift
```

## Design

### Injectable Local Backend

Define a main-actor-only playback backend with duration, current time, playing state, `play()`, and `stop()`. Conform `AVAudioPlayer` for production and inject a URL-to-backend factory in tests.

### Transactional Start State

`toggle(url:)` stops the previous slot first, constructs the new backend, and calls `play()`. It publishes `currentURL`, `isPlaying`, and polling state only after `play()` succeeds. Construction and start failures throw actionable errors while state stays stopped.

### Bounded Monotonic Progress

Normalize only finite values with positive finite duration, clamp to `0...1`, and publish `max(previous, normalized)` during active playback. Poll at 100 ms.

### Completion Policy

If the backend stops at 100%, cancel polling, release the backend, return the button to Play, retain `currentURL`, and keep progress at 1. Replay or selection of another source begins with `stop()`, resetting progress.

### Invalidation Integration

Stop playback synchronously before:

- recording begins or reference import starts;
- target text, synthesis language, or reference transcript changes;
- synthesis starts;
- voice effect or bypass selection changes.

### Control Presentation

The reusable control catches playback errors into `pipeline.lastError`. It renders an accessible compact progress bar whenever its URL is the retained/current source, including completed 100% state.

## Verification Strategy

1. Baseline ad-hoc verifier records current silent-failure/direct-AVAudioPlayer behavior.
2. Focused fake-driven tests cover switching, toggle stop, failures, metric normalization, progress polling, natural completion, and explicit reset.
3. Source verifier checks all stale-playback invalidation hooks and error routing.
4. Regenerate project and verify test membership by matching PBX lines.
5. Run focused tests, XCodeMCP build, CLI build, and documentation/task checks.
6. Refresh persistent Codebase Memory.

## Complexity Tracking

No constitution violations. The injected backend is the minimum seam needed for deterministic non-audible behavior tests.
