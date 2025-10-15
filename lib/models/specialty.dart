class Specialty {
  String id;
  String name;
  String? description; // facultatif
  String? videoUrl;     // optional video URL

  Specialty({
    required this.id,
    required this.name,
    this.description,
    this.videoUrl,
  });

  // Convert Firestore doc to Specialty
  factory Specialty.fromMap(Map<String, dynamic> data, String docId) {
    return Specialty(
      id: docId,
      name: data['name'] ?? '',
      description: data['description'],
      videoUrl: data['videoUrl'], // new field
    );
  }

  // Convert Specialty to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'videoUrl': videoUrl, // new field
    };
  }
}
