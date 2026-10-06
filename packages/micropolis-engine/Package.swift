// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MicropolisEngine",
    platforms: [.macOS(.v14)],
    products: [.library(name: "MicropolisEngine", targets: ["MicropolisEngine"])],
    targets: [
        .target(
            name: "MicropolisEngine",
            path: ".",
            exclude: ["Package.swift"],
            sources: ["src", "native"],
            publicHeadersPath: "native/include"
        )
    ],
    cxxLanguageStandard: .cxx17
)
