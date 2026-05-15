import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/model/user_data_model/user_data_model.dart';
import 'package:hyper_local/screens/auth/repo/auth_repo.dart';
import '../../../../bloc/user_details_bloc/user_details_bloc.dart';
import '../../../../bloc/user_details_bloc/user_details_event.dart';
import '../../model/auth_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository = AuthRepository();
  final UserDataBloc _userDetailBloc;

  Map<String, dynamic>? _pendingRegistrationData;
  String? _pendingPhoneNumber;
  String? _pendingCountryCode;
  String? _pendingIsoCode;
  String? _pendingGoogleToken; // Store Google token for linking with phone

  AuthBloc(this._userDetailBloc) : super(AuthInitial()) {
    on<RegisterRequest>(_onRegisterRequest);
    on<LogoutUserRequest>(_onLogoutUserRequest);
    on<DeleteUserRequest>(_onDeleteUserRequest);
    on<SendOtpToPhoneEvent>(_onSendOtpToPhone);
    on<VerifySentOtp>(_onVerifySentOtp);
    on<OnPhoneOtpSend>(_onPhoneOtpSent);
    on<OnPhoneAuthVerificationCompleted>(_onPhoneAuthVerified);
    on<ResendOtpRequest>(_onResendOtp);
    on<AuthFailureEvent>(_onAuthFailureEvent);
    on<SocialAuthRequest>(_onSocialAuthRequest);
    on<GoogleLoginRequest>(_onGoogleLoginRequest);
    on<LinkGooglePhoneEvent>(_onLinkGooglePhone);
    on<StoreRegistrationDataEvent>(_onStoreRegistrationData);
    on<ClearRegistrationDataEvent>(_onClearRegistrationData);
    on<DeleteUserAccount>(_onDeleteUserAccount);
  }

  Future<void> _onStoreRegistrationData(
      StoreRegistrationDataEvent event,
      Emitter<AuthState> emit,
      ) async {
    _pendingRegistrationData = event.registrationData;
    _pendingPhoneNumber = event.phoneNumber;
    _pendingCountryCode = event.countryCode;
    _pendingIsoCode = event.isoCode;

    log('✅ Registration data stored in bloc');
    emit(RegistrationDataStored(
      registrationData: event.registrationData,
      phoneNumber: event.phoneNumber,
      countryCode: event.countryCode,
      isoCode: event.isoCode,
    ));
  }

  Map<String, dynamic>? getPendingRegistrationData() =>
      _pendingRegistrationData;

  String? getPendingPhoneNumber() => _pendingPhoneNumber;
  String? getPendingCountryCode() => _pendingCountryCode;
  String? getPendingIsoCode() => _pendingIsoCode;

  Future<void> _onClearRegistrationData(
      ClearRegistrationDataEvent event,
      Emitter<AuthState> emit,
      ) async {
    _pendingRegistrationData = null;
    _pendingPhoneNumber = null;
    _pendingCountryCode = null;
    _pendingIsoCode = null;
    log('🗑️ Registration data cleared from bloc');
  }

  /// Called after OTP verification + phoneAuthCallback succeeds or for new user registration.
  /// This is only used when a new user needs to provide their name during registration.
  Future<void> _onRegisterRequest(
      RegisterRequest event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      // Get the current Firebase user's token (already authenticated via OTP)
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        emit(AuthFailed(error: 'Firebase session expired. Please try again.'));
        return;
      }

      final firebaseToken = await firebaseUser.getIdToken(true);
      if (firebaseToken == null || firebaseToken.isEmpty) {
        emit(AuthFailed(error: 'Failed to get authentication token.'));
        return;
      }

      // Call phone callback with registration data (name)
      final response = await _repository.phoneAuthCallback(
        firebaseToken: firebaseToken,
        name: event.name,
        country: event.country,
        iso2: event.iso2,
      );

      if (response.isEmpty) {
        emit(AuthFailed(error: 'No response from server'));
        return;
      }

      if (response['success'] == true) {
        final authModel = AuthModel.fromJson(response);
        final userData = authModel.data;
        if (userData == null) {
          emit(AuthFailed(error: authModel.message ?? 'User data not found'));
          return;
        }

        _userDetailBloc.add(SetUserData(UserDataModel(
          token: authModel.accessToken ?? '',
          userId: userData.id?.toString() ?? '',
          name: userData.name ?? '',
          email: userData.email ?? '',
          mobile: userData.mobile ?? '',
          country: userData.country ?? '',
          iso2: userData.iso2 ?? '',
          profileImage: userData.profileImage ?? '',
          referralCode: userData.referralCode ?? '',
          language: 'en',
        )));

        emit(AuthSuccess(
          message: authModel.message ?? 'Registration successful',
          isNewUser: true,
        ));
      } else {
        emit(AuthFailed(error: response['message'] ?? 'Registration failed'));
      }
    } catch (e) {
      log('Register exception: $e');
      emit(AuthFailed(error: e.toString()));
    }
  }

  Future<void> _onLogoutUserRequest(
      LogoutUserRequest event,
      Emitter<AuthState> emit,
      ) async {
    try {
      await FirebaseAuth.instance.signOut();
      await _repository.logout();
      _userDetailBloc.add(ClearUserData());

      _pendingRegistrationData = null;
      _pendingPhoneNumber = null;
      _pendingCountryCode = null;
      _pendingIsoCode = null;
      emit(LogoutUserSuccess());
    } catch (e) {
      emit(AuthFailed(error: e.toString()));
    }
  }

  Future<void> _onDeleteUserRequest(
      DeleteUserRequest event,
      Emitter<AuthState> emit,
      ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.delete();
      _userDetailBloc.add(ClearUserData());
      _pendingRegistrationData = null;
      _pendingPhoneNumber = null;
      _pendingCountryCode = null;
      _pendingIsoCode = null;
      emit(DeleteUserSuccess());
    } catch (e) {
      emit(AuthFailed(error: e.toString()));
    }
  }

  Future<void> _onSendOtpToPhone(
      SendOtpToPhoneEvent event,
      Emitter<AuthState> emit,
      ) async {
    emit(LoginCodeSentProgress(
      registrationData: _pendingRegistrationData,
      phoneNumber: _pendingPhoneNumber,
      countryCode: _pendingCountryCode,
      isoCode: _pendingIsoCode,
    ));
    try {
      await _verifyPhoneNumber(
        countryCode: event.countryCode,
        phoneNumber: event.number,
        isoCode: event.isoCode,
      );
    } catch (e) {
      log('OTP Send Failed: $e');
      emit(AuthFailed(error: e.toString()));
    }
  }

  Future<void> _onVerifySentOtp(
      VerifySentOtp event,
      Emitter<AuthState> emit,
      ) async {
    emit(VerifyingOTP());
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: event.verificationId,
        smsCode: event.otpCode,
      );
      add(OnPhoneAuthVerificationCompleted(
        credential: credential,
        countryCode: event.countryCode,
        number: event.phoneNumber,
        isoCode: event.isoCode,
      ));
    } catch (e) {
      emit(AuthFailed(error: e.toString()));
    }
  }

  void _onPhoneOtpSent(OnPhoneOtpSend event, Emitter<AuthState> emit) {
    log('📱 Emitting LoginPhoneCodeSentState with ID: ${event.verificationId}');
    emit(LoginPhoneCodeSentState(
      verificationId: event.verificationId,
      registrationData: _pendingRegistrationData,
      phoneNumber: _pendingPhoneNumber,
      countryCode: _pendingCountryCode,
      isoCode: _pendingIsoCode,
    ));
  }

  /// After OTP is verified via Firebase, send the token to backend.
  /// Backend handles both login (existing user) and registration (new user) automatically.
  Future<void> _onPhoneAuthVerified(
      OnPhoneAuthVerificationCompleted event,
      Emitter<AuthState> emit,
      ) async {
    try {
      final credential = event.credential;
      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      final phoneIdToken = await userCredential.user?.getIdToken(true);

      if (phoneIdToken == null || phoneIdToken.isEmpty) {
        emit(AuthFailed(error: 'Failed to get Firebase token'));
        return;
      }

      log('Phone Auth Success | Phone ID Token received');

      // Check if there's a pending Google token - this is the Google+Phone linking flow
      if (_pendingGoogleToken != null && _pendingGoogleToken!.isNotEmpty) {
        log('Detected Google+Phone linking flow - calling linkGoogleWithPhone API');

        final response = await _repository.linkGoogleWithPhone(
          googleIdToken: _pendingGoogleToken!,
          phoneIdToken: phoneIdToken,
        );

        // Clear pending Google token
        _pendingGoogleToken = null;

        if (response.isNotEmpty && response['success'] == true) {
          final authModel = AuthModel.fromJson(response);
          final user = authModel.data;

          if (user == null) {
            emit(AuthFailed(error: authModel.message ?? 'User data not found'));
            return;
          }

          _userDetailBloc.add(SetUserData(UserDataModel(
            token: authModel.accessToken ?? '',
            userId: user.id.toString(),
            name: user.name ?? '',
            email: user.email ?? '',
            mobile: user.mobile ?? '',
            country: user.country ?? '',
            iso2: user.iso2 ?? '',
            profileImage: user.profileImage ?? '',
            referralCode: user.referralCode ?? '',
            language: 'en',
          )));

          // Clear pending data
          _pendingRegistrationData = null;
          _pendingPhoneNumber = null;
          _pendingCountryCode = null;
          _pendingIsoCode = null;

          emit(AuthSuccess(message: authModel.message ?? 'Login successful'));
        } else {
          emit(AuthFailed(error: response['message'] ?? 'Failed to link accounts'));
        }
        return;
      }

      // Regular phone auth flow (non-Google)
      log('Phone Auth Success | Calling phoneAuthCallback');

      // Get details from pending registration data if available
      final pendingName = _pendingRegistrationData?['name'] as String?;
      final pendingEmail = _pendingRegistrationData?['email'] as String?;
      final pendingProfileImage = _pendingRegistrationData?['profile_image'] as String?;
      final pendingCountry = _pendingRegistrationData?['country'] as String?;
      final pendingIso2 = _pendingRegistrationData?['iso_2'] as String?;

      // Call backend phone callback - handles both login & auto-register
      final response = await _repository.phoneAuthCallback(
        firebaseToken: phoneIdToken,
        name: pendingName,
        email: pendingEmail,
        profileImage: pendingProfileImage,
        country: pendingCountry ?? event.isoCode,
        iso2: pendingIso2 ?? event.isoCode,
      );

      if (response.isNotEmpty && response['success'] == true) {
        final authModel = AuthModel.fromJson(response);
        final userData = authModel.data;

        if (userData == null) {
          emit(AuthFailed(error: authModel.message ?? 'User data not found'));
          return;
        }

        final isNewUser = userData.name == null || userData.name!.isEmpty ||
            userData.name == 'User';

        _userDetailBloc.add(SetUserData(UserDataModel(
          token: authModel.accessToken ?? '',
          userId: userData.id?.toString() ?? '',
          name: userData.name ?? '',
          email: userData.email ?? '',
          mobile: userData.mobile ?? '',
          country: userData.country ?? '',
          iso2: userData.iso2 ?? '',
          profileImage: userData.profileImage ?? '',
          referralCode: userData.referralCode ?? '',
          language: 'en',
        )));

        // Clear pending data
        _pendingRegistrationData = null;
        _pendingPhoneNumber = null;
        _pendingCountryCode = null;
        _pendingIsoCode = null;

        emit(AuthSuccess(
          message: authModel.message ?? 'Login successful',
          isNewUser: isNewUser,
        ));
      } else {
        // If backend call fails, still emit OTPVerified so UI can proceed
        log('Phone callback failed, emitting OTPVerified for manual handling');
        emit(OTPVerified(message: 'OTP Verified'));
      }
    } catch (e, s) {
      log('Phone verification failed: $e', stackTrace: s);
      emit(AuthFailed(error: e.toString()));
    }
  }

  Future<void> _onResendOtp(
      ResendOtpRequest event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      await _verifyPhoneNumber(
        countryCode: event.countryCode,
        phoneNumber: event.phoneNumber,
        isoCode: event.isoCode,
      );
    } catch (e) {
      emit(AuthFailed(error: 'Please wait before resending.'));
    }
  }

  Future<void> _verifyPhoneNumber({
    required String countryCode,
    required String phoneNumber,
    required String isoCode,
  }) async {
    final fullNumber = '+$countryCode$phoneNumber';
    log('Verifying phone: $fullNumber | ISO: $isoCode');

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: fullNumber,
      verificationCompleted: (PhoneAuthCredential credential) {
        add(OnPhoneAuthVerificationCompleted(
          credential: credential,
          countryCode: countryCode,
          number: phoneNumber,
          isoCode: isoCode,
        ));
      },
      verificationFailed: (FirebaseAuthException e) {
        log('Verification failed: ${e.message}');
        add(AuthFailureEvent(error: e.message ?? 'Verification failed'));
      },
      codeSent: (String verificationId, int? resendToken) {
        log('✅ OTP Code Sent! VerificationId: $verificationId');
        add(OnPhoneOtpSend(verificationId: verificationId, resendToken: resendToken));
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        log('Auto retrieval timeout: $verificationId');
      },
      timeout: const Duration(seconds: 120),
    );
  }

  Future<void> _onAuthFailureEvent(
      AuthFailureEvent event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthFailed(error: event.error));
  }

  /// Handle Google social auth - send Firebase token to backend
  Future<void> _onSocialAuthRequest(
      SocialAuthRequest event,
      Emitter<AuthState> emit,
      ) async {
    try {
      final response = await _repository.socialAuth(
        firebaseToken: event.firebaseToken,
      );

      log('Social auth response: $response');

      if (response is! Map<String, dynamic>) {
        log('Error: Social auth response is not a Map: $response');
        emit(AuthFailed(error: 'Invalid response from server'));
        return;
      }

      if (response['success'] == true) {
        // Parse user data and save session
        final authModel = AuthModel.fromJson(response);
        final user = authModel.data;

        if (user == null) {
          emit(AuthFailed(error: authModel.message ?? 'User data not found'));
          return;
        }

        _userDetailBloc.add(SetUserData(UserDataModel(
          token: authModel.accessToken ?? '',
          userId: user.id?.toString() ?? '',
          name: user.name ?? '',
          email: user.email ?? '',
          mobile: user.mobile ?? '',
          country: user.country ?? '',
          iso2: user.iso2 ?? '',
          profileImage: user.profileImage ?? '',
          referralCode: user.referralCode ?? '',
          language: 'en',
        )));

        emit(AuthSuccess(message: authModel.message ?? 'Login successful'));
      } else {
        final dynamic rawData = response['data'];
        if (rawData != null && rawData is Map<String, dynamic> && rawData['new_user'] == true) {
          final data = rawData;
          // Store Google token for linking with phone later
          _pendingGoogleToken = event.firebaseToken;
          emit(SocialAuthRequiresPhone(
            name: data['name'] ?? '',
            email: data['email'] ?? '',
            profileImage: data['profile_image'] ?? '',
            googleToken: event.firebaseToken,
          ));
        } else {
          emit(AuthFailed(error: response['message'] ?? 'Authentication failed'));
        }
      }
    } catch (e) {
      log('Social auth error: $e');
      emit(AuthFailed(error: e.toString()));
    }
  }

  Future<void> _onGoogleLoginRequest(
      GoogleLoginRequest event,
      Emitter<AuthState> emit,
      ) async {
    log('BLOC: GoogleLoginRequest event received');
    emit(AuthLoading());
    log('BLOC: Emitted AuthLoading state');
    
    try {
      log('BLOC: Calling repository.googleLogin()');
      String firebaseUserToken = await _repository.googleLogin();
      log('BLOC: googleLogin() returned token: ${firebaseUserToken.isNotEmpty ? "present (${firebaseUserToken.length} chars)" : "EMPTY"}');

      if (firebaseUserToken.isEmpty) {
        log('BLOC: Google sign-in cancelled by user - emitting AuthInitial');
        emit(AuthInitial());
        return;
      }

      log('BLOC: Dispatching SocialAuthRequest with token');
      add(SocialAuthRequest(
        firebaseToken: firebaseUserToken,
      ));
    } catch (e, stackTrace) {
      log('BLOC: Google login error: $e');
      log('BLOC: Stack trace: $stackTrace');
      emit(AuthFailed(error: e.toString()));
    }
  }

  Future<void> _onDeleteUserAccount(
      DeleteUserAccount event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _repository.deleteUser();
      if (response['success'] == true) {
        emit(DeleteUserSuccess());
      }
    } catch (e) {
      emit(AuthFailed(error: e.toString()));
    }
  }

  /// Handle linking Google account with phone number
  Future<void> _onLinkGooglePhone(
      LinkGooglePhoneEvent event,
      Emitter<AuthState> emit,
      ) async {
    log('BLOC: LinkGooglePhoneEvent received');
    emit(AuthLoading());
    log('BLOC: Emitted AuthLoading for linking');

    try {
      log('BLOC: Calling repository.linkGoogleWithPhone()');
      final response = await _repository.linkGoogleWithPhone(
        googleIdToken: event.googleIdToken,
        phoneIdToken: event.phoneIdToken,
      );
      log('BLOC: linkGoogleWithPhone response: $response');

      if (response['success'] == true) {
        final authModel = AuthModel.fromJson(response);
        final user = authModel.data;

        if (user == null) {
          emit(AuthFailed(error: authModel.message ?? 'User data not found'));
          return;
        }

        // Save user data
        _userDetailBloc.add(SetUserData(UserDataModel(
          token: authModel.accessToken ?? '',
          userId: user.id.toString(),
          name: user.name ?? '',
          email: user.email ?? '',
          mobile: user.mobile ?? '',
          country: user.country ?? '',
          iso2: user.iso2 ?? '',
          profileImage: user.profileImage ?? '',
          referralCode: user.referralCode ?? '',
          language: 'en',
        )));

        emit(AuthSuccess(message: authModel.message ?? 'Login successful'));
      } else {
        emit(AuthFailed(error: response['message'] ?? 'Failed to link accounts'));
      }
    } catch (e, stackTrace) {
      log('BLOC: Link Google Phone error: $e');
      log('BLOC: Stack trace: $stackTrace');
      emit(AuthFailed(error: e.toString()));
    }
  }
}
