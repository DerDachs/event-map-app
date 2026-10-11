import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/profile.dart';
import '../features/auth/services/session.dart';
import '../providers/user_provider.dart';

/// Avatar button for app bars that opens the account menu.
class ProfileMenuButton extends ConsumerWidget {
  const ProfileMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkResponse(
        radius: 24,
        onTap: () => _showMenu(context, ref, profile),
        child: UserAvatar(profile: profile, radius: 20),
      ),
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref, UserProfile? profile) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: UserAvatar(profile: profile, radius: 24),
              title: Text(profile?.name ?? 'Unbekannt',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(profile?.email ?? ''),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: const Text('Profil'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Einstellungen'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            if (profile?.role == 'admin')
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Admin'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.pushNamed(context, '/admin-panel');
                },
              ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Abmelden', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(sheetContext);
                signOutAndReturnToStart(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  final UserProfile? profile;
  final double radius;

  const UserAvatar({super.key, required this.profile, required this.radius});

  @override
  Widget build(BuildContext context) {
    final picture = profile?.profilePicture;
    return CircleAvatar(
      radius: radius,
      backgroundImage: picture != null ? AssetImage(picture) : null,
      child: picture == null ? Icon(Icons.person, size: radius) : null,
    );
  }
}
