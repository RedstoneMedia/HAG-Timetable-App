import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/parse.dart';
import 'package:stundenplan/widgets/grid.dart';

import 'content.dart';

void main() {
  runApp(MaterialApp(home: MyApp()));
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

  @override
  void initState() {
    super.initState();
    date = DateTime.now();
    day = DateFormat('EEEE').format(date);

    initiate("11e", widget.content, constants.subjects)
        .then((value) => setState(() {
              print("State was set to : ${widget.content}");
              loading = false;
            }));
    asyncinit();
  }

  void asyncinit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    constants.setThemeAsString = prefs.get("theme") ?? "light";
  }

  void saveTheme() async {
    print("saving Theme " + constants.themeAsString.toString());
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("theme", constants.themeAsString.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: constants.backgroundColor,
      child: SafeArea(
        child: loading
            ? Center(
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(),
                ),
              )
            : ListView(
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
                        RaisedButton(
                          child: Text("Switch Mode"),
                          onPressed: () {
                            setState(() {
                              if (constants.theme == constants.darkTheme)
                                constants.theme = constants.lightTheme;
                              else
                                constants.theme = constants.darkTheme;
                              saveTheme();
                            });
                          },
                        )
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
