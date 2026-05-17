import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;

import '../data/map_style.dart';
import '../domain/coverage_models.dart';
import '../../sessions/domain/session_type.dart';

class CoverageMapWidget extends StatefulWidget {
  final bool isEditMode;
  final bool isDrawing;
  final bool isEditingShape;
  final bool isInteractionLocked;
  final bool isMenuOpen;
  final bool showZones;
  final Set<String> selectedMemberIds;
  final SessionType? selectedType;
  final List<LatLng> draftPoints;
  final List<LatLng> editingPoints;
  final String? editingZoneId;
  final String? editingSubzoneId;
  final String? drawingMode;
  final int? highlightDraftMergeIndex;
  final int? highlightEditMergeIndex;
  final double mergeThreshold;

  final List<TerritoryZone> zones;
  final List<TerritorySubzone> subzones;
  final List<BranchMember> members;
  final List<CoverageRun> runs;

  final BitmapDescriptor? draftPointIcon;
  final BitmapDescriptor? editPointIcon;
  final BitmapDescriptor? midpointIcon;
  final BitmapDescriptor? mergeHighlightIcon;

  final void Function(LatLng) onMapTap;
  final void Function(TerritorySubzone) onSubzoneViewTap;
  final void Function(TerritoryZone) onZoneEditTap;
  final void Function(TerritorySubzone) onSubzoneEditTap;

  final void Function(int index, LatLng position) onUpdateDraftPoint;
  final void Function(int index) onRemoveDraftPoint;
  final void Function(int index, LatLng position) onInsertDraftPoint;
  final void Function(int? index) onSetHighlightDraftMerge;

  final void Function(int index, LatLng position) onUpdateEditPoint;
  final void Function(int index) onRemoveEditPoint;
  final void Function(int index, LatLng position) onInsertEditPoint;
  final void Function(int? index) onSetHighlightEditMerge;

  final void Function(String message) onSnackBar;

  const CoverageMapWidget({
    super.key,
    required this.isEditMode,
    required this.isDrawing,
    required this.isEditingShape,
    required this.isInteractionLocked,
    required this.isMenuOpen,
    required this.showZones,
    required this.selectedMemberIds,
    required this.selectedType,
    required this.draftPoints,
    required this.editingPoints,
    required this.editingZoneId,
    required this.editingSubzoneId,
    required this.drawingMode,
    required this.highlightDraftMergeIndex,
    required this.highlightEditMergeIndex,
    required this.mergeThreshold,
    required this.zones,
    required this.subzones,
    required this.members,
    required this.runs,
    required this.draftPointIcon,
    required this.editPointIcon,
    required this.midpointIcon,
    required this.mergeHighlightIcon,
    required this.onMapTap,
    required this.onSubzoneViewTap,
    required this.onZoneEditTap,
    required this.onSubzoneEditTap,
    required this.onUpdateDraftPoint,
    required this.onRemoveDraftPoint,
    required this.onInsertDraftPoint,
    required this.onSetHighlightDraftMerge,
    required this.onUpdateEditPoint,
    required this.onRemoveEditPoint,
    required this.onInsertEditPoint,
    required this.onSetHighlightEditMerge,
    required this.onSnackBar,
  });

  static Future<BitmapDescriptor> createCircleMarkerIcon({
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
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(bytes);
  }

  @override
  State<CoverageMapWidget> createState() => _CoverageMapWidgetState();
}

class _CoverageMapWidgetState extends State<CoverageMapWidget> {
  GoogleMapController? _mapController;

