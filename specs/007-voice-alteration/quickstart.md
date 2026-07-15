# Quickstart: Voice Alteration Verification

## Prerequisites

- macOS 26.0+
- Xcode with the Swift 6.2 toolchain
- Existing generated MacVoiceCloning Xcode project
- No model download is required for focused alteration tests

## Regenerate project metadata when source membership changes

```bash
xcodegen generate
```

## Run focused alteration tests

```bash
xcodebuild test \
  -project MacVoiceCloning.xcodeproj \
  -scheme MacVoiceCloning \
  -destination 'platform=macOS' \
  -only-testing:MacVoiceCloningTests/RubberBandProcessorTests
```

Expected coverage includes parameter conversion, identity handling, pitch, speed, R2 and R3 processing, invalid input, finite output, and cancellation.

## Build through XCodeMCP first

Use the configured XCodeMCP integration to build the `MacVoiceCloning` scheme. Resolve any reported compiler or project-membership failures before canonical CLI verification.

## Run canonical build and tests

```bash
xcodebuild build \
  -project MacVoiceCloning.xcodeproj \
  -scheme MacVoiceCloning \
  -destination 'platform=macOS'

xcodebuild test \
  -project MacVoiceCloning.xcodeproj \
  -scheme MacVoiceCloning \
  -destination 'platform=macOS'
```

## Manual behavior check

1. Generate or load a synthesis so stage 4 is enabled.
2. Change pitch and verify the processing indicator appears after the control settles.
3. Drag speed repeatedly and verify obsolete edits do not queue visible results.
4. While replacement processing runs, press Preview and verify the last successful altered clip remains available.
5. Enable Bypass during processing and verify Preview uses synthesis while processing continues.
6. Disable Bypass and verify the latest completed altered preview is selected.
7. Switch to R2 with non-neutral timbre and verify the control disables with explanatory text; switch back to R3 and verify the retained value returns.
8. Apply every preset and Reset; verify each action replaces the complete visible configuration.
9. Trigger a processing error in a test/debug path and verify the prior preview remains available with an actionable error.

## Privacy check

Alteration must perform no network request and must write only local session staging/stable files.

## Verification evidence (2026-07-15)

- XCodeMCP `BuildProject`: succeeded in 2.429 seconds with zero errors.
- Focused `RubberBandProcessorTests`: 14 tests passed in one suite.
- Full `MacVoiceCloning` test run: 35 tests passed across seven suites; the opt-in end-to-end voice-clone smoke test was skipped as designed.
- The canonical CLI run emitted no first-party compiler warnings. The only warning was App Intents metadata extraction being skipped because the project has no AppIntents dependency.
- Xcode's Issue Navigator retained a stale `PipelineState.swift:212` warning from an earlier build even though the referenced `await` was removed; the subsequent canonical compile/test log did not reproduce it.
- The built app launched successfully. The accessibility tree exposed Pitch, Speed, Timbre, Preserve vocal character, R3/R2 engine controls, Presets, Bypass, and Preview; alteration remained correctly disabled because no voice sample/synthesis was loaded. The synthesis-dependent manual checklist was therefore covered by automated contracts rather than by generating new biometric audio.
- The pre-existing staged asset-catalog relocation remained untouched and outside the feature implementation allowlist.
- `git diff --check` passed, and no project-membership change was required.
- Independent review found no blockers. It prompted clearing stale alteration errors on retry and adding executable revision-gate and atomic-publication coverage; both were implemented before final verification.
