import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:audio_session/audio_session.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:just_audio/just_audio.dart';

enum VoiceStatus { idle, recording, reviewing, sending, sent, cancelled, error }

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final FlutterTts _tts = FlutterTts();
  final AudioRecorder _recorder = AudioRecorder();
  final SpeechToText _speech = SpeechToText();
  final AudioPlayer _internalPlayer = AudioPlayer();
  
  final ValueNotifier<VoiceStatus> status = ValueNotifier(VoiceStatus.idle);
  final ValueNotifier<String> statusMessage = ValueNotifier("");
  final ValueNotifier<int> recordingSeconds = ValueNotifier(0);

  bool _isBusy = false;
  String? _lastFilePath;
  final String _targetNumber = "393925727775"; // Numero Lady Radio

  Future<void> init() async {
    await _tts.setLanguage("it-IT");
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.awaitSpeakCompletion(true);
    await _speech.initialize();
  }

  Future<bool> startVoiceMessageProcess() async {
    if (_isBusy) return false;
    _isBusy = true;

    final session = await AudioSession.instance;
    
    try {
      if (await session.setActive(true)) {
        status.value = VoiceStatus.idle;
        statusMessage.value = "Ascolta le istruzioni...";
        await _tts.speak("Registra il tuo vocale di 30 secondi dopo il bip.");
        
        // Bip più professionale (tonalità alta e breve)
        await _tts.setPitch(2.0);
        await _tts.setSpeechRate(1.0);
        await _tts.speak(" . "); // Un punto pronunciato velocemente suona come un click/bip
        await _tts.setPitch(1.0);
        await _tts.setSpeechRate(0.5);

        if (!await _recorder.hasPermission()) {
          _isBusy = false;
          return false;
        }

        final directory = await getApplicationDocumentsDirectory();
        _lastFilePath = p.join(directory.path, 'audio_msg.m4a');
        
        status.value = VoiceStatus.recording;
        await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: _lastFilePath!);
        
        for (int i = 0; i <= 30; i++) {
          if (!_isBusy || status.value != VoiceStatus.recording) break;
          recordingSeconds.value = i;
          statusMessage.value = "Parla ora... (${30 - i}s)";
          await Future.delayed(const Duration(seconds: 1));
        }
        
        await _recorder.stop();
        
        // 3. Fase di revisione
        status.value = VoiceStatus.reviewing;
        return await _reviewProcess();
      }
    } catch (e) {
      status.value = VoiceStatus.error;
    } finally {
      // Non resettiamo subito a idle per permettere la visualizzazione dei tasti in auto
    }
    return false;
  }

  Future<bool> _reviewProcess() async {
    statusMessage.value = "Usa i tasti o dì Invia/Riascolta";
    await _tts.speak("Registrazione terminata. Vuoi inviarlo o riascoltarlo?");
    
    // Restiamo in attesa dei comandi (vocali o pulsanti auto)
    while (status.value == VoiceStatus.reviewing) {
      String response = await _getVoiceCommand();
      
      if (response.contains("invia") || response.contains("si") || response.contains("sì")) {
        return await sendMessage();
      } else if (response.contains("riascolta") || response.contains("senti")) {
        await playBackRecording();
      } else if (response.contains("no") || response.contains("annulla")) {
        cancelProcess();
        return false;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }

  Future<void> playBackRecording() async {
    if (_lastFilePath != null) {
      statusMessage.value = "Riascolto in corso...";
      await _internalPlayer.setFilePath(_lastFilePath!);
      await _internalPlayer.play();
      await _internalPlayer.playerStateStream.firstWhere((state) => state.processingState == ProcessingState.completed);
      statusMessage.value = "Invia o riascolta?";
      await _tts.speak("Cosa vuoi fare ora? Invia o riascolta?");
    }
  }

  Future<bool> sendMessage() async {
    status.value = VoiceStatus.sending;
    statusMessage.value = "INVIO AUTOMATICO...";
    await _tts.speak("Sto inviando il messaggio a Lady Radio.");
    
    if (_lastFilePath != null) {
      try {
        // Tentativo di apertura diretta WhatsApp sul numero specifico
        // Nota: share_plus con il file è più affidabile per l'audio m4a rispetto a un link diretto
        await Share.shareXFiles(
          [XFile(_lastFilePath!)],
          text: 'Messaggio vocale Lady Radio',
          subject: 'Audio Messaggio',
        );
        
        status.value = VoiceStatus.sent;
        _isBusy = false;
        return true;
      } catch (e) {
        status.value = VoiceStatus.error;
      }
    }
    return false;
  }

  void cancelProcess() {
    status.value = VoiceStatus.cancelled;
    _tts.speak("Messaggio eliminato.");
    _isBusy = false;
  }

  Future<String> _getVoiceCommand() async {
    if (!_speech.isAvailable) return "";
    Completer<String> completer = Completer();
    _speech.listen(
      onResult: (result) {
        if (result.finalResult) completer.complete(result.recognizedWords.toLowerCase());
      },
      listenFor: const Duration(seconds: 3),
    );
    return completer.future.timeout(const Duration(seconds: 4), onTimeout: () => "");
  }
}