  List<CoverageRun> _filteredRuns() {
    return widget.runs.where((run) {
      final matchesMember =
          widget.selectedMemberIds.contains(run.memberId);
      final matchesType =
          widget.selectedType == null || run.type == widget.selectedType;
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
    final Set<Polyline> polylines = {};
    for (final run in _filteredRuns()) {
      final memberMatches =
          widget.members.where((m) => m.id == run.memberId);
      if (memberMatches.isEmpty) continue;
      final member = memberMatches.first;
      polylines.add(Polyline(
        polylineId: PolylineId(run.id),
        color: member.color,
        width: 4,
        points: run.routePoints,
      ));
    }
    return polylines;
  }

  Set<Polygon> _buildZonePolygons() {
    if (!widget.showZones && !widget.isEditMode) return {};
    final Set<Polygon> polygons = {};

    for (final zone in widget.zones) {
      if (zone.id == widget.editingZoneId && widget.isEditingShape) {
        continue;
      }
      polygons.add(Polygon(
        polygonId: PolygonId(zone.id),
        points: zone.points,
        consumeTapEvents: !widget.isDrawing &&
            !widget.isEditingShape &&
            !widget.isMenuOpen,
        onTap: (widget.isEditMode && !widget.isInteractionLocked)
            ? () => widget.onZoneEditTap(zone)
            : null,
        strokeColor: Colors.blueGrey,
        strokeWidth: 2,
        fillColor: Colors.blue.withOpacity(0.08),
      ));
    }

    for (final subzone in widget.subzones) {
      if (subzone.id == widget.editingSubzoneId &&
          widget.isEditingShape) continue;
      polygons.add(Polygon(
        polygonId: PolygonId(subzone.id),
        points: subzone.points,
        consumeTapEvents: !widget.isDrawing &&
            !widget.isEditingShape &&
            !widget.isMenuOpen,
        onTap: widget.isInteractionLocked
            ? null
            : () {
                if (widget.isEditMode) {
                  widget.onSubzoneEditTap(subzone);
                } else {
                  widget.onSubzoneViewTap(subzone);
                }
              },
        strokeColor: Colors.black87,
        strokeWidth: 2,
        fillColor: _subzoneFillColor(subzone.status),
      ));
    }

    if (widget.draftPoints.length >= 3) {
      polygons.add(Polygon(
        polygonId: const PolygonId('draft_polygon'),
        points: widget.draftPoints,
        strokeColor: Colors.red,
        strokeWidth: 3,
        fillColor: Colors.red.withOpacity(0.18),
      ));
    }

    if (widget.editingPoints.length >= 3) {
      polygons.add(Polygon(
        polygonId: const PolygonId('editing_polygon'),
        points: widget.editingPoints,
        strokeColor: Colors.red,
        strokeWidth: 3,
        fillColor: Colors.red.withOpacity(0.18),
      ));
    }

    return polygons;
  }

  Set<Polyline> _buildDraftPolylines() {
    if (widget.draftPoints.length < 2) return {};
    return {
      Polyline(
        polylineId: const PolylineId('draft_line'),
        points: widget.draftPoints,
        color: Colors.red,
        width: 3,
      ),
    };
  }

  double _pointDistance(LatLng a, LatLng b) {
    final latDiff = a.latitude - b.latitude;
    final lngDiff = a.longitude - b.longitude;
    return latDiff * latDiff + lngDiff * lngDiff;
  }

  int? _findMergeTargetIndex({
    required List<LatLng> points,
    required int draggingIndex,
    required LatLng candidatePosition,
  }) {
    int? bestIndex;
    double? bestDistance;
    final thresholdSquared =
        widget.mergeThreshold * widget.mergeThreshold;

    for (int i = 0; i < points.length; i++) {
      if (i == draggingIndex) continue;
      final distance = _pointDistance(candidatePosition, points[i]);
      if (distance <= thresholdSquared) {
        if (bestDistance == null || distance < bestDistance) {
          bestDistance = distance;
          bestIndex = i;
        }
      }
    }
    return bestIndex;
  }

  Set<Marker> _buildDraftMarkers() {
    if (widget.draftPoints.isEmpty) return {};
    final markers = <Marker>{};

    for (int i = 0; i < widget.draftPoints.length; i++) {
      final isMergeTarget = widget.highlightDraftMergeIndex == i;
      markers.add(Marker(
        markerId: MarkerId('draft_point_$i'),
        position: widget.draftPoints[i],
        draggable: true,
        icon: isMergeTarget
            ? (widget.mergeHighlightIcon ??
                widget.draftPointIcon ??
                BitmapDescriptor.defaultMarker)
            : (widget.draftPointIcon ?? BitmapDescriptor.defaultMarker),
        anchor: const Offset(0.5, 0.5),
        onDrag: (newPosition) {
          final target = _findMergeTargetIndex(
            points: widget.draftPoints,
            draggingIndex: i,
            candidatePosition: newPosition,
          );
          widget.onSetHighlightDraftMerge(target);
        },
        onDragEnd: (newPosition) {
          final target = _findMergeTargetIndex(
            points: widget.draftPoints,
            draggingIndex: i,
            candidatePosition: newPosition,
          );
          if (target == null) {
            widget.onUpdateDraftPoint(i, newPosition);
            widget.onSetHighlightDraftMerge(null);
          } else if (widget.draftPoints.length <= 3) {
            widget.onUpdateDraftPoint(i, newPosition);
            widget.onSetHighlightDraftMerge(null);
          } else {
            widget.onRemoveDraftPoint(i);
            widget.onSetHighlightDraftMerge(null);
            widget.onSnackBar('Point merged');
          }
        },
      ));
    }
    return markers;
  }

  Set<Marker> _buildEditMarkers() {
    if (widget.editingPoints.isEmpty) return {};
    final markers = <Marker>{};

    for (int i = 0; i < widget.editingPoints.length; i++) {
      final isMergeTarget = widget.highlightEditMergeIndex == i;
      markers.add(Marker(
        markerId: MarkerId('edit_point_$i'),
        position: widget.editingPoints[i],
        draggable: true,
        icon: isMergeTarget
            ? (widget.mergeHighlightIcon ??
                widget.editPointIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure))
            : (widget.editPointIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure)),
        anchor: const Offset(0.5, 0.5),
        onDrag: (newPosition) {
          final target = _findMergeTargetIndex(
            points: widget.editingPoints,
            draggingIndex: i,
            candidatePosition: newPosition,
          );
          widget.onSetHighlightEditMerge(target);
        },
        onDragEnd: (newPosition) {
          final target = _findMergeTargetIndex(
            points: widget.editingPoints,
            draggingIndex: i,
            candidatePosition: newPosition,
          );
          if (target == null) {
            widget.onUpdateEditPoint(i, newPosition);
            widget.onSetHighlightEditMerge(null);
          } else if (widget.editingPoints.length <= 3) {
            widget.onUpdateEditPoint(i, newPosition);
            widget.onSetHighlightEditMerge(null);
          } else {
            widget.onRemoveEditPoint(i);
            widget.onSetHighlightEditMerge(null);
            widget.onSnackBar('Point merged');
          }
        },
      ));
    }
    return markers;
  }

