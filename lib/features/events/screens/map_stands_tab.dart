import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/category.dart';
import '../../../data/models/event.dart';
import '../../../data/models/stand.dart';
import '../../../providers/category_provider.dart';
import '../../stands/providers/stand_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;

class MapStandsTab extends ConsumerStatefulWidget {
  final Event event;

  MapStandsTab({required this.event});

  @override
  _MapStandsTabState createState() => _MapStandsTabState();
}

class _MapStandsTabState extends ConsumerState<MapStandsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String? _selectedStandId; // Track selected stand ID
  double _currentZoomLevel = 18.0;
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final standsAsync = ref.watch(standsForEventProvider(widget.event.id));
    final categoriesAsync =
        ref.watch(categoriesForEventProvider(widget.event.id));

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search Stands',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
        // Map and Stands List
        Expanded(
          child: standsAsync.when(
            data: (stands) => categoriesAsync.when(
              data: (categories) =>
                  _buildMapAndStands(context, stands, categories),
              loading: () => Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('Error loading categories')),
            ),
            loading: () => Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                Center(child: Text('Error loading stands')),
          ),
        ),
      ],
    );
  }

  Widget _buildMapAndStands(BuildContext context, List<Stand> stands, List<Category> categories) {
    // Group stands by category
    final groupedStands = _groupStandsByCategory(stands, categories);

    return Column(
      children: [
        // Map section with fixed height
        Container(
          height: 300,
          margin: const EdgeInsets.only(bottom: 8.0),
          child: SizedBox(
              height: MediaQuery.of(context).size.height / 4, // Map section
              child: FutureBuilder<Set<Marker>>(
                  future: generateMarkers(stands, categories),
                  builder: (context, snapshot) {
                    return GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                            widget.event.latitude, widget.event.longitude),
                        zoom: _currentZoomLevel,
                      ),
                      onMapCreated: (controller) => _mapController = controller,
                      onCameraMove: (position) {
                        setState(() {
                          _currentZoomLevel = position.zoom; // Track zoom level
                        });
                      },
                      markers: snapshot.data ?? {},
                      scrollGesturesEnabled: true,
                      zoomGesturesEnabled: true,
                      rotateGesturesEnabled: true,
                      tiltGesturesEnabled: false,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                    );
                  })),
        ),
        // Stands grouped by categories
        Expanded(
          child: ListView(
            children: groupedStands.entries.map((entry) {
              final categoryName = entry.key;
              final stands = entry.value.where((stand) {
                return stand.name.toLowerCase().contains(_searchQuery) ||
                    stand.description.toLowerCase().contains(_searchQuery);
              }).toList();

              if (stands.isEmpty) return SizedBox.shrink();

              return ExpansionTile(
                title: Text(categoryName),
                children: stands.map((stand) {
                  return ListTile(
                    title: Text(stand.name),
                    subtitle: Text(stand.description),
                    onTap: () {
                      _onStandSelected(stand);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tapped on ${stand.name}')),
                      );
                    },
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Stand selection on Map
  void _onStandSelected(Stand stand) {
    setState(() {
      _selectedStandId = stand.id;
    });

    // Animate camera to the selected stand's location
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(stand.eventLatitude!, stand.eventLongitude!),
        _currentZoomLevel, // Keep current zoom level
      ),
    );
  }

  // Group stands by their categories
  Map<String, List<Stand>> _groupStandsByCategory(List<Stand> stands, List<Category> categories) {
    final categoryMap = {
      for (var category in categories) category.id: category.name,
    };

    final Map<String, List<Stand>> groupedStands = {};

    for (var stand in stands) {
      final categoryName = categoryMap[stand.standCategoryId] ?? 'Untitled';
      if (!groupedStands.containsKey(categoryName)) {
        groupedStands[categoryName] = [];
      }
      groupedStands[categoryName]!.add(stand);
    }

    return groupedStands;
  }

  // Generate markers dynamically based on category icons
  // Future<Set<Marker>> _generateDynamicMarkers(List<Stand> stands, List<Category> categories) async {
  //   // Map category IDs to their corresponding icons
  //   final categoryIconMap = {
  //     for (var category in categories) category.id: category.icon,
  //   };
  //   final Set<Marker> markers = {};
  //   stands.map((stand) async {
  //     final icon = categoryIconMap[stand.standCategoryId] ?? Icons.store;
  //
  //     // Highlight selected marker
  //     final isSelected = stand.id == _selectedStandId;
  //     final markerColor = isSelected ? Colors.red : Colors.blue;
  //     markers.add(Marker(
  //       markerId: MarkerId(stand.id),
  //       position: LatLng(stand.eventLatitude!, stand.eventLongitude!),
  //       icon: await _createSelectedMarker(icon, markerColor, isSelected),
  //       infoWindow: InfoWindow(
  //         title: stand.name,
  //         snippet: stand.description,
  //       ),
  //     ));
  //   });
  //   return markers;
  // }

  /// Create a BitmapDescriptor from an IconData
  // Future<BitmapDescriptor> _createBitmapDescriptorFromIcon(IconData icon) async {
  //   final pictureRecorder = ui.PictureRecorder();
  //   final canvas = Canvas(pictureRecorder);
  //   const double size = 48.0;
  //
  //   // Draw the icon
  //   final textPainter = TextPainter(
  //     text: TextSpan(
  //       text: String.fromCharCode(icon.codePoint),
  //       style: TextStyle(
  //         fontSize: size,
  //         fontFamily: icon.fontFamily,
  //         color: Colors.blue, // Set a default color for the icon
  //       ),
  //     ),
  //     textDirection: TextDirection.ltr,
  //   );
  //   textPainter.layout();
  //   textPainter.paint(
  //       canvas,
  //       Offset(
  //         (size - textPainter.width) / 2,
  //         (size - textPainter.height) / 2,
  //       ));
  //
  //   // Convert canvas to image
  //   final image = await pictureRecorder
  //       .endRecording()
  //       .toImage(size.toInt(), size.toInt());
  //   final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  //
  //   // Convert the image to a BitmapDescriptor
  //   return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  // }

  // Future<BitmapDescriptor> _createSelectedMarker(IconData icon, Color color, bool isSelected) async {
  //   // Adjust size for selected marker
  //   final double size = isSelected ? 60.0 : 40.0;
  //
  //   // Generate a custom marker
  //   const double markerWidth = 30.0; // Marker width
  //   const double markerHeight = 37.5; // Marker height
  //
  //   final pictureRecorder = ui.PictureRecorder();
  //   final canvas = Canvas(pictureRecorder);
  //
  //   final paint = Paint()..color = color;
  //
  //   // Draw marker pin shape
  //   final Path path = Path()
  //     ..moveTo(markerWidth / 2, markerHeight)
  //     ..lineTo(markerWidth * 0.1, markerHeight * 0.6)
  //     ..quadraticBezierTo(
  //       markerWidth / 2,
  //       0,
  //       markerWidth * 0.9,
  //       markerHeight * 0.6,
  //     )
  //     ..close();
  //   canvas.drawPath(path, paint);
  //
  //   // Draw white circle for the icon background
  //   final iconBackgroundPaint = Paint()..color = Colors.white;
  //   const double circleRadius = 10.0;
  //   canvas.drawCircle(
  //     Offset(markerWidth / 2, markerHeight * 0.4),
  //     circleRadius,
  //     iconBackgroundPaint,
  //   );
  //
  //   // Draw the icon in the center
  //   final textPainter = TextPainter(
  //     text: TextSpan(
  //       text: String.fromCharCode(icon.codePoint),
  //       style: TextStyle(
  //         fontSize: circleRadius * 1.5, // Adjust size based on circle radius
  //         fontFamily: 'MaterialIcons', // Use MaterialIcons font
  //         color: Colors.black, // Icon color
  //       ),
  //     ),
  //     textDirection: TextDirection.ltr,
  //   );
  //   textPainter.layout();
  //   textPainter.paint(
  //     canvas,
  //     Offset(
  //       (markerWidth - textPainter.width) / 2,
  //       (markerHeight * 0.4 - textPainter.height / 2),
  //     ),
  //   );
  //
  //   // Convert the canvas to an image
  //   final image = await pictureRecorder
  //       .endRecording()
  //       .toImage(markerWidth.toInt(), markerHeight.toInt());
  //   final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  //
  //   return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  //   // or use a simpler fallback like this:
  //   return BitmapDescriptor.defaultMarkerWithHue(
  //       isSelected ? BitmapDescriptor.hueRed : BitmapDescriptor.hueBlue);
  // }

  Future<BitmapDescriptor> createCustomMarker(IconData icon, Color markerColor, bool isSelected) async {
    final double markerWidth = isSelected ? 50.0 : 30.0; // Marker width
    final double markerHeight = isSelected ? 57.5 : 37.5; // Marker height

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    final paint = Paint()..color = markerColor;

    // Draw marker pin shape
    final Path path = Path()
      ..moveTo(markerWidth / 2, markerHeight)
      ..lineTo(markerWidth * 0.1, markerHeight * 0.6)
      ..quadraticBezierTo(
        markerWidth / 2,
        0,
        markerWidth * 0.9,
        markerHeight * 0.6,
      )
      ..close();
    canvas.drawPath(path, paint);

    // Draw white circle for the icon background
    final iconBackgroundPaint = Paint()..color = Colors.white;
    const double circleRadius = 10.0;
    canvas.drawCircle(
      Offset(markerWidth / 2, markerHeight * 0.4),
      circleRadius,
      iconBackgroundPaint,
    );

    // Draw the icon in the center
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: circleRadius * 1.5, // Adjust size based on circle radius
          fontFamily: 'MaterialIcons', // Use MaterialIcons font
          color: Colors.black, // Icon color
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (markerWidth - textPainter.width) / 2,
        (markerHeight * 0.4 - textPainter.height / 2),
      ),
    );

    // Convert the canvas to an image
    final image = await pictureRecorder
        .endRecording()
        .toImage(markerWidth.toInt(), markerHeight.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  Future<Set<Marker>> generateMarkers(List<Stand> stands, List<Category> categories) async {
    final categoryIconMap = {
      for (var category in categories) category.id: category.icon,
    };

    final Set<Marker> markers = {};
    for (var stand in stands) {
      final icon = categoryIconMap[stand.standCategoryId] ?? Icons.store;

      final isSelected = stand.id == _selectedStandId;
      final markerColor = isSelected ? Colors.red : Colors.blue;
      // Generate custom marker
      final markerIcon = await createCustomMarker(icon, markerColor, isSelected);

      markers.add(
        Marker(
          markerId: MarkerId(stand.id),
          position: LatLng(stand.eventLatitude!, stand.eventLongitude!),
          icon: markerIcon,
          infoWindow: InfoWindow(
            title: stand.name,
            snippet: stand.description,
          ),
        ),
      );
    }
    return markers;
  }
}
