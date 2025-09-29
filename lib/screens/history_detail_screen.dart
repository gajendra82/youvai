import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skin_assessment/models/history_enrty.dart';

class HistoryDetailScreen extends StatelessWidget {
  final HistoryEntry entry;
  final Future<void> Function()? onDelete;

  const HistoryDetailScreen({
    Key? key,
    required this.entry,
    this.onDelete,
  }) : super(key: key);

  Widget _buildImage() {
    if (entry.imagePath != null && !kIsWeb) {
      final f = File(entry.imagePath!);
      if (f.existsSync()) {
        return Image.file(f, fit: BoxFit.contain);
      }
    }
    if (entry.imageBase64 != null) {
      try {
        final bytes = base64Decode(entry.imageBase64!);
        return Image.memory(bytes, fit: BoxFit.contain);
      } catch (e) {
        return const Icon(Icons.broken_image, size: 96);
      }
    }
    return const Icon(Icons.image_not_supported_outlined, size: 96);
  }

  @override
  Widget build(BuildContext context) {
    final score = entry.attractivenessScore;
    final date = DateTime.fromMillisecondsSinceEpoch(entry.timestamp).toLocal();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete'),
                  content: const Text('Delete this entry?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (ok == true) {
                if (onDelete != null) await onDelete!();
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // image area
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: Colors.black,
                child: Center(child: _buildImage()),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  if (score != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: score >= 75
                            ? Colors.green
                            : (score >= 45 ? Colors.orange : Colors.red),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text('${score.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Captured: ${date.toLocal().toString()}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 6),
                        Text(
                            entry.note ??
                                (entry.analysis?['prediction']?.toString() ??
                                    'Skin Analysis'),
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Analysis Result',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: entry.analysis != null
                            ? Text(
                                const JsonEncoder.withIndent('  ')
                                    .convert(entry.analysis),
                                style: const TextStyle(
                                    fontFamily: 'monospace', fontSize: 13))
                            : const Text('No analysis data available'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Add re-analyze or share functionality
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text(
                                  'Re-analyze / share not implemented in this sample')));
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Re-analyze (optional)'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          // simple share: copy JSON to clipboard (or implement share_plus)
                          final data = entry.analysis != null
                              ? const JsonEncoder.withIndent('  ')
                                  .convert(entry.analysis)
                              : 'No analysis';
                          Clipboard.setData(ClipboardData(text: data));
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Analysis copied to clipboard')));
                        },
                        icon: const Icon(Icons.copy_outlined),
                        label: const Text('Copy analysis JSON'),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
