plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") // Flutter plugin
}

android {
    // Configuration NDK version correcte
    ndkVersion = "27.0.12077973" // NDK version requise par certains plugins

    namespace = "com.example.flutter_application_test"
    compileSdk = 34 // Use a recent version

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11 // Use Java 11 or 17
        targetCompatibility = JavaVersion.VERSION_11 // Use Java 11 or 17
        isCoreLibraryDesugaringEnabled = true // Keep this line
    }

    kotlinOptions {
        jvmTarget = "11" // Use Java 11 or 17
    }

    defaultConfig {
        applicationId = "com.example.flutter_application_test" // Unique ID de l'application
        minSdk = 23 // Minimum SDK requis
        targetSdk = 34 // Cible la version SDK de Flutter
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Configurer les clés de signature pour le build de production
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4") // Keep this line
}

flutter {
    source = "../.." // Emplacement du projet Flutter
}
