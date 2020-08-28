import 'package:flutter/material.dart';
import 'dart:convert'; // Contains the JSON encoder
import 'package:http/http.dart'; // Contains a client for making API calls
import 'package:html/parser.dart'; // Contains HTML parsers to generate a Document object
import 'package:html/dom.dart' as dom; // Contains DOM related classes for extracting data from elements

void main() {
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initiate().then((value) => print(value));
  }

  Future initiate() async {
    // Make API call to Hackernews homepage
    var client = Client();
    Response response = await client.get('https://hag-iserv.de/iserv/public/plan/show/Sch%C3%BCler-Stundenpl%C3%A4ne/b006cb5cf72cba5c/svertretung/svertretungen.htm');

    // Use html parser
    var document = parse(response.body);
    List<dom.Element> links = document.querySelectorAll('a');
    List<Map<String, dynamic>> linkMap = [];

    for (var link in links) {
      linkMap.add({
        'title': link.text,
        'href': link.attributes['href'],
      });
    }

    return json.encode(linkMap);
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
