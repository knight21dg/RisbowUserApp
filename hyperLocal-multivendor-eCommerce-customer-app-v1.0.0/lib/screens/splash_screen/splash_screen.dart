import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/bloc/coins_bloc/coins_bloc.dart';
import 'package:hyper_local/bloc/settings_bloc/settings_bloc.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/user_profile/bloc/user_profile_bloc/user_profile_bloc.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/global.dart';
import '../../services/install_attribution_service.dart';
import '../../services/location/location_service.dart';
import '../home_page/bloc/custom_sale_page/custom_sale_page_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash_config.dart';
import 'splash_controller.dart';
import 'splash_fallback_widget.dart';
import 'splash_navigation_service.dart';
import 'splash_video_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasInitialized = false;
  bool _hasNavigated = false;
  bool _lastKnownConnectivity = false;
  static const String _permissionsRequestedKey = 'permissions_requested';
  
  late SplashController _splashController;
  final SplashConfig _splashConfig = const SplashConfig(type: SplashType.staticImage);

  @override
  void initState() {
    super.initState();
    _splashController = SplashController();
    _initializeSplash();
  }

  void _initializeSplash() {
    _splashController.initialize(config: _splashConfig);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SettingsBloc>().add(FetchSettingsData());
      }
    });
  }

  @override
  void dispose() {
    _splashController.dispose();
    super.dispose();
  }

  Future<bool> _hasRequestedPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionsRequestedKey) ?? false;
  }

  Future<void> _markPermissionsRequested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionsRequestedKey, true);
  }

  Future<bool> _requestAllPermissions() async {
    final permissionsToRequest = <Permission>[];
    
    if (await Permission.location.status.isDenied || await Permission.location.status.isPermanentlyDenied) {
      permissionsToRequest.add(Permission.location);
    }
    if (await Permission.camera.status.isDenied || await Permission.camera.status.isPermanentlyDenied) {
      permissionsToRequest.add(Permission.camera);
    }
    if (await Permission.photos.status.isDenied || await Permission.photos.status.isPermanentlyDenied) {
      permissionsToRequest.add(Permission.photos);
    }
    if (await Permission.notification.status.isDenied || await Permission.notification.status.isPermanentlyDenied) {
      permissionsToRequest.add(Permission.notification);
    }
    
    if (permissionsToRequest.isEmpty) {
      await _markPermissionsRequested();
      return await Permission.location.isGranted;
    }
    
    await permissionsToRequest.request();
    await _markPermissionsRequested();
    
    return await Permission.location.isGranted;
  }

  Future<void> navigate() async {
    if (_hasNavigated) return;

    if (!await _hasRequestedPermissions()) {
      await _requestAllPermissions();
      if (!mounted) return;
    }

    // Detect location: if we have stored location, fetch new one in background. Otherwise wait.
    if (LocationService.hasStoredLocation()) {
      LocationService.requestAndStoreLocationWithRetry();
    } else {
      await LocationService.requestAndStoreLocationWithRetry();
    }
    if (!mounted) return;

    // Check and update delivery zone based on current location
    final storedLocation = LocationService.getStoredLocation();
    if (storedLocation != null) {
      if (storedLocation.zoneId != null && storedLocation.zoneId!.isNotEmpty) {
        LocationService.checkAndUpdateZone(storedLocation);
      } else {
        await LocationService.checkAndUpdateZone(storedLocation);
      }
    }
    if (!mounted) return;

    _dispatchInitialDataFetches();
    _checkAndNavigate();
  }

  void _handleConnectivityChanged(bool isConnected) {
    _lastKnownConnectivity = isConnected;
    if (isConnected && !_hasInitialized) {
      _hasInitialized = true;
      navigate();
    }
  }

  void _dispatchInitialDataFetches() {
    if (!mounted) return;
    context.read<UserProfileBloc>().add(FetchUserProfile());
    context.read<CustomSalePageBloc>().add(FetchCustomSalePages());
  }

  void _checkAndNavigate() {
    if (!mounted || _hasNavigated || !(_lastKnownConnectivity)) return;
    _hasNavigated = true;
    if (Global.token == null) {
      context.go(AppRoutes.login);
    } else {
      _trackInstallAttribution();
      context.go(AppRoutes.home);
    }
  }

  Future<void> _trackInstallAttribution() async {
    try {
      final attribution = await InstallAttributionService.getStoredAttribution();
      
      if (attribution.isNotEmpty && mounted) {
        context.read<CoinsBloc>().add(TrackInstallAttribution(
          referralCode: attribution['referral_code'],
          googlePlayReferrer: attribution['google_play_referrer'],
          utmSource: attribution['utm_source'],
          utmMedium: attribution['utm_medium'],
          utmCampaign: attribution['utm_campaign'],
          utmContent: attribution['utm_content'],
          utmTerm: attribution['utm_term'],
        ));
        
        await InstallAttributionService.clearAttribution();
      }
    } catch (e) {
      debugPrint('Error tracking install attribution: $e');
    }
  }

  Widget _buildSplashContent() {
    final useVideo = _splashController.useVideo && 
                      _splashConfig.videoUrl != null && 
                      _splashConfig.videoUrl!.isNotEmpty;

    Widget content;
    if (useVideo) {
      content = SplashVideoWidget(
        videoUrl: _splashConfig.videoUrl,
        onComplete: () {
          _splashController.complete();
        },
        onError: (String error) {
          _splashController.onVideoError(error);
        },
      );
    } else {
      content = const SplashFallbackWidget();
    }

    return Stack(
      children: [
        content,
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Powered by',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Knight21 Digi Hub',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleSplashCompletion() {
    if (_hasNavigated) return;
    
    final target = _splashController.getNavigationTarget();
    final route = SplashNavigationService.getRoute(target);
    
    if (route == AppRoutes.login) {
      context.go(AppRoutes.login);
    } else {
      _trackInstallAttribution();
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _splashController,
      builder: (context, _) {
        if (_splashController.state == SplashState.completed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleSplashCompletion();
          });
        }

        return BlocListener<SettingsBloc, SettingsState>(
          listener: (context, state) {
            if (state is SettingsLoaded) {
              _checkAndNavigate();
            }
          },
          child: CustomScaffold(
            showViewCart: false,
            notifyConnectivityStatusOnInit: true,
            onConnectivityChanged: (isConnected, _) {
              _handleConnectivityChanged(isConnected);
            },
            body: _buildSplashContent(),
          ),
        );
      },
    );
  }
}