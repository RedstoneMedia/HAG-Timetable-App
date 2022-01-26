import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stundenplan/widgets/buttons.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

import '../shared_state.dart';

// ignore: must_be_immutable
class ImportSubstitutionPage extends StatefulWidget {
  SharedState sharedState;

  ImportSubstitutionPage(this.sharedState);

  @override
  _ImportSubstitutionPageState createState() => _ImportSubstitutionPageState();
}

class _ImportSubstitutionPageState extends State<ImportSubstitutionPage> {
  late Interpreter classificationModel;
  final ImagePicker picker = ImagePicker();
  String result = "";

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

  Future<void> importSubst() async {
    final XFile? imageXFile = await picker.pickImage(source: ImageSource.camera);
    if (imageXFile == null) return;
    final image = img.decodeImage(File(imageXFile.path).readAsBytesSync())!;

    final imageProcessor = ImageProcessorBuilder()
        .add(ResizeOp(224, 224, ResizeMethod.NEAREST_NEIGHBOUR))
        .add(NormalizeOp(127.5, 127.5))
        .build();

    TensorImage tensorImage = TensorImage(classificationModel.getInputTensor(0).type);
    tensorImage.loadImage(image);
    tensorImage = imageProcessor.process(tensorImage);
    final outputBuffer = TensorBuffer.createFixedSize(classificationModel.getOutputTensor(0).shape, classificationModel.getInputTensor(0).type);
    classificationModel.run(tensorImage.buffer, outputBuffer.getBuffer());

    final probabilityProcessor = TensorProcessorBuilder().add(NormalizeOp(0, 1)).build();
    final labels = ["Good", "Bad"];
    final Map<String, double> labeledProb = TensorLabel.fromList(
        labels, probabilityProcessor.process(outputBuffer)
      ).getMapWithFloatValue();

    log(labeledProb.toString(), name: "subst-import");
    setState(() {
      result = labeledProb.toString();
    });
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
                  StandardButton(
                    text: "Kalender Importieren",
                    onPressed: importSubst,
                    sharedState: widget.sharedState,
                    color: widget.sharedState.theme.subjectSubstitutionColor.withAlpha(180),
                    size: 0.5,
                    fontSize: 15,
                  ),
                  if (result.isNotEmpty) Text(
                      result,
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
