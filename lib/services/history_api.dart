import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skin_assessment/models/history_enrty.dart';

class HistoryApi {
  /// Fetch history entries from remote API.
  /// Expects API to return a JSON array of objects with fields:
  /// - id (string or number)
  /// - timestamp (ms since epoch or ISO string)
  /// - image_url (optional) => public HTTP URL to the image
  /// - image_base64 (optional) => base64 image string
  /// - attractiveness_score (optional) => number
  /// - analysis (optional) => object
  ///
  /// Example response:
  /// [
  ///   { "id": "1", "timestamp": 1690000000000, "image_url": "https://...", "attractiveness_score": 72.3, "analysis": { ... } },
  ///   ...
  /// ]
  ///
  /// Provide `endpoint` (full URL). If your API requires auth, it will attempt to read `_token` from SharedPreferences.
  static Future<List<HistoryEntry>> fetchHistoryFromApi({
    required String endpoint,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('_token');

    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final uri = Uri.parse(endpoint);
    final resp = await http.get(uri, headers: headers);

    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch history: ${resp.statusCode}');
    }

    final List<dynamic> list = json.decode(resp.body) as List<dynamic>;
    final entries = <HistoryEntry>[];

    for (final item in list) {
      try {
        final Map<String, dynamic> map = Map<String, dynamic>.from(item as Map);
        // Normalize fields to match HistoryEntry model
        final id = map['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString();

        int timestamp = 0;
        if (map['timestamp'] is int) {
          timestamp = map['timestamp'] as int;
        } else if (map['timestamp'] is String) {
          // try parse ISO string
          try {
            timestamp = DateTime.parse(map['timestamp'] as String)
                .millisecondsSinceEpoch;
          } catch (_) {
            timestamp = DateTime.now().millisecondsSinceEpoch;
          }
        }

        final imageUrl = map['image_url'] as String?;
        final imageBase64 = map['image_base64'] as String?;

        double? attractiveness;
        if (map['attractiveness_score'] != null) {
          attractiveness = (map['attractiveness_score'] as num).toDouble();
        } else if (map['score'] != null) {
          attractiveness = (map['score'] as num).toDouble();
        }

        final analysis = map['analysis'] != null
            ? Map<String, dynamic>.from(map['analysis'] as Map)
            : null;

        // Use imageUrl in imagePath so UI can display as network image (dashboard handles both)
        final entry = HistoryEntry(
          id: id,
          timestamp: timestamp,
          imageBase64: imageBase64,
          imagePath:
              imageUrl, // remote URL stored here (dashboard renders network images when path is http)
          attractivenessScore: attractiveness,
          analysis: analysis,
          note: map['note']?.toString(),
        );

        entries.add(entry);
      } catch (e) {
        // skip malformed item but continue
        continue;
      }
    }

    // Sort descending by timestamp
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }
}
