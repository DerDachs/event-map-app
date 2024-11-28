import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/favorite_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../providers/user_provider.dart';

final favoriteServiceProvider = Provider<FavoriteService>((ref) {
  return FavoriteService(FirebaseFirestore.instance);
});

// Favorites state for a user
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Map<String, List<String>>>((ref) {
  final userProfile = ref.watch(userProfileProvider);
  final favoriteService = ref.read(favoriteServiceProvider);
  return userProfile.when(
    data: (profile) {
      if (profile == null) {
        return FavoritesNotifier.empty(); // Return an empty notifier for logged-out users
      }
      return FavoritesNotifier(favoriteService, profile.uid);
    },
    loading: () => FavoritesNotifier.empty(), // Return an empty notifier during loading
    error: (_, __) => FavoritesNotifier.empty(), // Handle errors gracefully
  );
});

class FavoritesNotifier extends StateNotifier<Map<String, List<String>>> {
  final FavoriteService? _service;
  final String? _userId;

  // Constructor for logged-in users
  FavoritesNotifier(this._service, this._userId) : super({'events': [], 'stands': []}) {
    if (_userId != null && _service != null) {
      loadFavorites();
    }
  }

  // Constructor for empty state
  FavoritesNotifier.empty() : _service = null, _userId = null, super({'events': [], 'stands': []});

  // Load favorites from Firestore
  Future<void> loadFavorites() async {
    if (_userId == null || _service == null) return; // No-op for empty state

    try {
      final favorites = await _service.getFavorites(_userId);
      state = favorites;
    } catch (e) {
      // Handle errors gracefully
      state = {'events': [], 'stands': []};
    }
  }

  // Toggle favorite (add or remove)
  Future<void> toggleFavorite(String category, String itemId) async {
    if (_userId == null || _service == null) return; // No-op for empty state

    if (state[category]?.contains(itemId) == true) {
      await _service.removeFavorite(_userId, category, itemId);
      state = {
        ...state,
        category: state[category]!.where((id) => id != itemId).toList(),
      };
    } else {
      await _service.addFavorite(_userId, category, itemId);
      state = {
        ...state,
        category: [...?state[category], itemId],
      };
    }
  }
}
