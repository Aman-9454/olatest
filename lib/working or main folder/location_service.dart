import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  static Future<LatLng?> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;

    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    return LatLng(pos.latitude, pos.longitude);
  }

  static Future<LatLng?> geocodeAddress(String address) async {
    // Implement your Ola Maps geocode API call here
    // Return LatLng or null
    return null;
  }

  static Future<String> getAddressFromLatLng(LatLng latLng) async {
    try {
      final placemarks = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isEmpty) return "Unknown";
      final p = placemarks.first;
      return [
        p.subLocality,
        p.thoroughfare,
        p.locality,
        p.postalCode
      ].where((e) => e != null && e.isNotEmpty).join(", ");
    } catch (_) {
      return "Unknown";
    }
  }
}
