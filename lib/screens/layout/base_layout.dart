import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/user_provider.dart';
import '../../data/models/profile.dart';
import '../../providers/state_provider.dart';

class BaseLayout extends ConsumerWidget {
  final Widget body;
  final String title;

  const BaseLayout({
    Key? key,
    required this.body,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileState = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          userProfileState.when(
            data: (profile) {
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: GestureDetector(
                  onTap: () {
                    _showProfileMenu(context, profile, ref);
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: profile?.profilePicture != null
                        ? AssetImage(profile!.profilePicture!)
                        : null,
                    child: profile?.profilePicture == null
                        ? Icon(Icons.person, size: 24, color: Colors.white)
                        : null,
                  ),
                ),
              );
            },
            loading: () => Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                radius: 20,
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
            error: (error, _) => Icon(Icons.error, color: Colors.red),
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: ref.watch(bottomNavIndexProvider), // From Riverpod
        onTap: (index) {
          ref.read(bottomNavIndexProvider.notifier).state = index;
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.event), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Discover"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Social Hub"),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext context, UserProfile? profile, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: profile?.profilePicture != null
                        ? AssetImage(profile!.profilePicture!)
                        : null,
                    child: profile?.profilePicture == null
                        ? Icon(Icons.person, size: 30, color: Colors.white)
                        : null,
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.name ?? 'User',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        profile?.email ?? 'user@example.com',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.account_circle),
                title: Text('Profile'),
                onTap: () {
                  Navigator.pushNamed(context, '/profile');
                },
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
                onTap: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  try {
                    ref.read(userProfileProvider.notifier).resetUserProfile();
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Logged out successfully')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error logging out: $e')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}