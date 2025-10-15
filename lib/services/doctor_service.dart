import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor.dart';

class DoctorService {
  final CollectionReference doctorsRef =
  FirebaseFirestore.instance.collection('doctors');

  Future<void> addDoctor(Doctor doctor) async {
    await doctorsRef.add(doctor.toMap());
  }

  Future<List<Doctor>> getDoctors() async {
    QuerySnapshot snapshot = await doctorsRef.get();
    return snapshot.docs
        .map((doc) => Doctor.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<void> updateDoctor(Doctor doctor) async {
    await doctorsRef.doc(doctor.id).update(doctor.toMap());
  }

  Future<void> deleteDoctor(String id) async {
    await doctorsRef.doc(id).delete();
  }
}
