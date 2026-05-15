import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/auth/bloc/auth/auth_bloc.dart';
import 'package:hyper_local/screens/auth/bloc/auth/auth_event.dart';
import 'package:hyper_local/screens/auth/bloc/auth/auth_state.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_toast.dart';
import 'package:hyper_local/utils/widgets/whole_page_progress.dart';
import 'package:hyper_local/services/location/location_service.dart';

import '../../../config/constant.dart';
import '../widgets/social_button_widget.dart';
import '../../../l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  String _countryCode = '+91';
  String _countryIso2 = 'IN';
  
  String? _googleName;
  String? _googleEmail;
  String? _googleProfileImage;

  String get _phoneNumber => _phoneController.text;

  bool _isDetectingLocation = false;
  String? _detectedLocation;
  Position? _currentPosition;

  Future<void> _detectLocation() async {
    if (_isDetectingLocation) return;
    
    setState(() {
      _isDetectingLocation = true;
      _detectedLocation = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (mounted) {
            ToastManager.show(
              context: context,
              message: 'Please enable location services',
              type: ToastType.warning
            );
          }
          setState(() => _isDetectingLocation = false);
          return;
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) {
          ToastManager.show(
            context: context,
            message: 'Location permission is required',
            type: ToastType.warning
          );
        }
        setState(() => _isDetectingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _detectedLocation = 'Location detected';
        });
        
        ToastManager.show(
          context: context,
          message: 'Location detected successfully!',
          type: ToastType.success
        );
      }
    } catch (e) {
      if (mounted) {
        ToastManager.show(
          context: context,
          message: 'Could not detect location',
          type: ToastType.error
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDetectingLocation = false);
      }
    }
  }

@override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detectLocation();
    });
  }

  void _sendOtp() {
    if (_phoneNumber.length != 10) {
      ToastManager.show(
        context: context,
        message: 'Please enter a valid 10-digit phone number',
        type: ToastType.error
      );
      return;
    }

    final registrationData = {
      'name': _googleName ?? '',
      'email': _googleEmail ?? '',
      'profile_image': _googleProfileImage ?? '',
      'mobile': _phoneNumber,
      'country': 'India',
      'iso2': _countryIso2,
      'countryCode': _countryCode.replaceAll('+', ''),
      'completePhoneNumber': '$_countryCode$_phoneNumber',
    };

    context.read<AuthBloc>().add(StoreRegistrationDataEvent(
      registrationData: registrationData,
      phoneNumber: _phoneNumber,
      countryCode: _countryCode.replaceAll('+', ''),
      isoCode: _countryIso2,
    ));

    context.read<AuthBloc>().add(SendOtpToPhoneEvent(
      number: _phoneNumber,
      countryCode: _countryCode.replaceAll('+', ''),
      isoCode: _countryIso2,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.creamColor,
      child: SafeArea(
        bottom: true,
        top: false,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is LoginPhoneCodeSentState) {
                _navigateToOtpVerification(state.verificationId ?? '');
              } else if (state is SocialAuthRequiresPhone) {
                setState(() {
                  _googleName = state.name;
                  _googleEmail = state.email;
                  _googleProfileImage = state.profileImage;
                });
                // Navigate to Google Phone Link page
                GoRouter.of(context).push(
                  AppRoutes.googlePhoneLink,
                  extra: {
                    'googleName': state.name,
                    'googleEmail': state.email,
                    'googleProfileImage': state.profileImage,
                    'googleToken': state.googleToken,
                  },
                );
              } else if (state is AuthFailed) {
                ToastManager.show(context: context, message: state.error, type: ToastType.error);
              } else if (state is AuthSuccess) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    GoRouter.of(context).go(AppRoutes.splashScreen);
                  }
                });
              }
            },
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                final isLoading = authState is AuthLoading || authState is LoginCodeSentProgress;
                return Stack(
                  children: [
                    _buildBackground(),
                    _buildContent(isLoading),
                    if (isLoading) const WholePageProgress(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.creamColor,
      ),
    );
  }

  Widget _buildContent(bool isLoading) {
    return SafeArea(
      child: Stack(
        children: [
          // Skip Button
          Positioned(
            top: 10.h,
            right: 20.w,
            child: InkWell(
              onTap: () {
                GoRouter.of(context).go(AppRoutes.home);
              },
              child: Text(
                'Skip',
                style: TextStyle(
                  color: AppTheme.headingColor.withValues(alpha: 0.6),
                  fontSize: isTablet(context) ? 18 : 14.sp,
                ),
              ),
            ),
          ),

          // Main Content - centered
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  CustomImageContainer(
                    imagePath: getAppLogoUrl(context),
                    height: 80,
                  ),
                  SizedBox(height: 32.h),
                  
                  // Login Form
                  _buildLoginForm(isLoading),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(bool isLoading) {
    return Container(
      width: double.infinity,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Welcome Header
            Text(
              'Welcome',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: isTablet(context) ? 28 : 22.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.headingColor,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Enter your phone number to continue',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: isTablet(context) ? 14 : 12.sp,
                color: AppTheme.subtitleColor,
              ),
            ),
            SizedBox(height: 24.h),

            // Phone Input Field
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _sendOtp(),
              cursorColor: AppTheme.orangeColor,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: TextStyle(color: Colors.grey.shade600),
                floatingLabelStyle: TextStyle(color: AppTheme.orangeColor),
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.orangeColor,
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
              ),
            ),
            SizedBox(height: 8.h),

            // Send OTP Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _phoneNumber.length == 10 && !isLoading ? _sendOtp : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.orangeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(isLoading ? 'Sending...' : 'Send OTP'),
              ),
            ),
            const SizedBox(height: 20),

            // Divider
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Or',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),

            // Google Login
            socialButton(
              onTap: () {
                context.read<AuthBloc>().add(GoogleLoginRequest());
              },
              asset: 'assets/images/icons/google-logo.png',
              background: Colors.white,
              borderColor: Colors.grey.shade300,
              type: LoginType.google,
              context: context
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  void _navigateToOtpVerification(String verificationId) async {
    final authBloc = context.read<AuthBloc>();
    final registrationData = authBloc.getPendingRegistrationData();
    final phoneNumber = authBloc.getPendingPhoneNumber();
    final countryCode = authBloc.getPendingCountryCode();
    final isoCode = authBloc.getPendingIsoCode();

    if (registrationData == null) {
      ToastManager.show(
        context: context,
        message: 'Registration data not found',
        type: ToastType.error,
      );
      return;
    }

    if (!mounted) return;

    GoRouter.of(context).push(
      AppRoutes.otpVerification,
      extra: {
        'phoneNumber': registrationData['completePhoneNumber'],
        'registrationData': registrationData,
        'verificationId': verificationId,
        'userNumber': phoneNumber,
        'countryCode': countryCode,
        'isoCode': isoCode,
      },
    );
  }
}