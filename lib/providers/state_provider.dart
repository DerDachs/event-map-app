import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/category_service.dart';
import 'package:permission_handler/permission_handler.dart';

// Provider for managing the current tab index
final bottomNavIndexProvider = StateProvider<int>((ref) {
  return 0; // Default to the first tab
});

final loginLoadingProvider = StateProvider<bool>((ref) => false);

Future<void> requestLocationPermission() async {
  var status = await Permission.locationWhenInUse.request();

  if (status.isGranted) {
    print('Location permission granted');
  } else if (status.isDenied) {
    print('Location permission denied');
  } else if (status.isPermanentlyDenied) {
    // Redirect the user to app settings
    await openAppSettings();
  }
}