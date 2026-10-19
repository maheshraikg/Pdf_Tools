import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.maheshrai.waqt"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Needed by flutter_local_notifications (java.time on old Androids).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Own id for Azan Time: installs cleanly next to any old "Waqt" test
        // build signed with another key.
        applicationId = "com.maheshrai.azantime"
        // Android 7.0+: DND access and battery-optimisation APIs.
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Release signing: android/key.properties (storeFile, storePassword,
    // keyAlias, keyPassword) when present. Otherwise the fixed test key in
    // app/test-signing.p12, so every test build (CI included) has the same
    // signature and installs as an update over the previous one. That key
    // is public: use your own key.properties for store releases.
    val keyProps = Properties().apply {
        val f = rootProject.file("key.properties")
        if (f.exists()) f.inputStream().use { load(it) }
    }
    signingConfigs {
        create("test") {
            storeFile = file("test-signing.p12")
            storeType = "PKCS12"
            storePassword = "waqt-test"
            keyAlias = "waqt-test"
            keyPassword = "waqt-test"
            // v1 (JAR) as well as v2: some phone makers' installers (seen on
            // Xiaomi, Android 10) reject APKs without a v1 signature.
            enableV1Signing = true
            enableV2Signing = true
        }
        if (keyProps.containsKey("storeFile")) {
            create("release") {
                storeFile = file(keyProps.getProperty("storeFile"))
                storePassword = keyProps.getProperty("storePassword")
                keyAlias = keyProps.getProperty("keyAlias")
                keyPassword = keyProps.getProperty("keyPassword")
                enableV1Signing = true
                enableV2Signing = true
            }
        }
    }

    // Compressed native libraries, extracted at install: the most widely
    // accepted packaging (also a smaller APK).
    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("test")
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
