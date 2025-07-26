import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:skin_assessment/widgets/doctor_card.dart';

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
        .map<Map<String, dynamic>>((result) {
      String analysis = result['analysis'];
      List<Map<String, String>> percentages = [];

      if (analysis.trim().startsWith('[')) {
        try {
          final decoded = json.decode(analysis);
          print(decoded);
          if (decoded is List) {
            for (var item in decoded) {
              // Each item may be a string with multiple conditions separated by commas or newlines
              final lines = item.toString().split(RegExp(r'[,\n]'));
              for (var line in lines) {
                final match =
                    RegExp(r'([A-Za-z ]+)[(:]\s*([\d.]+)%').firstMatch(line);
                if (match != null) {
                  final condition = match.group(1)!.trim();
                  if (!condition.toLowerCase().contains('skin redness')) {
                    percentages.add(
                        {'condition': condition, 'percent': match.group(2)!});
                  }
                }
              }
            }
          }
        } catch (e) {
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

  // Map condition names to icons and colors
  IconData _getConditionIcon(String condition) {
    final cond = condition.toLowerCase();
    if (cond.contains('normal')) return Icons.check_circle;
    if (cond.contains('wrinkle')) return Icons.blur_on;
    if (cond.contains('acne')) return Icons.bubble_chart;
    if (cond.contains('blackhead')) return Icons.circle;
    if (cond.contains('dark spot')) return Icons.brightness_3;
    if (cond.contains('pores')) return Icons.grain;
    if (cond.contains('eye bag')) return Icons.remove_red_eye;
    if (cond.contains('brown spot')) return Icons.brightness_2;
    if (cond.contains('mole')) return Icons.adjust;
    if (cond.contains('comedone')) return Icons.bubble_chart;
    if (cond.contains('dark circle')) return Icons.remove_red_eye;
    if (cond.contains('skin redness')) return Icons.warning;
    return Icons.info_outline;
  }

  Color _getConditionColor(String condition) {
    final cond = condition.toLowerCase();
    if (cond.contains('normal')) return Colors.green;
    if (cond.contains('wrinkle')) return Colors.orange;
    if (cond.contains('acne')) return Colors.redAccent;
    if (cond.contains('blackhead')) return Colors.brown;
    if (cond.contains('dark spot')) return Colors.deepPurple;
    if (cond.contains('pores')) return Colors.blueGrey;
    if (cond.contains('eye bag')) return Colors.indigo;
    if (cond.contains('brown spot')) return Colors.deepOrange;
    if (cond.contains('mole')) return Colors.black;
    if (cond.contains('comedone')) return Colors.purple;
    if (cond.contains('dark circle')) return Colors.blue;
    if (cond.contains('skin redness')) return Colors.pinkAccent;
    return Colors.grey;
  }

  int getNormalPercentage(String condition) {
    final cond = condition.toLowerCase();

    if (cond.contains('normal')) return 100;
    if (cond.contains('wrinkle')) return 60;
    if (cond.contains('acne')) return 50;
    if (cond.contains('blackhead')) return 55;
    if (cond.contains('dark spot')) return 40;
    if (cond.contains('pores')) return 65;
    if (cond.contains('eye bag')) return 45;
    if (cond.contains('brown spot')) return 42;
    if (cond.contains('mole')) return 50;
    if (cond.contains('comedone')) return 55;
    if (cond.contains('dark circle')) return 48;
    if (cond.contains('skin redness')) return 58;

    return 70; // Default percentage for unknown conditions
  }

  String _getConditionStatus(String condition, double percent) {
    if (condition.toLowerCase().contains('normal')) {
      return percent >= 70 ? "Normal" : "Not Normal";
    }
    if (percent >= 70) return "High";
    if (percent >= 40) return "Moderate";
    if (percent >= 20) return "Mild";
    return "Minimal";
  }

  Widget _summaryStat(String label, String value, IconData? icon, Color? color,
      {String? status, double? compareTo}) {
    // Parse the value as double for comparison
    double currentValue = double.tryParse(value.replaceAll('%', '')) ?? 0.0;
    String? compareText;
    Color? compareColor;

    if (compareTo != null) {
      if (currentValue > compareTo) {
        compareText = "Higher than average (${compareTo.toStringAsFixed(1)}%)";
        compareColor = Colors.redAccent;
      } else if (currentValue < compareTo) {
        compareText = "Lower than average (${compareTo.toStringAsFixed(1)}%)";
        compareColor = Colors.green;
      } else {
        compareText = "Equal to average (${compareTo.toStringAsFixed(1)}%)";
        compareColor = Colors.blueGrey;
      }
    }

    return Container(
      // padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: (color ?? Colors.grey).withOpacity(0.15),
            child: Icon(icon ?? Icons.info_outline,
                color: color ?? Colors.grey, size: 22),
            radius: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  value,
                  style: TextStyle(
                      color: color ?? Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (status != null)
                  Text(
                    status,
                    style: TextStyle(
                        color: color ?? Colors.grey,
                        fontWeight: FontWeight.w500,
                        fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                if (compareText != null)
                  Text(
                    compareText,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                        color: compareColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 13),
                    maxLines: 1,
                  ),
              ],
            ),
          )
        ],
      ),
    );
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 80,
          width: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 80,
                width: 80,
                child: CircularProgressIndicator(
                  value: (score / 10).clamp(0.0, 1.0),
                  strokeWidth: 8,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    score >= 8.5
                        ? Colors.green
                        : score >= 7.5
                            ? Colors.lightGreen
                            : score >= 6.5
                                ? Colors.orange
                                : Colors.red,
                  ),
                ),
              ),
              Text(
                "${score.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black87,
                ),
              ),
              const Positioned(
                bottom: 10,
                child: Text(
                  "/ 10",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 15),
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 2.0),
            child: Text(
              "$label Assessment Score",
              style: const TextStyle(fontWeight: FontWeight.bold),
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
    print(summaries[0]['percentages']);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skin Analysis Results'),
      ),
      body: summaries.isEmpty
          ? const Center(child: Text('No skin condition data found.'))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: summaries.isEmpty ? 0 : 1,
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
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GridView.builder(
                              shrinkWrap: true,
                              // physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, // Two cards per row
                                childAspectRatio:
                                    MediaQuery.of(context).size.width < 400
                                        ? 1.3
                                        : 2.4, // More square on mobile
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                              ),
                              itemCount: percentages.length,
                              itemBuilder: (context, idx) {
                                final p = percentages[idx];
                                return _summaryStat(
                                    p['condition'] ?? '',
                                    "${p['percent']}%",
                                    _getConditionIcon(p['condition'] ?? ''),
                                    _getConditionColor(p['condition'] ?? ''),
                                    compareTo:
                                        getNormalPercentage(p['condition'])
                                            .toDouble());
                              },
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    elevation: 3,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                            Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                            Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 18, horizontal: 8),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          buildAssessmentChart(scoreOutOf10,
                                              label: primaryCondition),
                                          const SizedBox(height: 8),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    elevation: 3,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                            Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                            Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                            Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 18, horizontal: 8),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          buildAssessmentChart(
                                              attractivenessScore,
                                              label: "Attractive"),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // buildAttractivenessChart(attractivenessScore),
                            //     color: Colors.deepPurple),
                            // ),
                            const SizedBox(height: 10),
                            Text("From Recently Uploaded Image",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
                            const SizedBox(height: 10),
                            if (imageUrl != null && imageUrl.isNotEmpty)
                              SizedBox(
                                height: 110,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    Card(
                                      margin: const EdgeInsets.only(right: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          imageUrl,
                                          width: 140,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                            width: 140,
                                            height: 100,
                                            color: Colors.grey.shade200,
                                            child: const Icon(
                                                Icons.broken_image,
                                                size: 40,
                                                color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Add more cards for other images if available in your data
                                  ],
                                ),
                              ),
                            const Divider(height: 24),
                            // ExpansionTiles for Q&A style extraction
                            ExpansionTile(
                              title: const Text("What's the diagnosis?",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(mainDiagnosis,
                                      style: const TextStyle(fontSize: 15)),
                                ),
                              ],
                            ),
                            // ExpansionTile(
                            //   title: const Text("What medicines are recommended?",
                            //       style: TextStyle(fontWeight: FontWeight.bold)),
                            //   children: [
                            //     Padding(
                            //       padding: const EdgeInsets.all(8.0),
                            //       child: Builder(
                            //         builder: (context) {
                            //           // Try to extract "Recommended Medicines" section
                            //           final recRegex = RegExp(
                            //               r'Recommended Medicines[:\s]*([\s\S]*?)(\n\n|$)',
                            //               caseSensitive: false);
                            //           final recMatch =
                            //               recRegex.firstMatch(fullOutput);
                            //           if (recMatch != null) {
                            //             return Text(recMatch.group(1)!.trim(),
                            //                 style: const TextStyle(fontSize: 15));
                            //           }
                            //           // Fallback: show all recommendations
                            //           return Text(summary['recommendations'] ?? '',
                            //               style: const TextStyle(fontSize: 15));
                            //         },
                            //       ),
                            //     ),
                            //   ],
                            // ),
                            ExpansionTile(
                              title: const Text("What are the treatment notes?",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Builder(
                                    builder: (context) {
                                      // Try to extract "Treatment Notes" or similar section
                                      final notesRegex = RegExp(
                                          r'(Treatment Notes|Treatment|Advice|Notes)[:\s]*([\s\S]*?)(\n\n|$)',
                                          caseSensitive: false);
                                      final notesMatch =
                                          notesRegex.firstMatch(fullOutput);
                                      if (notesMatch != null) {
                                        return Text(notesMatch.group(2)!.trim(),
                                            style:
                                                const TextStyle(fontSize: 15));
                                      }
                                      // Fallback: show full output
                                      return Text(fullOutput,
                                          style: const TextStyle(fontSize: 15));
                                    },
                                  ),
                                ),
                              ],
                            ),
                            ExpansionTile(
                              title: const Text("Show full details",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(fullOutput,
                                      style: const TextStyle(fontSize: 15)),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                const Text(
                                  "Recommended Doctor's",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // 👇 Fixed horizontal ListView inside a SizedBox
                                SizedBox(
                                  height:
                                      300, // Adjust based on your DoctorCard height
                                  child: ListView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.only(right: 16),
                                    scrollDirection: Axis.horizontal,
                                    itemCount: 5,
                                    itemBuilder: (context, index) {
                                      return const DoctorCard(); // Replace with actual data if needed
                                    },
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ));
              },
            ),
    );
  }
}
