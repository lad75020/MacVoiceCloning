# Quickstart: Voice Clone Synthesis

## Prerequisites

- macOS 26.0+ on Apple Silicon
- Xcode 26+
- XcodeGen
- Existing project dependencies resolvable

## Generate the Project

```bash
xcodegen generate
```

Confirm `Tests/SynthesisContractsTests.swift` appears in `MacVoiceCloning.xcodeproj/project.pbxproj`.

## Build

```bash
xcodebuild \
  -project MacVoiceCloning.xcodeproj \
  -scheme MacVoiceCloning \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/MacVoiceCloningDerived \
  build
```

Expected marker:

```text
** BUILD SUCCEEDED **
```

## Focused Fast Tests

```bash
xcodebuild test \
  -project MacVoiceCloning.xcodeproj \
  -scheme MacVoiceCloning \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/MacVoiceCloningDerived \
  -only-testing:MacVoiceCloningTests/SynthesisContractsTests
```

These tests cover progress estimation, throughput, result validation, and atomic synthesis-file replacement without model weights.

## Smoke-Test Registration

The existing smoke suite should compile but remain disabled in routine runs:

```bash
xcodebuild test \
  -project MacVoiceCloning.xcodeproj \
  -scheme MacVoiceCloning \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/MacVoiceCloningDerived \
  -only-testing:MacVoiceCloningTests/TTSSmokeTests
```

Do not set `MVC_TTS_SMOKE`; Swift Testing should register the suite without executing model inference.

## Explicit End-to-End Smoke Test

Only when a multi-gigabyte download and long local inference are intentional:

```bash
MVC_TTS_SMOKE=1 xcodebuild test \
  -project MacVoiceCloning.xcodeproj \
  -scheme MacVoiceCloning \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/MacVoiceCloningDerived \
  -only-testing:MacVoiceCloningTests/TTSSmokeTests
```

The output path is printed for human audition. This run is not part of routine feature verification.

## Manual Acceptance

1. Launch with a downloaded and loaded Base model.
2. Accept a valid reference voice and transcript.
3. Enter target text and select a language.
4. Generate and confirm progress duration increases.
5. Confirm a playable result, duration, and token throughput appear.
6. Generate again with the same inputs; if the second run fails, confirm prior synthesis and alteration remain usable.
7. Change text and confirm old generated output disappears because it no longer matches current intent.

## Final Hygiene

```bash
git diff --check
git diff --cached --check
```

Run the cleaned temporary source-contract verifier under:

```text
/private/var/folders/gq/fj68kcfn2t1fb21qqrt6b44h0000gn/T/hermes-verify-*.py
```

Describe it as focused ad-hoc verification, not a full suite.
