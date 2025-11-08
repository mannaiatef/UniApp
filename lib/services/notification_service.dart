import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io';
import '../models/appointment.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
      },
    );

    // Request permissions for Android 13+
    if (Platform.isAndroid) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }









  static Future<void> showAppointmentNotification(
      String title, String body, int id) async {
    // Configuration Android - utiliser le son par défaut pour éviter les erreurs
    // Le son personnalisé peut être ajouté plus tard si nécessaire
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'appointment_channel',
      'Rendez-vous',
      channelDescription: 'Notifications pour les rendez-vous médicaux',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      // Son personnalisé désactivé temporairement pour éviter les erreurs
      // sound: RawResourceAndroidNotificationSound('song'),
      enableVibration: true,
      enableLights: true,
      channelShowBadge: true,
    );

    // Configuration iOS - utiliser le son par défaut pour éviter les erreurs
    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      // Son personnalisé désactivé temporairement pour éviter les erreurs
      // sound: 'song.mp3',
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  static Future<void> scheduleAppointmentNotification(
      int id, String title, String body, DateTime scheduledTime) async {
    // Configuration Android - utiliser le son par défaut pour éviter les erreurs
    // Le son personnalisé peut être ajouté plus tard si nécessaire
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'appointment_channel',
      'Rendez-vous',
      channelDescription: 'Notifications pour les rendez-vous médicaux',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      // Son personnalisé désactivé temporairement pour éviter les erreurs
      // sound: RawResourceAndroidNotificationSound('song'),
      enableVibration: true,
      enableLights: true,
      channelShowBadge: true,
      styleInformation: BigTextStyleInformation(''),
    );

    // Configuration iOS - utiliser le son par défaut pour éviter les erreurs
    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      // Son personnalisé désactivé temporairement pour éviter les erreurs
      // sound: 'song.mp3',
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, // Changed from exact to inexact for compatibility
      );
    } catch (e) {
      // If inexact alarms also fail, try with inexact schedule mode (less precise but more compatible)
      try {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(scheduledTime, tz.local),
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.inexact, // Fallback to basic inexact mode
        );
      } catch (e2) {
        // If all scheduling modes fail, just log the error and continue
        // The notification will still work for immediate notifications
        print('Could not schedule notification: $e2');
      }
    }
  }

  /// Planifie une notification 1 heure avant un rendez-vous
  static Future<void> scheduleAppointmentReminder(
      int appointmentId, String doctorName, DateTime appointmentDateTime) async {
    try {
      // Calculer l'heure de notification (1 heure avant le rendez-vous)
      final notificationTime = appointmentDateTime.subtract(const Duration(hours: 1));
      final now = DateTime.now();
      
      // Ne planifier que si la notification est dans le futur
      if (notificationTime.isAfter(now)) {
        await scheduleAppointmentNotification(
          appointmentId,
          'Rappel de rendez-vous',
          'Vous avez un rendez-vous dans 1 heure avec Dr. $doctorName',
          notificationTime,
        );
      }
    } catch (e) {
      // Ignorer les erreurs de planification (notamment celles liées au son)
      // Les notifications programmées fonctionneront même si le son personnalisé n'est pas disponible
      print('Erreur lors de la planification de la notification: $e');
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Replanifie toutes les notifications pour les rendez-vous existants
  /// À appeler au démarrage de l'application
  static Future<void> rescheduleAllAppointmentNotifications(
      List<Appointment> appointments) async {
    try {
      for (final appointment in appointments) {
        if (appointment.id != null) {
          try {
            await scheduleAppointmentReminder(
              appointment.id!,
              appointment.doctor.name,
              appointment.dateTime,
            );
          } catch (e) {
            // Ignorer les erreurs individuelles pour continuer avec les autres rendez-vous
            // Les erreurs sont déjà gérées dans scheduleAppointmentReminder
          }
        }
      }
    } catch (e) {
      // Ignorer les erreurs globales de replanification
      // Les notifications programmées fonctionneront même en cas d'erreur
    }
  }
}