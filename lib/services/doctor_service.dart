import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/doctor.dart';

class DoctorService {
  final CollectionReference doctorsRef = FirebaseFirestore.instance.collection('doctors');
  final Box<Doctor> doctorsBox = Hive.box<Doctor>('doctors');

  /// Fetch doctors from Firebase and cache in Hive, fallback to cache if offline
  Future<List<Doctor>> fetchDoctors() async {
    try {
      final snapshot = await doctorsRef.get();
      final doctors = snapshot.docs
          .map((doc) => Doctor.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Update Hive without clearing to preserve local changes
      for (var doctor in doctors) {
        await doctorsBox.put(doctor.id, doctor); // Overwrites if ID exists
      }

      return doctors;
    } catch (e) {
      print('Fetch error: $e');
      return getCachedDoctors();
    }
  }

  /// Get doctors from Hive (offline cache)
  List<Doctor> getCachedDoctors() {
    return doctorsBox.values.toList();
  }

  /// Sync local Hive data with Firebase
  Future<void> syncWithFirebase() async {
    try {
      // Fetch Firebase doctors
      final snapshot = await doctorsRef.get();
      final firebaseDoctors = snapshot.docs
          .map((doc) => Doctor.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Update Hive with Firebase data
      for (var doctor in firebaseDoctors) {
        await doctorsBox.put(doctor.id, doctor);
      }

      // Push local-only doctors to Firebase
      for (var localDoctor in doctorsBox.values) {
        final doc = await doctorsRef.doc(localDoctor.id).get();
        if (!doc.exists) {
          await doctorsRef.doc(localDoctor.id).set(localDoctor.toMap());
        }
      }
    } catch (e) {
      print('Sync error: $e');
    }
  }

  /// Add a doctor to Firebase and Hive
  Future<void> addDoctor(Doctor doctor, {File? imageFile}) async {
    // Check if a doctor with the same name and email already exists
    final snapshot = await doctorsRef
        .where('name', isEqualTo: doctor.name)
        .where('email', isEqualTo: doctor.email)
        .get();

    if (snapshot.docs.isNotEmpty) {
      // Doctor already exists, update instead
      final existingId = snapshot.docs.first.id;
      final doctorToSave = doctor.copyWith(id: existingId);
      await updateDoctor(doctorToSave, imageFile: imageFile);
      return;
    }

    // Generate a unique ID if not provided
    final doctorId = doctor.id.isEmpty ? doctorsRef.doc().id : doctor.id;
    final doctorToSave = await _prepareDoctorWithImage(doctor.copyWith(id: doctorId), imageFile);

    // Save to Hive
    await doctorsBox.put(doctorToSave.id, doctorToSave);

    // Save to Firebase
    try {
      await doctorsRef.doc(doctorToSave.id).set(doctorToSave.toMap());
    } catch (e) {
      print('Firebase add error: $e');
    }
  }

  /// Update doctor in Firebase and Hive
  Future<void> updateDoctor(Doctor doctor, {File? imageFile}) async {
    final doctorToSave = await _prepareDoctorWithImage(doctor, imageFile);

    // Save to Hive
    await doctorsBox.put(doctorToSave.id, doctorToSave);

    // Update Firebase
    try {
      await doctorsRef.doc(doctorToSave.id).set(doctorToSave.toMap());
    } catch (e) {
      print('Firebase update error: $e');
    }
  }

  /// Delete doctor from Firebase and Hive
  Future<void> deleteDoctor(String id) async {
    // Delete from Hive
    await doctorsBox.delete(id);

    // Delete from Firebase
    try {
      await doctorsRef.doc(id).delete();
    } catch (e) {
      print('Firebase delete error: $e');
    }
  }

  /// Copy image to app directory and update doctor.photoUrl
  Future<Doctor> _prepareDoctorWithImage(Doctor doctor, File? imageFile) async {
    String? photoPath = doctor.photoUrl;

    if (imageFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'doctor_${doctor.id}.jpg';
      final localFile = await imageFile.copy('${appDir.path}/$fileName');
      photoPath = localFile.path;
    }

    return doctor.copyWith(photoUrl: photoPath);
  }

  /// Stream of doctors for real-time updates
  Stream<List<Doctor>> getDoctorsStream() {
    return doctorsRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Doctor.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  /// Clean up duplicate doctors in Firebase and Hive (run once if needed)
  Future<void> cleanDuplicateDoctors() async {
    final snapshot = await doctorsRef.get();
    final doctorMap = <String, List<DocumentSnapshot>>{};

    // Group by name and email
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final key = '${data['name']}_${data['email']}';
      doctorMap.putIfAbsent(key, () => []).add(doc);
    }

    // Delete duplicates, keeping the first document
    for (var entry in doctorMap.entries) {
      if (entry.value.length > 1) {
        for (var i = 1; i < entry.value.length; i++) {
          await doctorsRef.doc(entry.value[i].id).delete();
          await doctorsBox.delete(entry.value[i].id);
        }
      }
    }
  }
}