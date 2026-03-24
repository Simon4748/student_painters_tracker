import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/feed_item.dart';

class FeedItemCard extends StatelessWidget {
  final FeedItem item;

  const FeedItemCard({
    super.key,
    required this.item,
  });

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = DateFormat.yMd().add_jm().format(item.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: item.type == FeedItemType.run
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.authorName} logged a run',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('${item.branchName} • ${item.divisionName}'),
                  Text('Role: ${item.authorRole}'),
                  const SizedBox(height: 8),
                  if (item.sessionType != null)
                    Text('Session Type: ${item.sessionType!.label}'),
                  if (item.runDuration != null)
                    Text('Duration: ${_formatDuration(item.runDuration!)}'),
                  if (item.routePointCount != null)
                    Text('Route Points: ${item.routePointCount}'),
                  const SizedBox(height: 8),
                  Text(timestamp),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title ?? 'Untitled Post',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('By ${item.authorName} • ${item.authorRole}'),
                  Text('${item.branchName} • ${item.divisionName}'),
                  const SizedBox(height: 8),
                  Text(item.description ?? ''),
                  const SizedBox(height: 8),
                  Text(timestamp),
                ],
              ),
      ),
    );
  }
}