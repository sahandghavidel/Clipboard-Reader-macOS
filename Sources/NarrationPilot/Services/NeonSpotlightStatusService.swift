import AppKit
import Foundation

enum NeonSpotlightWaitResult: Equatable {
    case notRunning
    case alreadyIdle
    case completed
    case appTerminated
    case responseTimedOut
    case animationTimedOut
    case cancelled
}

struct NeonSpotlightAnimationSnapshot: Equatable {
    enum State: String {
        case idle
        case busy
    }

    enum Reason: String {
        case launched
        case activityChanged
        case requested
        case terminating
    }

    let protocolVersion: Int
    let sessionIdentifier: String
    let state: State
    let activeAnimationCount: Int
    let requestIdentifier: String?
    let reason: Reason

    init?(userInfo: [AnyHashable: Any]?) {
        guard let userInfo,
              let protocolVersion = userInfo[
                NeonSpotlightStatusProtocol.Key.protocolVersion
              ] as? Int,
              protocolVersion == NeonSpotlightStatusProtocol.version,
              let sessionIdentifier = userInfo[
                NeonSpotlightStatusProtocol.Key.sessionIdentifier
              ] as? String,
              !sessionIdentifier.isEmpty,
              let stateValue = userInfo[
                NeonSpotlightStatusProtocol.Key.state
              ] as? String,
              let state = State(rawValue: stateValue),
              let activeAnimationCount = userInfo[
                NeonSpotlightStatusProtocol.Key.activeAnimationCount
              ] as? Int,
              activeAnimationCount >= 0,
              let reasonValue = userInfo[
                NeonSpotlightStatusProtocol.Key.reason
              ] as? String,
              let reason = Reason(rawValue: reasonValue) else {
            return nil
        }

        guard (state == .idle && activeAnimationCount == 0)
                || (state == .busy && activeAnimationCount > 0) else {
            return nil
        }

        self.protocolVersion = protocolVersion
        self.sessionIdentifier = sessionIdentifier
        self.state = state
        self.activeAnimationCount = activeAnimationCount
        self.requestIdentifier = userInfo[
            NeonSpotlightStatusProtocol.Key.requestIdentifier
        ] as? String
        self.reason = reason
    }
}

enum NeonSpotlightStatusProtocol {
    static let version = 1
    static let bundleIdentifier = "com.sahand.neonspotlight"
    static let requestNotification = Notification.Name(
        "com.sahand.neonspotlight.animation-status.request"
    )
    static let statusNotification = Notification.Name(
        "com.sahand.neonspotlight.animation-status.status"
    )

    enum Key {
        static let protocolVersion = "protocolVersion"
        static let sessionIdentifier = "sessionIdentifier"
        static let state = "state"
        static let activeAnimationCount = "activeAnimationCount"
        static let requestIdentifier = "requestIdentifier"
        static let reason = "reason"
    }
}

@MainActor
final class NeonSpotlightStatusService: NSObject {
    private struct Waiter {
        let continuation: CheckedContinuation<NeonSpotlightWaitResult, Never>
        var sessionIdentifier: String?
        var receivedResponse = false
        var sawBusyAnimation = false
        var responseTimeoutTask: Task<Void, Never>?
        var animationTimeoutTask: Task<Void, Never>?
        var settleTask: Task<Void, Never>?
    }

    static let responseTimeout: Duration = .milliseconds(600)
    static let animationTimeout: Duration = .seconds(10)
    static let completionBuffer: Duration = .milliseconds(150)

    private let notificationCenter: DistributedNotificationCenter
    private var waiters: [UUID: Waiter] = [:]

