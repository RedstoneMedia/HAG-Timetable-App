import 'dart:io';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:collection/collection.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/content.dart';
import 'package:stundenplan/helper_functions.dart';
import 'package:stundenplan/integration.dart';
import 'package:stundenplan/parsing/parse.dart';
import 'package:stundenplan/parsing/parse_subsitution_plan.dart';
import 'package:stundenplan/parsing/parsing_util.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:stundenplan/week_subsitutions.dart';
import 'package:tuple/tuple.dart';
import 'package:workmanager/workmanager.dart';

Future<FlutterLocalNotificationsPlugin> initializeFlutterLocalNotifications() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  return flutterLocalNotificationsPlugin;
}

NotificationDetails getNotificationDetails() {
  const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'timetable_notifications',
      'Stundenplan Benachrichtigungen',
      channelDescription: 'Wenn Änderungen im Stunden- oder Vertretungsplan vorhanden sind, gibt es eine Benachrichtigung',
      priority: Priority.high,
      importance: Importance.high
  );
  return const NotificationDetails(android: androidPlatformChannelSpecifics);
}

Tuple2<String, String>? getSubstitutionsNotificationText(Map<String, dynamic> substitutionsBeforeJson, Map<String, dynamic> substitutionsJson) {
  final changes = <Tuple3<int, bool, Map<String, dynamic>>>[];
  // Merge old substitution with current substitutions, to find out what substitutions end up to be new, when merged.
  final weekSubstitutionsBefore1 = WeekSubstitutions(substitutionsBeforeJson, "before", checkWeekDay: false, checkWeek: false);
  final weekSubstitutions = WeekSubstitutions(substitutionsJson, "now", checkWeekDay: false, checkWeek: false);
  weekSubstitutionsBefore1.merge(weekSubstitutions, "now");
  for (final substitution in weekSubstitutionsBefore1.weekSubstitutions!.entries) {
    final weekDay = DateTime.parse(substitution.value.item2).weekday;
    final daySubstitutions = substitution.value.item1;
    changes.addAll(daySubstitutions.where((e) => e.item2 == "now")
        .map((e) => Tuple3(weekDay, true, e.item1)));
  }
  // Merge old substitution with current substitutions, but overwriting old substitutions, with new ones, even if they are the same, to see what substitutions are old, and not present in the current substitutions anymore (when a substitution gets revoked)
  final weekSubstitutionsBefore2 = WeekSubstitutions(substitutionsBeforeJson, "before", checkWeekDay: false, checkWeek: false);
  weekSubstitutionsBefore2.merge(weekSubstitutions, "now", overwriteEqual: true);
  for (final substitution in weekSubstitutionsBefore2.weekSubstitutions!.entries) {
    final weekDay = DateTime.parse(substitution.value.item2).weekday;
    final daySubstitutions = substitution.value.item1;
    changes.addAll(daySubstitutions.where((e) => e.item2 == "before")
        .map((e) => Tuple3(weekDay, false, e.item1)));
  }
  final now = clock.now();
  final currentWeekday = now.weekday;
  // Construct a title, and content for each change and sort them by importance (lower is more important)
  final changeTexts = <Tuple3<String, String, int>>[];
  for (final change in changes) {
    final substitution = change.item3;
    final revertedChange = !change.item2;
    if (revertedChange) continue; // Temporary "fix" to somewhat reduce duplicate notifications
    // Get the text to describe the day of the change
    String dayText = "";
    if (currentWeekday - change.item1 == 0) {
      dayText = "Heute";
    } else if (currentWeekday - change.item1 == 1) {
      dayText = "Morgen";
    } else {
      switch (change.item1) {
        case 1:
          dayText = "Montag";
          break;
        case 2:
          dayText = "Dienstag";
          break;
        case 3:
          dayText = "Mittwoch";
          break;
        case 4:
          dayText = "Donnerstag";
          break;
        case 5:
          dayText = "Freitag";
          break;
      }
    }
    String? originalSubject = substitution["statt Fach"] as String?;
    if (originalSubject == "---") originalSubject = null;
    final anchorText = originalSubject ?? substitution["Stunde"]; // Text that specifies what lesson or time frame the change is targeting (aka something, where the user can directly infer, when the change is happening)
    final substitutionTextMessage = customStrip(substitution["Text"] as String? ?? "").isNotEmpty && substitution["Text"] != "---" && !revertedChange ? '\nText: "${(substitution["Text"] as String).truncate(80)}"' : "";
    // Handle dropped lessons
    final String isDropped = substitution["Entfall"] as String? ?? "";
    if (isDropped == "x") {
      changeTexts.add(Tuple3(
          "$anchorText fällt${revertedChange ? " nicht" : ""} aus",
          "$dayText fällt $anchorText${revertedChange ? " doch nicht" : ""} aus$substitutionTextMessage",
          revertedChange ? 0 : 1)
      );
    } else if (substitution["Fach"] != substitution["statt Fach"] && substitution.containsKey("Fach") && substitution.containsKey("statt Fach")) {
      final newSubject = substitution["Fach"];
      changeTexts.add(Tuple3(
          originalSubject != null
              ? "${revertedChange ? "nicht " : ""}$newSubject anstatt $anchorText"
              : "${revertedChange ? "nicht " : ""}$newSubject in der $anchorText",
          originalSubject != null
              ? "$dayText findet statt $anchorText${revertedChange ? ", doch nicht" : ""}, $newSubject statt$substitutionTextMessage"
              : "$dayText findet${revertedChange ? " doch nicht" : ""} $newSubject in der $anchorText statt$substitutionTextMessage",
          revertedChange ? 2 : 3)
      );
    } else if (substitution["Raum"] != substitution["statt Raum"] && substitution.containsKey("Raum") && substitution.containsKey("statt Raum")) {
      final newRoom = substitution["Raum"];
      changeTexts.add(Tuple3(
          "${revertedChange ? "nicht " : ""}$anchorText in $newRoom",
          "$dayText findet $anchorText${revertedChange ? ", doch nicht" : ""} in $newRoom, anstatt in Raum ${substitution["statt Raum"]} statt$substitutionTextMessage",
          revertedChange ? 4 : 5)
      );
    } else if (substitution["Vertretung"] != substitution["statt Lehrer"] && substitution.containsKey("Vertretung") && substitution.containsKey("statt Lehrer")) {
      final newTeacher = substitution["Vertretung"];
      changeTexts.add(Tuple3(
          "$anchorText ${revertedChange ? "nicht " : ""}mit $newTeacher",
          "$anchorText wird $dayText von $newTeacher, anstatt von ${substitution["statt Lehrer"]} unterrichtet$substitutionTextMessage",
          revertedChange ? 4 : 5)
      );
    }
  }
  changeTexts.sort((a, b) => a.item2.compareTo(b.item2));
  if (changeTexts.isEmpty) return null;
  final mostImportantChange = changeTexts.first;
  return Tuple2(mostImportantChange.item1, "${mostImportantChange.item2}${changeTexts.length > 1 ? "\nZudem ${changeTexts.length - 1} weitere Änderung im Veretungsplan" : ""}");
}

