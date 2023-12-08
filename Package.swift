// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "CSVData",
    platforms: [
        .macOS(.v12),
        .iOS(.v14),
        .tvOS(.v14),
        .watchOS(.v7)
    ],
    products: [
        .library(
            name: "CSVData",
            targets: ["CSVData"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CSVData",
            dependencies: [],
            plugins: []),
        .testTarget(
            name: "CSVDataTests",
            dependencies: ["CSVData"]),
    ]
)
