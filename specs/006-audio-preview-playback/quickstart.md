# Quickstart: Audio Preview Playback

## Prerequisites

- macOS 26.0+ on Apple Silicon
- Xcode 26+
- XcodeGen
- Existing project dependencies resolvable

## Generate the Project

```bash
xcodegen generate
```

Verify `AudioPlayerTests.swift` appears as four matching project lines:

```bash
grep -n 'AudioPlayerTests.swift' MacVoiceCloning.xcodeproj/project.pbxproj
```

## Focused Playback Contracts

These tests use silent fake backends and emit no audio:

```bash
xcodebuild test \
  -project MacVoiceCloning.xcodeproj \
  -scheme MacVoiceCloning \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/MacVoiceCloningDerived \
  -only-testing:MacVoiceCloningTests/AudioPlayerTests
```

Expected: focused AudioPlayer tests pass.

## XCodeMCP Build

1. Call `XcodeListWindows`.
2. Build the open MacVoiceCloning project/scheme.
3. Confirm zero errors and record existing third-party warnings separately.

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

Expected: `** BUILD SUCCEEDED **`.

## Manual Workflow

1. Make a reference, synthesis, and altered preview available.
2. Play the reference; verify its progress appears.
3. Start synthesis playback; verify the reference stops first.
4. Start altered preview; verify synthesis stops first.
5. Stop explicitly; verify progress resets and source clears.
6. Let a clip finish; verify the button returns to Play and progress remains 100%.
7. Replay it; verify progress resets and advances again.
8. While playing, change text/language/transcript/effect/bypass or start recording/generation; verify stale playback stops.
9. Make a URL unavailable and select Play; verify an actionable shared alert.

## Ad-Hoc Verification

Create the verifier with Python `tempfile.mkstemp` using:

- directory: `/private/var/folders/gq/fj68kcfn2t1fb21qqrt6b44h0000gn/T`
- prefix: `hermes-verify-`
- suffix: `.py`

Verify backend injection, publication ordering, clamping, retained completion, mutual exclusion, error routing, and all invalidation hooks. Remove the script afterward.

## Persistent Codebase Memory

Refresh the full persistent repository index and confirm status `ready` before finalizing.
