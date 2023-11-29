import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/helper_functions.dart'; // Contains a client for making API calls
import 'package:tuple/tuple.dart';

enum IServLoginResponseKind {
  ok,
  badPassword,
  badUsername,
  error
}

const basicHeaders = {
  "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
  "Accept-Language": "en-GB,en;q=0.5",
  "Upgrade-Insecure-Requests": "1",
  "Sec-Fetch-Dest": "document",
  "Sec-Fetch-Mode": "navigate",
  "Sec-Fetch-Site": "same-origin",
  "Sec-Fetch-User": "?1",
  "Sec-GPC": "1",
  "Pragma": "no-cache",
  "Cache-Control": "no-cache"
};

const iServLoginExtraHeaders = {
  "Content-Type": "application/x-www-form-urlencoded"
};


Future<String> readResponse(HttpClientResponse response) {
  final completer = Completer<String>();
  final contents = StringBuffer();
  response.transform(utf8.decoder).listen((data) {
    contents.write(data);
  }, onDone: () => completer.complete(contents.toString()));
  return completer.future;
}


Future<Tuple4<Uri, int, HttpClientResponse, String>> followRedirects(HttpClient client, CookieJar cj, HttpClientResponse response) async {
  Uri? uri;
  int redirects = 0;
  String? lastBody;
  var lastResponse = response;
  while (lastResponse.statusCode == 302 || lastResponse.statusCode == 301 && redirects < 10) {
    // Get the new uri based on the last response
    final newLocation = lastResponse.headers.value("location")!;
    final newUri = newLocation.startsWith("/") ? Uri.parse("${Constants.iServHost}$newLocation") : Uri.parse(newLocation);
    assert(newUri.toString().startsWith(Constants.iServHost));
    // If the uri did not change no further request is necessary
    if (newUri != uri) {
      uri = newUri;
    } else {break;}
    // Make request on new location
    final request = await client.getUrl(uri);
    request.followRedirects = false;
    request.cookies.addAll(await cj.loadForRequest(uri));
    for (final entry in basicHeaders.entries) {
      request.headers.add(entry.key, entry.value);
    }
    lastResponse = await request.close();
    if (lastResponse.statusCode != 302) {
      lastBody = await readResponse(lastResponse);
    }
    await cj.saveFromResponse(uri, lastResponse.cookies);
    redirects += 1;
  }

  return Tuple4(uri!, redirects, lastResponse, lastBody!);
}

Future<Tuple4<Uri, int, HttpClientResponse, String>> makeRequestWithRedirects(String method, Uri uri, HttpClient client, CookieJar cj, {String? body, Map<String, String>? headers}) async {
  log("Make $method request to ${uri.path} with redirects", name: "iserv.auth");
  final request = await client.openUrl(method, uri);
  request.followRedirects = false;
  request.cookies.addAll(await cj.loadForRequest(uri));
  // Construct headers
  final Map<String, String> allHeaders = {...basicHeaders};
  allHeaders.addAll(headers ?? {});
  for (final entry in allHeaders.entries) {
    request.headers.add(entry.key, entry.value);
  }
  // Include body if needed
  if (body != null) request.write(body);
  // Make request and store cookies
  final HttpClientResponse response = await request.close();
  await cj.saveFromResponse(uri, response.cookies);
  if (response.statusCode != 302) {
    // Store the first requests body, if there is one
    final firstRequestBody = await response.transform(utf8.decoder).firstWhere((e) => true);
    return Tuple4(uri, 0, response, firstRequestBody);
  } else {
    // Follow redirects and remember cookies
    return followRedirects(client, cj, response);
  }
}

IServLoginResponseKind getIServLoginResponseKind(int statusCode, String responseBody) {
  if (responseBody.contains("Anmeldung fehlgeschlagen!")) {
    log("Cannot login. Bad password", name: "iserv.auth");
    return IServLoginResponseKind.badPassword;
  }
  if (responseBody.contains("existiert nicht")) {
    log("Cannot login. Bad username", name: "iserv.auth");
    return IServLoginResponseKind.badUsername;
  }
  if (statusCode != 200 || responseBody.contains("IServ-Anmeldung")) {
    log("Cannot login. Error code $statusCode", name: "iserv.auth");
    return IServLoginResponseKind.error;
  }
  return IServLoginResponseKind.ok;
}

String getIServLoginPostBody(Tuple2<String, String> iServCredentials) {
  return "_username=${iServCredentials.item1}&_password=${iServCredentials.item2}";
}


Future<Tuple2<List<Cookie>?, IServLoginResponseKind>> getIServLoginCookies(Tuple2<String, String> iServCredentials) async {
  final cj = CookieJar();
  final client = HttpClient();
  // Make get request to login url to get redirected to the correct website
  final tempResult = await makeRequestWithRedirects("GET", Uri.parse(Constants.loginUrlIServ), client, cj);
  await Future.delayed(const Duration(milliseconds: 300));
  // Send a post request to the login data
  final bodyString = getIServLoginPostBody(iServCredentials);
  final result = await makeRequestWithRedirects("POST", tempResult.item1, client, cj, headers: iServLoginExtraHeaders, body: bodyString);
  final response = result.item3;
  final responseBody = result.item4;
  client.close();
  // Check for errors
  final responseKind = getIServLoginResponseKind(response.statusCode, responseBody);
  if (responseKind != IServLoginResponseKind.ok) {
    return Tuple2(null, responseKind);
  }
  // Grab cookies from last request and return ok result
  final cookies = await cj.loadForRequest(result.item1);
  return Tuple2(cookies, IServLoginResponseKind.ok);
}

Future<bool> areCookiesGood(String? cookies) async {
  if (cookies == null) return false;
  // Make request to badges (Used because it's response size is quite small and requires authentication)
  final client = HttpClient();
  final request = await client.openUrl("GET", Uri.parse("${Constants.iServHost}/iserv/app/navigation/badges"));
  request.followRedirects = false;
  request.headers.add("Cookie", cookies);
  final HttpClientResponse response = await request.close();
  if (response.statusCode != 302) response.transform(utf8.decoder).listen((_) {});
  // Cookies are good, when the status code is ok
  return response.statusCode == 200;
}

Future<String?> iServLogin() async {
  final storedSessionCookies = await getIServSessionCookies();
  if (await areCookiesGood(storedSessionCookies)) {
    log("Using stored cookies", name: "iserv.auth");
    return storedSessionCookies;
  }
  final iServCredentials = await getIServCredentials();
  if (iServCredentials == null) return null;
  final result = await getIServLoginCookies(iServCredentials);
  if (result.item2 != IServLoginResponseKind.ok) return null;
  final cookies = result.item1!;
  final authCookieStringBuffer = StringBuffer();
  for (final cookie in cookies) {
    if (cookie.name.startsWith("IServSAT") || cookie.name.startsWith("IServSession")) {
      authCookieStringBuffer.write("${cookie.name}=${cookie.value}; ");
    }
  }
  // Construct string from buffer, return it, and store it for later to avoid unnecessary login requests.
  final authCookieString = authCookieStringBuffer.toString();
  await setIServSessionCookies(authCookieString);
  return authCookieString;
}

Map<String, String> getAuthHeaderFromCookies(String cookies) {
  return {...basicHeaders, "Cookie": cookies};
}