  LatLng _midpoint(LatLng a, LatLng b) => LatLng(
        (a.latitude + b.latitude) / 2,
        (a.longitude + b.longitude) / 2,
      );

  Set<Marker> _buildDraftMidpointMarkers() {
    if (widget.draftPoints.length < 2) return {};
    final markers = <Marker>{};
    final segmentCount = widget.draftPoints.length >= 3
        ? widget.draftPoints.length
        : widget.draftPoints.length - 1;

    for (int i = 0; i < segmentCount; i++) {
      final nextIndex = (i + 1) % widget.draftPoints.length;
      if (widget.draftPoints.length < 3 && nextIndex == 0) continue;
      final mid =
          _midpoint(widget.draftPoints[i], widget.draftPoints[nextIndex]);
      markers.add(Marker(
        markerId: MarkerId('draft_midpoint_$i'),
        position: mid,
        draggable: true,
        icon: widget.midpointIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        alpha: 0.45,
        anchor: const Offset(0.5, 0.5),
        onDragStart: (_) => widget.onInsertDraftPoint(i + 1, mid),
        onDragEnd: (newPosition) =>
            widget.onUpdateDraftPoint(i + 1, newPosition),
      ));
    }
    return markers;
  }

  Set<Marker> _buildEditMidpointMarkers() {
    if (widget.editingPoints.length < 2) return {};
    final markers = <Marker>{};

    for (int i = 0; i < widget.editingPoints.length; i++) {
      final nextIndex = (i + 1) % widget.editingPoints.length;
      final mid = _midpoint(
          widget.editingPoints[i], widget.editingPoints[nextIndex]);
      markers.add(Marker(
        markerId: MarkerId('edit_midpoint_$i'),
        position: mid,
        draggable: true,
        icon: widget.midpointIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        alpha: 0.45,
        anchor: const Offset(0.5, 0.5),
        onDragStart: (_) => widget.onInsertEditPoint(i + 1, mid),
        onDragEnd: (newPosition) =>
            widget.onUpdateEditPoint(i + 1, newPosition),
      ));
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(42.8120, -72.5450),
        zoom: 12,
      ),
      style: minimalMapStyle,
      onMapCreated: (controller) => _mapController = controller,
      onTap: (widget.isEditMode && widget.isDrawing && !widget.isMenuOpen)
          ? widget.onMapTap
          : null,
      polylines: {
        ...(widget.isEditMode ? <Polyline>{} : _buildRunPolylines()),
        ...(widget.isDrawing ? _buildDraftPolylines() : <Polyline>{}),
      },
      polygons: _buildZonePolygons(),
      markers: {
        ...(widget.isEditMode && widget.isDrawing
            ? _buildDraftMarkers()
            : <Marker>{}),
        ...(widget.isEditMode &&
                widget.isDrawing &&
                widget.draftPoints.length >= 2
            ? _buildDraftMidpointMarkers()
            : <Marker>{}),
        ...(widget.isEditMode && widget.editingPoints.isNotEmpty
            ? _buildEditMarkers()
            : <Marker>{}),
        ...(widget.isEditMode && widget.editingPoints.length >= 2
            ? _buildEditMidpointMarkers()
            : <Marker>{}),
      },
      myLocationEnabled: false,
      zoomControlsEnabled: true,
    );
  }
}