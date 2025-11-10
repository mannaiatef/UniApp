import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/sqlite_service.dart';

class CloudSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SQLiteService _sqliteService = SQLiteService();

  /// Synchroniser TOUTES les prescriptions SQLite vers Firestore
  Future<void> syncAllPrescriptions() async {
    final prescriptions = await _sqliteService.getPrescriptions();

    for (final p in prescriptions) {
      await syncPrescriptionToFirebase(p);
    }
  }

  /// Publier UNE prescription (avec son ID SQLite)
  Future<void> syncPrescriptionToFirebase(Map<String, dynamic> prescription) async {
    final String id = prescription['prescription_id'] ?? '';

    if (id.isEmpty) {
      print('⚠️ Prescription sans ID, ignorée');
      return;
    }

    final docRef = _firestore.collection('prescriptions').doc(id);

    await docRef.set({
      'prescription_id': id,
      'patient_name': prescription['patient_name'],
      'doctor_name': prescription['doctor_name'],
      'date_prescription': prescription['date_prescription'],
      'diagnostic': prescription['diagnostic'],
      'notes_medecin': prescription['notes_medecin'],
      'doctor_signature': prescription['doctor_signature'],
      'created_at': prescription['created_at'],
      'updated_at': prescription['updated_at'],
      // 🔹 On récupère aussi les médicaments liés depuis SQLite
      'medicines': await _sqliteService.getMedicines(id),
    });

    print("✅ Prescription $id synchronisée vers Firebase");
  }
}
