# mce-mobile-binaries

Vendored third-party mobile binaries (XCFramework + AAR), redistributed via SPM and JitPack for libraries that don't publish their own packages.

## Layout

```
mce-mobile-binaries/
├── Package.swift         # SPM entry; one product per library
├── jitpack.yml           # JitPack build config for Android
├── webrtc/
│   ├── ios/              # WebRTC.xcframework publish docs
│   └── android/          # webrtc.aar + maven-publish gradle config
└── <next-library>/
    ├── ios/
    └── android/
```

Each library gets its own subdirectory with `ios/` and `android/` siblings. Add a new library by:
1. Creating `<library>/ios/` and `<library>/android/` folders with the per-platform binaries.
2. Adding a `.binaryTarget` + matching `.library` product to `Package.swift`.
3. Adding a `<library>/android/build.gradle` if the JitPack publish needs custom config.

## Consumer side

### iOS (Swift Package Manager)

```swift
// Package.swift
.package(url: "https://github.com/mceSystems/mce-mobile-binaries", from: "1.0.0"),

// Target dependency
.product(name: "WebRTC", package: "mce-mobile-binaries"),
```

Or via Xcode: **File → Add Package Dependencies → https://github.com/mceSystems/mce-mobile-binaries** and select the products you need.

### Android (Gradle via JitPack)

```gradle
// settings.gradle
dependencyResolutionManagement {
    repositories {
        maven { url 'https://jitpack.io' }
    }
}

// build.gradle (app or library module)
dependencies {
    implementation 'com.github.mceSystems:mce-mobile-binaries:webrtc-android-1.1.29400'
}
```

## Release tagging

- **iOS releases** — tag `<library>-<version>` (e.g. `webrtc-1.1.29400`); attach `<Library>.xcframework.zip` as a release asset and reference it from `Package.swift`'s `.binaryTarget(url:checksum:)`.
- **Android releases** — tag `<library>-android-<version>` (e.g. `webrtc-android-1.1.29400`); JitPack reads the tag and builds on demand.
- **Repo-level semver tags** (e.g. `1.0.0`) — bumped when any library is added or updated, so SPM consumers can pin `from: "1.0.0"`.

See `webrtc/ios/README.md` and `webrtc/android/README.md` for per-library publish steps.

## Licence

Two owners, two sets of terms:

- **MCE's packaging and docs** (`Package.swift`, `jitpack.yml`, the Gradle publish config, the READMEs and `docs/`) are under the BSD 3-Clause licence in [`LICENSE`](LICENSE).
- **The binaries** (`WebRTC.xcframework`, `webrtc.aar` and every release asset) are third-party works under their authors' own terms, which `LICENSE` does not change. Those terms are in [`THIRD-PARTY-NOTICES.md`](THIRD-PARTY-NOTICES.md).

When you add a library, add its licence and notices to `THIRD-PARTY-NOTICES.md` in the same change.
