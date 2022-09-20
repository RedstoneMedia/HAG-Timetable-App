import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/parsing/iserv_authentication.dart';
import 'package:stundenplan/widgets/buttons.dart';
import 'package:stundenplan/widgets/labeled_text_input.dart';
import 'package:tuple/tuple.dart';
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
  bool incorrectUsername = false;
  bool incorrectPassword = false;
  bool isCheckingCredentials = false;

  @override
  void initState() {
    super.initState();
    areIServCredentialsSet().then((value) => setState(() {areCredentialsAvailable = value;}));
  }

  Future<void> saveIServCredentialsAndGoBack() async {
    // Reset correctness
    setState(() {
      incorrectPassword = false;
      incorrectUsername = false;
    });
    // Check if fields are filled
    for (int i = 0; i < credentialsOutputList.length; i++) {
      if (credentialsOutputList[i].length < 4) {
        setState(() {
          switch (i) {
            case 0:
              incorrectUsername = true;
              break;
            case 1:
              incorrectPassword = true;
          }
        });
        return;
      }
    }
    // Check if credentials are correct, if internet is available
    if (await isInternetAvailable(Connectivity())) {
      setState(() => isCheckingCredentials = true);
      // Make Request to check url and get the response kind
      final iServCredentials = Tuple2(credentialsOutputList[0], credentialsOutputList[1]);
      final httpClient = HttpClient();
      final result = await makeRequestWithRedirects("POST", Uri.parse(Constants.credentialCheckUrlIServ), httpClient, CookieJar(), headers: iServLoginExtraHeaders, body: getIServLoginPostBody(iServCredentials));
      final responseKind = getIServLoginResponseKind(result.item3.statusCode, result.item4);
      httpClient.close();
      setState(() => isCheckingCredentials = false);
      // Display possible to user
      switch (responseKind) {
        case IServLoginResponseKind.ok:
          break;
        case IServLoginResponseKind.badPassword:
          setState(() => incorrectPassword = true);
          return;
        case IServLoginResponseKind.badUsername:
          setState(() => incorrectUsername = true);
          return;
        case IServLoginResponseKind.error:
          setState(() => incorrectUsername = true);
          setState(() => incorrectPassword = true);
          return;
      }
    }
    if (canUseSecureStorage()) {
      const FlutterSecureStorage storage = FlutterSecureStorage();
      await storage.write(key: "username", value: credentialsOutputList[0]);
      await storage.write(key: "password", value: credentialsOutputList[1]);
      await storage.write(key: "credentialsLastLoaded", value: DateTime.now().toIso8601String());
      // Clear the schulmanagerClassName, that is dependent on the, with IServ associated Schulmanager account.
      // This is done, so that the schulmanger is forced to refresh the current school class
      widget.sharedState.schulmanagerClassName = null;
      await widget.sharedState.saveSchulmanagerClassName();
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
                      LabeledTextInput("Nutzername", widget.sharedState, credentialsOutputList, 0, incorrect: incorrectUsername),
                      const Divider(height: 15),
                      LabeledTextInput("Passwort", widget.sharedState, credentialsOutputList, 1, obscureText: true, incorrect: incorrectPassword),
                      const Divider(height: 15),
                      if (areCredentialsAvailable)
                        Column(
                          children: [
                            StandardButton(
                              text: "Daten Löschen",
                              onPressed: deleteIServCredentials,
                              sharedState: widget.sharedState,
                              color: widget.sharedState.theme.subjectSubstitutionColor.withAlpha(220),
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
                          color: widget.sharedState.theme.subjectColor,
                          disabled: isCheckingCredentials,
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
