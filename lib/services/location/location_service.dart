import 'dart:async';
import 'dart:developer';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/constant.dart';
import 'user_location_hive.dart';
import '../../model/user_location/user_location_model.dart';

class LocationService {
  
  // In lib/utils/location/location_service.dart
  static Future<bool> ensureServiceAndPermission() async {
    bool servicesOn = await Geolocator.isLocationServiceEnabled();
    if (!servicesOn) {
      await Geolocator.openLocationSettings();
      servicesOn = await Geolocator.isLocationServiceEnabled();
      if (!servicesOn) return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      await openAppSettings();
      permission = await Geolocator.checkPermission();
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  static Future<UserLocation?> requestAndStoreLocationWithRetry() async {
    bool ready = await ensureServiceAndPermission();
    if (!ready) return null;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          timeLimit: Duration(seconds: 10)
        ),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude, position.longitude,
      );
      final p = placemarks.isNotEmpty ? placemarks[0] : Placemark();
      final fullAddress = [
        p.street, p.subLocality, p.locality, p.administrativeArea,
      ].where((e) => e != null && e.isNotEmpty).join(', ');

      final userLocation = UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        fullAddress: fullAddress.isEmpty ? "" : fullAddress,
        area: p.subLocality ?? '',
        city: p.locality ?? '',
        state: p.administrativeArea ?? '',
        country: p.country ?? '',
        pincode: p.postalCode ?? '',
        landmark: p.name ?? '',
      );

