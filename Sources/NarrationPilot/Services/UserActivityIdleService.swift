import AppKit
import ApplicationServices
import Foundation

enum UserActivityIdleResult: Equatable {
    case idle
    case timedOut
    case monitoringUnavailable
    case cancelled
}

struct UserActivityIdlePolicy {
    static let defaultIdlePeriod = 1.0
    static let keyboardIdlePeriod = 2.5
    static let defaultMaximumWait = 10.0
    static let minimumIdlePeriod = 0.5
    static let maximumIdlePeriod = 3.0
    static let minimumMaximumWait = 3.0
    static let maximumMaximumWait = 30.0
    static let meaningfulPointerDistance = 4.0

    static func clampedIdlePeriod(_ value: Double) -> Double {
        min(maximumIdlePeriod, max(minimumIdlePeriod, value))
    }

    static func clampedMaximumWait(_ value: Double) -> Double {
        min(maximumMaximumWait, max(minimumMaximumWait, value))
    }
}

@MainActor
final class UserActivityIdleService {
    private static let monitoredEvents: NSEvent.EventTypeMask = [
        .mouseMoved,
        .leftMouseDragged,
        .rightMouseDragged,
        .otherMouseDragged,
        .leftMouseDown,
        .rightMouseDown,
        .otherMouseDown,
        .scrollWheel,
        .keyDown,
        .keyUp,
        .flagsChanged,
    ]

    private var lastActivityTime: TimeInterval = 0
    private var lastKeyboardActivityTime: TimeInterval?
    private var lastMeaningfulPointerLocation: CGPoint = .zero

    func waitUntilIdle(
        idlePeriod: Double,
        maximumWait: Double
    ) async -> UserActivityIdleResult {
        guard AXIsProcessTrusted() else {
            return .monitoringUnavailable
        }

        let resolvedIdlePeriod = UserActivityIdlePolicy.clampedIdlePeriod(
            idlePeriod
        )
        let startedAt = ProcessInfo.processInfo.systemUptime
        lastActivityTime = startedAt
        lastKeyboardActivityTime = nil
        lastMeaningfulPointerLocation = NSEvent.mouseLocation

        guard let monitor = NSEvent.addGlobalMonitorForEvents(
            matching: Self.monitoredEvents,
            handler: { [weak self] event in
                let isPointerMotion: Bool
                switch event.type {
                case .mouseMoved, .leftMouseDragged, .rightMouseDragged,
                     .otherMouseDragged:
                    isPointerMotion = true
                default:
                    isPointerMotion = false
                }
                let pointerLocation = isPointerMotion
                    ? event.locationInWindow
                    : .zero
                let isKeyboardActivity: Bool
                switch event.type {
                case .keyDown, .keyUp, .flagsChanged:
                    isKeyboardActivity = true
                default:
                    isKeyboardActivity = false
                }
                Task { @MainActor [weak self] in
                    self?.recordActivity(
                        isPointerMotion: isPointerMotion,
                        pointerLocation: pointerLocation,
                        isKeyboardActivity: isKeyboardActivity
                    )
                }
            }
        ) else {
            return .monitoringUnavailable
        }
        defer {
            NSEvent.removeMonitor(monitor)
        }

        while true {
            if Task.isCancelled {
                return .cancelled
            }

            let now = ProcessInfo.processInfo.systemUptime
            let pointerAndGeneralActivityIsIdle = now - lastActivityTime >= resolvedIdlePeriod
            let keyboardIsIdle = lastKeyboardActivityTime.map {
                now - $0 >= UserActivityIdlePolicy.keyboardIdlePeriod
            } ?? true
            if pointerAndGeneralActivityIsIdle, keyboardIsIdle {
                return .idle
            }

            try? await Task.sleep(for: .milliseconds(50))
        }
    }

    private func recordActivity(
        isPointerMotion: Bool,
        pointerLocation: CGPoint,
        isKeyboardActivity: Bool
    ) {
        if isPointerMotion {
            let xDistance = pointerLocation.x - lastMeaningfulPointerLocation.x
            let yDistance = pointerLocation.y - lastMeaningfulPointerLocation.y
            let threshold = UserActivityIdlePolicy.meaningfulPointerDistance
            guard xDistance * xDistance + yDistance * yDistance
                    >= threshold * threshold else {
                return
            }
            lastMeaningfulPointerLocation = pointerLocation
        }

        let now = ProcessInfo.processInfo.systemUptime
        lastActivityTime = now
        if isKeyboardActivity {
            lastKeyboardActivityTime = now
        }
    }
}
