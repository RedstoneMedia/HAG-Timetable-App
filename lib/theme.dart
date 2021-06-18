import 'package:flutter/material.dart';

final darkTheme = Theme(
  "Dark", // Theme name
  const Color.fromRGBO(25, 25, 25, 1.0), // Background color
  Colors.white.withAlpha(200), // Text color
  const Color.fromRGBO(38 - 20, 222 - 20, 129 - 20, 1.0), // Subject color
  const Color.fromRGBO(
      209 - 160, 216 - 160, 224 - 160, 1.0), // Subject drop out color
  const Color.fromRGBO(
      252 - 30, 92 - 30, 101 - 30, 1.0), // Subject substitution color
);

final arcticTheme = Theme(
  "Arctic", // Theme name
  const Color.fromRGBO(25, 25, 25, 1.0), // Background color
  Colors.white.withAlpha(200), // Text color
  const Color.fromRGBO(18, 195, 201, 1.0), // Subject color
  const Color.fromRGBO(
      209 - 160, 216 - 160, 224 - 160, 1.0), // Subject drop out color
  const Color.fromRGBO(
      252 - 30, 92 - 30, 101 - 30, 1.0), // Subject substitution color
);

final lightTheme = Theme(
  "Light", // Theme name
  const Color.fromRGBO(240, 240, 240, 1.0), // Background color
  Colors.black, // Text color
  const Color.fromRGBO(38, 222, 129, 1.0), // Subject color
  const Color.fromRGBO(209, 216, 224, 1.0), // Subject drop out color
  const Color.fromRGBO(252, 92, 101, 1.0), // Subject substitution color
);

final neonTheme = Theme(
  "Nein danke", // Theme name
  const Color.fromRGBO(0, 255, 255, 1), // Background color
  const Color.fromRGBO(255, 255, 0, 1), // Text color
  const Color.fromRGBO(255, 0, 255, 1), // Subject color
  const Color.fromRGBO(0, 0, 255, 1), // Subject drop out color
  const Color.fromRGBO(255, 0, 0, 1), // Subject substitution color
);


// Theses colors are just the standard colors for the custom theme and can be changed.
final customTheme = Theme(
  "Eigenes", // Theme name
  const Color.fromRGBO(25, 25, 25, 1.0), // Background color
  Colors.white.withAlpha(200), // Text color
  const Color.fromRGBO(38 - 20, 222 - 20, 129 - 20, 1.0), // Subject color
  const Color.fromRGBO(
      209 - 160, 216 - 160, 224 - 160, 1.0), // Subject drop out color
  const Color.fromRGBO(
      252 - 30, 92 - 30, 101 - 30, 1.0), // Subject substitution color
);


final themes = [darkTheme, arcticTheme,lightTheme, customTheme];


Map<String, dynamic> colorToJsonData(Color color) {
  final jsonColorData = <String, dynamic>{
    "r" : color.red,
    "g" : color.green,
    "b" : color.blue,
    "o" : color.opacity
  };
  return jsonColorData;
}


Color colorFromJsonData(dynamic jsonColorData) {
  return Color.fromRGBO(
      int.parse(jsonColorData["r"].toString()),
      int.parse(jsonColorData["g"].toString()),
      int.parse(jsonColorData["b"].toString()),
      double.parse(jsonColorData["o"].toString()));
}


class Theme {
  final String themeName;
  Color backgroundColor;
  Color textColor;
  Color subjectColor;
  Color subjectDropOutColor;
  Color subjectSubstitutionColor;

  Theme(this.themeName, this.backgroundColor, this.textColor, this.subjectColor,
      this.subjectDropOutColor, this.subjectSubstitutionColor);

  Color get invertedTextColor {
    return Theme.invertColor(textColor);
  }

  static Color invertColor(Color color) {
    return Color.fromRGBO(255 - color.red, 255 - color.green,
        255 - color.blue, color.opacity);
  }

  Map<String, dynamic> getJsonData() {
    final jsonThemeData = <String, dynamic>{
      "themeName" : themeName,
      "backgroundColor" : colorToJsonData(backgroundColor),
      "textColor" : colorToJsonData(textColor),
      "subjectColor" : colorToJsonData(subjectColor),
      "subjectDropOutColor" : colorToJsonData(subjectDropOutColor),
      "subjectSubstitutionColor" : colorToJsonData(subjectSubstitutionColor)
    };
    return jsonThemeData;
  }

  // ignore: prefer_constructors_over_static_methods
  static Theme fromJsonData(dynamic jsonThemeData) {
    final theme = Theme(
      jsonThemeData["themeName"].toString(),
      colorFromJsonData(jsonThemeData["backgroundColor"]),
      colorFromJsonData(jsonThemeData["textColor"]),
      colorFromJsonData(jsonThemeData["subjectColor"]),
      colorFromJsonData(jsonThemeData["subjectDropOutColor"]),
      colorFromJsonData(jsonThemeData["subjectSubstitutionColor"]),
    );
    return theme;
  }

  static Theme getThemeFromThemeName(String themeName) {
    for (final theme in themes) {
      if (theme.themeName == themeName) {
        return theme;
      }
    }
    return darkTheme;
  }

  static List<String> getThemeNames() {
    final themeNames = <String>[];
    for (final theme in themes) {
      themeNames.add(theme.themeName);
    }
    return themeNames;
  }
}
