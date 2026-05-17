import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/coverage/domain/coverage_models.dart';
import '../../features/sessions/domain/session_type.dart';

class CoverageService {
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

  static ZoneCoverageStatus _statusFromDb(String status) {
    switch (status) {
      case 'full':
        return ZoneCoverageStatus.full;
      case 'partial':
        return ZoneCoverageStatus.partial;
      default:
        return ZoneCoverageStatus.uncovered;
    }
  }

  static String _statusToDb(ZoneCoverageStatus status) {
    switch (status) {
      case ZoneCoverageStatus.full:
        return 'full';
      case ZoneCoverageStatus.partial:
        return 'partial';
      case ZoneCoverageStatus.uncovered:
        return 'uncovered';
    }
  }

  static List<LatLng> _pointsFromJson(List<dynamic> json) {
    return json
        .map((p) => LatLng(p['lat'] as double, p['lng'] as double))
        .toList();
  }

  static List<Map<String, dynamic>> _pointsToJson(List<LatLng> points) {
    return points
        .map((p) => {'lat': p.latitude, 'lng': p.longitude})
        .toList();
  }

  static Future<List<TerritoryZone>> fetchZones(String branchId) async {
    final data = await _client
        .from('zones')
        .select('id, name, branch_id, points')
        .eq('branch_id', branchId);

    return List<Map<String, dynamic>>.from(data).map((z) {
      return TerritoryZone(
        id: z['id'] as String,
        name: z['name'] as String,
        branchId: z['branch_id'] as String,
        points: _pointsFromJson(z['points'] as List),
      );
    }).toList();
  }

  static Future<List<TerritorySubzone>> fetchSubzones(String branchId) async {
    final data = await _client
        .from('subzones')
        .select('id, name, branch_id, zone_id, points, status, manual_override')
        .eq('branch_id', branchId);

    return List<Map<String, dynamic>>.from(data).map((s) {
      return TerritorySubzone(
        id: s['id'] as String,
        name: s['name'] as String,
        branchId: s['branch_id'] as String,
        points: _pointsFromJson(s['points'] as List),
        status: _statusFromDb(s['status'] as String),
        manualOverride: s['manual_override'] as bool,
      );
    }).toList();
  }

  static Future<List<BranchMember>> fetchMembers(String branchId) async {
    final data = await _client
        .from('profiles')
        .select('id, full_name, role, branch_id, color')
        .eq('branch_id', branchId);

    return List<Map<String, dynamic>>.from(data).map((m) {
      final colorHex = m['color'] as String;
      final color = Color(
          int.parse(colorHex.replaceFirst('#', '0xFF')));
      return BranchMember(
        id: m['id'] as String,
        name: m['full_name'] as String,
        role: _roleFromDb(m['role'] as String),
        branchId: m['branch_id'] as String,
        color: color,
      );
    }).toList();
  }

  static UserRole _roleFromDb(String role) {
    switch (role) {
      case 'branch_manager':
        return UserRole.branchManager;
      case 'general_manager':
        return UserRole.generalManager;
      case 'executive':
        return UserRole.executive;
      default:
        return UserRole.marketer;
    }
  }

  static Future<List<CoverageRun>> fetchRuns(String branchId) async {
    final data = await _client
        .from('sessions')
        .select('id, user_id, branch_id, session_type, route_points')
        .eq('branch_id', branchId);

    return List<Map<String, dynamic>>.from(data).map((r) {
      return CoverageRun(
        id: r['id'] as String,
        memberId: r['user_id'] as String,
        branchId: r['branch_id'] as String,
        type: _sessionTypeFromDb(r['session_type'] as String),
        routePoints: _pointsFromJson(r['route_points'] as List),
      );
    }).toList();
  }

  static Future<TerritoryZone> createZone({
    required String name,
    required String branchId,
    required List<LatLng> points,
  }) async {
    final data = await _client.from('zones').insert({
      'name': name,
      'branch_id': branchId,
      'points': _pointsToJson(points),
    }).select('id, name, branch_id, points').single();

    return TerritoryZone(
      id: data['id'] as String,
      name: data['name'] as String,
      branchId: data['branch_id'] as String,
      points: _pointsFromJson(data['points'] as List),
    );
  }

  static Future<TerritorySubzone> createSubzone({
    required String name,
    required String branchId,
    required List<LatLng> points,
  }) async {
    final data = await _client.from('subzones').insert({
      'name': name,
      'branch_id': branchId,
      'points': _pointsToJson(points),
      'status': 'uncovered',
      'manual_override': false,
    }).select('id, name, branch_id, zone_id, points, status, manual_override').single();

    return TerritorySubzone(
      id: data['id'] as String,
      name: data['name'] as String,
      branchId: data['branch_id'] as String,
      points: _pointsFromJson(data['points'] as List),
      status: ZoneCoverageStatus.uncovered,
      manualOverride: false,
    );
  }

  static Future<void> updateZone(TerritoryZone zone) async {
    await _client.from('zones').update({
      'name': zone.name,
      'points': _pointsToJson(zone.points),
    }).eq('id', zone.id);
  }

  static Future<void> updateSubzone(TerritorySubzone subzone) async {
    await _client.from('subzones').update({
      'name': subzone.name,
      'points': _pointsToJson(subzone.points),
      'status': _statusToDb(subzone.status),
      'manual_override': subzone.manualOverride,
    }).eq('id', subzone.id);
  }

  static Future<void> deleteZone(String zoneId) async {
    await _client.from('zones').delete().eq('id', zoneId);
  }

  static Future<void> deleteSubzone(String subzoneId) async {
    await _client.from('subzones').delete().eq('id', subzoneId);
  }

  static Future<void> deleteAllZones(String branchId) async {
    await _client.from('subzones').delete().eq('branch_id', branchId);
    await _client.from('zones').delete().eq('branch_id', branchId);
  }
}