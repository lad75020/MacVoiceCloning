# Voice Alteration Contract

## Parameter contract

- Pitch accepts finite whole-semitone values from -12 through +12.
- Speed accepts finite values from 0.5× through 2.0×.
- Formant scale accepts finite values from 0.5× through 2.0×.
- Sample rate must be greater than zero.
- R3 Finer applies independent formant scale; R2 Faster ignores it without deleting the retained selection.
- Presets replace the complete configuration; Reset restores neutral values.

## Processor contract

Given mono Float32 samples, a positive sample rate, and valid parameters:

- Empty input returns empty output without creating processor state.
- Identity parameters return equivalent source samples without an unnecessary transformation.
- Non-identity processing uses the original synthesis as input.
- Output sample rate remains unchanged.
- Output samples are finite and non-empty for non-empty valid input.
- Pitch-only processing keeps duration within 5% and shifts frequency within 10% of the request.
- Speed processing keeps duration within 10% of the requested time ratio.
- Task cancellation prevents result publication and is checked between processing blocks.
- Invalid input and processor creation/output failures throw actionable localized errors.

## Request/publication contract

- Effect changes stop playback and schedule one debounced request.
- A new request increments the alteration revision and supersedes older work.
- Every request writes to a unique staging URL.
- Only the current revision may replace the stable altered preview and publish state.
- Cancelled, stale, and failed requests remove their staging file and retain the last successful preview.
- Neutral settings select synthesis and do not schedule processor work.
- Visible processing state represents pending work for the latest request.

## Bypass contract

- Enabling bypass stops current playback and selects synthesis for Preview.
- Bypass retains effect settings and the last successful altered clip.
- Bypass does not cancel, pause, or reschedule alteration work.
- Disabling bypass selects the latest successful altered clip, or synthesis when no altered clip exists.

## Interface contract

- Alteration controls are unavailable until synthesis exists.
- R2 disables independent timbre editing and displays a clear limitation message when a non-neutral value is retained.
- The interface displays processing activity for the latest request.
- Preview remains available with the last successful result during replacement.
- Failures surface through the shared actionable error channel.
- All alteration behavior remains local with no audio/settings telemetry.
