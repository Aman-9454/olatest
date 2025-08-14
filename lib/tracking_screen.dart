// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_map/flutter_map.dart';
// // import 'package:latlong2/latlong.dart';
// // import 'package:geolocator/geolocator.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:geocoding/geocoding.dart';
// // import 'package:uuid/uuid.dart';

// // class RouteTrackingScreen extends StatefulWidget {
// //   const RouteTrackingScreen({super.key});

// //   @override
// //   State<RouteTrackingScreen> createState() => _RouteTrackingScreenState();
// // }

// // class _RouteTrackingScreenState extends State<RouteTrackingScreen> {
// //   final _startController = TextEditingController();
// //   final _endController = TextEditingController();
// //   final MapController _mapController = MapController();
// //   final String apiKey = "hsTXqp1dSR4JBPsQlw46vE2RSWj1Q7k1CfPtbgx6";
// //   final String _uuid = Uuid().v4();

// //   LatLng? _startLatLng;
// //   LatLng? _endLatLng;
// //   List<LatLng> _routePoints = [];

// //   Future<LatLng?> _geocode(String address) async {
// //     if (address.trim().isEmpty) return null;
// //     final url = Uri.parse(
// //       "https://api.olamaps.io/places/v1/geocode?address=${Uri.encodeComponent(address)}&api_key=$apiKey",
// //     );
// //     final res = await http.get(url);
// //     if (res.statusCode != 200) return null;

// //     final data = jsonDecode(res.body);
// //     final results = data['geocodingResults'];
// //     if (results is List && results.isNotEmpty) {
// //       final loc = results.first['geometry']['location'];
// //       if (loc != null)
// //         return LatLng(loc['lat'].toDouble(), loc['lng'].toDouble());
// //     }
// //     return null;
// //   }

// //   Future<List<LatLng>> _getRoute(LatLng start, LatLng end) async {
// //     final url = Uri.parse(
// //       "https://api.olamaps.io/routing/v1/directions?origin=${start.longitude},${start.latitude}&destination=${end.longitude},${end.latitude}&api_key=$apiKey",
// //     );
// //     final res = await http.post(
// //       url,
// //       headers: {"X-Request-Id": _uuid, "Content-Type": "application/json"},
// //       body: jsonEncode({}),
// //     );

// //     if (res.statusCode == 200) {
// //       final data = jsonDecode(res.body);
// //       final coords = data['routes']?['geometry']?['coordinates'];
// //       if (coords is List) {
// //         return coords.map<LatLng>((c) {
// //           return LatLng(c[1].toDouble(), c[0].toDouble());
// //         }).toList();
// //       }
// //     }
// //     return [];
// //   }

// //   Future<String> getExactAddress() async {
// //     try {
// //       LocationPermission permission = await Geolocator.checkPermission();
// //       if (permission == LocationPermission.denied) {
// //         permission = await Geolocator.requestPermission();
// //         if (permission == LocationPermission.deniedForever) {
// //           return "Location permission permanently denied.";
// //         }
// //       }

// //       bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
// //       if (!isServiceEnabled) return "Location services are disabled.";

// //       Position position = await Geolocator.getCurrentPosition(
// //         desiredAccuracy: LocationAccuracy.high,
// //       );

// //       List<Placemark> placemarks = await placemarkFromCoordinates(
// //         position.latitude,
// //         position.longitude,
// //       );

// //       if (placemarks.isNotEmpty) {
// //         Placemark place = placemarks.first;
// //         print("🗺 Location details (from geocoding package):");
// //         print("Street: ${place.street}");
// //         print("Area: ${place.subLocality}");
// //         print("City: ${place.locality}");
// //         print("State: ${place.administrativeArea}");
// //         print("Pin Code: ${place.postalCode}");
// //         print("Country: ${place.country}");

// //         String address =
// //             "${place.subLocality},${place.thoroughfare} "
// //             "${place.locality}-${place.postalCode}";

