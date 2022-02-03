import 'dart:collection';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:stundenplan/parsing/subsitution_image_parse.dart';
import 'package:stundenplan/widgets/buttons.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'package:tuple/tuple.dart';

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

  Future<img.Image?> warpWithMonitorCorners(img.Image image) async {
    // Resized image to a more manageable size
    const shrinkFactor = 2;
    final resizedImage = img.copyResize(
        image, width: (image.width / shrinkFactor).round(), height: (image.height / shrinkFactor).round(),
        interpolation: img.Interpolation.average
    );
    final grayscaleImage = img.grayscale(resizedImage.clone());
    final List<Tuple2<int, Tuple2<int, int>>> brightest = findBrightestPixels(grayscaleImage);
    // Trace contours starting at brightest pixel (should be somewhere in the monitor background, since the monitor background color is white) then going down
    return warpToCorners(brightest[0].item2, grayscaleImage, image, shrinkFactor: shrinkFactor);
  }

  Tuple2<img.Image, img.Image>? separateTables(img.Image image) {
    // Find X coordinate of longest continuous vertical white strip
    final grayscaleImage = img.grayscale(image.clone());
    int maxValueSum = 0;
    int separateXCord = 0;
    final whiteBalance = grayscaleImage.getWhiteBalance();
    for (int x = (image.width / 2.8).round(); x < (image.width / 1.2).round(); x++) {
      int valueSum = 0;
      for (int y = 50; y < grayscaleImage.height; y++) {
        final value = img.getRed(grayscaleImage.getPixel(x, y));
        if (value >= whiteBalance) {
          valueSum += value;
        } else {
          break;
        }
        valueSum += value;
      }
      if (valueSum > maxValueSum) {
        maxValueSum = valueSum;
        separateXCord = x;
      }
    }
    if (separateXCord == 0) return null;
    log("Found Table X separation at : $separateXCord");
    // Split image into two at table separation X
    final leftTable = img.copyCrop(image, 0, 0, separateXCord, image.height);
    final rightTable = img.copyCrop(image, separateXCord, 0, image.width, image.height);
    return Tuple2(leftTable, rightTable);
  }

  Future<void> importTable(img.Image image) async {
    var grayscaleImage = img.grayscale(image.clone());
    // Warp to corners of table. Starting at bottom then going up to find contours
    final tableWarpedImage = await warpToCorners(
        Tuple2((image.width / 2).round(), image.height-1),
        grayscaleImage,
        image,
        minPointsLength: 10000,
        searchYDirection: -1,
        contourWindowSize: 3,
        contourMinChange: 19
    );
    if (tableWarpedImage == null) {
      setState(() => infoText = "Tabellen Ecken konnten nicht gefunden werden");
      return;
    }
    displayImage(tableWarpedImage);
    grayscaleImage = img.grayscale(tableWarpedImage.clone());
    final whiteBalance = grayscaleImage.getWhiteBalance();

    final rowSeparators = [];
    // Go from bottom to top searching for horizontal black strips
    for (int y = grayscaleImage.height-11; y >= 0; y--) {
      final points = iterativeNeighborSearch(Tuple2((grayscaleImage.width / 2).round(), y), grayscaleImage, (_, color, position) {
        return img.getRed(color) < whiteBalance && (position.item2-y).abs() <= 2;
      });
      if (points.length < 100) continue;
      if (rowSeparators.isNotEmpty) if ((rowSeparators.last as int) - y < 15) continue;
      rowSeparators.add(y);
    }
    // Go from left to right searching for vertical black strips
    final columnSeparators = [];
    for (int x = 0; x < grayscaleImage.width; x++) {
      final points = iterativeNeighborSearch(Tuple2(x, (grayscaleImage.height / 2).round()), grayscaleImage, (_, color, position) {
        return img.getRed(color) < whiteBalance && (position.item1-x).abs() <= 3;
      });
      if (points.length < 100) continue;
      if (columnSeparators.isNotEmpty) if (x - (columnSeparators.last as int) < 10) continue;
      columnSeparators.add(x);
    }
    // TODO: Merge separators that are to close to each other
    // Detect text in each cell
    // TODO: Check if it is viable to text detect on the whole image and then just separate the characters by the separators x and y position (To speed up detection)
    final cellsText = HashMap<Tuple2<int, int>, String>();
    for (int row = rowSeparators.length-1; row >= 0; row--) {
      final yStart = rowSeparators[row] as int;
      final yEnd = row == 0 ? 0 : rowSeparators[row-1] as int;
      final height = yEnd-yStart;
      for (int column = 0; column < columnSeparators.length; column++) {
        final xStart = columnSeparators[column] as int;
        final xEnd = column == columnSeparators.length-1 ? tableWarpedImage.width : columnSeparators[column+1] as int;
        final width = xEnd-xStart;
        if (width < 10 || height < 10) continue;
        // Ensure that InputImage width and height is at least 32 (For text detection)
        var cellImage = img.copyCrop(tableWarpedImage, xStart, yStart, width, height);
        if (width < 32 || height < 32) {
          final resizeFactor = math.max((32 / width).ceil(), (32 / height).ceil());
          cellImage = img.copyResize(cellImage, width: width*resizeFactor, height: height*resizeFactor);
        }
        final text = await detectText(cellImage, textDetector);
        log("Cell $row-$column contains: $text", name: "subst-import");
        setState(() => infoText = "Cell $row-$column: $text"); // Just so that the users sees that something is happening (A progress bar would probably be better)
        cellsText[Tuple2(rowSeparators.length-1 - row, column)] = text;
      }
    }
    // Display parsed text (debug)
    setState(() => infoText = cellsText.toString());
    // Display horizontal strips (debug)
    for (int i = 0; i < rowSeparators.length; i++) {
      final y = rowSeparators[i] as int;
      final colors = img.hsvToRgb(i / rowSeparators.length, 1, 1);
      for (int x = 0; x < grayscaleImage.width; x++) {
        tableWarpedImage.setPixel(x, y, img.setBlue(img.setGreen(colors[0], colors[1]), colors[2]));
      }
    }
    // Display vertical strips (debug)
    for (int i = 0; i < columnSeparators.length; i++) {
      final x = columnSeparators[i] as int;
      final colors = img.hsvToRgb(i / columnSeparators.length, 1, 1);
      for (int y = 0; y < grayscaleImage.height; y++) {
        tableWarpedImage.setPixel(x, y, img.setBlue(img.setGreen(colors[0], colors[1]), colors[2]));
      }
    }
    displayImage(tableWarpedImage);
  }

  Future<void> importSubstitutionPlan() async {
    imageWidget = null;
    // Get image from camera
    final XFile? imageXFile = await picker.pickImage(source: ImageSource.camera);
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
      setState(() {infoText = "Monitor Ecken konnten nicht gefunden werden";});
      return;
    }
    final tableImages = separateTables(monitorContentImage);
    if (tableImages == null) {
      setState(() {infoText = "Tabellen konnten nich speariert werden";});
      return;
    }
    // Import data from table
    await importTable(tableImages.item1);
    //setState(() {result = "";});
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
