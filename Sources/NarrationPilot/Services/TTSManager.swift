import AppKit
import AVFoundation
import Foundation

final class TTSManager: NSObject, ObservableObject {
    @Published private(set) var state: SpeechState = .idle
    @Published private(set) var resolvedVoiceDescription: String = "System Default"
    @Published private(set) var resolvedVoiceNote: String?
    @Published private(set) var completedUtteranceCount = 0

    private let synthesizer = AVSpeechSynthesizer()
    private let systemSynthesizer = NSSpeechSynthesizer()

    private static let systemBaseRateWPM: Float = 175

    private enum ActiveEngine {
        case none
        case avSpeech
        case systemSpeech
    }

    private var activeEngine: ActiveEngine = .none

    override init() {
        super.init()
        synthesizer.delegate = self
        systemSynthesizer.delegate = self
    }

    func speak(
        text: String,
        speedMultiplier: Double,
        voiceIdentifier: String?,
        includesBracketedDirections: Bool = false
    ) {
        let spokenText = SpokenTextSanitizer.preparingForSpeech(
            text,
            includesBracketedDirections: includesBracketedDirections
        )
        guard !spokenText.isEmpty else {
            return
        }

        stopActiveSpeechBeforeStarting()

        if shouldUseSystemDefaultSpeechRoute(for: voiceIdentifier) {
            speakWithSystemDefaultSynthesizer(text: spokenText, speedMultiplier: speedMultiplier)
            return
        }

        speakWithAVSpeech(text: spokenText, speedMultiplier: speedMultiplier, voiceIdentifier: voiceIdentifier)
    }

    private func shouldUseSystemDefaultSpeechRoute(for voiceIdentifier: String?) -> Bool {
        guard let voiceIdentifier, !voiceIdentifier.isEmpty else {
            return true
        }

        return AVSpeechSynthesisVoice(identifier: voiceIdentifier) == nil
    }

    private func speakWithSystemDefaultSynthesizer(text: String, speedMultiplier: Double) {
        systemSynthesizer.rate = mappedSystemRate(multiplier: speedMultiplier)
        resolvedVoiceDescription = "System Default (macOS Spoken Content)"
        resolvedVoiceNote = systemVoiceNoteForSystemRoute()

        state = .speaking
        activeEngine = .systemSpeech

        let started = systemSynthesizer.startSpeaking(text)
        if !started {
            // Fallback if system synthesizer fails to start.
            activeEngine = .none
            resolvedVoiceDescription = "AVSpeech Default"
            resolvedVoiceNote = "System speech engine failed; fell back to AVSpeech."

            let utterance = AVSpeechUtterance(string: text)
            utterance.rate = SpeechRateMapper.utteranceRate(for: speedMultiplier)
            utterance.voice = nil
            utterance.prefersAssistiveTechnologySettings = true

            state = .speaking
            activeEngine = .avSpeech
            synthesizer.speak(utterance)
        }
    }

