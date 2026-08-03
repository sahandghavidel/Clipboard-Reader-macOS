import XCTest
@testable import NarrationPilot

final class NarrationPilotTests: XCTestCase {
    func testSpeedMultiplierClamps() {
        XCTAssertEqual(SpeechRateMapper.clampMultiplier(0.1), 0.5)
        XCTAssertEqual(SpeechRateMapper.clampMultiplier(1.0), 1.0)
        XCTAssertEqual(SpeechRateMapper.clampMultiplier(2.2), 1.5)
    }

    func testUtteranceRateMapping() {
        let slow = SpeechRateMapper.utteranceRate(for: 0.5)
        let normal = SpeechRateMapper.utteranceRate(for: 1.0)
        let fast = SpeechRateMapper.utteranceRate(for: 1.5)

        XCTAssertLessThan(slow, normal)
        XCTAssertLessThan(normal, fast)
        XCTAssertGreaterThanOrEqual(slow, 0.1)
        XCTAssertLessThanOrEqual(fast, 1.0)
    }

    func testTriggerDelayClampsToSupportedRange() {
        XCTAssertEqual(AppModel.clampTriggerDelay(-0.5), 0)
        XCTAssertEqual(AppModel.clampTriggerDelay(1.0), 1.0)
        XCTAssertEqual(AppModel.clampTriggerDelay(2.5), 2.5)
        XCTAssertEqual(AppModel.clampTriggerDelay(12.0), 10.0)
    }

    func testRecordingCueDelaysClampToSupportedRanges() {
        XCTAssertEqual(AppModel.clampRecordingStartCueDelay(0), 0.1)
        XCTAssertEqual(AppModel.clampRecordingStartCueDelay(2), 1.0)
        XCTAssertEqual(AppModel.clampRecordingStopCueDelay(-1), 0)
        XCTAssertEqual(AppModel.clampRecordingStopCueDelay(2), 1.0)
    }

    func testNeonSpotlightBusySnapshotParses() {
        let snapshot = NeonSpotlightAnimationSnapshot(userInfo: [
            NeonSpotlightStatusProtocol.Key.protocolVersion: 1,
            NeonSpotlightStatusProtocol.Key.sessionIdentifier: "session-1",
            NeonSpotlightStatusProtocol.Key.state: "busy",
            NeonSpotlightStatusProtocol.Key.activeAnimationCount: 2,
            NeonSpotlightStatusProtocol.Key.requestIdentifier: "request-1",
            NeonSpotlightStatusProtocol.Key.reason: "requested",
        ])

        XCTAssertEqual(snapshot?.state, .busy)
        XCTAssertEqual(snapshot?.activeAnimationCount, 2)
        XCTAssertEqual(snapshot?.requestIdentifier, "request-1")
    }

    func testNeonSpotlightIdleSnapshotParses() {
        let snapshot = NeonSpotlightAnimationSnapshot(userInfo: [
            NeonSpotlightStatusProtocol.Key.protocolVersion: 1,
            NeonSpotlightStatusProtocol.Key.sessionIdentifier: "session-1",
            NeonSpotlightStatusProtocol.Key.state: "idle",
            NeonSpotlightStatusProtocol.Key.activeAnimationCount: 0,
            NeonSpotlightStatusProtocol.Key.reason: "activityChanged",
        ])

        XCTAssertEqual(snapshot?.state, .idle)
        XCTAssertEqual(snapshot?.reason, .activityChanged)
    }

    func testNeonSpotlightSnapshotRejectsUnknownProtocolVersion() {
        XCTAssertNil(NeonSpotlightAnimationSnapshot(userInfo: [
            NeonSpotlightStatusProtocol.Key.protocolVersion: 2,
            NeonSpotlightStatusProtocol.Key.sessionIdentifier: "session-1",
            NeonSpotlightStatusProtocol.Key.state: "idle",
            NeonSpotlightStatusProtocol.Key.activeAnimationCount: 0,
            NeonSpotlightStatusProtocol.Key.reason: "requested",
        ]))
    }

    func testNeonSpotlightSnapshotRejectsInconsistentStateAndCount() {
        XCTAssertNil(NeonSpotlightAnimationSnapshot(userInfo: [
            NeonSpotlightStatusProtocol.Key.protocolVersion: 1,
            NeonSpotlightStatusProtocol.Key.sessionIdentifier: "session-1",
            NeonSpotlightStatusProtocol.Key.state: "idle",
            NeonSpotlightStatusProtocol.Key.activeAnimationCount: 1,
            NeonSpotlightStatusProtocol.Key.reason: "requested",
        ]))
    }

    func testUserActivityIdlePeriodClampsToSafeRange() {
        XCTAssertEqual(UserActivityIdlePolicy.clampedIdlePeriod(0), 0.5)
        XCTAssertEqual(UserActivityIdlePolicy.clampedIdlePeriod(1), 1)
        XCTAssertEqual(UserActivityIdlePolicy.clampedIdlePeriod(8), 3)
    }

