import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/app_theme.dart';
import '../core/app_constants.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/lady_radio_header.dart';
import '../data/favorites_service.dart';
import '../data/banner_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/rss_episode.dart';
import 'program_screen.dart';
import 'podcast_screen.dart';
import 'podcast_programs_screen.dart';
import 'schedule_screen.dart';
import '../widgets/campaign_banner.dart';
import '../widgets/global_mini_player.dart';
import '../widgets/twitch_events_slider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Piccolo delay per non disturbare l'animazione di avvio
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      final mic = await Permission.microphone.status;
      final speech = await Permission.speech.status;

      if (!mic.isGranted || !speech.isGranted) {
        // Notifica permessi rimossa
      }
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlobalMiniPlayerVisibilityBuilder(
        builder: (context, isMiniPlayerVisible) {
          return SafeArea(
            top: !isMiniPlayerVisible,
            child: Padding(
              padding: EdgeInsets.only(top: isMiniPlayerVisible ? 10 : 0),
              child: RefreshIndicator(
                onRefresh: () async {
                  await _viewModel.refresh();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: isMiniPlayerVisible ? 0 : 16),
                      const LadyRadioHeader(),
                      const SizedBox(height: 16),

                      // Banner Pubblicitario (Dinamico da WP)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: CampaignBanner(),
                      ),

                      const SizedBox(height: 16),

                      // Programmi del Giorno (Orizzontale)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'IL NOSTRO PALINSESTO',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: AppTheme.primaryColor,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Material(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(22),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(22),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ScheduleScreen(),
                                    ),
                                  );
                                },
                                child: const SizedBox(
                                  width: 86,
                                  height: 40,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Scopri',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 13,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListenableBuilder(
                        listenable: _viewModel,
                        builder: (context, _) {
                          if (_viewModel.isLoadingPrograms &&
                              _viewModel.programs.isEmpty) {
                            return const SizedBox(
                              height: 100,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            );
                          }
                          if (_viewModel.programs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Nessun programma trovato oggi.'),
                            );
                          }
                          return SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: _viewModel.programs.length,
                              itemBuilder: (context, index) {
                                final program = _viewModel.programs[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ProgramScreen(programData: program),
                                      ),
                                    );
                                  },
                                  child: AnimatedOpacity(
                                    opacity: 1.0,
                                    duration: Duration(
                                      milliseconds: 300 + index * 100,
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 16),
                                      padding: const EdgeInsets.all(12),
                                      width: 220,
                                      decoration: AppTheme.chipDecoration
                                          .copyWith(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: _buildProgramImage(
                                              program['image'],
                                              50,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  program['title'] ?? '',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  program['schedule'] ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        AppTheme.textSecondary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),

                      ListenableBuilder(
                        listenable: _viewModel,
                        builder: (context, _) {
                          if (_viewModel.podcastPrograms.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 32),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'I NOSTRI PODCAST',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        color: AppTheme.primaryColor,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    Material(
                                      color: AppTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(22),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(22),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  PodcastProgramsScreen(
                                                    podcastPrograms: _viewModel
                                                        .podcastPrograms,
                                                  ),
                                            ),
                                          );
                                        },
                                        child: const SizedBox(
                                          width: 86,
                                          height: 40,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Scopri',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              SizedBox(width: 6),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                size: 13,
                                                color: Colors.white,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildProgramPreviewList(
                                context,
                                _viewModel.podcastPrograms,
                                showSchedule: false,
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 28),
                      _buildLatestEpisodesSection(context),
                      const TwitchEventsSlider(),
                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: CampaignBanner(
                          position: BannerPosition.bottom,
                          allowFallback: false,
                        ),
                      ),
                      const SizedBox(height: 100), // Spazio per il mini player
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgramPreviewList(
    BuildContext context,
    List<Map<String, dynamic>> programs, {
    required bool showSchedule,
  }) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: programs.length,
        itemBuilder: (context, index) {
          final program = programs[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProgramScreen(programData: program),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(12),
              width: 220,
              decoration: AppTheme.chipDecoration.copyWith(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildProgramImage(program['image'], 50),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          program['title'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (showSchedule) ...[
                          Text(
                            program['schedule'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgramImage(String? imageUrl, double size) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Image.asset(
        AppConstants.logoAsset,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }
    if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          color: Colors.white,
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Image.asset(
          AppConstants.logoAsset,
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      );
    }
    return Image.asset(
      AppConstants.logoAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }

  Widget _buildLatestEpisodesSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'ULTIME TRASMISSIONI',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: AppTheme.primaryColor,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              if (_viewModel.isLoadingEpisodes &&
                  _viewModel.latestEpisodes.isEmpty) {
                return const SizedBox(
                  height: 96,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                );
              }

              if (_viewModel.latestEpisodes.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(4, 8, 4, 4),
                  child: Text('Nessuna trasmissione recente.'),
                );
              }

              return Column(
                children: _viewModel.latestEpisodes
                    .map((ep) => _buildEpisodeCard(context, ep))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeCard(BuildContext context, RssEpisode ep) {
    final programData = _viewModel.findProgramByPostId(ep.programId ?? '');
    final fallbackProgram = _viewModel.programs.isNotEmpty
        ? _viewModel.programs.first
        : <String, dynamic>{};
    final program = programData ?? fallbackProgram;

    final Map<String, dynamic> epDataMap = {
      'id': ep.title,
      'title': ep.title,
      'programId': program['postId'] ?? '',
      'program': program['title'] ?? '',
      'date': ep.pubDate,
      'duration': ep.duration,
      'image': program['image'] ?? AppConstants.logoAsset,
      'audioUrl': ep.audioUrl,
      'rssFeed': program['rssFeed'], // Passiamo il feed RSS
      'isPodcast': program['isPodcast'] ?? false,
      'urlVideo': ep.videoUrl,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PodcastScreen(episodeData: epDataMap),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.bgColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child:
                    (program['image'] != null &&
                        program['image'].toString().startsWith('http'))
                    ? CachedNetworkImage(
                        imageUrl: program['image'],
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 56,
                          height: 56,
                          color: Colors.white,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Image.asset(
                          AppConstants.logoAsset,
                          width: 56,
                          height: 56,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Image.asset(
                        AppConstants.logoAsset,
                        width: 56,
                        height: 56,
                        fit: BoxFit.contain,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      program['title'] ?? '',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ep.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        height: 1.18,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      ep.pubDate,
                      style: TextStyle(
                        color: AppTheme.textPrimary.withValues(alpha: 0.48),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: AppTheme.primaryColor.withValues(alpha: 0.11),
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(
                        Icons.play_arrow_rounded,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 34,
                        height: 34,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PodcastScreen(episodeData: epDataMap),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  ListenableBuilder(
                    listenable: FavoritesService(),
                    builder: (ctx, _) {
                      final isFav = FavoritesService().isFavorite(
                        epDataMap['audioUrl'] ?? '',
                      );
                      return IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : AppTheme.primaryColor,
                          size: 19,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 28,
                          height: 28,
                        ),
                        onPressed: () {
                          FavoritesService().toggleFavorite(epDataMap);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isFav
                                    ? 'Rimosso dai preferiti'
                                    : 'Aggiunto ai preferiti ❤️',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
