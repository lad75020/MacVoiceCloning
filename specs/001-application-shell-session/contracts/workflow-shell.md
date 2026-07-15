# Workflow Shell Contract

## Purpose

Define the observable user-facing contract of the application shell without prescribing specialized stage implementations.

## Window Contract

- Opening the app produces one primary workflow window.
- The window contains a scrollable vertical sequence.
- Model status appears first.
- Exactly five numbered stages follow in this order: Record, Write, Synthesize, Alter, Export.
- All stages share one application session.

## Launch Contract

1. Attempt to prepare app-owned model and session working locations.
2. If preparation fails, place a readable description in the shared error state.
3. Refresh local model availability regardless of preparation outcome.
4. If a complete model is available locally, begin making it ready.

## Synthesis Readiness Contract

Synthesis is available if and only if all conditions are true:

- the model is ready;
- a prepared reference sample exists;
- the reference transcript is non-empty after trimming whitespace;
- target text is non-empty after trimming whitespace; and
- synthesis is not already active.

When synthesis starts, current playback stops before work is delegated to the pipeline.

## Invalidation Contract

Replacing the reference sample clears:

- prior synthesized audio;
- prior synthesis statistics;
- prior altered audio; and
- obsolete synthesis progress.

Any queued alteration associated with the old synthesis is cancelled.

## Clip Selection Contract

- Export uses altered audio when a completed alteration exists; otherwise it uses synthesized audio.
- Preview uses synthesized audio when bypass is active.
- Preview uses altered audio when bypass is inactive and altered audio exists.
- Preview falls back to synthesized audio when bypass is inactive but no altered result exists.

## Error Contract

- The shell presents one shared error at a time in a dismissible message.
- Dismissing the message clears only that error.
- Valid inputs and outputs unrelated to the failure remain intact.
- Launch preparation failures use the same error channel as workflow failures.

## Privacy Contract

- Session audio, text, progress, and working state remain local to the Mac.
- The shell does not transmit session data.
- Model acquisition is an adjacent feature with its own network contract.

## Out-of-Scope Contracts

This contract does not define microphone permissions, audio conversion, speech recognition, model downloads, model inference, playback internals, voice-effect processing, or export encoding.
