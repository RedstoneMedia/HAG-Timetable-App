import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:opencv/opencv.dart';
import 'package:path_provider/path_provider.dart';
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
      result = "Kein Vertretungsplan erkannt; Genauigkeit: ${(labeledProbabilities["Bad"]! * 100).toStringAsFixed(2)}%";
    });
    return false;
  }

  void displayImage(img.Image image) {
    final encodedImage = Uint8List.fromList(img.encodeJpg(image, quality: 30));
    setState(() {
      imageWidget = Image.memory(encodedImage, filterQuality: FilterQuality.none);
    });
  }

  List<Tuple2<int, int>> getDirectNeighbors(Tuple2<int, int> pos, img.Image image) {
    final positions = [
      Tuple2(pos.item1 - 1, pos.item2),
      Tuple2(pos.item1 + 1, pos.item2),
      Tuple2(pos.item1, pos.item2 - 1),
      Tuple2(pos.item1, pos.item2 + 1),
    ];
    positions.removeWhere((pos) => pos.item1 >= image.width || pos.item2 >= image.height || pos.item1.isNegative || pos.item2.isNegative);
    return positions;
  }

  List<Tuple2<int, int>> getNeighbors(Tuple2<int, int> pos, img.Image image, int size) {
    final positions = <Tuple2<int, int>>[];
    final halfSize = (size/2).floor();
    for (int xOffset = -halfSize; xOffset <= halfSize; xOffset++) {
      for (int yOffset = -halfSize; yOffset <= halfSize; yOffset++) {
        final offsetPos = Tuple2(
            pos.item1 + xOffset,
            pos.item2 + yOffset
        );
        if (offsetPos.item1 >= image.width || offsetPos.item2 >= image.height || offsetPos.item1.isNegative || offsetPos.item2.isNegative) continue;
        positions.add(offsetPos);
      }
    }
    return positions;
  }

  Set<Tuple2<int, int>> iterativeNeighborSearch(Tuple2<int, int> startPosition, img.Image image, bool Function(int, int, Tuple2<int, int>) useNeighbor) {
    final working = <Tuple2<int, int>>{startPosition};
    final done = <Tuple2<int, int>>{};
    while (working.isNotEmpty) {
      final position = working.first;
      final neighbors = getDirectNeighbors(position, image);
      final color = image.getPixel(position.item1, position.item2);
      for (final n in neighbors) {
        if (!done.contains(n)) {
          if (useNeighbor(color, image.getPixel(n.item1, n.item2), n)) {
            working.add(n);
          }
        }
      }
      done.add(position);
      working.remove(position);
    }
    return done;
  }

  int getMaxNeighborDifference(int color, Tuple2<int, int> position, img.Image image, int windowSize) {
    final currentValue = img.getRed(color);
    final neighbors = getNeighbors(position, image, windowSize);
    int maxDifference = 0;
    for (final neighborPos in neighbors) {
      final neighborValue = img.getRed(image.getPixel(neighborPos.item1, neighborPos.item2));
      final difference = currentValue - neighborValue;
      if (difference > maxDifference) maxDifference = difference;
    }
    return maxDifference;
  }

  // Find the positions and value of the brightest pixels
  List<Tuple2<int, Tuple2<int, int>>> findBrightestPixels(img.Image image) {
    final List<Tuple2<int, Tuple2<int, int>>> brightest = [];
    for (int x = 0; x < image.width; x++) {
      for (int y = 0; y < image.height; y++) {
        final value = image.getPixel(x, y);
        final currentBrightestValue = brightest.isNotEmpty ? brightest[0].item1 : 0;
        if (value > currentBrightestValue) {
          brightest.clear();
          brightest.add(Tuple2(value, Tuple2(x, y)));
        } else if (value == currentBrightestValue) {
          brightest.add(Tuple2(value, Tuple2(x, y)));
        }
      }
    }
    return brightest;
  }

  void drawSquareOnTop(Tuple2<int, int> pos, int color, img.Image image, int size) {
    for (final p in getNeighbors(pos, image, size)) {
      image.setPixel(p.item1, p.item2, color);
    }
  }

  Tuple2<Tuple2<int, int>, Tuple2<int, int>> findMaxTopLeftAndBottomRight(List<Tuple2<int, int>> positions) {
    Tuple2<int, int> topLeft = const Tuple2(4294967296, 4294967296);
    Tuple2<int, int> bottomRight = const Tuple2(0, 0);
    for (final p in positions) {
      if (p.item1 + p.item2 < topLeft.item1 + topLeft.item2) topLeft = p;
      if (p.item1 + p.item2 > bottomRight.item1 + bottomRight.item2) bottomRight = p;
    }
    return Tuple2(topLeft, bottomRight);
  }

  Tuple2<int, int> flipPoint(Tuple2<int, int> point, int width) {
    return Tuple2(((1.0 - (point.item1 / width)) * width).round(), point.item2);
  }

  List<Tuple2<int, int>> flipPointsHorizontally(Iterable<Tuple2<int, int>> points, int width) {
    final List<Tuple2<int, int>> newPoints = [];
    for (final point in points) {
      newPoints.add(flipPoint(point, width));
    }
    return newPoints;
  }

  Future<String> detectText(img.Image image) async {
    final monitorImageTempFile = File("${(await getTemporaryDirectory()).path}/textDetect.tmp");
    await monitorImageTempFile.writeAsBytes(img.encodeJpg(image, quality: 90));
    final RecognisedText recognisedText = await textDetector.processImage(InputImage.fromFile(monitorImageTempFile));
    await monitorImageTempFile.delete();
    return recognisedText.text;
  }

  Future<img.Image?> warpToCorners(
      Tuple2<int, int> start,
      img.Image grayscaleImage,
      img.Image image, {
        int shrinkFactor = 1,
        int minPointsLength = 8000,
        int searchYDirection = 1,
        int contourWindowSize = 5,
        int contourMinChange = 45,
        int cleanupMinNeighborCount = 5
      }
      ) async {
    Set<Tuple2<int, int>> pointsSet = {};
    final startX = start.item1;
    int startY = start.item2;
    // Trace contours
    while (pointsSet.length <= minPointsLength) {
      pointsSet = iterativeNeighborSearch(Tuple2(startX, startY), grayscaleImage, (_, color, position) {
        return getMaxNeighborDifference(color, position, grayscaleImage, contourWindowSize) > contourMinChange;
      });
      startY += searchYDirection;
      if (startY >= grayscaleImage.height || startY < 0) return null;
    }
    // Clean up contour by discarding contour points with low neighbors
    final toRemovePoints = <Tuple2<int, int>>[];
    for (final p in pointsSet) {
      int neighborCount = 0;
      for (final neighbor in getNeighbors(p, image, 3)) {
        if (pointsSet.contains(neighbor)) neighborCount += 1;
      }
      if (neighborCount < cleanupMinNeighborCount) toRemovePoints.add(p);
    }
    for (final pointToRemove in toRemovePoints) {
      pointsSet.remove(pointToRemove);
    }
    final points = pointsSet.toList(growable: false);
    log("[Warp to Corners] Found contour ${points.length} points", name: "subst-import");
    // Extract corner points
    final topLeftAndBottomRight = findMaxTopLeftAndBottomRight(points);
    final topRightAndBottomLeft = findMaxTopLeftAndBottomRight(flipPointsHorizontally(points, grayscaleImage.width));
    final topLeft = topLeftAndBottomRight.item1;
    final bottomRight = topLeftAndBottomRight.item2;
    final topRight = flipPoint(topRightAndBottomLeft.item1, grayscaleImage.width);
    final bottomLeft = flipPoint(topRightAndBottomLeft.item2, grayscaleImage.width);
    // Calculate width and height
    final width = topRight.item1 - bottomLeft.item1;
    final height = bottomLeft.item2 - topRight.item2;
    if (width.isNegative || height.isNegative) {
      return null;
    }
    log("[Warp to Corners] Found corners: $topLeft $topRight $bottomLeft $bottomRight $width x $height", name: "subst-import");
    // Warp image to fit corner points
    final warpedImageBytes = await ImgProc.warpPerspectiveTransform(
        Uint8List.fromList(img.encodeJpg(image, quality: 90)),
        sourcePoints: [topLeft.item1 * shrinkFactor, topLeft.item2 * shrinkFactor, topRight.item1 * shrinkFactor, topRight.item2 * shrinkFactor, bottomLeft.item1 * shrinkFactor, bottomLeft.item2 * shrinkFactor, bottomRight.item1 * shrinkFactor, bottomRight.item2 * shrinkFactor],
        destinationPoints: [0, 0, width, 0, 0, height, width, height],
        outputSize: [width.toDouble(), height.toDouble()]) as Uint8List;
    return img.decodeImage(warpedImageBytes.toList());
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
    if (tableWarpedImage == null) return;
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
    final monitorContent = await warpWithMonitorCorners(image);
    if (monitorContent == null) {
      setState(() {result = "Monitor Ecken konnten nicht gefunden werden";});
      return;
    }
    final tableImages = separateTables(monitorContent);
    if (tableImages == null) {
      setState(() {result = "Tabellen konnten nich speariert werden";});
      return;
    }
    // Import data from table
    await importTable(tableImages.item1);
    setState(() {result = "";});
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
