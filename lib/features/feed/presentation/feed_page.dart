import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/session_store.dart';
import '../../../shared/models/tracked_session.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final List<TrackedSession> sessions = SessionStore.sessions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
      ),
      body: sessions.isEmpty
          ? const Center(
              child: Text('No sessions yet'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.type.label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('Elapsed: ${_formatDuration(session.elapsed)}'),
                        Text(
                          'Completed: ${DateFormat.yMd().add_jm().format(session.completedAt)}',
                        ),
                        Text('Route points: ${session.routePoints.length}'),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}