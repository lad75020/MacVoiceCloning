# Audio Preview Playback Contract

## Purpose

Define a deterministic local playback boundary, observable coordinator behavior, progress semantics, reusable control behavior, and stale-source invalidation.

## Backend Contract

```swift
@MainActor
protocol AudioPlaybackBackend: AnyObject {
    var duration: TimeInterval { get }
    var currentTime: TimeInterval { get }
    var isPlaying: Bool { get }

    func play() -> Bool
    func stop()
}
```

Production uses `AVAudioPlayer`; focused tests use silent fakes.

## Coordinator Contract

```swift
@MainActor
final class AudioPlayer {
    private(set) var currentURL: URL?
    private(set) var isPlaying: Bool
    private(set) var progress: Double

    func toggle(url: URL) throws
    func stop()

    static func normalizedProgress(
        currentTime: TimeInterval,
        duration: TimeInterval
    ) -> Double
}
```

## Start Ordering

1. If the same source is actively playing, explicitly stop and return.
2. Stop/reset any current or completed source.
3. Construct a candidate backend.
4. Call `play()`.
5. If construction throws or `play()` is false, remain stopped and throw an actionable error.
6. Only after successful start, publish backend, URL, playing state, and polling task.

## Mutual Exclusion

There is exactly one coordinator and at most one backend. Starting B synchronously stops A before constructing or starting B.

## Progress Normalization

```text
invalid/non-finite current or duration → 0
non-positive duration                → 0
otherwise                            → clamp(current / duration, 0...1)
```

During active playback, publication is monotonic:

```text
published = max(previous, normalized)
```

## Completion

- If the backend stops with normalized progress at 1:
  - cancel polling;
  - release backend;
  - publish `isPlaying = false`;
  - retain current URL;
  - publish progress 1.
- If the backend stops before progress reaches 1, perform explicit stop/reset.
- Replay or source change resets retained completion before starting.

## UI Contract

`PlayerControls`:

- disables itself for nil URL;
- calls throwing `toggle` for a URL;
- writes localized failure to `pipeline.lastError`;
- displays Stop only for the actively playing selected URL;
- displays an accessible progress bar for the selected URL, including retained completion.

## Invalidation Contract

The shared player stops before these mutations:

| Mutation | Integration |
|---|---|
| Recording start | `RecordStageView` |
| Reference import | `RecordStageView` |
| Reference transcript change | `RecordStageView` |
| Target text/language change | `TextStageView` |
| Generation start | `SynthesizeStageView` |
| Effect/bypass change | `AlterStageView` |

## Failure Contract

- File-open error: stopped state and actionable message.
- Start returns false: stopped state and actionable message.
- Invalid timing metadata: playback may continue; progress remains safe.
- Poll cancellation: no later state updates for the cancelled source.

## Locality and Privacy

No playback operation performs network I/O, telemetry, or external upload.
