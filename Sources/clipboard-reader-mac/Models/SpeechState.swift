import Foundation

enum SpeechState: Equatable {
    case idle
    case speaking
    case paused
    case stopping

    var label: String {
        switch self {
        case .idle:
            return "Ready"
        case .speaking:
            return "Reading clipboard…"
        case .paused:
            return "Paused"
        case .stopping:
            return "Stopping…"
        }
    }

    var pauseResumeTitle: String {
        switch self {
        case .paused:
            return "Resume Reading"
        default:
            return "Pause Reading"
        }
    }
}