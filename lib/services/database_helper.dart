import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/patient.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'patient_database.db');
    return await openDatabase(
      path,
      version: 7, // Incremented version to link appointments to patients
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Added onUpgrade callback
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE patients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        prenom TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        motDePasse TEXT NOT NULL,
        telephone TEXT,
        adresse TEXT,
        photoUrl TEXT
      )
    ''');
    await _createAppointmentsTable(db);
    await _createTreatmentsTable(db);
    await _createTreatmentConsumptionHistoryTable(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createAppointmentsTable(db);
    }
    if (oldVersion < 3) {
      await _createTreatmentsTable(db);
      await _createTreatmentConsumptionHistoryTable(db);
    }
    if (oldVersion < 5) {
      await _createTreatmentsTable(db);
      await _createTreatmentConsumptionHistoryTable(db);
    }
    // Migration pour ajouter la colonne photoUrl si elle n'existe pas
    if (oldVersion < 6) {
      try {
        // Vérifier si la colonne photoUrl existe déjà
        final columns = await db.rawQuery('PRAGMA table_info(patients)');
        final hasPhotoUrl = columns.any((column) => column['name'] == 'photoUrl');
        
        if (!hasPhotoUrl) {
          print('Ajout de la colonne photoUrl à la table patients');
          await db.execute('ALTER TABLE patients ADD COLUMN photoUrl TEXT');
        }
      } catch (e) {
        print('Erreur lors de l\'ajout de la colonne photoUrl: $e');
        // Si l'ajout échoue, essayer de recréer la table avec la nouvelle colonne
        // (mais cela supprimerait les données, donc on évite si possible)
      }
    }
    if (oldVersion < 7) {
      await _ensureAppointmentsPatientIdColumnExists(db);
    }
  }

  Future _createAppointmentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS appointments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patientId INTEGER,
        doctor_name TEXT NOT NULL,
        doctor_specialty TEXT NOT NULL,
        doctor_address TEXT NOT NULL,
        doctor_image TEXT NOT NULL,
        date_time TEXT NOT NULL,
        FOREIGN KEY (patientId) REFERENCES patients (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _createTreatmentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS treatments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patientId INTEGER NOT NULL,
        medicationName TEXT NOT NULL,
        dosage TEXT NOT NULL,
        frequency TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT,
        totalQuantity INTEGER NOT NULL,
        consumedQuantity INTEGER DEFAULT 0,
        consumptionTimes TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (patientId) REFERENCES patients (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _createTreatmentConsumptionHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS treatment_consumption_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        treatmentId INTEGER NOT NULL,
        consumptionTime TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (treatmentId) REFERENCES treatments (id) ON DELETE CASCADE
      )
    ''');
  }

  // Explicitly ensure appointments table exists
  Future<void> ensureAppointmentsTable() async {
    Database db = await database;
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS appointments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          patientId INTEGER,
          doctor_name TEXT NOT NULL,
          doctor_specialty TEXT NOT NULL,
          doctor_address TEXT NOT NULL,
          doctor_image TEXT NOT NULL,
          date_time TEXT NOT NULL,
          FOREIGN KEY (patientId) REFERENCES patients (id) ON DELETE CASCADE
        )
      ''');
      await _ensureAppointmentsPatientIdColumnExists(db);
    } catch (e) {
      print('Error ensuring appointments table exists: $e');
    }
  }

  // Explicitly ensure treatments table exists
  Future<void> ensureTreatmentsTable() async {
    Database db = await database;
    try {
      await _createTreatmentsTable(db);
      await _createTreatmentConsumptionHistoryTable(db);
    } catch (e) {
      print('Error ensuring treatments table exists: $e');
    }
  }

  // Méthodes CRUD pour les patients
  Future<int> insertPatient(Patient patient) async {
    Database db = await database;
    return await db.insert('patients', patient.toMap());
  }

  Future<Patient?> getPatientByEmail(String email) async {
    try {
      Database db = await database;
      
      // Vérifier que la table patients existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='patients'"
      );
      
      if (tables.isEmpty) {
        print('Table patients n\'existe pas, création en cours...');
        await _onCreate(db, 1);
      } else {
        // S'assurer que la colonne photoUrl existe
        await _ensurePhotoUrlColumnExists(db);
      }
      
      List<Map<String, dynamic>> maps = await db.query(
        'patients',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (maps.isNotEmpty) {
        return Patient.fromMap(maps.first);
      }
      print('Aucun patient trouvé avec l\'email: $email');
      return null;
    } catch (e) {
      print('Erreur dans getPatientByEmail: $e');
      return null;
    }
  }

  Future<bool> authenticatePatient(String email, String motDePasse) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'patients',
      where: 'email = ? AND motDePasse = ?',
      whereArgs: [email, motDePasse],
    );
    return maps.isNotEmpty;
  }

  Future<List<Patient>> getAllPatients() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('patients');
    return List.generate(maps.length, (i) {
      return Patient.fromMap(maps[i]);
    });
  }

  Future<int> updatePatient(Patient patient) async {
    Database db = await database;
    
    try {
      // S'assurer que la colonne photoUrl existe avant la mise à jour
      await _ensurePhotoUrlColumnExists(db);
      
      // Mettre à jour le patient
      return await db.update(
        'patients',
        patient.toMap(),
        where: 'id = ?',
        whereArgs: [patient.id],
      );
    } catch (e) {
      print('Erreur lors de la mise à jour du patient: $e');
      // Si l'erreur est liée à la colonne photoUrl, essayer de l'ajouter
      try {
        await _ensurePhotoUrlColumnExists(db);
        // Réessayer la mise à jour
        return await db.update(
          'patients',
          patient.toMap(),
          where: 'id = ?',
          whereArgs: [patient.id],
        );
      } catch (e2) {
        print('Erreur lors de la deuxième tentative de mise à jour: $e2');
        rethrow;
      }
    }
  }

  Future<void> _ensurePhotoUrlColumnExists(Database db) async {
    try {
      // Vérifier si la colonne photoUrl existe
      final columns = await db.rawQuery('PRAGMA table_info(patients)');
      final hasPhotoUrl = columns.any((column) => column['name'] == 'photoUrl');
      
      if (!hasPhotoUrl) {
        print('La colonne photoUrl n\'existe pas, ajout en cours...');
        await db.execute('ALTER TABLE patients ADD COLUMN photoUrl TEXT');
        print('Colonne photoUrl ajoutée avec succès');
      }
    } catch (e) {
      print('Erreur lors de la vérification/ajout de la colonne photoUrl: $e');
      // Si l'erreur persiste, on la laisse remonter
      rethrow;
    }
  }

  Future<void> ensureAppointmentsPatientLink() async {
    Database db = await database;
    await _ensureAppointmentsPatientIdColumnExists(db);
  }

  Future<void> _ensureAppointmentsPatientIdColumnExists(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(appointments)');
      final hasPatientId = columns.any((column) => column['name'] == 'patientId');

      if (!hasPatientId) {
        print('Ajout de la colonne patientId à la table appointments');
        await db.execute('ALTER TABLE appointments ADD COLUMN patientId INTEGER');
      }
    } catch (e) {
      print('Erreur lors de l\'ajout de la colonne patientId: $e');
    }
  }

  Future<int> deletePatient(int id) async {
    Database db = await database;
    return await db.delete(
      'patients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}