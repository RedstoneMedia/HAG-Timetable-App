import 'package:flutter/material.dart';
import 'package:stundenplan/pages/intro/theme_selection.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:stundenplan/widgets/base_intro_screen.dart';

import '../../widgets/settings_widgets.dart';

class ClassSelectionPage extends StatefulWidget {
  final SharedState sharedState;

  const ClassSelectionPage(this.sharedState);

  @override
  _ClassSelectionPageState createState() => _ClassSelectionPageState();
}

class _ClassSelectionPageState extends State<ClassSelectionPage> {
  late bool Function() saveClassSelection;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: BaseIntroScreen(
          sharedState: widget.sharedState,
          onPressed: () {
            if (saveClassSelection()) {
              widget.sharedState.saveState();
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => ThemeSelectionPage(widget.sharedState)));
            }
          },
          subtitle: "In welcher Klasse bist du?",
          title: "Klasse",
          helpPage: "Set-Up#eingabe-der-klasse",
          child: ClassSelect(
            initCallback: (validate, save, set) {
              saveClassSelection = save;
            },
            sharedState: widget.sharedState,
            vertical: true,
          ),
      ),
    );
  }
}
