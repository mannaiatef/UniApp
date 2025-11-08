import 'package:flutter/material.dart';
import '../models/doctor.dart';
import '../services/doctor_service.dart';
import '../services/video_consultation_service.dart';
import 'booking_screen.dart';
import 'video_consultation_screen.dart';

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({super.key});

  @override
  _DoctorListScreenState createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  final List<Doctor> _doctors = DoctorService.getDoctors();
  List<Doctor> _filteredDoctors = [];
  final TextEditingController _searchController = TextEditingController();
  String _patientName = 'Patient';

  @override
  void initState() {
    super.initState();
    _filteredDoctors = _doctors;
    _searchController.addListener(_filterDoctors);
    _loadPatientName();
  }

  Future<void> _loadPatientName() async {
    final name = await VideoConsultationService.getCurrentPatientName();
    setState(() {
      _patientName = name;
    });
  }



  void _filterDoctors() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredDoctors = _doctors.where((doctor) {
        return doctor.name.toLowerCase().contains(query) ||
            doctor.specialty.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des médecins'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Rechercher par nom ou spécialité',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredDoctors.length,
              itemBuilder: (context, index) {
                final doctor = _filteredDoctors[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: ClipOval(
                        child: Image.asset(
                          doctor.image,
                          fit: BoxFit.cover,
                          width: 40.0,
                          height: 40.0,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person, size: 40.0);
                          },
                        ),
                      ),
                    ),
                    title: Text(doctor.name),
                    subtitle: Text('${doctor.specialty}\n${doctor.address}'),
                    trailing: Container(
                      constraints: const BoxConstraints(maxWidth: 100),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Bouton Consultation Vidéo
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              height: 32,
                              child: ElevatedButton(
                                onPressed: () async {
                                  // Vérifier si le patient est connecté
                                  final isLoggedIn = await VideoConsultationService.isPatientLoggedIn();
                                  
                                  if (!mounted) return;
                                  
                                  if (!isLoggedIn) {
                                    // Afficher un message d'erreur si non connecté
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Row(
                                          children: [
                                            Icon(Icons.error_outline, color: Colors.white),
                                            SizedBox(width: 8),
                                            Text('Veuillez vous connecter pour faire une consultation vidéo'),
                                          ],
                                        ),
                                        backgroundColor: Colors.red.shade600,
                                        duration: const Duration(seconds: 3),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VideoConsultationScreen(
                                        doctorName: doctor.name.replaceAll('Dr. ', ''),
                                        patientName: _patientName,
                                      ),
                                    ),
                                  );
                                },
                                child: const Icon(Icons.videocam, size: 14),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                          // Bouton Réservation
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              height: 32,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BookingScreen(doctor: doctor),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Book',
                                  style: TextStyle(fontSize: 11),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],),
    );
  }
}