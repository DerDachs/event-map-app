import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/models/event.dart';

class EventDetailsScreen extends StatelessWidget {
  final Event event;

  const EventDetailsScreen({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map Section
            Container(
              height: 300,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(event.latitude, event.longitude),
                  zoom: 16.0,
                ),
                zoomControlsEnabled: true,
                markers: {
                  Marker(
                    markerId: MarkerId(event.id),
                    position: LatLng(event.latitude, event.longitude),
                    infoWindow: InfoWindow(title: event.name),
                  ),
                },
                scrollGesturesEnabled: false, // Disable scrolling
                rotateGesturesEnabled: false, // Disable rotation
                tiltGesturesEnabled: false, // Disable tilting
                zoomGesturesEnabled: true, // Allow zooming
                myLocationButtonEnabled: false,
                myLocationEnabled: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(height: 20),
                  Text('Teams:', style: Theme.of(context).textTheme.headlineSmall),
                  // Placeholder for teams or dynamic integration
                  Text('Team functionality to be integrated'),
                  Divider(),
                  Text('Stands:', style: Theme.of(context).textTheme.headlineSmall),
                  // Placeholder for stands
                  Text('Stands functionality to be integrated'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}