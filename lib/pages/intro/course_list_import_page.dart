import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stundenplan/helper_functions.dart';
import 'package:stundenplan/main.dart';
import 'package:stundenplan/parsing/parse_timetable.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:stundenplan/widgets/base_intro_screen.dart';
import 'package:stundenplan/widgets/course_select_list.dart';


class CourseListImportPage extends StatefulWidget {
  final SharedState sharedState;

  const CourseListImportPage(this.sharedState);

  @override
  _CourseListImportPageState createState() => _CourseListImportPageState();
}

const String introScreenCourseListImportPageSubtitle = "Mach ein Foto von deinem Stundenplan";

class _CourseListImportPageState extends State<CourseListImportPage> {

  final ImagePicker picker = ImagePicker();
  final textRecognizer = TextRecognizer();
  String subtitle = introScreenCourseListImportPageSubtitle;
  List<String> courses = [];
  List<String> availableCourses = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    getAvailableCourses();
  }

  Future<void> getAvailableCourses() async {
    final client = Client();
    final fullSchoolGradeName = widget.sharedState.profileManager.schoolClassFullName;
    availableCourses = await getAllAvailableSubjects(client, fullSchoolGradeName, widget.sharedState.profileManager.schoolGrade!);
  }

  void saveDataToProfile() {
    setState(() {
      final coursesSet = widget.sharedState.profileManager.subjects.toSet();
      coursesSet.addAll(courses);
      widget.sharedState.profileManager.subjects = coursesSet.toList();
      widget.sharedState.saveState();
    });
  }

  String? getCorrectCourseName(String courseName) {
    if (availableCourses.isEmpty) {
      return courseName;
    }
    if (availableCourses.contains(courseName)) {
      return courseName;
    }
    final closestAvailableCourseName = findClosestStringInList(availableCourses, courseName);
    final wrongLettersCount = (getRightLettersCount(courseName, closestAvailableCourseName) - closestAvailableCourseName.length).abs();
    if (wrongLettersCount <= 1) {
      return closestAvailableCourseName;
    }
  }

  Future<void> scan() async {
    setState(() {
      loading = true;
    });
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo == null) {
      setState(() {
        loading = false;
      });
      return;
    }
    final inputImage = InputImage.fromFilePath(photo.path);
    final RecognizedText recognisedText = await textRecognizer.processImage(inputImage);
    

    final headerLocations = <String, Rect>{};
    const headerNames = ["montag", "dienstag", "mittwoch", "donnerstag", "freitag"];
    final courseNamesCandidates = <String>{};
    for (final block in recognisedText.blocks) {
      final lowerCaseText = block.text.trim().toLowerCase();
      if (headerNames.contains(lowerCaseText)) {
        headerLocations[lowerCaseText] = block.boundingBox;
      } else {
        final regExpr = RegExp(r"^[a-zA-Z]{2}([0-9]|[a-zA-Z])$");
        if (regExpr.hasMatch(block.text.trim())) {
          courseNamesCandidates.add(block.text.trim());
        }
      }
    }

    if (headerLocations.length == headerNames.length) {
      setState(() {
        subtitle = introScreenCourseListImportPageSubtitle;
      });
    } else {
      setState(() {
        subtitle = "Es gab einen Fehler, probiere es bitte noch einmal.\n\nAlles, also auch die Kopfzeile mit \"Montag\" \"Dienstag\" \"Mittwoch\" usw. muss zu sehen sein.";
      });
      log("Could not detect the table", name: "scan");
      setState(() {
        loading = false;
      });
      return;
    }

    // Only add courses that exist in the current class and if they do not exists try to find the closest matching course if it is only off by one letter
    courses = [];
    for (final course in courseNamesCandidates.toList()) {
      final correctCourseName = getCorrectCourseName(course);
      if (correctCourseName != null) {
        courses.add(correctCourseName);
      }
    }
    log("Found courses : ${courses.join(" ")}", name: "scan");
    setState(() {
      courses = courses;
    });
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseIntroScreen(
        sharedState: widget.sharedState,
        onPressed: () {
          saveDataToProfile();
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => MyApp(widget.sharedState)));
        },
        subtitle: subtitle,
        title: "Scanen",
        noButton: courses.isEmpty,
        helpPage: "Set-Up#automatisch",
        child: Column(
          children: [
            ElevatedButton(
              style: ButtonStyle(
                padding: MaterialStateProperty.all(const EdgeInsets.all(10.0)),
                backgroundColor: MaterialStateProperty.all<Color>(widget.sharedState.theme.subjectColor),
                shape: MaterialStateProperty.all<OutlinedBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              onPressed: !loading ? scan : () {},
              child: loading ? CircularProgressIndicator(color: widget.sharedState.theme.textColor,) : Text(
                courses.isNotEmpty ? "Neues Foto Machen" : "Foto Machen",
                style: GoogleFonts.poppins(
                  color: widget.sharedState.theme.textColor,
                  fontSize: 26.0,
                  fontWeight: FontWeight.bold
                )
              ),
            ),
            const SizedBox(height: 15),
            if (courses.isNotEmpty) SizedBox(
              height: MediaQuery.of(context).size.height * 0.42,
              child: ListView(
                children: [
                  CourseSelectList(
                    widget.sharedState,
                    courses,
                  ),
                ],
              ),
            ) else Container(),
          ],
        )
    );
  }
}
