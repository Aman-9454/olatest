// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:http/http.dart' as http;
// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Origin→Destination Tracker',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
//         useMaterial3: true,
//       ),
//       home: const MapTrackPage(),
//     );
//   }
// }

// class MapTrackPage extends StatefulWidget {
//   const MapTrackPage({super.key});

//   @override
//   State<MapTrackPage> createState() => _MapTrackPageState();
// }

// class _MapTrackPageState extends State<MapTrackPage> {
//   GoogleMapController? _mapController;

//   final Set<Marker> _markers = {};
//   final Set<Polyline> _polylines = {};

//   LatLng? _originLatLng; // your live location
//   LatLng? _destinationLatLng; // user long-press

//   StreamSubscription<Position>? _positionSub;

//   // TODO: paste your Google API key (Directions API enabled)
//   static const String _googleApiKey = "AIzaSyBzkgWrbBZwkzIpNyGlqoj85Ig2JNyUb8E";

//   String? _distanceText; // from Directions API leg
//   String? _durationText; // from Directions API leg

//   bool _tracking = false;

//   @override
//   void initState() {
//     super.initState();
//     _initLocation();
//   }

//   @override
//   void dispose() {
//     _positionSub?.cancel();
//     _mapController?.dispose();
//     super.dispose();
//   }

//   Future<void> _initLocation() async {
//     final permitted = await _ensureLocationPermission();
//     if (!permitted) return;

//     final pos = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );
//     _originLatLng = LatLng(pos.latitude, pos.longitude);

//     _addOrUpdateOriginMarker();
//     _animateTo(_originLatLng!, zoom: 16);
//     setState(() {});
//   }

//   Future<bool> _ensureLocationPermission() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       await Geolocator.openLocationSettings();
//       serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) return false;
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) return false;
//     }
//     if (permission == LocationPermission.deniedForever) {
//       return false;
//     }
//     return true;
//   }

//   void _addOrUpdateOriginMarker() {
//     if (_originLatLng == null) return;
//     final marker = Marker(
//       markerId: const MarkerId('origin'),
//       position: _originLatLng!,
//       icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
//       infoWindow: const InfoWindow(title: 'You (Origin)'),
//     );
//     _markers.removeWhere((m) => m.markerId == marker.markerId);
//     _markers.add(marker);
//   }

//   void _addOrUpdateDestinationMarker() {
//     if (_destinationLatLng == null) return;
//     final marker = Marker(
//       markerId: const MarkerId('destination'),
//       position: _destinationLatLng!,
//       icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//       infoWindow: const InfoWindow(title: 'Destination'),
//     );
//     _markers.removeWhere((m) => m.markerId == marker.markerId);
//     _markers.add(marker);
//   }

//   Future<void> _animateTo(LatLng target, {double zoom = 15}) async {
//     if (_mapController == null) return;
//     await _mapController!.animateCamera(
//       CameraUpdate.newCameraPosition(
//         CameraPosition(target: target, zoom: zoom),
//       ),
//     );
//   }

// Future<void> _buildRoute() async {
//   if (_originLatLng == null || _destinationLatLng == null) return;

//   final polylinePoints = PolylinePoints(apiKey: _googleApiKey);
//   final result = await polylinePoints.getRouteBetweenCoordinates(
//     request: PolylineRequest(
//       origin: PointLatLng(_originLatLng!.latitude, _originLatLng!.longitude),
//       destination: PointLatLng(
//         _destinationLatLng!.latitude,
//         _destinationLatLng!.longitude,
//       ),
//       mode: TravelMode.driving,
//     ),
//   );

//   if (!mounted) return;

//   if (result.points.isNotEmpty) {
//     final polylineCoordinates =
//         result.points.map((p) => LatLng(p.latitude, p.longitude)).toList();

//     _polylines
//       ..removeWhere((p) => p.polylineId.value == 'route')
//       ..add(Polyline(
//         polylineId: const PolylineId('route'),
//         width: 5,
//         color: Colors.blue,
//         points: polylineCoordinates,
//       ));
//   }

//   setState(() {});
// }
//   void _startTracking() {
//     if (_tracking) return;
//     _tracking = true;

//     _positionSub = Geolocator.getPositionStream(
//       locationSettings: const LocationSettings(
//         accuracy: LocationAccuracy.bestForNavigation,
//         distanceFilter: 8, // meters
//       ),
//     ).listen((pos) async {
//       _originLatLng = LatLng(pos.latitude, pos.longitude);
//       _addOrUpdateOriginMarker();
//       await _buildRoute();
//       // Keep camera following the user a bit ahead
//       if (_originLatLng != null) {
//         _animateTo(_originLatLng!, zoom: 16);
//       }
//     });
//     setState(() {});
//   }

//   void _stopTracking() {
//     _tracking = false;
//     _positionSub?.cancel();
//     setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     final hasDestination = _destinationLatLng != null;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Track Origin → Destination'),
//         actions: [
//           if (_distanceText != null && _durationText != null)
//             Padding(
//               padding: const EdgeInsets.only(right: 12.0),
//               child: Center(
//                 child: Text(
//                   '${_distanceText!} • ${_durationText!}',
//                   style: const TextStyle(fontWeight: FontWeight.w600),
//                 ),
//               ),
//             ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition: const CameraPosition(
//               target: LatLng(28.6139, 77.2090), // Delhi fallback
//               zoom: 12,
//             ),
//             onMapCreated: (c) => _mapController = c,
//             myLocationEnabled: true,
//             myLocationButtonEnabled: true,
//             markers: _markers,
//             polylines: _polylines,
//             onLongPress: (latLng) async {
//               _destinationLatLng = latLng;
//               _addOrUpdateDestinationMarker();
//               await _buildRoute();
//               if (_destinationLatLng != null) {
//                 _animateTo(_destinationLatLng!, zoom: 14);
//               }
//             },
//           ),
//           Positioned(
//             left: 16,
//             right: 16,
//             bottom: 24,
//             child: Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     icon: Icon(_tracking ? Icons.stop : Icons.play_arrow),
//                     label: Text(_tracking ? 'Stop Tracking' : 'Start Tracking'),
//                     onPressed: hasDestination
//                         ? () {
//                             if (_tracking) {
//                               _stopTracking();
//                             } else {
//                               _startTracking();
//                             }
//                           }
//                         : null,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     icon: const Icon(Icons.route),
//                     label: const Text('Clear Route'),
//                     onPressed: () {
//                       _destinationLatLng = null;
//                       _distanceText = null;
//                       _durationText = null;
//                       _polylines.clear();
//                       _markers.removeWhere(
//                           (m) => m.markerId.value == 'destination');
//                       setState(() {});
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           )
//         ],
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () async {
//           // Recenter to your current location
//           if (_originLatLng != null) {
//             await _animateTo(_originLatLng!, zoom: 16);
//           }
//         },
//         icon: const Icon(Icons.my_location),
//         label: const Text('Me'),
//       ),
//     );
//   }
// }
