import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'prescription_form.dart';
import 'prescription_list.dart';
import '../services/sqlite_service.dart';
import '../services/cloud_sync_service.dart';

class PrescriptionDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> prescriptionData;
  final String documentId;

  const PrescriptionDetailsScreen({
    super.key,
    required this.prescriptionData,
    required this.documentId,
  });

  @override
  State<PrescriptionDetailsScreen> createState() =>
      _PrescriptionDetailsScreenState();
}

class _PrescriptionDetailsScreenState extends State<PrescriptionDetailsScreen> {
  int _selectedIndex = 1;
  bool _isUploading = false;

  // Couleurs du thème bleu et blanc
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

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PrescriptionListScreen()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PrescriptionFormScreen()),
      );
    } else if (index == 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("👤 Profil (à implémenter)")),
      );
    }
  }

  Future<void> _publishToFirebase() async {
    setState(() => _isUploading = true);
    final cloudSync = CloudSyncService();

    try {
      await cloudSync.syncPrescriptionToFirebase(widget.prescriptionData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("✅ Prescription publiée dans Firebase !"),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("⚠️ Erreur de publication : $e"),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.prescriptionData;
    final signatureData = data['doctor_signature'];
    final String prescriptionId = data['prescription_id'] ?? '---';
    final String doctorName = data['doctor_name'] ?? 'Inconnu';
    final String patientName = data['patient_name'] ?? 'Inconnu';
    final String datePrescription = data['date_prescription'] ?? '---';
    final String diagnostic = data['diagnostic'] ?? 'Aucun diagnostic';
    final String notes = data['notes_medecin'] ?? 'Aucune note';

    return Scaffold(
      backgroundColor: backgroundGrey,
      body: CustomScrollView(
        slivers: [
          // AppBar avec gradient bleu élégant
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: primaryBlue,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              if (!_isUploading)
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: _publishToFirebase,
                    icon: const Icon(Icons.cloud_upload, color: Colors.white),
                    tooltip: "Publier dans Firebase",
                  ),
                ),
              if (_isUploading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16, right: 20),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Prescription Médicale",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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

          // Contenu principal
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Informations principales
                  _buildInfoSection(doctorName, patientName, datePrescription),
                  
                  const SizedBox(height: 24),

                  // Section Diagnostic & Notes
                  _buildDiagnosticSection(diagnostic, notes),

                  const SizedBox(height: 24),

                  // Section Médicaments
                  _buildMedicinesSection(prescriptionId),

                  const SizedBox(height: 24),

                  // Section Signature & QR Code
                  _buildSignatureSection(signatureData, prescriptionId),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: cardWhite,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            color: Colors.transparent,
            elevation: 0,
            child: SizedBox(
              height: 70,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNavItem(Icons.home_rounded, "Accueil", 0),
                    const SizedBox(width: 50),
                    _buildNavItem(Icons.person_rounded, "Profil", 2),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),

      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [primaryBlue, mediumBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrescriptionFormScreen()),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, size: 28, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // Section Informations principales
  Widget _buildInfoSection(String doctorName, String patientName, String date) {
    return _buildSectionCard(
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.person_outline,
            label: "Médecin",
            value: doctorName,
            iconColor: primaryBlue,
          ),
          const Divider(height: 24, color: dividerColor),
          _buildInfoRow(
            icon: Icons.badge_outlined,
            label: "Patient",
            value: patientName,
            iconColor: accentBlue,
          ),
          const Divider(height: 24, color: dividerColor),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: "Date",
            value: date,
            iconColor: mediumBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textGrey,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Section Diagnostic & Notes
  Widget _buildDiagnosticSection(String diagnostic, String notes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Diagnostic & Notes Médicales"),
        const SizedBox(height: 16),
        _buildSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.medical_services_outlined,
                      color: primaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Diagnostic",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                diagnostic,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.note_outlined,
                      color: accentBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Notes du Médecin",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                notes,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Section Médicaments
  Widget _buildMedicinesSection(String prescriptionId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Médicaments Prescrits"),
        const SizedBox(height: 16),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: SQLiteService().getMedicines(prescriptionId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: CircularProgressIndicator(
                    color: primaryBlue,
                    strokeWidth: 3,
                  ),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildSectionCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.medication_outlined, size: 48, color: textGrey),
                        const SizedBox(height: 12),
                        Text(
                          "Aucun médicament prescrit",
                          style: TextStyle(
                            fontSize: 16,
                            color: textGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final meds = snapshot.data!;
            return Column(
              children: meds.asMap().entries.map((entry) {
                final index = entry.key;
                final med = entry.value;
                final effects = med['effects_description']?.toString().trim() ?? '';
                final hasEffects = effects.isNotEmpty;

                return Padding(
                  padding: EdgeInsets.only(bottom: index < meds.length - 1 ? 16 : 0),
                  child: _buildMedicineCard(med, effects, hasEffects),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> med, String effects, bool hasEffects) {
    return Container(
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: lightBlue,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header du médicament
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  lightBlue,
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.medication_liquid,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med['medicine_name'] ?? 'Médicament inconnu',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "Prescription",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: primaryBlue,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Détails du médicament
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMedicineDetail(
                  icon: Icons.science_outlined,
                  label: "Dosage",
                  value: med['dosage'] ?? '-',
                ),
                const SizedBox(height: 16),
                _buildMedicineDetail(
                  icon: Icons.access_time_outlined,
                  label: "Fréquence",
                  value: med['frequency'] ?? '-',
                ),
                const SizedBox(height: 16),
                _buildMedicineDetail(
                  icon: Icons.calendar_month_outlined,
                  label: "Durée",
                  value: "${med['duration'] ?? '-'} jours",
                ),
              ],
            ),
          ),

          // Effets secondaires
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasEffects ? lightBlue : Colors.orange[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasEffects
                    ? primaryBlue.withValues(alpha: 0.3)
                    : Colors.orange.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      hasEffects ? Icons.info_outline : Icons.hourglass_empty,
                      color: hasEffects ? primaryBlue : Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasEffects ? "Effets Secondaires" : "En cours de récupération",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: hasEffects ? primaryBlue : Colors.orange[800],
                      ),
                    ),
                  ],
                ),
                if (hasEffects) ...[
                  const SizedBox(height: 12),
                  Text(
                    effects,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),
          
          // Avertissement
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, 
                    color: Colors.orange[700], 
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Informations indicatives. Consultez votre médecin ou pharmacien.",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange[900],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMedicineDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: textGrey, size: 20),
        const SizedBox(width: 12),
        Text(
          "$label: ",
          style: const TextStyle(
            fontSize: 14,
            color: textGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Section Signature & QR Code
  Widget _buildSignatureSection(dynamic signatureData, String prescriptionId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Signature & QR Code"),
        const SizedBox(height: 16),
        _buildSectionCard(
          child: Column(
            children: [
              // Signature
              if (signatureData != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: lightBlue.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryBlue.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.draw_outlined, color: primaryBlue, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Signature du Médecin",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          signatureData is List
                              ? Uint8List.fromList(signatureData.cast<int>())
                              : signatureData,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ] else
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.edit_note, size: 48, color: textGrey),
                      const SizedBox(height: 12),
                      Text(
                        "Aucune signature enregistrée",
                        style: TextStyle(
                          fontSize: 14,
                          color: textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // QR Code
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: lightBlue,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2_outlined, color: primaryBlue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Code QR de la Prescription",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: lightBlue,
                          width: 1,
                        ),
                      ),
                      child: QrImageView(
                        data: "https://medassist-e6135.web.app/prescription.html?doc=$prescriptionId",
                        version: QrVersions.auto,
                        size: 180,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: textPrimary,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Scannez pour voir la prescription",
                      style: TextStyle(
                        fontSize: 12,
                        color: textGrey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Composants réutilisables
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
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

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryBlue : textGrey,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryBlue : textGrey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}