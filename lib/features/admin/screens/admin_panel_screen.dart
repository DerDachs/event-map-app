import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/user_provider.dart';
import '../../market_builder/demo/demo_market_service.dart';

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
            leading: Icon(Icons.wb_sunny_outlined),
            title: Text('Saisons'),
            subtitle: Text('Weihnachten, Pfingsten, Herbst … mit Banner und Countdown'),
            onTap: () {
              Navigator.pushNamed(context, '/admin/seasons');
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
          ListTile(
            leading: Icon(Icons.celebration_outlined),
            title: Text('Beispielmarkt anlegen'),
            subtitle: Text('Lichterdorf Musterstadt: erfundene Stände, keine fremden Daten'),
            onTap: () => _runDemo(context, () async {
              await DemoMarketService().createOrRefresh();
              return 'Beispielmarkt ist aktuell.';
            }),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline),
            title: Text('Beispielmarkt entfernen'),
            onTap: () => _runDemo(context, () async {
              await DemoMarketService().remove();
              return 'Beispielmarkt entfernt.';
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _runDemo(BuildContext context, Future<String> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(SnackBar(content: Text('Einen Moment …')));
      final message = await action();
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text('Das hat nicht geklappt: $e')));
    }
  }
}
