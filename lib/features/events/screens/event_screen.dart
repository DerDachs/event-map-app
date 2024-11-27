import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/models/event.dart';
import '../providers/event_provider.dart';
import 'package:intl/intl.dart';

class EventScreen extends ConsumerStatefulWidget {
  @override
  _EventScreenState createState() => _EventScreenState();
}

class _EventScreenState extends ConsumerState<EventScreen> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  LatLng _currentPosition = LatLng(48.896141, 9.191327); // Default position

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      body: eventsAsync.when(
        data: (events) {
          // Update markers dynamically
          _updateMarkers(events);

          return Column(
            children: [
              // Map View
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom: 14.0,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  markers: _markers,
                  onCameraMove: (CameraPosition position) {
                    _currentPosition = position.target;
                  },
                  onCameraIdle: () {
                    // When user stops dragging, fetch nearby events (optional future feature)
                    // _fetchEventsAround(_currentPosition);
                  },
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                ),
              ),
              Divider(),

              // List of Events
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'All Events',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return ListTile(
                      title: Text(event.name),
                      subtitle: Text(
                        '${DateFormat("yyyy-MM-dd").format(event.startTime)} - ${DateFormat("yyyy-MM-dd").format(event.endTime)}',
                      ),
                      trailing: Icon(Icons.arrow_forward),
                      onTap: () {
                        // Optional: Center map on marker
                        _mapController.animateCamera(
                          CameraUpdate.newLatLng(
                            LatLng(event.latitude, event.longitude),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error loading events: $error')),
      ),
    );
  }

  void _updateMarkers(List<Event> events) {
    setState(() {
      _markers.clear();
      for (final event in events) {
        _markers.add(
          Marker(
            markerId: MarkerId(event.id.toString()),
            position: LatLng(event.latitude, event.longitude),
            infoWindow: InfoWindow(
              title: event.name,
              snippet: event.description,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }
    });
  }
}