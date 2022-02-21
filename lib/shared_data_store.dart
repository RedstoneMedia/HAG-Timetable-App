import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuple/tuple.dart';

class SharedDataStore {
  final NearbyService nearbyService = NearbyService();
  final Map<String, Tuple2<DateTime, dynamic>> data = {};
  bool running = false;
  SharedPreferences preferences;
  final List<String> connectedDeviceIds = [];

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

  Future<void> syncLoop() async {
      while (running) {
        // Periodically broadcast all properties and their timestamp, so peers can request a value if they don't have that value, or have a older version
        final syncData = <String, String>{};
        for (final entry in data.entries) {
          syncData[entry.key] = entry.value.item1.toIso8601String();
        }
        await broadcastMessage(jsonEncode({"type": "sync", "data": syncData}));
        await Future.delayed(const Duration(milliseconds: 500));
      }
  }

  Future<void> broadcastMessage(String message) async {
    final futures = <Future<dynamic>>[];
    for (final peerId in connectedDeviceIds) {
      final result = nearbyService.sendMessage(peerId, message);
      if (result.runtimeType == Future && result != null) {
        futures.add(result as Future);
      }
    }
    await Future.wait(futures);
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
        if (device.state == SessionState.notConnected && !connectedDeviceIds.contains(device.deviceId)) {
          nearbyService.invitePeer(deviceID: device.deviceId, deviceName: device.deviceName);
        } else if (device.state == SessionState.notConnected && connectedDeviceIds.contains(device.deviceId)) {
          connectedDeviceIds.remove(device.deviceId);
        } else if (device.state == SessionState.connected && !connectedDeviceIds.contains(device.deviceId)) {
          connectedDeviceIds.add(device.deviceId);
        }
        log("deviceId: ${device.deviceId} | deviceName: ${device.deviceName} | state: ${device.state}", name: "Shared-Data-Store");
      }
    });

    nearbyService.dataReceivedSubscription(callback: (receivedData) async {
      final jsonData = jsonDecode(receivedData as String) as Map<String, dynamic>;
      log(jsonData.toString(), name: "Shared-Data-Store"); //
      final fromDeviceId = jsonData["deviceId"] as String;
      final messageData = jsonData["message"] as Map<String, dynamic>;
      final messageType = messageData["type"] as String;
      switch (messageType) {
        case "sync":
          final syncData = messageData["data"] as Map<String, String>;
          final newKeys = <String>[];
          for (final entry in syncData.entries) {
            if (!data.containsKey(entry.key)) {
              newKeys.add(entry.key);
            } else if (DateTime.parse(entry.value).isAfter(data[entry.key]!.item1)) {
              newKeys.add(entry.key);
            }
          }
          if (newKeys.isNotEmpty) {
            nearbyService.sendMessage(fromDeviceId, jsonEncode({"type" : "get", "keys": newKeys}));
          }
          break;
        case "get":
          final requestedKeys = messageData["keys"] as List<String>; // TODO: Only send requested keys and not everything
          await nearbyService.sendMessage(fromDeviceId, jsonEncode({"type" : "data", "data": getJsonData()}));
          break;
        case "data":
          final peerData = messageData["data"] as Map<String, dynamic>;
          // TODO: Maybe do some validation of the timestamp (and that the data has not been tampered with (HMAC maybe)) (at least for relayed data), since a malicious peer could spread bad data easily
          for (final property in peerData.entries) {
            final valueList = property.value as List;
            final timestamp = DateTime.parse(valueList[0] as String);
            if (!data.containsKey(property.key)) {
              data[property.key] = Tuple2(timestamp, valueList[1]);
              continue;
            }
            if (timestamp.isAfter(data[property.key]!.item1)) {
              data[property.key] = Tuple2(timestamp, valueList[1]);
            }
          }
          break;
      }
    });
    unawaited(syncLoop());
    log("Started", name: "Shared-Data-Store");
  }

}