import 'dart:convert';
import 'package:http/http.dart' as http;

class DrugEffectsService {
  // Base de données locale avec effets secondaires courants (étendue)
  static final Map<String, String> _localEffectsDatabase = {
    // Analgésiques
    'paracétamol': '• Nausées légères\n• Réactions allergiques (rare)\n• Troubles hépatiques en cas de surdosage\n• Éruption cutanée (rare)\n\nCes informations sont indicatives et ne remplacent pas un avis médical.',
    'doliprane': '• Nausées légères\n• Réactions allergiques (rare)\n• Troubles hépatiques en cas de surdosage\n• Éruption cutanée (rare)\n\nCes informations sont indicatives et ne remplacent pas un avis médical.',
    'dafalgan': '• Nausées légères\n• Réactions allergiques (rare)\n• Troubles hépatiques en cas de surdosage\n\nCes informations sont indicatives et ne remplacent pas un avis médical.',
    'efferalgan': '• Nausées légères\n• Réactions allergiques (rare)\n• Troubles hépatiques en cas de surdosage\n\nCes informations sont indicatives et ne remplacent pas un avis médical.',
    
    // Anti-inflammatoires
    'ibuprofene': '• Douleurs gastriques\n• Nausées et vomissements\n• Maux de tête\n• Vertiges\n• Troubles digestifs\n• Ulcères gastriques (à forte dose)\n\nCes informations sont indicatives et ne remplacent pas un avis médical.',
    'advil': '• Douleurs gastriques\n• Nausées et vomissements\n• Maux de tête\n• Vertiges\n• Troubles digestifs\n\nCes informations sont indicatives et ne remplacent pas un avis médical.',
    'nurofen': '• Douleurs gastriques\n• Nausées et vomissements\n• Maux de tête\n• Vertiges\n• Troubles digestifs\n\nCes informations sont indicatives et ne remplacent pas un avis médical.',
    'aspirine': '• Irritation gastrique\n• Saignements\n• Réactions allergiques\n• Acouphènes (à forte dose)\n• Nausées\n\nCes informations sont indicatives et ne remplacent pas un avis médical.',
    
    // Antibiotiques
    'amoxicilline': '• Diarrhée\n• Nausées\n• Éruptions cutanées\n• Réactions allergiques\n• Troubles digestifs\n• Candidose (rare)\n\nCes informations sont indicatives et ne remplacent pas un avis médical.',
    'amoxicillin': '• Diarrhée\n• Nausées\n• Éruptions cutanées\n• Réactions allergiques\n• Troubles digestifs\n• Candidose (rare)\n\nCes informations sont indicatives et ne remplacent pas un avis médical.',
    'augmentin': '• Diarrhée\n• Nausées\n• Éruptions cutanées\n• Réactions allergiques\n• Troubles digestifs\n\nCes informations sont indicatives et ne remplacent pas un avis médical.',
    
    // Antispasmodiques
    'spasfon': '• Sécheresse de la bouche\n• Constipation\n• Troubles de la vision\n• Somnolence\n• Vertiges\n\nCes informations sont indicatives et ne remplacent pas un avis médical.',
    'spasfon lyoc': '• Sécheresse de la bouche\n• Constipation\n• Troubles de la vision\n• Somnolence\n\nCes informations sont indicatives et ne remplacent pas un avis médical.',
    
    // Autres médicaments courants
    'ferrostrane': '• Constipation\n• Coloration noire des selles\n• Nausées\n• Douleurs abdominales\n\nCes informations sont indicatives et ne remplacent pas un avis médical.',
    'smecta': '• Constipation (rare)\n• Ballonnements\n\nCes informations sont indicatives et ne remplacent pas un avis médical.',
  };

  // Méthode principale pour récupérer les effets secondaires
  Future<String> fetchSideEffects(String medicineName) async {
    if (medicineName.isEmpty) {
      return _getDefaultMessage();
    }

    // Normaliser le nom du médicament (minuscules, sans accents pour la recherche)
    final normalizedName = _normalizeMedicineName(medicineName);

    // 1. Vérifier d'abord la base de données locale (recherche exacte et partielle)
    final localEffect = _searchLocalDatabase(normalizedName);
    if (localEffect != null) {
      print("✅ [Local DB] Effets trouvés pour $medicineName");
      return localEffect;
    }

    // 2. Essayer l'API externe (OpenFDA avec plusieurs stratégies)
    try {
      final apiEffect = await _fetchFromAPI(medicineName, normalizedName);
      if (apiEffect.isNotEmpty && !apiEffect.contains('Erreur') && !apiEffect.contains('n\'ont pas pu')) {
        print("✅ [API] Effets récupérés pour $medicineName");
        return apiEffect;
      }
    } catch (e) {
      print("⚠️ [API] Erreur lors de l'appel API : $e");
    }

    // 3. Fallback : message générique
    return _getGenericEffects(medicineName);
  }

