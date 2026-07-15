import Foundation

/// Monotonic request gate used to reject stale asynchronous alteration results.
nonisolated struct AlterationRevisionGate: Equatable, Sendable {
    private(set) var current: UInt = 0

    @discardableResult
    mutating func advance() -> UInt {
        current &+= 1
        return current
    }

    func isCurrent(_ revision: UInt) -> Bool {
        current == revision
    }
}

/// User-facing Rubber Band controls.
nonisolated struct VoiceEffectParameters: Equatable, Sendable {
    static let pitchRange: ClosedRange<Double> = -12...12
    static let speedRange: ClosedRange<Double> = 0.5...2.0
    static let formantScaleRange: ClosedRange<Double> = 0.5...2.0

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

    init(
        pitchSemitones: Double = 0,
        speed: Double = 1.0,
        preserveFormants: Bool = true,
        formantScale: Double = 1.0,
        engine: Engine = .r3Finer
    ) {
        self.pitchSemitones = pitchSemitones
        self.speed = speed
        self.preserveFormants = preserveFormants
        self.formantScale = formantScale
        self.engine = engine
    }

    var pitchScale: Double { pow(2.0, pitchSemitones / 12.0) }
    var timeRatio: Double { 1.0 / speed }
    var applicableFormantScale: Double { engine == .r3Finer ? formantScale : 1.0 }

    /// True when processing would not change the audio.
    var isIdentity: Bool {
        pitchSemitones == 0 && speed == 1.0
            && (formantScale == 1.0 || engine == .r2Faster)
    }

    enum ValidationError: LocalizedError, Equatable {
        case invalidSampleRate(Int)
        case invalidPitch(Double)
        case invalidSpeed(Double)
        case invalidFormantScale(Double)

        var errorDescription: String? {
            switch self {
            case .invalidSampleRate(let sampleRate):
                "Sample rate must be greater than zero before voice alteration. Received \(sampleRate) Hz."
            case .invalidPitch(let pitch):
                "Pitch must be a finite whole-semitone value from -12 through +12. Received \(pitch)."
            case .invalidSpeed(let speed):
                "Speed must be a finite value from 0.5x through 2.0x. Received \(speed)."
            case .invalidFormantScale(let formantScale):
                "Formant scale must be a finite value from 0.5x through 2.0x. Received \(formantScale)."
            }
        }
    }

    func validate(sampleRate: Int) throws {
        guard sampleRate > 0 else { throw ValidationError.invalidSampleRate(sampleRate) }
        guard pitchSemitones.isFinite,
              Self.pitchRange.contains(pitchSemitones),
              pitchSemitones.rounded() == pitchSemitones
        else { throw ValidationError.invalidPitch(pitchSemitones) }
        guard speed.isFinite, Self.speedRange.contains(speed) else {
            throw ValidationError.invalidSpeed(speed)
        }
        guard formantScale.isFinite, Self.formantScaleRange.contains(formantScale) else {
            throw ValidationError.invalidFormantScale(formantScale)
        }
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
