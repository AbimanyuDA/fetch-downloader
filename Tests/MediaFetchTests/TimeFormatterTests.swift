import XCTest
@testable import MediaFetch

final class TimeFormatterTests: XCTestCase {
    func testFormatSecondsToTimeStrings() {
        XCTAssertEqual(TimeFormatter.format(seconds: 0), "00:00")
        XCTAssertEqual(TimeFormatter.format(seconds: 59), "00:59")
        XCTAssertEqual(TimeFormatter.format(seconds: 65), "01:05")
        XCTAssertEqual(TimeFormatter.format(seconds: 3600), "01:00:00")
        XCTAssertEqual(TimeFormatter.format(seconds: 3665), "01:01:05")
    }

    func testParseTimeStringsToSeconds() {
        XCTAssertEqual(TimeFormatter.parse(string: "00:00"), 0)
        XCTAssertEqual(TimeFormatter.parse(string: "01:05"), 65)
        XCTAssertEqual(TimeFormatter.parse(string: "01:01:05"), 3665)
        XCTAssertEqual(TimeFormatter.parse(string: "120"), 120)
        XCTAssertNil(TimeFormatter.parse(string: "invalid"))
        XCTAssertNil(TimeFormatter.parse(string: "-10"))
    }

    func testFormatETA() {
        XCTAssertEqual(TimeFormatter.formatETA(seconds: 45), "00:45")
        XCTAssertEqual(TimeFormatter.formatETA(seconds: 125), "02:05")
        XCTAssertEqual(TimeFormatter.formatETA(seconds: 3610), "01:00:10")
    }
}
