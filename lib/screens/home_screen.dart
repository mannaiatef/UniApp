import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uniapp/models/doctor.dart';
import '../services/auth_service.dart';
import '../models/patient.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'doctor_list_screen.dart';
import '../models/appointment.dart';
import '../models/treatment.dart';
import '../services/appointment_service.dart';
import '../services/treatment_service.dart';
import 'medical_chat_page.dart';
import '../widgets/add_edit_treatment_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Patient? _currentPatient;
  Future<List<Appointment>> _appointmentsFuture = Future.value([]);
  Future<List<Treatment>> _treatmentsFuture = Future.value([]);
  final TreatmentService _treatmentService = TreatmentService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
    _loadAppointments();
    _loadTreatments();
  }

  void _loadTreatments() {
    _treatmentsFuture = _treatmentService.getTreatmentsByPatient(_currentPatient?.id ?? 1);
  }

  Future<void> _loadPatientData() async {
    if (!mounted) return;
    final authService = Provider.of<AuthService>(context, listen: false);
    final patient = await authService.getCurrentPatient();
    
    if (mounted) {
      setState(() {
        _currentPatient = patient;
        _isLoading = false;
      });
    }
  }

  void _loadAppointments() {
    _appointmentsFuture = AppointmentService.getAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade800,
        title: const Text(
          'Espace Patient',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              // Déconnexion et retour à l'écran de connexion
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Déconnexion'),
                  content: const Text('Êtes-vous sûr de vouloir vous déconnecter?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                      ),
                      onPressed: () {
                        Provider.of<AuthService>(context, listen: false).logout();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      child: const Text('Déconnecter'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.blue))
        : Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade800, Colors.blue.shade100],
                stops: const [0.0, 0.3],
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // En-tête avec photo de profil
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context, 
                                    MaterialPageRoute(builder: (_) => const ProfileScreen())
                                  ).then((_) => _loadPatientData());
                                },
                                child: Hero(
                                  tag: 'profilePhoto',
                                  child: FutureBuilder<bool>(
                                    future: _currentPatient?.photoUrl != null
                                        ? File(_currentPatient!.photoUrl!).exists()
                                        : Future.value(false),
                                    builder: (context, snapshot) {
                                      final hasImage = snapshot.data == true;
                                      return CircleAvatar(
                                        radius: 60,
                                        backgroundColor: Colors.white,
                                        backgroundImage: hasImage && _currentPatient?.photoUrl != null
                                            ? FileImage(File(_currentPatient!.photoUrl!))
                                            : null,
                                        child: !hasImage
                                            ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                            : null,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade800,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context, 
                                    MaterialPageRoute(builder: (_) => const ProfileScreen())
                                  ).then((_) => _loadPatientData());
                                },
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${_currentPatient?.prenom ?? ''} ${_currentPatient?.nom ?? ''}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentPatient?.email ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Contenu principal
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bienvenue dans votre espace patient',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Section Consulter les médecins
                        const Text(
                          'Consulter les médecins',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildServiceCard(
                          icon: Icons.medical_services_outlined,
                          title: 'Consulter les médecins',
                          description: 'Trouvez et consultez des médecins spécialisés',
                          onTap: () {
                            Navigator.pushNamed(context, '/doctors');
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildServiceCard(
                          icon: Icons.calendar_today,
                          title: 'Mes rendez-vous',
                          description: 'Gérez vos rendez-vous médicaux',
                          onTap: () {
                            Navigator.pushNamed(context, '/appointments');
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildServiceCard(
                          icon: Icons.chat_bubble_outline,
                          title: 'Assistant Médical',
                          description: 'Posez vos questions de santé',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MedicalChatPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        // Section Mes Traitements
                        const Text(
                          'Mes Traitements',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddEditTreatmentDialog(
                                  patientId: _currentPatient?.id ?? 1,
                                  onSave: (treatment) async {
                                    await _treatmentService.insertTreatment(treatment);
                                    setState(() {
                                      _treatmentsFuture = _treatmentService.getTreatmentsByPatient(_currentPatient?.id ?? 1);
                                    });
                                  },
                                ),
                              ),
                            ).then((_) {
                              setState(() {
                                _appointmentsFuture = AppointmentService.getAppointments();
                              });
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter un traitement'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<List<Treatment>>(
                          future: _treatmentsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(child: Text('Erreur: ${snapshot.error}'));
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Card(
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.medication_outlined,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Aucun traitement enregistré',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => AddEditTreatmentDialog(
                                                patientId: _currentPatient?.id ?? 1,
                                                onSave: (treatment) async {
                                                  await _treatmentService.insertTreatment(treatment);
                                                  setState(() {
                                                    _treatmentsFuture = _treatmentService.getTreatmentsByPatient(_currentPatient?.id ?? 1);
                                                  });
                                                },
                                              ),
                                            ),
                                          ).then((_) {
                                            setState(() {
                                              _treatmentsFuture = _treatmentService.getTreatmentsByPatient(_currentPatient?.id ?? 1);
                                            });
                                          });
                                        },
                                        child: const Text('Ajouter votre premier traitement'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else {
                              final treatments = snapshot.data!;
                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: treatments.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final treatment = treatments[index];
                                  return _TreatmentCard(
                                    treatment: treatment,
                                    onEdit: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddEditTreatmentDialog(
                                            treatment: treatment,
                                            patientId: _currentPatient?.id ?? 1,
                                            onSave: (updatedTreatment) async {
                                              await _treatmentService.updateTreatment(updatedTreatment);
                                              setState(() {
                                                _treatmentsFuture = _treatmentService.getTreatmentsByPatient(_currentPatient?.id ?? 1);
                                              });
                                            },
                                          ),
                                        ),
                                      ).then((_) {
                                        setState(() {
                                          _treatmentsFuture = _treatmentService.getTreatmentsByPatient(_currentPatient?.id ?? 1);
                                        });
                                      });
                                    },
                                    onDelete: () async {
                                      if (treatment.id != null) {
                                        await _treatmentService.deleteTreatment(treatment.id!);
                                        setState(() {
                                          _treatmentsFuture = _treatmentService.getTreatmentsByPatient(_currentPatient?.id ?? 1);
                                        });
                                      }
                                    },
                                    onConsume: () async {
                                      await _treatmentService.recordConsumption(treatment.id!, DateTime.now());
                                      setState(() {
                                        _treatmentsFuture = _treatmentService.getTreatmentsByPatient(_currentPatient?.id ?? 1);
                                      });
                                    },
                                  );
                                },
                              );
                            }
                          },
                        ),
                        /*
                        const SizedBox(height: 24),
                        const Text(
                          'Vos prochains rendez-vous',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        */



                        /*
                        const SizedBox(height: 16),
                        const Text(
                          'Mes rendez-vous',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<List<Appointment>>(
                          future: _appointmentsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(child: Text('Erreur: ${snapshot.error}'));
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Center(child: Text('Aucun rendez-vous à venir.'));
                            } else {
                              final appointments = snapshot.data!;
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: appointments.length,
                                itemBuilder: (context, index) {
                                  final appointment = appointments[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    elevation: 2,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundImage: appointment.doctor.image.startsWith('assets/')
                                            ? AssetImage(appointment.doctor.image)
                                            : null,
                                        onBackgroundImageError: (_, __) => null,
                                        child: appointment.doctor.image.startsWith('assets/')
                                            ? null
                                            : const Icon(Icons.person),
                                      ),
                                      title: Text(appointment.doctor.name),
                                      subtitle: Text('${appointment.doctor.specialty}\n${appointment.dateTime.toLocal()}'),
                                      isThreeLine: true,
                                    ),
                                  );
                                },
                              );
                            }
                          },
                        ),



                        */
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DoctorListScreen()),
                            ).then((_) {
                              setState(() {
                                _loadAppointments();
                              });
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Prendre un nouveau rendez-vous'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
  
  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.blue.shade800,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.blue.shade800,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TreatmentCard extends StatelessWidget {
  final Treatment treatment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onConsume;

  const _TreatmentCard({
    required this.treatment,
    required this.onEdit,
    required this.onDelete,
    required this.onConsume,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    treatment.medicationName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                      case 'consume':
                        onConsume();
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'consume',
                      child: ListTile(
                        leading: Icon(Icons.check_circle, color: Colors.green),
                        title: Text('Marquer comme pris'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit, color: Colors.blue),
                        title: Text('Modifier'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Supprimer'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Dosage: ${treatment.dosage}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Fréquence: ${treatment.frequency}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Date de début: ${_formatDate(treatment.startDate)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            if (treatment.endDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Date de fin: ${_formatDate(treatment.endDate!)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            if (treatment.notes != null && treatment.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Instructions: ${treatment.notes}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  treatment.isActive ? Icons.check_circle : Icons.cancel,
                  color: treatment.isActive ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  treatment.isActive ? 'Actif' : 'Inactif',
                  style: TextStyle(
                    fontSize: 12,
                    color: treatment.isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (treatment.id != null) ...[
                  FutureBuilder<int>(
                    future: TreatmentService().getConsumptionCountForToday(treatment.id!),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: count > 0 ? Colors.green.shade100 : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Pris: $count',
                          style: TextStyle(
                            fontSize: 12,
                            color: count > 0 ? Colors.green.shade700 : Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}