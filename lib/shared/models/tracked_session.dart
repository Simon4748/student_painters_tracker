import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../features/sessions/domain/session_type.dart';

class TrackedSession {
  final String id;
  final SessionType type;
  final Duration elapsed;
  final DateTime completedAt;
  final List<LatLng> routePoints;

  const TrackedSession({
    required this.id,
    required this.type,
    required this.elapsed,
    required this.completedAt,
    required this.routePoints,
  });
}