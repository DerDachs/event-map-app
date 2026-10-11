import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/authentication_provider.dart';
import '../services/auth_errors.dart';

class ForgotPasswordScreen extends ConsumerWidget {
  final emailController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepository = ref.watch(authRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Passwort vergessen')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gib deine E-Mail ein – wir schicken dir einen Link zum Zurücksetzen.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'E-Mail',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                try {
                  await authRepository.sendPasswordResetEmail(emailController.text.trim());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('E-Mail zum Zurücksetzen wurde gesendet.')),
                  );
                  Navigator.pop(context); // Return to the login screen
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(authErrorMessage(e))),
                  );
                }
              },
              child: Text('Link senden'),
            ),
          ],
        ),
      ),
    );
  }
}