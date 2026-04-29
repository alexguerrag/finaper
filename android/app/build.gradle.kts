import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

fun requireKeyProperty(name: String): String =
    (keyProperties[name] as String?)?.takeIf { it.isNotBlank() }
        ?: error("Release signing requires '$name' in key.properties. Aborting build.")

android {
    namespace = "com.alexguerrag.finaper"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            if (!keyPropertiesFile.exists()) {
                error("key.properties not found. Release builds require a valid signing configuration.")
            }
            keyAlias = requireKeyProperty("keyAlias")
            keyPassword = requireKeyProperty("keyPassword")
            storeFile = file(requireKeyProperty("storeFile"))
            storePassword = requireKeyProperty("storePassword")
        }
    }

    defaultConfig {
        applicationId = "com.alexguerrag.finaper"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
