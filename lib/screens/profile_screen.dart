import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/profile.dart';
import '../features/auth/services/session.dart';
import '../providers/user_provider.dart';
import '../utils/avatars.dart';
import '../widgets/profile_menu.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  String? _avatar;
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save(UserProfile profile) async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);
    await ref.read(userProfileProvider.notifier).saveUserProfile(UserProfile(
          uid: profile.uid,
          email: profile.email,
          name: name,
          age: profile.age,
          profilePicture: _avatar ?? profile.profilePicture,
          preferences: profile.preferences,
          favorites: profile.favorites,
          role: profile.role,
        ));
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil gespeichert.')));
  }

  Future<void> _pickAvatar() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 4,
          padding: const EdgeInsets.all(16),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            for (final a in avatarAssets)
              InkWell(
                borderRadius: BorderRadius.circular(40),
                onTap: () => Navigator.pop(context, a),
                child: CircleAvatar(backgroundImage: AssetImage(a)),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _avatar = picked);
  }

  Future<void> _deleteAccount(UserProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konto löschen?'),
        content: const Text(
          'Dein Profil, deine Favoriten und deine Teammitgliedschaften werden gelöscht. '
          'Das lässt sich nicht rückgängig machen.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Endgültig löschen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final firestore = FirebaseFirestore.instance;
    try {
      final teams = await firestore
          .collection('teams')
          .where('memberIds', arrayContains: profile.uid)
          .get();
      for (final team in teams.docs) {
        await team.reference.update({
          'memberIds': FieldValue.arrayRemove([profile.uid]),
        });
      }
      await firestore.collection('profiles').doc(profile.uid).delete();
      await FirebaseAuth.instance.currentUser?.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Dein Konto wurde gelöscht.')));
      await signOutAndReturnToStart(context, ref);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'requires-recent-login') {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Bitte erneut anmelden'),
            content: const Text(
              'Aus Sicherheitsgründen musst du dich kurz neu anmelden. '
              'Lösche das Konto danach bitte noch einmal.',
            ),
            actions: [
              FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          ),
        );
        if (mounted) await signOutAndReturnToStart(context, ref);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Löschen fehlgeschlagen: ${e.message}')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Löschen fehlgeschlagen: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_initialized) {
      _name.text = profile.name ?? '';
      _initialized = true;
    }
    final shownAvatar = UserProfile(
      uid: profile.uid,
      email: profile.email,
      role: profile.role,
      profilePicture: _avatar ?? profile.profilePicture,
    );
    final changed = _name.text.trim() != (profile.name ?? '') ||
        (_avatar != null && _avatar != profile.profilePicture);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Stack(
              children: [
                UserAvatar(profile: shownAvatar, radius: 56),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: IconButton.filled(
                    tooltip: 'Avatar ändern',
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: _pickAvatar,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _name,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _save(profile),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: TextEditingController(text: profile.email),
            enabled: false,
            decoration: const InputDecoration(labelText: 'E-Mail', border: OutlineInputBorder()),
          ),
          if (profile.role == 'admin') ...[
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                avatar: Icon(Icons.admin_panel_settings, size: 18),
                label: Text('Admin'),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: changed && !_saving ? () => _save(profile) : null,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Speichern'),
          ),
          const SizedBox(height: 40),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Abmelden'),
            onPressed: () => signOutAndReturnToStart(context, ref),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Konto löschen'),
            onPressed: () => _deleteAccount(profile),
          ),
        ],
      ),
    );
  }
}
