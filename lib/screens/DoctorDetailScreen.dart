import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/doctor.dart';
import '../models/specialty.dart';
import 'SpecialtyDetailScreen.dart';
import 'DoctorLocationScreen.dart';

class DoctorDetailScreen extends StatelessWidget {
  final Doctor doctor;

  const DoctorDetailScreen({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          doctor.name,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF003087),
        elevation: 4,
      ),
      body: Container(
        color: Colors.grey[100],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor photo
              Center(
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: (doctor.photoUrl != null &&
                      doctor.photoUrl!.isNotEmpty &&
                      File(doctor.photoUrl!).existsSync())
                      ? FileImage(File(doctor.photoUrl!))
                      : null,
                  child: (doctor.photoUrl == null ||
                      doctor.photoUrl!.isEmpty ||
                      !File(doctor.photoUrl!).existsSync())
                      ? const Icon(Icons.person, size: 70, color: Color(0xFF003087))
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              // Info Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoRow(label: 'Name', value: doctor.name),
                    const SizedBox(height: 12),
                    InfoRow(label: 'Email', value: doctor.email),
                    if (doctor.phone != null && doctor.phone!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      InfoRow(label: 'Phone', value: doctor.phone!),
                    ],
                    if (doctor.biography != null && doctor.biography!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      InfoRow(label: 'Bio', value: doctor.biography!),
                    ],
                    if (doctor.website != null && doctor.website!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      InfoRow(label: 'Website', value: doctor.website!),
                    ],
                    if (doctor.facebookUrl != null && doctor.facebookUrl!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      InfoRow(label: 'Facebook', value: doctor.facebookUrl!),
                    ],
                    if (doctor.address != null && doctor.address!.isNotEmpty) ...[
                      Text(
                        'Address',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003087),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          if (doctor.latitude != null && doctor.longitude != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DoctorLocationScreen(doctor: doctor),
                              ),
                            );
                          }
                        },
                        child: Text(
                          doctor.address!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003087),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 12),
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('specialties')
                          .doc(doctor.specialtyId)
                          .snapshots(),
                      builder: (context, specialtySnapshot) {
                        if (!specialtySnapshot.hasData || !specialtySnapshot.data!.exists) {
                          return const SizedBox();
                        }

                        final data = specialtySnapshot.data!.data() as Map<String, dynamic>;
                        final specialty = Specialty.fromMap(data, specialtySnapshot.data!.id);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Specialty',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF003087),
                              ),
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SpecialtyDetailScreen(specialty: specialty),
                                  ),
                                );
                              },
                              child: Text(
                                specialty.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF003087),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                    ),


                  ],
                ),
              ),
              // Buttons at the bottom
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (doctor.phone != null && doctor.phone!.isNotEmpty)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _launchURL('tel:${doctor.phone}', 'call', context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003087),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Call Doctor', style: TextStyle(fontSize: 16, color: Colors.white)),
                        ),
                      ),
                    if (doctor.email.isNotEmpty)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: ElevatedButton(
                            onPressed: () => _launchURL('mailto:${doctor.email}', 'email', context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003087),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Email Doctor', style: TextStyle(fontSize: 16, color: Colors.white)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Updated _launchURL to bypass canLaunchUrl check
  void _launchURL(String url, String action, BuildContext context) async {
    final uri = Uri.parse(url);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm', style: TextStyle(color: Color(0xFF003087))),
        content: Text('Do you want to $action using an external app?', style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF003087))),
          ),
          TextButton(
            onPressed: () async {
              try {
                await launchUrl(uri);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to $action: $e', style: TextStyle(fontSize: 16))),
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Yes', style: TextStyle(color: Color(0xFF003087))),
          ),
        ],
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF003087)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
      ],
    );
  }
}