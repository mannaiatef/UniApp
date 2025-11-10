import '../models/appointment.dart';
import 'database_helper.dart';
import 'notification_service.dart';

class AppointmentService {
  static Future<void> saveAppointment(Appointment appointment) async {
    if (appointment.patientId == null) {
      throw ArgumentError('patientId is required to save an appointment');
    }

    final dbHelper = DatabaseHelper();
    await dbHelper.ensureAppointmentsTable(); // Ensure table exists
    await dbHelper.ensureAppointmentsPatientLink();
    final db = await dbHelper.database;
    final id = await db.insert('appointments', appointment.toMap());
    
    // Planifier une notification 1 heure avant le rendez-vous
    if (id > 0) {
      await NotificationService.scheduleAppointmentReminder(
        id,
        appointment.doctor.name,
        appointment.dateTime,
      );
    }
  }

  static Future<List<Appointment>> getAppointments({int? patientId}) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.ensureAppointmentsTable(); // Ensure table exists
    await dbHelper.ensureAppointmentsPatientLink();
    final db = await dbHelper.database;
    List<Map<String, dynamic>> maps;
    if (patientId != null) {
      maps = await db.query(
        'appointments',
        where: 'patientId = ?',
        whereArgs: [patientId],
        orderBy: 'date_time ASC',
      );
    } else {
      maps = await db.query(
        'appointments',
        orderBy: 'date_time ASC',
      );
    }
    return List.generate(maps.length, (i) {
      return Appointment.fromMap(maps[i]);
    });
  }

  static Future<void> deleteAppointment(int id, {int? patientId}) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.ensureAppointmentsTable(); // Ensure table exists
    await dbHelper.ensureAppointmentsPatientLink();
    final db = await dbHelper.database;
    await db.delete(
      'appointments',
      where: patientId != null ? 'id = ? AND patientId = ?' : 'id = ?',
      whereArgs: patientId != null ? [id, patientId] : [id],
    );
  }

  static Future<void> updateAppointment(Appointment appointment) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.ensureAppointmentsTable(); // Ensure table exists
    await dbHelper.ensureAppointmentsPatientLink();
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