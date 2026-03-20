import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../sessions/domain/session_type.dart';

enum UserRole {
  marketer,
  branchManager,
  generalManager,
  executive,
}

enum ZoneCoverageStatus {
  uncovered,
  partial,
  full,
}

class BranchMember {
  final String id;
  final String name;
  final UserRole role;
  final String branchId;
  final Color color;

  const BranchMember({
    required this.id,
    required this.name,
    required this.role,
    required this.branchId,
    required this.color,
  });
}

class TerritoryZone {
  final String id;
  final String name;
  final String branchId;
  final List<LatLng> points;

  const TerritoryZone({
    required this.id,
    required this.name,
    required this.branchId,
    required this.points,
  });
}

class TerritorySubzone {
  final String id;
  final String name;
  final String branchId;
  final List<LatLng> points;
  final ZoneCoverageStatus status;
  final bool manualOverride;

  const TerritorySubzone({
    required this.id,
    required this.name,
    required this.branchId,
    required this.points,
    required this.status,
    this.manualOverride = false,
  });
}

class CoverageRun {
  final String id;
  final String memberId;
  final String branchId;
  final SessionType type;
  final List<LatLng> routePoints;

  const CoverageRun({
    required this.id,
    required this.memberId,
    required this.branchId,
    required this.type,
    required this.routePoints,
  });
}