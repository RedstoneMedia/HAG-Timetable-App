import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:stundenplan/widgets/buttons.dart';
import 'package:stundenplan/widgets/labeled_text_input.dart';

import '../helper_functions.dart';

class SharedDataStoreDebugPage extends StatefulWidget {
  final SharedState sharedState;

  const SharedDataStoreDebugPage(this.sharedState);

  @override
  _SharedDataStoreDebugPageState createState() => _SharedDataStoreDebugPageState();
}

class _SharedDataStoreDebugPageState extends State<SharedDataStoreDebugPage> {
  final newList = <String>[];
  late final Timer everyMinute;

  @override
  void initState() {
    super.initState();
    everyMinute = Timer.periodic(const Duration(seconds: 10), (Timer timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    everyMinute.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.sharedState.theme.backgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 20.0),
          child: Column(
            children: [
              ListView(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                children: widget.sharedState.sharedDataStore!.data.entries.map((e) => Container(
                  padding: EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    border: Border.all(color: widget.sharedState.theme.subjectDropOutColor.withOpacity(0.4), width: 1.0),
                    borderRadius: BorderRadius.circular(1.0)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(e.key, textAlign: TextAlign.left, style: GoogleFonts.poppins(
                          color: widget.sharedState.theme.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10
                      )),
                      Text("Timestamp: ${e.value.timestamp.toString()}", textAlign: TextAlign.left,style: GoogleFonts.poppins(
                          color: widget.sharedState.theme.textColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 9
                      )),
                      Text("Data: ${truncateString(e.value.data.toString(), 100)}", textAlign: TextAlign.left, style: GoogleFonts.poppins(
                          color: widget.sharedState.theme.textColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 9
                      )),
                      Text("Raw: ${truncateString(e.value.raw.toString(), 500)}", textAlign: TextAlign.left, style: GoogleFonts.poppins(
                          color: widget.sharedState.theme.textColor,
                          fontWeight: FontWeight.w300,
                          fontSize: 4
                      ))
                    ],
                  ),
                )).toList()
              ),
              LabeledTextInput("New Property name", widget.sharedState, newList, 0, fontSize: 13),
              LabeledTextInput("New Value", widget.sharedState, newList, 1, fontSize: 13),
              StandardButton(text: 'Add Property',
                fontSize: 15,
                size: 0.1,
                sharedState: widget.sharedState,
                color: widget.sharedState.theme.subjectColor,
                onPressed: () async {
                  if (newList[0].isEmpty || newList[1].isEmpty) return;
                  await widget.sharedState.sharedDataStore!.setProperty(newList[0], newList[1]);
                  setState(() {});
                }
              )
            ]
          ),
        )
      )
    );
  }
}
