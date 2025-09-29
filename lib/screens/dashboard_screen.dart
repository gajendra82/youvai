import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skin_assessment/models/history_enrty.dart';
import 'package:skin_assessment/services/history_api.dart';

import '../utils/history_storage.dart';
import '../widgets/CustomSpiderChart.dart';
import 'history_detail_screen.dart';

/// Dashboard that shows a detailed list of previous analyses.
/// Each list item uses the same visual layout as the single-analysis
/// SkinConditionResultPage: attractiveness chart, summary stats grid,
/// spider chart and recent images. Data is fetched from API (if apiEndpoint
/// provided) otherwise from local storage.
class DashboardDetailedScreen extends StatefulWidget {
  final String? apiEndpoint;
  const DashboardDetailedScreen({Key? key, this.apiEndpoint}) : super(key: key);

  @override
  State<DashboardDetailedScreen> createState() =>
      _DashboardDetailedScreenState();
}

class _DashboardDetailedScreenState extends State<DashboardDetailedScreen> {
  List<HistoryEntry> _entries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.apiEndpoint != null && widget.apiEndpoint!.isNotEmpty) {
        _entries =
            await HistoryApi.fetchHistoryFromApi(endpoint: widget.apiEndpoint!);
      } else {
        _entries = await HistoryStorage.loadAll();
      }
    } catch (e) {
      _error = e.toString();
      try {
        _entries = await HistoryStorage.loadAll();
      } catch (_) {
        _entries = [];
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteEntry(String id) async {
    // If the source is remote, you may want to call delete API. Here we delete locally.
    await HistoryStorage.deleteEntry(id);
    await _loadEntries();
  }

  Widget _buildImageWidget(HistoryEntry e) {
    final imagePath = e.imagePath;
    if (imagePath != null &&
        (imagePath.startsWith('http://') || imagePath.startsWith('https://'))) {
      return Image.network(imagePath, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
        if (e.imageBase64 != null) {
          try {
            final bytes = base64Decode(e.imageBase64!);
            return Image.memory(bytes, fit: BoxFit.cover);
          } catch (er) {
            return const Icon(Icons.broken_image, size: 48);
          }
        }
        return const Icon(Icons.broken_image, size: 48);
      });
    }

    if (imagePath != null && !kIsWeb) {
      final f = File(imagePath);
      if (f.existsSync()) {
        return Image.file(f, fit: BoxFit.cover);
      }
    }

    if (e.imageBase64 != null) {
      try {
        final bytes = base64Decode(e.imageBase64!);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (ex) {
        return const Icon(Icons.broken_image, size: 48);
      }
    }
    return const Icon(Icons.image_not_supported_outlined, size: 48);
  }

  /// Try to extract percentages array from entry.analysis (various shapes supported).
  /// Returns a list of maps: [{'condition': 'Acne', 'percent': '12.3'}, ...]
  List<Map<String, String>> _extractPercentagesFromAnalysis(dynamic analysis) {
    if (analysis == null) return [];
    try {
      if (analysis is Map && analysis['percentages'] is List) {
        final raw = List.from(analysis['percentages']);
        return raw.map<Map<String, String>>((p) {
          final condition = (p['condition'] ?? p['label'] ?? '').toString();
          final percent = (p['percent'] ?? p['value'] ?? '0').toString();
          return {'condition': condition, 'percent': percent};
        }).toList();
      }

      if (analysis is String) {
        final text = analysis.trim();
        // Attempt simple regex matches like "Acne: 12.3%"
        final List<Map<String, String>> out = [];
        final lines = text.split(RegExp(r'[\n,]'));
        for (var line in lines) {
          final m = RegExp(r'([A-Za-z &_-]+)[\s:)\(]*\s*([\d.]+)\s*%')
              .firstMatch(line);
          if (m != null) {
            out.add({'condition': m.group(1)!.trim(), 'percent': m.group(2)!});
          }
        }
        if (out.isNotEmpty) return out;
      }

      if (analysis is List) {
        // List of strings or maps
        final List<Map<String, String>> out = [];
        for (var item in analysis) {
          if (item is Map && item['condition'] != null) {
            out.add({
              'condition': item['condition'].toString(),
              'percent': item['percent'].toString()
            });
          } else if (item is String) {
            final m = RegExp(r'([A-Za-z &_-]+)[\s:)\(]*\s*([\d.]+)\s*%')
                .firstMatch(item);
            if (m != null) {
              out.add(
                  {'condition': m.group(1)!.trim(), 'percent': m.group(2)!});
            }
          }
        }
        return out;
      }

      // As a fallback, if analysis is a Map but not percentages, try to stringify and parse lines
      final asStr = json.encode(analysis);
      final lines = asStr.split(RegExp(r'[\n,]'));
      final List<Map<String, String>> out = [];
      for (var line in lines) {
        final m =
            RegExp(r'([A-Za-z &_-]+)[\s:)\(]*\s*([\d.]+)\s*%').firstMatch(line);
        if (m != null)
          out.add({'condition': m.group(1)!.trim(), 'percent': m.group(2)!});
      }
      return out;
    } catch (e) {
      return [];
    }
  }

  /// Convert percentages into spider chart data
  List<Map<String, dynamic>> _chartDataFromPercentages(
      List<Map<String, String>> percentages) {
    return percentages.map((p) {
      final cond = (p['condition'] ?? '').toUpperCase();
      final percent = double.tryParse(p['percent'] ?? '0') ?? 0.0;
      return {"condition": cond, "percent": percent};
    }).toList();
  }

  Widget _buildDetailedCard(BuildContext context, HistoryEntry entry) {
    final percentages = _extractPercentagesFromAnalysis(entry.analysis);
    final chartData = _chartDataFromPercentages(percentages);
    final attractivenessScore = entry.attractivenessScore ?? 0.0;
    final imageUrl = entry.imagePath;
    final date = DateTime.fromMillisecondsSinceEpoch(entry.timestamp).toLocal();

    final averageMap = {
      "normal": 100.0,
      "wrinkle": 25.0,
      "acne": 15.0,
      "blackhead": 20.0,
      "dark spot": 15.0,
      "pores": 25.0,
      "eye bag": 20.0,
      "brown spot": 15.0,
      "mole": 30.0,
      "comedone": 20.0,
      "dark circle": 20.0,
      "Pigmentation": 20.0,
      "eye pouch": 20.0,
      "nasolabial fold": 20.0,
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Header row with title + date + delete
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.note ??
                      (entry.analysis?['prediction']?.toString() ??
                          'Skin Analysis'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                "${date.day}/${date.month}/${date.year}",
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _confirmDelete(entry),
              )
            ],
          ),
          const SizedBox(height: 10),

          // Row: Attractiveness chart on left, short summary on right
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Assessment chart (re-using the same small widget)
              buildAssessmentChartSmall(attractivenessScore, context: context),
              const SizedBox(width: 12),
              // Short text summary and image thumbnails
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Attractiveness Score: ${attractivenessScore.toStringAsFixed(2)} / 10",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Quick insights",
                      style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (percentages.isEmpty)
                      Text("No detailed percentages available",
                          style: TextStyle(color: Colors.grey.shade600))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: percentages.take(6).map((p) {
                          return Chip(
                            label: Text("${p['condition']} ${p['percent']}%"),
                            backgroundColor: Colors.blueGrey.shade50,
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 8),
                    if (imageUrl != null)
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (imageUrl.startsWith('http')) {
                                _showImageDialog(context, imageUrl);
                              }
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 96,
                                height: 72,
                                child: _buildImageWidget(entry),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Tap image to view. Full details below.",
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Grid of summary stats (limited to first 6)
          if (percentages.isNotEmpty) ...[
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: percentages.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width < 600 ? 1 : 2,
                childAspectRatio: 4.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (ctx, idx) {
                final p = percentages[idx];
                final cond = p['condition'] ?? '';
                final val = "${p['percent']}%";
                return _summaryStat(cond.toUpperCase(), val,
                    _getConditionIcon(cond), _getConditionColor(cond), context,
                    compareTo: getNormalPercentage(cond).toDouble());
              },
            ),
            const SizedBox(height: 12),
            // Spider chart
            CustomSpiderChart(
              data: chartData,
              averageMap: averageMap,
              chartRadius:
                  MediaQuery.of(context).size.width < 400 ? 70.0 : 110.0,
              tickCount: 5,
            ),
          ],

          const SizedBox(height: 12),

          // Action row
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.info_outline),
                label: const Text("View Full Report"),
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => HistoryDetailScreen(
                          entry: entry,
                          onDelete: () async {
                            await _deleteEntry(entry.id);
                            Navigator.of(context).pop();
                          })));
                  await _loadEntries();
                },
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.share_outlined),
                label: const Text("Share"),
                onPressed: () {
                  // Share not implemented: you can integrate share_plus package here.
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Share not implemented")));
                },
              ),
            ],
          )
        ]),
      ),
    );
  }

  void _confirmDelete(HistoryEntry e) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _deleteEntry(e.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis History (Detailed)'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadEntries),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadEntries,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      Icon(Icons.error_outline,
                          size: 84, color: Colors.red.shade400),
                      const SizedBox(height: 16),
                      Center(child: Text('Failed to load history: $_error')),
                    ],
                  )
                : _entries.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          Icon(Icons.history,
                              size: 84, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Center(
                              child: Text('No analyses yet',
                                  style:
                                      TextStyle(color: Colors.grey.shade600))),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24, top: 12),
                        itemCount: _entries.length,
                        itemBuilder: (context, idx) {
                          final entry = _entries[idx];
                          return _buildDetailedCard(context, entry);
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(Icons.camera),
        label: const Text('New Capture'),
      ),
    );
  }
}

