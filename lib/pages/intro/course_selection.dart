import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/main.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:stundenplan/widgets/base_intro_screen.dart';
import 'package:stundenplan/widgets/course_select_list.dart';
import 'package:stundenplan/parsing/parse_timetable.dart';
import 'package:http/http.dart'; // Contains a client for making API calls

class CourseSelectionPage extends StatefulWidget {
  final SharedState sharedState;

  const CourseSelectionPage(this.sharedState);

  @override
  _ClassSelectionPageState createState() => _ClassSelectionPageState();
}

class _ClassSelectionPageState extends State<CourseSelectionPage> {

  TextEditingController courseAddNameTextEditingController = TextEditingController();
  List<String> courses = [];
  late List<String> options = [];

  _ClassSelectionPageState();

  void saveDataToProfile() {
    setState(() {
      widget.sharedState.profileManager.subjects = [];
      widget.sharedState.profileManager.subjects.addAll(courses);
      widget.sharedState.saveState();
      courses = widget.sharedState.profileManager.currentProfile.subjects;
    });
  }

  Future<void> setOptions() async {
    final client = Client();
    options = (await getAvailableSubjectNames(widget.sharedState.profileManager.currentProfileName, Constants.timeTableLinkBase, client)).toList();
    if (!Constants.displayFullHeightSchoolGrades.contains(widget.sharedState.profileManager.schoolGrade)) {
      options.addAll(await getAvailableSubjectNames("${widget.sharedState.profileManager.schoolGrade}K", Constants.timeTableLinkBase, client));
    }
  }

  @override
  void initState() {
    super.initState();
    courses = widget.sharedState.profileManager.subjects;
    setOptions();
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
                      child: Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text == '') {
                            return const Iterable<String>.empty();
                          }
                          return options.where((String option) {
                            return option.contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        fieldViewBuilder: (
                            BuildContext context,
                            TextEditingController fieldTextEditingController,
                            FocusNode fieldFocusNode,
                            VoidCallback onFieldSubmitted
                        ) {
                          courseAddNameTextEditingController = fieldTextEditingController;
                          return TextField(
                            controller: fieldTextEditingController,
                            focusNode: fieldFocusNode,
                            style: GoogleFonts.poppins(color: widget.sharedState.theme.invertedTextColor, fontSize: 30.0),
                          );
                        },
                        optionsViewBuilder: (
                            BuildContext context,
                            AutocompleteOnSelected<String> onSelected,
                            Iterable<String> options
                        ) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              child: Container(
                                width: 150,
                                color : Color.fromRGBO(widget.sharedState.theme.textColor.red-20, widget.sharedState.theme.textColor.green-20, widget.sharedState.theme.textColor.blue-20, 1.0),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.all(0.0),
                                  itemCount: options.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final String option = options.elementAt(index);
                                    return GestureDetector(
                                      onTap: () {
                                        onSelected(option);
                                      },
                                      child: ListTile(
                                        title: Text(option, style: GoogleFonts.poppins(color: widget.sharedState.theme.invertedTextColor, fontSize: 20.0),),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
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
