import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audio_service/audio_service.dart';
import '../core/app_theme.dart';
import '../core/app_constants.dart';
import '../core/audio_handler.dart';
import '../viewmodels/live_viewmodel.dart';
import '../widgets/animated_play_button.dart';
import '../screens/video_player_screen.dart';
import '../widgets/glass_container.dart';
import '../widgets/global_mini_player.dart';
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
      body: GlobalMiniPlayerVisibilityBuilder(
        builder: (context, isMiniPlayerVisible) {
          return SafeArea(
            top: !isMiniPlayerVisible,
            child: Padding(
              padding: EdgeInsets.only(top: isMiniPlayerVisible ? 10 : 0),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StreamBuilder<MediaItem?>(
                        stream: audioHandler?.mediaItem,
                        builder: (context, snapshot) {
                          final mediaItem = snapshot.data;
                          final bool isLive =
                              mediaItem?.id == CustomAudioHandler.liveItemKey;
                          final bool hasActiveItem =
                              mediaItem != null && !isLive;

                          return ValueListenableBuilder<bool>(
                            valueListenable: isPodcastScreenVisible,
                            builder: (context, isVisible, _) {
                              return ValueListenableBuilder<String?>(
                                valueListenable: currentPodcastPageId,
                                builder: (context, pageId, _) {
                                  final bool shouldHide =
                                      isVisible && pageId == mediaItem?.id;
                                  final bool miniPlayerVisible =
                                      hasActiveItem && !shouldHide;

                                  return ListenableBuilder(
                                    listenable: _viewModel,
                                    builder: (context, _) {
                                      return GlassContainer(
                                        width:
                                            MediaQuery.of(context).size.width *
                                            1,
                                        height:
                                            MediaQuery.of(context).size.height *
                                            1,
                                        padding: EdgeInsets.fromLTRB(
                                          24,
                                          miniPlayerVisible ? 20 : 100,
                                          24,
                                          12,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Album Art
                                            Container(
                                              margin: const EdgeInsets.only(
                                                top: 15,
                                              ),
                                              height: 200,
                                              width: 200,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                                color: Colors.white,
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                child: Image.asset(
                                                  'assets/lady512.png',
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 24),

                                            // Actions (Share, TV, WhatsApp)
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.share,
                                                    size: 28,
                                                  ),
                                                  color: AppTheme.primaryColor,
                                                  onPressed: () {
                                                    SharePlus.instance.share(
                                                      ShareParams(
                                                        text:
                                                            'Ascolta Lady Radio in diretta!\nhttps://ladyradio.it',
                                                      ),
                                                    );
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.tv,
                                                    size: 32,
                                                  ),
                                                  color: AppTheme.primaryColor,
                                                  onPressed: () {
                                                    audioHandler?.pause();
                                                    const String tvUrl =
                                                        'https://stream12.xdevel.com/video0s978435-2636/stream/playlist.m3u8';
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            const VideoPlayerScreen(
                                                              videoUrl: tvUrl,
                                                              title:
                                                                  'Lady Radio TV',
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.chat,
                                                    size: 28,
                                                    color:
                                                        AppTheme.successColor,
                                                  ),
                                                  onPressed: () async {
                                                    const text =
                                                        '[Lady Radio Live]: Sto ascoltando la diretta - https://ladyradio.it';
                                                    final url =
                                                        AppConstants.whatsappUri(
                                                          text: text,
                                                        );
                                                    final webUrl =
                                                        AppConstants.whatsappWebUri(
                                                          text: text,
                                                        );
                                                    if (await canLaunchUrl(
                                                      url,
                                                    )) {
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16.0,
                                                  ),
                                              child: Text(
                                                _viewModel.songTitle,
                                                textAlign: TextAlign.center,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      color:
                                                          AppTheme.primaryColor,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 32),

                                            // Pulsante Play
                                            AnimatedPlayButton(
                                              isPlaying: _viewModel.isPlaying,
                                              isLoading: _viewModel.isLoading,
                                              size: 80,
                                              onTap: () => _viewModel
                                                  .togglePlayPause(_isWindows),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 100),
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
}
