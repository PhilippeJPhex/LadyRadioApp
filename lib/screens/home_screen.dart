import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/app_theme.dart';
import '../core/app_constants.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/lady_radio_header.dart';
import '../data/rss_service.dart';
import '../data/favorites_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/rss_episode.dart';
import 'program_screen.dart';
import 'podcast_screen.dart';
import 'schedule_screen.dart';
import '../widgets/campaign_banner.dart';

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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _viewModel.refresh();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          fontSize: 18,
                          color: AppTheme.primaryColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primaryColor),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ScheduleScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ListenableBuilder(
                  listenable: _viewModel,
                  builder: (context, _) {
                    if (_viewModel.isLoadingPrograms && _viewModel.programs.isEmpty) {
                      return const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _viewModel.programs.length,
                        itemBuilder: (context, index) {
                          final program = _viewModel.programs[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        ProgramScreen(programData: program)),
                              );
                            },
                            child: AnimatedOpacity(
                              opacity: 1.0,
                              duration: Duration(milliseconds: 300 + index * 100),
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
                                                fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            program['schedule'] ?? '',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textSecondary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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
                
                const SizedBox(height: 32),
                
                // Ultimi Podcast (Verticale)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'ULTIMI PODCAST',
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
                    if (_viewModel.isLoadingEpisodes && _viewModel.latestEpisodes.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                      );
                    }
                    if (_viewModel.latestEpisodes.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Nessun podcast recente.'),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: _viewModel.latestEpisodes
                            .map((ep) => _buildEpisodeCard(context, ep))
                            .toList(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 100), // Spazio per il mini player
              ],
            ),
          ),
        ),
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
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
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

  Widget _buildEpisodeCard(BuildContext context, RssEpisode ep) {
    final programData = _viewModel.findProgramByPostId(ep.programId ?? '');
    final fallbackProgram = _viewModel.programs.isNotEmpty ? _viewModel.programs.first : <String, dynamic>{};
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
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    PodcastScreen(episodeData: epDataMap)),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Immagine podcast con ombra e arrotondamento
            Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: (program['image'] != null && program['image'].toString().startsWith('http'))
                    ? CachedNetworkImage(
                        imageUrl: program['image'],
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Container(
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
                          fit: BoxFit.contain,
                        ),
                      )
                    : Image.asset(
                        AppConstants.logoAsset,
                        fit: BoxFit.contain,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Info Podcast
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ep.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    program['title'] ?? '',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    PodcastScreen(episodeData: epDataMap)),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                        icon: const Icon(Icons.play_circle_fill, size: 16),
                        label: const Text('Ascolta',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      ListenableBuilder(
                        listenable: FavoritesService(),
                        builder: (ctx, _) {
                          final isFav = FavoritesService().isFavorite(epDataMap['audioUrl'] ?? '');
                          return IconButton(
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.red : AppTheme.primaryColor,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              FavoritesService().toggleFavorite(epDataMap);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isFav ? 'Rimosso dai preferiti' : 'Aggiunto ai preferiti ❤️'),
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
          ],
        ),
      ),
    );
  }
}
