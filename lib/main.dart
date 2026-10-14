import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/models/event.dart';
import 'features/admin/screens/admin_panel_screen.dart';
import 'features/admin/screens/event_creation_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/events/screens/event_detail_screen.dart';
import 'features/events/screens/event_page.dart';
import 'features/feed/screens/feed_admin_screen.dart';
import 'features/market_builder/screens/market_builder_screen.dart';
import 'features/market_editor/screens/market_list_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/brand_tokens.dart';
import 'utils/authentication_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('de');
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Market Mate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: BrandColors.red),
        useMaterial3: true,
      ),
      locale: const Locale('de'),
      supportedLocales: const [Locale('de')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => AuthenticationGate(),
        '/home': (context) => const HomeScreen(),
        '/login': (context) => LoginScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/event-details': (context) => EventDetailsScreen(
              event: ModalRoute.of(context)!.settings.arguments as Event,
            ),
        '/admin-panel': (context) => AdminPanelScreen(),
        '/create-event': (context) => CreateEventScreen(),
        '/market-builder': (context) => const MarketBuilderScreen(),
        '/admin/markets': (context) => const MarketListScreen(),
        '/admin/feed': (context) => const FeedAdminScreen(),
        '/event-joined': (context) => EventPage(
              event: ModalRoute.of(context)!.settings.arguments as Event,
            ),
      },
    );
  }
}
