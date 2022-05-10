import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/content.dart';
import 'package:stundenplan/integration.dart';
import 'package:stundenplan/parsing/parse.dart';
import 'package:stundenplan/parsing/parse_subsitution_plan.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:stundenplan/week_subsitutions.dart';
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

void callbackDispatcher() {
  Workmanager().executeTask((task, _inputData) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Initialize plugins
    SharedPreferencesAndroid.registerWith();
    final preferences = await SharedPreferences.getInstance();
    final notifyPlugin = await initializeFlutterLocalNotifications();
    // Initialize shared state
    final sharedState = SharedState(preferences, Content(Constants.width, Constants.defaultHeight));
    if (sharedState.loadStateAndCheckIfFirstTime()) return false; // Should not happen
    if (!sharedState.sendNotifications) return true; // Notifications are turned off
    // Load previous substitutions and content from cache
    (Integrations.instance.getIntegrationByName("IServ")! as IServUnitsSubstitutionIntegration).loadCheckWeekDay = false;
    (Integrations.instance.getIntegrationByName("Schulmanger")! as SchulmangerIntegration).loadCheckWeekDay = false;
    sharedState.loadCache();
    final substitutionsBefore = Integrations.instance.getValue("substitutions") as WeekSubstitutions?;
    if (substitutionsBefore == null) return true;
    substitutionsBefore.weekSubstitutions!.removeWhere((key, value) => DateTime.parse(value.item2).isBefore(today)); // Remove substitutions on passed days
    final substitutionsBeforeJson = substitutionsBefore.toJson();
    sharedState.content.lastUpdated = DateTime(0);
    final contentBeforeJson = sharedState.content.toJsonData();
    // Parse the substitution and timetable
    await parsePlans(sharedState);
    final substitutions = Integrations.instance.getValue("substitutions") as WeekSubstitutions?;
    if (substitutions == null) return false;
    // Remove substitutions on passed days
    final substitutionsJson = substitutions.toJson();
    substitutionsJson.removeWhere((key, value) => DateTime.parse((value as List<dynamic>)[1] as String).isBefore(today));
    // Send the notifications based on what changed
    sharedState.content.lastUpdated = DateTime(0);
    final NotificationDetails platformChannelSpecifics = getNotificationDetails();
    if (!const DeepCollectionEquality().equals(substitutionsBeforeJson, substitutionsJson)) {
      sharedState.content.updateLastUpdated();
      sharedState.saveCache();
      // TODO: Send more insightful notifications, by checking what substitutions changed/got added/removed and somehow conveying those changes in text (For example if a substitution got added, that changes the room on the next day in the second class, the notification should contain that information, and not just say: Something has changed)
      await notifyPlugin.show(Random().nextInt(2147483647), 'Vertretunsplan Änderungen', 'Es gibt Änderungen im Vertretunsplan die dich betreffen', platformChannelSpecifics);
    } else if (!const DeepCollectionEquality().equals(contentBeforeJson, sharedState.content.toJsonData())) {
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

