import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stundenplan/widgets/buttons.dart';
import 'package:stundenplan/widgets/labeled_text_input.dart';
import '../helper_functions.dart';
import '../shared_state.dart';

class IServLoginSettingsPage extends StatefulWidget {
  final SharedState sharedState;

  const IServLoginSettingsPage(this.sharedState);

  @override
  _IServLoginSettingsPageState createState() => _IServLoginSettingsPageState();
}

class _IServLoginSettingsPageState extends State<IServLoginSettingsPage> {

  final credentialsOutputList = <String>[];
  bool areCredentialsAvailable = false;

  @override
  void initState() {
    super.initState();
    areIServCredentialsSet().then((value) => setState(() {areCredentialsAvailable = value;}));
  }

  Future<void> saveIServCredentialsAndGoBack() async {
    if (credentialsOutputList.where((element) => element.length > 3).length != 2) return;

    if (Platform.isAndroid || Platform.isIOS || Platform.isLinux) {
      const FlutterSecureStorage storage = FlutterSecureStorage();
      await storage.write(key: "username", value: credentialsOutputList[0]);
      await storage.write(key: "password", value: credentialsOutputList[1]);
      await storage.write(key: "credentialsLastLoaded", value: DateTime.now().toIso8601String());
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> deleteIServCredentials() async {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    await storage.deleteAll();

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.sharedState.theme.backgroundColor,
      child: SafeArea(
        child: Stack(
          children: [
            HelpButton("Einstellungen#iserv-login-optionen", sharedState: widget.sharedState),
            Padding(
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
                      if (areCredentialsAvailable)
                        Column(
                          children: [
                            StandardButton(
                              text: "Daten Löschen",
                              onPressed: deleteIServCredentials,
                              sharedState: widget.sharedState,
                              color: widget.sharedState.theme.subjectSubstitutionColor.withAlpha(220)
                            ),
                            const Divider(height: 30)
                          ],
                        )
                      else Container(),
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
          ],
        ),
      ),
    );
  }
}
