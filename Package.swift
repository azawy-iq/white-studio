// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WhiteStudio",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "WhiteStudio",
            targets: ["WhiteStudio"]
        ),
    ],
    targets: [
        .target(
            name: "WhiteStudio",
            dependencies: [],
            resources: [
                .process("Resources")
            ]
        ),
    ]
)
