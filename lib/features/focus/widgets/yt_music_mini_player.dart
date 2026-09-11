import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class YtMusicMiniPlayer extends StatefulWidget {
  const YtMusicMiniPlayer({super.key});

  @override
  State<YtMusicMiniPlayer> createState() => _YtMusicMiniPlayerState();
}

class _YtMusicMiniPlayerState extends State<YtMusicMiniPlayer> {
  InAppWebViewController? _webViewController;
  bool _isExpanded = true;
  
  String _songTitle = 'YouTube Music';
  String _artistName = 'Đang phát ngầm...';
  bool _isPlaying = false;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _fetchTrackInfo();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _updateTimer = null;
    _webViewController = null;
    super.dispose();
  }

  Future<void> _fetchTrackInfo() async {
    if (!mounted || _webViewController == null) return;

    try {
      final result = await _webViewController!.evaluateJavascript(source: '''
        (() => {
          const title = document.querySelector('ytmusic-player-bar .title')?.textContent || '';
          const artist = document.querySelector('ytmusic-player-bar .byline')?.textContent || '';
          const video = document.querySelector('video');
          const isPlaying = video ? (!video.paused && !video.ended && video.readyState > 2) : false;
          return { title, artist, isPlaying };
        })()
      ''');

      if (result != null && mounted) {
        final title = result['title']?.toString().trim() ?? '';
        final artist = result['artist']?.toString().trim() ?? '';
        final playing = result['isPlaying'] == true;

        setState(() {
          if (title.isNotEmpty) _songTitle = title;
          if (artist.isNotEmpty) _artistName = artist;
          _isPlaying = playing;
        });
      }
    } catch (_) {}
  }

  Future<void> _togglePlayPause() async {
    if (_webViewController == null) return;
    
    setState(() {
      _isPlaying = !_isPlaying;
    });

    await _webViewController!.evaluateJavascript(source: '''
      (() => {
        const video = document.querySelector('video');
        if (video) {
          if (video.paused) {
            video.play();
          } else {
            video.pause();
          }
        } else {
          document.querySelector('#play-pause-button')?.click();
        }
      })()
    ''');
    
    _fetchTrackInfo();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _isExpanded ? 420 : 360,
      height: _isExpanded ? 520 : 72,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header / Thanh thu gọn hiển thị tên bài hát và điều khiển
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(Icons.music_note, color: Colors.redAccent, size: 24),
                  const SizedBox(width: 10),
                  
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _songTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _artistName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                      color: Colors.redAccent,
                      size: 32,
                    ),
                    onPressed: _togglePlayPause,
                  ),

                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),

          // WebView ngầm không bị hủy khi thu gọn nhờ Offstage
          Expanded(
            child: Offstage(
              offstage: !_isExpanded,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                child: InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri('https://music.youtube.com'),
                  ),
                  initialSettings: InAppWebViewSettings(
                    userAgent:
                        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
                    javaScriptEnabled: true,
                    domStorageEnabled: true,
                    databaseEnabled: true,
                    mediaPlaybackRequiresUserGesture: false,
                    useShouldOverrideUrlLoading: false,
                  ),
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                  },
                  shouldOverrideUrlLoading: (controller, navigationAction) async {
                    return NavigationActionPolicy.ALLOW;
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}