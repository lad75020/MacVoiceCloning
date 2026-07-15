# Quickstart: Application Shell and Session

## Prerequisites

- macOS 26.0+ on Apple Silicon
- Xcode 26+
- XcodeGen available on `PATH`

## Generate the Project

```bash
xcodegen generate
```

`project.yml` is the source of truth. This feature does not add source files, so regeneration should not introduce project-structure changes.

## Build

```bash
xcodebuild \
  -project MacVoiceCloning.xcodeproj \
  -scheme MacVoiceCloning \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  build
```

Expected result: `** BUILD SUCCEEDED **`.

## Run Fast Tests

```bash
xcodebuild test \
  -project MacVoiceCloning.xcodeproj \
  -scheme MacVoiceCloning \
  -destination 'platform=macOS,arch=arm64' \
  -only-testing:MacVoiceCloningTests/AudioConvertingTests \
  -only-testing:MacVoiceCloningTests/RubberBandProcessorTests
```

Expected result: `** TEST SUCCEEDED **`.

The multi-gigabyte end-to-end model smoke test is intentionally excluded from this feature’s default verification.

## Manual Acceptance Walkthrough

1. Launch the app and confirm model status precedes five numbered stages.
2. Resize the window to its minimum supported size and scroll through all stages.
3. Confirm Generate remains unavailable until model, reference, transcript, and target text are ready.
4. Start reference or generated-audio playback, then begin synthesis and confirm playback stops.
5. Replace a prepared reference after synthesis and confirm stale generated/altered results are no longer available.
6. Trigger a representative workflow error, dismiss it, and confirm unrelated inputs remain.
7. Simulate failure to prepare the app-owned working location and confirm the shared error message reports it while model availability still refreshes.

## Privacy Check

- Inspect the session workflow and confirm audio/text are written only to app-owned local paths or an explicit user-selected export destination.
- Confirm the shell introduces no request that transmits session audio or text.
