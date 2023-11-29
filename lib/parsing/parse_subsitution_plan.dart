import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:html/parser.dart'; // Contains HTML parsers to generate a Document object
import 'package:http/http.dart';  // Contains a client for making API calls
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/content.dart';
import 'package:stundenplan/helper_functions.dart';
import 'package:stundenplan/integration.dart';
import 'package:stundenplan/parsing/parse.dart';
import 'package:stundenplan/parsing/parsing_util.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:stundenplan/week_subsitutions.dart';
import 'package:tuple/tuple.dart';

import 'iserv_authentication.dart';


Future<void> overwriteContentWithSubstitutionPlan(
    SharedState sharedState,
    Client client,
    Content content,
    List<String> subjects) async
{
  await Integrations.instance.update(values: ["substitutions"]);
  final weekSubstitutions = Integrations.instance.getValue("substitutions")! as WeekSubstitutions;
  // Write substitutions to content.
  for (final weekDayString in weekSubstitutions.weekSubstitutions!.keys) {
    final weekDay = int.parse(weekDayString);
    final daySubstitution = weekSubstitutions.weekSubstitutions![weekDayString]!;
    writeSubstitutionPlan(daySubstitution.item1, weekDay, content, subjects);
  }
}

void writeSubstitutionPlan(List<Tuple2<Map<String, dynamic>, String>> plan, int weekDay,
    Content content, List<String> subjects)
{
  for (var i = 0; i < plan.length; i++) {
    final substitution = plan[i].item1;
    final hours = customStrip(substitution["Stunde"] as String).split("-");

    // Fill cell
    final cell = Cell();
    cell.subject = customStrip(substitution["Fach"] as String);
    cell.originalSubject = customStrip(substitution["statt Fach"] as String);
    if (!subjects.contains(cell.originalSubject)) {
      // Unicode 00A0 (Non breaking space, because that makes sense) indicates that
      // the subject replaces all other lessons taking place in the same time
      if (cell.originalSubject != "\u{00A0}") {
        // If user dose not have that subject skip that class
        continue;
      }
    }
    cell.teacher = customStrip(substitution["Vertretung"]! as String);
    cell.originalTeacher = customStrip(substitution["statt Lehrer"]! as String);
    cell.room = customStrip(substitution["Raum"]! as String);
    cell.originalRoom = customStrip(substitution["statt Raum"]! as String);
    cell.text = substitution["Text"] as String;
    cell.source = plan[i].item2;
    if (substitution.containsKey("Art")) cell.substitutionKind = substitution["Art"]!.toString();
    cell.isDropped = customStrip(substitution["Entfall"]! as String) == "x";

    // Replace non breaking space with three dashes
    // We need to do this because, otherwise the cell will not have any visible text and will just display a solid color.
    if (cell.subject == "\u{00A0}") cell.subject = "---";
    if (cell.teacher == "\u{00A0}") cell.teacher = "---";
    if (cell.room == "\u{00A0}") cell.room = "---";

    // Sometimes a substitution is set, but there is no data set which means that it is dropped.
    if (cell.subject == "---" && cell.room == "---" && cell.teacher == "---") {
      cell.isDropped = true;
    } else if (!cell.isDropped) {
      cell.isSubstitute = true;
    }

    if (hours.length == 1) {
      // No hour range (5)
      final hour = int.parse(hours[0]);
      cell.footnotes = content.getCell(hour - 1, weekDay).footnotes;
      content.setCell(hour - 1, weekDay, cell);
    } else if (hours.length == 2) {
      // Hour range (5-6)
      final hourStart = int.parse(hours[0]);
      final hourEnd = int.parse(hours[1]);
      for (var i = hourStart; i < hourEnd + 1; i++) {
        cell.footnotes = content.getCell(i -1, weekDay).footnotes;
        // Check if there is a subject that replaces all other subjects
        // (indicated by Unicode 00A0)
        if(content.getCell(i - 1, weekDay).originalSubject != "\u{00A0}") {
          content.setCell(i - 1, weekDay, cell);
        }
      }
    }
  }
}

class IServUnitsSubstitutionIntegration extends Integration {
  static const List<String> customSubstitutionProperties = ["(Le.) nach", "Art"];

  final Client client = Client();
  final SharedState sharedState;
  final Map<String, String> lastResponses = {};
  bool loadCheckWeekDay = true;

  IServUnitsSubstitutionIntegration(this.sharedState) : super(name: "IServ", save: true, precedence: 0, providedValues: ["substitutions"]);

