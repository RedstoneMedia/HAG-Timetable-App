
import 'dart:async';

import 'package:flutter/services.dart';

class CustomNearbyConnections {
  static const MethodChannel _channel = MethodChannel('custom_nearby_connections');

  static Future<void> start() async {
    await _channel.invokeMethod('start');
  }

  static Future<void> stop() async {
    await _channel.invokeMethod('stop');
  }
}
