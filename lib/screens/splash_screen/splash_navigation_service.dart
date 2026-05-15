import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/router/app_routes.dart';

enum NavigationTarget { login, home, onboarding, maintenance }

class SplashNavigationService {
  SplashNavigationService._();

  static NavigationTarget determineTarget({
    required bool hasToken,
    bool isMaintenanceMode = false,
    bool onboardingComplete = true,
  }) {
    if (isMaintenanceMode) {
      return NavigationTarget.maintenance;
    }

    if (!hasToken) {
      return NavigationTarget.login;
    }

    if (!onboardingComplete) {
      return NavigationTarget.onboarding;
    }

    return NavigationTarget.home;
  }

  static String getRoute(NavigationTarget target) {
    switch (target) {
      case NavigationTarget.login:
        return AppRoutes.login;
      case NavigationTarget.home:
        return AppRoutes.home;
      case NavigationTarget.onboarding:
        return AppRoutes.introSlider;
      case NavigationTarget.maintenance:
        return AppRoutes.maintenancePage;
    }
  }

  static bool get hasValidToken => Global.token != null && Global.token!.isNotEmpty;
}