import 'package:http/http.dart' as http;
import 'dart:convert';

class AppConfig {
  final String streamUrl;
  final String tvUrl;
  final String website;
  final String whatsapp;
  final String email;
  final String facebook;
  final String instagram;

  AppConfig({
    required this.streamUrl,
    required this.tvUrl,
    required this.website,
    required this.whatsapp,
    required this.email,
    required this.facebook,
    required this.instagram,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      streamUrl: json['radio']?['url'] ?? '',
      tvUrl: json['tv']?['url'] ?? '',
      website: json['info']?['website'] ?? '',
      whatsapp: json['info']?['whatsapp']?.replaceAll(' ', '') ?? '',
      email: json['info']?['email']?['to'] ?? '',
      facebook: json['info']?['facebook'] ?? '',
      instagram: json['info']?['instagram'] ?? '',
    );
  }
}

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  AppConfig? _currentConfig;
  AppConfig? get currentConfig => _currentConfig;

  Future<AppConfig> getConfig() async {
    if (_currentConfig != null) {
      return _currentConfig!;
    }
    
    try {
      final response = await http.get(Uri.parse('https://ladyradio.it/stream_conf/config.json'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        _currentConfig = AppConfig.fromJson(data);
        return _currentConfig!;
      } else {
        throw Exception('Failed to load config');
      }
    } catch (e) {
      // Fallback in case of error
      return AppConfig(
        streamUrl: 'https://stream4.xdevel.com/audio0s978435-2634/stream/icecast.audio',
        tvUrl: '',
        website: 'https://ladyradio.it',
        whatsapp: '393925727775',
        email: 'redazione@ladyradio.it',
        facebook: '',
        instagram: '',
      );
    }
  }
}
