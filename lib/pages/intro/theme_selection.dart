import 'package:flutter/material.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:stundenplan/widgets/base_intro_screen.dart';

import 'course_selection.dart';

class ThemeSelectionPage extends StatefulWidget {
  final SharedState sharedState;

  const ThemeSelectionPage(this.sharedState);

  @override
  _ClassSelectionPageState createState() => _ClassSelectionPageState();
}

class _ClassSelectionPageState extends State<ThemeSelectionPage> {

  @override
  Widget build(BuildContext context) {
    return BaseIntroScreen(
      sharedState: widget.sharedState,
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => CourseSelectionPage(widget.sharedState)));
      },
      subtitle: "Diese App unterstützt verschidene Themes.",
      title: "Theme",
      child: Container(), // TODO : Implement
    );
  }
}
