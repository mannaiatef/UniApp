import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient.dart';
import '../services/auth_service.dart';
import '../services/image_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();
  
  File? _imageFile;
  bool _isLoading = false;
  Patient? _currentPatient;
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Utiliser addPostFrameCallback pour s'assurer que le contexte est prêt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPatientData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Recharger les données quand l'app revient au premier plan
    if (state == AppLifecycleState.resumed && _hasLoadedOnce) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPatientData();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharger les données si nécessaire quand les dépendances changent
    if (_currentPatient == null && !_isLoading && !_hasLoadedOnce) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPatientData();
      });
    }
  }

  Future<void> _loadPatientData() async {
    if (!mounted) return;
    
    // Éviter les chargements multiples simultanés
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Attendre un peu pour s'assurer que le contexte est complètement prêt
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted) return;
      
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Vérifier directement dans SharedPreferences si l'utilisateur est connecté
      final prefs = await SharedPreferences.getInstance();
      final emailFromPrefs = prefs.getString('user_email');
      
      if (!mounted) return;
      
      // Si pas d'email dans SharedPreferences, l'utilisateur n'est vraiment pas connecté
      if (emailFromPrefs == null || emailFromPrefs.isEmpty) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorSnackBar('Vous devez être connecté pour voir votre profil');
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
        return;
      }
      
      // Récupérer le patient
      final patient = await authService.getCurrentPatient();
      
      if (!mounted) return;
    
      if (patient != null) {
        // Mettre à jour l'état de manière atomique
        setState(() {
          _currentPatient = patient;
          _nomController.text = patient.nom;
          _prenomController.text = patient.prenom;
          _emailController.text = patient.email;
          _telephoneController.text = patient.telephone ?? '';
          _adresseController.text = patient.adresse ?? '';
          _imageFile = null; // Reset image file
          _hasLoadedOnce = true; // Marquer comme chargé
        });
        
        // Charger l'image si elle existe (après avoir mis à jour l'état)
        if (patient.photoUrl != null && patient.photoUrl!.isNotEmpty) {
          try {
            final file = File(patient.photoUrl!);
            if (await file.exists()) {
              if (mounted) {
                setState(() {
                  _imageFile = file;
                });
              }
            } else {
              // Si le fichier n'existe pas, nettoyer la photoUrl dans la base
              if (mounted) {
                final updatedPatient = patient.copyWith(photoUrl: null);
                await authService.updatePatient(updatedPatient);
              }
            }
          } catch (e) {
            // Si l'image n'existe pas, continuer sans image
            if (mounted) {
              // Nettoyer la photoUrl invalide
              final updatedPatient = patient.copyWith(photoUrl: null);
              await authService.updatePatient(updatedPatient);
            }
          }
        }
      } else {
        // Email existe dans SharedPreferences mais patient non trouvé dans la DB
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorSnackBar('Aucune donnée trouvée pour votre profil. Veuillez vous reconnecter.');
        }
        return;
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Erreur lors du chargement du profil: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      // Afficher un dialogue pour choisir entre la caméra et la galerie
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Choisir une source'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  GestureDetector(
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(Icons.photo_library, color: Colors.blue),
                          SizedBox(width: 10),
                          Text('Galerie'),
                        ],
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _getImage(ImageSource.gallery);
                    },
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(Icons.camera_alt, color: Colors.blue),
                          SizedBox(width: 10),
                          Text('Caméra'),
                        ],
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _getImage(ImageSource.camera);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erreur lors de la sélection de l\'image: $e');
      }
    }
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      if (!mounted) return;
      final imageFile = await ImageService().pickImage(context, source: source);
      
      if (imageFile != null && mounted) {
        setState(() {
          _imageFile = imageFile;
        });
      }
    } catch (e) {
      if (mounted) {
      _showErrorSnackBar('Erreur lors de la sélection de l\'image: $e');
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate() || _currentPatient == null) {
      return;
    }

    if (!mounted) return;
      setState(() => _isLoading = true);
      
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        
        // Préparer l'URL de la photo
        String? photoUrl = _currentPatient!.photoUrl;
      
      // Si une nouvelle image a été sélectionnée, la sauvegarder
      if (_imageFile != null) {
        // Vérifier si c'est une nouvelle image (pas la même que celle actuelle)
        if (_currentPatient!.photoUrl == null || 
            _imageFile!.path != _currentPatient!.photoUrl) {
          // Supprimer l'ancienne image si elle existe
          if (_currentPatient!.photoUrl != null && _currentPatient!.photoUrl!.isNotEmpty) {
            try {
              final oldFile = File(_currentPatient!.photoUrl!);
              if (await oldFile.exists()) {
                await oldFile.delete();
              }
            } catch (e) {
              // Ignorer les erreurs de suppression de l'ancienne image
            }
          }
          
          // Sauvegarder la nouvelle image
          photoUrl = await ImageService.saveImage(_imageFile!);
        }
      }
      
      // Créer le patient mis à jour
        final updatedPatient = _currentPatient!.copyWith(
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
        telephone: _telephoneController.text.trim().isEmpty 
            ? null 
            : _telephoneController.text.trim(),
        adresse: _adresseController.text.trim().isEmpty 
            ? null 
            : _adresseController.text.trim(),
          photoUrl: photoUrl,
        );
        
      // Mettre à jour dans la base de données
        final success = await authService.updatePatient(updatedPatient);
      
      if (!mounted) return;
      
      if (success) {
        // Recharger les données depuis la base de données pour s'assurer qu'elles sont à jour
        // Attendre un peu pour s'assurer que la base de données est à jour
        await Future.delayed(const Duration(milliseconds: 200));
        
        final refreshedPatient = await authService.getCurrentPatient();
        
        if (!mounted) return;
        
        if (refreshedPatient != null) {
          // Mettre à jour l'état de manière atomique
          setState(() {
            _currentPatient = refreshedPatient;
            _nomController.text = refreshedPatient.nom;
            _prenomController.text = refreshedPatient.prenom;
            _emailController.text = refreshedPatient.email;
            _telephoneController.text = refreshedPatient.telephone ?? '';
            _adresseController.text = refreshedPatient.adresse ?? '';
            
            // Mettre à jour l'image si nécessaire
            if (refreshedPatient.photoUrl != null && refreshedPatient.photoUrl!.isNotEmpty) {
              try {
                final file = File(refreshedPatient.photoUrl!);
                if (file.existsSync()) {
                  _imageFile = file;
                } else {
                  _imageFile = null;
                }
              } catch (e) {
                _imageFile = null;
              }
            } else {
              _imageFile = null;
            }
          });
        }
        
        // Afficher le message de succès
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Profil mis à jour avec succès'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        
        // Attendre un peu pour que l'utilisateur voie le message, puis retourner à la page d'accueil
        await Future.delayed(const Duration(milliseconds: 500));
          
        // Retour à l'écran précédent (HomeScreen)
        if (mounted) {
          Navigator.of(context).pop(true); // Retourner true pour indiquer une mise à jour
        }
      } else {
        if (mounted) {
          _showErrorSnackBar('Erreur lors de la mise à jour du profil');
        }
      }
      } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erreur: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Widget _buildProfileImage() {
    // Priorité à _imageFile (image sélectionnée mais pas encore sauvegardée)
    if (_imageFile != null) {
      try {
        if (_imageFile!.existsSync()) {
          return Image.file(
            _imageFile!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultAvatar();
            },
          );
        }
      } catch (e) {
        // Si erreur, utiliser l'avatar par défaut
      }
    }
    
    // Sinon, utiliser photoUrl du patient
    if (_currentPatient?.photoUrl != null && _currentPatient!.photoUrl!.isNotEmpty) {
      try {
        final file = File(_currentPatient!.photoUrl!);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultAvatar();
            },
          );
        }
      } catch (e) {
        // Si erreur, utiliser l'avatar par défaut
      }
    }
    
    // Avatar par défaut
    return _buildDefaultAvatar();
  }
  
  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.person, size: 60, color: Colors.grey),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadPatientData,
            tooltip: 'Recharger les données',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _updateProfile,
            tooltip: 'Enregistrer les modifications',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue.shade100, Colors.white],
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.blue.shade800, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _buildProfileImage(),
                            ),
                          ),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade800,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nomController,
                                decoration: InputDecoration(
                                  labelText: 'Nom',
                                  prefixIcon: const Icon(Icons.person),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre nom';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _prenomController,
                                decoration: InputDecoration(
                                  labelText: 'Prénom',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre prénom';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: const Icon(Icons.email),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                ),
                                readOnly: true, // L'email ne peut pas être modifié
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _telephoneController,
                                decoration: InputDecoration(
                                  labelText: 'Téléphone',
                                  prefixIcon: const Icon(Icons.phone),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _adresseController,
                                decoration: InputDecoration(
                                  labelText: 'Adresse',
                                  prefixIcon: const Icon(Icons.home),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                ),
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Mettre à jour le profil',
                                style: TextStyle(fontSize: 18),
                              ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

}