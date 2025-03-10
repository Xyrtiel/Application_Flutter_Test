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
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.flutter_application_test" // Unique ID de l'application
        minSdk = 23 // Minimum SDK requis
        targetSdk = flutter.targetSdkVersion // Cible la version SDK de Flutter
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

flutter {
    source = "../.." // Emplacement du projet Flutter
}
