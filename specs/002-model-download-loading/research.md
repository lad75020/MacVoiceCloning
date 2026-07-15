# Research: Model Download and Loading

## Decision 1: Retain the six-state lifecycle

**Decision**: Preserve not downloaded, downloading with progress, downloaded, loading, ready, and failed states.

**Rationale**: These states distinguish network transfer, on-disk availability, in-memory readiness, and recoverable failure. The status surface already maps each state to one meaningful action or progress indicator.

**Alternatives considered**:

- Merge downloaded and ready: rejected because users must be able to unload roughly 4 GB of memory without deleting files.
- Track generation busy state here: rejected because synthesis belongs to pipeline state and would mix independent lifecycles.

## Decision 2: Keep resumable snapshot transfer and tokenizer fallback

**Decision**: Continue using snapshot semantics that reuse valid local files and fetch a compatible tokenizer asset only when the primary snapshot lacks it.

**Rationale**: Multi-gigabyte transfers must survive interruption. A model snapshot without the required tokenizer is not usable even if weights are present.

**Alternatives considered**:

- Delete partial downloads before retry: rejected because it wastes bandwidth and removes resumability.
- Treat weights alone as complete: rejected because loading requires the tokenizer asset.

## Decision 3: Write completion evidence atomically with error propagation

**Decision**: Replace best-effort marker creation with a throwing atomic data write after the snapshot and tokenizer are ready.

**Rationale**: The lifecycle must not report a durable complete download when completion evidence could not be persisted. A throwing write routes failure through the existing download error state, while atomic replacement prevents partial marker content.

**Alternatives considered**:

- Ignore the boolean result of non-throwing file creation: rejected because a successful in-session load could hide a persistence failure and trigger unnecessary redownload behavior at next launch.
- Infer completeness from any downloaded file: rejected because partial snapshots can contain plausible files.

## Decision 4: Reveal an existing app-owned location

**Decision**: Reveal the model snapshot directory when it exists; otherwise reveal the models root.

**Rationale**: Finder selection of a nonexistent snapshot path is unreliable. The models root is prepared at launch and remains the correct privacy boundary before the first download.

**Alternatives considered**:

- Disable reveal before download: rejected because users may need to inspect partial transfer files.
- Create the final snapshot directory solely for reveal: rejected because it can make an empty path look like a real snapshot.

## Decision 5: Test completeness with temporary local directories

**Decision**: Instantiate the downloader with an isolated temporary root, derive its local snapshot location, and test tokenizer/marker combinations without network access.

**Rationale**: Completion detection is deterministic local filesystem behavior. Network download and multi-gigabyte model loading are unsuitable for the fast focused suite.

**Alternatives considered**:

- Download the real model in tests: rejected due size, latency, network dependence, and cost.
- Verify only by source inspection: rejected because a small behavioral unit test provides stronger regression protection.
