import 'package:flutter/material.dart';
import '../content.dart';
import '../shared_state.dart';

Future<void> showInfoDialog(Cell cell, context, SharedState sharedState) async {
  bool showFootnotes =
      cell.footnotes == null ? false : cell.footnotes.length > 1;

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
                  height: 200,
                  width: 200,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: cell.footnotes.length,
                    itemBuilder: (_, i) {
                      return Row(
                        children: [
                          Flexible(
                            flex: 1,
                            child: Column(
                              children: [
                                Text("Fach:",
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                        color: sharedState.theme.textColor)),
                                Text("Raum:",
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                        color: sharedState.theme.textColor)),
                                Text("Lehrer:",
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                        color: sharedState.theme.textColor)),
                                Text("Text:",
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                        color: sharedState.theme.textColor)),
                                Divider(),
                              ],
                            ),
                          ),
                          Flexible(
                            flex: 1,
                            child: Column(
                              children: [
                                Text(cell.footnotes[i].subject,
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                        color: sharedState.theme.textColor)),
                                Text(cell.footnotes[i].room,
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                        color: sharedState.theme.textColor)),
                                Text(cell.footnotes[i].teacher,
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                        color: sharedState.theme.textColor)),
                                Text(cell.footnotes[i].text,
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                        color: sharedState.theme.textColor)),
                                Divider(),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                )
              : ListBody(
                  children: cell.isSubstitute || cell.isDropped
                      ? [
                          Row(
                            children: [
                              Flexible(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    cell.originalSubject != "---"
                                        ? Text("Orginal-Fach:",
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                                color: sharedState
                                                    .theme.textColor))
                                        : Container(),
                                    cell.subject != "---"
                                        ? Text("Fach:",
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                                color: sharedState
                                                    .theme.textColor))
                                        : Container(),
                                    cell.originalRoom != "---"
                                        ? Text("Orginal-Raum:",
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                                color: sharedState
                                                    .theme.textColor))
                                        : Container(),
                                    cell.room != "---"
                                        ? Text("Raum:",
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                                color: sharedState
                                                    .theme.textColor))
                                        : Container(),
                                    cell.originalTeacher != "---"
                                        ? Text("Orginal-Lehrer:",
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                                color: sharedState
                                                    .theme.textColor))
                                        : Container(),
                                    cell.teacher != "---"
                                        ? Text("Lehrer:",
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                                color: sharedState
                                                    .theme.textColor))
                                        : Container(),
                                    cell.isDropped
                                        ? Text("Fällt aus:",
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                                color: sharedState
                                                    .theme.textColor))
                                        : Container(),
                                    cell.text.codeUnitAt(0) != 160
                                        ? Text("Text:",
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                                color: sharedState
                                                    .theme.textColor))
                                        : Container(),
                                  ],
                                ),
                              ),
                              Flexible(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    cell.originalSubject != "---"
                                        ? Text(cell.originalSubject,
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                                color: sharedState
                                                    .theme.textColor))
                                        : Container(),
                                    cell.subject != "---"
                                        ? Text(cell.subject,
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                                color: sharedState
                                                    .theme.textColor))
                                        : Container(),
                                    cell.originalRoom != "---"
                                        ? Text(cell.originalRoom,
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                                color: sharedState
                                                    .theme.textColor))
                                        : Container(),
                                    cell.room != "---"
                                        ? Text(cell.room,
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                                color: sharedState
                                                    .theme.textColor))
                                        : Container(),
                                    cell.originalTeacher != "---"
                                        ? Text(cell.originalTeacher,
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                                color: sharedState
                                                    .theme.textColor))
                                        : Container(),
                                    cell.teacher != "---"
                                        ? Text(cell.teacher,
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                                color: sharedState
                                                    .theme.textColor))
                                        : Container(),
                                    cell.isDropped
                                        ? Text("Ja",
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                                color: sharedState
                                                    .theme.textColor))
                                        : Container(),
                                    cell.text.codeUnitAt(0) != 160
                                        ? Text("Text:           ${cell.text}",
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                                color: sharedState
                                                    .theme.textColor))
                                        : Container(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ]
                      : [
                          Row(
                            children: [
                              Flexible(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Fach:",
                                        style: TextStyle(
                                            color:
                                                sharedState.theme.textColor)),
                                    Text("Raum:",
                                        style: TextStyle(
                                            color:
                                                sharedState.theme.textColor)),
                                    Text("Lehrer:",
                                        style: TextStyle(
                                            color:
                                                sharedState.theme.textColor)),
                                    cell.footnotes != null
                                        ? cell.footnotes[0].text
                                                    .codeUnitAt(0) !=
                                                160
                                            ? Text("Text:",
                                                textAlign: TextAlign.left,
                                                style: TextStyle(
                                                    color: sharedState
                                                        .theme.textColor))
                                            : Container()
                                        : Container()
                                  ],
                                ),
                              ),
                              Flexible(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(cell.subject,
                                        style: TextStyle(
                                            color:
                                                sharedState.theme.textColor)),
                                    Text(cell.room,
                                        style: TextStyle(
                                            color:
                                                sharedState.theme.textColor)),
                                    Text(cell.teacher,
                                        style: TextStyle(
                                            color:
                                                sharedState.theme.textColor)),
                                    cell.footnotes != null
                                        ? cell.footnotes[0].text
                                                    .codeUnitAt(0) !=
                                                160
                                            ? Text(cell.footnotes[0].text,
                                                textAlign: TextAlign.left,
                                                style: TextStyle(
                                                    color: sharedState
                                                        .theme.textColor))
                                            : Container()
                                        : Container()
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                ),
        ),
        actions: <Widget>[
          FlatButton(
            child: Text('Schließen',
                style: TextStyle(
                    color: sharedState.theme.subjectSubstitutionColor)),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