// //         return address;
// //       } else {
// //         return "Address not found.";
// //       }
// //     } catch (e) {
// //       return "Error getting location: $e";
// //     }
// //   }

// //   Future<void> _useCurrentLocationAndAddress() async {
// //     String locationName = await getExactAddress();
// //     if (locationName.startsWith("Error") || locationName.contains("disabled")) {
// //       ScaffoldMessenger.of(
// //         context,
// //       ).showSnackBar(SnackBar(content: Text(locationName)));
// //       return;
// //     }

// //     Position pos = await Geolocator.getCurrentPosition(
// //       desiredAccuracy: LocationAccuracy.high,
// //     );

// //     setState(() {
// //       _startLatLng = LatLng(pos.latitude, pos.longitude);
// //       _startController.text = locationName; // <-- Sets the address field
// //       _mapController.move(_startLatLng!, 13.0);
// //     });
// //   }

// //   Future<void> _showRoute() async {
// //     LatLng? start = (_startController.text.trim() == "Current Location")
// //         ? _startLatLng
// //         : await _geocode(_startController.text);
// //     LatLng? end = await _geocode(_endController.text);

// //     if (start == null || end == null) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text("Start or end location not found")),
// //       );
// //       return;
// //     }

// //     final route = await _getRoute(start, end);
// //     if (route.isEmpty) {
// //       ScaffoldMessenger.of(
// //         context,
// //       ).showSnackBar(SnackBar(content: Text("No route found")));
// //       return;
// //     }

// //     setState(() {
// //       _startLatLng = start;
// //       _endLatLng = end;
// //       _routePoints = route;
// //       final bounds = LatLngBounds.fromPoints(route);
// //       _mapController.move(bounds.center, 13);
// //     });
// //   }

// //   String get startLat => _startLatLng?.latitude.toStringAsFixed(2) ?? '12.93';
// //   String get startLng => _startLatLng?.longitude.toStringAsFixed(2) ?? '77.61';
// //   String get endLat => _endLatLng?.latitude.toStringAsFixed(2) ?? '0.00';
// //   String get endLng => _endLatLng?.longitude.toStringAsFixed(2) ?? '0.00';

// //   @override
// //   void dispose() {
// //     _startController.dispose();
// //     _endController.dispose();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: const Text("Ola Maps Route Tracker")),
// //       body: Column(
// //         children: [
// //           Padding(
// //             padding: const EdgeInsets.all(8.0),
// //             child: Row(
// //               children: [
// //                 Expanded(
// //                   child: TextField(
// //                     controller: _startController,
// //                     decoration: InputDecoration(
// //                       labelText: "Start Address",
// //                       border: OutlineInputBorder(),
// //                     ),
// //                   ),
// //                 ),
// //                 IconButton(
// //                   icon: Icon(Icons.my_location),
// //                   onPressed: () => _useCurrentLocationAndAddress(),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           Padding(
// //             padding: const EdgeInsets.all(8.0),
// //             child: TextField(
// //               controller: _endController,
// //               decoration: InputDecoration(
// //                 labelText: "Destination Address",
// //                 border: OutlineInputBorder(),
// //               ),
// //             ),
// //           ),
// //           Padding(
// //             padding: const EdgeInsets.symmetric(horizontal: 8.0),
// //             child: ElevatedButton(
// //               onPressed: _showRoute,
// //               child: Text("Show Route"),
// //             ),
// //           ),
// //           Expanded(
// //             child: FlutterMap(
// //               mapController: _mapController,
// //               options: MapOptions(
// //                 initialCenter: _startLatLng ?? LatLng(20.5937, 78.9629),
// //                 initialZoom: 10,
// //               ),
// //               children: [
// //                 TileLayer(
// //                   urlTemplate:
// //                       "https://api.olamaps.io/tiles/v1/styles/default-light-standard/static/auto/800x600.png"
// //                       "?marker=${startLng},${startLat}|red|scale:0.9"
// //                       "&api_key=$apiKey",
// //                   userAgentPackageName: 'com.example.olamap',
// //                 ),
// //                 //  "?path=$startLng,$startLat|$endLng,$endLat|width:4|stroke:%2300ff44"
// //                 // MarkerLayer(
// //                 //   markers: [
// //                 //     if (_startLatLng != null)
// //                 //       Marker(
// //                 //         point: _startLatLng!,
// //                 //         width: 40,
// //                 //         height: 40,
// //                 //         child: Icon(
// //                 //           Icons.location_on,
// //                 //           color: Colors.green,
// //                 //           size: 40,
// //                 //         ),
// //                 //       ),
// //                 //     if (_endLatLng != null)
// //                 //       Marker(
// //                 //         point: _endLatLng!,
// //                 //         width: 40,
// //                 //         height: 40,
// //                 //         child: Icon(Icons.flag, color: Colors.red, size: 40),
// //                 //       ),
// //                 //   ],
// //                 // ),
// //                 PolylineLayer(
// //                   polylines: [
// //                     if (_routePoints.isNotEmpty)
// //                       Polyline(
// //                         points: _routePoints,
// //                         color: Colors.blue,
// //                         strokeWidth: 4,
// //                       ),
// //                   ],
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:http/http.dart' as http;
// import 'package:geocoding/geocoding.dart';
// import 'package:uuid/uuid.dart';

