import 'package:flutter/material.dart';
import 'package:stundenplan/main.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:stundenplan/widgets/base_intro_screen.dart';

class CourseSelectionPage extends StatefulWidget {
  final SharedState sharedState;

  const CourseSelectionPage(this.sharedState);

  @override
  _ClassSelectionPageState createState() => _ClassSelectionPageState();
}

class _ClassSelectionPageState extends State<CourseSelectionPage> {

  @override
  Widget build(BuildContext context) {
    return BaseIntroScreen(
      sharedState: widget.sharedState,
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => MyApp(widget.sharedState)));
      },
      subtitle: "Hier kannst du deine gewählten Kurse eintragen. z.B En",
      title: "Kurse",
      child: Container(), // TODO : Implement
    );
  }
}
