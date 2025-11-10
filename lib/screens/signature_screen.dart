import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SignatureScreen extends StatefulWidget {
  final Function(Uint8List?) onSigned;
  const SignatureScreen({super.key, required this.onSigned});

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.blue,
    exportBackgroundColor: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Signature du Médecin ✍️"),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Signez dans le cadre ci-dessous",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Signature(
              controller: _controller,
              height: 300,
              backgroundColor: Colors.grey[100]!,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: () => _controller.clear(),
                icon: const Icon(Icons.clear),
                label: const Text("Effacer"),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006AF6),
                ),
                onPressed: () async {
                  final signature = await _controller.toPngBytes();
                  widget.onSigned(signature);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check),
                label: const Text("Valider la signature"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