/// Remove subjects that the user dose not have from the old substitutions (sometimes kinda redundant), strip certain properties and remove days that don't fit in the current timeframe
void cleanupWeekSubstitutionJson(Map<String, dynamic> substitutionsJson, List<String> allSubjects) {
  final now = clock.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekStartEndDates = getCurrentWeekStartEndDates();
  final weekStartDate = weekStartEndDates.item1;
  final weekEndDate = weekStartEndDates.item2;
  // Remove passed days or days, that are not in the current week
  substitutionsJson.removeWhere((key, value) {
    final date = DateTime.parse((value as List<dynamic>)[1] as String);
    return !(
        (date.isAfter(weekStartDate) || date.isAtSameMomentAs(weekStartDate))
        && (date.isAfter(today) || date.isAtSameMomentAs(today))
        && (date.isBefore(weekEndDate) || date.isAtSameMomentAs(weekEndDate))
    );
  });
  // Remove unsuited substitutions and strip their properties
  substitutionsJson.forEach((key, value) => ((value as List<dynamic>)[0] as List<dynamic>).removeWhere((substitution) {
    final substitutionMap = substitution as Map<String, dynamic>;
    // Strip properties
    substitutionMap["Fach"] = customStrip(substitutionMap["Fach"] as String);
    substitutionMap["Raum"] = customStrip(substitutionMap["Raum"] as String);
    substitutionMap["statt Raum"] = customStrip(substitutionMap["statt Raum"] as String);
    substitutionMap["statt Lehrer"] = customStrip(substitutionMap["statt Lehrer"] as String);
    substitutionMap["Vertretung"] = customStrip(substitutionMap["Vertretung"] as String);
    substitutionMap["Raum"] = customStrip(substitutionMap["Raum"] as String);
    substitutionMap["Entfall"] = customStrip(substitutionMap["Entfall"] as String);
    // Remove subjects that the user dose not have
    final originalSubject = customStrip(substitutionMap["statt Fach"] as String);
    substitutionMap["statt Fach"] = originalSubject;
    return originalSubject != "\u{00A0}" && !allSubjects.contains(originalSubject);
  }));
}

