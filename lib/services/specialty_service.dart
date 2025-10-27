import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/specialty.dart';
import 'dart:developer' as developer;

class SpecialtyService {
  final CollectionReference specialtiesRef = FirebaseFirestore.instance.collection('specialties');
  final Box<Specialty> specialtiesBox = Hive.box<Specialty>('specialties');

  // Get cached specialties from Hive
  List<Specialty> getCachedSpecialties() {
    final specialties = specialtiesBox.values.toList();
    developer.log('Cached specialties: ${specialties.map((s) => s.toString()).toList()}',
        name: 'SpecialtyService');
    return specialties;
  }

  // Get Firestore specialties stream
  Stream<List<Specialty>> getSpecialtiesStream() {
    return specialtiesRef.snapshots().map((snapshot) {
      final specialties = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        developer.log('Firestore doc: ${doc.id}, data: $data', name: 'SpecialtyService');
        try {
          return Specialty.fromMap(data, doc.id);
        } catch (e, stackTrace) {
          developer.log('Error parsing Firestore doc: ${doc.id}, error: $e, stackTrace: $stackTrace',
              name: 'SpecialtyService');
          return Specialty(id: doc.id, name: 'Unknown');
        }
      }).toList();
      developer.log('Firestore specialties: ${specialties.map((s) => s.toString()).toList()}',
          name: 'SpecialtyService');
      return specialties;
    });
  }

  // Validate YouTube URL
  bool _isValidYouTubeUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final videoId = YoutubePlayer.convertUrlToId(url);
      final isValid = videoId != null && videoId.isNotEmpty;
      developer.log('Validating YouTube URL: $url, valid: $isValid', name: 'SpecialtyService');
      return isValid;
    } catch (e, stackTrace) {
      developer.log('Invalid YouTube URL: $url, error: $e, stackTrace: $stackTrace', name: 'SpecialtyService');
      return false;
    }
  }

  // Add or update specialty with deduplication
  Future<void> addSpecialty(Specialty specialty) async {
    try {
      // Validate videoUrl
      if (specialty.videoUrl != null && !_isValidYouTubeUrl(specialty.videoUrl)) {
        developer.log('Invalid videoUrl for specialty ${specialty.name}: ${specialty.videoUrl}', name: 'SpecialtyService');
        return; // Skip adding invalid URL
      }

      // Check for duplicates by name
      final snapshot = await specialtiesRef.where('name', isEqualTo: specialty.name).get();
      if (snapshot.docs.isNotEmpty) {
        final existingId = snapshot.docs.first.id;
        final specialtyToSave = specialty.copyWith(id: existingId);
        await updateSpecialty(specialtyToSave);
        return;
      }

      final specialtyId = specialty.id.isEmpty ? specialtiesRef.doc().id : specialty.id;
      final specialtyToSave = specialty.copyWith(id: specialtyId);
      await specialtiesBox.put(specialtyToSave.id, specialtyToSave);
      developer.log('Added to Hive: ${specialtyToSave.toString()}', name: 'SpecialtyService');
      await specialtiesRef.doc(specialtyToSave.id).set(specialtyToSave.toMap());
    } catch (e, stackTrace) {
      developer.log('Firebase add error: $e, stackTrace: $stackTrace', name: 'SpecialtyService');
    }
  }

  // Update specialty
  Future<void> updateSpecialty(Specialty specialty) async {
    try {
      // Validate videoUrl
      if (specialty.videoUrl != null && !_isValidYouTubeUrl(specialty.videoUrl)) {
        developer.log('Invalid videoUrl for specialty ${specialty.name}: ${specialty.videoUrl}', name: 'SpecialtyService');
        return; // Skip updating invalid URL
      }

      await specialtiesBox.put(specialty.id, specialty);
      developer.log('Updated in Hive: ${specialty.toString()}', name: 'SpecialtyService');
      await specialtiesRef.doc(specialty.id).set(specialty.toMap());
    } catch (e, stackTrace) {
      developer.log('Firebase update error: $e, stackTrace: $stackTrace', name: 'SpecialtyService');
    }
  }

  // Delete specialty
  Future<void> deleteSpecialty(String id) async {
    try {
      await specialtiesBox.delete(id);
      developer.log('Deleted from Hive: $id', name: 'SpecialtyService');
      await specialtiesRef.doc(id).delete();
    } catch (e, stackTrace) {
      developer.log('Firebase delete error: $e, stackTrace: $stackTrace', name: 'SpecialtyService');
    }
  }

  // Sync Hive with Firestore
  Future<void> syncWithFirebase() async {
    try {
      final localSpecialties = getCachedSpecialties();
      for (var specialty in localSpecialties) {
        if (specialty.videoUrl != null && !_isValidYouTubeUrl(specialty.videoUrl)) {
          developer.log('Skipping sync for invalid videoUrl: ${specialty.toString()}', name: 'SpecialtyService');
          continue;
        }
        await addSpecialty(specialty);
        developer.log('Synced specialty: ${specialty.toString()}', name: 'SpecialtyService');
      }
      // Update local cache with Firestore data
      final snapshot = await specialtiesRef.get();
      final firebaseSpecialties = snapshot.docs
          .map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        developer.log('Firestore doc: ${doc.id}, data: $data', name: 'SpecialtyService');
        try {
          return Specialty.fromMap(data, doc.id);
        } catch (e, stackTrace) {
          developer.log('Error parsing Firestore doc: ${doc.id}, error: $e, stackTrace: $stackTrace',
              name: 'SpecialtyService');
          return Specialty(id: doc.id, name: 'Unknown');
        }
      })
          .toList();
      for (var specialty in firebaseSpecialties) {
        if (specialty.videoUrl != null && !_isValidYouTubeUrl(specialty.videoUrl)) {
          developer.log('Skipping invalid Firestore videoUrl: ${specialty.toString()}', name: 'SpecialtyService');
          continue;
        }
        await specialtiesBox.put(specialty.id, specialty);
      }
      developer.log('Updated Hive cache with Firestore specialties: ${firebaseSpecialties.length}',
          name: 'SpecialtyService');
    } catch (e, stackTrace) {
      developer.log('Sync error: $e, stackTrace: $stackTrace', name: 'SpecialtyService');
    }
  }

  // Clean duplicates in Hive
  Future<void> cleanDuplicateSpecialties() async {
    try {
      final specialties = getCachedSpecialties();
      final seenNames = <String, Specialty>{};
      for (var specialty in specialties) {
        if (seenNames.containsKey(specialty.name)) {
          await specialtiesBox.delete(specialty.id);
          developer.log('Removed duplicate specialty from Hive: ${specialty.toString()}', name: 'SpecialtyService');
        } else {
          seenNames[specialty.name] = specialty;
        }
      }
    } catch (e, stackTrace) {
      developer.log('Clean duplicates error: $e, stackTrace: $stackTrace', name: 'SpecialtyService');
    }
  }
}

// Extension to add copyWith method
extension on Specialty {
  Specialty copyWith({
    String? id,
    String? name,
    String? description,
    String? videoUrl,
  }) {
    return Specialty(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }
}