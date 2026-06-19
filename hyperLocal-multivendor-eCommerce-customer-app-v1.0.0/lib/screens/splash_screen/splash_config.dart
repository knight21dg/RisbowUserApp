enum SplashType { video, staticImage, none }

class SplashConfig {
  final SplashType type;
  final String? videoUrl;
  final String? fallbackImageUrl;
  final int? customDurationMs;
  final bool maintenanceMode;
  final String? minimumVersion;

  const SplashConfig({
    this.type = SplashType.staticImage,
    this.videoUrl,
    this.fallbackImageUrl,
    this.customDurationMs,
    this.maintenanceMode = false,
    this.minimumVersion,
  });

  factory SplashConfig.fromJson(Map<String, dynamic> json) {
    return SplashConfig(
      type: _parseSplashType(json['splash_type'] as String?),
      videoUrl: json['splash_video_url'] as String?,
      fallbackImageUrl: json['splash_fallback_image'] as String?,
      customDurationMs: json['splash_duration'] as int?,
      maintenanceMode: json['maintenance_mode'] as bool? ?? false,
      minimumVersion: json['minimum_version'] as String?,
    );
  }

  static SplashType _parseSplashType(String? type) {
    switch (type?.toLowerCase()) {
      case 'video':
        return SplashType.video;
      case 'static':
        return SplashType.staticImage;
      default:
        return SplashType.none;
    }
  }

  bool get shouldPlayVideo => type == SplashType.video && videoUrl != null;

  int get effectiveDurationMs =>
      customDurationMs ??
      (type == SplashType.video ? 4000 : 3000);
}