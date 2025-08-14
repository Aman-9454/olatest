import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'location_service.dart';

class MapMarkers {
  static List<Marker> getMarkers({LatLng? start, LatLng? end}) {
    List<Marker> markers = [];
    if (start != null) {
      markers.add(Marker(
        point: start,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
      ));
    }

    if (end != null) {
      markers.add(Marker(
        point: end,
        width: 150,
        height: 80,
        child: FutureBuilder<String>(
          future: LocationService.getAddressFromLatLng(end),
          builder: (context, snapshot) {
            final text = snapshot.data ?? "Loading...";
            return Column(
              children: [
                const Icon(Icons.flag, color: Colors.red, size: 40),
                Container(
                  color: Colors.white.withOpacity(0.8),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(text, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
                ),
              ],
            );
          },
        ),
      ));
    }

    return markers;
  }
}
