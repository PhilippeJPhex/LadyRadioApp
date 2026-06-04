import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_theme.dart';
import '../data/twitch_service.dart';

class TwitchArchiveScreen extends StatelessWidget {
  final List<TwitchEventModel> completedEvents;

  const TwitchArchiveScreen({super.key, required this.completedEvents});

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByRubrica(completedEvents);

    return Scaffold(
      appBar: AppBar(title: const Text('Puntate Twitch')),
      body: grouped.isEmpty
          ? const Center(child: Text('Nessuna puntata disponibile.'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
              children: grouped.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...entry.value.map(_TwitchArchiveTile.new),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Map<String, List<TwitchEventModel>> _groupByRubrica(
    List<TwitchEventModel> events,
  ) {
    final grouped = <String, List<TwitchEventModel>>{};
    for (final event in events) {
      final key = event.rubrica.trim().isEmpty
          ? 'Altre puntate'
          : event.rubrica.trim();
      grouped.putIfAbsent(key, () => []).add(event);
    }
    return grouped;
  }
}

class _TwitchArchiveTile extends StatelessWidget {
  final TwitchEventModel event;

  const _TwitchArchiveTile(this.event);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: event.hasTargetUrl ? () => _open(event.targetUrl) : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: event.imageUrl.isEmpty
                      ? Container(
                          width: 72,
                          height: 72,
                          color: const Color(0xFF9146FF),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 34,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: event.imageUrl,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          httpHeaders: const {
                            'Referer': 'https://www.ladyradio.it/',
                          },
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      if (event.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          event.description.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (event.hasTargetUrl)
                  const Icon(
                    Icons.open_in_new,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