  @override
  Future<void> init() async {
    values["substitutions"] = WeekSubstitutions(null, name);
  }

  @override
  Future<void> update() async {
    final weekSubstitutions = values["substitutions"]! as WeekSubstitutions;
    final schoolClasses = getRelevantSchoolClasses(sharedState);
    if (Constants.defineHasTesterFeature) lastResponses.clear();
    // Get substitutions for each class and write it to week substitutions
    for (final schoolClassName in schoolClasses) {
      final ret = await getCourseSubstitutionPlan(schoolClassName);
      final classPlan = ret["substitutions"] as List<Map<String, String>>;
      final classSubstituteDate = ret["substituteDate"] as DateTime;
      weekSubstitutions.setDay(classPlan, classSubstituteDate, name);
    }
  }

  @override
  void loadValuesFromJson(Map<String, dynamic> jsonValues) {
    for (final jsonValueEntry in jsonValues.entries) {
      if (jsonValueEntry.key == "substitutions") {
        values[jsonValueEntry.key] = WeekSubstitutions(jsonValueEntry.value, name, checkWeekDay: loadCheckWeekDay);
      }
    }
  }

  @override
  Map<String, dynamic> saveValuesToJson() {
    final json = super.saveValuesToJson();
    if (Constants.defineHasTesterFeature) json["lastResponses"] = lastResponses;
    return json;
  }

  Future<Map<String, dynamic>> getCourseSubstitutionPlan(String course) async {
    final response = await client.get(Uri.parse('${Constants.substitutionLinkBase}_$course.htm'));
    if (Constants.defineHasTesterFeature) lastResponses[course] = "${response.statusCode}\n\n${response.body}";
    if (response.statusCode != 200) {
      log("Could not get substitution plan status code: ${response.statusCode}", name: "iserv-units-integration");
      return {
        "substitutions" : <Map<String, String>>[],
        "substituteDate" : DateTime.now(),
        "substituteWeekday" : 1
      };
    }

    final document = parse(response.body);
    if (document.outerHtml.contains("Fatal error")) {
      log("Could not parse substitution plan: Fatal error", name: "iserv-units-integration");
      return {
        "substitutions" : <Map<String, String>>[],
        "substituteDate" : DateTime.now(),
        "substituteWeekday" : 1
      };
    }
    // Why does this even happen sometimes. Fix your stuff please Units!
    if (!(document.body?.text.contains(course) ?? false)) {
      log("Could not load substitution for course: $course. Site does not contain course name", level: 3);
      return {
        "substitutions" : <Map<String, String>>[],
        "substituteDate" : DateTime.now(),
        "substituteWeekday" : 1
      };
    }

    // Get weekday for that substitute table
    final headerText = customStrip(document
        .getElementsByTagName("body")[0]
        .children[0]
        .children[0]
        .children[2]
        .text
        .replaceAll("  ", "/"));
    final regexp = RegExp(r"^[\w-]*\w+\/(?<day>\d+).(?<month>\d+).");
    final match = regexp.firstMatch(headerText)!;

    final substituteDate = DateTime(
        DateTime.now().year,
        int.parse(match.namedGroup("month")!),
        int.parse(match.namedGroup("day")!));
    var substituteWeekday = substituteDate.weekday;
    if (substituteWeekday > 5) {
      substituteWeekday = math.min(DateTime.now().weekday, 5);
    }

    final tables = document.getElementsByTagName("table");
    for (var i = 0; i < tables.length; i++) {
      if (!tables[i].attributes.containsKey("rules")) {
        tables.removeAt(i);
      }
    }

    final mainTable = tables[0];
    final rows = mainTable.getElementsByTagName("tr");
    final baseHeaderInformation = [
      "Stunde",
      "Fach",
      "Raum",
      "Art",
      "Lehrer",
      "Text",
      "Vertr-Text-2",
      "(Le.) nach",
      "Entfall"
    ];
    // Check what kind of columns exist and in what order they appear in the header
    final headerRow = rows.removeAt(0);
    headerRow.children.removeAt(0);
    final headerInformation = <String?>[];
    for (var i = 0; i < headerRow.children.length; i++) {
      final headerColumnText = headerRow.children[i].text;
      final headerName = baseHeaderInformation.firstWhereOrNull((headerName) {
        final checkHeaderName = headerName == "Lehrer" ? "(Lehrer)" : headerName;
        return headerColumnText.contains(checkHeaderName);
      });
      if (headerInformation.contains(headerName)) {
        headerInformation.add(null);
      } else {
        headerInformation.add(headerName);
      }
    }
    // Parse substitutions in rows
    final substitutions = <Map<String, String>>[];
    for (final row in rows) {
      final substitution = <String, String>{"Entfall": ""};
      final columns = row.getElementsByTagName("td");
      for (var i = 0; i < headerInformation.length; i++) {
        // Get the substitution keys for the header information and the current columns index
        var substitutionKey = headerInformation[i];
        if (substitutionKey == null) continue;
        final columnIndex = i + 1;
        substitutionKey = substitutionKey == "Lehrer" ? "Vertretung" : substitutionKey;
        String? beforeSubstitutionKey;
        if (["Fach", "Raum", "Vertretung"].contains(substitutionKey)) {
          beforeSubstitutionKey = "statt ${substitutionKey == "Vertretung" ? "Lehrer" : substitutionKey}";
        }
        // Handle random edge case, when there is no font child element
        if (columns[columnIndex].text == "\u{00A0}") {
          substitution[substitutionKey] = "\u{00A0}";
          if (beforeSubstitutionKey != null) substitution[beforeSubstitutionKey] = "\u{00A0}";
        }
        if (columns[columnIndex].children.isEmpty) continue;
        final cellElement = columns[columnIndex].children[0];
        final strikethroughElements = cellElement.getElementsByTagName("s");
        // Strikethrough indicates before value
        if (strikethroughElements.isNotEmpty && beforeSubstitutionKey != null) {
          final beforeSubstitutionValue = strikethroughElements[0].text;
          substitution[beforeSubstitutionKey] = beforeSubstitutionValue.replaceAll("\n", " ");
          // If there is only strikethrough text, the actual value will be empty (non breaking whitespace)
          if (!cellElement.text.contains("→")) {
            substitution[substitutionKey] = "---";
            continue;
          }
        }
        // Add the substitution value (Sometimes after an arrow)
        final cellValue = cellElement.text.replaceAll("\n", " ").split("→").last;
        substitution[substitutionKey] = cellValue;
        if (strikethroughElements.isEmpty && beforeSubstitutionKey != null) {
          substitution[beforeSubstitutionKey] = cellValue;
        }
      }
      if ((substitution["Art"] ?? substitution["(Le.) nach"] ?? "").contains("Entfall")) substitution["Entfall"] = "x";
      substitutions.add(substitution);
    }

    return {
      "substitutions" : substitutions,
      "substituteDate" : substituteDate,
      "substituteWeekday" : substituteWeekday
    };
  }

}


