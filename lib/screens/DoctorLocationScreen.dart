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
        appBar: AppBar(title: const Text('Location')),
        body: const Center(child: Text('No location available')),
      );
    }

    final point = LatLng(doctor.latitude!, doctor.longitude!);

    return Scaffold(
      appBar: AppBar(title: Text(doctor.name)),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: point,
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.demo',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: point,
                width: 80,
                height: 80,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
