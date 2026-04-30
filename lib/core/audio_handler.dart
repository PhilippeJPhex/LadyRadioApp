import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import '../data/rss_service.dart';
import '../data/schedule_service.dart';
import '../data/config_service.dart';
import '../data/favorites_service.dart';

class CustomAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  
  final RssService _rssService = RssService();
  final ConfigService _configService = ConfigService();
  final ScheduleService _scheduleService = ScheduleService();
  final FavoritesService _favoritesService = FavoritesService();

  static const String liveItemKey = 'live-stream';
  static const String liveFolderKey = 'live-folder';
  static const String podcastFolderKey = 'podcast-folder';
  static const String favoritesFolderKey = 'favorites-folder';

  final ladyLogoUri = Uri.parse('asset:///assets/lady512.png');
  final ladyRemoteLogo = 'https://www.ladyradio.it/wp-content/uploads/2026/04/lady512.png';

  final Map<String, MediaItem> _itemsCache = {};

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  CustomAudioHandler() {
    debugPrint("[AudioHandler] Costruttore avviato");
    _initStaticItems();
    _init();
    _cleanOldCache();
  }

  // --- LOGICA CACHE INTELLIGENTE ---
  
  Future<void> _cleanOldCache() async {


    try {
      final dir = await getTemporaryDirectory();
      final cacheDir = Directory(p.join(dir.path, 'just_audio_cache'));
      if (!await cacheDir.exists()) return;

      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      await for (var file in cacheDir.list()) {
        if (file is File) {
          final fileName = p.basename(file.path);
          final lastAccessStr = prefs.getString('cache_access_$fileName');
          if (lastAccessStr != null) {
            final lastAccess = DateTime.parse(lastAccessStr);
            if (now.difference(lastAccess).inDays >= 1) {
              await file.delete();
              await prefs.remove('cache_access_$fileName');
              debugPrint("[Cache] Eliminato file vecchio: $fileName");
            }
          } else {
            final stat = await file.stat();
            if (now.difference(stat.modified).inDays >= 1) {
              await file.delete();
            }
          }
        }
      }
    } catch (e) {
      debugPrint("[Cache] Errore pulizia: $e");
    }
  }

  Future<void> _markAsAccessed(String url) async {


    try {
      final prefs = await SharedPreferences.getInstance();
      final fileName = Uri.parse(url).pathSegments.last;
      await prefs.setString('cache_access_$fileName', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint("[Cache] Errore mark: $e");
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    debugPrint("[AudioHandler] Task rimosso (app chiusa dalle recenti). Fermo tutto.");
    await stop();
    await super.onTaskRemoved();
  }

  // ---------------------------------

  void _initStaticItems() {
    _itemsCache[liveItemKey] = MediaItem(
      id: liveItemKey,
      title: 'Lady Radio Live',
      album: 'Lady Radio',
      playable: true,
      artUri: ladyLogoUri,
      extras: {
        'android.media.metadata.DISPLAY_ICON_URI': 'asset:///assets/lady512.png',
        'android.media.metadata.ALBUM_ART_URI': ladyRemoteLogo,
      },
    );
  }

  Future<void> _init() async {
    _player.durationStream.listen((duration) {
      final item = mediaItem.value;
      if (item != null && duration != null && item.duration != duration) {
        mediaItem.add(item.copyWith(duration: duration));
      }
    });

    _player.sequenceStateStream.listen((state) {
      final currentSource = state.currentSource;
      if (currentSource != null && currentSource.tag is MediaItem) {
        final item = currentSource.tag as MediaItem;
        if (mediaItem.value?.id != item.id) {
          mediaItem.add(item);
        }
      }
    });

    _player.playbackEventStream.listen((event) {
      playbackState.add(_transformEvent(event));
    });
    
    _player.icyMetadataStream.listen((metadata) {
      final currentItem = mediaItem.value;
      if (currentItem != null && currentItem.id == liveItemKey) {
        mediaItem.add(currentItem.copyWith(
          title: metadata?.info?.title ?? 'Lady Radio Live',
          album: 'Lady Radio',
          artUri: ladyLogoUri,
        ));
      }
    });



    try {
      final config = await _configService.getConfig();
      if (config.streamUrl.isNotEmpty) {
        await _player.setAudioSource(AudioSource.uri(Uri.parse(config.streamUrl)), preload: false);
      }
    } catch (e) {
      debugPrint("[AudioHandler] Errore stream: $e");
    }
    
    await _favoritesService.init();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> playFromMediaId(String mediaId, [Map<String, dynamic>? extras]) async {
    debugPrint("[AudioHandler] playFromMediaId: $mediaId");
    
    final cachedItem = _itemsCache[mediaId];
    if (cachedItem != null && cachedItem.playable == true) {
      await playMediaItem(cachedItem);
      return;
    }

    if (mediaId == liveItemKey) {
      await playMediaItem(_itemsCache[liveItemKey]!);
    } 
    else if (mediaId.startsWith('http')) {
      final item = MediaItem(
        id: mediaId,
        album: extras?['album'] ?? 'Lady Radio',
        title: extras?['title'] ?? 'Episodio',
        artUri: ladyLogoUri,
      );
      await playMediaItem(item);
    }
  }

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> fastForward() => _player.seek(_player.position + const Duration(seconds: 10));

  @override
  Future<void> rewind() => _player.seek(_player.position - const Duration(seconds: 10));

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> playMediaItem(MediaItem item) async {
    // Se l'item non ha una playlist ma ha un feed RSS, lo recuperiamo ora
    if ((item.extras == null || item.extras!['playlist'] == null) && item.extras?['rssFeed'] != null) {
      try {
        final episodes = await _rssService.fetchPodcastEpisodes(item.extras!['rssFeed']);
        final List<AudioSource> sources = [];
        int initialIndex = 0;

        for (int i = 0; i < episodes.length; i++) {
          final ep = episodes[i];
          final uri = Uri.parse(ep.audioUrl);
          sources.add(LockCachingAudioSource(uri, tag: MediaItem(
            id: ep.audioUrl,
            album: item.album ?? 'Lady Radio',
            title: ep.title,
            artUri: item.artUri,
            extras: {
              'image': item.extras?['image'],
              'rssFeed': item.extras?['rssFeed'],
            },
          )));
          if (ep.audioUrl == item.id) initialIndex = i;
        }

        if (sources.isNotEmpty) {
          final playlist = ConcatenatingAudioSource(children: sources);
          mediaItem.add(item);
          await _player.setAudioSource(playlist, initialIndex: initialIndex);
          _player.play();
          return;
        }
      } catch (e) {
        debugPrint("[AudioHandler] Errore recupero feed automatico: $e");
      }
    }

    // Se l'item ha una playlist nei extras, carichiamo la playlist (fallback)
    if (item.extras != null && item.extras!['playlist'] != null) {
      final List<dynamic> playlistData = item.extras!['playlist'];
      final List<AudioSource> sources = [];
      int initialIndex = 0;

      for (int i = 0; i < playlistData.length; i++) {
        final ep = playlistData[i];
        final uri = Uri.parse(ep['audioUrl']);
        sources.add(LockCachingAudioSource(uri, tag: MediaItem(
          id: ep['audioUrl'],
          album: ep['program'] ?? 'Lady Radio',
          title: ep['title'] ?? 'Episodio',
          artUri: ladyLogoUri,
        )));
        if (ep['audioUrl'] == item.id) initialIndex = i;
      }

      final playlist = ConcatenatingAudioSource(children: sources);
      mediaItem.add(item);
      await _player.setAudioSource(playlist, initialIndex: initialIndex);
    } else {
      // Comportamento standard per item singolo
      mediaItem.add(item);
  

    try {
        if (item.id == liveItemKey) {
          final config = await _configService.getConfig();
          await _player.setAudioSource(AudioSource.uri(Uri.parse(config.streamUrl)));
        } else {
          final uri = Uri.parse(item.id);
          if (uri.scheme.startsWith('http')) {
            await _markAsAccessed(item.id);
            await _player.setAudioSource(LockCachingAudioSource(uri));
          } else {
            await _player.setAudioSource(AudioSource.uri(uri));
          }
        }
      } catch (e) {
        debugPrint("[AudioHandler] Errore play: $e");
      }
    }
    _player.play();
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    final currentItem = mediaItem.value;
    final isLive = currentItem != null && currentItem.id == liveItemKey;

    // Aggiorniamo il MediaItem corrente se il player è passato al prossimo nella playlist
    if (_player.currentIndex != null && !isLive) {
      final sequence = _player.sequence;
      if (_player.currentIndex! < sequence.length) {
        final currentSource = sequence[_player.currentIndex!];
        if (currentSource.tag is MediaItem) {
          final item = currentSource.tag as MediaItem;
          if (mediaItem.value?.id != item.id) {
            mediaItem.add(item);
          }
        }
      }
    }

    return PlaybackState(
      controls: [
        if (isLive)
          (_player.playing ? MediaControl.pause : MediaControl.play)
        else ...[
          MediaControl.rewind,
          MediaControl.skipToPrevious,
          if (_player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.fastForward,
        ],
      ],
      systemActions: {
        MediaAction.play,
        MediaAction.pause,
        MediaAction.stop,
        MediaAction.seek,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
        MediaAction.fastForward,
        MediaAction.rewind,
      },
      androidCompactActionIndices: isLive ? const [0] : const [1, 2, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    );
  }

  @override
  Future<List<MediaItem>> getChildren(String parentId, [Map<String, dynamic>? options]) async {
    debugPrint("[AudioHandler] getChildren: $parentId");

    if (parentId == AudioService.browsableRootId) {
      const String pkg = 'it.ladyradio.lady_app'; 
      final rootItems = [
        MediaItem(
          id: liveFolderKey, 
          title: 'Live', 
          playable: false,
          artUri: Uri.parse('android.resource://$pkg/drawable/wave'),
          extras: {
            'android.media.metadata.DISPLAY_ICON_URI': 'android.resource://$pkg/drawable/wave',
            'android.media.metadata.ALBUM_ART_URI': 'android.resource://$pkg/drawable/wave',
            'android.media.browse.CONTENT_STYLE_BROWSABLE_HINT': 1,
            'android.media.browse.CONTENT_STYLE_SUPPORTED': true,
          },
        ),
        MediaItem(
          id: podcastFolderKey, 
          title: 'Podcast', 
          playable: false,
          artUri: Uri.parse('android.resource://$pkg/drawable/mic'),
          extras: {
            'android.media.metadata.DISPLAY_ICON_URI': 'android.resource://$pkg/drawable/mic',
            'android.media.metadata.ALBUM_ART_URI': 'android.resource://$pkg/drawable/mic',
            'android.media.browse.CONTENT_STYLE_BROWSABLE_HINT': 1,
            'android.media.browse.CONTENT_STYLE_SUPPORTED': true,
          },
        ),
        MediaItem(
          id: favoritesFolderKey, 
          title: 'I miei preferiti', 
          playable: false,
          artUri: Uri.parse('android.resource://$pkg/drawable/heart'),
          extras: {
            'android.media.metadata.DISPLAY_ICON_URI': 'android.resource://$pkg/drawable/heart',
            'android.media.metadata.ALBUM_ART_URI': 'android.resource://$pkg/drawable/heart',
            'android.media.browse.CONTENT_STYLE_BROWSABLE_HINT': 1,
            'android.media.browse.CONTENT_STYLE_SUPPORTED': true,
          },
        ),
      ];
      for (var item in rootItems) {
        _itemsCache[item.id] = item;
      }
      return rootItems;
    }

    if (parentId == liveFolderKey) {
      final item = _itemsCache[liveItemKey]!.copyWith(title: 'Ascolta la diretta');
      _itemsCache[item.id] = item;
      return [item];
    }

    if (parentId == favoritesFolderKey) {
      return _favoritesService.favorites.map((f) {
        final artUriStr = f['image']?.toString();
        final artUri = (artUriStr != null && artUriStr.startsWith('http')) 
            ? Uri.parse(artUriStr) 
            : ladyLogoUri;
            
        final item = MediaItem(
          id: f['audioUrl'] ?? '',
          title: f['title'] ?? 'Senza Titolo',
          album: 'I miei preferiti',
          playable: true,
          artUri: artUri,
          extras: {
            'android.media.metadata.DISPLAY_ICON_URI': artUri.toString(),
            'android.media.metadata.ALBUM_ART_URI': artUri.toString(),
          },
        );
        _itemsCache[item.id] = item;
        return item;
      }).toList();
    }
    
    if (parentId == podcastFolderKey) {
  

    try {
        final programs = await _scheduleService.fetchUniquePrograms();
        return programs.where((p) => (p['rssFeed'] as String? ?? '').isNotEmpty).map((prog) {
          final artUriStr = prog['image']?.toString();
          final artUri = (artUriStr != null && artUriStr.startsWith('http')) 
              ? Uri.parse(artUriStr) 
              : ladyLogoUri;

          final item = MediaItem(
            id: "PROG_${prog['postId']}",
            title: prog['title'] ?? '',
            playable: false,
            artUri: artUri,
            extras: {
              'android.media.metadata.DISPLAY_ICON_URI': artUri.toString(),
              'android.media.metadata.ALBUM_ART_URI': artUri.toString(),
            },
          );
          _itemsCache[item.id] = item;
          return item;
        }).toList();
      } catch (e) { return []; }
    }

    if (parentId.startsWith("PROG_")) {
      final postId = parentId.replaceFirst("PROG_", "");


    try {
        final programs = await _scheduleService.fetchUniquePrograms();
        final program = programs.firstWhere((p) => p['postId']?.toString() == postId, orElse: () => {});
        if (program.isNotEmpty) {
          final episodes = await _rssService.fetchPodcastEpisodes(program['rssFeed']);
          final artUriStr = program['image']?.toString();
          final artUri = (artUriStr != null && artUriStr.startsWith('http')) 
              ? Uri.parse(artUriStr) 
              : ladyLogoUri;

          return episodes.map((ep) {
            final item = MediaItem(
              id: ep.audioUrl,
              title: ep.title,
              album: program['title'] ?? 'Podcast',
              playable: true,
              artUri: artUri,
              extras: {
                'android.media.metadata.DISPLAY_ICON_URI': artUri.toString(),
                'android.media.metadata.ALBUM_ART_URI': artUri.toString(),
              },
            );
            _itemsCache[item.id] = item;
            return item;
          }).toList();
        }
      } catch (e) { return []; }
    }
    
    return [];
  }
}
