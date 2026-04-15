import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../data/coverage_demo_data.dart';
import '../domain/coverage_models.dart';
import '../../sessions/domain/session_type.dart';
import 'coverage_map_widget.dart';
import 'coverage_toolbar.dart';
import 'coverage_panels.dart';

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
  BitmapDescriptor? _midpointIcon;
  BitmapDescriptor? _mergeHighlightIcon;

  final UserRole _currentUserRole = UserRole.branchManager;
  bool _isEditMode = false;

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

  bool get _canEditZones =>
      _currentUserRole == UserRole.branchManager ||
      _currentUserRole == UserRole.generalManager ||
      _currentUserRole == UserRole.executive;

  bool get _isDrawing => _drawingMode != null;

  bool get _isEditingShape =>
      _editingZoneId != null || _editingSubzoneId != null;

  bool get _isInteractionLocked =>
      _isMenuOpen || _isDrawing || _isEditingShape;

  @override
  void initState() {
    super.initState();
    _selectedMemberIds.addAll(
      CoverageDemoData.members.map((m) => m.id),
    );
    _initializeMarkerIcons();
  }

  @override
  void dispose() {
    _zoneNameController.dispose();
    super.dispose();
  }

  void _setMenuOpen(bool value) => setState(() => _isMenuOpen = value);

  void _setManualCoverage(
      TerritorySubzone subzone, ZoneCoverageStatus newStatus) {
    final index =
        CoverageDemoData.subzones.indexWhere((s) => s.id == subzone.id);
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

    setState(() {
      _isMenuOpen = true;
      _drawingMode = null;
    });

    CoveragePanels.showSavePolygonDialog(
      context: context,
      drawingMode: capturedMode,
      controller: _zoneNameController,
      draftPoints: _draftPoints,
      onSaved: () => setState(() {
        _draftPoints.clear();
        _highlightDraftMergeIndex = null;
      }),
      onMenuClosed: () {
        if (!mounted) return;
        setState(() => _isMenuOpen = false);
      },
    );
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

  void _saveVertexEdit() {
    if (_editingPoints.length < 3) return;
    setState(() {
      if (_editingZoneId != null) {
        final index = CoverageDemoData.zones
            .indexWhere((z) => z.id == _editingZoneId);
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
        final index = CoverageDemoData.subzones
            .indexWhere((s) => s.id == _editingSubzoneId);
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
      _highlightEditMergeIndex = null;
    });
  }

  void _deleteAllZones() {
    setState(() => _isMenuOpen = true);
    CoveragePanels.showDeleteAllDialog(
      context: context,
      onConfirmed: () => setState(() {
        CoverageDemoData.zones.clear();
        CoverageDemoData.subzones.clear();
        _draftPoints.clear();
        _editingPoints.clear();
        _drawingMode = null;
        _editingZoneId = null;
        _editingSubzoneId = null;
      }),
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
        onRenamed: (newName) => setState(() {
          final index =
              CoverageDemoData.zones.indexWhere((z) => z.id == zone.id);
          if (index != -1) {
            CoverageDemoData.zones[index] = TerritoryZone(
              id: zone.id,
              name: newName,
              branchId: zone.branchId,
              points: zone.points,
            );
          }
        }),
        onMenuClosed: () {
          if (!mounted) return;
          setState(() => _isMenuOpen = false);
        },
      ),
      onDelete: () => CoveragePanels.showDeleteZoneDialog(
        context: context,
        zone: zone,
        onConfirmed: () => setState(() {
          CoverageDemoData.zones.removeWhere((z) => z.id == zone.id);
        }),
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
        onRenamed: (newName) => setState(() {
          final index = CoverageDemoData.subzones
              .indexWhere((s) => s.id == subzone.id);
          if (index != -1) {
            CoverageDemoData.subzones[index] = TerritorySubzone(
              id: subzone.id,
              name: newName,
              branchId: subzone.branchId,
              points: subzone.points,
              status: subzone.status,
              manualOverride: subzone.manualOverride,
            );
          }
        }),
        onMenuClosed: () {
          if (!mounted) return;
          setState(() => _isMenuOpen = false);
        },
      ),
      onSetCoverage: (status) => _setManualCoverage(subzone, status),
      onDelete: () => CoveragePanels.showDeleteSubzoneDialog(
        context: context,
        subzone: subzone,
        onConfirmed: () => setState(() {
          CoverageDemoData.subzones.removeWhere((s) => s.id == subzone.id);
        }),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(CoverageDemoData.branchTitle),
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
          // map fills entire body
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

          // floating view toolbar
          if (!_isEditMode)
            Positioned(
              top: 12,
              left: 12,
              child: CoverageViewToolbar(
                selectedMemberIds: _selectedMemberIds,
                selectedType: _selectedType,
                showZones: _showZones,
                onMemberToggled: (id, selected) => setState(() {
                  if (selected) {
                    _selectedMemberIds.add(id);
                  } else {
                    _selectedMemberIds.remove(id);
                  }
                }),
                onTypeChanged: (type) => setState(() => _selectedType = type),
                onShowZonesChanged: (value) =>
                    setState(() => _showZones = value),
              ),
            ),

          // floating edit toolbar
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

          // floating drawing/editing banner
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