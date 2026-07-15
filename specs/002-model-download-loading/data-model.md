# Data Model: Model Download and Loading

## Model Lifecycle

Represents model availability and the operation currently visible to the user.

### States

- `notDownloaded`: No valid completion evidence and tokenizer combination exists.
- `downloading(progress)`: Snapshot transfer is active; progress is normalized from zero through one.
- `downloaded`: A complete snapshot is on disk but no engine is loaded.
- `loading`: Engine initialization is active.
- `ready`: A loaded engine is available for local synthesis.
- `failed(message)`: The most recent download or load operation failed with contextual diagnostics.

### Transitions

```text
notDownloaded ──Download──> downloading
     downloading ──snapshot + tokenizer + marker──> downloaded
       downloaded ──Load──> loading
           loading ──success──> ready
             ready ──Unload──> downloaded
notDownloaded/downloading ──failure──> failed
       downloaded/loading ──failure──> failed
            failed ──Retry + complete snapshot──> loading
            failed ──Retry + incomplete snapshot──> downloading
```

### Invariants

- A loaded engine exists only in `ready`.
- `downloaded` means completion evidence and the tokenizer asset both exist.
- `downloading` exposes a normalized progress fraction.
- A new action replaces stale failure presentation with its active state.
- Unload never deletes snapshot files.

## Model Snapshot

The local collection of files needed to initialize the voice engine.

### Required Asset Classes

- Model configuration metadata.
- Model weight files.
- Vocabulary or merge data selected by snapshot matching.
- Required tokenizer JSON, supplied by the compatible fallback snapshot when absent.
- Durable completion evidence written only after required retrieval succeeds.

### Validation Rules

- Snapshot transport success alone is insufficient.
- The tokenizer asset must exist.
- Completion evidence must exist.
- Evidence write failure leaves the lifecycle failed/incomplete.

## Completion Evidence

A local zero-length marker used to distinguish a complete usable snapshot from a resumable partial snapshot.

### Lifecycle

1. Absent during partial transfer.
2. Written atomically after primary snapshot and tokenizer preparation.
3. Read together with tokenizer existence at launch and retry.
4. Retained when the model is unloaded.

## Loaded Engine

The in-memory resource that performs synthesis after successful initialization.

### Rules

- Created from the downloaded snapshot location.
- Assigned only after load succeeds.
- Cleared after load failure.
- Unloaded and cleared when the user reclaims memory.

## Model Location

App-owned Application Support storage containing the model-hosting client cache.

### Reveal Selection

- Existing model snapshot: select the snapshot directory.
- Snapshot not yet present: select the existing models root.
