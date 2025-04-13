import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fake_async/fake_async.dart';
import 'dart:async';

// Adapte les chemins si nécessaire
import 'package:flutter_application_test/auth/auth_service.dart';
import 'package:flutter_application_test/models/pigeon_user_details.dart'; // Importe ton modèle

// Importe le fichier généré par mockito
import 'auth_service_test.mocks.dart';

// Annotation pour générer les mocks nécessaires
// --- AJOUT DE PigeonUserDetails SI TU VEUX LE MOCKER, MAIS PAS NÉCESSAIRE ICI ---
// On va plutôt vérifier les propriétés de l'objet retourné.
@GenerateMocks([FirebaseAuth, UserCredential, User])
void main() {
  // Déclaration des variables
  late MockFirebaseAuth mockFirebaseAuth;
  late AuthService authService;
  late MockUser mockUser;
  late MockUserCredential mockUserCredential;
  const String mockUserId = 'mock_user_123'; // Définit un ID de mock constant

  // setUp exécuté avant chaque test
  setUp(() {
    // Crée de nouvelles instances de mocks
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockUserCredential = MockUserCredential();

    // Configure les mocks
    // 1. Quand on demande l'utilisateur du UserCredential mocké, retourne l'utilisateur mocké
    when(mockUserCredential.user).thenReturn(mockUser);
    // 2. Quand on demande l'UID de l'utilisateur mocké, retourne notre ID constant
    when(mockUser.uid).thenReturn(mockUserId);

    // Crée l'instance du service avec le mock FirebaseAuth
    authService = AuthService.test(mockFirebaseAuth);
  });

  group('AuthService Unit Tests -', () {

    group('signInWithEmailAndPassword -', () {
      const testEmail = 'test@example.com';
      const testPassword = 'password123';

      test('should call FirebaseAuth.signInWithEmailAndPassword with correct arguments', () async {
        // Arrange
        when(mockFirebaseAuth.signInWithEmailAndPassword(email: testEmail, password: testPassword))
            .thenAnswer((_) async => mockUserCredential);

        // Act
        await authService.signInWithEmailAndPassword(testEmail, testPassword);

        // Assert
        verify(mockFirebaseAuth.signInWithEmailAndPassword(email: testEmail, password: testPassword)).called(1);
      });

      // --- MODIFICATION DE L'ASSERTION ---
      test('should return PigeonUserDetails with correct uid on successful sign in', () async {
        // Arrange
        when(mockFirebaseAuth.signInWithEmailAndPassword(email: testEmail, password: testPassword))
            .thenAnswer((_) async => mockUserCredential);

        // Act
        final result = await authService.signInWithEmailAndPassword(testEmail, testPassword);

        // Assert: Vérifie que le résultat est bien un PigeonUserDetails et que son uid est correct
        expect(result, isA<PigeonUserDetails>()); // Vérifie le type
        expect(result?.uid, equals(mockUserId)); // Vérifie l'UID (basé sur le mockUser configuré dans setUp)
      });

      test('should return null if UserCredential.user is null after sign in', () async {
        // Arrange: Simule un cas où Firebase retourne un UserCredential mais sans user (peu probable mais testons)
        final mockCredentialWithoutUser = MockUserCredential();
        when(mockCredentialWithoutUser.user).thenReturn(null); // Pas d'utilisateur dans le credential
        when(mockFirebaseAuth.signInWithEmailAndPassword(email: testEmail, password: testPassword))
            .thenAnswer((_) async => mockCredentialWithoutUser);

        // Act
        final result = await authService.signInWithEmailAndPassword(testEmail, testPassword);

        // Assert: Vérifie que le résultat est null comme le prévoit ta logique
        expect(result, isNull);
      });


      test('should rethrow FirebaseAuthException on user-not-found error', () async {
        // Arrange
        final exception = FirebaseAuthException(code: 'user-not-found');
        when(mockFirebaseAuth.signInWithEmailAndPassword(email: testEmail, password: testPassword))
            .thenThrow(exception);

        // Act & Assert
        expect(
          () => authService.signInWithEmailAndPassword(testEmail, testPassword),
          throwsA(predicate((e) => e is FirebaseAuthException && e.code == 'user-not-found'))
        );
        verify(mockFirebaseAuth.signInWithEmailAndPassword(email: testEmail, password: testPassword)).called(1);
      });

      test('should rethrow FirebaseAuthException on wrong-password error', () async {
        // Arrange
        final exception = FirebaseAuthException(code: 'wrong-password');
        when(mockFirebaseAuth.signInWithEmailAndPassword(email: testEmail, password: testPassword))
            .thenThrow(exception);

        // Act & Assert
        expect(
          () => authService.signInWithEmailAndPassword(testEmail, testPassword),
          throwsA(predicate((e) => e is FirebaseAuthException && e.code == 'wrong-password'))
        );
        verify(mockFirebaseAuth.signInWithEmailAndPassword(email: testEmail, password: testPassword)).called(1);
      });

       test('should rethrow FirebaseAuthException on invalid-email error', () async {
        // Arrange
        final exception = FirebaseAuthException(code: 'invalid-email');
        when(mockFirebaseAuth.signInWithEmailAndPassword(email: "invalid", password: testPassword))
            .thenThrow(exception);

        // Act & Assert
        expect(
          () => authService.signInWithEmailAndPassword("invalid", testPassword),
          throwsA(predicate((e) => e is FirebaseAuthException && e.code == 'invalid-email'))
        );
        verify(mockFirebaseAuth.signInWithEmailAndPassword(email: "invalid", password: testPassword)).called(1);
      });

      test('should rethrow generic Exception for other errors', () async {
        // Arrange
        final exception = Exception('Network error');
        when(mockFirebaseAuth.signInWithEmailAndPassword(email: testEmail, password: testPassword))
            .thenThrow(exception);

        // Act & Assert
        expect(
          () => authService.signInWithEmailAndPassword(testEmail, testPassword),
          throwsA(isA<Exception>())
        );
         verify(mockFirebaseAuth.signInWithEmailAndPassword(email: testEmail, password: testPassword)).called(1);
      });
    });


    group('signUpWithEmailAndPassword -', () {
       const testEmail = 'newuser@example.com';
       const testPassword = 'newpassword123';

       test('should call FirebaseAuth.createUserWithEmailAndPassword with correct arguments', () async {
         // Arrange
         when(mockFirebaseAuth.createUserWithEmailAndPassword(email: testEmail, password: testPassword))
             .thenAnswer((_) async => mockUserCredential);

         // Act
         await authService.signUpWithEmailAndPassword(testEmail, testPassword);

         // Assert
         verify(mockFirebaseAuth.createUserWithEmailAndPassword(email: testEmail, password: testPassword)).called(1);
       });

       // --- MODIFICATION DE L'ASSERTION ---
       test('should return PigeonUserDetails with correct uid on successful sign up', () async {
         // Arrange
         when(mockFirebaseAuth.createUserWithEmailAndPassword(email: testEmail, password: testPassword))
             .thenAnswer((_) async => mockUserCredential);

         // Act
         final result = await authService.signUpWithEmailAndPassword(testEmail, testPassword);

         // Assert: Vérifie que le résultat est bien un PigeonUserDetails et que son uid est correct
         expect(result, isA<PigeonUserDetails>()); // Vérifie le type
         expect(result?.uid, equals(mockUserId)); // Vérifie l'UID
       });

       test('should return null if UserCredential.user is null after sign up', () async {
        // Arrange: Simule un cas où Firebase retourne un UserCredential mais sans user
        final mockCredentialWithoutUser = MockUserCredential();
        when(mockCredentialWithoutUser.user).thenReturn(null);
        when(mockFirebaseAuth.createUserWithEmailAndPassword(email: testEmail, password: testPassword))
            .thenAnswer((_) async => mockCredentialWithoutUser);

        // Act
        final result = await authService.signUpWithEmailAndPassword(testEmail, testPassword);

        // Assert: Vérifie que le résultat est null
        expect(result, isNull);
      });

       test('should rethrow FirebaseAuthException on email-already-in-use error', () async {
         // Arrange
         final exception = FirebaseAuthException(code: 'email-already-in-use');
         when(mockFirebaseAuth.createUserWithEmailAndPassword(email: testEmail, password: testPassword))
             .thenThrow(exception);

         // Act & Assert
         expect(
           () => authService.signUpWithEmailAndPassword(testEmail, testPassword),
           throwsA(predicate((e) => e is FirebaseAuthException && e.code == 'email-already-in-use'))
         );
         verify(mockFirebaseAuth.createUserWithEmailAndPassword(email: testEmail, password: testPassword)).called(1);
       });

       test('should rethrow FirebaseAuthException on weak-password error', () async {
         // Arrange
         final exception = FirebaseAuthException(code: 'weak-password');
         when(mockFirebaseAuth.createUserWithEmailAndPassword(email: testEmail, password: testPassword))
             .thenThrow(exception);

         // Act & Assert
         expect(
           () => authService.signUpWithEmailAndPassword(testEmail, testPassword),
           throwsA(predicate((e) => e is FirebaseAuthException && e.code == 'weak-password'))
         );
         verify(mockFirebaseAuth.createUserWithEmailAndPassword(email: testEmail, password: testPassword)).called(1);
       });
    });


    group('signOut -', () {
      test('should call FirebaseAuth.signOut', () async {
        // Arrange
        when(mockFirebaseAuth.signOut()).thenAnswer((_) async {});

        // Act
        await authService.signOut();

        // Assert
        verify(mockFirebaseAuth.signOut()).called(1);
      });

      test('should complete normally even if FirebaseAuth.signOut throws an error', () async {
        // Arrange
        final exception = FirebaseAuthException(code: 'network-request-failed');
        when(mockFirebaseAuth.signOut()).thenThrow(exception);

        // Act & Assert
        // Ton AuthService attrape l'exception et fait un debugPrint, donc il ne la relance pas.
        // Le test vérifie que le Future se termine sans erreur.
        await expectLater(authService.signOut(), completes);

        verify(mockFirebaseAuth.signOut()).called(1);
      });

       test('should complete normally if called when already signed out', () async {
        // Arrange
        when(mockFirebaseAuth.signOut()).thenAnswer((_) async {});

        // Act
        await authService.signOut();

        // Assert
        verify(mockFirebaseAuth.signOut()).called(1);
        await expectLater(authService.signOut(), completes);
      });
    });


    group('authStateChanges -', () {
      test('should return the stream from FirebaseAuth.authStateChanges', () {
        // Arrange
        final controller = StreamController<User?>();
        when(mockFirebaseAuth.authStateChanges()).thenAnswer((_) => controller.stream);

        // Act
        final stream = authService.authStateChanges;

        // Assert
        verify(mockFirebaseAuth.authStateChanges()).called(1);
        expect(stream, equals(controller.stream));

        controller.close();
      });

      test('should emit user when Firebase auth state changes to logged in', () {
        fakeAsync((async) {
          // Arrange
          final controller = StreamController<User?>();
          when(mockFirebaseAuth.authStateChanges()).thenAnswer((_) => controller.stream);
          final stream = authService.authStateChanges;
          User? receivedUser;
          stream.listen((user) {
            receivedUser = user;
          });

          // Act
          controller.add(mockUser); // Émet le mockUser
          async.flushMicrotasks();

          // Assert
          expect(receivedUser, equals(mockUser));

          controller.close();
        });
      });

      test('should emit null when Firebase auth state changes to logged out', () {
        fakeAsync((async) {
          // Arrange
          final controller = StreamController<User?>();
          when(mockFirebaseAuth.authStateChanges()).thenAnswer((_) => controller.stream);
          final stream = authService.authStateChanges;
          User? receivedUser = mockUser; // État initial simulé
          stream.listen((user) {
            receivedUser = user;
          });

          // Act
          controller.add(null); // Émet null
          async.flushMicrotasks();

          // Assert
          expect(receivedUser, isNull);

          controller.close();
        });
      });

       test('should emit sequence of user, null, user correctly', () {
        fakeAsync((async) {
          // Arrange
          final controller = StreamController<User?>();
          when(mockFirebaseAuth.authStateChanges()).thenAnswer((_) => controller.stream);
          final stream = authService.authStateChanges;
          final receivedEvents = <User?>[];
          stream.listen((user) {
            receivedEvents.add(user);
          });
          final anotherMockUser = MockUser(); // Un autre mock user pour la séquence

          // Act
          controller.add(mockUser);
          async.flushMicrotasks();
          controller.add(null);
          async.flushMicrotasks();
          controller.add(anotherMockUser);
          async.flushMicrotasks();

          // Assert
          expect(receivedEvents, orderedEquals([mockUser, null, anotherMockUser]));

          controller.close();
        });
      });
    });


    group('getCurrentUser -', () {
      test('should return the current user from FirebaseAuth when logged in', () {
        // Arrange
        when(mockFirebaseAuth.currentUser).thenReturn(mockUser);

        // Act
        // Note: on appelle getCurrentUser() comme défini dans AuthService,
        // qui retourne lui-même le getter currentUser de FirebaseAuth via le mock.
        final user = authService.getCurrentUser();

        // Assert
        // Vérifie que la propriété currentUser du mock a été accédée (via le getter dans AuthService)
        verify(mockFirebaseAuth.currentUser).called(1);
        expect(user, equals(mockUser));
      });

      test('should return null when no user is logged in', () {
        // Arrange
        when(mockFirebaseAuth.currentUser).thenReturn(null);

        // Act
        final user = authService.getCurrentUser();

        // Assert
        verify(mockFirebaseAuth.currentUser).called(1);
        expect(user, isNull);
      });
    });

    // --- AJOUT : Test pour signInAnonymously ---
    group('signInAnonymously -', () {
      test('should call FirebaseAuth.signInAnonymously', () async {
        // Arrange
        when(mockFirebaseAuth.signInAnonymously()).thenAnswer((_) async => mockUserCredential);

        // Act
        await authService.signInAnonymously();

        // Assert
        verify(mockFirebaseAuth.signInAnonymously()).called(1);
      });

      test('should return PigeonUserDetails with correct uid on successful anonymous sign in', () async {
        // Arrange
        when(mockFirebaseAuth.signInAnonymously()).thenAnswer((_) async => mockUserCredential);

        // Act
        final result = await authService.signInAnonymously();

        // Assert
        expect(result, isA<PigeonUserDetails>());
        expect(result?.uid, equals(mockUserId));
      });

       test('should return null if anonymous sign in fails', () async {
        // Arrange: Simule une exception lors de l'appel à Firebase
        final exception = FirebaseAuthException(code: 'operation-not-allowed');
        when(mockFirebaseAuth.signInAnonymously()).thenThrow(exception);

        // Act
        final result = await authService.signInAnonymously();

        // Assert: Vérifie que null est retourné car ton AuthService attrape l'exception
        expect(result, isNull);
        verify(mockFirebaseAuth.signInAnonymously()).called(1);
      });

       test('should return null if UserCredential.user is null after anonymous sign in', () async {
        // Arrange
        final mockCredentialWithoutUser = MockUserCredential();
        when(mockCredentialWithoutUser.user).thenReturn(null);
        when(mockFirebaseAuth.signInAnonymously()).thenAnswer((_) async => mockCredentialWithoutUser);

        // Act
        final result = await authService.signInAnonymously();

        // Assert
        expect(result, isNull);
      });
    });


  }); // Fin du groupe principal
}
