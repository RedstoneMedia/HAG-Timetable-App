class Profile {
  String schoolGrade = "11";
  String subSchoolClass = "e";
  List<String> subjects = [];
  // TODO : Add way to input these urls in the settings (Maybe in a submenu since the setup page is already to long)
  Map<String, String> calendarUrls = {
    "Aufgabe" : "https://hag-iserv.de/iserv/public/calendar/ics/feed/plugin/randomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandom/calendar.ics",
    "Klausur" : "https://hag-iserv.de/iserv/public/calendar/ics/feed/plugin/randomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandom/calendar.ics",
    "Feiertag": "https://hag-iserv.de/iserv/public/calendar/ics/feed/plugin/randomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandomrandom/calendar.ics"
  };

  Map getJsonData() {
    final jsonData = {
      "schoolGrade": schoolGrade,
      "subSchoolClass": subSchoolClass,
      "subjects": subjects,
      "calendarUrls" : calendarUrls
    };
    return jsonData;
  }

  @override
  String toString() {
    return "$schoolGrade$subSchoolClass";
  }

  // ignore: prefer_constructors_over_static_methods
  static Profile fromJsonData(dynamic jsonData) {
    final newProfile = Profile();
    newProfile.schoolGrade = jsonData["schoolGrade"].toString();
    newProfile.subSchoolClass = jsonData["subSchoolClass"].toString();
    for (final subject in jsonData["subjects"]) {
      newProfile.subjects.add(subject.toString());
    }
    if (jsonData["calendarUrls"] != null) {
      newProfile.calendarUrls = {};
      for (final calendarUrlEntry in jsonData["calendarUrls"].entries) {
        newProfile.calendarUrls[calendarUrlEntry.key.toString()] = calendarUrlEntry.value as String;
      }
    }
    return newProfile;
  }
}
