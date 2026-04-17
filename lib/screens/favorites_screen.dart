import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../data/favorites_service.dart';
import 'podcast_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'I MIEI PREFERITI',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: FavoritesService(),
        builder: (context, _) {
          final favs = FavoritesService().favorites;

          if (favs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    const Text(
                      'Nessun preferito',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tocca il ❤️ su una puntata per salvarla qui.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: favs.length,
            itemBuilder: (context, index) {
              final ep = favs[index];
              return Dismissible(
                key: Key(ep['audioUrl'] ?? index.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red[400],
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  FavoritesService().removeFavorite(ep['audioUrl'] ?? '');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${ep['title']} rimosso dai preferiti'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildImage(ep['image'], 56),
                  ),
                  title: Text(
                    ep['title'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    ep['program'] ?? ep['date'] ?? '',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.play_circle_fill, color: AppTheme.primaryColor, size: 32),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PodcastScreen(episodeData: ep)),
                      );
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PodcastScreen(episodeData: ep)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildImage(String? imageUrl, double size) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: size, height: size,
        color: Colors.grey[200],
        child: const Icon(Icons.music_note, color: AppTheme.primaryColor),
      );
    }
    if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          color: Colors.grey[200],
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: size, height: size, color: Colors.grey[200],
          child: const Icon(Icons.music_note, color: AppTheme.primaryColor),
        ),
      );
    }
    return Image.asset(imageUrl, width: size, height: size, fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        width: size, height: size, color: Colors.grey[200],
        child: const Icon(Icons.music_note, color: AppTheme.primaryColor),
      ),
    );
  }
}
