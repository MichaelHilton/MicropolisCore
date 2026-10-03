// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MicropolisMac",
    platforms: [.macOS(.v14)],
    dependencies: [.package(path: "../../packages/micropolis-engine")],
    targets: [
        .target(name: "MicropolisKit",
                dependencies: [.product(name: "MicropolisEngine", package: "micropolis-engine")]),
        .executableTarget(name: "MicropolisMac", dependencies: ["MicropolisKit"], resources: [.copy("Resources")]),
        .testTarget(name: "MicropolisKitTests", dependencies: ["MicropolisKit"]),
    ]
)
