// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SleepCat",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(
            name: "SleepCat",
            path: "Sources/SleepCat",
            resources: [
                .copy("Resources/睁眼.png"),
                .copy("Resources/睡觉.png"),
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("IOKit"),
            ]
        )
    ]
)
