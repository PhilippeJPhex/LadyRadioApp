import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/app_constants.dart';

class ListeningChannel {
  final String id;
  final String title;
  final String subtitle;
  final String detail;
  final String url;
  final String icon;

  const ListeningChannel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.url,
    required this.icon,
  });

  factory ListeningChannel.fromJson(
    Map<String, dynamic> json, {
    String fallbackId = '',
  }) {
    final rawId = _readString(json, ['id', 'key', 'slug']);
    final rawIcon = _readString(json, ['icon', 'type']);
    final title = _readString(json, ['title', 'name', 'label']);
    final id = _normalizeId(
      rawId.isNotEmpty
          ? rawId
          : fallbackId.isNotEmpty
          ? fallbackId
          : rawIcon.isNotEmpty
          ? rawIcon
          : title,
    );

    return ListeningChannel(
      id: id,
      title: title.isNotEmpty ? title : _titleForId(id),
      subtitle: _stripHtml(
        _readString(json, ['subtitle', 'description', 'text']),
      ),
      detail: _stripHtml(_readDetail(json)),
      url: _readString(json, ['url', 'link', 'href']),
      icon: rawIcon.isNotEmpty ? _normalizeId(rawIcon) : id,
    );
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  static String _readDetail(Map<String, dynamic> json) {
    final directDetail = _readString(json, ['detail', 'value', 'frequency']);
    if (directDetail.isNotEmpty) return directDetail;

    final details = json['details'];
    if (details is String) return details;
    if (details is Map) {
      return _formatDetailMap(Map<String, dynamic>.from(details));
    }
    if (details is List) {
      return details
          .map((item) {
            if (item is Map) {
              return _formatDetailMap(Map<String, dynamic>.from(item));
            }
            return item?.toString().trim() ?? '';
          })
          .where((line) => line.isNotEmpty)
          .join('\n');
    }

    return '';
  }

  static String _formatDetailMap(Map<String, dynamic> item) {
    final area = _readString(item, ['area', 'zone', 'city', 'label']);
    final frequency = _readString(item, ['freq', 'frequency', 'value']);
    if (area.isEmpty) return frequency;
    if (frequency.isEmpty) return area;
    return '$area - $frequency';
  }

  static String _stripHtml(String value) {
    return value.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  static String _normalizeId(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
  }

  static String _titleForId(String id) {
    switch (id) {
      case 'fm':
        return 'FM';
      case 'dab':
        return 'DAB';
      case 'web':
      case 'website':
      case 'sito':
      case 'sito_web':
        return 'Sito web';
      case 'facebook':
      case 'fb':
        return 'Facebook';
      case 'instagram':
      case 'ig':
        return 'Instagram';
      case 'twitch':
        return 'Twitch';
      case 'car':
      case 'carplay':
      case 'android_auto':
      case 'carplay_android_auto':
        return 'CarPlay e Android Auto';
      case 'smart_speaker':
        return 'Smart speaker';
      default:
        return id
            .split('_')
            .where((part) => part.isNotEmpty)
            .map((part) => part[0].toUpperCase() + part.substring(1))
            .join(' ');
    }
  }
}

class AppConfig {
  final String streamUrl;
  final String tvUrl;
  final String tvText;
  final String website;
  final String whatsapp;
  final String email;
  final String facebook;
  final String instagram;
  final String dab;
  final String twitchChannelUrl;
  final List<ListeningChannel> channels;

  AppConfig({
    required this.streamUrl,
    required this.tvUrl,
    required this.tvText,
    required this.website,
    required this.whatsapp,
    required this.email,
    required this.facebook,
    required this.instagram,
    required this.dab,
    required this.twitchChannelUrl,
    required this.channels,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final streamUrl = json['radio']?['url']?.toString() ?? '';
    final tvUrl = json['tv']?['url']?.toString() ?? '';
    final tvText = ListeningChannel._stripHtml(
      json['tv']?['text']?.toString() ?? '',
    );
    final website = json['info']?['website']?.toString() ?? '';
    final whatsapp =
        json['info']?['whatsapp']?.toString().replaceAll(' ', '') ?? '';
    final email = json['info']?['email']?['to']?.toString() ?? '';
    final facebook = json['info']?['facebook']?.toString() ?? '';
    final instagram = json['info']?['instagram']?.toString() ?? '';
    final remoteChannels = _parseChannels(json['channels']);
    final dabChannelDetails = remoteChannels
        .where((channel) => _channelKey(channel) == 'dab')
        .map((channel) => channel.detail)
        .where((detail) => detail.isNotEmpty);
    final dab = dabChannelDetails.isNotEmpty ? dabChannelDetails.first : '';
    final fallback = fallbackChannels(
      website: website,
      tvUrl: tvUrl,
      tvText: tvText,
      facebook: facebook,
      instagram: instagram,
    );
    final channels = _mergeChannels(fallback, remoteChannels);

    return AppConfig(
      streamUrl: streamUrl,
      tvUrl: tvUrl,
      tvText: tvText,
      website: website,
      whatsapp: whatsapp,
      email: email,
      facebook: facebook,
      instagram: instagram,
      dab: dab,
      twitchChannelUrl: '',
      channels: channels,
    );
  }

  AppConfig copyWith({
    String? twitchChannelUrl,
    List<ListeningChannel>? channels,
  }) {
    return AppConfig(
      streamUrl: streamUrl,
      tvUrl: tvUrl,
      tvText: tvText,
      website: website,
      whatsapp: whatsapp,
      email: email,
      facebook: facebook,
      instagram: instagram,
      dab: dab,
      twitchChannelUrl: twitchChannelUrl ?? this.twitchChannelUrl,
      channels: channels ?? this.channels,
    );
  }

  static List<ListeningChannel> _parseChannels(dynamic rawChannels) {
    if (rawChannels is Map) {
      return rawChannels.entries
          .map((entry) {
            final fallbackId = entry.key.toString();
            final value = entry.value;
            if (value is Map) {
              return ListeningChannel.fromJson(
                Map<String, dynamic>.from(value),
                fallbackId: fallbackId,
              );
            }

            final normalizedId = ListeningChannel._normalizeId(fallbackId);
            return ListeningChannel(
              id: normalizedId,
              title: ListeningChannel._titleForId(normalizedId),
              subtitle: '',
              detail: ListeningChannel._stripHtml(value?.toString() ?? ''),
              url: '',
              icon: normalizedId,
            );
          })
          .where((channel) => channel.title.isNotEmpty)
          .toList();
    }

    if (rawChannels is! List) return [];

    return rawChannels
        .whereType<Map>()
        .map(
          (item) => ListeningChannel.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((channel) => channel.title.isNotEmpty)
        .toList();
  }

  static List<ListeningChannel> _mergeChannels(
    List<ListeningChannel> fallback,
    List<ListeningChannel> remote,
  ) {
    if (remote.isEmpty) return fallback;

    final remoteFmChannels = remote
        .where((channel) => _channelKey(channel) == 'fm')
        .toList();
    final remoteByKey = <String, ListeningChannel>{};

    for (final channel in remote) {
      final key = _channelKey(channel);
      if (key != 'fm') {
        remoteByKey[key] = channel;
      }
    }

    final result = <ListeningChannel>[];
    var addedRemoteFm = false;

    for (final fallbackChannel in fallback) {
      final key = _channelKey(fallbackChannel);
      if (key == 'fm') {
        if (remoteFmChannels.isNotEmpty) {
          if (!addedRemoteFm) {
            result.addAll(remoteFmChannels);
            addedRemoteFm = true;
          }
          continue;
        }
        result.add(fallbackChannel);
        continue;
      }

      result.add(remoteByKey.remove(key) ?? fallbackChannel);
    }

    result.addAll(remoteByKey.values);
    return result;
  }

  static String _channelKey(ListeningChannel channel) {
    final values = [
      channel.id,
      channel.icon,
      channel.title,
    ].map(ListeningChannel._normalizeId).toList();

    if (values.any((value) => value == 'fm' || value.contains('frequenz'))) {
      return 'fm';
    }
    if (values.any((value) => value == 'dab' || value.contains('dab'))) {
      return 'dab';
    }
    if (values.any(
      (value) =>
          value == 'web' ||
          value == 'website' ||
          value == 'sito' ||
          value == 'sito_web',
    )) {
      return 'web';
    }
    if (values.any((value) => value == 'facebook' || value == 'fb')) {
      return 'facebook';
    }
    if (values.any((value) => value == 'instagram' || value == 'ig')) {
      return 'instagram';
    }
    if (values.any((value) => value == 'twitch')) {
      return 'twitch';
    }
    if (values.any(
      (value) =>
          value == 'car' ||
          value == 'auto' ||
          value == 'carplay' ||
          value == 'android_auto' ||
          value == 'carplay_android_auto' ||
          value.contains('carplay'),
    )) {
      return 'car';
    }
    if (values.any(
      (value) =>
          value == 'smart_speaker' ||
          value == 'speaker' ||
          value == 'alexa' ||
          value == 'google_home',
    )) {
      return 'smart_speaker';
    }

    return values.firstWhere((value) => value.isNotEmpty, orElse: () => '');
  }

  static List<ListeningChannel> fallbackChannels({
    String website = AppConstants.website,
    String tvUrl = '',
    String tvText = '',
    String facebook = AppConstants.facebookUrl,
    String instagram = AppConstants.instagramUrl,
    String twitchChannelUrl = '',
  }) {
    return [
      ...AppConstants.frequencies.map(
        (frequency) => ListeningChannel(
          id: 'fm',
          title: 'FM',
          subtitle: frequency['area'] ?? '',
          detail: frequency['freq'] ?? '',
          url: '',
          icon: 'fm',
        ),
      ),
      ListeningChannel(
        id: 'web',
        title: 'Sito web',
        subtitle: 'Diretta, notizie e contenuti Lady Radio',
        detail: website.replaceAll(RegExp(r'https?://'), ''),
        url: website,
        icon: 'web',
      ),
      if (facebook.isNotEmpty)
        ListeningChannel(
          id: 'facebook',
          title: 'Facebook',
          subtitle: 'Seguici e resta aggiornato',
          detail: 'Lady Radio Firenze',
          url: facebook,
          icon: 'facebook',
        ),
      if (instagram.isNotEmpty)
        ListeningChannel(
          id: 'instagram',
          title: 'Instagram',
          subtitle: 'Stories, video e aggiornamenti',
          detail: '@ladyradiofirenze',
          url: instagram,
          icon: 'instagram',
        ),
      if (twitchChannelUrl.isNotEmpty && twitchChannelUrl != '#')
        ListeningChannel(
          id: 'twitch',
          title: 'Twitch',
          subtitle: 'Dirette video e contenuti speciali Lady Radio',
          detail: twitchChannelUrl.replaceAll(RegExp(r'https?://'), ''),
          url: twitchChannelUrl,
          icon: 'twitch',
        ),
      const ListeningChannel(
        id: 'car',
        title: 'CarPlay e Android Auto',
        subtitle: 'Ascolta Lady Radio anche in auto',
        detail: 'App mobile',
        url: '',
        icon: 'car',
      ),
      const ListeningChannel(
        id: 'smart_speaker',
        title: 'Smart speaker',
        subtitle: 'Ascolta Lady Radio con il tuo assistente vocale',
        detail: '',
        url: '',
        icon: 'smart_speaker',
      ),
    ];
  }
}

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  AppConfig? _currentConfig;
  AppConfig? get currentConfig => _currentConfig;

  void clearCache() {
    _currentConfig = null;
  }

  Future<AppConfig> getConfig() async {
    if (_currentConfig != null) {
      return _currentConfig!;
    }

    try {
      final response = await http.get(
        Uri.parse('https://www.ladyradio.it/stream_conf/config.json'),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(
          _removeTrailingCommas(utf8.decode(response.bodyBytes)),
        );
        final baseConfig = AppConfig.fromJson(data);
        final twitchChannelUrl = await _fetchTwitchChannelUrl();
        _currentConfig = twitchChannelUrl.isEmpty
            ? baseConfig
            : baseConfig.copyWith(
                twitchChannelUrl: twitchChannelUrl,
                channels: _upsertTwitchChannel(
                  baseConfig.channels,
                  twitchChannelUrl,
                ),
              );
        return _currentConfig!;
      } else {
        throw Exception('Failed to load config');
      }
    } catch (e) {
      // Fallback in case of error
      _currentConfig = AppConfig(
        streamUrl:
            'https://stream4.xdevel.com/audio0s978435-2634/stream/icecast.audio',
        tvUrl: '',
        tvText: '',
        website: 'https://www.ladyradio.it',
        whatsapp: '393925727775',
        email: 'redazione@ladyradio.it',
        facebook: '',
        instagram: '',
        dab: '',
        twitchChannelUrl: '',
        channels: AppConfig.fallbackChannels(),
      );
      return _currentConfig!;
    }
  }

  Future<String> _fetchTwitchChannelUrl() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.ladyradio.it/wp-json/ladyapp/v1/app-config'),
        headers: const {
          'Accept': 'application/json, text/plain, */*',
          'Cache-Control': 'no-cache',
        },
      );

      if (response.statusCode != 200) return '';

      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic>) return '';

      final url = data['twitchChannelUrl']?.toString().trim() ?? '';
      if (url.isEmpty || url == '#') return '';
      return url;
    } catch (_) {
      return '';
    }
  }

  List<ListeningChannel> _upsertTwitchChannel(
    List<ListeningChannel> channels,
    String twitchChannelUrl,
  ) {
    final twitchChannel = ListeningChannel(
      id: 'twitch',
      title: 'Twitch',
      subtitle: 'Dirette video e contenuti speciali Lady Radio',
      detail: twitchChannelUrl.replaceAll(RegExp(r'https?://'), ''),
      url: twitchChannelUrl,
      icon: 'twitch',
    );

    final filtered = channels
        .where((channel) => AppConfig._channelKey(channel) != 'twitch')
        .toList();

    final instagramIndex = filtered.indexWhere(
      (channel) => AppConfig._channelKey(channel) == 'instagram',
    );
    if (instagramIndex >= 0) {
      filtered.insert(instagramIndex + 1, twitchChannel);
      return filtered;
    }

    filtered.add(twitchChannel);
    return filtered;
  }

  static String _removeTrailingCommas(String source) {
    return source.replaceAllMapped(
      RegExp(r',\s*([}\]])'),
      (match) => match.group(1)!,
    );
  }
}
