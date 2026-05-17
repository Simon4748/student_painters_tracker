import 'package:supabase_flutter/supabase_flutter.dart';

class FeedService {
  static final _client = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> fetchFeedForBranch(
      String branchId) async {
    final data = await _client
        .from('feed_items')
        .select('''
          id,
          type,
          title,
          description,
          created_at,
          branch_id,
          session_id,
          profiles (
            id,
            full_name,
            role,
            color
          ),
          branches (
            id,
            name,
            divisions (
              name
            )
          ),
          sessions (
            session_type,
            duration_seconds,
            distance_miles,
            route_points
          ),
          feed_reactions (
            id,
            user_id
          ),
          feed_comments (
            id,
            text,
            author_id,
            parent_comment_id,
            created_at,
            profiles (
              full_name,
              role
            )
          ),
          feed_photos (
            id,
            storage_path
          )
        ''')
        .eq('branch_id', branchId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> toggleReaction({
    required String feedItemId,
    required String userId,
    required bool isLiked,
  }) async {
    if (isLiked) {
      await _client
          .from('feed_reactions')
          .delete()
          .eq('feed_item_id', feedItemId)
          .eq('user_id', userId);
    } else {
      await _client.from('feed_reactions').insert({
        'feed_item_id': feedItemId,
        'user_id': userId,
      });
    }
  }

  static Future<void> addComment({
    required String feedItemId,
    required String authorId,
    required String text,
    String? parentCommentId,
  }) async {
    await _client.from('feed_comments').insert({
      'feed_item_id': feedItemId,
      'author_id': authorId,
      'text': text,
      'parent_comment_id': parentCommentId,
    });
  }

  static Future<void> createPost({
    required String authorId,
    required String branchId,
    required String title,
    required String description,
  }) async {
    await _client.from('feed_items').insert({
      'type': 'post',
      'author_id': authorId,
      'branch_id': branchId,
      'title': title,
      'description': description,
    });
  }

  static String getPhotoUrl(String storagePath) {
    return _client.storage.from('photos').getPublicUrl(storagePath);
  }

  static Future<Map<String, dynamic>> fetchFeedItemById(String id) async {
    final data = await _client
        .from('feed_items')
        .select('''
          id,
          type,
          title,
          description,
          created_at,
          branch_id,
          session_id,
          profiles (
            id,
            full_name,
            role,
            color
          ),
          branches (
            id,
            name,
            divisions (
              name
            )
          ),
          sessions (
            session_type,
            duration_seconds,
            distance_miles,
            route_points
          ),
          feed_reactions (
            id,
            user_id
          ),
          feed_comments (
            id,
            text,
            author_id,
            parent_comment_id,
            created_at,
            profiles (
              full_name,
              role
            )
          ),
          feed_photos (
            id,
            storage_path
          )
        ''')
        .eq('id', id)
        .single();

    return Map<String, dynamic>.from(data);
  }
}