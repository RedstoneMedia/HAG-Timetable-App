import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/pages/setup_page.dart';
import 'package:stundenplan/parsing/parse.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:stundenplan/widgets/grid.dart';

import 'content.dart';

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

  final Content content = new Content(Constants.width, Constants.height);
  SharedState sharedState;

  MyApp(this.sharedState);
}

class _MyAppState extends State<MyApp> {
  SharedState sharedState;
  bool loading = true;
  DateTime date;
  String day;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  RefreshController _refreshController = RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    sharedState = widget.sharedState;
    date = DateTime.now();
    day = DateFormat('EEEE').format(date);


    if (sharedState.loadStateAndCheckIfFirstTime()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SetupPage(sharedState)),
        );});
    } else {
      parsePlans(widget.content, sharedState).then((value) => setState(() {
        print("State was set to : ${widget.content}");
        loading = false;
      }));
    }
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
            child: SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    sharedState.theme.subjectColor),
                backgroundColor: Colors.transparent,
                strokeWidth: 6.0,
              ),
            ),
          )
              : SmartRefresher(
            enablePullDown: true,
            controller: _refreshController,
            header: WaterDropHeader(
              refresh: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    sharedState.theme.subjectColor),
              ),
              waterDropColor: sharedState.theme.subjectColor,
              complete: Icon(
                Icons.done,
                color: sharedState.theme.subjectColor,
              ),
            ),
            onRefresh: () {
              parsePlans(widget.content, sharedState)
                  .then((value) => _refreshController.refreshCompleted());
            },
            child: ListView(
              physics: BouncingScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 8.0,
                    top: 8.0,
                    right: 8.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int y = 0; y < Constants.height; y++)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int x = 0; x < Constants.width; x++)
                              if (x == 0)
                                if (y == 0)
                                  PlaceholderGridObject()
                                else
                                  TimeGridObject(y, sharedState)
                              else
                                if (y == 0)
                                  WeekdayGridObject(
                                      Constants.weekDays[x],
                                      x,
                                      x == 1,
                                      x == Constants.width - 1,
                                      sharedState)
                                else
                                  ClassGridObject(widget.content,
                                      sharedState, x, y - 1, x == 1)
                          ],
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
