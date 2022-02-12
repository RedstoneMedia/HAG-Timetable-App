import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:stundenplan/parsing/parse_subsitution_plan.dart';
import 'package:stundenplan/parsing/subsitution_image_parse.dart';
import 'package:stundenplan/widgets/buttons.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'package:tuple/tuple.dart';

import '../shared_state.dart';

// TODO: Remove this debug page and move the functionality to import a substitution image to the main page somewhere

// ignore: must_be_immutable
class ImportSubstitutionPage extends StatefulWidget {
  SharedState sharedState;

  ImportSubstitutionPage(this.sharedState);

  @override
  _ImportSubstitutionPageState createState() => _ImportSubstitutionPageState();
}

class _ImportSubstitutionPageState extends State<ImportSubstitutionPage> {
  late Interpreter classificationModel;
  final textDetector = GoogleMlKit.vision.textDetectorV2();
  final ImagePicker picker = ImagePicker();
  Image? imageWidget;
  String infoText = "";

  @override
  void initState() {
    super.initState();
    asyncInit();
  }

  Future<void> asyncInit() async {
    classificationModel = await Interpreter.fromAsset('models/subst_classification_model.tflite');
  }

  Future<void> close() async {
    Navigator.of(context).pop();
  }

  Future<bool> isGoodImage(File imageFile) async {
    // Load and scale image
    final image = img.decodeImage(await imageFile.readAsBytes())!;
    final imageProcessor = ImageProcessorBuilder()
        .add(ResizeOp(224, 224, ResizeMethod.NEAREST_NEIGHBOUR))
        .add(NormalizeOp(127.5, 127.5))
        .build();
    TensorImage tensorImage = TensorImage(classificationModel.getInputTensor(0).type);
    tensorImage.loadImage(image);
    tensorImage = imageProcessor.process(tensorImage);
    // Run model on processed image
    final outputBuffer = TensorBuffer.createFixedSize(classificationModel.getOutputTensor(0).shape, classificationModel.getInputTensor(0).type);
    classificationModel.run(tensorImage.buffer, outputBuffer.getBuffer());
    // Get probabilities from output
    final probabilityProcessor = TensorProcessorBuilder().add(NormalizeOp(0, 1)).build();
    final labels = ["Good", "Bad"];
    final Map<String, double> labeledProbabilities = TensorLabel.fromList(
        labels, probabilityProcessor.process(outputBuffer)
    ).getMapWithFloatValue();
    log("Is good image output: $labeledProbabilities", name: "subst-import");
    // Evaluate result (Good or Bad)
    if (labeledProbabilities["Good"]! >= 0.62) return true;
    setState(() {
      infoText = "Kein Vertretungsplan erkannt; Genauigkeit: ${(labeledProbabilities["Bad"]! * 100).toStringAsFixed(2)}%";
    });
    return false;
  }

  void displayImage(img.Image image) {
    final encodedImage = Uint8List.fromList(img.encodeJpg(image, quality: 30));
    setState(() {
      imageWidget = Image.memory(encodedImage, filterQuality: FilterQuality.none);
    });
  }

  Future<void> importSubstitutionPlan() async {
    imageWidget = null;
    // Get image from camera
    final XFile? imageXFile = await picker.pickImage(
        source: ImageSource.gallery);
    if (imageXFile == null) return;
    final imageFile = File(imageXFile.path);
    // Check if image passes the classifier
    if (!await isGoodImage(imageFile)) {
      setState(() {
        imageWidget = Image.file(imageFile);
      });
      return;
    }
    // Extract monitor region and find tables in it
    final img.Image image = img.decodeImage(await imageFile.readAsBytes())!;
    final monitorContentImage = await warpWithMonitorCorners(image);
    if (monitorContentImage == null) {
      setState(() {
        infoText = "Monitor Ecken konnten nicht gefunden werden";
      });
      return;
    }
    final tableImages = separateTables(monitorContentImage);
    if (tableImages == null) {
      setState(() {
        infoText = "Tabellen konnten nicht speariert werden";
      });
      return;
    }
    // Import data from table
    bool didParseSomething = false;
    for (final tableImage in tableImages.toList()) {
      //displayImage(tableImage as img.Image);
      final coursesSubstitutionsResult = await getCoursesSubstitutionsFromTable(
          tableImage as img.Image,
          textDetector,
          widget.sharedState.content,
          widget.sharedState.profileManager.schoolClassFullName,
          displayImage
      );
      if (coursesSubstitutionsResult == null) {
        continue;
      }
      log(coursesSubstitutionsResult.toString(), name: "subst-import");
      didParseSomething = true;
      // Check if substitutions of parsed image are contained in the current week
      final coursesSubstitutions = coursesSubstitutionsResult.item2;
      final substitutionApplyDate = coursesSubstitutionsResult.item1;
      final tableWeekDay = substitutionApplyDate.weekday;
      final tableWeekStartDate = substitutionApplyDate.subtract(Duration(days: tableWeekDay-1));
      if (DateTime.now().difference(tableWeekStartDate).inDays > 7) {
        continue;
      }
      // Add new substitutions to weekSubstitutions
      for (final className in coursesSubstitutions.keys) {
        if (widget.sharedState.profileManager.schoolClassFullName != className) continue; // Skip all classes that are not the users class
        final dayClassSubstitutions = coursesSubstitutions[className]!;
        final currentDaySubstitutions = widget.sharedState.weekSubstitutions.weekSubstitutions?.putIfAbsent(
            tableWeekDay.toString(),
            () => Tuple2([], substitutionApplyDate.toString())
        ).item1.toSet();
        currentDaySubstitutions!.addAll(dayClassSubstitutions);
        widget.sharedState.weekSubstitutions.weekSubstitutions![tableWeekDay.toString()] = Tuple2(currentDaySubstitutions.toList(), substitutionApplyDate.toString());
      }
      // Write data from table weekSubstitutions day to content
      writeSubstitutionPlan(
          widget.sharedState.weekSubstitutions.weekSubstitutions![tableWeekDay.toString()]!.item1,
          tableWeekDay,
          widget.sharedState.content,
          widget.sharedState.profileManager.subjects
      );
      setState(() {
        infoText = coursesSubstitutions.toString();
      });
    }
    if (!didParseSomething) {
      setState(() => infoText = "Tabellen daten konnten nicht extrahiert werden");
    }
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
                      "Mache ein Bild von der Vertretungsplantabelle auf den Monitoren",
                      style: GoogleFonts.poppins(
                          color: widget.sharedState.theme.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15
                      ),
                      textAlign: TextAlign.center
                  ),
                  if (imageWidget != null)
                    Container(
                      child: imageWidget,
                    ),
                  StandardButton(
                    text: "Kalender Importieren",
                    onPressed: importSubstitutionPlan,
                    sharedState: widget.sharedState,
                    color: widget.sharedState.theme.subjectSubstitutionColor.withAlpha(180),
                    size: 0.5,
                    fontSize: 15,
                  ),
                  if (infoText.isNotEmpty) Text(
                      infoText,
                      style: GoogleFonts.poppins(
                          color: widget.sharedState.theme.textColor,
                          fontWeight: FontWeight.normal,
                          fontSize: 10
                      ),
                      textAlign: TextAlign.center
                  ) else Container(),
                  const Divider(height: 30),
                  StandardButton(
                      text: "Fertig",
                      onPressed: close,
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
