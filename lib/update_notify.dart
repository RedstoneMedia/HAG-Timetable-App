import 'package:package_info/package_info.dart';
import 'package:http/http.dart';
import 'package:stundenplan/constants.dart';
import 'package:yaml/yaml.dart'; // Contains a client for making API calls

class Version {
  int majorVersion;
  int minorVersion;
  int microVersion;

  Version(String versionString) {
    RegExp regExp = new RegExp(r"(?<major>\d).(?<minor>\d).(?<micro>\d)");
    RegExpMatch match = regExp.firstMatch(versionString);
    majorVersion = int.parse(match.namedGroup("major"));
    minorVersion = int.parse(match.namedGroup("minor"));
    microVersion = int.parse(match.namedGroup("micro"));
  }

  @override
  String toString() {
    return "$majorVersion.$minorVersion.$microVersion";
  }

  bool isOtherVersionGreater(Version other) {
    if (other.majorVersion > this.majorVersion)
      return true;
    if (other.minorVersion > this.minorVersion)
      return true;
    if (other.microVersion > this.microVersion)
      return true;
    return false;
  }

}

class UpdateNotifier {

  Version currentVersion;
  Client client;

  Future<void> init() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String versionString = packageInfo.version;
    currentVersion = Version(versionString);
    client = new Client();
  }

  Future<Version> getNewestVersion() async {
    Response response = await client.get(Constants.newestVersionPubspecUrl);
    var pubspecYamlData = loadYaml(response.body);
    return Version(pubspecYamlData["version"]);
  }

  //Todo impl push notification

}