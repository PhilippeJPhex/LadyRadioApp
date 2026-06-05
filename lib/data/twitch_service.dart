import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class TwitchEventsResponse {
  final String channelUrl;
  final List<TwitchEventModel> scheduled;
  final List<TwitchEventModel> completed;

  const TwitchEventsResponse({
    required this.channelUrl,
    required this.scheduled,
    required this.completed,
  });

  bool get hasChannelUrl =>
      channelUrl.trim().isNotEmpty && channelUrl.trim() != '#';

  factory TwitchEventsResponse.empty() {
    return const TwitchEventsResponse(
      channelUrl: '#',
      scheduled: [],
      completed: [],
    );
  }

  factory TwitchEventsResponse.fromJson(dynamic json) {
    if (json is List) {
      final events = json
          .whereType<Map<String, dynamic>>()
          .map(TwitchEventModel.fromJson)
          .where((event) => event.hasDisplayData)
          .toList();
      return TwitchEventsResponse(
        channelUrl: '#',
        scheduled: events,
        completed: const [],
      );
    }

    if (json is! Map<String, dynamic>) return TwitchEventsResponse.empty();

    final scheduled = (json['scheduled'] is List ? json['scheduled'] : const [])
        .whereType<Map<String, dynamic>>()
        .map(TwitchEventModel.fromJson)
        .where((event) => event.hasDisplayData)
        .toList();

    final completed = (json['completed'] is List ? json['completed'] : const [])
        .whereType<Map<String, dynamic>>()
        .map(TwitchEventModel.fromJson)
        .where((event) => event.hasDisplayData)
        .toList();

    return TwitchEventsResponse(
      channelUrl: json['channelUrl']?.toString() ?? '#',
      scheduled: scheduled,
      completed: completed,
    );
  }
}

class TwitchEventModel {
  final String id;
  final String title;
  final String description;
  final String rubrica;
  final int episodeNumber;
  final String imageUrl;
  final String targetUrl;
  final String startDate;
  final String status;

  const TwitchEventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.rubrica,
    required this.episodeNumber,
    required this.imageUrl,
    required this.targetUrl,
    required this.startDate,
    required this.status,
  });

  bool get hasDisplayData => title.isNotEmpty;
  bool get hasTargetUrl => targetUrl.trim().isNotEmpty;

  factory TwitchEventModel.fromJson(Map<String, dynamic> json) {
    return TwitchEventModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description:
          json['description']?.toString() ??
          json['descrizione']?.toString() ??
          '',
      rubrica:
          json['rubrica']?.toString() ??
          json['twitch_rubrica']?.toString() ??
          '',
      episodeNumber: _readInt(json['episodeNumber'] ?? json['episode_number']),
      imageUrl: json['imageUrl']?.toString() ?? '',
      targetUrl:
          json['targetUrl']?.toString() ?? json['twitch_url']?.toString() ?? '',
      startDate:
          json['startDate']?.toString() ??
          json['twitch_data_ora']?.toString() ??
          '',
      status:
          json['status']?.toString() ??
          json['twitch_stato']?.toString() ??
          'programmata',
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class TwitchService {
  static const String _baseUrl = 'https://www.ladyradio.it/wp-json/ladyapp/v1';
  static const Duration _requestTimeout = Duration(seconds: 8);

  final http.Client _client = http.Client();

  Future<TwitchEventsResponse> fetchEvents() async {
    try {
      final uri = Uri.parse('$_baseUrl/twitch-events').replace(
        queryParameters: {
          't': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
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
        return TwitchEventsResponse.empty();
      }

      return TwitchEventsResponse.fromJson(json.decode(response.body));
    } on TimeoutException catch (e) {
      debugPrint('Timeout fetch Twitch events: $e');
      return TwitchEventsResponse.empty();
    } catch (e) {
      debugPrint('Errore fetch Twitch events: $e');
      return TwitchEventsResponse.empty();
    }
  }
}
