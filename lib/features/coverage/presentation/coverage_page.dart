import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../data/coverage_demo_data.dart';
import '../domain/coverage_models.dart';
import '../../sessions/domain/session_type.dart';

import 'dart:ui' as ui;
import 'dart:typed_data';

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

  BitmapDescriptor? _draftPointIcon;
  BitmapDescriptor? _editPointIcon;

  final UserRole _currentUserRole = UserRole.branchManager;
  bool _isEditMode = false;

  String? _drawingMode; // 'zone' or 'subzone'
  final List<LatLng> _draftPoints = [];

  final TextEditingController _zoneNameController = TextEditingController();

  String? _editingZoneId;
  String? _editingSubzoneId;
  List<LatLng> _editingPoints = [];

  bool _isMenuOpen = false;

  bool get _canEditZones {
    return _currentUserRole == UserRole.branchManager ||
        _currentUserRole == UserRole.generalManager ||
        _currentUserRole == UserRole.executive;
  }

  bool get _isDrawing {
    return _drawingMode != null;
  }

  bool get _isEditingShape {
    return _editingZoneId != null || _editingSubzoneId != null;
  }

  bool get _isInteractionLocked {
    return _isMenuOpen || _isDrawing || _isEditingShape;
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
    _initializeMarkerIcons();
  }

  @override
  void dispose() {
    _zoneNameController.dispose();
    super.dispose();
  }

  void _showSubzonePanel(TerritorySubzone subzone) {

    setState(() {
      _isMenuOpen = true;
    });

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
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
    ).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _isMenuOpen = false;
      });
    });
  }

  void _setManualCoverage(TerritorySubzone subzone, ZoneCoverageStatus newStatus,){
    final index = CoverageDemoData.subzones.indexWhere(
      (s) => s.id == subzone.id,
    );

    if (index == -1) return;

    setState(() {
      CoverageDemoData.subzones[index] = TerritorySubzone(
        id: subzone.id,
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

    setState(() {
      _isMenuOpen = true;
    });

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final isSubzone = _drawingMode == 'subzone';

        return AlertDialog(
          title: Text(isSubzone ? 'Save Subzone' : 'Save Zone'),
          content: TextField(
            controller: _zoneNameController,
            decoration: InputDecoration(
              labelText: isSubzone ? 'Subzone Name' : 'Zone Name',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = _zoneNameController.text.trim();
                if (name.isEmpty) return;

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
    ).whenComplete(() {
      if (!mounted) return;

      setState(() {
        _isMenuOpen = false;
      });
    });
  }

  void _showZoneEditPanel(TerritoryZone zone) {
    setState(() {
      _isMenuOpen = true;
    });

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
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
                  _beginZoneVertexEdit(zone);
                },
                child: const Text('Edit Zone Shape'),
              ),
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
    ).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _isMenuOpen = false;
      });
    });
  }

  void _showSubzoneEditPanel(TerritorySubzone subzone) {
    
    setState(() {
      _isMenuOpen = true;
    });

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
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
                  _beginSubzoneVertexEdit(subzone);
                },
                child: const Text('Edit Subzone Shape'),
              ),
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
    ).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _isMenuOpen = false;
      });
    });
  }

  void _renameZone(TerritoryZone zone) {

    setState(() {
      _isMenuOpen = true;
    });

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
    ).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _isMenuOpen = false;
      });
    });
  }

  void _renameSubzone(TerritorySubzone subzone) {

    setState(() {
      _isMenuOpen = true;
    }); 

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
    ).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _isMenuOpen = false;
      });
    });
  }

  void _deleteZone(TerritoryZone zone) {

    setState(() {
      _isMenuOpen = true;
    }); 

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Zone'),
        content: Text('Delete "${zone.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                CoverageDemoData.zones.removeWhere((z) => z.id == zone.id);
              });
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    ).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _isMenuOpen = false;
      });
    });
  }

  void _deleteSubzone(TerritorySubzone subzone) {

    setState(() {
      _isMenuOpen = true;
    }); 

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
    ).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _isMenuOpen = false;
      });
    });
  }

  void _beginZoneVertexEdit(TerritoryZone zone) {
    setState(() {
      _editingZoneId = zone.id;
      _editingSubzoneId = null;
      _editingPoints = List<LatLng>.from(zone.points);
      _drawingMode = null;
      _draftPoints.clear();
    });
  }

  void _beginSubzoneVertexEdit(TerritorySubzone subzone) {
    setState(() {
      _editingSubzoneId = subzone.id;
      _editingZoneId = null;
      _editingPoints = List<LatLng>.from(subzone.points);
      _drawingMode = null;
      _draftPoints.clear();
    });
  }

  void _cancelVertexEdit() {
    setState(() {
      _editingZoneId = null;
      _editingSubzoneId = null;
      _editingPoints.clear();
    });
  }

  void _saveVertexEdit() {
    if (_editingPoints.length < 3) return;

    setState(() {
      if (_editingZoneId != null) {
        final index = CoverageDemoData.zones.indexWhere((z) => z.id == _editingZoneId);
        if (index != -1) {
          final zone = CoverageDemoData.zones[index];
          CoverageDemoData.zones[index] = TerritoryZone(
            id: zone.id,
            name: zone.name,
            branchId: zone.branchId,
            points: List<LatLng>.from(_editingPoints),
          );
        }
      } else if (_editingSubzoneId != null) {
        final index = CoverageDemoData.subzones.indexWhere((s) => s.id == _editingSubzoneId);
        if (index != -1) {
          final subzone = CoverageDemoData.subzones[index];
          CoverageDemoData.subzones[index] = TerritorySubzone(
            id: subzone.id,
            name: subzone.name,
            branchId: subzone.branchId,
            points: List<LatLng>.from(_editingPoints),
            status: subzone.status,
            manualOverride: subzone.manualOverride,
          );
        }
      }

      _editingZoneId = null;
      _editingSubzoneId = null;
      _editingPoints.clear();
    });
  }

  Future<void> _initializeMarkerIcons() async {
    final draft = await _createCircleMarkerIcon(
      fillColor: Colors.red,
      strokeColor: Colors.white,
      diameter: 14,
    );

    final edit = await _createCircleMarkerIcon(
      fillColor: Colors.blue,
      strokeColor: Colors.white,
      diameter: 14,
    );

    if (!mounted) return;

    setState(() {
      _draftPointIcon = draft;
      _editPointIcon = edit;
    });
  }

  Future<BitmapDescriptor> _createCircleMarkerIcon({
    required Color fillColor,
    required Color strokeColor,
    int diameter = 24,
    }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = fillColor;
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final center = Offset(diameter / 2, diameter / 2);
    final radius = diameter / 2.5;

    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius, strokePaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(diameter, diameter);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(bytes);
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
    if (!_showZones && !_isEditMode) return {};

    final Set<Polygon> polygons = {};

    for (final zone in CoverageDemoData.zones) {
      polygons.add(
        Polygon(
          polygonId: PolygonId(zone.id),
          points: zone.points,
          consumeTapEvents: !_isDrawing && !_isEditingShape && !_isMenuOpen,
          onTap: (_isEditMode && !_isInteractionLocked)
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
          consumeTapEvents: !_isDrawing && !_isEditingShape && !_isMenuOpen,
          onTap: _isInteractionLocked
              ? null
              : () {
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
          strokeColor: Colors.red,
          strokeWidth: 3,
          fillColor: Colors.red.withOpacity(0.18),
        ),
      );
    }

    if (_editingPoints.length >= 3) {
      polygons.add(
        Polygon(
          polygonId: const PolygonId('editing_polygon'),
          points: _editingPoints,
          strokeColor: Colors.red,
          strokeWidth: 3,
          fillColor: Colors.red.withOpacity(0.18),
        ),
      );
    }

    return polygons;
  }

  Set<Polyline> _buildDraftPolylines() {
    if (_draftPoints.length < 2) return {};

    return {
      Polyline(
        polylineId: const PolylineId('draft_line'),
        points: _draftPoints,
        color: Colors.red,
        width: 3,
      ),
    };
  }

  Set<Marker> _buildDraftMarkers() {
    if (_draftPoints.isEmpty) return {};

    final markers = <Marker>{};

    for (int i = 0; i < _draftPoints.length; i++) {
      markers.add(
        Marker(
          markerId: MarkerId('draft_point_$i'),
          position: _draftPoints[i],
          icon: _draftPointIcon ?? BitmapDescriptor.defaultMarker,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(title: 'Point ${i + 1}'),
        ),
      );
    }

    return markers;
  }

  Set<Marker> _buildEditMarkers() {
    if (_editingPoints.isEmpty) return {};

    final markers = <Marker>{};

    for (int i = 0; i < _editingPoints.length; i++) {
      markers.add(
        Marker(
          markerId: MarkerId('edit_point_$i'),
          position: _editingPoints[i],
          draggable: true,
          icon: _editPointIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
          anchor: const Offset(0.5, 0.5),
          onDragEnd: (newPosition) {
            setState(() {
              _editingPoints[i] = newPosition;
            });
          },
          infoWindow: InfoWindow(title: 'Vertex ${i + 1}'),
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
                          ? 'Tap map to draw zone. Then finish and name it.'
                          : 'Tap map to draw subzone. Then finish and name it.',
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
                          child: const Text('Finish & Name'),
                        ),
                        TextButton(
                          onPressed: _cancelDrawing,
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],

                  if (_editingPoints.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Editing shape: drag the blue points to adjust the boundary'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: _editingPoints.length >= 3 ? _saveVertexEdit : null,
                          child: const Text('Save Shape'),
                        ),
                        TextButton(
                          onPressed: _cancelVertexEdit,
                          child: const Text('Cancel Shape Edit'),
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(42.8120, -72.5450),
                zoom: 12,
              ),
              onTap: (_isEditMode && _isDrawing && !_isMenuOpen)
                ? _addDraftPoint
                : null,
              polylines: {
                ...(_isEditMode ? <Polyline>{} : _buildRunPolylines()),
                ...(_isDrawing ? _buildDraftPolylines() : <Polyline>{}),
              },
              polygons: _buildZonePolygons(),
              markers: {
                ...(_isEditMode && _isDrawing ? _buildDraftMarkers() : <Marker>{}),
                ...(_isEditMode && _editingPoints.isNotEmpty
                    ? _buildEditMarkers()
                    : <Marker>{}),
              },
              myLocationEnabled: false,
              zoomControlsEnabled: true,
            ),
          ),
        ],
      ),
    );
  }
}