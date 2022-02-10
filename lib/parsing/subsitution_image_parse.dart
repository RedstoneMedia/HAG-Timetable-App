import 'dart:collection';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:opencv/opencv.dart';
import 'package:path_provider/path_provider.dart';
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
  final List<Tuple2<int, Tuple2<int, int>>> brightest = findBrightestPixels(grayscaleImage);
  // Trace contours starting at brightest pixel (should be somewhere in the monitor background, since the monitor background color is white) then going down
  return (await warpToCorners(brightest[0].item2, grayscaleImage, image, shrinkFactor: shrinkFactor))?.item1;
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

Future<SplayTreeMap<Tuple2<int, int>, String>?> getCellsText(img.Image tableWarpedImage, TextDetectorV2 textDetector) async {
  final grayscaleImage = img.grayscale(tableWarpedImage.clone());
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
      cellsText[rowColumnPosition] = text.isEmpty ? "" : text;
    }
  }
  return cellsText;
}

Future<Tuple2<DateTime, Map<String, List<Map<String, String>>>>?> getCoursesSubstitutionsFromTable(img.Image image, TextDetectorV2 textDetector) async {
  // Warp to corners of table. Starting at bottom then going up to find contours
  final grayscaleImage = img.grayscale(image.clone());
  final warpToCornersResult = await warpToCorners(
      Tuple2((image.width / 2).round(), image.height-1),
      grayscaleImage,
      image,
      minPointsLength: 10000,
      searchYDirection: -1,
      contourWindowSize: 3,
      contourMinChange: 19
  );
  if (warpToCornersResult == null) return null;
  // Get image cropped to be above the table and get the text of it
  final tableYTop = ((warpToCornersResult.item2[0].item2 + warpToCornersResult.item2[1].item2) / 2).ceil();
  final aboveTableImage = img.copyCrop(image, 0, 0, image.width, tableYTop);
  final aboveTableText = (await detectText(aboveTableImage, textDetector)).text;
  // Extract datetime and page information
  final regexp = RegExp(r"^\s*(?<day>\d{1,2}).(?<month>\d{1,2}).(?<year>\d{4}) [a-zA-Z]{3,}\s+(\(Seite (?<page>\d)/(?<totalPages>\d)\)){0,1}", multiLine: true);
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
    if (!substitution.containsKey("Klassen")) continue; // TODO: Try to restore course name, if present substitution data matches data from the timetable
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
