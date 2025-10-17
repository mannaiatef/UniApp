import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/specialty.dart';
import '../services/specialty_service.dart';
import 'SpecialtyDetailScreen.dart';

class SpecialtyScreen extends StatefulWidget {
  const SpecialtyScreen({super.key});

  @override
  State<SpecialtyScreen> createState() => _SpecialtyScreenState();
}

class _SpecialtyScreenState extends State<SpecialtyScreen> {
  final SpecialtyService _specialtyService = SpecialtyService();

  void showSpecialtyDialog({Specialty? specialty}) {
    final _nameController = TextEditingController(text: specialty?.name ?? '');
    final _descriptionController = TextEditingController(text: specialty?.description ?? '');
    final _videoController = TextEditingController(text: specialty?.videoUrl ?? ''); // new

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          specialty == null ? 'Add Specialty' : 'Edit Specialty',
          style: const TextStyle(color: Color(0xFF003087), fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
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
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF003087), width: 1),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: const TextStyle(color: Color(0xFF003087)),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF003087), width: 1),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _videoController,
                  decoration: InputDecoration(
                    labelText: 'Video URL',
                    labelStyle: const TextStyle(color: Color(0xFF003087)),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF003087), width: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF003087))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003087),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (_nameController.text.isEmpty) return;

              if (specialty == null) {
                await _specialtyService.addSpecialty(
                  Specialty(
                    id: '',
                    name: _nameController.text,
                    description: _descriptionController.text,
                    videoUrl: _videoController.text,
                  ),
                );
              } else {
                await _specialtyService.specialtiesRef.doc(specialty.id).update({
                  'name': _nameController.text,
                  'description': _descriptionController.text,
                  'videoUrl': _videoController.text,
                });
              }

              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> confirmDelete(Specialty specialty) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Confirm Deletion',
          style: TextStyle(color: Color(0xFF8B0000), fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${specialty.name}"?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF003087))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _specialtyService.specialtiesRef.doc(specialty.id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Specialty Directory',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF003087),
        elevation: 4,
      ),
      body: Container(
        color: Colors.grey[100],
        child: StreamBuilder<QuerySnapshot>(
          stream: _specialtyService.specialtiesRef.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            final specialties = snapshot.data!.docs
                .map((doc) => Specialty.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                .toList();

            if (specialties.isEmpty) {
              return const Center(
                child: Text(
                  'No specialties found',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: specialties.length,
              itemBuilder: (context, index) {
                final specialty = specialties[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 6,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.white,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    title: Text(
                      specialty.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF003087)),
                    ),
                    subtitle: specialty.description != null && specialty.description!.isNotEmpty
                        ? Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        specialty.description!,
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFF006400)),
                          onPressed: () => showSpecialtyDialog(specialty: specialty),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Color(0xFF8B0000)),
                          onPressed: () => confirmDelete(specialty),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SpecialtyDetailScreen(specialty: specialty),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF003087),
        onPressed: () => showSpecialtyDialog(),
        child: const Icon(Icons.add, color: Colors.white),
        elevation: 6,
      ),
    );
  }
}