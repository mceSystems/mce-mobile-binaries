# WebRTC — iOS

Hosts the `WebRTC.xcframework` redistributed for SPM consumption.

## How to publish a new version

1. Obtain or build `WebRTC.xcframework` (covering device + simulator slices).
2. Zip it: `zip -ry WebRTC.xcframework.zip WebRTC.xcframework`
3. Compute the SPM checksum from the repo root:
   ```bash
   swift package compute-checksum webrtc/ios/WebRTC.xcframework.zip
   ```
4. Create a GitHub Release tagged `webrtc-<version>` (e.g. `webrtc-1.1.29400`) and attach `WebRTC.xcframework.zip`.
5. Update `Package.swift` at the repo root: set the `.binaryTarget` `url` to the release-asset URL and `checksum` to the value from step 3.
6. Bump the repo's semver tag (e.g. `v1.0.0`) so downstream consumers can pin via `from:`.

## Consumer side (iOS)

```swift
// In the consumer's Package.swift
.package(url: "https://github.com/mceSystems/mce-mobile-binaries", from: "1.0.0"),

// In the target's dependencies
.product(name: "WebRTC", package: "mce-mobile-binaries"),
```

Or via Xcode: **File → Add Package Dependencies → https://github.com/mceSystems/mce-mobile-binaries** and select the `WebRTC` product.
