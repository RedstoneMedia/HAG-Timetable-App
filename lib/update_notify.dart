import 'dart:developer';
import 'dart:io';

import 'package:app_installer/app_installer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:yaml/yaml.dart'; // Contains a client for making API calls

class Version {
  late int majorVersion;
  late int minorVersion;
  late int microVersion;

  Version(String versionString) {
    final regExp = RegExp(r"(?<major>\d).(?<minor>\d).(?<micro>\d)");
    final match = regExp.firstMatch(versionString)!;
    majorVersion = int.parse(match.namedGroup("major")!);
    minorVersion = int.parse(match.namedGroup("minor")!);
    microVersion = int.parse(match.namedGroup("micro")!);
  }

  @override
  String toString() {
    return "$majorVersion.$minorVersion.$microVersion";
  }

  bool isOtherVersionGreater(Version other) {
    if (other.majorVersion > majorVersion) {
      return true;
    }
    if (other.minorVersion > minorVersion) {
      return true;
    }
    if (other.microVersion > microVersion) {
      return true;
    }
    return false;
  }
}

class UpdateNotifier {
  late Version currentVersion;
  late Client client;

  Future<void> init() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final versionString = packageInfo.version;
    currentVersion = Version(versionString);
    client = Client();
  }

  Future<Version> getNewestVersion() async {
    final response =
        await client.get(Uri.parse(Constants.newestVersionPubspecUrl));
    final pubspecYamlData = loadYaml(response.body);
    return Version(pubspecYamlData["version"].toString());
  }

  Future<void> checkForNewestVersionAndShowDialog(
      BuildContext context, SharedState sharedState) async {
    final newestVersion = await getNewestVersion();
    if (currentVersion.isOtherVersionGreater(newestVersion)) {
      await showNewVersionDialog(context, sharedState, newestVersion, currentVersion);
    }
  }

  Future<void> showNewVersionDialog(
      BuildContext context, SharedState sharedState, Version newVersion, Version currentVersion) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: sharedState.theme.backgroundColor,
          title: Text('Neue Version verfügbar',
              style: TextStyle(color: sharedState.theme.textColor)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Es ist eine neue Version verfügbar: $newVersion',
                    style: TextStyle(color: sharedState.theme.textColor)),
                Text('(Aktuelle Version: $currentVersion)',
                    style: TextStyle(color: sharedState.theme.textColor)),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                  sharedState.theme.subjectColor.withOpacity(0.9),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Ok',
                  style: TextStyle(color: sharedState.theme.textColor)),
            ),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                  sharedState.theme.subjectColor,
                ),
              ),
              onPressed: () async {
                final path = await downloadNewAPKVersion(newVersion);
                final dir = await getTemporaryDirectory();
                await installAPK("${dir.path}/stundenplan.apk");
              },
              child: Text('Herunterladen',
                  style: TextStyle(color: sharedState.theme.textColor)),
            )
          ],
        );
      },
    );
  }

  Future<String> downloadNewAPKVersion(Version newVersion) async {
      final url = Uri.parse("${Constants.newestReleaseDownloadUrlPart}$newVersion/app-arm64-v8a-release.apk");
      log("Downloading new APK", name: "updater");
      final response = await client.get(url);
      log("Download done. Downloaded ${response.contentLength} bytes.", name: "updater");
      final output = await getTemporaryDirectory();
      log("Saving APK in ${output.path}", name: "updater");
      final file = File("${output.path}/stundenplan.apk");
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
  }

  Future<void> installAPK(String path) async {
    log("Installing APK.", name: "updater");
    await AppInstaller.installApk(path);
    log("APK installed.", name: "updater");
}
}
