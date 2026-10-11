import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/user_provider.dart';

/// Signs out of Firebase and returns to the start screen, which then shows
/// the login.
Future<void> signOutAndReturnToStart(BuildContext context, WidgetRef ref) async {
  final navigator = Navigator.of(context);
  await FirebaseAuth.instance.signOut();
  ref.read(userProfileProvider.notifier).resetUserProfile();
  navigator.pushNamedAndRemoveUntil('/', (route) => false);
}
