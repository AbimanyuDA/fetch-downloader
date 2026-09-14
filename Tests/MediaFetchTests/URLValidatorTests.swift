import XCTest
@testable import MediaFetch

final class URLValidatorTests: XCTestCase {
    func testValidURLs() {
        XCTAssertTrue(URLValidator.isValidMediaURL("https://www.youtube.com/watch?v=dQw4w9WgXcQ"))
        XCTAssertTrue(URLValidator.isValidMediaURL("https://youtu.be/dQw4w9WgXcQ"))
        XCTAssertTrue(URLValidator.isValidMediaURL("https://www.youtube.com/shorts/abcdef12345"))
        XCTAssertTrue(URLValidator.isValidMediaURL("https://www.youtube.com/playlist?list=PL1234567890"))
        XCTAssertFalse(URLValidator.isValidMediaURL("not a url"))
        XCTAssertFalse(URLValidator.isValidMediaURL("ftp://something.com"))
    }

    func testPlatformDetection() {
        XCTAssertEqual(
            URLValidator.detectPlatform(from: "https://www.youtube.com/watch?v=123"),
            .youtubeVideo
        )
        XCTAssertEqual(
            URLValidator.detectPlatform(from: "https://www.youtube.com/shorts/123"),
            .youtubeShorts
        )
        XCTAssertEqual(
            URLValidator.detectPlatform(from: "https://www.youtube.com/playlist?list=PL123"),
            .youtubePlaylist
        )
        XCTAssertEqual(
            URLValidator.detectPlatform(from: "https://vimeo.com/123456"),
            .generic
        )
    }

    func testCleanURL() {
        let dirty = "https://www.youtube.com/watch?v=123&si=trackingToken&feature=shared"
        let clean = URLValidator.cleanURL(dirty)
        XCTAssertTrue(clean.contains("v=123"))
        XCTAssertFalse(clean.contains("si=trackingToken"))
        XCTAssertFalse(clean.contains("feature=shared"))
    }
}
