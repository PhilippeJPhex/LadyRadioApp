import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:audio_service/audio_service.dart';
import '../main.dart'; // import audioHandler
import '../core/audio_handler.dart';
import '../widgets/global_mini_player.dart';

class LiveViewModel extends ChangeNotifier {
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _isDisposed = false;
  String _songTitle = 'Lady Radio Live';

  StreamSubscription? _stateSub;
  StreamSubscription? _itemSub;

  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading && !_isPlaying; 
  String get songTitle => _songTitle;

  LiveViewModel() {
    _init();
  }

  Future<void> _init() async {
    if (audioHandler == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    
    final AudioHandler h = audioHandler!;

    try {
      _itemSub = h.mediaItem.listen((item) {
        if (_isDisposed) return;
        if (item != null && item.id == CustomAudioHandler.liveItemKey) {
          _songTitle = item.title;
        }
        _syncPlaybackState(h);
      });

      _stateSub = h.playbackState.listen((state) {
        if (_isDisposed) return;
        _syncPlaybackState(h, state);
      });

      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      if (_isDisposed) return;
      debugPrint('LiveViewModel init error: $e');
      _isLoading = false;
      _songTitle = 'Errore di connessione.';
      notifyListeners();
    }
  }

  void _syncPlaybackState(AudioHandler h, [PlaybackState? state]) {
    final playbackState = state ?? h.playbackState.value;
    final currentId = h.mediaItem.value?.id;
    _isPlaying = playbackState.playing && currentId == CustomAudioHandler.liveItemKey;
    _isLoading = currentId == CustomAudioHandler.liveItemKey &&
        (playbackState.processingState == AudioProcessingState.loading ||
            playbackState.processingState == AudioProcessingState.buffering);
    notifyListeners();
  }

  Future<void> togglePlayPause(bool isWindows) async {
    if (audioHandler == null) return;
    final AudioHandler h = audioHandler!;
    final isLiveCurrent = h.mediaItem.value?.id == CustomAudioHandler.liveItemKey;
    final isLivePlaying = isLiveCurrent && h.playbackState.value.playing;

    // Feedback immediato per l'icona
    _isPlaying = !isLivePlaying;
    _isLoading = _isPlaying;
    notifyListeners();

    try {
      if (!isLivePlaying) {
        if (isWindows) {
          debugPrint('Audio disabilitato su Windows — crash MediaFoundation prevenuto.');
          _isLoading = false;
          _isPlaying = false; // Reset su Windows
          _songTitle = 'Audio in pausa (Debug Windows)';
          notifyListeners();
          return;
        }

        isPodcastScreenVisible.value = false;
        currentPodcastPageId.value = null;

        // Se l'audio era già in pausa ma avevamo già la sorgente caricata, 
        // forse non serve ricaricare l'intera URL se non è passato troppo tempo.
        // Ma per il live streaming è meglio ricaricare per evitare delay infiniti del buffer.
        await h.playFromMediaId(CustomAudioHandler.liveItemKey);
        if (!_isDisposed) {
          _isPlaying = true;
          _isLoading = false;
          notifyListeners();
        }
      } else {
        await h.pause(); // Usa pause() invece di stop() per velocizzare la ripresa se possibile
        if (!_isDisposed) {
          _isPlaying = false;
          _isLoading = false;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('LiveViewModel play error: $e');
      _isLoading = false;
      _isPlaying = false;
      _songTitle = 'Errore di connessione.';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _itemSub?.cancel();
    _stateSub?.cancel();
    super.dispose();
  }
}
