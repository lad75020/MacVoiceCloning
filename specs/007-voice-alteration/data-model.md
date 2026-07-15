# Data Model: Voice Alteration

## Effect Configuration

Represents the complete user-selected transformation.

| Field | Type | Validation | Notes |
|---|---|---|---|
| `pitchSemitones` | Number | Finite; -12...12 | Converts to scale `2^(value/12)` |
| `speed` | Number | Finite; 0.5...2.0 | Converts to time ratio `1/value` |
| `preserveFormants` | Boolean | Always valid | Independent formant-preservation policy |
| `formantScale` | Number | Finite; 0.5...2.0 | Applied only by R3 Finer |
| `engine` | Engine | R3 Finer or R2 Faster | Controls processor engine option |

### Derived state

- **Identity**: neutral pitch and speed, plus neutral formant scale or an engine that ignores independent formant scale.
- **Pitch scale**: exponential semitone conversion.
- **Time ratio**: reciprocal of speed.
- **Applicable formant scale**: selected scale under R3; neutral under R2.

## Effect Preset

| Field | Type | Rules |
|---|---|---|
| `name` | String | Stable, unique, non-empty user-facing identifier |
| `parameters` | Effect Configuration | Complete replacement configuration |

A preset replaces the whole current configuration. Reset uses a neutral configuration.

## Synthesis Clip

Immutable source for each alteration request.

| Field | Type | Validation |
|---|---|---|
| `samples` | Float array | Non-empty for processing; every output sample finite |
| `sampleRate` | Integer | Greater than zero |
| `url` | Local file URL | Existing stable synthesis artifact |
| `duration` | Derived time | `samples.count / sampleRate` |

## Alteration Request

| Field | Type | Rules |
|---|---|---|
| `revision` | Unsigned integer | Monotonically increases when a new request supersedes an older one |
| `source` | Synthesis Clip snapshot | Always original synthesis, never an altered clip |
| `parameters` | Effect Configuration snapshot | Validated before processing |
| `stagingURL` | Local file URL | Unique to the request revision |

### Lifecycle

```text
scheduled → debouncing → processing → writing → current-check → committed → published
     └────────────── superseded/cancelled ──────────────→ discarded
                                 └──── failure ─────────→ previous preview retained
```

Only the current revision may transition from `current-check` to `committed`.

## Altered Clip

The last successfully committed transformed result.

| Field | Type | Rules |
|---|---|---|
| `samples` | Float array | Non-empty, finite |
| `sampleRate` | Integer | Same as source |
| `url` | Local file URL | Stable altered preview URL |
| `revision` | Unsigned integer | Matches the request that published it |
| `parameters` | Effect Configuration | Matches the audible result |

The prior Altered Clip remains effective while a replacement is pending or fails.

## Effective Preview

Derived playback selection:

1. If bypass is on, use Synthesis Clip.
2. Else if current settings are identity, use Synthesis Clip.
3. Else if an Altered Clip exists, use the last successful Altered Clip, including while replacement is pending.
4. Else use Synthesis Clip until the first altered result succeeds.

Bypass does not mutate an Alteration Request or Altered Clip.
