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
      name: '1A',
      branchId: branchId,
      status: ZoneCoverageStatus.full,
      points: const [
        LatLng(42.8350, -72.6200),
        LatLng(42.8350, -72.5800),
        LatLng(42.8125, -72.5800),
        LatLng(42.8125, -72.6200),
      ],
    ),
    TerritorySubzone(
      id: 'subzone_1b',
      name: '1B',
      branchId: branchId,
      status: ZoneCoverageStatus.partial,
      points: const [
        LatLng(42.8350, -72.5800),
        LatLng(42.8350, -72.5400),
        LatLng(42.8125, -72.5400),
        LatLng(42.8125, -72.5800),
      ],
    ),
    TerritorySubzone(
      id: 'subzone_1c',
      name: '1C',
      branchId: branchId,
      status: ZoneCoverageStatus.uncovered,
      points: const [
        LatLng(42.8125, -72.6200),
        LatLng(42.8125, -72.5800),
        LatLng(42.7900, -72.5800),
        LatLng(42.7900, -72.6200),
      ],
    ),
    TerritorySubzone(
      id: 'subzone_1d',
      name: '1D',
      branchId: branchId,
      status: ZoneCoverageStatus.partial,
      points: const [
        LatLng(42.8125, -72.5800),
        LatLng(42.8125, -72.5400),
        LatLng(42.7900, -72.5400),
        LatLng(42.7900, -72.5800),
      ],
    ),
    TerritorySubzone(
      id: 'subzone_2a',
      name: '2A',
      branchId: branchId,
      status: ZoneCoverageStatus.full,
      points: const [
        LatLng(42.8350, -72.5400),
        LatLng(42.8350, -72.5050),
        LatLng(42.8125, -72.5050),
        LatLng(42.8125, -72.5400),
      ],
    ),
    TerritorySubzone(
      id: 'subzone_2b',
      name: '2B',
      branchId: branchId,
      status: ZoneCoverageStatus.uncovered,
      points: const [
        LatLng(42.8350, -72.5050),
        LatLng(42.8350, -72.4700),
        LatLng(42.8125, -72.4700),
        LatLng(42.8125, -72.5050),
      ],
    ),
    TerritorySubzone(
      id: 'subzone_2c',
      name: '2C',
      branchId: branchId,
      status: ZoneCoverageStatus.partial,
      points: const [
        LatLng(42.8125, -72.5400),
        LatLng(42.8125, -72.5050),
        LatLng(42.7900, -72.5050),
        LatLng(42.7900, -72.5400),
      ],
    ),
    TerritorySubzone(
      id: 'subzone_2d',
      name: '2D',
      branchId: branchId,
      status: ZoneCoverageStatus.uncovered,
      points: const [
        LatLng(42.8125, -72.5050),
        LatLng(42.8125, -72.4700),
        LatLng(42.7900, -72.4700),
        LatLng(42.7900, -72.5050),
      ],
    ),
  ];

  static final List<CoverageRun> runs = [
    // Simon - door to door in subzone 1A
    CoverageRun(
      id: 'run_1',
      memberId: 'manager_1',
      branchId: branchId,
      type: SessionType.doorToDoor,
      routePoints: const [
        LatLng(42.8300, -72.6100),
        LatLng(42.8280, -72.6080),
        LatLng(42.8260, -72.6060),
        LatLng(42.8240, -72.6040),
        LatLng(42.8220, -72.6020),
        LatLng(42.8210, -72.6050),
        LatLng(42.8230, -72.6070),
        LatLng(42.8250, -72.6090),
        LatLng(42.8270, -72.6110),
        LatLng(42.8290, -72.6130),
      ],
    ),
    // Simon - flyer run also in 1A
    CoverageRun(
      id: 'run_2',
      memberId: 'manager_1',
      branchId: branchId,
      type: SessionType.flyerRun,
      routePoints: const [
        LatLng(42.8320, -72.5900),
        LatLng(42.8300, -72.5880),
        LatLng(42.8280, -72.5860),
        LatLng(42.8260, -72.5840),
        LatLng(42.8240, -72.5820),
        LatLng(42.8230, -72.5850),
        LatLng(42.8250, -72.5870),
        LatLng(42.8270, -72.5890),
      ],
    ),
    // Alex - door to door in subzone 1B
    CoverageRun(
      id: 'run_3',
      memberId: 'marketer_1',
      branchId: branchId,
      type: SessionType.doorToDoor,
      routePoints: const [
        LatLng(42.8300, -72.5700),
        LatLng(42.8280, -72.5680),
        LatLng(42.8260, -72.5660),
        LatLng(42.8240, -72.5640),
        LatLng(42.8220, -72.5620),
        LatLng(42.8200, -72.5650),
        LatLng(42.8220, -72.5670),
        LatLng(42.8240, -72.5690),
        LatLng(42.8260, -72.5710),
      ],
    ),
    // Alex - flyer run in 1D
    CoverageRun(
      id: 'run_4',
      memberId: 'marketer_1',
      branchId: branchId,
      type: SessionType.flyerRun,
      routePoints: const [
        LatLng(42.8050, -72.5700),
        LatLng(42.8030, -72.5680),
        LatLng(42.8010, -72.5660),
        LatLng(42.7990, -72.5640),
        LatLng(42.7980, -72.5670),
        LatLng(42.8000, -72.5690),
        LatLng(42.8020, -72.5710),
        LatLng(42.8040, -72.5730),
      ],
    ),
    // Jordan - door to door in subzone 2A
    CoverageRun(
      id: 'run_5',
      memberId: 'marketer_2',
      branchId: branchId,
      type: SessionType.doorToDoor,
      routePoints: const [
        LatLng(42.8300, -72.5350),
        LatLng(42.8280, -72.5320),
        LatLng(42.8260, -72.5290),
        LatLng(42.8240, -72.5260),
        LatLng(42.8220, -72.5230),
        LatLng(42.8210, -72.5260),
        LatLng(42.8230, -72.5290),
        LatLng(42.8250, -72.5320),
        LatLng(42.8270, -72.5350),
        LatLng(42.8290, -72.5370),
      ],
    ),
    // Jordan - door to door in 2C
    CoverageRun(
      id: 'run_6',
      memberId: 'marketer_2',
      branchId: branchId,
      type: SessionType.doorToDoor,
      routePoints: const [
        LatLng(42.8100, -72.5350),
        LatLng(42.8080, -72.5320),
        LatLng(42.8060, -72.5290),
        LatLng(42.8040, -72.5260),
        LatLng(42.8020, -72.5240),
        LatLng(42.8010, -72.5270),
        LatLng(42.8030, -72.5300),
        LatLng(42.8050, -72.5330),
      ],
    ),
  ];
}