// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: MapScreen(),
//     );
//   }
// }

// class MapScreen extends StatefulWidget {
//   const MapScreen({super.key});

//   @override
//   State<MapScreen> createState() => _MapScreenState();
// }

// class _MapScreenState extends State<MapScreen> {
//   GoogleMapController? _mapController;
//   LatLng _initialPosition = const LatLng(20.5937, 78.9629); // India center
//   final TextEditingController _startController = TextEditingController();
//   final Set<Marker> _markers = {};

//   @override
//   void initState() {
//     super.initState();
//     _checkPermission();
//   }

//   Future<void> _checkPermission() async {
//     LocationPermission permission = await Geolocator.requestPermission();
//     if (permission == LocationPermission.denied ||
//         permission == LocationPermission.deniedForever) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Location permission is required")),
//       );
//     } else {
//       // If permission granted, go to current location automatically
//       _goToCurrentLocation();
//     }
//   }

//   Future<void> _goToCurrentLocation() async {
//     try {
//       Position pos = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//       LatLng currentLatLng = LatLng(pos.latitude, pos.longitude);

//       // Place marker on current location
//       _setMarker(currentLatLng, "Current Location");

//       // Move camera to current location
//       _mapController?.animateCamera(
//         CameraUpdate.newLatLngZoom(currentLatLng, 14),
//       );

//       _startController.text = "Current Location";
//     } catch (e) {
//       print("Error getting current location: $e");
//     }
//   }

//   Future<void> _goToEnteredLocation() async {
//     String query = _startController.text.trim();
//     if (query.isEmpty) return;

//     try {
//       List<Location> locations = await locationFromAddress(query);
//       if (locations.isNotEmpty) {
//         LatLng target =
//             LatLng(locations.first.latitude, locations.first.longitude);
//         _setMarker(target, query);
//         _mapController?.animateCamera(
//           CameraUpdate.newLatLngZoom(target, 14),
//         );
//       }
//     } catch (e) {
//       print("Error finding location: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Location not found")),
//       );
//     }
//   }

//   void _setMarker(LatLng position, String title) {
//     setState(() {
//       _markers.clear();
//       _markers.add(
//         Marker(
//           markerId: MarkerId(title),
//           position: position,
//           infoWindow: InfoWindow(title: title),
//         ),
//       );
//     });
//   }
// @override
// void dispose() {
//   _mapController?.dispose();
//   _startController.dispose();
//   super.dispose();
// }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Google Map Example"),
//         backgroundColor: Colors.blue,
//       ),
//       body: SafeArea(
//         child: Stack(
//           children: [
//             GoogleMap(
//               onMapCreated: (controller) => _mapController = controller,
//               initialCameraPosition: CameraPosition(
//                 target: _initialPosition,
//                 zoom: 5,
//               ),
//               markers: _markers,
//               myLocationEnabled: true,
//               myLocationButtonEnabled: true,
//             ),
//             Positioned(
//               top: 10,
//               left: 10,
//               right: 10,
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _startController,
//                       decoration: InputDecoration(
//                         hintText: "Enter location",
//                         fillColor: Colors.white,
//                         filled: true,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         contentPadding:
//                             const EdgeInsets.symmetric(horizontal: 10),
//                       ),
//                     ),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.search),
//                     onPressed: _goToEnteredLocation,
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.my_location),
//                     onPressed: _goToCurrentLocation,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
