import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/screens/address_list_page/bloc/check_delivery_zone_bloc/check_delivery_zone_bloc.dart';
import 'package:hyper_local/services/location/location_service.dart';
import 'package:hyper_local/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class GlobalServiceGuard extends StatefulWidget {
  final Widget child;
  final GoRouter router;

  const GlobalServiceGuard({
    super.key,
    required this.child,
    required this.router,
  });

  @override
  State<GlobalServiceGuard> createState() => _GlobalServiceGuardState();
}

class _GlobalServiceGuardState extends State<GlobalServiceGuard> {
  // Allow certain paths
  final List<String> allowedPaths = [
    '/account',
    '/user-profile',
    '/location-picker',
    '/address-list',
    '/policy-page',
    '/support-page',
    '/login',
    '/otp-verification',
    '/',
    '/intro-slider',
  ];

  @override
  void initState() {
    super.initState();
    _checkService();
  }

  void _checkService() {
    final location = LocationService.getStoredLocation();
    if (location != null && location.latitude != 0) {
      context.read<CheckDeliveryZoneBloc>().add(
        CheckDeliveryZoneRequest(
          latitude: location.latitude.toString(),
          longitude: location.longitude.toString(),
        ),
      );
    }
  }

  bool _isPathAllowed(String currentPath) {
    for (var allowedPath in allowedPaths) {
      if (currentPath == allowedPath ||
          currentPath.startsWith('$allowedPath/')) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // We listen to the router to know the current path
    final routeInfo = widget.router.routeInformationProvider.value;
    final currentPath = routeInfo.uri.path;

    return BlocConsumer<CheckDeliveryZoneBloc, CheckDeliveryZoneState>(
      listener: (context, state) {
        // Handle side effects if needed
      },
      builder: (context, state) {
        bool isServiceAvailable = true;

        if (state is CheckDeliveryZoneFailure) {
          isServiceAvailable = false;
        } else if (state is CheckDeliveryZoneSuccess) {
          isServiceAvailable = true;
        }

        // We only block if we know for sure it's unavailable
        final bool shouldBlock =
            !isServiceAvailable && !_isPathAllowed(currentPath);

        return Stack(
          children: [
            widget.child,
            if (shouldBlock)
              Positioned.fill(
                child: Material(
                  color: Colors.white,
                  child: SafeArea(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 100.w,
                              height: 100.w,
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  TablerIcons.map_pin_off,
                                  size: 48.sp,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                            SizedBox(height: 24.h),
                            Text(
                              AppLocalizations.of(
                                    context,
                                  )?.sorryWeDontDeliverHereYet ??
                                  'Service Not Available',
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              AppLocalizations.of(
                                    context,
                                  )?.thisLocationIsOutsideOurDeliveryZone ??
                                  "We're sorry, but our delivery service isn't available at your current location yet. You can update your location or visit your profile.",
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.black54,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 32.h),
                            ElevatedButton(
                              onPressed: () {
                                context.push('/location-picker');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                minimumSize: Size(double.infinity, 50.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: Text(
                                AppLocalizations.of(context)?.changeLocation ??
                                    'Change Location',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            OutlinedButton(
                              onPressed: () {
                                context.go('/account');
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size(double.infinity, 50.h),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: Text(
                                AppLocalizations.of(context)?.account ??
                                    'Go to Profile',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
