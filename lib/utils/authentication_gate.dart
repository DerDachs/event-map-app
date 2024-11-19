import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_provider.dart';
import '../features/auth/providers/authentication_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_initialization_screen.dart';

class AuthenticationGate extends ConsumerStatefulWidget {
  @override
  _AuthenticationGateState createState() => _AuthenticationGateState();
}

class _AuthenticationGateState extends ConsumerState<AuthenticationGate> {
  bool hasLoadedProfile = false; // Tracks if profile loading is complete

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUserProfile());
  }

  Future<void> _loadUserProfile() async {
    final authState = ref.read(authStateProvider);
    authState.whenData((user) {
      if (user != null) {
        ref.read(userProfileProvider.notifier).loadUserProfile(user.uid).then((_) {
          setState(() {
            hasLoadedProfile = true;
          });
        }).catchError((e) {
          setState(() {
            hasLoadedProfile = true; // Avoid infinite loading in case of errors
          });
        });
      } else {
        setState(() {
          hasLoadedProfile = true; // No user logged in
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final userProfileState = ref.watch(userProfileProvider);

    if (!hasLoadedProfile) {
      // Show loading indicator while profile is loading
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return authState.when(
      data: (user) {
        if (user != null) {
          return userProfileState.when(
            data: (profile) {
              if (profile == null || profile.name == null || profile.profilePicture == null) {
                return ProfileInitializationScreen(uid: user.uid, email: user.email!);
              } else {
                return HomeScreen();
              }
            },
            loading: () => Scaffold(body: Center(child: CircularProgressIndicator())),
            error: (error, stackTrace) =>
                Scaffold(body: Center(child: Text('Error loading profile: $error'))),
          );
        } else {
          return LoginScreen();
        }
      },
      loading: () => Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }
}