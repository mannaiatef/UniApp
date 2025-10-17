import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/doctor.dart';
import '../models/specialty.dart';
import 'SpecialtyDetailScreen.dart';
import 'DoctorLocationScreen.dart';

class DoctorDetailScreen extends StatefulWidget {
  final Doctor doctor;

  const DoctorDetailScreen({super.key, required this.doctor});

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  final _commentController = TextEditingController();
  double _rating = 0.0; // To store the selected rating

  void _showAddReviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Add Review',
          style: TextStyle(color: Color(0xFF003087), fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RatingBar.builder(
                initialRating: 0,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  setState(() {
                    _rating = rating;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  labelText: 'Comment (Optional)',
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
            ],
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
              if (_rating == 0.0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a rating')),
                );
                return;
              }

              final newReview = {
                'rating': _rating,
                'comment': _commentController.text.isEmpty ? null : _commentController.text,
                'date': DateTime.now().toIso8601String(),
              };

              await FirebaseFirestore.instance
                  .collection('doctors')
                  .doc(widget.doctor.id)
                  .update({
                'reviews': FieldValue.arrayUnion([newReview]),
              });

              _commentController.clear();
              setState(() {
                _rating = 0.0; // Reset rating
              });
              Navigator.pop(context);
              setState(() {}); // Refresh the screen
            },
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.doctor.name,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF003087),
        elevation: 4,
      ),
      body: Container(
        color: Colors.grey[100],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor photo
              Center(
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: (widget.doctor.photoUrl != null &&
                      widget.doctor.photoUrl!.isNotEmpty &&
                      File(widget.doctor.photoUrl!).existsSync())
                      ? FileImage(File(widget.doctor.photoUrl!))
                      : null,
                  child: (widget.doctor.photoUrl == null ||
                      widget.doctor.photoUrl!.isEmpty ||
                      !File(widget.doctor.photoUrl!).existsSync())
                      ? const Icon(Icons.person, size: 70, color: Color(0xFF003087))
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              // Info Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoRow(label: 'Name', value: widget.doctor.name),
                    const SizedBox(height: 12),
                    InfoRow(label: 'Email', value: widget.doctor.email),
                    if (widget.doctor.phone != null && widget.doctor.phone!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      InfoRow(label: 'Phone', value: widget.doctor.phone!),
                    ],
                    if (widget.doctor.biography != null && widget.doctor.biography!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      InfoRow(label: 'Biography', value: widget.doctor.biography!),
                    ],
                    if (widget.doctor.website != null && widget.doctor.website!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _launchURL(widget.doctor.website!, 'visit website', context),
                        child: InfoRow(label: 'Website', value: widget.doctor.website!),
                      ),
                    ],
                    if (widget.doctor.facebookUrl != null && widget.doctor.facebookUrl!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _launchURL(widget.doctor.facebookUrl!, 'visit Facebook', context),
                        child: InfoRow(label: 'Facebook', value: widget.doctor.facebookUrl!),
                      ),
                    ],
                    if (widget.doctor.twitterUrl != null && widget.doctor.twitterUrl!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _launchURL(widget.doctor.twitterUrl!, 'visit Twitter', context),
                        child: InfoRow(label: 'Twitter', value: widget.doctor.twitterUrl!),
                      ),
                    ],
                    if (widget.doctor.address != null && widget.doctor.address!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Address',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003087),
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          if (widget.doctor.latitude != null && widget.doctor.longitude != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DoctorLocationScreen(doctor: widget.doctor),
                              ),
                            );
                          }
                        },
                        child: Text(
                          widget.doctor.address!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF003087),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 12),
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('specialties')
                          .doc(widget.doctor.specialtyId)
                          .snapshots(),
                      builder: (context, specialtySnapshot) {
                        if (!specialtySnapshot.hasData || !specialtySnapshot.data!.exists) {
                          return const SizedBox();
                        }

                        final data = specialtySnapshot.data!.data() as Map<String, dynamic>;
                        final specialty = Specialty.fromMap(data, specialtySnapshot.data!.id);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Specialty',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF003087),
                              ),
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SpecialtyDetailScreen(specialty: specialty),
                                  ),
                                );
                              },
                              child: Text(
                                specialty.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF003087),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Reviews Card
              if (widget.doctor.reviews != null && widget.doctor.reviews!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Patient Reviews',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003087),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Average Rating
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              _calculateAverageRating(widget.doctor.reviews!).toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const Text(
                              '/5.0',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Reviews List
                        SizedBox(
                          height: 150, // Fixed height with scroll
                          child: ListView.builder(
                            itemCount: widget.doctor.reviews!.length,
                            itemBuilder: (context, index) {
                              final review = widget.doctor.reviews![index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${review['rating']} - ${review['comment'] ?? 'No comment'} (${_formatDate(review['date'])})',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              // Buttons at the bottom
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (widget.doctor.phone != null && widget.doctor.phone!.isNotEmpty)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _launchURL('tel:${widget.doctor.phone}', 'call', context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003087),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Call Doctor', style: TextStyle(fontSize: 16, color: Colors.white)),
                        ),
                      ),
                    if (widget.doctor.email.isNotEmpty)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: ElevatedButton(
                            onPressed: () => _launchURL('mailto:${widget.doctor.email}', 'email', context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003087),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Email Doctor', style: TextStyle(fontSize: 16, color: Colors.white)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Add Review Button
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003087),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _showAddReviewDialog,
                  child: const Text('Add Review', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateAverageRating(List<Map<String, dynamic>>? reviews) {
    if (reviews == null || reviews.isEmpty) return 0.0;
    final total = reviews.map((r) => r['rating'] as num).reduce((a, b) => a + b);
    return total / reviews.length;
  }

  String _formatDate(dynamic date) {
    if (date is String) {
      try {
        final dateTime = DateTime.parse(date);
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      } catch (e) {
        return 'Unknown Date';
      }
    }
    return 'Unknown Date';
  }

  // Updated _launchURL to bypass canLaunchUrl check
  void _launchURL(String url, String action, BuildContext context) async {
    final uri = Uri.parse(url);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm', style: TextStyle(color: Color(0xFF003087))),
        content: Text('Do you want to $action using an external app?', style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF003087))),
          ),
          TextButton(
            onPressed: () async {
              try {
                await launchUrl(uri);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to $action: $e', style: TextStyle(fontSize: 16))),
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Yes', style: TextStyle(color: Color(0xFF003087))),
          ),
        ],
      ),
    );
  }
}

// Helper widget for a neat label-value row
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF003087)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
      ],
    );
  }
}