pluginManagement {
    repositories {
        google {
            content {
                includeGroupByRegex("com\\.android.*")
                includeGroupByRegex("com\\.google.*")
                includeGroupByRegex("androidx.*")
            }
        }
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "AddToAppHost"
include(":app")

// ─── Flutter Module (source-based dependency) ────────────────────────────────
//
// This links the Flutter module as a Gradle source dependency so that the
// host app always builds the Flutter code from source on every Gradle sync.
//
// Requirements:
//   1. Flutter SDK must be installed and `flutter` must be on PATH.
//   2. Run `flutter pub get` inside ../flutter_module/ at least once.
//   3. Set FLUTTER_SDK in local.properties (auto-created by Flutter tooling):
//        flutter.sdk=/path/to/flutter
//
// Alternative: use a pre-built AAR.
//   cd ../flutter_module && flutter build aar --no-profile
//   Then replace the includeBuild below with a maven { url } pointing to the
//   generated local maven repo at flutter_module/build/host/outputs/repo.
//
// For CI/CD, the AAR approach is often simpler.

val flutterSdkPath: String by lazy {
    val localPropsFile = file("local.properties")
    if (localPropsFile.exists()) {
        val props = java.util.Properties().apply { load(localPropsFile.inputStream()) }
        props.getProperty("flutter.sdk")
            ?: error("flutter.sdk not set in local.properties — run `flutter pub get` in flutter_module/")
    } else {
        error("local.properties not found — run `flutter pub get` in flutter_module/ or create local.properties with flutter.sdk=<path>")
    }
}

// Include the Flutter Gradle plugin (provides the flutter() extension used in app/build.gradle.kts).
includeBuild("$flutterSdkPath/packages/flutter_tools/gradle/app_plugin_loader")

// Include the Flutter module itself as a source dependency.
// This makes ":flutter_module" available as a Gradle project.
include(":flutter_module")
project(":flutter_module").projectDir = file("../flutter_module")
