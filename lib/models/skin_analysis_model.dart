import 'package:flutter/material.dart';

enum SkinIssueType {
  acne,
  brownSpot,
  closedComedone,
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
  unknown,
}

String skinIssueTypeDisplayName(SkinIssueType type) {
  switch (type) {
    case SkinIssueType.acne:
      return 'Acne';
    case SkinIssueType.brownSpot:
      return 'Brown Spot';
    case SkinIssueType.closedComedone:
      return 'Closed Comedone';
    case SkinIssueType.melasma:
      return 'Melasma';
    case SkinIssueType.freckle:
      return 'Freckle';
    case SkinIssueType.mole:
      return 'Mole';
    case SkinIssueType.acnePustule:
      return 'Acne Pustule';
    case SkinIssueType.acneNodule:
      return 'Acne Nodule';
    case SkinIssueType.acneMark:
      return 'Acne Mark';
    case SkinIssueType.darkCircle:
      return 'Dark Circle';
    case SkinIssueType.wrinkle:
      return 'Wrinkle';
    case SkinIssueType.eyePouch:
      return 'Eye Pouch';
    case SkinIssueType.nasolabialFold:
      return 'Nasolabial Fold';
    case SkinIssueType.unknown:
      return 'Unknown';
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

  /// Extended parser for all types present in the JSON
  static List<SkinPatch> fromJsonAll(Map<String, dynamic> json) {
    final List<SkinPatch> patches = [];
    final result = json['result'] ?? {};

    // Acne
    if (result['acne'] != null) {
      final acne = result['acne'];
      if (acne['rectangle'] is List) {
        for (int i = 0; i < acne['rectangle'].length; i++) {
          final r = acne['rectangle'][i];
          patches.add(SkinPatch(
            issueType: SkinIssueType.acne,
            rect: Rect.fromLTWH(
              (r['left'] ?? 0).toDouble(),
              (r['top'] ?? 0).toDouble(),
              (r['width'] ?? 0).toDouble(),
              (r['height'] ?? 0).toDouble(),
            ),
            confidence:
                (acne['confidence'] is List && acne['confidence'].length > i)
                    ? (acne['confidence'][i] as num?)?.toDouble()
                    : null,
          ));
        }
      }
      if (acne['polygon'] is List) {
        for (var poly in acne['polygon']) {
          patches.add(SkinPatch(
            issueType: SkinIssueType.acne,
            polygon: (poly is List)
                ? poly
                    .map((p) => Offset(
                        (p['x'] as num).toDouble(), (p['y'] as num).toDouble()))
                    .toList()
                : null,
          ));
        }
      }
    }

    // Brown Spot
    if (result['brown_spot'] != null) {
      final brownSpot = result['brown_spot'];
      if (brownSpot['rectangle'] is List) {
        for (int i = 0; i < brownSpot['rectangle'].length; i++) {
          final r = brownSpot['rectangle'][i];
          patches.add(SkinPatch(
            issueType: SkinIssueType.brownSpot,
            rect: Rect.fromLTWH(
              (r['left'] ?? 0).toDouble(),
              (r['top'] ?? 0).toDouble(),
              (r['width'] ?? 0).toDouble(),
              (r['height'] ?? 0).toDouble(),
            ),
            confidence: (brownSpot['confidence'] is List &&
                    brownSpot['confidence'].length > i)
                ? (brownSpot['confidence'][i] as num?)?.toDouble()
                : null,
          ));
        }
      }
      if (brownSpot['polygon'] is List) {
        for (var poly in brownSpot['polygon']) {
          patches.add(SkinPatch(
            issueType: SkinIssueType.brownSpot,
            polygon: (poly is List)
                ? poly
                    .map((p) => Offset(
                        (p['x'] as num).toDouble(), (p['y'] as num).toDouble()))
                    .toList()
                : null,
          ));
        }
      }
    }

    // Closed Comedones
    if (result['closed_comedones'] != null) {
      final cc = result['closed_comedones'];
      if (cc['rectangle'] is List) {
        for (int i = 0; i < cc['rectangle'].length; i++) {
          final r = cc['rectangle'][i];
          patches.add(SkinPatch(
            issueType: SkinIssueType.closedComedone,
            rect: Rect.fromLTWH(
              (r['left'] ?? 0).toDouble(),
              (r['top'] ?? 0).toDouble(),
              (r['width'] ?? 0).toDouble(),
              (r['height'] ?? 0).toDouble(),
            ),
            confidence:
                (cc['confidence'] is List && cc['confidence'].length > i)
                    ? (cc['confidence'][i] as num?)?.toDouble()
                    : null,
          ));
        }
      }
      if (cc['polygon'] is List) {
        for (var poly in cc['polygon']) {
          patches.add(SkinPatch(
            issueType: SkinIssueType.closedComedone,
            polygon: (poly is List)
                ? poly
                    .map((p) => Offset(
                        (p['x'] as num).toDouble(), (p['y'] as num).toDouble()))
                    .toList()
                : null,
          ));
        }
      }
    }

    // Mole
    if (result['mole'] != null) {
      final mole = result['mole'];
      if (mole['rectangle'] is List) {
        for (int i = 0; i < mole['rectangle'].length; i++) {
          final r = mole['rectangle'][i];
          patches.add(SkinPatch(
            issueType: SkinIssueType.mole,
            rect: Rect.fromLTWH(
              (r['left'] ?? 0).toDouble(),
              (r['top'] ?? 0).toDouble(),
              (r['width'] ?? 0).toDouble(),
              (r['height'] ?? 0).toDouble(),
            ),
            confidence:
                (mole['confidence'] is List && mole['confidence'].length > i)
                    ? (mole['confidence'][i] as num?)?.toDouble()
                    : null,
          ));
        }
      }
      if (mole['polygon'] is List) {
        for (var poly in mole['polygon']) {
          patches.add(SkinPatch(
            issueType: SkinIssueType.mole,
            polygon: (poly is List)
                ? poly
                    .map((p) => Offset(
                        (p['x'] as num).toDouble(), (p['y'] as num).toDouble()))
                    .toList()
                : null,
          ));
        }
      }
    }

    // Melasma
    if (result['melasma'] != null && result['melasma']['value'] == 1) {
      patches.add(SkinPatch(
        issueType: SkinIssueType.melasma,
        rect: null,
        confidence: result['melasma']['confidence']?.toDouble(),
      ));
    }

    // Freckle
    if (result['freckle'] != null && result['freckle']['value'] == 1) {
      patches.add(SkinPatch(
        issueType: SkinIssueType.freckle,
        rect: null,
        confidence: result['freckle']['confidence']?.toDouble(),
      ));
    }

    // Dark Circle (from dark_circle_mark region rectangles)
    if (result['dark_circle_mark'] != null) {
      final dcm = result['dark_circle_mark'];
      if (dcm['left_eye_rect'] != null) {
        final r = dcm['left_eye_rect'];
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
      if (dcm['right_eye_rect'] != null) {
        final r = dcm['right_eye_rect'];
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

    // Eye Pouch (from left_eye_pouch_rect and right_eye_pouch_rect)
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

    // Nasolabial Fold (region rectangles not provided; add as summary)
    if (result['nasolabial_fold'] != null &&
        result['nasolabial_fold']['value'] == 1) {
      patches.add(SkinPatch(
        issueType: SkinIssueType.nasolabialFold,
        rect: null,
        confidence: result['nasolabial_fold']['confidence']?.toDouble(),
      ));
    }

    // Wrinkle (from wrinkle_count and *_wrinkle_info; only if count > 0)
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

    // TODO: Add more types as needed, e.g. acne_mark, acne_nodule, acne_pustule if locations are provided in API

    return patches;
  }
}
