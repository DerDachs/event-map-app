import 'package:firebase_auth/firebase_auth.dart';

/// Readable German message for a failed sign-in, registration or reset.
String authErrorMessage(Object error) {
  if (error is! FirebaseAuthException) return 'Etwas ist schiefgelaufen. Bitte versuche es erneut.';
  return switch (error.code) {
    'invalid-email' => 'Diese E-Mail-Adresse ist ungültig.',
    'user-disabled' => 'Dieses Konto wurde deaktiviert.',
    'user-not-found' || 'wrong-password' || 'invalid-credential' =>
      'E-Mail oder Passwort ist falsch.',
    'email-already-in-use' => 'Für diese E-Mail gibt es schon ein Konto. Melde dich an.',
    'weak-password' => 'Das Passwort ist zu schwach – bitte mindestens 6 Zeichen.',
    'too-many-requests' => 'Zu viele Versuche. Bitte warte kurz.',
    'network-request-failed' => 'Keine Internetverbindung.',
    'account-exists-with-different-credential' =>
      'Für diese E-Mail gibt es schon ein Konto mit Passwort. Melde dich damit an.',
    _ => error.message ?? 'Anmeldung fehlgeschlagen.',
  };
}
