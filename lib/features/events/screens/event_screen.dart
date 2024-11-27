import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:market_mates/data/models/event.dart';
import '../providers/event_provider.dart';

class EventScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Events')),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return Center(child: Text('No events available.'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Side-Scrolling Cards for Upcoming Events
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final standardImage = event.images.firstWhere(
                            (img) => img.isStandard,
                        orElse: () => event.images.first,
                      );

                      return Card(
                        margin: EdgeInsets.all(8.0),
                        child: Container(
                          width: 250,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Event Image
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                                  child: Image.network(
                                    standardImage.url,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                              ),
                              // Event Details
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.name,
                                      style: Theme.of(context).textTheme.headlineSmall,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      event.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '${event.startTime.toLocal()} - ${event.endTime.toLocal()}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Divider(),

                // Map Feature with Mapbox
                //Container(
                //  height: 300,
                //  child: MapboxMap(
                //    accessToken: 'sk.eyJ1IjoiZGFjaHN3ZSIsImEiOiJjbTN5bGo5aDkxbXc3MmlzY2hkMTRhOHI0In0.YgM1wFAMzbskDgYfjWKdTw', // Replace with your token
                //    onMapCreated: (MapboxMapController controller) {
                //      // Add markers when the map is created
                //      for (var event in events) {
                //        controller.addSymbol(SymbolOptions(
                //          geometry: LatLng(
                //            event.latitude,
                //            event.longitude,
                //          ),
                //          iconImage: "marker-15", // Default Mapbox marker icon
                //          iconSize: 2.0,
                //          textField: event.name,
                //          textOffset: Offset(0, 1.5),
                //        ));
                //      }
                //    },
                //    initialCameraPosition: CameraPosition(
                //      target: LatLng(37.7749, -122.4194), // Replace with dynamic user location
                //      zoom: 12.0,
                //    ),
                //  ),
                //),
                Divider(),

                // List of Events
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'All Events',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];

                    return ListTile(
                      title: Text(event.name),
                      subtitle: Text('${event.startTime.toLocal()} - ${event.endTime.toLocal()}'),
                      trailing: Icon(Icons.arrow_forward),
                      onTap: () {
                        // Navigate to Event Detail Page (future implementation)
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading events: $error')),
      ),
    );
  }
}