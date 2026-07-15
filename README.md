# MacVoiceCloning

A macOS 26+ voice cloning app (Swift 6.2, SwiftUI). Record a short sample of your voice,
type any text, synthesize it in your cloned voice with **Qwen3-TTS Base** (running fully
on-device via MLX), reshape the result with **Rubber Band** pitch/time/formant controls,
and export the final audio as WAV or M4A.

Everything runs locally — no audio or text leaves the Mac. The only network use is the
one-time model download from Hugging Face.

## Requirements

- macOS 26.0+ on Apple Silicon (≥16 GB RAM recommended; the loaded model uses ~4 GB)
- Xcode 26+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Build & run

```bash
xcodegen generate
open MacVoiceCloning.xcodeproj    # then ⌘R
```

The `.xcodeproj` is generated — `project.yml` is the source of truth; re-run
`xcodegen generate` after adding files.

## Using the app

1. **Model** — click *Download* in the status bar (~3.5 GB, resumable; stored in
   `~/Library/Application Support/MacVoiceCloning/Models`). The app loads it automatically
   on later launches.
2. **Record** — 5–15 s of clear speech (3 s minimum), or *Import…* an existing audio file.
   The transcript field auto-fills via on-device speech recognition; correct it if needed —
   its accuracy directly affects clone quality.
3. **Write** the text to synthesize and pick its language (10 languages supported).
4. **Generate** — progress shows seconds of audio produced (~6 codec tokens/s on an M4 Max,
   12 tokens ≈ 1 s of audio).
5. **Alter** — pitch (±12 st), speed (0.5–2×), timbre (formant scale), formant preservation,
   R3/R2 engine, plus presets (Chipmunk, Deep Voice, Helium, …). Changes re-process
   automatically; *Bypass* A/Bs against the unaltered synthesis.
6. **Save As…** — WAV (lossless) or M4A (AAC).

## Tests

```bash
# fast unit tests (no model needed)
xcodebuild test -project MacVoiceCloning.xcodeproj -scheme MacVoiceCloning \
  -destination 'platform=macOS,arch=arm64' \
  -only-testing:MacVoiceCloningTests/AudioConvertingTests \
  -only-testing:MacVoiceCloningTests/RubberBandProcessorTests

# end-to-end voice-clone smoke test (downloads the model on first run)
env TEST_RUNNER_MVC_TTS_SMOKE=1 xcodebuild test -project MacVoiceCloning.xcodeproj \
  -scheme MacVoiceCloning -destination 'platform=macOS,arch=arm64' \
  -only-testing:MacVoiceCloningTests/TTSSmokeTests
```

The smoke test fabricates a reference speaker with `say`, clones it, runs a Rubber Band
alteration, and round-trips an M4A export.

## Implementation notes

- **TTS**: [swift-qwen3-tts](https://github.com/AtomGradient/swift-qwen3-tts) (MLX), pinned by
  revision, isolated behind the `TTSEngine` protocol (`App/TTS/`) so another backend could be
  swapped in. Generation is synchronous and uncancellable upstream, so the engine actor runs
  on its own dispatch queue.
- **tokenizer.json**: the Qwen3-TTS HF repos don't ship one, but swift-transformers requires
  it; `ModelDownloader` fetches it from `Qwen/Qwen3-1.7B`, whose text vocab is byte-identical.
- **macOS 26 gotcha**: `AVAudioFile.read(into:)` returns short reads and throws past EOF —
  all readers loop with a `framePosition` guard (`App/Audio/AudioConverting.swift`).
- **Rubber Band**: vendored 4.0.0 single-compilation-unit build (`Vendor/rubberband/`),
  driven through the C API in offline two-pass mode (`App/Alteration/RubberBandProcessor.swift`).

## Licenses

- App code: MIT
- [swift-qwen3-tts](https://github.com/AtomGradient/swift-qwen3-tts): MIT
- [Rubber Band Library](https://breakfastquay.com/rubberband/) (vendored in `Vendor/rubberband/`): **GPL-2.0** —
  this project as a whole is GPL-2.0 if redistributed
- Qwen3-TTS model weights: Apache 2.0 (per the [HF model card](https://huggingface.co/Qwen/Qwen3-TTS-12Hz-1.7B-Base))
