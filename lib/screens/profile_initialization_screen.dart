import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_provider.dart';
import '../data/models/profile.dart';
import '../utils/avatars.dart';

class ProfileInitializationScreen extends ConsumerStatefulWidget {
  final String uid; // Pass the user's UID to link the profile
  final String email; // Display or pre-fill email

  ProfileInitializationScreen({required this.uid, required this.email});

  @override
  _ProfileInitializationScreenState createState() => _ProfileInitializationScreenState();
}

class _ProfileInitializationScreenState extends ConsumerState<ProfileInitializationScreen> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  String? selectedAvatar;

  List<String> get avatars => avatarAssets;

  @override
  Widget build(BuildContext context) {
    final userProfileNotifier = ref.read(userProfileProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Profil einrichten'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Willkommen! Wie sollen dich deine Freunde im Team sehen?',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            SizedBox(height: 20),
            Text(
              'Wähle einen Avatar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: avatars.length,
                itemBuilder: (context, index) {
                  final avatar = avatars[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedAvatar = avatar;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selectedAvatar == avatar
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.asset(avatar),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || selectedAvatar == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Bitte gib einen Namen ein und wähle einen Avatar.')),
                  );
                  return;
                }

                try {
                  // Create a UserProfile object with the provided details
                  final profile = UserProfile(
                    uid: widget.uid,
                    email: widget.email,
                    name: nameController.text.trim(),
                    age: int.tryParse(ageController.text),
                    profilePicture: selectedAvatar,
                    role: "user",
                  );

                  // Save the profile to Firestore
                  await userProfileNotifier.saveUserProfile(profile);

                  // Navigate to HomeScreen
                  Navigator.pushReplacementNamed(context, '/home');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Speichern fehlgeschlagen: $e')),
                  );
                }
              },
              child: Text('Los geht’s'),
            ),
          ],
        ),
      ),
    );
  }
}