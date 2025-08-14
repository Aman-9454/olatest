import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:uuid/uuid.dart';

class RouteTrackingScreen extends StatefulWidget {
  const RouteTrackingScreen({super.key});

  @override
  State<RouteTrackingScreen> createState() => _RouteTrackingScreenState();
}

class _RouteTrackingScreenState extends State<RouteTrackingScreen> {
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final MapController _mapController = MapController();
  final String apiKey = "hsTXqp1dSR4JBPsQlw46vE2RSWj1Q7k1CfPtbgx6";
  final String _uuid = const Uuid().v4();

  LatLng? _startLatLng; // current / origin
  LatLng? _endLatLng; // destination
  List<LatLng> _routePoints = [];

  StreamSubscription<Position>? _posSub;
  bool _autoFollow = true; // keep camera following user while tracking

  // ---------- GEOCODING ----------
  Future<LatLng?> _geocode(String address) async {
    if (address.trim().isEmpty) return null;
    final url = Uri.parse(
      "https://api.olamaps.io/places/v1/geocode?address=${Uri.encodeComponent(address)}&api_key=$apiKey",
    );
    final res = await http.get(url);
    if (res.statusCode != 200) return null;

    final data = jsonDecode(res.body);
    final results = data['geocodingResults'];
    if (results is List && results.isNotEmpty) {
      final loc = results.first['geometry']?['location'];
      if (loc != null) {
        final lat = (loc['lat'] as num).toDouble();
        final lng = (loc['lng'] as num).toDouble();
        return LatLng(lat, lng);
      }
    }
    return null;
  }

  // ---------- DIRECTIONS ----------
  Future<List<LatLng>> _getRoute(LatLng start, LatLng end) async {
    // Ola routing = POST. Some deployments accept origin/destination in body.
    // We'll request GEOJSON geometry for easy parsing.
    final url = Uri.parse(
      "https://api.olamaps.io/routing/v1/directions?api_key=$apiKey",
    );

    final body = {
      "origin": {"lng": start.longitude, "lat": start.latitude},
      "destination": {"lng": end.longitude, "lat": end.latitude},
      "geometries": "geojson", // so we can read geometry.coordinates
    };

    final res = await http.post(
      url,
      headers: {"X-Request-Id": _uuid, "Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body);

    // Defensive parsing: routes may be a list with first route holding geometry
    dynamic routeObj;
    if (data['routes'] is List && data['routes'].isNotEmpty) {
      routeObj = data['routes'][0];
    } else if (data['routes'] is Map) {
      routeObj = data['routes'];
    }

    final coords = routeObj?['geometry']?['coordinates'];
    if (coords is List) {
      // coordinates = [[lng,lat], ...]
      return coords
          .map<LatLng>(
            (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
          )
          .toList();
    }

    // Some variants may return "geometry" as LineString directly
    final geom = routeObj?['geometry'];
    if (geom is Map &&
        geom['type'] == 'LineString' &&
        geom['coordinates'] is List) {
      final list = (geom['coordinates'] as List);
      return list
          .map<LatLng>(
            (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
          )
          .toList();
    }

    return [];
  }

  // ---------- REVERSE ADDRESS (OPTIONAL) ----------
  Future<String> getExactAddressFromDevice() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) {
          return "Location permission permanently denied.";
        }
      }

      if (!await Geolocator.isLocationServiceEnabled()) {
        return "Location services are disabled.";
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) return "Address not found.";

      final p = placemarks.first;
      final address = [
        if ((p.subLocality ?? '').isNotEmpty) p.subLocality,
        if ((p.thoroughfare ?? '').isNotEmpty) p.thoroughfare,
        if ((p.locality ?? '').isNotEmpty) p.locality,
        if ((p.postalCode ?? '').isNotEmpty) p.postalCode,
      ].where((e) => e != null && e!.trim().isNotEmpty).join(", ");

      return address.isEmpty ? "Address not found." : address;
    } catch (e) {
      return "Error getting location: $e";
    }
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _startLatLng = LatLng(position.latitude, position.longitude);
    });
    _mapController.move(_startLatLng!, 15);
  }

  Future<void> _useCurrentLocationAndAddress() async {
    // set origin = current device location
    final locMsg = await getExactAddressFromDevice();
    if (locMsg.startsWith("Error") ||
        locMsg.contains("disabled") ||
        locMsg.contains("denied")) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(locMsg)));
      }
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _startLatLng = LatLng(pos.latitude, pos.longitude);
      _startController.text = locMsg;
    });

    // Move camera
    if (_startLatLng != null) {
      _mapController.move(_startLatLng!, 15);
    }
  }

// Future<void> _fetchPlaceName(double lat, double lng) async {
//   final url = Uri.parse(
//     "https://api.olamaps.io/places/v1/reverse-geocode?lat=$lat&lng=$lng&api_key=YOUR_KEY",
//   );

