import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stundenplan/shared_state.dart';

import '../constants.dart';

class ClassSelect extends StatefulWidget {
  final SharedState sharedState;
  final bool vertical;
  final void Function(bool Function(), bool Function(), void Function(String?, String)) initCallback;

  const ClassSelect({required this.initCallback, required this.sharedState, this.vertical = false});

  @override
  State<ClassSelect> createState() => _ClassSelectState();
}

class _ClassSelectState extends State<ClassSelect> {
  late SharedState sharedState;

  List<String> grades = Constants.schoolGrades;
  String? schoolGrade;
  String? subSchoolClass;
  TextEditingController subClassTextEditingController = TextEditingController();
  bool? subSchoolClassEnabled;
  bool subSchoolClassIsCorrect = true;
  bool schoolClassIsCorrect = true;

  /// Checks if the sub class text field matches the regex and if the school grade ist set and sets the correctness flag, to display an error.
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
    final text = subClassTextEditingController.text;
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

  /// Sets input school grade and sets if the sub class input field should be disabled accordingly.
  void setSchoolGrade(String? schoolGrade) {
    setState(() {
      this.schoolGrade = schoolGrade;
      if (this.schoolGrade != null) schoolClassIsCorrect = true;
      if (Constants.displayFullHeightSchoolGrades.contains(schoolGrade)) {
        subClassTextEditingController.text = "";
        subSchoolClassEnabled = false;
      } else {
        subSchoolClassEnabled = true;
      }
    });
  }

  void onSchoolClassChanged() {
    // Force the schulmanger to refresh the current school class
    widget.sharedState.schulmanagerClassName = null;
    widget.sharedState.saveSchulmanagerClassName();
  }

  bool save() {
    if (!validateClassInput()) return false;
    if (schoolGrade != sharedState.profileManager.schoolGrade) onSchoolClassChanged();
    sharedState.profileManager.schoolGrade = schoolGrade;

    if (Constants.displayFullHeightSchoolGrades.contains(schoolGrade)) {
      if ("" != sharedState.profileManager.subSchoolClass) onSchoolClassChanged();
      sharedState.profileManager.subSchoolClass = "";
      widget.sharedState.height = Constants.fullHeight;
    } else {
      if (subClassTextEditingController.text != sharedState.profileManager.subSchoolClass) onSchoolClassChanged();
      sharedState.profileManager.subSchoolClass = subClassTextEditingController.text;
      widget.sharedState.height = Constants.defaultHeight;
    }
    return true;
  }

  void setClass(String? schoolGrade, String subSchoolClass) {
    setState(() {
      subClassTextEditingController.text = subSchoolClass;
      schoolClassIsCorrect = true;
      subSchoolClassIsCorrect = true;
    });
    setSchoolGrade(schoolGrade);
  }

  @override
  void initState() {
    super.initState();
    sharedState = widget.sharedState;
    schoolGrade = sharedState.profileManager.schoolGrade;
    subClassTextEditingController.text = sharedState.profileManager.subSchoolClass;
    subSchoolClassEnabled = !Constants.displayFullHeightSchoolGrades.contains(schoolGrade);

    widget.initCallback(validateClassInput, save, setClass);
  }

  @override
  Widget build(BuildContext context) {
    var children = [
      Padding(
        padding: widget.vertical ? EdgeInsets.zero : const EdgeInsets.all(12.0),
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
              itemHeight: widget.vertical ? 58 : null,
              isExpanded: widget.vertical,
              value: schoolGrade,
              icon: const Icon(Icons.keyboard_arrow_down),
              elevation: 16,
              dropdownColor:
              sharedState.theme.textColor.withAlpha(255),
              style: TextStyle(
                  color: sharedState.theme.invertedTextColor,
                  fontSize: widget.vertical ? 30 : 16
              ),
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
                      style: GoogleFonts.poppins(fontSize: widget.vertical ? 30 : 16),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      SizedBox(height: widget.vertical ? 15 : 0),
      Container(
        width: widget.vertical ? null : 60,
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
          child: SizedBox(
            height: widget.vertical ? 58 : null,
            child: TextField(
              enabled: subSchoolClassEnabled,
              controller: subClassTextEditingController,
              style: GoogleFonts.poppins(color: sharedState.theme.invertedTextColor, fontSize: widget.vertical ? 30 : 16),
              decoration: InputDecoration(
                hintText: "a",
                border: widget.vertical ? InputBorder.none : null,
                hintStyle: GoogleFonts.poppins(
                    fontSize: widget.vertical ? 30 : 16,
                    color: sharedState.theme.invertedTextColor.withAlpha(80)),
              ),
            ),
          ),
        ),
      ),
    ];
    return widget.vertical ? SizedBox(width: 140, child: Column(children: children)) : Row(mainAxisAlignment: MainAxisAlignment.center, children: children);
  }
}