    private func speakWithAVSpeech(text: String, speedMultiplier: Double, voiceIdentifier: String?) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = SpeechRateMapper.utteranceRate(for: speedMultiplier)
        if let voiceIdentifier,
           let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
            utterance.voice = voice
            utterance.prefersAssistiveTechnologySettings = false
            resolvedVoiceDescription = "\(voice.name) (\(voice.language))"
            resolvedVoiceNote = nil
        } else {
            utterance.voice = nil
            utterance.prefersAssistiveTechnologySettings = true
            resolvedVoiceDescription = "AVSpeech Default"
            resolvedVoiceNote = nil
        }

        state = .speaking
        activeEngine = .avSpeech
        synthesizer.speak(utterance)
    }

    private func stopActiveSpeechBeforeStarting() {
        if activeEngine == .systemSpeech || systemSynthesizer.isSpeaking {
            systemSynthesizer.stopSpeaking(at: .immediateBoundary)
        }

        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }

        activeEngine = .none
    }

    private func mappedSystemRate(multiplier: Double) -> Float {
        let clamped = SpeechRateMapper.clampMultiplier(multiplier)
        return Float(Float(Self.systemBaseRateWPM) * Float(clamped))
    }

    private struct SpokenContentPreference {
        let voiceID: String?
        let language: String?
    }

    private func readSystemSpeechLanguage() -> String? {
        UserDefaults(suiteName: "com.apple.speech.voice.prefs")?.string(forKey: "SystemTTSLanguage")
    }

    private func readSpokenContentPreference() -> SpokenContentPreference? {
        guard let rawValues = UserDefaults(suiteName: "com.apple.Accessibility")?
            .array(forKey: "SpokenContentDefaultVoiceSelectionsByLanguage")
        else {
            return nil
        }

        let targetLanguage = readSystemSpeechLanguage()?.lowercased()
        var firstPreference: SpokenContentPreference?

        var index = 0
        while index + 1 < rawValues.count {
            guard let language = rawValues[index] as? String,
                  let payload = rawValues[index + 1] as? [String: Any]
            else {
                index += 1
                continue
            }

            let preference = SpokenContentPreference(
                voiceID: payload["voiceId"] as? String,
                language: (payload["boundLanguage"] as? String) ?? language
            )

            if firstPreference == nil {
                firstPreference = preference
            }

            if let targetLanguage,
               language.lowercased().hasPrefix(targetLanguage) {
                return preference
            }

            index += 2
        }

        return firstPreference
    }

    private func systemVoiceNoteForSystemRoute() -> String {
        guard let preference = readSpokenContentPreference() else {
            return "Using macOS spoken-content system voice."
        }

        if let voiceID = preference.voiceID,
           voiceID.localizedCaseInsensitiveContains(".siri.") {
            return "Using macOS spoken-content Siri voice via system speech engine."
        }

        if let voiceID = preference.voiceID, !voiceID.isEmpty {
            return "Using macOS spoken-content voice: \(voiceID)"
        }

        if let language = preference.language {
            return "Using macOS spoken-content voice for language: \(language)"
        }

        return "Using macOS spoken-content system voice."
    }

    func stop() {
        let avActive = synthesizer.isSpeaking || synthesizer.isPaused
        let systemActive = activeEngine == .systemSpeech || systemSynthesizer.isSpeaking

        guard avActive || systemActive else {
            state = .idle
            return
        }

        state = .stopping

        if systemActive {
            systemSynthesizer.stopSpeaking(at: .immediateBoundary)
        }

        if avActive {
            synthesizer.stopSpeaking(at: .immediate)
        }

        activeEngine = .none
        state = .idle
    }

    func togglePauseResume() {
        if activeEngine == .systemSpeech {
            switch state {
            case .speaking:
                systemSynthesizer.pauseSpeaking(at: .wordBoundary)
                state = .paused
            case .paused:
                systemSynthesizer.continueSpeaking()
                state = .speaking
            case .idle, .stopping:
                break
            }
            return
        }

        switch state {
        case .speaking:
            if synthesizer.pauseSpeaking(at: .word) {
                state = .paused
            }
        case .paused:
            if synthesizer.continueSpeaking() {
                state = .speaking
            }
        case .idle, .stopping:
            break
        }
    }
}

extension TTSManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.activeEngine = .none
            self.state = .idle
            self.completedUtteranceCount += 1
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.activeEngine = .none
            self.state = .idle
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.state = .paused
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.state = .speaking
        }
    }
}

extension TTSManager: NSSpeechSynthesizerDelegate {
    func speechSynthesizer(_ sender: NSSpeechSynthesizer, didFinishSpeaking finishedSpeaking: Bool) {
        DispatchQueue.main.async {
            guard self.activeEngine == .systemSpeech else {
                return
            }

            self.activeEngine = .none
            self.state = .idle
            if finishedSpeaking {
                self.completedUtteranceCount += 1
            }
        }
    }
}
