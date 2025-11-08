import '../models/appointment.dart';
import 'database_helper.dart';
import 'notification_service.dart';

class AppointmentService {
  static Future<void> saveAppointment(Appointment appointment) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.ensureAppointmentsTable(); // Ensure table exists
    final db = await dbHelper.database;
    final id = await db.insert('appointments', appointment.toMap());
    
    // Planifier une notification 1 heure avant le rendez-vous
    if (id != null && id > 0) {
      await NotificationService.scheduleAppointmentReminder(
        id,
        appointment.doctor.name,
        appointment.dateTime,
      );
    }
  }

  static Future<List<Appointment>> getAppointments() async {
    final dbHelper = DatabaseHelper();
    await dbHelper.ensureAppointmentsTable(); // Ensure table exists
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('appointments');
    return List.generate(maps.length, (i) {
      return Appointment.fromMap(maps[i]);
    });
  }

  static Future<void> deleteAppointment(int id) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.ensureAppointmentsTable(); // Ensure table exists
    final db = await dbHelper.database;
    await db.delete(
      'appointments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> updateAppointment(Appointment appointment) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.ensureAppointmentsTable(); // Ensure table exists
    final db = await dbHelper.database;
    
    // Annuler l'ancienne notification avant de mettre à jour
    if (appointment.id != null) {
      await NotificationService.cancelNotification(appointment.id!);
    }
    
    await db.update(
      'appointments',
      appointment.toMap(),
      where: 'id = ?',
      whereArgs: [appointment.id],
    );
    
    // Planifier une nouvelle notification avec les nouvelles données
    if (appointment.id != null) {
      await NotificationService.scheduleAppointmentReminder(
        appointment.id!,
        appointment.doctor.name,
        appointment.dateTime,
      );
    }
  }
}