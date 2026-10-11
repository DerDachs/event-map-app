import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../data/models/event.dart';
import '../../../utils/formatters.dart';

/// Dates, pictures and practical information about a market. Used on the
/// detail page before joining and in the "Infos" tab afterwards.
class EventInfo extends StatelessWidget {
  final Event event;
  final Widget? action;
  final bool showMap;

  const EventInfo({super.key, required this.event, this.action, this.showMap = true});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final rows = <(IconData, String, String)>[
      (Icons.calendar_today_outlined, 'Zeitraum', formatDateRange(event.startTime, event.endTime)),
      if ((event.openingHours ?? const []).isNotEmpty)
        (Icons.schedule, 'Öffnungszeiten', formatOpeningHours(event.openingHours!)),
      if ((event.ticketPrice ?? '').isNotEmpty) (Icons.confirmation_number_outlined, 'Eintritt', event.ticketPrice!),
      if ((event.organizerName ?? '').isNotEmpty) (Icons.business_outlined, 'Veranstalter', event.organizerName!),
      if (event.stands.isNotEmpty) (Icons.storefront_outlined, 'Stände', '${event.stands.length}'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (event.images.isNotEmpty)
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: event.images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  event.images[i].url,
                  width: event.images.length == 1 ? MediaQuery.of(context).size.width - 32 : 300,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 300,
                    color: Colors.black12,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(event.name, style: text.headlineSmall),
        ),
        for (final (icon, label, value) in rows)
          ListTile(
            dense: true,
            leading: Icon(icon),
            title: Text(label, style: text.labelMedium),
            subtitle: Text(value, style: text.bodyLarge),
          ),
        if (action != null)
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: action),
        if (event.description.isNotEmpty) _Section(title: 'Über den Markt', body: event.description),
        if ((event.eventTip ?? '').isNotEmpty) _Section(title: 'Unser Tipp', body: event.eventTip!),
        if ((event.organizerInfo ?? '').isNotEmpty) _Section(title: 'Veranstalter', body: event.organizerInfo!),
        if (showMap && (event.latitude != 0 || event.longitude != 0))
          Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 200,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(event.latitude, event.longitude),
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('event'),
                      position: LatLng(event.latitude, event.longitude),
                      infoWindow: InfoWindow(title: event.name),
                    ),
                  },
                  liteModeEnabled: true,
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(body),
          ],
        ),
      );
}
