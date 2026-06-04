import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_theme.dart';
import '../core/app_constants.dart';
import '../data/config_service.dart';
import '../widgets/global_mini_player.dart';

class FrequenciesScreen extends StatefulWidget {
  const FrequenciesScreen({super.key});

  @override
  State<FrequenciesScreen> createState() => _FrequenciesScreenState();
}

class _FrequenciesScreenState extends State<FrequenciesScreen> {
  late Future<AppConfig> _configFuture;

  @override
  void initState() {
    super.initState();
    _configFuture = ConfigService().getConfig();
  }

  Future<void> _refreshConfig() async {
    ConfigService().clearCache();
    final nextConfig = ConfigService().getConfig();
    setState(() {
      _configFuture = nextConfig;
    });
    await nextConfig;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlobalMiniPlayerVisibilityBuilder(
        builder: (context, isMiniPlayerVisible) {
          return FutureBuilder<AppConfig>(
            future: _configFuture,
            builder: (context, snapshot) {
              final config = snapshot.data;
              final channels = _sortListeningChannels(
                _groupFmChannels(
                  config?.channels ?? AppConfig.fallbackChannels(),
                ),
              );

              return RefreshIndicator(
                color: AppTheme.primaryColor,
                onRefresh: _refreshConfig,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    top: isMiniPlayerVisible ? 24 : 88,
                    left: 20,
                    right: 20,
                    bottom: 120,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Come ascoltarci',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Scegli il canale che preferisci: FM, streaming, sito, social e ascolto in auto.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          height: 1.35,
                          fontSize: 14,
                        ),
                      ),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: LinearProgressIndicator(
                            color: AppTheme.primaryColor,
                            minHeight: 2,
                          ),
                        ),
                      const SizedBox(height: 24),
                      ...channels.map(
                        (channel) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ListeningChannelCard(channel: channel),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildReportButton(),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildReportButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () async {
          const text =
              '[SEGNALAZIONE]: ciao, vorrei segnalare un problema riguardante...';
          final url = AppConstants.whatsappUri(text: text);
          final webUrl = AppConstants.whatsappWebUri(text: text);
          if (await canLaunchUrl(url)) {
            await launchUrl(url);
          } else {
            await launchUrl(webUrl);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        label: const Text(
          'Segnala un problema',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

List<ListeningChannel> _groupFmChannels(List<ListeningChannel> channels) {
  final fmChannels = channels.where(_isFmChannel).toList();
  if (fmChannels.length <= 1) return channels;

  final firstFmIndex = channels.indexWhere(_isFmChannel);
  final groupedFm = ListeningChannel(
    id: 'fm',
    title: 'FM',
    subtitle: 'Le frequenze per ascoltare Lady Radio',
    detail: fmChannels
        .map((channel) {
          final area = channel.subtitle.trim();
          final frequency = channel.detail.trim();
          if (area.isEmpty) return frequency;
          if (frequency.isEmpty) return area;
          return '$area - $frequency';
        })
        .where((line) => line.isNotEmpty)
        .join('\n'),
    url: '',
    icon: 'fm',
  );

  final result = <ListeningChannel>[];
  for (var index = 0; index < channels.length; index++) {
    final channel = channels[index];
    if (_isFmChannel(channel)) {
      if (index == firstFmIndex) {
        result.add(groupedFm);
      }
    } else {
      result.add(channel);
    }
  }

  return result;
}

bool _isFmChannel(ListeningChannel channel) {
  final id = _normalizeChannelValue(channel.id);
  final icon = _normalizeChannelValue(channel.icon);
  final title = _normalizeChannelValue(channel.title);
  return id == 'fm' ||
      icon == 'fm' ||
      title == 'fm' ||
      title.contains('frequenz');
}

List<ListeningChannel> _sortListeningChannels(List<ListeningChannel> channels) {
  final indexedChannels = channels.indexed.toList();
  indexedChannels.sort((left, right) {
    final leftOrder = _channelSortOrder(left.$2);
    final rightOrder = _channelSortOrder(right.$2);
    if (leftOrder != rightOrder) return leftOrder.compareTo(rightOrder);
    return left.$1.compareTo(right.$1);
  });
  return indexedChannels.map((entry) => entry.$2).toList();
}

int _channelSortOrder(ListeningChannel channel) {
  final key = _channelDisplayKey(channel);
  switch (key) {
    case 'fm':
      return 0;
    case 'dab':
      return 1;
    case 'web':
      return 2;
    case 'facebook':
      return 3;
    case 'instagram':
      return 4;
    case 'car':
      return 5;
    case 'smart_speaker':
      return 6;
    default:
      return 99;
  }
}

String _channelDisplayKey(ListeningChannel channel) {
  final values = [
    channel.id,
    channel.icon,
    channel.title,
  ].map(_normalizeChannelValue).toList();

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
  return '';
}

String _normalizeChannelValue(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
}

class _ListeningChannelCard extends StatelessWidget {
  final ListeningChannel channel;

  const _ListeningChannelCard({required this.channel});

  @override
  Widget build(BuildContext context) {
    final canOpen = channel.url.isNotEmpty;
    final isDab = _channelDisplayKey(channel) == 'dab';
    final subtitle = isDab
        ? 'Ascoltaci anche in digitale in tutta la Toscana'
        : channel.subtitle;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: canOpen ? () => _openUrl(channel.url) : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.brandGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _ChannelIcon(channel: channel),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          height: 1.25,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (channel.detail.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        channel.detail,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (canOpen) ...[
                const SizedBox(width: 10),
                const Icon(
                  Icons.open_in_new_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openUrl(String value) async {
    final uri = Uri.parse(value);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ChannelIcon extends StatelessWidget {
  final ListeningChannel channel;

  const _ChannelIcon({required this.channel});

  @override
  Widget build(BuildContext context) {
    final key = _channelDisplayKey(channel);
    if (key == 'facebook') return const Center(child: _FacebookIcon());
    if (key == 'instagram') return const Center(child: _InstagramIcon());

    return Icon(_iconFor(channel.icon), color: Colors.white, size: 25);
  }

  IconData _iconFor(String value) {
    switch (_normalizeChannelValue(value)) {
      case 'fm':
      case 'radio':
        return Icons.radio_rounded;
      case 'stream':
      case 'audio':
        return Icons.graphic_eq_rounded;
      case 'dab':
      case 'digital_radio':
        return Icons.settings_input_antenna_rounded;
      case 'tv':
      case 'video':
        return Icons.live_tv_rounded;
      case 'web':
      case 'website':
      case 'sito':
      case 'sito_web':
        return Icons.language_rounded;
      case 'car':
      case 'auto':
      case 'carplay':
        return Icons.directions_car_filled_rounded;
      case 'app':
        return Icons.phone_iphone_rounded;
      case 'smart_speaker':
      case 'speaker':
      case 'alexa':
      case 'google_home':
        return Icons.speaker_rounded;
      default:
        return Icons.headphones_rounded;
    }
  }
}

class _FacebookIcon extends StatelessWidget {
  const _FacebookIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 25,
      height: 25,
      child: Center(
        child: Text(
          'f',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 27,
            height: 0.92,
            fontWeight: FontWeight.w900,
            fontFamily: 'Arial',
          ),
        ),
      ),
    );
  }
}

class _InstagramIcon extends StatelessWidget {
  const _InstagramIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 25,
      height: 25,
      child: CustomPaint(painter: _InstagramIconPainter()),
    );
  }
}

class _InstagramIconPainter extends CustomPainter {
  const _InstagramIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final outerRect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(outerRect, const Radius.circular(7)),
      paint,
    );
    canvas.drawCircle(size.center(Offset.zero), size.width * 0.22, paint);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.28),
      1.65,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
