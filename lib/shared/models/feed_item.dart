import '../../features/sessions/domain/session_type.dart';

enum FeedItemType {
  run,
  post,
}

class FeedItem {
  final String id;
  final FeedItemType type;

  final String authorId;
  final String authorName;
  final String authorRole;

  final String branchId;
  final String branchName;
  final String divisionName;

  final DateTime createdAt;

  // Run specific
  final SessionType? sessionType;
  final Duration? runDuration;
  final int? routePointCount;

  // Manual post specific
  final String? title;
  final String? description;
  final List<String>? imagePaths;

  const FeedItem({
    required this.id,
    required this.type,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.branchId,
    required this.branchName,
    required this.divisionName,
    required this.createdAt,
    this.sessionType,
    this.runDuration,
    this.routePointCount,
    this.title,
    this.description,
    this.imagePaths,
  });
}