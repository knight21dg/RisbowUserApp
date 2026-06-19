class SplashConstants {
  SplashConstants._();

  static const Duration videoLoadTimeout = Duration(seconds: 3);
  static const Duration videoPlayTimeout = Duration(seconds: 5);
  static const Duration maxSplashDuration = Duration(seconds: 8);

  static const Duration fadeTransition = Duration(milliseconds: 300);
  static const Duration logoFadeIn = Duration(milliseconds: 500);

  static const double minBufferProgress = 0.5;

  static const int defaultSplashDurationMs = 3000;
  static const int minSplashDurationMs = 2000;
  static const int maxSplashDurationMs = 6000;
}