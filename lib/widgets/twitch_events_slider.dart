import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_theme.dart';
import '../data/twitch_service.dart';

class TwitchEventsSlider extends StatefulWidget {
  const TwitchEventsSlider({super.key});

  @override
  State<TwitchEventsSlider> createState() => _TwitchEventsSliderState();
}

class _TwitchEventsSliderState extends State<TwitchEventsSlider> {
  static const int _initialPage = 10000;

  final TwitchService _service = TwitchService();
  final PageController _pageController = PageController(
    initialPage: _initialPage,
  );
  late final Future<List<TwitchEventModel>> _eventsFuture;
  Timer? _autoScrollTimer;
  int _currentPage = _initialPage;
  int? _configuredEventsCount;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _service.fetchWeeklyEvents();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _configureAutoScroll(int eventsCount) {
    if (_configuredEventsCount == eventsCount) return;

    _configuredEventsCount = eventsCount;
    _autoScrollTimer?.cancel();

    if (eventsCount <= 1) return;

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_pageController.hasClients) return;

      final nextPage = _currentPage + 1;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _openEvent(TwitchEventModel event) async {
    final uri = Uri.tryParse(event.targetUrl);
    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TwitchEventModel>>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        final events = snapshot.data ?? const <TwitchEventModel>[];
        if (events.isEmpty) {
          return const SizedBox.shrink();
        }
        _configureAutoScroll(events.length);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'QUESTA SETTIMANA SU TWITCH',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppTheme.primaryColor,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) {
                  _currentPage = page;
                },
                itemBuilder: (context, index) {
                  final event = events[index % events.length];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => _openEvent(event),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: event.imageUrl,
                            httpHeaders: const {
                              'Referer': 'https://www.ladyradio.it/',
                            },
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            errorWidget: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
