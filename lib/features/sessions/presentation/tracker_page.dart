import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../domain/session_type.dart';

import '../../../shared/models/tracked_session.dart';
import '../../../shared/models/session_store.dart';

import '../../../shared/models/feed_item.dart';
import '../../../shared/models/feed_store.dart';

import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

import '../../../shared/models/feed_item.dart';
import '../../../shared/models/feed_store.dart';

class TrackerPage extends StatefulWidget {
  const TrackerPage({super.key});

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  SessionType? _selectedSessionType;
  Timer? _timer;
  GoogleMapController? _mapController;

  Duration _elapsed = Duration.zero;
  bool _isRunning = false;
  bool _isPaused = false;

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
  //DEMO:

  final String _currentUserId = 'manager_1';
  final String _currentUserName = 'Simon';
  final String _currentUserRole = 'Branch Manager';
  final String _currentBranchId = 'brattleboro_branch';
  final String _currentBranchName = 'Brattleboro Branch';
  final String _currentDivisionName = 'New England';

  Uint8List? _runPhotoBytes;

  @override
  void dispose() {
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _startSession() {
    if (_selectedSessionType == null) return;

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

    if (_runPhotoBytes != null) {
      _finalizeStoppedSession();
      return;
    }

    final shouldAddPhoto = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add a photo to this run?'),
        content: const Text(
          'Photos make feed posts more useful, but adding one is optional.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('Add Photo'),
          ),
        ],
      ),
    );

    if (shouldAddPhoto == true) {
      await _pickRunPhoto();
    }

    if (!mounted) return;

    _finalizeStoppedSession();
  }

  void _finalizeStoppedSession() {
    _timer?.cancel();

    final type = _selectedSessionType;
    final elapsed = _elapsed;

    if (type != null && _routePoints.isNotEmpty) {
      final session = TrackedSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        elapsed: elapsed,
        completedAt: DateTime.now(),
        routePoints: List<LatLng>.from(_routePoints),
      );

      SessionStore.sessions.insert(0, session);

      final feedItem = FeedItem(
        id: 'run_${DateTime.now().millisecondsSinceEpoch}',
        type: FeedItemType.run,
        authorId: _currentUserId,
        authorName: _currentUserName,
        authorRole: _currentUserRole,
        branchId: _currentBranchId,
        branchName: _currentBranchName,
        divisionName: _currentDivisionName,
        createdAt: DateTime.now(),
        sessionType: type,
        runDuration: elapsed,
        routePointCount: _routePoints.length,
        routePoints: List<LatLng>.from(_routePoints),
        coverPhotoBytes: _runPhotoBytes,
      );

      FeedStore.items.insert(0, feedItem);
    }

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Stopped'),
        content: Text(
          type == null
              ? 'Session ended.'
              : 'Type: ${type.label}\nElapsed: ${_formatDuration(elapsed)}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetSession();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _resetSession() {
    _timer?.cancel();

    setState(() {
      _selectedSessionType = null;
      _elapsed = Duration.zero;
      _isRunning = false;
      _isPaused = false;
      _routePoints.clear();
      _currentRouteIndex = 0;
      _runPhotoBytes = null;
    });
  }

  void _addNextRoutePoint() {
    if (_currentRouteIndex >= _fullRoute.length) return;

    setState(() {
      _routePoints.add(_fullRoute[_currentRouteIndex]);
      _currentRouteIndex++;
    });

    if (_routePoints.isNotEmpty && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(_routePoints.last),
      );
    }
  }

  Set<Polyline> _buildPolylines() {
    return {
      Polyline(
        polylineId: const PolylineId('sample_route'),
        color: Colors.blue,
        width: 4,
        points: _routePoints,
      ),
    };
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Future<bool> _pickRunPhoto() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
      maxWidth: 1600,
    );

    if (file == null) return false;

    final bytes = await file.readAsBytes();

    if (!mounted) return false;

    setState(() {
      _runPhotoBytes = bytes;
    });

    return true;
  }

  void _removeRunPhoto() {
    setState(() {
      _runPhotoBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canStart =
        !_isRunning && !_isPaused && _selectedSessionType != null;
    final canPause = _isRunning;
    final canResume = _isPaused;
    final canStop = _isRunning || _isPaused;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracker'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ===== SCROLLABLE CONTENT =====
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session Type',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<SessionType>(
                      value: _selectedSessionType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Select a session type',
                      ),
                      items: SessionType.values.map((type) {
                        return DropdownMenuItem<SessionType>(
                          value: type,
                          child: Text(type.label),
                        );
                      }).toList(),
                      onChanged: (_isRunning || _isPaused)
                          ? null
                          : (value) {
                              setState(() {
                                _selectedSessionType = value;
                              });
                            },
                    ),
                    const SizedBox(height: 24),

                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Elapsed Time',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDuration(_elapsed),
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isRunning
                                ? 'Running'
                                : _isPaused
                                    ? 'Paused'
                                    : 'Not Started',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      height: 220,
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
                          polylines: _buildPolylines(),
                          myLocationEnabled: false,
                          zoomControlsEnabled: false,
                        ),
                      ),
                    ),

                    // ===== RUN PHOTO SECTION =====
                    const SizedBox(height: 16),
                    Text(
                      'Run Photo (Optional)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Adding a photo is encouraged, but not required.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),

                    if (_runPhotoBytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _runPhotoBytes!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),

                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickRunPhoto,
                          icon: const Icon(Icons.camera_alt),
                          label: Text(
                            _runPhotoBytes == null ? 'Add Photo' : 'Change Photo',
                          ),
                        ),
                        if (_runPhotoBytes != null)
                          OutlinedButton(
                            onPressed: _removeRunPhoto,
                            child: const Text('Remove Photo'),
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ===== FIXED BUTTON SECTION =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: canStart ? _startSession : null,
                          child: const Text('Start'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: canPause
                              ? _pauseSession
                              : canResume
                                  ? _resumeSession
                                  : null,
                          child: Text(canResume ? 'Resume' : 'Pause'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: canStop ? _stopSession : null,
                      child: const Text('Stop'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}