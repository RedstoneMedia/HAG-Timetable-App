import 'dart:developer';

import 'package:http/http.dart';
import 'package:tuple/tuple.dart';

import '../constants.dart';
import '../helper_functions.dart'; // Contains a client for making API calls


Future<Response?> getIServLoginResponse(Client client, Tuple2<String, String> iServCredentials) async {
  final bodyString = "_username=${iServCredentials.item1}&_password=${iServCredentials.item2}";
  final Map<String, String> headers = {
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
    "Accept-Language": "en-GB,en;q=0.5",
    "Content-Type": "application/x-www-form-urlencoded",
    "Upgrade-Insecure-Requests": "1",
    "Sec-Fetch-Dest": "document",
    "Sec-Fetch-Mode": "navigate",
    "Sec-Fetch-Site": "same-origin",
    "Sec-Fetch-User": "?1",
    "Sec-GPC": "1",
    "Pragma": "no-cache",
    "Cache-Control": "no-cache"
  };
  final response = await client.post(Uri.parse(Constants.loginUrlIServ), headers: headers, body: bodyString);
  if (response.body.contains("Anmeldung fehlgeschlagen!")) {
    log("Cannot login. Bad credentials", name: "iserv.auth");
    return null;
  }
  if (response.statusCode != 302) {
    log("Cannot login. Error code ${response.statusCode}", name: "iserv.auth");
    return null;
  }
  return response;
}

Future<String?> iServLogin(Client client) async {
  final iServCredentials = await getIServCredentials();
  if (iServCredentials == null) return null;
  final response = await getIServLoginResponse(client, iServCredentials);
  if (response == null) return null;

  final cookiesString = response.headers["set-cookie"];
  final cookies = cookiesString!.split(";");
  final authCookieStringBuffer = StringBuffer();
  for (var cookie in cookies) {
    cookie = cookie.replaceAll(" ", "");
    final cookieAttributes = cookie.split(",");
    for (final cookieAttribute in cookieAttributes) {
      final cookieKeyValueSplit = cookieAttribute.split("=");
      if (cookieKeyValueSplit.length <= 1) continue;
      if (cookieKeyValueSplit[0].startsWith("IServSAT") || cookieKeyValueSplit[0].startsWith("IServSession")) {
        authCookieStringBuffer.write("$cookieAttribute; ");
      }
    }
  }
  return authCookieStringBuffer.toString();
}

Map<String, String> getAuthHeaderFromCookies(String cookies) {
  return {
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
    "Accept-Language": "en-GB,en;q=0.5",
    "Upgrade-Insecure-Requests": "1",
    "Sec-Fetch-Dest": "document",
    "Sec-Fetch-Mode": "navigate",
    "Sec-Fetch-Site": "same-origin",
    "Sec-Fetch-User": "?1",
    "Sec-GPC": "1",
    "Pragma": "no-cache",
    "Cache-Control": "no-cache",
    "Cookie" : cookies,
  };
}