import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

import '../../features/sessions/domain/session_type.dart';

class SessionService {
  static final _client = Supabase.instance.client;

  static String _sessionTypeToDb(SessionType type) {
    switch (type) {
      case SessionType.doorToDoor:
        return 'door_to_door';
      case SessionType.flyerRun:
        return 'flyer_run';
      case SessionType.nowHiringFlyers:
        return 'now_hiring_flyers';
      case SessionType.other:
        return 'other';
    }
  }

  static Future<void> saveSession({
    required String userId,
    required String branchId,
    required SessionType sessionType,
    required int durationSeconds,
    required double distanceMiles,
    required List<LatLng> routePoints,
    required String title,
    required String description,
    required List<Uint8List> photos,
  }) async {
    final routeJson = routePoints
        .map((p) => {'lat': p.latitude, 'lng': p.longitude})
        .toList();

    // insert session
    final sessionResponse = await _client
        .from('sessions')
        .insert({
          'user_id': userId,
          'branch_id': branchId,
          'session_type': _sessionTypeToDb(sessionType),
          'duration_seconds': durationSeconds,
          'distance_miles': distanceMiles,
          'route_points': routeJson,
          'completed_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();

    final sessionId = sessionResponse['id'] as String;

    // insert feed item
    final feedResponse = await _client
        .from('feed_items')
        .insert({
          'type': 'run',
          'author_id': userId,
          'branch_id': branchId,
          'session_id': sessionId,
          'title': title.isEmpty ? null : title,
          'description': description.isEmpty ? null : description,
        })
        .select('id')
        .single();

    final feedItemId = feedResponse['id'] as String;

    // upload photos if any
    if (photos.isNotEmpty) {
      for (int i = 0; i < photos.length; i++) {
        final path = 'feed/$feedItemId/$i.jpg';
        await _client.storage
            .from('photos')
            .uploadBinary(path, photos[i]);

        await _client.from('feed_photos').insert({
          'feed_item_id': feedItemId,
          'storage_path': path,
        });
      }
    }
  }

  static Future<List<Map<String, dynamic>>> fetchSessionsForBranch(
      String branchId) async {
    final data = await _client
        .from('sessions')
        .select('''
          id,
          session_type,
          duration_seconds,
          distance_miles,
          route_points,
          completed_at,
          profiles (
            id,
            full_name,
            role,
            color
          )
        ''')
        .eq('branch_id', branchId)
        .order('completed_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }
}