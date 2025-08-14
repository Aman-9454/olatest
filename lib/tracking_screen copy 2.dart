// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:geolocator/geolocator.dart';

// class RouteTrackingScreen extends StatefulWidget {
//   const RouteTrackingScreen({super.key});

//   @override
//   State<RouteTrackingScreen> createState() => _RouteTrackingScreenState();
// }

// class _RouteTrackingScreenState extends State<RouteTrackingScreen> {
//   late WebViewController _controller;
//   final _startController = TextEditingController();
//   final _endController = TextEditingController();

//   Map<String, double>? _currentCoords;

//   final String apiKey = "hsTXqp1dSR4JBPsQlw46vE2RSWj1Q7k1CfPtbgx6";

//   Future<Map<String, double>?> _geocode(String address) async {
//     final cleanAddress = address.trim();
//     print("Geocoding request for: $cleanAddress");

//     final url =
//         "https://api.olamaps.io/places/v1/geocode?address=${Uri.encodeComponent(cleanAddress)}&api_key=$apiKey";
//     print("Request URL: $url");

//     final res = await http.get(Uri.parse(url));
//     print("Response status: ${res.statusCode}");
//     print("Response body: ${res.body}");

//     if (res.statusCode == 200) {
//       final data = jsonDecode(res.body);
//       if (someList != null && someList.isNotEmpty) {
//         final coords = data["features"][0]["geometry"]["coordinates"];
//         return {"lng": coords[0], "lat": coords[1]};
//       }
//     }
//     return null;
//   }

//   // Future<Map<String, double>?> _geocode(String address) async {
//   //   final url =
//   //       "https://api.olamaps.io/places/geocode?text=${Uri.encodeComponent(address)}&api_key=$apiKey";
//   //   print("Request URL: $url");

//   //   final res = await http.get(Uri.parse(url));
//   //   print("Response status: ${res.statusCode}");
//   //   print("Response body: ${res.body}");
//   //   if (res.statusCode == 200) {
//   //     final data = jsonDecode(res.body);
//   //     if (data["features"].isNotEmpty) {
//   //       final coords = data["features"][0]["geometry"]["coordinates"];
//   //       return {"lng": coords[0], "lat": coords[1]};
//   //     }
//   //   }
//   //   return null;
//   // }

//   Future<List<List<double>>> _getRoute(
//     double startLat,
//     double startLng,
//     double endLat,
//     double endLng,
//   ) async {
//     final url =
//         "https://api.olamaps.io/directions?origin=$startLng,$startLat&destination=$endLng,$endLat&api_key=$apiKey";
//     final res = await http.get(Uri.parse(url));
//     final data = jsonDecode(res.body);
//     List coords = data["routes"][0]["geometry"]["coordinates"];
//     return coords.map<List<double>>((c) => [c[1], c[0]]).toList();
//   }

//   Future<void> _getCurrentLocation() async {
//     LocationPermission permission = await Geolocator.requestPermission();
//     if (permission == LocationPermission.denied ||
//         permission == LocationPermission.deniedForever) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Location permission is required")),
//       );
//       return;
//     }
//     Position pos = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );
//     setState(() {
//       _currentCoords = {"lat": pos.latitude, "lng": pos.longitude};
//       _startController.text = "Current Location";
//       print("Current location: $_currentCoords");
//     });
//   }

//   Future<void> _showRouteOnMap() async {
//     Map<String, double>? startLoc;

//     if (_currentCoords != null && _startController.text == "Current Location") {
//       startLoc = _currentCoords;
//     } else {
//       startLoc = await _geocode(_startController.text);
//     }

//     final endLoc = await _geocode(_endController.text);

//     if (startLoc == null) {
//       debugPrint("Start location not found");
//     }
//     if (endLoc == null) {
//       debugPrint("End location not found");
//     }

//     if (startLoc == null || endLoc == null) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Location not found")));
//       return;
//     }

//     final routeCoords = await _getRoute(
//       startLoc["lat"]!,
//       startLoc["lng"]!,
//       endLoc["lat"]!,
//       endLoc["lng"]!,
//     );

//     await _controller.runJavaScript(
//       'showRoute(${startLoc["lat"]}, ${startLoc["lng"]}, ${endLoc["lat"]}, ${endLoc["lng"]}, \'${jsonEncode(routeCoords)}\')',
//     );
//   }

//   // Future<void> _showRouteOnMap() async {
//   //   Map<String, double>? startLoc;

//   //   if (_startController.text.trim().toLowerCase() == "current location" &&
//   //       _currentCoords != null) {
//   //     startLoc = _currentCoords;
//   //   } else {
//   //     startLoc = await _geocode(_startController.text);
//   //   }

//   //   final endLoc = await _geocode(_endController.text);

//   //   if (startLoc == null || endLoc == null) {
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(content: Text("Location not found")),
//   //     );
//   //     return;
//   //   }

//   //   final routeCoords = await _getRoute(
//   //     startLoc["lat"]!,
//   //     startLoc["lng"]!,
//   //     endLoc["lat"]!,
//   //     endLoc["lng"]!,
//   //   );

//   //   await _controller.runJavaScript(
//   //     'showRoute(${startLoc["lat"]}, ${startLoc["lng"]}, ${endLoc["lat"]}, ${endLoc["lng"]}, \'${jsonEncode(routeCoords)}\')',
//   //   );
//   // }

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
//                     decoration: const InputDecoration(
//                       labelText: "Start Location",
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.my_location),
//                   onPressed: _getCurrentLocation,
//                 ),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               controller: _endController,
//               decoration: const InputDecoration(
//                 labelText: "End Location",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: _showRouteOnMap,
//             child: const Text("Show Route"),
//           ),
//           Expanded(
//             child: WebViewWidget(
//               controller: _controller = WebViewController()
//                 ..setJavaScriptMode(JavaScriptMode.unrestricted)
//                 ..loadFlutterAsset("lib/assets/ola_map.html"),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
