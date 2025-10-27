import 'package:hive/hive.dart';

part 'doctor.g.dart';

@HiveType(typeId: 0)
class Doctor extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String email;

  @HiveField(3)
  String? phone;

  @HiveField(4)
  String? address;

  @HiveField(5)
  String? photoUrl;

  @HiveField(6)
  String specialtyId;

  @HiveField(7)
  double? latitude;

  @HiveField(8)
  double? longitude;

  @HiveField(9)
  String? biography;

  @HiveField(10)
  String? website;

  @HiveField(11)
  String? facebookUrl;

  @HiveField(12)
  String? twitterUrl;

  // For reviews, we store as List<String> (JSON-encoded) or List<Map> using HiveTypeConverter
  @HiveField(13)
  List<Map<String, dynamic>>? reviews;

  @HiveField(14)
  String? status;

  @HiveField(15)
  Map<String, List<String>>? schedule;

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
    this.schedule,
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
      reviews: (map['reviews'] as List<dynamic>?)?.map((item) => Map<String, dynamic>.from(item)).toList(),
      status: map['status'] ?? 'Available',
      schedule: (map['schedule'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as List<dynamic>?)?.cast<String>() ?? []),
      ),
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
      'schedule': schedule,
    };
  }
}

extension DoctorCopyWith on Doctor {
  Doctor copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? photoUrl,
    String? specialtyId,
    double? latitude,
    double? longitude,
    String? biography,
    String? website,
    String? facebookUrl,
    String? twitterUrl,
    List<Map<String, dynamic>>? reviews,
    String? status,
    Map<String, List<String>>? schedule,
  }) {
    return Doctor(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
      specialtyId: specialtyId ?? this.specialtyId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      biography: biography ?? this.biography,
      website: website ?? this.website,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      twitterUrl: twitterUrl ?? this.twitterUrl,
      reviews: reviews ?? this.reviews,
      status: status ?? this.status,
      schedule: schedule ?? this.schedule,
    );
  }
}