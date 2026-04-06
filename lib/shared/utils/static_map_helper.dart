import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/google_maps_constants.dart';

class _MapBounds {
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  const _MapBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });
}

class StaticMapHelper {
  static String buildRunSnapshotUrl(
    List<LatLng> points, {
    int width = 800,
    int height = 400,
  }) {
    if (points.isEmpty) {
      return '';
    }

    final bounds = _computeBounds(points);
    final paddedBounds = _addPadding(bounds, 0.15);
    final center = _computeCenter(paddedBounds);
    final zoom = _computeZoom(paddedBounds, width.toDouble(), height.toDouble());

    final path = [
      'color:0xff0000ff',
      'weight:4',
      ...points.map((p) => '${p.latitude},${p.longitude}'),
    ].join('|');

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/staticmap',
      {
        'center': '${center.latitude},${center.longitude}',
        'zoom': '$zoom',
        'size': '${width}x$height',
        'maptype': 'roadmap',
        'path': path,
        'key': googleMapsApiKey,
      },
    );

    return uri.toString();
  }

  static _MapBounds _computeBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return _MapBounds(
      minLat: minLat,
      maxLat: maxLat,
      minLng: minLng,
      maxLng: maxLng,
    );
  }

  static _MapBounds _addPadding(_MapBounds bounds, double paddingFraction) {
    final latSpan = (bounds.maxLat - bounds.minLat).abs();
    final lngSpan = (bounds.maxLng - bounds.minLng).abs();

    final paddedLat = math.max(latSpan * paddingFraction, 0.0015);
    final paddedLng = math.max(lngSpan * paddingFraction, 0.0015);

    return _MapBounds(
      minLat: bounds.minLat - paddedLat,
      maxLat: bounds.maxLat + paddedLat,
      minLng: bounds.minLng - paddedLng,
      maxLng: bounds.maxLng + paddedLng,
    );
  }

  static LatLng _computeCenter(_MapBounds bounds) {
    return LatLng(
      (bounds.minLat + bounds.maxLat) / 2,
      (bounds.minLng + bounds.maxLng) / 2,
    );
  }

  static double _latRad(double lat) {
    final sinValue = math.sin(lat * math.pi / 180);
    final rad = math.log((1 + sinValue) / (1 - sinValue)) / 2;
    return math.max(math.min(rad, math.pi), -math.pi) / 2;
  }

  static int _computeZoom(_MapBounds bounds, double mapWidthPx, double mapHeightPx) {
    const worldTileSize = 256.0;

    final latFraction = math.max(
      (_latRad(bounds.maxLat) - _latRad(bounds.minLat)).abs() / math.pi,
      1e-6,
    );

    var lngDiff = (bounds.maxLng - bounds.minLng).abs();
    if (lngDiff > 180) lngDiff = 360 - lngDiff;
    final lngFraction = math.max(lngDiff / 360, 1e-6);

    final latZoom = math.log(mapHeightPx / worldTileSize / latFraction) / math.ln2;
    final lngZoom = math.log(mapWidthPx / worldTileSize / lngFraction) / math.ln2;

    final zoom = math.min(latZoom, lngZoom).floor();
    return zoom.clamp(10, 20);
  }
}