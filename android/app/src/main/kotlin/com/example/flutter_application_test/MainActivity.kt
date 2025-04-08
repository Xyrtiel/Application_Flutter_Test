package com.example.flutter_application_test

// Imports nécessaires
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.google.firebase.FirebaseApp
import com.google.firebase.appcheck.FirebaseAppCheck
import com.google.firebase.appcheck.debug.DebugAppCheckProviderFactory
import android.util.Log

// Importe ta classe BuildConfig générée par Gradle
import com.example.flutter_application_test.BuildConfig

// --- AJOUTS POUR FIREBASE AUTH ET PIGEON ---
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.ktx.auth
import com.google.firebase.ktx.Firebase
import com.example.flutter_application_test.PigeonUserDetails
// --- FIN DES AJOUTS ---


// --- CLASSE D'IMPLÉMENTATION PIGEON ---
class MyPigeonApiImplementation : HostApi {

    private val auth: FirebaseAuth = Firebase.auth

    override fun signInWithEmailAndPassword(email: String, password: String, callback: (kotlin.Result<PigeonUserDetails?>) -> Unit) {
        auth.signInWithEmailAndPassword(email, password)
            .addOnCompleteListener { task ->
                if (task.isSuccessful) {
                    val firebaseUser = task.result?.user
                    if (firebaseUser != null) {
                        val userDetails = PigeonUserDetails(
                            uid = firebaseUser.uid,
                            email = firebaseUser.email
                        )
                        Log.d("MyPigeonApi", "Sign in successful, returning user: ${userDetails.uid}")
                        callback(kotlin.Result.success(userDetails))
                    } else {
                        Log.w("MyPigeonApi", "Sign in task successful but user is null")
                        callback(kotlin.Result.success(null))
                    }
                } else {
                    Log.e("MyPigeonApi", "Sign in failed", task.exception)
                    callback(kotlin.Result.failure(task.exception ?: Exception("Unknown native sign-in error")))
                }
            }
    }
    // ... autres méthodes Pigeon si nécessaire
}
// --- FIN DE LA CLASSE D'IMPLÉMENTATION PIGEON ---


class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        FirebaseApp.initializeApp(/*context=*/ this)

        val firebaseAppCheck = FirebaseAppCheck.getInstance()
        if (BuildConfig.DEBUG) { // S'exécute uniquement en mode DEBUG
            Log.d("AppCheckDebug", "Installing DebugAppCheckProviderFactory")
            firebaseAppCheck.installAppCheckProviderFactory(
                DebugAppCheckProviderFactory.getInstance()
            )

            Log.d("AppCheckDebug", "Attempting to get debug token...")
            firebaseAppCheck.getAppCheckToken(false)
                 .addOnSuccessListener { tokenResponse ->
                     // *** Log Android standard (visible avec adb logcat ou Logcat d'Android Studio) ***
                     Log.d("AppCheckDebug", "Debug Token (Log.d): ${tokenResponse.token}")

                     // +++ AJOUT POUR VISIBILITÉ DANS LA CONSOLE flutter run +++
                     // Essayons d'imprimer sur la sortie standard, cela pourrait apparaître dans le terminal VS Code
                     // où 'flutter run' est exécuté.
                     System.out.println("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
                     System.out.println("!!! AppCheck Debug Token (System.out): ${tokenResponse.token}")
                     System.out.println("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
                     // +++ FIN DE L'AJOUT +++

                 }
                 .addOnFailureListener { exception ->
                     // C'est normal de voir cette erreur la première fois
                     Log.e("AppCheckDebug", "Failed to get debug token (This is expected until the token is registered in Firebase Console)", exception)
                     System.err.println("!!! AppCheck Failed to get debug token (System.err): ${exception.message}") // Aussi sur la sortie d'erreur
                 }

        } else {
            Log.d("AppCheckRelease", "Using default AppCheckProviderFactory (likely Play Integrity)")
            // ... (code release)
        }

        // Enregistrement de Pigeon
        try {
            HostApi.setUp(flutterEngine.dartExecutor.binaryMessenger, MyPigeonApiImplementation())
            Log.i("MainActivity", "Pigeon HostApi setup successful.")
        } catch (e: Exception) {
            Log.e("MainActivity", "Error setting up Pigeon HostApi", e)
        }

        // GeneratedPluginRegistrant.registerWith(flutterEngine) // Décommentez si nécessaire
    }
}
