import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../shared/providers/user_provider.dart';
import '../../../shared/services/feed_service.dart';
import '../../../shared/utils/static_map_helper.dart';
import 'feed_detail_page.dart';

class FeedItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onChanged;

  const FeedItemCard({
    super.key,
    required this.item,
    this.onChanged,
  });

  @override
  State<FeedItemCard> createState() => _FeedItemCardState();
}

class _FeedItemCardState extends State<FeedItemCard> {
  bool _isLiked = false;
  int _reactionCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncLikeState();
  }

  @override
  void didUpdateWidget(FeedItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncLikeState();
  }

  void _syncLikeState() {
    final user = UserProvider.of(context);
    final reactions =
        List<Map<String, dynamic>>.from(widget.item['feed_reactions'] ?? []);
    _isLiked = reactions.any((r) => r['user_id'] == user.id);
    _reactionCount = reactions.length;
  }

  String _formatDuration(int seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get _itemType => widget.item['type'] as String? ?? 'post';

  String get _authorName =>
      widget.item['profiles']?['full_name'] as String? ?? 'Unknown';

  String get _authorRole =>
      widget.item['profiles']?['role'] as String? ?? '';

  String get _branchName =>
      widget.item['branches']?['name'] as String? ?? '';

  String get _divisionName =>
      widget.item['branches']?['divisions']?['name'] as String? ?? '';

  DateTime get _createdAt =>
      DateTime.parse(widget.item['created_at'] as String);

  List<Map<String, dynamic>> get _topLevelComments {
    final comments = List<Map<String, dynamic>>.from(
        widget.item['feed_comments'] ?? []);
    return comments
        .where((c) => c['parent_comment_id'] == null)
        .toList();
  }

  List<LatLng> get _routePoints {
    final session = widget.item['sessions'];
    if (session == null) return [];
    final points =
        List<Map<String, dynamic>>.from(session['route_points'] ?? []);
    return points
        .map((p) => LatLng(p['lat'] as double, p['lng'] as double))
        .toList();
  }

  Future<void> _toggleLike() async {
    final user = UserProvider.of(context);
    final feedItemId = widget.item['id'] as String;
    final wasLiked = _isLiked;

    setState(() {
      _isLiked = !wasLiked;
      _reactionCount += wasLiked ? -1 : 1;
    });

    try {
      await FeedService.toggleReaction(
        feedItemId: feedItemId,
        userId: user.id,
        isLiked: wasLiked,
      );
    } catch (e) {
      setState(() {
        _isLiked = wasLiked;
        _reactionCount += wasLiked ? 1 : -1;
      });
    }

    widget.onChanged?.call();
  }

  Future<void> _openDetails(BuildContext context) async {
    final user = UserProvider.of(context);
    
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProvider(
          profile: user,
          child: FeedDetailPage(
            itemId: widget.item['id'] as String,
          ),
        ),
      ),
    );

    if (!mounted) return;
    widget.onChanged?.call();
  }

  Widget _buildRunCover() {
    final photos = List<Map<String, dynamic>>.from(
        widget.item['feed_photos'] ?? []);

    if (photos.isNotEmpty) {
      final url =
          FeedService.getPhotoUrl(photos.first['storage_path'] as String);
      return Image.network(
        url,
        width: double.infinity,
        height: 190,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _mapFallback(),
      );
    }

    final points = _routePoints;
    if (points.isNotEmpty) {
      final url = StaticMapHelper.buildRunSnapshotUrl(
        points,
        width: 800,
        height: 380,
      );
      return Image.network(
        url,
        width: double.infinity,
        height: 190,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _mapFallback(),
      );
    }

    return _mapFallback();
  }

  Widget _mapFallback() {
    return Container(
      height: 190,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Text('No run preview available'),
    );
  }

  Widget _buildPostCover() {
    final photos = List<Map<String, dynamic>>.from(
        widget.item['feed_photos'] ?? []);

    if (photos.isNotEmpty) {
      final url =
          FeedService.getPhotoUrl(photos.first['storage_path'] as String);
      return Image.network(
        url,
        width: double.infinity,
        height: 190,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 190,
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const Text('No photo attached'),
        ),
      );
    }

    return Container(
      height: 190,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Text('No photo attached'),
    );
  }

  Widget _buildCommentPreview(Map<String, dynamic> comment) {
    final authorName =
        comment['profiles']?['full_name'] as String? ?? 'Unknown';
    final text = comment['text'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$authorName ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: text),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = DateFormat.yMd().add_jm().format(_createdAt);
    final previewComments = _topLevelComments.take(3).toList();
    final session = widget.item['sessions'];
    final durationSeconds = session?['duration_seconds'] as int?;
    final sessionType = session?['session_type'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDetails(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: _itemType == 'run'
                  ? _buildRunCover()
                  : _buildPostCover(),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _itemType == 'run'
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_authorName logged a run',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('$_branchName • $_divisionName'),
                        Text('Role: $_authorRole'),
                        const SizedBox(height: 8),
                        if (sessionType != null)
                          Text('Session Type: $sessionType'),
                        if (durationSeconds != null)
                          Text(
                              'Duration: ${_formatDuration(durationSeconds)}'),
                        const SizedBox(height: 8),
                        Text(timestamp),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item['title'] as String? ?? 'Untitled Post',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('By $_authorName • $_authorRole'),
                        Text('$_branchName • $_divisionName'),
                        const SizedBox(height: 8),
                        Text(
                          widget.item['description'] as String? ?? '',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(timestamp),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _toggleLike,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 4),
                      child: Row(
                        children: [
                          Icon(
                            _isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 20,
                            color: _isLiked ? Colors.red : null,
                          ),
                          const SizedBox(width: 6),
                          Text('$_reactionCount'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _openDetails(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.mode_comment_outlined, size: 20),
                          const SizedBox(width: 6),
                          Text('${_topLevelComments.length}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (previewComments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      previewComments.map(_buildCommentPreview).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}