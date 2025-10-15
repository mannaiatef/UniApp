import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor.dart';
import 'DoctorDetailScreen.dart';

class DoctorFrontScreen extends StatefulWidget {
  const DoctorFrontScreen({super.key});

  @override
  State<DoctorFrontScreen> createState() => _DoctorFrontScreenState();
}

class _DoctorFrontScreenState extends State<DoctorFrontScreen> {
  String searchQuery = '';
  String? selectedSpecialtyId;
  Map<String, String> specialtyMap = {}; // specialtyId -> name

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctors'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // Search + Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                // Search Bar
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) =>
                        setState(() => searchQuery = value.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 12),

                // Specialty Filter Dropdown
                Expanded(
                  flex: 1,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('specialties')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      specialtyMap = {
                        for (var doc in snapshot.data!.docs)
                          doc.id: (doc.data() as Map<String, dynamic>)['name'] ??
                              'Unknown'
                      };

                      return DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'Specialty',
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        value: selectedSpecialtyId,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All')),
                          ...specialtyMap.entries.map(
                                (e) => DropdownMenuItem(
                                value: e.key, child: Text(e.value)),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => selectedSpecialtyId = value),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Doctor List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                List<Doctor> doctors = snapshot.data!.docs
                    .map((doc) =>
                    Doctor.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                    .toList();

                // Apply search filter
                if (searchQuery.isNotEmpty) {
                  doctors = doctors
                      .where((d) => d.name.toLowerCase().contains(searchQuery))
                      .toList();
                }

                // Apply specialty filter
                if (selectedSpecialtyId != null) {
                  doctors = doctors
                      .where((d) => d.specialtyId == selectedSpecialtyId)
                      .toList();
                }

                if (doctors.isEmpty) {
                  return const Center(child: Text('No doctors found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = doctors[index];
                    final specialtyName =
                        specialtyMap[doctor.specialtyId] ?? 'Unknown';

                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shadowColor: Colors.grey.withOpacity(0.3),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => DoctorDetailScreen(doctor: doctor)),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundImage: (doctor.photoUrl != null &&
                                    doctor.photoUrl!.isNotEmpty)
                                    ? FileImage(File(doctor.photoUrl!))
                                    : null,
                                child: (doctor.photoUrl == null ||
                                    doctor.photoUrl!.isEmpty)
                                    ? const Icon(Icons.person, size: 28)
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InfoRow(label: 'Name', value: doctor.name),
                                    const SizedBox(height: 6),
                                    InfoRow(label: 'Email', value: doctor.email),
                                    if (doctor.phone != null &&
                                        doctor.phone!.isNotEmpty)
                                      const SizedBox(height: 6),
                                    if (doctor.phone != null &&
                                        doctor.phone!.isNotEmpty)
                                      InfoRow(label: 'Phone', value: doctor.phone!),
                                    const SizedBox(height: 6),
                                    InfoRow(label: 'Specialty', value: specialtyName),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward, color: Colors.blue),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// InfoRow widget for consistent label-value design
class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
          const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style:
          const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
      ],
    );
  }
}
