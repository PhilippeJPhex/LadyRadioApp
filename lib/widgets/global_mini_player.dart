import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../main.dart';
import '../core/app_theme.dart';
import '../core/audio_handler.dart';
import '../data/favorites_service.dart';

final ValueNotifier<bool> isPodcastScreenVisible = ValueNotifier(false);
final ValueNotifier<String?> currentPodcastPageId = ValueNotifier(null);

class GlobalMiniPlayer extends StatelessWidget {
  final void Function(MediaItem) onTap;

  const GlobalMiniPlayer({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isPodcastScreenVisible,
      builder: (context, isVisible, child) {
        final handler = audioHandler;
        
        if (handler == null) return const SizedBox.shrink();

        return StreamBuilder<MediaItem?>(
          stream: handler.mediaItem,
          builder: (context, snapshot) {
            final mediaItem = snapshot.data;
            
            if (mediaItem == null || mediaItem.id == CustomAudioHandler.liveItemKey) {
              return const SizedBox.shrink();
            }

            return ValueListenableBuilder<String?>(
              valueListenable: currentPodcastPageId,
              builder: (context, pageId, _) {
                if (isVisible && pageId == mediaItem.id) {
                  return const SizedBox.shrink();
                }

                return Container(
                  color: Theme.of(context).scaffoldBackgroundColor, // Forza lo sfondo uguale alla pagina
                  padding: EdgeInsets.fromLTRB(16, 4, 16, isVisible ? 12 : 4), 
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onTap(mediaItem),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                final isFav = FavoritesService().isFavorite(mediaItem.id);
                                return IconButton(
                                  icon: Icon(
                                    isFav ? Icons.favorite : Icons.favorite_border,
                                    color: isFav ? Colors.red : Colors.white,
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    final epMap = {
                                      'id': mediaItem.id,
                                      'audioUrl': mediaItem.id,
                                      'title': mediaItem.title,
                                      'program': mediaItem.album ?? 'Lady Radio',
                                      'image': mediaItem.extras?['image'] ?? '',
                                    };
                                    FavoritesService().toggleFavorite(epMap);
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
  }
}
