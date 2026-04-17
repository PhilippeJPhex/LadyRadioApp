import 'package:url_launcher/url_launcher.dart';
import '../core/app_constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:share_plus/share_plus.dart';
import '../core/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/global_mini_player.dart';
import '../main.dart';
import '../core/audio_handler.dart';
import '../data/favorites_service.dart';

class PodcastScreen extends StatefulWidget {
  final Map<String, dynamic> episodeData;
  final List<Map<String, dynamic>>? playlist; // Aggiunta playlist per navigazione

  const PodcastScreen({super.key, required this.episodeData, this.playlist});

  @override
  State<PodcastScreen> createState() => _PodcastScreenState();
}

class _PodcastScreenState extends State<PodcastScreen> {
  late Map<String, dynamic> _currentEpisode; // Per gestire il cambio episodio
  bool _isPlaying = false;
  bool _isLoading = true;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  StreamSubscription? _stateSub;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;

  StreamSubscription? _itemSub;
  List<MediaItem> _currentQueue = [];
  StreamSubscription? _queueSub;

  @override
  void initState() {
    super.initState();
    _currentEpisode = widget.episodeData;
    _initAudio();
  }

  void _updatePageRefs() {
    currentPodcastPageId.value = _currentEpisode['audioUrl'];
    isPodcastScreenVisible.value = true;
  }

  bool _playerPlayingAnywhere() {
    if (audioHandler == null) return false;
    final state = audioHandler!.playbackState.value;
    return state.processingState != AudioProcessingState.idle;
  }

