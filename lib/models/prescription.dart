class Prescription {
  String id;
  String patientId;
  String doctorId;
  List<String> medicines;
  String date;

  Prescription({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.medicines,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'medicines': medicines,
      'date': date,
    };
  }

  factory Prescription.fromMap(String id, Map<String, dynamic> data) {
    return Prescription(
      id: id,
      patientId: data['patientId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      medicines: List<String>.from(data['medicines'] ?? []),
      date: data['date'] ?? '',
    );
  }
}
