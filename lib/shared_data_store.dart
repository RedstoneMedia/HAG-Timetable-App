import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuple/tuple.dart';

class SharedDataStore {
  NearbyService nearbyService = NearbyService();
  Map<String, Tuple2<DateTime, dynamic>> data = {};
  bool running = false;
  SharedPreferences preferences;

  SharedDataStore(this.preferences);

  void loadFromJson(dynamic json) {
    for (final property in (json as Map<String, dynamic>).entries) {
      final valueList = property.value as List;
      data[property.key] = Tuple2(DateTime.parse(valueList[0] as String), valueList[1]);
    }
  }

  Map<String, List<dynamic>> getJsonData() {
    final Map<String, List<dynamic>> jsonData = {};
    for (final property in data.entries) {
      jsonData[property.key] = [property.value.item1.toIso8601String(), property.value.item2];
    }
    return jsonData;
  }

  Future<void> stop() async {
    if (!running) return;
    await nearbyService.stopAdvertisingPeer();
    await nearbyService.stopBrowsingForPeers();
  }

  void setProperty(String propertyName, dynamic value) {
    data[propertyName] = Tuple2(DateTime.now(), value);
    preferences.setString("sharedDataStoreData", jsonEncode(getJsonData()));
  }

  dynamic getProperty(String propertyName) {
    return data[propertyName]?.item2;
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