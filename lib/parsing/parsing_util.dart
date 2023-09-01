String customStrip(String s) {
  return s.replaceAll(" ", "")
      .replaceAll("\t", "")
      .replaceAll("\n", "");
}

String getCookieStringFromSetCookieHeader(String setCookieString, List<String> relevantCookies) {
  final cookies = setCookieString.split(";");
  final stringBuffer = StringBuffer();
  for (var cookie in cookies) {
    cookie = cookie.replaceAll(" ", "");
    final cookieAttributes = cookie.split(",");
    for (final cookieAttribute in cookieAttributes) {
      final cookieKeyValueSplit = cookieAttribute.split("=");
      if (cookieKeyValueSplit.length <= 1) continue;
      if (relevantCookies.contains(cookieKeyValueSplit[0])) {
        stringBuffer.write("$cookieAttribute; ");
      }
    }
  }
  return stringBuffer.toString();
}
