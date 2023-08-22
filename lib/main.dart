import 'dart:async';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/helper_functions.dart';
import 'package:stundenplan/parsing/calendar_parse.dart';
import 'package:stundenplan/parsing/parse.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:stundenplan/update_notify.dart';
import 'package:time_ago_provider/time_ago_provider.dart' as time_ago;

import 'content.dart';
import 'loading_functions.dart';
import 'notifiy.dart';
import 'widgets/custom_widgets.dart';

void main() {
  // Make sure the widget fully loads before doing stuff
  WidgetsFlutterBinding.ensureInitialized();
  // Disable landscape mode for the app
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  initializeNotifications();
  // Create a SharedPreferences instance; [Used for caching and storing settings]
  SharedPreferences.getInstance().then((prefs) {
    runApp(
      MaterialApp(
        home: MyApp(
          SharedState(
            prefs,
            Content(0, 0),
          ),
        ),
      ),
    );
  });
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();

  const MyApp(this.sharedState);

  final SharedState sharedState;
}

class _MyAppState extends State<MyApp> {
  late SharedState sharedState;
  UpdateNotifier updateNotifier = UpdateNotifier();
  Connectivity connectivity = Connectivity();

  DateTime? date;
  bool loading = true;
  String? day;
  Timer? everyMinute;

  bool couldLoad = true;

  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final RefreshController _refreshController = RefreshController();

  @override
  void initState() {
    // Init the Widget
    super.initState();

    // Setup the sharedState
    sharedState = widget.sharedState;
    sharedState.content = Content(Constants.width, Constants.defaultHeight); // Temp initialize content

    // Calls set state every minute to update current school hour if changed
    everyMinute = Timer.periodic(const Duration(minutes: 1), (Timer timer) {
      setState(() {});
    });

    // Do all the Async Init stuff
    asyncInit();
  }

  Future<void> asyncInit() async {
    // Check if the App is opened for the first time
    if (sharedState.loadStateAndCheckIfFirstTime()) {
      // App is opened for the firs time -> load settings from file
      await openSetupPageAndCheckForFile(sharedState, context);
    } else {
      await tryMoveFile(Constants.saveDataFileLocationOld, Constants.saveDataFileLocation); // Legacy file location migration
      // Start and stop the notifications, based on, if they are enable or not
      if (sharedState.sendNotifications) {
          await startNotificationTask();
      } else {
        await stopNotificationTask();
      }
      // If not the first time -> Check if Internet is available
      final bool result = await isInternetAvailable(connectivity);
      // Internet is available
      if (result) {
        if (!mounted) return;
        // Check for App-Updates und Load the Timetable
        couldLoad = await checkForUpdateAndLoadTimetable(
            updateNotifier, sharedState, context);
        loading = false;
        // Update the Page to remove the loading Icon
        setState(() {});
        // Load the calendar data if the timetable data could be loaded.
        if (couldLoad) {
          sharedState.calendarData = await loadCalendarData(sharedState);
          sharedState.saveCache();
          setState(() {});
        }
      } else {
        // Internet is not available
        log("No connection !", name: "network");
        // Load cached content
        try {
          sharedState.loadCache();
        } catch (e) {
          log("Loading from Network or Cache failed.", name: "loading");
          couldLoad = false;
          if (!mounted) return;
          await showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text("Die Daten konnten nicht geladen werden"),
                  content: const Text(
                      "Die App konnte den Stundenplan nicht aus dem Internet oder dem Cache laden."),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Ok'),
                    ),
                  ],
                );
              });
        }
        // remove loading Icon
        loading = false;
        // Update the Page
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        leading: Container(),
        title: Text(
          "Stundenplan",
          style: GoogleFonts.poppins(
            color: sharedState.theme.textColor,
          ),
        ),
        backgroundColor: sharedState.theme.backgroundColor,
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: sharedState.theme.textColor,
            ),
            onPressed: () {
              showSettingsWindow(context, sharedState);
            },
          ),
        ],
      ),
      body: Material(
        color: sharedState.theme.backgroundColor,
        child: SafeArea(
          child: loading
              ? Center(
                  child: Loader(sharedState),
                )
              : !couldLoad
                  ? Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: Text(
                              "Es konnten keine Daten geladen werden...",
                              style: TextStyle(
                                  color: sharedState.theme.textColor,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                          Container(
                            height: 10.0,
                          ),
                          Center(
                            child: Text(
                              "Versuche eine Internetverbindung herzustellen und starte die App neu.",
                              style: TextStyle(
                                  color: sharedState.theme.textColor,
                                  fontWeight: FontWeight.w300),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          ElevatedButton(onPressed: () => {
                            setState(() {
                              couldLoad = true;
                            })
                          },
                            style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all<Color>(
                                sharedState.theme.subjectColor.withOpacity(0.9),
                              ),
                            ), child:
                            Text(
                              "Leeren/Alten Stundenplan anzeigen",
                              style: TextStyle(color: sharedState.theme.textColor),
                            )
                          )
                        ],
                      ),
                    )
                  : PullDownToRefresh(
                      onRefresh: () {
                        isInternetAvailable(connectivity)
                            .then((internetAvailable) {
                          if (internetAvailable) {
                            try {
                              // Reload timetable data
                              // ignore: prefer_function_declarations_over_variables
                              final VoidFutureCallBack reloadAsync = () async {
                                await parsePlans(sharedState);
                                sharedState.saveCache();
                                _refreshController.refreshCompleted();
                              };
                              reloadAsync().then((_) => setState(() {}));
                              // Reload calendar data
                              loadCalendarData(sharedState).then((value) => setState(() {
                                sharedState.calendarData = value;
                                sharedState.saveCache();
                              }));
                            } on TimeoutException catch (_) {
                              log("Timeout !", name: "network");
                              _refreshController.refreshFailed();
                            }
                          } else {
                            log("No connection !", name: "network");
                            _refreshController.refreshFailed();
                          }
                        });
                      },
                      sharedState: sharedState,
                      refreshController: _refreshController,
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 8.0,
                              top: 8.0,
                              right: 8.0,
                            ),
                            child: TimeTable(
                                sharedState: sharedState,
                                content: sharedState.content),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Text(
                                  "Zuletzt aktualisiert: ",
                                  style: GoogleFonts.poppins(
                                      color: sharedState.theme.textColor
                                          .withAlpha(200),
                                      fontWeight: FontWeight.w300),
                                ),
                                Text(
                                  time_ago.format(
                                      sharedState.content.lastUpdated,
                                      locale: "de"),
                                  style: GoogleFonts.poppins(
                                      color: sharedState.theme.textColor
                                          .withAlpha(200),
                                      fontWeight: FontWeight.w200),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}
