import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:olamap/working%20or%20main%20folder/direction_info.dart';


class RouteService {
  static const String _googleApiKey = "AIzaSyBzkgWrbBZwkzIpNyGlqoj85Ig2JNyUb8E";

  Future<Polyline?> buildPolyline(LatLng origin, LatLng destination) async {
    final polylinePoints = PolylinePoints();

    final result = await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(origin.latitude, origin.longitude),
        destination: PointLatLng(destination.latitude, destination.longitude),
        mode: TravelMode.driving,
      ),
      googleApiKey: _googleApiKey,
    );

    if (result.points.isNotEmpty) {
      final polylineCoordinates =
          result.points.map((p) => LatLng(p.latitude, p.longitude)).toList();

      return Polyline(
        polylineId: const PolylineId('route'),
        width: 5,
        color: Colors.blue,
        points: polylineCoordinates,
      );
    }
    return null;
  }

  Future<DirectionsInfo?> fetchDirectionsInfo(LatLng origin, LatLng destination) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=driving&key=$_googleApiKey');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final leg = data['routes'][0]['legs'][0];
        return DirectionsInfo(
          distance: leg['distance']['text'],
          duration: leg['duration']['text'],
        );
      }
    }
    return null;
  }
}
