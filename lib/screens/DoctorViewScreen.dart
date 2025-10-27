import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/doctor.dart';
import 'dart:io';

class DoctorViewScreen extends StatefulWidget {
  final String doctorId;

  const DoctorViewScreen({super.key, this.doctorId = 'ZjLX257uKcmcd0NTG6xT'});

  @override
  State<DoctorViewScreen> createState() => _DoctorViewScreenState();
}

class _DoctorViewScreenState extends State<DoctorViewScreen> {
  String? _currentStatus;
  XFile? _profileImage;
  String? _profileImageUrl;
  Doctor? _doctor;
  Map<String, List<String>>? _schedule;
  final ImagePicker _picker = ImagePicker();
  late Box _cacheBox;
  late Map<String, String> _specialtyMap;

  @override
  void initState() {
    super.initState();
    _cacheBox = Hive.box('cache');
    _loadSpecialtiesCache();
    _loadDoctorData();
  }

  void _loadSpecialtiesCache() {
    final cached = _cacheBox.get('specialties', defaultValue: {});
    _specialtyMap = Map<String, String>.from(cached);
  }

  Future<void> _loadDoctorData() async {
    final box = Hive.box<Doctor>('doctors');
    try {
      final doc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(widget.doctorId)
          .get();
      if (doc.exists) {
        final doctor = Doctor.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        await box.put(doctor.id, doctor);
        setState(() {
          _doctor = doctor;
          _currentStatus = doctor.status ?? 'Available';
          _schedule = doctor.schedule ?? {};
          _profileImageUrl = doctor.photoUrl; // Use photoUrl from Doctor model
        });
      } else if (box.containsKey(widget.doctorId)) {
        final cachedDoctor = box.get(widget.doctorId);
        setState(() {
          _doctor = cachedDoctor;
          _currentStatus = cachedDoctor!.status ?? 'Available';
          _schedule = cachedDoctor.schedule ?? {};
          _profileImageUrl = cachedDoctor.photoUrl; // Use photoUrl from Doctor model
        });
      } else {
        setState(() {
          _doctor = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading doctor data: $e'),
          backgroundColor: const Color(0xFF8B0000),
        ),
      );
    }
  }

  Future<void> _toggleStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(widget.doctorId)
          .update({'status': newStatus});
      setState(() {
        _currentStatus = newStatus;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: const Color(0xFF8B0000),
        ),
      );
    }
  }

  Future<String?> _saveImageToDocuments(File? imageFile, String doctorId) async {
    if (imageFile == null) return null;
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'doctor_$doctorId.jpg';
    final newPath = '${directory.path}/$fileName';
    await imageFile.copy(newPath);
    return newPath;
  }

  Future<void> _pickProfileImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _profileImage = pickedFile;
        });
        final newImagePath = await _saveImageToDocuments(File(pickedFile.path), widget.doctorId);
        if (_doctor?.photoUrl != null && !(_doctor!.photoUrl!.startsWith('http'))) {
          final oldFile = File(_doctor!.photoUrl!);
          if (oldFile.existsSync()) {
            await oldFile.delete();
          }
        }
        await FirebaseFirestore.instance
            .collection('doctors')
            .doc(widget.doctorId)
            .update({'profileImageUrl': newImagePath});
        setState(() {
          _profileImageUrl = newImagePath;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: const Color(0xFF8B0000),
        ),
      );
    }
  }

  Future<void> _updateProfile(String name, String? phone, ) async {
    try {
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(widget.doctorId)
          .update({
        'name': name,
        'phone': phone,
      });
      await _loadDoctorData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Color(0xFF006400),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: const Color(0xFF8B0000),
        ),
      );
    }
  }

  Future<void> _updateSchedule(Map<String, List<String>> newSchedule) async {
    try {
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(widget.doctorId)
          .update({'schedule': newSchedule});
      final box = Hive.box<Doctor>('doctors');
      final doctor = box.get(widget.doctorId);
      if (doctor != null) {
        await box.put(widget.doctorId, doctor.copyWith(schedule: newSchedule));
      }
      setState(() {
        _schedule = newSchedule;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule updated successfully'),
          backgroundColor: Color(0xFF006400),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating schedule: $e'),
          backgroundColor: const Color(0xFF8B0000),
        ),
      );
    }
  }

  void _showEditProfileDialog() {
    final _nameController = TextEditingController(text: _doctor?.name ?? '');
    final _phoneController = TextEditingController(text: _doctor?.phone ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color(0xFF003087),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: const TextStyle(color: Color(0xFF003087)),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF003087)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF003087), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone (optional)',
                  labelStyle: const TextStyle(color: Color(0xFF003087)),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF003087)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF003087), width: 2),
                  ),
                ),
              ),

            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF003087)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003087),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () async {
              if (_nameController.text.isNotEmpty) {
                await _updateProfile(
                  _nameController.text,
                  _phoneController.text.isNotEmpty ? _phoneController.text : null,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditScheduleDialog() {
    final Map<String, List<String>> tempSchedule = Map.from(_schedule ?? {});
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: const Text(
          'Edit Schedule',
          style: TextStyle(
            color: Color(0xFF003087),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: days.map((day) {
              final timeSlots = tempSchedule[day] ?? [];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003087),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...timeSlots.asMap().entries.map((entry) {
                      final index = entry.key;
                      final slot = entry.value;
                      return Row(
                        children: [
                          Expanded(
                            child: Text(
                              slot,
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFF006400)),
                            onPressed: () async {
                              final TimeOfDay? startTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                                builder: (context, child) => Theme(
                                  data: ThemeData.light().copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Color(0xFF003087),
                                      onPrimary: Colors.white,
                                    ),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (startTime != null) {
                                final TimeOfDay? endTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                  builder: (context, child) => Theme(
                                    data: ThemeData.light().copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Color(0xFF003087),
                                        onPrimary: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (endTime != null) {
                                  final newSlot = '${startTime.format(context)} - ${endTime.format(context)}';
                                  setState(() {
                                    if (tempSchedule[day] == null) tempSchedule[day] = [];
                                    if (index < tempSchedule[day]!.length) {
                                      tempSchedule[day]![index] = newSlot;
                                    } else {
                                      tempSchedule[day]!.add(newSlot);
                                    }
                                  });
                                }
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Color(0xFF8B0000)),
                            onPressed: () {
                              setState(() {
                                tempSchedule[day]!.removeAt(index);
                                if (tempSchedule[day]!.isEmpty) tempSchedule.remove(day);
                              });
                            },
                          ),
                        ],
                      );
                    }).toList(),
                    TextButton(
                      onPressed: () async {
                        final TimeOfDay? startTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                          builder: (context, child) => Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF003087),
                                onPrimary: Colors.white,
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (startTime != null) {
                          final TimeOfDay? endTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                            builder: (context, child) => Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF003087),
                                  onPrimary: Colors.white,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (endTime != null) {
                            setState(() {
                              if (tempSchedule[day] == null) tempSchedule[day] = [];
                              tempSchedule[day]!.add('${startTime.format(context)} - ${endTime.format(context)}');
                            });
                          }
                        }
                      },
                      child: const Text(
                        'Add Time Slot',
                        style: TextStyle(color: Color(0xFF003087)),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF003087)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003087),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () async {
              await _updateSchedule(tempSchedule);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  double _calculateAverageRating(List<Map<String, dynamic>>? reviews) {
    if (reviews == null || reviews.isEmpty) return 0.0;
    final total = reviews.fold<double>(
        0.0, (sum, review) => sum + (review['rating']?.toDouble() ?? 0.0));
    return total / reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Doctor Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF003087),
        elevation: 0,
        shadowColor: Colors.black45,
      ),
      body: Container(
        color: Colors.grey[100],
        padding: const EdgeInsets.all(16),
        child: _doctor == null
            ? const Center(
          child: CircularProgressIndicator(color: Color(0xFF003087)),
        )
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 300),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _pickProfileImage,
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: _profileImage != null
                                    ? FileImage(File(_profileImage!.path))
                                    : _profileImageUrl != null && File(_profileImageUrl!).existsSync()
                                    ? FileImage(File(_profileImageUrl!))
                                    : null,
                                child: _profileImage == null && (_profileImageUrl == null || !File(_profileImageUrl!).existsSync())
                                    ? const Icon(Icons.person, size: 40, color: Color(0xFF003087))
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dr. ${_doctor!.name}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF003087),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _specialtyMap[_doctor!.specialtyId] ?? 'General Practitioner',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF006400)),
                              tooltip: 'Edit Profile',
                              onPressed: _showEditProfileDialog,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        InfoRow(label: 'Email', value: _doctor!.email ?? 'N/A'),
                        if (_doctor!.phone != null && _doctor!.phone!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          InfoRow(label: 'Phone', value: _doctor!.phone!),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 300),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Availability Schedule',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF003087),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF006400)),
                              tooltip: 'Edit Schedule',
                              onPressed: _showEditScheduleDialog,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_schedule == null || _schedule!.isEmpty)
                          const Text(
                            'No schedule set',
                            style: TextStyle(fontSize: 16, color: Colors.black87),
                          )
                        else
                          Column(
                            children: _schedule!.entries.map((entry) {
                              final day = entry.key;
                              final slots = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        day,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF003087),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: slots.map((slot) => Text(
                                          slot,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        )).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 300),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Availability Status',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF003087),
                              ),
                            ),
                            Switch(
                              value: _currentStatus == 'Available',
                              activeColor: const Color(0xFF006400),
                              inactiveThumbColor: const Color(0xFF8B0000),
                              inactiveTrackColor: const Color(0xFF8B0000).withOpacity(0.3),
                              onChanged: (value) async {
                                final newStatus = value ? 'Available' : 'Busy';
                                await _toggleStatus(newStatus);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _currentStatus ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _currentStatus == 'Available'
                                ? const Color(0xFF006400)
                                : const Color(0xFF8B0000),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 300),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Patient Reviews',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF003087),
                              ),
                            ),
                            if (_doctor!.reviews != null && _doctor!.reviews!.isNotEmpty)
                              Text(
                                'Avg: ${_calculateAverageRating(_doctor!.reviews).toStringAsFixed(1)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF003087),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_doctor!.reviews == null || _doctor!.reviews!.isEmpty)
                          const Text(
                            'No reviews yet',
                            style: TextStyle(fontSize: 16, color: Colors.black87),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _doctor!.reviews!.length,
                            itemBuilder: (context, index) {
                              final review = _doctor!.reviews![index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RatingBarIndicator(
                                      rating: (review['rating'] ?? 0.0).toDouble(),
                                      itemBuilder: (context, _) => const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                      ),
                                      itemCount: 5,
                                      itemSize: 20.0,
                                      direction: Axis.horizontal,
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
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF003087),
        foregroundColor: Colors.white,
        onPressed: _showEditProfileDialog,
        child: const Icon(Icons.edit),
        elevation: 4,
        tooltip: 'Edit Profile',
      ),
    );
  }
}

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