// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MobileBinaries",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
    ],
    products: [
        .library(name: "WebRTC", targets: ["WebRTC"]),
    ],
    targets: [
        .binaryTarget(
            name: "WebRTC",
            url: "https://github.com/mceSystems/mce-mobile-binaries/releases/download/webrtc-1.1.29400/WebRTC.xcframework.zip",
            checksum: "25cd3fc059a75aba02eb552876ab87ca4412425a18752740eae717b4f8676c28"
        ),
    ]
)
