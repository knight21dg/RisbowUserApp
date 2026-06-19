import 'dart:async';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/auth/widgets/otp_input_boxes.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_toast.dart';
import 'package:hyper_local/utils/widgets/whole_page_progress.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';

class OTPVerificationPage extends StatefulWidget {
  final String phoneNumber;
  final Map<String, dynamic> registrationData;
  final String verificationId;
  final String number;
  final String countryCode;
  final String isoCode;
  final bool isGoogleLinking;
  final String googleToken;

  const OTPVerificationPage(
      {super.key,
      required this.phoneNumber,
      required this.registrationData,
      required this.verificationId,
      required this.number,
      required this.countryCode,
      required this.isoCode,
      this.isGoogleLinking = false,
      this.googleToken = ''});

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _verificationId;
  int _resendTimer = 60;
  bool _canResend = false;
  StreamSubscription? _registrationSubscription;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    log('📱 OTP Page initialized with:');
    log('   Phone: ${widget.phoneNumber}');
    log('   VerificationId: $_verificationId');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _sendOTP();
      _startResendTimer();
    });
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!_isActive || !mounted) return;
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
        _startResendTimer();
      } else {
        setState(() {
          _canResend = true;
        });
      }
    });
  }


  void _resendOTP() {
    if (_canResend) {
      setState(() {
        _canResend = false;
        _resendTimer = 60;
      });

      // ✅ Resend OTP
      context.read<AuthBloc>().add(SendOtpToPhoneEvent(
          number: widget.number,
          countryCode: widget.countryCode,
          isoCode: widget.isoCode));

      _startResendTimer();
    }
  }

  // void _verifyOTP() {
  //   context.read<AuthBloc>().add(VerifySentOtp(
  //     verificationId: _verificationId!,
  //     otpCode: _otpController.text.trim(),
  //   ));
  //   if (_verificationId == null) {
  //     ToastManager.show(
  //       context: context,
  //       message: 'Please wait for OTP to be sent',
  //       type: ToastType.error,
  //     );
  //     return;
  //   }
  // }

  void _verifyOTP() {
    if (_otpController.text.length < 6) {
      ToastManager.show(
        context: context,
        message: AppLocalizations.of(context)!.pleaseEnterCompleteOTP,
        type: ToastType.error,
      );
      return;
    }

    if (_verificationId == null || _verificationId!.isEmpty) {
      ToastManager.show(
        context: context,
        message: AppLocalizations.of(context)!.verificationIdNotFound,
        type: ToastType.error,
      );
      return;
    }

    // ✅ Send OTP verification event
    context.read<AuthBloc>().add(VerifySentOtp(
          verificationId: _verificationId!,
          otpCode: _otpController.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (!_isActive || !mounted) return;
        if (state is LoginPhoneCodeSentState) {
          if (!mounted) return;

          setState(() {
            _verificationId = state.verificationId;
          });
          ToastManager.show(
            context: context,
            message: AppLocalizations.of(context)!.otpSentTo(widget.phoneNumber),
            type: ToastType.success,
          );
        }
        else if (state is OTPVerified) {
          _completeRegistration();
        }
        else if (state is AuthSuccess) {
          if (!mounted) return;
          context.read<AuthBloc>().add(ClearRegistrationDataEvent());
          ToastManager.show(
            context: context,
            message: state.message,
            type: ToastType.success,
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              GoRouter.of(context).go(AppRoutes.home);
            }
          });
        }
        else if (state is AuthFailed) {
          if (!mounted) return;
          ToastManager.show(
            context: context,
            message: state.error,
            type: ToastType.error,
          );
        }
        else if (state is OTPFailed) {
          if (!mounted) return;
          ToastManager.show(
            context: context,
            message: state.error,
            type: ToastType.error,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is VerifyingOTP ||
            state is AuthLoading ||
            state is LoginCodeSentProgress;

        return CustomScaffold(
          showViewCart: false,
          backgroundColor: AppTheme.creamColor,
          body: Stack(
            children: [
              // Back Button
              Positioned(
                top: 50.h,
                left: 16.w,
                child: IconButton(
                  onPressed: () {
                    GoRouter.of(context).pushReplacement(AppRoutes.login);
                  },
                  icon: const Icon(TablerIcons.chevron_left, size: 28),
                ),
              ),

              // Content
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Verification Icon
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.orangeColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            TablerIcons.shield_check,
                            size: 60.sp,
                            color: AppTheme.orangeColor,
                          ),
                        ),
                        
                        SizedBox(height: 32.h),

                        // Header
                        Text(
                          'Verification',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 24.sp,
                            color: AppTheme.headingColor,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              color: AppTheme.subtitleColor,
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 14.sp,
                            ),
                            children: [
                              const TextSpan(text: 'Enter the 6-digit code we sent to\n'),
                              TextSpan(
                                text: widget.phoneNumber,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.headingColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 40.h),

                        // OTP Input
                        AbsorbPointer(
                          absorbing: isLoading,
                          child: OTPInputBoxes(
                            onCompleted: (otp) {
                              _otpController.text = otp;
                              if (otp.length == 6 && _verificationId != null) {
                                context.read<AuthBloc>().add(VerifySentOtp(
                                  verificationId: _verificationId!,
                                  otpCode: otp,
                                ));
                              }
                            },
                          ),
                        ),

                        SizedBox(height: 32.h),

                        // Verify Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _verifyOTP,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.orangeColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CustomCircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Verify OTP',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // Resend OTP
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Didn't receive code?",
                              style: TextStyle(
                                color: AppTheme.subtitleColor,
                                fontSize: 14.sp,
                              ),
                            ),
                            if (_canResend)
                              TextButton(
                                onPressed: _resendOTP,
                                child: Text(
                                  'Resend OTP',
                                  style: TextStyle(
                                    color: AppTheme.orangeColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              )
                            else
                              Padding(
                                padding: EdgeInsets.only(left: 8.w),
                                child: Text(
                                  'Resend in $_resendTimer s',
                                  style: TextStyle(
                                    color: AppTheme.headingColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isLoading) const WholePageProgress()
            ],
          ),
        );
      },
    );
  }

  /// Fallback registration - only called if phoneAuthCallback didn't succeed
  /// during the OTP verification step.
  void _completeRegistration() {
    final bloc = context.read<AuthBloc>();
    log('✅ Completing registration via fallback...');

    final registrationData = bloc.getPendingRegistrationData();
    if (registrationData == null) {
      ToastManager.show(
        context: context,
        message: AppLocalizations.of(context)!.registrationDataNotFound,
        type: ToastType.error,
      );
      return;
    }

    final name = widget.registrationData['name'].toString();
    
    // RegisterRequest now calls phoneAuthCallback with the Firebase token
    bloc.add(RegisterRequest(
      name: name.isEmpty ? 'User' : name,
      mobile: widget.registrationData['mobile'].toString(),
      country: widget.registrationData['country'].toString(),
      iso2: widget.registrationData['iso2'].toString(),
      countryCode: widget.registrationData['countryCode'].toString(),
      completePhoneNumber: widget.registrationData['completePhoneNumber'].toString(),
    ));
  }

  @override
  void dispose() {
    _isActive = false;
    _otpController.dispose();
    _registrationSubscription?.cancel();
    super.dispose();
  }
}
