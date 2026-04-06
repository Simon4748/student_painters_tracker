import 'dart:typed_data';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../features/sessions/domain/session_type.dart';

import 'feed_comment.dart';
import 'feed_reaction.dart';

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

  // Run-specific
  final SessionType? sessionType;
  final Duration? runDuration;
  final int? routePointCount;
  final List<LatLng>? routePoints;
  final Uint8List? coverPhotoBytes;

  // Manual post-specific
  final String? title;
  final String? description;
  final List<Uint8List>? imageBytesList;

  final List<FeedReaction> reactions;
  final List<FeedComment> comments;

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
    this.routePoints,
    this.coverPhotoBytes,
    this.title,
    this.description,
    this.imageBytesList,
    this.reactions = const [],
    this.comments = const [],
  });
}