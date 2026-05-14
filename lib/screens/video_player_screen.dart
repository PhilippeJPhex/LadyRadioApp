import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../core/app_theme.dart';
import '../main.dart';
import '../widgets/global_mini_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    this.title = 'Lady Radio TV',
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with WidgetsBindingObserver {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  StreamSubscription? _audioPlaybackSubscription;
  bool _videoControllerCreated = false;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    audioHandler?.pause();
    _audioPlaybackSubscription = audioHandler?.playbackState.listen((state) {
      if (state.playing &&
          _videoControllerCreated &&
          _videoController.value.isInitialized &&
          _videoController.value.isPlaying) {
        _videoController.pause();
      }
    });
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        httpHeaders: const {
          'User-Agent':
              'LadyRadioApp/1.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)',
        },
      );
      _videoControllerCreated = true;

      await _videoController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        deviceOrientationsOnEnterFullScreen: const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        deviceOrientationsAfterFullScreen: DeviceOrientation.values,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.primaryColor,
          handleColor: AppTheme.accentColor,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white54,
        ),
        placeholder: const ColoredBox(color: Colors.black),
        errorBuilder: (context, errorMessage) {
          return _buildErrorContent();
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _syncFullScreenWithOrientation();
        });
      }
    } catch (e) {
      debugPrint('Errore player Lady TV: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _retry() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    if (_videoControllerCreated) {
      await _videoController.dispose();
      _videoControllerCreated = false;
    }
    _chewieController?.dispose();
    _chewieController = null;
    await _initializePlayer();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncFullScreenWithOrientation();
    });
  }

  void _syncFullScreenWithOrientation() {
    if (!mounted) return;

    final chewieController = _chewieController;
    if (chewieController == null || _hasError || _isLoading) return;

    final size = View.of(context).physicalSize;
    final isLandscape = size.width > size.height;

    if (isLandscape && !chewieController.isFullScreen) {
      chewieController.enterFullScreen();
    } else if (!isLandscape && chewieController.isFullScreen) {
      chewieController.exitFullScreen();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlaybackSubscription?.cancel();
    _chewieController?.dispose();
    if (_videoControllerCreated) {
      _videoController.dispose();
    }
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Widget _buildErrorContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.tv_off, color: Colors.white54, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Impossibile caricare Lady TV',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _retry, child: const Text('Riprova')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chewieController = _chewieController;

    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GlobalMiniPlayerVisibilityBuilder(
          builder: (context, isMiniPlayerVisible) {
            return SafeArea(
              top: !isMiniPlayerVisible,
              child: Padding(
                padding: EdgeInsets.only(top: isMiniPlayerVisible ? 10 : 0),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: kToolbarHeight,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Text(
                                widget.title,
                                style: const TextStyle(fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                    ),
                    Positioned.fill(
                      top: kToolbarHeight,
                      child: Center(
                        child: _hasError
                            ? _buildErrorContent()
                            : chewieController != null
                            ? AspectRatio(
                                aspectRatio: _videoController.value.aspectRatio,
                                child: Chewie(controller: chewieController),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    if (_isLoading)
                      const Positioned.fill(
                        top: kToolbarHeight,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: AppTheme.primaryColor,
                              ),
                              SizedBox(height: 20),
                              Text(
                                'Connessione alla Lady TV...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
