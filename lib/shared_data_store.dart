import 'dart:async';
import 'dart:developer';

import 'package:flutter_blue/flutter_blue.dart';

class SharedDataStore {
  FlutterBlue bluetooth = FlutterBlue.instance;
  Map<String, dynamic> data = {};
  bool running = false;

  Future<void> start() async {
    if (running) return;
    running = true;
    unawaited(bluetooth.startScan(scanMode: ScanMode.lowPower));
    bluetooth.scanResults.listen((results) {
      for (final ScanResult r in results) {
        log('${r.device.name} found! rssi: ${r.rssi}');
      }
    });
  }

  void stop() {
    running = false;
    bluetooth.stopScan();
  }

}