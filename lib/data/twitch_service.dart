import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class TwitchEventModel {
  final String id;
  final String title;
  final String imageUrl;
  final String targetUrl;
  final String startDate;
  final String endDate;

  const TwitchEventModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.targetUrl,
    required this.startDate,
    required this.endDate,
  });

  factory TwitchEventModel.fromJson(Map<String, dynamic> json) {
    return TwitchEventModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      targetUrl: json['targetUrl']?.toString() ?? '',
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
    );
  }
}

class TwitchService {
  static const String _baseUrl = 'https://www.ladyradio.it/wp-json/ladyapp/v1';
  static const Duration _requestTimeout = Duration(seconds: 8);

  final http.Client _client = http.Client();

  Future<List<TwitchEventModel>> fetchWeeklyEvents() async {
    try {
      final uri = Uri.parse('$_baseUrl/twitch-events');
      final response = await _client
          .get(
            uri,
            headers: const {
              'Accept': 'application/json, text/plain, */*',
              'Cache-Control': 'no-cache',
              'Referer': 'https://www.ladyradio.it/',
              'User-Agent': 'LadyRadioApp/1.0',
            },
          )
          .timeout(_requestTimeout);

      if (response.statusCode != 200) {
        debugPrint('Errore fetch Twitch events: ${response.statusCode}');
        return const [];
      }

      final data = json.decode(response.body);
      if (data is! List) return const [];

      return data
          .whereType<Map<String, dynamic>>()
          .map(TwitchEventModel.fromJson)
          .where(
            (event) => event.imageUrl.isNotEmpty && event.targetUrl.isNotEmpty,
          )
          .toList();
    } on TimeoutException catch (e) {
      debugPrint('Timeout fetch Twitch events: $e');
      return const [];
    } catch (e) {
      debugPrint('Errore fetch Twitch events: $e');
      return const [];
    }
  }
}
