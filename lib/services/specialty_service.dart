import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/specialty.dart';

class SpecialtyService {
  final CollectionReference specialtiesRef =
  FirebaseFirestore.instance.collection('specialties');

  Future<void> addSpecialty(Specialty specialty) async {
    await specialtiesRef.add(specialty.toMap());
  }

  Future<List<Specialty>> getSpecialties() async {
    QuerySnapshot snapshot = await specialtiesRef.get();
    return snapshot.docs
        .map((doc) => Specialty.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }
}
