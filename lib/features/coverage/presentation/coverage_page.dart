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

  String? _drawingMode; // 'zone' or 'subzone'
  final List<LatLng> _draftPoints = [];

  final TextEditingController _zoneNameController = TextEditingController();
  String? _selectedParentZoneId;

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

  @override
  void dispose() {
    _zoneNameController.dispose();
    super.dispose();
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

  void _startDrawingZone() {
    setState(() {
      _drawingMode = 'zone';
      _draftPoints.clear();
    });
  }

  void _startDrawingSubzone() {
    setState(() {
      _drawingMode = 'subzone';
      _draftPoints.clear();
    });
  }

  void _cancelDrawing() {
    setState(() {
      _drawingMode = null;
      _draftPoints.clear();
    });
  }

  void _undoLastPoint() {
    if (_draftPoints.isEmpty) return;

    setState(() {
      _draftPoints.removeLast();
    });
  }

  void _addDraftPoint(LatLng point) {
    if (_drawingMode == null) return;

    setState(() {
      _draftPoints.add(point);
    });
  }

  void _saveDraftPolygon() {
    if (_draftPoints.length < 3 || _drawingMode == null) return;

    _zoneNameController.clear();
    _selectedParentZoneId = CoverageDemoData.zones.isNotEmpty
        ? CoverageDemoData.zones.first.id
        : null;

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isSubzone = _drawingMode == 'subzone';

            return AlertDialog(
              title: Text(isSubzone ? 'Save Subzone' : 'Save Zone'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _zoneNameController,
                    decoration: InputDecoration(
                      labelText: isSubzone ? 'Subzone Name' : 'Zone Name',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (isSubzone) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedParentZoneId,
                      decoration: const InputDecoration(
                        labelText: 'Parent Zone',
                        border: OutlineInputBorder(),
                      ),
                      items: CoverageDemoData.zones.map((zone) {
                        return DropdownMenuItem<String>(
                          value: zone.id,
                          child: Text(zone.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedParentZoneId = value;
                        });
                      },
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = _zoneNameController.text.trim();
                    if (name.isEmpty) return;
                    if (isSubzone && _selectedParentZoneId == null) return;

                    setState(() {
                      if (_drawingMode == 'zone') {
                        CoverageDemoData.zones.add(
                          TerritoryZone(
                            id: 'zone_${DateTime.now().millisecondsSinceEpoch}',
                            name: name,
                            branchId: CoverageDemoData.branchId,
                            points: List<LatLng>.from(_draftPoints),
                          ),
                        );
                      } else {
                        CoverageDemoData.subzones.add(
                          TerritorySubzone(
                            id: 'subzone_${DateTime.now().millisecondsSinceEpoch}',
                            zoneId: _selectedParentZoneId!,
                            name: name,
                            branchId: CoverageDemoData.branchId,
                            points: List<LatLng>.from(_draftPoints),
                            status: ZoneCoverageStatus.uncovered,
                            manualOverride: false,
                          ),
                        );
                      }

                      _drawingMode = null;
                      _draftPoints.clear();
                    });

                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showZoneEditPanel(TerritoryZone zone) {
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
                zone.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _renameZone(zone);
                },
                child: const Text('Edit Zone Name'),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteZone(zone);
                },
                child: const Text('Delete Zone'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSubzoneEditPanel(TerritorySubzone subzone) {
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
                subzone.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('Status: ${subzone.status.name}'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _renameSubzone(subzone);
                },
                child: const Text('Edit Zone Name'),
              ),
              ElevatedButton(
                onPressed: () {
                  _setManualCoverage(subzone, ZoneCoverageStatus.partial);
                  Navigator.pop(context);
                },
                child: const Text('Manual: Partial'),
              ),
              ElevatedButton(
                onPressed: () {
                  _setManualCoverage(subzone, ZoneCoverageStatus.full);
                  Navigator.pop(context);
                },
                child: const Text('Manual: Full'),
              ),
              OutlinedButton(
                onPressed: () {
                  _setManualCoverage(subzone, ZoneCoverageStatus.uncovered);
                  Navigator.pop(context);
                },
                child: const Text('Manual: Uncovered'),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteSubzone(subzone);
                },
                child: const Text('Delete Zone'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _renameZone(TerritoryZone zone) {
    final controller = TextEditingController(text: zone.name);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Zone Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Zone Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;

              final index =
                  CoverageDemoData.zones.indexWhere((z) => z.id == zone.id);
              if (index == -1) return;

              setState(() {
                CoverageDemoData.zones[index] = TerritoryZone(
                  id: zone.id,
                  name: newName,
                  branchId: zone.branchId,
                  points: zone.points,
                );
              });

              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _renameSubzone(TerritorySubzone subzone) {
    final controller = TextEditingController(text: subzone.name);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Subzone Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Subzone Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;

              final index = CoverageDemoData.subzones
                  .indexWhere((s) => s.id == subzone.id);
              if (index == -1) return;

              setState(() {
                CoverageDemoData.subzones[index] = TerritorySubzone(
                  id: subzone.id,
                  zoneId: subzone.zoneId,
                  name: newName,
                  branchId: subzone.branchId,
                  points: subzone.points,
                  status: subzone.status,
                  manualOverride: subzone.manualOverride,
                );
              });

              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteZone(TerritoryZone zone) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Zone'),
        content: Text('Delete "${zone.name}" and its subzones?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                CoverageDemoData.zones.removeWhere((z) => z.id == zone.id);
                CoverageDemoData.subzones
                    .removeWhere((s) => s.zoneId == zone.id);
              });
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteSubzone(TerritorySubzone subzone) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subzone'),
        content: Text('Delete "${subzone.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                CoverageDemoData.subzones.removeWhere((s) => s.id == subzone.id);
              });
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
          consumeTapEvents: true,
          onTap: _isEditMode
              ? () {
                  _showZoneEditPanel(zone);
                }
              : null,
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
            onTap: () {
              if (_isEditMode) {
                _showSubzoneEditPanel(subzone);
              } else {
                setState(() {
                  _selectedSubzone = subzone;
                });
                _showSubzonePanel(subzone);
              }
            },
          strokeColor: Colors.black87,
          strokeWidth: 2,
          fillColor: _subzoneFillColor(subzone.status),
        ),
      );
    }

    if (_draftPoints.length >= 3) {
      polygons.add(
        Polygon(
          polygonId: const PolygonId('draft_polygon'),
          points: _draftPoints,
          strokeColor: Colors.orange,
          strokeWidth: 3,
          fillColor: Colors.orange.withOpacity(0.2),
        ),
      );
    }

    return polygons;
  }

  Set<Marker> _buildDraftMarkers() {
    if (_draftPoints.isEmpty) return {};

    final markers = <Marker>{};

    for (int i = 0; i < _draftPoints.length; i++) {
      markers.add(
        Marker(
          markerId: MarkerId('draft_point_$i'),
          position: _draftPoints[i],
          infoWindow: InfoWindow(title: 'Point ${i + 1}'),
        ),
      );
    }

    return markers;
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

                  // Main edit buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: _startDrawingZone,
                        child: const Text('Create Zone'),
                      ),
                      ElevatedButton(
                        onPressed: _startDrawingSubzone,
                        child: const Text('Create Subzone'),
                      ),
                      OutlinedButton(
                        onPressed: _deleteAllZones,
                        child: const Text('Delete All Zones'),
                      ),
                    ],
                  ),

                  // Drawing controls
                  if (_drawingMode != null) ...[
                    const SizedBox(height: 12),

                    Text(
                      _drawingMode == 'zone'
                          ? 'Drawing new zone: tap map to add points'
                          : 'Drawing new subzone: tap map to add points',
                    ),

                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: _draftPoints.isNotEmpty ? _undoLastPoint : null,
                          child: const Text('Undo Point'),
                        ),
                        ElevatedButton(
                          onPressed:
                              _draftPoints.length >= 3 ? _saveDraftPolygon : null,
                          child: const Text('Save'),
                        ),
                        TextButton(
                          onPressed: _cancelDrawing,
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(42.8120, -72.5450),
                zoom: 12,
              ),
              onTap: _isEditMode ? _addDraftPoint : null,
              polylines: _isEditMode ? {} : _buildRunPolylines(),
              polygons: _buildZonePolygons(),
              markers: _isEditMode ? _buildDraftMarkers() : {},
              myLocationEnabled: false,
              zoomControlsEnabled: true,
            ),
          ),
        ],
      ),
    );
  }
}