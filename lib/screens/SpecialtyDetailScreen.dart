import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:developer' as developer;
import '../models/specialty.dart';
import '../models/doctor.dart';
import 'DoctorDetailScreen.dart';

class SpecialtyDetailScreen extends StatefulWidget {
  final Specialty specialty;

  const SpecialtyDetailScreen({super.key, required this.specialty});

  @override
  State<SpecialtyDetailScreen> createState() => _SpecialtyDetailScreenState();
}

class _SpecialtyDetailScreenState extends State<SpecialtyDetailScreen> with SingleTickerProviderStateMixin {
  YoutubePlayerController? _controller;
  bool _isVideoAvailable = false;
  bool _isLoading = true;
  String? _errorMessage;
  String? _videoId;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final GlobalKey _shareButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    developer.log('Entering SpecialtyDetailScreen for specialty: ${widget.specialty.name} (ID: ${widget.specialty.id})',
        name: 'SpecialtyDetailScreen');
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      developer.log('Initializing video with URL: ${widget.specialty.videoUrl}', name: 'SpecialtyDetailScreen');
      if (widget.specialty.videoUrl != null && widget.specialty.videoUrl!.isNotEmpty) {
        final videoId = YoutubePlayer.convertUrlToId(widget.specialty.videoUrl!);
        developer.log('Extracted video ID: $videoId', name: 'SpecialtyDetailScreen');
        if (videoId != null && videoId.isNotEmpty) {
          _controller = YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(
              autoPlay: false,
              mute: false,
              forceHD: false,
              enableCaption: true,
              loop: false,
              showLiveFullscreenButton: true,
            ),
          )..addListener(() {
            if (!mounted) return;
            setState(() {
              developer.log('YouTube player state: isReady=${_controller!.value.isReady}, isPlaying=${_controller!.value.isPlaying}',
                  name: 'SpecialtyDetailScreen');
            });
          });
          setState(() {
            _videoId = videoId;
            _isVideoAvailable = true;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Invalid YouTube URL provided';
            _isVideoAvailable = false;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'No video available for this specialty';
          _isVideoAvailable = false;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      setState(() {
        _errorMessage = 'Error loading video: $e';
        _isVideoAvailable = false;
        _isLoading = false;
      });
      developer.log('Video initialization error: $e, stackTrace: $stackTrace', name: 'SpecialtyDetailScreen');
    }
  }

  void _shareSpecialty() {
    final RenderBox? renderBox = _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
    Rect? shareRect = renderBox != null ? renderBox.localToGlobal(Offset.zero) & renderBox.size : null;

    Share.share(
      'Learn about ${widget.specialty.name}: https://example.com/specialties/${widget.specialty.id}',
      subject: '${widget.specialty.name} Specialty',
      sharePositionOrigin: shareRect,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).copyWith(
      primaryColor: const Color(0xFF003087),
      scaffoldBackgroundColor: Colors.grey[100],
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        shadowColor: Colors.grey.withOpacity(0.3),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF003087)),
        bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
        labelLarge: TextStyle(fontSize: 14, color: Colors.black54),
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.specialty.name, style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white)),
          backgroundColor: theme.primaryColor,
          elevation: 4,
          actions: [
            IconButton(
              key: _shareButtonKey,
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: _shareSpecialty,
              tooltip: 'Share Specialty',
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description Section
                if (widget.specialty.description != null && widget.specialty.description!.isNotEmpty) ...[
                  Text('Description', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        widget.specialty.description!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                // Video Section
                Text('Video', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                if (_isLoading)
                  Card(
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.3,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(color: Color(0xFF003087)),
                    ),
                  )
                else if (_isVideoAvailable && _videoId != null && _controller != null)
                  Card(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Column(
                        children: [
                          YoutubePlayer(
                            controller: _controller!,
                            showVideoProgressIndicator: true,
                            progressIndicatorColor: const Color(0xFF003087),
                            bottomActions: [
                              CurrentPosition(),
                              ProgressBar(isExpanded: true, colors: const ProgressBarColors(playedColor: Color(0xFF003087))),
                              RemainingDuration(),
                              FullScreenButton(),
                            ],
                            onReady: () {
                              developer.log('YouTube player ready', name: 'SpecialtyDetailScreen');
                            },
                            onEnded: (metaData) {
                              developer.log('Video ended: ${metaData.title}', name: 'SpecialtyDetailScreen');
                              _controller?.seekTo(Duration.zero);
                              _controller?.pause();
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.replay, color: Color(0xFF003087)),
                                  onPressed: () => _controller?.play(),
                                  tooltip: 'Replay Video',
                                ),
                                IconButton(
                                  icon: Icon(
                                    _controller?.value.isPlaying == true ? Icons.pause : Icons.play_arrow,
                                    color: const Color(0xFF003087),
                                  ),
                                  onPressed: () {
                                    if (_controller?.value.isPlaying == true) {
                                      _controller?.pause();
                                    } else {
                                      _controller?.play();
                                    }
                                    setState(() {});
                                  },
                                  tooltip: _controller?.value.isPlaying == true ? 'Pause' : 'Play',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Card(
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.3,
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _errorMessage ?? 'No video available',
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            if (_errorMessage != null)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isLoading = true;
                                    _errorMessage = null;
                                  });
                                  _initializeVideo();
                                },
                                child: const Text(
                                  'Retry',
                                  style: TextStyle(color: Color(0xFF003087), fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Related Doctors Section
                const SizedBox(height: 24),
                Text('Related Doctors', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('doctors')
                      .where('specialtyId', isEqualTo: widget.specialty.id)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Error loading doctors: ${snapshot.error}',
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Card(child: Center(child: CircularProgressIndicator(color: Color(0xFF003087))));
                    }
                    final doctors = snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Doctor(
                        id: doc.id,
                        name: data['name'] ?? 'Unknown',
                        email: data['email'],
                        phone: data['phone'],
                        address: data['address'],
                        biography: data['biography'],
                        website: data['website'],
                        facebookUrl: data['facebookUrl'],
                        twitterUrl: data['twitterUrl'],
                        photoUrl: data['photoUrl'],
                        specialtyId: data['specialtyId'] ?? '',
                        latitude: data['latitude']?.toDouble(),
                        longitude: data['longitude']?.toDouble(),
                        reviews: (data['reviews'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
                      );
                    }).toList();

                    if (doctors.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No doctors found for this specialty',
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: doctors.length,
                      itemBuilder: (context, index) {
                        final doctor = doctors[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: doctor.photoUrl != null && doctor.photoUrl!.isNotEmpty
                                  ? NetworkImage(doctor.photoUrl!)
                                  : null,
                              child: doctor.photoUrl == null || doctor.photoUrl!.isEmpty
                                  ? const Icon(Icons.person, color: Color(0xFF003087))
                                  : null,
                            ),
                            title: Text(doctor.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              doctor.biography ?? 'No biography available',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DoctorDetailScreen(doctor: doctor),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}