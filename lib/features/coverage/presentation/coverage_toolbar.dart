import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../data/coverage_demo_data.dart';
import '../domain/coverage_models.dart';
import '../../sessions/domain/session_type.dart';

import 'dart:ui' as ui;

class CoverageViewToolbar extends StatefulWidget {
  final Set<String> selectedMemberIds;
  final SessionType? selectedType;
  final bool showZones;
  final void Function(String id, bool selected) onMemberToggled;
  final void Function(SessionType? type) onTypeChanged;
  final void Function(bool value) onShowZonesChanged;

  const CoverageViewToolbar({
    super.key,
    required this.selectedMemberIds,
    required this.selectedType,
    required this.showZones,
    required this.onMemberToggled,
    required this.onTypeChanged,
    required this.onShowZonesChanged,
  });

  @override
  State<CoverageViewToolbar> createState() => _CoverageViewToolbarState();
}

class _CoverageViewToolbarState extends State<CoverageViewToolbar> {
  bool _expanded = false;

    bool get _hasActiveFilters {
    final allMembersSelected =
        widget.selectedMemberIds.length == CoverageDemoData.members.length;
    return !allMembersSelected || widget.selectedType != null || !widget.showZones;
    }

    @override
    Widget build(BuildContext context) {
        return AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            alignment: Alignment.topLeft,
            child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                constraints: const BoxConstraints(maxWidth: 300),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                    ),
                    ],
                ),
                child: _expanded
                    ? _buildExpanded(context)
                    : _buildCollapsed(context),
                ),
            ),
            ),
        );
    }

  Widget _buildCollapsed(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = true),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: _hasActiveFilters,
              backgroundColor: const Color(0xFFE93324),
              child: const Icon(Icons.filter_list, size: 22),
            ),
            const SizedBox(width: 6),
            const Text(
              'Filters',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpanded(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
              GestureDetector(
                onTap: () => setState(() => _expanded = false),
                child: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Team Members',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: CoverageDemoData.members.map((member) {
              final isSelected =
                  widget.selectedMemberIds.contains(member.id);
              return GestureDetector(
                onTap: () =>
                    widget.onMemberToggled(member.id, !isSelected),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? member.color : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    color: isSelected
                        ? member.color.withOpacity(0.08)
                        : Colors.grey.shade100,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: member.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        member.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? member.color
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Text(
            'Session Type',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _typeChip('All', null),
              ...SessionType.values
                  .map((t) => _typeChip(t.label, t)),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () =>
                widget.onShowZonesChanged(!widget.showZones),
            child: Row(
              children: [
                SizedBox(
                  height: 24,
                  child: Switch(
                    value: widget.showZones,
                    onChanged: widget.onShowZonesChanged,
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Show Zones',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String label, SessionType? type) {
    final isSelected = widget.selectedType == type;
    return GestureDetector(
      onTap: () => widget.onTypeChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? const Color(0xFFE93324)
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
          color: isSelected
              ? const Color(0xFFE93324).withOpacity(0.08)
              : Colors.grey.shade100,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? const Color(0xFFE93324)
                : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

class CoverageEditToolbar extends StatelessWidget {
  final VoidCallback onStartDrawingZone;
  final VoidCallback onStartDrawingSubzone;
  final VoidCallback onDeleteAll;

  const CoverageEditToolbar({
    super.key,
    required this.onStartDrawingZone,
    required this.onStartDrawingSubzone,
    required this.onDeleteAll,
  });

    @override
    Widget build(BuildContext context) {
    return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
                BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
                ),
            ],
            ),
            child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
                _editAction(
                icon: Icons.crop_square,
                label: 'Zone',
                onTap: onStartDrawingZone,
                ),
                _editAction(
                icon: Icons.grid_view,
                label: 'Subzone',
                onTap: onStartDrawingSubzone,
                ),
                _editAction(
                icon: Icons.delete_outline,
                label: 'Delete All',
                onTap: onDeleteAll,
                color: Colors.red,
                ),
            ],
            ),
        ),
        ),
    );
    }

  Widget _editAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: color ?? Colors.black87),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class CoverageDrawingBanner extends StatelessWidget {
  final String? drawingMode;
  final List<LatLng> draftPoints;
  final List<LatLng> editingPoints;
  final VoidCallback onUndoPoint;
  final VoidCallback onFinishDrawing;
  final VoidCallback onCancelDrawing;
  final VoidCallback onSaveShape;
  final VoidCallback onCancelShapeEdit;

  const CoverageDrawingBanner({
    super.key,
    required this.drawingMode,
    required this.draftPoints,
    required this.editingPoints,
    required this.onUndoPoint,
    required this.onFinishDrawing,
    required this.onCancelDrawing,
    required this.onSaveShape,
    required this.onCancelShapeEdit,
  });

  bool get _isDrawing => drawingMode != null;
  bool get _isEditingShape => editingPoints.isNotEmpty;

    @override
    Widget build(BuildContext context) {
    if (!_isDrawing && !_isEditingShape) return const SizedBox.shrink();

    return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
                BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
                ),
            ],
            ),
            child: _isDrawing
                ? _buildDrawingControls(context)
                : _buildEditControls(context),
        ),
        ),
    );
    }

  Widget _buildDrawingControls(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          drawingMode == 'zone'
              ? 'Drawing Zone'
              : 'Drawing Subzone',
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(
          'Tap map to add points. Drag a point onto another to merge.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed:
                    draftPoints.isNotEmpty ? onUndoPoint : null,
                child: const Text('Undo'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed:
                    draftPoints.length >= 3 ? onFinishDrawing : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE93324),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Finish & Name'),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onCancelDrawing,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditControls(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Editing Shape',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(
          'Drag blue points to adjust boundary. Drag onto another to merge.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed:
                    editingPoints.length >= 3 ? onSaveShape : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE93324),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Shape'),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onCancelShapeEdit,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }
}