import 'dart:ui';

enum SkinIssueType {
  unknown,
  acne,
  acne_scar,
  pores,
  closedComedone,
  SunSpot,
  melasma,
  freckle,
  mole,
  acnePustule,
  acneNodule,
  acneMark,
  dark_Circle,
  wrinkle,
  eyePouch,
  nasolabialFold,
  darkSpots,
  oiliness,
  dryness,
}

String skinIssueTypeDisplayName(SkinIssueType type) {
  switch (type) {
    case SkinIssueType.acne:
      return "Acne";
    case SkinIssueType.acne_scar:
      return "scar";
    case SkinIssueType.pores:
      return "PORES";
    case SkinIssueType.closedComedone:
      return "Closed Comedone";
    case SkinIssueType.SunSpot:
      return "pores";
    case SkinIssueType.melasma:
      return "Melasma";
    case SkinIssueType.freckle:
      return "Freckle";
    case SkinIssueType.mole:
      return "Mole";
    case SkinIssueType.acnePustule:
      return "Acne Pustule";
    case SkinIssueType.acneNodule:
      return "Acne Nodule";
    case SkinIssueType.acneMark:
      return "Acne Mark";
    case SkinIssueType.dark_Circle:
      return "Dark Circle";
    case SkinIssueType.wrinkle:
      return "Wrinkle";
    case SkinIssueType.eyePouch:
      return "Eye Pouch";
    case SkinIssueType.nasolabialFold:
      return "Nasolabial Fold";
    default:
      return "Unknown";
  }
}

class SkinPatch {
  final SkinIssueType issueType;
  final Rect? rect;
  final List<Offset>? polygon;
  final double? confidence;

  SkinPatch({
    required this.issueType,
    this.rect,
    this.polygon,
    this.confidence,
  });

  bool containsPoint(Offset point) {
    if (rect != null) return rect!.contains(point);
    if (polygon != null && polygon!.isNotEmpty)
      return _pointInPolygon(point, polygon!);
    return false;
  }

  bool _pointInPolygon(Offset point, List<Offset> polygon) {
    int intersectCount = 0;
    for (int j = 0; j < polygon.length; j++) {
      int i = (j + 1) % polygon.length;
      if (((polygon[j].dy > point.dy) != (polygon[i].dy > point.dy)) &&
          (point.dx <
              (polygon[i].dx - polygon[j].dx) *
                      (point.dy - polygon[j].dy) /
                      (polygon[i].dy - polygon[j].dy) +
                  polygon[j].dx)) {
        intersectCount++;
      }
    }
    return (intersectCount % 2 == 1);
  }

  factory SkinPatch.none() =>
      SkinPatch(issueType: SkinIssueType.unknown, rect: null, polygon: null);

  // --- THE IMPORTANT PART ---
  static List<SkinPatch> fromJsonAll(Map<String, dynamic> json) {
    final List<SkinPatch> patches = [];

    final detections = json['detections'];
    if (detections is List) {
      for (final item in detections) {
        if (item is Map<String, dynamic>) {
          final label = item['label'] as String? ?? 'unknown';
          final confidence = (item['confidence'] as num?)?.toDouble();
          final box = item['box'];

          final issueType = SkinIssueType.values.firstWhere(
            (e) => e.name.toLowerCase() == label.toLowerCase(),
            orElse: () => SkinIssueType.unknown,
          );

          Rect? rect;
          if (box is List && box.length == 4) {
            final x1 = (box[0] as num?)?.toDouble() ?? 0;
            final y1 = (box[1] as num?)?.toDouble() ?? 0;
            final x2 = (box[2] as num?)?.toDouble() ?? 0;
            final y2 = (box[3] as num?)?.toDouble() ?? 0;

            final left = x1;
            final top = y1;
            final width = (x2 - x1).clamp(0, double.infinity);
            final height = (y2 - y1).clamp(0, double.infinity);
            rect = Rect.fromLTWH(
              left.toDouble(),
              top.toDouble(),
              width.toDouble(),
              height.toDouble(),
            );
          }

          patches.add(SkinPatch(
            issueType: issueType,
            rect: rect,
            confidence: confidence,
          ));
        }
      }
    }

    return patches;
  }
}
