import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../utils/services/google_directions_service.dart';

List<LatLng> decodePolyline(String encoded) {
  final points = <LatLng>[];
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

    points.add(LatLng(lat / 1e5, lng / 1e5));
  }

  return points;
}

Future<List<LatLng>> getRoadRoute(LatLng start, LatLng end) async {
  final route = await GoogleDirectionsService.getDirectionsRoute(
    origin: start,
    destination: end,
  );
  if (route.isNotEmpty) return route;

  try {
    final url = 'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=polyline';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final route = data['routes'][0]['geometry'];
      return decodePolyline(route);
    }
  } catch (_) {}

  return [start, end];
}

