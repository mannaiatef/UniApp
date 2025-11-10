class Medicine {
  String id;
  String name;
  String dosage;
  String description;

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.description,
  });

  // Convertir un objet Medicine en Map (pour Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'description': description,
    };
  }

  // Créer un objet Medicine à partir d’un document Firestore
  factory Medicine.fromMap(String id, Map<String, dynamic> data) {
    return Medicine(
      id: id,
      name: data['name'] ?? '',
      dosage: data['dosage'] ?? '',
      description: data['description'] ?? '',
    );
  }
}
