import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'dart:convert';
import '../models/rss_episode.dart';

class RssService {
  Future<List<RssEpisode>> fetchPodcastEpisodes(String feedUrl) async {
    try {
      final url = feedUrl;
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'LadyRadioApp/1.0',
          'Referer': 'https://www.ladyradio.it/',
        },
      );

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(utf8.decode(response.bodyBytes));
        final items = document.findAllElements('item');

        return items.map((node) => RssEpisode.fromXml(node)).toList();
      } else {
        throw Exception('Failed to load RSS feed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('=== RSS ERROR === \n$e');
      throw Exception('Error fetching RSS feed: $e');
    }
  }
}
