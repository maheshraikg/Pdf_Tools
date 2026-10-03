import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.sortingsahayak.sorting_sahayak"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.sortingsahayak.sorting_sahayak"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // ML Kit text recognition v2 and camera need API 21+; Flutter needs 24+.
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Play Store upload key: android/key.properties (local, never committed)
    // or the UPLOAD_KEYSTORE_* environment variables (CI secrets). Without
    // either, release builds fall back to the debug key (test APKs only).
    val keyProps = Properties().apply {
        val f = rootProject.file("key.properties")
        if (f.exists()) f.inputStream().use { load(it) }
    }
    fun key(name: String, env: String): String? = keyProps.getProperty(name) ?: System.getenv(env)
    val uploadStore = key("storeFile", "UPLOAD_KEYSTORE_FILE")
    signingConfigs {
        if (uploadStore != null && file(uploadStore).exists()) {
            create("upload") {
                storeFile = file(uploadStore)
                storePassword = key("storePassword", "UPLOAD_KEYSTORE_PASSWORD")
                keyAlias = key("keyAlias", "UPLOAD_KEY_ALIAS")
                keyPassword = key("keyPassword", "UPLOAD_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("upload") ?: signingConfigs.getByName("debug")
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
    // Hindi (Devanagari) text recognition for address scans; bundled model,
    // works offline. Latin (English) comes with the plugin.
    implementation("com.google.mlkit:text-recognition-devanagari:16.0.1")
    // Kannada text recognition (ML Kit has no Kannada model): Tesseract with
    // the bundled tessdata_fast `kan` model in assets/tessdata.
    implementation("cz.adaptech.tesseract4android:tesseract4android:4.9.0")
}
