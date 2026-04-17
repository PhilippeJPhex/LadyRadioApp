import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_constants.dart';

class ScheduleService {
  static List<Map<String, dynamic>>? _cachedPrograms;

  /// Fetches the full schedule from WP API and returns all entries (one per day)
  Future<List<Map<String, dynamic>>> fetchSchedule() async {
    final url = Uri.parse('${AppConstants.website}/wp-json/ladyapp/v1/schedule');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final allEntries = jsonList.map((item) {
          return {
            'id': item['id'] ?? '',
            'postId': item['postId'] ?? item['id'] ?? '',
            'title': item['title'] ?? '',
            'description': item['subtitle'] ?? '',
            'schedule': '${item['startTime'] ?? ''} - ${item['endTime'] ?? ''}',
            'startTime': item['startTime'] ?? '',
            'day': item['day'] ?? '',
            'image': item['imageUrl'] != false && item['imageUrl'] != null && item['imageUrl'] != ''
                ? item['imageUrl']
                : AppConstants.logoUrl,
            'rssFeed': item['rssFeed'] ?? '',
          };
        }).toList();

        // Cache the unique programs for use by HomeScreen
        _cacheUniquePrograms(allEntries);

        return allEntries;
      } else {
        throw Exception('Failed to load schedule');
      }
    } catch (e) {
      throw Exception('Failed to load schedule: $e');
    }
  }

  /// Returns the unique list of programs (deduplicated by postId)
  /// Fetch must be called first, or this will trigger a fetch.
  Future<List<Map<String, dynamic>>> fetchUniquePrograms() async {
    if (_cachedPrograms != null) return _cachedPrograms!;
    await fetchSchedule();
    return _cachedPrograms ?? [];
  }

  void _cacheUniquePrograms(List<Map<String, dynamic>> allEntries) {
    final seen = <String>{};
    final unique = <Map<String, dynamic>>[];
    for (final entry in allEntries) {
      final postId = entry['postId'] as String;
      if (postId.isNotEmpty && !seen.contains(postId)) {
        seen.add(postId);
        unique.add(entry);
      }
    }
    _cachedPrograms = unique;
  }

  /// Clears the cache (useful for pull-to-refresh)
  static void clearCache() {
    _cachedPrograms = null;
  }
}
