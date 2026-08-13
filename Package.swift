// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "IPWhois",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
    ],
    products: [
        .library(name: "IPWhois", targets: ["IPWhois"]),
        .executable(name: "Check", targets: ["Check"]),
    ],
    targets: [
        .target(name: "IPWhois", dependencies: []),
        .executableTarget(
            name: "Check",
            dependencies: ["IPWhois"],
            path: "Examples/Check"
        ),
    ]
)
