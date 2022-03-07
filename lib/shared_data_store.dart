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

  static SharedValueList fromJson(List<dynamic> sharedValuesJson) {
    final List<SharedValue> sharedValues = [];
    for (final sharedValueJson in sharedValuesJson) {
      sharedValues.add(SharedValue.fromJson(sharedValueJson as Map<String, dynamic>));
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

  List<Map<String, String>> getSyncMessageData() {
      final List<Map<String, String>> syncData = [];
      for (final sharedValue in sharedValues) {
        syncData.add({"timestamp": sharedValue.timestamp.toIso8601String(), "hash_code": jsonEncode(sharedValue.data).hashCode.toString()});
      }
      return syncData;
  }

  List<String> getRawJsonData({List<int>? indices}) {
    final List<String> sharedValuesJson = [];
    for (int i = 0; i < sharedValues.length; i++) {
      if (indices != null) if (!indices.contains(i)) continue;
      final sharedValue = sharedValues[i];
      sharedValuesJson.add(jsonEncode(sharedValue.raw));
    }
    return sharedValuesJson;
  }

  bool containsSharedValueHash(String sharedValueHash) {
    return sharedValues.where((sharedValue) => jsonEncode(sharedValue.data).hashCode.toString() == sharedValueHash).isNotEmpty;
  }

  @override
  String toString() {
    return "SharedValueList$sharedValues";
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
  final Map<Tuple2<String, Tuple2<String, int?>>, Tuple2<int, List<String>>> partialReceivingBlocks = {};

  SharedDataStore(this.sharedState);

  void loadFromJson(dynamic json) {
    for (final property in (json as Map<String, dynamic>).entries) {
      if (property.value is Map) {
        data[property.key] = SharedValue.fromJson(property.value as Map<String, dynamic>);
      } else if (property.value is List) {
        data[property.key] = SharedValueList.fromJson(property.value as List<dynamic>);
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

  Future<void> setProperty(String propertyName, dynamic value, {DateTime? timestamp}) async {
    timestamp ??= DateTime.now();
    if (value is List) {
      data[propertyName] = SharedValueList([]);
      for (final dataValue in value) {
        await (data[propertyName] as SharedValueList).addNewSharedValue(timestamp, dataValue, keyPair!);
      }
    } else {
      data[propertyName] = await SharedValue.newSharedValue(timestamp, value, keyPair!);
    }
    return saveChanges();
  }

  Future<void> addToPropertyList(String propertyName, dynamic value, {DateTime? timestamp}) async {
    timestamp ??= DateTime.now();
    if (!data.containsKey(propertyName)) return;
    final sharedValueList = data[propertyName] as SharedValueList;
    await sharedValueList.addNewSharedValue(timestamp, value, keyPair!);
    return saveChanges();
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
        syncData[entry.key] = (entry.value as SharedValueList).getSyncMessageData();
      }
    }
    broadcastMessage(jsonEncode({"type": "sync", "data": syncData}));
  }

  Future<void> askForPartialBlocks() async {
    if (partialReceivingBlocks.isEmpty) return;
    for (final entry in partialReceivingBlocks.entries) {
      final remoteDeviceId = entry.key.item1;
      final remotePropertyName = entry.key.item2.item1;
      final getBlockData = {"type": "get_block", "property_key": remotePropertyName, "block" : entry.value.item2.length};
      if (entry.key.item2.item2 != null) {
        getBlockData["list_index"] = entry.key.item2.item2!;
      }
      nearbyService.sendMessage(remoteDeviceId, jsonEncode(getBlockData));
    }
  }

  void broadcastMessage(String message) {
    for (final peerId in connectedDeviceIds) {
      nearbyService.sendMessage(peerId, message);
    }
  }

  Future<void> loadKeyPair() async {
    // TODO: Don't create a new key pair every time. Instead only create a new one, if there isn't one in the secure storage already.
    keyPair ??= await Ed25519().newKeyPair();
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
    await loadKeyPair();
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
          await handleSyncMessage(fromDeviceId, messageData);
          break;
        case "get":
          await handleGetMessage(fromDeviceId, messageData);
          break;
        case "get_block":
          await handleGetBlockMessage(fromDeviceId, messageData);
          break;
        case "data_blocks_info":
          await handleDataBlocksInfo(fromDeviceId, messageData);
          break;
        case "data":
          await handleDataMessage(fromDeviceId, messageData);
          break;
      }
    });
    unawaited(backgroundLoop());
  }

  // Message handlers

  Future<void> handleSyncMessage(String fromDeviceId, Map<String, dynamic> messageData) async {
    final syncData = messageData["data"] as Map<String, dynamic>;
    final newKeys = <String, dynamic>{};
    for (final entry in syncData.entries) {
      if (partialReceivingBlocks.keys.where((e) => e.item2 == entry.key).isNotEmpty) continue;
      if (!data.containsKey(entry.key)) {
        newKeys[entry.key] = true;
        continue;
      }
      if (data[entry.key] is SharedValue) {
        if (DateTime.parse(entry.value as String).isAfter((data[entry.key]! as SharedValue).timestamp)) {
          newKeys[entry.key] = true;
        }
      } else if (data[entry.key] is SharedValueList) {
        final sharedValueList = data[entry.key] as SharedValueList;
        final remoteValues = entry.value as List<Map<String, dynamic>>;
        newKeys[entry.key] = [];
        for (int i = 0; i < remoteValues.length; i++) {
          final remoteValueSyncData = remoteValues[i];
          if (sharedValueList.containsSharedValueHash(remoteValueSyncData["hash_code"]! as String)) {
            (newKeys[entry.key] as List<int>).add(i);
          }
        }
      }
    }
    if (newKeys.isNotEmpty) {
      nearbyService.sendMessage(fromDeviceId, jsonEncode({"type" : "get", "keys": newKeys}));
    }
  }

  Future<void> handleGetMessage(String fromDeviceId, Map<String, dynamic> messageData) async {
    final requestedKeys = messageData["keys"] as Map<String, dynamic>;
    final responseData = <String, dynamic>{};
    for (final requestedEntry in requestedKeys.entries) {
      if (data.containsKey(requestedEntry.key)) {
        final value = data[requestedEntry.key];
        if (requestedEntry.value is List && value is SharedValueList) {
          responseData[requestedEntry.key] = jsonEncode(value.getRawJsonData(indices: requestedEntry.value as List<int>));
        } else if (requestedEntry.value == true) {
          if (value is SharedValue) {
            responseData[requestedEntry.key] = jsonEncode(value.raw);
          } else if (value is SharedValueList) {
            responseData[requestedEntry.key] = value.getRawJsonData();
          }
        }
      }
    }
    final responseString = jsonEncode({"type" : "data", "data" : responseData});
    // Sends properties as blocks, if message is to big
    if (responseString.length > Constants.sharedDataStoreBlockSize) {
      final blocksInfo = <Map<String, dynamic>>[];
      for (final responseDataEntry in responseData.entries) {
        if (responseDataEntry.value is String) {
          final nBlocks = ((responseDataEntry.value as String).length / Constants.sharedDataStoreBlockSize).ceil();
          blocksInfo.add({"property_key" : responseDataEntry.key, "n_blocks" : nBlocks});
        } else if (responseDataEntry.value is List<String>) {
          for (int i = 0; i < (responseDataEntry.value as List<String>).length; i++) {
            final dataValue = responseDataEntry.value[i] as String;
            final nBlocks = (dataValue.length / Constants.sharedDataStoreBlockSize).ceil();
            blocksInfo.add({"property_key" : responseDataEntry.key, "list_index" : i, "n_blocks" : nBlocks});
          }
        }
      }
      nearbyService.sendMessage(fromDeviceId, jsonEncode({"type" : "data_blocks_info", "blocks_info" : blocksInfo}));
    } else {
      nearbyService.sendMessage(fromDeviceId, responseString);
    }
  }

  Future<void> handleDataBlocksInfo(String fromDeviceId, Map<String, dynamic> messageData) async {
    final blocksInfo = messageData["blocks_info"] as List<Map<String, dynamic>>;
    for (final blockInfo in blocksInfo) {
      final property = blockInfo["property_key"]! as String;
      if (partialReceivingBlocks.containsKey(Tuple2(fromDeviceId, property))) return; // Avoids resetting blocks, while they are being received
      final nBlocks = blockInfo["n_blocks"]! as int;
      final propertyKey = blockInfo.containsKey("list_index") ? Tuple2(property, blockInfo["list_index"]! as int) : Tuple2(property, null);
      partialReceivingBlocks[Tuple2(fromDeviceId, propertyKey)] = Tuple2(nBlocks, []);
    }
  }

  Future<void> handleGetBlockMessage(String fromDeviceId, Map<String, dynamic> messageData) async {
    final requestedPropertyKey = messageData["property_key"]! as String;
    final requestedBlock = messageData["block"]! as int;
    if (!data.containsKey(requestedPropertyKey)) return;
    String? rawJsonString;
    if (data[requestedPropertyKey] is SharedValue) {
      rawJsonString = jsonEncode(data[requestedPropertyKey]! as SharedValue);
    } else if (data[requestedPropertyKey] is SharedValueList && messageData.containsKey("list_index")) {
      final listIndex = messageData["list_index"] as int;
      final sharedValueList = (data[requestedPropertyKey]! as SharedValueList).sharedValues;
      if (sharedValueList.length <= listIndex) return;
      rawJsonString = jsonEncode(sharedValueList[listIndex]);
    }
    if (rawJsonString!.length < Constants.sharedDataStoreBlockSize * requestedBlock) return;
    final responseData = rawJsonString.substring(Constants.sharedDataStoreBlockSize * requestedBlock, math.min(Constants.sharedDataStoreBlockSize * (requestedBlock + 1), rawJsonString.length));
    final Map<String, dynamic> responseMessage = {"type" : "data", "block": requestedBlock, "property_key": requestedPropertyKey, "data" : responseData};
    if (messageData.containsKey("list_index")) responseMessage["list_index"] = messageData["list_index"];
    nearbyService.sendMessage(fromDeviceId, jsonEncode(responseMessage));
  }

  Future<void> handleDataMessage(String fromDeviceId, Map<String, dynamic> messageData) async {
    dynamic peerData = messageData["data"];
    // Handle block data
    if (messageData.containsKey("block")) {
      final block = messageData["block"]! as int;
      final propertyKey = messageData["property_key"]! as String;
      final propertyTuple = messageData.containsKey("list_index") ? Tuple2(propertyKey, messageData["list_index"] as int) : Tuple2(propertyKey, null);
      final partialBlockKey = Tuple2(fromDeviceId, propertyTuple);
      if (!partialReceivingBlocks.containsKey(partialBlockKey)) return;
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
    // Accept new complete properties
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
      if (data[property.key] is SharedValue) {
        if (peerSharedValue.timestamp.isAfter((data[property.key]! as SharedValue).timestamp)) {
          data[property.key] = peerSharedValue;
          if (kDebugMode) {
            log("Accepted newer value ${property.key} from $fromDeviceId", name: "Shared-Data-Store");
            displayTextOverlay("Accepted newer value ${property.key} from $fromDeviceId", const Duration(seconds: 3), sharedState, sharedState.buildContext!);
          }
        }
      } else if (data[property.key] is SharedValueList) {
        final sharedValueList = data[property.key] as SharedValueList;
        if (property.value is! List) return;
        for (final sharedValueData in property.value) {
          final peerSharedValue = await SharedValue.fromRaw(jsonDecode(sharedValueData as String) as Map<String, dynamic>, keyPair!);
          if (sharedValueList.containsSharedValueHash(jsonEncode(peerSharedValue.data).hashCode as String)) continue;
          sharedValueList.sharedValues.add(peerSharedValue);
          log("Added new value to ${property.key} from $fromDeviceId", name: "Shared-Data-Store");
          displayTextOverlay("Added new value to ${property.key} from $fromDeviceId", const Duration(seconds: 3), sharedState, sharedState.buildContext!);
        }
      }
    }
    await saveChanges();
  }

}