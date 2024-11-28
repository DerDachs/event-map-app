import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/models/event.dart';
import '../../../data/models/stand.dart';
import '../../stands/providers/stand_provider.dart';


class EventDetailsScreen extends ConsumerWidget {
  final Event event;

  const EventDetailsScreen({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch stands dynamically based on event ID
    final standsAsync = ref.watch(standsForEventProvider(event.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(event.name),
      ),
      body: Column(
        children: [
          // Event Image Carousel
          _buildImageCarousel(event),
          SizedBox(height: 16), // Space between carousel and text
          Text("Description Placeholder"),
          SizedBox(height: 16), // Space between text and map

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
              child: SizedBox(
                height: 300,
                child: standsAsync.when(
                  data: (stands) => _buildMapWithMarkers(stands),
                  loading: () => Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error loading stands: $error')),
                ),
              ),
            ),
          ),
          SizedBox(height: 16), // Space between map and stands list
          Divider(),
          // Stands Overview
          standsAsync.when(
            data: (stands) => _buildStandList(context, stands),
            loading: () => Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error loading stands: $error')),
          ),
        ],
      ),
    );
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
          final standLatLng = LatLng(stand.eventLatitude!, stand.eventLongitude!);
          if (prev == null) {
            return LatLngBounds(southwest: standLatLng, northeast: standLatLng);
          }
          return LatLngBounds(
            southwest: LatLng(
              prev.southwest.latitude < standLatLng.latitude ? prev.southwest.latitude : standLatLng.latitude,
              prev.southwest.longitude < standLatLng.longitude ? prev.southwest.longitude : standLatLng.longitude,
            ),
            northeast: LatLng(
              prev.northeast.latitude > standLatLng.latitude ? prev.northeast.latitude : standLatLng.latitude,
              prev.northeast.longitude > standLatLng.longitude ? prev.northeast.longitude : standLatLng.longitude,
            ),
          );
        },
      );

      if (bounds != null) {
        return LatLngBounds(
          southwest: LatLng(bounds.southwest.latitude - 0.001, bounds.southwest.longitude - 0.001),
          northeast: LatLng(bounds.northeast.latitude + 0.001, bounds.northeast.longitude + 0.001),
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
        zoom: 15.0,
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
        controller.animateCamera(CameraUpdate.newLatLngBounds(calculateBounds(), 50));
      },
      scrollGesturesEnabled: false,
      zoomGesturesEnabled: true,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      minMaxZoomPreference: MinMaxZoomPreference(13,null),
    );
  }

  Widget _buildStandList(BuildContext context, List<Stand> stands) {
    return Expanded(
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
}