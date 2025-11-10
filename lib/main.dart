// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/prescription_list.dart';
import 'firebase_options.dart'; // ✅ important : auto-généré par FlutterFire CLI

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialise Firebase AVANT de lancer l’app
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MedAssist',

      // ✅ Support FR et EN pour les pickers
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('fr', 'FR'),

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF006AF6),
      ),

      home: const PrescriptionListScreen(),
    );
  }
}
