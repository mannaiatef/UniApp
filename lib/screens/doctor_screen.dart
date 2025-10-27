import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/doctor.dart';
import '../services/doctor_service.dart';
import 'DoctorDetailScreen.dart';
import 'package:email_validator/email_validator.dart';

class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key});

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  final DoctorService _doctorService = DoctorService();
  final ImagePicker _picker = ImagePicker();

  Map<String, String> _specialtyMap = {};
  String _searchText = '';
  String? _selectedSpecialtyId;

  late Box _cacheBox;

  @override
  void initState() {
    super.initState();
    _cacheBox = Hive.box('cache');
    _loadSpecialtiesCache();
    _doctorService.syncWithFirebase();
    _doctorService.cleanDuplicateDoctors();
  }

  void _loadSpecialtiesCache() {
    final cached = _cacheBox.get('specialties', defaultValue: {});
    _specialtyMap = Map<String, String>.from(cached);
  }

  void _saveSpecialtiesCache(Map<String, String> specialties) {
    _cacheBox.put('specialties', specialties);
  }

  Future<String?> _saveImageToDocuments(File? imageFile, String doctorId) async {
    if (imageFile == null) return null;
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'doctor_$doctorId.jpg';
    final newPath = '${directory.path}/$fileName';
    await imageFile.copy(newPath);
    return newPath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Doctor Directory',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF003087),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.2),
      ),
      body: Container(
        color: Colors.grey[50],
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('specialties').snapshots(),
          builder: (context, specialtySnapshot) {
            if (specialtySnapshot.hasData) {
              _specialtyMap = {
                for (var doc in specialtySnapshot.data!.docs)
                  doc.id: (doc.data() as Map<String, dynamic>)['name'] ?? 'Unknown'
              };
              _saveSpecialtiesCache(_specialtyMap);
            }

            return Column(
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
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF003087), width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF003087), width: 2),
                            ),
                          ),
                          onChanged: (value) => setState(() => _searchText = value.toLowerCase()),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: 'Filter by Specialty',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF003087), width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF003087), width: 2),
                            ),
                          ),
                          value: _selectedSpecialtyId,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All Specialties', style: TextStyle(color: Colors.black54)),
                            ),
                            ..._specialtyMap.entries
                                .map((e) => DropdownMenuItem<String>(
                              value: e.key,
                              child: Text(e.value, style: const TextStyle(color: Color(0xFF003087))),
                            ))
                                .toList(),
                          ],
                          onChanged: (value) => setState(() => _selectedSpecialtyId = value),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: Hive.box<Doctor>('doctors').listenable(),
                    builder: (context, Box<Doctor> box, _) {
                      return StreamBuilder<List<Doctor>>(
                        stream: _doctorService.getDoctorsStream(),
                        builder: (context, doctorSnapshot) {
                          final localDoctors = _doctorService.getCachedDoctors();
                          final firebaseDoctors = doctorSnapshot.hasData ? doctorSnapshot.data! : [];
                          final allDoctorsMap = <String, Doctor>{};

                          for (var doctor in localDoctors) {
                            allDoctorsMap[doctor.id] = doctor;
                          }

                          for (var doctor in firebaseDoctors) {
                            allDoctorsMap[doctor.id] = doctor;
                          }

                          final doctors = allDoctorsMap.values.where((doctor) {
                            final matchesName = doctor.name.toLowerCase().contains(_searchText);
                            final matchesSpecialty =
                                _selectedSpecialtyId == null || doctor.specialtyId == _selectedSpecialtyId;
                            return matchesName && matchesSpecialty;
                          }).toList();

                          if (doctors.isEmpty) {
                            return const Center(
                              child: Text('No doctors found', style: TextStyle(fontSize: 16, color: Colors.black54)),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: doctors.length,
                            itemBuilder: (context, index) {
                              final doctor = doctors[index];
                              return DoctorCard(
                                doctor: doctor,
                                specialtyName: _specialtyMap[doctor.specialtyId] ?? 'Unknown',
                                onEdit: () => showDoctorDialog(doctor: doctor),
                                onDelete: () => confirmDelete(doctor.id),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDoctorDialog(),
        backgroundColor: const Color(0xFF003087),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  void confirmDelete(String doctorId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Confirm Deletion', style: TextStyle(color: Color(0xFF8B0000), fontWeight: FontWeight.w600)),
        content: const Text('Are you sure you want to delete this doctor?', style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF003087), fontWeight: FontWeight.w500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              try {
                await _doctorService.deleteDoctor(doctorId);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Doctor deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting doctor: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  void showDoctorDialog({Doctor? doctor}) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: doctor?.name ?? '');
    final _emailController = TextEditingController(text: doctor?.email ?? '');
    final _phoneController = TextEditingController(text: doctor?.phone ?? '');
    final _addressController = TextEditingController(text: doctor?.address ?? '');
    final _latitudeController = TextEditingController(text: doctor?.latitude?.toString() ?? '');
    final _longitudeController = TextEditingController(text: doctor?.longitude?.toString() ?? '');
    final _websiteController = TextEditingController(text: doctor?.website ?? '');
    final _facebookController = TextEditingController(text: doctor?.facebookUrl ?? '');
    final _twitterController = TextEditingController(text: doctor?.twitterUrl ?? '');
    final _biographyController = TextEditingController(text: doctor?.biography ?? '');
    String? selectedSpecialtyId = doctor?.specialtyId;
    File? pickedImage;
    bool _isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              doctor == null ? 'Add Doctor' : 'Edit Doctor',
              style: const TextStyle(
                color: Color(0xFF003087),
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setDialogState(() => pickedImage = File(image.path));
                        }
                      },
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: pickedImage != null
                            ? FileImage(pickedImage!)
                            : (doctor?.photoUrl != null &&
                            (doctor!.photoUrl!.startsWith('http') || File(doctor.photoUrl!).existsSync())
                            ? (doctor.photoUrl!.startsWith('http')
                            ? NetworkImage(doctor.photoUrl!)
                            : FileImage(File(doctor.photoUrl!)))
                            : null),
                        child: (pickedImage == null &&
                            (doctor?.photoUrl == null ||
                                (!doctor!.photoUrl!.startsWith('http') && !File(doctor.photoUrl!).existsSync())))
                            ? const Icon(Icons.camera_alt, size: 40, color: Color(0xFF003087))
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name *',
                        labelStyle: const TextStyle(color: Color(0xFF003087)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF003087), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF003087), width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 1.5),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the doctor\'s name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email *',
                        labelStyle: const TextStyle(color: Color(0xFF003087)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF003087), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF003087), width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 1.5),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an email';
                        }
                        if (!EmailValidator.validate(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone *',
                        labelStyle: const TextStyle(color: Color(0xFF003087)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF003087), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF003087), width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 1.5),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a phone number';
                        }
                        if (!RegExp(r'^\+?[\d\s-]{8,15}$').hasMatch(value)) {
                          return 'Enter a valid phone number (8-15 digits, e.g., +1234567890)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Address *',
                        labelStyle: const TextStyle(color: Color(0xFF003087)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF003087), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF003087), width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 1.5),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an address';
                        }
                        if (value.trim().length < 5) {
                          return 'Address must be at least 5 characters long';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latitudeController,
                            decoration: InputDecoration(
                              labelText: 'Latitude',
                              labelStyle: const TextStyle(color: Color(0xFF003087)),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF003087), width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF003087), width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 1.5),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final lat = double.tryParse(value);
                                if (lat == null || lat < -90 || lat > 90) {
                                  return 'Enter a valid latitude (-90 to 90)';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _longitudeController,
                            decoration: InputDecoration(
                              labelText: 'Longitude',
                              labelStyle: const TextStyle(color: Color(0xFF003087)),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF003087), width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF003087), width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 1.5),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final lon = double.tryParse(value);
                                if (lon == null || lon < -180 || lon > 180) {
                                  return 'Enter a valid longitude (-180 to 180)';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _websiteController,
                      decoration: InputDecoration(
                        labelText: 'Website',
                        labelStyle: const TextStyle(color: Color(0xFF003087)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF003087), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF003087), width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!RegExp(r'^https?://').hasMatch(value)) {
                            return 'Enter a valid URL (e.g., https://example.com)';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _facebookController,
                      decoration: InputDecoration(
                        labelText: 'Facebook URL',
                        labelStyle: const TextStyle(color: Color(0xFF003087)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF003087), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF003087), width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!RegExp(r'^https?://').hasMatch(value)) {
                            return 'Enter a valid URL (e.g., https://facebook.com)';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _twitterController,
                      decoration: InputDecoration(
                        labelText: 'Twitter URL',
                        labelStyle: const TextStyle(color: Color(0xFF003087)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF003087), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF003087), width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!RegExp(r'^https?://').hasMatch(value)) {
                            return 'Enter a valid URL (e.g., https://twitter.com)';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _biographyController,
                      decoration: InputDecoration(
                        labelText: 'Biography',
                        labelStyle: const TextStyle(color: Color(0xFF003087)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF003087), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF003087), width: 2),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedSpecialtyId,
                      decoration: InputDecoration(
                        labelText: 'Select Specialty *',
                        labelStyle: const TextStyle(color: Color(0xFF003087)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF003087), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF003087), width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 1.5),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                      ),
                      items: _specialtyMap.entries
                          .map((e) => DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(e.value, style: const TextStyle(color: Color(0xFF003087))),
                      ))
                          .toList(),
                      onChanged: (value) => setDialogState(() => selectedSpecialtyId = value),
                      validator: (value) => value == null ? 'Please select a specialty' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFF003087), fontWeight: FontWeight.w500),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003087),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _isSaving
                    ? null
                    : () async {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }

                  setDialogState(() => _isSaving = true);
                  try {
                    final doctorId = doctor?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

                    String? savedImagePath = await _saveImageToDocuments(pickedImage, doctorId);

                    if (doctor != null &&
                        pickedImage != null &&
                        doctor.photoUrl != null &&
                        !doctor.photoUrl!.startsWith('http')) {
                      final oldFile = File(doctor.photoUrl!);
                      if (oldFile.existsSync()) {
                        await oldFile.delete();
                      }
                    }

                    final doctorToSave = Doctor(
                      id: doctorId,
                      name: _nameController.text.trim(),
                      email: _emailController.text.trim(),
                      specialtyId: selectedSpecialtyId!,
                      phone: _phoneController.text.trim(),
                      address: _addressController.text.trim(),
                      latitude: double.tryParse(_latitudeController.text) ?? 0.0,
                      longitude: double.tryParse(_longitudeController.text) ?? 0.0,
                      photoUrl: savedImagePath ?? doctor?.photoUrl,
                      website: _websiteController.text.trim(),
                      facebookUrl: _facebookController.text.trim(),
                      twitterUrl: _twitterController.text.trim(),
                      biography: _biographyController.text.trim(),
                    );

                    if (doctor == null) {
                      await _doctorService.addDoctor(doctorToSave, imageFile: pickedImage);
                    } else {
                      await _doctorService.updateDoctor(doctorToSave, imageFile: pickedImage);
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(doctor == null ? 'Doctor added successfully' : 'Doctor updated successfully')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error saving doctor: $e')),
                    );
                  } finally {
                    setDialogState(() => _isSaving = false);
                  }
                },
                child: _isSaving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text(
                  'Save',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final String specialtyName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DoctorCard({
    super.key,
    required this.doctor,
    required this.specialtyName,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = doctor.photoUrl != null &&
        doctor.photoUrl!.isNotEmpty &&
        (doctor.photoUrl!.startsWith('http') || File(doctor.photoUrl!).existsSync());

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[200],
              backgroundImage: hasPhoto
                  ? (doctor.photoUrl!.startsWith('http')
                  ? NetworkImage(doctor.photoUrl!)
                  : FileImage(File(doctor.photoUrl!)))
                  : null,
              child: !hasPhoto
                  ? const Icon(Icons.person, size: 20, color: Color(0xFF003087))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                doctor.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF003087),
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            InfoField(label: 'Email', value: doctor.email),
            InfoField(label: 'Phone', value: doctor.phone!),
            InfoField(label: 'Address', value: doctor.address!),
            InfoField(label: 'Specialty', value: specialtyName),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF006400)),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Color(0xFF8B0000)),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DoctorDetailScreen(doctor: doctor)),
        ),
      ),
    );
  }
}

class InfoField extends StatelessWidget {
  final String label;
  final String value;

  const InfoField({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF003087),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}