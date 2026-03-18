import 'dart:async';
import 'package:flutter/material.dart';
import '../domain/session_type.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TrackerPage extends StatefulWidget {
  const TrackerPage({super.key});

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  SessionType? _selectedSessionType;
  Timer? _timer;

  Duration _elapsed = Duration.zero;
  bool _isRunning = false;
  bool _isPaused = false;

  @override
  void dispose() {
    _timer?.cancel();
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
    });
  }

  void _stopSession() {
    _timer?.cancel();

    final type = _selectedSessionType;
    final elapsed = _elapsed;

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
    setState(() {
      _selectedSessionType = null;
      _elapsed = Duration.zero;
      _isRunning = false;
      _isPaused = false;
      _timer?.cancel();
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
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
        child: Padding(
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
              const SizedBox(height: 24),
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
      ),
    );
  }
    final List<LatLng> _sampleRoute = const [
        LatLng(42.3496, -71.0995),
        LatLng(42.3502, -71.1005),
        LatLng(42.3510, -71.1012),
        LatLng(42.3515, -71.1000),
    ];
    Set<Polyline> _buildPolylines() {
        return {
            Polyline(
            polylineId: const PolylineId('sample_route'),
            color: Colors.blue,
            width: 4,
            points: _sampleRoute,
        ),
    };
}
}