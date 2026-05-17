import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/sessions/domain/session_type.dart';
import '../../features/stats/domain/stats_models.dart';

class StatsService {
  static final _client = Supabase.instance.client;

  static SessionType _sessionTypeFromDb(String type) {
    switch (type) {
      case 'door_to_door':
        return SessionType.doorToDoor;
      case 'flyer_run':
        return SessionType.flyerRun;
      case 'now_hiring_flyers':
        return SessionType.nowHiringFlyers;
      default:
        return SessionType.other;
    }
  }

  static Future<List<UserStats>> fetchUserStats(String branchId) async {
    final data = await _client
        .from('sessions')
        .select('''
          user_id,
          session_type,
          duration_seconds,
          profiles (
            full_name,
            role,
            branch_id,
            branches (
              name,
              divisions (
                name
              )
            )
          )
        ''')
        .eq('branch_id', branchId);

    final sessions = List<Map<String, dynamic>>.from(data);

    // group by user
    final Map<String, Map<String, dynamic>> userMap = {};
    final Map<String, Map<SessionType, double>> hoursByUser = {};

    for (final session in sessions) {
      final userId = session['user_id'] as String;
      final type = _sessionTypeFromDb(session['session_type'] as String);
      final hours = (session['duration_seconds'] as int) / 3600.0;

      userMap[userId] = session['profiles'] as Map<String, dynamic>;
      hoursByUser[userId] ??= {};
      hoursByUser[userId]![type] =
          (hoursByUser[userId]![type] ?? 0) + hours;
    }

    return userMap.entries.map((entry) {
      final userId = entry.key;
      final profile = entry.value;
      final branch = profile['branches'] as Map<String, dynamic>;
      final division = branch['divisions'] as Map<String, dynamic>;

      return UserStats(
        userId: userId,
        name: profile['full_name'] as String,
        role: profile['role'] as String,
        branchId: profile['branch_id'] as String,
        branchName: branch['name'] as String,
        divisionName: division['name'] as String,
        hoursByType: hoursByUser[userId] ?? {},
      );
    }).toList();
  }

  static Future<List<BranchStats>> fetchBranchStats() async {
    final data = await _client
        .from('sessions')
        .select('''
          branch_id,
          session_type,
          duration_seconds,
          branches (
            name,
            divisions (
              name
            )
          )
        ''');

    final sessions = List<Map<String, dynamic>>.from(data);

    final Map<String, Map<String, dynamic>> branchMap = {};
    final Map<String, Map<SessionType, double>> hoursByBranch = {};

    for (final session in sessions) {
      final branchId = session['branch_id'] as String;
      final type = _sessionTypeFromDb(session['session_type'] as String);
      final hours = (session['duration_seconds'] as int) / 3600.0;

      branchMap[branchId] = session['branches'] as Map<String, dynamic>;
      hoursByBranch[branchId] ??= {};
      hoursByBranch[branchId]![type] =
          (hoursByBranch[branchId]![type] ?? 0) + hours;
    }

    return branchMap.entries.map((entry) {
      final branchId = entry.key;
      final branch = entry.value;
      final division = branch['divisions'] as Map<String, dynamic>;

      return BranchStats(
        branchId: branchId,
        branchName: branch['name'] as String,
        divisionName: division['name'] as String,
        hoursByType: hoursByBranch[branchId] ?? {},
      );
    }).toList();
  }
}