      await HiveLocationHelper.setCurrentUserLocation(userLocation);
      AppConstant.updateDefaultLocation(
        position.latitude.toString(),
        position.longitude.toString()
      );
      return userLocation;
    } catch (_) {
      // One controlled retry
      final readyAgain = await ensureServiceAndPermission();
      if (!readyAgain) return null;
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
            timeLimit: Duration(seconds: 15),
          ),
        );
        final placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude,
        );
        final p = placemarks.isNotEmpty ? placemarks[0] : Placemark();
        final fullAddress = [
          p.street, p.subLocality, p.locality, p.administrativeArea,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        final userLocation = UserLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          fullAddress: fullAddress.isEmpty ? "" : fullAddress,
          area: p.subLocality ?? '',
          city: p.locality ?? '',
          state: p.administrativeArea ?? '',
          country: p.country ?? '',
          pincode: p.postalCode ?? '',
          landmark: p.name ?? '',
        );

        await HiveLocationHelper.setCurrentUserLocation(userLocation);
        AppConstant.updateDefaultLocation(
          position.latitude.toString(),
          position.longitude.toString()
        );
        return userLocation;
      } catch (_) {
        return null;
      }
    }
  }

  static Future<UserLocation?> storeLocationFromCoordinates(
      {required String latitude, required String longitude}) async {
    try {
      final double lat = double.tryParse(latitude) ?? 0.0;
      final double lng = double.tryParse(longitude) ?? 0.0;

      // Geocoding: Get address details from coordinates
      final placemarks = await placemarkFromCoordinates(lat, lng);
      final p = placemarks.isNotEmpty ? placemarks[0] : Placemark();

      // Combine address parts for fullAddress field
      final fullAddress = [
        p.street, p.subLocality, p.locality, p.administrativeArea,
      ].where((e) => e != null && e.isNotEmpty).join(', ');

      final userLocation = UserLocation(
        latitude: lat,
        longitude: lng,
        fullAddress: fullAddress.isEmpty ? "Default Location" : fullAddress, // Use "Default Location" if geocoding fails to give an address
        area: p.subLocality ?? '',
        city: p.locality ?? '',
        state: p.administrativeArea ?? '',
        country: p.country ?? '',
        pincode: p.postalCode ?? '',
        // Use p.name for a potential landmark, or just leave it empty
        landmark: p.name ?? '',
      );

      // Store the determined location
      await HiveLocationHelper.setCurrentUserLocation(userLocation);
      AppConstant.updateDefaultLocation(latitude, longitude);
      return userLocation;

    } catch (e) {
      // Handle any errors during parsing or geocoding
      log("Error storing location from coordinates: $e");
      return null;
    }
  }

  /// Store a specific location in Hive
  static Future<void> storeLocation(UserLocation location) async {
    await HiveLocationHelper.setCurrentUserLocation(location);
    await HiveLocationHelper.addToRecentLocations(location);
    AppConstant.updateDefaultLocation(
      location.latitude.toString(),
      location.longitude.toString()
    );
  }

  /// Get stored location from Hive
  static UserLocation? getStoredLocation() {
    return HiveLocationHelper.getCurrentUserLocation();
  }

  /// Check if location is stored
  static bool hasStoredLocation() {
    return getStoredLocation() != null;
  }

  /// Clear stored location (for debugging/reset)
  static Future<void> clearStoredLocation() async {
    final box = Hive.box<dynamic>(HiveLocationHelper.boxName);
    await box.delete(HiveLocationHelper.currentLocationKey);
  }

  /// Get zone info from API
  static Future<Map<String, dynamic>?> getZoneFromApi(double lat, double lng) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: AppConstant.baseUrl,
        connectTimeout: Duration(seconds: 10),
      ));
      final response = await dio.get('/delivery-zone/check', queryParameters: {
        'latitude': lat,
        'longitude': lng,
      });
      
      if (response.data['success'] == true && response.data['data'] != null) {
        final data = response.data['data'];
        return {
          'zoneId': data['zone_id']?.toString(),
          'zoneName': data['zone'],
          'isDeliverable': data['is_deliverable'],
        };
      }
    } catch (_) {}
    return null;
  }

  /// Get coordinates - sync version that handles zone check
  static Map<String, double> getCoordinates() {
    final stored = getStoredLocation();
    debugPrint('=== getCoordinates() ===');
    debugPrint('Stored location: ${stored?.fullAddress ?? "null"}');
    debugPrint('Stored zoneId: ${stored?.zoneId ?? "null"}');
    
    if (stored != null && stored.zoneId != null && stored.zoneId != '') {
      debugPrint('Returning stored coords: lat=${stored.latitude}, lng=${stored.longitude}');
      return {
        'latitude': stored.latitude,
        'longitude': stored.longitude,
      };
    }
    
    // ZoneId is null - need to fetch it and update
    if (stored != null && stored.latitude > 0 && stored.longitude > 0) {
      debugPrint('No zoneId - will fetch from API');
      // Trigger background zone check
      checkAndUpdateZone(stored);
      return {
        'latitude': stored.latitude,
        'longitude': stored.longitude,
      };
    }
    
    // No valid location - use default
    const double defaultLat = 16.991903;
    const double defaultLng = 82.240429;
    debugPrint('No valid location, returning default coords');
    
    // Trigger background zone check for stored location
    if (stored != null) {
      checkAndUpdateZone(stored);
    }
    
    return {
      'latitude': defaultLat,
      'longitude': defaultLng,
    };
  }
  
  /// Background check and update zone
  static Future<void> checkAndUpdateZone(UserLocation location) async {
    debugPrint('=== STARTING ZONE CHECK for ${location.fullAddress} ===');
    try {
      final zoneInfo = await getZoneFromApi(location.latitude, location.longitude);
      debugPrint('Zone API result: $zoneInfo');
      
      if (zoneInfo != null && zoneInfo['isDeliverable'] == true) {
        final zoneId = zoneInfo['zoneId'];
        final zoneName = zoneInfo['zoneName'];
        debugPrint('Zone found: $zoneName (id: $zoneId)');
        
        // Update
        final updated = UserLocation(
          latitude: location.latitude,
          longitude: location.longitude,
          fullAddress: location.fullAddress,
          area: location.area,
          city: location.city,
          state: location.state,
          country: location.country,
          pincode: location.pincode,
          landmark: location.landmark,
          zoneId: zoneId,
          zoneName: zoneName,
        );
        await storeLocation(updated);
      }
    } catch (_) {}
  }
}