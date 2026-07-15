# Research: Multilingual Text Input

## Decision 1: Default to Auto-detect

**Decision**: Initialize stage 2 and synthesis requests with `.auto`.

**Rationale**: The user explicitly selected Auto-detect. It also matches the pinned Qwen3-TTS CLI and model API defaults.

**Alternatives considered**:

- English: rejected by the user and unnecessarily biases multilingual input.
- Current system language: rejected because system locale does not reliably describe the text the user enters.

## Decision 2: Use the model's exact full-name identifiers

**Decision**: Keep `auto`, `english`, `chinese`, `japanese`, `korean`, `german`, `french`, `russian`, `portuguese`, `spanish`, and `italian`.

**Rationale**: The pinned package's codec-language configuration maps these exact full names to IDs. Passing them unchanged avoids a second translation table at generation time.

**Alternatives considered**:

- ISO codes such as `en` or `zh`: rejected because support varies across package entry points and the model configuration uses full names.
- Localized display strings as raw values: rejected because localization would break backend identity.

## Decision 3: Auto-detection stays inside Qwen3-TTS

**Decision**: Pass `auto` and do not add an app-side language detector.

**Rationale**: The backend already performs the selection and returns no detection metadata. A second detector could disagree and would add dependencies, latency, and privacy surface.

## Decision 4: Trim at request construction, not during editing

**Decision**: Preserve the field exactly while using a whitespace/newline-trimmed value for readiness and synthesis.

**Rationale**: This rejects blank requests without rewriting user content or removing intentional internal formatting.

**Alternatives considered**:

- Trim the bound field on every edit: rejected because it disrupts typing and multiline composition.
- Pass boundary whitespace unchanged: rejected because it can create unintended pauses and inconsistent readiness.

## Decision 5: Invalidate output when inputs change

**Decision**: Clear synthesis and alteration state whenever target text or language changes to a different value.

**Rationale**: Existing output encodes both values. Keeping it visible after an edit makes preview and export semantically stale.

**Alternatives considered**:

- Show a stale warning: rejected because downstream export can still choose the wrong audio.
- Track revisions on every output: rejected as unnecessary for a single-session linear workflow.

## Decision 6: Lock controls during generation

**Decision**: Disable the editor and language picker while synthesis is active.

**Rationale**: Qwen3-TTS generation is a synchronous model call on a serial executor and does not offer reliable mid-run cancellation.

**Alternatives considered**:

- Allow edits and discard stale results: rejected because generation may run for minutes and progress becomes ambiguous.
- Add cancellation to the backend: deferred to synthesis lifecycle work because the package does not expose cooperative cancellation.

## Decision 7: Test value contracts independently

**Decision**: Add Swift Testing coverage for the language catalog, locale mapping, display names, and request default.

**Rationale**: These contracts are deterministic and do not require model files, MLX execution, or microphone access.
