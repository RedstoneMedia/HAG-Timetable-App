import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:tuple/tuple.dart';

class SharedDataStore {
  NearbyService nearbyService = NearbyService();
  Map<String, Tuple2<DateTime, dynamic>> data = {};
  bool running = false;

  Future<void> stop() async {
    if (!running) return;
    await nearbyService.stopAdvertisingPeer();
    await nearbyService.stopBrowsingForPeers();
  }

  Future<void> start() async {
    if (running) return;
    running = true;
    await nearbyService.init(
        serviceType: "HAG-SDS",
        strategy: Strategy.P2P_CLUSTER,
        callback: (bool isRunning) async {
          if (!isRunning) return null;
          // Restart browsing and advertising
          await nearbyService.stopAdvertisingPeer();
          await nearbyService.stopBrowsingForPeers();
          await Future.delayed(const Duration(microseconds: 200));
          await nearbyService.startAdvertisingPeer();
          await nearbyService.startBrowsingForPeers();
        }
    );

    nearbyService.stateChangedSubscription(callback: (devicesList) {
      for (final device in devicesList) {
        log("deviceId: ${device.deviceId} | deviceName: ${device.deviceName} | state: ${device.state}", name: "Shared-Data-Store");
      }
    });

    nearbyService.dataReceivedSubscription(callback: (data) {
      final jsonData = jsonDecode(data as String) as Map<String, dynamic>;
      log(jsonData.toString(), name: "Shared-Data-Store");
      final fromDeviceId = jsonData["deviceId"] as String;
      final messageData = jsonData["message"] as Map<String, dynamic>;
      final isResponse = messageData["isResponse"] as bool;
      if (isResponse) {
        // TODO: Implement receiving and updating data, but ignoring old peer data
      } else {
        nearbyService.sendMessage(fromDeviceId, jsonEncode(data));
      }
    });
    log("Started", name: "Shared-Data-Store");
  }

}