import 'package:flutter/material.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/parse.dart';
import 'content.dart';

void main() {
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
  Content content = new Content(Constants().width, Constants().height);
}

class _MyAppState extends State<MyApp> {
  Constants constants = new Constants();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    initiate("11e", widget.content).then((value) => setState(() {
          print("State was set to : ${widget.content}");
          loading = false;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: constants.backgroundColor,
      child: SafeArea(
        child: loading
            ? SizedBox(
                width: 80, height: 80, child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int y = 0; y < constants.height; y++)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int x = 0; x < constants.width; x++)
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      width: 1.0, color: Colors.black),
                                  color:
                                      widget.content.cells[y][x].subject == ""
                                          ? constants.subjectColor
                                          : constants.subjectAusfallColor),
                              child: Column(
                                children: [
                                  Text(
                                    widget.content.cells[y][x].originalSubject,
                                    style: TextStyle(
                                        decoration: TextDecoration.lineThrough),
                                  ),
                                  Text(widget.content.cells[y][x].subject),
                                  Text(widget.content.cells[y][x].room),
                                  Text(widget.content.cells[y][x].teacher),
                                ],
                              ),
                            ),
                          )
                      ],
                    ),
                ],
              ),
      ),
    );
  }
}
