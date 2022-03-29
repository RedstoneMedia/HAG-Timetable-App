import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stundenplan/pages/intro/course_input_method_selection.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:stundenplan/widgets/base_intro_screen.dart';
import 'package:stundenplan/widgets/buttons.dart';
import 'package:stundenplan/theme.dart' as my_theme;

class ThemeSelectionPage extends StatefulWidget {
  final SharedState sharedState;

  const ThemeSelectionPage(this.sharedState);

  @override
  _ClassSelectionPageState createState() => _ClassSelectionPageState();
}

class _ClassSelectionPageState extends State<ThemeSelectionPage> {
  // The first Theme is selected by default
  List<bool> isSelected = [true];
  List<String> themeNames = my_theme.Theme.getThemeNames();

  @override
  void initState() {
    super.initState();
    // Set the selected State to false for every theme
    for (final _ in themeNames) {
      isSelected.add(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseIntroScreen(
      sharedState: widget.sharedState,
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => CourseInputMethodSelectionPage(widget.sharedState)));
      },
      title: "Theme",
      subtitle: "Diese App unterstützt verschiedene Themes.",
      helpPage: "Set-Up#wählen-eines-farbschemas",
      child: ListView.builder(
          shrinkWrap: true,
          itemCount: themeNames.length,
          itemBuilder: (_, i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: ThemeButton(
                onPressed: () {
                  setState(() {
                    if (!isSelected[i]) {
                      for (int i = 0; i < isSelected.length; i++) {
                        isSelected[i] = false;
                      }
                      isSelected[i] = true;
                      widget.sharedState.setThemeFromThemeName(themeNames[i]);
                    }

                    final theme = widget.sharedState.theme;

                    if (widget.sharedState.theme.themeName == "Eigenes") {
                      showDialog(
                          context: context,
                          builder: (_) {
                            return AlertDialog(
                              title: Text(
                                "Farbe ändern",
                                style: GoogleFonts.poppins(
                                    color: theme.textColor,
                                    fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: theme.backgroundColor.withAlpha(255),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ColorPickerButton(
                                    bgColor: theme.backgroundColor,
                                    textColor: theme.textColor,
                                    text: "Hintergrund",
                                    theme: widget.sharedState.theme,
                                    borderColor: widget.sharedState.theme.textColor,
                                    onPicked: (color) {
                                      setState(() {
                                        widget.sharedState.theme
                                            .backgroundColor = color;
                                      });
                                    },
                                  ),
                                  ColorPickerButton(
                                    bgColor: theme.textColor,
                                    textColor: theme.backgroundColor,
                                    text: "Text",
                                    theme: widget.sharedState.theme,
                                    onPicked: (color) {
                                      setState(() {
                                        widget.sharedState.theme
                                            .textColor = color;
                                      });
                                    },
                                  ),
                                  ColorPickerButton(
                                    bgColor: theme.subjectColor,
                                    textColor: theme.textColor,
                                    text: "Fach",
                                    theme: widget.sharedState.theme,
                                    onPicked: (color) {
                                      setState(() {
                                        widget.sharedState.theme
                                            .subjectColor = color;
                                      });
                                    },
                                  ),
                                  ColorPickerButton(
                                    bgColor: theme.subjectDropOutColor,
                                    textColor: theme.textColor,
                                    text: "Fach ausfall",
                                    theme: widget.sharedState.theme,
                                    onPicked: (color) {
                                      setState(() {
                                        widget.sharedState.theme
                                            .subjectDropOutColor = color;
                                      });
                                    },
                                  ),
                                  ColorPickerButton(
                                    bgColor: theme.subjectSubstitutionColor,
                                    textColor: theme.textColor,
                                    text: "Fach vertretung",
                                    theme: widget.sharedState.theme,
                                    onPicked: (color) {
                                      setState(() {
                                        widget.sharedState.theme
                                            .subjectSubstitutionColor = color;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(
                                    "Fertig",
                                    style: GoogleFonts.poppins(
                                        color: theme.textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20.0),
                                  ),
                                ),
                              ],
                            );
                          });
                    }
                  });
                },
                theme: my_theme.Theme.getThemeFromThemeName(themeNames[i]),
                isSelected: isSelected[i],
              ),
            );
          }),
    );
  }
}
