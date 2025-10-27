import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For clipboard
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
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
  double _rating = 0.0;
  bool _isReviewsExpanded = false;
  final GlobalKey _shareButtonKey = GlobalKey();

  void _showAddReviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Add Review',
          style: TextStyle(
            color: Color(0xFF003087),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
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
            ],
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
            onPressed: () async {
              if (_rating == 0.0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a rating')),
                );
                return;
              }

              try {
                final newReview = {
                  'rating': _rating,
                  'comment': _commentController.text.isEmpty ? null : _commentController.text.trim(),
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
                  _rating = 0.0;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Review added successfully')),
                );
                setState(() {}); // Refresh the screen
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error adding review: $e')),
                );
              }
            },
            child: const Text(
              'Submit',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookAppointmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Book Appointment',
          style: TextStyle(
            color: Color(0xFF003087),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        content: const Text(
          'Appointment booking is coming soon! Please contact the doctor directly.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF003087), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateProfileCompletion() {
    int totalFields = 8;
    int filledFields = 0;
    if (widget.doctor.name.isNotEmpty) filledFields++;
    if (widget.doctor.email?.isNotEmpty ?? false) filledFields++;
    if (widget.doctor.phone?.isNotEmpty ?? false) filledFields++;
    if (widget.doctor.address?.isNotEmpty ?? false) filledFields++;
    if (widget.doctor.biography?.isNotEmpty ?? false) filledFields++;
    if (widget.doctor.website?.isNotEmpty ?? false) filledFields++;
    if (widget.doctor.facebookUrl?.isNotEmpty ?? false) filledFields++;
    if (widget.doctor.twitterUrl?.isNotEmpty ?? false) filledFields++;
    return (filledFields / totalFields) * 100;
  }

  void _shareProfile() {
    final RenderBox? renderBox = _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
    Rect? shareRect;

    if (renderBox != null) {
      final offset = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      shareRect = offset & size;
    } else {
      shareRect = const Rect.fromLTWH(50, 50, 100, 100);
    }

    Share.share(
      'Check out Dr. ${widget.doctor.name}\'s profile: https://example.com/doctors/${widget.doctor.id}',
      subject: 'Dr. ${widget.doctor.name} Profile',
      sharePositionOrigin: shareRect,
    );
  }

  Future<bool> _canLaunchPhone(String? phone) async {
    print('Checking phone: $phone'); // Debug log
    if (phone == null || phone.isEmpty) {
      print('Phone is null or empty');
      return false;
    }
    // Relaxed validation: allow any non-empty string with at least one digit
    final cleanedPhone = phone.replaceAll(RegExp(r'[^0-9+\-\(\) ]'), '');
    if (!RegExp(r'[0-9]').hasMatch(cleanedPhone)) {
      print('Phone invalid: no digits in $cleanedPhone');
      return false;
    }
    final uri = Uri.parse('tel:$cleanedPhone');
    final canLaunch = await canLaunchUrl(uri);
    print('Can launch tel:$cleanedPhone: $canLaunch');
    return canLaunch;
  }

  Future<bool> _canLaunchEmail(String? email) async {
    print('Checking email: $email'); // Debug log
    if (email == null || email.isEmpty) {
      print('Email is null or empty');
      return false;
    }
    // Relaxed email validation
    if (!RegExp(r'^.+@.+\..+$').hasMatch(email)) {
      print('Email invalid: $email');
      return false;
    }
    final uri = Uri.parse('mailto:$email');
    final canLaunch = await canLaunchUrl(uri);
    print('Can launch mailto:$email: $canLaunch');
    return canLaunch;
  }

  void _launchURL(String url, String action, BuildContext context) async {
    print('Attempting to launch: $url'); // Debug log
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback for iOS Simulator or devices without phone/email app
        if (action == 'call' && Platform.isIOS) {
          final phone = url.replaceFirst('tel:', '');
          await Clipboard.setData(ClipboardData(text: phone));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No phone app available. Phone number copied to clipboard.'),
              action: SnackBarAction(
                label: 'OK',
                onPressed: () {},
              ),
            ),
          );
        } else if (action == 'email' && Platform.isIOS) {
          final email = url.replaceFirst('mailto:', '');
          await Clipboard.setData(ClipboardData(text: email));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No email client available. Email address copied to clipboard.'),
              action: SnackBarAction(
                label: 'OK',
                onPressed: () {},
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                action == 'call'
                    ? 'Cannot make a call. Invalid number or no phone app available.'
                    : 'Cannot send email. Invalid email or no email client available.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error launching $url: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error performing $action: $e')),
      );
    }
  }

  void _copyToClipboard(String text, String type) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type copied to clipboard'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
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
    // Debug log to check data
    print('Doctor data: phone=${widget.doctor.phone}, email=${widget.doctor.email}');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.doctor.name,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF003087),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.2),
        actions: [
          IconButton(
            key: _shareButtonKey,
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareProfile,
            tooltip: 'Share Profile',
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[50],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: (widget.doctor.photoUrl != null &&
                          widget.doctor.photoUrl!.isNotEmpty &&
                          (widget.doctor.photoUrl!.startsWith('http') || File(widget.doctor.photoUrl!).existsSync()))
                          ? (widget.doctor.photoUrl!.startsWith('http')
                          ? NetworkImage(widget.doctor.photoUrl!)
                          : FileImage(File(widget.doctor.photoUrl!)))
                          : null,
                      child: (widget.doctor.photoUrl == null ||
                          widget.doctor.photoUrl!.isEmpty ||
                          (!widget.doctor.photoUrl!.startsWith('http') && !File(widget.doctor.photoUrl!).existsSync()))
                          ? const Icon(Icons.person, size: 60, color: Color(0xFF003087))
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.doctor.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF003087),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('specialties')
                          .doc(widget.doctor.specialtyId)
                          .snapshots(),
                      builder: (context, specialtySnapshot) {
                        if (!specialtySnapshot.hasData || !specialtySnapshot.data!.exists) {
                          return const Text(
                            'Unknown Specialty',
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                          );
                        }
                        final data = specialtySnapshot.data!.data() as Map<String, dynamic>;
                        final specialty = Specialty.fromMap(data, specialtySnapshot.data!.id);
                        return GestureDetector(
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
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _calculateProfileCompletion() / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF003087)),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Profile Completion: ${_calculateProfileCompletion().toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Contact Info Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contact Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF003087),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InfoRow(
                        label: 'Email',
                        value: widget.doctor.email?.isNotEmpty ?? false ? widget.doctor.email! : 'No email provided',
                        valueStyle: widget.doctor.email?.isNotEmpty ?? false
                            ? const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black87,
                        )
                            : const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: (widget.doctor.phone?.isNotEmpty ?? false)
                            ? () => _launchURL('tel:${widget.doctor.phone!}', 'call', context)
                            : null,
                        onLongPress: (widget.doctor.phone?.isNotEmpty ?? false)
                            ? () => _copyToClipboard(widget.doctor.phone!, 'Phone number')
                            : null,
                        child: InfoRow(
                          label: 'Phone',
                          value: widget.doctor.phone?.isNotEmpty ?? false ? widget.doctor.phone! : 'No phone number',
                          valueStyle: widget.doctor.phone?.isNotEmpty ?? false
                              ? const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF003087),
                            decoration: TextDecoration.underline,
                          )
                              : const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          if (widget.doctor.latitude != null && widget.doctor.longitude != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DoctorLocationScreen(doctor: widget.doctor),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  widget.doctor.address?.isNotEmpty ?? false
                                      ? 'Location coordinates are not available. Showing map with address.'
                                      : 'No address or coordinates available.',
                                ),
                              ),
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DoctorLocationScreen(doctor: widget.doctor),
                              ),
                            );
                          }
                        },
                        child: InfoRow(
                          label: 'Address',
                          value: widget.doctor.address?.isNotEmpty ?? false
                              ? widget.doctor.address!
                              : 'No address provided',
                          valueStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF003087),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Social Links Card
              if (widget.doctor.website != null ||
                  widget.doctor.facebookUrl != null ||
                  widget.doctor.twitterUrl != null) ...[
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Social Links',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF003087),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (widget.doctor.website != null && widget.doctor.website!.isNotEmpty)
                          GestureDetector(
                            onTap: () => _launchURL(widget.doctor.website!, 'visit website', context),
                            child: InfoRow(label: 'Website', value: widget.doctor.website!),
                          ),
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Biography Card
              if (widget.doctor.biography != null && widget.doctor.biography!.isNotEmpty) ...[
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Biography',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF003087),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.doctor.biography!,
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Reviews Card
              if (widget.doctor.reviews != null && widget.doctor.reviews!.isNotEmpty) ...[
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Patient Reviews',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF003087),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _isReviewsExpanded ? Icons.expand_less : Icons.expand_more,
                                color: const Color(0xFF003087),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isReviewsExpanded = !_isReviewsExpanded;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
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
                            const SizedBox(width: 8),
                            Text(
                              '(${widget.doctor.reviews!.length} reviews)',
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                          ],
                        ),
                        if (_isReviewsExpanded) ...[
                          const SizedBox(height: 16),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: widget.doctor.reviews!.length,
                            itemBuilder: (context, index) {
                              final review = widget.doctor.reviews![index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${review['rating']} - ${review['comment'] ?? 'No comment'}',
                                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDate(review['date']),
                                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Action Buttons
              FutureBuilder<bool>(
                future: _canLaunchPhone(widget.doctor.phone),
                builder: (context, phoneSnapshot) {
                  final canCall = phoneSnapshot.data ?? false;
                  if (!canCall && (widget.doctor.phone?.isNotEmpty ?? false)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Call button disabled: Invalid phone number (${widget.doctor.phone}) or no phone app available.',
                          ),
                        ),
                      );
                    });
                  }
                  return FutureBuilder<bool>(
                    future: _canLaunchEmail(widget.doctor.email),
                    builder: (context, emailSnapshot) {
                      final canEmail = emailSnapshot.data ?? false;
                      if (!canEmail && (widget.doctor.email?.isNotEmpty ?? false)) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Email button disabled: Invalid email (${widget.doctor.email}) or no email client available.',
                              ),
                            ),
                          );
                        });
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: canCall
                                  ? () => _launchURL('tel:${widget.doctor.phone!}', 'call', context)
                                  : null,
                              icon: const Icon(Icons.phone, size: 20, color: Colors.white),
                              label: const Text(
                                'Call',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canCall ? const Color(0xFF003087) : Colors.grey,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: canEmail
                                  ? () => _launchURL('mailto:${widget.doctor.email!}', 'email', context)
                                  : null,
                              icon: const Icon(Icons.email, size: 20, color: Colors.white),
                              label: const Text(
                                'Email',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canEmail ? const Color(0xFF003087) : Colors.grey,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showAddReviewDialog,
                      icon: const Icon(Icons.rate_review, size: 20, color: Colors.white),
                      label: const Text(
                        'Add Review',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003087),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showBookAppointmentDialog,
                      icon: const Icon(Icons.calendar_today, size: 20, color: Colors.white),
                      label: const Text(
                        'Book',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003087),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
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
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueStyle,
  });

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
          style: valueStyle ??
              const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
        ),
      ],
    );
  }
}