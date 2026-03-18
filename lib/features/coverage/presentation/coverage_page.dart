import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../shared/models/session_store.dart';
import '../../../shared/models/tracked_session.dart';

class CoveragePage extends StatefulWidget {
  const CoveragePage({super.key});

  @override
  State<CoveragePage> createState() => _CoveragePageState();
}

class _CoveragePageState extends State<CoveragePage> {
  GoogleMapController? _mapController;

  Set<Polyline> _buildAllPolylines(List<TrackedSession> sessions) {
    final Set<Polyline> polylines = {};

    for (final session in sessions) {
      polylines.add(
        Polyline(
          polylineId: PolylineId(session.id),
          color: Colors.blue.withOpacity(0.5),
          width: 4,
          points: session.routePoints,
        ),
      );
    }

    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    final sessions = SessionStore.sessions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coverage Map'),
      ),
      body: sessions.isEmpty
          ? const Center(child: Text('No coverage data yet'))
          : GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
              },
              initialCameraPosition: const CameraPosition(
                target: LatLng(42.3505, -71.1005),
                zoom: 14,
              ),
              polylines: _buildAllPolylines(sessions),
              myLocationEnabled: false,
              zoomControlsEnabled: true,
            ),
    );
  }
}