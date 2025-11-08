import 'package:uniapp/models/doctor.dart';

class Appointment {
  final int? id;
  final Doctor doctor;
  final DateTime dateTime;

  Appointment({this.id, required this.doctor, required this.dateTime});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctor_name': doctor.name,
      'doctor_specialty': doctor.specialty,
      'doctor_address': doctor.address,
      'doctor_image': doctor.image,
      'date_time': dateTime.toIso8601String(),
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'],
      doctor: Doctor(
        name: map['doctor_name'],
        specialty: map['doctor_specialty'],
        address: map['doctor_address'],
        image: map['doctor_image'],
      ),
      dateTime: DateTime.parse(map['date_time']),
    );
  }
}