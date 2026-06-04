import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../widgets/whatsapp_icon.dart';
import '../main.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  static const MethodChannel _nativeVideoPlayerChannel = MethodChannel(
    'it.ladyradio/native_video_player',
  );

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

  Future<void> _openTvPlayer() async {
    audioHandler?.pause();
    const String tvUrl =
        'https://stream12.xdevel.com/video0s978435-2636/stream/playlist.m3u8';

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android)) {
      try {
        await _nativeVideoPlayerChannel.invokeMethod<bool>('open', {
          'url': tvUrl,
          'title': 'Lady Radio Live',
        });
        return;
      } catch (error) {
        debugPrint('Errore player TV nativo iOS: $error');
      }
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const VideoPlayerScreen(videoUrl: tvUrl, title: 'Lady Radio TV'),
      ),
    );
  }

  String get _storeShareText {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return "Sto ascoltando Lady Radio, scarica anche te l'app: https://play.google.com/store/apps/details?id=com.toscanapost.ladyr&hl=it";
    }
    return "Sto ascoltando Lady Radio, scarica anche te l'app: https://apps.apple.com/it/app/lady-radio/id605378939";
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return StreamBuilder<MediaItem?>(
                    stream: audioHandler?.mediaItem,
                    builder: (context, snapshot) {
                      final mediaItem = snapshot.data;
                      final bool isLive =
                          mediaItem?.id == CustomAudioHandler.liveItemKey;
                      final bool hasActiveItem = mediaItem != null && !isLive;

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
                                    width: double.infinity,
                                    height: constraints.maxHeight,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: miniPlayerVisible ? 24 : 36,
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Album Art
                                          Container(
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
                                                      text: _storeShareText,
                                                    ),
                                                  );
                                                },
                                              ),
                                              ElevatedButton(
                                                onPressed: _openTvPlayer,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppTheme.primaryColor,
                                                  foregroundColor: Colors.white,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 22,
                                                        vertical: 12,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          30,
                                                        ),
                                                  ),
                                                  elevation: 0,
                                                ),
                                                child: const Text(
                                                  'TV',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const WhatsAppIcon(
                                                  size: 28,
                                                ),
                                                onPressed: () async {
                                                  const text =
                                                      '[Diretta Lady Radio]:';
                                                  final url =
                                                      AppConstants.whatsappUri(
                                                        text: text,
                                                      );
                                                  final webUrl =
                                                      AppConstants.whatsappWebUri(
                                                        text: text,
                                                      );
                                                  if (await canLaunchUrl(url)) {
                                                    await launchUrl(
                                                      url,
                                                      mode: LaunchMode
                                                          .externalApplication,
                                                    );
                                                  } else {
                                                    await launchUrl(
                                                      webUrl,
                                                      mode: LaunchMode
                                                          .externalApplication,
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),

                                          // Titolo canzone
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
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
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
