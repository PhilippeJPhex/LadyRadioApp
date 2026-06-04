import 'package:flutter/material.dart';
import '../data/rss_service.dart';
import '../data/schedule_service.dart';
import '../models/rss_episode.dart';

class HomeViewModel extends ChangeNotifier with WidgetsBindingObserver {
  final RssService _rssService = RssService();
  final ScheduleService _scheduleService = ScheduleService();

  List<Map<String, dynamic>> _programs = [];
  List<Map<String, dynamic>> _podcastPrograms = [];
  List<RssEpisode> _latestEpisodes = [];
  bool _isLoadingPrograms = true;
  bool _isLoadingEpisodes = true;
  DateTime? _lastRemoteRefresh;

  List<Map<String, dynamic>> get programs => _programs;
  List<Map<String, dynamic>> get podcastPrograms => _podcastPrograms;
  List<RssEpisode> get latestEpisodes => _latestEpisodes;
  bool get isLoadingPrograms => _isLoadingPrograms;
  bool get isLoadingEpisodes => _isLoadingEpisodes;

  HomeViewModel() {
    WidgetsBinding.instance.addObserver(this);
    _loadAll(forceRefresh: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    final lastRefresh = _lastRemoteRefresh;
    if (lastRefresh == null ||
        DateTime.now().difference(lastRefresh) > const Duration(seconds: 30)) {
      refresh();
    }
  }

  Future<void> _loadAll({bool forceRefresh = false}) async {
    try {
      final allPrograms = await _scheduleService.fetchUniquePrograms(
        forceRefresh: forceRefresh,
      );
      _lastRemoteRefresh = DateTime.now();
      _podcastPrograms = allPrograms.where(_isPodcastProgram).toList();
      _programs = allPrograms
          .where((program) => !_isPodcastProgram(program))
          .toList();
      _isLoadingPrograms = false;
      notifyListeners();

      // Now load episodes from programs that have an RSS feed
      _loadLatestEpisodes();
    } catch (e) {
      _isLoadingPrograms = false;
      _isLoadingEpisodes = false;
      notifyListeners();
    }
  }

  void _loadLatestEpisodes() {
    _isLoadingEpisodes = true;
    _latestEpisodes = [];
    notifyListeners();

    final programsWithFeed = _programs
        .where((p) => (p['rssFeed'] as String? ?? '').isNotEmpty)
        .toList();

    if (programsWithFeed.isEmpty) {
      _isLoadingEpisodes = false;
      notifyListeners();
      return;
    }

    int completedRequests = 0;

    // Date scoring for sorting
    int getScore(String dateStr) {
      final matches = RegExp(
        r'(\d{1,2}) (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) (\d{4}) (\d{2}):(\d{2}):(\d{2})',
      ).firstMatch(dateStr);
      if (matches != null) {
        final day = matches.group(1)!.padLeft(2, '0');
        final monthStr = matches.group(2)!;
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        final month = (months.indexOf(monthStr) + 1).toString().padLeft(2, '0');
        final year = matches.group(3)!;
        final hour = matches.group(4)!;
        final min = matches.group(5)!;
        final sec = matches.group(6)!;
        return int.tryParse('$year$month$day$hour$min$sec') ?? 0;
      }
      return 0;
    }

    for (var program in programsWithFeed) {
      _rssService
          .fetchPodcastEpisodes(program['rssFeed'])
          .then((eps) {
            completedRequests++;
            if (eps.isNotEmpty) {
              for (var ep in eps.take(2)) {
                ep.programId = program['postId'];
                _latestEpisodes.add(ep);
              }

              _latestEpisodes.sort((a, b) {
                final scoreA = getScore(a.pubDate);
                final scoreB = getScore(b.pubDate);
                if (scoreA != 0 && scoreB != 0) {
                  return scoreB.compareTo(scoreA);
                }
                return 0;
              });

              if (_latestEpisodes.length > 4) {
                _latestEpisodes = _latestEpisodes.sublist(0, 4);
              }
            }

            _isLoadingEpisodes = false;
            notifyListeners();
          })
          .catchError((e) {
            completedRequests++;
            if (completedRequests == programsWithFeed.length &&
                _latestEpisodes.isEmpty) {
              _isLoadingEpisodes = false;
              notifyListeners();
            }
          });
    }
  }

  /// Find a program by its postId
  Map<String, dynamic>? findProgramByPostId(String postId) {
    try {
      return [
        ..._programs,
        ..._podcastPrograms,
      ].firstWhere((p) => p['postId'] == postId);
    } catch (_) {
      return null;
    }
  }

  bool _isPodcastProgram(Map<String, dynamic> program) {
    final value = program['isPodcast'];
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

  Future<void> refresh() async {
    ScheduleService.clearCache();
    _isLoadingPrograms = true;
    _isLoadingEpisodes = true;
    notifyListeners();
    await _loadAll(forceRefresh: true);
  }
}
