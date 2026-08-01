import AVFoundation
import Combine
import Foundation
import KeyboardShortcuts
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var speechState: SpeechState = .idle
    @Published var statusMessage: String = SpeechState.idle.label
    @Published private(set) var outputVoiceDescription: String = "System Default"
    @Published private(set) var outputVoiceNote: String?
    @Published private(set) var isShortcutTriggerAccessibilityTrusted: Bool
    @Published private(set) var recordingTriggerShortcut: TriggerShortcut?
    @Published var typedText: String = ""

    @Published var readShortcutOneDelayBefore: Double {
        didSet { persistTriggerDelay(readShortcutOneDelayBefore, key: Self.readShortcutOneDelayBeforeKey) }
    }
    @Published var readShortcutOneDelayAfter: Double {
        didSet { persistTriggerDelay(readShortcutOneDelayAfter, key: Self.readShortcutOneDelayAfterKey) }
    }
    @Published var readShortcutTwoDelayBefore: Double {
        didSet { persistTriggerDelay(readShortcutTwoDelayBefore, key: Self.readShortcutTwoDelayBeforeKey) }
    }
    @Published var readShortcutTwoDelayAfter: Double {
        didSet { persistTriggerDelay(readShortcutTwoDelayAfter, key: Self.readShortcutTwoDelayAfterKey) }
    }
    @Published var readClipboardAlwaysDelayBefore: Double {
        didSet { persistTriggerDelay(readClipboardAlwaysDelayBefore, key: Self.readClipboardAlwaysDelayBeforeKey) }
    }
    @Published var readClipboardAlwaysDelayAfter: Double {
        didSet { persistTriggerDelay(readClipboardAlwaysDelayAfter, key: Self.readClipboardAlwaysDelayAfterKey) }
    }
    @Published var readClipboardAlwaysTwoDelayBefore: Double {
        didSet { persistTriggerDelay(readClipboardAlwaysTwoDelayBefore, key: Self.readClipboardAlwaysTwoDelayBeforeKey) }
    }
    @Published var readClipboardAlwaysTwoDelayAfter: Double {
        didSet { persistTriggerDelay(readClipboardAlwaysTwoDelayAfter, key: Self.readClipboardAlwaysTwoDelayAfterKey) }
    }
    @Published var readClipboardAlwaysThreeDelayBefore: Double {
        didSet { persistTriggerDelay(readClipboardAlwaysThreeDelayBefore, key: Self.readClipboardAlwaysThreeDelayBeforeKey) }
    }
    @Published var readClipboardAlwaysThreeDelayAfter: Double {
        didSet { persistTriggerDelay(readClipboardAlwaysThreeDelayAfter, key: Self.readClipboardAlwaysThreeDelayAfterKey) }
    }

    @Published var readShortcutOneActionBefore: ExternalTriggerAction {
        didSet {
            persistExternalTriggerAction(
                readShortcutOneActionBefore,
                actionKey: Self.readShortcutOneActionBeforeKey,
                legacyBoolKey: Self.readShortcutOneTriggerBeforeKey
            )
            refreshShortcutTriggerAccessibilityStatus()
        }
    }

    @Published var readShortcutOneActionAfter: ExternalTriggerAction {
        didSet {
            persistExternalTriggerAction(
                readShortcutOneActionAfter,
                actionKey: Self.readShortcutOneActionAfterKey,
                legacyBoolKey: Self.readShortcutOneTriggerAfterKey
            )
            refreshShortcutTriggerAccessibilityStatus()
        }
    }

    @Published var readShortcutOneSpeedMultiplier: Double {
        didSet {
            let clamped = SpeechRateMapper.clampMultiplier(readShortcutOneSpeedMultiplier)
            if clamped != readShortcutOneSpeedMultiplier {
                readShortcutOneSpeedMultiplier = clamped
                return
            }

            defaults.set(clamped, forKey: Self.readShortcutOneSpeedKey)
        }
    }

    @Published var readShortcutTwoActionBefore: ExternalTriggerAction {
        didSet {
            persistExternalTriggerAction(
                readShortcutTwoActionBefore,
                actionKey: Self.readShortcutTwoActionBeforeKey,
                legacyBoolKey: Self.readShortcutTwoTriggerBeforeKey
            )
            refreshShortcutTriggerAccessibilityStatus()
        }
    }

    @Published var readShortcutTwoActionAfter: ExternalTriggerAction {
        didSet {
            persistExternalTriggerAction(
                readShortcutTwoActionAfter,
                actionKey: Self.readShortcutTwoActionAfterKey,
                legacyBoolKey: Self.readShortcutTwoTriggerAfterKey
            )
            refreshShortcutTriggerAccessibilityStatus()
        }
    }

    @Published var readShortcutTwoSpeedMultiplier: Double {
        didSet {
            let clamped = SpeechRateMapper.clampMultiplier(readShortcutTwoSpeedMultiplier)
            if clamped != readShortcutTwoSpeedMultiplier {
                readShortcutTwoSpeedMultiplier = clamped
                return
            }

            defaults.set(clamped, forKey: Self.readShortcutTwoSpeedKey)
        }
    }

    @Published var readClipboardAlwaysActionBefore: ExternalTriggerAction {
        didSet {
            persistExternalTriggerAction(
                readClipboardAlwaysActionBefore,
                actionKey: Self.readClipboardAlwaysActionBeforeKey,
                legacyBoolKey: Self.readClipboardAlwaysTriggerBeforeKey
            )
            refreshShortcutTriggerAccessibilityStatus()
        }
    }

    @Published var readClipboardAlwaysActionAfter: ExternalTriggerAction {
        didSet {
            persistExternalTriggerAction(
                readClipboardAlwaysActionAfter,
                actionKey: Self.readClipboardAlwaysActionAfterKey,
                legacyBoolKey: Self.readClipboardAlwaysTriggerAfterKey
            )
            refreshShortcutTriggerAccessibilityStatus()
        }
    }

    @Published var readClipboardAlwaysSpeedMultiplier: Double {
        didSet {
            let clamped = SpeechRateMapper.clampMultiplier(readClipboardAlwaysSpeedMultiplier)
            if clamped != readClipboardAlwaysSpeedMultiplier {
                readClipboardAlwaysSpeedMultiplier = clamped
                return
            }

            defaults.set(clamped, forKey: Self.readClipboardAlwaysSpeedKey)
        }
    }

    @Published var readClipboardAlwaysTwoActionBefore: ExternalTriggerAction {
        didSet {
            persistExternalTriggerAction(
                readClipboardAlwaysTwoActionBefore,
                actionKey: Self.readClipboardAlwaysTwoActionBeforeKey,
                legacyBoolKey: Self.readClipboardAlwaysTwoTriggerBeforeKey
            )
            refreshShortcutTriggerAccessibilityStatus()
        }
    }

    @Published var readClipboardAlwaysTwoActionAfter: ExternalTriggerAction {
        didSet {
            persistExternalTriggerAction(
                readClipboardAlwaysTwoActionAfter,
                actionKey: Self.readClipboardAlwaysTwoActionAfterKey,
                legacyBoolKey: Self.readClipboardAlwaysTwoTriggerAfterKey
            )
            refreshShortcutTriggerAccessibilityStatus()
        }
    }

    @Published var readClipboardAlwaysTwoSpeedMultiplier: Double {
        didSet {
            let clamped = SpeechRateMapper.clampMultiplier(readClipboardAlwaysTwoSpeedMultiplier)
            if clamped != readClipboardAlwaysTwoSpeedMultiplier {
                readClipboardAlwaysTwoSpeedMultiplier = clamped
                return
            }

            defaults.set(clamped, forKey: Self.readClipboardAlwaysTwoSpeedKey)
        }
    }

    @Published var readClipboardAlwaysThreeActionBefore: ExternalTriggerAction {
        didSet {
            persistExternalTriggerAction(
                readClipboardAlwaysThreeActionBefore,
                actionKey: Self.readClipboardAlwaysThreeActionBeforeKey,
                legacyBoolKey: Self.readClipboardAlwaysThreeTriggerBeforeKey
            )
            refreshShortcutTriggerAccessibilityStatus()
        }
    }

    @Published var readClipboardAlwaysThreeActionAfter: ExternalTriggerAction {
        didSet {
            persistExternalTriggerAction(
                readClipboardAlwaysThreeActionAfter,
                actionKey: Self.readClipboardAlwaysThreeActionAfterKey,
                legacyBoolKey: Self.readClipboardAlwaysThreeTriggerAfterKey
            )
            refreshShortcutTriggerAccessibilityStatus()
        }
    }

    @Published var readClipboardAlwaysThreeSpeedMultiplier: Double {
        didSet {
            let clamped = SpeechRateMapper.clampMultiplier(readClipboardAlwaysThreeSpeedMultiplier)
            if clamped != readClipboardAlwaysThreeSpeedMultiplier {
                readClipboardAlwaysThreeSpeedMultiplier = clamped
                return
            }

            defaults.set(clamped, forKey: Self.readClipboardAlwaysThreeSpeedKey)
        }
    }

    @Published var showPresenterOverlay: Bool {
        didSet {
            defaults.set(showPresenterOverlay, forKey: Self.presenterOverlayKey)
            refreshPresenterOverlayVisibility()
        }
    }

    @Published var hidePresenterOverlayFromCapture: Bool {
        didSet {
            defaults.set(hidePresenterOverlayFromCapture, forKey: Self.presenterOverlayCaptureKey)
            presenterOverlayController?.updateCaptureVisibility()
        }
    }

    @Published var hidePresenterOverlayWhileSpeaking: Bool {
        didSet {
            defaults.set(hidePresenterOverlayWhileSpeaking, forKey: Self.presenterOverlayHideWhileSpeakingKey)
            refreshPresenterOverlayVisibility()
        }
    }

    @Published var presenterOverlayOpacity: Double {
        didSet {
            let clamped = Self.clamp(presenterOverlayOpacity, min: Self.minPresenterOverlayOpacity, max: Self.maxPresenterOverlayOpacity)
            if clamped != presenterOverlayOpacity {
                presenterOverlayOpacity = clamped
                return
            }

            defaults.set(clamped, forKey: Self.presenterOverlayOpacityKey)
            presenterOverlayController?.updateLayout()
        }
    }

    @Published var presenterOverlayWidth: Double {
        didSet {
            let clamped = Self.clamp(presenterOverlayWidth, min: Self.minPresenterOverlayWidth, max: Self.maxPresenterOverlayWidth)
            if clamped != presenterOverlayWidth {
                presenterOverlayWidth = clamped
                return
            }

            defaults.set(clamped, forKey: Self.presenterOverlayWidthKey)
            presenterOverlayController?.updateLayout()
        }
    }

    @Published var presenterOverlayHeight: Double {
        didSet {
            let clamped = Self.clamp(presenterOverlayHeight, min: Self.minPresenterOverlayHeight, max: Self.maxPresenterOverlayHeight)
            if clamped != presenterOverlayHeight {
                presenterOverlayHeight = clamped
                return
            }

            defaults.set(clamped, forKey: Self.presenterOverlayHeightKey)
            presenterOverlayController?.updateLayout()
        }
    }

    @Published var presenterOverlayBottomOffset: Double {
        didSet {
            let clamped = Self.clamp(presenterOverlayBottomOffset, min: Self.minPresenterOverlayBottomOffset, max: Self.maxPresenterOverlayBottomOffset)
            if clamped != presenterOverlayBottomOffset {
                presenterOverlayBottomOffset = clamped
                return
            }

            defaults.set(clamped, forKey: Self.presenterOverlayBottomOffsetKey)
            presenterOverlayController?.updateLayout()
        }
    }

    @Published var presenterOverlayHorizontalOffset: Double {
        didSet {
            let clamped = Self.clamp(presenterOverlayHorizontalOffset, min: Self.minPresenterOverlayHorizontalOffset, max: Self.maxPresenterOverlayHorizontalOffset)
            if clamped != presenterOverlayHorizontalOffset {
                presenterOverlayHorizontalOffset = clamped
                return
            }

            defaults.set(clamped, forKey: Self.presenterOverlayHorizontalOffsetKey)
            presenterOverlayController?.updateLayout()
        }
    }

    @Published var presenterOverlayCurrentFontSize: Double {
        didSet {
            let clamped = Self.clamp(presenterOverlayCurrentFontSize, min: Self.minPresenterOverlayCurrentFontSize, max: Self.maxPresenterOverlayCurrentFontSize)
            if clamped != presenterOverlayCurrentFontSize {
                presenterOverlayCurrentFontSize = clamped
                return
            }

            defaults.set(clamped, forKey: Self.presenterOverlayCurrentFontSizeKey)
            presenterOverlayController?.updateLayout()
        }
    }

    @Published var presenterOverlaySideFontSize: Double {
        didSet {
            let clamped = Self.clamp(presenterOverlaySideFontSize, min: Self.minPresenterOverlaySideFontSize, max: Self.maxPresenterOverlaySideFontSize)
            if clamped != presenterOverlaySideFontSize {
                presenterOverlaySideFontSize = clamped
                return
            }

            defaults.set(clamped, forKey: Self.presenterOverlaySideFontSizeKey)
            presenterOverlayController?.updateLayout()
        }
    }

    @Published var presenterOverlayCurrentTextOpacity: Double {
        didSet {
            let clamped = Self.clamp(presenterOverlayCurrentTextOpacity, min: Self.minPresenterOverlayTextOpacity, max: Self.maxPresenterOverlayTextOpacity)
            if clamped != presenterOverlayCurrentTextOpacity {
                presenterOverlayCurrentTextOpacity = clamped
                return
            }

            defaults.set(clamped, forKey: Self.presenterOverlayCurrentTextOpacityKey)
        }
    }

    @Published var presenterOverlaySecondaryTextOpacity: Double {
        didSet {
            let clamped = Self.clamp(presenterOverlaySecondaryTextOpacity, min: Self.minPresenterOverlayTextOpacity, max: Self.maxPresenterOverlayTextOpacity)
            if clamped != presenterOverlaySecondaryTextOpacity {
                presenterOverlaySecondaryTextOpacity = clamped
                return
            }

            defaults.set(clamped, forKey: Self.presenterOverlaySecondaryTextOpacityKey)
        }
    }

    @Published var presenterOverlayCurrentTextColor: Color {
        didSet {
            if let hexString = presenterOverlayCurrentTextColor.hexString {
                defaults.set(hexString, forKey: Self.presenterOverlayCurrentTextColorKey)
            }
            presenterOverlayController?.updateLayout()
        }
    }

    @Published var presenterOverlaySecondaryTextColor: Color {
        didSet {
            if let hexString = presenterOverlaySecondaryTextColor.hexString {
                defaults.set(hexString, forKey: Self.presenterOverlaySecondaryTextColorKey)
            }
            presenterOverlayController?.updateLayout()
        }
    }

    @Published var scriptModeEnabled: Bool {
        didSet {
            defaults.set(scriptModeEnabled, forKey: Self.scriptModeKey)
            if scriptModeEnabled {
                readsTypedTextInsteadOfClipboard = true
                refreshScriptScenes()
            }
            refreshPresenterOverlayVisibility()
        }
    }

    @Published var readsTypedTextInsteadOfClipboard: Bool {
        didSet {
            defaults.set(readsTypedTextInsteadOfClipboard, forKey: Self.inputModeKey)
            if !readsTypedTextInsteadOfClipboard, scriptModeEnabled {
                scriptModeEnabled = false
            }
        }
    }

    @Published var speedMultiplier: Double {
        didSet {
            let clamped = SpeechRateMapper.clampMultiplier(speedMultiplier)
            if clamped != speedMultiplier {
                speedMultiplier = clamped
                return
            }

            defaults.set(clamped, forKey: Self.speedKey)
        }
    }

    @Published var selectedVoiceIdentifier: String? {
        didSet {
            defaults.set(selectedVoiceIdentifier, forKey: Self.voiceKey)
        }
    }

    var availableVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices().sorted {
            if $0.language == $1.language {
                return $0.name < $1.name
            }

            return $0.language < $1.language
        }
    }

    var selectedVoiceIdentifierForPicker: String {
        selectedVoiceIdentifier ?? ""
    }

    var readButtonTitle: String {
        if scriptModeEnabled {
            return "Play Scene"
        }

        return readsTypedTextInsteadOfClipboard ? "Read Text" : "Read Clipboard"
    }

    var inputModeStatus: String {
        if scriptModeEnabled {
            return "Shortcut plays the current script scene."
        }

        return readsTypedTextInsteadOfClipboard ? "Shortcut reads typed text." : "Shortcut reads clipboard."
    }

    var currentSceneText: String? {
        guard scriptScenes.indices.contains(currentSceneIndex) else {
            return nil
        }

        return scriptScenes[currentSceneIndex]
    }

    var allSceneTexts: [String] {
        scriptScenes
    }

    var currentSceneIndexForEditor: Int {
        currentSceneIndex
    }

    var previousSceneText: String? {
        let previousIndex = currentSceneIndex - 1
        guard scriptScenes.indices.contains(previousIndex) else {
            return nil
        }

        return scriptScenes[previousIndex]
    }

    var nextSceneText: String? {
        let nextIndex = currentSceneIndex + 1
        guard scriptScenes.indices.contains(nextIndex) else {
            return nil
        }

        return scriptScenes[nextIndex]
    }

    var scriptSceneProgress: String {
        guard !scriptScenes.isEmpty else {
            return "No scenes yet"
        }

        return "Scene \(currentSceneIndex + 1) of \(scriptScenes.count)"
    }

    var canGoToPreviousScene: Bool {
        currentSceneIndex > 0
    }

    var canGoToNextScene: Bool {
        currentSceneIndex + 1 < scriptScenes.count
    }

    var shouldShowPresenterOverlay: Bool {
        showPresenterOverlay
            && scriptModeEnabled
            && !(hidePresenterOverlayWhileSpeaking && speechState == .speaking)
    }

    var presenterOverlaySideColumnWidth: Double {
        min(280, max(150, presenterOverlayWidth * 0.22))
    }

    private static let speedKey = "clipboardReader.speedMultiplier"
    private static let voiceKey = "clipboardReader.voiceIdentifier"
    private static let inputModeKey = "clipboardReader.readsTypedTextInsteadOfClipboard"
    private static let scriptModeKey = "clipboardReader.scriptModeEnabled"
    private static let legacyRecordingShortcutTriggerKey = "clipboardReader.recordingShortcutTrigger.enabled"
    private static let recordingShortcutValueKey = "clipboardReader.recordingShortcutTrigger.shortcut"
    private static let readShortcutOneTriggerBeforeKey = "clipboardReader.readShortcutOne.triggerBefore"
    private static let readShortcutOneTriggerAfterKey = "clipboardReader.readShortcutOne.triggerAfter"
    private static let readShortcutOneActionBeforeKey = "clipboardReader.readShortcutOne.actionBefore"
    private static let readShortcutOneActionAfterKey = "clipboardReader.readShortcutOne.actionAfter"
    private static let readShortcutOneDelayBeforeKey = "clipboardReader.readShortcutOne.delayBefore"
    private static let readShortcutOneDelayAfterKey = "clipboardReader.readShortcutOne.delayAfter"
    private static let readShortcutOneSpeedKey = "clipboardReader.readShortcutOne.speedMultiplier"
    private static let readShortcutTwoTriggerBeforeKey = "clipboardReader.readShortcutTwo.triggerBefore"
    private static let readShortcutTwoTriggerAfterKey = "clipboardReader.readShortcutTwo.triggerAfter"
    private static let readShortcutTwoActionBeforeKey = "clipboardReader.readShortcutTwo.actionBefore"
    private static let readShortcutTwoActionAfterKey = "clipboardReader.readShortcutTwo.actionAfter"
    private static let readShortcutTwoDelayBeforeKey = "clipboardReader.readShortcutTwo.delayBefore"
    private static let readShortcutTwoDelayAfterKey = "clipboardReader.readShortcutTwo.delayAfter"
    private static let readShortcutTwoSpeedKey = "clipboardReader.readShortcutTwo.speedMultiplier"
    private static let readClipboardAlwaysTriggerBeforeKey = "clipboardReader.readClipboardAlways.triggerBefore"
    private static let readClipboardAlwaysTriggerAfterKey = "clipboardReader.readClipboardAlways.triggerAfter"
    private static let readClipboardAlwaysActionBeforeKey = "clipboardReader.readClipboardAlways.actionBefore"
    private static let readClipboardAlwaysActionAfterKey = "clipboardReader.readClipboardAlways.actionAfter"
    private static let readClipboardAlwaysDelayBeforeKey = "clipboardReader.readClipboardAlways.delayBefore"
    private static let readClipboardAlwaysDelayAfterKey = "clipboardReader.readClipboardAlways.delayAfter"
    private static let readClipboardAlwaysSpeedKey = "clipboardReader.readClipboardAlways.speedMultiplier"
    private static let readClipboardAlwaysTwoTriggerBeforeKey = "clipboardReader.readClipboardAlwaysTwo.triggerBefore"
    private static let readClipboardAlwaysTwoTriggerAfterKey = "clipboardReader.readClipboardAlwaysTwo.triggerAfter"
    private static let readClipboardAlwaysTwoActionBeforeKey = "clipboardReader.readClipboardAlwaysTwo.actionBefore"
    private static let readClipboardAlwaysTwoActionAfterKey = "clipboardReader.readClipboardAlwaysTwo.actionAfter"
    private static let readClipboardAlwaysTwoDelayBeforeKey = "clipboardReader.readClipboardAlwaysTwo.delayBefore"
    private static let readClipboardAlwaysTwoDelayAfterKey = "clipboardReader.readClipboardAlwaysTwo.delayAfter"
    private static let readClipboardAlwaysTwoSpeedKey = "clipboardReader.readClipboardAlwaysTwo.speedMultiplier"
    private static let readClipboardAlwaysThreeTriggerBeforeKey = "clipboardReader.readClipboardAlwaysThree.triggerBefore"
    private static let readClipboardAlwaysThreeTriggerAfterKey = "clipboardReader.readClipboardAlwaysThree.triggerAfter"
    private static let readClipboardAlwaysThreeActionBeforeKey = "clipboardReader.readClipboardAlwaysThree.actionBefore"
    private static let readClipboardAlwaysThreeActionAfterKey = "clipboardReader.readClipboardAlwaysThree.actionAfter"
    private static let readClipboardAlwaysThreeDelayBeforeKey = "clipboardReader.readClipboardAlwaysThree.delayBefore"
    private static let readClipboardAlwaysThreeDelayAfterKey = "clipboardReader.readClipboardAlwaysThree.delayAfter"
    private static let readClipboardAlwaysThreeSpeedKey = "clipboardReader.readClipboardAlwaysThree.speedMultiplier"
    private static let presenterOverlayKey = "clipboardReader.showPresenterOverlay"
    private static let presenterOverlayCaptureKey = "clipboardReader.hidePresenterOverlayFromCapture"
    private static let presenterOverlayHideWhileSpeakingKey = "clipboardReader.hidePresenterOverlayWhileSpeaking"
    private static let presenterOverlayOpacityKey = "clipboardReader.presenterOverlay.opacity"
    private static let presenterOverlayWidthKey = "clipboardReader.presenterOverlay.width"
    private static let presenterOverlayHeightKey = "clipboardReader.presenterOverlay.height"
    private static let presenterOverlayBottomOffsetKey = "clipboardReader.presenterOverlay.bottomOffset"
    private static let presenterOverlayHorizontalOffsetKey = "clipboardReader.presenterOverlay.horizontalOffset"
    private static let presenterOverlayCurrentFontSizeKey = "clipboardReader.presenterOverlay.currentFontSize"
    private static let presenterOverlaySideFontSizeKey = "clipboardReader.presenterOverlay.sideFontSize"
    private static let presenterOverlayCurrentTextOpacityKey = "clipboardReader.presenterOverlay.currentTextOpacity"
    private static let presenterOverlaySecondaryTextOpacityKey = "clipboardReader.presenterOverlay.secondaryTextOpacity"
    private static let presenterOverlayCurrentTextColorKey = "clipboardReader.presenterOverlay.currentTextColor"
    private static let presenterOverlaySecondaryTextColorKey = "clipboardReader.presenterOverlay.secondaryTextColor"

    static let defaultPresenterOverlayOpacity = 0.82
    static let defaultPresenterOverlayWidth = 980.0
    static let defaultPresenterOverlayHeight = 170.0
    static let defaultPresenterOverlayBottomOffset = 24.0
    static let defaultPresenterOverlayHorizontalOffset = 0.0
    static let defaultPresenterOverlayCurrentFontSize = 24.0
    static let defaultPresenterOverlaySideFontSize = 13.0
    static let defaultPresenterOverlayCurrentTextOpacity = 1.0
    static let defaultPresenterOverlaySecondaryTextOpacity = 0.68
    static let minPresenterOverlayOpacity = 0.2
    static let maxPresenterOverlayOpacity = 1.0
    static let minPresenterOverlayWidth = 520.0
    static let maxPresenterOverlayWidth = 1600.0
    static let minPresenterOverlayHeight = 120.0
    static let maxPresenterOverlayHeight = 420.0
    static let minPresenterOverlayBottomOffset = 0.0
    static let maxPresenterOverlayBottomOffset = 700.0
    static let minPresenterOverlayHorizontalOffset = -700.0
    static let maxPresenterOverlayHorizontalOffset = 700.0
    static let minPresenterOverlayCurrentFontSize = 16.0
    static let maxPresenterOverlayCurrentFontSize = 56.0
    static let minPresenterOverlaySideFontSize = 10.0
    static let maxPresenterOverlaySideFontSize = 32.0
    static let minPresenterOverlayTextOpacity = 0.1
    static let maxPresenterOverlayTextOpacity = 1.0
    static let minTriggerDelay = 0.0
    static let maxTriggerDelay = 2.0

    private let defaults: UserDefaults
    private let clipboardService = ClipboardService()
    private let shortcutTriggerService = ShortcutTriggerService()
    private let focuSeeAccessibilityService = FocuSeeAccessibilityService()
    private let ttsManager = TTSManager()
    private var cancellables = Set<AnyCancellable>()
    private var presenterOverlayController: PresenterOverlayController?
    private var sceneEditorController: SceneEditorController?
    @Published private var currentSceneIndex = 0
    @Published private var scriptScenes: [String] = []
    private var manualSceneOverride: [String]?
    private var manualSceneOverrideSource: String?
    private var shouldAdvanceScriptSceneAfterSpeech = false
    private var externalTriggerActionAfterSpeech: ExternalTriggerAction = .none
    private var externalTriggerDelayAfterSpeech = 0.0
    private var activeReadSequenceID: UUID?
    private var pendingReadTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let storedSpeed = defaults.object(forKey: Self.speedKey) as? Double
        let legacyTriggerBefore = defaults.bool(forKey: Self.legacyRecordingShortcutTriggerKey)
        let initialSpeedMultiplier = SpeechRateMapper.clampMultiplier(storedSpeed ?? SpeechRateMapper.defaultMultiplier)
        self.speedMultiplier = initialSpeedMultiplier
        self.selectedVoiceIdentifier = defaults.string(forKey: Self.voiceKey)
        self.readsTypedTextInsteadOfClipboard = defaults.bool(forKey: Self.inputModeKey)
        self.scriptModeEnabled = defaults.bool(forKey: Self.scriptModeKey)
        self.readShortcutOneActionBefore = Self.storedExternalTriggerAction(
            in: defaults,
            actionKey: Self.readShortcutOneActionBeforeKey,
            legacyBoolKey: Self.readShortcutOneTriggerBeforeKey,
            legacyDefaultValue: legacyTriggerBefore
        )
        self.readShortcutOneActionAfter = Self.storedExternalTriggerAction(
            in: defaults,
            actionKey: Self.readShortcutOneActionAfterKey,
            legacyBoolKey: Self.readShortcutOneTriggerAfterKey
        )
        self.readShortcutOneDelayBefore = Self.storedTriggerDelay(in: defaults, forKey: Self.readShortcutOneDelayBeforeKey)
        self.readShortcutOneDelayAfter = Self.storedTriggerDelay(in: defaults, forKey: Self.readShortcutOneDelayAfterKey)
        self.readShortcutOneSpeedMultiplier = SpeechRateMapper.clampMultiplier(Self.storedDouble(
            in: defaults,
            forKey: Self.readShortcutOneSpeedKey,
            defaultValue: initialSpeedMultiplier
        ))
        self.readShortcutTwoActionBefore = Self.storedExternalTriggerAction(
            in: defaults,
            actionKey: Self.readShortcutTwoActionBeforeKey,
            legacyBoolKey: Self.readShortcutTwoTriggerBeforeKey
        )
        self.readShortcutTwoActionAfter = Self.storedExternalTriggerAction(
            in: defaults,
            actionKey: Self.readShortcutTwoActionAfterKey,
            legacyBoolKey: Self.readShortcutTwoTriggerAfterKey
        )
        self.readShortcutTwoDelayBefore = Self.storedTriggerDelay(in: defaults, forKey: Self.readShortcutTwoDelayBeforeKey)
        self.readShortcutTwoDelayAfter = Self.storedTriggerDelay(in: defaults, forKey: Self.readShortcutTwoDelayAfterKey)
        self.readShortcutTwoSpeedMultiplier = SpeechRateMapper.clampMultiplier(Self.storedDouble(
            in: defaults,
            forKey: Self.readShortcutTwoSpeedKey,
            defaultValue: initialSpeedMultiplier
        ))
        self.readClipboardAlwaysActionBefore = Self.storedExternalTriggerAction(
            in: defaults,
            actionKey: Self.readClipboardAlwaysActionBeforeKey,
            legacyBoolKey: Self.readClipboardAlwaysTriggerBeforeKey
        )
        self.readClipboardAlwaysActionAfter = Self.storedExternalTriggerAction(
            in: defaults,
            actionKey: Self.readClipboardAlwaysActionAfterKey,
            legacyBoolKey: Self.readClipboardAlwaysTriggerAfterKey
        )
        self.readClipboardAlwaysDelayBefore = Self.storedTriggerDelay(in: defaults, forKey: Self.readClipboardAlwaysDelayBeforeKey)
        self.readClipboardAlwaysDelayAfter = Self.storedTriggerDelay(in: defaults, forKey: Self.readClipboardAlwaysDelayAfterKey)
        self.readClipboardAlwaysSpeedMultiplier = SpeechRateMapper.clampMultiplier(Self.storedDouble(
            in: defaults,
            forKey: Self.readClipboardAlwaysSpeedKey,
            defaultValue: initialSpeedMultiplier
        ))
        self.readClipboardAlwaysTwoActionBefore = Self.storedExternalTriggerAction(
            in: defaults,
            actionKey: Self.readClipboardAlwaysTwoActionBeforeKey,
            legacyBoolKey: Self.readClipboardAlwaysTwoTriggerBeforeKey
        )
        self.readClipboardAlwaysTwoActionAfter = Self.storedExternalTriggerAction(
            in: defaults,
            actionKey: Self.readClipboardAlwaysTwoActionAfterKey,
            legacyBoolKey: Self.readClipboardAlwaysTwoTriggerAfterKey
        )
        self.readClipboardAlwaysTwoDelayBefore = Self.storedTriggerDelay(in: defaults, forKey: Self.readClipboardAlwaysTwoDelayBeforeKey)
        self.readClipboardAlwaysTwoDelayAfter = Self.storedTriggerDelay(in: defaults, forKey: Self.readClipboardAlwaysTwoDelayAfterKey)
        self.readClipboardAlwaysTwoSpeedMultiplier = SpeechRateMapper.clampMultiplier(Self.storedDouble(
            in: defaults,
            forKey: Self.readClipboardAlwaysTwoSpeedKey,
            defaultValue: initialSpeedMultiplier
        ))
        self.readClipboardAlwaysThreeActionBefore = Self.storedExternalTriggerAction(
            in: defaults,
            actionKey: Self.readClipboardAlwaysThreeActionBeforeKey,
            legacyBoolKey: Self.readClipboardAlwaysThreeTriggerBeforeKey
        )
        self.readClipboardAlwaysThreeActionAfter = Self.storedExternalTriggerAction(
            in: defaults,
            actionKey: Self.readClipboardAlwaysThreeActionAfterKey,
            legacyBoolKey: Self.readClipboardAlwaysThreeTriggerAfterKey
        )
        self.readClipboardAlwaysThreeDelayBefore = Self.storedTriggerDelay(in: defaults, forKey: Self.readClipboardAlwaysThreeDelayBeforeKey)
        self.readClipboardAlwaysThreeDelayAfter = Self.storedTriggerDelay(in: defaults, forKey: Self.readClipboardAlwaysThreeDelayAfterKey)
        self.readClipboardAlwaysThreeSpeedMultiplier = SpeechRateMapper.clampMultiplier(Self.storedDouble(
            in: defaults,
            forKey: Self.readClipboardAlwaysThreeSpeedKey,
            defaultValue: initialSpeedMultiplier
        ))
        self.recordingTriggerShortcut = Self.storedRecordingTriggerShortcut(in: defaults)
        self.isShortcutTriggerAccessibilityTrusted = ShortcutTriggerService.isAccessibilityTrusted
        self.showPresenterOverlay = defaults.bool(forKey: Self.presenterOverlayKey)
        self.hidePresenterOverlayFromCapture = (defaults.object(forKey: Self.presenterOverlayCaptureKey) as? Bool) ?? true
        self.hidePresenterOverlayWhileSpeaking = defaults.bool(forKey: Self.presenterOverlayHideWhileSpeakingKey)
        self.presenterOverlayOpacity = Self.storedDouble(
            in: defaults,
            forKey: Self.presenterOverlayOpacityKey,
            defaultValue: Self.defaultPresenterOverlayOpacity
        )
        self.presenterOverlayWidth = Self.storedDouble(
            in: defaults,
            forKey: Self.presenterOverlayWidthKey,
            defaultValue: Self.defaultPresenterOverlayWidth
        )
        self.presenterOverlayHeight = Self.storedDouble(
            in: defaults,
            forKey: Self.presenterOverlayHeightKey,
            defaultValue: Self.defaultPresenterOverlayHeight
        )
        self.presenterOverlayBottomOffset = Self.storedDouble(
            in: defaults,
            forKey: Self.presenterOverlayBottomOffsetKey,
            defaultValue: Self.defaultPresenterOverlayBottomOffset
        )
        self.presenterOverlayHorizontalOffset = Self.storedDouble(
            in: defaults,
            forKey: Self.presenterOverlayHorizontalOffsetKey,
            defaultValue: Self.defaultPresenterOverlayHorizontalOffset
        )
        self.presenterOverlayCurrentFontSize = Self.storedDouble(
            in: defaults,
            forKey: Self.presenterOverlayCurrentFontSizeKey,
            defaultValue: Self.defaultPresenterOverlayCurrentFontSize
        )
        self.presenterOverlaySideFontSize = Self.storedDouble(
            in: defaults,
            forKey: Self.presenterOverlaySideFontSizeKey,
            defaultValue: Self.defaultPresenterOverlaySideFontSize
        )
        self.presenterOverlayCurrentTextOpacity = Self.storedDouble(
            in: defaults,
            forKey: Self.presenterOverlayCurrentTextOpacityKey,
            defaultValue: Self.defaultPresenterOverlayCurrentTextOpacity
        )
        self.presenterOverlaySecondaryTextOpacity = Self.storedDouble(
            in: defaults,
            forKey: Self.presenterOverlaySecondaryTextOpacityKey,
            defaultValue: Self.defaultPresenterOverlaySecondaryTextOpacity
        )
        self.presenterOverlayCurrentTextColor = Color(
            hexString: defaults.string(forKey: Self.presenterOverlayCurrentTextColorKey) ?? "#FFFFFFFF",
            fallback: .white
        )
        self.presenterOverlaySecondaryTextColor = Color(
            hexString: defaults.string(forKey: Self.presenterOverlaySecondaryTextColorKey) ?? "#D8DEE9FF",
            fallback: Color(red: 0.85, green: 0.87, blue: 0.91)
        )

        bindSpeechState()
        registerShortcutHandlers()
        presenterOverlayController = PresenterOverlayController(appModel: self)
        sceneEditorController = SceneEditorController(appModel: self)
        DispatchQueue.main.async { [weak self] in
            self?.refreshPresenterOverlayVisibility()
        }
    }

    func readNow(
        actionBefore: ExternalTriggerAction = .none,
        actionAfter: ExternalTriggerAction = .none,
        delayBefore: Double = 0,
        delayAfter: Double = 0,
        speedMultiplier: Double? = nil
    ) {
        let resolvedSpeedMultiplier = speedMultiplier ?? self.speedMultiplier

        if scriptModeEnabled {
            readCurrentScriptSceneNow(
                actionBefore: actionBefore,
                actionAfter: actionAfter,
                delayBefore: delayBefore,
                delayAfter: delayAfter,
                speedMultiplier: resolvedSpeedMultiplier
            )
            return
        }

        if readsTypedTextInsteadOfClipboard {
            readTypedTextNow(
                actionBefore: actionBefore,
                actionAfter: actionAfter,
                delayBefore: delayBefore,
                delayAfter: delayAfter,
                speedMultiplier: resolvedSpeedMultiplier
            )
        } else {
            readClipboardNow(
                actionBefore: actionBefore,
                actionAfter: actionAfter,
                delayBefore: delayBefore,
                delayAfter: delayAfter,
                speedMultiplier: resolvedSpeedMultiplier
            )
        }
    }

    func readClipboardAlways(
        actionBefore: ExternalTriggerAction = .none,
        actionAfter: ExternalTriggerAction = .none,
        delayBefore: Double = 0,
        delayAfter: Double = 0,
        speedMultiplier: Double? = nil
    ) {
        readClipboardNow(
            actionBefore: actionBefore,
            actionAfter: actionAfter,
            delayBefore: delayBefore,
            delayAfter: delayAfter,
            speedMultiplier: speedMultiplier ?? self.speedMultiplier
        )
    }

    func clearTypedText() {
        manualSceneOverride = nil
        manualSceneOverrideSource = nil
        typedText = ""
        refreshScriptScenes()
    }

    func openCurrentSceneEditor() {
        if !scriptModeEnabled {
            scriptModeEnabled = true
        }

        refreshScriptScenes()
        sceneEditorController?.show()
    }

    func saveCurrentSceneEdit(_ editedText: String) {
        let replacement = editedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !replacement.isEmpty else {
            statusMessage = "Current scene cannot be empty."
            return
        }

        if manualSceneOverride != nil {
            var scenes = scriptScenes
            if scenes.indices.contains(currentSceneIndex) {
                scenes[currentSceneIndex] = replacement
            } else {
                scenes = [replacement]
            }

            saveSceneManagerScenes(scenes, selectedIndex: currentSceneIndex)
            return
        }

        let scenes = ScriptSceneSplitter.sceneRanges(from: typedText)
        guard scenes.indices.contains(currentSceneIndex) else {
            typedText = replacement
            refreshScriptScenes()
            currentSceneIndex = 0
            statusMessage = "Current scene created."
            presenterOverlayController?.updateLayout()
            return
        }

        let currentIndex = currentSceneIndex
        var normalizedScript = ScriptSceneSplitter.normalized(typedText)
        normalizedScript.replaceSubrange(scenes[currentIndex].range, with: replacement)
        typedText = normalizedScript
        refreshScriptScenes()
        currentSceneIndex = min(currentIndex, max(scriptScenes.count - 1, 0))
        statusMessage = "Current scene updated."
        presenterOverlayController?.updateLayout()
    }

    func saveSceneManagerScenes(_ scenes: [String], selectedIndex: Int) {
        let cleanedScenes = scenes
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !cleanedScenes.isEmpty else {
            manualSceneOverride = nil
            manualSceneOverrideSource = nil
            typedText = ""
            refreshScriptScenes()
            currentSceneIndex = 0
            statusMessage = "Script cleared."
            presenterOverlayController?.updateLayout()
            return
        }

        let updatedScript = cleanedScenes.joined(separator: "\n\n")
        manualSceneOverride = cleanedScenes
        manualSceneOverrideSource = ScriptSceneSplitter.normalized(updatedScript)
        typedText = updatedScript
        refreshScriptScenes()
        currentSceneIndex = min(max(selectedIndex, 0), max(scriptScenes.count - 1, 0))
        statusMessage = "Scenes updated."
        presenterOverlayController?.updateLayout()
    }

    func selectSceneForEditing(_ index: Int) {
        refreshScriptScenes()
        guard scriptScenes.indices.contains(index) else {
            return
        }

        currentSceneIndex = index
        statusMessage = scriptSceneProgress
        presenterOverlayController?.updateLayout()
    }

    func refreshScriptScenes() {
        let normalizedText = ScriptSceneSplitter.normalized(typedText)
        if let manualSceneOverride,
           manualSceneOverrideSource == normalizedText {
            scriptScenes = manualSceneOverride
            if scriptScenes.isEmpty {
                currentSceneIndex = 0
            } else {
                currentSceneIndex = min(currentSceneIndex, scriptScenes.count - 1)
            }
            return
        }

        manualSceneOverride = nil
        manualSceneOverrideSource = nil
        scriptScenes = ScriptSceneSplitter.scenes(from: typedText)
        if scriptScenes.isEmpty {
            currentSceneIndex = 0
        } else {
            currentSceneIndex = min(currentSceneIndex, scriptScenes.count - 1)
        }
    }

    func refreshPresenterOverlayVisibility() {
        presenterOverlayController?.updateVisibility()
    }

    func openShortcutTriggerAccessibilitySettings() {
        ShortcutTriggerService.openAccessibilitySettings()
        refreshShortcutTriggerAccessibilityStatus()
    }

    func refreshShortcutTriggerAccessibilityStatus(promptIfNeeded: Bool = false) {
        if promptIfNeeded {
            ShortcutTriggerService.requestAccessibilityTrustPrompt()
        }

        isShortcutTriggerAccessibilityTrusted = ShortcutTriggerService.isAccessibilityTrusted
    }

    func requestShortcutTriggerAccessibilityPermission() {
        ShortcutTriggerService.requestAccessibilityTrustPrompt()
        refreshShortcutTriggerAccessibilityStatus()
    }

    func updateRecordingTriggerShortcut(_ shortcut: TriggerShortcut) {
        recordingTriggerShortcut = shortcut

        guard let data = try? JSONEncoder().encode(shortcut) else {
            return
        }

        defaults.set(data, forKey: Self.recordingShortcutValueKey)
    }

    func clearRecordingTriggerShortcut() {
        recordingTriggerShortcut = nil
        defaults.removeObject(forKey: Self.recordingShortcutValueKey)
    }

    func togglePresenterOverlay() {
        guard scriptModeEnabled else {
            statusMessage = "Turn on Script mode to use presenter overlay."
            return
        }

        showPresenterOverlay.toggle()
        statusMessage = showPresenterOverlay ? "Presenter overlay shown." : "Presenter overlay hidden."
    }

    func resetPresenterOverlayDefaults() {
        presenterOverlayOpacity = Self.defaultPresenterOverlayOpacity
        presenterOverlayWidth = Self.defaultPresenterOverlayWidth
        presenterOverlayHeight = Self.defaultPresenterOverlayHeight
        presenterOverlayBottomOffset = Self.defaultPresenterOverlayBottomOffset
        presenterOverlayHorizontalOffset = Self.defaultPresenterOverlayHorizontalOffset
        presenterOverlayCurrentFontSize = Self.defaultPresenterOverlayCurrentFontSize
        presenterOverlaySideFontSize = Self.defaultPresenterOverlaySideFontSize
        presenterOverlayCurrentTextOpacity = Self.defaultPresenterOverlayCurrentTextOpacity
        presenterOverlaySecondaryTextOpacity = Self.defaultPresenterOverlaySecondaryTextOpacity
        presenterOverlayCurrentTextColor = .white
        presenterOverlaySecondaryTextColor = Color(red: 0.85, green: 0.87, blue: 0.91)
        presenterOverlayController?.updateLayout()
    }

    func goToPreviousScene() {
        guard scriptModeEnabled else {
            statusMessage = "Turn on Script mode to use scene controls."
            return
        }

        refreshScriptScenes()
        guard canGoToPreviousScene else {
            statusMessage = scriptScenes.isEmpty ? "Text field is empty." : "Already at first scene."
            return
        }

        stopSpeechForSceneNavigation()
        currentSceneIndex -= 1
        statusMessage = scriptSceneProgress
    }

    func goToNextScene() {
        guard scriptModeEnabled else {
            statusMessage = "Turn on Script mode to use scene controls."
            return
        }

        refreshScriptScenes()
        guard canGoToNextScene else {
            statusMessage = scriptScenes.isEmpty ? "Text field is empty." : "Already at last scene."
            return
        }

        stopSpeechForSceneNavigation()
        currentSceneIndex += 1
        statusMessage = scriptSceneProgress
    }

    func restartScript() {
        guard scriptModeEnabled else {
            statusMessage = "Turn on Script mode to use scene controls."
            return
        }

        stopSpeechForSceneNavigation()
        refreshScriptScenes()
        currentSceneIndex = 0
        statusMessage = scriptScenes.isEmpty ? "Text field is empty." : scriptSceneProgress
    }

    func replayCurrentScriptScene() {
        guard scriptModeEnabled else {
            statusMessage = "Turn on Script mode to use scene controls."
            return
        }

        readCurrentScriptSceneNow(
            advancesAfterSpeech: false,
            includesBracketedDirections: true
        )
    }

    private func readClipboardNow(
        actionBefore: ExternalTriggerAction,
        actionAfter: ExternalTriggerAction,
        delayBefore: Double,
        delayAfter: Double,
        speedMultiplier: Double
    ) {
        guard let text = clipboardService.currentText() else {
            statusMessage = "Clipboard is empty."
            return
        }

        beginReadSequence(
            actionBefore: actionBefore,
            actionAfter: actionAfter,
            delayBefore: delayBefore,
            delayAfter: delayAfter,
            readingStatus: "Reading clipboard…"
        ) { [weak self] in
            guard let self else { return }
            self.ttsManager.speak(
                text: text,
                speedMultiplier: speedMultiplier,
                voiceIdentifier: self.selectedVoiceIdentifier
            )
        }
    }

    private func readTypedTextNow(
        actionBefore: ExternalTriggerAction,
        actionAfter: ExternalTriggerAction,
        delayBefore: Double,
        delayAfter: Double,
        speedMultiplier: Double
    ) {
        let text = clipboardService.normalize(typedText)
        guard !text.isEmpty else {
            statusMessage = "Text field is empty."
            return
        }

        beginReadSequence(
            actionBefore: actionBefore,
            actionAfter: actionAfter,
            delayBefore: delayBefore,
            delayAfter: delayAfter,
            readingStatus: "Reading typed text…"
        ) { [weak self] in
            guard let self else { return }
            self.ttsManager.speak(
                text: text,
                speedMultiplier: speedMultiplier,
                voiceIdentifier: self.selectedVoiceIdentifier
            )
        }
    }

    private func readCurrentScriptSceneNow() {
        readCurrentScriptSceneNow(
            advancesAfterSpeech: true,
            actionBefore: .none,
            actionAfter: .none,
            delayBefore: 0,
            delayAfter: 0,
            speedMultiplier: speedMultiplier
        )
    }

    private func readCurrentScriptSceneNow(
        actionBefore: ExternalTriggerAction,
        actionAfter: ExternalTriggerAction,
        delayBefore: Double,
        delayAfter: Double,
        speedMultiplier: Double
    ) {
        readCurrentScriptSceneNow(
            advancesAfterSpeech: true,
            actionBefore: actionBefore,
            actionAfter: actionAfter,
            delayBefore: delayBefore,
            delayAfter: delayAfter,
            speedMultiplier: speedMultiplier
        )
    }

    private func readCurrentScriptSceneNow(
        advancesAfterSpeech: Bool,
        includesBracketedDirections: Bool = false,
        actionBefore: ExternalTriggerAction = .none,
        actionAfter: ExternalTriggerAction = .none,
        delayBefore: Double = 0,
        delayAfter: Double = 0,
        speedMultiplier: Double? = nil
    ) {
        refreshScriptScenes()

        guard let scene = currentSceneText else {
            statusMessage = "Text field is empty."
            return
        }

        shouldAdvanceScriptSceneAfterSpeech = advancesAfterSpeech
        let readingStatus = advancesAfterSpeech ? "Reading \(scriptSceneProgress)…" : "Replaying \(scriptSceneProgress)…"
        let resolvedSpeedMultiplier = speedMultiplier ?? self.speedMultiplier
        beginReadSequence(
            actionBefore: actionBefore,
            actionAfter: actionAfter,
            delayBefore: delayBefore,
            delayAfter: delayAfter,
            readingStatus: readingStatus
        ) { [weak self] in
            guard let self else { return }
            self.ttsManager.speak(
                text: scene,
                speedMultiplier: resolvedSpeedMultiplier,
                voiceIdentifier: self.selectedVoiceIdentifier,
                includesBracketedDirections: includesBracketedDirections
            )
        }
    }

    func stopReading() {
        shouldAdvanceScriptSceneAfterSpeech = false
        cancelPendingReadSequence()
        let wasIdle = speechState == .idle
        ttsManager.stop()
        if wasIdle {
            statusMessage = SpeechState.idle.label
        }
    }

    func togglePauseResume() {
        ttsManager.togglePauseResume()
    }

    func updateVoiceSelection(_ identifier: String) {
        selectedVoiceIdentifier = identifier.isEmpty ? nil : identifier
    }

    private func stopSpeechForSceneNavigation() {
        shouldAdvanceScriptSceneAfterSpeech = false
        cancelPendingReadSequence()
        if speechState == .speaking || speechState == .paused || speechState == .stopping {
            ttsManager.stop()
        }
    }

    private func beginReadSequence(
        actionBefore: ExternalTriggerAction,
        actionAfter: ExternalTriggerAction,
        delayBefore: Double,
        delayAfter: Double,
        readingStatus: String,
        speak: @escaping @MainActor () -> Void
    ) {
        cancelPendingReadSequence()
        if speechState == .speaking || speechState == .paused || speechState == .stopping {
            ttsManager.stop()
        }

        let sequenceID = UUID()
        activeReadSequenceID = sequenceID
        externalTriggerActionAfterSpeech = actionAfter
        externalTriggerDelayAfterSpeech = actionAfter == .none ? 0 : Self.clampTriggerDelay(delayAfter)
        performExternalTriggerAction(actionBefore)

        let resolvedDelayBefore = actionBefore == .none ? 0 : Self.clampTriggerDelay(delayBefore)
        guard resolvedDelayBefore > 0 else {
            statusMessage = readingStatus
            speak()
            return
        }

        statusMessage = "Starting speech in \(Self.formattedDelay(resolvedDelayBefore)) seconds…"
        pendingReadTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(resolvedDelayBefore))
            guard !Task.isCancelled,
                  let self,
                  self.activeReadSequenceID == sequenceID else {
                return
            }

            self.pendingReadTask = nil
            self.statusMessage = readingStatus
            speak()
        }
    }

    private func cancelPendingReadSequence() {
        pendingReadTask?.cancel()
        pendingReadTask = nil
        activeReadSequenceID = nil
        externalTriggerActionAfterSpeech = .none
        externalTriggerDelayAfterSpeech = 0
    }

    func ensureFocuSeeRecording() {
        performExternalTriggerAction(.ensureRecording, reportsSuccess: true)
    }

    func ensureFocuSeePaused() {
        performExternalTriggerAction(.ensurePaused, reportsSuccess: true)
    }

    private func performExternalTriggerAction(
        _ action: ExternalTriggerAction,
        reportsSuccess: Bool = false
    ) {
        switch action {
        case .none:
            return
        case .toggle:
            _ = triggerRecordingShortcutIfPossible()
        case .ensureRecording:
            ensureFocuSeeState(.recording, reportsSuccess: reportsSuccess)
        case .ensurePaused:
            ensureFocuSeeState(.paused, reportsSuccess: reportsSuccess)
        }
    }

    private func ensureFocuSeeState(
        _ targetState: FocuSeeRecordingState,
        reportsSuccess: Bool
    ) {
        refreshShortcutTriggerAccessibilityStatus()
        guard isShortcutTriggerAccessibilityTrusted else {
            statusMessage = "Accessibility permission is required to inspect FocuSee."
            return
        }

        let currentState = focuSeeAccessibilityService.recordingState()
        if currentState == targetState {
            if reportsSuccess {
                statusMessage = targetState == .recording
                    ? "FocuSee is already recording."
                    : "FocuSee is already paused."
            }
            return
        }

        let oppositeState: FocuSeeRecordingState = targetState == .recording ? .paused : .recording
        guard currentState == oppositeState else {
            switch currentState {
            case .notRunning:
                statusMessage = "FocuSee is not open."
            case .notRecording:
                statusMessage = "FocuSee does not have an active recording."
            case .unknown:
                statusMessage = "Could not determine whether FocuSee is recording or paused."
            case .recording, .paused:
                statusMessage = "Could not safely change FocuSee's recording state."
            }
            return
        }

        guard triggerRecordingShortcutIfPossible() else {
            return
        }

        if reportsSuccess {
            statusMessage = targetState == .recording
                ? "Resuming FocuSee recording…"
                : "Pausing FocuSee recording…"
        }
        verifyFocuSeeStateAfterTrigger(targetState)
    }

    private func verifyFocuSeeStateAfterTrigger(_ expectedState: FocuSeeRecordingState) {
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard let self else {
                return
            }

            let actualState = self.focuSeeAccessibilityService.recordingState()
            guard actualState != expectedState else {
                return
            }

            if actualState == .recording || actualState == .paused {
                self.statusMessage = "FocuSee did not change to the requested recording state."
            }
        }
    }

    @discardableResult
    private func triggerRecordingShortcutIfPossible() -> Bool {
        guard let shortcut = recordingTriggerShortcut else {
            statusMessage = "Set the external FocuSee toggle shortcut first."
            return false
        }

        refreshShortcutTriggerAccessibilityStatus()
        guard isShortcutTriggerAccessibilityTrusted else {
            statusMessage = "Accessibility permission is required to trigger the recording shortcut."
            return false
        }

        if !shortcutTriggerService.trigger(shortcut) {
            statusMessage = "Could not trigger the recording shortcut."
            return false
        }
        refreshShortcutTriggerAccessibilityStatus()
        return true
    }

    private static func storedRecordingTriggerShortcut(in defaults: UserDefaults) -> TriggerShortcut? {
        guard let data = defaults.data(forKey: recordingShortcutValueKey) else {
            return nil
        }

        return try? JSONDecoder().decode(TriggerShortcut.self, from: data)
    }

    private func bindSpeechState() {
        ttsManager.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.speechState = state
                if state != .speaking {
                    self?.statusMessage = state.label
                }
                self?.refreshPresenterOverlayVisibility()
            }
            .store(in: &cancellables)

        ttsManager.$resolvedVoiceDescription
            .receive(on: DispatchQueue.main)
            .sink { [weak self] description in
                self?.outputVoiceDescription = description
            }
            .store(in: &cancellables)

        ttsManager.$resolvedVoiceNote
            .receive(on: DispatchQueue.main)
            .sink { [weak self] note in
                self?.outputVoiceNote = note
            }
            .store(in: &cancellables)

        ttsManager.$completedUtteranceCount
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleCompletedSpeech()
            }
            .store(in: &cancellables)
    }

    private func handleCompletedSpeech() {
        performExternalTriggerActionAfterCompletedSpeechIfNeeded()
    }

    private func performExternalTriggerActionAfterCompletedSpeechIfNeeded() {
        guard let sequenceID = activeReadSequenceID else {
            return
        }

        let action = externalTriggerActionAfterSpeech
        let delay = externalTriggerDelayAfterSpeech
        externalTriggerActionAfterSpeech = .none
        externalTriggerDelayAfterSpeech = 0

        guard action != .none, delay > 0 else {
            performExternalTriggerAction(action)
            activeReadSequenceID = nil
            advanceScriptSceneAfterCompletedSpeech()
            return
        }

        statusMessage = "Finishing recording in \(Self.formattedDelay(delay)) seconds…"
        pendingReadTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled,
                  let self,
                  self.activeReadSequenceID == sequenceID else {
                return
            }

            self.pendingReadTask = nil
            self.performExternalTriggerAction(action)
            self.activeReadSequenceID = nil
            self.advanceScriptSceneAfterCompletedSpeech()
        }
    }

    private func advanceScriptSceneAfterCompletedSpeech() {
        guard scriptModeEnabled, shouldAdvanceScriptSceneAfterSpeech else {
            return
        }

        shouldAdvanceScriptSceneAfterSpeech = false
        refreshScriptScenes()

        if canGoToNextScene {
            currentSceneIndex += 1
            statusMessage = "Ready for \(scriptSceneProgress)"
        } else {
            statusMessage = "Script finished."
        }
    }

    private func registerShortcutHandlers() {
        KeyboardShortcuts.onKeyUp(for: .readClipboard) { [weak self] in
            Task { @MainActor in
                guard let self else {
                    return
                }

                self.readNow(
                    actionBefore: self.readShortcutOneActionBefore,
                    actionAfter: self.readShortcutOneActionAfter,
                    delayBefore: self.readShortcutOneDelayBefore,
                    delayAfter: self.readShortcutOneDelayAfter,
                    speedMultiplier: self.readShortcutOneSpeedMultiplier
                )
            }
        }

        KeyboardShortcuts.onKeyUp(for: .readCurrentInputSecondary) { [weak self] in
            Task { @MainActor in
                guard let self else {
                    return
                }

                self.readNow(
                    actionBefore: self.readShortcutTwoActionBefore,
                    actionAfter: self.readShortcutTwoActionAfter,
                    delayBefore: self.readShortcutTwoDelayBefore,
                    delayAfter: self.readShortcutTwoDelayAfter,
                    speedMultiplier: self.readShortcutTwoSpeedMultiplier
                )
            }
        }

        KeyboardShortcuts.onKeyUp(for: .readClipboardAlways) { [weak self] in
            Task { @MainActor in
                guard let self else {
                    return
                }

                self.readClipboardAlways(
                    actionBefore: self.readClipboardAlwaysActionBefore,
                    actionAfter: self.readClipboardAlwaysActionAfter,
                    delayBefore: self.readClipboardAlwaysDelayBefore,
                    delayAfter: self.readClipboardAlwaysDelayAfter,
                    speedMultiplier: self.readClipboardAlwaysSpeedMultiplier
                )
            }
        }

        KeyboardShortcuts.onKeyUp(for: .readClipboardAlwaysSecondary) { [weak self] in
            Task { @MainActor in
                guard let self else {
                    return
                }

                self.readClipboardAlways(
                    actionBefore: self.readClipboardAlwaysTwoActionBefore,
                    actionAfter: self.readClipboardAlwaysTwoActionAfter,
                    delayBefore: self.readClipboardAlwaysTwoDelayBefore,
                    delayAfter: self.readClipboardAlwaysTwoDelayAfter,
                    speedMultiplier: self.readClipboardAlwaysTwoSpeedMultiplier
                )
            }
        }

        KeyboardShortcuts.onKeyUp(for: .readClipboardAlwaysTertiary) { [weak self] in
            Task { @MainActor in
                guard let self else {
                    return
                }

                self.readClipboardAlways(
                    actionBefore: self.readClipboardAlwaysThreeActionBefore,
                    actionAfter: self.readClipboardAlwaysThreeActionAfter,
                    delayBefore: self.readClipboardAlwaysThreeDelayBefore,
                    delayAfter: self.readClipboardAlwaysThreeDelayAfter,
                    speedMultiplier: self.readClipboardAlwaysThreeSpeedMultiplier
                )
            }
        }

        KeyboardShortcuts.onKeyUp(for: .stopReading) { [weak self] in
            Task { @MainActor in
                self?.stopReading()
            }
        }

        KeyboardShortcuts.onKeyUp(for: .pauseResumeReading) { [weak self] in
            Task { @MainActor in
                self?.togglePauseResume()
            }
        }

        KeyboardShortcuts.onKeyUp(for: .replayScriptScene) { [weak self] in
            Task { @MainActor in
                self?.replayCurrentScriptScene()
            }
        }

        KeyboardShortcuts.onKeyUp(for: .previousScriptScene) { [weak self] in
            Task { @MainActor in
                self?.goToPreviousScene()
            }
        }

        KeyboardShortcuts.onKeyUp(for: .nextScriptScene) { [weak self] in
            Task { @MainActor in
                self?.goToNextScene()
            }
        }

        KeyboardShortcuts.onKeyUp(for: .restartScript) { [weak self] in
            Task { @MainActor in
                self?.restartScript()
            }
        }

        KeyboardShortcuts.onKeyUp(for: .togglePresenterOverlay) { [weak self] in
            Task { @MainActor in
                self?.togglePresenterOverlay()
            }
        }

        KeyboardShortcuts.onKeyUp(for: .editCurrentScene) { [weak self] in
            Task { @MainActor in
                self?.openCurrentSceneEditor()
            }
        }

        KeyboardShortcuts.onKeyUp(for: .ensureFocuSeeRecording) { [weak self] in
            Task { @MainActor in
                self?.ensureFocuSeeRecording()
            }
        }

        KeyboardShortcuts.onKeyUp(for: .ensureFocuSeePaused) { [weak self] in
            Task { @MainActor in
                self?.ensureFocuSeePaused()
            }
        }

    }

    private func persistExternalTriggerAction(
        _ action: ExternalTriggerAction,
        actionKey: String,
        legacyBoolKey: String
    ) {
        defaults.set(action.rawValue, forKey: actionKey)
        defaults.set(action != .none, forKey: legacyBoolKey)
    }

    private static func storedExternalTriggerAction(
        in defaults: UserDefaults,
        actionKey: String,
        legacyBoolKey: String,
        legacyDefaultValue: Bool = false
    ) -> ExternalTriggerAction {
        if let rawValue = defaults.string(forKey: actionKey),
           let action = ExternalTriggerAction(rawValue: rawValue) {
            return action
        }

        return storedBool(
            in: defaults,
            forKey: legacyBoolKey,
            defaultValue: legacyDefaultValue
        ) ? .toggle : .none
    }

    private func persistTriggerDelay(_ delay: Double, key: String) {
        defaults.set(Self.clampTriggerDelay(delay), forKey: key)
    }

    private static func storedTriggerDelay(in defaults: UserDefaults, forKey key: String) -> Double {
        clampTriggerDelay(storedDouble(in: defaults, forKey: key, defaultValue: 0))
    }

    static func clampTriggerDelay(_ value: Double) -> Double {
        clamp(value, min: minTriggerDelay, max: maxTriggerDelay)
    }

    private static func formattedDelay(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private static func storedDouble(in defaults: UserDefaults, forKey key: String, defaultValue: Double) -> Double {
        guard defaults.object(forKey: key) != nil else {
            return defaultValue
        }

        return defaults.double(forKey: key)
    }

    private static func storedBool(in defaults: UserDefaults, forKey key: String, defaultValue: Bool) -> Bool {
        guard defaults.object(forKey: key) != nil else {
            return defaultValue
        }

        return defaults.bool(forKey: key)
    }

    private static func clamp(_ value: Double, min minValue: Double, max maxValue: Double) -> Double {
        min(max(value, minValue), maxValue)
    }
}
