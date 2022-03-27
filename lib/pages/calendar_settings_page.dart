import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stundenplan/calendar_data.dart';
import 'package:stundenplan/helper_functions.dart';
import 'package:stundenplan/parsing/calendar_parse.dart';
import 'package:stundenplan/widgets/buttons.dart';
import 'package:stundenplan/widgets/labeled_text_input.dart';

import '../shared_state.dart';

// ignore: must_be_immutable
class CalendarSettingsPage extends StatefulWidget {
  SharedState sharedState;

  CalendarSettingsPage(this.sharedState);

  @override
  _CalendarSettingsPageState createState() => _CalendarSettingsPageState();
}

class _CalendarSettingsPageState extends State<CalendarSettingsPage> {
  late SharedState sharedState;
  final urlList = <String>[];
  bool areCredentialsAvailable = false;

  @override
  void initState() {
    super.initState();
    areIServCredentialsSet().then((value) => setState(() {areCredentialsAvailable = value;}));
    sharedState = widget.sharedState;
    for (final calendarType in pluginCalendarTypes) {
      final currentUrl = sharedState.profileManager.calendarUrls[calendarType.name()];
      if (currentUrl != null) {
        urlList.add(currentUrl);
      }
    }
  }

  Future<void> saveAndGoBack() async {
    for (var i = 0; i < urlList.length; i++) {
      final text = urlList[i];
      final urlRegex = RegExp(r"^https:\/\/hag-iserv.de\/(caldav\/.+\/calendar|iserv\/public\/calendar\/ics\/feed\/plugin\/[a-z0-9]{128}\/calendar.ics)$");
      if (urlRegex.hasMatch(text)) {
        final calendarTypeName = pluginCalendarTypes[i].name();
        log("set $text as $calendarTypeName url", name: "calendar settings");
        sharedState.profileManager.calendarUrls[calendarTypeName] = text;
      }
    }
    Navigator.of(context).pop();
  }

  Future<void> autoFillUrls() async {
    final calendarUrls = (await enableAllCalendarPluginUrls())!;
    // Update urls
    setState(() {
      for (var i = 0; i < urlList.length; i++) {
        urlList[i] = calendarUrls[pluginCalendarTypes[i].name()]!;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: sharedState.theme.backgroundColor,
      child: SafeArea(
        child: Stack(
          children: [
            HelpButton("Einstellungen#kalender-optionen", sharedState: sharedState),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 20.0),
              child: ListView(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                children: [
                  Column(
                    children: [
                      Text(
                        "Kopiere die Kalender Links von IServ in die entsprechenden Felder.",
                        style: GoogleFonts.poppins(
                          color: sharedState.theme.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15
                        ),
                        textAlign: TextAlign.center
                      ),
                      Text(
                          "\nKalender Modul ➜ Einstellungen ➜ Kalender verwalten ➜ Plugins ➜ <Pluginname> ➜ Freigabe",
                          style: GoogleFonts.poppins(
                              color: sharedState.theme.textColor,
                              fontWeight: FontWeight.normal,
                              fontSize: 15
                          ),
                          textAlign: TextAlign.center
                      ),
                      const Divider(height: 15),
                      for (var i = 0; i < pluginCalendarTypes.length; i++)
                        Column(
                          children: [
                            LabeledTextInput("${pluginCalendarTypes[i].name()} Link", sharedState, urlList, i, fontSize: 15),
                            const Divider(height: 15)
                          ],
                        )
                      ,
                      StandardButton(
                        text: "Automatisch füllen",
                        onPressed: autoFillUrls,
                        sharedState: sharedState,
                        color: areCredentialsAvailable ? sharedState.theme.subjectSubstitutionColor.withAlpha(180) : sharedState.theme.subjectDropOutColor.withAlpha(80),
                        size: 0.5,
                        fontSize: 15,
                        disabled: !areCredentialsAvailable,
                      ),
                      const Divider(height: 30),
                      StandardButton(
                        text: "Fertig",
                        onPressed: saveAndGoBack,
                        sharedState: sharedState,
                        size: 1.5,
                        fontSize: 25,
                        color: sharedState.theme.subjectColor
                      ),
                    ],
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
