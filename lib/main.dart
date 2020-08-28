import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        child: Column(
          children: [
            for (int y = 0; y < 10; y++)
              Row(
                children: [
                  for (int x = 0; x < 6; x++)
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(width: 1.0, color: Colors.black),
                      ),
                      width: 50,
                      height: 50,
                      child: Center(child: Text("$x - $y")),
                    )
                ],
              ),
          ],
        ),
      ),
    );
  }
}
