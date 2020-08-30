import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/main.dart';
import 'package:stundenplan/widgets/course_select_list.dart';

class SetupPage extends StatefulWidget {
  @override
  _SetupPageState createState() => _SetupPageState();

  SetupPage(this.constants, this.prefs);

  Constants constants;
  SharedPreferences prefs;
}

class _SetupPageState extends State<SetupPage> {
  String subSchoolClass = "a";
  String schoolGrade = "11";
  List<String> subClasses = [];
  List<String> grades = [];
  Constants constants;
  List<String> courses = [];
  SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    prefs = widget.prefs;
    constants = widget.constants ?? new Constants();
    subSchoolClass = constants.subSchoolClass;
    schoolGrade = constants.schoolGrade.toString();
    courses = constants.subjects;

    for (int i = 0; i < 10; i++) {
      subClasses.add(String.fromCharCode(i + 97));
    }
    for (int i = 5; i <= 13; i++) {
      grades.add(i.toString());
    }
    setState(() {
      constants.theme = constants.darkTheme;
    });
  }

  void saveDataAndGotToMain() {
    setState(() {
      constants.subjects = [];
      constants.subjects.addAll(courses);
      constants.schoolGrade = int.parse(schoolGrade);
      constants.subSchoolClass = subSchoolClass;

      prefs.setInt("schoolGrade", constants.schoolGrade);
      prefs.setString("subSchoolClass", constants.subSchoolClass);
      prefs.setStringList("subjects", constants.subjects);
      prefs.setString("theme", constants.themeAsString);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MyApp(constants)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: constants.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: constants.textColor.withAlpha(200),
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
                        dropdownColor: constants.textColor.withAlpha(255),
                        style: TextStyle(color: constants.subjectColor),
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
                  decoration: BoxDecoration(
                    color: constants.textColor.withAlpha(200),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 0.0, horizontal: 15.0),
                    child: DropdownButton<String>(
                      value: subSchoolClass,
                      icon: Icon(Icons.keyboard_arrow_down),
                      iconSize: 24,
                      elevation: 16,
                      style: TextStyle(color: constants.subjectColor),
                      underline: Container(),
                      dropdownColor: constants.textColor.withAlpha(255),
                      onChanged: (String newValue) {
                        setState(() {
                          subSchoolClass = newValue;
                        });
                      },
                      items: subClasses
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
              ],
            ),
            Container(
              child: InkWell(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
                  child: Text(
                    constants.themeAsString,
                    style: GoogleFonts.poppins(
                        color: constants.invertedTextColor, fontSize: 20.0),
                  ),
                ),
                onTap: () {
                  setState(() {
                    if (constants.theme == constants.lightTheme)
                      constants.theme = constants.darkTheme;
                    else
                      constants.theme = constants.lightTheme;
                  });
                },
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: constants.textColor.withAlpha(200),
              ),
            ),
            Expanded(
              child: CourseSelectList(
                constants,
                courses,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                  decoration: BoxDecoration(
                      color: constants.textColor,
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
                        color: constants.subjectColor,
                        size: 50,
                      ),
                    ),
                  )),
            ),
            RaisedButton(
              child: Text(
                "Fertig",
                style: GoogleFonts.poppins(
                    color: constants.textColor, fontSize: 25.0),
              ),
              onPressed: () {
                saveDataAndGotToMain();
              },
              color: constants.subjectColor,
            ),
          ],
        ),
      ),
    );
  }
}
