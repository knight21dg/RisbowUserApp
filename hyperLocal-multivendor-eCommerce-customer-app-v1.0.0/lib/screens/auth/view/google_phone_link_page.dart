import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/auth/bloc/auth/auth_bloc.dart';
import 'package:hyper_local/screens/auth/bloc/auth/auth_event.dart';
import 'package:hyper_local/screens/auth/bloc/auth/auth_state.dart';
import 'package:hyper_local/utils/widgets/custom_toast.dart';
import 'package:hyper_local/utils/widgets/whole_page_progress.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';

class GooglePhoneLinkPage extends StatefulWidget {
  final String googleName;
  final String googleEmail;
  final String googleProfileImage;
  final String googleToken;

  const GooglePhoneLinkPage({
    super.key,
    required this.googleName,
    required this.googleEmail,
    required this.googleProfileImage,
    required this.googleToken,
  });

  @override
  State<GooglePhoneLinkPage> createState() => _GooglePhoneLinkPageState();
}

class _GooglePhoneLinkPageState extends State<GooglePhoneLinkPage> {
  final TextEditingController _phoneController = TextEditingController();
  final String _countryCode = '+91';
  final String _countryIso2 = 'IN';
  bool _isLoading = false;

  String get _phoneNumber => _phoneController.text;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    if (_phoneNumber.length != 10) {
      ToastManager.show(
        context: context,
        message: 'Please enter a valid 10-digit phone number',
        type: ToastType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    context.read<AuthBloc>().add(
      StoreRegistrationDataEvent(
        registrationData: {
          'name': widget.googleName,
          'email': widget.googleEmail,
          'profile_image': widget.googleProfileImage,
          'google_token': widget.googleToken,
          'mobile': _phoneNumber,
          'country': 'India',
          'iso2': _countryIso2,
          'countryCode': _countryCode.replaceAll('+', ''),
          'completePhoneNumber': '$_countryCode$_phoneNumber',
        },
        phoneNumber: _phoneNumber,
        countryCode: _countryCode.replaceAll('+', ''),
        isoCode: _countryIso2,
      ),
    );

    context.read<AuthBloc>().add(
      SendOtpToPhoneEvent(
        number: _phoneNumber,
        countryCode: _countryCode.replaceAll('+', ''),
        isoCode: _countryIso2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is LoginPhoneCodeSentState) {
          setState(() => _isLoading = false);
          _navigateToOtpVerification(state.verificationId ?? '');
        } else if (state is AuthLoading || state is LoginCodeSentProgress) {
          setState(() => _isLoading = true);
        } else if (state is AuthFailed) {
          setState(() => _isLoading = false);
          ToastManager.show(
            context: context,
            message: state.error,
            type: ToastType.error,
          );
        }
      },
      child: Container(
        color: AppTheme.creamColor,
        child: SafeArea(
          bottom: true,
          top: false,
          child: Scaffold(
            backgroundColor: AppTheme.creamColor,
            resizeToAvoidBottomInset: true,
            body: Stack(
              children: [
                // Back Button
                Positioned(
                  top: 50.h,
                  left: 16.w,
                  child: IconButton(
                    onPressed: () {
                      context.read<AuthBloc>().add(ClearRegistrationDataEvent());
                      GoRouter.of(context).go(AppRoutes.login);
                    },
                    icon: const Icon(TablerIcons.chevron_left, size: 28),
                  ),
                ),

                // Main Content
                Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App Logo
                        CustomImageContainer(
                          imagePath: getAppLogoUrl(context),
                          height: 70.h,
                        ),
                        SizedBox(height: 40.h),

                        // Profile Avatar
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.orangeColor.withValues(alpha: 0.2), width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 40.r,
                            backgroundColor: Colors.white,
                            backgroundImage: widget.googleProfileImage.isNotEmpty
                                ? NetworkImage(widget.googleProfileImage)
                                : null,
                            child: widget.googleProfileImage.isEmpty
                                ? Icon(TablerIcons.user, size: 30, color: AppTheme.orangeColor)
                                : null,
                          ),
                        ),
                        SizedBox(height: 24.h),

                        // Welcome Text
                        Text(
                          'Almost There',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.headingColor,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Hello ${widget.googleName.split(" ")[0]},\nplease enter your phone number to continue.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 14.sp,
                            color: AppTheme.subtitleColor,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 40.h),

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
                            hintText: 'Enter 10-digit number',
                            hintStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.normal, color: Colors.grey.shade400),
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
                          onChanged: (_) => setState(() {}),
                        ),
                        SizedBox(height: 24.h),

                        // Send OTP Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _phoneNumber.length == 10 && !_isLoading ? _sendOtp : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.orangeColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CustomCircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Send OTP',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        
                        SizedBox(height: 24.h),
                        
                        // Footer
                        Text(
                          'A verification code will be sent to this number.',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppTheme.subtitleColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (_isLoading) const WholePageProgress(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToOtpVerification(String verificationId) {
    final authBloc = context.read<AuthBloc>();
    final registrationData = authBloc.getPendingRegistrationData();
    final phoneNumber = authBloc.getPendingPhoneNumber();
    final countryCode = authBloc.getPendingCountryCode();
    final isoCode = authBloc.getPendingIsoCode();

    if (registrationData == null || phoneNumber == null) {
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
        'phoneNumber': '$_countryCode$phoneNumber',
        'registrationData': registrationData,
        'verificationId': verificationId,
        'userNumber': phoneNumber,
        'countryCode': countryCode,
        'isoCode': isoCode,
        'isGoogleLinking': true,
        'googleToken': widget.googleToken,
      },
    );
  }
}