import 'dart:developer';

import 'package:http/http.dart'; // Contains a client for making API calls
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/content.dart';
import 'package:stundenplan/helper_functions.dart';
import 'package:stundenplan/parsing/parse_subsitution_plan.dart';
import 'package:stundenplan/parsing/parse_timetable.dart';
import 'package:stundenplan/shared_state.dart';


Future<void> parsePlans(Content content, SharedState sharedState) async {
  final client = Client();
  final schoolClassName = "${sharedState.profileManager.schoolGrade}${sharedState.profileManager.subSchoolClass}";

  log("Parsing main time table", name: "parsing");
  final mainTables = await getTimeTableTables(schoolClassName, Constants.timeTableLinkBase, client);
  // Don't know why but for some reason main tables gets modified by getAvailableSubjectNames so we need to clone it.
  final mainAvailableSubjects = getAvailableSubjectNames(mainTables!.map((e) => e.clone(true)).toList());

  final allSubjects = <String>[];
  // Add the subject that the user selected
  for (final subject in sharedState.profileManager.subjects) {
    // Check how often the subject exists when ignoring capitalization in the timetable.
    final possibleSubjects = mainAvailableSubjects.where((element) => element.toLowerCase() == subject.toLowerCase());
    if (possibleSubjects.isEmpty) continue;
    if (possibleSubjects.length <= 1) {
      allSubjects.add(possibleSubjects.single);
    } else {
      // Pick the subject that matches the closest with the inputted capitalization.
      final possibleSubjectList = possibleSubjects.toList();
      allSubjects.add(findClosestStringInList(possibleSubjectList, subject));
    }
  }
  // Add the default subjects that can not be changed by the user
  for (final defaultSubject in sharedState.defaultSubjects) {
    allSubjects.add(defaultSubject);
  }

  log("content length : ${content.cells.length}", name: "parse");
  await fillTimeTable(schoolClassName, mainTables, content, allSubjects)
      .timeout(Constants.clientTimeout);

  if (!Constants.displayFullHeightSchoolGrades.contains(sharedState.profileManager.schoolGrade)) {
    final courseName = "${sharedState.profileManager.schoolGrade}K";
    log("Parsing course only time table", name: "parsing");
    final courseTables = await getTimeTableTables(courseName, Constants.timeTableLinkBase, client);
    final courseTimeTableContent = Content(Constants.width, sharedState.height!);
    await fillTimeTable(
            courseName,
            courseTables,
            courseTimeTableContent,
            allSubjects)
        .timeout(Constants.clientTimeout);
    log("Combining both tables", name: "parsing");
    content.combine(courseTimeTableContent);
  }
  log("Parsing substitution plan", name: "parsing");
  await overwriteContentWithSubsitutionPlan(sharedState, client, content, allSubjects, schoolClassName)
      .timeout(Constants.clientTimeout);
}
