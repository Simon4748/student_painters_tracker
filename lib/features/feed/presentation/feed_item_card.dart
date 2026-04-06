import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/feed_item.dart';
import '../../../shared/utils/static_map_helper.dart';
import 'feed_detail_page.dart';

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

  void _openDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FeedDetailPage(itemId: item.id),
      ),
    );
  }

  Widget _buildRunCover() {
    if (item.coverPhotoBytes != null) {
      return Image.memory(
        item.coverPhotoBytes!,
        width: double.infinity,
        height: 190,
        fit: BoxFit.cover,
      );
    }

    if (item.routePoints != null && item.routePoints!.isNotEmpty) {
      final url = StaticMapHelper.buildRunSnapshotUrl(
        item.routePoints!,
        width: 800,
        height: 380,
      );

      return Image.network(
        url,
        width: double.infinity,
        height: 190,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 190,
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const Text('Run map preview unavailable'),
        ),
      );
    }

    return Container(
      height: 190,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Text('No run preview available'),
    );
  }

  Widget _buildPostCover() {
    if (item.imageBytesList != null && item.imageBytesList!.isNotEmpty) {
      return Image.memory(
        item.imageBytesList!.first,
        width: double.infinity,
        height: 190,
        fit: BoxFit.cover,
      );
    }

    return Container(
      height: 190,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Text('No photo attached'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = DateFormat.yMd().add_jm().format(item.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDetails(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: item.type == FeedItemType.run
                  ? _buildRunCover()
                  : _buildPostCover(),
            ),
            Padding(
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
                        Text(
                          item.description ?? '',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(timestamp),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  const Icon(Icons.favorite_border, size: 20),
                  const SizedBox(width: 6),
                  Text('${item.reactions.length}'),
                  const SizedBox(width: 20),
                  const Icon(Icons.mode_comment_outlined, size: 20),
                  const SizedBox(width: 6),
                  Text('${item.comments.where((c) => !c.isReply).length}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}