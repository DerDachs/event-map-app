import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/models/event.dart';
import '../../../data/models/stand.dart';
import '../../stands/providers/stand_provider.dart';

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
              icon: Icon(Icons.ios_share),
              onPressed: () {
                // Share event logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Dummy for Sharing - nothing behind yet...')),
                );
                shareEvent(event);
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // TODO: Dates (von wann bis wann)
              // Event Image Carousel
              _buildImageCarousel(event),
              SizedBox(height: 16),
              // Space between carousel and text
              _buildEventDescription(event, context),
              // TODO: Details, Veranstalter Öffnungszeiten, Eintritt
              SizedBox(height: 16),
              // Space between text and map
              // Map Section // TODO: Hier mit Standspezifischen Markern
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
                      data: (stands) => _buildMapWithMarkers(stands),
                      loading: () => Center(child: CircularProgressIndicator()),
                      error: (error, stack) =>
                          Center(child: Text('Error loading stands: $error')),
                    ),
                  ),
                ),
              ),
              //TODO: Unser Tipp als Platzhalter
              SizedBox(height: 16),
              // Space between map and stands list
              //TODO: Lange Beschreibung des Events
              Divider(),
              // Stands Overview TODO: Keine Stand Overview hier -> erst nach Eventbeitritt
              standsAsync.when(
                data: (stands) => _buildStandList(context, stands),
                loading: () => Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    Center(child: Text('Error loading stand list: $error')),
              ),
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

  Widget _buildBoxedSection(BuildContext context,  {required String title, required String content}) {
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

  void shareEvent(Event event) {
    // Implement sharing logic using share package
    print('Sharing event: ${event.name}');
  }
}
