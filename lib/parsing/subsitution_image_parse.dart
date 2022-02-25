import 'dart:collection';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opencv/opencv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stundenplan/content.dart';
import 'package:stundenplan/parsing/parse_subsitution_plan.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'package:tuple/tuple.dart';
import 'package:image/image.dart' as img;
import 'package:google_ml_kit/google_ml_kit.dart';

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

Tuple2<int, Tuple2<int, int>> findLargestWhiteStripPosition(img.Image image) {
  final whiteBalance = image.getWhiteBalance(asDouble: true) as double;
  var maxWhiteCount = 0;
  var maxWhiteCountY = 0;
  var maxWhiteCountXPositions = <Tuple2<int, int>>[];
  for (int y = image.height-1; y > 0; y--) {
    var whiteCount = 0;
    for (int x = 0; x < image.width; x++) {
      final value = img.getRed(image.getPixel(x, y));
      if (value > whiteBalance) {
        whiteCount += 1;
        maxWhiteCountXPositions.add(Tuple2(x, value));
      }
    }
    if (whiteCount > maxWhiteCount) {
      maxWhiteCount = whiteCount;
      maxWhiteCountY = y;
      maxWhiteCountXPositions = [];
    }
  }
  final whiteMiddle = maxWhiteCountXPositions[(maxWhiteCountXPositions.length / 2).round()];
  return Tuple2(whiteMiddle.item2, Tuple2(whiteMiddle.item1, maxWhiteCountY));
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

Future<RecognisedText> detectText(img.Image image, TextDetectorV2 textDetector) async {
  final monitorImageTempFile = File("${(await getTemporaryDirectory()).path}/textDetect.tmp");
  await monitorImageTempFile.writeAsBytes(img.encodeJpg(image, quality: 90));
  final RecognisedText recognisedText = await textDetector.processImage(InputImage.fromFile(monitorImageTempFile));
  await monitorImageTempFile.delete();
  return recognisedText;
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

Future<Tuple2<img.Image, List<Tuple2<int, int>>>?> warpToCorners(
    Tuple2<int, int> start,
    img.Image grayscaleImage,
    img.Image image, {
      int shrinkFactor = 1,
      int minPointsLength = 8000,
      int searchYDirection = 1,
      int contourWindowSize = 5,
      int contourMinChange = 45,
      int cleanupMinNeighborCount = 5,
      void Function(img.Image)? displayImage
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
  return Tuple2(img.decodeImage(warpedImageBytes.toList())!, [topLeft, topRight, bottomLeft, bottomRight]);
}

Future<img.Image?> warpWithMonitorCorners(img.Image image) async {
  // Resized image to a more manageable size
  const shrinkFactor = 2;
  final resizedImage = img.copyResize(
      image, width: (image.width / shrinkFactor).round(), height: (image.height / shrinkFactor).round(),
      interpolation: img.Interpolation.average
  );
  final grayscaleImage = img.grayscale(resizedImage.clone());
  final Tuple2<int, int> startPosition = findLargestWhiteStripPosition(grayscaleImage).item2;
  // Trace contours starting at largest white strip position (should be somewhere in the monitor background, since the monitor background color is white) then going down
  return (await warpToCorners(startPosition, grayscaleImage, image, shrinkFactor: shrinkFactor))?.item1;
}

Tuple2<img.Image, img.Image>? separateTables(img.Image image) {
  // Find X coordinate of longest continuous vertical white strip
  final grayscaleImage = img.grayscale(image.clone());
  int maxValueSum = 0;
  int separateXCord = 0;
  final whiteBalance = grayscaleImage.getWhiteBalance(asDouble: true) as double;
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

Future<SplayTreeMap<Tuple2<int, int>, String>?> getCellsText(img.Image tableWarpedImage, TextDetectorV2 textDetector) async {
  final grayscaleImage = img.grayscale(tableWarpedImage.clone());
  final whiteBalance = grayscaleImage.getWhiteBalance(asDouble: true) as double;

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
  // Find header end, by finding end of wide black strip at top
  bool insideHeader = false;
  int headerYEnd = 0;
  for (int y = 0; y < grayscaleImage.height; y++) {
    int blackPixels = 0;
    for (int x = 0; x < grayscaleImage.width; x++) {
      final value = img.getRed(grayscaleImage.getPixel(x, y));
      if (value < (whiteBalance - 20)) blackPixels++;
    }
    if (blackPixels < grayscaleImage.width * 0.5) {
      if (!insideHeader) {insideHeader = true;} else {
        headerYEnd = y;
        break;
      }
    }
  }
  // Remove separators that are above the header end and add header end as row separator
  rowSeparators.removeWhere((separatorY) => separatorY as int <= headerYEnd);
  rowSeparators.add(headerYEnd);
  rowSeparators.add(0);
  // TODO: Merge separators that are to close to each other
  // Make sure that cells text positions are always in order for later processing
  final cellsText = SplayTreeMap<Tuple2<int, int>, String>((a, b) {
    if (a.item1 > b.item1) return 1;
    if (a.item1 < b.item1) return -1;
    if (a.item2 > b.item2) return 1;
    if (a.item2 < b.item2) return -1;
    return 0;
  });
  // Detect text in each column
  for (int column = 0; column < columnSeparators.length; column++) {
    final xStart = columnSeparators[column] as int;
    final xEnd = column == columnSeparators.length-1 ? tableWarpedImage.width : columnSeparators[column+1] as int;
    final width = xEnd-xStart;
    final height = tableWarpedImage.height;
    // Ensure that InputImage width is at least 32 (For text detection)
    var cellImage = img.copyCrop(tableWarpedImage, xStart, 0, width, height);
    int resizeFactor = 1;
    if (width < 32) {
      resizeFactor = (32 / width).ceil();
      cellImage = img.copyResize(cellImage, width: width*resizeFactor, height: height*resizeFactor);
    }
    // Run text detection on whole column
    final recognizedText = await detectText(cellImage, textDetector);
    // Split recognized text lines by vertical separators into rows
    for (int row = rowSeparators.length-1; row >= 0; row--) {
      final yStart = (rowSeparators[row] as int) * resizeFactor;
      final yEnd = row == 0 ? 0 : (rowSeparators[row - 1] as int) * resizeFactor;
      String text = "";
      for (final blocks in recognizedText.blocks) {
        for (final line in blocks.lines) {
          final rect = line.rect;
          if (rect.bottom > yEnd) break;
          if (rect.top >= yStart && rect.bottom <= yEnd) {
            text += line.text + (text.isEmpty && line.text != " " ? "" : "\n");
          }
        }
      }
      log("Cell $row-$column contains: $text", name: "subst-import");
      final rowColumnPosition = Tuple2(rowSeparators.length-1 - row, column);
      cellsText[rowColumnPosition] = text.isEmpty ? "" : text.replaceAll("|", "");
    }
  }
  return cellsText;
}

Future<Tuple2<DateTime, Map<String, List<Map<String, String>>>>?> getCoursesSubstitutionsFromTable(img.Image image, TextDetectorV2 textDetector, Content content, String fullClassName, void Function(img.Image) displayImage) async {
  // Warp to corners of table. Starting at bottom then going up to find contours
  final grayscaleImage = img.grayscale(image.clone());
  final warpToCornersResult = await warpToCorners(
      Tuple2((image.width / 2).round(), image.height-1),
      grayscaleImage,
      image,
      minPointsLength: 10000,
      searchYDirection: -1,
      contourWindowSize: 3,
      contourMinChange: 19,
      displayImage: displayImage
  );
  if (warpToCornersResult == null) return null;
  displayImage(warpToCornersResult.item1);
  // Get image cropped to be above the table and get the text of it
  final tableYTop = ((warpToCornersResult.item2[0].item2 + warpToCornersResult.item2[1].item2) / 2).ceil();
  img.Image aboveTableImage = img.copyCrop(image, 0, 0, image.width, tableYTop);
  if (aboveTableImage.height < 32) {
    final resizeFactor = (32 / aboveTableImage.height).ceil();
    aboveTableImage = img.copyResize(aboveTableImage, width: aboveTableImage.width*resizeFactor, height: aboveTableImage.height*resizeFactor);
  }
  final aboveTableText = (await detectText(aboveTableImage, textDetector)).text.replaceAll("|", "/");
  // Extract datetime and page information
  final regexp = RegExp(r"^\s*(?<day>\d{1,2}).(?<month>\d{1,2}).(?<year>\d{4}) [a-zA-Z]{3,}\s*(\(Seite (?<page>\d)/(?<totalPages>\d)\)){0,1}", multiLine: true);
  final matches = regexp.allMatches(aboveTableText);
  if (matches.isEmpty) return null;
  final substitutionApplyDate = DateTime(
    int.parse(matches.single.namedGroup("year")!),
    int.parse(matches.single.namedGroup("month")!),
    int.parse(matches.single.namedGroup("day")!),
  );
  final tableWarpedImage = warpToCornersResult.item1;
  // Get contents of each cell from the table image
  final cellsText = await getCellsText(tableWarpedImage, textDetector);
  if (cellsText == null) return null;
  // Find header indices
  final Map<String, int?> headerColumnIndices = {
    "Klassen" : null,
    "Std." : null,
    "Fach" : null,
    "Vertre." : null,
    "Raum" : null,
    "(Fach)" : null,
    "(Leh.)" : null,
    "(Raum)" : null,
    "Ve..." : null,
    "Entf." : null
  };
  for (final cellPos in cellsText.keys) {
    if (cellPos.item1 > 0) break;
    final cellText = cellsText[cellPos]!
      .replaceAll(" ", "")
      .replaceAll("\n", "")
      .toLowerCase();
    try {
      final headerName = headerColumnIndices.keys.where((n) => n.toLowerCase() == cellText).single;
      headerColumnIndices[headerName] = cellPos.item2;
    } on StateError {}
  }
  final headerInformationMapping = {
    "Klassen" : "Klassen",
    "Std.": "Stunde",
    "Fach": "Fach",
    "Vertre.": "Vertretung",
    "Raum": "Raum",
    "(Fach)": "statt Fach",
    "(Leh.)": "statt Lehrer",
    "(Raum)": "statt Raum",
    "Ve...": "Text",
    "Entf.": "Entfall"
  };
  // Convert cells list to substitution list and rename column names to fit the online column names
  final substitutions = <Map<String, String>>[{}];
  int lastColumn = -1;
  for (final cellPos in cellsText.keys) {
    if (cellPos.item1 == 0) continue;
    if (cellPos.item2 < lastColumn) substitutions.add({});
    try {
      final entry = headerColumnIndices.entries.firstWhere((entry) => cellPos.item2 == entry.value);
      substitutions.last[headerInformationMapping[entry.key]!] = cellsText[cellPos]!;
    } on StateError {}
    lastColumn = cellPos.item2;
  }
  // Convert substitution list to substitutions per course
  final coursesSubstitutions = <String, List<Map<String, String>>>{};
  for (final substitution in substitutions) {
    correctSubstitution(substitution, content, fullClassName);
    if (!substitution.containsKey("Klassen")) continue;
    final className = substitution["Klassen"]!;
    substitution.remove("Klassen");
    if (substitution["Stunde"]!.isEmpty) continue;
    coursesSubstitutions.putIfAbsent(className, () => []);
    coursesSubstitutions[className]?.add(substitution);
    // If a substitution has no substitute or change, but still exists it can be assumed that the "X" in the drop out column was not detected even when it should
    if (substitution["Fach"]!.isEmpty && substitution["Vertretung"]!.isEmpty && substitution["Raum"]!.isEmpty && headerColumnIndices["Entf."] != null) {
      substitution["Entfall"] = "X";
    }
    // Replace empty fields with the non breaking space character. Because the website does exactly this (for some reason) and things should be at least kept constant.
    for (final substitutionDataEntry in substitution.entries) {
      if (substitutionDataEntry.value.isEmpty) {
        substitution[substitutionDataEntry.key] = "\u{00A0}";
      }
    }
  }
  return Tuple2(substitutionApplyDate, coursesSubstitutions);
}

int scorePropertyCorrectOption(String value, String matchValue) {
  if (value.length != matchValue.length) return 0;
  int score = 0;
  final replacements = [Tuple2("O", "0"), Tuple2("0", "O"), Tuple2("I", "1"), Tuple2("1", "I"), Tuple2("l", "1"), Tuple2("1", "l")];
  for (int i = 0; i < value.length; i++) {
    final char = value[i];
    final matchChar = matchValue[i];
    if (char == matchChar) {score += 4; continue;}
    if (char.toLowerCase() == matchChar.toLowerCase()) {score += 3; continue;}
    if (replacements.where((r) => char == r.item1 && r.item2 == matchChar).isNotEmpty) {
      score += 2;
      continue;
    }
    if (replacements.where((r) => char.toLowerCase() == r.item1.toLowerCase() && r.item2.toLowerCase() == matchChar.toLowerCase()).isNotEmpty) {
      score += 1;
      continue;
    }
    return -1;
  }
  return score;
}

void correctSubstitution(Map<String, String> substitution, Content content, String fullClassName) {
  // Look for properties in the substitution that are definitely right because they already exists in the current time table
  final allSubjectsTeachersAndRooms = <Tuple3<String, String, String>>{};
  final okProperties = <String>{};
  for (int y = 0; y < content.cells.length; y++) {
    final column = content.cells[y];
    for (int y = 0; y < column.length; y++) {
      final item = column[y];
      final subjectsTeachersAndRooms = <Tuple3<String, String, String>>{};
      subjectsTeachersAndRooms.add(Tuple3(item.subject, item.teacher, item.room));
      if (item.footnotes != null) {
        subjectsTeachersAndRooms.addAll(item.footnotes!.map((f) => Tuple3(f.subject, f.teacher, f.room)));
      }
      for (final subjectsTeachersAndRoom in subjectsTeachersAndRooms) {
        if (subjectsTeachersAndRoom.item1 == substitution["Fach"]) okProperties.add("Fach");
        if (subjectsTeachersAndRoom.item1 == substitution["statt Fach"]) okProperties.add("statt Fach");
        if (subjectsTeachersAndRoom.item2 == substitution["Vertretung"]) okProperties.add("Vertretung");
        if (subjectsTeachersAndRoom.item2 == substitution["statt Lehrer"]) okProperties.add("statt Lehrer");
        if (subjectsTeachersAndRoom.item3 == substitution["Raum"]) okProperties.add("Raum");
        if (subjectsTeachersAndRoom.item3 == substitution["statt Raum"]) okProperties.add("statt Raum");
      }
      allSubjectsTeachersAndRooms.addAll(subjectsTeachersAndRooms);
    }
  }
  final beforeHashCode = substitution.hashCode;
  // Try to fix properties which could be incorrect
  for (final property in substitution.entries) {
    final ignoreProperties = ["Stunde", "Text", "Entfall", "Klassen"];
    ignoreProperties.addAll(okProperties);
    if (ignoreProperties.contains(property.key)) continue;
    final int matchType;
    if (["Fach", "statt Fach"].contains(property.key)) matchType = 0;
    else if (["Vertretung", "statt Lehrer"].contains(property.key)) matchType = 1;
    else if (["Raum", "statt Raum"].contains(property.key)) matchType = 2;
    else continue;
    final propertyValue = property.value;
    // Score values in the current timetable which match the propertyValue the closest
    // TODO: Extra Room property correction (Rooms always match ^[A-Z]\d.\d{2}$)
    final scoredOptions = <Tuple2<int, String>>[];
    for (final allSubjectsTeachersAndRoom in allSubjectsTeachersAndRooms) {
      final matchValue = allSubjectsTeachersAndRoom.toList()[matchType]! as String;
      scoredOptions.add(Tuple2(scorePropertyCorrectOption(propertyValue, matchValue), matchValue));
    }
    // Set closest match to the propertyValue
    scoredOptions.sort((a, b) => b.item1.compareTo(a.item1));
    final bestMatch = scoredOptions.first;
    if (bestMatch.item1 > (math.max(propertyValue.length-2, 1))*4 + 1) {
      substitution[property.key] = bestMatch.item2;
      okProperties.add(property.key);
    }
  }
  // If the class is not set, but the subject, room and teacher are contained in the current users timetable, it can be assumed that the class is the same as the current users class
  if (!substitution.containsKey("Klassen") && okProperties.contains("statt Fach") && okProperties.contains("statt Lehrer") && okProperties.contains("statt Raum")) {
    substitution["Klassen"] = fullClassName;
  }
  if (beforeHashCode != substitution.hashCode) {
    log("Fixed: $okProperties $substitution", name: "subst-correct");
  }
}

enum SubstitutionImageImportResult {
  allOk,
  badImage,
  noMonitorCorners,
  badTableSeparation,
  badTable,
  badTables,
  toOld
}

class SubstitutionImageImporter {
  final SharedState sharedState;
  late Interpreter classificationModel;
  final textDetector = GoogleMlKit.vision.textDetectorV2();
  final ImagePicker picker = ImagePicker();

  SubstitutionImageImporter(this.sharedState) {
    Interpreter.fromAsset('models/subst_classification_model.tflite').then((interpreter) => classificationModel = interpreter);
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
    return false;
  }

  Future<SubstitutionImageImportResult> importSubstitutionPlan(void Function(img.Image) displayImage) async {
    // Get image from camera
    final XFile? imageXFile = await picker.pickImage(source: kDebugMode ? ImageSource.gallery : ImageSource.camera);
    if (imageXFile == null) return SubstitutionImageImportResult.badImage;
    final imageFile = File(imageXFile.path);
    // Check if image passes the classifier
    if (!await isGoodImage(imageFile)) {
      return SubstitutionImageImportResult.badImage;
    }
    // Extract monitor region and find tables in it
    final img.Image image = img.decodeImage(await imageFile.readAsBytes())!;
    final monitorContentImage = await warpWithMonitorCorners(image);
    if (monitorContentImage == null) {
      // Error: Could not find monitor corners
      return SubstitutionImageImportResult.noMonitorCorners;
    }
    final tableImages = separateTables(monitorContentImage);
    if (tableImages == null) {
      // Error: Could not separate tables
      return SubstitutionImageImportResult.badTableSeparation;
    }
    // Import data from table
    int okTablesCount = 0;
    for (final tableImage in tableImages.toList()) {
      //displayImage(tableImage as img.Image);
      final coursesSubstitutionsResult = await getCoursesSubstitutionsFromTable(
          tableImage as img.Image,
          textDetector,
          sharedState.content,
          sharedState.profileManager.schoolClassFullName,
          displayImage
      );
      if (coursesSubstitutionsResult == null) {
        continue;
      }
      log(coursesSubstitutionsResult.toString(), name: "subst-import");
      // Check if substitutions of parsed image are contained in the current week
      final coursesSubstitutions = coursesSubstitutionsResult.item2;
      final substitutionApplyDate = coursesSubstitutionsResult.item1;
      final tableWeekDay = substitutionApplyDate.weekday;
      final tableWeekStartDate = substitutionApplyDate.subtract(Duration(days: tableWeekDay-1));
      final currentWeekStartDate = DateTime.now().subtract(Duration(days: DateTime.now().weekday-1));
      if (currentWeekStartDate.difference(tableWeekStartDate).inDays >= 7) {
        return SubstitutionImageImportResult.toOld;
      }
      // Add new substitutions to weekSubstitutions
      for (final className in coursesSubstitutions.keys) {
        if (sharedState.profileManager.schoolClassFullName != className) continue; // Skip all classes that are not the users class
        final dayClassSubstitutions = coursesSubstitutions[className]!;
        final currentDaySubstitutions = sharedState.weekSubstitutions.weekSubstitutions?.putIfAbsent(
            tableWeekDay.toString(),
                () => Tuple2([], substitutionApplyDate.toString())
        ).item1.toSet();
        currentDaySubstitutions!.addAll(dayClassSubstitutions);
        sharedState.weekSubstitutions.weekSubstitutions![tableWeekDay.toString()] = Tuple2(currentDaySubstitutions.toList(), substitutionApplyDate.toString());
      }
      // Write data from table weekSubstitutions day to content
      if (!sharedState.weekSubstitutions.weekSubstitutions!.containsKey(tableWeekDay.toString())) continue;
      writeSubstitutionPlan(
          sharedState.weekSubstitutions.weekSubstitutions![tableWeekDay.toString()]!.item1,
          tableWeekDay,
          sharedState.content,
          sharedState.profileManager.subjects
      );
      okTablesCount++;
    }
    if (okTablesCount > 0) sharedState.saveCache();
    if (okTablesCount == 0) {
      return SubstitutionImageImportResult.badTables;
    } else if (okTablesCount == 1) {
      return SubstitutionImageImportResult.badTable;
    }
    return SubstitutionImageImportResult.allOk;
  }
}

Image getImageWidgetFromImage(img.Image image) {
  final encodedImage = Uint8List.fromList(img.encodeJpg(image, quality: 30));
  return Image.memory(encodedImage, filterQuality: FilterQuality.none);
}