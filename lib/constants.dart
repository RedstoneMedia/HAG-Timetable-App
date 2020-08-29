import 'package:flutter/material.dart';

enum Theme {
  light,
  dark,
}

class Constants {
  //Theme
  Theme theme = Theme.light;

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
