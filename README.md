# MacVoiceCloning

A macOS 26+ voice cloning app (Swift 6.2, SwiftUI). Record a short sample of your voice,
type any text, synthesize it in your cloned voice with **Qwen3-TTS Base** (running fully
on-device via MLX), reshape the result with **Rubber Band** pitch/time/formant controls,
and export the final audio as WAV or M4A.

## Requirements

- macOS 26.0+ on Apple Silicon
- Xcode 26+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Build

```bash
xcodegen generate
open MacVoiceCloning.xcodeproj   # or: xcodebuild -scheme MacVoiceCloning build
```

On first use the app downloads the `mlx-community/Qwen3-TTS-12Hz-1.7B-Base-bf16` model
(~3.5 GB) to `~/Library/Application Support/MacVoiceCloning/Models/`.

## Licenses

- App code: MIT
- [swift-qwen3-tts](https://github.com/AtomGradient/swift-qwen3-tts): MIT
- [Rubber Band Library](https://breakfastquay.com/rubberband/) (vendored in `Vendor/rubberband/`): **GPL-2.0** —
  this project as a whole is GPL-2.0 if redistributed
- Qwen3-TTS model weights: Apache 2.0 (per the [HF model card](https://huggingface.co/Qwen/Qwen3-TTS-12Hz-1.7B-Base))
