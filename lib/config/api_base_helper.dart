import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart' as dio_;
import 'package:flutter/material.dart';
import 'package:hyper_local/config/security.dart' as security;

class ApiBaseHelper {
  static final _options = BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    sendTimeout: const Duration(seconds: 60),
  );

  static final dio_.Dio _dio = dio_.Dio(_options);
  
  dio_.Dio get dio => _dio;

  // Get auth headers from security.dart
  Map<String, String>? get headers => security.headers;

  String _extractValidationError(dynamic data) {
    if (data is Map && data.containsKey('errors') && data['errors'] is Map) {
      final errors = data['errors'] as Map;
      if (errors.isNotEmpty) {
        final firstField = errors.values.first;
        if (firstField is List && firstField.isNotEmpty) {
          return firstField.first.toString();
        }
      }
    }
    if (data is Map && data.containsKey('message')) {
      return data['message'].toString();
    }
    return 'Validation error';
  }

  Future<void> downloadFile(
      {required String url,
        required dio_.CancelToken cancelToken,
        required String savePath,
        required Function(int, int) updateDownloadedPercentage,
      }) async {
    try {
      final dio_.Dio dio = dio_.Dio();
      await dio.download(
        url,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: updateDownloadedPercentage,
        options: dio_.Options(
          headers: headers,
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );

      final file = File(savePath);
      if (!await file.exists() || await file.length() == 0) {
        throw ApiException('Downloaded file is empty or does not exist');
      }

      // Check if it's actually a PDF
      final firstBytes = await file.openRead(0, 10).first;
      final headerString = String.fromCharCodes(firstBytes.take(4));

      if (!headerString.startsWith('%PDF')) {
        // If it's HTML, read the content to see what error we got
        await file.readAsString();
        throw ApiException('Server returned HTML instead of PDF. Check authentication or URL.');
      }

    } on dio_.DioException catch (e) {
      if (e.type == dio_.DioExceptionType.connectionError) {
        throw ApiException('No Internet connection');
      }
      throw ApiException(e.toString());
    } catch (e) {
      throw Exception(e.toString());
    }
  }


  // POST METHOD
  Future<dynamic> postAPICall(String url, dynamic params) async {
    dio_.Response responseJson;
    try {
      final response =
      await _dio.post(
        url,
        data: params is dio_.FormData ? params : (params.isNotEmpty ? params : {}),
        options: dio_.Options(
          headers: headers,
        ),
      );
      log(
          'response api****$url***************${response.statusCode}*********${response.data}');

      responseJson = response;
    } on dio_.DioException catch (e) {
      // DioError handling.
      if (e.response != null) {
        final data = e.response?.data;
        final message = (data is Map && data.containsKey('message')) 
            ? data['message'] 
            : e.response?.statusMessage ?? 'Unknown error';

        // The server responded but with an error status.
        if (e.response?.statusCode == 401) {
          throw ApiException(message);
        } else if (e.response?.statusCode == 422) {
          final specificError = _extractValidationError(data);
          throw ApiException(specificError);
        } else if (e.response?.statusCode == 500 || e.response?.statusCode == 503) {
          log('SERVER ERROR RESPONSE: $data');
          throw ApiException('Server error: $message');
        }
        throw ApiException(message);
      } else {
        throw ApiException('Something Went Wrong: ${e.message}');
      }
    } on SocketException {
      throw ApiException('No Internet connection');
    } on TimeoutException {
      throw ApiException('Something went wrong, Server not Responding');
    } on Exception catch (e) {
      throw ApiException('Something Went wrong with ${e.toString()}');
    }
    return responseJson;
  }

  // PUT METHOD
  Future<dynamic> putAPICall(String url, dynamic params) async {
    dio_.Response responseJson;
    try {
      final response = await _dio.put(
        url,
        data: params.isNotEmpty ? params : [],
        options: dio_.Options(
          headers: headers,
        ),
      );
      log(
          'response api****$url***************${response.statusCode}*********${response.data}');

      responseJson = response;
    } on dio_.DioException catch (e) {
      // DioError handling.
      if (e.response != null) {
        final data = e.response?.data;
        final message = (data is Map && data.containsKey('message')) 
            ? data['message'] 
            : e.response?.statusMessage ?? 'Unknown error';

        // The server responded but with an error status.
        if (e.response?.statusCode == 401) {
          throw ApiException(message);
        } else if (e.response?.statusCode == 422) {
          final errorEmail = (data is Map && data.containsKey('errors') && data['errors'] is Map) 
              ? data['errors']['email'] 
              : message;
          throw ApiException(errorEmail ?? message);
        } else if (e.response?.statusCode == 500 || e.response?.statusCode == 503) {
          throw ApiException('Server error: $message');
        }
        throw ApiException(message);
      } else {
        throw ApiException('Something Went Wrong: ${e.message}');
      }
    } on SocketException {
      throw ApiException('No Internet connection');
    } on TimeoutException {
      throw ApiException('Something went wrong, Server not Responding');
    } on Exception catch (e) {
      throw ApiException('Something Went wrong with ${e.toString()}');
    }
    return responseJson;
  }

  Future<dynamic> getAPICall(String url, dynamic params, {bool? isUserApi, BuildContext? context, dio_.CancelToken? cancelToken}) async {
    dio_.Response responseJson;
    try {
      debugPrint('=== API GET REQUEST ===');
      debugPrint('URL: $url');
      debugPrint('Params: $params');
      
      final response =
      await _dio.get(
          url,
          queryParameters: (params is Map<String, dynamic> && params.isNotEmpty) ? params : {},
          cancelToken: cancelToken,
          options: dio_.Options(headers: headers)
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');
      responseJson = response;
    } on dio_.DioException catch (e) {
      // DioError handling.
      if(e.response?.statusCode == 401 && isUserApi == true){}
      if (e.response != null) {
        final data = e.response?.data;
        final message = (data is Map && data.containsKey('message')) 
            ? data['message'] 
            : e.response?.statusMessage ?? 'Unknown error';

        if (e.response?.statusCode == 401) {
          throw ApiException(message);
        } else if (e.response?.statusCode == 422) {
          throw ApiException(message ?? 'Validation error');
        } else if (e.response?.statusCode == 500) {
          log('SERVER ERROR (500) at $url: ${e.response?.data}');
          throw ApiException('Server error: ${e.response?.statusMessage}');
        } else if (e.response?.statusCode == 403 || e.response?.statusCode == 503) {
          log('SERVICE UNAVAILABLE/FORBIDDEN at $url: ${e.response?.data}');
          throw ApiException(message);
        }
        throw ApiException(message);
      } else {
        throw ApiException('Something Went Wrong: ${e.message}');
      }
    } on SocketException {
      throw ApiException('No Internet connection');
    } on TimeoutException {
      throw ApiException('Something went wrong, Server not Responding');
    } on Exception catch (e) {
      log('///////$e///////');
      throw ApiException('Something went wrong: ${e.toString()}');
    }
    return responseJson;
  }

  Future<dynamic> deleteAPICall(String url, dynamic params) async {
    dio_.Response responseJson;
    try {
      final response =
      await _dio.delete(
        url,
        data: params.isNotEmpty ? params : [],
        options: dio_.Options(
          headers: headers,
        ),
      );
      if (kDebugMode) {
        print(
            'response api****$url***************${response.statusCode}*********${response.data}');
      }

      responseJson = response;
    } on dio_.DioException catch (e) {
      // DioError handling.
      if (e.response != null) {
        final data = e.response?.data;
        final message = (data is Map && data.containsKey('message')) 
            ? data['message'] 
            : e.response?.statusMessage ?? 'Unknown error';

        if (e.response?.statusCode == 401) {
          throw ApiException(message);
        } else if (e.response?.statusCode == 422) {
          final errorEmail = (data is Map && data.containsKey('errors') && data['errors'] is Map) 
              ? data['errors']['email'] 
              : message;
          throw ApiException(errorEmail ?? message);
        } else if (e.response?.statusCode == 500 || e.response?.statusCode == 503) {
          throw ApiException('Server error: $message');
        }
        throw ApiException(message);
      } else {
        throw ApiException('Something Went Wrong: ${e.message}');
      }
    } on SocketException {
      throw ApiException('No Internet connection');
    } on TimeoutException {
      throw ApiException('Something went wrong, Server not Responding');
    } on Exception catch (e) {
      throw ApiException('Something Went wrong with ${e.toString()}');
    }
    return responseJson;
  }

}

class CustomException implements Exception {
  final dynamic message;
  final dynamic prefix;

  CustomException([this.message, this.prefix]);

  @override
  String toString() {
    return '$prefix$message';
  }
}

class FetchDataException extends CustomException {
  FetchDataException([message])
      : super(message, 'Error During Communication: ');
}

class BadRequestException extends CustomException {
  BadRequestException([message]) : super(message, 'Invalid Request: ');
}

class UnauthorisedException extends CustomException {
  UnauthorisedException([message]) : super(message, 'Unauthorised: ');
}

class InvalidInputException extends CustomException {
  InvalidInputException([message]) : super(message, 'Invalid Input: ');
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  
  @override
  String toString() => message;
}
