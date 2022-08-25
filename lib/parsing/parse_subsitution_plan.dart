import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

import 'package:html/parser.dart'; // Contains HTML parsers to generate a Document object
import 'package:http/http.dart';  // Contains a client for making API calls
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/content.dart';
import 'package:stundenplan/helper_functions.dart';
import 'package:stundenplan/integration.dart';
import 'package:stundenplan/parsing/parsing_util.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:stundenplan/week_subsitutions.dart';
import 'package:tuple/tuple.dart';

import 'iserv_authentication.dart';


Future<void> overwriteContentWithSubsitutionPlan(
    SharedState sharedState,
    Client client,
    Content content,
    List<String> subjects,
    String schoolClassName) async
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
    cell.teacher = customStrip(substitution["Vertretung"] as String);
    cell.originalTeacher = customStrip(substitution["statt Lehrer"] as String);
    cell.room = customStrip(substitution["Raum"] as String);
    cell.originalRoom = customStrip(substitution["statt Raum"] as String);
    cell.text = substitution["Text"] as String;
    cell.source = plan[i].item2;
    cell.isDropped = customStrip(substitution["Entfall"] as String) == "x";

    // Sometimes a substitution is set, but there is no data set which means that it is dropped.
    if (cell.originalSubject == "\u{00A0}" && cell.subject == "\u{00A0}" && cell.room == "\u{00A0}" && cell.teacher == "\u{00A0}") {
      cell.isDropped = true;
    } else if (!cell.isDropped) {
      cell.isSubstitute = true;
    }

    // Replace non breaking space with three dashes
    // We need to do this because, otherwise the cell will not have any visible text and will just display a solid color.
    if (cell.subject == "\u{00A0}") cell.subject = "---";
    if (cell.teacher == "\u{00A0}") cell.teacher = "---";
    if (cell.room == "\u{00A0}") cell.room = "---";

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
  final Client client = Client();
  final SharedState sharedState;
  bool loadCheckWeekDay = true;

  IServUnitsSubstitutionIntegration(this.sharedState) : super(name: "IServ", save: true, precedence: 0, providedValues: ["substitutions"]);

  @override
  Future<void> init() async {
    values["substitutions"] = WeekSubstitutions(null, name);
  }

  @override
  Future<void> update() async {
    final weekSubstitutions = values["substitutions"]! as WeekSubstitutions;
    final schoolClassName = "${sharedState.profileManager.schoolGrade}${sharedState.profileManager.subSchoolClass}";
    // Get main substitutions
    final ret = await getCourseSubstitutionPlan(schoolClassName);
    final mainPlan = ret["substitutions"] as List<Map<String, String>>;
    final mainSubstituteDate = ret["substituteDate"] as DateTime;
    weekSubstitutions.setDay(mainPlan, mainSubstituteDate, name);

    //  Get course substitutions
    if (!Constants.displayFullHeightSchoolGrades.contains(sharedState.profileManager.schoolGrade)) {
      final courseRet = await getCourseSubstitutionPlan(
          "${sharedState.profileManager.schoolGrade}K",
      );
      final coursePlan = courseRet["substitutions"] as List<Map<String, String>>;
      final courseSubstituteDate = ret["substituteDate"] as DateTime;
      weekSubstitutions.setDay(coursePlan, courseSubstituteDate, name);
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

  Future<Map<String, dynamic>> getCourseSubstitutionPlan(String course) async {
    final response = await client.get(Uri.parse('${Constants.substitutionLinkBase}_$course.htm'));
    if (response.statusCode != 200) {
      return {
        "substitutions" : <Map<String, String>>[],
        "substituteDate" : DateTime.now(),
        "substituteWeekday" : 1
      };
    }

    final document = parse(response.body);
    if (document.outerHtml.contains("Fatal error")) {
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
    final regexp = RegExp(r"^\w+\/(?<day>\d+).(?<month>\d+).");
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
    final headerInformation = [
      "Stunde",
      "Fach",
      "Vertretung",
      "Raum",
      "statt Fach",
      "statt Lehrer",
      "statt Raum",
      "Text",
      "Entfall"
    ];
    rows.removeAt(0);
    final substitutions = <Map<String, String>>[];

    for (final row in rows) {
      final substitution = <String, String>{};
      final columns = row.getElementsByTagName("td");
      for (var i = 0; i < columns.length; i++) {
        substitution[headerInformation[i]] =
            columns[i].text.replaceAll("\n", " ");
      }
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

  SchulmanagerIntegration.Schulmanager(this.sharedState) : super(name: "Schulmanager", save: true, precedence: 1, providedValues: ["substitutions"]);

  @override
  Future<void> init() async {
    final _bundleVersion = await getBundleVersion();
    if (_bundleVersion == null) return;
    bundleVersion = _bundleVersion;
    active = await loginOauth();
    if (active) values["substitutions"] = WeekSubstitutions(null, name);
  }

  @override
  Future<void> update() async {
    if (!active) return;
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
        if (!sharedState.allCurrentSubjects.contains(originalLessonSubject)) continue;
        final comment = lesson["comment"] as String?;
        final substitutionData = <String, dynamic>{
          "Stunde" : classHour.toString(),
          "Fach" : "---",
          "Vertretung" : "---",
          "Raum" : "---",
          "statt Fach" : currentCell.subject,
          "statt Lehrer" : currentCell.teacher,
          "statt Raum" : currentCell.room,
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
      if (!sharedState.profileManager.subjects.contains(subject)) continue;
      if (actualLesson.containsKey("room")) continue;
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

  Future<String?> getBundleVersion() async {
    // Get bundle version in order to be able to make api requests
    Response response = await client.get(Uri.parse("https://login.schulmanager-online.de/#/login"));
    if (response.statusCode != 200) return null;
    final result = parse(response.body);
    final scripts = result.getElementsByTagName("script");
    String? bundleVersion;
    for (final script in scripts) {
      if (script.attributes["src"]?.contains("bundle") ?? false) {
        final srcSplit = script.attributes["src"]!.split(".");
        bundleVersion = srcSplit[srcSplit.length-2];
        break;
      }
    }
    return bundleVersion;
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
    // Get user info
    final userInfoResponse = await client.post(Uri.parse("${Constants.schulmanagerApiBaseUrl}/login-status"), headers: {
      "Authorization" : "Bearer $jwt"
    });
    if (userInfoResponse.statusCode != 200) {
      log("Oauth failed on getting user info: ${jwtResponse.statusCode} ${jwtResponse.body}", name: "schulmanager-integration");
      return false;
    }
    final userInfo = (jsonDecode(userInfoResponse.body) as Map<String, dynamic>)["user"] as Map<String, dynamic>;
    authJwt = jwt;
    setStudentDataFromUserInfo(userInfo);
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
