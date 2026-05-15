import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'global.dart';

Map<String, String>? get headers {
  String? token;
  token = Global.token;
    if (token != null) {
      return {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } else {
      return{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
    }
}