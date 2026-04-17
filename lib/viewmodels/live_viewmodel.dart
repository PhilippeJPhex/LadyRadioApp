import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:audio_service/audio_service.dart';
import '../main.dart'; // import audioHandler
import '../core/audio_handler.dart';

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
          notifyListeners();
        }
      });

      _stateSub = h.playbackState.listen((state) {
        if (_isDisposed) return;
        
        // Verifica se l'ID corrente è effettivamente la diretta
        final currentId = h.mediaItem.value?.id;
        _isPlaying = state.playing && currentId == CustomAudioHandler.liveItemKey;

        _isLoading = state.processingState == AudioProcessingState.loading ||
            state.processingState == AudioProcessingState.buffering;
        notifyListeners();
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

  Future<void> togglePlayPause(bool isWindows) async {
    if (audioHandler == null) return;
    final AudioHandler h = audioHandler!;

    // Feedback immediato per l'icona
    _isPlaying = !_isPlaying;
    if (_isPlaying) {
      _isLoading = true;
    } else {
      _isLoading = false;
    }
    notifyListeners();

    try {
      if (_isPlaying) {
        if (isWindows) {
          debugPrint('Audio disabilitato su Windows — crash MediaFoundation prevenuto.');
          _isLoading = false;
          _isPlaying = false; // Reset su Windows
          _songTitle = 'Audio in pausa (Debug Windows)';
          notifyListeners();
          return;
        }

        // Se l'audio era già in pausa ma avevamo già la sorgente caricata, 
        // forse non serve ricaricare l'intera URL se non è passato troppo tempo.
        // Ma per il live streaming è meglio ricaricare per evitare delay infiniti del buffer.
        await h.playFromMediaId(CustomAudioHandler.liveItemKey);
      } else {
        await h.pause(); // Usa pause() invece di stop() per velocizzare la ripresa se possibile
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
