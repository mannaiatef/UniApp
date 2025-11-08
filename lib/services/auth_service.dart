import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient.dart';
import 'database_helper.dart';

class AuthService with ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool _isAuthenticated = false;
  String? _currentUserEmail;

  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserEmail => _currentUserEmail;

  AuthService() {
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      if (email != null && email.isNotEmpty) {
        _isAuthenticated = true;
        _currentUserEmail = email;
        print('Authentification vérifiée: $email');
        notifyListeners();
      } else {
        print('Aucun email trouvé dans SharedPreferences lors de la vérification');
      }
    } catch (e) {
      print('Erreur lors de la vérification de l\'authentification: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final isAuthenticated = await _databaseHelper.authenticatePatient(email, password);
      if (isAuthenticated) {
        _isAuthenticated = true;
        _currentUserEmail = email;
        
        // Sauvegarder l'état de connexion avec plus d'informations
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', email);
        
        // Récupérer et sauvegarder les informations du patient
        final patient = await _databaseHelper.getPatientByEmail(email);
        if (patient != null) {
          final fullName = '${patient.prenom} ${patient.nom}';
          await prefs.setString('user_name', fullName);
          if (patient.telephone != null) {
            await prefs.setString('user_phone', patient.telephone!);
          }
          if (patient.adresse != null) {
            await prefs.setString('user_address', patient.adresse!);
          }
          if (patient.photoUrl != null) {
            await prefs.setString('user_photo_url', patient.photoUrl!);
          }
        }
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur de connexion: $e');
      return false;
    }
  }
  
  Future<void> logout() async {
    try {
      // Supprimer l'état de connexion et toutes les informations du patient
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.remove('user_phone');
      await prefs.remove('user_address');
      await prefs.remove('user_photo_url');
      
      _isAuthenticated = false;
      _currentUserEmail = null;
      notifyListeners();
    } catch (e) {
      print('Erreur de déconnexion: $e');
    }
  }

  Future<bool> register(Patient patient) async {
    try {
      // Vérifier si l'email existe déjà
      final existingPatient = await _databaseHelper.getPatientByEmail(patient.email);
      if (existingPatient != null) {
        return false;
      }

      // Insérer le nouveau patient
      await _databaseHelper.insertPatient(patient);
      return true;
    } catch (e) {
      print('Erreur d\'inscription: $e');
      return false;
    }
  }
/*
  Future<void> logout() async {
    _isAuthenticated = false;
    _currentUserEmail = null;
    
    // Supprimer l'état de connexion
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    
    notifyListeners();
  }
*/
  Future<Patient?> getCurrentPatient() async {
    try {
      // Toujours vérifier SharedPreferences d'abord pour s'assurer d'avoir l'email le plus récent
      final prefs = await SharedPreferences.getInstance();
      String? emailToUse = prefs.getString('user_email');
      
      // Si pas d'email dans SharedPreferences, essayer _currentUserEmail
      if (emailToUse == null || emailToUse.isEmpty) {
        emailToUse = _currentUserEmail;
      }
      
      // Si toujours pas d'email, l'utilisateur n'est pas connecté
      if (emailToUse == null || emailToUse.isEmpty) {
        print('Aucun email trouvé - utilisateur non connecté');
        return null;
      }
      
      // Mettre à jour les variables d'instance pour être cohérent
      if (_currentUserEmail != emailToUse) {
        _currentUserEmail = emailToUse;
        _isAuthenticated = true;
        print('Email mis à jour: $emailToUse');
      }
      
      print('Recherche du patient avec l\'email: $emailToUse');
      final patient = await _databaseHelper.getPatientByEmail(emailToUse);
      
      if (patient != null) {
        print('Patient trouvé: ${patient.nom} ${patient.prenom}');
        // S'assurer que l'authentification est marquée comme vraie
        if (!_isAuthenticated) {
          _isAuthenticated = true;
          notifyListeners();
        }
      } else {
        print('Aucun patient trouvé dans la base de données pour: $emailToUse');
      }
      
      return patient;
    } catch (e) {
      print('Erreur dans getCurrentPatient: $e');
      return null;
    }
  }
  
  // Alias pour la compatibilité avec le code existant
  Future<Patient?> getCurrentUser() async {
    return getCurrentPatient();
  }
  
  Future<bool> updatePatient(Patient patient) async {
    try {
      // Vérifier que le patient existe
      final existingPatient = await _databaseHelper.getPatientByEmail(patient.email);
      if (existingPatient == null) {
        return false;
      }
      
      // Mettre à jour le patient dans la base de données
      await _databaseHelper.updatePatient(patient);
      
      // Mettre à jour les SharedPreferences avec les nouvelles informations
      final prefs = await SharedPreferences.getInstance();
      final fullName = '${patient.prenom} ${patient.nom}';
      await prefs.setString('user_name', fullName);
      if (patient.telephone != null) {
        await prefs.setString('user_phone', patient.telephone!);
      } else {
        await prefs.remove('user_phone');
      }
      if (patient.adresse != null) {
        await prefs.setString('user_address', patient.adresse!);
      } else {
        await prefs.remove('user_address');
      }
      if (patient.photoUrl != null) {
        await prefs.setString('user_photo_url', patient.photoUrl!);
      } else {
        await prefs.remove('user_photo_url');
      }
      
      // Mettre à jour l'email courant si nécessaire
      if (_currentUserEmail != patient.email) {
        _currentUserEmail = patient.email;
        await prefs.setString('user_email', patient.email);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Erreur de mise à jour du profil: $e');
      return false;
    }
  }
}