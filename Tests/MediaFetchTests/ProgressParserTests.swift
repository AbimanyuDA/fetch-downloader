import XCTest
@testable import MediaFetch

final class ProgressParserTests: XCTestCase {
    func testParseYTDLPProgressLine() {
        let line = "[download]  45.2% of ~  125.40MiB at    8.32MiB/s ETA 00:08"
        let update = ProgressParser.parseYTDLPLine(line)

        XCTAssertNotNil(update)
        XCTAssertEqual(update?.percentage, 45.2)
        XCTAssertEqual(update?.phase, .downloading)
        XCTAssertEqual(update?.etaSeconds, 8)
        XCTAssertNotNil(update?.totalBytes)
        XCTAssertNotNil(update?.speedBytesPerSecond)
    }

    func testParseYTDLPFinishedLine() {
        let line = "[download] 100% of 12.34MiB in 00:01"
        let update = ProgressParser.parseYTDLPLine(line)

        XCTAssertNotNil(update)
        XCTAssertEqual(update?.percentage, 100.0)
    }

    func testParseMergerLine() {
        let line = "[Merger] Merging formats into 'output.mp4'"
        let update = ProgressParser.parseYTDLPLine(line)

        XCTAssertNotNil(update)
        XCTAssertEqual(update?.phase, .merging)
    }

    func testParseFFmpegProgress() {
        let line = "frame=  120 fps= 60 q=28.0 size=    1024kB time=00:00:10.00 bitrate= 838.9kbits/s speed=1.95x"
        let update = ProgressParser.parseFFmpegProgress(line: line, totalDuration: 20.0)

        XCTAssertNotNil(update)
        XCTAssertEqual(update?.percentage, 50.0)
        XCTAssertEqual(update?.phase, .converting)
    }
}
