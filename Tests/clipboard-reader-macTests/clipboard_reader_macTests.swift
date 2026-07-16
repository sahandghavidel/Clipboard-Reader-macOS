import XCTest
@testable import clipboard_reader_mac

final class ClipboardReaderMacTests: XCTestCase {
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
}
