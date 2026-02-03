import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/profile.dart';
import '../../../providers/user_provider.dart';
import '../../../screens/profile_initialization_screen.dart';
import '../providers/authentication_provider.dart';


class RegisterScreen extends ConsumerWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepository = ref.watch(authRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Register the user
                  final user = await authRepository.registerWithEmail(
                    emailController.text,
                    passwordController.text,
                  );

                  // Create a blank profile in Firestore
                  await ref.read(userProfileProvider.notifier).saveUserProfile(
                    UserProfile(
                      uid: user.uid,
                      email: user.email!,
                      name: null, // Initially blank
                      age: null,
                      profilePicture: null,
                      preferences: null,
                      role: "user",
                    ),
                  );

                  // Navigate to Profile Initialization Screen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileInitializationScreen(
                        uid: user.uid,
                        email: user.email!,
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}