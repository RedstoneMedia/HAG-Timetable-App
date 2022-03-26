import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/main.dart';
import 'package:stundenplan/pages/calendar_settings_page.dart';
import 'package:stundenplan/pages/intro/class_selection.dart';
import 'package:stundenplan/pages/iserv_login_settings_page.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:stundenplan/theme.dart' as my_theme;
import 'package:stundenplan/widgets/buttons.dart';
import 'package:stundenplan/widgets/course_autocomplete_add_input.dart';
import 'package:stundenplan/widgets/course_select_list.dart';
import 'package:flutter/foundation.dart';

// ignore: must_be_immutable
class SetupPage extends StatefulWidget {
  @override
  _SetupPageState createState() => _SetupPageState();

  SetupPage(this.sharedState);

  SharedState sharedState;
}

class _SetupPageState extends State<SetupPage> {
  String? schoolGrade;
  String? profileName;
  String? subSchoolClass;
  String themeName = "dark";

  List<String> grades = Constants.schoolGrades;
  List<String> themeNames = my_theme.Theme.getThemeNames();
  List<String> courses = [];

  TextEditingController subClassTextEdetingController = TextEditingController();

  late SharedState sharedState;
  bool? subSchoolClassEnabled;
  bool subSchoolClassIsCorrect = true;
  bool schoolClassIsCorrect = true;
  Color? lastPickedColor;

  @override
  void initState() {
    super.initState();
    sharedState = widget.sharedState;
    themeName = sharedState.theme.themeName;
    profileName = sharedState.profileManager.currentProfileName;
    schoolGrade = sharedState.profileManager.schoolGrade.toString();
    subClassTextEdetingController.text =
        sharedState.profileManager.subSchoolClass;
    courses = sharedState.profileManager.subjects;
    subSchoolClassEnabled =
        !Constants.displayFullHeightSchoolGrades.contains(schoolGrade);
  }

  void setSharedStateFromLocalStateVars() {
    if (!validateClassInput()) return;
    sharedState.profileManager.subjects = [];
    sharedState.profileManager.subjects.addAll(courses);
    sharedState.profileManager.schoolGrade = schoolGrade!;

    if (Constants.displayFullHeightSchoolGrades.contains(schoolGrade)) {
      sharedState.profileManager.subSchoolClass = "";
      sharedState.height = Constants.fullHeight;
    } else {
      sharedState.profileManager.subSchoolClass =
          subClassTextEdetingController.text;
      sharedState.height = Constants.defaultHeight;
    }
  }

