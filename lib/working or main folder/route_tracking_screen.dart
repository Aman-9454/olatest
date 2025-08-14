import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'location_service.dart';
import 'route_service.dart';
import 'map_markers.dart';

class RouteTrackingScreen extends StatefulWidget {
  const RouteTrackingScreen({super.key});

  @override
  State<RouteTrackingScreen> createState() => _RouteTrackingScreenState();
}

class _RouteTrackingScreenState extends State<RouteTrackingScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();

  LatLng? _startLatLng;
  LatLng? _endLatLng;
  List<LatLng> _routePoints = [];
  StreamSubscription? _posSub;
  bool _autoFollow = true;

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _posSub?.cancel();
    super.dispose();
  }

  Future<void> _showRoute() async {
    LatLng? start = (_startController.text.toLowerCase() == 'current location')
        ? _startLatLng
        : await LocationService.geocodeAddress(_startController.text);
    LatLng? end = await LocationService.geocodeAddress(_endController.text);

    if (start == null || end == null) return;

    final route = await RouteService.getRoute(start, end);
    setState(() {
      _startLatLng = start;
      _endLatLng = end;
      _routePoints = route;
    });

    final bounds = LatLngBounds.fromPoints(route);
    _mapController.move(bounds.center, 13);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ola Maps Route Tracker"),
        actions: [
          IconButton(
            icon: Icon(_autoFollow ? Icons.center_focus_strong : Icons.center_focus_weak),
            onPressed: () => setState(() => _autoFollow = !_autoFollow),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startController,
                    decoration: const InputDecoration(
                      labelText: "Start Address",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: () async {
                    final loc = await LocationService.getCurrentLocation();
                    if (loc != null) {
                      setState(() {
                        _startLatLng = loc;
                        _startController.text = "Current Location";
                      });
                      _mapController.move(loc, 15);
                    }
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _endController,
                    decoration: const InputDecoration(
                      labelText: "Destination Address",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _showRoute,
                  child: const Text("Show Route"),
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _startLatLng ?? const LatLng(20.5937, 78.9629),
                initialZoom: 5,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://api.olamaps.io/tiles/v1/styles/default-light-standard/{z}/{x}/{y}.png?api_key=${RouteService.apiKey}",
                ),
                PolylineLayer(
                  polylines: [
                    if (_routePoints.isNotEmpty)
                      Polyline(points: _routePoints, color: Colors.blue, strokeWidth: 4),
                  ],
                ),
                MarkerLayer(
                  markers: MapMarkers.getMarkers(
                      start: _startLatLng, end: _endLatLng),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
