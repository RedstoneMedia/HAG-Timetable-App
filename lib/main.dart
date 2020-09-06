import 'dart:async';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/helper_functions.dart';
import 'package:stundenplan/pages/setup_page.dart';
import 'package:stundenplan/parsing/parse.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:stundenplan/update_notify.dart';

import 'content.dart';
import 'widgets/custom_widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.getInstance().then((prefs) {
    runApp(
      MaterialApp(
        home: MyApp(new SharedState(prefs)),
      ),
    );
  });
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();

  MyApp(this.sharedState);

  final SharedState sharedState;
}

class _MyAppState extends State<MyApp> {
  SharedState sharedState;
  UpdateNotifier updateNotifier = new UpdateNotifier();
  Connectivity connectivity = new Connectivity();

  DateTime date;
  bool loading = true;
  String day;

  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  RefreshController _refreshController = RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    sharedState = widget.sharedState;
    sharedState.content = new Content(Constants.width, sharedState.height);

    if (sharedState.loadStateAndCheckIfFirstTime()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SetupPage(sharedState)),
        );
      });
    } else {
      isInternetAvailable(connectivity).then((result) {
        if (result) {
          updateNotifier.init().then((value) {
            updateNotifier.checkForNewestVersionAndShowDialog(context, sharedState);
          });
          try {
            parsePlans(sharedState.content, sharedState).then((value) => setState(() {
              print("State was set to : ${sharedState.content}"); //TODO: Remove Debug Message
              sharedState.saveContent();
              loading = false;
            }));
          } on TimeoutException catch (_) {
            setState(() {
              print("Timeout !");
              sharedState.loadContent();
              loading = false;
            });
          }
        } else {
          setState(() {
            print("No connection !");
            sharedState.loadContent();
            loading = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
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
                    isInternetAvailable(connectivity).then((value) {
                      if (value) {
                        try {
                          parsePlans(sharedState.content, sharedState).then((value) {
                            sharedState.saveContent();
                            _refreshController.refreshCompleted();
                          });
                        } on TimeoutException catch (_) {
                          print("Timeout !");
                          _refreshController.refreshFailed();
                        }
                      } else {
                        print("no connection !");
                        _refreshController.refreshFailed();
                      }
                    });
                  },
                  sharedState: sharedState,
                  refreshController: _refreshController,
                  child: ListView(
                    physics: BouncingScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: 8.0,
                          top: 8.0,
                          right: 8.0,
                        ),
                        child: TimeTable(
                            sharedState: sharedState, content: sharedState.content
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
