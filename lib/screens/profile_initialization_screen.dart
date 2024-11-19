import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_provider.dart';
import '../data/models/profile.dart';

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

  // List of generic avatars
  final List<String> avatars = [
    'assets/avatars/avatar_1.jpg',
    'assets/avatars/avatar_2.jpg',
    'assets/avatars/avatar_3.jpg',
    'assets/avatars/avatar_4.jpg',
    'assets/avatars/avatar_5.jpg',
    'assets/avatars/avatar_6.jpg',
    'assets/avatars/avatar_7.jpg',
    'assets/avatars/avatar_8.jpg',
    'assets/avatars/avatar_9.jpg',
    'assets/avatars/avatar_10.jpg',
    'assets/avatars/avatar_11.jpg',
    'assets/avatars/avatar_12.jpg',
    'assets/avatars/avatar_13.jpg',
    'assets/avatars/avatar_14.jpg',
    'assets/avatars/avatar_15.jpg',
    'assets/avatars/avatar_16.jpg',
    'assets/avatars/avatar_17.jpg',
    'assets/avatars/avatar_18.jpg',
    'assets/avatars/avatar_19.jpg',
    'assets/avatars/avatar_20.jpg',
    // Add paths to more avatar images here
  ];

  @override
  Widget build(BuildContext context) {
    final userProfileNotifier = ref.read(userProfileProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Your Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome! Let’s complete your profile.',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: ageController,
              decoration: InputDecoration(labelText: 'Age'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            Text(
              'Choose an Avatar',
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
                    SnackBar(content: Text('Please fill out all fields and select an avatar')),
                  );
                  return;
                }

                try {
                  // Create a UserProfile object with the provided details
                  final profile = UserProfile(
                    uid: widget.uid,
                    email: widget.email,
                    name: nameController.text,
                    age: int.tryParse(ageController.text),
                    profilePicture: selectedAvatar,
                  );

                  // Save the profile to Firestore
                  await userProfileNotifier.saveUserProfile(profile);

                  // Navigate to HomeScreen
                  Navigator.pushReplacementNamed(context, '/home');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}