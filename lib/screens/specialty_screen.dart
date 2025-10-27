import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _specialtyService.syncWithFirebase();
    _specialtyService.cleanDuplicateSpecialties();
    print('SpecialtyScreen init - Hive specialties: ${Hive.box<Specialty>('specialties').values.map((s) => "Specialty(id: ${s.id}, name: ${s.name})").toList()}');
    _searchController.addListener(() {
      setState(() => _searchText = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void showSpecialtyDialog({Specialty? specialty}) {
    final _nameController = TextEditingController(text: specialty?.name ?? '');
    final _descriptionController = TextEditingController(text: specialty?.description ?? '');
    final _videoController = TextEditingController(text: specialty?.videoUrl ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text(
          specialty == null ? 'Add Specialty' : 'Edit Specialty',
          style: const TextStyle(
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
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
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
            onPressed: _isSaving
                ? null
                : () async {
              if (_nameController.text.isEmpty) return;
              setState(() => _isSaving = true);
              try {
                final newSpecialty = Specialty(
                  id: specialty?.id ?? '',
                  name: _nameController.text,
                  description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
                  videoUrl: _videoController.text.isNotEmpty ? _videoController.text : null,
                );
                if (specialty == null) {
                  await _specialtyService.addSpecialty(newSpecialty);
                } else {
                  await _specialtyService.updateSpecialty(newSpecialty);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: const Color(0xFF8B0000),
                  ),
                );
              } finally {
                setState(() => _isSaving = false);
                Navigator.pop(context);
              }
            },
            child: _isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> confirmDelete(Specialty specialty) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: const Text(
          'Confirm Deletion',
          style: TextStyle(
            color: Color(0xFF8B0000),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${specialty.name}"?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF003087)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _specialtyService.deleteSpecialty(specialty.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Specialty Directory',
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search specialties...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF003087)),
                  filled: true,
                  fillColor: Colors.white,
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
            ),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box<Specialty>('specialties').listenable(),
                builder: (context, Box<Specialty> box, _) {
                  return StreamBuilder<List<Specialty>>(
                    stream: _specialtyService.getSpecialtiesStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF003087)));
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading specialties',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF8B0000),
                            ),
                          ),
                        );
                      }
                      final localSpecialties = _specialtyService.getCachedSpecialties();
                      final firebaseSpecialties = snapshot.hasData ? snapshot.data! : [];
                      final allSpecialtiesMap = <String, Specialty>{};

                      for (var specialty in localSpecialties) {
                        allSpecialtiesMap[specialty.id] = specialty;
                      }
                      for (var specialty in firebaseSpecialties) {
                        allSpecialtiesMap[specialty.id] = specialty;
                      }

                      final specialties = allSpecialtiesMap.values
                          .where((s) => s.name.toLowerCase().contains(_searchText))
                          .toList();

                      if (specialties.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.search_off, size: 48, color: Colors.black54),
                              const SizedBox(height: 8),
                              Text(
                                'No specialties found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: specialties.length,
                        itemBuilder: (context, index) {
                          final specialty = specialties[index];
                          return AnimatedOpacity(
                            opacity: 1.0,
                            duration: const Duration(milliseconds: 300),
                            child: Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              color: Colors.white,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                title: Text(
                                  specialty.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF003087),
                                  ),
                                ),
                                subtitle: specialty.description != null && specialty.description!.isNotEmpty
                                    ? Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    specialty.description!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                                    : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Color(0xFF006400)),
                                      onPressed: () => showSpecialtyDialog(specialty: specialty),
                                      tooltip: 'Edit specialty',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Color(0xFF8B0000)),
                                      onPressed: () => confirmDelete(specialty),
                                      tooltip: 'Delete specialty',
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
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF003087),
        foregroundColor: Colors.white,
        onPressed: () => showSpecialtyDialog(),
        child: const Icon(Icons.add),
        elevation: 4,
      ),
    );
  }
}