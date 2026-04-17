import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'live_screen.dart';
import 'frequencies_screen.dart';
import 'contacts_screen.dart';
import '../widgets/global_mini_player.dart';
import 'podcast_screen.dart';
import '../main.dart';
import '../core/audio_handler.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  final List<Widget> _screens = [
    const HomeScreen(),
    const LiveScreen(),
    const FrequenciesScreen(),
    const ContactsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final navigator = _navigatorKeys[_currentIndex].currentState;
        if (navigator != null && await navigator.maybePop()) {
          return;
        }
        
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        } else {
          if (context.mounted) {
            final mainNavigator = Navigator.of(context);
            if (mainNavigator.canPop()) {
              mainNavigator.pop();
            } else {
              mainNavigator.maybePop();
            }
          }
        }
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Contenuto principale: ora a tutto schermo
            IndexedStack(
              index: _currentIndex,
              children: List.generate(_screens.length, (index) {
                return Navigator(
                  key: _navigatorKeys[index],
                  onGenerateRoute: (routeSettings) {
                    return MaterialPageRoute(
                      builder: (context) => _screens[index],
                    );
                  },
                );
              }),
            ),
            
            // Mini Player in alto: ora posizionato sopra il contenuto
            SafeArea(
              bottom: false,
              child: StreamBuilder<MediaItem?>(
                stream: audioHandler?.mediaItem,
                builder: (context, snapshot) {
                  final mediaItem = snapshot.data;
                  final bool isLive = mediaItem?.id == CustomAudioHandler.liveItemKey;
                  final bool hasActiveItem = mediaItem != null && !isLive;

                  return ValueListenableBuilder<bool>(
                    valueListenable: isPodcastScreenVisible,
                    builder: (context, isVisible, _) {
                      return ValueListenableBuilder<String?>(
                        valueListenable: currentPodcastPageId,
                        builder: (context, pageId, _) {
                          final bool shouldHide = isVisible && pageId == mediaItem?.id;
                          
                          if (hasActiveItem && !shouldHide) {
                            return GlobalMiniPlayer(
                              onTap: (mediaItem) {
                                final dummyMap = {
                                  'program': mediaItem.album ?? 'Lady Radio',
                                  'title': mediaItem.title,
                                  'image': mediaItem.extras?['image'] ?? 'https://ladyradio.it/wp-content/uploads/2021/01/logo-lady-radio.png',
                                  'duration': '',
                                  'date': '',
                                  'audioUrl': mediaItem.id,
                                };
                                _navigatorKeys[_currentIndex].currentState?.push(
                                  MaterialPageRoute(builder: (_) => PodcastScreen(episodeData: dummyMap))
                                );
                              },
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == _currentIndex) {
              _navigatorKeys[index].currentState!.popUntil((route) => route.isFirst);
              isPodcastScreenVisible.value = false;
              currentPodcastPageId.value = null;
            } else {
              setState(() {
                _currentIndex = index;
              });
              
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  final navState = _navigatorKeys[index].currentState;
                  final bool hasNestedRoute = navState?.canPop() ?? false;
                  isPodcastScreenVisible.value = hasNestedRoute;
                  // In caso di cambio tab, resettiamo l'ID della pagina corrente per sicurezza
                  if (!hasNestedRoute) currentPodcastPageId.value = null;
                }
              });
            }
          },
        ),
      ),
    );
  }
}
