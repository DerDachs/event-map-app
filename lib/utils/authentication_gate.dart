import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_provider.dart';
import '../features/auth/providers/authentication_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/onboarding/onboarding.dart';
import '../screens/home_screen.dart';
import '../screens/profile_initialization_screen.dart';
import 'package:market_mates/l10n/l10n.dart';

class AuthenticationGate extends ConsumerStatefulWidget {
  @override
  _AuthenticationGateState createState() => _AuthenticationGateState();
}

class _AuthenticationGateState extends ConsumerState<AuthenticationGate> {
  bool hasLoadedProfile = false; // Tracks if profile loading is complete
  String? _loadingFor; // uid whose profile is loaded or loading

  @override
  void initState() {
    super.initState();
    // Auth may still be resolving here (e.g. while the intro cards show), so
    // the listener in build() takes over once a user arrives.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFor(ref.read(authStateProvider)));
  }

  /// Loads the profile once per signed-in user, whenever the auth state settles.
  void _loadFor(AsyncValue<User?> authState) {
    if (!mounted || !authState.hasValue) return;
    final user = authState.value;
    if (user == null) {
      _loadingFor = null;
      setState(() => hasLoadedProfile = true); // No user logged in
      return;
    }
    if (_loadingFor == user.uid) return;
    _loadingFor = user.uid;
    ref.read(userProfileProvider.notifier).loadUserProfile(user.uid).then((_) {
      if (mounted) setState(() => hasLoadedProfile = true);
    }).catchError((e) {
      _loadingFor = null;
      if (mounted) setState(() => hasLoadedProfile = false); // Avoid infinite loading in case of errors
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<User?>>(authStateProvider, (_, next) => _loadFor(next));

    // First start (and first start after the 1.1 update): three intro cards.
    final seen = ref.watch(onboardingSeenProvider);
    if (seen.isLoading) return const Scaffold(body: SizedBox());
    if (seen.valueOrNull == false) return const OnboardingScreen();

    final authState = ref.watch(authStateProvider);
    final userProfileState = ref.watch(userProfileProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return userProfileState.when(
            data: (profile) {
              if (hasLoadedProfile == false || profile == null || profile.name == null || profile.profilePicture == null) {
                return ProfileInitializationScreen(uid: user.uid, email: user.email!);
              } else {
                return HomeScreen();
              }
            },
            loading: () => Scaffold(body: Center(child: CircularProgressIndicator())),
            error: (error, stackTrace) =>
                Scaffold(body: Center(child: Text(context.l10n.profileLoadFailed('$error'), textAlign: TextAlign.center))),
          );
        } else {
          return LoginScreen();
        }
      },
      loading: () => Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(body: Center(child: Text(context.l10n.signInFailedWithError('$error'), textAlign: TextAlign.center))),
    );
  }
}