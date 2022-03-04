import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/helper_functions.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:stundenplan/widgets/bottom_overlay.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:tuple/tuple.dart';

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
    final signatureRaw = raw["signature"]! as Map<String, dynamic>;
    final signatureBytes = base64Decode(signatureRaw["bytes"]! as String);
    final signaturePublicKey = SimplePublicKey(base64Decode(signatureRaw["publicKey"]! as String), type: KeyPairType.ed25519);
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

class SharedValueList {
  List<SharedValue> sharedValues = [];

  SharedValueList(this.sharedValues);

  Future<void> addNewSharedValue(DateTime timestamp, dynamic data, KeyPair keyPair) async {
    sharedValues.add(await SharedValue.newSharedValue(timestamp, data, keyPair));
  }

  static SharedValueList fromJson(List<Map<String, dynamic>> sharedValuesJson) {
    final List<SharedValue> sharedValues = [];
    for (final sharedValueJson in sharedValuesJson) {
      sharedValues.add(SharedValue.fromJson(sharedValueJson));
    }
    return SharedValueList(sharedValues);
  }

  List<Map<String, dynamic>> toJson() {
    final List<Map<String, dynamic>> sharedValuesJson = [];
    for (final sharedValue in sharedValues) {
      sharedValuesJson.add(sharedValue.toJson());
    }
    return sharedValuesJson;
  }

  List<Map<String, String>> getSyncData() {
      final List<Map<String, String>> syncData = [];
      for (final sharedValue in sharedValues) {
        syncData.add({"timestamp": sharedValue.timestamp.toIso8601String(), "hash_code": jsonEncode(sharedValue.raw).hashCode.toString()});
      }
      return syncData;
  }

  @override
  String toString() {
    return sharedValues.toString();
  }
}

class SharedDataStore {
  final NearbyService nearbyService = NearbyService();
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  final Map<String, dynamic> data = {}; // Type should only contain SharedValue or SharedValueList
  bool running = false;
  SharedState sharedState;
  final List<String> connectedDeviceIds = [];
  KeyPair? keyPair;
  late String? deviceName;
  final Map<Tuple2<String, String>, Tuple2<int, List<String>>> partialReceivingBlocks = {};

  SharedDataStore(this.sharedState);

