import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for managing the current tab index
final bottomNavIndexProvider = StateProvider<int>((ref) {
  return 0; // Default to the first tab
});

final loginLoadingProvider = StateProvider<bool>((ref) => false);