class SchulmanagerIntegration extends Integration {
  Client client = Client();
  SharedState sharedState;
  late String bundleVersion;
  late String authJwt;
  late Map<String, dynamic> studentData;
  bool active = false;
  bool loadCheckWeekDay = true;
  dynamic lastResponse;

  SchulmanagerIntegration.Schulmanager(this.sharedState) : super(name: "Schulmanager", save: true, precedence: 1, providedValues: ["substitutions"]);

  @override
  Future<void> init() async {
    final _bundleVersion = await getBundleVersion();
    if (_bundleVersion == null) return;
    bundleVersion = _bundleVersion;
    log("Bundle version: $bundleVersion", name: "schulmanager");
    // Attempt to init with stored jwt
    final checkAuthJwt = await getSchulmanagerJWT();
    var needsOauthLogin = true;
    if (checkAuthJwt != null) {
      if (await setStudentDateFromJWT(checkAuthJwt)) {
        authJwt = checkAuthJwt;
        active = true;
        needsOauthLogin = false;
      }
    }
    // Otherwise login with oauth
    if (needsOauthLogin) active = await loginOauth();

    if (active) {
      values["substitutions"] = WeekSubstitutions(null, name);
      await setSchulmanagerClassName();
    }
  }

  @override
  Future<void> update() async {
    if (!active) return;
    if (sharedState.profileManager.schoolClassFullName != sharedState.schulmanagerClassName) return; // It does not make sense to show substitutions from the wrong class
    final weekSubstitutions = values["substitutions"]! as WeekSubstitutions;
    final weekStartEndDates = getCurrentWeekStartEndDates();
    final weekStartDate = weekStartEndDates.item1;
    final weekEndDate = weekStartEndDates.item2;
    final lessons = (await sendSchulmanagerApiRequest([{
      "endpointName" : "get-actual-lessons",
      "moduleName" : "schedules",
      "parameters" : {
        "start" : "${weekStartDate.year}-${weekStartDate.month.toString().padLeft(2, "0")}-${weekStartDate.day.toString().padLeft(2, "0")}",
        "end" : "${weekEndDate.year}-${weekEndDate.month.toString().padLeft(2, "0")}-${weekEndDate.day.toString().padLeft(2, "0")}",
        "student" : studentData
      }
    }]))![0];
    if (Constants.defineHasTesterFeature) lastResponse = lessons;
    // Parse json into day substitutions list
    final substitutions = <DateTime, List<Map<String, dynamic>>>{};
    for (final l in lessons as List<dynamic>) {
      final lesson = l as Map<String, dynamic>;
      final date = DateTime.parse(lesson["date"]! as String);
      final weekDay = date.weekday;
      final classHour = int.parse((lesson["classHour"]! as Map<String, dynamic>)["number"]! as String);
      final actualLesson = lesson["actualLesson"] as Map<String, dynamic>?;
      final currentCell = sharedState.content.getCell(classHour-1, weekDay);
      // Handle dropout
      if (actualLesson == null && lesson.containsKey("originalLessons")) {
        final originalLessons = lesson["originalLessons"] as List<dynamic>;
        if (originalLessons.length > 1) continue; // TODO: Don't do this
        final originalLesson = originalLessons[0] as Map<String, dynamic>;
        final originalLessonSubject = originalLesson["subjectLabel"]! as String;
        final originalLessonTeacher = ((originalLesson["teachers"] as List<dynamic>?)?[0] as Map<String, dynamic>?)?["abbreviation"] as String?;
        final originalLessonRoom = (originalLesson["room"] as Map<String, dynamic>?)?["name"] as String?;
        if (!sharedState.allCurrentSubjects.contains(originalLessonSubject)) continue;
        final comment = lesson["comment"] as String?;
        final substitutionData = <String, dynamic>{
          "Stunde" : classHour.toString(),
          "Fach" : "---",
          "Vertretung" : "---",
          "Raum" : "---",
          "statt Fach" : originalLessonSubject,
          "statt Lehrer" : originalLessonTeacher ?? currentCell.teacher,
          "statt Raum" : originalLessonRoom ?? currentCell.room,
          "Text" : comment ?? "\u{00A0}",
          "Entfall" : "x"
        };
        final daySubstitutions = substitutions.putIfAbsent(date, () => []);
        daySubstitutions.add(substitutionData);
        continue;
      } else if (actualLesson == null) {
        // TODO: Maybe handle this case (this case is rarely present)
        continue;
      }
      final subject = actualLesson["subjectLabel"]! as String;
      if (!sharedState.allCurrentSubjects.contains(subject)) continue;
      if (!actualLesson.containsKey("room") || actualLesson["room"] == null) continue;
      final room = (actualLesson["room"] as Map<String, dynamic>)["name"]! as String;
      final teachers = actualLesson["teachers"]! as List<dynamic>;
      final teacher = (teachers[0] as Map<String, dynamic>)["abbreviation"] as String;
      final text = actualLesson["comment"] as String?;

      // Skip if nothing changed (aka not a substitution just redundant information)
      if (currentCell.subject == subject && currentCell.teacher == teacher && currentCell.room == room && text == null) continue;
      final substitutionData = <String, dynamic>{
        "Stunde" : classHour.toString(),
        "Fach" : subject,
        "Vertretung" : teacher,
        "Raum" : room,
        "statt Fach" : currentCell.subject,
        "statt Lehrer" : currentCell.teacher,
        "statt Raum" : currentCell.room,
        "Text" : text ?? "\u{00A0}",
        "Entfall" : ""
      };
      final daySubstitutions = substitutions.putIfAbsent(date, () => []);
      daySubstitutions.add(substitutionData);
    }
    // Set weekSubstitutions
    for (final entry in substitutions.entries) {
      final daySubstitutions = entry.value;
      daySubstitutions.sort((a, b) => (int.parse(a["Stunde"]! as String)).compareTo(int.parse(b["Stunde"]! as String)));
      weekSubstitutions.setDay(daySubstitutions, entry.key, name);
    }
  }

