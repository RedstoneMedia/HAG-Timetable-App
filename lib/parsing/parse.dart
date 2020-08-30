import 'package:http/http.dart'; // Contains a client for making API calls
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/content.dart';
import 'package:stundenplan/parsing/parse_subsitution_plan.dart';
import 'package:stundenplan/parsing/parse_timetable.dart';
import 'package:stundenplan/shared_state.dart';


Future<void> parsePlans(Content content, SharedState sharedState) async {
  var client = Client();

  var allSubjects = new List<String>();
  // Add the subject that the user selected
  for (var subject in sharedState.subjects) {
    allSubjects.add(subject);
  }
  // Add the default subjects that can not be changed by the user
  for (var defaultSubject in Constants.defaultSubjects) {
    allSubjects.add(defaultSubject);
  }

  var schoolClassName ="${sharedState.schoolGrade}${sharedState.subSchoolClass}";
  print("Parsing main time table");
  await fillTimeTable(schoolClassName, Constants.timeTableLinkBase, client, content, allSubjects);
  print("Parsing course only time table");
  var courseTimeTableContent = new Content(Constants.width, Constants.height);
  await fillTimeTable("${sharedState.schoolGrade}K", Constants.timeTableLinkBase, client, courseTimeTableContent, allSubjects);
  print("Combining both tables");
  content.combine(courseTimeTableContent);
  print("Parsing substitution plan");
  await overwriteContentWithSubsitutionPlan(sharedState, client, content, allSubjects, schoolClassName);
}

