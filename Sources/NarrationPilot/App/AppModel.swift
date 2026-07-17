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

    @Published var readShortcutOneTriggersBefore: Bool {
        didSet {
            defaults.set(readShortcutOneTriggersBefore, forKey: Self.readShortcutOneTriggerBeforeKey)
            refreshShortcutTriggerAccessibilityStatus()
        }
    }

    @Published var readShortcutOneTriggersAfter: Bool {
        didSet {
            defaults.set(readShortcutOneTriggersAfter, forKey: Self.readShortcutOneTriggerAfterKey)
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

    @Published var readShortcutTwoTriggersBefore: Bool {
        didSet {
            defaults.set(readShortcutTwoTriggersBefore, forKey: Self.readShortcutTwoTriggerBeforeKey)
            refreshShortcutTriggerAccessibilityStatus()
        }
    }

    @Published var readShortcutTwoTriggersAfter: Bool {
        didSet {
            defaults.set(readShortcutTwoTriggersAfter, forKey: Self.readShortcutTwoTriggerAfterKey)
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

    @Published var readClipboardAlwaysTriggersBefore: Bool {
        didSet {
            defaults.set(readClipboardAlwaysTriggersBefore, forKey: Self.readClipboardAlwaysTriggerBeforeKey)
            refreshShortcutTriggerAccessibilityStatus()
        }
    }

    @Published var readClipboardAlwaysTriggersAfter: Bool {
        didSet {
            defaults.set(readClipboardAlwaysTriggersAfter, forKey: Self.readClipboardAlwaysTriggerAfterKey)
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

    @Published var readClipboardAlwaysTwoTriggersBefore: Bool {
        didSet {
            defaults.set(readClipboardAlwaysTwoTriggersBefore, forKey: Self.readClipboardAlwaysTwoTriggerBeforeKey)
            refreshShortcutTriggerAccessibilityStatus()
        }
    }

    @Published var readClipboardAlwaysTwoTriggersAfter: Bool {
        didSet {
            defaults.set(readClipboardAlwaysTwoTriggersAfter, forKey: Self.readClipboardAlwaysTwoTriggerAfterKey)
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

    @Published var readClipboardAlwaysThreeTriggersBefore: Bool {
        didSet {
            defaults.set(readClipboardAlwaysThreeTriggersBefore, forKey: Self.readClipboardAlwaysThreeTriggerBeforeKey)
            refreshShortcutTriggerAccessibilityStatus()
        }
    }

    @Published var readClipboardAlwaysThreeTriggersAfter: Bool {
        didSet {
            defaults.set(readClipboardAlwaysThreeTriggersAfter, forKey: Self.readClipboardAlwaysThreeTriggerAfterKey)
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
    private static let readShortcutOneSpeedKey = "clipboardReader.readShortcutOne.speedMultiplier"
    private static let readShortcutTwoTriggerBeforeKey = "clipboardReader.readShortcutTwo.triggerBefore"
    private static let readShortcutTwoTriggerAfterKey = "clipboardReader.readShortcutTwo.triggerAfter"
    private static let readShortcutTwoSpeedKey = "clipboardReader.readShortcutTwo.speedMultiplier"
    private static let readClipboardAlwaysTriggerBeforeKey = "clipboardReader.readClipboardAlways.triggerBefore"
    private static let readClipboardAlwaysTriggerAfterKey = "clipboardReader.readClipboardAlways.triggerAfter"
    private static let readClipboardAlwaysSpeedKey = "clipboardReader.readClipboardAlways.speedMultiplier"
    private static let readClipboardAlwaysTwoTriggerBeforeKey = "clipboardReader.readClipboardAlwaysTwo.triggerBefore"
    private static let readClipboardAlwaysTwoTriggerAfterKey = "clipboardReader.readClipboardAlwaysTwo.triggerAfter"
    private static let readClipboardAlwaysTwoSpeedKey = "clipboardReader.readClipboardAlwaysTwo.speedMultiplier"
    private static let readClipboardAlwaysThreeTriggerBeforeKey = "clipboardReader.readClipboardAlwaysThree.triggerBefore"
    private static let readClipboardAlwaysThreeTriggerAfterKey = "clipboardReader.readClipboardAlwaysThree.triggerAfter"
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

    private let defaults: UserDefaults
    private let clipboardService = ClipboardService()
    private let shortcutTriggerService = ShortcutTriggerService()
    private let ttsManager = TTSManager()
    private var cancellables = Set<AnyCancellable>()
    private var presenterOverlayController: PresenterOverlayController?
    private var sceneEditorController: SceneEditorController?
    @Published private var currentSceneIndex = 0
    @Published private var scriptScenes: [String] = []
    private var manualSceneOverride: [String]?
    private var manualSceneOverrideSource: String?
    private var shouldAdvanceScriptSceneAfterSpeech = false
    private var shouldTriggerRecordingShortcutAfterSpeech = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let storedSpeed = defaults.object(forKey: Self.speedKey) as? Double
        let legacyTriggerBefore = defaults.bool(forKey: Self.legacyRecordingShortcutTriggerKey)
        let initialSpeedMultiplier = SpeechRateMapper.clampMultiplier(storedSpeed ?? SpeechRateMapper.defaultMultiplier)
        self.speedMultiplier = initialSpeedMultiplier
        self.selectedVoiceIdentifier = defaults.string(forKey: Self.voiceKey)
        self.readsTypedTextInsteadOfClipboard = defaults.bool(forKey: Self.inputModeKey)
        self.scriptModeEnabled = defaults.bool(forKey: Self.scriptModeKey)
        self.readShortcutOneTriggersBefore = Self.storedBool(
            in: defaults,
            forKey: Self.readShortcutOneTriggerBeforeKey,
            defaultValue: legacyTriggerBefore
        )
        self.readShortcutOneTriggersAfter = defaults.bool(forKey: Self.readShortcutOneTriggerAfterKey)
        self.readShortcutOneSpeedMultiplier = SpeechRateMapper.clampMultiplier(Self.storedDouble(
            in: defaults,
            forKey: Self.readShortcutOneSpeedKey,
            defaultValue: initialSpeedMultiplier
        ))
        self.readShortcutTwoTriggersBefore = defaults.bool(forKey: Self.readShortcutTwoTriggerBeforeKey)
        self.readShortcutTwoTriggersAfter = defaults.bool(forKey: Self.readShortcutTwoTriggerAfterKey)
        self.readShortcutTwoSpeedMultiplier = SpeechRateMapper.clampMultiplier(Self.storedDouble(
            in: defaults,
            forKey: Self.readShortcutTwoSpeedKey,
            defaultValue: initialSpeedMultiplier
        ))
        self.readClipboardAlwaysTriggersBefore = defaults.bool(forKey: Self.readClipboardAlwaysTriggerBeforeKey)
        self.readClipboardAlwaysTriggersAfter = defaults.bool(forKey: Self.readClipboardAlwaysTriggerAfterKey)
        self.readClipboardAlwaysSpeedMultiplier = SpeechRateMapper.clampMultiplier(Self.storedDouble(
            in: defaults,
            forKey: Self.readClipboardAlwaysSpeedKey,
            defaultValue: initialSpeedMultiplier
        ))
        self.readClipboardAlwaysTwoTriggersBefore = defaults.bool(forKey: Self.readClipboardAlwaysTwoTriggerBeforeKey)
        self.readClipboardAlwaysTwoTriggersAfter = defaults.bool(forKey: Self.readClipboardAlwaysTwoTriggerAfterKey)
        self.readClipboardAlwaysTwoSpeedMultiplier = SpeechRateMapper.clampMultiplier(Self.storedDouble(
            in: defaults,
            forKey: Self.readClipboardAlwaysTwoSpeedKey,
            defaultValue: initialSpeedMultiplier
        ))
        self.readClipboardAlwaysThreeTriggersBefore = defaults.bool(forKey: Self.readClipboardAlwaysThreeTriggerBeforeKey)
        self.readClipboardAlwaysThreeTriggersAfter = defaults.bool(forKey: Self.readClipboardAlwaysThreeTriggerAfterKey)
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

    func readNow(triggerBefore: Bool = false, triggerAfter: Bool = false, speedMultiplier: Double? = nil) {
        let resolvedSpeedMultiplier = speedMultiplier ?? self.speedMultiplier

        if scriptModeEnabled {
            readCurrentScriptSceneNow(
                triggerBefore: triggerBefore,
                triggerAfter: triggerAfter,
                speedMultiplier: resolvedSpeedMultiplier
            )
            return
        }

        if readsTypedTextInsteadOfClipboard {
            readTypedTextNow(
                triggerBefore: triggerBefore,
                triggerAfter: triggerAfter,
                speedMultiplier: resolvedSpeedMultiplier
            )
        } else {
            readClipboardNow(
                triggerBefore: triggerBefore,
                triggerAfter: triggerAfter,
                speedMultiplier: resolvedSpeedMultiplier
            )
        }
    }

    func readClipboardAlways(triggerBefore: Bool = false, triggerAfter: Bool = false, speedMultiplier: Double? = nil) {
        readClipboardNow(
            triggerBefore: triggerBefore,
            triggerAfter: triggerAfter,
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

    private func readClipboardNow(triggerBefore: Bool, triggerAfter: Bool, speedMultiplier: Double) {
        guard let text = clipboardService.currentText() else {
            statusMessage = "Clipboard is empty."
            return
        }

        prepareRecordingShortcutTriggers(triggerBefore: triggerBefore, triggerAfter: triggerAfter)
        ttsManager.speak(
            text: text,
            speedMultiplier: speedMultiplier,
            voiceIdentifier: selectedVoiceIdentifier
        )
        statusMessage = "Reading clipboard…"
    }

    private func readTypedTextNow(triggerBefore: Bool, triggerAfter: Bool, speedMultiplier: Double) {
        let text = clipboardService.normalize(typedText)
        guard !text.isEmpty else {
            statusMessage = "Text field is empty."
            return
        }

        prepareRecordingShortcutTriggers(triggerBefore: triggerBefore, triggerAfter: triggerAfter)
        ttsManager.speak(
            text: text,
            speedMultiplier: speedMultiplier,
            voiceIdentifier: selectedVoiceIdentifier
        )
        statusMessage = "Reading typed text…"
    }

    private func readCurrentScriptSceneNow() {
        readCurrentScriptSceneNow(advancesAfterSpeech: true, triggerBefore: false, triggerAfter: false, speedMultiplier: speedMultiplier)
    }

    private func readCurrentScriptSceneNow(triggerBefore: Bool, triggerAfter: Bool, speedMultiplier: Double) {
        readCurrentScriptSceneNow(
            advancesAfterSpeech: true,
            triggerBefore: triggerBefore,
            triggerAfter: triggerAfter,
            speedMultiplier: speedMultiplier
        )
    }

    private func readCurrentScriptSceneNow(
        advancesAfterSpeech: Bool,
        includesBracketedDirections: Bool = false,
        triggerBefore: Bool = false,
        triggerAfter: Bool = false,
        speedMultiplier: Double? = nil
    ) {
        refreshScriptScenes()

        guard let scene = currentSceneText else {
            statusMessage = "Text field is empty."
            return
        }

        shouldAdvanceScriptSceneAfterSpeech = advancesAfterSpeech
        prepareRecordingShortcutTriggers(triggerBefore: triggerBefore, triggerAfter: triggerAfter)
        ttsManager.speak(
            text: scene,
            speedMultiplier: speedMultiplier ?? self.speedMultiplier,
            voiceIdentifier: selectedVoiceIdentifier,
            includesBracketedDirections: includesBracketedDirections
        )
        statusMessage = advancesAfterSpeech ? "Reading \(scriptSceneProgress)…" : "Replaying \(scriptSceneProgress)…"
    }

    func stopReading() {
        shouldAdvanceScriptSceneAfterSpeech = false
        shouldTriggerRecordingShortcutAfterSpeech = false
        ttsManager.stop()
    }

    func togglePauseResume() {
        ttsManager.togglePauseResume()
    }

    func updateVoiceSelection(_ identifier: String) {
        selectedVoiceIdentifier = identifier.isEmpty ? nil : identifier
    }

    private func stopSpeechForSceneNavigation() {
        shouldAdvanceScriptSceneAfterSpeech = false
        shouldTriggerRecordingShortcutAfterSpeech = false
        if speechState == .speaking || speechState == .paused || speechState == .stopping {
            ttsManager.stop()
        }
    }

    private func prepareRecordingShortcutTriggers(triggerBefore: Bool, triggerAfter: Bool) {
        shouldTriggerRecordingShortcutAfterSpeech = triggerAfter

        if triggerBefore {
            triggerRecordingShortcutIfPossible()
        }
    }

    private func triggerRecordingShortcutIfPossible() {
        guard let shortcut = recordingTriggerShortcut
        else {
            return
        }

        refreshShortcutTriggerAccessibilityStatus()
        guard isShortcutTriggerAccessibilityTrusted else {
            statusMessage = "Accessibility permission is required to trigger the recording shortcut."
            return
        }

        if !shortcutTriggerService.trigger(shortcut) {
            statusMessage = "Could not trigger the recording shortcut."
        }
        refreshShortcutTriggerAccessibilityStatus()
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
        triggerRecordingShortcutAfterCompletedSpeechIfNeeded()
        advanceScriptSceneAfterCompletedSpeech()
    }

    private func triggerRecordingShortcutAfterCompletedSpeechIfNeeded() {
        guard shouldTriggerRecordingShortcutAfterSpeech else {
            return
        }

        shouldTriggerRecordingShortcutAfterSpeech = false
        triggerRecordingShortcutIfPossible()
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
                    triggerBefore: self.readShortcutOneTriggersBefore,
                    triggerAfter: self.readShortcutOneTriggersAfter,
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
                    triggerBefore: self.readShortcutTwoTriggersBefore,
                    triggerAfter: self.readShortcutTwoTriggersAfter,
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
                    triggerBefore: self.readClipboardAlwaysTriggersBefore,
                    triggerAfter: self.readClipboardAlwaysTriggersAfter,
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
                    triggerBefore: self.readClipboardAlwaysTwoTriggersBefore,
                    triggerAfter: self.readClipboardAlwaysTwoTriggersAfter,
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
                    triggerBefore: self.readClipboardAlwaysThreeTriggersBefore,
                    triggerAfter: self.readClipboardAlwaysThreeTriggersAfter,
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
