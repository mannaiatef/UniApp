import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../services/drug_effects_service.dart'; // ⬅️ ajoute cette ligne tout en haut


class SQLiteService {
  static Database? _db;
  static final SQLiteService _instance = SQLiteService._internal();
  SQLiteService._internal();
  factory SQLiteService() => _instance;

  // ⚠️ Passe de 1 -> 2
  static const _dbVersion = 2;
  static const _dbName = 'medassist.db';

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    // print('📂 DB: $path');

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE prescriptions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            prescription_id TEXT UNIQUE,
            patient_name TEXT,
            doctor_name TEXT,
            date_prescription TEXT,
            diagnostic TEXT,
            notes_medecin TEXT,
            doctor_signature BLOB,
            created_at TEXT,
            updated_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE medicines(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            prescription_id TEXT,
            medicine_name TEXT,
            dosage TEXT,
            frequency TEXT,
            duration TEXT,
            instructions TEXT,
            start_date TEXT,
            effects_description TEXT   -- ✅ nouveau champ dès la création
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE medicines ADD COLUMN effects_description TEXT",
          );
        }
      },
    );
  }

  Future<void> insertPrescription(Map<String, dynamic> prescription) async {
    final db = await database;
    
    // 1️⃣ Insérer la prescription et les médicaments dans une transaction
    final List<int> medicineIds = [];
    final List<String> medicineNames = [];
    
    await db.transaction((txn) async {
      await txn.insert(
        'prescriptions',
        {
          'prescription_id': prescription['prescription_id'],
          'patient_name': prescription['patient_name'],
          'doctor_name': prescription['doctor_name'],
          'date_prescription': prescription['date_prescription'],
          'diagnostic': prescription['diagnostic'],
          'notes_medecin': prescription['notes_medecin'],
          'doctor_signature': prescription['doctor_signature'] as Uint8List?,
          'created_at': prescription['created_at'],
          'updated_at': prescription['updated_at'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final meds = (prescription['medicines'] ?? []) as List<dynamic>;
      for (final m in meds) {
        final Map<String, dynamic> med = Map<String, dynamic>.from(m);

        // Insérer le médicament sans effets (on les ajoutera après)
        final medicineId = await txn.insert('medicines', {
          'prescription_id': prescription['prescription_id'],
          'medicine_name': med['medicine_name'] ?? '',
          'dosage': med['dosage'] ?? '',
          'frequency': med['frequency'] ?? '',
          'duration': med['duration'] ?? '',
          'instructions': med['instructions'] ?? '',
          'start_date': med['start_date'] ?? '',
          'effects_description': null,
        });
        
        medicineIds.add(medicineId);
        medicineNames.add(med['medicine_name'] ?? '');
      }
    });

    // 2️⃣ Récupérer les effets secondaires EN DEHORS de la transaction
    // Cela évite de bloquer la transaction et permet une meilleure gestion d'erreur
    final drugService = DrugEffectsService();
    for (int i = 0; i < medicineIds.length; i++) {
      final medicineId = medicineIds[i];
      final medicineName = medicineNames[i];
      
      if (medicineName.isEmpty) continue;

      try {
        // Récupérer les effets secondaires (peut prendre quelques secondes)
        final effects = await drugService.fetchSideEffects(medicineName);

        // Mettre à jour la base de données avec les effets
        await updateMedicineEffects(
          medicineRowId: medicineId,
          effects: effects,
        );

        print("✅ Effets secondaires ajoutés pour $medicineName");
      } catch (e) {
        print("⚠️ Erreur lors de la récupération des effets pour $medicineName : $e");
        // Même en cas d'erreur, on met un message par défaut
        try {
          await updateMedicineEffects(
            medicineRowId: medicineId,
            effects: '⚕️ Les effets secondaires n\'ont pas pu être récupérés automatiquement. Consultez la notice du médicament ou votre médecin.',
          );
        } catch (updateError) {
          print("❌ Erreur lors de la mise à jour des effets : $updateError");
        }
      }
    }
  }

  Future<List<Map<String, dynamic>>> getPrescriptions() async {
    final db = await database;
    return await db.query('prescriptions', orderBy: 'created_at DESC');
  }

  Future<Map<String, dynamic>?> getPrescriptionById(String id) async {
    final db = await database;
    final res = await db.query(
      'prescriptions',
      where: 'prescription_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return res.isNotEmpty ? res.first : null;
  }

  Future<List<Map<String, dynamic>>> getMedicines(String prescriptionId) async {
    final db = await database;
    return await db.query(
      'medicines',
      where: 'prescription_id = ?',
      whereArgs: [prescriptionId],
      orderBy: 'id ASC',
    );
  }
  // ------------------------------------------------------------
  // 🔹 Fermeture de la base de données proprement
  // ------------------------------------------------------------
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      print("📕 Base SQLite fermée correctement.");
    }
  }

  // ✅ mise à jour de la description d'effets pour un médicament
  Future<void> updateMedicineEffects({
    required int medicineRowId,
    required String effects,
  }) async {
    final db = await database;
    await db.update(
      'medicines',
      {'effects_description': effects},
      where: 'id = ?',
      whereArgs: [medicineRowId],
    );
  }
}
