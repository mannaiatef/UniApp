import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/doctor.dart';

class DoctorLocationScreen extends StatefulWidget {
  final Doctor doctor;

  const DoctorLocationScreen({super.key, required this.doctor});

  @override
  State<DoctorLocationScreen> createState() => _DoctorLocationScreenState();
}

class _DoctorLocationScreenState extends State<DoctorLocationScreen> {
  late Box _cacheBox;
  late Map<String, String> _specialtyMap;

  @override
  void initState() {
    super.initState();
    _cacheBox = Hive.box('cache');
    _loadSpecialtiesCache();
  }

  void _loadSpecialtiesCache() {
    final cached = _cacheBox.get('specialties', defaultValue: {});
    _specialtyMap = Map<String, String>.from(cached);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.doctor.latitude == null || widget.doctor.longitude == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Location',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
          ),
          backgroundColor: const Color(0xFF003087),
          elevation: 4,
          shadowColor: Colors.black45,
        ),
        body: Container(
          color: Colors.grey[100],
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_off, size: 60, color: Color(0xFF8B0000)),
                    const SizedBox(height: 16),
                    Text(
                      'No location available',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final point = LatLng(widget.doctor.latitude!, widget.doctor.longitude!);
    final specialtyName = _specialtyMap[widget.doctor.specialtyId] ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dr. ${widget.doctor.name}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF003087),
        elevation: 4,
        shadowColor: Colors.black45,
      ),
      body: Container(
        color: Colors.grey[100],
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: point,
                      initialZoom: 13,
                      maxZoom: 18,
                      minZoom: 10,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.demo',
                        tileProvider: NetworkTileProvider(),
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: point,
                            width: 40,
                            height: 40,
                            child: AnimatedOpacity(
                              opacity: 1.0,
                              duration: const Duration(milliseconds: 500),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF003087), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.shade300,
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Color(0xFF003087),
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              color: Colors.grey[200],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. ${widget.doctor.name}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Specialty: $specialtyName',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (widget.doctor.phone != null && widget.doctor.phone!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.phone, color: Color(0xFF006400), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              widget.doctor.phone!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.doctor.latitude != null && widget.doctor.longitude != null
          ? FloatingActionButton.extended(
        onPressed: () async {
          final url =
              'https://www.google.com/maps/search/?api=1&query=${widget.doctor.latitude},${widget.doctor.longitude}';
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not open maps'),
                backgroundColor: Color(0xFF8B0000),
              ),
            );
          }
        },
        backgroundColor: const Color(0xFF003087),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.directions),
        label: const Text('Get Directions'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      )
          : null,
    );
  }
}