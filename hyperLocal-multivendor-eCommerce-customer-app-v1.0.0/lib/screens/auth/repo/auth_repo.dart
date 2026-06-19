import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/config/notification_service.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _extractErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      return _firebaseAuthErrorMessage(error);
    }
    if (error is ApiException) {
      return error.message;
    }
    return error.toString();
  }

  String _firebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'ERROR_INVALID_PHONE_NUMBER':
      case 'invalid-phone-number':
        return 'Please enter a valid phone number.';
      case 'ERROR_TOO_MANY_REQUESTS':
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'ERROR_QUOTA_EXCEEDED':
      case 'quota-exceeded':
        return 'Service temporarily unavailable. Please try again later.';
      case 'ERROR_SESSION_EXPIRED':
      case 'session-expired':
        return 'Session expired. Please request a new OTP.';
      case 'ERROR_INVALID_VERIFICATION_CODE':
      case 'invalid-verification-code':
        return 'The OTP you entered is incorrect. Please try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }

  String getDeviceType() {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else {
      return 'unknown';
    }
  }

  /// Phone OTP callback - sends Firebase token to backend after OTP verification.
  /// Backend handles both new user registration and existing user login automatically.
  Future<Map<String, dynamic>> phoneAuthCallback({
    required String firebaseToken,
    String? name,
    String? email,
    String? profileImage,
    String? country,
    String? iso2,
  }) async {
    try {
      String? fcmToken = await getFCMToken();
      final response = await AppConstant.apiBaseHelper.postAPICall(
        ApiRoutes.phoneAuthApi,
        {
          'idToken': firebaseToken,
          if (name != null && name.isNotEmpty) 'name': name,
          if (email != null && email.isNotEmpty) 'email': email,
          if (profileImage != null && profileImage.isNotEmpty) 'profile_image': profileImage,
          if (country != null && country.isNotEmpty) 'country': country,
          if (iso2 != null && iso2.isNotEmpty) 'iso_2': iso2,
          'device_type': getDeviceType(),
          'fcm_token': fcmToken,
        },
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      return {};
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(_extractErrorMessage(e));
    }
  }

  /// Google social auth callback - sends Firebase token to backend.
  Future<Map<String, dynamic>> socialAuth({
    required String firebaseToken,
  }) async {
    try {
      String? fcmToken = await getFCMToken();
      final response = await AppConstant.apiBaseHelper.postAPICall(
        ApiRoutes.googleAuthApi,
        {
          'idToken': firebaseToken,
          'device_type': getDeviceType(),
          'fcm_token': fcmToken,
        },
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      return {};
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(_extractErrorMessage(e));
    }
  }

  /// Link Google account with phone number after phone OTP verification
  Future<Map<String, dynamic>> linkGoogleWithPhone({
    required String googleIdToken,
    required String phoneIdToken,
  }) async {
    try {
      String? fcmToken = await getFCMToken();
      final response = await AppConstant.apiBaseHelper.postAPICall(
        ApiRoutes.linkGooglePhoneApi,
        {
          'google_id_token': googleIdToken,
          'phone_id_token': phoneIdToken,
          'device_type': getDeviceType(),
          'fcm_token': fcmToken,
        },
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      return {};
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(_extractErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> verifyUser({required String type, required String value}) async {
    try {
      final response = await AppConstant.apiBaseHelper.postAPICall(ApiRoutes.verifyUserApi, {
        'type': type,
        'value': value,
      });
      return response.data;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(_extractErrorMessage(e));
    }
  }

  Future<void> logout() async {
    try {
      await AppConstant.apiBaseHelper.postAPICall(ApiRoutes.logoutApi, {});
    } catch (e) {
      throw ApiException('Failed to logout user');
    }
  }

  Future<Map<String, String>> sendOTPWithCallback({
    required String phoneNumber,
    Function(String verificationId)? onCodeSent,
  }) async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final Completer<String> completer = Completer<String>();

      await auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          completer.completeError(e.message ?? 'Failed to send OTP');
        },
        codeSent: (String verificationId, int? resendToken) {
          completer.complete(verificationId);
          if (onCodeSent != null) {
            onCodeSent(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );

      final verificationId = await completer.future;
      return {'verificationId': verificationId};
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(_extractErrorMessage(e));
    }
  }

  Future<bool> verifyOTP({required String verificationId, required String otpCode}) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );

      await _auth.signInWithCredential(credential);
      return true;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(_extractErrorMessage(e));
    }
  }

  Future<String> googleLogin() async {
    print('===== GOOGLE LOGIN START =====');
    print('Step 1: Creating GoogleSignIn instance');
    
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: [
        'email',
        'profile',
      ],
    );

    print('Step 2: Checking current user');
    final currentUser = googleSignIn.currentUser;
    print('Current user before signOut: ${currentUser?.email ?? "null"}');

    try {
      print('Step 3: Signing out previous session');
      await googleSignIn.signOut();
      print('Sign out completed - now calling signIn()');

      print('Step 4: Calling googleSignIn.signIn() - opening Google dialog');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      print('googleSignIn.signIn() returned: ${googleUser?.email ?? "NULL (cancelled or error)"}');

      if (googleUser == null) {
        print('ERROR: Google Sign-In returned null - user cancelled or error occurred');
        return '';
      }

      print('Step 5: Getting authentication tokens for user: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('Google Auth received - idToken: ${googleAuth.idToken != null ? "present" : "NULL"}');
      print('Google Auth received - accessToken: ${googleAuth.accessToken != null ? "present" : "NULL"}');
      print('Google Auth received - serverAuthCode: ${googleAuth.serverAuthCode != null ? "present" : "NULL"}');

      if (googleAuth.idToken == null) {
        print('idToken is NULL - trying alternative approach');
        
        if (googleAuth.serverAuthCode != null) {
          print('Trying to get Firebase token using serverAuthCode...');
          try {
            final credential = OAuthCredential(
              providerId: 'google.com',
              signInMethod: 'oauth',
              accessToken: googleAuth.serverAuthCode,
            );
            
            final userCredential = await _auth.signInWithCredential(credential);
            if (userCredential.user != null) {
              print('Signed in with serverAuthCode via OAuth credential');
              final idTokenResult = await userCredential.user!.getIdTokenResult();
              final token = idTokenResult.token;
              if (token != null && token.isNotEmpty) {
                print('===== GOOGLE LOGIN SUCCESS (via serverAuthCode) =====');
                return token;
              }
            }
          } catch (e) {
            print('Error with serverAuthCode: $e');
          }
        }
        
        if (googleAuth.accessToken != null) {
          print('Trying to get Firebase token using accessToken...');
          try {
            final credential = GoogleAuthProvider.credential(
              accessToken: googleAuth.accessToken,
            );
            
            final userCredential = await _auth.signInWithCredential(credential);
            if (userCredential.user != null) {
              print('Signed in with accessToken');
              final idTokenResult = await userCredential.user!.getIdTokenResult();
              final token = idTokenResult.token;
              if (token != null && token.isNotEmpty) {
                print('===== GOOGLE LOGIN SUCCESS (via accessToken) =====');
                return token;
              }
            }
          } catch (e) {
            print('Error with accessToken: $e');
          }
        }
        
        print('ERROR: idToken is null and no fallback worked!');
        throw ApiException('Failed to get Google idToken');
      }

      print('Step 6: Creating Firebase credential');
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      print('Firebase credential created successfully');

      print('Step 7: Signing in to Firebase with credential');
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      print('Firebase signInWithCredential completed');

      final User? user = userCredential.user;
      print('Firebase user: ${user?.email ?? "null"}, uid: ${user?.uid ?? "null"}');

      if (user == null) {
        print('ERROR: Firebase user is null after sign-in!');
        throw ApiException('Failed to get Firebase user');
      }

      print('Step 8: Getting Firebase ID token');
      final IdTokenResult idTokenResult = await user.getIdTokenResult();
      final String? firebaseToken = idTokenResult.token;
      print('Firebase token received: ${firebaseToken != null ? "present" : "NULL"}, length: ${firebaseToken?.length ?? 0}');

      if (firebaseToken == null || firebaseToken.isEmpty) {
        print('ERROR: Firebase token is null or empty!');
        throw ApiException('Failed to get Firebase token');
      }

      print('===== GOOGLE LOGIN SUCCESS =====');
      return firebaseToken;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException caught!');
      print('Error code: ${e.code}');
      print('Error message: ${e.message}');
      print('Error stack: ${e.stackTrace}');
      
      if (e.code == 'user-cancelled') {
        print('User cancelled Google sign-in');
        return '';
      }
      if (e.code == 'DEVELOPER_ERROR') {
        print('DEVELOPER_ERROR: Check SHA-1 fingerprint and OAuth config in Google Cloud Console');
      }
      if (e.code == '10') {
        print('Error code 10: Missing or invalid SHA-1 fingerprint');
      }
      throw ApiException(e.message ?? 'Google sign-in failed');
    } catch (e, stackTrace) {
      print('Generic error caught in Google login!');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('cancel') || errorStr.contains('null')) {
        print('Login cancelled or returned null');
        return '';
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteUser() async {
    try {
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.deleteUserApi,
        {},
      );
      if (response.statusCode == 200) {
        return response.data;
      } else {
        return {};
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(_extractErrorMessage(e));
    }
  }
}
