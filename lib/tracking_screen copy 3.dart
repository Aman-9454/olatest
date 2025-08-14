import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

class RouteTrackingScreenWithoutWebView extends StatefulWidget {
  const RouteTrackingScreenWithoutWebView({super.key});

  @override
  State<RouteTrackingScreenWithoutWebView> createState() =>
      _RouteTrackingScreenWithoutWebViewState();
}

class _RouteTrackingScreenWithoutWebViewState
    extends State<RouteTrackingScreenWithoutWebView> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final MapController _mapController = MapController();
  final _uuid = Uuid().v4();


  
  Map<String, double>? _currentCoords;
  List<LatLng> _routePoints = [];
  LatLng? _startLatLng;
  LatLng? _endLatLng;

  static const String apiKey = "hsTXqp1dSR4JBPsQlw46vE2RSWj1Q7k1CfPtbgx6";

  Future<LatLng?> _geocode(String address) async {
    final cleanAddress = address.trim();
    if (cleanAddress.isEmpty) return null;

    final url =
        "https://api.olamaps.io/places/v1/geocode?address=${Uri.encodeComponent(cleanAddress)}&api_key=$apiKey";

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body);
      final results = data['geocodingResults'];

      if (results is List && results.isNotEmpty) {
        final first = results.first;
        final geometry = first['geometry'];
        final location = geometry?['location'];
        final lat = (location?['lat'])?.toDouble();
        final lng = (location?['lng'])?.toDouble();
        if (lat != null && lng != null) return LatLng(lat, lng);
      }
    } catch (_) {}
    return null;
  }


  Future<List<LatLng>> _getRoute(
    LatLng start, // start.latitude, start.longitude
    LatLng end,   // end.latitude, end.longitude
  ) async {
    // Ola Maps Directions API expects longitude,latitude format in origin/destination
    // Use the URL structure from your curl example, including "routing"
    // CRITICAL: origin और destination parameters में longitude पहले और latitude बाद में दें
    final url =
        "https://api.olamaps.io/routing/v1/directions?origin=${start.longitude},${start.latitude}&destination=${end.longitude},${end.latitude}&api_key=$apiKey";

    debugPrint("Directions POST request URL: $url");

    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {
          "X-Request-Id": _uuid, 
          "Content-Type": "application/json",
        },
        
        body: jsonEncode({}), 
      );
      debugPrint("Directions status: ${res.statusCode} body: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["routes"] != null && data["routes"].isNotEmpty) {
          final List<dynamic> routeCoords = data["routes"]["geometry"]["coordinates"];
          return routeCoords.map((c) => LatLng(c, c)).toList();
        }
      }
    } catch (e) {
      debugPrint("Error during route fetching (POST): $e");
    }
    return [];
  }


  // Future<List<LatLng>> _getRoute(LatLng start, LatLng end) async {
  //   final url =
  //           "https://api.olamaps.io/routing/v1/directions/basic?origin=26.7976704,80.8969098&destination=26.7812963,80.8854194&mode=driving&snap_to_road=false&api_key=$apiKey";

  //       // "https://api.olamaps.io/routing/v1/directions/basic?origin=${start.longitude},${start.latitude}&destination=${end.longitude},${end.latitude}&mode=driving&snap_to_road=false&api_key=$apiKey";

  //   debugPrint("Directions request: $url");

  //   try {
  //     final res = await http.post(
  //       Uri.parse(url),
  //       headers: { 
  //         "X-Request-Id": _uuid,
  //         "Content-Type": "application/json",
  //       },
  //       body: jsonEncode({}),
  //     );
  //     debugPrint("Directions status: ${res.statusCode} body: ${res.body}");
  //     if (res.statusCode == 200) {
  //       final data = jsonDecode(res.body);
  //       if (data["routes"] != null && data["routes"].isNotEmpty) {
  //         final List<dynamic> routeCoords =
  //             data["routes"][0]["geometry"]["coordinates"];
  //         return routeCoords.map((c) => LatLng(c[1], c[0])).toList();
  //       }
  //     }
  //   } catch (e) {
  //     debugPrint("Error during route fetching: $e");
  //   }
  //   return [];
  // }

  Future<String> getExactAddress() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) {
          return "Location permission permanently denied.";
        }
      }

      bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) return "Location services are disabled.";

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        print("🗺 Location details (from geocoding package):");
        print("Street: ${place.street}");
        print("Area: ${place.subLocality}");
        print("City: ${place.locality}");
        print("State: ${place.administrativeArea}");
        print("Pin Code: ${place.postalCode}");
        print("Country: ${place.country}");

        String address =
            "${place.subLocality},${place.thoroughfare} "
            "${place.locality}-${place.postalCode}";

        return address;
      } else {
        return "Address not found.";
      }
    } catch (e) {
      return "Error getting location: $e";
    }
  }

  Future<void> _getCurrentLocation() async {
    String locationName = await getExactAddress();
    if (locationName.startsWith("Error") ||
        locationName.startsWith("Location")) {
      _snack(locationName);
      return;
    }

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentCoords = {"lat": pos.latitude, "lng": pos.longitude};
      _startController.text = locationName;
      _startLatLng = LatLng(pos.latitude, pos.longitude);
      _mapController.move(_startLatLng!, 13.0);
    });
  }

  Future<void> _showRouteOnMap() async {
    LatLng? startLoc;
    LatLng? endLoc;

    if (_startController.text.trim() == "Current Location" &&
        _currentCoords != null) {
      startLoc = _startLatLng;
    } else {
      startLoc = await _geocode(_startController.text);
    }

    endLoc = await _geocode(_endController.text);

    if (startLoc == null || endLoc == null) {
      _snack("Location not found");
      setState(() {
        _routePoints = [];
        _startLatLng = null;
        _endLatLng = null;
      });
      return;
    }

    final routeCoords = await _getRoute(startLoc, endLoc);

    if (routeCoords.isEmpty) {
      _snack("No route found");
      setState(() {
        _routePoints = [];
        _startLatLng = null;
        _endLatLng = null;
      });
      return;
    }

    setState(() {
      _routePoints = routeCoords;
      _startLatLng = startLoc;
      _endLatLng = endLoc;

      final bounds = LatLngBounds.fromPoints(routeCoords);
      _mapController.move(bounds.center, 13.0);
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ola Maps Route Tracker (No WebView)")),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _startController,
                      decoration: const InputDecoration(
                        labelText: "Start Location",
                        hintText: "Type address or use GPS",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: "Use Current Location",
                    icon: const Icon(Icons.my_location),
                    onPressed: _getCurrentLocation,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _endController,
                decoration: const InputDecoration(
                  labelText: "End Location",
                  hintText: "Type destination address",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showRouteOnMap,
                  child: const Text("Show Route"),
                ),
              ),
            ),
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _startLatLng ?? LatLng(26.8467, 80.9462),
                  initialZoom: 10.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://api.olamaps.io/tiles/vector/v1/styles/default-light-standard/tiles/{z}/{x}/{y}.png?api_key=$apiKey",
                    userAgentPackageName: 'com.example.olamap',
                  ),
                  MarkerLayer(
                    markers: [
                      if (_startLatLng != null)
                        Marker(
                          width: 40.0,
                          height: 40.0,
                          point: _startLatLng!,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40.0,
                          ),
                        ),
                      if (_endLatLng != null)
                        Marker(
                          width: 40.0,
                          height: 40.0,
                          point: _endLatLng!,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40.0,
                          ),
                        ),
                    ],
                  ),
                  PolylineLayer(
                    polylines: [
                      if (_routePoints.isNotEmpty)
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 5.0,
                          color: Colors.blue,
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
