# Data Model: Audio Preview Playback

## Playback Backend

Main-actor local abstraction over the production AVFoundation player.

### Fields

- `duration: TimeInterval`: Backend-reported total duration.
- `currentTime: TimeInterval`: Backend-reported playback position.
- `isPlaying: Bool`: Whether the backend is actively playing.

### Operations

- `play() -> Bool`: Attempts to start playback.
- `stop()`: Stops playback.

### Production Mapping

`AVAudioPlayer` conforms directly. Tests use deterministic in-memory fakes.

## Playback Coordinator

Shared observable `AudioPlayer` instance owned by `AppModel`.

### Published Fields

- `currentURL: URL?`: Active or naturally completed source identity.
- `isPlaying: Bool`: Whether the current backend is active.
- `progress: Double`: Finite normalized progress in `0...1`.

### Private Fields

- `player: PlaybackBackend?`: Current production or fake backend.
- `pollTask: Task<Void, Never>?`: One progress polling task.
- `makePlayer: (URL) throws -> PlaybackBackend`: Injected backend factory.

### State Transitions

| Current | Event | Next | Result |
|---|---|---|---|
| stopped | start valid source | playing | Backend/current URL published; progress 0 |
| playing A | start B | playing B | A stopped before B starts |
| playing A | toggle A | stopped | Backend/source cleared; progress 0 |
| any | construction failure | stopped | Typed open error thrown |
| any | `play()` false | stopped | Typed start error thrown |
| playing | progress poll | playing | Bounded monotonic progress updated |
| playing | backend stops before end | stopped | Source cleared; progress 0 |
| playing | backend stops at end | completed | Backend released; source retained; progress 1 |
| completed | replay | playing | Completed state reset before backend starts |
| completed | start another | playing | Completed state reset; new source starts |
| any | explicit invalidation | stopped | Backend/source cleared; progress 0 |

## Playback Error

Typed localized failure thrown by the coordinator.

### Variants

- `couldNotOpen(String)`: Backend factory failed for the local URL.
- `couldNotStart`: Backend was created but `play()` returned false.

### Rules

- No failed candidate becomes current.
- `PlayerControls` writes the localized message to `pipeline.lastError`.

## Player Control

Reusable stage UI bound to the shared coordinator.

### Inputs

- `url: URL?`: Clip to preview.
- `label: String`: Idle action label, default `Play`.

### Derived State

- `isSelected`: URL equals retained/current coordinator URL.
- `isPlayingCurrent`: Selected and coordinator is playing.

### Presentation

- Idle source: Play/Preview icon and label.
- Active source: Stop icon and label plus progress.
- Naturally completed source: Play/Preview label plus retained 100% progress.
- Missing source: disabled control.

## Progress Value

### Invariants

- Always finite.
- Always inside `0...1`.
- Monotonic during one active source.
- Explicit stop/replay/source switch resets to 0.
- Natural completion retains 1.

## Invalidation Boundaries

Playback stops before:

- recording start;
- reference import;
- reference transcript change;
- target text change;
- synthesis language change;
- generation start;
- voice effect change;
- bypass change.
