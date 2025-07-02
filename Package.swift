// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SegmentUserpilot",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "SegmentUserpilot",
            targets: ["SegmentUserpilot"]),
    ],
    dependencies: [
        .package(url: "https://github.com/segmentio/analytics-swift.git", from: "1.7.3"),
        .package(url: "https://github.com/Userpilot/ios-sdk.git", from: "1.0.2"),
    ],
    targets: [
        .target(
            name: "SegmentUserpilot",
            dependencies: [
                .product(name: "Segment", package: "analytics-swift"),
                .product(name: "Userpilot", package: "ios-sdk")
            ]),
        .testTarget(
            name: "SegmentUserpilotTests",
            dependencies: ["SegmentUserpilot"]),
    ]
)
