import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:stundenplan/widgets/base_intro_screen.dart';
import 'package:stundenplan/widgets/course_select_list.dart';

import '../../main.dart';

class CourseListImportPage extends StatefulWidget {
  final SharedState sharedState;

  const CourseListImportPage(this.sharedState);

  @override
  _CourseListImportPageState createState() => _CourseListImportPageState();
}

class _CourseListImportPageState extends State<CourseListImportPage> {

  final ImagePicker picker = ImagePicker();
  final textDetector = GoogleMlKit.vision.textDetector();
  List<String> courses = [];

  @override
  void initState() {
    super.initState();
  }

  void saveDataToProfile() {
    setState(() {
      final coursesSet = widget.sharedState.profileManager.subjects.toSet();
      coursesSet.addAll(courses);
      widget.sharedState.profileManager.subjects = coursesSet.toList();
      widget.sharedState.saveState();
    });
  }

  Future<void> scan() async {
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    final inputImage = InputImage.fromFilePath(photo!.path);
    final RecognisedText recognisedText = await textDetector.processImage(inputImage);

    final headerLocations = <String, Rect>{};
    const headerNames = ["montag", "dienstag", "mittwoch", "donnerstag", "freitag"];
    final courseNamesCandidates = <String>{};
    for (final block in recognisedText.blocks) {
      final lowerCaseText = block.text.trim().toLowerCase();
      if (headerNames.contains(lowerCaseText)) {
        headerLocations[lowerCaseText] = block.rect;
      } else {
        final regExpr = RegExp(r"^[a-zA-Z]{2}([0-9]|[a-zA-Z])$");
        if (regExpr.hasMatch(block.text.trim())) {
          courseNamesCandidates.add(block.text.trim());
        }
      }
    }
    if (headerLocations.length == headerNames.length) {
      log(courseNamesCandidates.join(" "), name: "scan");
      setState(() {
        courses = courseNamesCandidates.toList();
      });
    } else {
      log("Could not detect the table", name: "scan");
    }

    // TODO : Only add courses that exist in the current class and if they do not exists try to find the closest matching course if it is only off by one letter
  }

  @override
  Widget build(BuildContext context) {
    return BaseIntroScreen(
        sharedState: widget.sharedState,
        onPressed: () {
          saveDataToProfile();
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => MyApp(widget.sharedState)));
        },
        subtitle: "Mach ein Foto von deinem Stundenplan",
        title: "Scanen",
        noButton: courses.isEmpty,
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
              onPressed: scan,
              child: Text(
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
