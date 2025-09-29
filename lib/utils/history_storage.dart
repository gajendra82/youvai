import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skin_assessment/models/history_enrty.dart';

class HistoryStorage {
  static const String _kHistoryKey = 'analysis_history_v1';

  /// Load all entries (sorted descending by timestamp)
  static Future<List<HistoryEntry>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kHistoryKey) ?? [];
    final entries = raw
        .map((s) {
          try {
            return HistoryEntry.fromRawJson(s);
          } catch (e) {
            return null;
          }
        })
        .whereType<HistoryEntry>()
        .toList();
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  /// Save a new entry and return the saved entry (appends to existing list).
  /// - If you have bytes (Uint8List) and want to persist them in SharedPreferences,
  ///   convert to base64 and pass as imageBase64.
  static Future<void> saveEntry(HistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kHistoryKey) ?? [];
    raw.add(entry.toRawJson());
    await prefs.setStringList(_kHistoryKey, raw);
  }

  /// Delete a specific entry by id
  static Future<void> deleteEntry(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kHistoryKey) ?? [];
    final filtered = raw.where((s) {
      try {
        final entry = HistoryEntry.fromRawJson(s);
        return entry.id != id;
      } catch (e) {
        return true;
      }
    }).toList();
    await prefs.setStringList(_kHistoryKey, filtered);
  }

  /// Clear all history
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHistoryKey);
  }

  /// Convenience to create and save an entry from bytes and analysis map.
  /// usage:
  /// await HistoryStorage.saveFromBytes(
  ///   bytes: imageBytes,
  ///   attractivenessScore: 72.3,
  ///   analysis: analysisMap,
  /// );
  static Future<HistoryEntry> saveFromBytes({
    required Uint8List bytes,
    double? attractivenessScore,
    Map<String, dynamic>? analysis,
    String? note,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final base64Img = base64Encode(bytes);
    final entry = HistoryEntry(
      id: id,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      imageBase64: base64Img,
      imagePath: null,
      attractivenessScore: attractivenessScore,
      analysis: analysis,
      note: note,
    );
    await saveEntry(entry);
    return entry;
  }

  /// Convenience to create and save an entry from local file path (mobile)
  static Future<HistoryEntry> saveFromFilePath({
    required String filePath,
    double? attractivenessScore,
    Map<String, dynamic>? analysis,
    String? note,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final entry = HistoryEntry(
      id: id,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      imageBase64: null,
      imagePath: filePath,
      attractivenessScore: attractivenessScore,
      analysis: analysis,
      note: note,
    );
    await saveEntry(entry);
    return entry;
  }
}
