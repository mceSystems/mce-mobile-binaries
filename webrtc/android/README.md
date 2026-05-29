# WebRTC — Android

Hosts the `webrtc.aar` redistributed for Gradle consumption via JitPack.

## How to publish a new version

1. Drop the prebuilt `webrtc.aar` here (next to `build.gradle`).
2. Bump `webrtcVersion` in `build.gradle` (or pass `-PwebrtcVersion=...` on publish).
3. Create a GitHub Release tagged `webrtc-android-<version>` — JitPack reads the tag and builds the Maven artifact on first request.

## Consumer side (Android)

In the consumer's project-level `settings.gradle`:

```gradle
dependencyResolutionManagement {
    repositories {
        maven { url 'https://jitpack.io' }
    }
}
```

In the app/library module's `build.gradle`:

```gradle
dependencies {
    implementation 'com.github.mceSystems:mce-mobile-binaries:webrtc-android-1.1.29400'
}
```

(JitPack maps `<group>:<repo>:<tag>` to a build of that tag; the first consumer triggers the build, subsequent consumers get the cached artifact.)
