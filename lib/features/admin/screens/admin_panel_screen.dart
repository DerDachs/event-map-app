import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/user_provider.dart';

class AdminPanelScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);

    if (userProfile.value?.role != 'admin') {
      return Scaffold(
        appBar: AppBar(title: Text('Unauthorized')),
        body: Center(child: Text('You do not have access to this page.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Admin Panel')),
      body: ListView(
        children: [
          ListTile(
            title: Text('Create Event'),
            onTap: () {
              Navigator.pushNamed(context, '/create-event');
            },
          ),
          ListTile(
            title: Text('Manage Stands'),
            onTap: () {
              Navigator.pushNamed(context, '/manage-stands');
            },
          ),
          ListTile(
            title: Text('Upload Images'),
            onTap: () {
              Navigator.pushNamed(context, '/upload-images');
            },
          ),
        ],
      ),
    );
  }
}