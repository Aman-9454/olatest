// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:geolocator/geolocator.dart';

// class OlaMapScreen extends StatefulWidget {
//   @override
//   State<OlaMapScreen> createState() => _OlaMapScreenState();
// }

// class _OlaMapScreenState extends State<OlaMapScreen> {
//   GoogleMapController? _mapController;
//   Set<Marker> _markers = {};
//   Set<Polyline> _polylines = {};
//   LatLng _initialPosition = LatLng(20.5937, 78.9629); // India center
//   final String _olaApiKey = "hsTXqp1dSR4JBPsQlw46vE2RSWj1Q7k1CfPtbgx6";

//   LatLng? _origin;
//   LatLng? _destination;

//   Future<void> _getCurrentLocation() async {
//     Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high);
//     setState(() {
//       _origin = LatLng(position.latitude, position.longitude);
//       _markers.add(
//         Marker(
//           markerId: MarkerId("origin"),
//           position: _origin!,
//           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//         ),
//       );
//     });
//     _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_origin!, 14));
//   }

//   Future<void> _setDestinationFromAddress(String address) async {
//     final url =
//         "https://api.olamaps.io/places/v1/geocode?address=${Uri.encodeComponent(address)}&api_key=$_olaApiKey";
//     final response = await http.get(Uri.parse(url));

//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       final loc = data['geocodingResults'][0]['geometry']['location'];
//       _destination = LatLng(loc['lat'], loc['lng']);

//       setState(() {
//         _markers.add(
//           Marker(
//             markerId: MarkerId("destination"),
//             position: _destination!,
//             icon:
//                 BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
//           ),
//         );
//       });

//       _getRoute();
//     }
//   }

//   Future<void> _getRoute() async {
//     if (_origin == null || _destination == null) return;

//     final url =
//         "https://api.olamaps.io/routes/v1/directions?origin=${_origin!.latitude},${_origin!.longitude}&destination=${_destination!.latitude},${_destination!.longitude}&mode=driving&snap_to_road=true&api_key=$_olaApiKey";

//     final response = await http.get(Uri.parse(url));

//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       final points = data['routes'][0]['overview_polyline']['points'];

//       List<LatLng> routeCoords = _decodePolyline(points);
//       setState(() {
//         _polylines.add(
//           Polyline(
//             polylineId: PolylineId("route"),
//             points: routeCoords,
//             color: Colors.blue,
//             width: 5,
//           ),
//         );
//       });
//     }
//   }

//   List<LatLng> _decodePolyline(String encoded) {
//     List<LatLng> poly = [];
//     int index = 0, len = encoded.length;
//     int lat = 0, lng = 0;

//     while (index < len) {
//       int b, shift = 0, result = 0;
//       do {
//         b = encoded.codeUnitAt(index++) - 63;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
//       lat += dlat;

//       shift = 0;
//       result = 0;
//       do {
//         b = encoded.codeUnitAt(index++) - 63;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
//       lng += dlng;

//       poly.add(LatLng(lat / 1E5, lng / 1E5));
//     }
//     return poly;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Ola Map (Native)")),
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition:
//                 CameraPosition(target: _initialPosition, zoom: 5),
//             markers: _markers,
//             polylines: _polylines,
//             onMapCreated: (controller) => _mapController = controller,
//             myLocationEnabled: true,
//           ),
//           Positioned(
//             top: 10,
//             left: 10,
//             right: 10,
//             child: Column(
//               children: [
//                 ElevatedButton(
//                     onPressed: _getCurrentLocation,
//                     child: Text("Set Origin (Current Location)")),
//                 TextField(
//                   decoration: InputDecoration(
//                       hintText: "Enter destination address",
//                       filled: true,
//                       fillColor: Colors.white),
//                   onSubmitted: _setDestinationFromAddress,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
