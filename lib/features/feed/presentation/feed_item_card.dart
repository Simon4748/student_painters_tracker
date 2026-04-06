import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/feed_comment.dart';
import '../../../shared/models/feed_item.dart';
import '../../../shared/models/feed_reaction.dart';
import '../../../shared/models/feed_store.dart';
import '../../../shared/utils/static_map_helper.dart';
import 'feed_detail_page.dart';

class FeedItemCard extends StatefulWidget {
  final FeedItem item;
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
  final String _currentUserId = 'manager_1';
  final String _currentUserName = 'Simon';

  FeedItem get _item =>
      FeedStore.items.firstWhere((element) => element.id == widget.item.id);

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  bool get _isLikedByCurrentUser {
    return _item.reactions.any((reaction) => reaction.userId == _currentUserId);
  }

  List<FeedComment> get _topLevelComments {
    return _item.comments.where((comment) => !comment.isReply).toList();
  }

  void _toggleLike() {
    final index = FeedStore.items.indexWhere((item) => item.id == _item.id);
    if (index == -1) return;

    final current = FeedStore.items[index];
    final alreadyLiked = current.reactions.any((r) => r.userId == _currentUserId);

    final updatedReactions = List<FeedReaction>.from(current.reactions);

    if (alreadyLiked) {
      updatedReactions.removeWhere((reaction) => reaction.userId == _currentUserId);
    } else {
      updatedReactions.add(
        FeedReaction(
          userId: _currentUserId,
          userName: _currentUserName,
        ),
      );
    }

    FeedStore.items[index] = FeedItem(
      id: current.id,
      type: current.type,
      authorId: current.authorId,
      authorName: current.authorName,
      authorRole: current.authorRole,
      branchId: current.branchId,
      branchName: current.branchName,
      divisionName: current.divisionName,
      createdAt: current.createdAt,
      sessionType: current.sessionType,
      runDuration: current.runDuration,
      routePointCount: current.routePointCount,
      routePoints: current.routePoints,
      coverPhotoBytes: current.coverPhotoBytes,
      title: current.title,
      description: current.description,
      imageBytesList: current.imageBytesList,
      reactions: updatedReactions,
      comments: current.comments,
    );

    setState(() {});
    widget.onChanged?.call();
  }

  Future<void> _openDetails(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FeedDetailPage(itemId: _item.id),
      ),
    );

    if (!mounted) return;
    setState(() {});
    widget.onChanged?.call();
  }

  Widget _buildRunCover() {
    if (_item.coverPhotoBytes != null) {
      return Image.memory(
        _item.coverPhotoBytes!,
        width: double.infinity,
        height: 190,
        fit: BoxFit.cover,
      );
    }

    if (_item.routePoints != null && _item.routePoints!.isNotEmpty) {
      final url = StaticMapHelper.buildRunSnapshotUrl(
        _item.routePoints!,
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
    if (_item.imageBytesList != null && _item.imageBytesList!.isNotEmpty) {
      return Image.memory(
        _item.imageBytesList!.first,
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

  Widget _buildCommentPreview(FeedComment comment) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '${comment.authorName} ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: comment.text),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = DateFormat.yMd().add_jm().format(_item.createdAt);
    final previewComments = _topLevelComments.take(3).toList();

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
              child: _item.type == FeedItemType.run
                  ? _buildRunCover()
                  : _buildPostCover(),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _item.type == FeedItemType.run
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_item.authorName} logged a run',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('${_item.branchName} • ${_item.divisionName}'),
                        Text('Role: ${_item.authorRole}'),
                        const SizedBox(height: 8),
                        if (_item.sessionType != null)
                          Text('Session Type: ${_item.sessionType!.label}'),
                        if (_item.runDuration != null)
                          Text('Duration: ${_formatDuration(_item.runDuration!)}'),
                        if (_item.routePointCount != null)
                          Text('Route Points: ${_item.routePointCount}'),
                        const SizedBox(height: 8),
                        Text(timestamp),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _item.title ?? 'Untitled Post',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('By ${_item.authorName} • ${_item.authorRole}'),
                        Text('${_item.branchName} • ${_item.divisionName}'),
                        const SizedBox(height: 8),
                        Text(
                          _item.description ?? '',
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
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Row(
                        children: [
                          Icon(
                            _isLikedByCurrentUser ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                            color: _isLikedByCurrentUser ? Colors.red : null,
                          ),
                          const SizedBox(width: 6),
                          Text('${_item.reactions.length}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _openDetails(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
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
                  children: previewComments.map(_buildCommentPreview).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}