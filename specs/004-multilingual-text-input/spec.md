# Feature Specification: Multilingual Text Input

**Feature Branch**: `feature/time-machine-multilingual-text-input`

**Created**: 2026-07-15

**Status**: Draft

**Input**: User description: "Lets users enter the speech their clone should say and select or auto-detect one of the supported synthesis languages."

## User Scenarios & Testing

### User Story 1 - Enter Target Speech (Priority: P1)

A user enters the exact speech that the cloned voice should generate, including Unicode characters, punctuation, and multiple lines.

**Why this priority**: Target text is a required synthesis input and the feature has no value without it.

**Independent Test**: Type multilingual and multiline text, verify it remains editable and bound to pipeline state, and confirm whitespace-only input is not synthesis-ready.

**Acceptance Scenarios**:

1. **Given** stage 2 is visible, **When** the user types non-empty speech, **Then** the exact text remains available as the target synthesis input.
2. **Given** the field contains only spaces or line breaks, **When** readiness is evaluated, **Then** synthesis remains unavailable and the empty-state guidance remains applicable.
3. **Given** the user enters non-Latin characters and punctuation, **When** the text is retained, **Then** no transliteration, ASCII restriction, or silent truncation occurs.
4. **Given** the user clears the field, **When** it becomes effectively empty, **Then** the placeholder guidance is visible.

---

### User Story 2 - Select a Supported Language (Priority: P1)

A user chooses a specific Qwen3-TTS language or asks the model to auto-detect the target text language.

**Why this priority**: The backend requires a supported language identifier to tokenize and generate multilingual speech correctly.

**Independent Test**: Inspect every picker option and verify its exact backend raw value, stable identity, display name, and locale mapping.

**Acceptance Scenarios**:

1. **Given** the language picker is open, **When** options are listed, **Then** Auto-detect and all ten model-supported languages are present exactly once.
2. **Given** a specific language is selected, **When** synthesis is requested, **Then** its model-compatible lowercase identifier is passed unchanged.
3. **Given** Auto-detect is selected, **When** synthesis is requested, **Then** the backend receives `auto` and chooses from the target text.
4. **Given** a language is selected, **When** the user edits target text, **Then** the explicit selection remains unchanged.
5. **Given** the stage first appears, **When** no language has been chosen, **Then** Auto-detect is selected by default.

---

### User Story 3 - Keep Output Consistent with Inputs (Priority: P2)

A user changes target text or language after generating speech and never mistakes the older audio for the new inputs.

**Why this priority**: Exporting or altering stale speech after an input edit is a correctness failure.

**Independent Test**: Model an existing synthesis, change text and language independently, and verify synthesis, statistics, alteration, and progress are invalidated.

**Acceptance Scenarios**:

1. **Given** synthesized or altered audio exists, **When** target text changes, **Then** all output derived from the prior text becomes unavailable.
2. **Given** synthesized or altered audio exists, **When** language changes, **Then** all output derived from the prior language becomes unavailable.
3. **Given** synthesis is running, **When** stage 2 is displayed, **Then** text and language controls cannot mutate the request until that run finishes.
4. **Given** only target text or language changes, **When** invalidation occurs, **Then** the accepted reference audio and editable reference transcript remain unchanged.

---

### Edge Cases

- Empty and whitespace-only target text are equivalent for readiness.
- Leading and trailing whitespace is ignored at the synthesis boundary without changing the editable field.
- Unicode scripts, emoji, punctuation, and line breaks remain valid input.
- Very long text remains editable; backend token limits and generation errors are surfaced by the synthesis workflow rather than silently truncating input.
- Re-selecting the current language does not invalidate output.
- Changing target text does not reset an explicit language selection.
- Changing language does not erase or re-transcribe the user's reference transcript.
- Auto-detect does not claim or display a detected language because the current backend returns audio, not detection metadata.

## Requirements

### Functional Requirements

- **FR-001**: The system MUST provide an editable multiline target-text field in stage 2.
- **FR-002**: The system MUST preserve Unicode text, punctuation, and line breaks as entered.
- **FR-003**: The system MUST treat target text as missing when trimming whitespace and newlines produces an empty string.
- **FR-004**: The system MUST show placeholder guidance whenever target text is effectively empty.
- **FR-005**: The system MUST pass target text with boundary whitespace removed when constructing a synthesis request.
- **FR-006**: The system MUST NOT silently truncate or transliterate target text.
- **FR-007**: The system MUST provide Auto-detect plus Chinese, English, German, Italian, Portuguese, Spanish, Japanese, Korean, French, and Russian exactly once.
- **FR-008**: Each language option MUST have a stable identity, human-readable display name, and exact lowercase raw value accepted by Qwen3-TTS.
- **FR-009**: Auto-detect MUST pass the raw value `auto` to Qwen3-TTS.
- **FR-010**: The initial language selection MUST be Auto-detect.
- **FR-011**: Editing target text MUST preserve the selected language.
- **FR-012**: Changing target text after synthesis MUST invalidate synthesis audio, synthesis statistics, altered audio, and synthesis progress.
- **FR-013**: Changing language after synthesis MUST invalidate synthesis audio, synthesis statistics, altered audio, and synthesis progress.
- **FR-014**: Reassigning an unchanged text or language value MUST NOT invalidate output.
- **FR-015**: Target text and language controls MUST be disabled while synthesis is running.
- **FR-016**: Text or language edits MUST NOT modify the accepted reference audio or reference transcript.
- **FR-017**: The language picker MUST expose an accessible label and each option MUST expose its display name.
- **FR-018**: The system MUST keep per-language locale identifiers for the best-effort reference-transcription integration.
- **FR-019**: Auto-detect MUST retain no fixed reference-transcription locale and MUST fall back through the transcription workflow.
- **FR-020**: The system MUST surface backend generation failures through the shared error workflow rather than alter input text.

### Key Entities

- **Target Text**: Editable Unicode speech content whose trimmed value becomes the synthesis request text.
- **TTS Language**: Stable model-compatible language choice with raw value, display name, and optional transcription locale.
- **Synthesis Input Revision**: The combination of target text and language whose changes invalidate older generated output.

## Assumptions

- Qwen3-TTS Base supports the ten language identifiers currently declared by its model configuration plus `auto`.
- Auto-detection occurs inside Qwen3-TTS from target text and does not return a detected-language value.
- The model's 2,048-token generation cap remains part of the synthesis workflow; this stage does not estimate tokens or silently shorten input.
- Reference transcript editing belongs to stage 1 and remains independent of target-language changes.
- Input controls are locked during synthesis because the current backend run is not safely cancellable mid-generation.
- Auto-detect is the user-selected default; English and system-language defaults were explicitly rejected.

## Success Criteria

### Measurable Outcomes

- **SC-001**: All eleven picker options map one-to-one to the model-supported raw values.
- **SC-002**: Empty and whitespace-only inputs are rejected in 100% of focused readiness checks.
- **SC-003**: Non-empty Unicode and multiline text reaches synthesis without transliteration or silent truncation.
- **SC-004**: Changing text or language removes all stale synthesis-derived state before the next user action.
- **SC-005**: Input controls remain non-editable for the full duration of an active synthesis run.
- **SC-006**: Focused language and input tests pass without loading the voice model.
- **SC-007**: The macOS application builds successfully with zero project-code compilation errors.
