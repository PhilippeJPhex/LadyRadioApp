import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_theme.dart';
import '../core/app_constants.dart';
import '../data/favorites_service.dart';
import '../models/rss_episode.dart';
import '../viewmodels/program_viewmodel.dart';
import 'podcast_screen.dart';

class ProgramScreen extends StatefulWidget {
  final Map<String, dynamic> programData;

  const ProgramScreen({super.key, required this.programData});

  @override
  State<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  late final ProgramViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProgramViewModel();
    _viewModel.loadEpisodes(widget.programData['rssFeed'] as String?);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _launchWhatsApp() async {
    const text = '[Messaggio per la diretta]: ';
    final url = AppConstants.whatsappUri(text: text);
    final webUrl = AppConstants.whatsappWebUri(text: text);
    if (!await launchUrl(url)) {
      await launchUrl(webUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final program = widget.programData;
    // Descrizione dal programData (non hardcoded), fallback generico
    final description = (program['description'] as String?)?.isNotEmpty == true
        ? program['description'] as String
        : 'Ascolta le ultime notizie e aggiornamenti su Lady Radio.';
    final schedule = (program['schedule'] as String?)?.isNotEmpty == true
        ? program['schedule'] as String
        : 'In onda su Lady Radio';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 350,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.8),
                    AppTheme.primaryColor.withValues(alpha: 0.4),
                    Colors.white,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  pinned: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: const Text(
                    '',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  centerTitle: true,
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Cover del programma
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          image: DecorationImage(
                            image: program['image'].toString().startsWith('http')
                                ? CachedNetworkImageProvider(program['image'])
                                : AssetImage(program['image']) as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Titolo
                      Text(
                        program['title'],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Descrizione dinamica (non hardcoded)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Orario dinamico
                      Text(
                        schedule,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Azioni
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.play_circle_fill),
                            label: const Text('Riproduci',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.favorite_border),
                            color: AppTheme.secondaryColor,
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_horiz),
                            color: AppTheme.secondaryColor,
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // Episodi
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ascolta le ultime puntate',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondaryColor,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ListenableBuilder(
                              listenable: _viewModel,
                              builder: (context, _) {
                                if (_viewModel.isLoading) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                        color: AppTheme.primaryColor),
                                  );
                                }
                                if (_viewModel.errorMessage != null) {
                                  return Text(_viewModel.errorMessage!,
                                      style: const TextStyle(
                                          color: Colors.red));
                                }
                                if (_viewModel.episodes.isEmpty) {
                                  return const Text(
                                    'Nessuna puntata disponibile.',
                                    style: TextStyle(color: Colors.grey),
                                  );
                                }
                                return Column(
                                  children: _viewModel.episodes
                                      .map((ep) => _buildEpisodeTile(
                                          context, ep))
                                      .toList(),
                                );
                              },
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // FAB WhatsApp
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _launchWhatsApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                ),
                icon: Icon(Icons.chat, color: AppTheme.successColor),
                label: const Text('Invia un messaggio per la diretta',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeTile(BuildContext context, RssEpisode ep) {
    final parts = ep.pubDate.split(' ');
    String day = '0';
    String month = 'MMM';
    if (parts.length >= 3) {
      day = parts[1];
      month = parts[2].toUpperCase();
    }

    final epMap = {
      'program': widget.programData['title'],
      'title': ep.title,
      'image': widget.programData['image'],
      'duration': ep.duration,
      'date': ep.pubDate,
      'audioUrl': ep.audioUrl,
      'rssFeed': widget.programData['rssFeed'], // Passiamo il feed RSS
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => PodcastScreen(episodeData: epMap)),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Data
            SizedBox(
              width: 50,
              child: Column(
                children: [
                  Text(day,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary)),
                  Text(month,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary)),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Titolo e descrizione
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ep.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.secondaryColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ep.description.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Favorites
            ListenableBuilder(
              listenable: FavoritesService(),
              builder: (ctx, _) {
                final isFav = FavoritesService().isFavorite(ep.audioUrl);
                return GestureDetector(
                  onTap: () {
                    FavoritesService().toggleFavorite(epMap);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isFav ? 'Rimosso dai preferiti' : 'Aggiunto ai preferiti ❤️'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red : Colors.grey,
                    size: 22,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),

            // Play icon (still clickable but now the whole row is too)
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.play_arrow, color: Colors.white, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}