  void loadFromJson(dynamic json) {
    for (final property in (json as Map<String, dynamic>).entries) {
      if (property.value is Map) {
        data[property.key] = SharedValue.fromJson(property.value as Map<String, dynamic>);
      } else if (property.value is List) {
        data[property.key] = SharedValueList.fromJson(property.value as List<Map<String, dynamic>>);
      }
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
    await nearbyService.stopAdvertisingPeer();
    await nearbyService.stopBrowsingForPeers();
  }

  Future<void> setProperty(String propertyName, dynamic value) async {
    data[propertyName] = await SharedValue.newSharedValue(DateTime.now(), value, keyPair!);
    await saveChanges();
  }

  dynamic getProperty(String propertyName) {
    return data[propertyName]?.data;
  }

  Future<void> backgroundLoop() async {
    while (running) {
      await sendSync();
      await askForPartialBlocks();
      await Future.delayed(const Duration(milliseconds: 1000));
    }
  }

  Future<void> sendSync() async {
    // Periodically broadcast all properties and their timestamp, so peers can request a value if they don't have that value, or have a older version
    final syncData = <String, dynamic>{};
    for (final entry in data.entries) {
      if (entry.value is SharedValue) {
        syncData[entry.key] = (entry.value as SharedValue).timestamp.toIso8601String();
      } else if (entry.value is SharedValueList) {
        syncData[entry.key] = (entry.value as SharedValueList).getSyncData();
      }
    }
    broadcastMessage(jsonEncode({"type": "sync", "data": syncData}));
  }

  Future<void> askForPartialBlocks() async {
    if (partialReceivingBlocks.isEmpty) return;
    for (final entry in partialReceivingBlocks.entries) {
      final remoteDeviceId = entry.key.item1;
      final remotePropertyName = entry.key.item2;
      nearbyService.sendMessage(remoteDeviceId, jsonEncode({"type": "get_block", "property_key": remotePropertyName, "block" : entry.value.item2.length}));
    }
  }

  void broadcastMessage(String message) {
    for (final peerId in connectedDeviceIds) {
      nearbyService.sendMessage(peerId, message);
    }
  }

  Future<void> start() async {
    if (running) return;
    running = true;
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceName = androidInfo.display! + androidInfo.fingerprint!;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceName = iosInfo.name! + iosInfo.identifierForVendor!;
    }
    keyPair ??= await Ed25519().newKeyPair(); // TODO: Don't create a new key pair every time. Instead only create a new one, if there isn't one in the secure storage already.

    await nearbyService.init(
        serviceType: "HAG-SDS",
        strategy: Strategy.P2P_CLUSTER,
        deviceName: deviceName,
        callback: (bool isRunning) async {
          if (!isRunning) return null;
          // Restart browsing and advertising
          await nearbyService.stopAdvertisingPeer();
          await nearbyService.stopBrowsingForPeers();
          await Future.delayed(const Duration(microseconds: 200));
          // Don't await here, because it obviously makes sense that awaiting a start method does not in fact wait until the advertising is started, but infact never returns, because someone forgot to call result.success
          nearbyService.startAdvertisingPeer();
          nearbyService.startBrowsingForPeers();
          log("Started advertising and browsing", name: "Shared-Data-Store");
          if (kDebugMode) {
            displayTextOverlay("Shared-Data-Store: Started advertising and browsing", const Duration(seconds: 3), sharedState, sharedState.buildContext!);
          }
        }
    );

    nearbyService.stateChangedSubscription(callback: (devicesList) {
      for (final device in devicesList) {
        if (device.state == SessionState.notConnected && !connectedDeviceIds.contains(device.deviceId)) {
          log("Trying connecting to ${device.deviceName} ${device.deviceId}");
          nearbyService.invitePeer(deviceID: device.deviceId, deviceName: deviceName);
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
      final fromDeviceId = receivedData["deviceId"]! as String;
      final messageData = jsonDecode(receivedData["message"]! as String) as Map<String, dynamic>;
      final messageType = messageData["type"] as String;
      if (kDebugMode) {
        log("Got $messageType Message from $fromDeviceId: $messageData", name: "Shared-Data-Store");
        displayTextOverlay("Got $messageType Message from $fromDeviceId: ${truncateString(messageData.toString(), 1000)}", const Duration(seconds: 2), sharedState, sharedState.buildContext!);
      }
      switch (messageType) {
        case "sync":
          final syncData = messageData["data"] as Map<String, dynamic>;
          final newKeys = <String>[];
          for (final entry in syncData.entries) {
            if (partialReceivingBlocks.keys.where((e) => e.item2 == entry.key).isNotEmpty) continue;
            if (!data.containsKey(entry.key)) {
              newKeys.add(entry.key);
              continue;
            }
            if (data[entry.key] is SharedValue) {
              if (DateTime.parse(entry.value as String).isAfter((data[entry.key]! as SharedValue).timestamp)) {
                newKeys.add(entry.key);
              }
            } else if (data[entry.key] is SharedValueList) {
              // TODO: Implement
            }
          }
          if (newKeys.isNotEmpty) {
            nearbyService.sendMessage(fromDeviceId, jsonEncode({"type" : "get", "keys": newKeys}));
          }
          break;
        case "get":
          final requestedKeys = messageData["keys"] as List<dynamic>;
          final responseData = <String, dynamic>{};
          for (final requestedKey in requestedKeys) {
            if (data.containsKey(requestedKey as String)) {
              final value = data[requestedKey]!;
              responseData[requestedKey] = jsonEncode(value.raw);
            }
          }
          final responseString = jsonEncode({"type" : "data", "data" : responseData});
          if (responseString.length > Constants.sharedDataStoreBlockSize) {
            // Only sends first property, if message is to big
            // TODO: Send data block info for all requested keys messages
            final firstRequestProperty = responseData.entries.first;
            final nBlocks = (jsonEncode(firstRequestProperty.value).length / Constants.sharedDataStoreBlockSize).ceil();
            nearbyService.sendMessage(fromDeviceId, jsonEncode({"type" : "data_blocks_info", "property_key" : firstRequestProperty.key, "n_blocks" : nBlocks}));
          } else {
            nearbyService.sendMessage(fromDeviceId, responseString);
          }
          break;
        case "get_block":
          final requestedPropertyKey = messageData["property_key"]! as String;
          final requestedBlock = messageData["block"]! as int;
          if (!data.containsKey(requestedPropertyKey)) return;
          String responseData = "";
          if (data[requestedPropertyKey] is SharedValue) {
            final rawJsonString = jsonEncode(data[requestedPropertyKey]! as SharedValue);
            if (rawJsonString.length < Constants.sharedDataStoreBlockSize * requestedBlock) return;
            responseData = rawJsonString.substring(Constants.sharedDataStoreBlockSize * requestedBlock, math.min(Constants.sharedDataStoreBlockSize * (requestedBlock + 1), rawJsonString.length));
          } else if (data[requestedPropertyKey] is SharedValueList) {
            // TODO: Implement
            return;
          }
          nearbyService.sendMessage(fromDeviceId, jsonEncode({"type" : "data", "block": requestedBlock, "property_key": requestedPropertyKey, "data" : responseData}));
          break;
        case "data_blocks_info":
          final property = messageData["property_key"]! as String;
          final nBlocks = messageData["n_blocks"]! as int;
          partialReceivingBlocks[Tuple2(fromDeviceId, property)] = Tuple2(nBlocks, []);
          break;
        case "data":
          dynamic peerData = messageData["data"];
          if (messageData.containsKey("block")) {
            final block = messageData["block"]! as int;
            final propertyKey = messageData["property_key"]! as String;
            final partialBlockKey = Tuple2(fromDeviceId, propertyKey);
            final partialBlocks = partialReceivingBlocks[partialBlockKey]!;
            if (partialBlocks.item2.length != block) return;
            partialBlocks.item2.add(peerData as String);
            if (partialBlocks.item2.length == partialBlocks.item1) {
              final receivedValue = partialBlocks.item2.join();
              peerData = {propertyKey: receivedValue};
              partialReceivingBlocks.remove(partialBlockKey);
            } else {
              return;
            }
          }
          // TODO: Maybe do some validation of the timestamp
          for (final property in (peerData as Map<String, dynamic>).entries) {
            final peerSharedValue = await SharedValue.fromRaw(jsonDecode(property.value as String) as Map<String, dynamic>, keyPair!);
            if (!data.containsKey(property.key)) {
              if (kDebugMode) {
                log("Accepted new value ${property.key} from $fromDeviceId", name: "Shared-Data-Store");
                displayTextOverlay("Accepted new value ${property.key} from $fromDeviceId", const Duration(seconds: 3), sharedState, sharedState.buildContext!);
              }
              data[property.key] = peerSharedValue;
              continue;
            }
            if (data[property.key] is Map) {
              if (peerSharedValue.timestamp.isAfter((data[property.key]! as SharedValue).timestamp)) {
                data[property.key] = peerSharedValue;
                if (kDebugMode) {
                  log("Accepted newer value ${property.key} from $fromDeviceId", name: "Shared-Data-Store");
                  displayTextOverlay("Accepted newer value ${property.key} from $fromDeviceId", const Duration(seconds: 3), sharedState, sharedState.buildContext!);
                }
              }
            } else if (data[property.key] is List) {
              // TODO: Implement
            }
          }
          await saveChanges();
          break;
      }
    });
    unawaited(backgroundLoop());
  }

}