  @override
  void loadValuesFromJson(Map<String, dynamic> jsonValues) {
    for (final jsonValueEntry in jsonValues.entries) {
      if (jsonValueEntry.key == "substitutions") {
        values[jsonValueEntry.key] = WeekSubstitutions(jsonValueEntry.value, name, checkWeekDay: loadCheckWeekDay);
      }
    }
  }

  @override
  Map<String, dynamic> saveValuesToJson() {
    final json = super.saveValuesToJson();
    if (Constants.defineHasTesterFeature) json["lastResponse"] = lastResponse;
    return json;
  }

  Future<String?> getBundleVersion() async {
    // Get bundle version in order to be able to make api requests
    final Response response = await client.get(Uri.parse("${Constants.schulmanagerBaseUrl}/#/login"));
    if (response.statusCode != 200) return null;
    final result = parse(response.body);
    final scripts = result.getElementsByTagName("script");
    String? bundleVersion;
    for (final script in scripts) {
      if (script.attributes["src"]?.contains("static/runtime.") ?? false) {
        final srcRelative = script.attributes["src"]!;
        final src = "${Constants.schulmanagerBaseUrl}/$srcRelative";
        final responseJavscript = await client.get(Uri.parse(src));
        if (responseJavscript.statusCode != 200) return null;
        // Get javscript code and use regex to extract bundle version:
        final regExp = RegExp(r'r\.h=\(\)=>"([A-Za-z0-9]+?)"');
        final match = regExp.firstMatch(responseJavscript.body);
        bundleVersion = match?.group(1);
        break;
      }
    }
    return bundleVersion;
  }

