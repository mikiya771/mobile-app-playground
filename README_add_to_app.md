# Flutter Add-to-App — Native Tabs + Single Shared Engine

Reference implementation of **Flutter Add-to-App** with a native 5-tab bar and two Flutter-hosted tabs sharing one `FlutterEngine`.

## Architecture Overview

```
┌──────────────────────────────────────────────────┐
│                  UIWindow / Activity              │
│  ┌────────────────────────────────────────────┐  │
│  │        Native Tab Bar Controller /          │  │
│  │        MainActivity (tab bar owner)         │  │
│  │                                            │  │
│  │  ┌──────────────────────────────────────┐  │  │
│  │  │  FlutterViewController / FlutterFrag  │  │  │
│  │  │  (single resident host — show/hide)   │  │  │
│  │  │                                       │  │  │
│  │  │  ┌───────────────────────────────┐   │  │  │
│  │  │  │  StatefulShellRoute           │   │  │  │
│  │  │  │  .indexedStack                │   │  │  │
│  │  │  │                               │   │  │  │
│  │  │  │  Branch 0: /search/**         │   │  │  │
│  │  │  │  Branch 1: /shop/**           │   │  │  │
│  │  │  │                               │   │  │  │
│  │  │  │  (IndexedStack preserves      │   │  │  │
│  │  │  │   each branch's nav stack)    │   │  │  │
│  │  │  └───────────────────────────────┘   │  │  │
│  │  │                                       │  │  │
│  │  │  Single FlutterEngine / Dart isolate  │  │  │
│  │  │  Single ProviderScope (Riverpod)      │  │  │
│  │  └──────────────────────────────────────┘  │  │
│  │                                            │  │
│  │  ┌──────────────────────────────────────┐  │  │
│  │  │  Native Tab Bar (5 tabs)             │  │  │
│  │  │  [Home] [Search] [Activity] [Shop] [Profile] │  │
│  │  └──────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────┘
```

### Key Constraints (never violate)

| Constraint | Why |
|---|---|
| Exactly **1 FlutterEngine** | 2+ engines = doubled RAM/CPU + broken shared state |
| Exactly **1 Flutter host** (FVC / FlutterFragment) | Re-parenting on tab switch = flicker + detachment |
| Flutter host uses **show/hide**, never replace/recreate | Preserves engine attachment and branch state |
| **Native** owns the tab bar | Flutter never draws a BottomNavigationBar |
| **Native** initiates all branch switches via MethodChannel | Source-of-truth is native |

---

## Tab Configuration

| Index | Label    | Type    | go_router branch / path prefix |
|-------|----------|---------|-------------------------------|
| 0     | Home     | Native  | —                             |
| 1     | Search   | Flutter | Branch 0 — `/search/**`       |
| 2     | Activity | Native  | —                             |
| 3     | Shop     | Flutter | Branch 1 — `/shop/**`         |
| 4     | Profile  | Native  | —                             |

---

## MethodChannel Contract

Channel name: **`app/navigation`**

### Native → Flutter

| Method | Arguments | Behaviour |
|--------|-----------|-----------|
| `setBranch` | `{ index: int, reselect: bool }` | Calls `shell.goBranch(index)`. If `reselect=true`, calls `goBranch(index, initialLocation: true)` to reset the branch stack to root. |
| `navigate` | `{ location: String }` | Calls `router.go(location)`. go_router selects the correct branch automatically by path prefix. Used for deep links. |
| `popRoute` | — | Calls `router.pop()`. Android delegates back-press to Flutter when branch depth > 1. |

### Flutter → Native

| Method | Arguments | Behaviour |
|--------|-----------|-----------|
| `openNativeScreen` | `{ route: String, args: Map }` | iOS: presents `NativeDetailViewController` modally (pageSheet). Android: starts `NativeDetailActivity`. |
| `branchStackDidChange` | `{ index: int, depth: int }` | Sent on every route change. Android uses `depth` to decide whether back-press should pop Flutter or go to Home. |

---

## Flutter → Native Screen Strategy

**iOS**: modal `pageSheet` via `UINavigationController(rootViewController: NativeDetailViewController)`.

Rationale: The `UITabBarController` does not own a `UINavigationController` for push. Modal presentation avoids inserting into the tab controller's navigation hierarchy, keeps dismissal (swipe-down / close button) unambiguous, and doesn't conflict with the resident FlutterViewController overlay.

