import XCTest
@testable import MediaFetch

final class FormatSelectionTests: XCTestCase {
    func testAvailableHeightsSorting() {
        let formats = [
            MediaFormat(id: "1", ext: "mp4", height: 720, videoCodec: "avc1"),
            MediaFormat(id: "2", ext: "mp4", height: 1080, videoCodec: "avc1"),
            MediaFormat(id: "3", ext: "webm", height: 2160, videoCodec: "vp9"),
            MediaFormat(id: "4", ext: "mp4", height: 480, videoCodec: "avc1")
        ]

        let info = MediaInfo(
            id: "vid1",
            title: "Test Video",
            channel: "Test Channel",
            webpageUrl: "https://youtube.com/watch?v=123",
            formats: formats
        )

        XCTAssertEqual(info.maxResolutionHeight, 2160)
        XCTAssertEqual(info.availableHeights, [2160, 1080, 720, 480])
    }

    func testTrimRangeValidation() {
        var range = TrimRange(isEnabled: true, startTime: 10, endTime: 30, totalDuration: 60)
        XCTAssertTrue(range.isValid)
        XCTAssertNil(range.validationErrorMessage)
        XCTAssertEqual(range.duration, 20)

        // Invalid: start >= end
        range.startTime = 35
        XCTAssertFalse(range.isValid)
        XCTAssertNotNil(range.validationErrorMessage)

        // Invalid: end > duration
        range.startTime = 10
        range.endTime = 70
        XCTAssertFalse(range.isValid)
        XCTAssertNotNil(range.validationErrorMessage)
    }

    func testFastRemuxDecision() {
        var settings = OutputSettings()
        settings.mode = .video
        settings.videoFormat = .mkv
        XCTAssertTrue(settings.isFastRemuxOnly)

        settings.videoFormat = .mp4
        settings.videoCodec = .copy
        XCTAssertTrue(settings.isFastRemuxOnly)
    }
}