    func testUserActivityMaximumWaitClampsToSafeRange() {
        XCTAssertEqual(UserActivityIdlePolicy.clampedMaximumWait(0), 3)
        XCTAssertEqual(UserActivityIdlePolicy.clampedMaximumWait(10), 10)
        XCTAssertEqual(UserActivityIdlePolicy.clampedMaximumWait(90), 30)
    }

    func testFailureCueCanReuseSelectedStopSound() {
        XCTAssertEqual(
            RecordingFailureCueSound.sameAsStop.resolvedSound(stopSound: .glass),
            .glass
        )
    }

    func testClipboardNormalization() {
        let service = ClipboardService()
        XCTAssertEqual(service.normalize("   hello world\n"), "hello world")
    }

    func testScriptSceneSplitterSplitsSentences() {
        let scenes = ScriptSceneSplitter.scenes(from: "First step. Now click the button! Done?")
        XCTAssertEqual(scenes, ["First step.", "Now click the button!", "Done?"])
    }

    func testScriptSceneSplitterDropsEmptyWhitespace() {
        XCTAssertEqual(ScriptSceneSplitter.scenes(from: "\n\n  "), [])
    }

    func testNarrationChapterLoaderPreservesExplicitScenes() throws {
        let data = Data(#"""
        {
          "schemaVersion": 3,
          "projectSlug": "test-project",
          "chapterNumber": 1,
          "chapterTitle": "Test Chapter",
          "status": "approved",
          "scenes": [
            {
              "id": "scene-01",
              "sceneNumber": 1,
              "title": "First scene",
              "displayTitle": "First Scene",
              "onScreen": {"action":"Show the page","result":"The page is visible."},
              "narration": "First sentence. Second sentence stays in this scene.",
              "code": null,
              "links": []
            },
            {
              "id": "scene-02",
              "sceneNumber": 2,
              "title": "Second scene",
              "displayTitle": "Second Scene",
              "onScreen": {"action":"Show the next view","result":"The next view is visible."},
              "narration": "Another scene.",
              "code": null,
              "links": []
            }
          ]
        }
        """#.utf8)

        let chapter = try NarrationChapterLoader.decode(data)

        XCTAssertEqual(chapter.scenes.count, 2)
        XCTAssertEqual(chapter.scenes[0].narration, "First sentence. Second sentence stays in this scene.")
    }

    func testNarrationChapterLoaderMigratesVersionTwoInMemory() throws {
        let data = Data(#"""
        {
          "schemaVersion": 2,
          "projectSlug": "legacy-project",
          "chapterNumber": 1,
          "chapterTitle": "Legacy Chapter",
          "status": "draft",
          "scenes": [{
            "id": "scene-01",
            "sceneNumber": 1,
            "title": "Legacy scene",
            "displayTitle": "Legacy Scene",
            "onScreen": {"action":"Add the code","result":"The code is visible."},
            "narration": "I am going to add this code.",
            "code": "const legacy = true;"
          }]
        }
        """#.utf8)

        let chapter = try NarrationChapterLoader.decode(data)

        XCTAssertEqual(chapter.schemaVersion, 3)
        XCTAssertEqual(chapter.scenes[0].code?.text, "const legacy = true;")
        XCTAssertEqual(chapter.scenes[0].code?.targetFile, "Unspecified")
        XCTAssertEqual(chapter.scenes[0].links, [])
    }

    func testNarrationChapterLoaderRejectsUnsupportedSchema() {
        let data = Data(#"""
        {
          "schemaVersion": 4,
          "projectSlug": "test-project",
          "chapterNumber": 1,
          "chapterTitle": "Test Chapter",
          "status": "approved",
          "scenes": [{
            "id": "scene-01",
            "sceneNumber": 1,
            "title": "Scene",
            "displayTitle": "Scene",
            "onScreen": {"action":"Show it","result":"It is visible."},
            "narration": "Narration.",
            "code": null,
            "links": []
          }]
        }
        """#.utf8)

        XCTAssertThrowsError(try NarrationChapterLoader.decode(data)) { error in
            XCTAssertEqual(error as? NarrationChapterError, .unsupportedSchemaVersion(4))
        }
    }

    func testNarrationChapterLoaderRejectsDuplicateSceneIDs() {
        let data = Data(#"""
        {
          "schemaVersion": 3,
          "projectSlug": "test-project",
          "chapterNumber": 1,
          "chapterTitle": "Test Chapter",
          "status": "approved",
          "scenes": [
            {"id":"same","sceneNumber":1,"title":"One","displayTitle":"One","onScreen":{"action":"Show one","result":"One is visible."},"narration":"One.","code":null,"links":[]},
            {"id":"same","sceneNumber":2,"title":"Two","displayTitle":"Two","onScreen":{"action":"Show two","result":"Two is visible."},"narration":"Two.","code":null,"links":[]}
          ]
        }
        """#.utf8)

        XCTAssertThrowsError(try NarrationChapterLoader.decode(data)) { error in
            XCTAssertEqual(error as? NarrationChapterError, .duplicateSceneID("same"))
        }
    }

    func testNarrationChapterLoaderRejectsEmptyNarration() {
        let data = Data(#"""
        {
          "schemaVersion": 3,
          "projectSlug": "test-project",
          "chapterNumber": 1,
          "chapterTitle": "Test Chapter",
          "status": "approved",
          "scenes": [{
            "id": "scene-01",
            "sceneNumber": 1,
            "title": "Scene",
            "displayTitle": "Scene",
            "onScreen": {"action":"Show it","result":"It is visible."},
            "narration": "   ",
            "code": null,
            "links": []
          }]
        }
        """#.utf8)

        XCTAssertThrowsError(try NarrationChapterLoader.decode(data)) { error in
            XCTAssertEqual(error as? NarrationChapterError, .emptyNarration(1))
        }
    }

    func testSpokenTextSanitizerRemovesBracketedDirections() {
        let text = "[On screen: Show the editor.] Yesterday, I wanted to add an image overlay."

        XCTAssertEqual(
            SpokenTextSanitizer.removingBracketedDirections(from: text),
            "Yesterday, I wanted to add an image overlay."
        )
    }

    func testSpokenTextSanitizerRemovesMultipleAndMultilineDirections() {
        let text = "First sentence. [On screen:\nShow the editor.] [Pause] Second sentence."

        XCTAssertEqual(
            SpokenTextSanitizer.removingBracketedDirections(from: text),
            "First sentence. Second sentence."
        )
    }

    func testSpokenTextSanitizerHandlesNestedBrackets() {
        let text = "Before [Show the editor [briefly] and close it] after."

        XCTAssertEqual(
            SpokenTextSanitizer.removingBracketedDirections(from: text),
            "Before after."
        )
    }

    func testSpokenTextSanitizerKeepsUnmatchedOpeningBracket() {
        let text = "Read this [unfinished direction"

        XCTAssertEqual(
            SpokenTextSanitizer.removingBracketedDirections(from: text),
            "Read this [unfinished direction"
        )
    }

    func testSpokenTextSanitizerCanReturnEmptyText() {
        XCTAssertEqual(
            SpokenTextSanitizer.removingBracketedDirections(from: " [Do not read this] "),
            ""
        )
    }

    func testSpeechPreparationPreservesBracketedDirectionsForReplay() {
        let text = " [On screen: Show the editor.] Read this sentence. "

        XCTAssertEqual(
            SpokenTextSanitizer.preparingForSpeech(text, includesBracketedDirections: true),
            "[On screen: Show the editor.] Read this sentence."
        )
    }

    func testSpeechPreparationRemovesBracketedDirectionsByDefault() {
        let text = "[On screen: Show the editor.] Read this sentence."

        XCTAssertEqual(
            SpokenTextSanitizer.preparingForSpeech(text, includesBracketedDirections: false),
            "Read this sentence."
        )
    }

    func testPauseResumeLabel() {
        XCTAssertEqual(SpeechState.speaking.pauseResumeTitle, "Pause Reading")
        XCTAssertEqual(SpeechState.paused.pauseResumeTitle, "Resume Reading")
    }

    func testFocuSeeStateDetectsRecordingFromPauseAction() {
        let elements = [
            FocuSeeAccessibilityElementSnapshot(
                role: "AXButton",
                labels: ["Pause"],
                isEnabled: true
            )
        ]

        XCTAssertEqual(
            FocuSeeAccessibilityService.classify(isRunning: true, elements: elements),
            .recording
        )
    }

    func testFocuSeeStateDetectsPausedFromResumeAction() {
        let elements = [
            FocuSeeAccessibilityElementSnapshot(
                role: "AXMenuItem",
                labels: ["Resume"],
                isEnabled: true
            )
        ]

        XCTAssertEqual(
            FocuSeeAccessibilityService.classify(isRunning: true, elements: elements),
            .paused
        )
    }

    func testFocuSeeStateTreatsDisabledPauseControlAsNotRecording() {
        let elements = [
            FocuSeeAccessibilityElementSnapshot(
                role: "AXMenuItem",
                labels: ["Pause"],
                isEnabled: false
            )
        ]

        XCTAssertEqual(
            FocuSeeAccessibilityService.classify(isRunning: true, elements: elements),
            .notRecording
        )
    }

    func testFocuSeeStateFailsSafeWhenSignalsConflict() {
        let elements = [
            FocuSeeAccessibilityElementSnapshot(
                role: "AXButton",
                labels: ["Pause"],
                isEnabled: true
            ),
            FocuSeeAccessibilityElementSnapshot(
                role: "AXButton",
                labels: ["Resume"],
                isEnabled: true
            )
        ]

        XCTAssertEqual(
            FocuSeeAccessibilityService.classify(isRunning: true, elements: elements),
            .unknown
        )
    }

    func testFocuSeeStateDetectsClosedApplication() {
        XCTAssertEqual(
            FocuSeeAccessibilityService.classify(isRunning: false, elements: []),
            .notRunning
        )
    }
}
