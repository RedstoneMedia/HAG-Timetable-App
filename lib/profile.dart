class Profile {
  String? schoolGrade;
  String subSchoolClass = "";
  List<String> subjects = [];
  Map<String, String> calendarUrls = {};

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
