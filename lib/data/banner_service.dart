import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/app_constants.dart';

enum BannerPosition {
  upper('upper'),
  bottom('bottom');

  final String apiValue;
  const BannerPosition(this.apiValue);
}

class CampaignBannerModel {
  final String id;
  final String imageUrl;
  final String targetUrl;
  final bool isFallback;
  final BannerPosition position;

  CampaignBannerModel({
    required this.id,
    required this.imageUrl,
    required this.targetUrl,
    this.isFallback = false,
    this.position = BannerPosition.upper,
  });

  factory CampaignBannerModel.fromJson(Map<String, dynamic> json) {
    return CampaignBannerModel(
      id: json['id']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      targetUrl: json['targetUrl']?.toString() ?? '',
      isFallback: _readBool(json['isFallback'] ?? json['is_fallback']),
      position: _readPosition(json['position'] ?? json['posizione']),
    );
  }

  factory CampaignBannerModel.fallback() {
    return CampaignBannerModel(
      id: 'fallback',
      imageUrl: AppConstants.fallbackBannerImage,
      targetUrl: AppConstants.fallbackBannerTargetUrl,
      isFallback: true,
      position: BannerPosition.upper,
    );
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      return [
        '1',
        'true',
        'yes',
        'si',
        'sì',
      ].contains(value.trim().toLowerCase());
    }
    return false;
  }

  static BannerPosition _readPosition(dynamic value) {
    return value?.toString() == BannerPosition.bottom.apiValue
        ? BannerPosition.bottom
        : BannerPosition.upper;
  }
}

class BannerService {
  static const String _baseUrl = 'https://www.ladyradio.it/wp-json/ladyapp/v1';
  static const String _siteOrigin = 'https://www.ladyradio.it';
  static const String _siteReferer = 'https://www.ladyradio.it/';
  static const String _appUserAgent =
      'LadyRadioApp/1.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148';
  static const Duration _requestTimeout = Duration(seconds: 8);
  static const Duration _trackingTimeout = Duration(seconds: 4);

  final http.Client _client = http.Client();
  final Map<String, String> _cookies = {};

  Map<String, String> get _defaultHeaders => _headers();
  Map<String, String> get _formHeaders => _headers(
    extra: const {'Content-Type': 'application/x-www-form-urlencoded'},
  );
  Map<String, String> get _jsonHeaders =>
      _headers(extra: const {'Content-Type': 'application/json'});

  /// Chiama GET /api/active-banner
  /// Ritorna il banner valido per data, o null se non ce ne sono
  Future<CampaignBannerModel?> fetchActiveBanner({
    BannerPosition position = BannerPosition.upper,
  }) async {
    try {
      final apiUrl = '$_baseUrl/active-banner/${position.apiValue}';
      final uri = Uri.parse(apiUrl).replace(
        queryParameters: {
          'position': position.apiValue,
          't': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      final response = await _client
          .get(uri, headers: _defaultHeaders)
          .timeout(_requestTimeout);
      _storeCookies(response);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CampaignBannerModel.fromJson(data);
      } else {
        debugPrint('Nessun banner attivo (Status: ${response.statusCode})');
        return null;
      }
    } on TimeoutException catch (e) {
      debugPrint('Timeout durante il fetch del banner: $e');
      return null;
    } catch (e) {
      debugPrint('Errore durante il fetch del banner: $e');
      return null;
    }
  }

  CampaignBannerModel? get fallbackBanner {
    if (AppConstants.fallbackBannerImage.trim().isEmpty) return null;
    return CampaignBannerModel.fallback();
  }

  /// Chiama POST /api/track-impression
  void trackImpression(String bannerId) {
    unawaited(
      _sendTrackingEvent(
        endpoint: 'track-impression',
        bannerId: bannerId,
        successMessage:
            '[BANNER TRACKING] \x1B[32m+1 VISTA\x1B[0m (Impression) salvata sul Server per il Banner: $bannerId',
        errorMessage: 'Errore tracking impression',
      ),
    );
  }

  /// Chiama POST /api/track-click
  Future<bool> trackClick(String bannerId) {
    return _sendTrackingEvent(
      endpoint: 'track-click',
      bannerId: bannerId,
      successMessage:
          '[BANNER TRACKING] \x1B[34m+1 CLICK\x1B[0m salvato sul Server per il Banner: $bannerId',
      errorMessage: 'Errore tracking click',
    );
  }

  Future<bool> _sendTrackingEvent({
    required String endpoint,
    required String bannerId,
    required String successMessage,
    required String errorMessage,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/$endpoint',
      ).replace(queryParameters: {'bannerId': bannerId});

      final formResponse = await _client
          .post(uri, headers: _formHeaders, body: {'bannerId': bannerId})
          .timeout(_trackingTimeout);
      _storeCookies(formResponse);

      if (_isSuccessfulTrackingResponse(formResponse)) {
        debugPrint(successMessage);
        return true;
      }

      debugPrint(
        '$errorMessage form fallback richiesto '
        '(Status: ${formResponse.statusCode}, Body: ${_shortBody(formResponse.body)})',
      );

      final jsonResponse = await _client
          .post(
            uri,
            headers: _jsonHeaders,
            body: json.encode({'bannerId': bannerId}),
          )
          .timeout(_trackingTimeout);
      _storeCookies(jsonResponse);

      if (_isSuccessfulTrackingResponse(jsonResponse)) {
        debugPrint(successMessage);
        return true;
      }

      debugPrint(
        '$errorMessage (Status: ${jsonResponse.statusCode}, Body: ${_shortBody(jsonResponse.body)})',
      );
      return false;
    } on TimeoutException catch (e) {
      debugPrint('$errorMessage timeout: $e');
      return false;
    } catch (e) {
      debugPrint('$errorMessage: $e');
      return false;
    }
  }

  Map<String, String> _headers({Map<String, String> extra = const {}}) {
    final headers = <String, String>{
      'User-Agent': _appUserAgent,
      'Accept': 'application/json, text/plain, */*',
      'Origin': _siteOrigin,
      'Referer': _siteReferer,
      'X-Requested-With': 'it.ladyradio.app',
      'Cache-Control': 'no-cache',
      'Connection': 'close',
      ...extra,
    };

    final cookieHeader = _cookieHeader;
    if (cookieHeader.isNotEmpty) {
      headers['Cookie'] = cookieHeader;
    }

    return headers;
  }

  String get _cookieHeader {
    return _cookies.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('; ');
  }

  void _storeCookies(http.Response response) {
    final rawSetCookie = response.headers['set-cookie'];
    if (rawSetCookie == null || rawSetCookie.isEmpty) return;

    final cookieParts = rawSetCookie.split(RegExp(r',(?=[^;,]+=)'));
    for (final cookiePart in cookieParts) {
      final cookie = cookiePart.split(';').first.trim();
      final separatorIndex = cookie.indexOf('=');
      if (separatorIndex <= 0) continue;

      final name = cookie.substring(0, separatorIndex);
      final value = cookie.substring(separatorIndex + 1);
      if (name.isNotEmpty && value.isNotEmpty) {
        _cookies[name] = value;
      }
    }
  }

  bool _isSuccessfulTrackingResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return false;
    }

    if (response.body.isEmpty) {
      return true;
    }

    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic> && decoded['success'] == false) {
        return false;
      }
    } catch (_) {
      return true;
    }

    return true;
  }

  String _shortBody(String body) {
    final normalized = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 180) {
      return normalized;
    }
    return '${normalized.substring(0, 180)}...';
  }
}
