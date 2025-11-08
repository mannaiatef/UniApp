import 'package:flutter/material.dart';
import '../services/video_consultation_service.dart';
import 'video_chat_screen.dart';

class VideoConsultationScreen extends StatefulWidget {
  final String doctorName;
  final String patientName;

  const VideoConsultationScreen({
    super.key,
    required this.doctorName,
    required this.patientName,
  });

  @override
  State<VideoConsultationScreen> createState() => _VideoConsultationScreenState();
}

class _VideoConsultationScreenState extends State<VideoConsultationScreen> {
  bool _isCallActive = false;
  String _patientName = 'Patient';

  @override
  void initState() {
    super.initState();
    _initializeConsultation();
  }

  Future<void> _initializeConsultation() async {
    final name = await VideoConsultationService.getCurrentPatientName();
    setState(() {
      _patientName = name;
    });
  }

  void _startCall() {
    setState(() {
      _isCallActive = true;
    });
  }

  void _endCall() {
    setState(() {
      _isCallActive = false;
    });
    Navigator.pop(context);
  }

  void _toggleMicrophone() {
    // Implémentation pour activer/désactiver le microphone
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Microphone togglé')),
    );
  }

  void _toggleCamera() {
    // Implémentation pour activer/désactiver la caméra
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Caméra togglée')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCallActive) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text('Appel avec Dr. ${widget.doctorName}'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoChatScreen(
                      doctorName: widget.doctorName,
                      patientName: _patientName,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.mic_off, color: Colors.white),
              onPressed: _toggleMicrophone,
            ),
            IconButton(
              icon: const Icon(Icons.videocam_off, color: Colors.white),
              onPressed: _toggleCamera,
            ),
          ],
        ),
        body: Stack(
          children: [
            // Vue principale (caméra du médecin)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[900],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.person, size: 80, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Dr. ${widget.doctorName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '00:02:30',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Mini vue de la caméra du patient (picture-in-picture)
            Positioned(
              top: 100,
              right: 16,
              width: 120,
              height: 160,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 2),
                  color: Colors.grey[800],
                ),
                child: const Center(
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
              ),
            ),
            // Contrôles d'appel
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    onPressed: _toggleMicrophone,
                    backgroundColor: Colors.white24,
                    child: const Icon(Icons.mic_off, color: Colors.white),
                  ),
                  const SizedBox(width: 24),
                  FloatingActionButton(
                    onPressed: _endCall,
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.call_end, color: Colors.white),
                  ),
                  const SizedBox(width: 24),
                  FloatingActionButton(
                    onPressed: _toggleCamera,
                    backgroundColor: Colors.white24,
                    child: const Icon(Icons.videocam_off, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Écran de pré-appel
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultation Vidéo'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar du médecin
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue.shade800, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  radius: 60,
                  child: Icon(Icons.person, size: 60),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Dr. ${widget.doctorName}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Prêt pour la consultation vidéo',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),
              // Boutons d'action
              SizedBox(
                width: 200,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _startCall,
                  icon: const Icon(Icons.videocam, size: 28),
                  label: const Text(
                    'Démarrer l\'appel',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Annuler',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}