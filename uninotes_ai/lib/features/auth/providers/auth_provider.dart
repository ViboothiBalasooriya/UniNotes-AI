import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/firebase_service.dart';
import '../../../shared/models/user_role.dart';

// ─── Auth Stream Provider ─────────────────────────────────────────────────────
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// ─── Current User Role Provider ───────────────────────────────────────────────
final userRoleProvider = FutureProvider.family<UserRole?, String>((ref, uid) async {
  final firebaseService = ref.read(firebaseServiceProvider);
  return await firebaseService.getUserRole(uid);
});

// ─── Auth Notifier ────────────────────────────────────────────────────────────
final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, User?>(() => AuthNotifier());

class AuthNotifier extends AsyncNotifier<User?> {
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();

  @override
  Future<User?> build() async {
    return _auth.currentUser;
  }

  // ─── Email & Password Login ───────────────────────────────────────────────────
  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    });
  }

  // ─── Email & Password Registration ────────────────────────────────────────────
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Update display name
      await credential.user?.updateDisplayName(displayName);
      await credential.user?.reload();

      // Create default 'student' role in Firestore
      if (credential.user != null) {
        await ref.read(firebaseServiceProvider).setUserRole(
          credential.user!.uid,
          AppConstants.roleStudent,
        );
      }
      return credential.user;
    });
  }

  // ─── Google Sign-In ───────────────────────────────────────────────────────────
  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google sign-in cancelled');

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      // If new user, create default role
      if (userCredential.additionalUserInfo?.isNewUser == true && user != null) {
        await ref.read(firebaseServiceProvider).setUserRole(
          user.uid,
          AppConstants.roleStudent,
        );
      }
      return user;
    });
  }

  // ─── Anonymous / Guest Login ──────────────────────────────────────────────────
  Future<User?> signInAnonymously({bool isAdmin = false}) async {
    state = const AsyncLoading();
    User? user;
    try {
      final credential = await _auth.signInAnonymously();
      user = credential.user;
      if (user != null) {
        await ref.read(firebaseServiceProvider).setUserRole(
          user.uid,
          isAdmin ? AppConstants.roleAdmin : AppConstants.roleStudent,
        );
      }
    } catch (e) {
      debugPrint('Anonymous auth fallback: $e');
    }
    state = AsyncData(user);
    return user;
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    state = const AsyncData(null);
  }

  // ─── Password Reset ───────────────────────────────────────────────────────────
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
