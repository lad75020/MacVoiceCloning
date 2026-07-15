# Research: Application Shell and Session

## Decision 1: Retain a single observable composition root

**Decision**: Keep one application model for model lifecycle, pipeline state, recording, and playback, and inject that shared model into the workflow view hierarchy.

**Rationale**: The five stages are parts of one user session and must observe consistent readiness, progress, clips, and errors. One composition root avoids duplicated service instances and keeps mutually exclusive playback enforceable.

**Alternatives considered**:

- Give each stage its own service instances: rejected because stages would drift and could play or process conflicting artifacts.
- Introduce a global singleton: rejected because explicit window-scoped ownership is easier to reason about and test.
- Persist the entire session as a document: rejected because resumable projects and multiple sessions are outside this feature.

## Decision 2: Keep pipeline orchestration in one state owner

**Decision**: Keep reference, text, synthesis, alteration, preview/export selection, progress, cancellation, and errors in one pipeline state owner.

**Rationale**: Upstream changes must invalidate downstream results atomically. Central ownership makes readiness and clip-selection rules explicit and prevents stage views from implementing conflicting business rules.

**Alternatives considered**:

- Store state independently in each view: rejected because view recreation could lose state and cross-stage invalidation would become fragile.
- Split every stage into a separate store now: rejected because the current scope is small and such a refactor would add coordination without user value.

## Decision 3: Centralize app-owned working paths

**Decision**: Keep model and current-session working locations centralized under the user’s Application Support directory.

**Rationale**: A single authority prevents path disagreement, keeps temporary workflow artifacts out of user-selected export locations, and supports local-only privacy expectations.

**Alternatives considered**:

- Use arbitrary temporary-directory paths: rejected because lifecycle and cleanup behavior would be less predictable.
- Ask users to choose a session folder: rejected because persistent projects are out of scope.
- Store raw audio in preferences: rejected because preferences are unsuitable for audio payloads.

## Decision 4: Surface launch preparation failures

**Decision**: Report a failure to prepare app-owned directories through the pipeline’s existing user-facing error state, while still refreshing model availability.

**Rationale**: Silent failure delays diagnosis until a later stage and violates the shell’s error contract. Reusing the current alert channel is the smallest consistent correction and avoids a second error system.

**Alternatives considered**:

- Continue ignoring the error: rejected because users receive no actionable feedback.
- Abort all launch work: rejected because model status can still be refreshed and the user may recover after dismissing the error.
- Add a dedicated launch-error view: rejected because the shared alert already provides the required interaction.

## Decision 5: Verify without expanding feature scope

**Decision**: Use a full app build, the repository’s fast unit tests, and a focused contract check for the launch-error path. Do not alter model, recording, synthesis, playback, alteration, or export internals.

**Rationale**: This is a retro-specification of an existing feature with one narrow behavior gap. Broad new test-target wiring or stage refactors would create more risk than the correction itself.

**Alternatives considered**:

- Add a new UI automation suite: deferred because it requires infrastructure beyond this feature.
- Run the model smoke test by default: rejected because it downloads and loads a multi-gigabyte model and is not needed to verify shell orchestration.
- Verify only by source inspection: rejected because the real Xcode build and current fast tests provide stronger regression evidence.
