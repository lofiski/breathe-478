plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.breathe478.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.breathe478.app"
        // minSdk 26 (Android 8.0+) lets us ship a pure vector adaptive icon
        // with no binary PNG assets in the repo.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        getByName("debug") {
            // Every GitHub Actions run is a fresh VM with no pre-existing
            // ~/.android/debug.keystore, so AGP's implicit default would
            // silently generate a NEW random debug key per build. That
            // breaks installing an update over a previous build (Android
            // refuses a signature mismatch). Pin it to a committed keystore
            // instead so every release signs identically. This is a debug
            // key only (never used for a Play Store release), so committing
            // it carries the same non-secret status as everyone's shared
            // local ~/.android/debug.keystore.
            storeFile = file("debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
            storeType = "PKCS12"
        }
    }

    buildTypes {
        release {
            // No Play Store release yet: sign with the (pinned) debug key so
            // `flutter build apk --release` produces a directly sideloadable
            // APK without needing a secret keystore in CI.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
