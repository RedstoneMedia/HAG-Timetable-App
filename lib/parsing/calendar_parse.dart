// import 'package:icalendar_parser/icalendar_parser.dart';

Future<void> loadCalendarData() async {
  // TODO: Implement
  /*
  final getObjectsResult = await calDavClient.getObjects("/calendar");

  for (final result in getObjectsResult.multistatus!.response) {
    if (result.propstat.status == 200) {
      final icsData = result.propstat.prop['calendar-data'];
      final parsedData = ICalendar.fromString(icsData.toString()).data;
      for (final data in parsedData!) {
        if (data["type"] == "VEVENT") {
          final dateStart = data["dtstart"] as DateTime;
          final dateEnd = data["dtend"] as DateTime;
          final summary = data["summary"];
          log("$dateStart-$dateEnd : $summary", name: "ics");
        }
      }

    } else {
      log('Bad prop status', name: "cal dav");
    }
  }
  */
}