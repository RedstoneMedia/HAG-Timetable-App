import 'dart:developer';

import 'package:http/http.dart'; // Contains a client for making API calls
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/content.dart';
import 'package:stundenplan/parsing/parse_subsitution_plan.dart';
import 'package:stundenplan/parsing/parse_timetable.dart';
import 'package:stundenplan/shared_state.dart';

Future<void> parsePlans(Content content, SharedState sharedState) async {
  final client = Client();
  final allSubjects = <String>[];
  // Add the subject that the user selected
  for (final subject in sharedState.profileManager.subjects) {
    allSubjects.add(subject);
  }
  // Add the default subjects that can not be changed by the user
  for (final defaultSubject in sharedState.defaultSubjects) {
    allSubjects.add(defaultSubject);
  }

  final schoolClassName = "${sharedState.profileManager.schoolGrade}${sharedState.profileManager.subSchoolClass}";
  log("Parsing main time table", name: "parsing");
  await fillTimeTable(schoolClassName, Constants.timeTableLinkBase, client, content, allSubjects)
      .timeout(Constants.clientTimeout);

  if (!Constants.displayFullHeightSchoolGrades.contains(sharedState.profileManager.schoolGrade)) {
    log("Parsing course only time table", name: "parsing");
    final courseTimeTableContent = Content(Constants.width, sharedState.height!);
    await fillTimeTable(
            "${sharedState.profileManager.schoolGrade}K",
            Constants.timeTableLinkBase,
            client,
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
