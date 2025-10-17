import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/specialty.dart';

class SpecialtyDetailScreen extends StatefulWidget {
  final Specialty specialty;

  const SpecialtyDetailScreen({super.key, required this.specialty});

  @override
  State<SpecialtyDetailScreen> createState() => _SpecialtyDetailScreenState();
}

class _SpecialtyDetailScreenState extends State<SpecialtyDetailScreen> {
  late YoutubePlayerController _controller;
  bool _isVideoAvailable = false;
  bool _isPlaying = false;
  bool _isLoading = true; // Add loading state
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    try {
      if (widget.specialty.videoUrl != null && widget.specialty.videoUrl!.isNotEmpty) {
        final videoId = YoutubePlayer.convertUrlToId(widget.specialty.videoUrl!);
        if (videoId != null) {
          _controller = YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(
              autoPlay: false,
              mute: false,
              forceHD: false, // Disable HD to reduce resource usage
            ),
          )..addListener(() {
            if (!mounted) return;
            setState(() {
              _isPlaying = _controller.value.isPlaying;
              _isLoading = false; // Stop loading when ready
            });
          });
          setState(() {
            _isVideoAvailable = true;
            _isLoading = false; // Stop loading on success
          });
        } else {
          setState(() {
            _errorMessage = 'Invalid YouTube URL';
            _isLoading = false; // Stop loading on error
          });
        }
      } else {
        setState(() {
          _isLoading = false; // Stop loading if no URL
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading video: $e';
        _isLoading = false; // Stop loading on exception
      });
      print('Video initialization error: $e'); // Log for debugging
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller.value.isReady) {
      setState(() {
        if (_controller.value.isPlaying) {
          _controller.pause();
          _isPlaying = false;
        } else {
          _controller.play();
          _isPlaying = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.specialty.name,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF003087),
        elevation: 4,
      ),
      body: Container(
        color: Colors.grey[100],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Specialty description
              if (widget.specialty.description != null && widget.specialty.description!.isNotEmpty)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      widget.specialty.description!,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Video section with loading state
              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: Color(0xFF003087)))
              else if (_isVideoAvailable)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: YoutubePlayer(
                          controller: _controller,
                          showVideoProgressIndicator: true,
                          progressIndicatorColor: const Color(0xFF003087),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FloatingActionButton(
                              mini: true,
                              backgroundColor: const Color(0xFF003087),
                              onPressed: _togglePlay,
                              child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else if (_errorMessage != null)
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 16, color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                else
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'No video available',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}