  // Normaliser le nom du médicament pour la recherche
  String _normalizeMedicineName(String name) {
    if (name.isEmpty) return '';
    
    // Convertir en minuscules et supprimer les espaces multiples
    String normalized = name.toLowerCase().trim();
    
    // Remplacer les accents
    normalized = normalized
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[ñ]'), 'n');
    
    // Normaliser certains termes courants de médicaments français
    normalized = normalized
        .replaceAll(RegExp(r'\bcomprimes?\b'), '')
        .replaceAll(RegExp(r'\bcapsules?\b'), '')
        .replaceAll(RegExp(r'\bgélules?\b'), '')
        .replaceAll(RegExp(r'\bsirop\b'), '')
        .replaceAll(RegExp(r'\bsuspension\b'), '')
        .replaceAll(RegExp(r'\bmg\b'), '')
        .replaceAll(RegExp(r'\bg\b'), '');
    
    // Supprimer les caractères spéciaux mais garder les espaces
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9\s]'), '');
    
    // Supprimer les espaces multiples
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return normalized;
  }

  // Rechercher dans la base de données locale avec correspondance partielle
  String? _searchLocalDatabase(String normalizedName) {
    // Recherche exacte
    if (_localEffectsDatabase.containsKey(normalizedName)) {
      return _localEffectsDatabase[normalizedName];
    }
    
    // Recherche partielle (contient)
    for (var entry in _localEffectsDatabase.entries) {
      if (normalizedName.contains(entry.key) || entry.key.contains(normalizedName)) {
        return entry.value;
      }
    }
    
    // Recherche par mots-clés communs
    final keywords = normalizedName.split(' ');
    for (var keyword in keywords) {
      if (keyword.length > 3) { // Ignorer les mots trop courts
        for (var entry in _localEffectsDatabase.entries) {
          if (entry.key.contains(keyword)) {
            return entry.value;
          }
        }
      }
    }
    
    return null;
  }

  // Essayer de récupérer depuis une API externe (OpenFDA avec plusieurs stratégies)
  Future<String> _fetchFromAPI(String medicineName, String normalizedName) async {
    // Extraire les mots significatifs (ignorer les mots trop courts)
    final words = normalizedName.split(' ').where((w) => w.length >= 3).toList();
    if (words.isEmpty) return '';

    // Stratégie 1: Recherche par nom de marque (brand_name) - recherche exacte puis partielle
    try {
      // Essayer d'abord avec le nom complet (sans caractères spéciaux)
      final cleanName = normalizedName.replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (cleanName.length >= 4) {
        final url1a = 'https://api.fda.gov/drug/label.json?search=openfda.brand_name:"$cleanName"&limit=3';
        final result1a = await _tryOpenFDASearch(url1a, medicineName);
        if (result1a.isNotEmpty) return result1a;
      }
      
      // Ensuite avec le premier mot significatif
      final firstWord = words.first;
      if (firstWord.length >= 3) {
        final url1b = 'https://api.fda.gov/drug/label.json?search=openfda.brand_name:$firstWord&limit=5';
        final result1b = await _tryOpenFDASearch(url1b, medicineName);
        if (result1b.isNotEmpty) return result1b;
      }
    } catch (e) {
      print("⚠️ [API] Stratégie 1 échouée : $e");
    }

    // Stratégie 2: Recherche par nom générique (generic_name) - utile pour les médicaments internationaux
    try {
      for (var word in words.take(2)) { // Essayer avec les 2 premiers mots
        if (word.length >= 4) {
          final url2 = 'https://api.fda.gov/drug/label.json?search=openfda.generic_name:$word&limit=5';
          final result2 = await _tryOpenFDASearch(url2, medicineName);
          if (result2.isNotEmpty) return result2;
        }
      }
    } catch (e) {
      print("⚠️ [API] Stratégie 2 échouée : $e");
    }

    // Stratégie 3: Recherche dans les indications (plus large, peut trouver des résultats même si le nom exact ne correspond pas)
    try {
      final firstWord = words.first;
      if (firstWord.length >= 4) {
        // Recherche dans les descriptions de produit
        final url3 = 'https://api.fda.gov/drug/label.json?search=description:$firstWord&limit=3';
        final result3 = await _tryOpenFDASearch(url3, medicineName);
        if (result3.isNotEmpty) return result3;
      }
    } catch (e) {
      print("⚠️ [API] Stratégie 3 échouée : $e");
    }

    return '';
  }

  // Méthode helper pour essayer une recherche OpenFDA
  Future<String> _tryOpenFDASearch(String url, String medicineName) async {
    try {
      print("🌐 [API] Tentative: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'MedAssist-App/1.0',
        },
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw Exception('Timeout de la requête API');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['results'] != null && data['results'] is List && (data['results'] as List).isNotEmpty) {
          // Normaliser le nom recherché pour la comparaison
          final searchNormalized = _normalizeMedicineName(medicineName);
          final searchWords = searchNormalized.split(' ').where((w) => w.length >= 3).toList();
          
          // Parcourir tous les résultats pour trouver le meilleur match
          for (var result in data['results']) {
            // Vérifier si le résultat correspond au médicament recherché
            final openfda = result['openfda'];
            bool isRelevant = false;
            
            if (openfda != null && openfda is Map) {
              // Convertir en Map<String, dynamic> pour éviter les erreurs de type
              final openfdaMap = Map<String, dynamic>.from(openfda);
              // Vérifier dans les noms de marque
              final brandNames = _extractFieldList(openfdaMap, 'brand_name');
              final genericNames = _extractFieldList(openfdaMap, 'generic_name');
              
              for (var brand in brandNames) {
                final brandNormalized = _normalizeMedicineName(brand);
                if (_isNameMatch(brandNormalized, searchNormalized, searchWords)) {
                  isRelevant = true;
                  break;
                }
              }
              
              // Vérifier dans les noms génériques si pas encore trouvé
              if (!isRelevant) {
                for (var generic in genericNames) {
                  final genericNormalized = _normalizeMedicineName(generic);
                  if (_isNameMatch(genericNormalized, searchNormalized, searchWords)) {
                    isRelevant = true;
                    break;
                  }
                }
              }
            }
            
            // Si on n'a pas trouvé de correspondance exacte mais qu'on a des résultats, on les accepte quand même
            // (utile pour les recherches par description)
            if (!isRelevant && searchWords.isNotEmpty) {
              isRelevant = true; // Accepter le résultat par défaut si on a des mots de recherche
            }
            
            if (isRelevant) {
              final adverseReactions = _extractField(result, 'adverse_reactions');
              final warnings = _extractField(result, 'warnings');
              final precautions = _extractField(result, 'precautions');
              final drugInteractions = _extractField(result, 'drug_interactions');

              if (adverseReactions.isNotEmpty || warnings.isNotEmpty || precautions.isNotEmpty) {
                String effects = '';
                
                if (warnings.isNotEmpty) {
                  effects += '⚠️ Avertissements :\n${_cleanText(warnings)}\n\n';
                }
                
                if (precautions.isNotEmpty) {
                  effects += '📋 Précautions :\n${_cleanText(precautions)}\n\n';
                }
                
                if (adverseReactions.isNotEmpty) {
                  effects += '⚕️ Effets secondaires :\n${_cleanText(adverseReactions)}\n\n';
                }
                
                if (drugInteractions.isNotEmpty) {
                  effects += '🔗 Interactions médicamenteuses :\n${_cleanText(drugInteractions)}\n\n';
                }
                
                effects += 'Ces informations sont indicatives et ne remplacent pas un avis médical.';
                
                // Limiter la longueur pour éviter des textes trop longs
                if (effects.length > 2000) {
                  effects = '${effects.substring(0, 2000)}...\n\nCes informations sont indicatives et ne remplacent pas un avis médical.';
                }
                
                return effects;
              }
            }
          }
        } else if (data['error'] != null) {
          final errorMsg = data['error'] is Map ? data['error']['message'] : data['error'].toString();
          print("⚠️ [API] Erreur OpenFDA: $errorMsg");
        } else if (data['meta'] != null && data['meta']['results'] != null && data['meta']['results']['total'] == 0) {
          print("⚠️ [API] Aucun résultat trouvé pour $medicineName");
        }
      } else if (response.statusCode == 404) {
        print("⚠️ [API] Médicament non trouvé (404)");
      } else if (response.statusCode == 429) {
        print("⚠️ [API] Trop de requêtes (429) - Rate limit atteint");
      } else if (response.statusCode >= 500) {
        print("⚠️ [API] Erreur serveur (${response.statusCode})");
      } else {
        final errorPreview = response.body.length > 100 
            ? response.body.substring(0, 100) 
            : response.body;
        print("⚠️ [API] Erreur HTTP ${response.statusCode}: $errorPreview");
      }
    } catch (e) {
      if (e.toString().contains('Timeout')) {
        print("⏱️ [API] Timeout pour $medicineName");
      } else {
        print("❌ [API] Exception : $e");
      }
    }

    return '';
  }

  // Extraire un champ du résultat (peut être une liste ou une string)
  String _extractField(Map<String, dynamic> result, String fieldName) {
    try {
      final value = result[fieldName];
      if (value == null) return '';
      
      if (value is List) {
        return value.map((e) => e.toString()).join('\n');
      } else if (value is String) {
        return value;
      } else {
        return value.toString();
      }
    } catch (e) {
      return '';
    }
  }

  // Extraire une liste de strings d'un champ
  List<String> _extractFieldList(Map<String, dynamic> result, String fieldName) {
    try {
      final value = result[fieldName];
      if (value == null) return [];
      
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      } else if (value is String) {
        return [value];
      } else {
        return [value.toString()];
      }
    } catch (e) {
      return [];
    }
  }

  // Vérifier si deux noms de médicaments correspondent
  bool _isNameMatch(String name1, String name2, List<String> searchWords) {
    if (name1.isEmpty || name2.isEmpty) return false;
    
    // Correspondance exacte (après normalisation)
    if (name1 == name2) return true;
    
    // Vérifier si un nom contient l'autre
    if (name1.contains(name2) || name2.contains(name1)) return true;
    
    // Vérifier si au moins un mot de recherche est présent
    if (searchWords.isNotEmpty) {
      for (var word in searchWords) {
        if (name1.contains(word) || name2.contains(word)) {
          return true;
        }
      }
    }
    
    // Vérifier la similarité par mots (au moins 50% des mots en commun)
    final words1 = name1.split(' ').where((w) => w.length >= 3).toSet();
    final words2 = name2.split(' ').where((w) => w.length >= 3).toSet();
    
    if (words1.isNotEmpty && words2.isNotEmpty) {
      final commonWords = words1.intersection(words2);
      final minLength = words1.length < words2.length ? words1.length : words2.length;
      if (minLength > 0 && commonWords.length >= (minLength / 2).ceil()) {
        return true;
      }
    }
    
    return false;
  }

  // Nettoyer le texte (supprimer les balises HTML, limiter la longueur des lignes)
  String _cleanText(String text) {
    if (text.isEmpty) return '';
    
    // Supprimer les balises HTML simples
    String cleaned = text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    // Limiter la longueur de chaque ligne
    final lines = cleaned.split('\n');
    final limitedLines = lines.take(20).map((line) {
      if (line.length > 150) {
        return '${line.substring(0, 147)}...';
      }
      return line;
    }).toList();
    
    return limitedLines.join('\n');
  }

  // Message générique si aucun effet n'est trouvé
  String _getGenericEffects(String medicineName) {
    return '⚕️ Effets secondaires possibles :\n'
        '• Consultez la notice du médicament pour les effets secondaires spécifiques\n'
        '• Réactions allergiques possibles\n'
        '• Troubles digestifs (nausées, diarrhée) possibles\n'
        '• En cas d\'effet indésirable, consultez votre médecin ou pharmacien\n\n'
        '⚠️ Ces informations sont données à titre indicatif et ne remplacent pas un avis médical.\n'
        'Pour des informations détaillées sur $medicineName, consultez la notice ou votre professionnel de santé.';
  }

  // Message par défaut
  String _getDefaultMessage() {
    return '⚕️ Aucun nom de médicament fourni.\n'
        'Consultez la notice du médicament ou votre médecin pour les effets secondaires.';
  }
}
