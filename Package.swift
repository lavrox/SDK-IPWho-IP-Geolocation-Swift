// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "IPWho",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
    ],
    products: [
        .library(name: "IPWho", targets: ["IPWho"]),
        .executable(name: "Check", targets: ["Check"]),
    ],
    targets: [
        .target(name: "IPWho", dependencies: []),
        .executableTarget(
            name: "Check",
            dependencies: ["IPWho"],
            path: "Examples/Check"
        ),
    ]
)
