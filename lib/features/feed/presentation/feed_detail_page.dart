import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/feed_comment.dart';
import '../../../shared/models/feed_item.dart';
import '../../../shared/models/feed_reaction.dart';
import '../../../shared/models/feed_store.dart';
import '../../../shared/utils/static_map_helper.dart';

class FeedDetailPage extends StatefulWidget {
  final String itemId;

  const FeedDetailPage({
    super.key,
    required this.itemId,
  });

  @override
  State<FeedDetailPage> createState() => _FeedDetailPageState();
}

class _FeedDetailPageState extends State<FeedDetailPage> {
  final String _currentUserId = 'manager_1';
  final String _currentUserName = 'Simon';
  final String _currentUserRole = 'Branch Manager';

  final TextEditingController _commentController = TextEditingController();
  String? _replyingToCommentId;
  String? _replyingToName;

  FeedItem get _item =>
      FeedStore.items.firstWhere((element) => element.id == widget.itemId);

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  bool get _isLikedByCurrentUser {
    return _item.reactions.any((reaction) => reaction.userId == _currentUserId);
  }

  void _toggleLike() {
    final index = FeedStore.items.indexWhere((item) => item.id == widget.itemId);
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
  }

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final index = FeedStore.items.indexWhere((item) => item.id == widget.itemId);
    if (index == -1) return;

    final current = FeedStore.items[index];
    final updatedComments = List<FeedComment>.from(current.comments);

    updatedComments.add(
      FeedComment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        feedItemId: current.id,
        authorId: _currentUserId,
        authorName: _currentUserName,
        authorRole: _currentUserRole,
        text: text,
        createdAt: DateTime.now(),
        parentCommentId: _replyingToCommentId,
      ),
    );

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
      reactions: current.reactions,
      comments: updatedComments,
    );

    _commentController.clear();
    _replyingToCommentId = null;
    _replyingToName = null;

    setState(() {});
    FocusScope.of(context).unfocus();
  }

  void _startReply(FeedComment comment) {
    setState(() {
      _replyingToCommentId = comment.id;
      _replyingToName = comment.authorName;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToName = null;
    });
  }

  List<FeedComment> _topLevelComments() {
    return _item.comments.where((comment) => !comment.isReply).toList();
  }

  List<FeedComment> _repliesFor(String parentCommentId) {
    return _item.comments
        .where((comment) => comment.parentCommentId == parentCommentId)
        .toList();
  }

  Widget _buildRunImage() {
    if (_item.coverPhotoBytes != null) {
      return Image.memory(
        _item.coverPhotoBytes!,
        width: double.infinity,
        height: 260,
        fit: BoxFit.cover,
      );
    }

    if (_item.routePoints != null && _item.routePoints!.isNotEmpty) {
      final url = StaticMapHelper.buildRunSnapshotUrl(
        _item.routePoints!,
        width: 1200,
        height: 520,
      );

      return Image.network(
        url,
        width: double.infinity,
        height: 260,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 260,
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const Text('Run snapshot unavailable'),
        ),
      );
    }

    return Container(
      height: 260,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Text('No run image available'),
    );
  }

  Widget _buildPostImages() {
    final images = _item.imageBytesList ?? const [];

    if (images.isEmpty) {
      return Container(
        height: 240,
        width: double.infinity,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Text('No photos attached'),
      );
    }

    if (images.length == 1) {
      return Image.memory(
        images.first,
        width: double.infinity,
        height: 260,
        fit: BoxFit.cover,
      );
    }

    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              images[index],
              width: 260,
              height: 260,
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommentTile(FeedComment comment) {
    final replies = _repliesFor(comment.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${comment.authorName} • ${comment.authorRole}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(comment.text),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    DateFormat.yMd().add_jm().format(comment.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _startReply(comment),
                    child: Text(
                      'Reply',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              children: replies.map((reply) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${reply.authorName} • ${reply.authorRole}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(reply.text),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat.yMd().add_jm().format(reply.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = DateFormat.yMd().add_jm().format(_item.createdAt);
    final topComments = _topLevelComments();

    return Scaffold(
      appBar: AppBar(
        title: Text(_item.type == FeedItemType.run ? 'Run Details' : 'Post Details'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _item.type == FeedItemType.run ? _buildRunImage() : _buildPostImages(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _item.type == FeedItemType.run
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_item.authorName} logged a run',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text('${_item.branchName} • ${_item.divisionName}'),
                              Text('Role: ${_item.authorRole}'),
                              const SizedBox(height: 8),
                              Text('Completed: $timestamp'),
                              const SizedBox(height: 16),
                              if (_item.sessionType != null)
                                Text(
                                  'Session Type: ${_item.sessionType!.label}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              const SizedBox(height: 8),
                              if (_item.runDuration != null)
                                Text('Duration: ${_formatDuration(_item.runDuration!)}'),
                              if (_item.routePointCount != null)
                                Text('Route Points: ${_item.routePointCount}'),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _item.title ?? 'Untitled Post',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text('By ${_item.authorName} • ${_item.authorRole}'),
                              Text('${_item.branchName} • ${_item.divisionName}'),
                              const SizedBox(height: 8),
                              Text('Posted: $timestamp'),
                              const SizedBox(height: 16),
                              Text(
                                _item.description ?? '',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _toggleLike,
                          icon: Icon(
                            _isLikedByCurrentUser ? Icons.favorite : Icons.favorite_border,
                            color: _isLikedByCurrentUser ? Colors.red : null,
                          ),
                        ),
                        Text('${_item.reactions.length}'),
                        const SizedBox(width: 16),
                        const Icon(Icons.mode_comment_outlined),
                        const SizedBox(width: 6),
                        Text('${topComments.length}'),
                      ],
                    ),
                  ),
                  const Divider(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Comments',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (topComments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('No comments yet'),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: topComments.map(_buildCommentTile).toList(),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_replyingToCommentId != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('Replying to $_replyingToName'),
                          ),
                          TextButton(
                            onPressed: _cancelReply,
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: _replyingToCommentId == null
                                ? 'Add a comment...'
                                : 'Write a reply...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _submitComment,
                        child: const Text('Send'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}