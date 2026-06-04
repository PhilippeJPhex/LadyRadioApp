import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_theme.dart';
import '../core/app_constants.dart';
import '../data/favorites_service.dart';
import '../models/rss_episode.dart';
import '../utils/date_text_formatter.dart';
import '../viewmodels/program_viewmodel.dart';
import '../widgets/global_mini_player.dart';
import '../widgets/whatsapp_icon.dart';
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
    await _openWhatsApp(text);
  }

  Future<void> _launchProgramWhatsApp() async {
    final programName = widget.programData['title']?.toString().trim();
    final text =
        '[${programName?.isNotEmpty == true ? programName : 'Lady Radio'}]: ';
    await _openWhatsApp(text);
  }

  Future<void> _openWhatsApp(String text) async {
    final url = AppConstants.whatsappUri(text: text);
    final webUrl = AppConstants.whatsappWebUri(text: text);
    if (!await launchUrl(url)) {
      await launchUrl(webUrl);
    }
  }

  Map<String, dynamic> _episodeDataMap(RssEpisode episode) {
    return {
      'program': widget.programData['title'],
      'title': episode.title,
      'image': widget.programData['image'],
      'duration': episode.duration,
      'date': episode.pubDate,
      'audioUrl': episode.audioUrl,
      'rssFeed': widget.programData['rssFeed'],
      'isPodcast': widget.programData['isPodcast'] ?? false,
      'urlVideo': episode.videoUrl,
    };
  }

  void _openEpisode(RssEpisode episode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PodcastScreen(episodeData: _episodeDataMap(episode)),
      ),
    );
  }

  void _playLatestEpisode() {
    if (_viewModel.isLoading) return;

    if (_viewModel.episodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessuna puntata disponibile per questo programma.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _openEpisode(_viewModel.episodes.first);
  }

  Future<void> _shareProgram() async {
    final programName = widget.programData['title']?.toString().trim();
    final programTitle = programName?.isNotEmpty == true
        ? programName!
        : 'Lady Radio';
    final rssFeed = widget.programData['rssFeed']?.toString().trim() ?? '';
    final shareText = rssFeed.isNotEmpty
        ? 'Ascolta $programTitle su Lady Radio!\n$rssFeed'
        : 'Ascolta $programTitle su Lady Radio!';

    await SharePlus.instance.share(ShareParams(text: shareText));
  }

  Future<void> _handleProgramMenuSelection(String value) async {
    switch (value) {
      case 'share':
        await _shareProgram();
        break;
      case 'write':
        await _launchProgramWhatsApp();
        break;
    }
  }

  bool _isPodcastProgram(Map<String, dynamic> program) {
    final value = program['isPodcast'] ?? program['is_podcast'];
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

  @override
  Widget build(BuildContext context) {
    final program = widget.programData;
    final isPodcastProgram = _isPodcastProgram(program);
    // Descrizione dal programData (non hardcoded), fallback generico
    final description = (program['description'] as String?)?.isNotEmpty == true
        ? program['description'] as String
        : 'Ascolta le ultime notizie e aggiornamenti su Lady Radio.';
    final schedule = (program['schedule'] as String?)?.isNotEmpty == true
        ? program['schedule'] as String
        : 'In onda su Lady Radio';

    return GlobalMiniPlayerBackgroundScope(
      color: const Color(0xFF6A1E68),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
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
            GlobalMiniPlayerVisibilityBuilder(
              builder: (context, isMiniPlayerVisible) {
                return SafeArea(
                  top: !isMiniPlayerVisible,
                  child: Padding(
                    padding: EdgeInsets.only(top: isMiniPlayerVisible ? 10 : 0),
                    child: CustomScrollView(
                      slivers: [
                        if (!isMiniPlayerVisible)
                          SliverAppBar(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            pinned: true,
                            leading: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            title: const Text(
                              '',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            centerTitle: true,
                          ),
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              SizedBox(height: isMiniPlayerVisible ? 0 : 20),
                              Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                  image: DecorationImage(
                                    image:
                                        program['image'].toString().startsWith(
                                          'http',
                                        )
                                        ? CachedNetworkImageProvider(
                                            program['image'],
                                          )
                                        : AssetImage(program['image'])
                                              as ImageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                program['title'],
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secondaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                ),
                                child: Text(
                                  description,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (!isPodcastProgram) ...[
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
                              ] else
                                const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ListenableBuilder(
                                    listenable: _viewModel,
                                    builder: (context, _) {
                                      return ElevatedButton.icon(
                                        onPressed: _viewModel.isLoading
                                            ? null
                                            : _playLatestEpisode,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppTheme.primaryColor,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: AppTheme
                                              .primaryColor
                                              .withValues(alpha: 0.45),
                                          disabledForegroundColor: Colors.white
                                              .withValues(alpha: 0.85),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        icon: const Icon(
                                          Icons.play_circle_fill,
                                        ),
                                        label: Text(
                                          _viewModel.isLoading
                                              ? 'Caricamento'
                                              : 'Riproduci',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    icon: const Icon(Icons.favorite_border),
                                    color: AppTheme.secondaryColor,
                                    onPressed: () {},
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_horiz),
                                    color: Colors.white,
                                    surfaceTintColor: Colors.white,
                                    iconColor: AppTheme.secondaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    onSelected: _handleProgramMenuSelection,
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(
                                        value: 'share',
                                        child: Row(
                                          children: [
                                            Icon(Icons.share, size: 20),
                                            SizedBox(width: 10),
                                            Text('Condividi'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'write',
                                        child: Row(
                                          children: [
                                            WhatsAppIcon(size: 20),
                                            SizedBox(width: 10),
                                            Text('Scrivici'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 40),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                ),
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
                                              color: AppTheme.primaryColor,
                                            ),
                                          );
                                        }
                                        if (_viewModel.errorMessage != null) {
                                          return Text(
                                            _viewModel.errorMessage!,
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          );
                                        }
                                        if (_viewModel.episodes.isEmpty) {
                                          return const Text(
                                            'Nessuna puntata disponibile.',
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                          );
                                        }
                                        return Column(
                                          children: _viewModel.episodes
                                              .map(
                                                (ep) => _buildEpisodeTile(
                                                  context,
                                                  ep,
                                                ),
                                              )
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
                );
              },
            ),
            GlobalMiniPlayerVisibilityBuilder(
              builder: (context, isMiniPlayerVisible) {
                if (!isMiniPlayerVisible) return const SizedBox.shrink();

                return Positioned(
                  top: 10,
                  left: 4,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                );
              },
            ),
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
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  icon: const WhatsAppIcon(size: 24),
                  label: const Text(
                    'Invia un messaggio per la diretta',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodeTile(BuildContext context, RssEpisode ep) {
    final day = DateTextFormatter.dayFromRss(ep.pubDate);
    final month = DateTextFormatter.monthShortUpperFromRss(ep.pubDate);

    final epMap = _episodeDataMap(ep);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _openEpisode(ep);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Data
            SizedBox(
              width: 50,
              child: Column(
                children: [
                  Text(
                    day.isNotEmpty ? day : '--',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    month.isNotEmpty ? month : '',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
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
                      color: AppTheme.secondaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ep.description.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
                    style: const TextStyle(fontSize: 12, color: Colors.black),
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
                        content: Text(
                          isFav
                              ? 'Rimosso dai preferiti'
                              : 'Aggiunto ai preferiti ❤️',
                        ),
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
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
