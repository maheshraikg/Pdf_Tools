plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.beatmitra.beat_mitra"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.beatmitra.beat_mitra"
        // flutter_secure_storage / local_auth / ML Kit need API 23+; 24 keeps
        // SQLCipher and camera plugins happy on old low-end phones too.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // "offline" (default): no INTERNET permission at all.
    // "map": adds INTERNET only for the optional OpenStreetMap view.
    flavorDimensions += "network"
    productFlavors {
        create("offline") {
            dimension = "network"
        }
        create("map") {
            dimension = "network"
            applicationIdSuffix = ".map"
            versionNameSuffix = "-map"
        }
    }

    buildTypes {
        release {
            // Signed with the debug key so the APK installs directly. For a
            // store release, create your own keystore (see README).
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // On-device OCR model for Hindi / Devanagari (bundled, works offline).
    implementation("com.google.mlkit:text-recognition-devanagari:16.0.1")
}
