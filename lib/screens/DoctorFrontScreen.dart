import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/doctor.dart';
import 'DoctorDetailScreen.dart';
import '../services/medical_chat_service.dart';

class DoctorFrontScreen extends StatefulWidget {
  const DoctorFrontScreen({super.key});

  @override
  State<DoctorFrontScreen> createState() => _DoctorFrontScreenState();
}

class _DoctorFrontScreenState extends State<DoctorFrontScreen> {
  String searchQuery = '';
  String? selectedSpecialtyId;
  Map<String, String> specialtyMap = {}; // specialtyId -> name

  double _calculateAverageRating(List<Map<String, dynamic>>? reviews) {
    if (reviews == null || reviews.isEmpty) return 0.0;
    final ratings = reviews.where((r) => r['rating'] != null).map((r) => r['rating'] as num);
    return ratings.isEmpty ? 0.0 : ratings.reduce((a, b) => a + b) / ratings.length;
  }

  void _showChatDialog(String doctorName) {
    final TextEditingController _chatController = TextEditingController();
    final List<Map<String, String>> _chatMessages = [];
    bool _isLoading = false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chat with Medical Assistant for $doctorName'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _chatMessages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isLoading && index == _chatMessages.length) {
                      return const Padding(
                        padding: EdgeInsets.all(8),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final message = _chatMessages[index];
                    return Align(
                      alignment: message['role'] == 'user'
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: message['role'] == 'user'
                              ? Colors.blue.shade100
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(message['text']!),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        decoration: InputDecoration(
                          hintText: 'Ask a medical question...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFF003087)),
                      onPressed: () async {
                        if (_chatController.text.isEmpty) return;
                        final userMessage = _chatController.text;
                        setState(() {
                          _chatMessages.add({'role': 'user', 'text': userMessage});
                          _isLoading = true;
                        });
                        _chatController.clear();
                        try {
                          print('Sending message: $userMessage');
                          final response = await MedicalChatService.sendMedicalMessage(userMessage);
                          print('Response received: $response');
                          setState(() {
                            _chatMessages.add({'role': 'assistant', 'text': response});
                            _isLoading = false;
                          });
                        } catch (e) {
                          print('Error: $e');
                          setState(() {
                            _chatMessages.add({'role': 'assistant', 'text': 'Error: $e'});
                            _isLoading = false;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF003087))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Doctor Directory',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF003087),
        elevation: 4,
      ),
      body: Container(
        color: Colors.grey[100],
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by name...',
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF003087)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF003087), width: 1),
                        ),
                      ),
                      onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('specialties').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        specialtyMap = {
                          for (var doc in snapshot.data!.docs)
                            doc.id: (doc.data() as Map<String, dynamic>)['name'] ?? 'Unknown'
                        };

                        return DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: 'Filter by Specialty',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF003087), width: 1),
                            ),
                          ),
                          value: selectedSpecialtyId,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Specialties')),
                            ...specialtyMap.entries.map(
                                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                            ),
                          ],
                          onChanged: (value) => setState(() => selectedSpecialtyId = value),
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Color(0xFF003087), fontSize: 16),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  List<Doctor> doctors = snapshot.data!.docs
                      .map((doc) => Doctor.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                      .toList();

                  if (searchQuery.isNotEmpty) {
                    doctors = doctors
                        .where((d) => d.name.toLowerCase().contains(searchQuery))
                        .toList();
                  }

                  if (selectedSpecialtyId != null) {
                    doctors = doctors
                        .where((d) => d.specialtyId == selectedSpecialtyId)
                        .toList();
                  }

                  if (doctors.isEmpty) {
                    return const Center(
                      child: Text('No doctors found', style: TextStyle(fontSize: 16, color: Colors.black87)),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: doctors.length,
                    itemBuilder: (context, index) {
                      final doctor = doctors[index];
                      final specialtyName = specialtyMap[doctor.specialtyId] ?? 'Unknown';
                      final averageRating = _calculateAverageRating(doctor.reviews);

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 6,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        color: Colors.white,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => DoctorDetailScreen(doctor: doctor)),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage: (doctor.photoUrl != null &&
                                      doctor.photoUrl!.isNotEmpty &&
                                      File(doctor.photoUrl!).existsSync())
                                      ? FileImage(File(doctor.photoUrl!))
                                      : null,
                                  child: (doctor.photoUrl == null ||
                                      doctor.photoUrl!.isEmpty ||
                                      !File(doctor.photoUrl!).existsSync())
                                      ? const Icon(Icons.person, size: 30, color: Color(0xFF003087))
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      InfoRow(label: 'Name', value: doctor.name),
                                      const SizedBox(height: 8),
                                      InfoRow(label: 'Email', value: doctor.email),
                                      if (doctor.phone != null && doctor.phone!.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        InfoRow(label: 'Phone', value: doctor.phone!),
                                      ],
                                      const SizedBox(height: 8),
                                      InfoRow(label: 'Specialty', value: specialtyName),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          RatingBarIndicator(
                                            rating: averageRating,
                                            itemBuilder: (context, index) => const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                            ),
                                            itemCount: 5,
                                            itemSize: 16,
                                            direction: Axis.horizontal,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            averageRating.toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: doctor.status == 'Available'
                                            ? Colors.green.shade100
                                            : Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        doctor.status ?? 'Unknown',
                                        style: TextStyle(
                                          color: doctor.status == 'Available'
                                              ? Colors.green.shade800
                                              : Colors.red.shade800,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    IconButton(
                                      icon: const Icon(Icons.chat, color: Color(0xFF003087)),
                                      onPressed: () => _showChatDialog(doctor.name),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_ios, color: Color(0xFF003087), size: 20),
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF003087)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
}