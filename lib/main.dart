import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
// import 'services/background_service.dart'; // Disabled for Android 14+ compatibility
import 'services/appointment_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/doctor_list_screen.dart';
import 'screens/appointments_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service with error handling
  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('Erreur lors de l\'initialisation du service de notifications: $e');
  }
  
  // Initialize background service with error handling
  // Note: BackgroundService is disabled for Android 14+ (API 36) compatibility
  // Notifications are handled by NotificationService with scheduled notifications
  /*
  try {
    await BackgroundService.initialize();
  } catch (e) {
    debugPrint('Erreur lors de l\'initialisation du service d\'arrière-plan: $e');
  }
  */
  
  // Replanifier les notifications pour les rendez-vous existants
  try {
    final appointments = await AppointmentService.getAppointments();
    await NotificationService.rescheduleAllAppointmentNotifications(appointments);
  } catch (e) {
    debugPrint('Erreur lors de la replanification des notifications: $e');
  }
  
  // Run the app even if initialization errors occurred
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Application Patient',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Add error handling for the app
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: Consumer<AuthService>(
        builder: (context, authService, _) {
          try {
            return authService.isAuthenticated
                ? const HomeScreen()
                : const LoginScreen();
          } catch (e) {
            debugPrint('Error building home screen: $e');
            return const LoginScreen();
          }
        },
      ),
      routes: {
        '/doctors': (context) => const DoctorListScreen(),
        '/appointments': (context) => const AppointmentsScreen(),
      },
    );
  }
}
