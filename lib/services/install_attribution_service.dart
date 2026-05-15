import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class InstallAttributionService {
  static const String _attributionKey = 'install_attribution';
  static const String _referrerCheckedKey = 'referrer_checked';

  static Future<Map<String, dynamic>> getStoredAttribution() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_attributionKey);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return {};
  }

  static Future<void> storeAttribution(Map<String, dynamic> attribution) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_attributionKey, jsonEncode(attribution));
  }

  static Future<bool> isReferrerChecked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_referrerCheckedKey) ?? false;
  }

  static Future<void> setReferrerChecked(bool checked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_referrerCheckedKey, checked);
  }

  static Future<Map<String, dynamic>> getGooglePlayReferrer() async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final uri = Uri.parse('https://app-measurement.com/a');
        final response = await http.get(uri).timeout(
          const Duration(seconds: 5),
          onTimeout: () => http.Response('', 408),
        );
        
        if (response.statusCode == 200 && response.body.isNotEmpty) {
          final params = Uri.parse('?${response.body}').queryParameters;
          
          return {
            'referrer': params['referrer'],
            'utm_source': params['utm_source'],
            'utm_medium': params['utm_medium'],
            'utm_campaign': params['utm_campaign'],
            'utm_content': params['utm_content'],
            'utm_term': params['utm_term'],
            'gclid': params['gclid'],
          };
        }
      }
    } catch (e) {
      debugPrint('Error getting Google Play referrer: $e');
    }
    return {};
  }

  static Map<String, dynamic> parseUtmFromLaunchUrl(Uri? uri) {
    if (uri == null) return {};
    
    final params = uri.queryParameters;
    if (params.isEmpty) return {};

    final utmKeys = ['utm_source', 'utm_medium', 'utm_campaign', 'utm_content', 'utm_term', 'gclid'];
    final attribution = <String, dynamic>{};

    for (final key in utmKeys) {
      if (params.containsKey(key)) {
        attribution[key] = params[key];
      }
    }

    return attribution;
  }

  static Future<void> captureAttributionFromDeepLink(Uri? uri) async {
    if (uri == null) return;

    final referralCode = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
    final existingAttribution = await getStoredAttribution();

    if (referralCode != null && !existingAttribution.containsKey('referral_code')) {
      existingAttribution['referral_code'] = referralCode;
      existingAttribution['source'] = 'deep_link';
    }

    final utmParams = parseUtmFromLaunchUrl(uri);
    if (utmParams.isNotEmpty) {
      existingAttribution.addAll(utmParams);
    }

    if (existingAttribution.isNotEmpty) {
      await storeAttribution(existingAttribution);
    }
  }

  static Future<void> clearAttribution() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_attributionKey);
    await prefs.remove(_referrerCheckedKey);
  }
}