import 'package:market_mates/screens/home_screen.dart';
import 'package:market_mates/screens/profile_screen.dart';
import 'package:market_mates/screens/settings_screen.dart';
import 'package:market_mates/utils/authentication_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'data/models/event.dart';
import 'features/admin/screens/admin_panel_screen.dart';
import 'features/admin/screens/event_creation_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/events/screens/event_detail_screen.dart';
import 'features/events/screens/event_joined_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(ProviderScope(child: MyApp())); // Wrap the app with ProviderScope
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Market Mate',
      initialRoute: '/',
      routes: {
        '/': (context) => AuthenticationGate(), // Main routing logic
        '/home': (context) => HomeScreen(), // Templated screen
        '/login': (context) => LoginScreen(),
        '/profile': (context) => ProfileScreen(),
        '/settings': (context) => SettingsScreen(),
        '/event-details': (context) => EventDetailsScreen(
          event: ModalRoute.of(context)!.settings.arguments as Event,
        ),
        '/admin-panel': (context) => AdminPanelScreen(),
        '/create-event': (context) => CreateEventScreen(),
        '/event-joined': (context) => EventJoinedScreen(
          key: key,
          event: ModalRoute.of(context)!.settings.arguments as Event,
        ),
        //'/manage-stands': (context) => ManageStandsScreen(),
        //'/upload-images': (context) => UploadImagesScreen(),
      },
    );
  }
}