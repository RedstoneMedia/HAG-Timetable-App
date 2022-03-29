import 'package:flutter/material.dart';
import 'package:stundenplan/main.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:stundenplan/widgets/base_intro_screen.dart';
import 'package:stundenplan/widgets/course_autocomplete_add_input.dart';
import 'package:stundenplan/widgets/course_select_list.dart';

class CourseSelectionPage extends StatefulWidget {
  final SharedState sharedState;

  const CourseSelectionPage(this.sharedState);

  @override
  _ClassSelectionPageState createState() => _ClassSelectionPageState();
}

class _ClassSelectionPageState extends State<CourseSelectionPage> {

  TextEditingController courseAddNameTextEditingController = TextEditingController();
  List<String> courses = [];

  _ClassSelectionPageState();

  void saveDataToProfile() {
    setState(() {
      widget.sharedState.profileManager.subjects = [];
      widget.sharedState.profileManager.subjects.addAll(courses);
      widget.sharedState.saveState();
      courses = widget.sharedState.profileManager.currentProfile.subjects;
    });
  }

  @override
  void initState() {
    super.initState();
    courses = widget.sharedState.profileManager.subjects;
  }

  @override
  Widget build(BuildContext context) {
    return BaseIntroScreen(
      sharedState: widget.sharedState,
      onPressed: () {
        saveDataToProfile();
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => MyApp(widget.sharedState)));
      },
      subtitle: "Hier kannst du deine gewählten Kurse eintragen. z.B En",
      title: "Kurse",
      helpPage: "Set-Up#manuell",
      child: Column(
        children: [
          CourseAutoCompleteAddInput(sharedState: widget.sharedState, onAdd: (courseName) {
            setState(() {
              courses.add(courseName);
            });
          }),
          const SizedBox(height: 20),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.42,
            child: ListView(
              children: [
                CourseSelectList(
                  widget.sharedState,
                  courses,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
