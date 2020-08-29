import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/parse.dart';
import 'package:stundenplan/widgets/grid.dart';

import 'content.dart';

void main() {
  runApp(
    MaterialApp(
      home: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
  final Content content = new Content(Constants().width, Constants().height);
}

class _MyAppState extends State<MyApp> {
  Constants constants = new Constants();
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
    date = DateTime.now();
    day = DateFormat('EEEE').format(date);

    initiate(widget.content, constants).then((value) => setState(() {
          print("State was set to : ${widget.content}");
          loading = false;
        }));
    asyncInit();
  }

  void asyncInit() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      constants.setThemeAsString = prefs.get("theme") ?? "dark";
    });
  }

  void saveTheme() async {
    prefs.setString("theme", constants.themeAsString.toString());
  }

  void showSettingsWindow() {
    showModalBottomSheet(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        backgroundColor: constants.subjectAusfallColor,
        context: context,
        builder: (builder) =>
            Container(
              color: Colors.transparent,
              height: 250,
              width: double.infinity,
              child: Column(
                children: [
                  Container(
                    color: constants.textColor,
                    width: double.infinity,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Themes",
                          style: GoogleFonts.poppins(
                              color: constants.backgroundColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18.0),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Material(
                            color: constants.textColor.withAlpha(25),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  constants.theme = constants.darkTheme;
                                  saveTheme();
                                  Navigator.pop(context);
                                });
                              },
                              child: Center(
                                child: Text(
                                  "Dark Theme",
                                  style: GoogleFonts.poppins(
                                      color: constants.textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 32.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Material(
                            color: constants.invertedTextColor.withAlpha(100),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  constants.theme = constants.lightTheme;
                                  saveTheme();
                                  Navigator.pop(context);
                                });
                              },
                              child: Center(
                                child: Text(
                                  "Light Theme",
                                  style: GoogleFonts.poppins(
                                      color: constants.textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 32.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ));
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text(
          "StundenPlan",
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
                                  day,
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