  Future<void> setSchulmanagerClassName() async {
    if (sharedState.schulmanagerClassName == null) {
      // Get the term id (which is for some reason required to get the list of all classes)
      final termResponse = await sendSchulmanagerApiRequest([{
        "endpointName" : "get-current-term",
        "moduleName" : null
      }]);
      if (termResponse == null) {log("Could not get term id", name: "schulmanager-integration"); return;}
      final termId = (termResponse[0] as Map<String, dynamic>)["id"] as int;
      // Get a list of all classes, to map a classId to an actual name
      final classesResponse = await sendSchulmanagerApiRequest([{
        "endpointName" : "poqa",
        "moduleName" : "schedules",
        "parameters" : {
          "action" : {
            "action" : "findAll",
            "model" : "main/class",
            "parameters" : [{
              "attributes" : ["id", "name", "gradeLevels"],
              "where" : {
                "termId" : termId
              }
            }]
          }
        }
      }]);
      // Check for any errors
      if (classesResponse == null) {log("Could not class ids with term id", name: "schulmanager-integration"); return;}
      final classesData = classesResponse[0] as List<dynamic>;
      final schulmanagerClassData = classesData.firstWhereOrNull((classData) => (classData as Map<String, dynamic>)["id"] == studentData["classId"]);
      if (schulmanagerClassData == null) {log("Could not find the class name, that is associated with the students class id", name: "schulmanager-integration"); return;}
      // Save the class name
      sharedState.schulmanagerClassName = (schulmanagerClassData as Map<String, dynamic>)["name"] as String;
      await sharedState.saveSchulmanagerClassName();
    }
  }

  void setStudentDataFromUserInfo(Map<String, dynamic> userInfo) {
    Map<String, dynamic> studentUser;
    if (userInfo["associatedStudent"] != null) {
      studentUser = userInfo["associatedStudent"] as Map<String, dynamic>;
    } else {
      final parents = userInfo["associatedParents"] as List<dynamic>;
      final parent = parents.first as Map<String, dynamic>;
      studentUser = parent["student"] as Map<String, dynamic>;
    }
    studentData = {
      "classId": studentUser["classId"],
      "firstname": studentUser["firstname"],
      "lastname": studentUser["lastname"],
      "id": studentUser["id"],
      "sex": studentUser["sex"]
    };
  }

  Future<bool> setStudentDateFromJWT(String jwt) async {
    final userInfoResponse = await client.post(Uri.parse("${Constants.schulmanagerApiBaseUrl}/login-status"), headers: {
      "Authorization" : "Bearer $jwt"
    });
    if (userInfoResponse.statusCode != 200) {
      log("Oauth failed on getting user info: ${userInfoResponse.statusCode} ${userInfoResponse.body}", name: "schulmanager-integration");
      return false;
    }
    final userInfo = (jsonDecode(userInfoResponse.body) as Map<String, dynamic>)["user"] as Map<String, dynamic>;
    setStudentDataFromUserInfo(userInfo);
    return true;
  }

