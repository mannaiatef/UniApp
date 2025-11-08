import 'dart:convert';
import 'package:http/http.dart' as http;

class MedicalChatService {
  static const String _apiKey = 'AIzaSyCfDNyCO7nxk70CRdGUMVD55UxjjOW-idc';
  // Google Gemini API endpoint
  static const String _apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  
  // Keywords that indicate health-related questions
  static const List<String> _healthKeywords = [
    'santé', 'symptôme', 'maladie', 'médicament', 'traitement', 'médecin',
    'docteur', 'mal', 'douleur', 'fièvre', 'toux', 'rhume', 'grippe',
    'allergie', 'migraine', 'maux', 'remède', 'soin', 'bien-être', 'santé',
    'cardiaque', 'pression', 'tension', 'diabète', 'asthme', 'infection',
    'vaccin', 'prévention', 'diagnostic', 'consultation', 'urgence', 'hôpital',
    'pharmacie', 'pilule', 'comprimé', 'prescription', 'analyse', 'examen',
    'thérapie', 'rééducation', 'récupération', 'guérison', 'cicatrisation',
    'brûlure', 'blessure', 'fracture', 'entorse', 'contusion', 'plaie',
    'nausée', 'vomissement', 'diarrhée', 'constipation', 'insomnie',
    'stress', 'anxiété', 'dépression', 'fatigue', 'vertige', 'étourdissement',
    'essoufflement', 'respiration', 'poumon', 'cœur', 'foie', 'rein',
    'articulation', 'muscle', 'os', 'peau', 'cheveux', 'ongle', 'dent',
    'vision', 'audition', 'goût', 'odorat', 'digestion', 'métabolisme',
    'cholestérol', 'vitamine', 'minéral', 'nutrition', 'régime', 'alimentation',
    'poids', 'obésité', 'minceur', 'sport', 'exercice', 'activité physique',
    'grossesse', 'accouchement', 'bébé', 'enfant', 'adolescent', 'adulte',
    'senior', 'vieillissement', 'ménopause', 'andropause', 'hormone',
    'médical', 'clinique', 'hospitalier', 'paramédical', 'infirmier',
    'sage-femme', 'kinésithérapeute', 'ostéopathe', 'chiropracteur',
  ];

  /// Check if the question is health-related
  bool isHealthRelated(String question) {
    final lowerQuestion = question.toLowerCase();
    return _healthKeywords.any((keyword) => lowerQuestion.contains(keyword));
  }

  /// Send a message to the Google Gemini API
  Future<String> sendMessage(String message) async {
    try {
      // Check if the question is health-related
      if (!isHealthRelated(message)) {
        return 'Je suis un assistant médical. Je ne peux répondre qu\'à des questions liées à la santé.';
      }

      // Prepare the system instruction and user message for Gemini
      final systemInstruction = 'Tu es un assistant médical professionnel et bienveillant. Réponds de manière claire, concise et rassurante aux questions de santé. Réponds toujours en français de manière professionnelle et accessible. Si la question concerne des symptômes graves, conseille de consulter un médecin.';
      
      final userMessage = 'Question: $message\n\nRéponds de manière professionnelle et accessible.';

      // Prepare the request body for Gemini API
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': '$systemInstruction\n\n$userMessage'}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          }
        ]
      };

      // Make the API request to Gemini
      final uri = Uri.parse('$_apiUrl?key=$_apiKey');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: La requête a pris trop de temps');
        },
      );

      // Log the response for debugging
      print('Gemini API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          
          // Check for errors in the response
          if (responseData.containsKey('error')) {
            final error = responseData['error'];
            print('Gemini API Error: $error');
            return 'Erreur de l\'API: ${error['message'] ?? 'Erreur inconnue'}. Veuillez réessayer.';
          }
          
          // Extract the generated text from Gemini response
          if (responseData.containsKey('candidates') && 
              responseData['candidates'] is List &&
              responseData['candidates'].isNotEmpty) {
            final candidate = responseData['candidates'][0];
            
            // Check if the response was blocked by safety settings
            if (candidate.containsKey('finishReason') && 
                candidate['finishReason'] == 'SAFETY') {
              return 'Désolé, je ne peux pas répondre à cette question pour des raisons de sécurité. Veuillez reformuler votre question ou consulter un professionnel de la santé.';
            }
            
            if (candidate.containsKey('content') && 
                candidate['content'].containsKey('parts')) {
              final parts = candidate['content']['parts'];
              if (parts is List && parts.isNotEmpty) {
                final text = parts[0]['text']?.toString() ?? '';
                if (text.isNotEmpty) {
                  // Clean up the response
                  String cleanedText = text.trim();
                  
                  // Remove the system instruction if present
                  if (cleanedText.contains(systemInstruction)) {
                    cleanedText = cleanedText.replaceAll(systemInstruction, '').trim();
                  }
                  
                  if (cleanedText.isEmpty || cleanedText.length < 10) {
                    return 'Je comprends votre question. Pour une réponse plus précise, je vous recommande de consulter un professionnel de la santé qui pourra évaluer votre situation spécifique.';
                  }
                  
                  return cleanedText;
                }
              }
            }
          }
          
          // If we get here, the response format is unexpected
          print('Unexpected Gemini response format: $responseData');
          return 'Je comprends votre question. Pour une réponse plus précise, je vous recommande de consulter un professionnel de la santé.';
        } catch (e) {
          print('Error parsing Gemini response: $e');
          return 'Je comprends votre question. Pour une réponse plus précise, je vous recommande de consulter un professionnel de la santé.';
        }
      } else if (response.statusCode == 400) {
        // Bad request
        try {
          final errorData = jsonDecode(response.body);
          final error = errorData['error'] ?? {};
          final message = error['message']?.toString() ?? 'Requête invalide';
          print('Gemini API 400 Error: $message');
          return 'Erreur de requête: $message. Veuillez réessayer.';
        } catch (e) {
          return 'Erreur de requête. Veuillez réessayer.';
        }
      } else if (response.statusCode == 401) {
        // Unauthorized - API key issue
        return 'Erreur d\'authentification avec l\'API. Veuillez contacter le support.';
      } else if (response.statusCode == 403) {
        // Forbidden - API key may not have access
        return 'Accès refusé à l\'API. Veuillez vérifier la configuration ou contacter le support.';
      } else if (response.statusCode == 429) {
        // Rate limit exceeded
        return 'Trop de requêtes. Veuillez attendre un moment avant de réessayer.';
      } else if (response.statusCode == 500 || response.statusCode == 503) {
        // Server error
        return 'Le service est temporairement indisponible. Veuillez réessayer dans quelques instants.';
      } else {
        // Other errors
        print('Gemini API Error: Status ${response.statusCode}, Body: ${response.body}');
        return 'Erreur de connexion à l\'API (Code: ${response.statusCode}). Veuillez réessayer plus tard.';
      }
    } catch (e, stackTrace) {
      print('Exception in sendMessage: $e');
      print('Stack trace: $stackTrace');
      if (e.toString().contains('Timeout') || e.toString().contains('timeout')) {
        return 'La requête a pris trop de temps. Veuillez réessayer.';
      } else if (e.toString().contains('SocketException') || e.toString().contains('Network')) {
        return 'Problème de connexion réseau. Vérifiez votre connexion Internet et réessayez.';
      }
      return 'Erreur de connexion à l\'API. Veuillez réessayer plus tard.';
    }
  }
}
