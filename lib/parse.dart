import 'dart:collection';

import 'package:flutter/material.dart';
import 'dart:convert'; // Contains the JSON encoder
import 'package:http/http.dart'; // Contains a client for making API calls
import 'package:html/parser.dart'; // Contains HTML parsers to generate a Document object
import 'package:html/dom.dart' as dom;
import 'package:stundenplan/content.dart'; // Contains DOM related classes for extracting data from elements

Future<Content> initiate(course, Content content) async{
  var client = Client();

  await getCourseSubsitutionPlan(course, client).then((plan) {
    getCourseSubsitutionPlan("11K", client).then((value) {
      plan.addAll(value);
      for (int i = 0; i < plan.length; i++) {
        var hour = int.parse(plan[i]["Stunde"][1]);

        Cell cell = new Cell();
        cell.subject = plan[i]["Fach"];
        content.setCell(hour, 1, cell);
      }
    });
  });
  return content;
}

Future<List<HashMap<String, String>>> getCourseSubsitutionPlan(
    String course, client) async {
  Response response = await client.get(
      'https://hag-iserv.de/iserv/public/plan/show/Sch%C3%BCler-Stundenpl%C3%A4ne/b006cb5cf72cba5c/svertretung/svertretungen_${course}.htm');
  if (response.statusCode != 200) return new List<HashMap<String, String>>();

  var document = parse(response.body);
  List<dom.Element> tables = document.getElementsByTagName("table");
  for (int i = 0; i < tables.length; i++) {
    if (!tables[i].attributes.containsKey("rules")) {
      tables.removeAt(i);
    }
  }

  dom.Element mainTable = tables[0];
  List<dom.Element> rows = mainTable.getElementsByTagName("tr");
  List<String> headerInformation = [
    "Stunde",
    "Fach",
    "Vertretung",
    "Raum",
    "statt Fach",
    "statt Lehrer",
    "statt Raum",
    "Text",
    "Entfall"
  ];
  rows.removeAt(0);
  List<HashMap<String, String>> subsituions =
      new List<HashMap<String, String>>();

  for (var row in rows) {
    HashMap<String, String> substituion = new HashMap<String, String>();
    var coloumns = row.getElementsByTagName("td");
    for (int i = 0; i < coloumns.length; i++) {
      substituion[headerInformation[i]] =
          coloumns[i].text.replaceAll("\n", " ");
    }
    subsituions.add(substituion);
  }

  return subsituions;
}
