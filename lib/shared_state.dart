import 'package:shared_preferences/shared_preferences.dart';
import 'package:stundenplan/theme.dart';

class SharedState {
  SharedPreferences preferences;

  Theme theme = darkTheme;
  int schoolGrade = 11;
  String subSchoolClass = "e";
  List<String> subjects = [];

  SharedState(this.preferences);

  void saveState() {
    preferences.setString("theme", theme.themeName);
    preferences.setInt("schoolGrade", schoolGrade);
    preferences.setString("subSchoolClass", subSchoolClass);
    preferences.setStringList("subjects", subjects);
  }

  bool loadStateAndCheckIfFirstTime() {
    setThemeFromThemeName(preferences.getString("theme") ?? "dark");
    subSchoolClass = preferences.getString("subSchoolClass") ?? "e";
    subjects = preferences.getStringList("subjects") ?? [];

    // If first time using app
    schoolGrade = preferences.getInt("schoolGrade");
    if (schoolGrade == null) {
      schoolGrade = 11;
      return true;
    }
    return false;
  }

  void setThemeFromThemeName(String themeName) {
    this.theme = Theme.getThemeFromThemeName(themeName);
  }
}

