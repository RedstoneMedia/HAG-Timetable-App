import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/helper_functions.dart';
import 'package:stundenplan/parsing/parse.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:stundenplan/update_notify.dart';
import 'package:time_ago_provider/time_ago_provider.dart' as time_ago;

import 'content.dart';
import 'loading_functions.dart';
import 'widgets/custom_widgets.dart';

void main() {
  //Make sure the widget fully loads before doing stuff
  WidgetsFlutterBinding.ensureInitialized();
  //Create a SharedPreferences instance; [Used for caching and storing settings]
  SharedPreferences.getInstance().then((prefs) {
    runApp(
      MaterialApp(
        home: MyApp(SharedState(prefs)),
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
  SharedState sharedState;
  UpdateNotifier updateNotifier = UpdateNotifier();
  Connectivity connectivity = Connectivity();

  DateTime date;
  bool loading = true;
  String day;
  Timer everyMinute;

  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final RefreshController _refreshController = RefreshController();

  @override
  void initState() {
    //Init the Widget
    super.initState();

    //Setup the sharedState
    sharedState = widget.sharedState;
    sharedState.content = Content(Constants.width, sharedState.height);

    // Calls set state every minute to update current school hour if changed
    everyMinute = Timer.periodic(const Duration(minutes: 1), (Timer timer) {
      setState(() {});
    });

    //Do all the Async Init stuff
    asyncInit();
  }

  Future<void> asyncInit() async {
    //Check if the App is opened for the first time
    if (sharedState.loadStateAndCheckIfFirstTime()) {
      //App is opened for the firs time -> load settings from file
      await openSetupPageAndCheckForFiles(sharedState, context);
    } else {
      //If not the first time -> Check if Internet is available
      final bool result = await isInternetAvailable(connectivity);
      //Internet is available
      if (result) {
        //Check for App-Updates und Load the Timetable
        loading = await checkForUpdateAndLoadTimetable(
            updateNotifier, sharedState, context);
        //Update the Page to remove the loading Icon
        setState(() {});
      } else {
        //Internet is not available
        print("No connection !");
        //Load cached content
        sharedState.loadContent();
        //remove loading Icon
        loading = false;
        //Update the Page
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
              : PullDownToRefresh(
                  onRefresh: () {
                    isInternetAvailable(connectivity).then((internetAvailable) {
                      if (internetAvailable) {
                        try {
                          setState(() {
                            parsePlans(sharedState.content, sharedState)
                                .then((value) {
                              sharedState.saveContent();
                              _refreshController.refreshCompleted();
                            });
                          });
                        } on TimeoutException catch (_) {
                          // ignore: avoid_print
                          print("Timeout !");
                          _refreshController.refreshFailed();
                        }
                      } else {
                        // ignore: avoid_print
                        print("no connection !");
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
                              time_ago.format(sharedState.content.lastUpdated,
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
