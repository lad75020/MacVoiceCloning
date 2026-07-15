# Data Model: Application Shell and Session

## Application Session

Represents one open workflow window and owns the services that cooperate during its lifetime.

### Fields

- `model lifecycle`: current local model availability and readiness
- `pipeline`: shared workflow inputs, outputs, progress, effects, and errors
- `recorder`: current microphone capture state and metering
- `player`: the single active playback slot

### Invariants

- One session owns exactly one pipeline, recorder, and playback slot.
- Synthesis is ready only when the model and all required pipeline inputs are ready.
- Starting synthesis stops current playback first.
- Session state is in-memory and is not restored as a project after relaunch.

## Pipeline State

Represents the data flowing through the ordered workflow.

### Fields

- `reference sample`: optional prepared local voice sample
- `reference transcript`: editable text describing the reference speech
- `target text`: speech the clone should generate
- `language`: selected or automatically detected speech language
- `synthesis activity`: running flag and produced-audio progress
- `synthesis result`: optional generated audio clip and performance statistics
- `effect parameters`: current pitch, speed, timbre, formant, and engine choices
- `bypass`: whether preview uses the original synthesis
- `alteration activity`: running flag
- `altered result`: optional processed audio clip
- `last error`: optional user-facing failure description

### Relationships

- The reference sample and two text inputs are prerequisites for synthesis.
- A synthesis result is the prerequisite for alteration and export.
- An altered result supersedes the synthesis result as the export source.
- Bypass changes preview selection but not export-source selection.

### State Transitions

1. **Empty → Reference ready**: a prepared reference is accepted; any previous synthesis chain is invalidated.
2. **Reference ready → Inputs ready**: reference transcript and target text become non-empty.
3. **Inputs ready → Synthesizing**: model is ready and no synthesis is active; playback stops.
4. **Synthesizing → Synthesis ready**: generated audio and statistics are stored; alteration may be scheduled.
5. **Synthesis ready → Altering**: non-identity effects are applied.
6. **Altering → Altered ready**: processed audio becomes preview/export eligible.
7. **Any state → Error presented**: a recoverable failure populates the shared error state.
8. **Error presented → Prior workflow state**: dismissal clears only the error.

## Reference Sample

Represents a voice sample ready for downstream cloning.

### Fields

- local working-file location
- duration in seconds

### Validation Rules

- Must refer to an app-owned prepared file.
- Must meet the minimum duration enforced by the reference feature.
- Replacing it invalidates all downstream generated artifacts.

## Audio Clip

Represents generated or altered mono audio available to preview or export.

### Fields

- floating-point samples
- sample rate
- local working-file location
- duration derived from sample count and sample rate

### Validation Rules

- Sample rate must be positive.
- Duration is derived and is not independently mutable.
- The clip remains local until the user explicitly exports it.

## Working Locations

Represents the app-owned directory hierarchy used during launch and processing.

### Locations

- application support root
- model root
- current-session root
- raw recording
- prepared reference
- synthesis output
- altered output

### Invariants

- Model and session directories are prepared before output is written.
- A preparation failure is reported through the shared error state.
- User-selected final exports are outside this working-location model.

## Workflow Stage

Represents a numbered section of the main window.

### Fields

- number
- title
- content bound to shared session state

### Ordering

1. Record reference voice
2. Write target text
3. Synthesize cloned voice
4. Alter generated voice
5. Export final audio

Model status precedes the numbered stages and is not itself numbered.