// class RouteTrackingScreen extends StatefulWidget {
//   const RouteTrackingScreen({super.key});

//   @override
//   State<RouteTrackingScreen> createState() => _RouteTrackingScreenState();
// }

// class _RouteTrackingScreenState extends State<RouteTrackingScreen> {
//   final _startController = TextEditingController();
//   final _endController = TextEditingController();
//   final MapController _mapController = MapController();
//   final String apiKey = "hsTXqp1dSR4JBPsQlw46vE2RSWj1Q7k1CfPtbgx6";
//   final String _uuid = Uuid().v4();

//   LatLng? _startLatLng;
//   LatLng? _endLatLng;
//   List<LatLng> _routePoints = [];
//   StreamSubscription<Position>? _locationSubscription;
//   bool _isTracking = false;

//   @override
//   void initState() {
//     super.initState();
//     _startLocationTracking();
//   }

//   @override
//   void dispose() {
//     _startController.dispose();
//     _endController.dispose();
//     _locationSubscription?.cancel();
//     super.dispose();
//   }

//   Future<LatLng?> _geocode(String address) async {
//     if (address.trim().isEmpty) return null;
//     final url = Uri.parse(
//       "https://api.olamaps.io/places/v1/geocode?address=${Uri.encodeComponent(address)}&api_key=$apiKey",
//     );
//     final res = await http.get(url);
//     if (res.statusCode != 200) return null;

//     final data = jsonDecode(res.body);
//     final results = data['geocodingResults'];
//     if (results is List && results.isNotEmpty) {
//       final loc = results.first['geometry']['location'];
//       if (loc != null) {
//         return LatLng(loc['lat'].toDouble(), loc['lng'].toDouble());
//       }
//     }
//     return null;
//   }

//   Future<List<LatLng>> _getRoute(LatLng start, LatLng end) async {
//     final url = Uri.parse(
//       "https://api.olamaps.io/routing/v1/directions?origin=${start.longitude},${start.latitude}&destination=${end.longitude},${end.latitude}&api_key=$apiKey",
//     );
//     final res = await http.post(
//       url,
//       headers: {"X-Request-Id": _uuid, "Content-Type": "application/json"},
//       body: jsonEncode({}),
//     );

//     if (res.statusCode == 200) {
//       final data = jsonDecode(res.body);
//       final coords = data['routes']?[0]?['geometry']?['coordinates'];
//       if (coords is List) {
//         return coords.map<LatLng>((c) {
//           return LatLng(c[1].toDouble(), c[0].toDouble());
//         }).toList();
//       }
//     }
//     return [];
//   }

//   Future<String> _getExactAddress(LatLng position) async {
//     try {
//       List<Placemark> placemarks = await placemarkFromCoordinates(
//         position.latitude,
//         position.longitude,
//       );

