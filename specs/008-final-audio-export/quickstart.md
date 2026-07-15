# Quickstart: Final Audio Export Verification

## Prerequisites

- macOS 26.0+
- Xcode with Swift 6.2
- Existing generated `MacVoiceCloning.xcodeproj`
- No model download is needed for focused export tests

## Focused tests

```bash
xcodebuild test \
  -project MacVoiceCloning.xcodeproj \
  -scheme MacVoiceCloning \
  -destination 'platform=macOS' \
  -only-testing:MacVoiceCloningTests/AudioConvertingTests
```

Expected coverage: invalid clips, WAV fidelity, AAC readability/duration, atomic replacement, staging cleanup, current-effect export gating, and result retention contracts.

## XCodeMCP build first

Use configured XCodeMCP `BuildProject` on the open `MacVoiceCloning.xcodeproj`. Resolve first-party diagnostics before canonical CLI verification.

## Canonical verification

```bash
xcodebuild test \
  -project MacVoiceCloning.xcodeproj \
  -scheme MacVoiceCloning \
  -destination 'platform=macOS'
```

## Manual smoke check

1. Launch the built app and inspect stage 5.
2. With no synthesis, verify format/save controls are disabled.
3. With a current synthesis, verify WAV is the default and Save As is enabled.
4. Start a replacement alteration and verify Save As disables while Preview may still use the previous altered result.
5. After completion, export WAV and M4A and verify each is playable.
6. Cancel a later save and verify the previous Reveal in Finder action remains.
7. Activate Reveal in Finder and verify the exported file is selected.

## Privacy check

Inspect the implementation and build logs: export must use only local file URLs and AVFoundation/AppKit APIs, with no network requests or telemetry.

## Verification evidence (2026-07-15)

- XCodeMCP `BuildProject`: succeeded in 2.203 seconds with zero errors and no first-party `App/` or `Tests/` diagnostics.
- Focused `AudioConvertingTests`: 10 tests in 1 suite passed in 1.998 seconds.
- Full suite: 40 tests in 7 suites passed in 3.524 seconds; the opt-in end-to-end TTS smoke test was skipped as designed.
- Canonical CLI logs contained only Xcode's expected AppIntents metadata-skip notices; no first-party compiler warning or test failure remained.
- The built app launched. With no synthesis loaded, stage 5 showed WAV selected and both Format and Save As correctly disabled with the current-voice-not-ready explanation.
- Review confirmed local file URLs only, validation before writes, same-directory unique staging with cleanup, and destination publication only after successful encoding.
- The pre-existing staged asset-catalog relocation remained outside this feature's commit allowlist.