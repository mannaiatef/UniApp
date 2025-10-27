import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/DoctorViewScreen.dart';
import 'screens/doctor_screen.dart';
import 'screens/specialty_screen.dart';
import 'screens/DoctorFrontScreen.dart';

// Hive imports
import 'package:hive_flutter/hive_flutter.dart';
import 'models/doctor.dart';
import 'models/specialty.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(DoctorAdapter());
  Hive.registerAdapter(SpecialtyAdapter());

  // Open Hive boxes
  await Hive.openBox<Doctor>('doctors');
  await Hive.openBox<Specialty>('specialties');
  await Hive.openBox('settings');
  await Hive.openBox('cache');

  // Log Hive contents for debugging
  final doctorsBox = Hive.box<Doctor>('doctors');
  final specialtiesBox = Hive.box<Specialty>('specialties');
  print('Hive doctors on app start: ${doctorsBox.values.map((d) => "Doctor(id: ${d.id}, name: ${d.name}, email: ${d.email})").toList()}');
  print('Hive specialties on app start: ${specialtiesBox.values.map((s) => "Specialty(id: ${s.id}, name: ${s.name})").toList()}');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MedApp Admin',
      theme: ThemeData(
        primarySwatch: const MaterialColor(
          0xFF003087,
          <int, Color>{
            50: Color(0xFFE6F0FA),
            100: Color(0xFFB3CDE6),
            200: Color(0xFF80B3D1),
            300: Color(0xFF4D99BC),
            400: Color(0xFF1A7FA7),
            500: Color(0xFF003087),
            600: Color(0xFF002F7D),
            700: Color(0xFF00266D),
            800: Color(0xFF001E5D),
            900: Color(0xFF00144D),
          },
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          headlineSmall: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003087)),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MedApp Admin',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF003087),
        elevation: 4,
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF003087)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'MedApp Admin',
                      style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dashboard',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF003087)),
                title: Text('Doctor View', style: Theme.of(context).textTheme.bodyMedium),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DoctorViewScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF003087)),
                title: Text('Doctors', style: Theme.of(context).textTheme.bodyMedium),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DoctorScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.category, color: Color(0xFF003087)),
                title: Text('Specialties', style: Theme.of(context).textTheme.bodyMedium),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SpecialtyScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.public, color: Color(0xFF003087)),
                title: Text('Front Office', style: Theme.of(context).textTheme.bodyMedium),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DoctorFrontScreen()),
                  );
                },
              ),
              const Divider(color: Color(0xFF003087), thickness: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFF8B0000)),
                title: Text('Logout', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Color(0xFF8B0000))),
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logged out', style: TextStyle(color: Colors.white)),
                      backgroundColor: Color(0xFF8B0000),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: Container(
        color: Colors.grey[100],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.home, size: 60, color: Color(0xFF003087)),
              const SizedBox(height: 16),
              Text(
                'Select an option from the menu',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}