import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

class ConnectivityService with WidgetsBindingObserver {
  ConnectivityService._privateConstructor({Dio? dio})
      : _dio = dio ??
             Dio(
               BaseOptions(
                 connectTimeout: const Duration(seconds: 5),
                 receiveTimeout: const Duration(seconds: 5),
               ),
             );

  static ConnectivityService? _instance;
  static ConnectivityService get instance {
    _instance ??= ConnectivityService._privateConstructor();
    return _instance!;
  }

  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final Dio _dio;

  StreamSubscription<dynamic>? _connectivitySubscription;
  bool _isConnected = true;
  bool _isInitialized = false;
  DateTime _lastRefresh = DateTime(0);
  static const _refreshThrottle = Duration(seconds: 2);
  bool _apiAvailable = false;

  Stream<bool> get onConnectionChanged =>
      _connectionController.stream.distinct();

  bool get isConnected => _isConnected;

  bool get isApiAvailable => _apiAvailable;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;

    WidgetsBinding.instance.addObserver(this);

    final initialResults = await _connectivity.checkConnectivity();
    _isConnected = await _hasInternetAccess(_normalizeResults(initialResults));
    _connectionController.add(_isConnected);

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(
      (dynamic event) async {
        try {
          final hasAccess = await _hasInternetAccess(_normalizeResults(event));
          if (_isConnected != hasAccess) {
            _isConnected = hasAccess;
            _connectionController.add(_isConnected);
          }
        } catch (e) {
          _isConnected = false;
          _connectionController.add(_isConnected);
        }
      },
      onError: (error) {
        _isConnected = false;
        _connectionController.add(_isConnected);
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  Future<void> _onAppResumed() async {
    final now = DateTime.now();
    if (now.difference(_lastRefresh) < _refreshThrottle) {
      return;
    }
    _lastRefresh = now;
    await refreshStatus(emitChanges: true);
  }

  Future<bool> checkApiAvailability() async {
    if (!_isConnected) {
      _apiAvailable = false;
      return false;
    }

    try {
      final response = await _dio.get(
        'https://www.google.com/generate_204',
        options: Options(
          followRedirects: false,
          responseType: ResponseType.plain,
          receiveDataWhenStatusError: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      _isConnected = response.statusCode == 204 || response.statusCode == 200;
      _apiAvailable = _isConnected;
      return _apiAvailable;
    } on DioException {
      _isConnected = false;
      _apiAvailable = false;
      return false;
    } catch (_) {
      _isConnected = false;
      _apiAvailable = false;
      return false;
    }
  }

  Future<bool> refreshStatus({bool emitChanges = true}) async {
    if (!_isInitialized) {
      await initialize();
    }

    final currentResults = await _connectivity.checkConnectivity();
    final hasAccess =
        await _hasInternetAccess(_normalizeResults(currentResults));

    if (emitChanges && _isConnected != hasAccess) {
      _isConnected = hasAccess;
      _connectionController.add(_isConnected);
    } else {
      _isConnected = hasAccess;
    }

    return hasAccess;
  }

  List<ConnectivityResult> _normalizeResults(dynamic value) {
    if (value is ConnectivityResult) {
      return [value];
    }
    if (value is List<ConnectivityResult>) {
      return value;
    }
    return const [];
  }

  Future<bool> _hasInternetAccess(List<ConnectivityResult> results) async {
    if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
      return false;
    }

    try {
      final response = await _dio.get(
        'https://www.google.com/generate_204',
        options: Options(
          followRedirects: false,
          responseType: ResponseType.plain,
          receiveDataWhenStatusError: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      return response.statusCode == 204 || response.statusCode == 200;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    if (!_connectionController.isClosed) {
      _connectionController.close();
    }
    _dio.close(force: true);
    _isInitialized = false;
    WidgetsBinding.instance.removeObserver(this);
  }
}