    init(notificationCenter: DistributedNotificationCenter = .default()) {
        self.notificationCenter = notificationCenter
        super.init()
        notificationCenter.addObserver(
            self,
            selector: #selector(receiveStatusNotification(_:)),
            name: NeonSpotlightStatusProtocol.statusNotification,
            object: nil
        )
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    func waitUntilIdle() async -> NeonSpotlightWaitResult {
        guard isNeonSpotlightRunning else { return .notRunning }

        let requestIdentifier = UUID()
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                var waiter = Waiter(continuation: continuation)
                waiter.responseTimeoutTask = Task { @MainActor [weak self] in
                    try? await Task.sleep(for: Self.responseTimeout)
                    guard !Task.isCancelled else { return }
                    self?.finishWait(
                        requestIdentifier,
                        result: .responseTimedOut
                    )
                }
                waiters[requestIdentifier] = waiter
                notificationCenter.postNotificationName(
                    NeonSpotlightStatusProtocol.requestNotification,
                    object: nil,
                    userInfo: [
                        NeonSpotlightStatusProtocol.Key.requestIdentifier:
                            requestIdentifier.uuidString,
                    ],
                    deliverImmediately: true
                )
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                self?.finishWait(requestIdentifier, result: .cancelled)
            }
        }
    }

    @objc
    private func receiveStatusNotification(_ notification: Notification) {
        guard let snapshot = NeonSpotlightAnimationSnapshot(
            userInfo: notification.userInfo
        ) else {
            return
        }

        if snapshot.reason == .requested,
           let requestValue = snapshot.requestIdentifier,
           let requestIdentifier = UUID(uuidString: requestValue) {
            receiveRequestedSnapshot(snapshot, for: requestIdentifier)
            return
        }

        for requestIdentifier in Array(waiters.keys) {
            receiveActivitySnapshot(snapshot, for: requestIdentifier)
        }
    }

    private func receiveRequestedSnapshot(
        _ snapshot: NeonSpotlightAnimationSnapshot,
        for requestIdentifier: UUID
    ) {
        guard var waiter = waiters[requestIdentifier] else { return }
        waiter.receivedResponse = true
        waiter.sessionIdentifier = snapshot.sessionIdentifier
        waiter.responseTimeoutTask?.cancel()
        waiter.responseTimeoutTask = nil

        waiters[requestIdentifier] = waiter
        receiveActivitySnapshot(snapshot, for: requestIdentifier)
    }

    private func receiveActivitySnapshot(
        _ snapshot: NeonSpotlightAnimationSnapshot,
        for requestIdentifier: UUID
    ) {
        guard var waiter = waiters[requestIdentifier],
              waiter.receivedResponse,
              waiter.sessionIdentifier == snapshot.sessionIdentifier else {
            return
        }

        if snapshot.reason == .terminating {
            waiters[requestIdentifier] = waiter
            finishWait(requestIdentifier, result: .appTerminated)
            return
        }

        waiter.settleTask?.cancel()
        waiter.settleTask = nil
        if snapshot.state == .idle {
            let result: NeonSpotlightWaitResult = waiter.sawBusyAnimation
                ? .completed
                : .alreadyIdle
            waiter.settleTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: Self.completionBuffer)
                guard !Task.isCancelled else { return }
                self?.finishWait(requestIdentifier, result: result)
            }
        } else {
            waiter.sawBusyAnimation = true
            if waiter.animationTimeoutTask == nil {
                waiter.animationTimeoutTask = Task { @MainActor [weak self] in
                    try? await Task.sleep(for: Self.animationTimeout)
                    guard !Task.isCancelled else { return }
                    self?.finishWait(
                        requestIdentifier,
                        result: .animationTimedOut
                    )
                }
            }
        }
        waiters[requestIdentifier] = waiter
    }

    private func finishWait(
        _ requestIdentifier: UUID,
        result: NeonSpotlightWaitResult
    ) {
        guard let waiter = waiters.removeValue(forKey: requestIdentifier) else {
            return
        }
        waiter.responseTimeoutTask?.cancel()
        waiter.animationTimeoutTask?.cancel()
        waiter.settleTask?.cancel()
        waiter.continuation.resume(returning: result)
    }

    private var isNeonSpotlightRunning: Bool {
        !NSRunningApplication.runningApplications(
            withBundleIdentifier: NeonSpotlightStatusProtocol.bundleIdentifier
        ).isEmpty
    }
}
