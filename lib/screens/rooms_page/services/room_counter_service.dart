import 'dart:async';

class RoomCounterService {
  static RoomCounterService? _instance;
  static RoomCounterService get instance => _instance ??= RoomCounterService._();
  RoomCounterService._();

  final Map<String, StreamController<RoomCounterUpdate>> _controllers = {};
  final Map<String, int> _cachedCounts = {};
  bool _isInitialized = false;

  Future<void> initialize() async {
    _isInitialized = true;
  }

  Stream<RoomCounterUpdate> subscribeToRoom(String roomCode) {
    if (_controllers.containsKey(roomCode)) {
      _controllers[roomCode]?.close();
    }

    final controller = StreamController<RoomCounterUpdate>.broadcast();
    _controllers[roomCode] = controller;

    // Initialize with cached or default count
    final currentCount = _cachedCounts[roomCode] ?? 0;
    controller.add(RoomCounterUpdate(
      roomCode: roomCode,
      currentMembers: currentCount,
      requiredMembers: 50,
      status: 'active',
      timestamp: DateTime.now(),
    ));

    // Real-time count synced via REST API or Firebase
    syncFromRestApi(roomCode, _cachedCounts[roomCode] ?? 0);

    return controller.stream;
  }

  void updateRoomCount(String roomCode, int count) {
    _cachedCounts[roomCode] = count;
    final controller = _controllers[roomCode];
    if (controller != null && !controller.isClosed) {
      controller.add(RoomCounterUpdate(
        roomCode: roomCode,
        currentMembers: count,
        requiredMembers: 50,
        status: count >= 50 ? 'unlocked' : 'active',
        timestamp: DateTime.now(),
      ));
    }
  }

  void unsubscribeFromRoom(String roomCode) {
    _controllers[roomCode]?.close();
    _controllers.remove(roomCode);
  }

  void unsubscribeAll() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }

  int? getCachedCount(String roomCode) {
    return _cachedCounts[roomCode];
  }

  bool get isSubscribed => _controllers.isNotEmpty;
  
  int get activeSubscriptionCount => _controllers.length;

  // Method to sync with REST API when Firebase fails
  Future<void> syncFromRestApi(String roomCode, int apiCount) async {
    _cachedCounts[roomCode] = apiCount;
    final controller = _controllers[roomCode];
    if (controller != null && !controller.isClosed) {
      controller.add(RoomCounterUpdate(
        roomCode: roomCode,
        currentMembers: apiCount,
        requiredMembers: 50,
        status: apiCount >= 50 ? 'unlocked' : 'active',
        timestamp: DateTime.now(),
      ));
    }
  }
}

class RoomCounterUpdate {
  final String roomCode;
  final int currentMembers;
  final int requiredMembers;
  final String status;
  final DateTime timestamp;

  const RoomCounterUpdate({
    required this.roomCode,
    required this.currentMembers,
    required this.requiredMembers,
    required this.status,
    required this.timestamp,
  });

  double get progress => requiredMembers > 0 
      ? (currentMembers / requiredMembers).clamp(0.0, 1.0) 
      : 0.0;

  int get membersNeeded => (requiredMembers - currentMembers).clamp(0, requiredMembers);

  bool get isUnlocked => currentMembers >= requiredMembers;

  bool get isActive => status.toLowerCase() == 'active';

  RoomCounterUpdate copyWith({
    String? roomCode,
    int? currentMembers,
    int? requiredMembers,
    String? status,
    DateTime? timestamp,
  }) {
    return RoomCounterUpdate(
      roomCode: roomCode ?? this.roomCode,
      currentMembers: currentMembers ?? this.currentMembers,
      requiredMembers: requiredMembers ?? this.requiredMembers,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}