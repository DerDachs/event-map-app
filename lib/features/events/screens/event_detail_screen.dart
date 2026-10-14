import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/event.dart';
import '../../../providers/state_provider.dart';
import '../../../providers/user_provider.dart';
import '../../market_editor/widgets/edit_market_button.dart';
import '../providers/event_provider.dart';
import '../widgets/event_info.dart';

/// A market before the user has joined it. Joined users go straight to the
/// event page with map and team.
class EventDetailsScreen extends ConsumerStatefulWidget {
  final Event event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  ConsumerState<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends ConsumerState<EventDetailsScreen> {
  bool _joining = false;
  bool _redirected = false;

  void _openEventPage({int tab = 1}) {
    if (_redirected) return;
    _redirected = true;
    ref.read(bottomNavIndexProvider.notifier).state = tab;
    Navigator.pushReplacementNamed(context, '/event-joined', arguments: widget.event);
  }

  Future<void> _join() async {
    final uid = ref.read(userProfileProvider).valueOrNull?.uid;
    if (uid == null) return;
    setState(() => _joining = true);
    try {
      await ref.read(eventServiceProvider).joinEvent(widget.event.id, uid);
      ref.invalidate(userParticipationProvider(widget.event.id));
      if (mounted) _openEventPage();
    } catch (e) {
      if (!mounted) return;
      setState(() => _joining = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Beitreten fehlgeschlagen: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final participation = ref.watch(userParticipationProvider(widget.event.id));
    if (participation.valueOrNull == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openEventPage());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.name),
        actions: [EditMarketButton(eventId: widget.event.id)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 16),
        child: EventInfo(
          event: widget.event,
          action: participation.isLoading
              ? const Center(child: CircularProgressIndicator())
              : FilledButton.icon(
                  icon: _joining
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.map_outlined),
                  label: const Text('Zur Marktkarte'),
                  onPressed: _joining ? null : _join,
                ),
        ),
      ),
    );
  }
}
