import 'package:flutter/material.dart';

enum Theme {
  light,
  dark,
}

class Constants {
  //Theme
  Theme theme = Theme.light;

  String get themeAsString {
    switch (theme) {
      case (Theme.light):
        return "light";
        break;
      case (Theme.dark):
        return "dark";
        break;
      default:
        return "light";
        break;
    }
  }

  set setThemeAsString(String value) {
    switch (value) {
      case ("light"):
        theme = Theme.light;
        break;
      case ("dark"):
        theme = Theme.dark;
        break;
      default:
        theme = Theme.light;
        break;
    }
  }

  Theme get lightTheme => Theme.light;

  Theme get darkTheme => Theme.dark;

  //Grid Properties
  final int width = 6;
  final int height = 10;
  final List<String> weekDays = ["", "Mo", "Di", "Mi", "Do", "Fr"];
  final List<String> subjects = [
    "De",
    "Ma",
    "Sp",
    "Ge",
    "Ek",
    "Po",
    "En",
  ];
  final List<String> startTimes = [
    "7:55",
    "8:45",
    "9:50",
    "10:35",
    "11:40",
    "12:25",
    "13:10",
    "13:50",
    "14:35",
    "15:30",
    "16:15"
  ];
  final List<String> endTimes = [
    "8:40",
    "9:30",
    "10:35",
    "11:20",
    "12:25",
    "13:10",
    "13:45",
    "14:35",
    "15:20",
    "16:15",
    "17:00"
  ];

  //Colors
  Color get backgroundColor {
    switch (theme) {
      case (Theme.light):
        return Color.fromRGBO(240, 240, 240, 1.0);
        break;
      case (Theme.dark):
        return Color.fromRGBO(25, 25, 25, 1.0);
        break;
      default:
        return Color.fromRGBO(240, 240, 240, 1.0);
        break;
    }
  }

  Color get textColor {
    switch (theme) {
      case (Theme.light):
        return Colors.black;
        break;
      case (Theme.dark):
        return Colors.white.withAlpha(200);
        break;
      default:
        return Colors.black;
        break;
    }
  }

  Color get invertedTextColor {
    switch (theme) {
      case (Theme.light):
        return Colors.white;
        break;
      case (Theme.dark):
        return Colors.black.withAlpha(200);
        break;
      default:
        return Colors.white;
        break;
    }
  }

  //final Color subjectColor = Color.fromRGBO(38, 222, 129, 1.0);
  Color get subjectColor {
    switch (theme) {
      case (Theme.light):
        return Color.fromRGBO(38, 222, 129, 1.0);
        break;
      case (Theme.dark):
        return Color.fromRGBO(38 - 20, 222 - 20, 129 - 20, 1.0);
        break;
      default:
        return Color.fromRGBO(38, 222, 129, 1.0);
        break;
    }
  }

  Color get subjectAusfallColor {
    switch (theme) {
      case (Theme.light):
        return Color.fromRGBO(209, 216, 224, 1.0);
        break;
      case (Theme.dark):
        return Color.fromRGBO(209 - 160, 216 - 160, 224 - 160, 1.0);
        break;
      default:
        return Color.fromRGBO(209, 216, 224, 1.0);
        break;
    }
  }

  Color get subjectVertretungColor {
    switch (theme) {
      case (Theme.light):
        return Color.fromRGBO(252, 92, 101, 1.0);
        break;
      case (Theme.dark):
        return Color.fromRGBO(252 - 30, 92 - 30, 101 - 30, 1.0);
        break;
      default:
        return Color.fromRGBO(252, 92, 101, 1.0);
        break;
    }
  }
}
