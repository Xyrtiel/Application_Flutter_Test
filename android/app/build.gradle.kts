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
        // Ajout pour le multidex si minSdk < 21 (pas nécessaire ici car minSdk = 23)
        // multiDexEnabled = true
        // buildConfig = true // <-- SUPPRIMER CETTE LIGNE D'ICI
    }

    buildTypes {
        release {
            // Configurer les clés de signature pour le build de production
            // ATTENTION: Utiliser 'debug' pour la release n'est PAS recommandé pour la production !
            // Tu devrais configurer une vraie clé de signature pour la release.
            signingConfig = signingConfigs.getByName("debug")
            // Ajout pour Proguard/R8 si nécessaire pour la release
            // minifyEnabled = true
            // shrinkResources = true
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    // --- AJOUTER CE BLOC ---
    buildFeatures {
        buildConfig = true
    }
    // --- FIN DE L'AJOUT ---


    // Ajout pour éviter les conflits de packaging si nécessaire
    // packagingOptions {
    //     exclude("META-INF/DEPENDENCIES")
    // }
}

// Bloc des dépendances MODIFIÉ
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4") // Keep this line

    // --- AJOUTS POUR FIREBASE ---
    // Importer la Firebase BoM (Bill of Materials) pour gérer les versions
    implementation(platform("com.google.firebase:firebase-bom:33.1.0")) // Utilise la dernière version stable de la BoM

    // Ajouter les dépendances Firebase SDK dont tu as besoin SANS spécifier de version
    // (la BoM s'en charge)

    // Pour Firebase Authentication (nécessaire pour la connexion)
    implementation("com.google.firebase:firebase-auth-ktx")

    // Pour Firebase App Check (avec Play Integrity pour la production/release)
    implementation("com.google.firebase:firebase-appcheck-playintegrity")

    // Pour Firebase App Check (avec le fournisseur de débogage pour le développement)
    // Cette dépendance est nécessaire si tu utilises le DebugAppCheckProviderFactory dans MainActivity.kt
    implementation("com.google.firebase:firebase-appcheck-debug")

    // Ajoute d'autres dépendances Firebase si tu les utilises (ex: Firestore, Storage, etc.)
    // implementation("com.google.firebase:firebase-firestore-ktx")
    // implementation("com.google.firebase:firebase-storage-ktx")

    // Dépendances Kotlin standard (souvent déjà présentes ou ajoutées par les plugins)
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.8.22") // Vérifie la version de Kotlin utilisée par ton projet

    // Dépendance pour Multidex si minSdk < 21 (pas nécessaire ici)
    // implementation("androidx.multidex:multidex:2.0.1")
    // --- FIN DES AJOUTS POUR FIREBASE ---
}


flutter {
    source = "../.." // Emplacement du projet Flutter
}

// Appliquer le plugin Google Services à la fin du fichier
apply(plugin = "com.google.gms.google-services")