import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/auth/services/session.dart';
import '../utils/app_links.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with WidgetsBindingObserver {
  PermissionStatus? _location;
  String _version = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermission();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = '${info.version} (${info.buildNumber})');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Coming back from the iOS settings app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPermission();
  }

  Future<void> _refreshPermission() async {
    final status = await Permission.locationWhenInUse.status;
    if (mounted) setState(() => _location = status);
  }

  Future<void> _changeLocation() async {
    if (_location == PermissionStatus.denied) {
      final status = await Permission.locationWhenInUse.request();
      if (mounted) setState(() => _location = status);
    } else {
      await openAppSettings();
    }
  }

  Future<void> _open(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Seite konnte nicht geöffnet werden.')));
    }
  }

  String get _locationText => switch (_location) {
        PermissionStatus.granted || PermissionStatus.limited => 'Erlaubt, während die App genutzt wird',
        PermissionStatus.denied => 'Noch nicht erlaubt',
        PermissionStatus.permanentlyDenied || PermissionStatus.restricted =>
          'Nicht erlaubt – in den iOS-Einstellungen änderbar',
        _ => '…',
      };

  @override
  Widget build(BuildContext context) {
    final header = Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Datenschutz', style: header),
          ),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Standort'),
            subtitle: Text(
              '$_locationText\nZeigt deine Position auf der Marktkarte. '
              'Der Standort wird nicht gespeichert.',
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: _changeLocation,
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Datenschutzerklärung'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _open(privacyPolicyUrl),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Impressum'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _open(imprintUrl),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Konto', style: header),
          ),
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: const Text('Profil bearbeiten'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Abmelden', style: TextStyle(color: Colors.red)),
            onTap: () => signOutAndReturnToStart(context, ref),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: const Text('Market Mate'),
            subtitle: Text(_version.isEmpty ? '' : 'Version $_version'),
          ),
        ],
      ),
    );
  }
}
