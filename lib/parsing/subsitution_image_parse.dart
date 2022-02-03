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

Future<String> detectText(img.Image image, TextDetectorV2 textDetector) async {
  final monitorImageTempFile = File("${(await getTemporaryDirectory()).path}/textDetect.tmp");
  await monitorImageTempFile.writeAsBytes(img.encodeJpg(image, quality: 90));
  final RecognisedText recognisedText = await textDetector.processImage(InputImage.fromFile(monitorImageTempFile));
  await monitorImageTempFile.delete();
  return recognisedText.text;
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