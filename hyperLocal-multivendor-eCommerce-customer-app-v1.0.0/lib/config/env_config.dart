// ignore_for_file: dangling_library_doc_comments
// Environment configuration for the app
/// 
/// To configure the app for different environments:
/// 1. Copy .env.example to .env in the project root
/// 2. Set the values for your environment
/// 3. The app will read these values at runtime
/// 
/// For development, you can also override values in this file directly.

class EnvConfig {
  // Default values - override these in .env file or before release
  // For local development, use your computer's IP address (e.g., 192.168.1.x) for mobile testing
static const String defaultDomainBaseUrl = String.fromEnvironment(
    'DOMAIN_BASE_URL',
    defaultValue: 'https://api.risbow.com',
  );

  static const String defaultGoogleMapsAndroidKey = String.fromEnvironment(
    'GOOGLE_MAPS_ANDROID_KEY',
    defaultValue: '', // Set via .env or compile-time args
  );

  static const String defaultGoogleMapsIosKey = String.fromEnvironment(
    'GOOGLE_MAPS_IOS_KEY',
    defaultValue: '', // Set via .env or compile-time args
  );

  static const String defaultFirebaseServerClientId = String.fromEnvironment(
    'FIREBASE_SERVER_CLIENT_ID',
    defaultValue: '54191014459-dlm6st9ij8bl6jhlhhgd98lq2eusv8jd.apps.googleusercontent.com',
  );

  /// Get the domain base URL
  /// Priority: Environment variable > Default value
  static String get domainBaseUrl {
    final envUrl = const String.fromEnvironment('DOMAIN_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    return defaultDomainBaseUrl;
  }

  /// Get the API base URL (domain + /api/)
  static String get apiBaseUrl => '$domainBaseUrl/api/';

  /// Get Google Maps Android API Key
  static String get googleMapsAndroidKey {
    final envKey = const String.fromEnvironment('GOOGLE_MAPS_ANDROID_KEY');
    if (envKey.isNotEmpty) return envKey;
    return defaultGoogleMapsAndroidKey;
  }

  /// Get Google Maps iOS API Key
  static String get googleMapsIosKey {
    final envKey = const String.fromEnvironment('GOOGLE_MAPS_IOS_KEY');
    if (envKey.isNotEmpty) return envKey;
    return defaultGoogleMapsIosKey;
  }

  /// Get Firebase Server Client ID
  static String get firebaseServerClientId {
    final envId = const String.fromEnvironment('FIREBASE_SERVER_CLIENT_ID');
    if (envId.isNotEmpty) return envId;
    return defaultFirebaseServerClientId;
  }

  /// Check if we're in production mode
  static bool get isProduction =>
      const bool.fromEnvironment('dart.vm.product', defaultValue: false);

  /// Check if we're in debug mode
  static bool get isDebug => !isProduction;
}
