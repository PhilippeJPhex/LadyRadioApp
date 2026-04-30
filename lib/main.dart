import 'dart:io';
import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'screens/main_screen.dart';
import 'package:audio_service/audio_service.dart';
import 'core/audio_handler.dart';
import 'data/favorites_service.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

AudioHandler? audioHandler;
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = MyHttpOverrides();
    
    // Inizializzazione servizi con gestione errori
    await _initServices();
    
    runApp(const LadyRadioApp());
  } catch (e, stack) {
    debugPrint("Errore critico durante l'avvio: $e");
    debugPrint(stack.toString());
    // Avviamo comunque l'app per mostrare un eventuale errore o fallback
    runApp(const LadyRadioApp());
  }
}

Future<void> _initServices() async {
  // Carichiamo i preferiti
  try {
    await FavoritesService().init();
  } catch (e) {
    debugPrint("Errore inizializzazione Preferiti: $e");
  }

  // Inizializziamo l'audio handler
  try {
    audioHandler = await AudioService.init(
      builder: () => CustomAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'it.ladyradio.lady_app.channel.audio',
        androidNotificationChannelName: 'Lady Radio Riproduzione',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidResumeOnClick: false, // Impedisce il resume automatico via Bluetooth/Media buttons
      ),
    );
  } catch (e) {
    debugPrint("Errore inizializzazione AudioService: $e");
    // Fallback se AudioService fallisce per evitare il blocco totale
  }
}

class LadyRadioApp extends StatefulWidget {
  const LadyRadioApp({super.key});

  @override
  State<LadyRadioApp> createState() => _LadyRadioAppState();
}

class _LadyRadioAppState extends State<LadyRadioApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _removeSplash();
  }

  Future<void> _removeSplash() async {
    // Forza una durata minima di 2 secondi per il loader/branding
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'Lady Radio',
      theme: AppTheme.lightTheme,
      home: _showSplash ? const SplashScreen() : const MainScreen(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return child!;
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/lady512.png',
              width: 180,
              height: 180,
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}

