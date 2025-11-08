class Patient {
  final int? id;
  final String nom;
  final String prenom;
  final String email;
  final String motDePasse;
  final String? telephone;
  final String? adresse;
  final String? photoUrl;

  Patient({
    this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.motDePasse,
    this.telephone,
    this.adresse,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'motDePasse': motDePasse,
      'telephone': telephone,
      'adresse': adresse,
      'photoUrl': photoUrl,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      nom: map['nom'],
      prenom: map['prenom'],
      email: map['email'],
      motDePasse: map['motDePasse'],
      telephone: map['telephone'],
      adresse: map['adresse'],
      photoUrl: map['photoUrl'],
    );
  }

  Patient copyWith({
    int? id,
    String? nom,
    String? prenom,
    String? email,
    String? motDePasse,
    String? telephone,
    String? adresse,
    String? photoUrl,
  }) {
    return Patient(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      motDePasse: motDePasse ?? this.motDePasse,
      telephone: telephone ?? this.telephone,
      adresse: adresse ?? this.adresse,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}