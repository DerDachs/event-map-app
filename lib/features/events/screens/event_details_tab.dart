import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/event.dart';
import '../../../utils/event_details_section.dart';
import '../../../utils/formatters.dart';


class EventDetailsTab extends StatelessWidget {
  final Event event;

  const EventDetailsTab({required this.event});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 8),
          Text(
            '${DateFormat('MMM dd, yyyy').format(event.startTime)} - ${DateFormat('MMM dd, yyyy').format(event.endTime)}',
            style: Theme.of(context).textTheme.titleMedium,
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
          EventDetailSection(event: event),
          SizedBox(height: 16,)
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

}