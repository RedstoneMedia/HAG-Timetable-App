import 'package:shared_preferences/shared_preferences.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/theme.dart';

class SharedState {
  SharedPreferences preferences;

  Theme theme = darkTheme;
  String schoolGrade = "11";
  String subSchoolClass = "e";
  int height = Constants.defaultHeight;
  List<String> subjects = [];

  SharedState(this.preferences);

  void saveState() {
    preferences.setString("theme", theme.themeName);
    preferences.setString("schoolGrade", schoolGrade);
    preferences.setString("subSchoolClass", subSchoolClass);
    preferences.setInt("height", height);
    preferences.setStringList("subjects", subjects);
  }

  bool loadStateAndCheckIfFirstTime() {
    setThemeFromThemeName(preferences.getString("theme") ?? "dark");
    subSchoolClass = preferences.getString("subSchoolClass") ?? "e";
    subjects = preferences.getStringList("subjects") ?? [];
    height = preferences.getInt("height") ?? Constants.defaultHeight;

    // If first time using app
    schoolGrade = preferences.getString("schoolGrade");
    if (schoolGrade == null) {
      schoolGrade = "11";
      return true;
    }
    return false;
  }

  void setThemeFromThemeName(String themeName) {
    this.theme = Theme.getThemeFromThemeName(themeName);
  }

  List<String> get defaultSubjects {
    for (var schoolGradeList in Constants.defaultSubjectsMap.keys) {
      if (schoolGradeList.contains(schoolGrade)) {
        var defaultSubjects = new List<String>.from(Constants.defaultSubjectsMap[schoolGradeList]);
        defaultSubjects.addAll(Constants.alwaysDefaultSubjects);
        return defaultSubjects;
      }
    }
    return Constants.alwaysDefaultSubjects;
  }
}

