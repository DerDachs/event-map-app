import 'package:flutter/material.dart';

class DiscoverScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Featured Stands', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 10),
            _buildHorizontalScrollCards(context, ['Stand 1', 'Stand 2', 'Stand 3']),
            Divider(),

            Text('New Markets', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 10),
            _buildHorizontalScrollCards(context, ['Market A', 'Market B']),
            Divider(),

            Text('Personalized Recommendations', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 10),
            _buildHorizontalScrollCards(context, ['Event X', 'Event Y']),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalScrollCards(BuildContext context, List<String> items) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Container(
              width: 120,
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store, size: 50, color: Theme.of(context).primaryColor),
                  SizedBox(height: 8),
                  Text(items[index], textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}