# Multilingual Input Contract

## Purpose

Define the exact target-text and language values supplied to local Qwen3-TTS synthesis and the lifecycle of output derived from those inputs.

## Target Text Contract

1. Provide a multiline Unicode editor.
2. Preserve the bound value exactly while editing.
3. Treat the value as empty when whitespace/newline trimming yields an empty string.
4. Show placeholder guidance for effectively empty input.
5. Pass a boundary-trimmed value to synthesis.
6. Do not transliterate, silently truncate, or estimate tokens in stage 2.
7. Preserve the selected language while text changes.

## Language Catalog Contract

| Order | Case | Raw value | Display name |
|---:|---|---|---|
| 1 | `auto` | `auto` | Auto-detect |
| 2 | `english` | `english` | English |
| 3 | `chinese` | `chinese` | Chinese |
| 4 | `japanese` | `japanese` | Japanese |
| 5 | `korean` | `korean` | Korean |
| 6 | `german` | `german` | German |
| 7 | `french` | `french` | French |
| 8 | `russian` | `russian` | Russian |
| 9 | `portuguese` | `portuguese` | Portuguese |
| 10 | `spanish` | `spanish` | Spanish |
| 11 | `italian` | `italian` | Italian |

## Selection Contract

1. Auto-detect is selected for a new pipeline.
2. Picker identity equals the backend raw value.
3. Auto-detect passes `auto` without app-side detection.
4. Explicit selection passes the exact lowercase full-name identifier.
5. Text edits do not change selection.
6. Selection changes do not alter reference audio or transcript.

## Derived-State Contract

When target text or language changes to a different value:

1. Cancel pending alteration work.
2. Clear synthesis audio.
3. Clear synthesis statistics.
4. Clear altered audio.
5. Reset synthesis progress.
6. Keep reference audio, reference transcript, and effect parameters.

Assigning the same value performs no invalidation.

## Active-Synthesis Contract

1. Disable the target-text editor while synthesis is active.
2. Disable the language picker while synthesis is active.
3. Keep current values visible.
4. Re-enable both controls when synthesis finishes or fails.

## Request Contract

A synthesis request receives:

- `text`: Current target text trimmed at its boundaries.
- `language`: Current selected enum case.
- `referenceAudioURL`: Unchanged accepted reference.
- `referenceText`: Unchanged reference transcript.
- `maxTokens`: Existing generation cap.

The request default language is Auto-detect.
