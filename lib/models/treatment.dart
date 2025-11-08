import 'package:flutter/material.dart';

class Treatment {
  final int? id;
  final int patientId;
  final String medicationName;
  final String dosage;
  final String frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final int totalQuantity;
  final int consumedQuantity;
  final List<ConsumptionTime> consumptionTimes;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Treatment({
    this.id,
    required this.patientId,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.totalQuantity,
    this.consumedQuantity = 0,
    required this.consumptionTimes,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  int get remainingQuantity => totalQuantity - consumedQuantity;
  
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && (endDate == null || now.isBefore(endDate!));
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'medicationName': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'totalQuantity': totalQuantity,
      'consumedQuantity': consumedQuantity,
      'consumptionTimes': consumptionTimes.map((time) => time.toMap()).join(','),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Treatment.fromMap(Map<String, dynamic> map) {
    return Treatment(
      id: map['id'],
      patientId: map['patientId'],
      medicationName: map['medicationName'],
      dosage: map['dosage'],
      frequency: map['frequency'],
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      totalQuantity: map['totalQuantity'],
      consumedQuantity: map['consumedQuantity'] ?? 0,
      consumptionTimes: (map['consumptionTimes'] as String).split(',').map((timeStr) {
        return ConsumptionTime.fromMap(timeStr);
      }).toList(),
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Treatment copyWith({
    int? id,
    int? patientId,
    String? medicationName,
    String? dosage,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    int? totalQuantity,
    int? consumedQuantity,
    List<ConsumptionTime>? consumptionTimes,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Treatment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      consumedQuantity: consumedQuantity ?? this.consumedQuantity,
      consumptionTimes: consumptionTimes ?? this.consumptionTimes,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

class ConsumptionTime {
  final TimeOfDay time;
  final int quantity;

  ConsumptionTime({
    required this.time,
    required this.quantity,
  });

  String toMap() {
    return '${time.hour}:${time.minute}:$quantity';
  }

  factory ConsumptionTime.fromMap(String map) {
    final parts = map.split(':');
    return ConsumptionTime(
      time: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
      quantity: int.parse(parts[2]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': time.hour,
      'minute': time.minute,
      'quantity': quantity,
    };
  }

  factory ConsumptionTime.fromJson(Map<String, dynamic> json) {
    return ConsumptionTime(
      time: TimeOfDay(hour: json['hour'], minute: json['minute']),
      quantity: json['quantity'],
    );
  }
}