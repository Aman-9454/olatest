import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart'
    hide LatLng, LatLngBounds;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  static const String _googleApiKey = "AIzaSyBzkgWrbBZwkzIpNyGlqoj85Ig2JNyUb8E";
  late FlutterGooglePlacesSdk _places;

  LatLng? _currentLatLng;
  LatLng? _originLatLng;
  LatLng? _destinationLatLng;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  List<AutocompletePrediction> _originPredictions = [];
  List<AutocompletePrediction> _destinationPredictions = [];

  @override
  void initState() {
    super.initState();
    _places = FlutterGooglePlacesSdk(_googleApiKey);
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLatLng = LatLng(position.latitude, position.longitude);
      _markers.add(
        Marker(
          markerId: const MarkerId("current"),
          position: _currentLatLng!,
          infoWindow: const InfoWindow(title: "My Location"),
        ),
      );
    });

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(_currentLatLng!, 14));
    print(
      "Current Position: ${_currentLatLng!.latitude}, ${_currentLatLng!.longitude}",
    );
  }

  Future<void> _searchPlaces(String query, bool isOrigin) async {
    if (query.isEmpty) {
      setState(() {
        if (isOrigin)
          _originPredictions = [];
        else
          _destinationPredictions = [];
      });
      return;
    }

    final result = await _places.findAutocompletePredictions(
      query,
      countries: ["in"],
    );
    setState(() {
      if (isOrigin)
        _originPredictions = result.predictions;
      else
        _destinationPredictions = result.predictions;
    });
  }

  Future<void> _selectPlace(
    AutocompletePrediction prediction,
    bool isOrigin,
  ) async {
    final details = await _places.fetchPlace(
      prediction.placeId,
      fields: [PlaceField.Location],
    );

    if (details.place?.latLng != null) {
      final lat = details.place!.latLng!.lat;
      final lng = details.place!.latLng!.lng;

      setState(() {
        if (isOrigin) {
          _originLatLng = LatLng(lat, lng);
          _originController.text = prediction.primaryText;
          _originPredictions = [];
          _markers.add(
            Marker(
              markerId: const MarkerId("origin"),
              position: _originLatLng!,
              infoWindow: const InfoWindow(title: "Origin"),
            ),
          );
          print("Origin selected: $lat, $lng");
        } else {
          _destinationLatLng = LatLng(lat, lng);
          _destinationController.text = prediction.primaryText;
          _destinationPredictions = [];
          _markers.add(
            Marker(
              markerId: const MarkerId("destination"),
              position: _destinationLatLng!,
              infoWindow: const InfoWindow(title: "Destination"),
            ),
          );
          print("Destination selected: $lat, $lng");
        }
      });

      if (_originLatLng != null && _destinationLatLng != null) {
        _buildRoute();
      }

      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14),
      );
    }
  }

  Future<void> _buildRoute() async {
    if (_originLatLng == null || _destinationLatLng == null) return;

    final polylinePoints = PolylinePoints();
    final result = await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(_originLatLng!.latitude, _originLatLng!.longitude),
        destination: PointLatLng(
          _destinationLatLng!.latitude,
          _destinationLatLng!.longitude,
        ),
        mode: TravelMode.driving,
      ),
      googleApiKey: _googleApiKey,
    );

    if (result.points.isNotEmpty) {
      final polylineCoordinates = result.points
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();

      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            width: 5,
            color: Colors.blue,
            points: polylineCoordinates,
          ),
        );
      });

      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              _originLatLng!.latitude <= _destinationLatLng!.latitude
                  ? _originLatLng!.latitude
                  : _destinationLatLng!.latitude,
              _originLatLng!.longitude <= _destinationLatLng!.longitude
                  ? _originLatLng!.longitude
                  : _destinationLatLng!.longitude,
            ),
            northeast: LatLng(
              _originLatLng!.latitude >= _destinationLatLng!.latitude
                  ? _originLatLng!.latitude
                  : _destinationLatLng!.latitude,
              _originLatLng!.longitude >= _destinationLatLng!.longitude
                  ? _originLatLng!.longitude
                  : _destinationLatLng!.longitude,
            ),
          ),
          50,
        ),
      );
    }
  }

  Widget _buildPredictionList(
    List<AutocompletePrediction> predictions,
    bool isOrigin,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: predictions.length,
      itemBuilder: (context, index) {
        final prediction = predictions[index];
        return ListTile(
          title: Text(prediction.primaryText),
          subtitle: Text(prediction.secondaryText ?? ""),
          onTap: () => _selectPlace(prediction, isOrigin),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Google Maps Route")),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _originController,
                  decoration: InputDecoration(
                    labelText: "Origin",
                    prefixIcon: const Icon(Icons.my_location),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (value) => _searchPlaces(value, true),
                ),
                // Origin predictions
                if (_originPredictions.isNotEmpty)
                  Container(
                    height: 100,
                    child: _buildPredictionList(_originPredictions, true),
                  ),
              ],
            ),
          ),

          // ---------------- Destination Field ----------------
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    labelText: "Destination",
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (value) => _searchPlaces(value, false),
                ),
                // Destination predictions
                if (_destinationPredictions.isNotEmpty)
                  Container(
                    height: 100,
                    child: _buildPredictionList(_destinationPredictions, false),
                  ),
              ],
            ),
          ),

            Expanded(
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(20.5937, 78.9629),
                  zoom: 4,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                markers: _markers,
                polylines: _polylines,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
              ),
            ), 
          ],
        ),
      ),
    );
  }
}
