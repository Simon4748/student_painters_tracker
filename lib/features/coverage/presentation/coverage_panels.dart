import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../data/coverage_demo_data.dart';
import '../domain/coverage_models.dart';

class CoveragePanels {
  static Widget _dragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  static Widget _sheetTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }

  static Widget _primaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE93324),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 46),
        ),
        child: Text(label),
      ),
    );
  }

  static Widget _secondaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 46),
        ),
        child: Text(label),
      ),
    );
  }

  static Widget _destructiveButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 46),
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
        ),
        child: Text(label),
      ),
    );
  }

  static Widget _cancelButton({
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        child: const Text('Cancel'),
      ),
    );
  }

  static void showSubzonePanel({
    required BuildContext context,
    required TerritorySubzone subzone,
    required void Function(ZoneCoverageStatus status) onSetCoverage,
    required VoidCallback onMenuClosed,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dragHandle(),
            _sheetTitle(context, 'Subzone ${subzone.name}'),
            const SizedBox(height: 4),
            Text(
              'Status: ${subzone.status.name}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            _primaryButton(
              label: 'Mark Fully Covered',
              onPressed: () {
                onSetCoverage(ZoneCoverageStatus.full);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            _secondaryButton(
              label: 'Mark Partially Covered',
              onPressed: () {
                onSetCoverage(ZoneCoverageStatus.partial);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            _destructiveButton(
              label: 'Reset to Uncovered',
              onPressed: () {
                onSetCoverage(ZoneCoverageStatus.uncovered);
                Navigator.pop(context);
              },
            ),
            _cancelButton(onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    ).whenComplete(onMenuClosed);
  }

  static void showZoneEditPanel({
    required BuildContext context,
    required TerritoryZone zone,
    required VoidCallback onEditShape,
    required VoidCallback onRename,
    required VoidCallback onDelete,
    required VoidCallback onMenuClosed,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dragHandle(),
            _sheetTitle(context, zone.name),
            const SizedBox(height: 16),
            _primaryButton(
              label: 'Edit Zone Shape',
              onPressed: () {
                Navigator.pop(context);
                onEditShape();
              },
            ),
            const SizedBox(height: 8),
            _secondaryButton(
              label: 'Rename Zone',
              onPressed: () {
                Navigator.pop(context);
                onRename();
              },
            ),
            const SizedBox(height: 8),
            _destructiveButton(
              label: 'Delete Zone',
              onPressed: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
            _cancelButton(onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    ).whenComplete(onMenuClosed);
  }

  static void showSubzoneEditPanel({
    required BuildContext context,
    required TerritorySubzone subzone,
    required VoidCallback onEditShape,
    required VoidCallback onRename,
    required void Function(ZoneCoverageStatus status) onSetCoverage,
    required VoidCallback onDelete,
    required VoidCallback onMenuClosed,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dragHandle(),
            _sheetTitle(context, subzone.name),
            const SizedBox(height: 4),
            Text(
              'Status: ${subzone.status.name}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            _primaryButton(
              label: 'Edit Subzone Shape',
              onPressed: () {
                Navigator.pop(context);
                onEditShape();
              },
            ),
            const SizedBox(height: 8),
            _secondaryButton(
              label: 'Rename Subzone',
              onPressed: () {
                Navigator.pop(context);
                onRename();
              },
            ),
            const SizedBox(height: 8),
            _secondaryButton(
              label: 'Mark Fully Covered',
              onPressed: () {
                onSetCoverage(ZoneCoverageStatus.full);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            _secondaryButton(
              label: 'Mark Partially Covered',
              onPressed: () {
                onSetCoverage(ZoneCoverageStatus.partial);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            _destructiveButton(
              label: 'Delete Subzone',
              onPressed: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
            _cancelButton(onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    ).whenComplete(onMenuClosed);
  }

  static void showRenameZoneDialog({
    required BuildContext context,
    required TerritoryZone zone,
    required void Function(String newName) onRenamed,
    required VoidCallback onMenuClosed,
  }) {
    final controller = TextEditingController(text: zone.name);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Zone'),
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
              onRenamed(newName);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).whenComplete(onMenuClosed);
  }

  static void showRenameSubzoneDialog({
    required BuildContext context,
    required TerritorySubzone subzone,
    required void Function(String newName) onRenamed,
    required VoidCallback onMenuClosed,
  }) {
    final controller = TextEditingController(text: subzone.name);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Subzone'),
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
              onRenamed(newName);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).whenComplete(onMenuClosed);
  }

  static void showDeleteZoneDialog({
    required BuildContext context,
    required TerritoryZone zone,
    required VoidCallback onConfirmed,
    required VoidCallback onMenuClosed,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Zone'),
        content: Text('Delete "${zone.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              onConfirmed();
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    ).whenComplete(onMenuClosed);
  }

  static void showDeleteSubzoneDialog({
    required BuildContext context,
    required TerritorySubzone subzone,
    required VoidCallback onConfirmed,
    required VoidCallback onMenuClosed,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subzone'),
        content:
            Text('Delete "${subzone.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              onConfirmed();
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    ).whenComplete(onMenuClosed);
  }

  static void showDeleteAllDialog({
    required BuildContext context,
    required VoidCallback onConfirmed,
    required VoidCallback onMenuClosed,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Zones'),
        content: const Text(
            'This will delete all zones and subzones. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              onConfirmed();
              Navigator.of(context).pop();
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    ).whenComplete(onMenuClosed);
  }

  static void showSavePolygonDialog({
    required BuildContext context,
    required String drawingMode,
    required TextEditingController controller,
    required List<LatLng> draftPoints,
    required VoidCallback onSaved,
    required VoidCallback onMenuClosed,
  }) {
    final isSubzone = drawingMode == 'subzone';
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text(isSubzone ? 'Name this Subzone' : 'Name this Zone'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: isSubzone ? 'Subzone Name' : 'Zone Name',
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
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              if (drawingMode == 'zone') {
                CoverageDemoData.zones.add(TerritoryZone(
                  id: 'zone_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  branchId: CoverageDemoData.branchId,
                  points: List<LatLng>.from(draftPoints),
                ));
              } else {
                CoverageDemoData.subzones.add(TerritorySubzone(
                  id: 'subzone_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  branchId: CoverageDemoData.branchId,
                  points: List<LatLng>.from(draftPoints),
                  status: ZoneCoverageStatus.uncovered,
                  manualOverride: false,
                ));
              }
              onSaved();
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).whenComplete(onMenuClosed);
  }
}