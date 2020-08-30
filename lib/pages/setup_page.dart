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
  String schoolGrade = "11";
  String subSchoolClass;
  String theme = "dark";

  List<String> grades = [];
  List<String> themes = ["dark", "light"];
  List<String> courses = [];

  TextEditingController subClassTextEdetingController =
      new TextEditingController();

  Constants constants;
  SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    prefs = widget.prefs;
    constants = widget.constants ?? new Constants();
    schoolGrade = constants.schoolGrade.toString();
    subClassTextEdetingController.text = constants.subSchoolClass;
    courses = constants.subjects;

    for (int i = 5; i <= 13; i++) {
      grades.add(i.toString());
    }
  }

  void saveDataAndGotToMain() {
    setState(() {
      if (!validateSubClassInput()) return; //TODO: Error handling

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
        MaterialPageRoute(
          builder: (context) => WillPopScope(
            onWillPop: () async => false,
            child: MyApp(constants),
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
      color: constants.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "Klasse",
                style: GoogleFonts.poppins(
                    color: constants.textColor,
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
                        style: TextStyle(color: constants.invertedTextColor),
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
                    color: constants.textColor.withAlpha(200),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 0.0, horizontal: 15.0),
                    child: TextField(
                      controller: subClassTextEdetingController,
                      decoration: InputDecoration(hintText: "a"),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 12.0),
              child: Text(
                "Theme",
                style: GoogleFonts.poppins(
                    color: constants.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 26.0),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: constants.textColor.withAlpha(200),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding:
                const EdgeInsets.symmetric(vertical: 0.0, horizontal: 15.0),
                child: DropdownButton<String>(
                  value: theme,
                  icon: Icon(Icons.keyboard_arrow_down),
                  iconSize: 24,
                  elevation: 16,
                  style: TextStyle(color: constants.invertedTextColor),
                  underline: Container(),
                  dropdownColor: constants.textColor.withAlpha(255),
                  onChanged: (String newValue) {
                    setState(() {
                      theme = newValue;
                      setState(() {
                        constants.setThemeAsString = newValue;
                      });
                    });
                  },
                  items: themes.map<DropdownMenuItem<String>>((String value) {
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
                ),
              ),
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
