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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    if (widget.specialty.videoUrl != null && widget.specialty.videoUrl!.isNotEmpty) {
      // Extract YouTube video ID from URL
      final videoId = YoutubePlayer.convertUrlToId(widget.specialty.videoUrl!);
      if (videoId != null) {
        _controller = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
          ),
        )..addListener(() {
          if (!mounted) return;
          setState(() {
            _isPlaying = _controller.value.isPlaying;
          });
        });
        setState(() {
          _isVideoAvailable = true;
        });
      } else {
        setState(() {
          _errorMessage = 'Invalid YouTube URL';
        });
      }
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
        title: Text(widget.specialty.name),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.specialty.description != null && widget.specialty.description!.isNotEmpty)
              Text(widget.specialty.description!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),

            // Video Section
            if (_isVideoAvailable)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  YoutubePlayer(
                    controller: _controller,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: Colors.blueAccent,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton(
                        mini: true,
                        backgroundColor: Colors.blue.shade700,
                        onPressed: _togglePlay,
                        child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      ),
                    ],
                  ),
                ],
              )
            else if (_errorMessage != null)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'No video available',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
              ),
          ],
        ),
      ),
      backgroundColor: Colors.grey.shade100,
    );
  }
}