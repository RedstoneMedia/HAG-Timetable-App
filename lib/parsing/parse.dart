import 'package:http/http.dart'; // Contains a client for making API calls
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/content.dart';
import 'package:stundenplan/parsing/parse_subsitution_plan.dart';
import 'package:stundenplan/parsing/parse_timetable.dart';


Future<void> parsePlans(Content content, Constants constants) async {
  var client = Client();

  var allSubjects = new List<String>();
  // Add the subject that the user selected
  for (var subject in constants.subjects) {
    allSubjects.add(subject);
  }
  // Add the default subjects that can not be changed by the user
  for (var defaultSubject in constants.defaultSubjects) {
    allSubjects.add(defaultSubject);
  }

  var schoolClassName ="${constants.schoolGrade}${constants.subSchoolClass}";
  print("Parsing main time table");
  await fillTimeTable(schoolClassName, constants.timeTableLinkBase, client, content, allSubjects);
  print("Parsing course only time table");
  var courseTimeTableContent = new Content(constants.width, constants.height);
  await fillTimeTable("${constants.schoolGrade}K", constants.timeTableLinkBase, client, courseTimeTableContent, allSubjects);
  print("Combining both tables");
  content.combine(courseTimeTableContent);
  print("Parsing substitution plan");
  await overwriteContentWithSubsitutionPlan(constants, client, content, allSubjects, schoolClassName);

}

