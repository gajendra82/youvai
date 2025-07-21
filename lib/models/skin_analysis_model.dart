import 'dart:ui';

enum SkinIssueType {
  unknown,
  acne,
  closedComedone,
  brownSpot,
  melasma,
  freckle,
  mole,
  acnePustule,
  acneNodule,
  acneMark,
  darkCircle,
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
    case SkinIssueType.closedComedone:
      return "Closed Comedone";
    case SkinIssueType.brownSpot:
      return "Brown Spot";
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
    case SkinIssueType.darkCircle:
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
    final result = json['result'];
    if (result is Map<String, dynamic>) {
      void extractRectsPolys(String key, SkinIssueType type) {
        final obj = result[key];
        if (obj is Map<String, dynamic>) {
          // Rectangles
          final rects = obj['rectangle'];
          if (rects is List) {
            for (int i = 0; i < rects.length; i++) {
              final rect = rects[i];
              if (rect is Map) {
                final confidence =
                    (obj['confidence'] is List && obj['confidence'].length > i)
                        ? (obj['confidence'][i] as num?)?.toDouble()
                        : null;
                patches.add(SkinPatch(
                  issueType: type,
                  rect: Rect.fromLTWH(
                    (rect['left'] as num?)?.toDouble() ?? 0,
                    (rect['top'] as num?)?.toDouble() ?? 0,
                    (rect['width'] as num?)?.toDouble() ?? 0,
                    (rect['height'] as num?)?.toDouble() ?? 0,
                  ),
                  confidence: confidence,
                ));
              }
            }
          }
          // Polygons
          final polys = obj['polygon'];
          if (polys is List) {
            for (int i = 0; i < polys.length; i++) {
              final poly = polys[i];
              if (poly is List && poly.isNotEmpty) {
                patches.add(SkinPatch(
                  issueType: type,
                  polygon: poly
                      .map<Offset>((pt) => Offset(
                          (pt['x'] as num?)?.toDouble() ?? 0,
                          (pt['y'] as num?)?.toDouble() ?? 0))
                      .toList(),
                  confidence: (obj['confidence'] is List &&
                          obj['confidence'].length > i)
                      ? (obj['confidence'][i] as num?)?.toDouble()
                      : null,
                ));
              }
            }
          }
        }
      }

      extractRectsPolys('acne', SkinIssueType.acne);
      extractRectsPolys('closed_comedones', SkinIssueType.closedComedone);
      extractRectsPolys('brown_spot', SkinIssueType.brownSpot);
      extractRectsPolys('melasma', SkinIssueType.melasma);
      extractRectsPolys('freckle', SkinIssueType.freckle);
      extractRectsPolys('mole', SkinIssueType.mole);
      extractRectsPolys('acne_pustule', SkinIssueType.acnePustule);
      extractRectsPolys('acne_nodule', SkinIssueType.acneNodule);
      extractRectsPolys('acne_mark', SkinIssueType.acneMark);

      // Dark circle patches: add rectangles if available
      final darkCircleMark = result['dark_circle_mark'];
      if (darkCircleMark is Map) {
        if (darkCircleMark['left_eye_rect'] != null) {
          final r = darkCircleMark['left_eye_rect'];
          patches.add(SkinPatch(
            issueType: SkinIssueType.darkCircle,
            rect: Rect.fromLTWH(
              (r['left'] ?? 0).toDouble(),
              (r['top'] ?? 0).toDouble(),
              (r['width'] ?? 0).toDouble(),
              (r['height'] ?? 0).toDouble(),
            ),
          ));
        }
        if (darkCircleMark['right_eye_rect'] != null) {
          final r = darkCircleMark['right_eye_rect'];
          patches.add(SkinPatch(
            issueType: SkinIssueType.darkCircle,
            rect: Rect.fromLTWH(
              (r['left'] ?? 0).toDouble(),
              (r['top'] ?? 0).toDouble(),
              (r['width'] ?? 0).toDouble(),
              (r['height'] ?? 0).toDouble(),
            ),
          ));
        }
      }

      // Eye pouch
      if (result['left_eye_pouch_rect'] != null) {
        final r = result['left_eye_pouch_rect'];
        patches.add(SkinPatch(
          issueType: SkinIssueType.eyePouch,
          rect: Rect.fromLTWH(
            (r['left'] ?? 0).toDouble(),
            (r['top'] ?? 0).toDouble(),
            (r['width'] ?? 0).toDouble(),
            (r['height'] ?? 0).toDouble(),
          ),
        ));
      }
      if (result['right_eye_pouch_rect'] != null) {
        final r = result['right_eye_pouch_rect'];
        patches.add(SkinPatch(
          issueType: SkinIssueType.eyePouch,
          rect: Rect.fromLTWH(
            (r['left'] ?? 0).toDouble(),
            (r['top'] ?? 0).toDouble(),
            (r['width'] ?? 0).toDouble(),
            (r['height'] ?? 0).toDouble(),
          ),
        ));
      }

      // Nasolabial fold (no geometry, but you might want to show a chip)
      if (result['nasolabial_fold'] != null &&
          result['nasolabial_fold']['value'] == 1) {
        patches.add(SkinPatch(
          issueType: SkinIssueType.nasolabialFold,
          rect: null,
          confidence:
              (result['nasolabial_fold']['confidence'] as num?)?.toDouble(),
        ));
      }

      // Wrinkle: count only, no geometry
      if (result['wrinkle_count'] != null) {
        final wc = result['wrinkle_count'];
        for (final region in [
          'forehead_count',
          'left_undereye_count',
          'right_undereye_count',
          'left_mouth_count',
          'right_mouth_count',
          'left_nasolabial_count',
          'right_nasolabial_count',
          'glabella_count',
          'left_cheek_count',
          'right_cheek_count',
          'left_crowsfeet_count',
          'right_crowsfeet_count',
        ]) {
          final count = wc[region] ?? 0;
          if (count > 0) {
            patches.add(SkinPatch(
              issueType: SkinIssueType.wrinkle,
              rect: null,
              confidence: null,
            ));
          }
        }
      }
    }
    return patches;
  }
}
