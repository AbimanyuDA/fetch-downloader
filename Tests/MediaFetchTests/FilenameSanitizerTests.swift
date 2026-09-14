import XCTest
@testable import MediaFetch

final class FilenameSanitizerTests: XCTestCase {
    func testSanitizeIllegalCharacters() {
        let dirty = "My Video: Episode 1 / Season ? * < > | \" 2026"
        let clean = FilenameSanitizer.sanitize(dirty)
        XCTAssertFalse(clean.contains(":"))
        XCTAssertFalse(clean.contains("/"))
        XCTAssertFalse(clean.contains("?"))
        XCTAssertFalse(clean.contains("*"))
        XCTAssertFalse(clean.contains("<"))
        XCTAssertFalse(clean.contains(">"))
        XCTAssertFalse(clean.contains("|"))
        XCTAssertFalse(clean.contains("\""))
    }

    func testApplyTemplate() {
        let template = "%(channel)s - %(title)s - %(resolution)s"
        let result = FilenameSanitizer.applyTemplate(
            template: template,
            title: "Swift Tutorial",
            channel: "Apple Dev",
            resolution: "1080p",
            ext: "mp4"
        )
        XCTAssertEqual(result, "Apple Dev - Swift Tutorial - 1080p.mp4")
    }

    func testResolveCollision() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let file1 = tempDir.appendingPathComponent("video.mp4")
        try? "test".write(to: file1, atomically: true, encoding: .utf8)

        let resolved = FilenameSanitizer.resolveCollision(in: tempDir, desiredFilename: "video.mp4")
        XCTAssertEqual(resolved.lastPathComponent, "video 2.mp4")
    }
}
