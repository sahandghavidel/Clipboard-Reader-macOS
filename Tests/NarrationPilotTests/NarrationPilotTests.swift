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
          "schemaVersion": 4,
          "projectSlug": "test-project",
          "chapterNumber": 1,
          "chapterTitle": "Test Chapter",
          "status": "approved",
          "scenes": [
            {
              "id": "scene-01",
              "sceneNumber": 1,
              "sceneType": "action",
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
              "sceneType": "action",
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

        XCTAssertEqual(chapter.schemaVersion, 4)
        XCTAssertEqual(chapter.scenes[0].sceneType, .action)
        XCTAssertEqual(chapter.scenes[0].code?.text, "const legacy = true;")
        XCTAssertEqual(chapter.scenes[0].code?.targetFile, "Unspecified")
        XCTAssertEqual(chapter.scenes[0].links, [])
    }

    func testNarrationChapterLoaderMigratesVersionThreeResultScene() throws {
        let data = Data(#"""
        {
          "schemaVersion": 3,
          "projectSlug": "legacy-project",
          "chapterNumber": 1,
          "chapterTitle": "Legacy Chapter",
          "status": "draft",
          "scenes": [
            {"id":"scene-01","sceneNumber":1,"title":"Run","displayTitle":"Run","onScreen":{"action":"Run the page","result":"The page is visible."},"narration":"Now I would run the page.","code":null,"links":[]},
            {"id":"scene-02","sceneNumber":2,"title":"Show","displayTitle":"Page Works","onScreen":{"action":"Keep the page visible","result":"The page remains visible."},"narration":"As you can see, the page is working.","code":null,"links":[]}
          ]
        }
        """#.utf8)

        let chapter = try NarrationChapterLoader.decode(data)

        XCTAssertEqual(chapter.schemaVersion, 4)
        XCTAssertEqual(chapter.scenes[1].sceneType, .result)
        XCTAssertNil(chapter.scenes[1].onScreen.action)
    }

    func testNarrationChapterLoaderRejectsUnsupportedSchema() {
        let data = Data(#"""
        {
          "schemaVersion": 5,
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
            XCTAssertEqual(error as? NarrationChapterError, .unsupportedSchemaVersion(5))
        }
    }

    func testNarrationChapterLoaderRejectsDuplicateSceneIDs() {
        let data = Data(#"""
        {
          "schemaVersion": 4,
          "projectSlug": "test-project",
          "chapterNumber": 1,
          "chapterTitle": "Test Chapter",
          "status": "approved",
          "scenes": [
            {"id":"same","sceneNumber":1,"sceneType":"action","title":"One","displayTitle":"One","onScreen":{"action":"Show one","result":"One is visible."},"narration":"One.","code":null,"links":[]},
            {"id":"same","sceneNumber":2,"sceneType":"action","title":"Two","displayTitle":"Two","onScreen":{"action":"Show two","result":"Two is visible."},"narration":"Two.","code":null,"links":[]}
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
          "schemaVersion": 4,
          "projectSlug": "test-project",
          "chapterNumber": 1,
          "chapterTitle": "Test Chapter",
          "status": "approved",
          "scenes": [{
            "id": "scene-01",
            "sceneNumber": 1,
            "sceneType": "action",
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

    func testNarrationChapterLoaderAcceptsResultSceneAfterAction() throws {
        let data = Data(#"""
        {
          "schemaVersion": 4,
          "projectSlug": "test-project",
          "chapterNumber": 1,
          "chapterTitle": "Test Chapter",
          "status": "draft",
          "scenes": [
            {"id":"scene-01","sceneNumber":1,"sceneType":"action","title":"Run","displayTitle":"Run","onScreen":{"action":"Run the page","result":"The page is visible."},"narration":"Now I would run the page.","code":null,"links":[]},
            {"id":"scene-02","sceneNumber":2,"sceneType":"result","title":"Show","displayTitle":"Page Works","onScreen":{"action":null,"result":"The page remains visible."},"narration":"As you can see, the page is working.","code":null,"links":[]}
          ]
        }
        """#.utf8)

        let chapter = try NarrationChapterLoader.decode(data)

        XCTAssertEqual(chapter.scenes[1].sceneType, .result)
        XCTAssertNil(chapter.scenes[1].onScreen.action)
    }

    func testNarrationChapterLoaderRejectsResultTransitionInActionScene() {
        let data = Data(#"""
        {
          "schemaVersion": 4,
          "projectSlug": "test-project",
          "chapterNumber": 1,
          "chapterTitle": "Test Chapter",
          "status": "draft",
          "scenes": [{
            "id":"scene-01","sceneNumber":1,"sceneType":"action","title":"Run","displayTitle":"Run",
            "onScreen":{"action":"Run the page","result":"The page is visible."},
            "narration":"Now I would run the page. As you can see, it works.","code":null,"links":[]
          }]
        }
        """#.utf8)

        XCTAssertThrowsError(try NarrationChapterLoader.decode(data)) { error in
            XCTAssertEqual(error as? NarrationChapterError, .resultTransitionOutsideResultScene(1))
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

    func testJSONActionSceneReplayIntroducesActionResultAndNarration() {
        let scene = NarrationScene(
            id: "scene-01",
            sceneNumber: 1,
            sceneType: .action,
            title: "Open the browser",
            displayTitle: "Open Browser",
            onScreen: NarrationOnScreen(
                action: "Open the browser.",
                result: "The homepage is visible."
            ),
            narration: "Now we can begin building the project.",
            code: nil,
            links: [],
            visualId: nil
        )

        XCTAssertEqual(
            JSONSceneReplayFormatter.spokenText(for: scene),
            """
            On screen, the action you need to do is: Open the browser.
            As a result, you should see: The homepage is visible.
            And the narration is: Now we can begin building the project.
            """
        )
    }

    func testJSONSceneReplayWithoutActionIntroducesResultAndNarration() {
        let scene = NarrationScene(
            id: "scene-02",
            sceneNumber: 2,
            sceneType: .result,
            title: "Show the homepage",
            displayTitle: "Homepage",
            onScreen: NarrationOnScreen(
                action: nil,
                result: "The homepage remains visible."
            ),
            narration: "As you can see, the homepage is ready.",
            code: nil,
            links: [],
            visualId: nil
        )

        XCTAssertEqual(
            JSONSceneReplayFormatter.spokenText(for: scene),
            """
            On screen, you should see: The homepage remains visible.
            And the narration is: As you can see, the homepage is ready.
            """
        )
    }

    func testChapterBuildsVisualURLFromSceneLink() throws {
        let scene = NarrationScene(
            id: "scene-01",
            sceneNumber: 1,
            sceneType: .action,
            title: "Show the loop",
            displayTitle: "Learning Loop",
            onScreen: NarrationOnScreen(action: "Open the visual.", result: "The loop is visible."),
            narration: "Now I would show the learning loop.",
            code: nil,
            links: [NarrationLink(label: "Learning page", url: "http://localhost:3010/learn/test-project")],
            visualId: "learning-loop"
        )
        let chapter = NarrationChapter(
            schemaVersion: 4,
            projectSlug: "test-project",
            chapterNumber: 1,
            chapterTitle: "Test",
            status: "draft",
            scenes: [scene]
        )

        XCTAssertEqual(
            chapter.visualURL(for: scene)?.absoluteString,
            "http://localhost:3010/learn/test-project#learning-loop"
        )
    }

    func testChapterBuildsProductionVisualURLWithoutSceneLink() {
        let scene = NarrationScene(
            id: "scene-01",
            sceneNumber: 1,
            sceneType: .explanation,
            title: "Show the loop",
            displayTitle: "Learning Loop",
            onScreen: NarrationOnScreen(action: nil, result: "The loop is visible."),
            narration: "This loop keeps the learning process focused.",
            code: nil,
            links: [],
            visualId: "learning-loop"
        )
        let chapter = NarrationChapter(
            schemaVersion: 4,
            projectSlug: "test-project",
            chapterNumber: 1,
            chapterTitle: "Test",
            status: "draft",
            scenes: [scene]
        )

        XCTAssertEqual(
            chapter.visualURL(for: scene)?.absoluteString,
            "https://www.100jsprojects.com/learn/test-project#learning-loop"
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
