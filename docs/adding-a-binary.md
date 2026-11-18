# Adding a binary to `mce-mobile-binaries`

End-to-end manual for publishing a new third-party binary (e.g. WebRTC, OpenSSL, any vendor's prebuilt framework) so it's consumable via Swift Package Manager (iOS) and JitPack/Maven (Android).

Worked example throughout: **`WebRTC` version `1.1.29400`**. Substitute your library and version wherever you see those values.

---

## 0. Prerequisites

- Local clone of this repo, on the default branch (`main`).
- `gh` CLI authenticated against `mceSystems` (`gh auth status`).
- Swift toolchain installed (`swift --version`) — only needed for iOS step 2.5 (checksum) and 2.8 (local verification).
- The prebuilt binary in hand:
  - **iOS**: a valid `XCFramework` covering device + simulator slices.
  - **Android**: a valid `.aar`.

---

## 1. Repo state requirements (one-time, already done for this repo)

- Repo visibility must be **public**. SPM downloads binary-target assets anonymously; private repos return 404. Set via:
  ```bash
  gh repo edit mceSystems/mce-mobile-binaries --visibility public --accept-visibility-change-consequences
  ```
- Repo must have a semver-style git tag (e.g. `1.0.0`) so SPM consumers can pin with `from: "x.y.z"`. Per-library tags like `webrtc-1.1.29400` are **separate** from the repo's semver — they identify the binary asset's upstream version.

---

## 2. iOS / Swift Package Manager flow

### 2.1 Place the XCFramework

```
<library>/ios/<Library>.xcframework/
```

Example for WebRTC: `webrtc/ios/WebRTC.xcframework/`

The `.xcframework` itself is gitignored (`*.xcframework/`) — it lives in the working tree only for build/publish, never committed.

### 2.2 Validate the XCFramework structure

```bash
ls <library>/ios/<Library>.xcframework
```

You should see:
- `Info.plist` — declares the bundle as `XFWK` format
- Per-slice subdirectories like `ios-arm64/` (device) and `ios-arm64_x86_64-simulator/` (simulator)
- Each slice contains the actual `.framework`

If you only see one slice (e.g. only device, no simulator), SPM consumers won't be able to build for the simulator. Reject and rebuild.

### 2.3 Clean cruft

```bash
find <library>/ios/<Library>.xcframework -name .DS_Store -delete
```

Stray `.DS_Store` files don't break SPM but pollute the artifact and waste bytes in every consumer's checkout.

### 2.4 Zip the framework

```bash
cd <library>/ios
zip -ry <Library>.xcframework.zip <Library>.xcframework
cd -
```

`-r` recursive, `-y` preserves symlinks (some frameworks need this).

### 2.5 Compute the SPM checksum

```bash
swift package compute-checksum <library>/ios/<Library>.xcframework.zip
```

Run from the **repo root** (not the `ios/` subdir — SPM resolves the path relative to where you invoke it). Save the SHA256 output; you'll paste it into `Package.swift`.

Example: `25cd3fc059a75aba02eb552876ab87ca4412425a18752740eae717b4f8676c28`

### 2.6 Cut a GitHub Release for the binary

**Why this step matters:** a git commit alone doesn't host binaries — the repo only contains source code, and we deliberately gitignore `.xcframework` files because they're huge. Without a release, your `<Library>.xcframework.zip` would just be sitting on your laptop with nowhere to be downloaded from.

The release gives the zip a permanent home with a URL we can hardcode into `Package.swift`. When a consumer's Xcode resolves the SPM dependency, it downloads the zip from that URL, checks the SHA256 against the `checksum` we declared, and unzips it into its build folder.

```bash
gh release create <library>-<version> <library>/ios/<Library>.xcframework.zip \
  --repo mceSystems/mce-mobile-binaries \
  --title "<Library> <version> (iOS XCFramework)"
```

When prompted:
- **Title** — accept the default or override (already set via `--title` above).
- **Notes** — optional; can be edited later via `gh release edit` or the web UI.
- **Prerelease** — `N` for stable.

This creates:
- A new git tag `<library>-<version>` on the default branch.
- A release page with `<Library>.xcframework.zip` as a downloadable asset.
- A stable URL: `https://github.com/mceSystems/mce-mobile-binaries/releases/download/<library>-<version>/<Library>.xcframework.zip`

### 2.7 Add the product + binary target to `Package.swift`

```swift
products: [
    // existing libraries
    .library(name: "<Library>", targets: ["<Library>"]),
],
targets: [
    // existing binary targets
    .binaryTarget(
        name: "<Library>",
        url: "https://github.com/mceSystems/mce-mobile-binaries/releases/download/<library>-<version>/<Library>.xcframework.zip",
        checksum: "<sha256 from step 2.5>"
    ),
]
```

### 2.8 Verify SPM can resolve

```bash
swift package resolve
```

From the repo root. Output is silent on success. Failure modes:
- `badResponseStatusCode(404)` → repo is private (see step 1) or URL/tag mismatch.
- `checksumMismatch` → checksum in `Package.swift` doesn't match the asset on the release. Recompute (2.5) and update.

### 2.9 Commit, push, bump the repo's semver tag

First add the library's licence and the notices of everything built into it to `THIRD-PARTY-NOTICES.md`: a row in the table, and a section with the notice text the binary ships with. The root `LICENSE` covers only MCE's packaging, never the binary.

```bash
git add Package.swift THIRD-PARTY-NOTICES.md
git commit -m "Add <Library> <version>"
git push origin main

# Bump the repo's semver — minor for added library, patch for version bump of an existing one
git tag 1.1.0
git push origin 1.1.0
```

After this, downstream consumers can pin via `from: "1.1.0"` (or `.exact("1.1.0")` for strict pinning, which is often the right choice for binary-only packages — see "Consumer pinning strategy" below).

---

## 3. Android / JitPack flow

### 3.1 Place the AAR

```
<library>/android/<library>.aar
```

Gitignored (`*.aar`) — same lifecycle as the XCFramework.

### 3.2 Update or add `build.gradle`

If this is a new library, create `<library>/android/build.gradle`:

```gradle
plugins {
    id 'maven-publish'
}

group = 'com.github.mceSystems.mce-mobile-binaries'
version = project.findProperty('<library>Version') ?: '<default-version>'

publishing {
    publications {
        <library>(MavenPublication) {
            groupId = group
            artifactId = '<library>'
            version = version

            artifact("$projectDir/<library>.aar")

            pom {
                name = '<Library>'
                description = 'Prebuilt <Library> for Android, redistributed by MCE Systems'
                url = 'https://github.com/mceSystems/mce-mobile-binaries'
                licenses {
                    license {
                        name = '<SPDX id of the library licence>'
                        url = 'https://raw.githubusercontent.com/mceSystems/mce-mobile-binaries/<library>-android-<version>/THIRD-PARTY-NOTICES.md'
                        comments = '<Library> and its bundled components; see THIRD-PARTY-NOTICES.md for the full set'
                    }
                }
            }
        }
    }
}
```

The `pom` block is what gives the published Maven POM a licence. Its `url` points at the notices file as of the release tag from 3.3, so it keeps matching the artifact. Write the tag out by hand and update it with each release: under JitPack `version` is the whole tag name (`<library>-android-<version>`), so building the URL from `${version}` would repeat the prefix.

### 3.3 Tag the Android release

```bash
gh release create <library>-android-<version> <library>/android/<library>.aar \
  --repo mceSystems/mce-mobile-binaries \
  --title "<Library> <version> (Android AAR)"
```

JitPack reads the tag and builds the Maven artifact on first consumer request. The `jitpack.yml` at the repo root configures the build (JDK + gradle publish command).

### 3.4 Consumer Gradle snippet

In the consumer's `settings.gradle`:

```gradle
dependencyResolutionManagement {
    repositories {
        maven { url 'https://jitpack.io' }
    }
}
```

In the consumer's module `build.gradle`:

```gradle
dependencies {
    implementation 'com.github.mceSystems:mce-mobile-binaries:<library>-android-<version>'
}
```

---

## 4. Consumer pinning strategy

For binary-only packages, prefer `.exact(...)` over `from:` — a binary's behavior is fixed at build time, and you usually don't want a "compatible minor version" surprise.

```swift
// Recommended for binary dependencies
.package(url: "https://github.com/mceSystems/mce-mobile-binaries", .exact("1.1.0")),

// Looser, semver-compatible — only OK if you trust this repo's versioning
.package(url: "https://github.com/mceSystems/mce-mobile-binaries", from: "1.0.0"),
```

---

## 5. Updating an existing library to a new upstream version

1. Replace the local `<library>/ios/<Library>.xcframework` (and/or `.aar`).
2. Repeat steps 2.3 → 2.6 with the new `<version>`. Use a **new** binary tag (`<library>-<new-version>`); don't overwrite the old release — keep it for any consumers pinned to it.
3. Update the existing `.binaryTarget(url:checksum:)` in `Package.swift` to the new URL + new checksum.
4. Bump the repo's semver tag (step 2.9) — patch for a binary-only bump, minor if you also added/removed a library.

---

## 6. Common pitfalls

| Symptom | Cause | Fix |
|---|---|---|
| `swift package resolve` → `badResponseStatusCode(404)` | Repo is private | `gh repo edit ... --visibility public --accept-visibility-change-consequences` |
| `swift package resolve` → `checksumMismatch` | Zip changed after checksum was computed (re-zipped without recomputing, `.DS_Store` re-added, etc.) | Recompute (2.5), update `Package.swift`, recommit |
| Asset URL works in browser but SPM still 404s | Browser is authenticated; SPM isn't. Asset is on a private repo. | Same as 404 above. |
| `swift package compute-checksum` → "file not found" | You ran it from the wrong directory. Paths are relative to `cwd`. | Run from repo root with the relative path: `swift package compute-checksum webrtc/ios/WebRTC.xcframework.zip` |
| Consumer's `from: "1.0.0"` doesn't pick up the new release | New release was tagged `<library>-<version>` (not semver) — that doesn't satisfy `from:` | Bump the **repo-level** semver tag too (step 2.9) |
| Build fails for simulator only | XCFramework has only the device slice | Rebuild XCFramework with both `ios-arm64` and `ios-arm64_x86_64-simulator` slices |

---

## 7. Quick reference — the WebRTC 1.1.29400 publish, condensed

```bash
# 1. place the framework
mv ~/Downloads/WebRTC.xcframework webrtc/ios/

# 2. clean + zip
find webrtc/ios/WebRTC.xcframework -name .DS_Store -delete
(cd webrtc/ios && zip -ry WebRTC.xcframework.zip WebRTC.xcframework)

# 3. checksum
swift package compute-checksum webrtc/ios/WebRTC.xcframework.zip
# → 25cd3fc059a75aba02eb552876ab87ca4412425a18752740eae717b4f8676c28

# 4. release
gh release create webrtc-1.1.29400 webrtc/ios/WebRTC.xcframework.zip \
  --repo mceSystems/mce-mobile-binaries \
  --title "WebRTC 1.1.29400 (iOS XCFramework)"

# 5. edit Package.swift — add product + binary target with url + checksum

# 6. add the binary's licence and bundled notices to THIRD-PARTY-NOTICES.md

# 7. verify
swift package resolve

# 8. push + semver tag
git add Package.swift THIRD-PARTY-NOTICES.md && git commit -m "Add WebRTC 1.1.29400"
git push origin main
git tag 1.0.0 && git push origin 1.0.0
```
