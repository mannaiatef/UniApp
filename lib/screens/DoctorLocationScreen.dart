import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/doctor.dart';

class DoctorLocationScreen extends StatelessWidget {
  final Doctor doctor;

  const DoctorLocationScreen({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    if (doctor.latitude == null || doctor.longitude == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Location',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF003087),
          elevation: 4,
        ),
        body: Container(
          color: Colors.grey[100],
          child: const Center(
            child: Text(
              'No location available',
              style: TextStyle(fontSize: 18, color: Colors.black87),
            ),
          ),
        ),
      );
    }

    final point = LatLng(doctor.latitude!, doctor.longitude!);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          doctor.name,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF003087),
        elevation: 4,
      ),
      body: Container(
        color: Colors.grey[100], // Light background for contrast
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}