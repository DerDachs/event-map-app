import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../../data/models/event.dart';
import '../../../data/models/stand.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../utils/event_details_section.dart';
import '../../stands/providers/stand_provider.dart';
import 'dart:ui' as ui;

import '../../teams/providers/team_provider.dart';
import '../../teams/screens/team_section.dart';

class EventJoinedScreen extends ConsumerWidget {
  final Event event;

  const EventJoinedScreen({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch stands dynamically based on event ID
    final standsAsync = ref.watch(standsForEventProvider(event.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(event.name),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'notifications should be shown here in the future')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.ios_share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Dummy for Sharing - nothing behind yet...')),
              );
              shareEvent(event);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 16),
            Text(
              '${DateFormat('MMM dd, yyyy').format(event.startTime)} - ${DateFormat('MMM dd, yyyy').format(event.endTime)}',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            EventDetailSection(event: event),
            SizedBox(height: 16),
            _buildTeamSection(context, ref),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  height: 300,
                  child: standsAsync.when(
                    data: (stands) => _buildMapWithDynamicMarkers(stands, ref),
                    loading: () => Center(child: CircularProgressIndicator()),
                    error: (error, stack) =>
                        Center(child: Text('Error loading stands: $error')),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Divider(),
            standsAsync.when(
              data: (stands) => _buildStandList(context, stands),
              loading: () => Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('Error loading stand list: $error')),
            ),
          ],
        ),
      ),
    );
  }

  Future<BitmapDescriptor> _getMaterialIcon(IconData icon) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = Colors.blue;
    const double size = 48.0;

    // Draw circle background
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);

    // Draw Material icon
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size / 2,
          fontFamily: icon.fontFamily,
          color: Colors.white,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
        canvas,
        Offset(
            (size - textPainter.width) / 2, (size - textPainter.height) / 2));

    final image = await pictureRecorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Future<Set<Marker>> _generateDynamicMarkers(
      List<Stand> stands, WidgetRef ref) async {
    Set<Marker> markers = {};

    for (Stand stand in stands) {
      // Fetch category details
      final categoryId = stand.standCategoryId ?? 'JN6cmd31Wy32uoM41rH7';
      final category = ref.read(categoryByIdProvider(categoryId)).value;
      final iconData = category?.icon ??
          Icons.store; // Default to `Icons.store` if no category or icon found
      final markerIcon = await _getMaterialIcon(iconData);

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

  Widget _buildMapWithDynamicMarkers(List<Stand> stands, WidgetRef ref) {
    return FutureBuilder<Set<Marker>>(
      future: _generateDynamicMarkers(stands, ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error generating markers'));
        }

        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(event.latitude, event.longitude),
            zoom: 18.0,
          ),
          markers: snapshot.data ?? {},
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: false,
          minMaxZoomPreference: MinMaxZoomPreference(16, null),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
        );
      },
    );
  }

  Widget _buildStandList(BuildContext context, List<Stand> stands) {
    return Container(
      height: 300, // Set a fixed height for the list
      child: ListView.builder(
        itemCount: stands.length,
        itemBuilder: (context, index) {
          final stand = stands[index];
          return ListTile(
            leading: Icon(Icons.storefront),
            title: Text(stand.name),
            subtitle: Text(stand.description),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tapped on ${stand.name}')),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTeamSection(BuildContext context, WidgetRef ref) {
    return TeamSection(event: event);
  }

  Future<void> joinTeam(BuildContext context, WidgetRef ref, String teamCode) async {
    final teamAsync = ref.read(teamByCodeProvider(teamCode));

    teamAsync.when(
      data: (team) async {
        if (team == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Team not found')),
          );
          return;
        }

        // Get the current user ID
        final userProfile = ref.read(userProfileProvider).value;
        if (userProfile == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User profile not loaded')),
          );
          return;
        }

        final userId = userProfile.uid;

        try {
          // Add user to the team using the service
          final teamService = ref.read(teamServiceProvider);
          await teamService.addMemberToTeam(team.id, userId);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully joined the team!')),
          );

          // Navigate or perform additional actions
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error joining team: $e')),
          );
        }
      },
      loading: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loading team information...')),
      ),
      error: (error, stack) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching team: $error')),
      ),
    );
  }

  void shareEvent(Event event) {
    // Implement sharing logic using share package
    print('Sharing event: ${event.name}');
  }
}