/// Small assessment chart used inside each card.
Widget buildAssessmentChartSmall(double score,
    {required BuildContext context}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      SizedBox(
        height: 70,
        width: 70,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 70,
              width: 70,
              child: CircularProgressIndicator(
                value: (score / 10).clamp(0.0, 1.0),
                strokeWidth: 7,
                backgroundColor:
                    Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary),
              ),
            ),
            Text(
              "${score.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Positioned(
              bottom: 6,
              child: Text("/10", style: TextStyle(fontSize: 10)),
            )
          ],
        ),
      ),
      const SizedBox(height: 8),
      const Text("Attractiveness",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    ],
  );
}

/// The following helper methods and data structures are adapted from
/// the SkinConditionResultPage to keep visual parity with the single-analysis UI.

String _getConditionStatus(String condition, double percent) {
  if (condition.toLowerCase().contains('normal')) {
    return percent >= 70 ? "Normal" : "Not Normal";
  }
  if (percent >= 70) return "High";
  if (percent >= 40) return "Moderate";
  if (percent >= 20) return "Mild";
  return "Minimal";
}

final Map<String, dynamic> conditionInfo = {
  "normal": {
    "type": "Normal Skin",
    "meaning": "Your skin is well-balanced — not too oily or too dry.",
    "cause": "Genetics, routine, hydration.",
    "suggestion": "Keep a gentle routine and sunscreen."
  },
  "oily": {
    "type": "Oily Skin",
    "meaning": "Excess sebum production.",
    "cause": "Genetics, hormones.",
    "suggestion": "Use oil-free, non-comedogenic products."
  },
  "acne": {
    "type": "Acne",
    "meaning": "Pimples or cysts caused by clogged follicles.",
    "cause": "Hormones, sebum, bacteria.",
    "suggestion":
        "Use salicylic acid and consult a dermatologist for severe cases."
  },
  // (You can extend this map with other conditions copied from your large map)
};

