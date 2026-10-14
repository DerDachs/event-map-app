import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/user_provider.dart';

class AdminPanelScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);

    if (userProfile.value?.role != 'admin') {
      return Scaffold(
        appBar: AppBar(title: Text('Kein Zugriff')),
        body: Center(child: Text('Diese Seite ist nur für Admins.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Admin')),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.auto_awesome),
            title: Text('Markt aus Lageplan erstellen'),
            subtitle: Text('Plan hochladen – die KI legt Stände und Karte an'),
            onTap: () {
              Navigator.pushNamed(context, '/market-builder');
            },
          ),
          ListTile(
            leading: Icon(Icons.dynamic_feed_outlined),
            title: Text('Startseite: Beiträge'),
            subtitle: Text('Neuigkeiten und Tipps für den Feed schreiben'),
            onTap: () {
              Navigator.pushNamed(context, '/admin/feed');
            },
          ),
          ListTile(
            leading: Icon(Icons.edit_location_alt_outlined),
            title: Text('Märkte bearbeiten'),
            subtitle: Text('Infos, Bilder und Stände bestehender Märkte ändern'),
            onTap: () {
              Navigator.pushNamed(context, '/admin/markets');
            },
          ),
          ListTile(
            leading: Icon(Icons.edit_calendar_outlined),
            title: Text('Event manuell anlegen'),
            subtitle: Text('Ohne Lageplan, Koordinaten selbst eintragen'),
            onTap: () {
              Navigator.pushNamed(context, '/create-event');
            },
          ),
        ],
      ),
    );
  }
}