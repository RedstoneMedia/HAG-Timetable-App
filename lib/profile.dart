class Profile {
  String schoolGrade = "11";
  String subSchoolClass = "e";
  List<String> subjects = [];

  Map getJsonData() {
    final jsonData = {
      "schoolGrade": schoolGrade,
      "subSchoolClass": subSchoolClass,
      "subjects": subjects
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
    return newProfile;
  }
}
