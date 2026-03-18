import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../domain/coverage_models.dart';
import '../../sessions/domain/session_type.dart';

class CoverageDemoData {
  static const String branchId = 'brattleboro_branch';

  static const String branchTitle = 'Brattleboro Branch';

  static const List<BranchMember> members = [
    BranchMember(
      id: 'manager_1',
      name: 'Simon',
      role: UserRole.branchManager,
      branchId: branchId,
      color: Colors.blue,
    ),
    BranchMember(
      id: 'marketer_1',
      name: 'Alex',
      role: UserRole.marketer,
      branchId: branchId,
      color: Colors.red,
    ),
    BranchMember(
      id: 'marketer_2',
      name: 'Jordan',
      role: UserRole.marketer,
      branchId: branchId,
      color: Colors.green,
    ),
  ];

  static final List<TerritoryZone> zones = [
    TerritoryZone(
      id: 'zone_west_brattleboro',
      name: 'West Brattleboro',
      branchId: branchId,
      points: const [
        LatLng(42.8350, -72.6200),
        LatLng(42.8350, -72.5400),
        LatLng(42.7900, -72.5400),
        LatLng(42.7900, -72.6200),
      ],
    ),
    TerritoryZone(
      id: 'zone_east_brattleboro',
      name: 'East Brattleboro',
      branchId: branchId,
      points: const [
        LatLng(42.8350, -72.5400),
        LatLng(42.8350, -72.4700),
        LatLng(42.7900, -72.4700),
        LatLng(42.7900, -72.5400),
      ],
    ),
  ];

  static final List<TerritorySubzone> subzones = [
    TerritorySubzone(
      id: 'subzone_1a',
      zoneId: 'zone_west_brattleboro',
      name: '1A',
      branchId: branchId,
      status: ZoneCoverageStatus.uncovered,
      points: const [
        LatLng(42.8170, -72.5850),
        LatLng(42.8170, -72.5650),
        LatLng(42.8040, -72.5650),
        LatLng(42.8040, -72.5850),
      ],
    ),
    TerritorySubzone(
      id: 'subzone_1b',
      zoneId: 'zone_west_brattleboro',
      name: '1B',
      branchId: branchId,
      status: ZoneCoverageStatus.partial,
      points: const [
        LatLng(42.8040, -72.5850),
        LatLng(42.8040, -72.5650),
        LatLng(42.7920, -72.5650),
        LatLng(42.7920, -72.5850),
      ],
    ),
    TerritorySubzone(
      id: 'subzone_1c',
      zoneId: 'zone_east_brattleboro',
      name: '1C',
      branchId: branchId,
      status: ZoneCoverageStatus.full,
      points: const [
        LatLng(42.8120, -72.5200),
        LatLng(42.8120, -72.4980),
        LatLng(42.7980, -72.4980),
        LatLng(42.7980, -72.5200),
      ],
    ),
  ];

  static final List<CoverageRun> runs = [
    CoverageRun(
      id: 'run_1',
      memberId: 'manager_1',
      branchId: branchId,
      type: SessionType.doorToDoor,
      routePoints: const [
        LatLng(42.8090, -72.5800),
        LatLng(42.8110, -72.5760),
        LatLng(42.8130, -72.5720),
      ],
    ),
    CoverageRun(
      id: 'run_2',
      memberId: 'marketer_1',
      branchId: branchId,
      type: SessionType.flyerRun,
      routePoints: const [
        LatLng(42.8000, -72.5800),
        LatLng(42.7990, -72.5750),
        LatLng(42.7980, -72.5700),
      ],
    ),
    CoverageRun(
      id: 'run_3',
      memberId: 'marketer_2',
      branchId: branchId,
      type: SessionType.doorToDoor,
      routePoints: const [
        LatLng(42.8080, -72.5150),
        LatLng(42.8050, -72.5100),
        LatLng(42.8020, -72.5050),
      ],
    ),
  ];
}