Widget _summaryStat(String label, String value, IconData? icon, Color? color,
    BuildContext context,
    {String? status, double? compareTo}) {
  double currentValue = double.tryParse(value.replaceAll('%', '')) ?? 0.0;
  String? compareText;
  Color? compareColor;

  if (compareTo != null) {
    if (currentValue > compareTo) {
      compareText = "Higher than average (${compareTo.toStringAsFixed(1)}%)";
      compareColor = Colors.redAccent;
    } else if (currentValue < compareTo) {
      compareText = "Lower than average (${compareTo.toStringAsFixed(1)}%)";
      compareColor = Colors.blueGrey;
    } else {
      compareText = "Equal to average (${compareTo.toStringAsFixed(1)}%)";
      compareColor = Colors.blueGrey;
    }
  }

  return InkWell(
    onTap: () {
      final info = conditionInfo[label.toLowerCase()];
      if (info != null) {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text("Meaning: ${info['meaning']}"),
                      const SizedBox(height: 8),
                      Text("Causes: ${info['cause']}"),
                      const SizedBox(height: 8),
                      Text("Suggestions: ${info['suggestion']}"),
                    ]),
              ),
            );
          },
        );
      }
    },
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.06),
              blurRadius: 7,
              offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: (color ?? Theme.of(context).colorScheme.secondary)
              .withOpacity(0.12),
          child: Icon(icon ?? Icons.info_outline,
              color: color ?? Theme.of(context).colorScheme.primary, size: 20),
          radius: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(value,
                style: TextStyle(
                    color: compareColor ?? Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            if (compareText != null)
              Text(compareText,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
        ),
      ]),
    ),
  );
}

IconData _getConditionIcon(String condition) {
  final cond = condition.toLowerCase();
  if (cond.contains('normal')) return Icons.check_circle;
  if (cond.contains('wrinkle')) return Icons.blur_on;
  if (cond.contains('acne')) return Icons.bubble_chart;
  if (cond.contains('blackhead')) return Icons.circle;
  if (cond.contains('dark spot')) return Icons.brightness_3;
  if (cond.contains('pores')) return Icons.grain;
  if (cond.contains('eye bag')) return Icons.remove_red_eye;
  if (cond.contains('mole')) return Icons.adjust;
  if (cond.contains('comedone')) return Icons.bubble_chart;
  if (cond.contains('dark circle')) return Icons.remove_red_eye;
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
  if (cond.contains('mole')) return Colors.black;
  return Colors.grey;
}

int getNormalPercentage(String condition) {
  final cond = condition.toLowerCase();
  if (cond.contains('normal')) return 100;
  if (cond.contains('wrinkle')) return 25;
  if (cond.contains('acne')) return 15;
  if (cond.contains('blackhead')) return 20;
  if (cond.contains('dark spot')) return 15;
  if (cond.contains('pores')) return 25;
  if (cond.contains('eye bag')) return 20;
  if (cond.contains('brown spot')) return 15;
  if (cond.contains('mole')) return 30;
  if (cond.contains('comedone')) return 20;
  if (cond.contains('dark circle')) return 20;
  if (cond.contains('pigmentation')) return 20;
  return 30;
}

void _showImageDialog(BuildContext context, String imageUrl) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InteractiveViewer(
        panEnabled: true,
        minScale: 1,
        maxScale: 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 320,
              height: 320,
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image, size: 80),
            ),
          ),
        ),
      ),
    ),
  );
}
