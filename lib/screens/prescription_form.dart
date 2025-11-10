import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'medicine_form.dart';
import 'signature_screen.dart';
import '../services/sqlite_service.dart';
import '../services/cloud_sync_service.dart';
import '../config/current_user.dart';

class PrescriptionFormScreen extends StatefulWidget {
  const PrescriptionFormScreen({super.key});

  @override
  State<PrescriptionFormScreen> createState() => _PrescriptionFormScreenState();
}

class _PrescriptionFormScreenState extends State<PrescriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final SQLiteService _sqliteService = SQLiteService();

  final _patientNameController = TextEditingController();
  final _doctorNameController = TextEditingController(text: CurrentUser.name);
  final _dateController = TextEditingController();
  final _diagnosticController = TextEditingController();
  final _notesController = TextEditingController();

  List<Map<String, dynamic>> medicines = [];
  Uint8List? _doctorSignature;

  // Couleurs du thème
  static const Color primaryBlue = Color(0xFF006AF6);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color mediumBlue = Color(0xFF2196F3);
  static const Color accentBlue = Color(0xFF42A5F5);
  static const Color backgroundGrey = Color(0xFFF8FAFC);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A237E);
  static const Color textSecondary = Color(0xFF5C6BC0);
  static const Color textGrey = Color(0xFF78909C);
  static const Color dividerColor = Color(0xFFE0E7FF);

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _dateController.text =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _doctorNameController.dispose();
    _dateController.dispose();
    _diagnosticController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectPrescriptionDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              surface: cardWhite,
              onSurface: textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon, {bool isReadOnly = false}) {
    return InputDecoration(
      prefixIcon: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isReadOnly 
              ? lightBlue.withValues(alpha: 0.5)
              : primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isReadOnly ? textGrey : primaryBlue, size: 20),
      ),
      labelText: label,
      labelStyle: TextStyle(
        color: textGrey,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: isReadOnly ? lightBlue.withValues(alpha: 0.3) : cardWhite,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: dividerColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: dividerColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGrey,
      body: CustomScrollView(
        slivers: [
          // AppBar avec gradient bleu
          SliverAppBar(
            expandedHeight: 140.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: primaryBlue,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16, right: 20),
              title: const Text(
                "Nouvelle Prescription",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryBlue,
                      mediumBlue,
                      accentBlue,
                    ],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ),
          ),

          // Contenu du formulaire
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Informations de base
                    _buildSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader("Informations de Base", Icons.info_outline),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _patientNameController,
                            decoration: _inputDecoration('Nom du patient', Icons.person_outline),
                            style: const TextStyle(color: textPrimary, fontSize: 16),
                            validator: (v) => v!.isEmpty ? 'Veuillez entrer le nom du patient' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _doctorNameController,
                            readOnly: true,
                            decoration: _inputDecoration('Nom du médecin', Icons.medical_information_outlined, isReadOnly: true),
                            style: const TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _dateController,
                            readOnly: true,
                            decoration: _inputDecoration('Date de prescription', Icons.calendar_today_outlined, isReadOnly: true),
                            style: const TextStyle(color: textPrimary, fontSize: 16),
                            onTap: () => _selectPrescriptionDate(context),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section Diagnostic & Notes
                    _buildSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader("Diagnostic & Notes", Icons.description_outlined),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _diagnosticController,
                            decoration: _inputDecoration('Diagnostic', Icons.medical_services_outlined),
                            style: const TextStyle(color: textPrimary, fontSize: 16),
                            maxLines: 2,
                            validator: (v) => v!.isEmpty ? 'Veuillez entrer le diagnostic' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _notesController,
                            decoration: _inputDecoration('Notes du médecin', Icons.note_outlined),
                            style: const TextStyle(color: textPrimary, fontSize: 16),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section Médicaments
                    _buildSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionHeader("Médicaments Prescrits", Icons.medication_liquid),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: primaryBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "${medicines.length}",
                                  style: const TextStyle(
                                    color: primaryBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          if (medicines.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: lightBlue.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: dividerColor),
                              ),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.medication_outlined, size: 48, color: textGrey),
                                    const SizedBox(height: 12),
                                    Text(
                                      "Aucun médicament ajouté",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: textGrey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...medicines.asMap().entries.map((entry) {
                              final index = entry.key;
                              final medicine = entry.value;
                              return Padding(
                                padding: EdgeInsets.only(bottom: index < medicines.length - 1 ? 12 : 0),
                                child: _buildMedicineCard(medicine, index),
                              );
                            }),

                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: primaryBlue, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                backgroundColor: lightBlue.withValues(alpha: 0.3),
                              ),
                              icon: const Icon(Icons.add_circle_outline, color: primaryBlue, size: 24),
                              label: const Text(
                                "Ajouter un médicament",
                                style: TextStyle(
                                  color: primaryBlue,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => MedicineFormScreen(
                                    onAddMedicine: (med) {
                                      setState(() {
                                        medicines.add(med);
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section Signature
                    _buildSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader("Signature du Médecin", Icons.draw_outlined),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SignatureScreen(
                                    onSigned: (signature) {
                                      setState(() {
                                        _doctorSignature = signature;
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              height: 160,
                              decoration: BoxDecoration(
                                color: _doctorSignature == null 
                                    ? lightBlue.withValues(alpha: 0.3)
                                    : cardWhite,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _doctorSignature == null 
                                      ? dividerColor
                                      : primaryBlue,
                                  width: 2,
                                  style: _doctorSignature == null 
                                      ? BorderStyle.solid
                                      : BorderStyle.solid,
                                ),
                              ),
                              child: _doctorSignature == null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: primaryBlue.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.draw_outlined,
                                            color: primaryBlue,
                                            size: 32,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          "Appuyez pour signer",
                                          style: TextStyle(
                                            color: textPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "La signature est obligatoire",
                                          style: TextStyle(
                                            color: textGrey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 32,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          "Signature enregistrée",
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.memory(
                                            _doctorSignature!,
                                            height: 60,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Bouton d'enregistrement
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [primaryBlue, mediumBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            if (_doctorSignature == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.orange,
                                  content: const Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: Colors.white),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          "⚠️ Veuillez ajouter une signature avant d'enregistrer.",
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                              return;
                            }

                            if (medicines.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.orange,
                                  content: const Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: Colors.white),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          "⚠️ Veuillez ajouter au moins un médicament.",
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                              return;
                            }

                            final now = DateTime.now();
                            final uniqueNumber = now.millisecondsSinceEpoch % 100000;
                            final generatedId = 'RX-${now.year}-$uniqueNumber';

                            final prescription = {
                              'prescription_id': generatedId,
                              'patient_name': _patientNameController.text,
                              'doctor_id': CurrentUser.id,
                              'doctor_name': CurrentUser.name,
                              'date_prescription': _dateController.text,
                              'diagnostic': _diagnosticController.text,
                              'notes_medecin': _notesController.text,
                              'doctor_signature': _doctorSignature,
                              'created_at': DateTime.now().toIso8601String(),
                              'updated_at': DateTime.now().toIso8601String(),
                              'medicines': medicines,
                            };

                            try {
                              // Sauvegarde locale
                              await _sqliteService.insertPrescription(prescription);

                              // Publication Cloud (QR code)
                              await CloudSyncService().syncPrescriptionToFirebase(prescription);

                              if (!mounted) return;
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.green,
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.white),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            '✅ Prescription enregistrée avec ID : $generatedId',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }

                              if (mounted) {
                                Navigator.pop(context, true);
                              }
                            } catch (e) {
                              if (!mounted) return;
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.red,
                                    content: Row(
                                      children: [
                                        const Icon(Icons.error_outline, color: Colors.white),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            '❌ Erreur : $e',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_outlined, color: Colors.white, size: 24),
                            SizedBox(width: 12),
                            Text(
                              "Enregistrer la Prescription",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> medicine, int index) {
    return Container(
      decoration: BoxDecoration(
        color: lightBlue.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryBlue.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.medication_liquid,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          medicine['medicine_name'] ?? 'Médicament',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            "${medicine['dosage'] ?? '-'} • ${medicine['frequency'] ?? '-'} • ${medicine['duration'] ?? '-'} jours",
            style: TextStyle(
              color: textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () {
            setState(() {
              medicines.removeAt(index);
            });
          },
        ),
      ),
    );
  }
}