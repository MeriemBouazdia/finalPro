plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle plugin
    id("dev.flutter.flutter-gradle-plugin")
    // Google Services plugin
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.app"
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
        applicationId = "com.example.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.7.0"))

    // Firebase products (no versions when using BoM)
    implementation("com.google.firebase:firebase-analytics")
}

// Explicitly apply the plugin at the bottom (fixes some Kotlin DSL issues)
apply(plugin = "com.google.gms.google-services")
