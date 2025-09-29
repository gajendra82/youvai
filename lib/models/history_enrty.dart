import 'dart:convert';

class HistoryEntry {
  final String id;
  final int timestamp; // milliseconds since epoch
  final String? imageBase64; // optional base64 image (web or inline)
  final String? imagePath; // optional local file path (mobile)
  final double? attractivenessScore; // 0.0 - 100.0 (or null)
  final Map<String, dynamic>? analysis; // raw analysis JSON/map
  final String? note; // optional small note or label

  HistoryEntry({
    required this.id,
    required this.timestamp,
    this.imageBase64,
    this.imagePath,
    this.attractivenessScore,
    this.analysis,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp,
      'imageBase64': imageBase64,
      'imagePath': imagePath,
      'attractivenessScore': attractivenessScore,
      'analysis': analysis,
      'note': note,
    };
  }

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'] as String? ?? '',
      timestamp: json['timestamp'] as int? ?? 0,
      imageBase64: json['imageBase64'] as String?,
      imagePath: json['imagePath'] as String?,
      attractivenessScore: json['attractivenessScore'] != null
          ? (json['attractivenessScore'] as num).toDouble()
          : null,
      analysis: json['analysis'] != null
          ? Map<String, dynamic>.from(json['analysis'] as Map)
          : null,
      note: json['note'] as String?,
    );
  }

  String toRawJson() => json.encode(toJson());

  factory HistoryEntry.fromRawJson(String str) =>
      HistoryEntry.fromJson(json.decode(str) as Map<String, dynamic>);
}
