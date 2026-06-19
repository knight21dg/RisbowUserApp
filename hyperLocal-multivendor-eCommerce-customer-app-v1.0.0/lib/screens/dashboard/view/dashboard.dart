import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:remixicon/remixicon.dart';
import '../../../bloc/user_cart_bloc/user_cart_bloc.dart';
import '../../../bloc/user_cart_bloc/user_cart_state.dart';
import '../../../services/location/location_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/cart_service.dart';
import '../../../utils/widgets/custom_toast.dart';
import '../../../config/theme.dart';
import '../../../config/notification_service.dart';
import '../../../services/notification/notification_repository.dart';
import '../../chat_page/widgets/bow_assistant_widget.dart';
import '../../chat_page/bloc/bow/bow_bloc.dart';

class Dashboard extends StatefulWidget {
  final int index;
  final StatefulNavigationShell navigationShell;
  const Dashboard({
    super.key,
    required this.index,
    required this.navigationShell
  });

  @override
  State<Dashboard> createState() => _DashboardState();
}


class _DashboardState extends State<Dashboard> with SingleTickerProviderStateMixin {
  DateTime? _lastBackPressed;

  Future<void> _syncFcmToken() async {
    try {
      final NotificationService notificationService = NotificationService();
      log('FCM: Getting token...');
      final String? token = await notificationService.getFcmToken();
      log('FCM: Got token: ${token != null ? "present" : "NULL"}');
      
      if (token != null) {
        final NotificationRepository repo = NotificationRepository();
        final result = await repo.saveFcmToken(token);
        log('FCM: Token save result: $result');
        if (!result) {
          log('FCM: Warning - token save returned false');
        }
      } else {
        log('FCM: Token is null - skipping save');
      }
    } catch (e, stack) {
      log('Dashboard FCM Sync Error: $e');
      log('Stack: $stack');
    }
  }

  @override
  void initState() {
    super.initState();
    _syncFcmToken();
    
    final storedLocation = LocationService.getStoredLocation();
    if (storedLocation != null) {
      log('Stored Location: ${storedLocation.fullAddress}');
    }
  }

  @override
  void didUpdateWidget(Dashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Force rebuild when widget.index changes
    if (oldWidget.index != widget.index) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    super.dispose();
  }


  void _goBranch(int index) {
    widget.navigationShell.goBranch(index);
    setState(() {});
  }

  Future<void> _handleBack(BuildContext context) async {
    if (widget.index != 0) {
      _goBranch(0);
      return;
    }

    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      ToastManager.show(
        context: context,
        message: AppLocalizations.of(context)?.pressAgainToExitTheApp ?? 'Press again to exit the app',
      );
      return;
    }

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocListener<CartBloc, CartState>(
      listener: (context, state) {
        if (state is CartLoaded) {
          if(state.errorMessage != null){
            ToastManager.show(
              context: context,
              message: state.errorMessage ?? 'Failed to add item to cart',
              type: ToastType.error,
            );
          }
          CartService.triggerCartAnimationOnFirstAdd(context, state);
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) return;
          await _handleBack(context);
        },
        child: Scaffold(
          body: widget.navigationShell,
          bottomNavigationBar: _buildBottomNavigationBar(l10n),
        ),
      ),
    );
  }


  Widget _buildBottomNavigationBar(AppLocalizations? l10n) {
    return SizedBox(
      height: 65 + MediaQuery.of(context).padding.bottom,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 65,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Home
                    Expanded(
                      child: Center(child: _buildNavItem(0, RemixIcons.home_smile_line, RemixIcons.home_smile_fill, l10n?.home ?? 'Home')),
                    ),
                    // Categories
                    Expanded(
                      child: Center(child: _buildNavItem(1, HeroiconsOutline.squares2x2, HeroiconsSolid.squares2x2, l10n?.categories ?? 'Categories')),
                    ),
                    // Stores
                    Expanded(
                      child: Center(child: _buildNavItem(2, HeroiconsOutline.buildingStorefront, HeroiconsSolid.buildingStorefront, l10n?.stores ?? 'Stores')),
                    ),
                    // Account
                    Expanded(
                      child: Center(child: _buildNavItem(3, HeroiconsOutline.userCircle, HeroiconsSolid.userCircle, l10n?.account ?? 'Account')),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Centre Floating Button
          Positioned(
            bottom: 15,
            left: MediaQuery.of(context).size.width / 2 - 32,
            child: _buildFloatingCenterButton(),
          ),
        ],
      ),
    );
  }

  void _showBowBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: BlocProvider.of<BowBloc>(context),
        child: const BowAssistantWidget(),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlined, IconData filled, String label) {
    final isSelected = widget.index == index;
    return InkWell(
      onTap: () => _goBranch(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? filled : outlined,
                size: 24,
                color: isSelected ? AppTheme.activeIconColor : AppTheme.inactiveIconColor,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 11 : 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppTheme.activeIconColor : AppTheme.inactiveIconColor,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingCenterButton() {
    return GestureDetector(
      onTap: _showBowBottomSheet,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withValues(alpha: 0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          TablerIcons.robot,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}
