import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../main.dart';
import '../core/app_theme.dart';
import '../core/audio_handler.dart';
import '../data/favorites_service.dart';

final ValueNotifier<bool> isPodcastScreenVisible = ValueNotifier(false);
final ValueNotifier<bool> isVideoPlayerVisible = ValueNotifier(false);
final ValueNotifier<String?> currentPodcastPageId = ValueNotifier(null);
final ValueNotifier<Color> globalMiniPlayerBackgroundColor = ValueNotifier(
  const Color(0xFF6A1E68),
);

class GlobalMiniPlayerBackgroundScope extends StatefulWidget {
  final Color color;
  final Widget child;

  const GlobalMiniPlayerBackgroundScope({
    super.key,
    required this.color,
    required this.child,
  });

  @override
  State<GlobalMiniPlayerBackgroundScope> createState() =>
      _GlobalMiniPlayerBackgroundScopeState();
}

class _GlobalMiniPlayerBackgroundScopeState
    extends State<GlobalMiniPlayerBackgroundScope> {
  late Color _previousColor;

  @override
  void initState() {
    super.initState();
    _previousColor = globalMiniPlayerBackgroundColor.value;
    globalMiniPlayerBackgroundColor.value = widget.color;
  }

  @override
  void didUpdateWidget(GlobalMiniPlayerBackgroundScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color) {
      globalMiniPlayerBackgroundColor.value = widget.color;
    }
  }

  @override
  void dispose() {
    globalMiniPlayerBackgroundColor.value = _previousColor;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class GlobalMiniPlayerVisibilityBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, bool isVisible) builder;

  const GlobalMiniPlayerVisibilityBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: audioHandler?.mediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;
        final isLive = mediaItem?.id == CustomAudioHandler.liveItemKey;
        final hasActiveItem = mediaItem != null && !isLive;

        return ValueListenableBuilder<bool>(
          valueListenable: isPodcastScreenVisible,
          builder: (context, isPodcastVisible, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: isVideoPlayerVisible,
              builder: (context, isVideoVisible, _) {
                return ValueListenableBuilder<String?>(
                  valueListenable: currentPodcastPageId,
                  builder: (context, pageId, _) {
                    final shouldHide =
                        isVideoVisible ||
                        (isPodcastVisible && pageId == mediaItem?.id);
                    return builder(context, hasActiveItem && !shouldHide);
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class GlobalMiniPlayer extends StatelessWidget {
  final void Function(MediaItem) onTap;

  const GlobalMiniPlayer({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isPodcastScreenVisible,
      builder: (context, isPodcastVisible, child) {
        final handler = audioHandler;

        if (handler == null) return const SizedBox.shrink();

        return StreamBuilder<MediaItem?>(
          stream: handler.mediaItem,
          builder: (context, snapshot) {
            final mediaItem = snapshot.data;

            if (mediaItem == null ||
                mediaItem.id == CustomAudioHandler.liveItemKey) {
              return const SizedBox.shrink();
            }

            return ValueListenableBuilder<bool>(
              valueListenable: isVideoPlayerVisible,
              builder: (context, isVideoVisible, _) {
                if (isVideoVisible) return const SizedBox.shrink();

                return ValueListenableBuilder<String?>(
                  valueListenable: currentPodcastPageId,
                  builder: (context, pageId, _) {
                    if (isPodcastVisible && pageId == mediaItem.id) {
                      return const SizedBox.shrink();
                    }

                    return ValueListenableBuilder<Color>(
                      valueListenable: globalMiniPlayerBackgroundColor,
                      builder: (context, backgroundColor, _) {
                        return Container(
                          color: backgroundColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => onTap(mediaItem),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'In riproduzione',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          Text(
                                            mediaItem.title,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ListenableBuilder(
                                      listenable: FavoritesService(),
                                      builder: (context, _) {
                                        final isFav = FavoritesService()
                                            .isFavorite(mediaItem.id);
                                        return IconButton(
                                          icon: Icon(
                                            isFav
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: isFav
                                                ? Colors.red
                                                : Colors.white,
                                            size: 20,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            final epMap = {
                                              'id': mediaItem.id,
                                              'audioUrl': mediaItem.id,
                                              'title': mediaItem.title,
                                              'program':
                                                  mediaItem.album ??
                                                  'Lady Radio',
                                              'image':
                                                  mediaItem.extras?['image'] ??
                                                  '',
                                            };
                                            FavoritesService().toggleFavorite(
                                              epMap,
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(
                                      Icons.open_in_new,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
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
    );
  }
}
