import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stundenplan/parsing/subsitution_image_parse.dart';
import 'package:stundenplan/shared_state.dart';

class BottomOverlay<T extends BottomOverlayState> extends StatefulWidget {
  final SharedState sharedState;
  late final OverlayEntry overlayEntry;
  final T state;

  BottomOverlay({
    required this.sharedState,
    required this.state,
    required BuildContext context
  }) {
    overlayEntry = OverlayEntry(builder: (context) => this);
    Overlay.of(context)?.insert(overlayEntry);
  }

  @override
  T createState() => state;
}

abstract class BottomOverlayState extends State<BottomOverlay> {
  String text = "";

  @override
  void initState() {
    super.initState();
    run().then((_) => widget.overlayEntry.remove());
  }

  Future<void> run() async {}
}

class BottomOverlayWrapper extends StatelessWidget {
  final String text;
  final Widget child;
  final SharedState sharedState;

  const BottomOverlayWrapper({required this.text, required this.child, required this.sharedState});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                  color: sharedState.theme.textColor,
                  borderRadius: const BorderRadius.all(Radius.circular(8.0))
              ),
              child: Column(
                children: [
                  Text(
                      text,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          color: sharedState.theme.backgroundColor,
                          fontSize: 10,
                          decoration: TextDecoration.none,
                          fontWeight: FontWeight.bold
                      )
                  ),
                  child
                ],
              )
          )
        ],
      ),
    );
  }
}

void displayTextOverlay(String text, Duration duration, SharedState sharedState, BuildContext context,) {
  final overlayEntry = OverlayEntry(builder: (context) => BottomOverlayWrapper(text: text, sharedState: sharedState, child: Container()));
  Overlay.of(context)?.insert(overlayEntry);
  Future.delayed(duration).then((_) => overlayEntry.remove());
}

class SubstitutionScanningOverlayState extends BottomOverlayState {
  Image? imageWidget;
  late Color progressBarColor;

  @override
  Future<void> run() async {
    final substitutionImageImporter = SubstitutionImageImporter(widget.sharedState);
    setState(() {
      text = "Scanne";
      progressBarColor = widget.sharedState.theme.subjectColor;
    });
    // Take image and import substitution plan
    final result = await substitutionImageImporter.importSubstitutionPlan((newImage) {
      setState(() {
        imageWidget = getImageWidgetFromImage(newImage);
      });
    });
    // Display scan error message if there were any scanning issues
    if (result == SubstitutionImageImportResult.allOk) {return;}
    switch (result) {
      case SubstitutionImageImportResult.allOk:
        break;
      case SubstitutionImageImportResult.badImage:
        setState(() => text = "Vertretungsbildschirm wurde nicht erkannt");
        break;
      case SubstitutionImageImportResult.noMonitorCorners:
        setState(() => text = "Monitor Ecken konnten nicht gefunden werden");
        break;
      case SubstitutionImageImportResult.badTableSeparation:
        setState(() => text = "Tabellen konnten nicht sepeariert werden");
        break;
      case SubstitutionImageImportResult.badTable:
        setState(() => text = "Eine der Tabellen konnte nicht eingelsen werden");
        break;
      case SubstitutionImageImportResult.badTables:
        setState(() => text = "Tabellen konntent nicht eingelsen werden");
        break;
      case SubstitutionImageImportResult.toOld:
        setState(() => text = "Vertretungsplan ist zu alt");
        break;
      case SubstitutionImageImportResult.alreadyScanned:
        setState(() => text = "Dieser Vertretungsplan wurde bereits eingelesen");
        break;
    }
    setState(() {
      progressBarColor = widget.sharedState.theme.subjectSubstitutionColor;
    });
    await Future.delayed(const Duration(milliseconds: 2000)); // Some wait time so the user can has some time to see the error
  }

  @override
  Widget build(BuildContext context) {
    return BottomOverlayWrapper(
      text: text,
      sharedState: widget.sharedState,
      child: Column(
        children: [
          if (imageWidget != null) imageWidget! else Container(),
          LinearProgressIndicator(color: progressBarColor, backgroundColor: Colors.transparent)
        ]
      )
    );
  }

}
