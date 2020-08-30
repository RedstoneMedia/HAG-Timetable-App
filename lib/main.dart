import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/pages/setup_page.dart';
import 'package:stundenplan/parsing/parse.dart';
import 'package:stundenplan/widgets/grid.dart';

import 'content.dart';

void main() {
  Constants constants = new Constants();

  runApp(
    MaterialApp(
      home: MyApp(constants),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();

  MyApp(this.constants);
  final Content content = new Content(Constants().width, Constants().height);
  final Constants constants;
}

class _MyAppState extends State<MyApp> {
  Constants constants;
  bool loading = true;
  DateTime date;
  String day;
  SharedPreferences prefs;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    constants = widget.constants;
    date = DateTime.now();
    day = DateFormat('EEEE').format(date);

    SharedPreferences.getInstance().then((prefs) {
      this.prefs = prefs;
      var theme = prefs.get("theme");
      var schoolGrade = prefs.getInt("schoolGrade");
      constants.setThemeAsString = theme ?? "dark"; // Set theme
      constants.schoolGrade = schoolGrade ?? 11;
      constants.subSchoolClass = prefs.getString("subSchoolClass") ?? "e";
      constants.subjects = prefs.getStringList("subjects") ?? [];
      if (schoolGrade == null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SetupPage(constants, prefs)),
        );
        return;
      }
    });
    initiate(widget.content, constants).then((value) => setState(() {
      print("State was set to : ${widget.content}");
      loading = false;
    }));
  }

  void saveTheme() {
    prefs.setString("theme", constants.themeAsString.toString());
  }

  void showSettingsWindow() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SetupPage(constants, prefs)),
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
            color: constants.textColor,
          ),
        ),
        backgroundColor: constants.backgroundColor,
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: constants.textColor,
            ),
            onPressed: () {
              showSettingsWindow();
            },
          ),
        ],
      ),
      body: Material(
        color: constants.backgroundColor,
        child: SafeArea(
          child: loading
              ? Center(
            child: SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                valueColor:
                AlwaysStoppedAnimation<Color>(constants.subjectColor),
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
                valueColor:
                AlwaysStoppedAnimation<Color>(constants.subjectColor),
              ),
              waterDropColor: constants.subjectColor,
              complete: Icon(
                Icons.done,
                color: constants.subjectColor,
              ),
            ),
            onRefresh: () {
              initiate(widget.content, constants)
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
                      for (int y = 0; y < constants.height; y++)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int x = 0; x < constants.width; x++)
                              x == 0
                                  ? y == 0
                                  ? PlaceholderGridObject()
                                  : TimeGridObject(
                                  "12:30", "12:43", y, constants)
                                  : y == 0
                                  ? WeekdayGridObject(
                                  constants.weekDays[x],
                                  x,
                                  x == 1,
                                  x == constants.width - 1,
                                  constants)
                                  : ClassGridObject(
                                widget.content,
                                constants,
                                x,
                                y - 1,
                                x == 1,
                              ),
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
