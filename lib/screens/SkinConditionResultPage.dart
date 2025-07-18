import 'dart:convert';
import 'package:flutter/material.dart';

class SkinConditionResultPage extends StatelessWidget {
  final Map<String, dynamic> gradioResult;

  const SkinConditionResultPage({Key? key, required this.gradioResult})
      : super(key: key);

  List<Map<String, dynamic>> extractSkinSummaries(dynamic gradioResult) {
    final List<dynamic> outputs = gradioResult['data']?['outpUt'] ?? [];
    return outputs
        .where((o) => o['analysis'] != null && o['output'] != null)
        .map((result) {
      // Parse analysis string
      String analysis = result['analysis'];
      List<Map<String, String>> percentages = [];

      // Sometimes the analysis is a JSON-encoded string of list, sometimes plain text
      if (analysis.trim().startsWith('[')) {
        // Try to decode as JSON array
        try {
          final decoded = json.decode(analysis);
          if (decoded is List) {
            for (var item in decoded) {
              final match =
                  RegExp(r'([A-Za-z ]+)[(:]\s*([\d.]+)%').firstMatch(item);
              if (match != null) {
                percentages.add({
                  'condition': match.group(1)!.trim(),
                  'percent': match.group(2)!
                });
              }
            }
          }
        } catch (_) {
          // fallback to normal text split
          for (var line in analysis.split('\n')) {
            final match =
                RegExp(r'([A-Za-z ]+)[(:]\s*([\d.]+)%').firstMatch(line);
            if (match != null) {
              percentages.add({
                'condition': match.group(1)!.trim(),
                'percent': match.group(2)!
              });
            }
          }
        }
      } else {
        // Parse as plain text
        for (var line in analysis.split('\n')) {
          final match =
              RegExp(r'([A-Za-z ]+)[(:]\s*([\d.]+)%').firstMatch(line);
          if (match != null) {
            percentages.add({
              'condition': match.group(1)!.trim(),
              'percent': match.group(2)!
            });
          }
        }
      }

      // Extract main diagnosis from output (prefer 'Confirmed Diagnosis')
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

      // Optionally, extract recommendations (after 'Recommended Medicines' or similar)
      String recommendations = '';
      final recRegex =
          RegExp(r'Recommended Medicines[:\s]*([\s\S]*)', caseSensitive: false);
      final recMatch = recRegex.firstMatch(output);
      if (recMatch != null) {
        recommendations = recMatch.group(1)!.trim();
      } else {
        recommendations = output.trim();
      }

      // Calculate skin assessment based on percentages
      String assessment = getAssessment(percentages);

      return {
        'percentages': percentages,
        'mainDiagnosis': mainDiagnosis,
        'recommendations': recommendations,
        'fullOutput': output,
        'assessment': assessment,
        'imageUrl': result['image_url'],
      };
    }).toList();
  }

  /// Simple rule-based assessment (customize as needed)
  String getAssessment(List<Map<String, String>> percentages) {
    if (percentages.isEmpty) return "Insufficient data for assessment.";
    // Find the condition with the highest percentage
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
    return "Primary Concern: $condition ($value%)\nAssessment: $risk risk for this condition.";
  }

  @override
  Widget build(BuildContext context) {
    final summaries = extractSkinSummaries(gradioResult);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skin Analysis Results'),
      ),
      body: summaries.isEmpty
          ? const Center(child: Text('No skin condition data found.'))
          : ListView.builder(
              itemCount: summaries.length,
              itemBuilder: (context, index) {
                final summary = summaries[index];
                final percentages = summary['percentages'] as List<dynamic>;
                final imageUrl = summary['imageUrl'] as String?;
                final mainDiagnosis = summary['mainDiagnosis'] as String;
                final recommendations = summary['recommendations'] as String;
                final assessment = summary['assessment'] as String;
                final fullOutput = summary['fullOutput'] as String;

                return Card(
                  margin: const EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with all conditions & percentages
                        if (percentages.isNotEmpty)
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: percentages
                                .map<Widget>(
                                  (p) => Chip(
                                    label: Text(
                                        "${p['condition']}: ${p['percent']}%"),
                                  ),
                                )
                                .toList(),
                          ),
                        const SizedBox(height: 10),
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
