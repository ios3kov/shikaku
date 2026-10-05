// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ShikakuCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "ShikakuCore", targets: ["ShikakuCore"])
    ],
    targets: [
        .target(name: "ShikakuCore"),
        .testTarget(name: "ShikakuCoreTests", dependencies: ["ShikakuCore"])
    ]
)
