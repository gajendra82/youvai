import 'dart:convert';
import 'package:flutter/material.dart';

class SkinConditionResultPage extends StatelessWidget {
  final Map<String, dynamic> gradioResult;
  final Map<String, dynamic>? patchJson; // <-- Pass the first API JSON here

  const SkinConditionResultPage({
    Key? key,
    required this.gradioResult,
    this.patchJson,
  }) : super(key: key);

  List<Map<String, dynamic>> extractSkinSummaries(
      dynamic gradioResult, dynamic patchJson) {
    final List<dynamic> outputs = gradioResult['data']?['outpUt'] ?? [];
    final patchStats = extractPatchStats(patchJson);

    return outputs
        .where((o) => o['analysis'] != null && o['output'] != null)
        .map((result) {
      String analysis = result['analysis'];
      List<Map<String, String>> percentages = [];

      if (analysis.trim().startsWith('[')) {
        try {
          final decoded = json.decode(analysis);
          if (decoded is List) {
            for (var item in decoded) {
              final match =
                  RegExp(r'([A-Za-z ]+)[(:]\s*([\d.]+)%').firstMatch(item);
              if (match != null) {
                final condition = match.group(1)!.trim();
                if (!condition.toLowerCase().contains('skin redness')) {
                  percentages.add(
                      {'condition': condition, 'percent': match.group(2)!});
                }
              }
            }
          }
        } catch (_) {
          for (var line in analysis.split('\n')) {
            final match =
                RegExp(r'([A-Za-z ]+)[(:]\s*([\d.]+)%').firstMatch(line);
            if (match != null) {
              final condition = match.group(1)!.trim();
              if (!condition.toLowerCase().contains('skin redness')) {
                percentages
                    .add({'condition': condition, 'percent': match.group(2)!});
              }
            }
          }
        }
      } else {
        for (var line in analysis.split('\n')) {
          final match =
              RegExp(r'([A-Za-z ]+)[(:]\s*([\d.]+)%').firstMatch(line);
          if (match != null) {
            final condition = match.group(1)!.trim();
            if (!condition.toLowerCase().contains('skin redness')) {
              percentages
                  .add({'condition': condition, 'percent': match.group(2)!});
            }
          }
        }
      }

      String output = result['output'];
      String mainDiagnosis = '';
      final diagnosisRegex = RegExp(
          r'Confirmed Diagnosis[:\s]*([\s\S]*?)(\n\n|$)',
          caseSensitive: false);
      final diagnosisMatch = diagnosisRegex.firstMatch(output);
      if (diagnosisMatch != null) {
        mainDiagnosis = diagnosisMatch.group(1)!.trim();
      } else {
        mainDiagnosis = output.split('\n').first.trim();
      }

      String recommendations = '';
      final recRegex =
          RegExp(r'Recommended Medicines[:\s]*([\s\S]*)', caseSensitive: false);
      final recMatch = recRegex.firstMatch(output);
      if (recMatch != null) {
        recommendations = recMatch.group(1)!.trim();
      } else {
        recommendations = output.trim();
      }

      Map<String, dynamic> assessmentData = getAssessment(percentages);

      double attractivenessScore =
          calculateCombinedAttractivenessScore(percentages, patchStats);

      return {
        'percentages': percentages,
        'mainDiagnosis': mainDiagnosis,
        'recommendations': recommendations,
        'fullOutput': output,
        'assessment': assessmentData['assessment'],
        'scoreOutOf10': assessmentData['scoreOutOf10'],
        'primaryCondition': assessmentData['primaryCondition'],
        'imageUrl': result['image_url'],
        'attractivenessScore': attractivenessScore,
      };
    }).toList();
  }

  /// Extract counts/statistics from the first (patch) JSON
  Map<String, dynamic> extractPatchStats(dynamic patchJson) {
    if (patchJson == null || patchJson['result'] == null) return {};
    final r = patchJson['result'];
    final Map<String, int> patchCounts = {};

    // Example: count for acne, brown_spot etc, using count field or rectangles
    for (final k in [
      'acne',
      'brown_spot',
      'closed_comedones',
      'acne_mark',
      'acne_nodule',
      'acne_pustule',
      'mole',
    ]) {
      if (r[k] != null) {
        if (r[k]['count'] != null) {
          patchCounts[k] = int.tryParse(r[k]['count'].toString()) ?? 0;
        } else if (r[k]['rectangle'] != null &&
            r[k]['rectangle'] is List &&
            r[k]['rectangle'].isNotEmpty) {
          patchCounts[k] = (r[k]['rectangle'] as List).length;
        }
      }
    }
    // Wrinkle counts as sum of all wrinkle_count fields
    if (r['wrinkle_count'] != null && r['wrinkle_count'] is Map) {
      int wrinkleSum = 0;
      r['wrinkle_count']
          .forEach((k, v) => wrinkleSum += int.tryParse(v.toString()) ?? 0);
      patchCounts['wrinkle'] = wrinkleSum;
    }
    // Dark Circle
    if (r['dark_circle'] != null && r['dark_circle']['value'] != null) {
      patchCounts['dark_circle'] =
          int.tryParse(r['dark_circle']['value'].toString()) ?? 0;
    }
    // Eye Pouch
    if (r['eye_pouch'] != null && r['eye_pouch']['value'] != null) {
      patchCounts['eye_pouch'] =
          int.tryParse(r['eye_pouch']['value'].toString()) ?? 0;
    }
    // Add more as needed for your logic.

    return patchCounts;
  }