  // Not currently used but could be used, by parents who don't have an IServ account
  Future<bool> loginSchulmanager(String email, String password) async {
    // Send login request to get jwt token
    final loginRequestBody = {"emailOrUsername": email, "password": password, "hash":null, "mobileApp": false, "institutionId":null};
    final response = await client.post(
      Uri.parse("${Constants.schulmanagerApiBaseUrl}/login"),
      body: jsonEncode(loginRequestBody),
      headers: {"Content-Type": "application/json;charset=utf-8"},
    );
    if (response.statusCode != 200) return false;
    final responseJson = jsonDecode(response.body);
    final jwt = responseJson["jwt"]! as String;
    final userInfo = responseJson["user"]! as Map<String, dynamic>;
    setStudentDataFromUserInfo(userInfo);
    await setSchulmanagerJWT(jwt);
    authJwt = jwt;
    return true;
  }

  Future<bool> loginOauth() async {
    // Make initial oidc request to schulmanager
    final oidcRequest = Request("Get", Uri.parse("${Constants.schulmanagerOicdBaseUrl}/${Constants.schulmanagerSchoolId}"))..followRedirects = false;
    final oidcResponse = await client.send(oidcRequest);
    if (oidcResponse.statusCode != 302) {
      log("Initializing Oauth failed: ${oidcResponse.statusCode}", name: "schulmanager-integration");
      return false;
    }
    final oidcCookieString = getCookieStringFromSetCookieHeader(oidcResponse.headers["set-cookie"]!, ["session", "session.sig"]);
    final iservRedirectUri = Uri.parse(oidcResponse.headers['location']!);
    // Login to iserv and grab the cookies
    final iServCookies = await iServLogin();
    if (iServCookies == null) return false;
    // Authorize schulmangager with iserv cookies
    final iservAuthRequest = Request("Get", iservRedirectUri)..followRedirects = false;
    for (final h in getAuthHeaderFromCookies(iServCookies).entries) {
      iservAuthRequest.headers[h.key] = h.value;
    }
    final iservAuthResponse = await client.send(iservAuthRequest);
    if (iservAuthResponse.statusCode != 302) {
      log("Oauth failed on iserv login: ${iservAuthResponse.statusCode}", name: "schulmanager-integration");
      return false;
    }
    // Make callback request to get schulmanager session cookies
    final callbackRedirectUri = Uri.parse(iservAuthResponse.headers['location']!);
    final callbackRequest = Request("Get", callbackRedirectUri)..followRedirects = false;
    callbackRequest.headers["Cookie"] = oidcCookieString;
    final callbackResponse = await client.send(callbackRequest);
    if (callbackResponse.statusCode != 302) {
      log("Oauth failed on schulmanager callback: ${callbackResponse.statusCode}", name: "schulmanager-integration");
      return false;
    }
    final callBackSessionCookieString = getCookieStringFromSetCookieHeader(callbackResponse.headers["set-cookie"]!, ["session", "session.sig"]);
    // Get jwt
    final jwtResponse = await client.get(Uri.parse("${Constants.schulmanagerOicdBaseUrl}/get-jwt"), headers: {"Cookie" : callBackSessionCookieString});
    if (jwtResponse.statusCode != 204) {
      log("Oauth failed on getting jwt: ${jwtResponse.statusCode} ${jwtResponse.body}", name: "schulmanager-integration");
      return false;
    }
    final jwt = jwtResponse.headers["x-new-bearer-token"]!;
    // Attempt to get user info
    if (!await setStudentDateFromJWT(jwt)) return false;
    // Store jwt, if successful
    authJwt = jwt;
    await setSchulmanagerJWT(jwt);
    log("Oauth was successful", name: "schulmanager-integration");
    return true;
  }

  Future<List<dynamic>?> sendSchulmanagerApiRequest(List<Map<String, dynamic>> requests) async {
    final response = await client.post(Uri.parse("${Constants.schulmanagerApiBaseUrl}/calls"),
      body: jsonEncode({"bundleVersion" : bundleVersion, "requests" : requests}),
      headers: {"Content-Type": "application/json;charset=utf-8", "Authorization": "Bearer $authJwt"},
    );
    if (response.statusCode != 200) {
      log("Api call error: ${response.statusCode} ${response.body}", name: "schulmanager-integration");
      return null;
    }
    // Update jwt to extend session lifetime
    if (response.headers.containsKey("x-new-bearer-token")) {
      authJwt = response.headers["x-new-bearer-token"]!;
    }
    final responseResults = jsonDecode(response.body)["results"]! as List<dynamic>;
    final returnData = <dynamic>[];
    for (final result in responseResults) {
      if (result["status"] != 200) return null;
      returnData.add(result["data"]!);
    }
    return returnData;
  }

}
