# Research: Voice Clone Synthesis

## Decision 1: Represent Progress as Codec Tokens

**Decision**: Introduce a `SynthesisProgress` value carrying emitted codec-token count and deriving estimated audio duration at 12.5 tokens per second.

**Rationale**: Upstream `generateVoiceClone` invokes `onToken` once per generated top-level codec token and documents a 12.5 Hz codec rate. The existing division by 12.0 is close but semantically inaccurate and passes an untyped `Double` whose unit must be inferred.

**Alternatives considered**:

- Keep dividing token count by 12.0: rejected because it conflicts with upstream's documented codec rate.
- Report only token count: rejected because generated-audio duration is more useful during speech generation.
- Show determinate percent from `maxTokens`: rejected because the upstream implementation dynamically caps tokens by text length and normally stops at EOS before the cap.

## Decision 2: Validate Results Before Persistence

**Decision**: Give `SynthesisResult` a validation boundary requiring a positive sample rate, at least one sample, and only finite samples. Validate in both the concrete engine adapter and pipeline.

**Rationale**: The engine check catches malformed upstream output near its origin. The pipeline check protects against alternate or test engine implementations before audio persistence.

**Alternatives considered**:

- Rely on `AVAudioFile`: rejected because persistence errors are less actionable and non-finite samples may still be written.
- Validate only in the concrete adapter: rejected because `TTSEngine` admits other implementations.

## Decision 3: Stage Before Replacing Accepted WAV

**Decision**: Write the candidate to `synthesis-staging.wav`, then atomically replace `synthesis.wav` only after validation and revision checks.

**Rationale**: `AudioConverting.writeWAV` removes its destination before writing. Writing directly to the accepted destination can destroy a valid prior file if writing fails.

**Alternatives considered**:

- Write directly to `synthesis.wav`: rejected due prior-output loss.
- Keep uniquely named historical outputs: rejected as unnecessary storage growth for a single-session workflow.

## Decision 4: Preserve Previous Accepted State on Failure

**Decision**: Do not clear synthesis or alteration when same-input regeneration begins. Replace both only after a new candidate commits successfully.

**Rationale**: Laurent selected preservation of both prior synthesis and alteration. This supports immediate recovery from transient generation or storage errors.

**Alternatives considered**:

- Clear at generation start: rejected by clarification.
- Preserve synthesis but clear alteration: rejected by clarification.

Input changes still intentionally invalidate old output because it no longer corresponds to current text/language/reference state.

## Decision 5: Use a Monotonic Pipeline Revision

**Decision**: Increment a private synthesis revision whenever synthesis-derived state is invalidated. Capture it at generation start and gate progress, staging commit, and state publication on equality.

**Rationale**: UI controls are disabled during generation, but public model state can still change programmatically. A revision prevents an old asynchronous result from overwriting newer intent.

**Alternatives considered**:

- Depend only on disabled controls: rejected because it does not protect non-UI mutations.
- Compare all request fields after generation: rejected because the reference entity and future request fields make comparisons brittle.
- Cancel the generation task: rejected because upstream generation is a synchronous blocking call without reliable cooperative cancellation.

## Decision 6: Keep Smoke Inference Opt-In

**Decision**: Preserve the `MVC_TTS_SMOKE=1` gate and update only its typed progress callback and output validation expectations.

**Rationale**: Routine verification must not unexpectedly download about 3.5 GB or run model inference for up to an hour.

**Alternatives considered**:

- Run smoke test by default: rejected for cost and runtime.
- Remove smoke coverage: rejected because it is valuable for explicit end-to-end validation.

## Decision 7: Keep Inference Local and Serial

**Decision**: Retain `QwenTTSEngine` on its dedicated `DispatchSerialQueue` executor and exchange only Sendable Foundation values across the protocol.

**Rationale**: The model's synchronous generation can occupy a thread for minutes. The dedicated executor protects Swift's cooperative pool and keeps MLX values actor-confined.