**Android**: `startActivity(NativeDetailActivity::class.java)`.

Rationale: Launching a new `Activity` completely sidesteps z-ordering with the `FlutterFragment` inside `MainActivity`. The user presses Back to return (standard Android pattern).

---

## go_router Route Tree

```
StatefulShellRoute.indexedStack
├── Branch 0 (Search)
│   └── /search
│       └── /:id          →  SearchDetailScreen
└── Branch 1 (Shop)
    └── /shop
        └── /:id          →  ShopDetailScreen
```

Deep-link examples:
- `sampleapp://shop/42`    → `/shop/42`   → Shop tab + detail for id=42
- `sampleapp://search/alpha` → `/search/alpha` → Search tab + detail for id=alpha

---

## Shared State (Acceptance Criterion #3)

Both branches run inside **one Dart isolate** backed by the single `FlutterEngine`. The `ProviderScope` is at the root of the widget tree and is therefore shared between the Search and Shop branches:

- `cartCountProvider` — incremented in Shop, visible in Search's AppBar badge
- `sharedCounterProvider` — editable from either branch, reflected in both

Seeing these values update without navigating proves the shared-engine constraint is met.

---

## Versions

| Package | Version |
|---------|---------|
| Flutter SDK | stable (≥ 3.22) |
| Dart SDK | ≥ 3.5.0 |
| go_router | ^14.3.0 |
| flutter_riverpod | ^2.5.1 |
| iOS deployment target | 16.0 |
| Android minSdk | 23 (Android 6.0) |
| Android compileSdk | 35 |
| Android Gradle Plugin | 8.13.2 |
| Kotlin | 2.0.21 |
| Material Components Android | 1.12.0 |

---

## Build & Run Instructions

### 1. Flutter Module

```bash
cd flutter_module
flutter pub get
# Standalone test (branch switching with temporary toggle buttons):
flutter run
```

### 2. iOS Host

Requirements: macOS + Xcode 16 + CocoaPods + XcodeGen

```bash
# 1. Ensure Flutter module deps are fetched (generates .ios/)
cd flutter_module && flutter pub get && cd ..

# 2. Generate Xcode project
cd ios
brew install xcodegen   # if not already installed
xcodegen generate

# 3. Install CocoaPods (links Flutter.framework + plugin pods)
pod install

# 4. Open workspace and run
open AddToAppHost.xcworkspace
# In Xcode: select a simulator or device, press Run (⌘R)
```

### 3. Android Host

Requirements: Android Studio or the Android SDK + Java 17

```bash
# 1. Ensure Flutter module deps are fetched
cd flutter_module && flutter pub get && cd ..

# 2. Create local.properties pointing to your Flutter SDK
cat > android/local.properties <<EOF
flutter.sdk=/path/to/your/flutter/sdk
sdk.dir=/path/to/your/android/sdk
EOF

# 3. Build & run (connects to running emulator or device)
cd android
./gradlew installDebug
```

---

## Acceptance Criteria — Reproduction Steps

| # | Criterion | Steps |
|---|-----------|-------|
| 1 | Search stack survives tab switch | Open Search → tap "Result: alpha" (depth 2) → tap Shop tab → tap Search tab → verify "Detail: alpha" is still shown |
| 2 | Shop stack survives tab switch | Open Shop → tap "Product #42" (depth 2) → tap Search tab → tap Shop tab → verify "#42" detail is still shown |
| 3 | Shared state | Open Shop → add 3 items to cart → tap Search tab → verify cart badge shows 3 |
| 4 | Re-select resets branch | Navigate to Search detail → tap Search tab again → verify Search root screen appears |
| 5 | Android back at root → Home | Open Search → press Back → verify Home tab is selected |
| 5b | Android back in detail → pop | Open Search → tap detail → press Back → verify Search root screen |
| 6 | Deep link — iOS | In Safari: `sampleapp://shop/42` → app opens Shop tab + `/shop/42` detail |
| 6b | Deep link — Android | `adb shell am start -a android.intent.action.VIEW -d "sampleapp://shop/42" com.example.addtoapp` |
| 7 | Flutter→Native | Open Search → "Open Native Screen" → native sheet/activity appears |
| 8 | Engine liveness | Go to Home (native) → wait 10 s → tap Search → Flutter renders instantly (no cold start) |
