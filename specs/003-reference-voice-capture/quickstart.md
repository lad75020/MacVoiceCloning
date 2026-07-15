# Quickstart: Reference Voice Capture

## Prerequisites

- macOS 26.0+ on Apple Silicon
- Xcode 26+
- A microphone for manual recording acceptance

## Build with XCodeMCP

1. Open `MacVoiceCloning.xcodeproj`.
2. Call `XcodeListWindows`.
3. Build the `MacVoiceCloning` scheme with XCodeMCP.
4. Record the exact result and diagnostics.

## CLI Build

```bash
xcodebuild \
  -project MacVoiceCloning.xcodeproj \
  -scheme MacVoiceCloning \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/MacVoiceCloningDerived \
  build
```

Expected marker: `** BUILD SUCCEEDED **`.

## Focused Conversion Tests

```bash
xcodebuild test \
  -project MacVoiceCloning.xcodeproj \
  -scheme MacVoiceCloning \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/MacVoiceCloningDerived \
  -only-testing:MacVoiceCloningTests/AudioConvertingTests
```

Expected outcomes:

- 48 kHz input normalizes to approximately 24 kHz mono.
- WAV round trips preserve sample count and energy.
- System-generated speech converts into a usable reference.
- Empty audio input is rejected.

## Manual Recording Acceptance

1. Launch the application and allow microphone access.
2. Start recording and confirm meter and duration update.
3. Stop before three seconds and confirm the sample is rejected.
4. Record five to fifteen seconds and confirm the accepted duration and player appear.
5. Confirm transcription progress ends and the field stays editable.

## Manual Replacement Acceptance

1. Begin with an accepted reference and non-empty transcript.
2. Import a corrupt or shorter-than-three-second file.
3. Confirm the previous sample, transcript, synthesis, and alteration remain available.
4. Import a valid audio file.
5. Confirm the new reference commits, the transcript is refreshed, and prior synthesis is invalidated.
6. Attempt Record or Import while preparation is active and confirm controls are disabled.

## Security-Scoped Import Acceptance

1. Choose an audio file outside the application container.
2. Confirm preparation succeeds while the file remains selected.
3. Move or remove the original file after preparation.
4. Confirm the app-owned accepted reference remains playable.
