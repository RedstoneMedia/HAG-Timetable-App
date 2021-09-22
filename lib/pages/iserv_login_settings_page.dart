import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stundenplan/widgets/buttons.dart';
import 'package:stundenplan/widgets/labeled_text_input.dart';
import '../shared_state.dart';

class IServLoginSettingsPage extends StatefulWidget {
  final SharedState sharedState;

  const IServLoginSettingsPage(this.sharedState);

  @override
  _IServLoginSettingsPageState createState() => _IServLoginSettingsPageState();
}

class _IServLoginSettingsPageState extends State<IServLoginSettingsPage> {

  final credentialsOutputList = <String>[];

  @override
  void initState() {
    super.initState();
  }

  Future<void> saveIServCredentialsAndGoBack() async {
    if (credentialsOutputList.where((element) => element.length > 3).length != 2) return;

    if (Platform.isAndroid || Platform.isIOS || Platform.isLinux) {
      const FlutterSecureStorage storage = FlutterSecureStorage();
      await storage.write(key: "username", value: credentialsOutputList[0]);
      await storage.write(key: "password", value: credentialsOutputList[1]);
      await storage.write(key: "credentialsLastSaved", value: DateTime.now().toIso8601String());
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.sharedState.theme.backgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 20.0),
          child: ListView(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            children: [
              Column(
                children: [
                  Text(
                      "Gebe deinen IServ Nutzernamen und Passwort ein, wenn du der App erlauben willst auf deine Daten von IServ zuzugreifen.",
                      style: GoogleFonts.poppins(
                          color: widget.sharedState.theme.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15
                      ),
                      textAlign: TextAlign.center
                  ),
                  const Divider(height: 15),
                  LabeledTextInput("Nutzername", widget.sharedState, credentialsOutputList, 0),
                  const Divider(height: 15),
                  LabeledTextInput("Passwort", widget.sharedState, credentialsOutputList, 1, obscureText: true),
                  const Divider(height: 15),
                  StandardButton(
                      text: "Speichern",
                      onPressed: saveIServCredentialsAndGoBack,
                      sharedState: widget.sharedState,
                      size: 1.5,
                      fontSize: 25,
                      color: widget.sharedState.theme.subjectColor
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
