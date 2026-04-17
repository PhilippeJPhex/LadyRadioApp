import 'package:flutter/material.dart';
import '../data/rss_service.dart';
import '../models/rss_episode.dart';

class ProgramViewModel extends ChangeNotifier {
  final RssService _rssService = RssService();

  List<RssEpisode> _episodes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<RssEpisode> get episodes => _episodes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadEpisodes(String? rssFeedUrl) async {
    if (rssFeedUrl == null || rssFeedUrl.isEmpty) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _episodes = await _rssService.fetchPodcastEpisodes(rssFeedUrl);
    } catch (e) {
      debugPrint('ProgramViewModel: errore caricamento episodi: $e');
      _errorMessage = 'Impossibile caricare le puntate.';
      _episodes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
