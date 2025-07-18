import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/skin_analysis_model.dart';
import 'skin_analysis_event.dart';
import 'skin_analysis_state.dart';

class SkinAnalysisBloc extends Bloc<SkinAnalysisEvent, SkinAnalysisState> {
  SkinAnalysisBloc() : super(SkinAnalysisInitial()) {
    on<LoadSkinAnalysis>(_onLoadSkinAnalysis);
  }

  Future<void> _onLoadSkinAnalysis(
      LoadSkinAnalysis event, Emitter<SkinAnalysisState> emit) async {
    try {
      final List<SkinPatch> patches = [];
      final analysisJson = event.analysisJson;
      // --- AILab Format ---
      if (analysisJson['result'] != null && analysisJson['result'] is Map) {
        final result = analysisJson['result'] as Map;

        // Helper for extracting rectangles and polygons from known keys
        void extractRectsAndPolys(String key, SkinIssueType type) {
          final issue = result[key];
          if (issue != null && issue is Map) {
            // Rectangles
            final rectangles = issue['rectangle'];
            if (rectangles != null && rectangles is List) {
              for (final rect in rectangles) {
                if (rect is Map) {
                  final width = (rect['width'] as num?)?.toDouble() ?? 0;
                  final height = (rect['height'] as num?)?.toDouble() ?? 0;
                  if (width > 0 && height > 0) {
                    patches.add(SkinPatch(
                      issueType: type,
                      rect: Rect.fromLTWH(
                        (rect['left'] as num?)?.toDouble() ?? 0,
                        (rect['top'] as num?)?.toDouble() ?? 0,
                        width,
                        height,
                      ),
                    ));
                  }
                }
              }
            }
            // Polygons
            final polygons = issue['polygon'];
            if (polygons != null && polygons is List) {
              for (final poly in polygons) {
                if (poly is List && poly.isNotEmpty) {
                  final points = <Offset>[];
                  for (final p in poly) {
                    if (p is Map && p['x'] != null && p['y'] != null) {
                      points.add(Offset(
                        (p['x'] as num).toDouble(),
                        (p['y'] as num).toDouble(),
                      ));
                    }
                  }
                  if (points.isNotEmpty) {
                    patches.add(SkinPatch(issueType: type, polygon: points));
                  }
                }
              }
            }
          }
        }

        // Standard skin problems
        extractRectsAndPolys('acne', SkinIssueType.acne);
        extractRectsAndPolys('closed_comedones', SkinIssueType.closedComedone);
        extractRectsAndPolys('brown_spot', SkinIssueType.brownSpot);
        extractRectsAndPolys('melasma', SkinIssueType.melasma);
        extractRectsAndPolys('freckle', SkinIssueType.freckle);
        extractRectsAndPolys('mole', SkinIssueType.mole);
        extractRectsAndPolys('acne_pustule', SkinIssueType.acnePustule);
        extractRectsAndPolys('acne_nodule', SkinIssueType.acneNodule);
        extractRectsAndPolys('acne_mark', SkinIssueType.acneMark);
        ;

        // Dark Spots (as Hyperpigmentation, marked by 'melanin_mark')
        final melaninMark = result['melanin_mark'];
        if (melaninMark != null &&
            melaninMark is Map &&
            melaninMark['polygon'] != null &&
            melaninMark['polygon'] is List) {
          for (final poly in melaninMark['polygon']) {
            if (poly is List && poly.isNotEmpty) {
              final points = <Offset>[];
              for (final p in poly) {
                if (p is Map && p['x'] != null && p['y'] != null) {
                  points.add(Offset(
                    (p['x'] as num).toDouble(),
                    (p['y'] as num).toDouble(),
                  ));
                }
              }
              if (points.isNotEmpty) {
                patches.add(SkinPatch(
                    issueType: SkinIssueType.darkCircle, polygon: points));
              }
            }
          }
        }

        // Dark Circle (from dark_circle_mark region rectangles)
        final darkCircleMark = result['dark_circle_mark'];
        if (darkCircleMark != null && darkCircleMark is Map) {
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

        // Eye Pouch
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

        // Nasolabial Fold
        if (result['nasolabial_fold'] != null &&
            result['nasolabial_fold']['value'] == 1) {
          patches.add(SkinPatch(
            issueType: SkinIssueType.nasolabialFold,
            rect: null,
            confidence: result['nasolabial_fold']['confidence']?.toDouble(),
          ));
        }

        // Wrinkle (from wrinkle_count; only if count > 0)
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
                rect: null, // If you have location, use it here
                confidence: null,
              ));
            }
          }
        }

        emit(SkinAnalysisLoaded(patches: patches, image: event.inputImage));
        return;
      }

      // --- YOLOv8 Format ---
      if (analysisJson['results'] != null && analysisJson['results'] is List) {
        final results = analysisJson['results'] as List;
        for (final box in results) {
          if (box is Map) {
            final confidence = (box['confidence'] as num?)?.toDouble();
            final dynamic classValue = box['class'];
            SkinIssueType type;
            if (classValue is String) {
              type = _nameToSkinIssueType(classValue);
            } else if (classValue is int) {
              type = _yoloClassToSkinIssueType(classValue);
            } else {
              type = SkinIssueType.unknown;
            }

            if (box['bbox'] is Map) {
              final bbox = box['bbox'] as Map;
              patches.add(SkinPatch(
                issueType: type,
                rect: Rect.fromLTWH(
                  (bbox['left'] as num?)?.toDouble() ?? 0,
                  (bbox['top'] as num?)?.toDouble() ?? 0,
                  (bbox['width'] as num?)?.toDouble() ?? 0,
                  (bbox['height'] as num?)?.toDouble() ?? 0,
                ),
                confidence: confidence,
              ));
            } else if (box['bbox'] is List) {
              final bboxList = box['bbox'] as List;
              if (bboxList.length == 4) {
                final left = (bboxList[0] as num?)?.toDouble() ?? 0;
                final top = (bboxList[1] as num?)?.toDouble() ?? 0;
                final right = (bboxList[2] as num?)?.toDouble() ?? 0;
                final bottom = (bboxList[3] as num?)?.toDouble() ?? 0;
                final width = right - left;
                final height = bottom - top;
                patches.add(SkinPatch(
                  issueType: type,
                  rect: Rect.fromLTWH(left, top, width, height),
                  confidence: confidence,
                ));
              }
            }
          }
        }
        emit(SkinAnalysisLoaded(patches: patches, image: event.inputImage));
        return;
      }

      emit(SkinAnalysisError("Failed to parse analysis: Unrecognized format"));
    } catch (e, st) {
      emit(SkinAnalysisError("Failed to parse analysis: $e"));
    }
  }

  // Map YOLOv8 class name (string) to SkinIssueType
  SkinIssueType _nameToSkinIssueType(String? clsName) {
    switch (clsName?.toLowerCase()) {
      case "acne":
        return SkinIssueType.acne;
      case "closed_comedone":
        return SkinIssueType.closedComedone;
      case "brown_spot":
        return SkinIssueType.brownSpot;
      case "melasma":
        return SkinIssueType.melasma;
      case "freckle":
        return SkinIssueType.freckle;
      case "mole":
        return SkinIssueType.mole;
      case "acne_pustule":
        return SkinIssueType.acnePustule;
      case "acne_nodule":
        return SkinIssueType.acneNodule;
      case "acne_mark":
        return SkinIssueType.acneMark;
      case "dark_circle":
        return SkinIssueType.darkCircle;
      case "wrinkle":
        return SkinIssueType.wrinkle;
      case "eye_pouch":
        return SkinIssueType.eyePouch;
      case "nasolabial_fold":
        return SkinIssueType.nasolabialFold;
      default:
        return SkinIssueType.unknown;
    }
  }
}

// Map YOLOv8 class index to SkinIssueType
SkinIssueType _yoloClassToSkinIssueType(int cls) {
  switch (cls) {
    case 0:
      return SkinIssueType.acne;
    case 1:
      return SkinIssueType.closedComedone;
    case 2:
      return SkinIssueType.brownSpot;
    case 3:
      return SkinIssueType.melasma;
    case 4:
      return SkinIssueType.freckle;
    case 5:
      return SkinIssueType.mole;
    case 6:
      return SkinIssueType.acnePustule;
    case 7:
      return SkinIssueType.acneNodule;
    case 8:
      return SkinIssueType.acneMark;
    case 9:
      return SkinIssueType.darkCircle;
    case 10:
      return SkinIssueType.wrinkle;
    case 11:
      return SkinIssueType.eyePouch;
    case 12:
      return SkinIssueType.nasolabialFold;
    default:
      return SkinIssueType.unknown;
  }
}