  void saveDataAndGotToMain() {
    if (!validateClassInput()) return;

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

  bool validateClassInput() {
    setState(() {
      schoolClassIsCorrect = true;
      subSchoolClassIsCorrect = true;
    });

    if (schoolGrade == null) {
      setState(() {
        schoolClassIsCorrect = false;
      });
      return false;
    }
    if (Constants.displayFullHeightSchoolGrades.contains(schoolGrade)) {
      return true;
    }
    final text = subClassTextEdetingController.text;
    final regExp = RegExp(r"^[a-zA-Z]{1,3}\d{0,2}$");
    final hasMatch = regExp.hasMatch(text);
    if (hasMatch) {
      return true;
    } else {
      setState(() {
        subSchoolClassIsCorrect = false;
      });
      return false;
    }
  }

  void setSchoolGrade(String? schoolGrade) {
    setState(() {
      this.schoolGrade = schoolGrade;
      if (this.schoolGrade != null) schoolClassIsCorrect = true;
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
      setSharedStateFromLocalStateVars(); // Save old profile local state variables into shared state
      sharedState.profileManager.currentProfileName =
          profileName; // Change to new profile name
      sharedState.profileManager.renameAllProfiles();
      // Set local state variables
      this.profileName = sharedState.profileManager.currentProfileName;
      subClassTextEdetingController.text =
          sharedState.profileManager.currentProfile.subSchoolClass;
      setSchoolGrade(sharedState.profileManager.currentProfile.schoolGrade);
      courses = sharedState.profileManager.currentProfile.subjects;
      schoolClassIsCorrect = true;
      subSchoolClassIsCorrect = true;
    });
  }

  void removeProfile() {
    setState(() {
      if (sharedState.profileManager.profiles.length > 1) {
        // Check if to few profiles
        final toDeleteProfileName = profileName; //  Get current profile name
        final profileKeys = sharedState.profileManager.profiles.keys
            .toList(); // Get profile names
        profileKeys.remove(
            toDeleteProfileName); // Remove current profile from profile name list
        profileName = profileKeys.last; // Set current profile to last profile
        // Update local state variables
        sharedState.profileManager.currentProfileName = profileName!;
        subClassTextEdetingController.text =
            sharedState.profileManager.currentProfile.subSchoolClass;
        setSchoolGrade(sharedState.profileManager.currentProfile.schoolGrade);
        courses = sharedState.profileManager.currentProfile.subjects;
        sharedState.profileManager.profiles
            .remove(toDeleteProfileName); // Remove profile
      }
    });
  }

  void addProfile() {
    if (!validateClassInput()) return;
    profileName = sharedState.profileManager
        .findNewProfileName("Neues Profil"); // Get new profile placeholder name.
    sharedState.profileManager.addProfileWithName(profileName!); // Add that new Profile to placeholder name.
    setProfile(profileName!); // Switch to that profile
  }

  // TODO : Refactor this madness
  @override
  Widget build(BuildContext context) {
    return Material(
      color: sharedState.theme.backgroundColor,
      child: SafeArea(
        child: ListView(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Profil",
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
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: DropdownButton<String>(
                        value: profileName,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        elevation: 16,
                        dropdownColor:
                            sharedState.theme.textColor.withAlpha(255),
                        style: TextStyle(
                            color: sharedState.theme.invertedTextColor),
                        underline: Container(),
                        onChanged: (String? profileName) {
                          setProfile(profileName!);
                        },
                        items: sharedState.profileManager.profiles.keys
                            .map<DropdownMenuItem<String>>(
                                (String profileName) {
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
                      child: MaterialButton(
                        onPressed: () {
                          addProfile();
                        },
                        color: sharedState.theme.textColor,
                        padding: const EdgeInsets.all(15.0),
                        shape: const CircleBorder(),
                        child: Icon(
                          Icons.add,
                          color: sharedState.theme.subjectColor,
                          size: 30,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: MaterialButton(
                        onPressed: () {
                          removeProfile();
                        },
                        color: sharedState.theme.textColor,
                        padding: const EdgeInsets.all(15.0),
                        shape: const CircleBorder(),
                        child: Icon(
                          Icons.remove,
                          color: sharedState.theme.subjectSubstitutionColor,
                          size: 30,
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
                          border: Border.all(
                              color: schoolClassIsCorrect
                                  ? Colors.transparent
                                  : Colors.red,
                              width: schoolClassIsCorrect ? 0 : 2.0)
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15.0),
                          child: DropdownButton<String>(
                            value: schoolGrade,
                            icon: const Icon(Icons.keyboard_arrow_down),
                            elevation: 16,
                            dropdownColor:
                                sharedState.theme.textColor.withAlpha(255),
                            style: TextStyle(
                                color: sharedState.theme.invertedTextColor),
                            underline: Container(),
                            onChanged: (String? newValue) {
                              setSchoolGrade(newValue!);
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
                        color: subSchoolClassEnabled!
                            ? sharedState.theme.textColor.withAlpha(200)
                            : sharedState.theme.textColor.withAlpha(100),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                            color: subSchoolClassIsCorrect
                                ? Colors.transparent
                                : Colors.red,
                            width: subSchoolClassIsCorrect ? 0 : 2.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
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
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    "Kurse",
                    style: GoogleFonts.poppins(
                        color: sharedState.theme.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 26.0),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CourseAutoCompleteAddInput(sharedState: sharedState, onAdd: (courseName) {
                    setState(() {
                      courses.add(courseName);
                    });
                  }),
                ),
                CourseSelectList(
                  sharedState,
                  courses,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5.0, vertical: 4.0),
                  child: Divider(
                    thickness: 2.0,
                    color: sharedState.theme.textColor.withAlpha(200),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    StandardButton(
                      text : "Kalender Optionen",
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => CalendarSettingsPage(widget.sharedState)));
                      },
                      sharedState: sharedState,
                      color: sharedState.theme.subjectSubstitutionColor.withAlpha(150),
                      fontSize: 12,
                      size: 0.5,
                    ),
                    StandardButton(
                      text: "IServ Login Optionen",
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => IServLoginSettingsPage(widget.sharedState)));
                      },
                      sharedState: sharedState,
                      color: sharedState.theme.subjectDropOutColor.withAlpha(150),
                      fontSize: 12,
                      size : 0.5
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
                  padding: const EdgeInsets.only(bottom: 12.0),
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
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: DropdownButton<String>(
                      value: themeName,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      elevation: 16,
                      style:
                          TextStyle(color: sharedState.theme.invertedTextColor),
                      underline: Container(),
                      dropdownColor: sharedState.theme.textColor.withAlpha(255),
                      onChanged: (String? newValue) {
                        setState(() {
                          themeName = newValue!;
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
                if (themeName == "Eigenes")
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0, top: 15.0, left: 90, right: 90),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ColorPickerButton(
                          bgColor: widget.sharedState.theme.backgroundColor,
                          textColor: widget.sharedState.theme.textColor,
                          text: "Hintergrund",
                          theme: widget.sharedState.theme,
                          borderColor: widget.sharedState.theme.textColor.withAlpha(150),
                          padding: 6.0,
                          fontSize: 16.0,
                          onPicked: (color) {
                            setState(() {
                              widget.sharedState.theme
                                  .backgroundColor = color;
                            });
                          },
                        ),
                        ColorPickerButton(
                          bgColor: widget.sharedState.theme.textColor,
                          textColor: widget.sharedState.theme.backgroundColor,
                          text: "Text",
                          theme: widget.sharedState.theme,
                          padding: 6.0,
                          fontSize: 16.0,
                          onPicked: (color) {
                            setState(() {
                              widget.sharedState.theme
                                  .textColor = color;
                            });
                          },
                        ),
                        ColorPickerButton(
                          bgColor: widget.sharedState.theme.subjectColor,
                          textColor: widget.sharedState.theme.textColor,
                          text: "Fach",
                          theme: widget.sharedState.theme,
                          padding: 6.0,
                          fontSize: 16.0,
                          onPicked: (color) {
                            setState(() {
                              widget.sharedState.theme
                                  .subjectColor = color;
                            });
                          },
                        ),
                        ColorPickerButton(
                          bgColor: widget.sharedState.theme.subjectDropOutColor,
                          textColor: widget.sharedState.theme.textColor,
                          text: "Fach ausfall",
                          theme: widget.sharedState.theme,
                          padding: 6.0,
                          fontSize: 16.0,
                          onPicked: (color) {
                            setState(() {
                              widget.sharedState.theme
                                  .subjectDropOutColor = color;
                            });
                          },
                        ),
                        ColorPickerButton(
                          bgColor: widget.sharedState.theme.subjectSubstitutionColor,
                          textColor: widget.sharedState.theme.textColor,
                          text: "Fach vertretung",
                          theme: widget.sharedState.theme,
                          padding: 6.0,
                          fontSize: 16.0,
                          onPicked: (color) {
                            setState(() {
                              widget.sharedState.theme
                                  .subjectSubstitutionColor = color;
                            });
                          },
                        )
                      ]
                    )
                  )
                else
                  Container(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0, top: 15.0),
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(sharedState.theme.subjectColor),
                      shape: MaterialStateProperty.all<OutlinedBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                    onPressed: () {
                      saveDataAndGotToMain();
                    },
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
                  ),
                ),
                if (!kReleaseMode) Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5.0, vertical: 4.0),
                      child: Divider(
                        thickness: 2.0,
                        color: sharedState.theme.textColor.withAlpha(200),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        "Debug",
                        style: GoogleFonts.poppins(
                            color: sharedState.theme.textColor.withAlpha(150),
                            fontWeight: FontWeight.bold,
                            fontSize: 22.0),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5.0),
                      child : ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(sharedState.theme.subjectDropOutColor),
                          shape: MaterialStateProperty.all<OutlinedBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => ClassSelectionPage(widget.sharedState)));
                        },
                        child: Text(
                          "Show intro screen",
                          style: GoogleFonts.poppins(
                              color: sharedState.theme.textColor.withAlpha(150),
                              fontSize: 9.0,
                              fontWeight: FontWeight.normal),
                        ),
                      ),
                    ),
                  ],
                ) else
                  Container(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
