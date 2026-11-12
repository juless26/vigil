// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VigilDesignSystem",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(name: "VigilDesignSystem", targets: ["VigilDesignSystem"])
    ],
    targets: [
        .target(
            name: "VigilDesignSystem",
            path: "Sources/VigilDesignSystem",
            resources: [.process("Resources")]
        )
    ]
)
