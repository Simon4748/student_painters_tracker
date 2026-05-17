import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../shared/providers/user_provider.dart';
import '../../../shared/services/feed_service.dart';
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
  final TextEditingController _commentController = TextEditingController();
  String? _replyingToCommentId;
  String? _replyingToName;

  Map<String, dynamic>? _item;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadItem() async {
    setState(() => _isLoading = true);
    try {
      final items = await FeedService.fetchFeedItemById(widget.itemId);
      if (!mounted) return;
      setState(() {
        _item = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _formatDuration(int seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  bool get _isLikedByCurrentUser {
    final user = UserProvider.of(context);
    final reactions = List<Map<String, dynamic>>.from(
        _item?['feed_reactions'] ?? []);
    return reactions.any((r) => r['user_id'] == user.id);
  }

  int get _reactionCount {
    return (_item?['feed_reactions'] as List?)?.length ?? 0;
  }

  List<Map<String, dynamic>> get _topLevelComments {
    final comments = List<Map<String, dynamic>>.from(
        _item?['feed_comments'] ?? []);
    return comments
        .where((c) => c['parent_comment_id'] == null)
        .toList();
  }

  List<Map<String, dynamic>> _repliesFor(String parentId) {
    final comments = List<Map<String, dynamic>>.from(
        _item?['feed_comments'] ?? []);
    return comments
        .where((c) => c['parent_comment_id'] == parentId)
        .toList();
  }

  List<LatLng> get _routePoints {
    final session = _item?['sessions'];
    if (session == null) return [];
    final points =
        List<Map<String, dynamic>>.from(session['route_points'] ?? []);
    return points
        .map((p) => LatLng(p['lat'] as double, p['lng'] as double))
        .toList();
  }

  Future<void> _toggleLike() async {
    if (_item == null) return;
    final user = UserProvider.of(context);
    final isLiked = _isLikedByCurrentUser;

    try {
      await FeedService.toggleReaction(
        feedItemId: widget.itemId,
        userId: user.id,
        isLiked: isLiked,
      );
      await _loadItem();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update reaction: $e')),
      );
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    final user = UserProvider.of(context);

    setState(() => _isSubmitting = true);

    try {
      await FeedService.addComment(
        feedItemId: widget.itemId,
        authorId: user.id,
        text: text,
        parentCommentId: _replyingToCommentId,
      );

      _commentController.clear();
      _replyingToCommentId = null;
      _replyingToName = null;

      await _loadItem();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post comment: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
        FocusScope.of(context).unfocus();
      }
    }
  }

  void _startReply(Map<String, dynamic> comment) {
    setState(() {
      _replyingToCommentId = comment['id'] as String;
      _replyingToName =
          comment['profiles']?['full_name'] as String? ?? 'Unknown';
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToName = null;
    });
  }

  Widget _buildRunImage() {
    final photos = List<Map<String, dynamic>>.from(
        _item?['feed_photos'] ?? []);

    if (photos.isNotEmpty) {
      final url =
          FeedService.getPhotoUrl(photos.first['storage_path'] as String);
      return Image.network(
        url,
        width: double.infinity,
        height: 260,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imageFallback(260),
      );
    }

    final points = _routePoints;
    if (points.isNotEmpty) {
      final url = StaticMapHelper.buildRunSnapshotUrl(
        points,
        width: 1200,
        height: 520,
      );
      return Image.network(
        url,
        width: double.infinity,
        height: 260,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imageFallback(260),
      );
    }

    return _imageFallback(260);
  }

  Widget _buildPostImages() {
    final photos = List<Map<String, dynamic>>.from(
        _item?['feed_photos'] ?? []);

    if (photos.isEmpty) return _imageFallback(240);

    if (photos.length == 1) {
      final url =
          FeedService.getPhotoUrl(photos.first['storage_path'] as String);
      return Image.network(
        url,
        width: double.infinity,
        height: 260,
        fit: BoxFit.cover,
      );
    }

    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final url = FeedService.getPhotoUrl(
              photos[index]['storage_path'] as String);
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url,
              width: 260,
              height: 260,
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }

  Widget _imageFallback(double height) {
    return Container(
      height: height,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Text('No image available'),
    );
  }

  Widget _buildCommentTile(Map<String, dynamic> comment) {
    final replies = _repliesFor(comment['id'] as String);
    final authorName =
        comment['profiles']?['full_name'] as String? ?? 'Unknown';
    final authorRole =
        comment['profiles']?['role'] as String? ?? '';
    final text = comment['text'] as String? ?? '';
    final createdAt =
        DateTime.parse(comment['created_at'] as String);

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
                '$authorName • $authorRole',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(text),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    DateFormat.yMd().add_jm().format(createdAt),
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
                final replyAuthor =
                    reply['profiles']?['full_name'] as String? ?? 'Unknown';
                final replyRole =
                    reply['profiles']?['role'] as String? ?? '';
                final replyText = reply['text'] as String? ?? '';
                final replyCreatedAt =
                    DateTime.parse(reply['created_at'] as String);
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
                        '$replyAuthor • $replyRole',
                        style:
                            const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(replyText),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat.yMd().add_jm().format(replyCreatedAt),
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_item == null) {
      return const Scaffold(
        body: Center(child: Text('Post not found')),
      );
    }

    final itemType = _item!['type'] as String? ?? 'post';
    final timestamp =
        DateFormat.yMd().add_jm().format(DateTime.parse(_item!['created_at'] as String));
    final authorName =
        _item!['profiles']?['full_name'] as String? ?? 'Unknown';
    final authorRole = _item!['profiles']?['role'] as String? ?? '';
    final branchName = _item!['branches']?['name'] as String? ?? '';
    final divisionName =
        _item!['branches']?['divisions']?['name'] as String? ?? '';
    final session = _item!['sessions'];
    final durationSeconds = session?['duration_seconds'] as int?;
    final sessionType = session?['session_type'] as String?;
    final topComments = _topLevelComments;

    return Scaffold(
      appBar: AppBar(
        title: Text(itemType == 'run' ? 'Run Details' : 'Post Details'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  itemType == 'run'
                      ? _buildRunImage()
                      : _buildPostImages(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: itemType == 'run'
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$authorName logged a run',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text('$branchName • $divisionName'),
                              Text('Role: $authorRole'),
                              const SizedBox(height: 8),
                              Text('Completed: $timestamp'),
                              const SizedBox(height: 16),
                              if (sessionType != null)
                                Text(
                                  'Session Type: $sessionType',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              const SizedBox(height: 8),
                              if (durationSeconds != null)
                                Text(
                                    'Duration: ${_formatDuration(durationSeconds)}'),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _item!['title'] as String? ??
                                    'Untitled Post',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text('By $authorName • $authorRole'),
                              Text('$branchName • $divisionName'),
                              const SizedBox(height: 8),
                              Text('Posted: $timestamp'),
                              const SizedBox(height: 16),
                              Text(
                                _item!['description'] as String? ?? '',
                                style:
                                    Theme.of(context).textTheme.bodyLarge,
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
                            _isLikedByCurrentUser
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color:
                                _isLikedByCurrentUser ? Colors.red : null,
                          ),
                        ),
                        Text('$_reactionCount'),
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
                        children:
                            topComments.map(_buildCommentTile).toList(),
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
                        onPressed: _isSubmitting ? null : _submitComment,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Text('Send'),
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