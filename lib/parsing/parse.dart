import 'dart:developer';

import 'package:html/dom.dart' as dom;
import 'package:http/http.dart'; // Contains a client for making API calls
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/content.dart';
import 'package:stundenplan/helper_functions.dart';
import 'package:stundenplan/parsing/parse_subsitution_plan.dart';
import 'package:stundenplan/parsing/parse_timetable.dart';
import 'package:stundenplan/shared_state.dart';

List<String> getRelevantSchoolClasses(SharedState sharedState) {
  final classes = [sharedState.profileManager.schoolClassFullName];
  if (!Constants.displayFullHeightSchoolGrades.contains(sharedState.profileManager.schoolGrade)) {
    classes.add("${sharedState.profileManager.schoolClassFullName}K");
  }
  if ((sharedState.hasChangedCourses || sharedState.processSpecialAGClass) && Constants.useAGs) classes.add(Constants.specialClassNameAG);
  return classes;
}

Future<void> parsePlans(SharedState sharedState) async {
  var content = Content(Constants.width, sharedState.height!);
  final client = Client();
  final schoolClasses = getRelevantSchoolClasses(sharedState);
  final List<String> mainAvailableSubjects = [];
  final List<List<dom.Element>?> classesTimeTables = [];
  List<String>? agAvailableClassSubjects;
  for (final schoolClassName in schoolClasses) {
    log("Parsing $schoolClassName time table", name: "parsing");
    final timeTables = await getTimeTableTables(schoolClassName, Constants.timeTableLinkBase, client);
    if (timeTables == null) continue;
    // Don't know why but for some reason main tables gets modified by getAvailableSubjectNames so we need to clone it.
    final classAvailableSubjects = getAvailableSubjectNames(timeTables.map((e) => e.clone(true)).toList());
    // Store special ag class subjects separately
    if (schoolClassName == Constants.specialClassNameAG) {
      agAvailableClassSubjects = classAvailableSubjects.toList(growable: false);
    }
    // Add class subject and timetables to lists
    mainAvailableSubjects.addAll(classAvailableSubjects);
    classesTimeTables.add(timeTables);
  }
  // Update the subjects that the user selected
  for (int i = 0; i < sharedState.profileManager.subjects.length; i++) {
    final subject = sharedState.profileManager.subjects[i];
    // Check how often the subject exists when ignoring capitalization in the timetable.
    final possibleSubjects = mainAvailableSubjects.where((element) => element.toLowerCase() == subject.toLowerCase());
    if (possibleSubjects.isEmpty) continue;
    if (possibleSubjects.length <= 1) {
      sharedState.profileManager.subjects[i] = possibleSubjects.single;
    } else {
      // Pick the subject that matches the closest with the inputted capitalization.
      final possibleSubjectList = possibleSubjects.toList();
      sharedState.profileManager.subjects[i] = findClosestStringInList(possibleSubjectList, subject);
    }
  }

  // Checks if the courses have changed flag is true, does some processing and then sets the flag to false
  if (sharedState.hasChangedCourses) {
    // Check if any of the subjects are in the special AG class, if not remember to not process this class until the courses change.
    // This is done to avoid unnecessary requests, which could slow down the app loading speeds
    if (agAvailableClassSubjects != null && sharedState.profileManager.subjects.any((subject) => agAvailableClassSubjects?.contains(subject) ?? false)) {
      sharedState.processSpecialAGClass = true;
    } else {
      sharedState.processSpecialAGClass = false;
    }
    sharedState.hasChangedCourses = false;
  }
  log("Writing to content", name: "parse");
  // Write time tables to content
  for (var i = 0; i < classesTimeTables.length; i++) {
    final classTimeTables = classesTimeTables[i];
    final schoolClassName = schoolClasses[i];
    // Fill class content
    final classTimeTableContent = Content(Constants.width, sharedState.height!);
    await fillTimeTable(schoolClassName, classTimeTables, classTimeTableContent, sharedState.allCurrentSubjects)
        .timeout(Constants.clientTimeout);
    // Set content (Or combine with it, if it is already set)
    if (i == 0) {
      content = classTimeTableContent;
    } else {
      log("Combining both tables", name: "parsing");
      content.combine(classTimeTableContent);
    }
  }
  log("content length : ${content.cells.length}", name: "parse");
  sharedState.content = content;
  log("Parsing substitution plan", name: "parsing");
  await overwriteContentWithSubstitutionPlan(sharedState, client, content, sharedState.allCurrentSubjects)
      .timeout(Constants.clientTimeout);
  sharedState.content = content;
}
