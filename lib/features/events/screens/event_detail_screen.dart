import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../../data/models/event.dart';
import '../../../data/models/stand.dart';
import '../../../providers/user_provider.dart';
import '../../../utils/custom_widgets.dart';
import '../../../utils/formatters.dart';
import '../../stands/providers/stand_provider.dart';
import '../providers/event_provider.dart';

class EventDetailsScreen extends ConsumerWidget {
  final Event event;

  const EventDetailsScreen({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userParticipationAsync = ref.watch(userParticipationProvider(event.id));
    // Fetch stands dynamically based on event ID
    final standsAsync = ref.watch(standsForEventProvider(event.id));

    return Scaffold(
        appBar: AppBar(
          title: Text(event.name),
          actions: [
            IconButton(
              icon: Icon(Icons.ios_share),
              onPressed: () {
                // Share event logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Dummy for Sharing - nothing behind yet...')),
                );
                shareEvent(event);
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          // Wrap the content in a scrollable view
          child: Column(
            children: [
              Text(
                '${DateFormat('MMM dd, yyyy').format(event.startTime)} - ${DateFormat('MMM dd, yyyy').format(event.endTime)}',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              // Space between dates and pictures
              // Event Image Carousel
              _buildImageCarousel(event),
              SizedBox(height: 16),
              // Space between carousel and text
              // Event Details
              _buildEventDetail('Organizer', event.organizerName ?? 'Unknown'),
              _buildOpeningHours(event, context),
              _buildEventDetail('Ticket Price',
                  event.ticketPrice != null ? '${event.ticketPrice}' : 'Free'),

              SizedBox(height: 16),
              // Space between text and map
              userParticipationAsync.when(
                data: (isParticipant) {
                  if (isParticipant) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pushReplacementNamed(
                        context,
                        '/event-joined',
                        arguments: event,
                      );
                    });
                    return SizedBox.shrink(); // Avoid rendering a button
                  } else {
                    return Center(
                      child: CustomElevatedButton(
                        label: 'Join Event',
                        onPressed: () => joinEvent(context, ref, event.id),
                      ),
                    );
                  }
                },
                loading: () => Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Text('Error loading participation: $error'),
                ),
              ),
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 16),
              // Description
              _buildEventDescription(event, context),
              SizedBox(height: 16),
              Divider(),
              Text(
                'Location',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 16),
              // Map Section
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
                    child: Container(
                      height: 200,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(event.latitude, event.longitude),
                          zoom: 15,
                        ),
                        markers: {
                          Marker(
                            markerId: MarkerId('eventLocation'),
                            position: LatLng(event.latitude, event.longitude),
                            infoWindow: InfoWindow(title: event.name),
                          ),
                        },
                        zoomControlsEnabled: true,
                        scrollGesturesEnabled: true,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                      ),
                    ),

                    // Space between map and stands list
                    //TODO: Lange Beschreibung des Events
                  )),
              SizedBox(height: 100),
            ],
          ),
        ));
  }

  Widget _buildImageCarousel(Event event) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: event.images.length,
        itemBuilder: (context, index) {
          final image = event.images[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                image.url,
                fit: BoxFit.cover,
                width: 300,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapWithMarkers(List<Stand> stands) {
    // Calculate map bounds
    LatLngBounds calculateBounds() {
      final bounds = stands.fold<LatLngBounds?>(
        null,
        (prev, stand) {
          final standLatLng =
              LatLng(stand.eventLatitude!, stand.eventLongitude!);
          if (prev == null) {
            return LatLngBounds(southwest: standLatLng, northeast: standLatLng);
          }
          return LatLngBounds(
            southwest: LatLng(
              prev.southwest.latitude < standLatLng.latitude
                  ? prev.southwest.latitude
                  : standLatLng.latitude,
              prev.southwest.longitude < standLatLng.longitude
                  ? prev.southwest.longitude
                  : standLatLng.longitude,
            ),
            northeast: LatLng(
              prev.northeast.latitude > standLatLng.latitude
                  ? prev.northeast.latitude
                  : standLatLng.latitude,
              prev.northeast.longitude > standLatLng.longitude
                  ? prev.northeast.longitude
                  : standLatLng.longitude,
            ),
          );
        },
      );

      if (bounds != null) {
        return LatLngBounds(
          southwest: LatLng(bounds.southwest.latitude - 0.001,
              bounds.southwest.longitude - 0.001),
          northeast: LatLng(bounds.northeast.latitude + 0.001,
              bounds.northeast.longitude + 0.001),
        );
      } else {
        // Fallback: Default bounds around the event
        return LatLngBounds(
          southwest: LatLng(event.latitude - 0.001, event.longitude - 0.001),
          northeast: LatLng(event.latitude + 0.001, event.longitude + 0.001),
        );
      }
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(event.latitude, event.longitude),
        zoom: 30.0,
      ),
      markers: stands.map((stand) {
        return Marker(
          markerId: MarkerId(stand.id),
          position: LatLng(stand.eventLatitude!, stand.eventLongitude!),
          infoWindow: InfoWindow(
            title: stand.name,
            snippet: stand.description,
          ),
        );
      }).toSet(),
      onMapCreated: (GoogleMapController controller) {
        controller
            .animateCamera(CameraUpdate.newLatLngBounds(calculateBounds(), 50));
      },
      scrollGesturesEnabled: false,
      zoomGesturesEnabled: true,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      minMaxZoomPreference: MinMaxZoomPreference(16, null),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }

  Widget _buildEventDescription(Event event, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBoxedSection(
          context,
          title: 'Description',
          content: event.description,
        ),
        SizedBox(height: 16),
        _buildBoxedSection(
          context,
          title: 'Unser Tipp',
          content: event.eventTip ?? 'No hint available right now!',
        ),
        SizedBox(height: 16),
        _buildBoxedSection(
          context,
          title: 'Organizer Information',
          content: event.organizerInfo ?? 'N/A',
        ),
      ],
    );
  }

  Widget _buildBoxedSection(BuildContext context,
      {required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.white, // Background color for the box
        borderRadius: BorderRadius.circular(12.0), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black12, // Shadow color
            blurRadius: 8, // How much the shadow should blur
            offset: Offset(0, 4), // Offset for the shadow
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.left,
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            value,
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _buildOpeningHours(Event event, BuildContext context) {
    if (event.openingHours != null) {
      final List<OpeningHour> openingHours =
          event.openingHours as List<OpeningHour>;
      final formattedHours = formatOpeningHours(openingHours);

      return _buildEventDetail('Opening Hours', formattedHours);
    } else {
      return _buildEventDetail('Opening Hours', 'Not available');
    }
  }

  void joinEvent(BuildContext context, WidgetRef ref, String eventId) async {
    try {
      final eventService = ref.read(eventServiceProvider);
      final userId = ref.read(userProfileProvider).value?.uid;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You must be logged in to join the event.')),
        );
        return;
      }

      // Add user to participants
      await eventService.joinEvent(eventId, userId);

      // Refresh participation state
      ref.invalidate(userParticipationProvider(eventId));

      // Navigate to EventJoinedScreen
      Navigator.pushReplacementNamed(context, '/event-joined', arguments: event);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining event: $e')),
      );
    }
  }

  void shareEvent(Event event) {
    // Implement sharing logic using share package
    print('Sharing event: ${event.name}');
  }
}
