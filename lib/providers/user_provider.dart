import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/profile.dart';
import '../services/user_service.dart';

// Provider for the UserService
final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

// StateNotifier for managing UserProfile
class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final UserService _userService;

  UserProfileNotifier(this._userService) : super(const AsyncValue.loading());

  // Fetch the user profile and update the state
  Future<void> loadUserProfile(String uid) async {
    try {
      state = const AsyncValue.loading(); // Set the state to loading
      final profile = await _userService.fetchUserProfile(uid); // Fetch profile using _userService
      state = AsyncValue.data(profile); // Set the state to data with the fetched profile
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace); // Handle errors
    }
  }

  // Save the user profile and refresh the state
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await _userService.saveUserProfile(profile);
      state = AsyncValue.data(profile); // Update the state after saving
    } catch (e, stackTrace) {
      state = AsyncValue.error(e,stackTrace);
    }
  }
  // Reset the user profile state
  void resetUserProfile() {
    state = const AsyncValue.data(null); // Reset to a null profile
  }

  Future<bool> doesUserProfileExist(String uid) async {
    bool exists = await _userService.doesUserProfileExist(uid);
    return exists;
  }

  bool isAdmin(UserProfile? userProfile) {
    return userProfile?.role == 'admin';
  }
}

// Provider for accessing UserProfile state
final userProfileProvider =
StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  final userService = ref.watch(userServiceProvider);
  return UserProfileNotifier(userService);
});