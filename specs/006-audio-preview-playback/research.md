# Research: Audio Preview Playback

## Decision 1: Inject a Minimal Playback Backend

**Decision**: Place a five-member backend interface in `AudioPlayer.swift` and inject a URL factory.

**Rationale**: Direct `AVAudioPlayer` construction cannot deterministically exercise source switching, failed starts, timing, and natural completion without emitting sound. A local interface keeps production behavior unchanged while making contracts fast and silent.

**Alternatives considered**:

- Play generated test audio: audible and environment-dependent.
- Mock `AVAudioPlayer` directly: concrete Objective-C class is not a useful Swift test seam.
- Add a general media framework: disproportionate scope.

## Decision 2: Publish State Only After Playback Starts

**Decision**: Stop the current slot, construct a candidate backend, require `play()` to return true, then publish it as current/playing.

**Rationale**: The current implementation silently returns on construction failure and ignores the Boolean start result, which can publish false playing state.

**Alternatives considered**:

- Publish before start and roll back: exposes transient invalid state.
- Keep silent failure: leaves the user without recovery information.

## Decision 3: Throw Playback Errors to the Reusable Control

**Decision**: `toggle(url:)` throws a typed localized error. `PlayerControls` maps it to the existing shared pipeline alert.

**Rationale**: `AudioPlayer` should not depend on pipeline state, while all stage controls need the same visible error path.

**Alternatives considered**:

- Store `lastError` in the player: creates a second alert source.
- Pass an error callback into every toggle: noisier than Swift error propagation.

## Decision 4: Clamp and Preserve Monotonic Progress

**Decision**: Return 0 for non-finite current time/duration or non-positive duration, otherwise clamp current time divided by duration into `0...1`. During one playback, publish the maximum observed value.

**Rationale**: AV metadata and custom backends can expose invalid or out-of-range values; UI progress must remain finite and stable.

**Alternatives considered**:

- Trust AVFoundation values: violates progress safety.
- Throw on invalid metadata: playback can remain useful even when progress metadata is unavailable.

## Decision 5: Retain Completed Progress at 100%

**Decision**: Natural completion releases the backend and changes Stop back to Play while keeping the completed URL and progress 1. Explicit stop, replay, or a different source resets progress to 0.

**Rationale**: This follows the user’s clarification and gives a durable completion signal without looping.

**Alternatives considered**:

- Reset immediately: rejected by clarification.
- Autoreplay: rejected by clarification and surprising for previews.

## Decision 6: Stop Playback at Input/Source Boundaries

**Decision**: Stage views stop the shared player before mutations that can invalidate or replace the audible source.

**Rationale**: Stable file URLs are atomically replaced. URL equality alone cannot reveal that bytes changed, so an old backend could continue stale audio while the UI points to a new clip.

**Alternatives considered**:

- File metadata observation inside the player: complex and race-prone.
- Let stale playback finish: contradicts workflow state and source identity.
- Couple `PipelineState` to `AudioPlayer`: creates a model dependency cycle.

## Decision 7: Poll Every 100 ms

**Decision**: Retain the existing 100 ms polling cadence.

**Rationale**: Ten updates per second are smooth enough for compact progress and inexpensive for one local player.

**Alternatives considered**:

- Display link: unnecessary for non-visual media progress.
- AVAudioPlayer delegate only: supports completion, not continuous progress.