  Future<void> _initAudio() async {
    _updatePageRefs();
    if (audioHandler == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final AudioHandler h = audioHandler!;
    final customHandler = h as CustomAudioHandler;

    // Pulizia sottoscrizioni precedenti
    await _stateSub?.cancel();
    await _posSub?.cancel();
    await _durSub?.cancel();
    await _itemSub?.cancel();
    await _queueSub?.cancel();
    
    try {
      final audioUrl = _currentEpisode['audioUrl'] as String?;
      
      _stateSub = h.playbackState.listen((state) {
        if (mounted) {
          final currentId = h.mediaItem.value?.id;
          setState(() {
            _isPlaying = state.playing && currentId == audioUrl;
            _isLoading = state.processingState == AudioProcessingState.loading || 
                         state.processingState == AudioProcessingState.buffering;
          });
        }
      });

      // Sincronizzazione UI con il cambio traccia nel service
      _itemSub = h.mediaItem.listen((item) {
        if (item != null && mounted) {
          setState(() {
            _currentEpisode = {
              'audioUrl': item.id,
              'title': item.title,
              'program': item.album,
              'image': item.extras?['image'],
              'rssFeed': item.extras?['rssFeed'],
            };
          });
          _updatePageRefs();
        }
      });

      // Monitoraggio della coda per abilitare i tasti
      _queueSub = h.queue.listen((q) {
        if (mounted) setState(() => _currentQueue = q);
      });

      _posSub = customHandler.positionStream.listen((pos) {
        if (mounted) setState(() => _position = pos);
      });

      _durSub = customHandler.durationStream.listen((dur) {
        if (mounted && dur != null) setState(() => _duration = dur);
      });

      if (audioUrl != null && audioUrl.isNotEmpty) {
        if (customHandler.mediaItem.value?.id == audioUrl && _playerPlayingAnywhere()) {
          if (mounted) setState(() => _isLoading = false);
        } else {
          final item = MediaItem(
            id: audioUrl,
            title: _currentEpisode['title'] ?? 'Podcast',
            album: _currentEpisode['program'] ?? 'Lady Radio',
            playable: true,
            displayTitle: _currentEpisode['title'],
            displaySubtitle: _currentEpisode['program'],
            extras: {
              'image': _currentEpisode['image'],
              'rssFeed': _currentEpisode['rssFeed'],
              'playlist': widget.playlist,
            },
          );
          await h.playMediaItem(item);
        }
      }
    } catch (e) {
      debugPrint("Error loading podcast audio: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToEpisode(int direction) {
    if (audioHandler == null) return;
    if (direction > 0) {
      audioHandler!.skipToNext();
    } else {
      audioHandler!.skipToPrevious();
    }
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _itemSub?.cancel();
    _queueSub?.cancel();
    
    // Riaffacciamo il miniplayer quando usciamo
    // Usiamo microtask per essere sicuri che avvenga DOPO la distruzione del widget
    Future.microtask(() {
      isPodcastScreenVisible.value = false;
      currentPodcastPageId.value = null;
    });

    super.dispose();
  }

  void _togglePlayPause() {
    if (audioHandler == null) return;
    final AudioHandler h = audioHandler!;
    
    if (_isPlaying) {
      h.pause();
    } else {
      h.play();
    }
  }

  void _seekTo(double value) {
    if (audioHandler == null) return;
    final AudioHandler h = audioHandler!;

    if (_duration.inMilliseconds > 0 && !_isLoading) {
      final position = Duration(milliseconds: (value * _duration.inMilliseconds).round());
      h.seek(position);
    }
  }
  
  void _skip(int seconds) {
    if (audioHandler == null) return;
    final AudioHandler h = audioHandler!;

    final newPos = _position + Duration(seconds: seconds);
    h.seek(newPos < Duration.zero ? Duration.zero : (newPos > _duration ? _duration : newPos));
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${d.inHours > 0 ? '${d.inHours}:' : ''}$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double coverSize = size.height * 0.22; // Rimpicciolita dinamicamente

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lady Radio Podcast'),
        centerTitle: true,
        toolbarHeight: 50,
      ),
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 100), // Padding generoso per centrare e staccarsi dal bottom
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlassContainer(
                width: size.width * 0.9,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cover rimpicciolita
                    Container(
                      height: coverSize,
                      width: coverSize,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryColor, width: 3),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _currentEpisode['image'].toString().startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: _currentEpisode['image'],
                                fit: BoxFit.contain,
                                placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor)),
                                errorWidget: (context, url, error) => Image.asset('assets/lady512.png'),
                              )
                            : Image.asset(
                                _currentEpisode['image'],
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Image.asset('assets/lady512.png'),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Row icone (Share + Fav + WhatsApp)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.share, size: 24), 
                          onPressed: () {
                            SharePlus.instance.share(ShareParams(
                                text: 'Ascolta ${_currentEpisode["title"]} su Lady Radio!\n${_currentEpisode["audioUrl"]}'));
                          }
                        ),
                        const SizedBox(width: 15),
                        IconButton(
                          icon: const Icon(Icons.chat, size: 24, color: AppTheme.successColor),
                          onPressed: () async {
                            final title = _currentEpisode['title'] ?? '';
                            final cleanTitle = title.split('|')[0].trim();
                            final message = '[$cleanTitle]: ';
                            
                            final url = AppConstants.whatsappUri(text: message);
                            final webUrl = AppConstants.whatsappWebUri(text: message);
                            
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            } else {
                              await launchUrl(webUrl);
                            }
                          },
                        ),
                        const SizedBox(width: 15),
                        ListenableBuilder(
                          listenable: FavoritesService(),
                          builder: (context, _) {
                            final isFav = FavoritesService().isFavorite(_currentEpisode['audioUrl'] ?? '');
                            return IconButton(
                              icon: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                size: 24,
                                color: isFav ? Colors.red : null,
                              ),
                              onPressed: () {
                                FavoritesService().toggleFavorite(_currentEpisode);
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _currentEpisode['program'] ?? '',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentEpisode['title'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppTheme.primaryColor,
                        inactiveTrackColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                        thumbColor: AppTheme.primaryColor,
                        trackHeight: 4.0,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                      ),
                      child: Slider(
                        value: _duration.inMilliseconds > 0 
                           ? _position.inMilliseconds.clamp(0, _duration.inMilliseconds) / _duration.inMilliseconds 
                           : 0.0,
                        onChanged: _seekTo,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(_position), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          Text(_formatDuration(_duration), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // AUDIO CONTROLS SU UNA RIGA SOLA
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.replay_10, size: 32), 
                          onPressed: () => _skip(-10),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            width: 70, height: 70,
                            decoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                            child: _isLoading 
                               ? const Padding(
                                   padding: EdgeInsets.all(20.0),
                                   child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                 )
                               : Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 40),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.forward_10, size: 32), 
                          onPressed: () => _skip(10),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('www.ladyradio.it', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
