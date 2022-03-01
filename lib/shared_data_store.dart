import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
//import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:stundenplan/widgets/bottom_overlay.dart';
import 'package:custom_nearby_connections/custom_nearby_connections.dart';

class SharedValue {
  DateTime timestamp;
  dynamic data;
  Map<String, dynamic> raw;
  SharedValue(this.timestamp, this.raw, this.data);

  static Future<SharedValue> fromRaw(Map<String, dynamic> raw, KeyPair keyPair) async {
    final rawData = await _getDataFromRaw(raw);
    final signedRaw = await _signMessage(jsonEncode(raw), keyPair);
    return SharedValue(DateTime.parse(rawData["timestamp"] as String), signedRaw, rawData["data"]);
  }

  static Future<Map<String, dynamic>> _getDataFromRaw(Map<String, dynamic> raw) async {
    // Verify message
    final signatureRaw = raw["signature"]! as Map<String, String>;
    final signatureBytes = base64Decode(signatureRaw["bytes"]!);
    final signaturePublicKey = SimplePublicKey(base64Decode(signatureRaw["publicKey"]!), type: KeyPairType.ed25519);
    final signature = Signature(signatureBytes, publicKey: signaturePublicKey);
    final message = raw["message"] as String;
    final algorithm = Ed25519();
    if (!await algorithm.verify(message.codeUnits, signature: signature)) {
      throw Exception("$signature does not match message");
    }
    // Traverse deeper, if required
    final messageJson = jsonDecode(message) as Map<String, dynamic>;
    if (messageJson.containsKey("message")) {
      return _getDataFromRaw(jsonDecode(messageJson["message"] as String) as Map<String, dynamic>);
    }
    return messageJson;
  }

  static Future<Map<String, dynamic>> _signMessage(String message, KeyPair keyPair) async {
    final algorithm = Ed25519();
    final signature = await algorithm.sign(message.codeUnits, keyPair: keyPair);
    final signatureRaw = {"bytes" : base64Encode(signature.bytes), "publicKey" : base64Encode((signature.publicKey as SimplePublicKey).bytes)};
    return {"signature": signatureRaw, "message" : message};
  }

  static Future<SharedValue> newSharedValue(DateTime timestamp, dynamic data, KeyPair keyPair) async {
    final messageData = jsonEncode({"timestamp" : timestamp.toIso8601String(), "data" : data});
    return SharedValue(timestamp, await _signMessage(messageData, keyPair), data);
  }

  static SharedValue fromJson(Map<String, dynamic> json) {
    return SharedValue(DateTime.parse(json["timestamp"] as String), json["raw"] as Map<String, dynamic>, json["data"]);
  }

  Map<String, dynamic> toJson() {
    return {"timestamp" : timestamp.toIso8601String(), "raw" : raw, "data" : data};
  }

  @override
  String toString() {
    return "SharedValue($timestamp, $data raw: $raw)";
  }
}

class SharedDataStore {
  //final NearbyService nearbyService = NearbyService();
  final Map<String, SharedValue> data = {};
  bool running = false;
  SharedState sharedState;
  final List<String> connectedDeviceIds = [];
  KeyPair? keyPair;

  SharedDataStore(this.sharedState);

  void loadFromJson(dynamic json) {
    for (final property in (json as Map<String, dynamic>).entries) {
      data[property.key] = SharedValue.fromJson(property.value as Map<String, dynamic>);
    }
  }

  Map<String, dynamic> getJsonData() {
    final Map<String, dynamic> jsonData = {};
    for (final property in data.entries) {
      jsonData[property.key] = property.value.toJson();
    }
    return jsonData;
  }

  Future<void> saveChanges() async {
    await sharedState.preferences.setString("sharedDataStoreData", jsonEncode(getJsonData()));
  }

  Future<void> stop() async {
    if (!running) return;
    //await nearbyService.stopAdvertisingPeer();
    //await nearbyService.stopBrowsingForPeers();
    await CustomNearbyConnections.stop();
  }

  Future<void> setProperty(String propertyName, dynamic value) async {
    data[propertyName] = await SharedValue.newSharedValue(DateTime.now(), value, keyPair!);
    await saveChanges();
  }

  dynamic getProperty(String propertyName) {
    return data[propertyName]?.data;
  }

