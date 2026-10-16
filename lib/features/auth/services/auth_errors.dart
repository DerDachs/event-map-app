import 'package:firebase_auth/firebase_auth.dart';

import '../../../l10n/app_localizations.dart';

/// Readable message for a failed sign-in, registration or reset.
String authErrorMessage(Object error, AppLocalizations l) {
  if (error is! FirebaseAuthException) return l.authErrorGeneric;
  return switch (error.code) {
    'invalid-email' => l.authErrorInvalidEmail,
    'user-disabled' => l.authErrorUserDisabled,
    'user-not-found' || 'wrong-password' || 'invalid-credential' => l.authErrorWrongCredentials,
    'email-already-in-use' => l.authErrorEmailInUse,
    'weak-password' => l.authErrorWeakPassword,
    'too-many-requests' => l.authErrorTooManyRequests,
    'network-request-failed' => l.authErrorNetwork,
    'account-exists-with-different-credential' => l.authErrorOtherCredential,
    _ => error.message ?? l.authErrorFallback,
  };
}
