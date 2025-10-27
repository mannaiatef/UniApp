import 'dart:developer' as developer;

import 'package:hive/hive.dart';

part 'specialty.g.dart';

@HiveType(typeId: 1)
class Specialty {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final String? videoUrl;

  Specialty({
    required this.id,
    required this.name,
    this.description,
    this.videoUrl,
  });

  factory Specialty.fromMap(Map<String, dynamic> map, String id) {
    try {
      return Specialty(
        id: id,
        name: (map['name']?.toString() ?? 'Unknown'), // Handle int or null
        description: map['description']?.toString(), // Handle int or null
        videoUrl: map['videoUrl']?.toString(), // Handle int or null
      );
    } catch (e, stackTrace) {
      developer.log('Error parsing Specialty from map: $e, map: $map, stackTrace: $stackTrace',
          name: 'Specialty');
      return Specialty(id: id, name: 'Unknown');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'videoUrl': videoUrl,
    };
  }

  @override
  String toString() {
    return 'Specialty(id: $id, name: $name, description: $description, videoUrl: $videoUrl)';
  }
}