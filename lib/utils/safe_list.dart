import 'package:flutter/foundation.dart';

extension ListExtension<T> on List<T>? {
  T? get firstOrNull {
    if (this == null || this!.isEmpty) return null;
    return this!.first;
  }

  T? get lastOrNull {
    if (this == null || this!.isEmpty) return null;
    return this!.last;
  }

  bool get isNullOrEmpty => this == null || this!.isEmpty;

  bool get isNotNullOrEmpty => this != null && this!.isNotEmpty;

  T? firstWhereOrNull(bool Function(T) test, {T? Function()? orElse}) {
    if (this == null || this!.isEmpty) return orElse?.call();
    try {
      return this!.firstWhere(test);
    } catch (e) {
      return orElse?.call();
    }
  }
}

extension IterableExtension<T> on Iterable<T>? {
  T? get firstOrNull {
    if (this == null || this!.isEmpty) return null;
    return this!.first;
  }

  bool get isNullOrEmpty => this == null || this!.isEmpty;
  bool get isNotNullOrEmpty => this != null && this!.isNotEmpty;
}

class SafeList<T> {
  final List<T> _list;

  SafeList(this._list);

  T? get first => _list.isNotEmpty ? _list.first : null;
  T? get last => _list.isNotEmpty ? _list.last : null;
  int get length => _list.length;
  bool get isEmpty => _list.isEmpty;
  bool get isNotEmpty => _list.isNotEmpty;

  T? elementAt(int index) {
    if (index < 0 || index >= _list.length) return null;
    return _list[index];
  }

  T? firstWhere(bool Function(T) test, {T? Function()? orElse}) {
    try {
      return _list.firstWhere(test);
    } catch (e) {
      return orElse?.call();
    }
  }

  T? firstWhereOrNull(bool Function(T) test) {
    try {
      return _list.firstWhere(test);
    } catch (e) {
      return null;
    }
  }
}

T? safeFirst<T>(List<T>? list) {
  if (list == null || list.isEmpty) return null;
  return list.first;
}

T? safeLast<T>(List<T>? list) {
  if (list == null || list.isEmpty) return null;
  return list.last;
}

T? safeElementAt<T>(List<T>? list, int index) {
  if (list == null || index < 0 || index >= list.length) return null;
  return list[index];
}

List<T> safeList<T>(List<T>? list) {
  return list ?? [];
}

bool isListEmpty<T>(List<T>? list) {
  return list == null || list.isEmpty;
}

bool isListNotEmpty<T>(List<T>? list) {
  return list != null && list.isNotEmpty;
}