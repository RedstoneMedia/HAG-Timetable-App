import 'dart:io';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/content.dart';
import 'package:stundenplan/parsing/parse.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:workmanager/workmanager.dart';

Future<FlutterLocalNotificationsPlugin> initializeFlutterLocalNotifications() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  return flutterLocalNotificationsPlugin;
}

void callbackDispatcher() {
  Workmanager().executeTask((task, _inputData) async {
    final preferences = await SharedPreferences.getInstance(); //Initialize shared preferences
    final notifyPlugin = await initializeFlutterLocalNotifications();
    final sharedState = SharedState(preferences, Content(Constants.width, Constants.defaultHeight));
    if (sharedState.loadStateAndCheckIfFirstTime()) return true; // Should not happen
    // Todo: Parse the plans and check if they changed
    await parsePlans(sharedState);
    // Show notification
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'timetable_notifications',
        'Stundenplan Benachrichtigungen',
        channelDescription: 'Wenn Änderungen im Stunden- oder Vertretungsplan vorhanden sind, gibt es eine Benachrichtigung',
        priority: Priority.high,
        importance: Importance.high
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await notifyPlugin.show(Random().nextInt(256), 'Test', 'bruh', platformChannelSpecifics);
    return true;
  });
}

Future<void> initializeNotifications() async {
  if (!Platform.isAndroid) return;
  await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true,
  );
}

Future<void> startNotificationTask() async {
  if (!Platform.isAndroid) return;
  await Workmanager().registerOneOffTask(
    "timetableNotificationTask",
    "timetableNotificationTask",
    //frequency: const Duration(minutes: 15),
    existingWorkPolicy: ExistingWorkPolicy.replace,
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

