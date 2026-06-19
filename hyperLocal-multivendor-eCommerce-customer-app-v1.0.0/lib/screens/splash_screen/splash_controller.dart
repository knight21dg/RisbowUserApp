import 'package:flutter/material.dart';
import 'splash_config.dart';
import 'splash_navigation_service.dart';

enum SplashState { initializing, playing, completed, failed, navigating }

class SplashController extends ChangeNotifier {
  SplashState _state = SplashState.initializing;
  SplashConfig _config = const SplashConfig();
  bool _useVideo = false;
  DateTime? _startTime;
  String? _videoError;

  SplashState get state => _state;
  SplashConfig get config => _config;
  bool get useVideo => _useVideo;
  String? get videoError => _videoError;
  int get effectiveDurationMs => _config.effectiveDurationMs;

  void initialize({SplashConfig? config}) {
    _startTime = DateTime.now();
    
    if (config != null) {
      _config = config;
    } else {
      _config = const SplashConfig(type: SplashType.staticImage);
    }

    _useVideo = _config.shouldPlayVideo;
    _state = SplashState.playing;
    notifyListeners();
  }

  void onVideoLoadComplete() {
    if (_state == SplashState.playing) {
      _scheduleCompletion();
    }
  }

  void onVideoError(String error) {
    _videoError = error;
    _state = SplashState.failed;
    notifyListeners();
  }

  void _scheduleCompletion() {
    final duration = Duration(milliseconds: effectiveDurationMs);
    Future.delayed(duration, () {
      if (_state == SplashState.playing) {
        complete();
      }
    });
  }

  void complete() {
    if (_state != SplashState.navigating) {
      _state = SplashState.completed;
      notifyListeners();
    }
  }

  NavigationTarget getNavigationTarget() {
    return SplashNavigationService.determineTarget(
      hasToken: SplashNavigationService.hasValidToken,
      isMaintenanceMode: _config.maintenanceMode,
    );
  }

  String getRoute() {
    final target = getNavigationTarget();
    return SplashNavigationService.getRoute(target);
  }

  int getSplashDurationMs() {
    if (_startTime != null) {
      return DateTime.now().difference(_startTime!).inMilliseconds;
    }
    return 0;
  }

  void reset() {
    _state = SplashState.initializing;
    _videoError = null;
    _startTime = null;
  }
}