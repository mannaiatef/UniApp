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
        title: Text(specialty == null ? 'Add Specialty' : 'Edit Specialty'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _videoController,
                decoration: const InputDecoration(labelText: 'Video URL', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> confirmDelete(Specialty specialty) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete "${specialty.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
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
      appBar: AppBar(title: const Text('Specialties'), backgroundColor: Colors.blue.shade700),
      body: StreamBuilder<QuerySnapshot>(
        stream: _specialtyService.specialtiesRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final specialties = snapshot.data!.docs
              .map((doc) => Specialty.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();

          if (specialties.isEmpty) {
            return const Center(child: Text('No specialties found', style: TextStyle(fontSize: 16)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: specialties.length,
            itemBuilder: (context, index) {
              final specialty = specialties[index];
              return Card(
                elevation: 3,
                shadowColor: Colors.grey.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  title: Text(specialty.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: specialty.description != null && specialty.description!.isNotEmpty
                      ? Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(specialty.description!, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                  )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => showSpecialtyDialog(specialty: specialty)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => confirmDelete(specialty)),
                    ],
                  ),
                  onTap: () {
                    // navigate to detail screen with whole specialty object
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade700,
        onPressed: () => showSpecialtyDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
