import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_constants.dart';

class ScheduleService {
  static List<Map<String, dynamic>>? _cachedPrograms;

  /// Fetches the full schedule from WP API and returns all entries (one per day)
  Future<List<Map<String, dynamic>>> fetchSchedule({
    bool bypassHttpCache = false,
  }) async {
    final baseUrl = Uri.parse(
      '${AppConstants.website}/wp-json/ladyapp/v1/schedule',
    );
    final url = bypassHttpCache
        ? baseUrl.replace(
            queryParameters: {
              ...baseUrl.queryParameters,
              '_': DateTime.now().millisecondsSinceEpoch.toString(),
            },
          )
        : baseUrl;

    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'LadyRadioApp/1.0',
          'Referer': 'https://www.ladyradio.it/',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final allEntries = jsonList.map((item) {
          return {
            'id': item['id']?.toString() ?? '',
            'postId':
                item['postId']?.toString() ?? item['id']?.toString() ?? '',
            'title': item['title']?.toString() ?? '',
            'description': item['subtitle']?.toString() ?? '',
            'schedule': '${item['startTime'] ?? ''} - ${item['endTime'] ?? ''}',
            'startTime': item['startTime']?.toString() ?? '',
            'day': item['day']?.toString() ?? '',
            'image':
                item['imageUrl'] != false &&
                    item['imageUrl'] != null &&
                    item['imageUrl'] != ''
                ? item['imageUrl'].toString()
                : AppConstants.logoUrl,
            'rssFeed': item['rssFeed']?.toString() ?? '',
            'podcastCategory': _readCategory(item),
            'isPodcast': _readBool(item, [
              'isPodcast',
              'is_podcast',
              'podcast',
              'isPodcastProgram',
            ]),
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
  Future<List<Map<String, dynamic>>> fetchUniquePrograms({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedPrograms != null) return _cachedPrograms!;
    await fetchSchedule(bypassHttpCache: forceRefresh);
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

  String _readCategory(Map<String, dynamic> item) {
    final directKeys = [
      'podcastCategory',
      'podcast_category',
      'categoriaPodcast',
      'categoria_podcast',
      'category',
    ];

    for (final key in directKeys) {
      final value = item[key];
      final category = _normalizeCategoryValue(value);
      if (category.isNotEmpty) return category;
    }

    final categories = item['categories'];
    if (categories is Iterable) {
      for (final value in categories) {
        final category = _normalizeCategoryValue(value);
        if (category.isNotEmpty) return category;
      }
    }

    return '';
  }

  String _normalizeCategoryValue(dynamic value) {
    if (value == null) return '';

    if (value is Map) {
      return _normalizeCategoryValue(
        value['name'] ?? value['title'] ?? value['label'] ?? value['slug'],
      );
    }

    final category = value.toString().trim();
    if (category.isEmpty) return '';

    final normalized = category.toLowerCase();
    if (['podcast', 'podcasts', 'true', '1'].contains(normalized)) return '';

    return category;
  }

  bool _readBool(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (['1', 'true', 'yes', 'si', 'sì'].contains(normalized)) {
          return true;
        }
        if (['0', 'false', 'no'].contains(normalized)) {
          return false;
        }
      }
    }

    final searchableValues = [
      item['type'],
      item['contentType'],
      item['category'],
      item['categories'],
      item['tag'],
      item['tags'],
    ].whereType<Object>().map((value) => value.toString().toLowerCase());

    return searchableValues.any((value) => value.contains('podcast'));
  }
}
