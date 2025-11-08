import 'package:shared_preferences/shared_preferences.dart';

class VideoConsultationService {
  // Vérifier si un patient est connecté
  static Future<bool> isPatientLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('user_email');
  }
  
  // Récupérer le nom du patient connecté
  static Future<String> getCurrentPatientName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name') ?? 'Patient';
  }
  
  // Récupérer l'email du patient connecté
  static Future<String> getCurrentPatientEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email') ?? '';
  }

  // Créer un ID unique pour la consultation
  static String generateConsultationId(String doctorName, String patientName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'consult_${doctorName.replaceAll(' ', '_')}_${patientName.replaceAll(' ', '_')}_$timestamp';
  }

  // Configuration Agora (à remplacer par vos vraies clés)
  static const String agoraAppId = "YOUR_AGORA_APP_ID";
  
  // Fonction pour obtenir un token Agora (à implémenter avec votre backend)
  static Future<String?> getAgoraToken(String channelName) async {
    // Ici vous devriez appeler votre backend pour obtenir un token
    // Pour le moment, retournons null pour utiliser le mode testing
    return null;
  }
}