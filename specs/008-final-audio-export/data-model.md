# Data Model: Final Audio Export

## Export Format

- `wav`: lossless mono Float32 PCM WAV, exact source sample rate
- `m4a`: mono AAC in an MPEG-4 audio container, source sample rate when supported

Each format exposes a display name, Uniform Type Identifier, and required filename extension.

## Exportable Clip

Immutable value captured from pipeline state:

- samples: non-empty finite `Float` values
- sample rate: positive integer
- source URL: stable session artifact identity
- duration: sample count divided by sample rate

Validation occurs before any destination file is modified.

## Altered Result Identity

Pipeline state stores the exact `VoiceEffectParameters` that produced the latest successful altered clip.

Eligibility rules:

1. Neutral current effect + synthesis available → synthesis eligible.
2. Non-neutral effect + alteration active → no exportable clip.
3. Non-neutral effect + altered clip exists + recorded effect equals current effect → altered clip eligible.
4. Non-neutral effect + failed/stale/mismatched altered clip → no exportable clip.
5. Bypass changes preview only and does not change final export selection.

## Export Operation

Transient state:

- captured immutable clip
- selected format
- user-selected destination
- unique sibling staging URL
- operation activity flag

Transitions:

`idle → selectingDestination → encodingStaging → publishing → succeeded | cancelled | failed`

Cancellation at destination selection writes nothing. Failed encoding removes staging and preserves any existing destination.

## Export Result

The view retains only the last successfully published URL for the current app session. A failed or cancelled later operation does not replace it. Reveal in Finder is explicit and user initiated.
