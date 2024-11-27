import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:mapbox_gl/mapbox_gl.dart';
import '../../../data/models/event.dart';
import '../../../data/models/stand.dart';
import '../../stands/providers/stand_provider.dart';
import '../providers/event_provider.dart';

class EventDetailsScreen extends ConsumerWidget {
  final Event event;

  const EventDetailsScreen({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standsAsync = ref.watch(standsProvider(event.stands));

    return Scaffold(
      appBar: AppBar(title: Text(event.name)),
      body: standsAsync.when(
        data: (stands) {
          return Column(
            children: [
              //Container(
              //  height: 300,
              //  child: MapboxMap(
              //    accessToken: 'YOUR_MAPBOX_ACCESS_TOKEN',
              //    initialCameraPosition: CameraPosition(
              //      target: LatLng(event.latitude, event.longitude),
              //      zoom: 14,
              //    ),
              //    onMapCreated: (controller) {
              //      for (final stand in stands) {
              //        controller.addSymbol(SymbolOptions(
              //          geometry: LatLng(stand.latitude, stand.longitude),
              //          iconImage: "marker-15",
              //          textField: stand.name,
              //        ));
              //      }
              //    },
              //  ),
              //),
              Expanded(
                child: ListView(
                  children: stands.map((stand) {
                    return ListTile(
                      title: Text(stand.name),
                      subtitle: Text(stand.description),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading stands: $error')),
      ),
    );
  }
}