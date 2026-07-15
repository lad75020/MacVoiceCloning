# Quickstart: Multilingual Text Input

## Prerequisites

- macOS 26.0+ on Apple Silicon
- Xcode 26+
- Generated `MacVoiceCloning.xcodeproj`

## Generate the Project

Run after adding the focused test file:

```bash
xcodegen generate
```

Confirm `TTSLanguageTests.swift` appears in the test target.

## Build with XCodeMCP

1. Open `MacVoiceCloning.xcodeproj`.
2. Call `XcodeListWindows`.
3. Build the `MacVoiceCloning` project with XCodeMCP.
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

## Focused Language Tests

```bash
xcodebuild test \
  -project MacVoiceCloning.xcodeproj \
  -scheme MacVoiceCloning \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/MacVoiceCloningDerived \
  -only-testing:MacVoiceCloningTests/TTSLanguageTests
```

Expected outcomes:

- Eleven ordered language cases expose exact backend raw values.
- Every display name and locale mapping matches the contract.
- New synthesis requests default to Auto-detect.

## Manual Input Acceptance

1. Launch the application.
2. Confirm the initial picker selection is Auto-detect.
3. Enter whitespace only and confirm synthesis guidance still reports missing text.
4. Enter multilingual, multiline Unicode text and confirm it remains unchanged.
5. Select Spanish, edit the text, and confirm Spanish remains selected.
6. Generate speech, then edit text and confirm prior synthesis and alteration controls disappear.
7. Generate again, then change language and confirm prior generated output disappears.
8. Start generation and confirm the editor and picker remain disabled until completion.

## Source-Contract Verification

Create a temporary `hermes-verify-*.py` file under the system temporary directory and verify:

- Auto-detect pipeline and request defaults
- trimmed readiness/request construction
- actual-change guards around invalidation
- stage-2 control disabling during synthesis
- exact picker catalog and accessibility labels

Clean up the verifier after execution and report it as focused ad-hoc verification.
