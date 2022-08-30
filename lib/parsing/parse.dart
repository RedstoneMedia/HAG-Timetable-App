import 'dart:developer';

import 'package:html/dom.dart' as dom;
import 'package:http/http.dart'; // Contains a client for making API calls
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/content.dart';
import 'package:stundenplan/helper_functions.dart';
import 'package:stundenplan/parsing/parse_subsitution_plan.dart';
import 'package:stundenplan/parsing/parse_timetable.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:tuple/tuple.dart';

List<String> getRelevantSchoolClasses(SharedState sharedState) {
  final classes = [sharedState.profileManager.schoolClassFullName];
  if (!Constants.displayFullHeightSchoolGrades.contains(sharedState.profileManager.schoolGrade) &&
      (sharedState.processSpecialCourseClass || sharedState.hasChangedCourses)
  ) {
    classes.add("${sharedState.profileManager.schoolGrade}K");
  }
  if ((sharedState.hasChangedCourses || sharedState.processSpecialAGClass) && Constants.useAGs) classes.add(Constants.specialClassNameAG);
  return classes;
}

Future<void> parsePlans(SharedState sharedState) async {
  var content = Content(Constants.width, sharedState.height!);
  final client = Client();
  final schoolClasses = getRelevantSchoolClasses(sharedState);
  final List<String> mainAvailableSubjects = [];
  final List<Tuple2<List<dom.Element>, String>> classesTimeTables = [];
  List<String>? agAvailableClassSubjects;
  // Get the time tables for each class
  for (final schoolClassName in schoolClasses) {
    log("Parsing $schoolClassName time table", name: "parsing");
    final getTimeTablesResult = await getTimeTableTables(schoolClassName, Constants.timeTableLinkBase, client);
    final timeTables = getTimeTablesResult.item1;
    // Check if special course class was not found, if so don't attempt to get data from this class anymore, since it does not exist.
    if (timeTables == null) {
      if (getTimeTablesResult.item2 == GetTileTablesResponse.notFound &&
          schoolClassName == "${sharedState.profileManager.schoolGrade}K"
      ) sharedState.processSpecialCourseClass = false;
      continue; // Always skip empty timeTables, as the cannot be parsed
    }
    if (schoolClassName == "${sharedState.profileManager.schoolGrade}K") sharedState.processSpecialCourseClass = true;
    // Don't know why but for some reason main tables gets modified by getAvailableSubjectNames so we need to clone it.
    final classAvailableSubjects = getAvailableSubjectNames(timeTables.map((e) => e.clone(true)).toList());
    // Store special ag class subjects separately
    if (schoolClassName == Constants.specialClassNameAG) {
      agAvailableClassSubjects = classAvailableSubjects.toList(growable: false);
    }
    // Add class subject and timetables to lists
    mainAvailableSubjects.addAll(classAvailableSubjects);
    classesTimeTables.add(Tuple2(timeTables, schoolClassName));
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
    final classTimeTables = classesTimeTables[i].item1;
    final schoolClassName = classesTimeTables[i].item2;
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
