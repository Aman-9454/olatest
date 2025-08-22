import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:olamap/working%20or%20main%20folder/direction_info.dart';
import 'package:olamap/working%20or%20main%20folder/location_service.dart';
import 'package:olamap/working%20or%20main%20folder/route_service.dart';

class MapTrackPage extends StatefulWidget {
  const MapTrackPage({super.key});

  @override
  State<MapTrackPage> createState() => _MapTrackPageState();
}

class _MapTrackPageState extends State<MapTrackPage> {
  GoogleMapController? _mapController;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  LatLng? _originLatLng;
  LatLng? _destinationLatLng;
  StreamSubscription<Position>? _positionSub;

  final _locationService = LocationService();
  final _routeService = RouteService();

  bool _tracking = false;
  DirectionsInfo? _directionsInfo;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final pos = await _locationService.getInitialLocation();
    if (pos == null) return;
    _originLatLng = LatLng(pos.latitude, pos.longitude);
    _addOrUpdateOriginMarker();
    _animateTo(_originLatLng!, zoom: 16);
    setState(() {});
  }

  void _addOrUpdateOriginMarker() {
    if (_originLatLng == null) return;
    final marker = Marker(
      markerId: const MarkerId('origin'),
      position: _originLatLng!,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(title: 'You (Origin)'),
    );
    _markers.removeWhere((m) => m.markerId == marker.markerId);
    _markers.add(marker);
  }

  void _addOrUpdateDestinationMarker() {
    if (_destinationLatLng == null) return;
    final marker = Marker(
      markerId: const MarkerId('destination'),
      position: _destinationLatLng!,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(title: 'Destination'),
    );
    _markers.removeWhere((m) => m.markerId == marker.markerId);
    _markers.add(marker);
  }

  Future<void> _buildRoute() async {
    if (_originLatLng == null || _destinationLatLng == null) return;

    final polyline = await _routeService.buildPolyline(_originLatLng!, _destinationLatLng!);
    if (polyline != null) {
      _polylines.removeWhere((p) => p.polylineId.value == 'route');
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: polyline.points,
          color: Colors.blue,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    }

    _directionsInfo = await _routeService.fetchDirectionsInfo(_originLatLng!, _destinationLatLng!);

    // Animate camera to show both origin and destination
    _animateToBounds(_originLatLng!, _destinationLatLng!);

    setState(() {});
  }

  Future<void> _animateToBounds(LatLng origin, LatLng destination) async {
    if (_mapController == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        origin.latitude < destination.latitude ? origin.latitude : destination.latitude,
        origin.longitude < destination.longitude ? origin.longitude : destination.longitude,
      ),
      northeast: LatLng(
        origin.latitude > destination.latitude ? origin.latitude : destination.latitude,
        origin.longitude > destination.longitude ? origin.longitude : destination.longitude,
      ),
    );

    await _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  Future<void> _animateTo(LatLng target, {double zoom = 15}) async {
    if (_mapController == null) return;
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ),
    );
  }

  void _startTracking() {
    if (_tracking) return;
    _tracking = true;

    _positionSub = _locationService.locationStream().listen((pos) async {
      _originLatLng = LatLng(pos.latitude, pos.longitude);
      _addOrUpdateOriginMarker();

      if (_destinationLatLng != null) {
        await _buildRoute(); // Update polyline dynamically
      } else {
        _animateTo(_originLatLng!, zoom: 16); // Just move to origin if no destination
      }
    }, onError: (error) {
      print("Location stream error: $error");
      _stopTracking();
    });

    setState(() {});
  }

  void _stopTracking() {
    _tracking = false;
    _positionSub?.cancel();
    _positionSub = null;
    setState(() {});
  }

  void _clearRoute() {
    setState(() {
      _destinationLatLng = null;
      _directionsInfo = null;
      _polylines.clear();
      _markers.removeWhere((m) => m.markerId.value == 'destination');
      _stopTracking();
      if (_originLatLng != null) {
        _animateTo(_originLatLng!, zoom: 16);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasDestination = _destinationLatLng != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Origin → Destination'),
        actions: [
          if (_directionsInfo != null)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Center(
                child: Text(
                  '${_directionsInfo!.distance} • ${_directionsInfo!.duration}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(28.6139, 77.2090),
                zoom: 12,
              ),
              onMapCreated: (c) => _mapController = c,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _markers,
              polylines: _polylines,
              onLongPress: (latLng) async {
                _destinationLatLng = latLng;
                _addOrUpdateDestinationMarker();
                await _buildRoute();
              },
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(_tracking ? Icons.stop : Icons.play_arrow),
                      label: Text(_tracking ? 'Stop Tracking' : 'Start Tracking'),
                      onPressed: hasDestination
                          ? () {
                              if (_tracking) {
                                _stopTracking();
                              } else {
                                _startTracking();
                              }
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.route),
                      label: const Text('Clear Route'),
                      onPressed: hasDestination ? _clearRoute : null,
                    ),
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
