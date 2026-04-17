import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CampaignBannerModel {
  final String id;
  final String imageUrl;
  final String targetUrl;

  CampaignBannerModel({
    required this.id,
    required this.imageUrl,
    required this.targetUrl,
  });

  factory CampaignBannerModel.fromJson(Map<String, dynamic> json) {
    return CampaignBannerModel(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String,
      targetUrl: json['targetUrl'] as String,
    );
  }
}

class BannerService {
  static const String _baseUrl = 'https://ladyradio.it/wp-json/ladyapp/v1';

  /// Chiama GET /api/active-banner
  /// Ritorna il banner valido per data, o null se non ce ne sono
  Future<CampaignBannerModel?> fetchActiveBanner() async {
    try {
      final apiUrl = '$_baseUrl/active-banner';
      final uri = Uri.parse(apiUrl);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CampaignBannerModel.fromJson(data);
      } else {
        debugPrint('Nessun banner attivo (Status: ${response.statusCode})');
        return null;
      }
    } catch (e) {
      debugPrint('Errore durante il fetch del banner: $e');
      return null;
    }
  }

  /// Chiama POST /api/track-impression
  Future<void> trackImpression(String bannerId) async {
    try {
      final apiUrl = '$_baseUrl/track-impression';
      final uri = Uri.parse(apiUrl);

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'bannerId': bannerId}),
      );
      if (response.statusCode == 200) {
        debugPrint('[BANNER TRACKING] \x1B[32m+1 VISTA\x1B[0m (Impression) salvata sul Server per il Banner: $bannerId');
      }
    } catch (e) {
      debugPrint('Errore tracking impression: $e');
    }
  }

  /// Chiama POST /api/track-click
  Future<void> trackClick(String bannerId) async {
    try {
      final apiUrl = '$_baseUrl/track-click';
      final uri = Uri.parse(apiUrl);

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'bannerId': bannerId}),
      );
      if (response.statusCode == 200) {
        debugPrint('[BANNER TRACKING] \x1B[34m+1 CLICK\x1B[0m salvato sul Server per il Banner: $bannerId');
      }
    } catch (e) {
      debugPrint('Errore tracking click: $e');
    }
  }
}

