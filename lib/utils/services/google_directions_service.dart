import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlng;
import '../../config/constant.dart';
import '../../config/settings_data_instance.dart';

class GoogleDirectionsService {
  static const String _directionsBaseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';
  static const String _roadsBaseUrl =
      'https://roads.googleapis.com/v1/snapToRoads';
  static const String _distanceMatrixBaseUrl =
      'https://maps.googleapis.com/maps/api/distancematrix/json';

  static String _apiKey() {
    final serverKey = SettingsData.instance.authentication?.googleApiKey;
    if (serverKey != null && serverKey.isNotEmpty) return serverKey;
    return AppConstant.androidMapKey;
  }

  static List<latlng.LatLng> _decodePolyline(String encoded) {
    final points = <latlng.LatLng>[];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      points.add(latlng.LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  static Future<List<latlng.LatLng>> getDirectionsRoute({
    required latlng.LatLng origin,
    required latlng.LatLng destination,
    List<latlng.LatLng> waypoints = const [],
  }) async {
    try {
      final key = _apiKey();
      if (key.isEmpty) return [];

      final waypointsParam = waypoints
          .map((wp) => '${wp.latitude},${wp.longitude}')
          .join('|');

      final uri = Uri.parse(_directionsBaseUrl).replace(queryParameters: {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        if (waypointsParam.isNotEmpty) 'waypoints': waypointsParam,
        'key': key,
        'mode': 'driving',
      });

      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return [];

      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return [];

      final route = routes.first as Map<String, dynamic>;
      final overviewPolyline =
          route['overview_polyline'] as Map<String, dynamic>?;
      if (overviewPolyline == null) return [];

      final points = overviewPolyline['points'] as String?;
      if (points == null || points.isEmpty) return [];

      return _decodePolyline(points);
    } catch (_) {
      return [];
    }
  }

  static Future<latlng.LatLng?> snapToRoad({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final key = _apiKey();
      if (key.isEmpty) return null;

      final uri = Uri.parse(_roadsBaseUrl).replace(queryParameters: {
        'path': '$latitude,$longitude',
        'key': key,
      });

      final response =
          await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final snappedPoints = data['snappedPoints'] as List<dynamic>?;
      if (snappedPoints == null || snappedPoints.isEmpty) return null;

      final point = snappedPoints.first as Map<String, dynamic>;
      final location = point['location'] as Map<String, dynamic>;
      return latlng.LatLng(
        (location['latitude'] as num).toDouble(),
        (location['longitude'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getDistanceMatrix({
    required List<latlng.LatLng> origins,
    required List<latlng.LatLng> destinations,
  }) async {
    try {
      final key = _apiKey();
      if (key.isEmpty) return null;

      final originsStr =
          origins.map((o) => '${o.latitude},${o.longitude}').join('|');
      final destStr = destinations
          .map((d) => '${d.latitude},${d.longitude}')
          .join('|');

      final uri = Uri.parse(_distanceMatrixBaseUrl).replace(queryParameters: {
        'origins': originsStr,
        'destinations': destStr,
        'key': key,
        'mode': 'driving',
      });

      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return null;

      final rows = data['rows'] as List<dynamic>?;
      if (rows == null || rows.isEmpty) return null;

      final elements = rows.first['elements'] as List<dynamic>?;
      if (elements == null || elements.isEmpty) return null;

      final element = elements.first as Map<String, dynamic>;
      if (element['status'] != 'OK') return null;

      final distance = element['distance'] as Map<String, dynamic>?;
      final duration = element['duration'] as Map<String, dynamic>?;

      return {
        'distance_text': distance?['text'] ?? '',
        'distance_value': (distance?['value'] as num?)?.toInt() ?? 0,
        'duration_text': duration?['text'] ?? '',
        'duration_value': (duration?['value'] as num?)?.toInt() ?? 0,
      };
    } catch (_) {
      return null;
    }
  }
}
