import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../providers/user_provider.dart';
import '../services/authentication_service.dart';

// Provider for FirebaseAuth instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Provider for monitoring the user's authentication state
final authStateProvider = StreamProvider<User?>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return firebaseAuth.authStateChanges();
});

// Provider for Authentication Logic (Sign In, Sign Out, etc.)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(firebaseAuthProvider));
});

class AuthRepository {
  final FirebaseAuth _auth;
  AuthRepository(this._auth);

  Future<User> signInWithEmail(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user!; // Return the authenticated User
  }

  Future<User> registerWithEmail(String email, String password) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user!; // Return the created User
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  void handleAppleSignIn(BuildContext context, WidgetRef ref) async {
    final user = await signInWithApple();

    if (user != null) {
      final userProfileNotifier = ref.read(userProfileProvider.notifier);

      // Check if the user profile exists
      final profileExists = await userProfileNotifier.doesUserProfileExist(user.uid);

      if (!profileExists) {
        // Redirect to profile initialization if necessary
        Navigator.pushNamed(context, '/', arguments: user);
      } else {
        // Load the profile and navigate to home
        await userProfileNotifier.loadUserProfile(user.uid);
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apple Sign-In failed. Please try again.')),
      );
    }
  }

}