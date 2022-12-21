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
import 'package:stundenplan/widgets/settings_widgets.dart';

// ignore: must_be_immutable
class SetupPage extends StatefulWidget {
  @override
  _SetupPageState createState() => _SetupPageState();

  SetupPage(this.sharedState);

  SharedState sharedState;
}

class _SetupPageState extends State<SetupPage> {
  String? profileName;
  String themeName = "dark";
  late bool Function() validateClassSelection;
  late bool Function() saveClassSelection;
  late void Function(String?, String) setClassSelectionClass;

  List<String> themeNames = my_theme.Theme.getThemeNames();
  List<String> courses = [];
  bool sendNotifications = false;

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
    courses = sharedState.profileManager.subjects;
    sendNotifications = sharedState.sendNotifications;
  }

  void setSharedStateFromLocalStateVars() {
    if (!saveClassSelection()) return;
    sharedState.profileManager.subjects = [];
    sharedState.profileManager.subjects.addAll(courses);
    sharedState.sendNotifications = sendNotifications;
  }

  void saveDataAndGotToMain() {
    if (!validateClassSelection()) return;

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

  void setProfile(String profileName) {
    setState(() {
      if (!validateClassSelection()) return;
      sharedState.hasChangedCourses = true;
      setSharedStateFromLocalStateVars(); // Save old profile local state variables into shared state
      sharedState.profileManager.currentProfileName =
          profileName; // Change to new profile name
      sharedState.profileManager.renameAllProfiles();
      setClassSelectionClass(sharedState.profileManager.currentProfile.schoolGrade, sharedState.profileManager.currentProfile.subSchoolClass);
      // Set local state variables
      this.profileName = sharedState.profileManager.currentProfileName;
      courses = sharedState.profileManager.currentProfile.subjects;
      // Force update Schulmanager class name
      widget.sharedState.schulmanagerClassName = null;
      widget.sharedState.saveSchulmanagerClassName();
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
        setClassSelectionClass(sharedState.profileManager.currentProfile.schoolGrade!, sharedState.profileManager.currentProfile.subSchoolClass);
        courses = sharedState.profileManager.currentProfile.subjects;
        sharedState.profileManager.profiles.remove(toDeleteProfileName); // Remove profile
        // Force update Schulmanager class name
        widget.sharedState.schulmanagerClassName = null;
        widget.sharedState.saveSchulmanagerClassName();
      }
    });
  }

  void addProfile() {
    if (!validateClassSelection()) return;
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
            Stack(
              children: [
                HelpButton("Einstellungen", sharedState: sharedState),
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
                    ClassSelect(
                      initCallback: (validate, save, set) {
                        validateClassSelection = validate;
                        saveClassSelection = save;
                        setClassSelectionClass = set;
                      },
                      sharedState: sharedState,
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
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: Center(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Benachrichtigungen senden",
                                      style: GoogleFonts.poppins(
                                          color: sharedState.theme.textColor,
                                          fontWeight: FontWeight.normal,
                                          fontSize: 16.0),
                                    ),
                                    Text(
                                      "(Experimentell)",
                                      textAlign: TextAlign.start,
                                      style: GoogleFonts.poppins(
                                          color: sharedState.theme.textColor,
                                          fontWeight: FontWeight.w200,
                                          fontSize: 10.0),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Switch(
                                splashRadius: 0,
                                value: sendNotifications,
                                inactiveTrackColor: sharedState.theme.subjectSubstitutionColor,
                                activeColor: sharedState.theme.subjectColor,
                                thumbColor: MaterialStateProperty.resolveWith((states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return sharedState.theme.subjectColor;
                                  }
                                  return sharedState.theme.textColor;
                                }),
                                onChanged: (bool value) {
                                  setState(() {
                                    sendNotifications = value;
                                  });
                                }
                            ),
                          ],
                        )
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
                    if (!kReleaseMode || Constants.defineHasTesterFeature) Column(
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
                            "Testing",
                            style: GoogleFonts.poppins(
                                color: sharedState.theme.textColor.withAlpha(150),
                                fontWeight: FontWeight.bold,
                                fontSize: 22.0),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5.0),
                          child : StandardButton(
                            sharedState: sharedState,
                            text: "Show intro screen",
                            fontSize: 9.0,
                            textColor: sharedState.theme.textColor.withAlpha(150),
                            fontWeight: FontWeight.normal,
                            color: sharedState.theme.subjectDropOutColor,
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(builder: (context) => ClassSelectionPage(widget.sharedState)));
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5.0),
                          child: StandardButton(
                            sharedState: sharedState,
                            text: "Save snapshot",
                            fontSize: 9.0,
                            textColor: sharedState.theme.textColor.withAlpha(150),
                            fontWeight: FontWeight.normal,
                            color: sharedState.theme.subjectColor.withOpacity(0.6),
                            onPressed: () async {
                              await sharedState.saveSnapshot();
                            },
                          ),
                        ),
                      ],
                    ) else
                      Container(),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
