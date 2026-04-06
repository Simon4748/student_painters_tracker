class FeedComment {
  final String id;
  final String feedItemId;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String text;
  final DateTime createdAt;
  final String? parentCommentId;

  const FeedComment({
    required this.id,
    required this.feedItemId,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.text,
    required this.createdAt,
    this.parentCommentId,
  });

  bool get isReply => parentCommentId != null;
}