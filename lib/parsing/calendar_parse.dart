import 'dart:convert';
import 'dart:developer';
import 'package:html/parser.dart'; // Contains HTML parsers to generate a Document object
import 'package:http/http.dart'; // Contains a client for making API calls
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:rrule/rrule.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/helper_functions.dart';
import 'package:stundenplan/parsing/parsing_util.dart';

import '../calendar_data.dart';
import '../shared_state.dart';
import 'iserv_authentication.dart';

Future<CalendarData> loadCalendarData(SharedState sharedState) async {
  log("Parsing calendar data", name: "parsing.calendar");
  final calendarData = CalendarData();
  final client = Client();
  for (final calenderUrlEntry in sharedState.profileManager.calendarUrls.entries) {
    final calenderType = CalendarTypeExtension.fromString(calenderUrlEntry.key)!;
    await getPluginCalendarData(calenderUrlEntry.value, calenderType, client, calendarData);
  }
  await getCaldavCalendarData("${Constants.calDavBaseUrl}/+public/calendar", CalendarType.public, client, calendarData);
  await getCaldavCalendarData("${Constants.calDavBaseUrl}/klasse.${sharedState.profileManager.schoolClassFullName.toLowerCase()}/calendar", CalendarType.public, client, calendarData);
  {
    final iServCredentials = await getIServCredentials();
    if (iServCredentials != null) {
      await getCaldavCalendarData("${Constants.calDavBaseUrl}/schuelerinnen/calendar", CalendarType.students, client, calendarData);
      //                                                              ^^^^^
      //                                                              why ?
      await getCaldavCalendarData("${Constants.calDavBaseUrl}/${iServCredentials.item1}/home", CalendarType.personal, client, calendarData);
    }
  }
  log(calendarData.toString(), name: "parsing.calendar");
  return calendarData;
}

Future<Map<String, String>?> enableAllCalendarPluginUrls() async {
  final client = Client();
  // Login
  final cookies = await iServLogin();
  if (cookies == null) return null;
  // Get plugin list to get feed ids
  final response = await client.get(Uri.parse("${Constants.calendarIServBaseUrl}/plugin"), headers: getAuthHeaderFromCookies(cookies));
  if (response.statusCode != 200) return null;
  final document = parse(response.body);
  final pluginTableElement = document.getElementById("crud-table")!;
  final pluginRows = pluginTableElement.children[1].children;
  // Loop over every row in the plugin table and extract the Plugin name and the feedId
  final Map<String, String> calendarPluginUrls = {};
  for (final pluginRow in pluginRows) {
    final pluginEditATag = pluginRow.firstChild!.firstChild!;
    final pluginName = customStrip(pluginEditATag.text!);
    final feedId = pluginEditATag.attributes["href"]!.split("/").last;
    log("Enabling $pluginName feed url");
    // Enable plugin calendarPluginUrl
    final calendarPluginUrl = await enableCalendarPluginUrl(client, cookies, feedId);
    if (calendarPluginUrl == null) continue;
    // Get correct calendar type string from plugin name
    final calendarTypeString = pluginCalendarTypes.where((calendarType) => pluginName.toLowerCase().contains(calendarType.name().toLowerCase())).first.name();
    calendarPluginUrls[calendarTypeString] = calendarPluginUrl;
  }
  return calendarPluginUrls;
}

Future<String?> enableCalendarPluginUrl(Client client, String cookies, String feedId) async {
  // Get plugin feed edit page
  var response = await client.get(Uri.parse("${Constants.calendarIServBaseUrl}/plugin/edit/$feedId"), headers: getAuthHeaderFromCookies(cookies));
  if (response.statusCode != 200) return null;
  // Grab data-csrf-token
  final document = parse(response.body);
  final element = document.getElementById("plugin-urls");
  final dataCsrfToken = element!.attributes["data-csrf-token"];
  // Generate token
  response = await client.post(Uri.parse("${Constants.calendarIServBaseUrl}/ics/feed/$feedId/generate/plugin?type=plugin&_token=$dataCsrfToken"), headers: getAuthHeaderFromCookies(cookies));
  if (response.statusCode != 200) {
    log("Cannot generate plugin toke. Error code ${response.statusCode}", name: "parsing.calendar");
  }
  final responseJsonBody = jsonDecode(response.body);
  return "${Constants.publicIServUrl}/calendar/ics/feed/plugin/${responseJsonBody["token"]}/calendar.ics";
}

