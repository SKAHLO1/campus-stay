import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static Future<bool> requestLocationPermission() async {
    final PermissionStatus status = await Permission.location.request();
    return status == PermissionStatus.granted;
  }

  static Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      double distanceInKm = distanceInMeters / 1000;
      return '${distanceInKm.toStringAsFixed(1)} km';
    }
  }

  static Future<List<String>> getLocationSuggestions(String query) async {
    // This is a simplified version. In production, you might want to use
    // Google Places API or another geocoding service for better results
    List<String> suggestions = [
      'New York, NY',
      'Los Angeles, CA',
      'Chicago, IL',
      'Houston, TX',
      'Phoenix, AZ',
      'Philadelphia, PA',
      'San Antonio, TX',
      'San Diego, CA',
      'Dallas, TX',
      'San Jose, CA',
      'Austin, TX',
      'Jacksonville, FL',
      'Fort Worth, TX',
      'Columbus, OH',
      'Charlotte, NC',
      'San Francisco, CA',
      'Indianapolis, IN',
      'Seattle, WA',
      'Denver, CO',
      'Washington, DC',
      'Boston, MA',
      'El Paso, TX',
      'Detroit, MI',
      'Nashville, TN',
      'Portland, OR',
      'Memphis, TN',
      'Oklahoma City, OK',
      'Las Vegas, NV',
      'Louisville, KY',
      'Baltimore, MD',
      'Milwaukee, WI',
      'Albuquerque, NM',
      'Tucson, AZ',
      'Fresno, CA',
      'Mesa, AZ',
      'Sacramento, CA',
      'Atlanta, GA',
      'Kansas City, MO',
      'Colorado Springs, CO',
      'Miami, FL',
      'Raleigh, NC',
      'Omaha, NE',
      'Long Beach, CA',
      'Virginia Beach, VA',
      'Oakland, CA',
      'Minneapolis, MN',
      'Tulsa, OK',
      'Arlington, TX',
      'Tampa, FL',
      'New Orleans, LA',
    ];

    if (query.isEmpty) {
      return suggestions.take(10).toList();
    }

    return suggestions
        .where((location) => location.toLowerCase().contains(query.toLowerCase()))
        .take(10)
        .toList();
  }
}
