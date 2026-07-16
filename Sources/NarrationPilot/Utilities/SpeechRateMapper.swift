import AVFoundation
import Foundation

enum SpeechRateMapper {
    static let minMultiplier = 0.25
    static let maxMultiplier = 2.5
    static let defaultMultiplier = 1.0

    static func clampMultiplier(_ value: Double) -> Double {
        min(max(value, minMultiplier), maxMultiplier)
    }

    static func utteranceRate(for multiplier: Double) -> Float {
        let clamped = clampMultiplier(multiplier)
        let mapped = Double(AVSpeechUtteranceDefaultSpeechRate) * clamped
        return Float(min(max(mapped, 0.1), 1.0))
    }
}
