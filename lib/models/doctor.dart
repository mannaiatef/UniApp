class Doctor {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? photoUrl;
  final String specialtyId;
  final double? latitude;
  final double? longitude;
  final String? biography;
  final String? website;
  final String? facebookUrl;
  final String? twitterUrl;
  final List<Map<String, dynamic>>? reviews; // New field for reviews
  final String? status;

  Doctor({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.photoUrl,
    required this.specialtyId,
    this.latitude,
    this.longitude,
    this.biography,
    this.website,
    this.facebookUrl,
    this.twitterUrl,
    this.reviews,
    this.status,
  });

  factory Doctor.fromMap(Map<String, dynamic> map, String id) {
    return Doctor(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      address: map['address'],
      photoUrl: map['photoUrl'],
      specialtyId: map['specialtyId'] ?? '',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      biography: map['biography'],
      website: map['website'],
      facebookUrl: map['facebookUrl'],
      twitterUrl: map['twitterUrl'],
      reviews: (map['reviews'] as List<dynamic>?)?.map((item) => item as Map<String, dynamic>).toList(),
      status: map['status'] ?? 'Available',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'photoUrl': photoUrl,
      'specialtyId': specialtyId,
      'latitude': latitude,
      'longitude': longitude,
      'biography': biography,
      'website': website,
      'facebookUrl': facebookUrl,
      'twitterUrl': twitterUrl,
      'reviews': reviews,
      'status': status,
    };
  }
}