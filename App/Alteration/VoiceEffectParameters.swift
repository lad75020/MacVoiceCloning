import Foundation

/// User-facing Rubber Band controls.
nonisolated struct VoiceEffectParameters: Equatable, Sendable {
    enum Engine: String, CaseIterable, Sendable, Identifiable {
        case r3Finer
        case r2Faster

        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .r3Finer: "R3 (finer)"
            case .r2Faster: "R2 (faster)"
            }
        }
    }

    /// -12…+12 semitones → Rubber Band pitch scale 2^(n/12).
    var pitchSemitones: Double = 0
    /// 0.5…2.0× playback speed → Rubber Band time ratio 1/speed.
    var speed: Double = 1.0
    /// Keeps the vocal tract character while shifting pitch.
    var preserveFormants: Bool = true
    /// 0.5…2.0 timbre control (independent formant shift; R3 engine only).
    var formantScale: Double = 1.0
    var engine: Engine = .r3Finer

    var pitchScale: Double { pow(2.0, pitchSemitones / 12.0) }
    var timeRatio: Double { 1.0 / speed }

    /// True when processing would not change the audio.
    var isIdentity: Bool {
        pitchSemitones == 0 && speed == 1.0
            && (formantScale == 1.0 || engine == .r2Faster)
    }

    nonisolated struct Preset: Identifiable, Sendable {
        let name: String
        let parameters: VoiceEffectParameters
        var id: String { name }
    }

    static let presets: [Preset] = [
        Preset(name: "Chipmunk", parameters: .init(pitchSemitones: 7, speed: 1.15, preserveFormants: false)),
        Preset(name: "Deep Voice", parameters: .init(pitchSemitones: -5, formantScale: 0.85)),
        Preset(name: "Helium", parameters: .init(pitchSemitones: 2, formantScale: 1.4)),
        Preset(name: "Giant", parameters: .init(pitchSemitones: -7, speed: 0.9, formantScale: 0.8)),
        Preset(name: "Slow Motion", parameters: .init(speed: 0.6)),
        Preset(name: "Fast Talker", parameters: .init(speed: 1.5)),
    ]
}
