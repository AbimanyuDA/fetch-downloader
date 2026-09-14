// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MediaFetch",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "MediaFetch",
            targets: ["MediaFetch"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MediaFetch",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "MediaFetchTests",
            dependencies: ["MediaFetch"],
            path: "Tests/MediaFetchTests"
        )
    ]
)
