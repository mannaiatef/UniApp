import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/doctor.dart';
import '../services/doctor_service.dart';
import 'DoctorDetailScreen.dart';
import 'DoctorLocationScreen.dart';

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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('specialties').snapshots(),
          builder: (context, specialtySnapshot) {
            if (!specialtySnapshot.hasData) return const Center(child: CircularProgressIndicator());

            _specialtyMap = {
              for (var doc in specialtySnapshot.data!.docs)
                doc.id: (doc.data() as Map<String, dynamic>)['name'] ?? 'Unknown'
            };

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
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF003087), width: 1),
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
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF003087), width: 1),
                            ),
                          ),
                          value: _selectedSpecialtyId,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Specialties')),
                            ..._specialtyMap.entries
                                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                                .toList(),
                          ],
                          onChanged: (value) => setState(() => _selectedSpecialtyId = value),
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Color(0xFF003087), fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
                    builder: (context, doctorSnapshot) {
                      if (!doctorSnapshot.hasData) return const Center(child: CircularProgressIndicator());

                      final doctors = doctorSnapshot.data!.docs
                          .map((doc) => Doctor.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                          .where((doctor) {
                        final matchesName = doctor.name.toLowerCase().contains(_searchText);
                        final matchesSpecialty = _selectedSpecialtyId == null || doctor.specialtyId == _selectedSpecialtyId;
                        return matchesName && matchesSpecialty;
                      }).toList();

                      if (doctors.isEmpty) return const Center(child: Text('No doctors found', style: TextStyle(fontSize: 16)));

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: doctors.length,
                        itemBuilder: (context, index) {
                          final doctor = doctors[index];
                          final specialtyName = _specialtyMap[doctor.specialtyId] ?? 'Unknown';

                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 6,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            color: Colors.white,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
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
                              title: Text(
                                doctor.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF003087)),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  InfoField(label: 'Email', value: doctor.email),
                                  if (doctor.phone != null && doctor.phone!.isNotEmpty)
                                    InfoField(label: 'Phone', value: doctor.phone!),
                                  if (doctor.address != null && doctor.address!.isNotEmpty)
                                    InfoField(label: 'Address', value: doctor.address!),

                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Color(0xFF006400)),
                                    onPressed: () => showDoctorDialog(doctor: doctor),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Color(0xFF8B0000)),
                                    onPressed: () => confirmDelete(doctor.id),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => DoctorDetailScreen(doctor: doctor)),
                                );
                              },
                            ),
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
        child: const Icon(Icons.add, color: Colors.white),
        elevation: 6,
      ),
    );
  }

  void confirmDelete(String doctorId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion', style: TextStyle(color: Color(0xFF8B0000))),
        content: const Text('Are you sure you want to delete this doctor?', style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF003087))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B0000)),
            onPressed: () async {
              await _doctorService.deleteDoctor(doctorId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void showDoctorDialog({Doctor? doctor}) {
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              doctor == null ? 'Add Doctor' : 'Edit Doctor',
              style: const TextStyle(color: Color(0xFF003087), fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                      if (image != null) setDialogState(() => pickedImage = File(image.path));
                    },
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: pickedImage != null
                          ? FileImage(pickedImage!)
                          : (doctor?.photoUrl != null && File(doctor!.photoUrl!).existsSync()
                          ? FileImage(File(doctor.photoUrl!))
                          : null),
                      child: (pickedImage == null &&
                          (doctor?.photoUrl == null || !File(doctor!.photoUrl!).existsSync()))
                          ? const Icon(Icons.camera_alt, size: 40, color: Color(0xFF003087))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name', labelStyle: TextStyle(color: Color(0xFF003087)))),
                  TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', labelStyle: TextStyle(color: Color(0xFF003087)))),
                  TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone', labelStyle: TextStyle(color: Color(0xFF003087)))),
                  TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address', labelStyle: TextStyle(color: Color(0xFF003087)))),
                  TextField(controller: _latitudeController, decoration: const InputDecoration(labelText: 'Latitude', labelStyle: TextStyle(color: Color(0xFF003087)))),
                  TextField(controller: _longitudeController, decoration: const InputDecoration(labelText: 'Longitude', labelStyle: TextStyle(color: Color(0xFF003087)))),
                  TextField(controller: _websiteController, decoration: const InputDecoration(labelText: 'Website', labelStyle: TextStyle(color: Color(0xFF003087)))),
                  TextField(controller: _facebookController, decoration: const InputDecoration(labelText: 'Facebook URL', labelStyle: TextStyle(color: Color(0xFF003087)))),
                  TextField(controller: _twitterController, decoration: const InputDecoration(labelText: 'Twitter URL', labelStyle: TextStyle(color: Color(0xFF003087)))),
                  TextField(controller: _biographyController, decoration: const InputDecoration(labelText: 'Biography', labelStyle: TextStyle(color: Color(0xFF003087))), maxLines: 3),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedSpecialtyId,
                    hint: const Text('Select Specialty', style: TextStyle(color: Color(0xFF003087))),
                    items: _specialtyMap.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(color: Color(0xFF003087)))))
                        .toList(),
                    onChanged: (value) => setDialogState(() => selectedSpecialtyId = value),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF003087), width: 1),
                      ),
                    ),
                    dropdownColor: Colors.white,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Color(0xFF003087)))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003087)),
                onPressed: () async {
                  if (_nameController.text.isEmpty || _emailController.text.isEmpty || selectedSpecialtyId == null) return;

                  String? photoPath = doctor?.photoUrl;
                  if (pickedImage != null) {
                    final appDir = await getApplicationDocumentsDirectory();
                    final fileName = 'doctor_${DateTime.now().millisecondsSinceEpoch}.jpg';
                    final localFile = await pickedImage!.copy('${appDir.path}/$fileName');
                    photoPath = localFile.path;
                  }

                  final newDoctor = Doctor(
                    id: doctor?.id ?? '',
                    name: _nameController.text,
                    email: _emailController.text,
                    specialtyId: selectedSpecialtyId!,
                    phone: _phoneController.text,
                    address: _addressController.text,
                    latitude: double.tryParse(_latitudeController.text),
                    longitude: double.tryParse(_longitudeController.text),
                    photoUrl: photoPath,
                    website: _websiteController.text,
                    facebookUrl: _facebookController.text,
                    twitterUrl: _twitterController.text,
                    biography: _biographyController.text,
                  );

                  if (doctor == null) {
                    await _doctorService.addDoctor(newDoctor);
                  } else {
                    await _doctorService.updateDoctor(newDoctor);
                  }

                  Navigator.pop(context);
                },
                child: const Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Reusable stacked label-value widget
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF003087)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
