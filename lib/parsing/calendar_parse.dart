import 'dart:developer';
import 'package:http/http.dart'; // Contains a client for making API calls
import 'package:icalendar_parser/icalendar_parser.dart';

import '../calendar_data.dart';
import '../shared_state.dart';

Future<CalendarData> loadCalendarData(SharedState sharedState) async {
  log("Parsing calendar data", name: "parsing.calendar");
  final calendarData = CalendarData();
  final client = Client();
  for (final calenderUrlEntry in sharedState.profileManager.calendarUrls.entries) {
    if (calenderUrlEntry.value.endsWith(".ics")) {
      final calenderType = CalendarTypeExtension.fromString(calenderUrlEntry.key)!;
      await getPluginCalendarData(calenderUrlEntry.value, calenderType, client, calendarData);
    }
  }
  log(calendarData.toString(), name: "parsing.calendar");
  return calendarData;
}

Future<CalendarData> getPluginCalendarData(String url, CalendarType type, Client client, CalendarData calendarData) async {
  final response = await client.get(Uri.parse(url));
  if (response.statusCode != 200) {
    log("Cannot get plugin calendar data", name: "parsing.calendar");
    return calendarData;
  }
  return parseToCalendarData(response.body, type, calendarData);
}

DateTime parseTimeString(String string) {
  final splitString = string.split(":")[1].split("T");
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

CalendarData parseToCalendarData(String iCalendarString, CalendarType type, CalendarData calendarData) {
  final parsedData = ICalendar.fromString(iCalendarString).data;
  for (final data in parsedData!) {
    if (data["type"] == "VEVENT") {
      final dateStart = data["dtstart"];
      final dateEnd = data["dtend"];
      DateTime dateStartDateTime;
      DateTime dateEndDateTime;

      if (dateStart is DateTime) {
        dateStartDateTime = dateStart;
      } else {
        dateStartDateTime = parseTimeString(dateStart as String);
      }
      if (dateEnd is DateTime) {
        dateEndDateTime = dateEnd;
      } else {
        dateEndDateTime = parseTimeString(dateEnd as String);
      }

      final summary = data["summary"] as String;
      calendarData.addCalendarDataPoint(CalendarDataPoint(type, summary, dateStartDateTime, dateEndDateTime));
    }
  }
  return calendarData;
}