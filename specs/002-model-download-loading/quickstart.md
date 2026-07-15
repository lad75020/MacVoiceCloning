# Quickstart: Model Download and Loading

## Prerequisites

- macOS 26.0+ on Apple Silicon
- Xcode 26+
- XcodeGen available on `PATH`

## Regenerate the Project

A new focused test file is added, so regenerate the checked-in project before building:

```bash
xcodegen generate
```

`project.yml` remains the source of truth.

## Build

```bash
xcodebuild \
  -project MacVoiceCloning.xcodeproj \
  -scheme MacVoiceCloning \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  build
```

## Run Focused Tests

```bash
xcodebuild test \
  -project MacVoiceCloning.xcodeproj \
  -scheme MacVoiceCloning \
  -destination 'platform=macOS,arch=arm64' \
  -only-testing:MacVoiceCloningTests/ModelDownloaderTests
```

The focused tests use temporary local directories and do not download model weights.

## Manual Acceptance

1. Launch without a complete model and confirm the status shows the fixed model, approximate size, local-processing notice, and Download.
2. Start a real download only when network and disk capacity permit; confirm determinate progress and no conflicting action.
3. Interrupt and retry the transfer; confirm it resumes or reuses valid local files.
4. After completion, confirm the lifecycle loads automatically and reaches ready.
5. Select Unload, verify memory is released and status returns to downloaded, then select Load and return to ready.
6. Force or observe a download/load failure and confirm the phase-specific message and Retry action.
7. Reveal the model folder before and after completion; Finder must open an existing app-owned location.

## Expected Result

The fixed model can be downloaded resumably, recognized only when complete, loaded and unloaded predictably, retried according to local completeness, and inspected in Finder without exposing files outside the app-owned storage boundary.
