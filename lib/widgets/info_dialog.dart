import 'package:flutter/material.dart';
import '../content.dart';
import '../shared_state.dart';

// This is ridiculously long for a simple info-dialog.
// You could probably remove the 'flexible' widgets.
// Not quite sure what else can be done. I have to look into this.
// TODO: fix this mess

Future<void> showInfoDialog(
    Cell cell, BuildContext context, SharedState sharedState) async {
  final showFootnotes = cell.footnotes != null && cell.footnotes!.length > 1;

  bool isTextNotEmpty(String? text) {
    return !((text?.isEmpty ?? true) || text == "\u{00A0}" || text == " " || text == "---");
  }

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
                    itemCount: cell.footnotes!.length,
                    itemBuilder: (_, i) {
                      return Row(
                        children: [
                          Flexible(
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
                                const Divider(),
                              ],
                            ),
                          ),
                          Flexible(
                            child: Column(
                              children: [
                                Text(cell.footnotes![i].subject,
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                        color: sharedState.theme.textColor)),
                                Text(cell.footnotes![i].room,
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                        color: sharedState.theme.textColor)),
                                Text(cell.footnotes![i].teacher,
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                        color: sharedState.theme.textColor)),
                                Text(cell.footnotes![i].text,
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                        color: sharedState.theme.textColor)),
                                const Divider(),
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (isTextNotEmpty(cell.originalSubject))
                                FittedBox(
                                  fit: BoxFit.fitWidth,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Orginal-Fach:",
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                            color: sharedState.theme.textColor
                                        )),
                                      Text(cell.originalSubject,
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                              color:
                                              sharedState.theme.textColor)
                                      )
                                    ],
                                  ),
                                ),
                              if (isTextNotEmpty(cell.subject))
                                FittedBox(
                                  fit: BoxFit.fitWidth,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Fach:",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                              color:
                                              sharedState.theme.textColor)),
                                      Text(cell.subject,
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                              color:
                                              sharedState.theme.textColor))
                                    ],
                                  ),
                                ),
                              if (isTextNotEmpty(cell.originalRoom))
                                FittedBox(
                                  fit: BoxFit.fitWidth,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Orginal-Raum:",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                              color:
                                              sharedState.theme.textColor)),
                                      Text(cell.originalRoom,
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                              color:
                                              sharedState.theme.textColor))
                                    ],
                                  ),
                                ),
                              if (isTextNotEmpty(cell.room))
                                FittedBox(
                                  fit: BoxFit.fitWidth,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Raum:",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                              color:
                                              sharedState.theme.textColor)),
                                      Text(cell.room,
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                              color:
                                              sharedState.theme.textColor))
                                    ],
                                  ),
                                ),
                              if (isTextNotEmpty(cell.originalTeacher))
                                FittedBox(
                                  fit: BoxFit.fitWidth,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Orginal-Lehrer:",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                              color:
                                              sharedState.theme.textColor)),
                                      Text(cell.originalTeacher,
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                              color:
                                              sharedState.theme.textColor))
                                    ],
                                  ),
                                ),
                              if (isTextNotEmpty(cell.teacher))
                                FittedBox(
                                  fit: BoxFit.fitWidth,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Lehrer:",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                              color:
                                              sharedState.theme.textColor)),
                                      Text(cell.teacher,
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                              color:
                                              sharedState.theme.textColor))
                                    ],
                                  ),
                                ),
                              if (cell.isDropped)
                                FittedBox(
                                  fit: BoxFit.fitWidth,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Entfall:",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                              color:
                                              sharedState.theme.textColor)),
                                      Text("Ja",
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                              color:
                                              sharedState.theme.textColor))
                                    ],
                                  ),
                                ),
                              if (cell.text.codeUnitAt(0) != 160)
                                FittedBox(
                                  fit: BoxFit.fitWidth,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Text:",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                              color:
                                              sharedState.theme.textColor)),
                                      Text(cell.text,
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                              color:
                                              sharedState.theme.textColor))
                                    ],
                                  ),
                                )
                              ],
                          ),
                        ]
                      : [
                          Row(
                            children: [
                              Flexible(
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
                                    if (cell.footnotes != null &&
                                        cell.footnotes![0].text.codeUnitAt(0) !=
                                            160)
                                      Text("Text:",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                              color:
                                                  sharedState.theme.textColor))
                                  ],
                                ),
                              ),
                              Flexible(
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
                                    if (cell.footnotes != null &&
                                        cell.footnotes![0].text.codeUnitAt(0) !=
                                            160)
                                      Text(cell.footnotes![0].text,
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                              color:
                                                  sharedState.theme.textColor))
                                  ],
                                ),
                              ),
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