//       if (placemarks.isNotEmpty) {
//         Placemark place = placemarks.first;
//         return "${place.subLocality}, ${place.thoroughfare} ${place.locality}-${place.postalCode}";
//       }
//     } catch (e) {
//       print("Error in reverse geocoding: $e");
//     }
//     return "Address not found";
//   }

//   Future<void> _checkAndRequestPermissions() async {
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.deniedForever) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text("Location permissions are permanently denied."),
//             ),
//           );
//         }
//         return;
//       }
//     }
//     if (permission == LocationPermission.denied) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Location permissions are denied.")),
//         );
//       }
//       return;
//     }
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Location services are disabled.")),
//         );
//       }
//     }
//   }

//   void _startLocationTracking() async {
//     await _checkAndRequestPermissions();

//     _locationSubscription =
//         Geolocator.getPositionStream(
//           locationSettings: const LocationSettings(
//             accuracy: LocationAccuracy.high,
//             distanceFilter: 10,
//           ),
//         ).listen(
//           (Position position) async {
//             final newLatLng = LatLng(position.latitude, position.longitude);
//             final address = await _getExactAddress(newLatLng);
//             setState(() {
//               _startLatLng = newLatLng;
//               _startController.text = address;
//               _mapController.move(newLatLng, _mapController.camera.zoom);
//               _isTracking = true;
//             });
//           },
//           onError: (e) {
//             if (mounted) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text("Error getting location: $e")),
//               );
//             }
//           },
//         );
//   }

//   void _stopLocationTracking() {
//     _locationSubscription?.cancel();
//     setState(() {
//       _isTracking = false;
//     });
//   }

//   Future<void> _showRoute() async {
//     if (_startLatLng == null || _endController.text.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Please select a start and end location."),
//         ),
//       );
//       return;
//     }

//     final end = await _geocode(_endController.text);
//     if (end == null) {
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text("Destination not found")));
//       }
//       return;
//     }

//     final route = await _getRoute(_startLatLng!, end);
//     if (route.isEmpty) {
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text("No route found")));
//       }
//       return;
//     }

//     setState(() {
//       _endLatLng = end;
//       _routePoints = route;
//       final bounds = LatLngBounds.fromPoints(route);
//       _mapController.move(bounds.center, 13.0);
//     });
//   }

//   String get startLat => _startLatLng?.latitude.toStringAsFixed(2) ?? '12.93';
//   String get startLng => _startLatLng?.longitude.toStringAsFixed(2) ?? '77.61';
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Ola Maps Route Tracker")),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _startController,
//                     readOnly: true,
//                     decoration: const InputDecoration(
//                       labelText: "Start Address (Current Location)",
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: Icon(
//                     _isTracking ? Icons.location_off : Icons.my_location,
//                   ),
//                   onPressed: _isTracking
//                       ? _stopLocationTracking
//                       : _startLocationTracking,
//                 ),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               controller: _endController,
//               decoration: const InputDecoration(
//                 labelText: "Destination Address",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8.0),
//             child: ElevatedButton(
//               onPressed: _showRoute,
//               child: const Text("Show Route"),
//             ),
//           ),
//           Expanded(
//             child: FlutterMap(
//               mapController: _mapController,
//               options: MapOptions(
//                 initialCenter: _startLatLng ?? const LatLng(20.5937, 78.9629),
//                 initialZoom: 10,
//               ),
//               children: [
//                 TileLayer(
//                   urlTemplate:
//                       "https://api.olamaps.io/tiles/v1/styles/default-light-standard/static/auto/800x600.png"
//                       "?marker=${startLng},${startLat}|red|scale:0.9"
//                       "&api_key=$apiKey",
//                   userAgentPackageName: 'com.example.olamap',
//                 ),
//                 PolylineLayer(
//                   polylines: [
//                     if (_routePoints.isNotEmpty)
//                       Polyline(
//                         points: _routePoints,
//                         color: Colors.blue,
//                         strokeWidth: 4,
//                       ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
