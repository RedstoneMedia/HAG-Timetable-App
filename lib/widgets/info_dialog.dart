import 'package:flutter/material.dart';
import '../content.dart';
import '../shared_state.dart';

class InfoProperty extends StatelessWidget {
  final String name;
  final dynamic value;
  final SharedState sharedState;

  const InfoProperty(this.value, {required this.name, required this.sharedState});

  bool isTextNotEmpty(String? text) {
    return !((text?.isEmpty ?? true) || text == "\u{00A0}" || text == " " || text == "---");
  }

  @override
  Widget build(BuildContext context) {
    if (value == null) return Container();
    bool display = false;
    if (value is String || value is int) {
      display = isTextNotEmpty(value.toString());
    } else if (value is bool) {
      display = value as bool;
    }
    if (display) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text("$name:",
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontSize: 17,
                    color: sharedState.theme.textColor)),
          ),
          Flexible(
            child: Text(value is bool ? value == true ? "Ja" : "" : value.toString(),
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 17,
                    color: sharedState.theme.textColor)),
          )
        ],
      );
    } else {
      return Container();
    }
  }
}


Future<void> showInfoDialog(
    Cell cell, BuildContext context, SharedState sharedState) async {
  final showFootnotes = cell.footnotes != null && cell.footnotes!.length > 1;

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: sharedState.theme.backgroundColor,
        title: Text(
          'Informationen',
          style: TextStyle(color: sharedState.theme.textColor),
        ),
        content: SingleChildScrollView(
          child: showFootnotes
              ? SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                height: MediaQuery.of(context).size.height * 0.2,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: cell.footnotes!.length,
                    itemBuilder: (_, i) {
                      return Column(
                        children: [
                          InfoProperty(cell.footnotes![i].subject, name: "Fach", sharedState: sharedState),
                          InfoProperty(cell.footnotes![i].room, name: "Raum", sharedState: sharedState),
                          InfoProperty(cell.footnotes![i].teacher, name: "Lehrer", sharedState: sharedState),
                          InfoProperty(cell.footnotes![i].text, name: "Text", sharedState: sharedState),
                          const Divider(),
                        ],
                      );
                    },
                  ),
                )
              : ListBody(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InfoProperty(cell.originalSubject, name: "Orginal-Fach", sharedState: sharedState),
                        InfoProperty(cell.subject, name: "Fach", sharedState: sharedState),
                        InfoProperty(cell.originalRoom, name: "Orginal-Raum", sharedState: sharedState),
                        InfoProperty(cell.room, name: "Raum", sharedState: sharedState),
                        InfoProperty(cell.originalTeacher, name: "Orginal-Lehrer", sharedState: sharedState),
                        InfoProperty(cell.teacher, name: "Lehrer", sharedState: sharedState),
                        InfoProperty(cell.isDropped, name: "Entfall", sharedState: sharedState),
                        if (cell.isDropped || cell.isSubstitute) InfoProperty(cell.text, name: "Text", sharedState: sharedState) else
                          if (cell.footnotes == null) Container()
                          else InfoProperty(cell.footnotes![0].text, name: "Text", sharedState: sharedState),
                        if (!cell.isDropped && cell.substitutionKind != "Entfall") InfoProperty(cell.substitutionKind, name: "Art", sharedState: sharedState)
                        else Container(),
                        InfoProperty(cell.source, name: "Quelle", sharedState: sharedState)
                      ],
                    ),
                  ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Schließen',
                style: TextStyle(
                    color: sharedState.theme.subjectSubstitutionColor)),
          ),
        ],
      );
    },
  );
}
