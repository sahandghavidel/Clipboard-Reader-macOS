import AppKit

enum RecordingCueSound: String, CaseIterable, Identifiable {
    case none
    case basso = "Basso"
    case bottle = "Bottle"
    case glass = "Glass"
    case hero = "Hero"
    case ping = "Ping"
    case pop = "Pop"
    case purr = "Purr"
    case submarine = "Submarine"
    case tink = "Tink"

    var id: String { rawValue }

    var title: String {
        self == .none ? "None" : rawValue
    }

    func play() {
        guard self != .none else {
            return
        }

        NSSound(named: NSSound.Name(rawValue))?.play()
    }
}

enum RecordingFailureCueSound: String, CaseIterable, Identifiable {
    case sameAsStop
    case none
    case basso = "Basso"
    case bottle = "Bottle"
    case glass = "Glass"
    case hero = "Hero"
    case ping = "Ping"
    case pop = "Pop"
    case purr = "Purr"
    case submarine = "Submarine"
    case tink = "Tink"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sameAsStop:
            return "Same as Stop Sound"
        case .none:
            return "None"
        default:
            return rawValue
        }
    }

    func resolvedSound(stopSound: RecordingCueSound) -> RecordingCueSound {
        switch self {
        case .sameAsStop:
            return stopSound
        case .none:
            return .none
        default:
            return RecordingCueSound(rawValue: rawValue) ?? .none
        }
    }
}
