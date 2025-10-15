class Doctor {
  String id;
  String name;
  String email;
  String specialtyId;
  String? photoUrl;
  String? phone;
  String? address;
  String? biography;
  double? latitude;
  double? longitude;
  String? website; // New field
  String? facebookUrl; // Optional
  String? twitterUrl; // Optional

  Doctor({
    required this.id,
    required this.name,
    required this.email,
    required this.specialtyId,
    this.photoUrl,
    this.phone,
    this.address,
    this.biography,
    this.latitude,
    this.longitude,
    this.website,
    this.facebookUrl,
    this.twitterUrl,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'specialtyId': specialtyId,
    'photoUrl': photoUrl,
    'phone': phone,
    'address': address,
    'biography': biography,
    'latitude': latitude,
    'longitude': longitude,
    'website': website,
    'facebookUrl': facebookUrl,
    'twitterUrl': twitterUrl,
  };

  factory Doctor.fromMap(Map<String, dynamic> map, String id) => Doctor(
    id: id,
    name: map['name'],
    email: map['email'],
    specialtyId: map['specialtyId'],
    photoUrl: map['photoUrl'],
    phone: map['phone'],
    address: map['address'],
    biography: map['biography'],
    latitude: map['latitude']?.toDouble(),
    longitude: map['longitude']?.toDouble(),
    website: map['website'],
    facebookUrl: map['facebookUrl'],
    twitterUrl: map['twitterUrl'],
  );
}