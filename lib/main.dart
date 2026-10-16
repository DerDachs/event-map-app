import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'data/models/event.dart';
import 'features/admin/screens/admin_panel_screen.dart';
import 'l10n/l10n.dart';
import 'l10n/locale_provider.dart';
import 'features/admin/screens/event_creation_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/events/screens/event_detail_screen.dart';
import 'features/events/screens/event_page.dart';
import 'features/feed/screens/feed_admin_screen.dart';
import 'features/market_builder/screens/market_builder_screen.dart';
import 'features/seasons/screens/season_admin_screen.dart';
import 'features/market_editor/screens/market_list_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';
import 'utils/authentication_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // Null follows the device: German there, otherwise English.
      locale: ref.watch(appLanguageProvider).locale,
      localeResolutionCallback: (device, _) => resolveAppLocale(device),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) {
        // Date formatting outside of widgets follows the app language too.
        Intl.defaultLocale = Localizations.localeOf(context).languageCode;
        return child!;
      },
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
        '/admin/seasons': (context) => const SeasonAdminScreen(),
        '/event-joined': (context) => EventPage(
              event: ModalRoute.of(context)!.settings.arguments as Event,
            ),
      },
    );
  }
}
