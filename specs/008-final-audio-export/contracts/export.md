# Contract: Final Audio Export

## Export availability

```swift
@MainActor
var exportClip: PipelineState.AudioClip? { get }
```

Returns a clip only when it represents the current complete settings. Retained stale altered previews are excluded.

## Destination writer

```swift
nonisolated static func write(
    clip: PipelineState.AudioClip,
    format: AudioExporter.Format,
    to destination: URL
) async throws
```

### Preconditions

- `clip.samples` is non-empty.
- `clip.sampleRate > 0`.
- Every sample is finite.
- Destination is a local file URL.

### Guarantees

- Encoding occurs outside MainActor.
- Existing destination content is replaced only after staging succeeds.
- Staging is unique, beside the destination, and removed after success/failure.
- WAV preserves sample rate/sample count.
- M4A is readable AAC with approximately equal duration.
- Failure returns a localized actionable error.

## Save-panel export

```swift
@MainActor
static func export(
    clip: PipelineState.AudioClip,
    format: AudioExporter.Format,
    suggestedName: String
) async throws -> URL?
```

Returns `nil` on user cancellation without error. Returns the published destination only after successful write.

## View behavior

- Save controls disabled when `exportClip == nil` or export is active.
- Successful destination becomes the Reveal in Finder target.
- Cancellation/failure does not replace the previous target.
- Finder never opens automatically.
