import 'dart:math';
import 'package:skin_assessment/models/history_enrty.dart';

import 'history_storage.dart';

/// Sample data seeder for the Dashboard.
/// - By default it creates a few placeholder entries using network images.
/// - If [localImagePath] is provided, the first sample entry will use that local
///   path for its image (useful on desktop/mobile), and will include the
///   specific analysis percentages you requested (normal 20%, acne & acne scars 0.8%, wrinkles 2%, etc).
///
/// Usage:
/// await SampleData.seedSampleData(localImagePath: r"C:\Users\gajen\Downloads\youvai_attractiveness.png");
class SampleData {
  /// Seed sample entries.
  /// - count: total number of sample entries to create (including the local one if provided).
  /// - localImagePath: optional local file path to use for the first sample entry.
  static Future<void> seedSampleData(
      {int count = 4, String? localImagePath}) async {
    // Clear existing local history to avoid duplicates during demo
    await HistoryStorage.clearAll();

    final rng = Random();
    final now = DateTime.now().millisecondsSinceEpoch;

    // A few example analysis templates (percentages list + meta fields)
    final sampleAnalyses = [
      // The "local" analysis (user requested specific percentages)
      {
        'prediction': 'Mixed - Minor Issues',
        'percentages': [
          {'condition': 'Normal', 'percent': '20'},
          {'condition': 'Acne & Acne scars', 'percent': '0.8'},
          {'condition': 'Wrinkle', 'percent': '2'},
          {'condition': 'Pigmentation', 'percent': '5'},
          {'condition': 'Pores', 'percent': '8'},
        ],
        'notes':
            'Sample analysis using local image (youvai_attractiveness.png)',
      },
      // A few other synthetic samples for the dashboard look
      {
        'prediction': 'Oily',
        'percentages': [
          {'condition': 'Normal', 'percent': '10'},
          {'condition': 'Acne & Acne scars', 'percent': '18'},
          {'condition': 'Wrinkle', 'percent': '1.2'},
          {'condition': 'Blackhead', 'percent': '12'},
          {'condition': 'Pores', 'percent': '22'},
        ],
        'notes': 'Synthetic oily-skin sample',
      },
      {
        'prediction': 'Dry',
        'percentages': [
          {'condition': 'Normal', 'percent': '15'},
          {'condition': 'Pigmentation', 'percent': '8'},
          {'condition': 'Wrinkle', 'percent': '3.5'},
          {'condition': 'Pores', 'percent': '6'},
          {'condition': 'Brown Spot', 'percent': '4'},
        ],
        'notes': 'Synthetic dry-skin sample',
      },
      {
        'prediction': 'Combination',
        'percentages': [
          {'condition': 'Normal', 'percent': '18'},
          {'condition': 'Acne & Acne scars', 'percent': '4'},
          {'condition': 'Wrinkle', 'percent': '2'},
          {'condition': 'Pigmentation', 'percent': '6'},
          {'condition': 'Pores', 'percent': '10'},
        ],
        'notes': 'Synthetic combination-skin sample',
      },
    ];

    // Ensure at least 'count' templates available by repeating if needed.
    final templates = <Map<String, dynamic>>[];
    for (int i = 0; i < count; i++) {
      templates.add(sampleAnalyses[i % sampleAnalyses.length]);
    }

    for (var i = 0; i < templates.length; i++) {
      final tpl = templates[i];
      final id = (now + i).toString();

      String? imagePath;
      String? imageBase64;

      // If the user provided a localImagePath, use it for the first entry
      if (i == 0 && localImagePath != null && localImagePath.isNotEmpty) {
        imagePath = localImagePath;
      } else {
        // Use picsum placeholders for other samples
        final seed = rng.nextInt(10000);
        imagePath = 'https://picsum.photos/seed/$seed/800/800';
      }

      // Very simple attractiveness score for demo (random-ish but within range)
      double attractivenessScore;
      if (i == 0 && localImagePath != null) {
        // For the user-requested sample, set a reasonable sample score
        attractivenessScore = 6.78;
      } else {
        attractivenessScore = 5.0 + rng.nextDouble() * 4.0; // 5.0 - 9.0
        attractivenessScore =
            double.parse(attractivenessScore.toStringAsFixed(2));
      }

      final analysis = {
        'prediction': tpl['prediction'],
        'percentages': tpl['percentages'],
        'notes': tpl['notes'],
        // keep a human-friendly summary string as some parsers expect text
        'summary_text': tpl['percentages']
            .map((p) => "${p['condition']}: ${p['percent']}%")
            .join('\n'),
      };

      final entry = HistoryEntry(
        id: id,
        timestamp: now - (i * 1000 * 60 * 60),
        imageBase64: imageBase64,
        imagePath: imagePath,
        attractivenessScore: attractivenessScore,
        analysis: analysis,
        note: 'Sample entry #${i + 1}',
      );

      await HistoryStorage.saveEntry(entry);
    }
  }
}