  Future<void> syncLoop() async {
    while (running) {
      // Periodically broadcast all properties and their timestamp, so peers can request a value if they don't have that value, or have a older version
      final syncData = <String, String>{};
      for (final entry in data.entries) {
        syncData[entry.key] = entry.value.timestamp.toIso8601String();
      }
      await broadcastMessage(jsonEncode({"type": "sync", "data": syncData}));
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> broadcastMessage(String message) async {
    final futures = <Future<dynamic>>[];
    for (final peerId in connectedDeviceIds) {
      final result = null; //nearbyService.sendMessage(peerId, message);
      if (result.runtimeType == Future && result != null) {
        futures.add(result as Future);
      }
    }
    await Future.wait(futures);
  }

  Future<void> start() async {
    if (running) return;
    running = true;
    keyPair ??= await Ed25519().newKeyPair(); // TODO: Don't create a new key pair every time. Instead only create a new one, if there isn't one in the secure storage already.
    await CustomNearbyConnections.start();
    /*
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
        if (kDebugMode) {
          displayTextOverlay("[${device.deviceId}-${device.deviceName}] ${device.state}", const Duration(seconds: 3), sharedState, sharedState.buildContext!);
          log("deviceId: ${device.deviceId} | deviceName: ${device.deviceName} | state: ${device.state}", name: "Shared-Data-Store");
        }
      }
    });

    nearbyService.dataReceivedSubscription(callback: (receivedData) async {
      final jsonData = jsonDecode(receivedData as String) as Map<String, dynamic>;
      log(jsonData.toString(), name: "Shared-Data-Store"); //
      final fromDeviceId = jsonData["deviceId"] as String;
      final messageData = jsonData["message"] as Map<String, dynamic>;
      final messageType = messageData["type"] as String;
      if (kDebugMode) {
        log("Got $messageType Message from $fromDeviceId: $messageData", name: "Shared-Data-Store");
        displayTextOverlay("Got $messageType Message from $fromDeviceId: $messageData", const Duration(seconds: 3), sharedState, sharedState.buildContext!);
      }
      switch (messageType) {
        case "sync":
          final syncData = messageData["data"] as Map<String, String>;
          final newKeys = <String>[];
          for (final entry in syncData.entries) {
            if (!data.containsKey(entry.key)) {
              newKeys.add(entry.key);
            } else if (DateTime.parse(entry.value).isAfter(data[entry.key]!.timestamp)) {
              newKeys.add(entry.key);
            }
          }
          if (newKeys.isNotEmpty) {
            nearbyService.sendMessage(fromDeviceId, jsonEncode({"type" : "get", "keys": newKeys}));
          }
          break;
        case "get":
          final requestedKeys = messageData["keys"] as List<String>;
          final responseData = <String, dynamic>{};
          for (final requestedKey in requestedKeys) {
            if (data.containsKey(requestedKey)) {
              final value = data[requestedKey]!;
              responseData[requestedKey] = jsonEncode(value.raw);
            }
          }
          await nearbyService.sendMessage(fromDeviceId, jsonEncode({"type" : "data", "data" : responseData}));
          break;
        case "data":
          final peerData = messageData["data"] as Map<String, dynamic>;
          // TODO: Maybe do some validation of the timestamp
          for (final property in peerData.entries) {
            final peerSharedValue = await SharedValue.fromRaw(property.value as Map<String, dynamic>, keyPair!);
            if (!data.containsKey(property.key)) {
              if (kDebugMode) {
                log("Accepted new value ${property.key} from $fromDeviceId", name: "Shared-Data-Store");
                displayTextOverlay("Accepted new value ${property.key} from $fromDeviceId", const Duration(seconds: 3), sharedState, sharedState.buildContext!);
              }
              data[property.key] = peerSharedValue;
              continue;
            }
            if (peerSharedValue.timestamp.isAfter(data[property.key]!.timestamp)) {
              data[property.key] = peerSharedValue;
              if (kDebugMode) {
                log("Accepted newer value ${property.key} from $fromDeviceId", name: "Shared-Data-Store");
                displayTextOverlay("Accepted newer value ${property.key} from $fromDeviceId", const Duration(seconds: 3), sharedState, sharedState.buildContext!);
              }
            }
          }
          await saveChanges();
          break;
      }
    });
     */
    unawaited(syncLoop());
    log("Started", name: "Shared-Data-Store");
    if (kDebugMode) {
      displayTextOverlay("Shared-Data-Store: Started", const Duration(seconds: 3), sharedState, sharedState.buildContext!);
    }
  }

}