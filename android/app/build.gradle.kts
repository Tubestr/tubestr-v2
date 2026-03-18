import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun propOrEnv(propName: String, envName: String): String? =
    keystoreProperties.getProperty(propName)?.takeIf { it.isNotBlank() }
        ?: System.getenv(envName)?.takeIf { it.isNotBlank() }

val releaseKeyAlias = propOrEnv("keyAlias", "ANDROID_KEY_ALIAS")
val releaseKeyPassword = propOrEnv("keyPassword", "ANDROID_KEY_PASSWORD")
val releaseStorePassword = propOrEnv("storePassword", "ANDROID_STORE_PASSWORD")
val releaseStoreFilePath =
    keystoreProperties.getProperty("storeFile")?.takeIf { it.isNotBlank() }
        ?: System.getenv("ANDROID_KEYSTORE_PATH")?.takeIf { it.isNotBlank() }
val hasReleaseSigning =
    releaseKeyAlias != null &&
        releaseKeyPassword != null &&
        releaseStorePassword != null &&
        releaseStoreFilePath != null

android {
    namespace = "app.tubestr.mobile"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "app.tubestr.mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
                storeFile = file(releaseStoreFilePath!!)
                storePassword = releaseStorePassword
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

gradle.taskGraph.whenReady {
    val isReleaseBuildRequested =
        allTasks.any { task ->
            (task.name.startsWith("assemble") ||
                task.name.startsWith("bundle") ||
                task.name.startsWith("package")) &&
                task.name.contains("Release", ignoreCase = true)
        }

    if (isReleaseBuildRequested && !hasReleaseSigning) {
        throw GradleException(
            "Release signing is not configured. Add android/key.properties or set ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD, ANDROID_STORE_PASSWORD, and ANDROID_KEYSTORE_PATH.",
        )
    }
}