  Map<String, dynamic> getAssessment(List<Map<String, String>> percentages) {
    if (percentages.isEmpty) {
      return {
        'assessment': "Insufficient data for assessment.",
        'scoreOutOf10': 0.0,
        'primaryCondition': ""
      };
    }
    Map<String, String>? highest = percentages.reduce((a, b) =>
        double.tryParse(a['percent'] ?? "0")! >
                double.tryParse(b['percent'] ?? "0")!
            ? a
            : b);
    double value = double.tryParse(highest['percent'] ?? "0") ?? 0.0;
    String condition = highest['condition'] ?? "";

    String risk;
    if (value >= 70) {
      risk = "High";
    } else if (value >= 40) {
      risk = "Moderate";
    } else if (value >= 20) {
      risk = "Mild";
    } else {
      risk = "Minimal";
    }
    double score = (value / 10).clamp(0.0, 10.0);
    return {
      'assessment':
          "Primary Concern: $condition ($value%)\nAssessment: $risk risk for this condition.",
      'scoreOutOf10': score,
      'primaryCondition': condition,
    };
  }

  /// Combine both JSONs for more accurate attractiveness score.
  double calculateCombinedAttractivenessScore(
      List<Map<String, String>> percentages, Map<String, dynamic> patchStats) {
    double normal = 0;
    double negative = 0;
    final negativeConditions = [
      "dry",
      "acne",
      "wrinkles",
      "dark spots",
      "blackheads",
      "pores",
      "eye bags",
      "dark circle",
      "mole",
      "brown spot",
      "comedone",
      "eye pouch",
      "nasolabial fold"
    ];
    for (var entry in percentages) {
      final cond = entry['condition']?.toLowerCase() ?? "";
      final val = double.tryParse(entry['percent'] ?? "0") ?? 0;
      if (cond.contains("normal")) {
        normal += val;
      } else if (negativeConditions.any((c) => cond.contains(c))) {
        negative += val;
      }
    }

    // Patch count penalties
    double patchPenalty = 0.0;
    for (final k in patchStats.keys) {
      final v = patchStats[k];
      if (v is int && v > 0) {
        if (['acne', 'brown_spot', 'closed_comedones', 'mole'].contains(k)) {
          patchPenalty += v * 0.18;
        } else if (['wrinkle', 'dark_circle', 'eye_pouch'].contains(k)) {
          patchPenalty += v * 0.12;
        }
      }
    }

    // Score: start from 8, add positive, subtract negative and patch penalty
    double score =
        8.0 + (normal / 100) * 2.0 - (negative / 100) * 2.0 - patchPenalty;
    return score.clamp(6.01, 10.0);
  }

  Widget buildAssessmentChart(double score, {String? label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 2.0),
            child: Text(
              "$label Assessment Score",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        SizedBox(
          height: 28,
          child: Stack(
            children: [
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (score / 10).clamp(0.0, 1.0),
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: score >= 8.5
                        ? Colors.green
                        : score >= 7.5
                            ? Colors.lightGreen
                            : score >= 6.5
                                ? Colors.orange
                                : Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Text(
                    "${score.toStringAsFixed(2)} / 10",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildAttractivenessChart(double score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 2.0),
          child: Text(
            "Attractiveness Score",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 28,
          child: Stack(
            children: [
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (score / 10).clamp(0.0, 1.0),
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: score >= 8.5
                        ? Colors.green
                        : score >= 7.5
                            ? Colors.lightGreen
                            : score >= 6.5
                                ? Colors.orange
                                : Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Text(
                    "${score.toStringAsFixed(2)} / 10",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildIndividualPercentagesChart(
      List<Map<String, String>> percentages) {
    if (percentages.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Condition Percentages",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ...percentages.map((p) {
          final cond = p['condition'];
          final val = double.tryParse(p['percent'] ?? "0") ?? 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(cond!,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                ),
                Expanded(
                  flex: 6,
                  child: LinearProgressIndicator(
                    value: (val / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade300,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Text('${val.toStringAsFixed(1)}%'),
              ],
            ),
          );
        }),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final summaries = extractSkinSummaries(gradioResult, patchJson);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skin Analysis Results'),
      ),
      body: summaries.isEmpty
          ? const Center(child: Text('No skin condition data found.'))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: summaries.length,
              itemBuilder: (context, i) {
                final summary = summaries[i];
                final percentages = summary['percentages'] as List<dynamic>;
                final imageUrl = summary['imageUrl'] as String?;
                final mainDiagnosis = summary['mainDiagnosis'] as String;
                final assessment = summary['assessment'] as String;
                final scoreOutOf10 = summary['scoreOutOf10'] as double;
                final attractivenessScore =
                    summary['attractivenessScore'] as double;
                final primaryCondition = summary['primaryCondition'] as String;
                final fullOutput = summary['fullOutput'] as String;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageUrl != null && imageUrl.isNotEmpty)
                          Center(
                            child: Image.network(
                              imageUrl,
                              height: 180,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, size: 80),
                            ),
                          ),
                        buildIndividualPercentagesChart(
                            percentages.cast<Map<String, String>>()),
                        const SizedBox(height: 10),
                        buildAssessmentChart(scoreOutOf10,
                            label: primaryCondition),
                        const SizedBox(height: 10),
                        buildAttractivenessChart(attractivenessScore),
                        const SizedBox(height: 10),
                        Text(
                          assessment,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple),
                        ),
                        const Divider(height: 24),
                        const Text('Diagnosis:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(mainDiagnosis),
                        const Divider(height: 24),
                        ExpansionTile(
                          title: const Text('View Recommendations & Details'),
                          children: [Text(fullOutput)],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