Future<CalendarData> getPluginCalendarData(String url, CalendarType type, Client client, CalendarData calendarData) async {
  final response = await client.get(Uri.parse(url));
  if (response.statusCode != 200) {
    log("Cannot get plugin calendar data with url $url. Error code ${response.statusCode}", name: "parsing.calendar");
    return calendarData;
  }
  return parseToCalendarData(response.body, type, calendarData);
}

Future<CalendarData> getCaldavCalendarData(String url, CalendarType type, Client client, CalendarData calendarData) async {
  final iservCredentials = await getIServCredentials();
  if (iservCredentials == null) return calendarData;
  final basicAuthString = "Basic ${base64Encode(utf8.encode("${iservCredentials.item1}:${iservCredentials.item2}"))}";
  final response = await client.get(Uri.parse(url), headers: {"authorization" : basicAuthString});
  if (response.statusCode != 200) {
    log("Cannot get caldav calendar data with url $url. Error code ${response.statusCode}", name: "parsing.calendar");
    return calendarData;
  }
  return parseToCalendarData(response.body, type, calendarData);
}


DateTime parseTimeString(String string) {
  final splitString = string.split("T");
  final datePart = splitString[0];
  final timePart = splitString[1];
  final year = int.parse(datePart.substring(0, 4));
  final month = int.parse(datePart.substring(4, 6));
  final day = int.parse(datePart.substring(6, 8));

  final hour = int.parse(timePart.substring(0, 2));
  final minute = int.parse(timePart.substring(2, 4));
  final second = int.parse(timePart.substring(4, 6));
  return DateTime(year, month, day, hour, minute, second);
}


void executeIcsRecurrenceRule(String rRuleString, CalendarDataPoint origDataPoint, CalendarData calendarData) {
  final rRule = RecurrenceRule.fromString("RRULE:$rRuleString");
  // Add repeating calendar entries based on rRule
  final now = DateTime.now();
  final weekStartDate = now.subtract(Duration(days: now.weekday));
  if (weekStartDate.difference(origDataPoint.startDate).inDays.isNegative) return; // Recurrent rule hasn't started yet.
  final instances = rRule.getInstances(start: weekStartDate.toUtc());
  for (final instance in instances.take(5)) {
    final newStartDate = DateTime(instance.year, instance.month, instance.day, origDataPoint.startDate.hour, origDataPoint.startDate.minute, origDataPoint.startDate.second);
    final newEndDate = DateTime(instance.year, instance.month, instance.day, origDataPoint.endDate.hour, origDataPoint.endDate.minute, origDataPoint.endDate.second);
    calendarData.addCalendarDataPoint(CalendarDataPoint(origDataPoint.calendarType, origDataPoint.name, newStartDate, newEndDate));
  }
}

CalendarData parseToCalendarData(String iCalendarString, CalendarType type, CalendarData calendarData) {
  final parsedData = ICalendar.fromString(iCalendarString).data;
  for (final data in parsedData.reversed) {
    if (data["type"] == "VEVENT") {
      final IcsDateTime dateStart = data["dtstart"] as IcsDateTime;
      final IcsDateTime dateEnd = data["dtend"] as IcsDateTime;
      final String? rRule = data["rrule"] as String?;
      // Parse entry's date start time
      DateTime dateStartDateTime;
      if (dateStart.toDateTime() != null) {
        dateStartDateTime = dateStart.toDateTime()!;
      } else {
        dateStartDateTime = parseTimeString(dateStart.dt.split(":")[1]);
      }
      // Parse entry's date end time
      DateTime dateEndDateTime;
      if (dateEnd.toDateTime() != null) {
        dateEndDateTime = dateEnd.toDateTime()!;
      } else {
        dateEndDateTime = parseTimeString(dateEnd.dt.split(":")[1]);
      }

      final summary = data["summary"] as String;
      final dataPoint = CalendarDataPoint(type, summary, dateStartDateTime, dateEndDateTime);
      if (rRule != null) {
        executeIcsRecurrenceRule(rRule, dataPoint, calendarData);
      } else {
        calendarData.addCalendarDataPoint(dataPoint);
      }
    }
  }
  return calendarData;
}
