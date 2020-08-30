import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stundenplan/main.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:stundenplan/theme.dart' as MyTheme;
import 'package:stundenplan/widgets/course_select_list.dart';

class SetupPage extends StatefulWidget {
  @override
  _SetupPageState createState() => _SetupPageState();

  SetupPage(this.sharedState);

  SharedState sharedState;
}

class _SetupPageState extends State<SetupPage> {
  String schoolGrade = "11";
  String subSchoolClass;
  String themeName = "dark";

  List<String> grades = [];
  List<String> themeNames = MyTheme.Theme.getThemeNames();
  List<String> courses = [];

  TextEditingController subClassTextEdetingController = new TextEditingController();

  SharedState sharedState;

  @override
  void initState() {
    super.initState();
    sharedState = widget.sharedState;
    themeName = sharedState.theme.themeName;
    schoolGrade = sharedState.schoolGrade.toString();
    subClassTextEdetingController.text = sharedState.subSchoolClass;
    courses = sharedState.subjects;
    for (int i = 5; i <= 13; i++) {
      grades.add(i.toString());
    }
  }

  void saveDataAndGotToMain() {
    setState(() {
      if (!validateSubClassInput()) return; //TODO: Error handling

      sharedState.subjects = [];
      sharedState.subjects.addAll(courses);
      sharedState.schoolGrade = int.parse(schoolGrade);
      sharedState.subSchoolClass = subClassTextEdetingController.text;
      sharedState.saveState();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WillPopScope(
            onWillPop: () async => false,
            child: MyApp(sharedState),
          ),
        ),
      );
    });
  }

  bool validateSubClassInput() {
    String text = subClassTextEdetingController.text;
    RegExp regExp = new RegExp(r"^[a-zA-Z]\d{0,2}$");
    return regExp.hasMatch(text);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: sharedState.theme.backgroundColor,
      child: SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Klasse",
                    style: GoogleFonts.poppins(
                        color: sharedState.theme.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 26.0),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: sharedState.theme.textColor.withAlpha(200),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 0.0, horizontal: 15.0),
                          child: DropdownButton<String>(
                            value: schoolGrade,
                            icon: Icon(Icons.keyboard_arrow_down),
                            iconSize: 24,
                            elevation: 16,
                            dropdownColor: sharedState.theme.textColor.withAlpha(255),
                            style:
                                TextStyle(color: sharedState.theme.invertedTextColor),
                            underline: Container(),
                            onChanged: (String newValue) {
                              setState(() {
                                schoolGrade = newValue;
                              });
                            },
                            items: grades
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: Text(
                                    value,
                                    style: GoogleFonts.poppins(fontSize: 16.0),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 60,
                      decoration: BoxDecoration(
                        color: sharedState.theme.textColor.withAlpha(200),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 0.0, horizontal: 15.0),
                        child: TextField(
                          controller: subClassTextEdetingController,
                          style: GoogleFonts.poppins(
                              color: sharedState.theme.invertedTextColor),
                          decoration: InputDecoration(
                            hintText: "a",
                            hintStyle: GoogleFonts.poppins(
                                color:
                                sharedState.theme.invertedTextColor.withAlpha(80)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 80.0, vertical: 4.0),
                  child: Divider(
                    thickness: 2.0,
                    color: sharedState.theme.textColor.withAlpha(200),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 0.0, bottom: 12.0),
                  child: Text(
                    "Theme",
                    style: GoogleFonts.poppins(
                        color: sharedState.theme.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 26.0),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: sharedState.theme.textColor.withAlpha(200),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 0.0, horizontal: 15.0),
                    child: DropdownButton<String>(
                      value: themeName,
                      icon: Icon(Icons.keyboard_arrow_down),
                      iconSize: 24,
                      elevation: 16,
                      style: TextStyle(color: sharedState.theme.invertedTextColor),
                      underline: Container(),
                      dropdownColor: sharedState.theme.textColor.withAlpha(255),
                      onChanged: (String newValue) {
                        setState(() {
                          themeName = newValue;
                          sharedState.setThemeFromThemeName(themeName);
                        });
                      },
                      items:
                          themeNames.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: Text(
                              value,
                              style: GoogleFonts.poppins(fontSize: 16.0),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 80.0, vertical: 4.0),
                  child: Divider(
                    thickness: 2.0,
                    color: sharedState.theme.textColor.withAlpha(200),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 0.0, bottom: 8.0),
                  child: Text(
                    "Kurse",
                    style: GoogleFonts.poppins(
                        color: sharedState.theme.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 26.0),
                  ),
                ),
                CourseSelectList(
                  sharedState,
                  courses,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                        color: sharedState.theme.textColor,
                        borderRadius: BorderRadius.circular(100)),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          courses.add("");
                        });
                      },
                      child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Icon(
                          Icons.add,
                          color: sharedState.theme.subjectColor,
                          size: 50,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0, top: 2.0),
                  child: RaisedButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Fertig",
                        style: GoogleFonts.poppins(
                            color: sharedState.theme.textColor,
                            fontSize: 25.0,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    onPressed: () {
                      saveDataAndGotToMain();
                    },
                    color: sharedState.theme.subjectColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