void callbackDispatcher() {
  Workmanager().executeTask((task, _inputData) async {
    // Initialize plugins
    SharedPreferencesAndroid.registerWith();
    final preferences = await SharedPreferences.getInstance();
    final notifyPlugin = await initializeFlutterLocalNotifications();
    // Initialize shared state
    final sharedState = SharedState(preferences, Content(Constants.width, Constants.defaultHeight));
    if (sharedState.loadStateAndCheckIfFirstTime(fromBackgroundTask: true)) return false; // Should not happen
    if (!sharedState.sendNotifications) return true; // Notifications are turned off
    final allSubjects = sharedState.allCurrentSubjects;
    // Load previous substitutions and content from cache
    (Integrations.instance.getIntegrationByName("IServ")! as IServUnitsSubstitutionIntegration).loadCheckWeekDay = false;
    (Integrations.instance.getIntegrationByName("Schulmanager")! as SchulmanagerIntegration).loadCheckWeekDay = false;
    sharedState.loadCache();
    final substitutionsBefore = Integrations.instance.getValue("substitutions") as WeekSubstitutions?;
    if (substitutionsBefore == null) return true;
    final substitutionsBeforeJson = substitutionsBefore.toJson();
    cleanupWeekSubstitutionJson(substitutionsBeforeJson, allSubjects);

    sharedState.content.lastUpdated = DateTime(0);
    final contentBeforeJson = sharedState.content.toJsonData();
    // Parse the substitution and timetable
    await parsePlans(sharedState);
    final substitutions = Integrations.instance.getValue("substitutions") as WeekSubstitutions?;
    if (substitutions == null) return false;
    final substitutionsJson = substitutions.toJson();
    cleanupWeekSubstitutionJson(substitutionsJson, allSubjects);
    // Send the notifications based on what changed
    sharedState.content.lastUpdated = DateTime(0);
    final NotificationDetails platformChannelSpecifics = getNotificationDetails();
    if (!const DeepCollectionEquality().equals(substitutionsBeforeJson, substitutionsJson)) {
      sharedState.content.updateLastUpdated();
      sharedState.saveCache();
      final notificationText = getSubstitutionsNotificationText(substitutionsBeforeJson, substitutionsJson);
      if (notificationText != null) {
        await notifyPlugin.show(Random().nextInt(2147483647), notificationText.item1, notificationText.item2, platformChannelSpecifics);
        return true;
      }
    }
    if (!const DeepCollectionEquality().equals(contentBeforeJson, sharedState.content.toJsonData())) {
      sharedState.content.updateLastUpdated();
      sharedState.saveCache();
      await notifyPlugin.show(Random().nextInt(2147483647), 'Stundenplan Änderungen', 'Es gibt Änderungen im Stundenplan die dich betreffen', platformChannelSpecifics);
    }
    return true;
  });
}

Future<void> initializeNotifications() async {
  if (!Platform.isAndroid) return;
  await Workmanager().initialize(
      callbackDispatcher
  );
}

Future<void> startNotificationTask() async {
  if (!Platform.isAndroid) return;
  await Workmanager().registerPeriodicTask(
    "1",
    "timetableNotificationTask",
    frequency: const Duration(minutes: 15),
    existingWorkPolicy: ExistingWorkPolicy.keep,
    initialDelay: const Duration(seconds: 10),
    backoffPolicy: BackoffPolicy.linear,
    backoffPolicyDelay: const Duration(minutes: 5),
    inputData: {},
    constraints: Constraints(
      networkType: NetworkType.not_roaming,
      requiresBatteryNotLow: true
    ),
  );
}

Future<void> stopNotificationTask() async {
  if (!Platform.isAndroid) return;
  await Workmanager().cancelByUniqueName("1");
}

