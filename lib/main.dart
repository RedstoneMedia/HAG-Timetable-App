import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:stundenplan/parse.dart';
import 'content.dart';

void main() {
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
  Content content = new Content(6, 10);
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    asyncinit();
  }

  Future<void> asyncinit() async {
    var result = await initiate("11e", widget.content);
    return;
    /*
      setState(() {
        for (List<Cell> cellList in value.cells)
          for (Cell cell in cellList) print(cell.subject);
        widget.content = value;
      });
    });*/
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int y = 0; y < 10; y++)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int x = 0; x < 6; x++)
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(width: 1.0, color: Colors.black),
                      ),
                      width: 50,
                      height: 50,
                      child: Center(
                          child:
                              Text("" ?? widget.content.cells[y][x].subject)),
                    )
                ],
              ),
            RaisedButton(
              child: Text("Reload"),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
