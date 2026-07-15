# Data Model: Multilingual Text Input

## Target Text

Editable speech content for the next synthesis request.

### Fields

- `editableValue`: Exact Unicode string bound to the multiline editor.
- `synthesisValue`: `editableValue` with boundary whitespace and newlines removed.
- `isReady`: True when `synthesisValue` is non-empty.

### Rules

- Internal punctuation, Unicode, emoji, and line breaks are preserved.
- The editable value is never silently truncated or transliterated.
- Whitespace-only values are not synthesis-ready.
- A changed value invalidates all synthesis-derived state.
- Reassigning the same value has no effect.

## TTS Language

A stable model-compatible language choice.

### Fields

- `rawValue`: Lowercase identifier passed to Qwen3-TTS.
- `displayName`: Human-readable picker label.
- `localeIdentifier`: Optional BCP-47 locale used by best-effort reference transcription.
- `id`: Stable identity equal to `rawValue`.

### Catalog

| Display name | Raw value | Transcription locale |
|---|---|---|
| Auto-detect | `auto` | None |
| English | `english` | `en-US` |
| Chinese | `chinese` | `zh-CN` |
| Japanese | `japanese` | `ja-JP` |
| Korean | `korean` | `ko-KR` |
| German | `german` | `de-DE` |
| French | `french` | `fr-FR` |
| Russian | `russian` | `ru-RU` |
| Portuguese | `portuguese` | `pt-BR` |
| Spanish | `spanish` | `es-ES` |
| Italian | `italian` | `it-IT` |

### Rules

- Auto-detect is the initial selection.
- Each raw value appears exactly once.
- Explicit selection persists while target text changes.
- A changed selection invalidates synthesis-derived state.
- Reassigning the same selection has no effect.
- Language changes do not clear or re-transcribe the reference transcript.

## Synthesis Input Revision

The pair that identifies generated speech semantics.

### Fields

- `text`: Current non-empty synthesis value.
- `language`: Current TTS language.

### State Transition

```text
ready inputs ──generate──▶ current synthesis
current synthesis ──text/language changes──▶ invalidated
invalidated ──generate──▶ current synthesis
```

### Invalidated Derived State

- Synthesis audio
- Synthesis statistics
- Altered audio
- Synthesis progress

### Preserved State

- Accepted reference audio
- Reference transcript
- Voice effect parameters
- Model readiness

## Control Availability

### States

- `editable`: No synthesis run is active; editor and picker accept input.
- `locked`: Synthesis is active; editor and picker display values but do not mutate them.

### Invariant

The visible target text and selected language cannot diverge from an active synthesis request.
