import 'package:sqflite/sqflite.dart';
import '../models/treatment.dart';
import 'database_helper.dart';

class TreatmentService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<int> insertTreatment(Treatment treatment) async {
    await _databaseHelper.ensureTreatmentsTable(); // Ensure table exists
    final Database db = await _databaseHelper.database;
    return await db.insert('treatments', treatment.toMap());
  }

  Future<List<Treatment>> getTreatmentsByPatient(int patientId) async {
    await _databaseHelper.ensureTreatmentsTable(); // Ensure table exists
    final Database db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'treatments',
      where: 'patientId = ?',
      whereArgs: [patientId],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Treatment.fromMap(maps[i]);
    });
  }

  Future<List<Treatment>> getActiveTreatments(int patientId) async {
    final Database db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    final List<Map<String, dynamic>> maps = await db.query(
      'treatments',
      where: 'patientId = ? AND startDate <= ? AND (endDate IS NULL OR endDate >= ?)',
      whereArgs: [patientId, now, now],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Treatment.fromMap(maps[i]);
    });
  }

  Future<Treatment?> getTreatmentById(int id) async {
    final Database db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'treatments',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Treatment.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateTreatment(Treatment treatment) async {
    final Database db = await _databaseHelper.database;
    return await db.update(
      'treatments',
      treatment.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [treatment.id],
    );
  }

  Future<int> deleteTreatment(int id) async {
    final Database db = await _databaseHelper.database;
    return await db.delete(
      'treatments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> incrementConsumedQuantity(int treatmentId, int quantity) async {
    final treatment = await getTreatmentById(treatmentId);
    
    if (treatment != null) {
      final newConsumedQuantity = treatment.consumedQuantity + quantity;
      if (newConsumedQuantity <= treatment.totalQuantity) {
        final updatedTreatment = treatment.copyWith(
          consumedQuantity: newConsumedQuantity,
        );
        return await updateTreatment(updatedTreatment);
      }
    }
    return 0;
  }

  Future<Map<String, dynamic>> getTreatmentSummary(int patientId) async {
    final treatments = await getTreatmentsByPatient(patientId);
    final activeTreatments = treatments.where((t) => t.isActive).toList();
    final completedTreatments = treatments.where((t) => !t.isActive && t.consumedQuantity >= t.totalQuantity).toList();

    return {
      'totalTreatments': treatments.length,
      'activeTreatments': activeTreatments.length,
      'completedTreatments': completedTreatments.length,
      'totalMedications': treatments.map((t) => t.medicationName).toSet().length,
    };
  }

  Future<List<Treatment>> getTreatmentsForToday(int patientId) async {
    final Database db = await _databaseHelper.database;
    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];
    
    final List<Map<String, dynamic>> maps = await db.query(
      'treatments',
      where: 'patientId = ? AND startDate <= ? AND (endDate IS NULL OR endDate >= ?)',
      whereArgs: [patientId, todayStr, todayStr],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Treatment.fromMap(maps[i]);
    }).where((treatment) {
      // Filter treatments that have consumption times for today
      return treatment.consumptionTimes.isNotEmpty;
    }).toList();
  }

  Future<void> markConsumptionTime(int treatmentId, DateTime consumptionTime, int quantity) async {
    // Record consumption in history table
    await _databaseHelper.database.then((database) => database.insert('treatment_consumption_history', {
      'treatmentId': treatmentId,
      'consumptionTime': consumptionTime.toIso8601String(),
      'quantity': quantity,
      'createdAt': DateTime.now().toIso8601String(),
    }));

    // Update consumed quantity
    await incrementConsumedQuantity(treatmentId, quantity);
  }

  Future<List<Map<String, dynamic>>> getConsumptionHistory(int treatmentId, {int limit = 50}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'treatment_consumption_history',
      where: 'treatmentId = ?',
      whereArgs: [treatmentId],
      orderBy: 'consumptionTime DESC',
      limit: limit,
    );
    return maps;
  }

  Future<void> recordConsumption(int treatmentId, DateTime consumptionTime) async {
    // Get treatment to determine consumption quantity
    final treatment = await getTreatmentById(treatmentId);
    if (treatment != null && treatment.consumptionTimes.isNotEmpty) {
      // Use the quantity from the first consumption time as default
      final quantity = treatment.consumptionTimes.first.quantity;
      await markConsumptionTime(treatmentId, consumptionTime, quantity);
    }
  }

  Future<int> getConsumptionCountForToday(int treatmentId) async {
    try {
      // Ensure all tables exist
      await _databaseHelper.ensureTreatmentsTable();
      final db = await _databaseHelper.database;
      
      // Verify the consumption history table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='treatment_consumption_history'"
      );
      
      if (tables.isEmpty) {
        // Table doesn't exist, create it
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
      
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      // Query consumption count for today
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM treatment_consumption_history '
        'WHERE treatmentId = ? AND consumptionTime >= ? AND consumptionTime < ?',
        [treatmentId, startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      );
      
      final count = Sqflite.firstIntValue(result) ?? 0;
      return count;
    } catch (e) {
      // If table doesn't exist or error occurs, return 0
      return 0;
    }
  }
}