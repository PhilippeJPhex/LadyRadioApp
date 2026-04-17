import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service per gestire i preferiti (puntate salvate) in locale.
class FavoritesService extends ChangeNotifier {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  static const String _key = 'favorite_episodes';
  List<Map<String, dynamic>> _favorites = [];

  List<Map<String, dynamic>> get favorites => List.unmodifiable(_favorites);
  int get count => _favorites.length;

  /// Inizializza caricando i preferiti dal disco
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = json.decode(jsonStr);
        _favorites = decoded.cast<Map<String, dynamic>>();
      } catch (e) {
        _favorites = [];
      }
    }
  }

  /// Controlla se un episodio è nei preferiti (per audioUrl)
  bool isFavorite(String audioUrl) {
    return _favorites.any((ep) => ep['audioUrl'] == audioUrl);
  }

  /// Aggiunge un episodio ai preferiti
  Future<void> addFavorite(Map<String, dynamic> episodeData) async {
    if (isFavorite(episodeData['audioUrl'] ?? '')) return;
    _favorites.insert(0, Map<String, dynamic>.from(episodeData));
    await _save();
    notifyListeners();
  }

  /// Rimuove un episodio dai preferiti
  Future<void> removeFavorite(String audioUrl) async {
    _favorites.removeWhere((ep) => ep['audioUrl'] == audioUrl);
    await _save();
    notifyListeners();
  }

  /// Toggle preferito
  Future<void> toggleFavorite(Map<String, dynamic> episodeData) async {
    final audioUrl = episodeData['audioUrl'] ?? '';
    if (isFavorite(audioUrl)) {
      await removeFavorite(audioUrl);
    } else {
      await addFavorite(episodeData);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(_favorites));
  }
}
