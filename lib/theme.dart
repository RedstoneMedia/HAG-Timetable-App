import 'package:flutter/material.dart';

final darkTheme = Theme(
    "dark", // Theme name
    Color.fromRGBO(25, 25, 25, 1.0), // Background color
    Colors.white.withAlpha(200), // Text color
    Color.fromRGBO(38 - 20, 222 - 20, 129 - 20, 1.0),  // Subject color
    Color.fromRGBO(209 - 160, 216 - 160, 224 - 160, 1.0),  // Subject drop out color
    Color.fromRGBO(252 - 30, 92 - 30, 101 - 30, 1.0),  // Subject substitution color
);

final lightTheme = Theme(
    "light", // Theme name
    Color.fromRGBO(240, 240, 240, 1.0), // Background color
    Colors.black, // Text color
    Color.fromRGBO(38, 222, 129, 1.0),  // Subject color
    Color.fromRGBO(209, 216, 224, 1.0),  // Subject drop out color
    Color.fromRGBO(252, 92, 101, 1.0),  // Subject substitution color
);


final neonTheme = Theme(
    "nein danke", // Theme name
    Color.fromRGBO(0, 255, 255, 1), // Background color
    Color.fromRGBO(255, 255, 0, 1), // Text color
    Color.fromRGBO(255, 0, 255, 1),  // Subject color
    Color.fromRGBO(0, 0, 255, 1),  // Subject drop out color
    Color.fromRGBO(255, 0, 0, 1),  // Subject substitution color
);

final themes = [darkTheme, lightTheme, neonTheme];

class Theme {
  final String themeName;
  final Color backgroundColor;
  final Color textColor;
  final Color subjectColor;
  final Color subjectDropOutColor;
  final Color subjectSubstitutionColor;
  //final Color invertedTextColor;

  Theme(this.themeName, this.backgroundColor, this.textColor, this.subjectColor, this.subjectDropOutColor, this.subjectSubstitutionColor);

  Color get invertedTextColor {
    return Color.fromRGBO(255 - textColor.red, 255 - textColor.green, 255 - textColor.blue, textColor.opacity);
  }

  static Theme getThemeFromThemeName(String themeName) {
    for (var theme in themes) {
      if (theme.themeName == themeName) {
       return theme;
      }
    }
    return darkTheme;
  }

  static List<String> getThemeNames() {
    List<String> themeNames = [];
    for (var theme in themes) {
      themeNames.add(theme.themeName);
    }
    return themeNames;
  }
}

