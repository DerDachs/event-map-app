import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

Future<User?> signInWithApple() async {
  try {
    // Request Apple credentials
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    );

    // Create OAuth credential for Firebase
    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    // Sign in with Firebase
    final authResult = await FirebaseAuth.instance.signInWithCredential(oauthCredential);

    return authResult.user;
  } catch (e) {
    print('Error signing in with Apple: $e');
    return null;
  }
}