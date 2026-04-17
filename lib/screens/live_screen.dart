import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_theme.dart';
import '../core/app_constants.dart';
import '../viewmodels/live_viewmodel.dart';
import '../widgets/animated_play_button.dart';
import '../screens/video_player_screen.dart';
import '../widgets/glass_container.dart';
import '../data/config_service.dart';
import '../main.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  late final LiveViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = LiveViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  bool get _isWindows =>
      !kIsWeb && Theme.of(context).platform == TargetPlatform.windows;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 100), // Spazio per il MiniPlayer in alto
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) {
                  return GlassContainer(
                    width: MediaQuery.of(context).size.width * 0.92,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Album Art
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          height: 200,
                          width: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/lady512.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Actions (Share, TV, WhatsApp)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.share, size: 28),
                              color: AppTheme.primaryColor,
                              onPressed: () {
                                SharePlus.instance.share(ShareParams(
                                    text: 'Ascolta Lady Radio in diretta!\nhttps://ladyradio.it'));
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.tv, size: 32),
                              color: AppTheme.primaryColor,
                              onPressed: () {
                                audioHandler?.pause();
                                const String tvPlayerUrl = 'https://play.xdevel.com/13794';
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const VideoPlayerScreen(
                                      videoUrl: tvPlayerUrl,
                                      title: 'Lady Radio TV',
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.chat,
                                  size: 28, color: AppTheme.successColor),
                              onPressed: () async {
                                const text =
                                    '[Lady Radio Live]: Sto ascoltando la diretta - https://ladyradio.it';
                                final url = AppConstants.whatsappUri(text: text);
                                final webUrl =
                                    AppConstants.whatsappWebUri(text: text);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                } else {
                                  await launchUrl(webUrl);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Titolo canzone
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            _viewModel.songTitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          AppConstants.liveSubtitle,
                          style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                        const SizedBox(height: 32),

                        // Pulsante Play
                        AnimatedPlayButton(
                          isPlaying: _viewModel.isPlaying,
                          isLoading: _viewModel.isLoading,
                          size: 80,
                          onTap: () =>
                              _viewModel.togglePlayPause(_isWindows),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 120), // Padding extra per non finire sotto la bottom nav
            ],
          ),
        ),
      ),
    );
  }
}
