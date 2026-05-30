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

    func testPauseResumeLabel() {
        XCTAssertEqual(SpeechState.speaking.pauseResumeTitle, "Pause Reading")
        XCTAssertEqual(SpeechState.paused.pauseResumeTitle, "Resume Reading")
    }
}
