import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stundenplan/main.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:stundenplan/widgets/base_intro_screen.dart';
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
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    height: 60+12,
                    decoration: BoxDecoration(
                      color: widget.sharedState.theme.textColor.withAlpha(200),
                      borderRadius: BorderRadius.circular(15)
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: TextField(
                        controller: courseAddNameTextEditingController,
                        style: GoogleFonts.poppins(color: widget.sharedState.theme.invertedTextColor, fontSize: 30.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                SizedBox(
                  child: ElevatedButton(
                    style: ButtonStyle(
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            )
                        ),
                        backgroundColor: MaterialStateProperty.all<Color>(
                          widget.sharedState.theme.subjectColor,
                        ),
                      ),
                    onPressed: () {
                      setState(() {
                        courses.add(courseAddNameTextEditingController.text);
                        courseAddNameTextEditingController.text = "";
                      });
                    },
                    child: Container(
                      height: 60+12,
                      width: 60-12,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.add,
                        size: 60-12,
                        color: widget.sharedState.theme.textColor,
                      ),
                    ),
                  ),
                )
              ],
            ),
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
      ),
    );
  }
}
