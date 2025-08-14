import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

class RouteService {
  static const String apiKey = "hsTXqp1dSR4JBPsQlw46vE2RSWj1Q7k1CfPtbgx6";
  static final String _uuid = const Uuid().v4();

  static Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    final url = Uri.parse("https://api.olamaps.io/routing/v1/directions?api_key=$apiKey");
    final body = {
      "origin": {"lng": start.longitude, "lat": start.latitude},
      "destination": {"lng": end.longitude, "lat": end.latitude},
      "geometries": "geojson",
    };

    final res = await http.post(url, headers: {"X-Request-Id": _uuid, "Content-Type": "application/json"}, body: jsonEncode(body));
    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body);
    final coords = data['routes']?[0]?['geometry']?['coordinates'] ?? [];
    return (coords as List).map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
  }
}

