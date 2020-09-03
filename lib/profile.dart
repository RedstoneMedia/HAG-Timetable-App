
class Profile {
  String schoolGrade = "11";
  String subSchoolClass = "e";
  List<String> subjects = [];

  Map getJsonData() {
    Map jsonData = {
      "schoolGrade" : schoolGrade,
      "subSchoolClass" : subSchoolClass,
      "subjects" : subjects
    };
    return jsonData;
  }

  String toString() {
    return "$schoolGrade$subSchoolClass";
  }

  static Profile fromJsonData(dynamic jsonData) {
    Profile newProfile = new Profile();
    newProfile.schoolGrade = jsonData["schoolGrade"];
    newProfile.subSchoolClass = jsonData["subSchoolClass"];
    for (String subject in jsonData["subjects"]) {
      newProfile.subjects.add(subject);
    }
    return newProfile;
  }
}