import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../data/coverage_demo_data.dart';
import '../domain/coverage_models.dart';
import '../../sessions/domain/session_type.dart';

class CoveragePage extends StatefulWidget {
  const CoveragePage({super.key});

  @override
  State<CoveragePage> createState() => _CoveragePageState();
}

class _CoveragePageState extends State<CoveragePage> {
  final Set<String> _selectedMemberIds = {};
  SessionType? _selectedType;
  bool _showZones = true;
  TerritorySubzone? _selectedSubzone;

  final UserRole _currentUserRole = UserRole.branchManager;
  bool _isEditMode = false;

  bool get _canEditZones {
    return _currentUserRole == UserRole.branchManager ||
        _currentUserRole == UserRole.generalManager ||
        _currentUserRole == UserRole.executive;
  }

  void _createZone() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create Zone coming next')),
    );
  }

  void _createSubzone() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create Subzone coming next')),
    );
  }

  void _deleteAllZones() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Zones'),
        content: const Text(
          'Are you sure you want to delete all zones and subzones?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                CoverageDemoData.zones.clear();
                CoverageDemoData.subzones.clear();
              });
              Navigator.of(context).pop();
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedMemberIds.addAll(
      CoverageDemoData.members.map((member) => member.id),
    );
  }

  void _showSubzonePanel(TerritorySubzone subzone) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subzone ${subzone.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Status: ${subzone.status.name}'),
            const SizedBox(height: 16),


            OutlinedButton(
              onPressed: () {
                _setManualCoverage(subzone, ZoneCoverageStatus.uncovered);
                Navigator.pop(context);
              },
                child: const Text('Reset to Uncovered'),
              ),

            ElevatedButton(
              onPressed: () {
                _setManualCoverage(subzone, ZoneCoverageStatus.partial);
                Navigator.pop(context);
              },
              child: const Text('Mark Partially Covered'),
            ),

            ElevatedButton(
              onPressed: () {
                _setManualCoverage(subzone, ZoneCoverageStatus.full);
                Navigator.pop(context);
              },
              child: const Text('Mark Fully Covered'),
            ),

            ],
         ),
        );
      },
    );
  }

  void _setManualCoverage(
  TerritorySubzone subzone,
  ZoneCoverageStatus newStatus,
  ) {
    final index = CoverageDemoData.subzones.indexWhere(
      (s) => s.id == subzone.id,
    );

    if (index == -1) return;

    setState(() {
      CoverageDemoData.subzones[index] = TerritorySubzone(
        id: subzone.id,
        zoneId: subzone.zoneId,
        name: subzone.name,
        branchId: subzone.branchId,
        points: subzone.points,
        status: newStatus,
        manualOverride: true,
      );
    });
  }

  List<CoverageRun> _filteredRuns() {
    return CoverageDemoData.runs.where((run) {
      final matchesMember = _selectedMemberIds.contains(run.memberId);
      final matchesType = _selectedType == null || run.type == _selectedType;
      return matchesMember && matchesType;
    }).toList();
  }

  Color _subzoneFillColor(ZoneCoverageStatus status) {
    switch (status) {
      case ZoneCoverageStatus.uncovered:
        return Colors.transparent;
      case ZoneCoverageStatus.partial:
        return Colors.yellow.withOpacity(0.35);
      case ZoneCoverageStatus.full:
        return Colors.green.withOpacity(0.35);
    }
  }

  Set<Polyline> _buildRunPolylines() {
    final runs = _filteredRuns();
    final Set<Polyline> polylines = {};

    for (final run in runs) {
      final member = CoverageDemoData.members.firstWhere(
        (m) => m.id == run.memberId,
      );

      polylines.add(
        Polyline(
          polylineId: PolylineId(run.id),
          color: member.color,
          width: 4,
          points: run.routePoints,
        ),
      );
    }

    return polylines;
  }

  Set<Polygon> _buildZonePolygons() {
    if (!_showZones) return {};

    final Set<Polygon> polygons = {};

    for (final zone in CoverageDemoData.zones) {
      polygons.add(
        Polygon(
          polygonId: PolygonId(zone.id),
          points: zone.points,
          strokeColor: Colors.blueGrey,
          strokeWidth: 2,
          fillColor: Colors.blue.withOpacity(0.08),
        ),
      );
    }

    for (final subzone in CoverageDemoData.subzones) {
      polygons.add(
        Polygon(
          polygonId: PolygonId(subzone.id),
          points: subzone.points,
          consumeTapEvents: true,
          onTap: _isEditMode
            ? null
            : () {
                setState(() {
                  _selectedSubzone = subzone;
                });
                _showSubzonePanel(subzone);
              },
          strokeColor: Colors.black87,
          strokeWidth: 2,
          fillColor: _subzoneFillColor(subzone.status),
        ),
      );
    }

    return polygons;
  }

  Widget _buildMemberChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CoverageDemoData.members.map((member) {
        final isSelected = _selectedMemberIds.contains(member.id);

        return FilterChip(
          selected: isSelected,
          label: Text(member.name),
          avatar: CircleAvatar(
            backgroundColor: member.color,
            radius: 8,
          ),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedMemberIds.add(member.id);
              } else {
                _selectedMemberIds.remove(member.id);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildTypeChips() {
    final allSelected = _selectedType == null;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          selected: allSelected,
          label: const Text('All'),
          onSelected: (_) {
            setState(() {
              _selectedType = null;
            });
          },
        ),
        ...SessionType.values.map((type) {
          return FilterChip(
            selected: _selectedType == type,
            label: Text(type.label),
            onSelected: (_) {
              setState(() {
                _selectedType = type;
              });
            },
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredRuns = _filteredRuns();

    return Scaffold(
      appBar: AppBar(
        title: Text(CoverageDemoData.branchTitle),
        actions: [
          if (_canEditZones)
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditMode = !_isEditMode;
                });
              },
              icon: Icon(_isEditMode ? Icons.check : Icons.edit),
              tooltip: _isEditMode ? 'Done' : 'Edit Zones',
            ),
        ],
      ),

      body: Column(
        children: [
          if (!_isEditMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Team Members',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _buildMemberChips(),
                  const SizedBox(height: 16),
                  Text(
                    'Marketing Type',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _buildTypeChips(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Switch(
                        value: _showZones,
                        onChanged: (value) {
                          setState(() {
                            _showZones = value;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text('Show Zones'),
                    ],
                  ),
                  Text(
                    'Showing ${filteredRuns.length} run(s)',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          if (_isEditMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zone Edit Mode',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: _createZone,
                        child: const Text('Create Zone'),
                      ),
                      ElevatedButton(
                        onPressed: _createSubzone,
                        child: const Text('Create Subzone'),
                      ),
                      OutlinedButton(
                        onPressed: _deleteAllZones,
                        child: const Text('Delete All Zones'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(42.8120, -72.5450),
                zoom: 12,
              ),
              polylines: _isEditMode ? {} : _buildRunPolylines(),
              polygons: _buildZonePolygons(),
              myLocationEnabled: false,
              zoomControlsEnabled: true,
            ),
          ),
        ],
      ),
    );
  }
}