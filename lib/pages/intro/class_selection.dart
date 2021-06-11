import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/pages/intro/theme_selection.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:stundenplan/widgets/base_intro_screen.dart';

class ClassSelectionPage extends StatefulWidget {
  final SharedState sharedState;

  const ClassSelectionPage(this.sharedState);

  @override
  _ClassSelectionPageState createState() => _ClassSelectionPageState();
}

class _ClassSelectionPageState extends State<ClassSelectionPage> {
  String schoolGrade = "11";
  bool subSchoolClassEnabled = true;
  bool subSchoolClassIsCorrect = true;
  TextEditingController subClassTextEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    schoolGrade = widget.sharedState.profileManager.schoolGrade;
    subClassTextEditingController.text = widget.sharedState.profileManager.subSchoolClass;
  }

  /// Sets input school grade and sets if the sub class input field should be disabled accordingly.
  void setSchoolGrade(String schoolGrade) {
    setState(() {
      this.schoolGrade = schoolGrade;
      if (Constants.displayFullHeightSchoolGrades.contains(schoolGrade)) {
        subClassTextEditingController.text = "";
        subSchoolClassEnabled = false;
      } else {
        subSchoolClassEnabled = true;
      }
    });
  }

  /// Checks if the sub class text field matches the regex and sets the correctness flag, to display an error.
  bool validateSubClassInput() {
    if (!subSchoolClassEnabled) return true;
    final text = subClassTextEditingController.text;
    final regExp = RegExp(r"^[a-zA-Z]{0,3}\d{0,2}$");
    final hasMatch = regExp.hasMatch(text);
    if (hasMatch) {
      setState(() {
        subSchoolClassIsCorrect = true;
      });
      return true;
    }
    setState(() {
      subSchoolClassIsCorrect = false;
    });
    return false;
  }

  /// Saves the school grade and sub school class in the current profile and sets the height.
  void saveDataToProfile() {
    widget.sharedState.profileManager.schoolGrade = schoolGrade;

    if (Constants.displayFullHeightSchoolGrades.contains(schoolGrade)) {
      widget.sharedState.profileManager.subSchoolClass = "";
      widget.sharedState.height = Constants.fullHeight;
    } else {
      widget.sharedState.profileManager.subSchoolClass = subClassTextEditingController.text;
      widget.sharedState.height = Constants.defaultHeight;
    }

    widget.sharedState.saveState();
  }

  @override
  Widget build(BuildContext context) {
    return BaseIntroScreen(
        sharedState: widget.sharedState,
        onPressed: () {
          if (validateSubClassInput()) {
            saveDataToProfile();
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => ThemeSelectionPage(widget.sharedState)));
          }
        },
        subtitle: "In welcher Klasse bist du ?",
        title: "Klasse",
        child: SizedBox(
          width: 140,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: widget.sharedState.theme.textColor.withAlpha(200),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: schoolGrade,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    elevation: 16,
                    dropdownColor: widget.sharedState.theme.textColor.withAlpha(255),
                    style: TextStyle(color: widget.sharedState.theme.invertedTextColor),
                    underline: Container(),
                    onChanged: (String? newValue) {
                      setSchoolGrade(newValue!);
                    },
                    items: Constants.schoolGrades.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: Text(
                            value,
                            style: GoogleFonts.poppins(fontSize: 30.0),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Container(
                decoration: BoxDecoration(
                  color: subSchoolClassEnabled
                      ? widget.sharedState.theme.textColor.withAlpha(200)
                      : widget.sharedState.theme.textColor.withAlpha(100),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      color: subSchoolClassIsCorrect ? Colors.transparent : Colors.red,
                      width: subSchoolClassIsCorrect ? 0 : 2.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: TextField(
                    enabled: subSchoolClassEnabled,
                    controller: subClassTextEditingController,
                    style: GoogleFonts.poppins(color: widget.sharedState.theme.invertedTextColor, fontSize: 30.0),
                    decoration: InputDecoration(
                      hintText: "a",
                      hintStyle: GoogleFonts.poppins(
                          color: widget.sharedState.theme.invertedTextColor.withAlpha(80), fontSize: 30.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
    );
  }
}
