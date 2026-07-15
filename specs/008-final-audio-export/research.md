# Research: Final Audio Export

## Decision 1: Keep the macOS save panel on MainActor, separate file writing

`NSSavePanel.runModal()` is AppKit UI and remains on MainActor. The selected URL and immutable `AudioClip` are then passed to a nonisolated asynchronous writer so encoding does not block UI interaction.

**Alternatives considered**: testing the modal panel directly, or moving all of `AudioExporter` off MainActor. Both make AppKit isolation less explicit and reduce deterministic testability.

## Decision 2: Stage beside the destination and publish atomically

Encode into a unique sibling `.partial` file. On success, replace an existing destination or move into an absent destination. A `defer` cleanup removes abandoned staging files.

**Why**: Direct writes can truncate an existing user file before encoding fails. Same-directory staging keeps the final rename on one volume and minimizes partial-file exposure.

## Decision 3: Track the effect represented by altered audio

A retained altered preview is intentionally playable while replacement work runs, but it is not automatically eligible for final export. Pipeline state records the `VoiceEffectParameters` that produced the latest altered clip and exports it only when it equals current settings and processing is complete.

**Alternatives considered**: disabling only on `isAltering`, which would incorrectly re-enable stale output after a failed replacement; clearing the prior preview, which conflicts with the alteration feature clarification.

## Decision 4: Validate before crossing AVFoundation write APIs

Reject empty clips, non-positive sample rates, and non-finite samples with actionable localized errors. This prevents force-unwrapping an empty sample buffer and avoids publishing invalid audio.

## Decision 5: AAC uses AVFoundation encoder defaults appropriate to mono source rate

The existing encoder selects a supported bitrate for the selected sample rate and mono channel count. Focused tests reopen the M4A and compare duration instead of asserting an implementation-specific bitrate.

## Decision 6: Reveal is explicit, not automatic

The interface retains the last successful export URL and shows an action that calls `NSWorkspace.activateFileViewerSelecting`. Cancellation or failure leaves the previous target unchanged.
