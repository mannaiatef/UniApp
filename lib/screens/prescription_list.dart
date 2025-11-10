import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lottie/lottie.dart';
import 'prescription_details.dart';
import 'prescription_form.dart';
import '../theme/app_theme.dart';
import '../screens/home_screen.dart';
import '../services/sqlite_service.dart';

class PrescriptionListScreen extends StatefulWidget {
  const PrescriptionListScreen({super.key});

  @override
  State<PrescriptionListScreen> createState() => _PrescriptionListScreenState();
}

class _PrescriptionListScreenState extends State<PrescriptionListScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 1;
  late AnimationController _animationController;
  final SQLiteService _sqliteService = SQLiteService();
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _sqliteService.close();
    super.dispose();
  }

  DateTime? _safeParseDate(String dateStr) {
    if (dateStr.isEmpty) return null;

    try {
      // Essayer le format YYYY-MM-DD
      return DateTime.parse(dateStr);
    } catch (_) {
      try {
        // Essayer le format DD/MM/YYYY
        return DateFormat('dd/MM/yyyy').parse(dateStr);
      } catch (_) {
        // Essayer d'autres formats si nécessaire
        return null;
      }
    }
  }

  bool isSameDay(DateTime date1, DateTime date2) =>
      date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;

  bool isYesterday(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("🏠 Accueil (à implémenter)"),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else if (index == 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("👤 Profil (à implémenter)"),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _sqliteService.getPrescriptions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF006AF6)));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset('assets/images/empty.png', height: 180),
                  const SizedBox(height: 10),
                  const Text(
                    "Aucune prescription enregistrée",
                    style: TextStyle(
                      color: Colors.grey, 
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final prescriptions = snapshot.data!;
          final Map<String, List<Map<String, dynamic>>> grouped = {};

          for (var prescription in prescriptions) {
            final dateStr = prescription['date_prescription'] ?? '';
            DateTime? date = _safeParseDate(dateStr);

            if (date == null && prescription['created_at'] != null) {
              try {
                date = DateTime.parse(prescription['created_at']);
              } catch (_) {
                date = DateTime.now();
              }
            } else if (date == null) {
              date = DateTime.now();
            }

            String key;
            final now = DateTime.now();
            if (isSameDay(date, now)) {
              key = "Aujourd'hui";
            } else if (isYesterday(date)) {
              key = "Hier";
            } else {
              key = DateFormat('dd MMM yyyy', 'fr').format(date);
            }

            grouped.putIfAbsent(key, () => []).add(prescription);
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Forcer le rechargement des données
              setState(() {});
            },
            child: CustomScrollView(
              slivers: [
              // 🔹 EN-TÊTE MODERNE
              SliverAppBar(
                pinned: true,
                floating: true,
                elevation: 0,
                backgroundColor: const Color(0xFF006AF6),
                expandedHeight: 180,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF006AF6),
                          const Color(0xFF0055CC),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(width: 40),
                                const Expanded(
                                  child: Center(
                                    child: Text(
                                      "Mes Prescriptions",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        onPressed: () {},
                                        icon: const Icon(Icons.search,
                                            color: Colors.white, size: 22),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        onPressed: () {},
                                        icon: const Icon(Icons.filter_alt_outlined,
                                        color: Colors.white, size: 22),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Remplacer l'animation par un compteur élégant
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF006AF6).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.medical_services_outlined,
                                    color: Color(0xFF006AF6),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Prescriptions actives",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      "${prescriptions.length} ordonnances",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              ...grouped.entries.map((entry) {
                return SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // En-tête de section de date avec design amélioré
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        entry.key == "Aujourd’hui"
                                            ? Icons.today_rounded
                                            : entry.key == "Hier"
                                                ? Icons.history_rounded
                                                : Icons.calendar_month_rounded,
                                        color: AppTheme.primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      entry.key,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "${entry.value.length}",
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Cartes prescriptions
                          ...entry.value.map((prescription) {
                            return _buildPrescriptionCard(context, prescription, prescription['id'].toString());
                          }).toList(),
                        ],
                      ),
                    ),
                  ]),
                );
              }).toList(),
            ],
          ),
        );
        },
      ),

      // ✅ Bouton flottant
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PrescriptionFormScreen()),
          );
          
          // Si une nouvelle prescription a été ajoutée via SQLite, forcer le rechargement
          if (result == true && mounted) {
            setState(() {});
          }
        },
        backgroundColor: const Color(0xFF006AF6),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(40))),
        child: const Icon(Icons.add, size: 30, color: Color(0xFFFFFFFF)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ✅ Navbar
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        color: Colors.white,
        elevation: 8,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: _NavItem(
                    icon: Icons.home_rounded, 
                    label: "Accueil", 
                    isSelected: _selectedIndex == 0,
                    onTap: () => _onItemTapped(0),
                  ),
                ),
                const SizedBox(width: 50),
                Flexible(
                  child: _NavItem(
                    icon: Icons.person_rounded, 
                    label: "Profil", 
                    isSelected: _selectedIndex == 2,
                    onTap: () => _onItemTapped(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrescriptionCard(BuildContext context, Map<String, dynamic> data, String docId) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PrescriptionDetailsScreen(
              prescriptionData: data,
              documentId: docId,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.medical_services_outlined,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Dr. ${data['doctor_name'] ?? 'Inconnu'}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF2D3142),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                data['patient_name'] ?? 'Patient inconnu',
                                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (data['diagnostic'] != null && data['diagnostic'].isNotEmpty)
                          Row(
                            children: [
                              Icon(Icons.assignment_outlined, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  data['diagnostic'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    fontStyle: FontStyle.italic,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      QrImageView(
                        data: docId,
                        version: QrVersions.auto,
                        size: 50.0,
                        gapless: false,
                        errorStateBuilder: (cxt, err) {
                          return const Center(
                            child: Text(
                              'Erreur QR',
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Builder(builder: (context) {
                        final dateStr = data['date_prescription'] ?? '';
                        DateTime? date = _safeParseDate(dateStr);
                        if (date == null && data['created_at'] != null) {
                          try {
                            date = DateTime.parse(data['created_at']);
                          } catch (_) {
                            date = DateTime.now();
                          }
                        } else if (date == null) {
                          date = DateTime.now();
                        }

                        return Text(
                          DateFormat('dd/MM/yy').format(date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    Key? key,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? const Color(0xFF006AF6) : Colors.grey, size: 24),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF006AF6) : Colors.grey,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
