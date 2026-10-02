// swift-tools-version: 6.1
import PackageDescription
let package = Package(
    name: "KeyboardCore",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [.library(name: "KeyboardCore", targets: ["KeyboardCore"])],
    dependencies: [
        .package(url: "https://github.com/azooKey/AzooKeyKanaKanjiConverter", exact: "0.11.2")
    ],
    targets: [
        .target(
            name: "KeyboardCore",
            dependencies: [.product(name: "KanaKanjiConverterModuleWithDefaultDictionary", package: "AzooKeyKanaKanjiConverter")],
            path: "KeyboardExtension",
            exclude: ["KeyboardModel.swift", "KeyboardViewController.swift", "KurukuruKeyboardView.swift"],
            sources: ["KanaKanjiEngine.swift"]
        ),
        .testTarget(name: "KeyboardCoreTests", dependencies: ["KeyboardCore"], path: "Tests")
    ]
)
