import 'package:flutter/material.dart';
import '../../../data/models/event.dart';

class EventDetailSection extends StatelessWidget {
  final Event event;

  const EventDetailSection({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
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
      child: ExpansionTile(
        title: Text(
          'Event Details',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        children: [
          _buildDetailItem(
            context: context,
            title: 'Description',
            content: event.description,
          ),
          Divider(height: 1),
          _buildDetailItem(
            context: context,
            title: 'Unser Tipp',
            content: event.eventTip ?? 'No hint available right now!',
          ),
          Divider(height: 1),
          _buildDetailItem(
            context: context,
            title: 'Organizer Information',
            content: event.organizerInfo ?? 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required BuildContext context,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
}