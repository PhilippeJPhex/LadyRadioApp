import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_theme.dart';
import '../data/twitch_service.dart';
import '../screens/twitch_archive_screen.dart';

class TwitchEventsSlider extends StatefulWidget {
  const TwitchEventsSlider({super.key});

  @override
  State<TwitchEventsSlider> createState() => _TwitchEventsSliderState();
}

class _TwitchEventsSliderState extends State<TwitchEventsSlider> {
  static const Color _twitchPurple = Color(0xFF9146FF);

  final TwitchService _service = TwitchService();
  late final Future<TwitchEventsResponse> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _service.fetchEvents();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openArchive(List<TwitchEventModel> completed) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TwitchArchiveScreen(completedEvents: completed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TwitchEventsResponse>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        final response = snapshot.data ?? TwitchEventsResponse.empty();
        if (response.scheduled.isEmpty && response.completed.isEmpty) {
          return const SizedBox.shrink();
        }

        final nextEvent = response.scheduled.isNotEmpty
            ? response.scheduled.first
            : null;
        final agendaItems = response.scheduled.length > 1
            ? response.scheduled.skip(1).take(4).toList()
            : <TwitchEventModel>[];

        return Padding(
          padding: const EdgeInsets.only(top: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildHeader(response),
              ),
              if (nextEvent != null) ...[
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildFeaturedCard(nextEvent),
                ),
              ],
              if (agendaItems.isNotEmpty) ...[
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildAgendaList(agendaItems),
                ),
              ],
              if (response.completed.isNotEmpty) ...[
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildCompletedStrip(response.completed),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(TwitchEventsResponse response) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _twitchPurple,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/twitch.svg',
              width: 25,
              height: 25,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            'SU TWITCH',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: AppTheme.primaryColor,
              letterSpacing: 2.8,
            ),
          ),
        ),
        if (response.hasChannelUrl)
          Material(
            color: _twitchPurple,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => _openUrl(response.channelUrl),
              child: const SizedBox(
                height: 46,
                width: 112,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Seguici',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFeaturedCard(TwitchEventModel event) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D1B5E), Color(0xFF1A1A3E)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: Container(
              width: 180,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.centerLeft,
                  colors: [
                    _twitchPurple.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildFeaturedThumb(event),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '● PROSSIMA DIRETTA',
                      style: TextStyle(
                        color: _twitchPurple,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 21,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _subtitleFor(event),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dateLineFor(event),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.58),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (event.hasTargetUrl) ...[
                      const SizedBox(height: 14),
                      Material(
                        color: _twitchPurple,
                        borderRadius: BorderRadius.circular(22),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () => _openUrl(event.targetUrl),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.notifications_active,
                                  color: Colors.white,
                                  size: 17,
                                ),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Ricordamelo su Twitch',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedThumb(TwitchEventModel event) {
    return Container(
      width: 98,
      height: 98,
      decoration: BoxDecoration(
        color: _twitchPurple.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _twitchPurple.withValues(alpha: 0.42)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: event.imageUrl.isEmpty
            ? Center(
                child: SvgPicture.asset(
                  'assets/twitch.svg',
                  width: 38,
                  height: 38,
                  colorFilter: const ColorFilter.mode(
                    _twitchPurple,
                    BlendMode.srcIn,
                  ),
                ),
              )
            : CachedNetworkImage(
                imageUrl: event.imageUrl,
                fit: BoxFit.cover,
                httpHeaders: const {'Referer': 'https://www.ladyradio.it/'},
                errorWidget: (_, _, _) => Center(
                  child: SvgPicture.asset(
                    'assets/twitch.svg',
                    width: 38,
                    height: 38,
                    colorFilter: const ColorFilter.mode(
                      _twitchPurple,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAgendaList(List<TwitchEventModel> items) {
    return Container(
      decoration: AppTheme.cardDecoration(radius: 20),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _buildAgendaRow(items[i]),
            if (i != items.length - 1)
              Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
          ],
        ],
      ),
    );
  }

  Widget _buildAgendaRow(TwitchEventModel event) {
    final date = _parseDate(event.startDate);
    return InkWell(
      onTap: event.hasTargetUrl ? () => _openUrl(event.targetUrl) : null,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: Column(
                children: [
                  Text(
                    _weekdayShort(date).toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.textPrimary.withValues(alpha: 0.45),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    date?.day.toString() ?? '',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 42,
              color: Colors.black.withValues(alpha: 0.08),
              margin: const EdgeInsets.symmetric(horizontal: 14),
            ),
            Expanded(
              child: Text(
                event.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _timeOf(date),
              style: TextStyle(
                color: AppTheme.textPrimary.withValues(alpha: 0.48),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedStrip(List<TwitchEventModel> completed) {
    return InkWell(
      onTap: () => _openArchive(completed),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration(radius: 20),
        child: Row(
          children: [
            SizedBox(
              width: 112,
              height: 54,
              child: Stack(
                children: completed.take(3).toList().asMap().entries.map((
                  entry,
                ) {
                  return Positioned(
                    left: entry.key * 32.0,
                    child: _buildMiniThumb(entry.value, entry.key + 1),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PUNTATE GIA ANDATE IN ONDA',
                    style: TextStyle(
                      color: Color(0xFF92869B),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.6,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Rivedi su Twitch →',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.primaryColor,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniThumb(TwitchEventModel event, int fallbackIndex) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: _twitchPurple.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: event.imageUrl.isEmpty
            ? Center(
                child: Text(
                  fallbackIndex.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              )
            : CachedNetworkImage(
                imageUrl: event.imageUrl,
                fit: BoxFit.cover,
                httpHeaders: const {'Referer': 'https://www.ladyradio.it/'},
                errorWidget: (_, _, _) => Center(
                  child: Text(
                    fallbackIndex.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  String _subtitleFor(TwitchEventModel event) {
    if (event.description.trim().isNotEmpty) return event.description.trim();
    final rubrica = event.rubrica.trim();
    final episode = event.episodeNumber > 0 ? 'Ep. ${event.episodeNumber}' : '';
    if (rubrica.isNotEmpty && episode.isNotEmpty) return '$rubrica · $episode';
    if (rubrica.isNotEmpty) return rubrica;
    if (episode.isNotEmpty) return episode;
    return 'Diretta Twitch Lady Radio';
  }

  String _dateLineFor(TwitchEventModel event) {
    final date = _parseDate(event.startDate);
    final episode = event.episodeNumber > 0
        ? 'Ep. ${event.episodeNumber} · '
        : '';
    if (date == null) {
      return episode.isEmpty ? event.startDate : '$episode${event.startDate}';
    }
    return '$episode${_weekdayName(date)} ${date.day} ${_monthName(date)} · ore ${_timeOf(date)}';
  }

  DateTime? _parseDate(String value) {
    final normalized = value.trim().replaceFirst(' ', 'T');
    return DateTime.tryParse(normalized);
  }

  String _timeOf(DateTime? date) {
    if (date == null) return '';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _weekdayShort(DateTime? date) {
    if (date == null) return '';
    const days = ['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'];
    return days[date.weekday - 1];
  }

  String _weekdayName(DateTime date) {
    const days = [
      'Lunedi',
      'Martedi',
      'Mercoledi',
      'Giovedi',
      'Venerdi',
      'Sabato',
      'Domenica',
    ];
    return days[date.weekday - 1];
  }

  String _monthName(DateTime date) {
    const months = [
      'gennaio',
      'febbraio',
      'marzo',
      'aprile',
      'maggio',
      'giugno',
      'luglio',
      'agosto',
      'settembre',
      'ottobre',
      'novembre',
      'dicembre',
    ];
    return months[date.month - 1];
  }
}
