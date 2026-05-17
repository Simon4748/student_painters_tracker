import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../domain/session_type.dart';

import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

import '../../../shared/providers/user_provider.dart';
import '../../../shared/services/session_service.dart';

class TrackerPage extends StatefulWidget {
  const TrackerPage({super.key});

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  SessionType _selectedSessionType = SessionType.doorToDoor;
  Timer? _timer;
  GoogleMapController? _mapController;

  Duration _elapsed = Duration.zero;
  bool _isRunning = false;
  bool _isPaused = false;

  double _distanceMiles = 0.0;
  double _currentPace = 0.0;
  double _avgPace = 0.0;
  LatLng? _lastPacePoint;
  Duration _lastPaceTime = Duration.zero;

  final List<LatLng> _routePoints = [];
  int _currentRouteIndex = 0;

  final List<LatLng> _fullRoute = const [
    LatLng(42.3496, -71.0995),
    LatLng(42.3502, -71.1005),
    LatLng(42.3510, -71.1012),
    LatLng(42.3515, -71.1000),
    LatLng(42.3520, -71.0990),
    LatLng(42.3525, -71.1002),
  ];

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _startSession() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed += const Duration(seconds: 1);
      });
      _addNextRoutePoint();
    });
  }

  void _pauseSession() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = true;
    });
  }

  void _resumeSession() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed += const Duration(seconds: 1);
      });
      _addNextRoutePoint();
    });
  }

  Future<void> _stopSession() async {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = false;
    });

    await _showStopBottomSheet();
  }

  Future<void> _showStopBottomSheet() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final List<Uint8List> photos = [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 430),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> pickPhotos() async {
              final files = await _imagePicker.pickMultiImage(
                imageQuality: 75,
                maxWidth: 1600,
              );
              for (final file in files) {
                final bytes = await file.readAsBytes();
                setSheetState(() => photos.add(bytes));
              }
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        'Save Run',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'e.g. Morning round on Elm St',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description (optional)',
                          hintText: 'Any notes about this run...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Photos (optional)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (photos.isNotEmpty)
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: photos.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      photos[i],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => setSheetState(
                                          () => photos.removeAt(i)),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: pickPhotos,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Add Photos'),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _finalizeSession(
                            title: titleController.text.trim(),
                            description: descController.text.trim(),
                            photos: photos,
                          );
                        },
                        child: const Text('Save Run'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _resetSession();
                        },
                        child: const Text(
                          'Discard Run',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _finalizeSession({
    required String title,
    required String description,
    required List<Uint8List> photos,
  }) async {
    final user = UserProvider.of(context);
    final type = _selectedSessionType;
    final elapsed = _elapsed;
    final points = List<LatLng>.from(_routePoints);

    if (points.isEmpty) {
      _resetSession();
      return;
    }

    try {
      await SessionService.saveSession(
        userId: user.id,
        branchId: user.branchId,
        sessionType: type,
        durationSeconds: elapsed.inSeconds,
        distanceMiles: _distanceMiles,
        routePoints: points,
        title: title,
        description: description,
        photos: photos,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save session: $e')),
      );
    }

    _resetSession();
  }

  void _resetSession() {
    _timer?.cancel();
    setState(() {
      _selectedSessionType = SessionType.doorToDoor;
      _elapsed = Duration.zero;
      _isRunning = false;
      _isPaused = false;
      _routePoints.clear();
      _currentRouteIndex = 0;
      _distanceMiles = 0.0;
      _currentPace = 0.0;
      _avgPace = 0.0;
      _lastPacePoint = null;
      _lastPaceTime = Duration.zero;
    });
  }

  void _addNextRoutePoint() {
    if (_currentRouteIndex >= _fullRoute.length) return;

    final newPoint = _fullRoute[_currentRouteIndex];

    if (_routePoints.isNotEmpty) {
      final segmentMiles = _haversineDistance(_routePoints.last, newPoint);
      _distanceMiles += segmentMiles;

      if (_lastPacePoint != null) {
        final segmentFromLast = _haversineDistance(_lastPacePoint!, newPoint);
        final timeDeltaMinutes =
            (_elapsed - _lastPaceTime).inSeconds / 60.0;
        if (segmentFromLast > 0 && timeDeltaMinutes > 0) {
          _currentPace = timeDeltaMinutes / segmentFromLast;
        }
      }
      _lastPacePoint = newPoint;
      _lastPaceTime = _elapsed;

      if (_distanceMiles > 0) {
        _avgPace = (_elapsed.inSeconds / 60.0) / _distanceMiles;
      }
    }

    setState(() {
      _routePoints.add(newPoint);
      _currentRouteIndex++;
    });

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(_routePoints.last),
      );
    }
  }

  double _haversineDistance(LatLng a, LatLng b) {
    const earthRadiusMiles = 3958.8;
    final dLat = _toRad(b.latitude - a.latitude);
    final dLon = _toRad(b.longitude - a.longitude);
    final lat1 = _toRad(a.latitude);
    final lat2 = _toRad(b.latitude);
    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    return earthRadiusMiles * 2 * asin(sqrt(h));
  }

  double _toRad(double deg) => deg * pi / 180;

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatPace(double paceMinPerMile) {
    if (paceMinPerMile <= 0 ||
        paceMinPerMile.isInfinite ||
        paceMinPerMile.isNaN) {
      return '--:--';
    }
    final mins = paceMinPerMile.floor();
    final secs = ((paceMinPerMile - mins) * 60).round();
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildMetricTile(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }

  String _sessionHeading() {
    final status = _isRunning ? 'Now Running' : 'Paused';
    final shortLabel = _selectedSessionType == SessionType.doorToDoor
        ? 'Door to Door'
        : _selectedSessionType.label;
    return '$status · $shortLabel';
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _isRunning || _isPaused;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracker'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // single AnimatedSize wraps the entire collapsible top block
                    AnimatedSize(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOut,
                      child: SizedBox(
                        width: double.infinity,
                        child: isActive
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Text(
                                      _sessionHeading(),
                                      key: ValueKey(_sessionHeading()),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Center(
                                    child: Text(
                                      _formatDuration(_elapsed),
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayMedium
                                          ?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      'Duration',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildMetricTile(
                                        'Distance (mi)',
                                        _distanceMiles.toStringAsFixed(2),
                                      ),
                                      _buildMetricTile(
                                        'Pace (min/mi)',
                                        _formatPace(_currentPace),
                                      ),
                                      _buildMetricTile(
                                        'Avg Pace',
                                        _formatPace(_avgPace),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Session Type',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<SessionType>(
                                    value: _selectedSessionType,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                    ),
                                    items: SessionType.values.map((type) {
                                      return DropdownMenuItem<SessionType>(
                                        value: type,
                                        child: Text(type.label),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(
                                          () => _selectedSessionType = value!);
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                      ),
                    ),

                    // map always visible
                    SizedBox(
                      height: 280,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GoogleMap(
                          onMapCreated: (controller) {
                            _mapController = controller;
                          },
                          initialCameraPosition: const CameraPosition(
                            target: LatLng(42.3505, -71.1005),
                            zoom: 15,
                          ),
                          polylines: {
                            if (_routePoints.isNotEmpty)
                              Polyline(
                                polylineId: const PolylineId('route'),
                                color: colorScheme.primary,
                                width: 4,
                                points: _routePoints,
                              ),
                          },
                          myLocationEnabled: false,
                          zoomControlsEnabled: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: isActive
                  ? Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                _isRunning ? _pauseSession : _resumeSession,
                            child: Text(_isRunning ? 'Pause' : 'Resume'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _stopSession,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Stop'),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _startSession,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                        ),
                        child: const Text(
                          'Start Run',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}