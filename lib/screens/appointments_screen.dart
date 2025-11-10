import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../widgets/edit_appointment_dialog.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  late Future<List<Appointment>> _appointmentsFuture;
  int? _patientId;

  @override
  void initState() {
    super.initState();
    _appointmentsFuture = Future.value([]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAppointments();
    });
  }

  Future<void> _loadAppointments() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final patient = await authService.getCurrentPatient();

    if (!mounted) return;

    if (patient == null || patient.id == null) {
      setState(() {
        _patientId = null;
        _appointmentsFuture = Future.value([]);
      });
      return;
    }

    setState(() {
      _patientId = patient.id;
      _appointmentsFuture = AppointmentService.getAppointments(patientId: patient.id!);
    });
  }

  Future<void> _deleteAppointment(int id) async {
    try {
      // Annuler les notifications associées au rendez-vous
      // On annule la notification principale (id) et les notifications planifiées (id + 1000 pour 24h)
      await NotificationService.cancelNotification(id);
      await NotificationService.cancelNotification(id + 1000);
      
      // Supprimer le rendez-vous de la base de données
      await AppointmentService.deleteAppointment(id, patientId: _patientId);
      
      if (mounted) {
        await _loadAppointments();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rendez-vous supprimé avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _editAppointment(Appointment appointment) async {
    showDialog(
      context: context,
      builder: (context) => EditAppointmentDialog(
        appointment: appointment,
        onSave: (updatedAppointment) async {
          try {
            await AppointmentService.updateAppointment(updatedAppointment);
            await _loadAppointments();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Rendez-vous modifié avec succès'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors de la modification: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes rendez-vous'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: FutureBuilder<List<Appointment>>(
        future: _appointmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final appointments = snapshot.data ?? [];

          if (appointments.isEmpty) {
            return const Center(
              child: Text('Aucun rendez-vous programmé'),
            );
          }

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appointment.doctor.specialty),
                      Text(appointment.dateTime.toLocal().toString()),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editAppointment(appointment),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirmer la suppression'),
                              content: Text(
                                'Êtes-vous sûr de vouloir supprimer le rendez-vous avec ${appointment.doctor.name} ?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Annuler'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _deleteAppointment(appointment.id!);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Supprimer'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigation vers la page de réservation
          Navigator.pushNamed(context, '/doctors');
        },
        backgroundColor: Colors.blue.shade800,
        child: const Icon(Icons.add),
      ),
    );
  }
}