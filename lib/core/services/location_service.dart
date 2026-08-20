import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'package:public_pulse/model/location_suggestion.dart';

class LocationService {
  String get _geoapifyApiKey {
    final key = dotenv.env['GEOAPIFY_API_KEY'];

    if (key == null || key.trim().isEmpty) {
      throw Exception('GEOAPIFY_API_KEY is missing from .env');
    }

    return key.trim();
  }

  // ============================================================
  // SEARCH LOCATION - GEOAPIFY
  // ============================================================

  Future<List<LocationSuggestion>> searchLocations(String query) async {
    final searchText = query.trim();

    if (searchText.length < 2) {
      return [];
    }

    try {
      final uri = Uri.https('api.geoapify.com', '/v1/geocode/autocomplete', {
        'text': searchText,
        'format': 'json',
        'limit': '8',
        'lang': 'en',
        'apiKey': _geoapifyApiKey,
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          'Location search failed '
          '(${response.statusCode})',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        return [];
      }

      final rawResults = decoded['results'];

      if (rawResults is! List) {
        return [];
      }

      final results = rawResults
          .whereType<Map>()
          .map(
            (item) => LocationSuggestion.fromGeoapify(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((item) => item.formattedAddress.isNotEmpty)
          .toList();

      return results;
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================
  // CURRENT PHONE LOCATION
  // ============================================================

  Future<LocationSuggestion> getCurrentLocation() async {
    try {
      // ========================================================
      // 1. CHECK WHETHER GPS IS ENABLED
      // ========================================================

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Location services are disabled. '
          'Please turn on GPS.',
        );
      }

      // ========================================================
      // 2. CHECK LOCATION PERMISSION
      // ========================================================

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is permanently denied. '
          'Please enable it from app settings.',
        );
      }

      // ========================================================
      // 3. GET GPS LATITUDE / LONGITUDE
      // ========================================================

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      // ========================================================
      // 4. CONVERT GPS TO READABLE ADDRESS
      // ========================================================

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      // If Android cannot resolve the address,
      // still return the coordinates.
      if (placemarks.isEmpty) {
        return LocationSuggestion(
          name: 'Current Location',
          formattedAddress:
              '${position.latitude}, '
              '${position.longitude}',
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }

      final place = placemarks.first;

      // ========================================================
      // 5. BUILD CLEAN ADDRESS
      // ========================================================

      final addressParts = <String>[
        if (_isValid(place.name)) place.name!.trim(),

        if (_isValid(place.street)) place.street!.trim(),

        if (_isValid(place.subLocality)) place.subLocality!.trim(),

        if (_isValid(place.locality)) place.locality!.trim(),

        if (_isValid(place.subAdministrativeArea))
          place.subAdministrativeArea!.trim(),

        if (_isValid(place.administrativeArea))
          place.administrativeArea!.trim(),

        if (_isValid(place.postalCode)) place.postalCode!.trim(),

        if (_isValid(place.country)) place.country!.trim(),
      ];

      // Remove duplicate pieces.
      final uniqueParts = <String>[];

      for (final part in addressParts) {
        if (!uniqueParts.contains(part)) {
          uniqueParts.add(part);
        }
      }

      final formattedAddress = uniqueParts.join(', ');

      // Pick a short title for UI.
      String name = 'Current Location';

      if (_isValid(place.name)) {
        name = place.name!.trim();
      } else if (_isValid(place.locality)) {
        name = place.locality!.trim();
      } else if (_isValid(place.subLocality)) {
        name = place.subLocality!.trim();
      }

      return LocationSuggestion(
        name: name,
        formattedAddress: formattedAddress.isEmpty
            ? 'Current Location'
            : formattedAddress,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================
  // HELPER
  // ============================================================

  bool _isValid(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
