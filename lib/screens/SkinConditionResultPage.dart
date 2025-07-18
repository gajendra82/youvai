import 'package:flutter/material.dart';

class SkinConditionResultPage extends StatelessWidget {
  final Map<String, dynamic> gradioResult;

  const SkinConditionResultPage({Key? key, required this.gradioResult})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract the output array from the JSON
    final List<dynamic> outputs = gradioResult['data']['outpUt'];
    // Only show outputs that have analysis and output (filter images without results)
    final List<dynamic> resultOutputs = outputs
        .where((o) => o['analysis'] != null && o['output'] != null)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skin Analysis Results'),
      ),
      body: resultOutputs.isEmpty
          ? const Center(child: Text('No skin condition data found.'))
          : ListView.builder(
              itemCount: resultOutputs.length,
              itemBuilder: (context, index) {
                final result = resultOutputs[index];
                final analysis = result['analysis'] as String;
                final output = result['output'] as String;
                final imageUrl = result['image_url'] as String?;

                // Parse analysis for percentage breakdown
                final List<String> analysisLines = analysis.split('\n');
                final List<Widget> percentageWidgets = [];
                for (var line in analysisLines) {
                  // Try to extract "Condition (xx.xx%)" or "Condition: xx.xx%"
                  final regex = RegExp(r'([A-Za-z ]+)[(:]\s*([\d.]+)%');
                  final match = regex.firstMatch(line);
                  if (match != null) {
                    final condition = match.group(1)!.trim();
                    final percent = match.group(2)!;
                    percentageWidgets.add(
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(condition,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500)),
                          Text('$percent%',
                              style: const TextStyle(color: Colors.blue)),
                        ],
                      ),
                    );
                  }
                }

                return Card(
                  margin: const EdgeInsets.all(12),
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
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, size: 80),
                            ),
                          ),
                        const SizedBox(height: 12),
                        const Text('Skin Condition Percentages:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        ...percentageWidgets,
                        const Divider(height: 24),
                        const Text('Diagnosis & Recommendations:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(output),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
