import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../domain/coverage_models.dart';
import '../../sessions/domain/session_type.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/services/coverage_service.dart';
import 'coverage_map_widget.dart';
import 'coverage_toolbar.dart';
import 'coverage_panels.dart';

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
  BitmapDescriptor? _midpointIcon;
  BitmapDescriptor? _mergeHighlightIcon;

  bool _isEditMode = false;
  bool _isLoading = true;

  String? _drawingMode;
  final List<LatLng> _draftPoints = [];
  final TextEditingController _zoneNameController = TextEditingController();

  String? _editingZoneId;
  String? _editingSubzoneId;
  List<LatLng> _editingPoints = [];

  bool _isMenuOpen = false;

  static const double _mergeThreshold = 0.0003;

  int? _highlightDraftMergeIndex;
  int? _highlightEditMergeIndex;

  List<TerritoryZone> _zones = [];
  List<TerritorySubzone> _subzones = [];
  List<BranchMember> _members = [];
  List<CoverageRun> _runs = [];

  bool get _canEditZones {
    final user = UserProvider.of(context);
    return user.canEditZones;
  }

  bool get _isDrawing => _drawingMode != null;
  bool get _isEditingShape => _editingZoneId != null || _editingSubzoneId != null;
  bool get _isInteractionLocked => _isMenuOpen || _isDrawing || _isEditingShape;

  @override
  void initState() {
    super.initState();
    _initializeMarkerIcons();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  @override
  void dispose() {
    _zoneNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = UserProvider.of(context);
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        CoverageService.fetchZones(user.branchId),
        CoverageService.fetchSubzones(user.branchId),
        CoverageService.fetchMembers(user.branchId),
        CoverageService.fetchRuns(user.branchId),
      ]);

      if (!mounted) return;
      setState(() {
        _zones = results[0] as List<TerritoryZone>;
        _subzones = results[1] as List<TerritorySubzone>;
        _members = results[2] as List<BranchMember>;
        _runs = results[3] as List<CoverageRun>;
        _selectedMemberIds.addAll(_members.map((m) => m.id));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load coverage data: $e')),
      );
    }
  }

  void _setManualCoverage(
      TerritorySubzone subzone, ZoneCoverageStatus newStatus) async {
    final updated = TerritorySubzone(
      id: subzone.id,
      name: subzone.name,
      branchId: subzone.branchId,
      points: subzone.points,
      status: newStatus,
      manualOverride: true,
    );

    setState(() {
      final index = _subzones.indexWhere((s) => s.id == subzone.id);
      if (index != -1) _subzones[index] = updated;
    });

    try {
      await CoverageService.updateSubzone(updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update subzone: $e')),
      );
    }
  }

  void _startDrawingZone() => setState(() {
        _drawingMode = 'zone';
        _draftPoints.clear();
      });

  void _startDrawingSubzone() => setState(() {
        _drawingMode = 'subzone';
        _draftPoints.clear();
      });

  void _cancelDrawing() => setState(() {
        _drawingMode = null;
        _draftPoints.clear();
        _highlightDraftMergeIndex = null;
      });

  void _undoLastPoint() {
    if (_draftPoints.isEmpty) return;
    setState(() => _draftPoints.removeLast());
  }

  void _addDraftPoint(LatLng point) {
    if (_drawingMode == null) return;
    setState(() => _draftPoints.add(point));
  }

  void _saveDraftPolygon() {
    if (_draftPoints.length < 3 || _drawingMode == null) return;
    _zoneNameController.clear();
    final capturedMode = _drawingMode!;
    final capturedPoints = List<LatLng>.from(_draftPoints);

    setState(() {
      _isMenuOpen = true;
      _drawingMode = null;
    });

    final user = UserProvider.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text(capturedMode == 'subzone'
            ? 'Name this Subzone'
            : 'Name this Zone'),
        content: TextField(
          controller: _zoneNameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: capturedMode == 'subzone' ? 'Subzone Name' : 'Zone Name',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE93324),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final name = _zoneNameController.text.trim();
              if (name.isEmpty) return;
              Navigator.of(context).pop();

              try {
                if (capturedMode == 'zone') {
                  final zone = await CoverageService.createZone(
                    name: name,
                    branchId: user.branchId,
                    points: capturedPoints,
                  );
                  setState(() {
                    _zones.add(zone);
                    _draftPoints.clear();
                    _highlightDraftMergeIndex = null;
                  });
                } else {
                  final subzone = await CoverageService.createSubzone(
                    name: name,
                    branchId: user.branchId,
                    points: capturedPoints,
                  );
                  setState(() {
                    _subzones.add(subzone);
                    _draftPoints.clear();
                    _highlightDraftMergeIndex = null;
                  });
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to save: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).whenComplete(() {
      if (!mounted) return;
      setState(() => _isMenuOpen = false);
    });
  }

  void _beginZoneVertexEdit(TerritoryZone zone) => setState(() {
        _editingZoneId = zone.id;
        _editingSubzoneId = null;
        _editingPoints = List<LatLng>.from(zone.points);
        _drawingMode = null;
        _draftPoints.clear();
      });

  void _beginSubzoneVertexEdit(TerritorySubzone subzone) => setState(() {
        _editingSubzoneId = subzone.id;
        _editingZoneId = null;
        _editingPoints = List<LatLng>.from(subzone.points);
        _drawingMode = null;
        _draftPoints.clear();
      });

  void _cancelVertexEdit() => setState(() {
        _editingZoneId = null;
        _editingSubzoneId = null;
        _editingPoints.clear();
        _highlightEditMergeIndex = null;
      });

  Future<void> _saveVertexEdit() async {
    if (_editingPoints.length < 3) return;

    if (_editingZoneId != null) {
      final index = _zones.indexWhere((z) => z.id == _editingZoneId);
      if (index != -1) {
        final updated = TerritoryZone(
          id: _zones[index].id,
          name: _zones[index].name,
          branchId: _zones[index].branchId,
          points: List<LatLng>.from(_editingPoints),
        );
        setState(() => _zones[index] = updated);
        try {
          await CoverageService.updateZone(updated);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save zone: $e')),
          );
        }
      }
    } else if (_editingSubzoneId != null) {
      final index = _subzones.indexWhere((s) => s.id == _editingSubzoneId);
      if (index != -1) {
        final updated = TerritorySubzone(
          id: _subzones[index].id,
          name: _subzones[index].name,
          branchId: _subzones[index].branchId,
          points: List<LatLng>.from(_editingPoints),
          status: _subzones[index].status,
          manualOverride: _subzones[index].manualOverride,
        );
        setState(() => _subzones[index] = updated);
        try {
          await CoverageService.updateSubzone(updated);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save subzone: $e')),
          );
        }
      }
    }

    setState(() {
      _editingZoneId = null;
      _editingSubzoneId = null;
      _editingPoints.clear();
      _highlightEditMergeIndex = null;
    });
  }

  Future<void> _deleteAllZones() async {
    final user = UserProvider.of(context);
    setState(() => _isMenuOpen = true);

    CoveragePanels.showDeleteAllDialog(
      context: context,
      onConfirmed: () async {
        try {
          await CoverageService.deleteAllZones(user.branchId);
          setState(() {
            _zones.clear();
            _subzones.clear();
            _draftPoints.clear();
            _editingPoints.clear();
            _drawingMode = null;
            _editingZoneId = null;
            _editingSubzoneId = null;
          });
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete zones: $e')),
          );
        }
      },
      onMenuClosed: () {
        if (!mounted) return;
        setState(() => _isMenuOpen = false);
      },
    );
  }

  void _showSubzonePanel(TerritorySubzone subzone) {
    setState(() => _isMenuOpen = true);
    CoveragePanels.showSubzonePanel(
      context: context,
      subzone: subzone,
      onSetCoverage: (status) => _setManualCoverage(subzone, status),
      onMenuClosed: () {
        if (!mounted) return;
        setState(() => _isMenuOpen = false);
      },
    );
  }

  void _showZoneEditPanel(TerritoryZone zone) {
    setState(() => _isMenuOpen = true);
    CoveragePanels.showZoneEditPanel(
      context: context,
      zone: zone,
      onEditShape: () => _beginZoneVertexEdit(zone),
      onRename: () => CoveragePanels.showRenameZoneDialog(
        context: context,
        zone: zone,
        onRenamed: (newName) async {
          final updated = TerritoryZone(
            id: zone.id,
            name: newName,
            branchId: zone.branchId,
            points: zone.points,
          );
          setState(() {
            final index = _zones.indexWhere((z) => z.id == zone.id);
            if (index != -1) _zones[index] = updated;
          });
          try {
            await CoverageService.updateZone(updated);
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to rename zone: $e')),
            );
          }
        },
        onMenuClosed: () {
          if (!mounted) return;
          setState(() => _isMenuOpen = false);
        },
      ),
      onDelete: () => CoveragePanels.showDeleteZoneDialog(
        context: context,
        zone: zone,
        onConfirmed: () async {
          setState(() => _zones.removeWhere((z) => z.id == zone.id));
          try {
            await CoverageService.deleteZone(zone.id);
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete zone: $e')),
            );
          }
        },
        onMenuClosed: () {
          if (!mounted) return;
          setState(() => _isMenuOpen = false);
        },
      ),
      onMenuClosed: () {
        if (!mounted) return;
        setState(() => _isMenuOpen = false);
      },
    );
  }

  void _showSubzoneEditPanel(TerritorySubzone subzone) {
    setState(() => _isMenuOpen = true);
    CoveragePanels.showSubzoneEditPanel(
      context: context,
      subzone: subzone,
      onEditShape: () => _beginSubzoneVertexEdit(subzone),
      onRename: () => CoveragePanels.showRenameSubzoneDialog(
        context: context,
        subzone: subzone,
        onRenamed: (newName) async {
          final updated = TerritorySubzone(
            id: subzone.id,
            name: newName,
            branchId: subzone.branchId,
            points: subzone.points,
            status: subzone.status,
            manualOverride: subzone.manualOverride,
          );
          setState(() {
            final index = _subzones.indexWhere((s) => s.id == subzone.id);
            if (index != -1) _subzones[index] = updated;
          });
          try {
            await CoverageService.updateSubzone(updated);
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to rename subzone: $e')),
            );
          }
        },
        onMenuClosed: () {
          if (!mounted) return;
          setState(() => _isMenuOpen = false);
        },
      ),
      onSetCoverage: (status) => _setManualCoverage(subzone, status),
      onDelete: () => CoveragePanels.showDeleteSubzoneDialog(
        context: context,
        subzone: subzone,
        onConfirmed: () async {
          setState(
              () => _subzones.removeWhere((s) => s.id == subzone.id));
          try {
            await CoverageService.deleteSubzone(subzone.id);
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete subzone: $e')),
            );
          }
        },
        onMenuClosed: () {
          if (!mounted) return;
          setState(() => _isMenuOpen = false);
        },
      ),
      onMenuClosed: () {
        if (!mounted) return;
        setState(() => _isMenuOpen = false);
      },
    );
  }

  Future<void> _initializeMarkerIcons() async {
    final draft = await CoverageMapWidget.createCircleMarkerIcon(
      fillColor: Colors.red,
      strokeColor: Colors.white,
      diameter: 14,
    );
    final edit = await CoverageMapWidget.createCircleMarkerIcon(
      fillColor: Colors.blue,
      strokeColor: Colors.white,
      diameter: 14,
    );
    final midpoint = await CoverageMapWidget.createCircleMarkerIcon(
      fillColor: Colors.red.withOpacity(0.55),
      strokeColor: Colors.white,
      diameter: 10,
    );
    final mergeHighlight = await CoverageMapWidget.createCircleMarkerIcon(
      fillColor: Colors.yellow,
      strokeColor: Colors.red,
      diameter: 18,
    );

    if (!mounted) return;
    setState(() {
      _draftPointIcon = draft;
      _editPointIcon = edit;
      _midpointIcon = midpoint;
      _mergeHighlightIcon = mergeHighlight;
    });
  }

  void _updateDraftPoint(int index, LatLng position) =>
      setState(() => _draftPoints[index] = position);
  void _removeDraftPoint(int index) =>
      setState(() => _draftPoints.removeAt(index));
  void _insertDraftPoint(int index, LatLng position) =>
      setState(() => _draftPoints.insert(index, position));
  void _setHighlightDraftMerge(int? index) =>
      setState(() => _highlightDraftMergeIndex = index);
  void _updateEditPoint(int index, LatLng position) =>
      setState(() => _editingPoints[index] = position);
  void _removeEditPoint(int index) =>
      setState(() => _editingPoints.removeAt(index));
  void _insertEditPoint(int index, LatLng position) =>
      setState(() => _editingPoints.insert(index, position));
  void _setHighlightEditMerge(int? index) =>
      setState(() => _highlightEditMergeIndex = index);

  @override
  Widget build(BuildContext context) {
    final user = UserProvider.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(user.branchName),
        actions: [
          if (_canEditZones)
            IconButton(
              onPressed: () =>
                  setState(() => _isEditMode = !_isEditMode),
              icon: Icon(_isEditMode ? Icons.check : Icons.edit),
              tooltip: _isEditMode ? 'Done' : 'Edit Zones',
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CoverageMapWidget(
              isEditMode: _isEditMode,
              isDrawing: _isDrawing,
              isEditingShape: _isEditingShape,
              isInteractionLocked: _isInteractionLocked,
              isMenuOpen: _isMenuOpen,
              showZones: _showZones,
              selectedMemberIds: _selectedMemberIds,
              selectedType: _selectedType,
              draftPoints: _draftPoints,
              editingPoints: _editingPoints,
              editingZoneId: _editingZoneId,
              editingSubzoneId: _editingSubzoneId,
              drawingMode: _drawingMode,
              highlightDraftMergeIndex: _highlightDraftMergeIndex,
              highlightEditMergeIndex: _highlightEditMergeIndex,
              mergeThreshold: _mergeThreshold,
              draftPointIcon: _draftPointIcon,
              editPointIcon: _editPointIcon,
              midpointIcon: _midpointIcon,
              mergeHighlightIcon: _mergeHighlightIcon,
              zones: _zones,
              subzones: _subzones,
              members: _members,
              runs: _runs,
              onMapTap: _addDraftPoint,
              onSubzoneViewTap: (subzone) {
                setState(() => _selectedSubzone = subzone);
                _showSubzonePanel(subzone);
              },
              onZoneEditTap: _showZoneEditPanel,
              onSubzoneEditTap: _showSubzoneEditPanel,
              onUpdateDraftPoint: _updateDraftPoint,
              onRemoveDraftPoint: _removeDraftPoint,
              onInsertDraftPoint: _insertDraftPoint,
              onSetHighlightDraftMerge: _setHighlightDraftMerge,
              onUpdateEditPoint: _updateEditPoint,
              onRemoveEditPoint: _removeEditPoint,
              onInsertEditPoint: _insertEditPoint,
              onSetHighlightEditMerge: _setHighlightEditMerge,
              onSnackBar: (message) => ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(message))),
            ),
          ),
          if (!_isEditMode)
            Positioned(
              top: 12,
              left: 12,
              child: CoverageViewToolbar(
                selectedMemberIds: _selectedMemberIds,
                selectedType: _selectedType,
                showZones: _showZones,
                members: _members,
                onMemberToggled: (id, selected) => setState(() {
                  if (selected) {
                    _selectedMemberIds.add(id);
                  } else {
                    _selectedMemberIds.remove(id);
                  }
                }),
                onTypeChanged: (type) =>
                    setState(() => _selectedType = type),
                onShowZonesChanged: (value) =>
                    setState(() => _showZones = value),
              ),
            ),
          if (_isEditMode)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: CoverageEditToolbar(
                onStartDrawingZone: _startDrawingZone,
                onStartDrawingSubzone: _startDrawingSubzone,
                onDeleteAll: _deleteAllZones,
              ),
            ),
          if (_isEditMode)
            Positioned(
              bottom: 16,
              left: 12,
              right: 12,
              child: CoverageDrawingBanner(
                drawingMode: _drawingMode,
                draftPoints: _draftPoints,
                editingPoints: _editingPoints,
                onUndoPoint: _undoLastPoint,
                onFinishDrawing: _saveDraftPolygon,
                onCancelDrawing: _cancelDrawing,
                onSaveShape: _saveVertexEdit,
                onCancelShapeEdit: _cancelVertexEdit,
              ),
            ),
        ],
      ),
    );
  }
}