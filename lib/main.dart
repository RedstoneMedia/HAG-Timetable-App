import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stundenplan/constants.dart';
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

  Content content;
  SharedState sharedState;
}

class _MyAppState extends State<MyApp> {
  SharedState sharedState;
  UpdateNotifier updateNotifier = new UpdateNotifier();

  DateTime date;
  bool loading = true;
  String day;

  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    sharedState = widget.sharedState;

    if (sharedState.loadStateAndCheckIfFirstTime()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SetupPage(sharedState)),
        );
      });
    } else {
      updateNotifier.init().then((value) {
        updateNotifier.getNewestVersion().then((newestVersion) {
          if (updateNotifier.currentVersion
              .isOtherVersionGreater(newestVersion)) {
            print("A newer version was found : $newestVersion");
          }
        });
      });
      widget.content = new Content(Constants.width, sharedState.height);
      loadCachedCells();
      parsePlans(widget.content, sharedState).then((value) => setState(() {
            print(
                "State was set to : ${widget.content}"); //TODO: Remove Debug Message
            cacheCells();
            loading = false;
          }));
    }
  }

  void cacheCells() {
    var encoded = jsonEncode(widget.content.toJsonData());
    sharedState.preferences
        .setString("content", encoded);
  }

  void loadCachedCells() {
    String content = sharedState.preferences.get("content");
    print("Getting: $content");
    if (content == null) return;
    setState(() {
      widget.content = Content.fromJsonData(jsonDecode(content));
    });
  }

  void showSettingsWindow() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SetupPage(sharedState)),
    );
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
              showSettingsWindow();
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
                    parsePlans(widget.content, sharedState)
                        .then((value) => _refreshController.refreshCompleted());
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
                            sharedState: sharedState, content: widget.content),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
