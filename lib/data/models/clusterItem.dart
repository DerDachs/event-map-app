import 'package:google_maps_flutter/google_maps_flutter.dart';

class ClusterItem {
  final String id;
  final LatLng location;
  final String title;
  final List<dynamic> items; // To store associated data (like stands)

  ClusterItem({
    required this.id,
    required this.location,
    required this.title,
    required this.items,
  });
}