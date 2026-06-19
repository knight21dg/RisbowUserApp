import 'package:url_launcher/url_launcher.dart';

class AppInstallChecker {
  static const String _playStoreUrl = 'https://play.google.com/store/apps/details?id=com.knight21.risbow';
  static const String _appScheme = 'risbow://';

  static Future<bool> isAppInstalled() async {
    try {
      final uri = Uri.parse(_appScheme);
      return await canLaunchUrl(uri);
    } catch (e) {
      return false;
    }
  }

  static Future<void> openAppOrPlayStore({String? deepLink}) async {
    String url = _appScheme;
    if (deepLink != null && deepLink.isNotEmpty) {
      url = '$_appScheme$deepLink';
    }
    
    final uri = Uri.parse(url);
    final canLaunch = await canLaunchUrl(uri);
    
    if (canLaunch) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await redirectToPlayStore();
    }
  }

  static Future<void> redirectToPlayStore() async {
    final uri = Uri.parse(_playStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<bool> checkAndRedirectIfNeeded({String? deepLink}) async {
    final uri = Uri.parse(_appScheme);
    final canLaunch = await canLaunchUrl(uri);
    
    if (!canLaunch) {
      await redirectToPlayStore();
      return false;
    }
    
    if (deepLink != null && deepLink.isNotEmpty) {
      final fullUri = Uri.parse('$_appScheme$deepLink');
      await launchUrl(fullUri, mode: LaunchMode.externalApplication);
    }
    
    return true;
  }
}