//   final res = await http.get(url);
//   if (res.statusCode == 200) {
//     final data = jsonDecode(res.body);
//     String? name = data["results"]?[0]?["formatted_address"];
//     if (name != null) {
//       setState(() {
//         _currentPlaceName = name;
//       });
//     }
//   }
// }


  // ---------- SHOW ROUTE ----------
  Future<void> _showRoute() async {
    // If user typed "Current Location", try to use _startLatLng, else geocode the text
    LatLng? start =
        (_startController.text.trim().toLowerCase() == "current location")
        ? _startLatLng
        : await _geocode(_startController.text);

    final end = await _geocode(_endController.text);

    if (start == null || end == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Start or end location not found")),
        );
      }
      return;
    }

    final route = await _getRoute(start, end);
    if (route.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No route found")));
      }
      return;
    }

    setState(() {
      _startLatLng = start;
      _endLatLng = end;
      _routePoints = route;
    });

    // Fit route in view
    final bounds = LatLngBounds.fromPoints(route);
    final center = bounds.center;
    // pick a zoom that roughly fits; for more accuracy use fitCamera package helpers
    _mapController.move(center, 13);
  }

  // ---------- LIVE TRACKING ----------
  Future<void> _startTracking() async {
    // permissions
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location services are disabled.")),
        );
      }
      return;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permission denied.")),
          );
        }
        return;
      }
    }

    // initial position
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
    setState(() => _startLatLng = LatLng(pos.latitude, pos.longitude));
    if (_autoFollow && _startLatLng != null)
      _mapController.move(_startLatLng!, 16);

    // stream for live updates
    _posSub?.cancel();
    _posSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 5, // update every 5 meters
          ),
        ).listen((Position p) {
          final current = LatLng(p.latitude, p.longitude);
          setState(() => _startLatLng = current);

          if (_autoFollow) {
            _mapController.move(current, _mapController.camera.zoom);
          }
        });
  }

  void _stopTracking() {
    _posSub?.cancel();
    _posSub = null;
  }

  // ---------- HELPERS ----------
  String get startLat => _startLatLng?.latitude.toStringAsFixed(5) ?? '12.9716';
  String get startLng =>
      _startLatLng?.longitude.toStringAsFixed(5) ?? '77.5946';
  String get endLat => _endLatLng?.latitude.toStringAsFixed(5) ?? '0.00000';
  String get endLng => _endLatLng?.longitude.toStringAsFixed(5) ?? '0.00000';

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _posSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ola Maps Route Tracker"),
        actions: [
          IconButton(
            tooltip: _autoFollow ? "Disable follow" : "Enable follow",
            onPressed: () => setState(() => _autoFollow = !_autoFollow),
            icon: Icon(
              _autoFollow ? Icons.center_focus_strong : Icons.center_focus_weak,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Inputs
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _startController,
                      decoration: const InputDecoration(
                        labelText: "Start Address (type or 'Current Location')",
                        border: OutlineInputBorder(),
                      ),

                      onSubmitted: (value) async {
                        if (value.trim().isEmpty) return;

                        if (value.toLowerCase() != 'current location') {
                          try {
                            final startLatLng = await _geocode(
                              value,
                            ); // Ola API ka geocode use karo
                            if (startLatLng != null) {
                              setState(() {
                                _startLatLng = startLatLng;
                              });
                              _mapController.move(
                                startLatLng,
                                15,
                              ); // Map move karo
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Start address not found"),
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                          }
                        } else {
                          _getCurrentLocation();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: "Use current location",
                    icon: const Icon(Icons.my_location),
                    onPressed: _useCurrentLocationAndAddress,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
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
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _showRoute,
                    child: const Text("Show Route"),
                  ),
                ],
              ),
            ),
            // Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _startTracking,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("Start Tracking"),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _stopTracking,
                    icon: const Icon(Icons.stop),
                    label: const Text("Stop"),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () {
                      if (_startLatLng != null) {
                        _mapController.move(_startLatLng!, 16);
                      }
                    },
                    icon: const Icon(Icons.my_location),
                    label: const Text("Recenter"),
                  ),
                ],
              ),
            ),
            // Map
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
                        "https://api.olamaps.io/tiles/v1/styles/default-light-standard/{z}/{x}/{y}.png?api_key=$apiKey",
                    userAgentPackageName: 'com.example.olamap',
                  ),
                  PolylineLayer(
                    polylines: [
                      if (_routePoints.isNotEmpty)
                        Polyline(
                          points: _routePoints,
                          color: Colors.blue,
                          strokeWidth: 4,
                        ),
                    ],
                  ),

                  // Markers
                  MarkerLayer(
                    markers: [
                      if (_startLatLng != null)
                        Marker(
                          point: _startLatLng!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            size: 40,
                            color: Colors.red,
                          ),
                        ),
                      if (_endLatLng != null)
                        Marker(
                          point: _endLatLng!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.flag,
                            size: 40,
                            color: Colors.red,
                          ),
                        ),
                    ],
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
