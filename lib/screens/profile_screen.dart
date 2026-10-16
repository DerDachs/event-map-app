import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/profile.dart';
import '../features/auth/services/session.dart';
import '../providers/user_provider.dart';
import '../utils/avatars.dart';
import '../widgets/profile_menu.dart';
import 'package:market_mates/l10n/l10n.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.profileSaved)));
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
        title: Text(context.l10n.deleteAccountTitle),
        content: Text(
          context.l10n.deleteAccountText,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.deleteForever),
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
          .showSnackBar(SnackBar(content: Text(context.l10n.accountDeleted)));
      await signOutAndReturnToStart(context, ref);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'requires-recent-login') {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.l10n.reauthTitle),
            content: Text(
              context.l10n.reauthText,
            ),
            actions: [
              FilledButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.ok)),
            ],
          ),
        );
        if (mounted) await signOutAndReturnToStart(context, ref);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.deleteFailed('${e.message}'))));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.deleteFailed('$e'))));
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
      appBar: AppBar(title: Text(context.l10n.profileTitle)),
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
                    tooltip: context.l10n.changeAvatar,
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
            decoration: InputDecoration(labelText: context.l10n.nameLabel, border: const OutlineInputBorder()),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _save(profile),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: TextEditingController(text: profile.email),
            enabled: false,
            decoration: InputDecoration(labelText: context.l10n.emailLabel, border: const OutlineInputBorder()),
          ),
          if (profile.role == 'admin') ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                avatar: const Icon(Icons.admin_panel_settings, size: 18),
                label: Text(context.l10n.menuAdmin),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: changed && !_saving ? () => _save(profile) : null,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(context.l10n.save),
          ),
          const SizedBox(height: 40),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: Text(context.l10n.signOut),
            onPressed: () => signOutAndReturnToStart(context, ref),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            icon: const Icon(Icons.delete_forever_outlined),
            label: Text(context.l10n.deleteAccount),
            onPressed: () => _deleteAccount(profile),
          ),
        ],
      ),
    );
  }
}
