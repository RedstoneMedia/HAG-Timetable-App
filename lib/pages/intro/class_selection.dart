import 'package:flutter/material.dart';
import 'package:stundenplan/pages/intro/theme_selection.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:stundenplan/widgets/base_intro_screen.dart';

class ClassSelectionPage extends StatefulWidget {
  final SharedState sharedState;

  const ClassSelectionPage(this.sharedState);

  @override
  _ClassSelectionPageState createState() => _ClassSelectionPageState();
}

class _ClassSelectionPageState extends State<ClassSelectionPage> {

  @override
  Widget build(BuildContext context) {
    return BaseIntroScreen(
      sharedState: widget.sharedState,
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => ThemeSelectionPage(widget.sharedState)));
      },
      subtitle: "In welcher Klasse bist du ?",
      title: "Klasse",
      child: Container(), // TODO : Implement
    );
  }
}
