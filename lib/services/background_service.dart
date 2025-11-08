import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'notification_service.dart';
import 'appointment_service.dart';

class BackgroundService {
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        autoStartOnBoot: true,
      ),
      iosConfiguration: IosConfiguration(
        onForeground: onStart,
        onBackground: onIosBackground,
        autoStart: true,
      ),
    );

    service.startService();
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    // Initialize notification service
    await NotificationService.initialize();

    // Check for upcoming appointments every 15 minutes
    Timer.periodic(const Duration(minutes: 15), (timer) async {
      await _checkUpcomingAppointments();
    });

    // Initial check
    await _checkUpcomingAppointments();
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  static Future<void> _checkUpcomingAppointments() async {
    try {
      final appointments = await AppointmentService.getAppointments();
      final now = DateTime.now();
      
      for (final appointment in appointments) {
        final appointmentTime = appointment.dateTime;
        final difference = appointmentTime.difference(now);
        
        // Show notification if appointment is in 1 hour
        if (difference.inMinutes == 60) {
          await NotificationService.showAppointmentNotification(
            'Rappel de rendez-vous',
            'Vous avez un rendez-vous dans 1 heure avec ${appointment.doctor.name}',
            appointment.id ?? 0,
          );
        }
        
        // Show notification if appointment is in 24 hours
        if (difference.inHours == 24) {
          await NotificationService.showAppointmentNotification(
            'Rappel de rendez-vous',
            'Vous avez un rendez-vous demain à ${appointment.dateTime.hour}:${appointment.dateTime.minute.toString().padLeft(2, '0')} avec ${appointment.doctor.name}',
            (appointment.id ?? 0) + 1000, // Different ID to avoid conflicts
          );
        }
      }
    } catch (e) {
      // Handle error silently in background
    }
  }
}