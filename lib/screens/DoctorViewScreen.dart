import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor.dart';

class DoctorViewScreen extends StatefulWidget {
  final String doctorId; // Hardcoded or passed parameter

  const DoctorViewScreen({super.key, this.doctorId = 'ZjLX257uKcmcd0NTG6xT'});

  @override
  State<DoctorViewScreen> createState() => _DoctorViewScreenState();
}

class _DoctorViewScreenState extends State<DoctorViewScreen> {
  String? _currentStatus;

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('doctors')
            .doc(widget.doctorId)
            .get();
        if (doc.exists) {
          final doctor = Doctor.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          setState(() {
            _currentStatus = doctor.status ?? 'Available';
          });
          return;
        }
      } catch (e) {
        if (attempt == 2) rethrow;
        await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
      }
    }
  }

  Future<void> _toggleStatus(String newStatus) async {
    await FirebaseFirestore.instance
        .collection('doctors')
        .doc(widget.doctorId)
        .update({'status': newStatus});
    setState(() {
      _currentStatus = newStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Doctor Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF003087),
        elevation: 4,
      ),
      body: Container(
        color: Colors.grey[100],
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('doctors')
              .doc(widget.doctorId)
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF003087)));
            }

            if (!snapshot.data!.exists) {
              return const Center(child: Text('Doctor profile not found'));
            }

            final doctor = Doctor.fromMap(
                snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${doctor.name}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        InfoRow(label: 'Email', value: doctor.email),
                        if (doctor.phone != null && doctor.phone!.isNotEmpty)
                          const SizedBox(height: 12),
                        if (doctor.phone != null && doctor.phone!.isNotEmpty)
                          InfoRow(label: 'Phone', value: doctor.phone!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Availability Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003087),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _currentStatus ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: _currentStatus == 'Available'
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                              ),
                            ),
                            Switch(
                              value: _currentStatus == 'Available',
                              activeColor: Colors.green,
                              inactiveThumbColor: Colors.red,
                              inactiveTrackColor: Colors.red.shade200,
                              onChanged: (value) async {
                                final newStatus = value ? 'Available' : 'Busy';
                                await _toggleStatus(newStatus);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Patient Reviews',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003087),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (doctor.reviews == null || doctor.reviews!.isEmpty)
                          const Text(
                            'No reviews yet',
                            style: TextStyle(fontSize: 16, color: Colors.black87),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: doctor.reviews!.length,
                            itemBuilder: (context, index) {
                              final review = doctor.reviews![index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${review['rating'] ?? 0.0}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.amber,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            review['comment'] ?? 'No comment',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            review['date'] ?? 'No date',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Helper widget for a neat label-value row
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
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF003087),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}