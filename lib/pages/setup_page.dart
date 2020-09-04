import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stundenplan/constants.dart';
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
  String profileName = "11e";
  String subSchoolClass;
  String themeName = "dark";

  List<String> grades = Constants.schoolGrades;
  List<String> themeNames = MyTheme.Theme.getThemeNames();
  List<String> courses = [];

  TextEditingController subClassTextEdetingController = new TextEditingController();

  SharedState sharedState;
  bool subSchoolClassEnabled;
  bool subSchoolClassIsCorrect = true;

  @override
  void initState() {
    super.initState();
    sharedState = widget.sharedState;
    themeName = sharedState.theme.themeName;
    profileName = sharedState.profileManager.currentProfileName;
    schoolGrade = sharedState.profileManager.schoolGrade.toString();
    subClassTextEdetingController.text = sharedState.profileManager.subSchoolClass;
    courses = sharedState.profileManager.subjects;
    subSchoolClassEnabled = !Constants.displayFullHeightSchoolGrades.contains(schoolGrade);
  }

  void setSharedStateFromLocalStateVars() {
    if (!validateSubClassInput()) return;
    sharedState.profileManager.subjects = [];
    sharedState.profileManager.subjects.addAll(courses);
    sharedState.profileManager.schoolGrade = schoolGrade;

    if (Constants.displayFullHeightSchoolGrades.contains(schoolGrade)) {
      sharedState.profileManager.subSchoolClass = "";
      sharedState.height = Constants.fullHeight;
    } else {
      sharedState.profileManager.subSchoolClass = subClassTextEdetingController.text;
      sharedState.height = Constants.defaultHeight;
    }
  }

  void saveDataAndGotToMain() {
    if (!validateSubClassInput()) return;

    setSharedStateFromLocalStateVars();
    sharedState.saveState();
    profileName = sharedState.profileManager.currentProfileName;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: MyApp(sharedState),
        ),
      ),
    );
  }

  bool validateSubClassInput() {
    if (Constants.displayFullHeightSchoolGrades.contains(schoolGrade)) {
      return true;
    }
    String text = subClassTextEdetingController.text;
    RegExp regExp = new RegExp(r"^[a-zA-Z]{0,3}\d{0,2}$");
    bool hasMatch = regExp.hasMatch(text);
    if (hasMatch) {
      setState(() {
        subSchoolClassIsCorrect = true;
      });
      return true;
    } else {
      setState(() {
        subSchoolClassIsCorrect = false;
      });
      return false;
    }
  }

  void setSchoolGrade(String schoolGrade) {
    setState(() {
      this.schoolGrade = schoolGrade;
      if (Constants.displayFullHeightSchoolGrades.contains(schoolGrade)) {
        subClassTextEdetingController.text = "";
        subSchoolClassEnabled = false;
      } else {
        subSchoolClassEnabled = true;
      }
    });
  }

  void setProfile(String profileName) {
    setState(() {
      setSharedStateFromLocalStateVars();  // Save old profile local state variables into shared state
      sharedState.profileManager.currentProfileName = profileName;  // Change to new profile name
      sharedState.profileManager.renameAllProfiles();
      // Set local state variables
      this.profileName = sharedState.profileManager.currentProfileName;
      subClassTextEdetingController.text = sharedState.profileManager.currentProfile.subSchoolClass;
      schoolGrade = sharedState.profileManager.currentProfile.schoolGrade;
      courses = sharedState.profileManager.currentProfile.subjects;
    });
  }

  void removeProfile() {
    setState(() {
      if (sharedState.profileManager.profiles.length > 1) {  // Check if to few profiles
        String toDeleteProfileName = profileName;  //  Get current profile name
        List<String> profileKeys = sharedState.profileManager.profiles.keys.toList();  // Get profile names
        profileKeys.remove(toDeleteProfileName);  // Remove current profile from profile name list
        this.profileName = profileKeys.last;  // Set current profile to last profile
        // Update local state variables
        sharedState.profileManager.currentProfileName = profileName;
        subClassTextEdetingController.text = sharedState.profileManager.currentProfile.subSchoolClass;
        schoolGrade = sharedState.profileManager.currentProfile.schoolGrade;
        courses = sharedState.profileManager.currentProfile.subjects;
        sharedState.profileManager.profiles.remove(toDeleteProfileName);  // Remove profile
      }
    });
  }

  void addProfile() {
    profileName = sharedState.profileManager.findNewProfileName("New Profile");  // Get new profile placeholder name.
    sharedState.profileManager.addProfileWithName(profileName);  // Add that new Profile to placeholder name.
    setProfile(profileName);  // Switch to that profile
  }


  // TODO : Refactor this madness
  @override
  Widget build(BuildContext context) {
    return Material(
      color: sharedState.theme.backgroundColor,
      child: SafeArea(
        child: ListView(
          shrinkWrap: true,
          physics: BouncingScrollPhysics(),
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text("Profile",
                    style: GoogleFonts.poppins(
                        color: sharedState.theme.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 26.0),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: sharedState.theme.textColor.withAlpha(200),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 15.0),
                      child: DropdownButton<String>(
                        value: profileName,
                        icon: Icon(Icons.keyboard_arrow_down),
                        iconSize: 24,
                        elevation: 16,
                        dropdownColor:
                        sharedState.theme.textColor.withAlpha(255),
                        style: TextStyle(color: sharedState.theme.invertedTextColor),
                        underline: Container(),
                        onChanged: (String profileName) {
                          setProfile(profileName);
                        },
                        items: sharedState.profileManager.profiles.keys.map<DropdownMenuItem<String>>((String profileName) {
                          return DropdownMenuItem<String>(
                            value: profileName,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: Text(
                                profileName,
                                style: GoogleFonts.poppins(fontSize: 16.0),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                            color: sharedState.theme.textColor,
                            borderRadius: BorderRadius.circular(100)),
                        child: InkWell(
                          onTap: () {
                            addProfile();
                          },
                          child: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Icon(
                              Icons.add,
                              color: sharedState.theme.subjectColor,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                            color: sharedState.theme.textColor,
                            borderRadius: BorderRadius.circular(100)),
                        child: InkWell(
                          onTap: () {
                            removeProfile();
                          },
                          child: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Icon(
                              Icons.remove,
                              color: sharedState.theme.subjectSubstitutionColor,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5.0, vertical: 4.0),
                  child: Divider(
                    thickness: 2.0,
                    color: sharedState.theme.textColor.withAlpha(200),
                  ),
                ),
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
                            dropdownColor:
                            sharedState.theme.textColor.withAlpha(255),
                            style: TextStyle(
                                color: sharedState.theme.invertedTextColor),
                            underline: Container(),
                            onChanged: (String newValue) {
                              setSchoolGrade(newValue);
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
                        color: subSchoolClassEnabled
                            ? sharedState.theme.textColor.withAlpha(200)
                            : sharedState.theme.textColor.withAlpha(100),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: subSchoolClassIsCorrect
                            ? Colors.transparent
                            : Colors.red,
                            width: subSchoolClassIsCorrect ? 0 : 2.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 0.0, horizontal: 15.0),
                        child: TextField(
                          enabled: subSchoolClassEnabled,
                          controller: subClassTextEdetingController,
                          style: GoogleFonts.poppins(
                              color: sharedState.theme.invertedTextColor),
                          decoration: InputDecoration(
                            hintText: "a",
                            hintStyle: GoogleFonts.poppins(
                                color: sharedState.theme.invertedTextColor
                                    .withAlpha(80)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5.0, vertical: 4.0),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5.0, vertical: 4.0),
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
                      style:
                      TextStyle(color: sharedState.theme.invertedTextColor),
                      underline: Container(),
                      dropdownColor: sharedState.theme.textColor.withAlpha(255),
                      onChanged: (String newValue) {
                        setState(() {
                          themeName = newValue;
                          sharedState.setThemeFromThemeName(themeName);
                        });
                      },
                      items: themeNames
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0, top: 15.0),
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
